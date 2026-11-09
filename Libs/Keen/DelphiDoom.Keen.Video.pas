{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the video manager of the EGA                      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  id_vw.c and id_vw_ae.asm                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Video;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The drawing routines of the game on the video memory. Every operation does what the routine of the C does
  ///   to the planes with the write mode and the bit mask that it sets: the coordinates and the offsets are
  ///   16 bit and wrap at 64 KB, a blit is done row after row and byte after byte in the order of the assembler
  ///   (the blocks of the screen copy can overlap). What is not here: the double buffer of the menus
  ///   (VW_MarkUpdateBlock, VW_UpdateScreen), the proportional fonts, the cursor, the fades, the video card
  ///   detection and the CGA code: they come with the user interface of the game
  /// </summary>
  TKeenVideo = class(TInterfacedObject, IKeenVideo)
  strict private
    FMemory: IKeenEgaMemory;
    FGraphics: IKeenGraphics;
    FSprites: IKeenSpriteCache;
    FPictures: TArray<TKeenPictureEntry>;
    FMaskedPictures: TArray<TKeenPictureEntry>;
    FLineWidth: Integer;
    FYLookup: array[0..KEEN_VIRTUALHEIGHT - 1] of Integer;
    FBufferOfs: Integer;
    FDisplayOfs: Integer;
    FPanX: Integer;
    FPanY: Integer;
    FPanSX: Integer;
    FPanSY: Integer;
    FPanAdjust: Integer;
    FCrtcStart: Integer;
    FPelPan: Integer;
    function RequireGraphics(const AWhat: string): IKeenGraphics;
    procedure WritePixels(AOffset: Integer; AMask: Byte; AColor: Integer);
    class function LeftMask(AX: Integer): Byte; static;
    class function RightMask(AX: Integer): Byte; static;
  public
    /// <param name="AMemory">The video memory that the routines draw in</param>
    /// <param name="AGraphics">The tiles and the pictures; nil is a video manager that only draws blocks and pixels</param>
    /// <param name="ASprites">The sprites with their shifts; nil if the game draws none</param>
    constructor Create(const AMemory: IKeenEgaMemory; const AGraphics: IKeenGraphics;
      const ASprites: IKeenSpriteCache);
    function GetMemory: IKeenEgaMemory;
    function GetLineWidth: Integer;
    function GetBufferOfs: Integer;
    procedure SetBufferOfs(AValue: Integer);
    function GetDisplayOfs: Integer;
    procedure SetDisplayOfs(AValue: Integer);
    function GetPanX: Integer;
    procedure SetPanX(AValue: Integer);
    function GetPanY: Integer;
    procedure SetPanY(AValue: Integer);
    function GetPanSX: Integer;
    procedure SetPanSX(AValue: Integer);
    function GetPanSY: Integer;
    procedure SetPanSY(AValue: Integer);
    function GetPanAdjust: Integer;
    procedure SetPanAdjust(AValue: Integer);
    function GetCrtcStart: Integer;
    function GetPelPan: Integer;
    procedure SetLineWidth(AWidth: Integer);
    function YLookup(ARow: Integer): Integer;
    procedure SetScreen(ACrtc, APelPan: Integer);
    procedure ClearVideo(AColor: Integer);
    procedure Plot(AX, AY, AColor: Integer);
    procedure Hlin(AXLow, AXHigh, AY, AColor: Integer);
    procedure Vlin(AYLow, AYHigh, AX, AColor: Integer);
    procedure Bar(AX, AY, AWidth, AHeight, AColor: Integer);
    procedure MaskBlock(const AData: TBytes; AOffset, ADest, AWide, AHeight, APlaneSize: Integer);
    procedure MemToScreen(const ASource: TBytes; ADest, AWide, AHeight: Integer);
    function ScreenToMem(ASource, AWide, AHeight: Integer): TBytes;
    procedure ScreenToScreen(ASource, ADest, AWide, AHeight: Integer);
    procedure DrawTile8(AX, AY, ATile: Integer);
    procedure DrawTile8Masked(AX, AY, ATile: Integer);
    procedure DrawTile16(AX, AY, ATile: Integer);
    procedure DrawTile16Masked(AX, AY, ATile: Integer);
    procedure DrawPic(AX, AY, AChunk: Integer);
    procedure DrawMaskedPic(AX, AY, AChunk: Integer);
    procedure DrawSprite(AX, AY, AChunk: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.Arithmetic;

const
  // leftmask and rightmask of id_vw.c: the pixels of a byte from the x (left) or up to the x (right)
  LEFT_MASKS: array[0..7] of Byte = ($FF, $7F, $3F, $1F, $0F, $07, $03, $01);
  RIGHT_MASKS: array[0..7] of Byte = ($80, $C0, $E0, $F0, $F8, $FC, $FE, $FF);

{ TKeenVideo }

constructor TKeenVideo.Create(const AMemory: IKeenEgaMemory; const AGraphics: IKeenGraphics;
  const ASprites: IKeenSpriteCache);
begin
  inherited Create;
  if not Assigned(AMemory) then
    raise EArgumentNilException.Create('AMemory');
  FMemory := AMemory;
  FGraphics := AGraphics;
  FSprites := ASprites;
  if Assigned(AGraphics) then
  begin
    FPictures := AGraphics.PictureTable;
    FMaskedPictures := AGraphics.MaskedPictureTable;
  end;
  SetLineWidth(KEEN_SCREENWIDTH);
end;

function TKeenVideo.RequireGraphics(const AWhat: string): IKeenGraphics;
begin
  if not Assigned(FGraphics) then
    raise EKeenException.CreateFmt(SKeenVideoNoGraphics, [AWhat]);
  Result := FGraphics;
end;

function TKeenVideo.GetMemory: IKeenEgaMemory;
begin
  Result := FMemory;
end;

function TKeenVideo.GetLineWidth: Integer;
begin
  Result := FLineWidth;
end;

function TKeenVideo.GetBufferOfs: Integer;
begin
  Result := FBufferOfs;
end;

procedure TKeenVideo.SetBufferOfs(AValue: Integer);
begin
  FBufferOfs := AValue and $FFFF;
end;

function TKeenVideo.GetDisplayOfs: Integer;
begin
  Result := FDisplayOfs;
end;

procedure TKeenVideo.SetDisplayOfs(AValue: Integer);
begin
  FDisplayOfs := AValue and $FFFF;
end;

function TKeenVideo.GetPanX: Integer;
begin
  Result := FPanX;
end;

procedure TKeenVideo.SetPanX(AValue: Integer);
begin
  FPanX := AValue and $FFFF;
end;

function TKeenVideo.GetPanY: Integer;
begin
  Result := FPanY;
end;

procedure TKeenVideo.SetPanY(AValue: Integer);
begin
  FPanY := AValue and $FFFF;
end;

function TKeenVideo.GetPanSX: Integer;
begin
  Result := FPanSX;
end;

procedure TKeenVideo.SetPanSX(AValue: Integer);
begin
  FPanSX := AValue and $FFFF;
end;

function TKeenVideo.GetPanSY: Integer;
begin
  Result := FPanSY;
end;

procedure TKeenVideo.SetPanSY(AValue: Integer);
begin
  FPanSY := AValue and $FFFF;
end;

function TKeenVideo.GetPanAdjust: Integer;
begin
  Result := FPanAdjust;
end;

procedure TKeenVideo.SetPanAdjust(AValue: Integer);
begin
  FPanAdjust := AValue and $FFFF;
end;

function TKeenVideo.GetCrtcStart: Integer;
begin
  Result := FCrtcStart;
end;

function TKeenVideo.GetPelPan: Integer;
begin
  Result := FPelPan;
end;

procedure TKeenVideo.SetLineWidth(AWidth: Integer);
var
  LRow: Integer;
  LOffset: Integer;
begin
  FLineWidth := AWidth;
  LOffset := 0;
  for LRow := 0 to KEEN_VIRTUALHEIGHT - 1 do
  begin
    FYLookup[LRow] := LOffset and $FFFF;
    Inc(LOffset, AWidth);
  end;
end;

function TKeenVideo.YLookup(ARow: Integer): Integer;
begin
  // the table of the C has VIRTUALHEIGHT rows and a row after them reads the next variable of the program
  if (ARow < 0) or (ARow >= KEEN_VIRTUALHEIGHT) then
    raise EKeenException.CreateFmt(SKeenVideoOutside, [ARow, KEEN_VIRTUALHEIGHT]);
  Result := FYLookup[ARow];
end;

procedure TKeenVideo.SetScreen(ACrtc, APelPan: Integer);
begin
  FCrtcStart := ACrtc and $FFFF;
  FPelPan := APelPan and 7;
end;

procedure TKeenVideo.ClearVideo(AColor: Integer);
begin
  FMemory.Fill(Byte(AColor));
end;

procedure TKeenVideo.WritePixels(AOffset: Integer; AMask: Byte; AColor: Integer);
var
  LPlane: Integer;
  LOld: Byte;
begin
  // write mode 2 with a bit mask: the pixels of the mask get the color, the others keep what the latches hold
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
  begin
    LOld := FMemory.ReadByte(LPlane, AOffset);
    LOld := LOld and not AMask;
    if ((AColor shr LPlane) and 1) <> 0 then
      LOld := LOld or AMask;
    FMemory.WriteByte(LPlane, AOffset, LOld);
  end;
end;

class function TKeenVideo.LeftMask(AX: Integer): Byte;
begin
  Result := LEFT_MASKS[AX and 7];
end;

class function TKeenVideo.RightMask(AX: Integer): Byte;
begin
  Result := RIGHT_MASKS[AX and 7];
end;

procedure TKeenVideo.Plot(AX, AY, AColor: Integer);
var
  LOffset: Integer;
begin
  LOffset := FBufferOfs + YLookup(AY) + (AX and $FFFF) div 8;
  WritePixels(LOffset, Byte($80 shr (AX and 7)), AColor);
end;

procedure TKeenVideo.Hlin(AXLow, AXHigh, AY, AColor: Integer);
var
  LLowByte: Integer;
  LHighByte: Integer;
  LMaskLeft: Byte;
  LMaskRight: Byte;
  LDest: Integer;
  LMiddle: Integer;
  LIndex: Integer;
begin
  AXLow := AXLow and $FFFF;
  AXHigh := AXHigh and $FFFF;
  LLowByte := AXLow div 8;
  LHighByte := AXHigh div 8;
  LMaskLeft := LeftMask(AXLow);
  LMaskRight := RightMask(AXHigh);
  LDest := FBufferOfs + YLookup(AY) + LLowByte;
  if LLowByte = LHighByte then
  begin
    // the whole line is in one byte
    WritePixels(LDest, LMaskLeft and LMaskRight, AColor);
    Exit;
  end;
  WritePixels(LDest, LMaskLeft, AColor);
  LMiddle := (LHighByte - LLowByte - 1) and $FFFF;
  for LIndex := 1 to LMiddle do
    WritePixels(LDest + LIndex, $FF, AColor);
  WritePixels(LDest + LMiddle + 1, LMaskRight, AColor);
end;

procedure TKeenVideo.Vlin(AYLow, AYHigh, AX, AColor: Integer);
var
  LRow: Integer;
  LByte: Integer;
  LMask: Byte;
begin
  LByte := FBufferOfs + YLookup(AYLow) + (AX and $FFFF) div 8;
  LMask := Byte($80 shr (AX and 7));
  // one row after the other by the width of a line, like the C does (not by ylookup)
  for LRow := AYLow to AYHigh do
  begin
    WritePixels(LByte, LMask, AColor);
    LByte := (LByte + FLineWidth) and $FFFF;
  end;
end;

procedure TKeenVideo.Bar(AX, AY, AWidth, AHeight, AColor: Integer);
var
  LXHigh: Integer;
  LLowByte: Integer;
  LHighByte: Integer;
  LMaskLeft: Byte;
  LMaskRight: Byte;
  LMiddle: Integer;
  LDest: Integer;
  LRow: Integer;
  LIndex: Integer;
begin
  AX := AX and $FFFF;
  LXHigh := (AX + AWidth - 1) and $FFFF;
  LLowByte := AX div 8;
  LHighByte := LXHigh div 8;
  LMaskLeft := LeftMask(AX);
  LMaskRight := RightMask(LXHigh);
  LMiddle := (LHighByte - LLowByte - 1) and $FFFF;
  LDest := FBufferOfs + YLookup(AY) + LLowByte;
  for LRow := 0 to AHeight - 1 do
  begin
    if LLowByte = LHighByte then
      WritePixels(LDest, LMaskLeft and LMaskRight, AColor)
    else
    begin
      WritePixels(LDest, LMaskLeft, AColor);
      for LIndex := 1 to LMiddle do
        WritePixels(LDest + LIndex, $FF, AColor);
      WritePixels(LDest + LMiddle + 1, LMaskRight, AColor);
    end;
    LDest := (LDest + FLineWidth) and $FFFF;
  end;
end;

procedure TKeenVideo.MaskBlock(const AData: TBytes; AOffset, ADest, AWide, AHeight, APlaneSize: Integer);
var
  LPlane: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LDest: Integer;
  LLineDelta: Integer;
  LMask: Byte;
  LData: Byte;
begin
  if (AWide <= 0) or (AHeight <= 0) then
    Exit;
  // the last byte read is the one of the last plane, at the end of the block
  if (AOffset < 0) or (Int64(AWide) * AHeight > APlaneSize) or
    (Int64(AOffset) + Int64(AWide) * AHeight + Int64(APlaneSize) * KEEN_EGA_PLANES > Length(AData)) then
    raise EKeenDataException.CreateFmt(SKeenSpriteTooShort,
      [Int64(AOffset) + Int64(AWide) * AHeight + Int64(APlaneSize) * KEEN_EGA_PLANES, Length(AData)]);
  LLineDelta := FLineWidth - AWide;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
  begin
    LSource := AOffset;
    LDest := ADest and $FFFF;
    for LRow := 0 to AHeight - 1 do
    begin
      for LColumn := 0 to AWide - 1 do
      begin
        LMask := AData[LSource];
        LData := AData[LSource + APlaneSize * (LPlane + 1)];
        FMemory.WriteByte(LPlane, LDest, (FMemory.ReadByte(LPlane, LDest) and LMask) or LData);
        Inc(LSource);
        LDest := (LDest + 1) and $FFFF;
      end;
      LDest := (LDest + LLineDelta) and $FFFF;
    end;
  end;
end;

procedure TKeenVideo.MemToScreen(const ASource: TBytes; ADest, AWide, AHeight: Integer);
var
  LPlane: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LDest: Integer;
begin
  if (AWide <= 0) or (AHeight <= 0) then
    Exit;
  if Int64(AWide) * AHeight * KEEN_EGA_PLANES > Length(ASource) then
    raise EKeenDataException.CreateFmt(SKeenPlanarTooShort,
      [Int64(AWide) * AHeight * KEEN_EGA_PLANES, Length(ASource)]);
  LSource := 0;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
  begin
    LDest := ADest and $FFFF;
    for LRow := 0 to AHeight - 1 do
    begin
      for LColumn := 0 to AWide - 1 do
      begin
        FMemory.WriteByte(LPlane, LDest + LColumn, ASource[LSource]);
        Inc(LSource);
      end;
      LDest := (LDest + FLineWidth) and $FFFF;
    end;
  end;
end;

function TKeenVideo.ScreenToMem(ASource, AWide, AHeight: Integer): TBytes;
var
  LPlane: Integer;
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LTarget: Integer;
begin
  if (AWide <= 0) or (AHeight <= 0) then
    Exit(nil);
  SetLength(Result, AWide * AHeight * KEEN_EGA_PLANES);
  LTarget := 0;
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
  begin
    LSource := ASource and $FFFF;
    for LRow := 0 to AHeight - 1 do
    begin
      for LColumn := 0 to AWide - 1 do
      begin
        Result[LTarget] := FMemory.ReadByte(LPlane, LSource + LColumn);
        Inc(LTarget);
      end;
      LSource := (LSource + FLineWidth) and $FFFF;
    end;
  end;
end;

procedure TKeenVideo.ScreenToScreen(ASource, ADest, AWide, AHeight: Integer);
var
  LRow: Integer;
  LColumn: Integer;
  LSource: Integer;
  LDest: Integer;
begin
  LSource := ASource and $FFFF;
  LDest := ADest and $FFFF;
  for LRow := 0 to AHeight - 1 do
  begin
    for LColumn := 0 to AWide - 1 do
      FMemory.CopyByte(LSource + LColumn, LDest + LColumn);
    LSource := (LSource + FLineWidth) and $FFFF;
    LDest := (LDest + FLineWidth) and $FFFF;
  end;
end;

procedure TKeenVideo.DrawTile8(AX, AY, ATile: Integer);
var
  LBytes: TBytes;
  LPlane: Integer;
  LRow: Integer;
  LDest: Integer;
begin
  LBytes := RequireGraphics('an 8x8 tile').Tile8(ATile);
  if Length(LBytes) < KEEN_TILE8_BYTES then
    Exit;
  LDest := FBufferOfs + AX + YLookup(AY);
  for LPlane := 0 to KEEN_EGA_PLANES - 1 do
    for LRow := 0 to 7 do
      FMemory.WriteByte(LPlane, LDest + LRow * FLineWidth, LBytes[LPlane * 8 + LRow]);
end;

procedure TKeenVideo.DrawTile8Masked(AX, AY, ATile: Integer);
begin
  MaskBlock(RequireGraphics('a masked 8x8 tile').Tile8Masked(ATile), 0, FBufferOfs + YLookup(AY) + AX, 1, 8, 8);
end;

procedure TKeenVideo.DrawTile16(AX, AY, ATile: Integer);
var
  LBytes: TBytes;
begin
  LBytes := RequireGraphics('a 16x16 tile').Tile16(ATile);
  if Length(LBytes) >= KEEN_TILE16_BYTES then
    MemToScreen(LBytes, FBufferOfs + YLookup(AY) + AX, 2, 16);
end;

procedure TKeenVideo.DrawTile16Masked(AX, AY, ATile: Integer);
var
  LBytes: TBytes;
begin
  LBytes := RequireGraphics('a masked 16x16 tile').Tile16Masked(ATile);
  if Length(LBytes) >= KEEN_TILE16M_BYTES then
    MaskBlock(LBytes, 0, FBufferOfs + YLookup(AY) + AX, 2, 16, 32);
end;

procedure TKeenVideo.DrawPic(AX, AY, AChunk: Integer);
var
  LPicture: Integer;
begin
  LPicture := AChunk - KEEN_STARTPICS;
  RequireGraphics('a picture');
  if (LPicture < 0) or (LPicture >= Length(FPictures)) then
    raise EKeenDataException.CreateFmt(SKeenPictureInvalid, [LPicture, Length(FPictures)]);
  MemToScreen(FGraphics.PicturePlanar(LPicture), YLookup(AY) + AX + FBufferOfs,
    FPictures[LPicture].Width, FPictures[LPicture].Height);
end;

procedure TKeenVideo.DrawMaskedPic(AX, AY, AChunk: Integer);
var
  LPicture: Integer;
  LWidth: Integer;
  LHeight: Integer;
begin
  LPicture := AChunk - KEEN_STARTPICM;
  RequireGraphics('a masked picture');
  if (LPicture < 0) or (LPicture >= Length(FMaskedPictures)) then
    raise EKeenDataException.CreateFmt(SKeenPictureInvalid, [LPicture, Length(FMaskedPictures)]);
  // VW_DrawMPic of the C takes the size from pictable (the table of the plain pictures): a mistake that
  // nothing in the game relies on (only VWB_DrawMPic is called, with picmtable); here it is picmtable
  LWidth := FMaskedPictures[LPicture].Width;
  LHeight := FMaskedPictures[LPicture].Height;
  MaskBlock(FGraphics.MaskedPicturePlanar(LPicture), 0, YLookup(AY) + AX + FBufferOfs, LWidth, LHeight,
    LWidth * LHeight);
end;

procedure TKeenVideo.DrawSprite(AX, AY, AChunk: Integer);
var
  LEntry: TKeenSpriteEntry;
  LSprite: TKeenSprite;
  LShift: Integer;
  LDest: Integer;
begin
  if not Assigned(FSprites) then
    raise EKeenException.CreateFmt(SKeenVideoNoGraphics, ['a sprite']);
  LEntry := FSprites.GetEntry(AChunk);
  LSprite := FSprites.GetSprite(AChunk);
  AY := AY + TKeenArithmetic.ShiftRight(LEntry.OriginY, 4);
  AX := AX + TKeenArithmetic.ShiftRight(LEntry.OriginX, 4);
  LShift := (AX and 7) div 2;
  LDest := FBufferOfs + YLookup(AY);
  if AX >= 0 then
    Inc(LDest, AX div 8)
  else
    Inc(LDest, (AX + 1) div 8);
  MaskBlock(LSprite.Data, LSprite.SourceOffset[LShift], LDest, LSprite.Width[LShift], LEntry.Height,
    LSprite.PlaneSize[LShift]);
end;

end.
