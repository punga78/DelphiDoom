{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TZlibClient                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zlib.Client;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf,
  DelphiDoom.Zlib.Client;

type
  [TestFixture]
  [Category('zlib')]
  TTestZlibClient = class(TObject)
  private
    FClient: TZlibClient;
    function MakeSample(ASize: Integer): TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateWithoutZlibRaises;
    [Test]
    procedure TestVersion;
    [Test]
    [TestCase('Vuoto', '0')]
    [TestCase('Piccolo', '100')]
    [TestCase('Grande', '300000')]
    procedure TestRoundTripWithKnownSize(ASize: Integer);
    [Test]
    [TestCase('Piccolo', '100')]
    [TestCase('Grande', '300000')]
    procedure TestRoundTripWithUnknownSize(ASize: Integer);
    [Test]
    procedure TestUncompressGarbageRaisesDataError;
    [Test]
    procedure TestUncompressIntoTooSmallBufferRaisesBufError;
    [Test]
    procedure DovrebbeCreareFlussiDiCompressioneEDecompressione;
    [Test]
    procedure DovrebbeSollevareLErroreDiDatiSenzaMisuraNota;
    [Test]
    procedure DovrebbeSollevareLErroreDiUnLivelloSbagliato;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine;

{ TTestZlibClient }

procedure TTestZlibClient.Setup;
begin
  FClient := TZlibClient.Create(TZlibEngine.Create);
end;

procedure TTestZlibClient.TearDown;
begin
  FreeAndNil(FClient);
end;

function TTestZlibClient.MakeSample(ASize: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 0 to ASize - 1 do
    Result[LIndex] := Byte((LIndex * 5 + (LIndex shr 9)) and $FF);
end;

procedure TTestZlibClient.TestCreateWithoutZlibRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TZlibClient.Create(nil).Free;
    end, EArgumentNilException);
end;

procedure TTestZlibClient.TestVersion;
begin
  Assert.AreEqual('System.ZLib', FClient.Version);
end;

procedure TTestZlibClient.TestRoundTripWithKnownSize(ASize: Integer);
var
  LSample, LRestored: TBytes;
begin
  LSample := MakeSample(ASize);
  LRestored := FClient.Uncompress(FClient.Compress(LSample), ASize);
  Assert.AreEqual<Integer>(ASize, Length(LRestored));
  Assert.AreEqualMemory(Pointer(LSample), Pointer(LRestored), ASize);
end;

procedure TTestZlibClient.TestRoundTripWithUnknownSize(ASize: Integer);
var
  LSample, LRestored: TBytes;
begin
  LSample := MakeSample(ASize);
  LRestored := FClient.Uncompress(FClient.Compress(LSample));
  Assert.AreEqual<Integer>(ASize, Length(LRestored));
  Assert.AreEqualMemory(Pointer(LSample), Pointer(LRestored), ASize);
end;

procedure TTestZlibClient.TestUncompressGarbageRaisesDataError;
var
  LGarbage: TBytes;
  LIndex: Integer;
begin
  SetLength(LGarbage, 64);
  for LIndex := 0 to High(LGarbage) do
    LGarbage[LIndex] := Byte(LIndex * 13 + 1);

  try
    FClient.Uncompress(LGarbage, 1000);
    Assert.Fail('EZlibException expected');
  except
    on E: EZlibException do
      Assert.AreEqual(ZLIB_DATA_ERROR, E.Code);
  end;
end;

procedure TTestZlibClient.TestUncompressIntoTooSmallBufferRaisesBufError;
var
  LCompressed: TBytes;
begin
  LCompressed := FClient.Compress(MakeSample(10000));

  try
    FClient.Uncompress(LCompressed, 100);
    Assert.Fail('EZlibException expected');
  except
    on E: EZlibException do
      Assert.AreEqual(ZLIB_BUF_ERROR, E.Code);
  end;
end;

procedure TTestZlibClient.DovrebbeCreareFlussiDiCompressioneEDecompressione;
begin
  Assert.IsNotNull(FClient.CreateInflater(TZlibFormat.Zlib));
  Assert.IsNotNull(FClient.CreateDeflater(ZLIB_BEST_SPEED));
end;

procedure TTestZlibClient.DovrebbeSollevareLErroreDiDatiSenzaMisuraNota;
begin
  // Only a full buffer is tried again: an error of the data comes out at once
  try
    FClient.Uncompress(TBytes.Create($78, $9C, $FF, $FF, $FF, $FF), TZlibFormat.Zlib);
    Assert.Fail('EZlibException expected');
  except
    on E: EZlibException do
      Assert.AreEqual(ZLIB_DATA_ERROR, E.Code);
  end;
end;

procedure TTestZlibClient.DovrebbeSollevareLErroreDiUnLivelloSbagliato;
begin
  try
    FClient.CreateDeflater(99);
    Assert.Fail('EZlibException expected');
  except
    on E: EZlibException do
      Assert.AreEqual(ZLIB_STREAM_ERROR, E.Code);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZlibClient);

end.
