{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the platform library - the PE header                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Platform.PeImageReader;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Platform.PeImageReader;

type
  [TestFixture]
  [Category('platform')]
  TTestPlatformPeImageReader = class(TObject)
  private
    function MakePe(AMagic, AOptionalSize: Word; AImageSize: Cardinal): TBytesStream;
  public
    [Test]
    procedure DovrebbeLeggereLaDimensioneDiUnPe32;
    [Test]
    procedure DovrebbeLeggereLaDimensioneDiUnPe32Plus;
    [Test]
    procedure DovrebbeDareZeroSeMancaMZ;
    [Test]
    procedure DovrebbeDareZeroSeMancaLaFirmaPE;
    [Test]
    procedure DovrebbeDareZeroSeLOffsetDellIntestazioneENullo;
    [Test]
    procedure DovrebbeDareZeroSeLaMagiaNonCorrispondeAllaDimensione;
    [Test]
    procedure DovrebbeDareZeroSeLoStreamEVuoto;
    [Test]
    procedure DovrebbeDareZeroSeLoStreamEInterrotto;
    [Test]
    procedure DovrebbeLeggereIlProgrammaStesso;
  end;

implementation

{ TTestPlatformPeImageReader }

function TTestPlatformPeImageReader.MakePe(AMagic, AOptionalSize: Word;
  AImageSize: Cardinal): TBytesStream;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, $80 + 4 + 20 + 64);
  FillChar(LBytes[0], Length(LBytes), 0);
  LBytes[0] := Ord('M');
  LBytes[1] := Ord('Z');
  PCardinal(@LBytes[$3C])^ := $80;
  PCardinal(@LBytes[$80])^ := $00004550;
  PWord(@LBytes[$80 + 4 + 16])^ := AOptionalSize;
  PWord(@LBytes[$80 + 4 + 20])^ := AMagic;
  PCardinal(@LBytes[$80 + 4 + 20 + 56])^ := AImageSize;
  Result := TBytesStream.Create(LBytes);
end;

procedure TTestPlatformPeImageReader.DovrebbeLeggereLaDimensioneDiUnPe32;
var
  LStream: TBytesStream;
begin
  LStream := MakePe($10B, 224, $12345678);
  try
    Assert.AreEqual($12345678, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeLeggereLaDimensioneDiUnPe32Plus;
var
  LStream: TBytesStream;
begin
  // il vecchio codice accettava solo i file a 32 bit
  LStream := MakePe($20B, 240, $00ABCDEF);
  try
    Assert.AreEqual($00ABCDEF, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeDareZeroSeMancaMZ;
var
  LStream: TBytesStream;
begin
  LStream := MakePe($10B, 224, 99);
  try
    LStream.Bytes[0] := Ord('X');
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeDareZeroSeMancaLaFirmaPE;
var
  LStream: TBytesStream;
begin
  LStream := MakePe($10B, 224, 99);
  try
    LStream.Bytes[$80] := Ord('X');
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeDareZeroSeLOffsetDellIntestazioneENullo;
var
  LStream: TBytesStream;
begin
  LStream := MakePe($10B, 224, 99);
  try
    PCardinal(@LStream.Bytes[$3C])^ := 0;
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeDareZeroSeLaMagiaNonCorrispondeAllaDimensione;
var
  LStream: TBytesStream;
begin
  LStream := MakePe($10B, 240, 99);
  try
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
  LStream := MakePe($20B, 224, 99);
  try
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeDareZeroSeLoStreamEVuoto;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeDareZeroSeLoStreamEInterrotto;
var
  LStream: TBytesStream;
begin
  LStream := MakePe($10B, 224, 99);
  try
    LStream.Size := $80 + 4 + 20 + 10;
    Assert.AreEqual(0, Integer(TPeImageReader.ReadImageSize(LStream)));
  finally
    LStream.Free;
  end;
end;

procedure TTestPlatformPeImageReader.DovrebbeLeggereIlProgrammaStesso;
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyNone);
  try
    Assert.IsTrue(TPeImageReader.ReadImageSize(LStream) > 0);
  finally
    LStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPlatformPeImageReader);

end.
