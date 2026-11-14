{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity of the compressors with idCompressor of Doom 3           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Compression.Parity;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Crc32,
  DelphiDoom.Compression.Intf, DelphiDoom.Compression.Factory;

type
  /// <summary>
  ///   Compares the compressors with Tests\Data\Compression\golden.txt, written by the real
  ///   idCompressor classes of Doom 3 (Tools\Verifica\98\Build-Harness.ps1). The table of cases and the
  ///   test data generators are the same as in main.cpp of the harness. For every case: the compressed
  ///   length and CRC-32 (byte for byte), the compression ratio (as the bits of a float, to 1e-3), whether
  ///   the data came back and the CRC-32 of what came back; the compressed bytes of the small cases are
  ///   also decompressed here (what the C++ wrote, read by the Delphi code).
  /// </summary>
  [TestFixture]
  [Category('Compression')]
  TTestCompressorParity = class
  strict private
    type
      TCase = record
        Name, Kind, Compressor: string;
        WordLength, WriteChunk, ReadChunk: Integer;
      end;
      TLcg = record
        State: Cardinal;
        procedure Start(ASeed: Cardinal);
        function NextByte: Cardinal;
      end;
    var
      FGolden: TDictionary<string, TArray<string>>;
    class function Cases: TArray<TCase>; static;
    class function MakeData(const AKind: string): TBytes; static;
    class function Allocate(const AName: string): ICompressor; static;
    class function CrcOf(const AData: TBytes; ALength: Integer): Cardinal; static;
    function Decompress(const AName: string; const ACompressed: TBytes; AWordLength, AReadChunk, ALength: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeProdurreGliStessiByteDelC;
    [Test]
    procedure DovrebbeLeggereCioCheHaScrittoIlC;
    [Test]
    procedure DovrebbeAvereTuttiICasiNelGolden;
  end;

implementation

{ TTestCompressorParity.TLcg }

procedure TTestCompressorParity.TLcg.Start(ASeed: Cardinal);
begin
  State := ASeed;
end;

function TTestCompressorParity.TLcg.NextByte: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State shr 24;
end;

{ TTestCompressorParity }

class function TTestCompressorParity.Cases: TArray<TCase>;

  function Make(const AName, AKind, ACompressor: string; AWordLength, AWriteChunk, AReadChunk: Integer): TCase;
  begin
    Result.Name := AName;
    Result.Kind := AKind;
    Result.Compressor := ACompressor;
    Result.WordLength := AWordLength;
    Result.WriteChunk := AWriteChunk;
    Result.ReadChunk := AReadChunk;
  end;

begin
  // the same table as cases[] of Tools\Verifica\98\main.cpp
  Result := [
    Make('none-random', 'random', 'none', 8, 0, 0),
    Make('bit-text', 'text', 'bit', 8, 0, 0),
    Make('bit-random-chunked', 'random', 'bit', 8, 777, 500),
    Make('rle8-runs', 'runs', 'rle', 8, 0, 0),
    Make('rle8-zeros', 'zeros', 'rle', 8, 0, 0),
    Make('rle8-ones', 'ones', 'rle', 8, 0, 0),
    Make('rle8-text-chunked', 'text', 'rle', 8, 500, 0),
    Make('rle4-runs', 'runs', 'rle', 4, 0, 0),
    Make('rle5-random', 'random', 'rle', 5, 0, 0),
    Make('rle16-zeros', 'zeros', 'rle', 16, 0, 0),
    Make('rlz8-sparse', 'sparse', 'rlz', 8, 0, 0),
    Make('rlz8-zeros', 'zeros', 'rlz', 8, 0, 0),
    Make('rlz4-sparse', 'sparse', 'rlz', 4, 0, 0),
    Make('huff-text', 'text', 'huff', 8, 0, 0),
    Make('huff-random', 'random', 'huff', 8, 0, 0),
    Make('huff-mixed', 'mixed', 'huff', 8, 0, 0),
    Make('huff-big-chunked', 'big', 'huff', 8, 3000, 777),
    Make('arith-text', 'text', 'arith', 8, 0, 0),
    Make('arith-random', 'random', 'arith', 8, 0, 0),
    Make('arith-mixed', 'mixed', 'arith', 8, 0, 0),
    Make('lzss8-text', 'text', 'lzss', 8, 0, 0),
    Make('lzss8-runs', 'runs', 'lzss', 8, 0, 0),
    Make('lzss8-big', 'big', 'lzss', 8, 0, 0),
    Make('lzss8-big-chunked', 'big', 'lzss', 8, 4096, 5000),
    Make('lzss4-runs', 'runs', 'lzss', 4, 0, 0),
    Make('lzss16-text', 'text', 'lzss', 16, 0, 0),
    Make('lzssw8-text', 'text', 'lzssw', 8, 0, 0),
    Make('lzssw8-big', 'big', 'lzssw', 8, 0, 0),
    Make('lzssw4-runs', 'runs', 'lzssw', 4, 0, 0),
    Make('lzw-text', 'text', 'lzw', 8, 0, 0),
    Make('lzw-random', 'random', 'lzw', 8, 0, 0),
    Make('lzw-big', 'big', 'lzw', 8, 0, 0),
    Make('lzw-big-chunked', 'big', 'lzw', 8, 1000, 3000)];
end;

class function TTestCompressorParity.MakeData(const AKind: string): TBytes;
var
  LRandom: TLcg;
  LCount, LIndex, LValue, LLength, LHigh, LLow, LOffset: Integer;
  LPhrase: AnsiString;
  LByte: Byte;

  procedure Add(AByte: Byte);
  begin
    if LCount >= Length(Result) then
      SetLength(Result, Length(Result) * 2 + 64);
    Result[LCount] := AByte;
    Inc(LCount);
  end;

begin
  LCount := 0;
  SetLength(Result, 0);
  if AKind = 'text' then
  begin
    LPhrase := 'the quick brown fox jumps over the lazy dog. ';
    for LIndex := 0 to 1499 do
      Add(Byte(LPhrase[(LIndex mod Length(LPhrase)) + 1]));
  end
  else if AKind = 'zeros' then
  begin
    for LIndex := 0 to 2999 do
      Add(0);
  end
  else if AKind = 'ones' then
  begin
    for LIndex := 0 to 699 do
      Add($FF);
  end
  else if AKind = 'runs' then
  begin
    LRandom.Start(1);
    while LCount < 4000 do
    begin
      LByte := Byte(LRandom.NextByte);
      LLength := 1 + Integer(LRandom.NextByte mod 40);
      for LIndex := 1 to LLength do
        Add(LByte);
    end;
  end
  else if AKind = 'random' then
  begin
    LRandom.Start(2);
    for LIndex := 0 to 2999 do
      Add(Byte(LRandom.NextByte));
  end
  else if AKind = 'sparse' then
  begin
    LRandom.Start(3);
    for LIndex := 0 to 5999 do
    begin
      LValue := Integer(LRandom.NextByte);
      LByte := Byte(LRandom.NextByte);
      if LValue mod 8 = 0 then
        Add(LByte)
      else
        Add(0);
    end;
  end
  else if AKind = 'mixed' then
  begin
    LRandom.Start(4);
    for LIndex := 0 to 9999 do
      Add(0);
    for LIndex := 0 to 9999 do
      Add(Byte(LRandom.NextByte));
  end
  else if AKind = 'big' then
  begin
    LRandom.Start(5);
    while LCount < 70000 do
    begin
      LValue := Integer(LRandom.NextByte);
      if (LCount > 100) and (LValue mod 4 = 0) then
      begin
        LHigh := Integer(LRandom.NextByte);
        LLow := Integer(LRandom.NextByte);
        LOffset := (LHigh * 256 + LLow) mod (LCount - 40);
        LLength := 20 + Integer(LRandom.NextByte mod 41);
        for LIndex := 0 to LLength - 1 do
          Add(Result[LOffset + LIndex]);
      end
      else
      begin
        LValue := Integer(LRandom.NextByte);
        Add(Byte(Ord('a') + (LValue shr 5)));
      end;
    end;
    LCount := 70000;
  end;
  SetLength(Result, LCount);
end;

class function TTestCompressorParity.Allocate(const AName: string): ICompressor;
begin
  if AName = 'none' then
    Result := TCompressorFactory.CreateNoCompression
  else if AName = 'bit' then
    Result := TCompressorFactory.CreateBitStream
  else if AName = 'rle' then
    Result := TCompressorFactory.CreateRunLength
  else if AName = 'rlz' then
    Result := TCompressorFactory.CreateRunLengthZeroBased
  else if AName = 'huff' then
    Result := TCompressorFactory.CreateHuffman
  else if AName = 'arith' then
    Result := TCompressorFactory.CreateArithmetic
  else if AName = 'lzss' then
    Result := TCompressorFactory.CreateLzss
  else if AName = 'lzssw' then
    Result := TCompressorFactory.CreateLzssWordAligned
  else
    Result := TCompressorFactory.CreateLzw;
end;

class function TTestCompressorParity.CrcOf(const AData: TBytes; ALength: Integer): Cardinal;
var
  LEmpty: Byte;
begin
  if ALength = 0 then
    Exit(TCrc32.Calculate(LEmpty, 0));
  Result := TCrc32.Calculate(AData[0], ALength);
end;

function TTestCompressorParity.Decompress(const AName: string; const ACompressed: TBytes;
  AWordLength, AReadChunk, ALength: Integer): TBytes;
var
  LStream: TBytesStream;
  LCompressor: ICompressor;
  LPosition, LStep, LGot: Integer;
begin
  LStream := TBytesStream.Create(ACompressed);
  try
    LCompressor := Allocate(AName);
    LCompressor.Init(LStream, False, AWordLength);
    SetLength(Result, ALength + 16);
    FillChar(Result[0], Length(Result), 0);
    if AReadChunk = 0 then
      AReadChunk := ALength;
    LPosition := 0;
    while LPosition < ALength do
    begin
      LStep := ALength - LPosition;
      if LStep > AReadChunk then
        LStep := AReadChunk;
      LGot := LCompressor.Read(@Result[LPosition], LStep);
      if LGot <= 0 then
        Break;
      Inc(LPosition, AReadChunk);
    end;
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressorParity.Setup;
var
  LLine: string;
  LParts: TArray<string>;
begin
  FGolden := TDictionary<string, TArray<string>>.Create;
  for LLine in TFile.ReadAllLines(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Compression\golden.txt'))) do
  begin
    LParts := LLine.Split(['|']);
    if (Length(LParts) = 8) and (LParts[0] = 'C') then
      FGolden.Add(LParts[1], LParts);
  end;
end;

procedure TTestCompressorParity.TearDown;
begin
  FGolden.Free;
end;

procedure TTestCompressorParity.DovrebbeAvereTuttiICasiNelGolden;
var
  LCase: TCase;
begin
  for LCase in Cases do
    Assert.IsTrue(FGolden.ContainsKey(LCase.Name), 'caso assente dal golden: ' + LCase.Name);
  Assert.AreEqual<Integer>(Length(Cases), FGolden.Count);
end;

procedure TTestCompressorParity.DovrebbeProdurreGliStessiByteDelC;
var
  LCase: TCase;
  LData, LCompressedBytes, LBack: TBytes;
  LStream: TBytesStream;
  LCompressor: ICompressor;
  LPosition, LStep, LChunk: Integer;
  LRatio: Single;
  LExpected: TArray<string>;
  LRatioExpected: Single;
  LRatioBits: Cardinal;
  LFailures: string;
begin
  LFailures := '';
  for LCase in Cases do
  begin
    LExpected := FGolden[LCase.Name];
    LData := MakeData(LCase.Kind);
    LStream := TBytesStream.Create;
    try
      LCompressor := Allocate(LCase.Compressor);
      LCompressor.Init(LStream, True, LCase.WordLength);
      LChunk := LCase.WriteChunk;
      if LChunk = 0 then
        LChunk := Length(LData);
      LPosition := 0;
      while LPosition < Length(LData) do
      begin
        LStep := Length(LData) - LPosition;
        if LStep > LChunk then
          LStep := LChunk;
        LCompressor.Write(@LData[LPosition], LStep);
        Inc(LPosition, LChunk);
      end;
      LCompressor.FinishCompress;
      LRatio := LCompressor.GetCompressionRatio;
      LCompressor := nil;
      LCompressedBytes := Copy(LStream.Bytes, 0, LStream.Size);
    finally
      LStream.Free;
    end;
    if IntToStr(Length(LCompressedBytes)) <> LExpected[2] then
      LFailures := LFailures + Format(' %s: lunghezza %d invece di %s;', [LCase.Name, Length(LCompressedBytes), LExpected[2]])
    else if LowerCase(IntToHex(CrcOf(LCompressedBytes, Length(LCompressedBytes)), 8)) <> LExpected[3] then
      LFailures := LFailures + Format(' %s: byte diversi;', [LCase.Name]);
    LRatioBits := StrToUInt('$' + LExpected[4]);
    LRatioExpected := PSingle(@LRatioBits)^;
    if Abs(LRatio - LRatioExpected) > 0.001 then
      LFailures := LFailures + Format(' %s: rapporto %f invece di %f;', [LCase.Name, LRatio, LRatioExpected]);
    LBack := Decompress(LCase.Compressor, LCompressedBytes, LCase.WordLength, LCase.ReadChunk, Length(LData));
    if LowerCase(IntToHex(CrcOf(LBack, Length(LData)), 8)) <> LExpected[6] then
      LFailures := LFailures + Format(' %s: dati letti diversi;', [LCase.Name]);
    if (CompareMem(@LBack[0], @LData[0], Length(LData))) <> (LExpected[5] = '1') then
      LFailures := LFailures + Format(' %s: andata e ritorno diversa dal C;', [LCase.Name]);
  end;
  Assert.AreEqual('', LFailures);
end;

procedure TTestCompressorParity.DovrebbeLeggereCioCheHaScrittoIlC;
var
  LCase: TCase;
  LData, LBack, LCompressedBytes: TBytes;
  LExpected: TArray<string>;
  LHex: string;
  LIndex: Integer;
  LFailures: string;
  LChecked: Integer;
begin
  LFailures := '';
  LChecked := 0;
  for LCase in Cases do
  begin
    LExpected := FGolden[LCase.Name];
    LHex := LExpected[7];
    if LHex = '-' then
      Continue;
    SetLength(LCompressedBytes, Length(LHex) div 2);
    for LIndex := 0 to High(LCompressedBytes) do
      LCompressedBytes[LIndex] := Byte(StrToInt('$' + Copy(LHex, LIndex * 2 + 1, 2)));
    LData := MakeData(LCase.Kind);
    LBack := Decompress(LCase.Compressor, LCompressedBytes, LCase.WordLength, LCase.ReadChunk, Length(LData));
    if LowerCase(IntToHex(CrcOf(LBack, Length(LData)), 8)) <> LExpected[6] then
      LFailures := LFailures + ' ' + LCase.Name;
    Inc(LChecked);
  end;
  Assert.AreEqual('', LFailures);
  Assert.IsTrue(LChecked >= 10, 'pochi casi con i byte nel golden: ' + IntToStr(LChecked));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCompressorParity);

end.
