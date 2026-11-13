{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the compressors (idCompressor family)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Compression.Compressors;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Compression.Types, DelphiDoom.Compression.Intf, DelphiDoom.Compression.Factory;

type
  [TestFixture]
  [Category('Compression')]
  TTestCompressors = class
  strict private
    function RandomBytes(ACount: Integer; ASeed: Cardinal): TBytes;
    function Compress(const ACompressor: ICompressor; const AData: TBytes; AWordLength: Integer): TBytes;
    function Decompress(const ACompressor: ICompressor; const ACompressed: TBytes; ALength, AWordLength: Integer): TBytes;
    procedure CheckRoundTrip(const ACreate: TFunc<ICompressor>; const AData: TBytes; AWordLength: Integer);
  public
    [Test]
    procedure NonDovrebbeComprimereSeNonComprime;
    [Test]
    procedure DovrebbeRifiutareLaLetturaInCompressione;
    [Test]
    procedure DovrebbeRifiutareLaScritturaInDecompressione;
    [Test]
    procedure DovrebbeDareZeroPerLunghezzeNonPositive;
    [Test]
    procedure DovrebbeRifiutareUnFlussoMancante;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaDiParolaFuoriIntervallo;
    [Test]
    procedure DovrebbeRifiutareLaRicerca;
    [Test]
    procedure DovrebbeRiferireLunghezzaEPosizioneDelFlusso;
    [Test]
    procedure DovrebbeUsareLeOverloadSuTBytes;
    [Test]
    procedure DovrebbeFareAndataERitornoDiTuttiICompressori;
    [Test]
    procedure DovrebbeFareAndataERitornoDiUnSoloByte;
    [Test]
    procedure DovrebbeFareAndataERitornoDiTuttiIValoriDiByte;
    [Test]
    procedure DovrebbeSvuotareIlDizionarioDiLzwDopoQuattromilaVoci;
    [Test]
    procedure DovrebbeComprimereMoltoUnaSequenzaDiZeri;
    [Test]
    procedure DovrebbeDareRapportoZeroAlCompressoreNullo;
    [Test]
    procedure DovrebbeDareRapportoNegativoSeIDatiSonoCasuali;
    [Test]
    procedure DovrebbeUsareLaFabbricaPerOgniCompressore;
    [Test]
    procedure DovrebbeNonModificareIlFlussoSeNonSiScrive;
  end;

implementation

{ TTestCompressors }

function TTestCompressors.RandomBytes(ACount: Integer; ASeed: Cardinal): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    ASeed := ASeed * 1664525 + 1013904223;
    Result[LIndex] := Byte(ASeed shr 24);
  end;
end;

function TTestCompressors.Compress(const ACompressor: ICompressor; const AData: TBytes; AWordLength: Integer): TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    ACompressor.Init(LStream, True, AWordLength);
    ACompressor.Write(AData);
    ACompressor.FinishCompress;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function TTestCompressors.Decompress(const ACompressor: ICompressor; const ACompressed: TBytes;
  ALength, AWordLength: Integer): TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create(ACompressed);
  try
    ACompressor.Init(LStream, False, AWordLength);
    SetLength(Result, ALength + 16);
    FillChar(Result[0], Length(Result), 0);
    ACompressor.Read(@Result[0], ALength);
    SetLength(Result, ALength);
  finally
    LStream.Free;
  end;
end;

procedure TTestCompressors.CheckRoundTrip(const ACreate: TFunc<ICompressor>; const AData: TBytes; AWordLength: Integer);
var
  LCompressed, LBack: TBytes;
begin
  LCompressed := Compress(ACreate(), AData, AWordLength);
  LBack := Decompress(ACreate(), LCompressed, Length(AData), AWordLength);
  Assert.AreEqual<Integer>(Length(AData), Length(LBack));
  Assert.IsTrue(CompareMem(@AData[0], @LBack[0], Length(AData)), 'i dati non sono tornati uguali');
end;

procedure TTestCompressors.NonDovrebbeComprimereSeNonComprime;
var
  LData, LCompressed: TBytes;
begin
  LData := RandomBytes(300, 7);
  LCompressed := Compress(TCompressorFactory.CreateNoCompression, LData, 8);
  Assert.AreEqual<Integer>(300, Length(LCompressed));
  Assert.IsTrue(CompareMem(@LData[0], @LCompressed[0], 300));
end;

procedure TTestCompressors.DovrebbeRifiutareLaLetturaInCompressione;
var
  LStream: TMemoryStream;
  LBuffer: array[0..3] of Byte;
  LCompressor: ICompressor;
begin
  LStream := TMemoryStream.Create;
  try
    LCompressor := TCompressorFactory.CreateNoCompression;
    LCompressor.Init(LStream, True, 8);
    Assert.AreEqual(0, LCompressor.Read(@LBuffer[0], 4));
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeRifiutareLaScritturaInDecompressione;
var
  LStream: TMemoryStream;
  LBuffer: array[0..3] of Byte;
  LCompressor: ICompressor;
begin
  LStream := TMemoryStream.Create;
  try
    LCompressor := TCompressorFactory.CreateLzss;
    LCompressor.Init(LStream, False, 8);
    LBuffer[0] := 1;
    Assert.AreEqual(0, LCompressor.Write(@LBuffer[0], 4));
    Assert.AreEqual(0, Integer(LStream.Size));
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeDareZeroPerLunghezzeNonPositive;
var
  LStream: TMemoryStream;
  LBuffer: Byte;
  LCompressor: ICompressor;
  LFactory: TFunc<ICompressor>;
  LIndex: Integer;
  LCreators: TArray<TFunc<ICompressor>>;
begin
  LCreators := [
    function: ICompressor begin Result := TCompressorFactory.CreateNoCompression; end,
    function: ICompressor begin Result := TCompressorFactory.CreateBitStream; end,
    function: ICompressor begin Result := TCompressorFactory.CreateRunLength; end,
    function: ICompressor begin Result := TCompressorFactory.CreateRunLengthZeroBased; end,
    function: ICompressor begin Result := TCompressorFactory.CreateHuffman; end,
    function: ICompressor begin Result := TCompressorFactory.CreateArithmetic; end,
    function: ICompressor begin Result := TCompressorFactory.CreateLzss; end];
  LBuffer := 0;
  for LIndex := 0 to High(LCreators) do
  begin
    LFactory := LCreators[LIndex];
    LStream := TMemoryStream.Create;
    try
      LCompressor := LFactory();
      LCompressor.Init(LStream, True, 8);
      Assert.AreEqual(0, LCompressor.Write(@LBuffer, 0), 'compressore ' + IntToStr(LIndex));
      Assert.AreEqual(0, LCompressor.Write(@LBuffer, -3));
      LCompressor.Init(LStream, False, 8);
      Assert.AreEqual(0, LCompressor.Read(@LBuffer, 0));
      Assert.AreEqual(0, LCompressor.Read(@LBuffer, -1));
    finally
      LCompressor := nil;
      LStream.Free;
    end;
  end;
end;

procedure TTestCompressors.DovrebbeRifiutareUnFlussoMancante;
var
  LCompressor: ICompressor;
begin
  LCompressor := TCompressorFactory.CreateHuffman;
  Assert.WillRaise(
    procedure
    begin
      LCompressor.Init(nil, True, 8);
    end, ECompressionException);
end;

procedure TTestCompressors.DovrebbeRifiutareUnaLunghezzaDiParolaFuoriIntervallo;
var
  LStream: TMemoryStream;
  LCompressor: ICompressor;
begin
  LStream := TMemoryStream.Create;
  try
    LCompressor := TCompressorFactory.CreateRunLength;
    Assert.WillRaise(
      procedure
      begin
        LCompressor.Init(LStream, True, 0);
      end, ECompressionException);
    Assert.WillRaise(
      procedure
      begin
        LCompressor.Init(LStream, True, 33);
      end, ECompressionException);
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeRifiutareLaRicerca;
var
  LStream: TMemoryStream;
  LCompressor: ICompressor;
begin
  LStream := TMemoryStream.Create;
  try
    LCompressor := TCompressorFactory.CreateNoCompression;
    LCompressor.Init(LStream, True, 8);
    Assert.WillRaise(
      procedure
      begin
        LCompressor.Seek(0, soBeginning);
      end, ECompressionException);
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeRiferireLunghezzaEPosizioneDelFlusso;
var
  LStream: TMemoryStream;
  LCompressor: ICompressor;
  LData: TBytes;
begin
  LCompressor := TCompressorFactory.CreateNoCompression;
  Assert.AreEqual(0, LCompressor.Length);
  Assert.AreEqual(0, LCompressor.Tell);
  LStream := TMemoryStream.Create;
  try
    LCompressor.Init(LStream, True, 8);
    LData := RandomBytes(10, 1);
    LCompressor.Write(LData);
    Assert.AreEqual(10, LCompressor.Length);
    Assert.AreEqual(10, LCompressor.Tell);
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeUsareLeOverloadSuTBytes;
var
  LStream: TBytesStream;
  LCompressor: ICompressor;
  LData, LBack: TBytes;
begin
  LData := RandomBytes(100, 3);
  LStream := TBytesStream.Create;
  try
    LCompressor := TCompressorFactory.CreateNoCompression;
    LCompressor.Init(LStream, True, 8);
    Assert.AreEqual(100, LCompressor.Write(LData));
    Assert.AreEqual(0, LCompressor.Write(nil));
    LStream.Position := 0;
    LCompressor.Init(LStream, False, 8);
    Assert.AreEqual(100, LCompressor.Read(LBack, 100));
    Assert.IsTrue(CompareMem(@LData[0], @LBack[0], 100));
    Assert.AreEqual(0, LCompressor.Read(LBack, 0));
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeFareAndataERitornoDiTuttiICompressori;
var
  LData: TBytes;
  LCreators: TArray<TFunc<ICompressor>>;
  LIndex: Integer;
begin
  LData := RandomBytes(5000, 11);
  // some structure so the matches and runs are exercised
  for LIndex := 1000 to 2999 do
    LData[LIndex] := Byte(LIndex div 50);
  LCreators := [
    function: ICompressor begin Result := TCompressorFactory.CreateNoCompression; end,
    function: ICompressor begin Result := TCompressorFactory.CreateBitStream; end,
    function: ICompressor begin Result := TCompressorFactory.CreateRunLength; end,
    function: ICompressor begin Result := TCompressorFactory.CreateRunLengthZeroBased; end,
    function: ICompressor begin Result := TCompressorFactory.CreateHuffman; end,
    function: ICompressor begin Result := TCompressorFactory.CreateArithmetic; end,
    function: ICompressor begin Result := TCompressorFactory.CreateLzss; end,
    function: ICompressor begin Result := TCompressorFactory.CreateLzssWordAligned; end,
    function: ICompressor begin Result := TCompressorFactory.CreateLzw; end];
  for LIndex := 0 to High(LCreators) do
    CheckRoundTrip(LCreators[LIndex], LData, 8);
end;

procedure TTestCompressors.DovrebbeFareAndataERitornoDiUnSoloByte;
var
  LData: TBytes;
begin
  LData := TBytes.Create(77);
  CheckRoundTrip(function: ICompressor begin Result := TCompressorFactory.CreateHuffman; end, LData, 8);
  CheckRoundTrip(function: ICompressor begin Result := TCompressorFactory.CreateLzw; end, LData, 8);
  CheckRoundTrip(function: ICompressor begin Result := TCompressorFactory.CreateLzss; end, LData, 8);
  CheckRoundTrip(function: ICompressor begin Result := TCompressorFactory.CreateArithmetic; end, LData, 8);
end;

procedure TTestCompressors.DovrebbeFareAndataERitornoDiTuttiIValoriDiByte;
var
  LData: TBytes;
  LIndex: Integer;
begin
  // every symbol is new to the adaptive Huffman tree: the NYT path and all the swaps
  SetLength(LData, 256 * 4);
  for LIndex := 0 to High(LData) do
    LData[LIndex] := Byte((LIndex * 7) and 255);
  CheckRoundTrip(function: ICompressor begin Result := TCompressorFactory.CreateHuffman; end, LData, 8);
end;

procedure TTestCompressors.DovrebbeSvuotareIlDizionarioDiLzwDopoQuattromilaVoci;
var
  LData: TBytes;
begin
  LData := RandomBytes(30000, 5);
  CheckRoundTrip(function: ICompressor begin Result := TCompressorFactory.CreateLzw; end, LData, 8);
end;

procedure TTestCompressors.DovrebbeComprimereMoltoUnaSequenzaDiZeri;
var
  LData, LCompressed: TBytes;
begin
  SetLength(LData, 4000);
  FillChar(LData[0], 4000, 0);
  LCompressed := Compress(TCompressorFactory.CreateRunLengthZeroBased, LData, 8);
  Assert.IsTrue(Length(LCompressed) < 100, 'lunghezza ' + IntToStr(Length(LCompressed)));
  LCompressed := Compress(TCompressorFactory.CreateLzw, LData, 8);
  Assert.IsTrue(Length(LCompressed) < 200, 'lunghezza ' + IntToStr(Length(LCompressed)));
end;

procedure TTestCompressors.DovrebbeDareRapportoZeroAlCompressoreNullo;
var
  LCompressor: ICompressor;
begin
  LCompressor := TCompressorFactory.CreateNoCompression;
  Assert.AreEqual(Single(0.0), LCompressor.GetCompressionRatio);
end;

procedure TTestCompressors.DovrebbeDareRapportoNegativoSeIDatiSonoCasuali;
var
  LStream: TBytesStream;
  LCompressor: ICompressor;
  LData: TBytes;
begin
  LData := RandomBytes(3000, 2);
  LStream := TBytesStream.Create;
  try
    LCompressor := TCompressorFactory.CreateHuffman;
    LCompressor.Init(LStream, True, 8);
    LCompressor.Write(LData);
    LCompressor.FinishCompress;
    Assert.IsTrue(LCompressor.GetCompressionRatio < 0);
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

procedure TTestCompressors.DovrebbeUsareLaFabbricaPerOgniCompressore;
begin
  Assert.IsNotNull(TCompressorFactory.CreateNoCompression);
  Assert.IsNotNull(TCompressorFactory.CreateBitStream);
  Assert.IsNotNull(TCompressorFactory.CreateRunLength);
  Assert.IsNotNull(TCompressorFactory.CreateRunLengthZeroBased);
  Assert.IsNotNull(TCompressorFactory.CreateHuffman);
  Assert.IsNotNull(TCompressorFactory.CreateArithmetic);
  Assert.IsNotNull(TCompressorFactory.CreateLzss);
  Assert.IsNotNull(TCompressorFactory.CreateLzssWordAligned);
  Assert.IsNotNull(TCompressorFactory.CreateLzw);
end;

procedure TTestCompressors.DovrebbeNonModificareIlFlussoSeNonSiScrive;
var
  LStream: TMemoryStream;
  LCompressor: ICompressor;
begin
  LStream := TMemoryStream.Create;
  try
    LCompressor := TCompressorFactory.CreateBitStream;
    LCompressor.Init(LStream, True, 8);
    LCompressor.FinishCompress;
    Assert.AreEqual(0, Integer(LStream.Size));
    LCompressor.Init(LStream, False, 8);
    LCompressor.FinishCompress;
    Assert.AreEqual(0, Integer(LStream.Size));
  finally
    LCompressor := nil;
    LStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCompressors);

end.
