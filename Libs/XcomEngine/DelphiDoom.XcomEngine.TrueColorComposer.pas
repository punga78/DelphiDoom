{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the composition of the frame in true       }
{  color (issue 183): palette applied at the composition, the game picture      }
{  scaled by the nearest pixel, the finer drawings of the widgets over it       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.TrueColorComposer;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomSurface.Ink.Types,
  DelphiDoom.XcomSurface.FontDetail.Intf;

type
  /// <summary>
  ///   IXcomFrameComposer and IXcomDetailLayers on a display of colors. The frame has the size of the display: the
  ///   base surface goes in the rectangle between the black bands, each pixel of the display taking the pixel of
  ///   the base that the software scaler of the screen takes (Zoom::_zoomSurfaceY: the same steps), turned into a
  ///   color with the palette. So at any scale the frame is the 8 bit picture of the screen after its palette.
  ///   When the display is a whole number of times the base and has no bands, the layers the widgets left are laid
  ///   over it (see IXcomDetailLayers), and so is the ink of the texts (IXcomInkLayers, issue 184): a color of
  ///   the palette mixed with what is under it by its coverage
  /// </summary>
  TXcomTrueColorComposer = class(TInterfacedObject, IXcomFrameComposer, IXcomDetailLayers, IXcomInkLayers)
  public
    const
      /// <summary>The largest scale the detail layers are used at</summary>
      MAX_DETAIL_SCALE = 8;
  strict private
    type
      TLayer = record
        X: Integer;
        Y: Integer;
        Width: Integer;
        Height: Integer;
        Before: TBytes;
        After: TBytes;
        Detail: TXcomSurface;
        /// <summary>An ink layer: the ink of the whole widget, where the rectangle (cut to the picture) is in it, the widget without text</summary>
        IsInk: Boolean;
        Ink: TXcomInkBuffer;
        InkX: Integer;
        InkY: Integer;
        Under: TBytes;
      end;
    var
      FDisplay: IXcomTrueColorDisplay;
      FFrame: TXcomTrueColorPixels;
      FBaseWidth: Integer;
      FBaseHeight: Integer;
      FDisplayWidth: Integer;
      FDisplayHeight: Integer;
      FBands: TXcomBlackBands;
      FColumns: TArray<Integer>;
      FRows: TArray<Integer>;
      FDetailScale: Integer;
      FLayers: TArray<TLayer>;
      FLayerCount: Integer;
      FOpenLayer: Boolean;
      FOpenInk: Boolean;
      FInkWidth: Integer;
      FInkHeight: Integer;
      FBase: TXcomSurface;
      FCellState: TBytes;
    class function SourceIndexes(ASourceSize, ADestSize: Integer): TArray<Integer>; static;
    class procedure CopyRect(ABase: TXcomSurface; const ALayer: TLayer; var ATarget: TBytes); static;
    procedure ComposeLayer(ABase: TXcomSurface; const ALayer: TLayer; const AColors: array of Cardinal);
    procedure ComposeInk(ABase: TXcomSurface; const ALayer: TLayer; const AColors: array of Cardinal);
    class function Mix(AUnder, AColor: Cardinal; AAlpha: Cardinal): Cardinal; static; inline;
  public
    /// <param name="ADisplay">Where the frames go</param>
    constructor Create(const ADisplay: IXcomTrueColorDisplay);
    procedure SetGeometry(ABaseWidth, ABaseHeight, ADisplayWidth, ADisplayHeight: Integer;
      const ABands: TXcomBlackBands);
    function Present(ABase: TXcomSurface; const APalette: TXcomColors): Boolean;
    function DetailLayers: IXcomDetailLayers;
    function DetailScale: Integer;
    procedure BeginLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
    procedure EndLayer(ABase, ADetail: TXcomSurface);
    /// <summary>
    ///   IXcomInkLayers. Only on the picture the last frame was composed from, at a whole scale of 2 or more, and
    ///   not inside another layer
    /// </summary>
    function BeginInk(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer): Boolean;
    procedure EndInk(ABase: TXcomSurface; const AInk: TXcomInkBuffer; const AUnder: TBytes);
    /// <summary>The last frame that was composed (the size of the display)</summary>
    property Frame: TXcomTrueColorPixels read FFrame;
  end;

implementation

const
  OPAQUE_BLACK = $FF000000;

constructor TXcomTrueColorComposer.Create(const ADisplay: IXcomTrueColorDisplay);
begin
  inherited Create;
  if not Assigned(ADisplay) then
    raise EArgumentNilException.Create('ADisplay');
  FDisplay := ADisplay;
  FDetailScale := 1;
end;

class function TXcomTrueColorComposer.SourceIndexes(ASourceSize, ADestSize: Integer): TArray<Integer>;
var
  LCounter: Integer;
  LSource: Integer;
  LIndex: Integer;
begin
  // Zoom::_zoomSurfaceY as TXcomScreen.Zoom does it: the source index advances after every destination pixel by a
  // step that an error counter decides; here the index of each destination pixel is kept instead of the steps
  SetLength(Result, ADestSize);
  LCounter := 0;
  LSource := 0;
  for LIndex := 0 to ADestSize - 1 do
  begin
    Result[LIndex] := LSource;
    Inc(LCounter, ASourceSize);
    while LCounter >= ADestSize do
    begin
      Dec(LCounter, ADestSize);
      Inc(LSource);
    end;
  end;
end;

procedure TXcomTrueColorComposer.SetGeometry(ABaseWidth, ABaseHeight, ADisplayWidth, ADisplayHeight: Integer;
  const ABands: TXcomBlackBands);
var
  LWidth: Integer;
  LHeight: Integer;
  LIndex: Integer;
begin
  FBaseWidth := ABaseWidth;
  FBaseHeight := ABaseHeight;
  FDisplayWidth := ADisplayWidth;
  FDisplayHeight := ADisplayHeight;
  FBands := ABands;
  FLayerCount := 0;
  FOpenLayer := False;
  SetLength(FFrame, ADisplayWidth * ADisplayHeight);
  for LIndex := 0 to High(FFrame) do
    FFrame[LIndex] := OPAQUE_BLACK;
  LWidth := ADisplayWidth - ABands.Left - ABands.Right;
  LHeight := ADisplayHeight - ABands.Top - ABands.Bottom;
  FColumns := nil;
  FRows := nil;
  FDetailScale := 1;
  if (LWidth <= 0) or (LHeight <= 0) or (ABaseWidth <= 0) or (ABaseHeight <= 0) then
    Exit;
  FColumns := SourceIndexes(ABaseWidth, LWidth);
  FRows := SourceIndexes(ABaseHeight, LHeight);
  // the detail needs whole pixels: the same whole scale on both sides and no bands
  if (ABands.Left + ABands.Right + ABands.Top + ABands.Bottom = 0) and (ADisplayWidth mod ABaseWidth = 0)
    and (ADisplayHeight mod ABaseHeight = 0) and (ADisplayWidth div ABaseWidth = ADisplayHeight div ABaseHeight)
    and (ADisplayWidth div ABaseWidth <= MAX_DETAIL_SCALE) then
    FDetailScale := ADisplayWidth div ABaseWidth;
end;

function TXcomTrueColorComposer.DetailLayers: IXcomDetailLayers;
begin
  Result := Self;
end;

function TXcomTrueColorComposer.DetailScale: Integer;
begin
  Result := FDetailScale;
end;

class procedure TXcomTrueColorComposer.CopyRect(ABase: TXcomSurface; const ALayer: TLayer; var ATarget: TBytes);
var
  LRow: Integer;
  LPixels: TBytes;
begin
  SetLength(ATarget, ALayer.Width * ALayer.Height);
  LPixels := ABase.Pixels;
  for LRow := 0 to ALayer.Height - 1 do
    Move(LPixels[(ALayer.Y + LRow) * ABase.Width + ALayer.X], ATarget[LRow * ALayer.Width], ALayer.Width);
end;

procedure TXcomTrueColorComposer.BeginLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer);
begin
  FOpenLayer := False;
  FOpenInk := False;
  // only on the picture of the screen, with a whole rectangle inside it, and never one inside another
  if (FDetailScale < 2) or (not Assigned(ABase)) or (ABase.Width <> FBaseWidth) or (ABase.Height <> FBaseHeight)
    or (AX < 0) or (AY < 0) or (AWidth <= 0) or (AHeight <= 0) or (AX + AWidth > FBaseWidth)
    or (AY + AHeight > FBaseHeight) then
    Exit;
  if FLayerCount = Length(FLayers) then
    SetLength(FLayers, FLayerCount + 4);
  FLayers[FLayerCount].X := AX;
  FLayers[FLayerCount].Y := AY;
  FLayers[FLayerCount].Width := AWidth;
  FLayers[FLayerCount].Height := AHeight;
  FLayers[FLayerCount].Detail := nil;
  FLayers[FLayerCount].IsInk := False;
  CopyRect(ABase, FLayers[FLayerCount], FLayers[FLayerCount].Before);
  FOpenLayer := True;
end;

procedure TXcomTrueColorComposer.EndLayer(ABase, ADetail: TXcomSurface);
begin
  if not FOpenLayer then
    Exit;
  FOpenLayer := False;
  if (not Assigned(ADetail)) or (ADetail.Width <> FLayers[FLayerCount].Width * FDetailScale)
    or (ADetail.Height <> FLayers[FLayerCount].Height * FDetailScale) or (ABase.Width <> FBaseWidth)
    or (ABase.Height <> FBaseHeight) then
    Exit;
  CopyRect(ABase, FLayers[FLayerCount], FLayers[FLayerCount].After);
  FLayers[FLayerCount].Detail := ADetail;
  Inc(FLayerCount);
end;

procedure TXcomTrueColorComposer.ComposeLayer(ABase: TXcomSurface; const ALayer: TLayer;
  const AColors: array of Cardinal);
var
  LBase: TBytes;
  LDetail: TBytes;
  LDetailWidth: Integer;
  LX: Integer;
  LY: Integer;
  LSubX: Integer;
  LSubY: Integer;
  LCell: Integer;
  LUnder: Cardinal;
  LValue: Byte;
  LDetailRow: Integer;
  LFrameRow: Integer;
begin
  LBase := ABase.Pixels;
  LDetail := ALayer.Detail.Pixels;
  LDetailWidth := ALayer.Detail.Width;
  for LY := 0 to ALayer.Height - 1 do
    for LX := 0 to ALayer.Width - 1 do
    begin
      LCell := LY * ALayer.Width + LX;
      // something drawn after the widget covers this pixel: it stays the pixel of the game picture
      if LBase[(ALayer.Y + LY) * FBaseWidth + ALayer.X + LX] <> ALayer.After[LCell] then
        Continue;
      // where the detail draws nothing, what was there before the widget shows through
      LUnder := AColors[ALayer.Before[LCell]];
      for LSubY := 0 to FDetailScale - 1 do
      begin
        LDetailRow := (LY * FDetailScale + LSubY) * LDetailWidth + LX * FDetailScale;
        LFrameRow := ((ALayer.Y + LY) * FDetailScale + LSubY) * FDisplayWidth + (ALayer.X + LX) * FDetailScale;
        for LSubX := 0 to FDetailScale - 1 do
        begin
          LValue := LDetail[LDetailRow + LSubX];
          if LValue <> 0 then
            FFrame[LFrameRow + LSubX] := AColors[LValue]
          else
            FFrame[LFrameRow + LSubX] := LUnder;
        end;
      end;
    end;
end;

function TXcomTrueColorComposer.BeginInk(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer): Boolean;
var
  LLeft: Integer;
  LTop: Integer;
  LRight: Integer;
  LBottom: Integer;
begin
  Result := False;
  FOpenInk := False;
  // a text drawn on another surface (a button, a list) is not on the screen: its owner leaves the ink
  if FOpenLayer or (FDetailScale < 2) or (not Assigned(ABase)) or (ABase <> FBase) or (ABase.Width <> FBaseWidth)
    or (ABase.Height <> FBaseHeight) or (AWidth <= 0) or (AHeight <= 0) then
    Exit;
  // a widget may go out of the picture: the part that is in it
  LLeft := AX;
  if LLeft < 0 then
    LLeft := 0;
  LTop := AY;
  if LTop < 0 then
    LTop := 0;
  LRight := AX + AWidth;
  if LRight > FBaseWidth then
    LRight := FBaseWidth;
  LBottom := AY + AHeight;
  if LBottom > FBaseHeight then
    LBottom := FBaseHeight;
  if (LRight <= LLeft) or (LBottom <= LTop) then
    Exit;
  if FLayerCount = Length(FLayers) then
    SetLength(FLayers, FLayerCount + 16);
  FLayers[FLayerCount].X := LLeft;
  FLayers[FLayerCount].Y := LTop;
  FLayers[FLayerCount].Width := LRight - LLeft;
  FLayers[FLayerCount].Height := LBottom - LTop;
  FLayers[FLayerCount].Detail := nil;
  FLayers[FLayerCount].IsInk := True;
  FLayers[FLayerCount].InkX := LLeft - AX;
  FLayers[FLayerCount].InkY := LTop - AY;
  CopyRect(ABase, FLayers[FLayerCount], FLayers[FLayerCount].Before);
  FInkWidth := AWidth;
  FInkHeight := AHeight;
  FOpenInk := True;
  Result := True;
end;

procedure TXcomTrueColorComposer.EndInk(ABase: TXcomSurface; const AInk: TXcomInkBuffer; const AUnder: TBytes);
begin
  if not FOpenInk then
    Exit;
  FOpenInk := False;
  if (ABase <> FBase) or (AInk.Scale <> FDetailScale) or (AInk.Width <> FInkWidth) or (AInk.Height <> FInkHeight)
    or (Length(AInk.Pixels) <> FInkWidth * FInkHeight * FDetailScale * FDetailScale)
    or (Length(AInk.Cells) <> FInkWidth * FInkHeight)
    or ((Length(AUnder) <> 0) and (Length(AUnder) <> FInkWidth * FInkHeight)) then
    Exit;
  CopyRect(ABase, FLayers[FLayerCount], FLayers[FLayerCount].After);
  FLayers[FLayerCount].Ink := AInk;
  FLayers[FLayerCount].Under := AUnder;
  Inc(FLayerCount);
end;

class function TXcomTrueColorComposer.Mix(AUnder, AColor: Cardinal; AAlpha: Cardinal): Cardinal;
var
  LRest: Cardinal;
  LPair: Cardinal;
  LGreen: Cardinal;
begin
  if AAlpha = 0 then
    Exit(AUnder);
  if AAlpha >= 255 then
    Exit(AColor);
  LRest := 255 - AAlpha;
  // each channel is (color * alpha + under * rest) / 255 rounded to the nearest; red and blue are computed
  // together, and (t + t shr 8) shr 8 with t = x + 128 is that division for every x up to 255 * 255
  LPair := (AColor and $FF00FF) * AAlpha + (AUnder and $FF00FF) * LRest + $800080;
  LPair := ((LPair + ((LPair shr 8) and $FF00FF)) shr 8) and $FF00FF;
  LGreen := ((AColor shr 8) and $FF) * AAlpha + ((AUnder shr 8) and $FF) * LRest + $80;
  LGreen := (LGreen + (LGreen shr 8)) and $FF00;
  Result := $FF000000 or LPair or LGreen;
end;

procedure TXcomTrueColorComposer.ComposeInk(ABase: TXcomSurface; const ALayer: TLayer;
  const AColors: array of Cardinal);
const
  COVERED = 0;
  FREE_CELL = 1;
  TEXT_CELL = 2;
  // a pixel of ink beside no text of the picture is not trusted further than this many pixels of the game
  NEIGHBOURHOOD = 2;
var
  LBase: TBytes;
  LHasUnder: Boolean;
  LX: Integer;
  LY: Integer;
  LCell: Integer;
  LInkCell: Integer;
  LUnder: Byte;
  LState: Byte;
  LNearX: Integer;
  LNearY: Integer;
  LNear: Boolean;
  LSubX: Integer;
  LSubY: Integer;
  LInkRow: Integer;
  LFrameRow: Integer;
  LInkWidth: Integer;
  LValue: TXcomInkPixel;
  LColor: Cardinal;
begin
  LBase := ABase.Pixels;
  LHasUnder := Length(ALayer.Under) <> 0;
  LInkWidth := ALayer.Ink.Width * FDetailScale;
  if Length(FCellState) < ALayer.Width * ALayer.Height then
    SetLength(FCellState, ALayer.Width * ALayer.Height);
  // first what every pixel of the game is now: covered by something drawn later, still the text of the picture
  // (the widget changed it and it is not what shows without the text), or untouched
  for LY := 0 to ALayer.Height - 1 do
    for LX := 0 to ALayer.Width - 1 do
    begin
      LCell := LY * ALayer.Width + LX;
      LState := COVERED;
      if LBase[(ALayer.Y + LY) * FBaseWidth + ALayer.X + LX] = ALayer.After[LCell] then
      begin
        LUnder := ALayer.Before[LCell];
        if LHasUnder and (ALayer.Under[(ALayer.InkY + LY) * ALayer.Ink.Width + ALayer.InkX + LX] <> 0) then
          LUnder := ALayer.Under[(ALayer.InkY + LY) * ALayer.Ink.Width + ALayer.InkX + LX];
        if LUnder <> ALayer.After[LCell] then
          LState := TEXT_CELL
        else
          LState := FREE_CELL;
      end;
      FCellState[LCell] := LState;
    end;
  for LY := 0 to ALayer.Height - 1 do
    for LX := 0 to ALayer.Width - 1 do
    begin
      LCell := LY * ALayer.Width + LX;
      LState := FCellState[LCell];
      if LState = COVERED then
        Continue;
      LInkCell := (ALayer.InkY + LY) * ALayer.Ink.Width + ALayer.InkX + LX;
      if LState = TEXT_CELL then
      begin
        // the text of the picture goes away: what the widget shows without it comes back
        LUnder := ALayer.Before[LCell];
        if LHasUnder and (ALayer.Under[LInkCell] <> 0) then
          LUnder := ALayer.Under[LInkCell];
        LColor := AColors[LUnder];
        for LSubY := 0 to FDetailScale - 1 do
        begin
          LFrameRow := ((ALayer.Y + LY) * FDetailScale + LSubY) * FDisplayWidth + (ALayer.X + LX) * FDetailScale;
          for LSubX := 0 to FDetailScale - 1 do
            FFrame[LFrameRow + LSubX] := LColor;
        end;
      end;
      if ALayer.Ink.Cells[LInkCell] = 0 then
        Continue;
      if LState = FREE_CELL then
      begin
        // ink where the picture has no text (the edge of a character): only beside text that is still seen, so
        // that something of the same color drawn over the widget is not taken for the widget
        LNear := False;
        for LNearY := LY - NEIGHBOURHOOD to LY + NEIGHBOURHOOD do
          if (LNearY >= 0) and (LNearY < ALayer.Height) and not LNear then
            for LNearX := LX - NEIGHBOURHOOD to LX + NEIGHBOURHOOD do
              if (LNearX >= 0) and (LNearX < ALayer.Width)
                and (FCellState[LNearY * ALayer.Width + LNearX] = TEXT_CELL) then
              begin
                LNear := True;
                Break;
              end;
        if not LNear then
          Continue;
      end;
      for LSubY := 0 to FDetailScale - 1 do
      begin
        LInkRow := ((ALayer.InkY + LY) * FDetailScale + LSubY) * LInkWidth + (ALayer.InkX + LX) * FDetailScale;
        LFrameRow := ((ALayer.Y + LY) * FDetailScale + LSubY) * FDisplayWidth + (ALayer.X + LX) * FDetailScale;
        for LSubX := 0 to FDetailScale - 1 do
        begin
          LValue := ALayer.Ink.Pixels[LInkRow + LSubX];
          if LValue = 0 then
            Continue;
          // the outline first, the body over it
          LColor := FFrame[LFrameRow + LSubX];
          if LValue and $FF00 <> 0 then
            LColor := Mix(LColor, AColors[LValue and $FF], (LValue shr 8) and $FF);
          if LValue shr 24 <> 0 then
            LColor := Mix(LColor, AColors[(LValue shr 16) and $FF], LValue shr 24);
          FFrame[LFrameRow + LSubX] := LColor;
        end;
      end;
    end;
end;

function TXcomTrueColorComposer.Present(ABase: TXcomSurface; const APalette: TXcomColors): Boolean;
var
  LColors: array[0..255] of Cardinal;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LSource: TBytes;
  LSourceRow: Integer;
  LFrameRow: Integer;
  LWidth: Integer;
begin
  Result := False;
  try
    if (Length(FColumns) = 0) or (not Assigned(ABase)) or (ABase.Width <> FBaseWidth)
      or (ABase.Height <> FBaseHeight) then
      Exit;
    // the palette is applied here: the colors the display would have used for the indexes
    for LIndex := 0 to 255 do
      LColors[LIndex] := OPAQUE_BLACK or (Cardinal(APalette[LIndex].Red) shl 16) or
        (Cardinal(APalette[LIndex].Green) shl 8) or Cardinal(APalette[LIndex].Blue);
    // the bands are the color 0 of the palette, as the indexes of the 8 bit display are
    if FBands.Left + FBands.Right + FBands.Top + FBands.Bottom > 0 then
      for LIndex := 0 to High(FFrame) do
        FFrame[LIndex] := LColors[0];
    LSource := ABase.Pixels;
    LWidth := Length(FColumns);
    for LY := 0 to High(FRows) do
    begin
      LSourceRow := FRows[LY] * FBaseWidth;
      LFrameRow := (FBands.Top + LY) * FDisplayWidth + FBands.Left;
      for LX := 0 to LWidth - 1 do
        FFrame[LFrameRow + LX] := LColors[LSource[LSourceRow + FColumns[LX]]];
    end;
    for LIndex := 0 to FLayerCount - 1 do
      if FLayers[LIndex].IsInk then
        ComposeInk(ABase, FLayers[LIndex], LColors)
      else
        ComposeLayer(ABase, FLayers[LIndex], LColors);
    Result := FDisplay.PresentTrueColor(FFrame, FDisplayWidth, FDisplayHeight);
  finally
    // the layers are of one frame: the widgets leave them again at every blit
    for LIndex := 0 to FLayerCount - 1 do
    begin
      FLayers[LIndex].Detail := nil;
      FLayers[LIndex].Ink := Default(TXcomInkBuffer);
      FLayers[LIndex].Under := nil;
    end;
    FLayerCount := 0;
    FOpenLayer := False;
    FOpenInk := False;
    // the widgets of the next frame leave their ink only on this picture
    FBase := ABase;
  end;
end;

end.
