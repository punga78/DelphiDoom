{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedNames                                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.Names;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedNames = class(TObject)
  public
    [Test]
    [TestCase('Decimale', '42,42')]
    [TestCase('Negativo', '-7,-7')]
    [TestCase('Esadecimale con 0x', '0x1F,31')]
    [TestCase('Esadecimale con dollaro', '$FF,255')]
    [TestCase('Con il cancelletto', '#12,12')]
    [TestCase('Meno e 0x', '-0x10,-16')]
    [TestCase('Testo', 'ABC,0')]
    [TestCase('Vuoto', ',0')]
    [TestCase('Troppo grande', '99999999999,0')]
    [TestCase('Numero e lettere', '12AB,0')]
    procedure DovrebbeLeggereUnNumeroComeAtoiDelVecchioCodice(const AText: string; AExpected: Integer);
    [Test]
    procedure DovrebbeDareLaParteDelNomePrimaDelPunto;
    [Test]
    procedure DovrebbeDareTuttoIlNomeSeNonCeIlPunto;
    [Test]
    procedure DovrebbeDareLEstensione;
    [Test]
    procedure DovrebbeDareIlNumeroCheIlNomeInizia;
    [Test]
    procedure DovrebbeRiconoscereIlNumeroScrittoNelModoCanonico;
    [Test]
    procedure DovrebbeOrdinareIPrimiPerNumeroEPoiPerNome;
    [Test]
    procedure DovrebbeDareZeroAlNomeSenzaNumero;
    [Test]
    procedure DovrebbeRiconoscereLEstensioneSenzaMaiuscole;
    [Test]
    procedure DovrebbeTogliereLEstensioneDiQuattroCaratteri;
    [Test]
    procedure DovrebbeRiempireDiZeriASinistra;
  end;

implementation

uses
  DelphiDoom.Speed.Names;

{ TTestSpeedNames }

procedure TTestSpeedNames.DovrebbeLeggereUnNumeroComeAtoiDelVecchioCodice(const AText: string;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TSpeedNames.ToInteger(AText));
end;

procedure TTestSpeedNames.DovrebbeDareLaParteDelNomePrimaDelPunto;
begin
  Assert.AreEqual('GRAFS', TSpeedNames.Stem('GRAFS.PAL'));
  Assert.AreEqual('A', TSpeedNames.Stem('A.B.C'));
end;

procedure TTestSpeedNames.DovrebbeDareTuttoIlNomeSeNonCeIlPunto;
begin
  Assert.AreEqual('README', TSpeedNames.Stem('README'));
  Assert.AreEqual('', TSpeedNames.Extension('README'));
end;

procedure TTestSpeedNames.DovrebbeDareLEstensione;
begin
  Assert.AreEqual('PAL', TSpeedNames.Extension('GRAFS.PAL'));
  Assert.AreEqual('B.C', TSpeedNames.Extension('A.B.C'));
end;

procedure TTestSpeedNames.DovrebbeDareIlNumeroCheIlNomeInizia;
begin
  Assert.AreEqual(22, TSpeedNames.NumericPrefix('22.IS2'));
  Assert.AreEqual(0, TSpeedNames.NumericPrefix('GND001AA.IS2'));
end;

procedure TTestSpeedNames.DovrebbeRiconoscereIlNumeroScrittoNelModoCanonico;
begin
  Assert.IsTrue(TSpeedNames.HasCanonicalNumberStem('5.IS2'));
  Assert.IsTrue(TSpeedNames.HasCanonicalNumberStem('0.IS2'));
  Assert.IsTrue(TSpeedNames.HasCanonicalNumberStem('36.IS2'));
  Assert.IsFalse(TSpeedNames.HasCanonicalNumberStem('05.IS2'), 'leading zero');
  Assert.IsFalse(TSpeedNames.HasCanonicalNumberStem('0x5.IS2'), 'hexadecimal');
  Assert.IsFalse(TSpeedNames.HasCanonicalNumberStem('XPR026.IS2'));
  Assert.IsFalse(TSpeedNames.HasCanonicalNumberStem('.IS2'), 'no stem');
end;

procedure TTestSpeedNames.DovrebbeOrdinareIPrimiPerNumeroEPoiPerNome;
begin
  Assert.IsTrue(TSpeedNames.Compare('2.IS2', '10.IS2') < 0, '2 before 10');
  Assert.IsTrue(TSpeedNames.Compare('10.IS2', '2.IS2') > 0);
  Assert.IsTrue(TSpeedNames.Compare('AB.IS2', 'AC.IS2') < 0, 'same number: by name');
  Assert.AreEqual(0, TSpeedNames.Compare('A.IS2', 'A.IS2'));
  Assert.IsTrue(TSpeedNames.Compare('ZZ.IS2', '1.IS2') < 0, 'a name without number is 0, before 1');
end;

procedure TTestSpeedNames.DovrebbeDareZeroAlNomeSenzaNumero;
begin
  Assert.AreEqual(0, TSpeedNames.NumericPrefix('MENUS.S3M'));
end;

procedure TTestSpeedNames.DovrebbeRiconoscereLEstensioneSenzaMaiuscole;
begin
  Assert.IsTrue(TSpeedNames.EndsWith('Wall.is2', '.IS2'));
  Assert.IsFalse(TSpeedNames.EndsWith('WALL.PIX', '.IS2'));
  Assert.IsFalse(TSpeedNames.EndsWith('A', '.IS2'));
end;

procedure TTestSpeedNames.DovrebbeTogliereLEstensioneDiQuattroCaratteri;
begin
  Assert.AreEqual('GND001AA', TSpeedNames.WithoutExtension('GND001AA.IS2'));
end;

procedure TTestSpeedNames.DovrebbeRiempireDiZeriASinistra;
begin
  Assert.AreEqual('0007', TSpeedNames.ZeroFill(4, 7));
  Assert.AreEqual('12345', TSpeedNames.ZeroFill(4, 12345));
  Assert.AreEqual('005', TSpeedNames.ZeroFill(3, 5));
end;

end.
