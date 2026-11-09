{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the yaml library - the conversions of scalars          }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Yaml.Convert;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Yaml.Types;

type
  [TestFixture]
  [Category('yaml')]
  TTestYamlConvert = class(TObject)
  public
    [Test]
    [TestCase('decimale', '42,42')]
    [TestCase('negativo', '-7,-7')]
    [TestCase('piu', '+5,5')]
    [TestCase('esadecimale', '0x1F,31')]
    [TestCase('esadecimale maiuscolo', '0XfF,255')]
    [TestCase('ottale', '010,8')]
    [TestCase('zero', '0,0')]
    [TestCase('spazi dopo', '5  ,5')]
    procedure DovrebbeLeggereGliInteriCheIlStreamLegge(const AText: string; AExpected: Integer);
    [Test]
    [TestCase('vuoto', '')]
    [TestCase('spazio prima', ' 5')]
    [TestCase('lettere dopo', '5x')]
    [TestCase('esadecimale senza cifre', '0x')]
    [TestCase('non ottale', '08')]
    [TestCase('binario', '0b1')]
    [TestCase('troppo grande', '2147483648')]
    [TestCase('decimale', '1.5')]
    procedure DovrebbeRifiutareIlTestoCheNonEUnIntero(const AText: string);
    [Test]
    procedure DovrebbeAccettareIlMinimoEIlMassimoDiOgniTipo;
    [Test]
    procedure DovrebbeRifiutareUnNegativoPerGliInteriSenzaSegno;
    [Test]
    procedure DovrebbeLeggereUnSoloCarattere;
    [Test]
    procedure DovrebbeLeggereIDecimaliEGliSpeciali;
    [Test]
    [TestCase('1e5', '1e5,100000')]
    [TestCase('punto finale', '5.,5')]
    [TestCase('punto iniziale', '.5,0.5')]
    [TestCase('esponente negativo', '-.5e-3,-0.0005')]
    procedure DovrebbeLeggereLeFormeDelDouble(const AText: string; AExpected: Double);
    [Test]
    [TestCase('y', 'y,True')]
    [TestCase('N', 'N,False')]
    [TestCase('Yes', 'Yes,True')]
    [TestCase('NO', 'NO,False')]
    [TestCase('true', 'true,True')]
    [TestCase('FALSE', 'FALSE,False')]
    [TestCase('On', 'On,True')]
    [TestCase('off', 'off,False')]
    procedure DovrebbeLeggereLeFormeDeiBooleani(const AText: string; AExpected: Boolean);
    [Test]
    procedure DovrebbeRifiutareIBooleaniInCaseMisto;
    [Test]
    procedure DovrebbeScrivereIDoubleCome_printf_g;
    [Test]
    procedure DovrebbeScrivereLeCifreEsatteDiUnDouble;
    [Test]
    procedure DovrebbeFareLaBase64DiUnBuffer;
    [Test]
    procedure DovrebbeRifiutareUnaBase64NonValida;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Yaml.Convert;

procedure TTestYamlConvert.DovrebbeLeggereGliInteriCheIlStreamLegge(const AText: string; AExpected: Integer);
var
  LValue: Integer;
begin
  Assert.IsTrue(TYamlConvert.TryInt32(YamlStringToText(AText), LValue));
  Assert.AreEqual(AExpected, LValue);
end;

procedure TTestYamlConvert.DovrebbeRifiutareIlTestoCheNonEUnIntero(const AText: string);
var
  LValue: Integer;
begin
  Assert.IsFalse(TYamlConvert.TryInt32(YamlStringToText(AText), LValue));
end;

procedure TTestYamlConvert.DovrebbeAccettareIlMinimoEIlMassimoDiOgniTipo;
var
  L32: Integer;
  LU32: Cardinal;
  L64: Int64;
  LU64: UInt64;
  L16: SmallInt;
  LU16: Word;
  L8: ShortInt;
  LU8: Byte;
begin
  Assert.IsTrue(TYamlConvert.TryInt32('-2147483648', L32));
  Assert.AreEqual(Low(Integer), L32);
  Assert.IsFalse(TYamlConvert.TryInt32('-2147483649', L32));
  Assert.IsTrue(TYamlConvert.TryUInt32('4294967295', LU32));
  Assert.IsFalse(TYamlConvert.TryUInt32('4294967296', LU32));
  Assert.IsTrue(TYamlConvert.TryInt64('-9223372036854775808', L64));
  Assert.AreEqual(Low(Int64), L64);
  Assert.IsFalse(TYamlConvert.TryInt64('9223372036854775808', L64));
  Assert.IsTrue(TYamlConvert.TryUInt64('18446744073709551615', LU64));
  Assert.IsFalse(TYamlConvert.TryUInt64('18446744073709551616', LU64));
  Assert.IsTrue(TYamlConvert.TryInt16('-32768', L16));
  Assert.IsFalse(TYamlConvert.TryInt16('32768', L16));
  Assert.IsTrue(TYamlConvert.TryUInt16('65535', LU16));
  Assert.IsFalse(TYamlConvert.TryUInt16('65536', LU16));
  Assert.IsTrue(TYamlConvert.TryInt8('-128', L8));
  Assert.IsFalse(TYamlConvert.TryInt8('128', L8));
  Assert.IsTrue(TYamlConvert.TryUInt8('255', LU8));
  Assert.IsFalse(TYamlConvert.TryUInt8('256', LU8));
end;

procedure TTestYamlConvert.DovrebbeRifiutareUnNegativoPerGliInteriSenzaSegno;
var
  LU32: Cardinal;
  LU64: UInt64;
begin
  Assert.IsFalse(TYamlConvert.TryUInt32('-1', LU32));
  Assert.IsFalse(TYamlConvert.TryUInt64('-0', LU64));
end;

procedure TTestYamlConvert.DovrebbeLeggereUnSoloCarattere;
var
  LChar: AnsiChar;
begin
  Assert.IsTrue(TYamlConvert.TryChar('a', LChar));
  Assert.AreEqual('a', string(LChar));
  Assert.IsTrue(TYamlConvert.TryChar('a ', LChar), 'gli spazi dopo ci possono essere');
  Assert.IsFalse(TYamlConvert.TryChar('ab', LChar));
  Assert.IsFalse(TYamlConvert.TryChar('', LChar));
end;

procedure TTestYamlConvert.DovrebbeLeggereIDecimaliEGliSpeciali;
var
  LDouble: Double;
  LSingle: Single;
begin
  Assert.IsTrue(TYamlConvert.TryDouble('.inf', LDouble));
  Assert.IsTrue(LDouble > 1e308);
  Assert.IsTrue(TYamlConvert.TryDouble('-.INF', LDouble));
  Assert.IsTrue(LDouble < -1e308);
  Assert.IsTrue(TYamlConvert.TryDouble('.NaN', LDouble));
  Assert.IsTrue(LDouble <> LDouble);
  Assert.IsFalse(TYamlConvert.TryDouble('inf', LDouble));
  Assert.IsFalse(TYamlConvert.TryDouble('1e', LDouble));
  Assert.IsFalse(TYamlConvert.TryDouble('1.2.3', LDouble));
  Assert.IsFalse(TYamlConvert.TryDouble('0x10', LDouble));
  Assert.IsFalse(TYamlConvert.TryDouble('1e400', LDouble));
  Assert.IsTrue(TYamlConvert.TrySingle('0.5', LSingle));
  Assert.IsFalse(TYamlConvert.TrySingle('1e39', LSingle));
end;

procedure TTestYamlConvert.DovrebbeLeggereLeFormeDelDouble(const AText: string; AExpected: Double);
var
  LValue: Double;
begin
  Assert.IsTrue(TYamlConvert.TryDouble(YamlStringToText(AText), LValue));
  Assert.AreEqual(AExpected, LValue, 0);
end;

procedure TTestYamlConvert.DovrebbeLeggereLeFormeDeiBooleani(const AText: string; AExpected: Boolean);
var
  LValue: Boolean;
begin
  Assert.IsTrue(TYamlConvert.TryBool(YamlStringToText(AText), LValue));
  Assert.AreEqual(AExpected, LValue);
end;

procedure TTestYamlConvert.DovrebbeRifiutareIBooleaniInCaseMisto;
var
  LValue: Boolean;
begin
  Assert.IsFalse(TYamlConvert.TryBool('tRue', LValue));
  Assert.IsFalse(TYamlConvert.TryBool('YEs', LValue));
  Assert.IsFalse(TYamlConvert.TryBool('1', LValue));
  Assert.IsFalse(TYamlConvert.TryBool('', LValue));
end;

procedure TTestYamlConvert.DovrebbeScrivereIDoubleCome_printf_g;
begin
  Assert.AreEqual('0', string(TYamlConvert.FormatGeneral(0, 17)));
  Assert.AreEqual('-0', string(TYamlConvert.FormatGeneral(-0.0, 17)));
  Assert.AreEqual('100000', string(TYamlConvert.FormatGeneral(1e5, 6)));
  Assert.AreEqual('1e+06', string(TYamlConvert.FormatGeneral(1e6, 6)));
  Assert.AreEqual('0.0001', string(TYamlConvert.FormatGeneral(1e-4, 6)));
  Assert.AreEqual('1e-05', string(TYamlConvert.FormatGeneral(1e-5, 6)));
  Assert.AreEqual('3.14159', string(TYamlConvert.FormatGeneral(3.14159265358979, 6)));
  Assert.AreEqual('1e+100', string(TYamlConvert.FormatGeneral(1e100, 17)));
  Assert.AreEqual('1', string(TYamlConvert.FormatGeneral(0.9999999, 1)));
  Assert.AreEqual('inf', string(TYamlConvert.FormatGeneral(Infinity, 17)));
end;

procedure TTestYamlConvert.DovrebbeScrivereLeCifreEsatteDiUnDouble;
begin
  Assert.AreEqual('0.10000000000000001', string(TYamlConvert.FormatGeneral(0.1, 17)));
  Assert.AreEqual('0.30000000000000004', string(TYamlConvert.FormatGeneral(0.30000000000000004, 17)));
  Assert.AreEqual('1.7976931348623157e+308', string(TYamlConvert.FormatGeneral(1.7976931348623157E+308, 17)));
  Assert.AreEqual('4.9406564584124654e-324', string(TYamlConvert.FormatGeneral(4.9406564584124654E-324, 17)));
  Assert.AreEqual('0.5', string(TYamlConvert.FormatGeneral(0.5, 17)));
end;

procedure TTestYamlConvert.DovrebbeFareLaBase64DiUnBuffer;
var
  LData, LBack: TBytes;
begin
  SetLength(LData, 5);
  LData[0] := 1;
  LData[1] := 2;
  LData[2] := 3;
  LData[3] := 4;
  LData[4] := 5;
  Assert.AreEqual('AQIDBAU=', string(TYamlConvert.EncodeBase64(LData)));
  LBack := TYamlConvert.DecodeBase64('AQID BAU=');
  Assert.AreEqual(5, Integer(Length(LBack)), 'gli spazi si saltano');
  Assert.AreEqual(5, Integer(LBack[4]));
end;

procedure TTestYamlConvert.DovrebbeRifiutareUnaBase64NonValida;
begin
  Assert.AreEqual(0, Integer(Length(TYamlConvert.DecodeBase64('AQ!D'))));
  Assert.AreEqual(0, Integer(Length(TYamlConvert.DecodeBase64(''))));
end;

end.
