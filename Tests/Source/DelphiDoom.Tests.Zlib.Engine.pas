{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TZlibEngine                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf;

type
  [TestFixture]
  [Category('zlib')]
  TTestZlibEngine = class(TObject)
  private
    FZlib: IZlib;
    function MakeSample(ASize: Integer): TBytes;
    function CompressAll(const ASample: TBytes): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestVersion;
    [Test]
    [TestCase('Vuoto', '0')]
    [TestCase('Piccolo', '100')]
    [TestCase('Grande', '1000000')]
    procedure TestCompressBoundIsNotSmallerThanSource(ASize: Integer);
    [Test]
    [TestCase('Piccolo', '100')]
    [TestCase('Medio', '65536')]
    [TestCase('Grande', '1000000')]
    procedure TestRoundTrip(ASize: Integer);
    [Test]
    procedure TestRepetitiveDataIsCompressed;
    [Test]
    procedure TestCompressIntoTooSmallBufferReturnsBufError;
    [Test]
    procedure TestUncompressIntoTooSmallBufferReturnsBufError;
    [Test]
    procedure TestUncompressGarbageReturnsDataError;
    [Test]
    procedure TestUncompressTruncatedInputReturnsBufError;
    [Test]
    procedure TestUncompressRawDeflate;
    [Test]
    procedure TestUncompressAutoDetectsZlib;
    [Test]
    procedure TestStreamingRoundTrip;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine;

{ TTestZlibEngine }

procedure TTestZlibEngine.Setup;
begin
  FZlib := TZlibEngine.Create;
end;

procedure TTestZlibEngine.TearDown;
begin
  FZlib := nil;
end;

function TTestZlibEngine.MakeSample(ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := Byte((LIndex * 7 + (LIndex shr 8)) and $FF);
end;

function TTestZlibEngine.CompressAll(const ASample: TBytes): TBytes;
var
  LSize: Cardinal;
begin
  LSize := FZlib.CompressBound(Length(ASample));
  SetLength(Result, LSize);
  Assert.AreEqual(ZLIB_OK, FZlib.Compress(Pointer(ASample), Length(ASample),
    Pointer(Result), LSize, ZLIB_DEFAULT_LEVEL));
  SetLength(Result, LSize);
end;

procedure TTestZlibEngine.TestVersion;
begin
  Assert.AreEqual('1.2.8', string(AnsiString(FZlib.GetVersion)));
end;

procedure TTestZlibEngine.TestCompressBoundIsNotSmallerThanSource(ASize: Integer);
begin
  Assert.IsTrue(FZlib.CompressBound(ASize) >= Cardinal(ASize));
end;

procedure TTestZlibEngine.TestRoundTrip(ASize: Integer);
var
  LSample, LCompressed, LRestored: TBytes;
  LSize: Cardinal;
begin
  LSample := MakeSample(ASize);
  LCompressed := CompressAll(LSample);

  SetLength(LRestored, ASize);
  LSize := ASize;
  Assert.AreEqual(ZLIB_OK, FZlib.Uncompress(Pointer(LCompressed),
    Length(LCompressed), Pointer(LRestored), LSize, TZlibFormat.Zlib));
  Assert.AreEqual(Cardinal(ASize), LSize);
  Assert.AreEqualMemory(Pointer(LSample), Pointer(LRestored), ASize);
end;

procedure TTestZlibEngine.TestRepetitiveDataIsCompressed;
var
  LSample: TBytes;
begin
  SetLength(LSample, 100000);
  FillChar(LSample[0], Length(LSample), 65);
  Assert.IsTrue(Length(CompressAll(LSample)) < 1000);
end;

procedure TTestZlibEngine.TestCompressIntoTooSmallBufferReturnsBufError;
var
  LSample, LDest: TBytes;
  LSize: Cardinal;
begin
  LSample := MakeSample(10000);
  SetLength(LDest, 8);
  LSize := Length(LDest);
  Assert.AreEqual(ZLIB_BUF_ERROR, FZlib.Compress(Pointer(LSample),
    Length(LSample), Pointer(LDest), LSize, ZLIB_DEFAULT_LEVEL));
end;

procedure TTestZlibEngine.TestUncompressIntoTooSmallBufferReturnsBufError;
var
  LCompressed, LDest: TBytes;
  LSize: Cardinal;
begin
  LCompressed := CompressAll(MakeSample(10000));
  SetLength(LDest, 100);
  LSize := Length(LDest);
  Assert.AreEqual(ZLIB_BUF_ERROR, FZlib.Uncompress(Pointer(LCompressed),
    Length(LCompressed), Pointer(LDest), LSize, TZlibFormat.Zlib));
end;

procedure TTestZlibEngine.TestUncompressGarbageReturnsDataError;
var
  LGarbage, LDest: TBytes;
  LSize: Cardinal;
  LIndex: Integer;
begin
  SetLength(LGarbage, 64);
  for LIndex := 0 to High(LGarbage) do
    LGarbage[LIndex] := Byte(LIndex * 13 + 1);
  SetLength(LDest, 1000);
  LSize := Length(LDest);
  Assert.AreEqual(ZLIB_DATA_ERROR, FZlib.Uncompress(Pointer(LGarbage),
    Length(LGarbage), Pointer(LDest), LSize, TZlibFormat.Zlib));
end;

procedure TTestZlibEngine.TestUncompressTruncatedInputReturnsBufError;
var
  LCompressed, LDest: TBytes;
  LSize: Cardinal;
begin
  LCompressed := CompressAll(MakeSample(10000));
  SetLength(LDest, 10000);
  LSize := Length(LDest);
  Assert.AreEqual(ZLIB_BUF_ERROR, FZlib.Uncompress(Pointer(LCompressed),
    Length(LCompressed) div 2, Pointer(LDest), LSize, TZlibFormat.Zlib));
end;

procedure TTestZlibEngine.TestUncompressRawDeflate;
var
  LSample, LCompressed, LRaw, LRestored: TBytes;
  LSize: Cardinal;
begin
  LSample := MakeSample(5000);
  LCompressed := CompressAll(LSample);
  // zlib format = 2 bytes of header + raw deflate + 4 bytes of Adler-32
  LRaw := Copy(LCompressed, 2, Length(LCompressed) - 6);

  SetLength(LRestored, Length(LSample));
  LSize := Length(LRestored);
  Assert.AreEqual(ZLIB_OK, FZlib.Uncompress(Pointer(LRaw), Length(LRaw),
    Pointer(LRestored), LSize, TZlibFormat.Raw));
  Assert.AreEqualMemory(Pointer(LSample), Pointer(LRestored), Length(LSample));
end;

procedure TTestZlibEngine.TestUncompressAutoDetectsZlib;
var
  LSample, LCompressed, LRestored: TBytes;
  LSize: Cardinal;
begin
  LSample := MakeSample(5000);
  LCompressed := CompressAll(LSample);

  SetLength(LRestored, Length(LSample));
  LSize := Length(LRestored);
  Assert.AreEqual(ZLIB_OK, FZlib.Uncompress(Pointer(LCompressed),
    Length(LCompressed), Pointer(LRestored), LSize, TZlibFormat.Auto));
  Assert.AreEqualMemory(Pointer(LSample), Pointer(LRestored), Length(LSample));
end;

procedure TTestZlibEngine.TestStreamingRoundTrip;
const
  CHUNK_IN = 97;
  CHUNK_OUT = 61;
var
  LSample, LCompressed, LRestored: TBytes;
  LDeflater: IZlibDeflater;
  LInflater: IZlibInflater;
  LBuffers: TZlibStreamBuffers;
  LOutBuf: array[0..CHUNK_OUT - 1] of Byte;
  LCode: Integer;
  LUsed, LFeed: Cardinal;
  LPos: Integer;
begin
  LSample := MakeSample(20000);

  // Compress feeding the input in small pieces and collecting small outputs
  Assert.AreEqual(ZLIB_OK, FZlib.CreateDeflater(ZLIB_DEFAULT_LEVEL, LDeflater));
  FillChar(LBuffers, SizeOf(LBuffers), 0);
  LPos := 0;
  repeat
    LFeed := Cardinal(Length(LSample) - LPos);
    if LFeed > CHUNK_IN then
      LFeed := CHUNK_IN;
    LBuffers.NextIn := @LSample[LPos];
    LBuffers.AvailIn := LFeed;
    repeat
      LBuffers.NextOut := @LOutBuf[0];
      LBuffers.AvailOut := CHUNK_OUT;
      if LPos + Integer(LFeed) >= Length(LSample) then
        LCode := LDeflater.Deflate(LBuffers, ZLIB_FINISH)
      else
        LCode := LDeflater.Deflate(LBuffers, ZLIB_NO_FLUSH);
      Assert.IsTrue((LCode = ZLIB_OK) or (LCode = ZLIB_STREAM_END) or (LCode = ZLIB_BUF_ERROR));
      LUsed := CHUNK_OUT - LBuffers.AvailOut;
      SetLength(LCompressed, Length(LCompressed) + Integer(LUsed));
      if LUsed > 0 then
        Move(LOutBuf[0], LCompressed[Length(LCompressed) - Integer(LUsed)], LUsed);
    until (LBuffers.AvailOut > 0) or (LCode = ZLIB_STREAM_END);
    Inc(LPos, Integer(LFeed));
  until LCode = ZLIB_STREAM_END;

  // Decompress it the same way
  Assert.AreEqual(ZLIB_OK, FZlib.CreateInflater(TZlibFormat.Zlib, LInflater));
  FillChar(LBuffers, SizeOf(LBuffers), 0);
  LPos := 0;
  repeat
    LFeed := Cardinal(Length(LCompressed) - LPos);
    if LFeed > CHUNK_IN then
      LFeed := CHUNK_IN;
    LBuffers.NextIn := @LCompressed[LPos];
    LBuffers.AvailIn := LFeed;
    repeat
      LBuffers.NextOut := @LOutBuf[0];
      LBuffers.AvailOut := CHUNK_OUT;
      LCode := LInflater.Inflate(LBuffers, ZLIB_NO_FLUSH);
      Assert.IsTrue((LCode = ZLIB_OK) or (LCode = ZLIB_STREAM_END) or (LCode = ZLIB_BUF_ERROR));
      LUsed := CHUNK_OUT - LBuffers.AvailOut;
      SetLength(LRestored, Length(LRestored) + Integer(LUsed));
      if LUsed > 0 then
        Move(LOutBuf[0], LRestored[Length(LRestored) - Integer(LUsed)], LUsed);
    until (LBuffers.AvailOut > 0) or (LCode = ZLIB_STREAM_END);
    Inc(LPos, Integer(LFeed));
  until (LCode = ZLIB_STREAM_END) or (LPos >= Length(LCompressed));

  Assert.AreEqual(Length(LSample), Length(LRestored));
  Assert.AreEqualMemory(Pointer(LSample), Pointer(LRestored), Length(LSample));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibEngine);

end.
