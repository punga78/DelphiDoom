{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the double buffered drawing of the menus, the     }
{  proportional font and the cursor                                             }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  VWB_*, VW_InitDoubleBuffer, VW_FixRefreshBuffer, VW_UpdateScreen and the      }
{  cursor of id_vw.c; VW_DrawPropString, ShiftPropChar and BufferToScreen of    }
{  id_vw_ae.asm                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.BufferedVideo;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.Font;

type
  /// <summary>
  ///   The drawing of the windows and of the menus. Everything is drawn on the buffer page of the video manager
  ///   and marks the tiles that it touches in the update array of the refresh manager; UpdateScreen copies those
  ///   tiles to the page that is shown. A string is put together bit by bit in a buffer (each character shifted
  ///   to its place) and then XORed to the planes of the font color: over a white window the color F_BLACK (15)
  ///   gives black
  /// </summary>
  TKeenBufferedVideo = class(TInterfacedObject, IKeenBufferedVideo)
  strict private
    FVideo: IKeenVideo;
    FBlocks: IKeenUpdateBlocks;
    FGraphics: IKeenGraphics;
    FSprites: IKeenSpriteCache;
    FClock: IKeenClock;
    FFont: TKeenFont;
    FPx: Integer;
    FPy: Integer;
    FFontColor: Integer;
    FBufferWidth: Integer;
    FBufferHeight: Integer;
    FCursorVisible: Integer;
    FCursorNumber: Integer;
    FCursorWidth: Integer;
    FCursorHeight: Integer;
    FCursorX: Integer;
    FCursorY: Integer;
    FCursorSave: TBytes;
    FCursorSpot: Integer;
    FUpdateHook: TProc;
    function Font: TKeenFont;
    procedure DrawPropString(const AText: AnsiString);
    procedure DrawCursor;
    procedure EraseCursor;
  public
    /// <param name="AVideo">The video manager; the drawings go to its buffer page</param>
    /// <param name="ABlocks">The update array (the refresh manager)</param>
    /// <param name="AGraphics">The font (the chunk STARTFONT) and the tables of the pictures</param>
    /// <param name="ASprites">The sprites (the cursor)</param>
    /// <param name="AClock">TimeCount, for WaitVBL</param>
    constructor Create(const AVideo: IKeenVideo; const ABlocks: IKeenUpdateBlocks; const AGraphics: IKeenGraphics;
      const ASprites: IKeenSpriteCache; const AClock: IKeenClock);
    destructor Destroy; override;
    function GetVideo: IKeenVideo;
    function GetPx: Integer;
    procedure SetPx(AValue: Integer);
    function GetPy: Integer;
    procedure SetPy(AValue: Integer);
    function GetFontColor: Integer;
    procedure SetFontColor(AValue: Integer);
    procedure MeasureString(const AText: AnsiString; out AWidth, AHeight: Integer);
    procedure DrawString(const AText: AnsiString);
    procedure Bar(AX, AY, AWidth, AHeight, AColor: Integer);
    procedure Plot(AX, AY, AColor: Integer);
    procedure Hlin(AX1, AX2, AY, AColor: Integer);
    procedure Vlin(AY1, AY2, AX, AColor: Integer);
    procedure DrawTile8(AX, AY, ATile: Integer);
    procedure DrawTile8Masked(AX, AY, ATile: Integer);
    procedure DrawPic(AX, AY, AChunk: Integer);
    procedure DrawMaskedPic(AX, AY, AChunk: Integer);
    procedure DrawSprite(AX, AY, AChunk: Integer);
    procedure InitDoubleBuffer;
    procedure FixRefreshBuffer;
    procedure UpdateScreen;
    procedure SetCursor(ASpriteChunk: Integer);
    procedure ShowCursor;
    procedure HideCursor;
    procedure MoveCursor(AX, AY: Integer);
    function MarkUpdateBlock(AX1, AY1, AX2, AY2: Integer): Boolean;
    procedure WaitVBL(ACount: Integer);
    procedure SetUpdateHook(const AHook: TProc);
  end;

implementation

uses
  DelphiDoom.Keen.Arithmetic, DelphiDoom.Keen.SpriteShifter;

const
  SCREENXMASK = not 7;
  SCREENXDIV = 8;

{ TKeenBufferedVideo }

constructor TKeenBufferedVideo.Create(const AVideo: IKeenVideo; const ABlocks: IKeenUpdateBlocks;
  const AGraphics: IKeenGraphics; const ASprites: IKeenSpriteCache; const AClock: IKeenClock);
begin
  inherited Create;
  if not Assigned(AVideo) then
    raise EArgumentNilException.Create('AVideo');
  if not Assigned(ABlocks) then
    raise EArgumentNilException.Create('ABlocks');
  if not Assigned(AGraphics) then
    raise EArgumentNilException.Create('AGraphics');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FVideo := AVideo;
  FBlocks := ABlocks;
  FGraphics := AGraphics;
  FSprites := ASprites;
  FClock := AClock;
  FFontColor := KEEN_WHITE;
end;

destructor TKeenBufferedVideo.Destroy;
begin
  FFont.Free;
  inherited Destroy;
end;

function TKeenBufferedVideo.Font: TKeenFont;
begin
  if not Assigned(FFont) then
    FFont := TKeenFont.Create(FGraphics.Chunks.Read(KEEN_STARTFONT));
  Result := FFont;
end;

function TKeenBufferedVideo.GetVideo: IKeenVideo;
begin
  Result := FVideo;
end;

function TKeenBufferedVideo.GetPx: Integer;
begin
  Result := FPx;
end;

procedure TKeenBufferedVideo.SetPx(AValue: Integer);
begin
  FPx := AValue and $FFFF;
end;

function TKeenBufferedVideo.GetPy: Integer;
begin
  Result := FPy;
end;

procedure TKeenBufferedVideo.SetPy(AValue: Integer);
begin
  FPy := AValue and $FFFF;
end;

function TKeenBufferedVideo.GetFontColor: Integer;
begin
  Result := FFontColor;
end;

procedure TKeenBufferedVideo.SetFontColor(AValue: Integer);
begin
  FFontColor := AValue and 15;
end;

procedure TKeenBufferedVideo.MeasureString(const AText: AnsiString; out AWidth, AHeight: Integer);
begin
  AHeight := Font.Height;
  AWidth := Font.Measure(AText) and $FFFF;
end;

procedure TKeenBufferedVideo.DrawPropString(const AText: AnsiString);
var
  LBuffer: array[0..KEEN_FONT_MAX_HEIGHT - 1, 0..KEEN_FONT_BUFFER_WIDTH - 1] of Byte;
  LFont: TKeenFont;
  LBufferBit: Integer;
  LBufferByte: Integer;
  LIndex: Integer;
  LCharacter: Byte;
  LWidth: Integer;
  LWide: Integer;
  LRow: Integer;
  LColumn: Integer;
  LShifted: Word;
  LSpot: Integer;
  LDest: Integer;
  LPlane: Integer;
  LMemory: IKeenEgaMemory;
begin
  LFont := Font;
  FillChar(LBuffer, SizeOf(LBuffer), 0);
  // shift the characters into the buffer: the first byte of a character is ORed with what the one before left
  // there, the next byte is replaced
  LBufferBit := FPx and 7;
  LBufferByte := 0;
  for LIndex := 1 to Length(AText) do
  begin
    LCharacter := Ord(AText[LIndex]);
    if LCharacter = 0 then
      Break;
    LWidth := LFont.CharWidth(LCharacter);
    LWide := (LWidth + 7) div 8;
    // the C has routines for characters of one, two and three bytes; a wider one would jump to nothing
    if LWide > 3 then
      LWide := 3;
    if LBufferByte + LWide >= KEEN_FONT_BUFFER_WIDTH then
      raise EKeenException.CreateFmt(SKeenStringTooWide, [LBufferByte + LWide + 1, KEEN_FONT_BUFFER_WIDTH]);
    for LRow := 0 to LFont.Height - 1 do
      for LColumn := 0 to LWide - 1 do
      begin
        LShifted := TKeenSpriteShifter.ShiftWord(LFont.RowByte(LCharacter, LRow, LColumn), LBufferBit);
        LBuffer[LRow, LBufferByte + LColumn] := LBuffer[LRow, LBufferByte + LColumn] or Byte(LShifted);
        LBuffer[LRow, LBufferByte + LColumn + 1] := Byte(LShifted shr 8);
      end;
    Inc(LBufferBit, LWidth);
    Inc(LBufferByte, LBufferBit shr 3);
    LBufferBit := LBufferBit and 7;
  end;
  // where the buffer goes on the screen
  LSpot := (FVideo.YLookup(FPy) + FVideo.BufferOfs + FVideo.PanAdjust + (FPx shr 3)) and $FFFF;
  // px moves by the whole position in the buffer, the bits before the first character too (as the assembler does)
  FPx := (FPx + ((LBufferByte shl 3) or LBufferBit)) and $FFFF;
  FBufferWidth := LBufferByte;
  if LBufferBit <> 0 then
    Inc(FBufferWidth);
  FBufferHeight := LFont.Height;
  // BufferToScreen with the data rotate register on XOR and the map mask on the color
  LMemory := FVideo.Memory;
  for LRow := 0 to FBufferHeight - 1 do
  begin
    LDest := (LSpot + LRow * FVideo.LineWidth) and $FFFF;
    for LColumn := 0 to FBufferWidth - 1 do
      if LBuffer[LRow, LColumn] <> 0 then
        for LPlane := 0 to KEEN_EGA_PLANES - 1 do
          if (FFontColor and (1 shl LPlane)) <> 0 then
            LMemory.WriteByte(LPlane, (LDest + LColumn) and $FFFF,
              LMemory.ReadByte(LPlane, (LDest + LColumn) and $FFFF) xor LBuffer[LRow, LColumn]);
  end;
end;

procedure TKeenBufferedVideo.DrawString(const AText: AnsiString);
var
  LX: Integer;
  LY: Integer;
begin
  LX := FPx + FVideo.PanSX;
  LY := FPy + FVideo.PanSY;
  DrawPropString(AText);
  FBlocks.MarkUpdateBlock(LX, LY, LX + FBufferWidth * 8 - 1, LY + FBufferHeight - 1);
end;

function TKeenBufferedVideo.MarkUpdateBlock(AX1, AY1, AX2, AY2: Integer): Boolean;
begin
  Result := FBlocks.MarkUpdateBlock(AX1, AY1, AX2, AY2);
end;

procedure TKeenBufferedVideo.Bar(AX, AY, AWidth, AHeight, AColor: Integer);
begin
  Inc(AX, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  if FBlocks.MarkUpdateBlock(AX, AY, AX + AWidth, AY + AHeight - 1) then
    FVideo.Bar(AX, AY, AWidth, AHeight, AColor);
end;

procedure TKeenBufferedVideo.Plot(AX, AY, AColor: Integer);
begin
  Inc(AX, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  if FBlocks.MarkUpdateBlock(AX, AY, AX, AY) then
    FVideo.Plot(AX, AY, AColor);
end;

procedure TKeenBufferedVideo.Hlin(AX1, AX2, AY, AColor: Integer);
begin
  Inc(AX1, FVideo.PanSX);
  Inc(AX2, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  if FBlocks.MarkUpdateBlock(AX1, AY, AX2, AY) then
    FVideo.Hlin(AX1, AX2, AY, AColor);
end;

procedure TKeenBufferedVideo.Vlin(AY1, AY2, AX, AColor: Integer);
begin
  Inc(AX, FVideo.PanSX);
  Inc(AY1, FVideo.PanSY);
  Inc(AY2, FVideo.PanSY);
  if FBlocks.MarkUpdateBlock(AX, AY1, AX, AY2) then
    FVideo.Vlin(AY1, AY2, AX, AColor);
end;

procedure TKeenBufferedVideo.DrawTile8(AX, AY, ATile: Integer);
begin
  Inc(AX, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  if FBlocks.MarkUpdateBlock(AX and SCREENXMASK, AY, (AX and SCREENXMASK) + 7, AY + 7) then
    FVideo.DrawTile8(AX div SCREENXDIV, AY, ATile);
end;

procedure TKeenBufferedVideo.DrawTile8Masked(AX, AY, ATile: Integer);
begin
  Inc(AX, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  if FBlocks.MarkUpdateBlock(AX and SCREENXMASK, AY, (AX and SCREENXMASK) + 7, AY + 7) then
    FVideo.DrawTile8Masked(AX div SCREENXDIV, AY, ATile);
end;

procedure TKeenBufferedVideo.DrawPic(AX, AY, AChunk: Integer);
var
  LPicture: Integer;
  LTable: TArray<TKeenPictureEntry>;
begin
  LPicture := AChunk - KEEN_STARTPICS;
  LTable := FGraphics.PictureTable;
  if (LPicture < 0) or (LPicture >= Length(LTable)) then
    raise EKeenDataException.CreateFmt(SKeenPictureInvalid, [LPicture, Length(LTable)]);
  Inc(AX, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  AX := AX div SCREENXDIV;
  if FBlocks.MarkUpdateBlock(AX * SCREENXDIV, AY, (AX + LTable[LPicture].Width) * SCREENXDIV - 1,
    AY + LTable[LPicture].Height - 1) then
    FVideo.DrawPic(AX, AY, AChunk);
end;

procedure TKeenBufferedVideo.DrawMaskedPic(AX, AY, AChunk: Integer);
var
  LPicture: Integer;
  LTable: TArray<TKeenPictureEntry>;
begin
  LPicture := AChunk - KEEN_STARTPICM;
  LTable := FGraphics.MaskedPictureTable;
  if (LPicture < 0) or (LPicture >= Length(LTable)) then
    raise EKeenDataException.CreateFmt(SKeenPictureInvalid, [LPicture, Length(LTable)]);
  Inc(AX, FVideo.PanSX);
  Inc(AY, FVideo.PanSY);
  AX := AX div SCREENXDIV;
  if FBlocks.MarkUpdateBlock(AX * SCREENXDIV, AY, (AX + LTable[LPicture].Width) * SCREENXDIV - 1,
    AY + LTable[LPicture].Height - 1) then
    FVideo.DrawMaskedPic(AX, AY, AChunk);
end;

procedure TKeenBufferedVideo.DrawSprite(AX, AY, AChunk: Integer);
var
  LEntry: TKeenSpriteEntry;
  LSprite: TKeenSprite;
  LShift: Integer;
  LX: Integer;
  LY: Integer;
begin
  if not Assigned(FSprites) then
    raise EKeenException.CreateFmt(SKeenVideoNoGraphics, ['a sprite']);
  LEntry := FSprites.GetEntry(AChunk);
  LSprite := FSprites.GetSprite(AChunk);
  // the same place that VW_DrawSprite works out: the mark needs the width of the shifted copy
  LX := AX + FVideo.PanSX + TKeenArithmetic.ShiftRight(LEntry.OriginX, 4);
  LY := AY + FVideo.PanSY + TKeenArithmetic.ShiftRight(LEntry.OriginY, 4);
  LShift := (LX and 7) div 2;
  if FBlocks.MarkUpdateBlock(LX and SCREENXMASK, LY, (LX and SCREENXMASK) + LSprite.Width[LShift] * SCREENXDIV - 1,
    LY + LEntry.Height - 1) then
    FVideo.DrawSprite(AX + FVideo.PanSX, AY + FVideo.PanSY, AChunk);
end;

procedure TKeenBufferedVideo.InitDoubleBuffer;
begin
  FVideo.SetScreen(FVideo.DisplayOfs + FVideo.PanAdjust, 0);
end;

procedure TKeenBufferedVideo.FixRefreshBuffer;
begin
  FVideo.ScreenToScreen(FVideo.DisplayOfs, FVideo.BufferOfs, KEEN_PORTTILESWIDE * 4 * 2, KEEN_PORTTILESHIGH * 16);
end;

procedure TKeenBufferedVideo.DrawCursor;
begin
  if FCursorNumber = 0 then
    raise EKeenException.Create(SKeenCursorNotSet);
  FCursorSpot := (FVideo.BufferOfs + FVideo.YLookup(FCursorY + FVideo.PanSY) +
    (FCursorX + FVideo.PanSX) div SCREENXDIV) and $FFFF;
  FCursorSave := FVideo.ScreenToMem(FCursorSpot, FCursorWidth, FCursorHeight);
  DrawSprite(FCursorX, FCursorY, FCursorNumber);
end;

procedure TKeenBufferedVideo.EraseCursor;
begin
  FVideo.MemToScreen(FCursorSave, FCursorSpot, FCursorWidth, FCursorHeight);
  FBlocks.MarkUpdateBlock((FCursorX + FVideo.PanSX) and SCREENXMASK, FCursorY + FVideo.PanSY,
    ((FCursorX + FVideo.PanSX) and SCREENXMASK) + FCursorWidth * SCREENXDIV - 1,
    FCursorY + FVideo.PanSY + FCursorHeight - 1);
end;

procedure TKeenBufferedVideo.UpdateScreen;
begin
  if FCursorVisible > 0 then
    DrawCursor;
  FBlocks.UpdateScreenBlocks;
  // the start of the display, without the pel panning (the C writes only the start address of the CRTC)
  FVideo.SetScreen(FVideo.DisplayOfs + FVideo.PanAdjust, FVideo.PelPan);
  if FCursorVisible > 0 then
    EraseCursor;
  if Assigned(FUpdateHook) then
    FUpdateHook();
end;

procedure TKeenBufferedVideo.SetCursor(ASpriteChunk: Integer);
var
  LEntry: TKeenSpriteEntry;
begin
  if not Assigned(FSprites) then
    raise EKeenException.CreateFmt(SKeenVideoNoGraphics, ['a sprite']);
  LEntry := FSprites.GetEntry(ASpriteChunk);
  FCursorNumber := ASpriteChunk;
  FCursorWidth := LEntry.Width + 1;
  FCursorHeight := LEntry.Height;
end;

procedure TKeenBufferedVideo.ShowCursor;
begin
  Inc(FCursorVisible);
end;

procedure TKeenBufferedVideo.HideCursor;
begin
  Dec(FCursorVisible);
end;

procedure TKeenBufferedVideo.MoveCursor(AX, AY: Integer);
begin
  FCursorX := AX;
  FCursorY := AY;
end;

procedure TKeenBufferedVideo.WaitVBL(ACount: Integer);
var
  LEnd: Integer;
begin
  LEnd := FClock.TimeCount + ACount;
  while FClock.TimeCount < LEnd do
    FClock.Idle;
end;

procedure TKeenBufferedVideo.SetUpdateHook(const AHook: TProc);
begin
  FUpdateHook := AHook;
end;

end.
