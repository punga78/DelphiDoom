{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the frames of a FLI movie                        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): fli_readframe,              }
{  fli_readcolors, fli_brun and fli_linecompression of playfli.pas              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.FliDecoder;

// the 6 bit colors times 4 and the line count of a chunk (a word) wrap around on purpose, as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils;

const
  /// <summary>SizeOf(fliheader_t), SizeOf(frameheader_t), SizeOf(chunktype_t)</summary>
  GREED_FLI_HEADER_BYTES = 128;
  GREED_FLI_FRAME_HEADER_BYTES = 16;
  GREED_FLI_CHUNK_HEADER_BYTES = 6;
  /// <summary>The magic of a frame</summary>
  GREED_FLI_FRAME_MAGIC = $F1FA;
  /// <summary>The chunks that the original knows; any other is read and ignored</summary>
  GREED_FLI_CHUNK_COLORS = 11;
  GREED_FLI_CHUNK_LINES = 12;
  GREED_FLI_CHUNK_CLEAR = 13;
  GREED_FLI_CHUNK_RUN = 15;
  GREED_FLI_CHUNK_COPY = 16;
  GREED_FLI_SCREEN_BYTES = 64000;
  GREED_FLI_PALETTE_BYTES = 768;

type
  /// <summary>
  ///   A FLI movie (Autodesk Animator, 320 x 200) read as playfli.pas reads it, one frame for each call, from
  ///   bytes in memory (a file, or a lump of the archive: the movie starts at AOffset). The header gives the number
  ///   of frames, the height (used by the "run" chunk) and the tics of a frame (Speed, 70 a second); its magic is
  ///   not checked. A frame is its header (magic F1FA) and its chunks, read one after the other: the size of the
  ///   frame is not used to find the next one. The pixels go in the buffer of the caller (the screen), where each
  ///   picture chunk turns every 0 into ApproxZero (I_TranslateBuffer on the whole buffer); a color chunk changes
  ///   Palette (8 bit values: the 6 bit ones times 4), sets PaletteChanged and makes ApproxZero again from it, as
  ///   I_SetPalette does.
  ///   Kept from the original: a color packet starts at the color it says, not after the one before (the FLI
  ///   format says the skips add up); the "run" chunk does not start each row at its first column; a chunk shorter
  ///   than what it says reads the bytes left in the buffer by the chunk before; FLC chunks (4, 7) are ignored.
  ///   Differences from the original: what would be written outside the screen or the palette is not written, a
  ///   chunk longer than 64000 bytes is read whole, the chunk buffer starts as zeroes, and a movie cut short is
  ///   EGreedDataException (MS_Error in the original)
  /// </summary>
  TGreedFliDecoder = class
  strict private
    FData: TBytes;
    FPosition: Integer;
    FFrameCount: Integer;
    FWidth: Integer;
    FHeight: Integer;
    FSpeed: Integer;
    FCurrentFrame: Integer;
    FChunk: TBytes;
    FChunkPosition: Integer;
    FPalette: TBytes;
    FPaletteChanged: Boolean;
    FApproxZero: Byte;
    function GetByte: Byte;
    function GetShortInt: ShortInt;
    function GetWord: Word;
    procedure NeedBytes(ACount: Integer; const AWhat: string);
    procedure ReadColors;
    procedure ReadRun(var APixels: TBytes);
    procedure ReadLines(var APixels: TBytes);
    class procedure Translate(var APixels: TBytes; AZero: Byte); static;
  public
    /// <summary>
    ///   APalette is flipal of the original, which a movie inherits from the one before: the array is changed in
    ///   place (nil: a new one, all zeroes). EGreedDataException if the 128 bytes of the header are not there
    /// </summary>
    constructor Create(const AData: TBytes; AOffset: Integer = 0; const APalette: TBytes = nil);
    /// <summary>
    ///   fli_readframe: False, and nothing is read, after the last frame. APixels must have 64000 bytes.
    ///   EGreedDataException for a wrong frame magic or a movie that ends inside a frame
    /// </summary>
    function DecodeFrame(var APixels: TBytes): Boolean;
    /// <summary>header.nframes, header.width, header.height, header.speed</summary>
    property FrameCount: Integer read FFrameCount;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Speed: Integer read FSpeed;
    /// <summary>The frames decoded so far</summary>
    property CurrentFrame: Integer read FCurrentFrame;
    /// <summary>flipal: 768 bytes</summary>
    property Palette: TBytes read FPalette;
    /// <summary>True after a frame with a color chunk; the caller clears it when it has shown the palette</summary>
    property PaletteChanged: Boolean read FPaletteChanged write FPaletteChanged;
    /// <summary>approx_zero: the caller gives the one of the screen; a color chunk changes it</summary>
    property ApproxZero: Byte read FApproxZero write FApproxZero;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.LittleEndian, DelphiDoom.Greed.PaletteFader;

const
  SGreedFliTooShort = 'Greed: the FLI movie ends inside %s (%d bytes at %d, the movie has %d)';
  SGreedFliFrameMagic = 'Greed: the frame %d of the FLI movie has the magic %.4x and not F1FA';
  SGreedFliScreen = 'Greed: the screen of a FLI movie has %d bytes, it needs %d';

{ TGreedFliDecoder }

constructor TGreedFliDecoder.Create(const AData: TBytes; AOffset: Integer; const APalette: TBytes);
begin
  inherited Create;
  FData := AData;
  FPosition := AOffset;
  if AOffset < 0 then
    raise EGreedDataException.CreateFmt(SGreedFliTooShort, ['the header', GREED_FLI_HEADER_BYTES, AOffset,
      Length(AData)]);
  NeedBytes(GREED_FLI_HEADER_BYTES, 'the header');
  FFrameCount := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 6));
  FWidth := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 8));
  FHeight := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 10));
  FSpeed := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 16));
  Inc(FPosition, GREED_FLI_HEADER_BYTES);
  SetLength(FChunk, GREED_FLI_SCREEN_BYTES);
  if Length(APalette) >= GREED_FLI_PALETTE_BYTES then
    FPalette := APalette
  else
    SetLength(FPalette, GREED_FLI_PALETTE_BYTES);
end;

procedure TGreedFliDecoder.NeedBytes(ACount: Integer; const AWhat: string);
begin
  if (ACount < 0) or (Int64(FPosition) + ACount > Length(FData)) then
    raise EGreedDataException.CreateFmt(SGreedFliTooShort, [AWhat, ACount, FPosition, Length(FData)]);
end;

function TGreedFliDecoder.GetByte: Byte;
begin
  if FChunkPosition < Length(FChunk) then
    Result := FChunk[FChunkPosition]
  else
    Result := 0;
  Inc(FChunkPosition);
end;

function TGreedFliDecoder.GetShortInt: ShortInt;
begin
  Result := ShortInt(GetByte);
end;

function TGreedFliDecoder.GetWord: Word;
var
  LLow: Byte;
begin
  LLow := GetByte;
  Result := LLow + (GetByte shl 8);
end;

procedure TGreedFliDecoder.ReadColors;
var
  LPackets: Integer;
  LPacket: Integer;
  LSkip: Integer;
  LTotal: Integer;
  LIndex: Integer;
  LDest: Integer;
  LValue: Byte;
begin
  LPackets := GetWord;
  for LPacket := 0 to LPackets - 1 do
  begin
    LSkip := GetByte;
    LTotal := GetByte;
    if LTotal = 0 then
      LTotal := 256;
    LDest := LSkip * 3;
    for LIndex := 0 to LTotal * 3 - 1 do
    begin
      LValue := Byte(GetByte * 4);
      if LDest < GREED_FLI_PALETTE_BYTES then
        FPalette[LDest] := LValue;
      Inc(LDest);
    end;
  end;
  // I_SetPalette(@flipal)
  FPaletteChanged := True;
  FApproxZero := TGreedPaletteFader.ApproximateZero(FPalette);
end;

procedure TGreedFliDecoder.ReadRun(var APixels: TBytes);
var
  LRow: Integer;
  LPackets: Integer;
  LPacket: Integer;
  LCount: Integer;
  LIndex: Integer;
  LData: Byte;
  LDest: Integer;
begin
  // line := @viewbuffer[0] once: the rows follow each other wherever the packets of the row before ended
  LDest := 0;
  for LRow := 0 to FHeight - 1 do
  begin
    LPackets := GetByte;
    for LPacket := 0 to LPackets - 1 do
    begin
      LCount := GetShortInt;
      if LCount < 0 then
      begin
        for LIndex := 0 to -LCount - 1 do
        begin
          LData := GetByte;
          if LDest < GREED_FLI_SCREEN_BYTES then
            APixels[LDest] := LData;
          Inc(LDest);
        end;
      end
      else
      begin
        LData := GetByte;
        for LIndex := 0 to LCount - 1 do
        begin
          if LDest < GREED_FLI_SCREEN_BYTES then
            APixels[LDest] := LData;
          Inc(LDest);
        end;
      end;
    end;
  end;
end;

procedure TGreedFliDecoder.ReadLines(var APixels: TBytes);
var
  LRow: Word;
  LLast: Word;
  LPackets: Integer;
  LPacket: Integer;
  LCount: Integer;
  LIndex: Integer;
  LData: Byte;
  LDest: Integer;
begin
  LRow := GetWord;
  LLast := GetWord;
  LLast := Word(LLast + LRow);
  while LRow < LLast do
  begin
    // ylookup[y]: a row after the last one is not a place of the screen, nothing is drawn there
    LDest := LRow * 320;
    LPackets := GetByte;
    for LPacket := 0 to LPackets - 1 do
    begin
      LDest := LDest + GetByte;
      LCount := GetShortInt;
      if LCount < 0 then
      begin
        LData := GetByte;
        for LIndex := 0 to -LCount - 1 do
        begin
          if LDest < GREED_FLI_SCREEN_BYTES then
            APixels[LDest] := LData;
          Inc(LDest);
        end;
      end
      else
        for LIndex := 0 to LCount - 1 do
        begin
          LData := GetByte;
          if LDest < GREED_FLI_SCREEN_BYTES then
            APixels[LDest] := LData;
          Inc(LDest);
        end;
    end;
    Inc(LRow);
  end;
end;

class procedure TGreedFliDecoder.Translate(var APixels: TBytes; AZero: Byte);
var
  LIndex: Integer;
begin
  for LIndex := 0 to GREED_FLI_SCREEN_BYTES - 1 do
    if APixels[LIndex] = 0 then
      APixels[LIndex] := AZero;
end;

function TGreedFliDecoder.DecodeFrame(var APixels: TBytes): Boolean;
var
  LSize: Integer;
  LMagic: Integer;
  LChunks: Integer;
  LChunk: Integer;
  LChunkSize: Integer;
  LChunkType: Integer;
begin
  Result := FCurrentFrame < FFrameCount;
  if not Result then
    Exit;
  if Length(APixels) < GREED_FLI_SCREEN_BYTES then
    raise EGreedException.CreateFmt(SGreedFliScreen, [Length(APixels), GREED_FLI_SCREEN_BYTES]);
  NeedBytes(GREED_FLI_FRAME_HEADER_BYTES, 'the header of a frame');
  LSize := TGreedLittleEndian.ReadInt32(FData, FPosition);
  LMagic := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 4));
  LChunks := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 6));
  Inc(FPosition, GREED_FLI_FRAME_HEADER_BYTES);
  if LMagic <> GREED_FLI_FRAME_MAGIC then
    raise EGreedDataException.CreateFmt(SGreedFliFrameMagic, [FCurrentFrame, LMagic]);
  Inc(FCurrentFrame);
  // an empty frame: the picture of before stays
  if LSize = 0 then
    Exit;
  for LChunk := 0 to LChunks - 1 do
  begin
    NeedBytes(GREED_FLI_CHUNK_HEADER_BYTES, 'the header of a chunk');
    LChunkSize := TGreedLittleEndian.ReadInt32(FData, FPosition) - GREED_FLI_CHUNK_HEADER_BYTES;
    LChunkType := Word(TGreedLittleEndian.ReadSmallInt(FData, FPosition + 4));
    Inc(FPosition, GREED_FLI_CHUNK_HEADER_BYTES);
    NeedBytes(LChunkSize, 'a chunk');
    if LChunkSize > Length(FChunk) then
      SetLength(FChunk, LChunkSize);
    if LChunkSize > 0 then
      Move(FData[FPosition], FChunk[0], LChunkSize);
    Inc(FPosition, LChunkSize);
    FChunkPosition := 0;
    case LChunkType of
      GREED_FLI_CHUNK_LINES:
        begin
          ReadLines(APixels);
          Translate(APixels, FApproxZero);
        end;
      GREED_FLI_CHUNK_RUN:
        begin
          ReadRun(APixels);
          Translate(APixels, FApproxZero);
        end;
      GREED_FLI_CHUNK_COPY:
        begin
          Move(FChunk[0], APixels[0], GREED_FLI_SCREEN_BYTES);
          Translate(APixels, FApproxZero);
        end;
      GREED_FLI_CHUNK_COLORS:
        ReadColors;
      GREED_FLI_CHUNK_CLEAR:
        FillChar(APixels[0], GREED_FLI_SCREEN_BYTES, FApproxZero);
    end;
  end;
end;

end.
