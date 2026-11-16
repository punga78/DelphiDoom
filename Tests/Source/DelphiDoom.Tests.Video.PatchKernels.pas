{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the kernels of the patches          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.PatchKernels;

// The oracle is not the old text of v_video (the kernels are that text, moved): it is a list of
// writes worked out from the format of a patch (posts, tall patches) and from the arithmetic
// of the stretch, to which the operation on the pixel is applied in order

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Video.Stretch,
  DelphiDoom.Video.PatchPainter,
  DelphiDoom.Video.PatchPainter32,
  DelphiDoom.Video.PatchZoomer;

type
  [TestFixture]
  [Category('video')]
  TTestVideoPatchKernels = class(TObject)
  public
    [Test]
    procedure DovrebbeDisegnareLaPatchStirataOpaca8;
    [Test]
    procedure DovrebbeDisegnareLaPatchTrasparente8IntegraEPerFili;
    [Test]
    procedure DovrebbeDisegnareLaPatchStirataTrasparente8IntegraEPerFili;
    [Test]
    procedure DovrebbeDisegnareLaPatch32ConESenzaTraduzione;
    [Test]
    procedure DovrebbeDisegnareLaPatchStirata32ConESenzaTraduzione;
    [Test]
    procedure DovrebbeDisegnareLaPatchTrasparente32IntegraEPerFili;
    [Test]
    procedure DovrebbeDisegnareLaPatchTrasparente32ConAlfa;
    [Test]
    procedure DovrebbeDisegnareLaPatchStirataTrasparente32IntegraEPerFili;
    [Test]
    procedure DovrebbeDisegnareLaPatchStirataTrasparente32ConAlfa;
    [Test]
    procedure DovrebbeIngrandireLaPatch8;
    [Test]
    procedure DovrebbeIngrandireLaPatch32;
  end;

implementation

type
  TPatchImage = record
    Bytes: TBytes;
    Offsets: TArray<Integer>;
    Width: Integer;
  end;

  TWrite = record
    Offset: Integer;
    Source: Byte;
  end;

  TWrites = TArray<TWrite>;

  TRowStart = reference to function(const ADelta: Integer): Integer;

const
  SCREEN_WIDTH = 80;
  SCREEN_HEIGHT = 200;
  SCREEN_COUNT = SCREEN_WIDTH * SCREEN_HEIGHT;
  // where the top of the patch goes (pixel x 5 of row 3)
  START_OFFSET = 3 * SCREEN_WIDTH + 5;

// A patch of AWidth columns; every column has the posts of the (top, length) pairs. The values of the
// pixels depend on the column, on the post and on the row, so that a wrong pixel shows up
function BuildPatch(const AWidth: Integer; const APosts: array of Integer): TPatchImage;
var
  LColumn, LPost, LRow, LLength: Integer;

  procedure AddByte(const AValue: Byte);
  begin
    SetLength(Result.Bytes, Length(Result.Bytes) + 1);
    Result.Bytes[High(Result.Bytes)] := AValue;
  end;

begin
  Result.Width := AWidth;
  SetLength(Result.Offsets, AWidth);
  SetLength(Result.Bytes, 8 + AWidth * 4);
  for LColumn := 0 to AWidth - 1 do
  begin
    Result.Offsets[LColumn] := Length(Result.Bytes);
    PInteger(@Result.Bytes[8 + LColumn * 4])^ := Length(Result.Bytes);
    for LPost := 0 to (Length(APosts) div 2) - 1 do
    begin
      LLength := APosts[LPost * 2 + 1];
      AddByte(APosts[LPost * 2]);
      AddByte(LLength);
      AddByte(0);
      for LRow := 0 to LLength - 1 do
        AddByte(Byte(1 + LColumn * 29 + LPost * 7 + LRow * 3));
      AddByte(0);
    end;
    AddByte($FF);
    // a source pixel read after the end of a post (the stretch reads one more): a padding byte
    AddByte(0);
  end;
end;

// The writes of the patch, in the order of the columns and of the rows
function ExpectedWrites(const APatch: TPatchImage; const ADestinationWidth, AStepX, AStepY: Integer;
  const ARowStart: TRowStart; const AIndex, AIndexCount: Integer): TWrites;
var
  LColumn, LSourceColumn, LDelta, LPreviousTop, LTop, LLength, LPosition, LRow, LSource: Integer;
  LTall: Boolean;
  LWrite: TWrite;
  LCount: Integer;
begin
  LCount := 0;
  SetLength(Result, 4096);
  for LColumn := 0 to ADestinationWidth - 1 do
  begin
    if (AIndexCount > 1) and (LColumn mod AIndexCount <> AIndex) then
      Continue;
    LSourceColumn := Integer(Cardinal(Int64(LColumn) * AStepX) shr 16);
    LPosition := APatch.Offsets[LSourceColumn];
    LDelta := 0;
    LTall := False;
    while APatch.Bytes[LPosition] <> $FF do
    begin
      LTop := APatch.Bytes[LPosition];
      LLength := APatch.Bytes[LPosition + 1];
      LDelta := LDelta + LTop;
      LRow := 0;
      // the source pixel advances every time the 16.16 position crosses a whole number
      while Integer(Cardinal(Int64(LRow) * AStepY) shr 16) < LLength do
      begin
        LSource := Integer(Cardinal(Int64(LRow) * AStepY) shr 16);
        LWrite.Offset := LColumn + (ARowStart(LDelta) + LRow) * SCREEN_WIDTH;
        LWrite.Source := APatch.Bytes[LPosition + 3 + LSource];
        if LCount = Length(Result) then
          SetLength(Result, LCount * 2);
        Result[LCount] := LWrite;
        Inc(LCount);
        Inc(LRow);
      end;
      LPreviousTop := LTop;
      LPosition := LPosition + LLength + 4;
      if not LTall then
      begin
        if APatch.Bytes[LPosition] > LPreviousTop then
          LDelta := 0
        else
          LTall := True;
      end;
    end;
  end;
  SetLength(Result, LCount);
end;

procedure CheckInside(const AWrites: TWrites);
var
  LIndex: Integer;
begin
  // the screen must hold every write: a kernel that writes elsewhere would corrupt the memory
  for LIndex := 0 to High(AWrites) do
    Assert.IsTrue(START_OFFSET + AWrites[LIndex].Offset < SCREEN_COUNT, 'the test screen is too small');
end;

function Base8: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, SCREEN_COUNT);
  for LIndex := 0 to SCREEN_COUNT - 1 do
    Result[LIndex] := Byte(LIndex * 7 + 3);
end;

function Base32: TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, SCREEN_COUNT);
  for LIndex := 0 to SCREEN_COUNT - 1 do
    Result[LIndex] := Cardinal(LIndex * $010305) + $00102030;
end;

function Translation8: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := Byte(255 - LIndex * 3);
end;

function Table8: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 65536);
  for LIndex := 0 to 65535 do
    Result[LIndex] := Byte(LIndex * 5 + (LIndex shr 8) * 3 + 1);
end;

function Palette32: TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := Cardinal(LIndex * $00010503) xor $00A0B0C0;
end;

// The mean of two colors written out by channel, the alpha of the result is 0
function Mean(const AColor1, AColor2: Cardinal): Cardinal;
var
  LShift: Integer;
begin
  Result := 0;
  for LShift := 0 to 2 do
    Result := Result or (Cardinal(((AColor1 shr (LShift * 8)) and $FF) + ((AColor2 shr (LShift * 8)) and $FF)) shr 1 shl (LShift * 8));
end;

procedure CompareBytes(const AExpected, AActual: TBytes);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AExpected) do
    if AExpected[LIndex] <> AActual[LIndex] then
      Assert.Fail(Format('pixel %d: expected %d, actual %d', [LIndex, AExpected[LIndex], AActual[LIndex]]));
end;

procedure CompareLongs(const AExpected, AActual: TArray<Cardinal>);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AExpected) do
    if AExpected[LIndex] <> AActual[LIndex] then
      Assert.Fail(Format('pixel %d: expected %x, actual %x', [LIndex, AExpected[LIndex], AActual[LIndex]]));
end;

// patches: several posts, a tall patch (the second post has a top delta not above the first)
function SamplePatch: TPatchImage;
begin
  Result := BuildPatch(9, [0, 4, 6, 5]);
end;

function TallPatch: TPatchImage;
begin
  Result := BuildPatch(7, [10, 3, 2, 3, 0, 2]);
end;

function RowStart100(const ADelta: Integer): Integer;
begin
  Result := (ADelta * 100) div 200;
end;

function RowStartRound(const ADelta: Integer): Integer;
begin
  Result := Round(ADelta * 140 / 200);
end;

{ TTestVideoPatchKernels }

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchStirataOpaca8;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LTranslation: TBytes;
  LIndex, LStepY, LPatchIndex, LStepIndex: Integer;
begin
  LTranslation := Translation8;
  for LPatchIndex := 0 to 1 do
    for LStepIndex := 0 to 2 do
    begin
      if LPatchIndex = 0 then
        LPatch := SamplePatch
      else
        LPatch := TallPatch;
      case LStepIndex of
        0: LStepY := 65536;
        1: LStepY := 40000;
      else
        LStepY := 21845;
      end;
      LWrites := ExpectedWrites(LPatch, LPatch.Width * 2, 32768, LStepY,
        function(const ADelta: Integer): Integer begin Result := (ADelta * 100) div 200 end, 0, 1);
      CheckInside(LWrites);
      LExpected := Base8;
      for LIndex := 0 to High(LWrites) do
        LExpected[START_OFFSET + LWrites[LIndex].Offset] := LTranslation[LWrites[LIndex].Source];
      LActual := Base8;
      TVideoPatchPainter.DrawColumnsStretched8(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]),
        LPatch.Width * 2, 32768, LStepY, @LActual[START_OFFSET], SCREEN_WIDTH, 100, PVideoByteRow(@LTranslation[0]));
      CompareBytes(LExpected, LActual);
    end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchTrasparente8IntegraEPerFili;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LTranslation, LTable: TBytes;
  LIndex, LThread, LThreads: Integer;
begin
  LTranslation := Translation8;
  LTable := Table8;
  LPatch := TallPatch;
  for LThreads in [1, 3] do
  begin
    LExpected := Base8;
    LActual := Base8;
    for LThread := 0 to LThreads - 1 do
    begin
      LWrites := ExpectedWrites(LPatch, LPatch.Width, 65536, 65536,
        function(const ADelta: Integer): Integer begin Result := ADelta end, LThread, LThreads);
      CheckInside(LWrites);
      for LIndex := 0 to High(LWrites) do
        LExpected[START_OFFSET + LWrites[LIndex].Offset] :=
          LTable[LExpected[START_OFFSET + LWrites[LIndex].Offset] shl 8 + LTranslation[LWrites[LIndex].Source]];
      TVideoPatchPainter.DrawColumnsTransparent8(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]),
        LPatch.Width, @LActual[START_OFFSET], SCREEN_WIDTH, PVideoByteRow(@LTranslation[0]),
        PVideoByteRow(@LTable[0]), LThread, LThreads);
    end;
    CompareBytes(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchStirataTrasparente8IntegraEPerFili;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LTranslation, LTable: TBytes;
  LIndex, LThread, LThreads: Integer;
begin
  LTranslation := Translation8;
  LTable := Table8;
  LPatch := SamplePatch;
  for LThreads in [1, 4] do
  begin
    LExpected := Base8;
    LActual := Base8;
    for LThread := 0 to LThreads - 1 do
    begin
      LWrites := ExpectedWrites(LPatch, 20, 29127, 40000, RowStart100, LThread, LThreads);
      CheckInside(LWrites);
      for LIndex := 0 to High(LWrites) do
        LExpected[START_OFFSET + LWrites[LIndex].Offset] :=
          LTable[LExpected[START_OFFSET + LWrites[LIndex].Offset] shl 8 + LTranslation[LWrites[LIndex].Source]];
      TVideoPatchPainter.DrawColumnsStretchedTransparent8(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]),
        20, 29127, 40000, @LActual[START_OFFSET], SCREEN_WIDTH, 100, PVideoByteRow(@LTranslation[0]),
        PVideoByteRow(@LTable[0]), LThread, LThreads);
    end;
    CompareBytes(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatch32ConESenzaTraduzione;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LTranslation: TBytes;
  LIndex, LUseTranslation: Integer;
begin
  LTranslation := Translation8;
  LPalette := Palette32;
  LPatch := TallPatch;
  LWrites := ExpectedWrites(LPatch, LPatch.Width, 65536, 65536,
    function(const ADelta: Integer): Integer begin Result := ADelta end, 0, 1);
  CheckInside(LWrites);
  for LUseTranslation := 0 to 1 do
  begin
    LExpected := Base32;
    for LIndex := 0 to High(LWrites) do
      if LUseTranslation = 1 then
        LExpected[START_OFFSET + LWrites[LIndex].Offset] := LPalette[LTranslation[LWrites[LIndex].Source]]
      else
        LExpected[START_OFFSET + LWrites[LIndex].Offset] := LPalette[LWrites[LIndex].Source];
    LActual := Base32;
    if LUseTranslation = 1 then
      TVideoPatchPainter32.DrawColumns32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), LPatch.Width,
        @LActual[START_OFFSET], SCREEN_WIDTH, PVideoLongWordRow(@LPalette[0]), PVideoByteRow(@LTranslation[0]))
    else
      TVideoPatchPainter32.DrawColumns32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), LPatch.Width,
        @LActual[START_OFFSET], SCREEN_WIDTH, PVideoLongWordRow(@LPalette[0]), nil);
    CompareLongs(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchStirata32ConESenzaTraduzione;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LTranslation: TBytes;
  LIndex, LUseTranslation: Integer;
begin
  LTranslation := Translation8;
  LPalette := Palette32;
  LPatch := SamplePatch;
  // the first row of a post is Round(delta * 140 / 200)
  LWrites := ExpectedWrites(LPatch, 14, 41943, 30000, RowStartRound, 0, 1);
  CheckInside(LWrites);
  for LUseTranslation := 0 to 1 do
  begin
    LExpected := Base32;
    for LIndex := 0 to High(LWrites) do
      if LUseTranslation = 1 then
        LExpected[START_OFFSET + LWrites[LIndex].Offset] := LPalette[LTranslation[LWrites[LIndex].Source]]
      else
        LExpected[START_OFFSET + LWrites[LIndex].Offset] := LPalette[LWrites[LIndex].Source];
    LActual := Base32;
    if LUseTranslation = 1 then
      TVideoPatchPainter32.DrawColumnsStretched32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), 14,
        41943, 30000, @LActual[START_OFFSET], SCREEN_WIDTH, 140, PVideoLongWordRow(@LPalette[0]),
        PVideoByteRow(@LTranslation[0]))
    else
      TVideoPatchPainter32.DrawColumnsStretched32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), 14,
        41943, 30000, @LActual[START_OFFSET], SCREEN_WIDTH, 140, PVideoLongWordRow(@LPalette[0]), nil);
    CompareLongs(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchTrasparente32IntegraEPerFili;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LIndex, LThread, LThreads: Integer;
begin
  LPalette := Palette32;
  LPatch := TallPatch;
  for LThreads in [1, 2, 5] do
  begin
    LExpected := Base32;
    LActual := Base32;
    for LThread := 0 to LThreads - 1 do
    begin
      LWrites := ExpectedWrites(LPatch, LPatch.Width, 65536, 65536,
        function(const ADelta: Integer): Integer begin Result := ADelta end, LThread, LThreads);
      CheckInside(LWrites);
      for LIndex := 0 to High(LWrites) do
        LExpected[START_OFFSET + LWrites[LIndex].Offset] :=
          Mean(LPalette[LWrites[LIndex].Source], LExpected[START_OFFSET + LWrites[LIndex].Offset]);
      TVideoPatchPainter32.DrawColumnsTransparent32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]),
        LPatch.Width, @LActual[START_OFFSET], SCREEN_WIDTH, PVideoLongWordRow(@LPalette[0]), LThread, LThreads);
    end;
    CompareLongs(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchTrasparente32ConAlfa;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LIndex: Integer;
begin
  LPalette := Palette32;
  LPatch := TallPatch;
  LWrites := ExpectedWrites(LPatch, LPatch.Width, 65536, 65536,
    function(const ADelta: Integer): Integer begin Result := ADelta end, 0, 1);
  CheckInside(LWrites);
  LExpected := Base32;
  for LIndex := 0 to High(LWrites) do
    LExpected[START_OFFSET + LWrites[LIndex].Offset] :=
      Mean(LPalette[LWrites[LIndex].Source], LExpected[START_OFFSET + LWrites[LIndex].Offset]) or $80000000;
  LActual := Base32;
  TVideoPatchPainter32.DrawColumnsTransparentAlpha32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]),
    LPatch.Width, @LActual[START_OFFSET], SCREEN_WIDTH, PVideoLongWordRow(@LPalette[0]));
  CompareLongs(LExpected, LActual);
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchStirataTrasparente32IntegraEPerFili;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LIndex, LThread, LThreads: Integer;
begin
  LPalette := Palette32;
  LPatch := SamplePatch;
  for LThreads in [1, 3] do
  begin
    LExpected := Base32;
    LActual := Base32;
    for LThread := 0 to LThreads - 1 do
    begin
      // the first row of a post is delta * 100 div 200 here (not the rounded one)
      LWrites := ExpectedWrites(LPatch, 20, 29127, 40000, RowStart100, LThread, LThreads);
      CheckInside(LWrites);
      for LIndex := 0 to High(LWrites) do
        LExpected[START_OFFSET + LWrites[LIndex].Offset] :=
          Mean(LPalette[LWrites[LIndex].Source], LExpected[START_OFFSET + LWrites[LIndex].Offset]);
      TVideoPatchPainter32.DrawColumnsStretchedTransparent32(@LPatch.Bytes[0],
        PVideoIntegerRow(@LPatch.Offsets[0]), 20, 29127, 40000, @LActual[START_OFFSET], SCREEN_WIDTH, 100,
        PVideoLongWordRow(@LPalette[0]), LThread, LThreads);
    end;
    CompareLongs(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeDisegnareLaPatchStirataTrasparente32ConAlfa;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LIndex: Integer;
begin
  LPalette := Palette32;
  LPatch := SamplePatch;
  LWrites := ExpectedWrites(LPatch, 20, 29127, 40000, RowStart100, 0, 1);
  CheckInside(LWrites);
  LExpected := Base32;
  for LIndex := 0 to High(LWrites) do
    LExpected[START_OFFSET + LWrites[LIndex].Offset] :=
      Mean(LPalette[LWrites[LIndex].Source], LExpected[START_OFFSET + LWrites[LIndex].Offset]) or $80000000;
  LActual := Base32;
  TVideoPatchPainter32.DrawColumnsStretchedTransparentAlpha32(@LPatch.Bytes[0],
    PVideoIntegerRow(@LPatch.Offsets[0]), 20, 29127, 40000, @LActual[START_OFFSET], SCREEN_WIDTH, 100,
    PVideoLongWordRow(@LPalette[0]));
  CompareLongs(LExpected, LActual);
end;

procedure TTestVideoPatchKernels.DovrebbeIngrandireLaPatch8;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LTranslation: TBytes;
  LIndex, LPreserve: Integer;
  LZoom: Integer;
begin
  LTranslation := Translation8;
  LPatch := SamplePatch;
  LZoom := 98304; // 1.5
  for LPreserve := 0 to 1 do
  begin
    if LPreserve = 1 then
      LWrites := ExpectedWrites(LPatch, 13, 43690, 43690,
        function(const ADelta: Integer): Integer begin Result := ((ADelta * 100) * 98304 div 65536 div 200) end, 0, 1)
    else
      LWrites := ExpectedWrites(LPatch, 13, 43690, 43690,
        function(const ADelta: Integer): Integer begin Result := ADelta * 98304 div 65536 end, 0, 1);
    CheckInside(LWrites);
    LExpected := Base8;
    for LIndex := 0 to High(LWrites) do
      LExpected[START_OFFSET + LWrites[LIndex].Offset] := LTranslation[LWrites[LIndex].Source];
    LActual := Base8;
    TVideoPatchZoomer.DrawColumns8(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), 13, 43690, 43690,
      @LActual[START_OFFSET], SCREEN_WIDTH, 100, LZoom, LPreserve = 1, PVideoByteRow(@LTranslation[0]));
    CompareBytes(LExpected, LActual);
  end;
end;

procedure TTestVideoPatchKernels.DovrebbeIngrandireLaPatch32;
var
  LPatch: TPatchImage;
  LWrites: TWrites;
  LExpected, LActual, LPalette: TArray<Cardinal>;
  LIndex, LPreserve: Integer;
  LZoom: Integer;
begin
  LPalette := Palette32;
  LPatch := TallPatch;
  LZoom := 98304;
  for LPreserve := 0 to 1 do
  begin
    if LPreserve = 1 then
      LWrites := ExpectedWrites(LPatch, 10, 43690, 43690,
        function(const ADelta: Integer): Integer begin Result := ((ADelta * 100) * 98304 div 65536 div 200) end, 0, 1)
    else
      LWrites := ExpectedWrites(LPatch, 10, 43690, 43690,
        function(const ADelta: Integer): Integer begin Result := ADelta * 98304 div 65536 end, 0, 1);
    CheckInside(LWrites);
    LExpected := Base32;
    for LIndex := 0 to High(LWrites) do
      LExpected[START_OFFSET + LWrites[LIndex].Offset] := LPalette[LWrites[LIndex].Source];
    LActual := Base32;
    TVideoPatchZoomer.DrawColumns32(@LPatch.Bytes[0], PVideoIntegerRow(@LPatch.Offsets[0]), 10, 43690, 43690,
      @LActual[START_OFFSET], SCREEN_WIDTH, 100, LZoom, LPreserve = 1, PVideoLongWordRow(@LPalette[0]));
    CompareLongs(LExpected, LActual);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestVideoPatchKernels);

end.
