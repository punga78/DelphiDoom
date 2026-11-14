{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixControlRules                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.ControlRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Control.Rules;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixControlRules = class(TObject)
  public
    [Test]
    [TestCase('tasto, energia, avanti', 'True,100,50,0,True')]
    [TestCase('tasto, energia, di lato', 'True,100,0,-40,True')]
    [TestCase('tasto, energia, indietro', 'True,5,-50,0,True')]
    [TestCase('senza tasto', 'False,100,50,0,False')]
    [TestCase('fermo', 'True,100,0,0,False')]
    [TestCase('energia al minimo', 'True,4,50,0,False')]
    [TestCase('energia finita', 'True,0,50,40,False')]
    procedure DovrebbeAccendereIlPostbruciatoreSoloInSpintaEConEnergia(AKeyDown: Boolean; AEnergy, AForward,
      ASide: Integer; AExpected: Boolean);
    [Test]
    [TestCase('fermo', '0,0')]
    [TestCase('avanti', '1638400,655360')]
    [TestCase('indietro', '-1638400,-655360')]
    [TestCase('tronca verso zero', '7,2')]
    [TestCase('velocita massima del volo', '1179648,471859')]
    procedure DovrebbeAggiungereDueQuintiDellaStrada(AMomentum, AExpected: Integer);
    [Test]
    procedure DovrebbeDareLaVelocitaDiRadXSommataAllaStrada;
    [Test]
    procedure DovrebbeConsumareUnPuntoOgniOttoTic;
    [Test]
    procedure DovrebbeConsumareLaRiservaPrimaDellEnergia;
    [Test]
    procedure DovrebbeNonScendereSottoZero;
    [Test]
    procedure DovrebbeChiedereUnaBombaSolaPerOgniPressione;
  end;

implementation

{ TTestRadixControlRules }

procedure TTestRadixControlRules.DovrebbeAccendereIlPostbruciatoreSoloInSpintaEConEnergia(AKeyDown: Boolean;
  AEnergy, AForward, ASide: Integer; AExpected: Boolean);
begin
  Assert.AreEqual(AExpected, TRadixControlRules.AfterburnerOn(AKeyDown, AEnergy, AForward, ASide));
end;

procedure TTestRadixControlRules.DovrebbeAggiungereDueQuintiDellaStrada(AMomentum, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TRadixControlRules.AfterburnerSlide(AMomentum));
end;

procedure TTestRadixControlRules.DovrebbeDareLaVelocitaDiRadXSommataAllaStrada;
const
  MOMENTUM = 50 * 65536;
begin
  // 50 with the run key, 70 with the afterburner: the same ratio of the two moves of Rad-X
  Assert.AreEqual(70 * 65536, MOMENTUM + TRadixControlRules.AfterburnerSlide(MOMENTUM));
end;

procedure TTestRadixControlRules.DovrebbeConsumareUnPuntoOgniOttoTic;
var
  LReserve: Integer;
  LEnergy: Integer;
  LTic: Integer;
  LTaken: Integer;
begin
  LReserve := 0;
  LEnergy := 100;
  LTaken := 0;
  for LTic := 1 to 80 do
    if TRadixControlRules.DrainAfterburner(LTic, LReserve, LEnergy) then
      Inc(LTaken);
  Assert.AreEqual(10, LTaken);
  Assert.AreEqual(90, LEnergy);
  Assert.AreEqual(0, LReserve);
end;

procedure TTestRadixControlRules.DovrebbeConsumareLaRiservaPrimaDellEnergia;
var
  LReserve: Integer;
  LEnergy: Integer;
begin
  LReserve := 1;
  LEnergy := 50;
  Assert.IsTrue(TRadixControlRules.DrainAfterburner(8, LReserve, LEnergy));
  Assert.AreEqual(0, LReserve);
  Assert.AreEqual(50, LEnergy);
  Assert.IsFalse(TRadixControlRules.DrainAfterburner(9, LReserve, LEnergy));
  Assert.IsTrue(TRadixControlRules.DrainAfterburner(16, LReserve, LEnergy));
  Assert.AreEqual(49, LEnergy);
end;

procedure TTestRadixControlRules.DovrebbeNonScendereSottoZero;
var
  LReserve: Integer;
  LEnergy: Integer;
begin
  LReserve := 0;
  LEnergy := 0;
  Assert.IsFalse(TRadixControlRules.DrainAfterburner(8, LReserve, LEnergy));
  Assert.AreEqual(0, LEnergy);
  Assert.AreEqual(0, LReserve);
end;

procedure TTestRadixControlRules.DovrebbeChiedereUnaBombaSolaPerOgniPressione;
var
  LWasDown: Boolean;
begin
  LWasDown := False;
  Assert.IsTrue(TRadixControlRules.PlasmaBombAsked(True, LWasDown));
  Assert.IsFalse(TRadixControlRules.PlasmaBombAsked(True, LWasDown));
  Assert.IsFalse(TRadixControlRules.PlasmaBombAsked(False, LWasDown));
  Assert.IsFalse(LWasDown);
  Assert.IsTrue(TRadixControlRules.PlasmaBombAsked(True, LWasDown));
  Assert.IsTrue(LWasDown);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRadixControlRules);

end.
