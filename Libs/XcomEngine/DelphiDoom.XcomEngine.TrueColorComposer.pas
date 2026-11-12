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
  ///   the palette mixed with what is under it by its coverage.
  ///   The composer remembers what it composed the frame from (the base, the palette, the layers): the rows of the
  ///   game picture that are as they were keep the rows of the frame they have, only the others are composed again.
  ///   The rectangle of an ink layer is always composed again (the ink is mixed over what is under it)
  /// </summary>
  TXcomTrueColorComposer = class(TInterfacedObject, IXcomFrameComposer, IXcomDetailLayers, IXcomBlendLayers,
    IXcomInkLayers)
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
      /// <summary>The colors of the pixels of a widget that are blends: the rectangle, what the widget left there
      /// (After) and, for the pixels that have one (Valid), the color</summary>
      TBlend = record
        X: Integer;
        Y: Integer;
        Width: Integer;
        Height: Integer;
        After: TBytes;
        Valid: TBytes;
        Colors: TXcomTrueColorPixels;
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
      /// <summary>What the frame was last composed from; FLastValid false: the frame is composed whole</summary>
      FLastValid: Boolean;
      FLastBase: TBytes;
      FLastColors: array[0..255] of Cardinal;
      FLastLayers: TArray<TLayer>;
      FLastDetails: TArray<TBytes>;
      FLastLayerCount: Integer;
      FDirtyRows: TArray<Boolean>;
      FComposedRows: Integer;
      FBlends: TArray<TBlend>;
      FBlendCount: Integer;
      FLastBlends: TArray<TBlend>;
      FLastBlendCount: Integer;
    class function SourceIndexes(ASourceSize, ADestSize: Integer): TArray<Integer>; static;
    class procedure CopyRect(ABase: TXcomSurface; const ALayer: TLayer; var ATarget: TBytes); static;
    procedure ComposeLayer(ABase: TXcomSurface; const ALayer: TLayer; const AColors: array of Cardinal);
    procedure ComposeBase(const ASource: TBytes; const AColors: array of Cardinal);
    function SameLayers: Boolean;
    procedure FindDirtyRows(const ASource: TBytes; const AColors: array of Cardinal);
    procedure RememberFrame(const ASource: TBytes; const AColors: array of Cardinal);
    function SameBlends: Boolean;
    procedure ComposeBlend(const ASource: TBytes; const ABlend: TBlend);
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
    procedure AddBlendLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer; const AValid: TBytes;
      const AColors: TXcomTrueColorPixels; AStride: Integer);
    /// <summary>
    ///   IXcomInkLayers. Only on the picture the last frame was composed from, at a whole scale of 2 or more, and
    ///   not inside another layer
    /// </summary>
    function BeginInk(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer): Boolean;
    procedure EndInk(ABase: TXcomSurface; const AInk: TXcomInkBuffer; const AUnder: TBytes);
    /// <summary>The last frame that was composed (the size of the display)</summary>
    property Frame: TXcomTrueColorPixels read FFrame;
    /// <summary>How many rows of the game picture the last frame composed again (all of them: its height)</summary>
    property ComposedRows: Integer read FComposedRows;
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
  FLastValid := False;
  FLastLayerCount := 0;
  FBlendCount := 0;
  FLastBlendCount := 0;
  SetLength(FDirtyRows, ABaseHeight);
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
  LX: Integer;
  LY: Integer;
  LSubX: Integer;
  LSubY: Integer;
  LUnder: Cardinal;
  LBaseRow: PByteArray;
  LAfterRow: PByteArray;
  LBeforeRow: PByteArray;
  LDetail: PByte;
  LFrame: PCardinal;
begin
  for LY := 0 to ALayer.Height - 1 do
  begin
    if not FDirtyRows[ALayer.Y + LY] then
      Continue;
    LBaseRow := @ABase.Pixels[(ALayer.Y + LY) * FBaseWidth + ALayer.X];
    LAfterRow := @ALayer.After[LY * ALayer.Width];
    LBeforeRow := @ALayer.Before[LY * ALayer.Width];
    for LSubY := 0 to FDetailScale - 1 do
    begin
      LDetail := @ALayer.Detail.Pixels[(LY * FDetailScale + LSubY) * ALayer.Detail.Width];
      LFrame := @FFrame[((ALayer.Y + LY) * FDetailScale + LSubY) * FDisplayWidth + ALayer.X * FDetailScale];
      for LX := 0 to ALayer.Width - 1 do
      begin
        // something drawn after the widget covers this pixel: it stays the pixel of the game picture
        if LBaseRow[LX] <> LAfterRow[LX] then
        begin
          Inc(LDetail, FDetailScale);
          Inc(LFrame, FDetailScale);
          Continue;
        end;
        // a pixel the widget did not change: only what the detail draws is laid on the frame, which may already
        // hold the finer drawing of a widget under this one (the lines of the graphs are a pile of surfaces)
        if LBeforeRow[LX] = LAfterRow[LX] then
        begin
          for LSubX := 0 to FDetailScale - 1 do
          begin
            if LDetail^ <> 0 then
              LFrame^ := AColors[LDetail^];
            Inc(LDetail);
            Inc(LFrame);
          end;
          Continue;
        end;
        // where the detail draws nothing, what was there before the widget shows through
        LUnder := AColors[LBeforeRow[LX]];
        for LSubX := 0 to FDetailScale - 1 do
        begin
          if LDetail^ <> 0 then
            LFrame^ := AColors[LDetail^]
          else
            LFrame^ := LUnder;
          Inc(LDetail);
          Inc(LFrame);
        end;
      end;
    end;
  end;
end;

procedure TXcomTrueColorComposer.ComposeBase(const ASource: TBytes; const AColors: array of Cardinal);
var
  LX: Integer;
  LY: Integer;
  LSourceRow: Integer;
  LFrameRow: Integer;
  LWidth: Integer;
begin
  LWidth := Length(FColumns);
  for LY := 0 to High(FRows) do
  begin
    if not FDirtyRows[FRows[LY]] then
      Continue;
    LFrameRow := (FBands.Top + LY) * FDisplayWidth + FBands.Left;
    // the rows of the display that take the same row of the game picture are copies of the first one
    if (LY > 0) and (FRows[LY - 1] = FRows[LY]) then
    begin
      Move(FFrame[LFrameRow - FDisplayWidth], FFrame[LFrameRow], LWidth * SizeOf(Cardinal));
      Continue;
    end;
    LSourceRow := FRows[LY] * FBaseWidth;
    for LX := 0 to LWidth - 1 do
      FFrame[LFrameRow + LX] := AColors[ASource[LSourceRow + FColumns[LX]]];
  end;
end;

function TXcomTrueColorComposer.SameLayers: Boolean;
var
  LIndex: Integer;
begin
  Result := FLayerCount = FLastLayerCount;
  if Result then
    for LIndex := 0 to FLayerCount - 1 do
      if (FLayers[LIndex].X <> FLastLayers[LIndex].X) or (FLayers[LIndex].Y <> FLastLayers[LIndex].Y)
        or (FLayers[LIndex].Width <> FLastLayers[LIndex].Width)
        or (FLayers[LIndex].Height <> FLastLayers[LIndex].Height)
        or (FLayers[LIndex].IsInk <> FLastLayers[LIndex].IsInk)
        or ((not FLayers[LIndex].IsInk) and (Length(FLayers[LIndex].Detail.Pixels) <> Length(FLastDetails[LIndex]))) then
        Exit(False);
end;

procedure TXcomTrueColorComposer.FindDirtyRows(const ASource: TBytes; const AColors: array of Cardinal);
var
  LIndex: Integer;
  LRow: Integer;
  LWidth: Integer;
  LDetail: TBytes;
  LDetailBytes: Integer;
begin
  FComposedRows := 0;
  if (not FLastValid) or (not CompareMem(@AColors[0], @FLastColors[0], SizeOf(FLastColors))) or (not SameLayers)
    or (not SameBlends) then
  begin
    for LRow := 0 to FBaseHeight - 1 do
      FDirtyRows[LRow] := True;
    FComposedRows := FBaseHeight;
    Exit;
  end;
  for LRow := 0 to FBaseHeight - 1 do
    FDirtyRows[LRow] := not CompareMem(@ASource[LRow * FBaseWidth], @FLastBase[LRow * FBaseWidth], FBaseWidth);
  // a row of a layer is as it was when what was under the widget, what the widget left and its detail all are
  for LIndex := 0 to FLayerCount - 1 do
  begin
    // the rectangle of an ink layer is composed again whole: its ink is mixed over the frame
    if FLayers[LIndex].IsInk then
    begin
      for LRow := 0 to FLayers[LIndex].Height - 1 do
        FDirtyRows[FLayers[LIndex].Y + LRow] := True;
      Continue;
    end;
    LDetail := FLayers[LIndex].Detail.Pixels;
    LWidth := FLayers[LIndex].Width;
    LDetailBytes := LWidth * FDetailScale * FDetailScale;
    for LRow := 0 to FLayers[LIndex].Height - 1 do
      if (not FDirtyRows[FLayers[LIndex].Y + LRow])
        and ((not CompareMem(@FLayers[LIndex].Before[LRow * LWidth], @FLastLayers[LIndex].Before[LRow * LWidth],
        LWidth))
        or (not CompareMem(@FLayers[LIndex].After[LRow * LWidth], @FLastLayers[LIndex].After[LRow * LWidth], LWidth))
        or (not CompareMem(@LDetail[LRow * LDetailBytes], @FLastDetails[LIndex][LRow * LDetailBytes],
        LDetailBytes))) then
        FDirtyRows[FLayers[LIndex].Y + LRow] := True;
  end;
  // and a row of blends when the widget left the same pixels with the same colors
  for LIndex := 0 to FBlendCount - 1 do
  begin
    LWidth := FBlends[LIndex].Width;
    for LRow := 0 to FBlends[LIndex].Height - 1 do
      if (not FDirtyRows[FBlends[LIndex].Y + LRow])
        and ((not CompareMem(@FBlends[LIndex].After[LRow * LWidth], @FLastBlends[LIndex].After[LRow * LWidth], LWidth))
        or (not CompareMem(@FBlends[LIndex].Valid[LRow * LWidth], @FLastBlends[LIndex].Valid[LRow * LWidth], LWidth))
        or (not CompareMem(@FBlends[LIndex].Colors[LRow * LWidth], @FLastBlends[LIndex].Colors[LRow * LWidth],
        LWidth * SizeOf(Cardinal)))) then
        FDirtyRows[FBlends[LIndex].Y + LRow] := True;
  end;
  for LRow := 0 to FBaseHeight - 1 do
    if FDirtyRows[LRow] then
      Inc(FComposedRows);
end;

procedure TXcomTrueColorComposer.RememberFrame(const ASource: TBytes; const AColors: array of Cardinal);
var
  LIndex: Integer;
  LDetail: TBytes;
begin
  if Length(FLastBase) <> Length(ASource) then
    SetLength(FLastBase, Length(ASource));
  if FComposedRows > 0 then
    Move(ASource[0], FLastBase[0], Length(ASource));
  Move(AColors[0], FLastColors[0], SizeOf(FLastColors));
  if Length(FLastLayers) < FLayerCount then
  begin
    SetLength(FLastLayers, FLayerCount);
    SetLength(FLastDetails, FLayerCount);
  end;
  for LIndex := 0 to FLayerCount - 1 do
  begin
    // the two copies of the rectangle change hands (the next BeginLayer makes its own)
    FLastLayers[LIndex] := FLayers[LIndex];
    FLastLayers[LIndex].Detail := nil;
    FLastLayers[LIndex].Ink := Default(TXcomInkBuffer);
    FLastLayers[LIndex].Under := nil;
    FLayers[LIndex].Before := nil;
    FLayers[LIndex].After := nil;
    if FLayers[LIndex].IsInk then
    begin
      FLastDetails[LIndex] := nil;
      Continue;
    end;
    LDetail := FLayers[LIndex].Detail.Pixels;
    if Length(FLastDetails[LIndex]) <> Length(LDetail) then
      SetLength(FLastDetails[LIndex], Length(LDetail));
    if FComposedRows > 0 then
      Move(LDetail[0], FLastDetails[LIndex][0], Length(LDetail));
  end;
  // the blends change hands whole: the next AddBlendLayer makes its own copies
  if Length(FLastBlends) < FBlendCount then
    SetLength(FLastBlends, FBlendCount);
  for LIndex := 0 to FBlendCount - 1 do
  begin
    FLastBlends[LIndex] := FBlends[LIndex];
    FBlends[LIndex].After := nil;
    FBlends[LIndex].Valid := nil;
    FBlends[LIndex].Colors := nil;
  end;
  FLastBlendCount := FBlendCount;
  FLastLayerCount := FLayerCount;
  FLastValid := True;
end;

function TXcomTrueColorComposer.SameBlends: Boolean;
var
  LIndex: Integer;
begin
  Result := FBlendCount = FLastBlendCount;
  if Result then
    for LIndex := 0 to FBlendCount - 1 do
      if (FBlends[LIndex].X <> FLastBlends[LIndex].X) or (FBlends[LIndex].Y <> FLastBlends[LIndex].Y)
        or (FBlends[LIndex].Width <> FLastBlends[LIndex].Width)
        or (FBlends[LIndex].Height <> FLastBlends[LIndex].Height) then
        Exit(False);
end;

procedure TXcomTrueColorComposer.AddBlendLayer(ABase: TXcomSurface; AX, AY, AWidth, AHeight: Integer;
  const AValid: TBytes; const AColors: TXcomTrueColorPixels; AStride: Integer);
var
  LRow: Integer;
  LLayer: TLayer;
begin
  // only on the picture of the screen, with a whole rectangle inside it and all its rows given
  if (not Assigned(ABase)) or (ABase.Width <> FBaseWidth) or (ABase.Height <> FBaseHeight) or (AX < 0) or (AY < 0)
    or (AWidth <= 0) or (AHeight <= 0) or (AX + AWidth > FBaseWidth) or (AY + AHeight > FBaseHeight)
    or (AStride < AWidth) or (Length(AValid) < (AHeight - 1) * AStride + AWidth)
    or (Length(AColors) < (AHeight - 1) * AStride + AWidth) then
    Exit;
  if FBlendCount = Length(FBlends) then
    SetLength(FBlends, FBlendCount + 2);
  FBlends[FBlendCount].X := AX;
  FBlends[FBlendCount].Y := AY;
  FBlends[FBlendCount].Width := AWidth;
  FBlends[FBlendCount].Height := AHeight;
  LLayer.X := AX;
  LLayer.Y := AY;
  LLayer.Width := AWidth;
  LLayer.Height := AHeight;
  CopyRect(ABase, LLayer, FBlends[FBlendCount].After);
  SetLength(FBlends[FBlendCount].Valid, AWidth * AHeight);
  SetLength(FBlends[FBlendCount].Colors, AWidth * AHeight);
  for LRow := 0 to AHeight - 1 do
  begin
    Move(AValid[LRow * AStride], FBlends[FBlendCount].Valid[LRow * AWidth], AWidth);
    Move(AColors[LRow * AStride], FBlends[FBlendCount].Colors[LRow * AWidth], AWidth * SizeOf(Cardinal));
  end;
  Inc(FBlendCount);
end;

procedure TXcomTrueColorComposer.ComposeBlend(const ASource: TBytes; const ABlend: TBlend);
var
  LX: Integer;
  LY: Integer;
  LBaseX: Integer;
  LBaseY: Integer;
  LCell: Integer;
  LFrameRow: Integer;
begin
  // every pixel of the display takes the pixel of the game picture the scaler gives it: where that pixel has a
  // color of its own and still is the one the widget left, the color goes in place of the one of the palette
  for LY := 0 to High(FRows) do
  begin
    LBaseY := FRows[LY];
    if (LBaseY < ABlend.Y) or (LBaseY >= ABlend.Y + ABlend.Height) or (not FDirtyRows[LBaseY]) then
      Continue;
    LFrameRow := (FBands.Top + LY) * FDisplayWidth + FBands.Left;
    for LX := 0 to High(FColumns) do
    begin
      LBaseX := FColumns[LX];
      if (LBaseX < ABlend.X) or (LBaseX >= ABlend.X + ABlend.Width) then
        Continue;
      LCell := (LBaseY - ABlend.Y) * ABlend.Width + LBaseX - ABlend.X;
      if (ABlend.Valid[LCell] <> 0) and (ASource[LBaseY * FBaseWidth + LBaseX] = ABlend.After[LCell]) then
        FFrame[LFrameRow + LX] := ABlend.Colors[LCell];
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
  LSource: TBytes;
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
    LSource := ABase.Pixels;
    FindDirtyRows(LSource, LColors);
    // the bands are the color 0 of the palette, as the indexes of the 8 bit display are (when the palette
    // changes the frame is composed whole)
    if (FComposedRows = FBaseHeight) and (FBands.Left + FBands.Right + FBands.Top + FBands.Bottom > 0) then
      for LIndex := 0 to High(FFrame) do
        FFrame[LIndex] := LColors[0];
    if FComposedRows > 0 then
    begin
      ComposeBase(LSource, LColors);
      for LIndex := 0 to FBlendCount - 1 do
        ComposeBlend(LSource, FBlends[LIndex]);
      for LIndex := 0 to FLayerCount - 1 do
        if FLayers[LIndex].IsInk then
          ComposeInk(ABase, FLayers[LIndex], LColors)
        else
          ComposeLayer(ABase, FLayers[LIndex], LColors);
    end;
    RememberFrame(LSource, LColors);
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
    FBlendCount := 0;
    FOpenLayer := False;
    FOpenInk := False;
    // the widgets of the next frame leave their ink only on this picture
    FBase := ABase;
  end;
end;

end.
