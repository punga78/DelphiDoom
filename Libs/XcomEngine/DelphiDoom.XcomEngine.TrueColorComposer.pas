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
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.TrueColor.Intf;

type
  /// <summary>
  ///   IXcomFrameComposer and IXcomDetailLayers on a display of colors. The frame has the size of the display: the
  ///   base surface goes in the rectangle between the black bands, each pixel of the display taking the pixel of
  ///   the base that the software scaler of the screen takes (Zoom::_zoomSurfaceY: the same steps), turned into a
  ///   color with the palette. So at any scale the frame is the 8 bit picture of the screen after its palette.
  ///   When the display is a whole number of times the base and has no bands, the layers the widgets left are laid
  ///   over it (see IXcomDetailLayers).
  ///   The composer remembers what it composed the frame from (the base, the palette, the layers): the rows of the
  ///   game picture that are as they were keep the rows of the frame they have, only the others are composed again
  /// </summary>
  TXcomTrueColorComposer = class(TInterfacedObject, IXcomFrameComposer, IXcomDetailLayers)
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
      /// <summary>What the frame was last composed from; FLastValid false: the frame is composed whole</summary>
      FLastValid: Boolean;
      FLastBase: TBytes;
      FLastColors: array[0..255] of Cardinal;
      FLastLayers: TArray<TLayer>;
      FLastDetails: TArray<TBytes>;
      FLastLayerCount: Integer;
      FDirtyRows: TArray<Boolean>;
      FComposedRows: Integer;
    class function SourceIndexes(ASourceSize, ADestSize: Integer): TArray<Integer>; static;
    class procedure CopyRect(ABase: TXcomSurface; const ALayer: TLayer; var ATarget: TBytes); static;
    procedure ComposeLayer(ABase: TXcomSurface; const ALayer: TLayer; const AColors: array of Cardinal);
    procedure ComposeBase(const ASource: TBytes; const AColors: array of Cardinal);
    function SameLayers: Boolean;
    procedure FindDirtyRows(const ASource: TBytes; const AColors: array of Cardinal);
    procedure RememberFrame(const ASource: TBytes; const AColors: array of Cardinal);
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
        or (Length(FLayers[LIndex].Detail.Pixels) <> Length(FLastDetails[LIndex])) then
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
  if (not FLastValid) or (not CompareMem(@AColors[0], @FLastColors[0], SizeOf(FLastColors))) or (not SameLayers) then
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
    FLayers[LIndex].Before := nil;
    FLayers[LIndex].After := nil;
    LDetail := FLayers[LIndex].Detail.Pixels;
    if Length(FLastDetails[LIndex]) <> Length(LDetail) then
      SetLength(FLastDetails[LIndex], Length(LDetail));
    if FComposedRows > 0 then
      Move(LDetail[0], FLastDetails[LIndex][0], Length(LDetail));
  end;
  FLastLayerCount := FLayerCount;
  FLastValid := True;
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
      for LIndex := 0 to FLayerCount - 1 do
        ComposeLayer(ABase, FLayers[LIndex], LColors);
    end;
    RememberFrame(LSource, LColors);
    Result := FDisplay.PresentTrueColor(FFrame, FDisplayWidth, FDisplayHeight);
  finally
    // the layers are of one frame: the widgets leave them again at every blit
    for LIndex := 0 to FLayerCount - 1 do
      FLayers[LIndex].Detail := nil;
    FLayerCount := 0;
    FOpenLayer := False;
  end;
end;

end.
