{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - encoders and files made in memory    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Builders;

{$Q-}{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.MemoryFiles;

const
  /// <summary>The RLEW tag of the files made here</summary>
  TEST_RLEW_TAG = $ABCD;
  /// <summary>8x8 tiles whose data the chunk of a made game has (the shareware has 40 of 72)</summary>
  TEST_TILE8_PRESENT = 40;
  /// <summary>Masked 8x8 tiles whose data the chunk has (30 of 36)</summary>
  TEST_TILE8M_PRESENT = 30;

type
  /// <summary>
  ///   A Huffman code with a dictionary in the format of the .KDR files (255 nodes, head 254, 1024 bytes), built
  ///   from random weights, and its encoder: the opposite of TKeenHuffman, written from the description of the C
  /// </summary>
  TTestHuffmanCode = class
  strict private
    FDictionary: TBytes;
    FCodes: array[0..255] of TArray<Byte>;
    procedure Walk(AValue: Integer; const ANodes: TArray<TKeenHuffNode>; APath: TArray<Byte>);
  public
    constructor Create(ASeed: Integer);
    /// <summary>The bits go into a byte from the lowest; the last byte is filled with zeros</summary>
    function Encode(const AData: TBytes): TBytes;
    property Dictionary: TBytes read FDictionary;
  end;

  /// <summary>The run length encoding of words, as CA_RLEWCompress does it</summary>
  TTestRlewEncoder = class
  public
    class function Encode(const AWords: TArray<Word>; ATag: Word): TBytes; static;
    class function WordsToBytes(const AWords: TArray<Word>): TBytes; static;
  end;

  /// <summary>A file of chunks: the compressed bytes of each, and the offsets that go in front of them</summary>
  TTestChunkFile = class
  strict private
    FChunks: TArray<TBytes>;
    FPresent: TArray<Boolean>;
  public
    constructor Create(AChunkCount: Integer);
    procedure SetChunk(AIndex: Integer; const ACompressed: TBytes);
    /// <param name="ASparseMinusOne">The chunks that are not set get -1; if false they get the offset of the next chunk</param>
    procedure Build(ASparseMinusOne: Boolean; out AHeader, AData: TBytes);
  end;

  /// <summary>
  ///   A small game: graphics with a few pictures and tiles, two maps, audio with two chunks; every file with its own
  ///   Huffman dictionary. The files are in Files; the plain data are kept for the comparisons
  /// </summary>
  TTestGame = class
  strict private
    FMemory: TKeenMemoryFiles;
    FFiles: IKeenDataFiles;
    FGraphicsCode: TTestHuffmanCode;
    FMapCode: TTestHuffmanCode;
    FAudioCode: TTestHuffmanCode;
    FState: Cardinal;
    function NextByte: Byte;
    function RandomBytes(ACount: Integer): TBytes;
    function RandomWords(ACount: Integer): TArray<Word>;
    function ExplicitChunk(const ACode: TTestHuffmanCode; const APlain: TBytes): TBytes;
    function PlaneChunk(const APlane: TArray<Word>; AWidth, AHeight: Integer): TBytes;
    procedure BuildGraphics;
    procedure BuildMaps;
    procedure BuildAudio;
  public
    PictureTable: TBytes;
    Picture0: TBytes;
    Picture1: TBytes;
    MaskedPictureTable: TBytes;
    MaskedPicture0: TBytes;
    SpriteTable: TBytes;
    Sprite0: TBytes;
    Tile8All: TBytes;
    Tile8MaskedAll: TBytes;
    Tile16Zero: TBytes;
    Tile16MaskedZero: TBytes;
    TileInfo: TBytes;
    Audio0: TBytes;
    Audio5: TBytes;
    MapPlanes: array[0..1, 0..2] of TArray<Word>;
    MapWidth: array[0..1] of Integer;
    MapHeight: array[0..1] of Integer;
    /// <summary>The slots of the two maps in MAPHEAD</summary>
    MapSlot: array[0..1] of Integer;
    constructor Create(ASeed: Cardinal);
    destructor Destroy; override;
    property Files: IKeenDataFiles read FFiles;
  end;

implementation

procedure AppendBytes(var ATarget: TBytes; const ASource: TBytes);
begin
  if Length(ASource) > 0 then
  begin
    SetLength(ATarget, Length(ATarget) + Length(ASource));
    Move(ASource[0], ATarget[Length(ATarget) - Length(ASource)], Length(ASource));
  end;
end;

procedure AppendWord(var ATarget: TBytes; AValue: Word);
begin
  SetLength(ATarget, Length(ATarget) + 2);
  ATarget[Length(ATarget) - 2] := Byte(AValue);
  ATarget[Length(ATarget) - 1] := Byte(AValue shr 8);
end;

procedure AppendInt32(var ATarget: TBytes; AValue: Integer);
begin
  AppendWord(ATarget, Word(Cardinal(AValue)));
  AppendWord(ATarget, Word(Cardinal(AValue) shr 16));
end;

{ TTestHuffmanCode }

constructor TTestHuffmanCode.Create(ASeed: Integer);
var
  LValues: TList<Integer>;
  LWeights: TList<Int64>;
  LNodes: TArray<TKeenHuffNode>;
  LIndex: Integer;
  LStep: Integer;
  LMinimum: Integer;
  LFirstValue: Integer;
  LFirstWeight: Int64;
  LSecondValue: Integer;
  LSecondWeight: Int64;
  LState: Cardinal;

  function TakeLightest(out AValue: Integer; out AWeight: Int64): Boolean;
  var
    LI: Integer;
  begin
    LMinimum := 0;
    for LI := 1 to LValues.Count - 1 do
      if LWeights[LI] < LWeights[LMinimum] then
        LMinimum := LI;
    AValue := LValues[LMinimum];
    AWeight := LWeights[LMinimum];
    LValues.Delete(LMinimum);
    LWeights.Delete(LMinimum);
    Result := True;
  end;

begin
  inherited Create;
  LState := Cardinal(ASeed) * 2654435761 + 12345;
  LValues := TList<Integer>.Create;
  LWeights := TList<Int64>.Create;
  try
    for LIndex := 0 to 255 do
    begin
      LState := LState * 1664525 + 1013904223;
      LValues.Add(LIndex);
      LWeights.Add(Int64(1) shl ((LState shr 24) mod 13));
    end;
    SetLength(LNodes, KEEN_HUFF_NODES);
    for LStep := 0 to KEEN_HUFF_NODES - 1 do
    begin
      TakeLightest(LFirstValue, LFirstWeight);
      TakeLightest(LSecondValue, LSecondWeight);
      LNodes[LStep].Bit0 := Word(LFirstValue);
      LNodes[LStep].Bit1 := Word(LSecondValue);
      LValues.Add(256 + LStep);
      LWeights.Add(LFirstWeight + LSecondWeight);
    end;
  finally
    LWeights.Free;
    LValues.Free;
  end;
  // 255 merges of 256 leaves: the last node made is the head, node 254
  SetLength(FDictionary, 1024);
  for LIndex := 0 to KEEN_HUFF_NODES - 1 do
  begin
    FDictionary[LIndex * 4] := Byte(LNodes[LIndex].Bit0);
    FDictionary[LIndex * 4 + 1] := Byte(LNodes[LIndex].Bit0 shr 8);
    FDictionary[LIndex * 4 + 2] := Byte(LNodes[LIndex].Bit1);
    FDictionary[LIndex * 4 + 3] := Byte(LNodes[LIndex].Bit1 shr 8);
  end;
  Walk(256 + KEEN_HUFF_HEAD, LNodes, nil);
end;

procedure TTestHuffmanCode.Walk(AValue: Integer; const ANodes: TArray<TKeenHuffNode>;
  APath: TArray<Byte>);
var
  LPath: TArray<Byte>;
begin
  if AValue < 256 then
  begin
    FCodes[AValue] := APath;
    Exit;
  end;
  LPath := Copy(APath);
  SetLength(LPath, Length(LPath) + 1);
  LPath[High(LPath)] := 0;
  Walk(ANodes[AValue - 256].Bit0, ANodes, LPath);
  LPath := Copy(APath);
  SetLength(LPath, Length(LPath) + 1);
  LPath[High(LPath)] := 1;
  Walk(ANodes[AValue - 256].Bit1, ANodes, LPath);
end;

function TTestHuffmanCode.Encode(const AData: TBytes): TBytes;
var
  LBits: Integer;
  LByte: Integer;
  LBit: Byte;
  LCode: TArray<Byte>;
begin
  SetLength(Result, 0);
  LBits := 0;
  for LByte := 0 to High(AData) do
  begin
    LCode := FCodes[AData[LByte]];
    for LBit in LCode do
    begin
      if LBits mod 8 = 0 then
        SetLength(Result, Length(Result) + 1);
      if LBit <> 0 then
        Result[High(Result)] := Result[High(Result)] or Byte(1 shl (LBits mod 8));
      Inc(LBits);
    end;
  end;
end;

{ TTestRlewEncoder }

class function TTestRlewEncoder.Encode(const AWords: TArray<Word>; ATag: Word): TBytes;
var
  LIndex: Integer;
  LCount: Integer;
  LValue: Word;
  LRepeat: Integer;
begin
  SetLength(Result, 0);
  LIndex := 0;
  while LIndex < Length(AWords) do
  begin
    LValue := AWords[LIndex];
    LCount := 1;
    while (LIndex + LCount < Length(AWords)) and (AWords[LIndex + LCount] = LValue) and (LCount < 65535) do
      Inc(LCount);
    if (LCount > 3) or (LValue = ATag) then
    begin
      AppendWord(Result, ATag);
      AppendWord(Result, Word(LCount));
      AppendWord(Result, LValue);
    end
    else
      for LRepeat := 1 to LCount do
        AppendWord(Result, LValue);
    Inc(LIndex, LCount);
  end;
end;

class function TTestRlewEncoder.WordsToBytes(const AWords: TArray<Word>): TBytes;
var
  LWord: Word;
begin
  SetLength(Result, 0);
  for LWord in AWords do
    AppendWord(Result, LWord);
end;

{ TTestChunkFile }

constructor TTestChunkFile.Create(AChunkCount: Integer);
begin
  inherited Create;
  SetLength(FChunks, AChunkCount);
  SetLength(FPresent, AChunkCount);
end;

procedure TTestChunkFile.SetChunk(AIndex: Integer; const ACompressed: TBytes);
begin
  FChunks[AIndex] := ACompressed;
  FPresent[AIndex] := True;
end;

procedure TTestChunkFile.Build(ASparseMinusOne: Boolean; out AHeader, AData: TBytes);
var
  LOffsets: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(AData, 0);
  SetLength(AHeader, 0);
  SetLength(LOffsets, Length(FChunks) + 1);
  for LIndex := 0 to High(FChunks) do
    if FPresent[LIndex] then
    begin
      LOffsets[LIndex] := Length(AData);
      AppendBytes(AData, FChunks[LIndex]);
    end
    else if ASparseMinusOne then
      LOffsets[LIndex] := -1
    else
      LOffsets[LIndex] := Length(AData);
  LOffsets[Length(FChunks)] := Length(AData);
  for LIndex := 0 to High(LOffsets) do
    AppendInt32(AHeader, LOffsets[LIndex]);
end;

{ TTestGame }

constructor TTestGame.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed * 2654435761 + 7;
  FMemory := TKeenMemoryFiles.Create;
  FFiles := FMemory;
  FGraphicsCode := TTestHuffmanCode.Create(Integer(ASeed) + 1);
  FMapCode := TTestHuffmanCode.Create(Integer(ASeed) + 2);
  FAudioCode := TTestHuffmanCode.Create(Integer(ASeed) + 3);
  BuildGraphics;
  BuildMaps;
  BuildAudio;
end;

destructor TTestGame.Destroy;
begin
  FFiles := nil;
  FAudioCode.Free;
  FMapCode.Free;
  FGraphicsCode.Free;
  inherited Destroy;
end;

function TTestGame.NextByte: Byte;
begin
  FState := FState * 1664525 + 1013904223;
  Result := Byte(FState shr 24);
end;

function TTestGame.RandomBytes(ACount: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := NextByte;
end;

function TTestGame.RandomWords(ACount: Integer): TArray<Word>;
var
  LIndex: Integer;
  LRun: Integer;
  LValue: Word;
begin
  SetLength(Result, ACount);
  LIndex := 0;
  while LIndex < ACount do
  begin
    LValue := Word(NextByte) or (Word(NextByte and 3) shl 8);
    case NextByte mod 6 of
      0: LValue := TEST_RLEW_TAG;
      1: LValue := $FFFF;
    end;
    if NextByte mod 3 = 0 then
      LRun := 1
    else
      LRun := 4 + NextByte mod 6;
    while (LRun > 0) and (LIndex < ACount) do
    begin
      Result[LIndex] := LValue;
      Inc(LIndex);
      Dec(LRun);
    end;
  end;
end;

function TTestGame.ExplicitChunk(const ACode: TTestHuffmanCode; const APlain: TBytes): TBytes;
begin
  SetLength(Result, 0);
  AppendInt32(Result, Length(APlain));
  AppendBytes(Result, ACode.Encode(APlain));
end;

function TTestGame.PlaneChunk(const APlane: TArray<Word>; AWidth, AHeight: Integer): TBytes;
var
  LInner: TBytes;
begin
  SetLength(LInner, 0);
  AppendWord(LInner, Word(AWidth * AHeight * 2));
  AppendBytes(LInner, TTestRlewEncoder.Encode(APlane, TEST_RLEW_TAG));
  SetLength(Result, 0);
  AppendWord(Result, Word(Length(LInner)));
  AppendBytes(Result, FMapCode.Encode(LInner));
end;

procedure TTestGame.BuildGraphics;
var
  LFile: TTestChunkFile;
  LHeader: TBytes;
  LData: TBytes;
begin
  PictureTable := TBytes.Create(1, 0, 2, 0, 2, 0, 1, 0);
  Picture0 := RandomBytes(1 * 2 * 4);
  Picture1 := RandomBytes(2 * 1 * 4);
  MaskedPictureTable := TBytes.Create(1, 0, 1, 0);
  MaskedPicture0 := RandomBytes(1 * 1 * 5);
  SpriteTable := TBytes.Create(1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8, 0, 4, 0);
  Sprite0 := RandomBytes(1 * 2 * 5);
  // as in the shareware: the chunk of the 8x8 tiles has the data of 40 tiles (30 of the masked ones), not the
  // 72 (36) that the size says; what the chunk has not is zero here (the bytes after the data may be the padding
  // bits of the last byte, decoded as one more byte)
  Tile8All := RandomBytes(KEEN_TILE8_BYTES * KEEN_NUMTILE8);
  FillChar(Tile8All[TEST_TILE8_PRESENT * KEEN_TILE8_BYTES], (KEEN_NUMTILE8 - TEST_TILE8_PRESENT) * KEEN_TILE8_BYTES, 0);
  Tile8MaskedAll := RandomBytes(KEEN_TILE8M_BYTES * KEEN_NUMTILE8M);
  FillChar(Tile8MaskedAll[TEST_TILE8M_PRESENT * KEEN_TILE8M_BYTES],
    (KEEN_NUMTILE8M - TEST_TILE8M_PRESENT) * KEEN_TILE8M_BYTES, 0);
  Tile16Zero := RandomBytes(KEEN_TILE16_BYTES);
  Tile16MaskedZero := RandomBytes(KEEN_TILE16M_BYTES);

  LFile := TTestChunkFile.Create(KEEN_NUMCHUNKS);
  try
    LFile.SetChunk(KEEN_STRUCTPIC, ExplicitChunk(FGraphicsCode, PictureTable));
    LFile.SetChunk(KEEN_STRUCTPICM, ExplicitChunk(FGraphicsCode, MaskedPictureTable));
    LFile.SetChunk(KEEN_STRUCTSPRITE, ExplicitChunk(FGraphicsCode, SpriteTable));
    LFile.SetChunk(KEEN_STARTPICS, ExplicitChunk(FGraphicsCode, Picture0));
    LFile.SetChunk(KEEN_STARTPICS + 1, ExplicitChunk(FGraphicsCode, Picture1));
    LFile.SetChunk(KEEN_STARTPICM, ExplicitChunk(FGraphicsCode, MaskedPicture0));
    LFile.SetChunk(KEEN_STARTSPRITES, ExplicitChunk(FGraphicsCode, Sprite0));
    // the tiles have no length in front of them
    LFile.SetChunk(KEEN_STARTTILE8,
      FGraphicsCode.Encode(Copy(Tile8All, 0, TEST_TILE8_PRESENT * KEEN_TILE8_BYTES)));
    LFile.SetChunk(KEEN_STARTTILE8M,
      FGraphicsCode.Encode(Copy(Tile8MaskedAll, 0, TEST_TILE8M_PRESENT * KEEN_TILE8M_BYTES)));
    LFile.SetChunk(KEEN_STARTTILE16, FGraphicsCode.Encode(Tile16Zero));
    LFile.SetChunk(KEEN_STARTTILE16M, FGraphicsCode.Encode(Tile16MaskedZero));
    LFile.Build(True, LHeader, LData);
  finally
    LFile.Free;
  end;
  FMemory.Add('KDREAMS.EGA', LData);
  FMemory.Add('EGAHEAD.KDR', LHeader);
  FMemory.Add('EGADICT.KDR', FGraphicsCode.Dictionary);
end;

procedure TTestGame.BuildMaps;
var
  LData: TBytes;
  LHead: TBytes;
  LMapHeader: TBytes;
  LCompressedHeader: TBytes;
  LMap: Integer;
  LPlane: Integer;
  LChunk: TBytes;
  LStarts: array[0..2] of Integer;
  LLengths: array[0..2] of Integer;
  LOffsets: array[0..KEEN_MAP_SLOTS - 1] of Integer;
  LSizes: array[0..KEEN_MAP_SLOTS - 1] of Byte;
  LIndex: Integer;
  LName: AnsiString;
begin
  MapSlot[0] := 0;
  MapSlot[1] := 3;
  MapWidth[0] := 5;
  MapHeight[0] := 4;
  MapWidth[1] := 12;
  MapHeight[1] := 7;
  for LIndex := 0 to KEEN_MAP_SLOTS - 1 do
  begin
    LOffsets[LIndex] := -1;
    LSizes[LIndex] := 0;
  end;
  LOffsets[1] := 0;
  SetLength(LData, 0);
  for LMap := 0 to 1 do
  begin
    for LPlane := 0 to 2 do
    begin
      MapPlanes[LMap, LPlane] := RandomWords(MapWidth[LMap] * MapHeight[LMap]);
      LChunk := PlaneChunk(MapPlanes[LMap, LPlane], MapWidth[LMap], MapHeight[LMap]);
      LStarts[LPlane] := Length(LData);
      LLengths[LPlane] := Length(LChunk);
      AppendBytes(LData, LChunk);
    end;
    SetLength(LMapHeader, 0);
    for LPlane := 0 to 2 do
      AppendInt32(LMapHeader, LStarts[LPlane]);
    for LPlane := 0 to 2 do
      AppendWord(LMapHeader, Word(LLengths[LPlane]));
    AppendWord(LMapHeader, Word(MapWidth[LMap]));
    AppendWord(LMapHeader, Word(MapHeight[LMap]));
    LName := AnsiString(Format('TEST MAP %d', [LMap]));
    SetLength(LMapHeader, Length(LMapHeader) + 16);
    FillChar(LMapHeader[22], 16, 0);
    Move(LName[1], LMapHeader[22], Length(LName));
    LCompressedHeader := FMapCode.Encode(LMapHeader);
    LOffsets[MapSlot[LMap]] := Length(LData);
    LSizes[MapSlot[LMap]] := Byte(Length(LCompressedHeader));
    AppendBytes(LData, LCompressedHeader);
  end;

  TileInfo := RandomBytes(KEEN_TINF_SIZE);
  SetLength(LHead, 0);
  AppendWord(LHead, TEST_RLEW_TAG);
  for LIndex := 0 to KEEN_MAP_SLOTS - 1 do
    AppendInt32(LHead, LOffsets[LIndex]);
  for LIndex := 0 to KEEN_MAP_SLOTS - 1 do
  begin
    SetLength(LHead, Length(LHead) + 1);
    LHead[High(LHead)] := LSizes[LIndex];
  end;
  AppendBytes(LHead, TileInfo);
  FMemory.Add('KDREAMS.MAP', LData);
  FMemory.Add('MAPHEAD.KDR', LHead);
  // the dictionary of the maps is 1020 bytes in the real game (the others have 1024)
  FMemory.Add('MAPDICT.KDR', Copy(FMapCode.Dictionary, 0, KEEN_HUFF_DICT_BYTES));
end;

procedure TTestGame.BuildAudio;
var
  LFile: TTestChunkFile;
  LHeader: TBytes;
  LData: TBytes;
begin
  Audio0 := RandomBytes(20);
  Audio5 := RandomBytes(300);
  LFile := TTestChunkFile.Create(KEEN_NUMSNDCHUNKS);
  try
    LFile.SetChunk(0, ExplicitChunk(FAudioCode, Audio0));
    LFile.SetChunk(5, ExplicitChunk(FAudioCode, Audio5));
    LFile.Build(False, LHeader, LData);
  finally
    LFile.Free;
  end;
  FMemory.Add('KDREAMS.AUD', LData);
  FMemory.Add('AUDIOHHD.KDR', LHeader);
  FMemory.Add('AUDIODCT.KDR', FAudioCode.Dictionary);
end;

end.
