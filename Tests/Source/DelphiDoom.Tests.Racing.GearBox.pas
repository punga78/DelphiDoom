{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingGearBox                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.GearBox;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingGearBox = class(TObject)
  strict private
    function NewCar(AGear, ASpeed: Integer): TRacingCarState;
  public
    [Test]
    procedure DovrebbeLeggereLaTabellaDelleMarce;
    [Test]
    procedure DovrebbeLeggereUnaRigaDopoLAltraSeIlPassoESedici;
    [Test]
    procedure DovrebbeDareZeroOltreLaFineDellaTabella;
    [Test]
    procedure DovrebbeChiedereUnaMarciaSeNonCEUnCambioInCorso;
    [Test]
    procedure DovrebbeIgnorareLaRichiestaDellaMarciaGiaInserita;
    [Test]
    procedure DovrebbeIgnorareLaRichiestaDuranteUnCambio;
    [Test]
    procedure DovrebbeSalireDiMarciaQuandoLaSuccessivaSpingeDiPiu;
    [Test]
    procedure DovrebbeScenderediMarciaQuandoLaPrecedenteSpingeDiPiu;
    [Test]
    procedure DovrebbeRestareInMarciaSeNessunaSpingeDiPiu;
    [Test]
    procedure DovrebbeNonCambiareConLaVelocitaNegativa;
    [Test]
    procedure DovrebbeSalireConIlPulsanteDelCambioManuale;
    [Test]
    procedure DovrebbeNonSalireOltreLaSestaMarcia;
    [Test]
    procedure DovrebbeScendereSoloSeLaMarciaSottoSpinge;
    [Test]
    procedure DovrebbeNonScenderesottoLaSecondaMarciaConIlCambioManuale;
    [Test]
    procedure DovrebbeFarCalareGliGiriInFolle;
    [Test]
    procedure DovrebbeFarSalireGliGiriVersoQuelliDellaVelocita;
    [Test]
    procedure DovrebbeFarCalareGliGiriFinoAZero;
    [Test]
    procedure DovrebbeDareZeroDiSpintaDuranteIlCambio;
    [Test]
    procedure DovrebbeDareTuttaLaSpintaInRetromarcia;
    [Test]
    procedure DovrebbeDareLaSpintaDellaMarciaPerLaVelocita;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.CarData, DelphiDoom.Racing.GearBox;

{ TTestRacingGearBox }

function TTestRacingGearBox.NewCar(AGear, ASpeed: Integer): TRacingCarState;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.CarInfo := 0;
  Result.Gear := AGear;
  Result.EngineSpeed := ASpeed;
end;

procedure TTestRacingGearBox.DovrebbeLeggereLaTabellaDelleMarce;
begin
  Assert.AreEqual(64, TRacingGearBox.Factor(-1, 0));
  Assert.AreEqual(0, TRacingGearBox.Factor(0, 5));
  Assert.AreEqual(32, TRacingGearBox.Factor(1, 3));
  Assert.AreEqual(64, TRacingGearBox.Factor(2, 2));
  Assert.AreEqual(16, TRacingGearBox.Factor(6, 15));
end;

procedure TTestRacingGearBox.DovrebbeLeggereUnaRigaDopoLAltraSeIlPassoESedici;
begin
  // The old code read the table as one block: the step 16 of a gear is the step 0 of the next gear
  Assert.AreEqual(4, TRacingGearBox.Factor(5, 16));
  Assert.AreEqual(TRacingGearBox.Factor(2, 0), TRacingGearBox.Factor(1, 16));
end;

procedure TTestRacingGearBox.DovrebbeDareZeroOltreLaFineDellaTabella;
begin
  Assert.AreEqual(0, TRacingGearBox.Factor(6, 16));
  Assert.AreEqual(0, TRacingGearBox.Factor(9, 0));
  Assert.AreEqual(0, TRacingGearBox.Factor(-3, 0));
end;

procedure TTestRacingGearBox.DovrebbeChiedereUnaMarciaSeNonCEUnCambioInCorso;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(0, 0);
  TRacingGearBox.SetGear(LCar, 1);
  Assert.AreEqual(1, LCar.DestinationGear);
  Assert.AreEqual(RACING_AUTO_GEAR_CHANGE_TICS, LCar.GearTics);
  Assert.AreEqual(RACING_AUTO_NEXT_GEAR_CHANGE_TICS, LCar.NextGearTics);
end;

procedure TTestRacingGearBox.DovrebbeIgnorareLaRichiestaDellaMarciaGiaInserita;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(2, 0);
  TRacingGearBox.SetGear(LCar, 2);
  Assert.AreEqual(0, LCar.GearTics);
  Assert.AreEqual(0, LCar.NextGearTics);
end;

procedure TTestRacingGearBox.DovrebbeIgnorareLaRichiestaDuranteUnCambio;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(1, 0);
  LCar.NextGearTics := 3;
  TRacingGearBox.SetGear(LCar, 4);
  Assert.AreEqual(0, LCar.DestinationGear);
end;

procedure TTestRacingGearBox.DovrebbeSalireDiMarciaQuandoLaSuccessivaSpingeDiPiu;
var
  LCar: TRacingCarState;
begin
  // Step 5: the first gear pushes 1 and the second one 32
  LCar := NewCar(1, 5 * (RACING_CAR_DATA[0].MaxSpeed div 16));
  TRacingGearBox.AutomaticGearBox(LCar);
  Assert.AreEqual(2, LCar.DestinationGear);
  Assert.AreEqual(RACING_AUTO_GEAR_CHANGE_TICS, LCar.GearTics);
end;

procedure TTestRacingGearBox.DovrebbeScenderediMarciaQuandoLaPrecedenteSpingeDiPiu;
var
  LCar: TRacingCarState;
begin
  // Step 0: the third gear pushes 16 and the second one 32
  LCar := NewCar(3, 0);
  TRacingGearBox.AutomaticGearBox(LCar);
  Assert.AreEqual(2, LCar.DestinationGear);
end;

procedure TTestRacingGearBox.DovrebbeRestareInMarciaSeNessunaSpingeDiPiu;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(1, 0);
  TRacingGearBox.AutomaticGearBox(LCar);
  Assert.AreEqual(0, LCar.GearTics);
  Assert.AreEqual(0, LCar.DestinationGear);
end;

procedure TTestRacingGearBox.DovrebbeNonCambiareConLaVelocitaNegativa;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(1, -100000);
  TRacingGearBox.AutomaticGearBox(LCar);
  Assert.AreEqual(0, LCar.GearTics);
end;

procedure TTestRacingGearBox.DovrebbeSalireConIlPulsanteDelCambioManuale;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(2, 0);
  TRacingGearBox.ManualGearBox(LCar, RACING_BUTTON_GEAR_UP);
  Assert.AreEqual(3, LCar.DestinationGear);
  Assert.AreEqual(RACING_MANUAL_GEAR_CHANGE_TICS, LCar.GearTics);
  Assert.AreEqual(RACING_MANUAL_NEXT_GEAR_CHANGE_TICS, LCar.NextGearTics);
end;

procedure TTestRacingGearBox.DovrebbeNonSalireOltreLaSestaMarcia;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(RACING_GEAR_COUNT, 0);
  TRacingGearBox.ManualGearBox(LCar, RACING_BUTTON_GEAR_UP);
  Assert.AreEqual(0, LCar.GearTics);
end;

procedure TTestRacingGearBox.DovrebbeScendereSoloSeLaMarciaSottoSpinge;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(3, 0);
  TRacingGearBox.ManualGearBox(LCar, RACING_BUTTON_GEAR_DOWN);
  Assert.AreEqual(2, LCar.DestinationGear);

  // At the top speed the second gear does not push any more
  LCar := NewCar(3, RACING_CAR_DATA[0].MaxSpeed);
  TRacingGearBox.ManualGearBox(LCar, RACING_BUTTON_GEAR_DOWN);
  Assert.AreEqual(0, LCar.GearTics);
end;

procedure TTestRacingGearBox.DovrebbeNonScenderesottoLaSecondaMarciaConIlCambioManuale;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(1, 0);
  TRacingGearBox.ManualGearBox(LCar, RACING_BUTTON_GEAR_DOWN);
  Assert.AreEqual(0, LCar.GearTics);
end;

procedure TTestRacingGearBox.DovrebbeFarCalareGliGiriInFolle;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(0, 100000);
  LCar.Rpm := 1000;
  TRacingGearBox.CalculateRpm(LCar);
  Assert.AreEqual(1000 - RACING_RPM_FADE, LCar.Rpm);
end;

procedure TTestRacingGearBox.DovrebbeFarSalireGliGiriVersoQuelliDellaVelocita;
var
  LCar: TRacingCarState;
begin
  // The first gear pushes up to the step 5: 6/16 of the top speed is 13000 rpm
  LCar := NewCar(1, 114 * RACING_KMH_TO_FIXED);
  TRacingGearBox.CalculateRpm(LCar);
  Assert.AreEqual(RACING_RPM_FADE, LCar.Rpm);
  LCar.Rpm := 12900;
  TRacingGearBox.CalculateRpm(LCar);
  Assert.AreEqual(13000, LCar.Rpm);
end;

procedure TTestRacingGearBox.DovrebbeFarCalareGliGiriFinoAZero;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(1, 0);
  LCar.Rpm := 100;
  TRacingGearBox.CalculateRpm(LCar);
  Assert.AreEqual(0, LCar.Rpm);
  LCar.Rpm := 13000;
  TRacingGearBox.CalculateRpm(LCar);
  Assert.AreEqual(13000 - RACING_RPM_FADE, LCar.Rpm);
end;

procedure TTestRacingGearBox.DovrebbeDareZeroDiSpintaDuranteIlCambio;
var
  LCar: TRacingCarState;
begin
  LCar := NewCar(1, 0);
  LCar.GearTics := 2;
  Assert.AreEqual(0, TRacingGearBox.AccelerationFactor(LCar));
end;

procedure TTestRacingGearBox.DovrebbeDareTuttaLaSpintaInRetromarcia;
begin
  Assert.AreEqual(FIXED_ONE, TRacingGearBox.AccelerationFactor(NewCar(-1, -1000)));
end;

procedure TTestRacingGearBox.DovrebbeDareLaSpintaDellaMarciaPerLaVelocita;
begin
  Assert.AreEqual(64 * RACING_GEAR_FACTOR_MULTIPLIER, TRacingGearBox.AccelerationFactor(NewCar(1, 0)));
  Assert.AreEqual(1 * RACING_GEAR_FACTOR_MULTIPLIER,
    TRacingGearBox.AccelerationFactor(NewCar(1, 5 * (RACING_CAR_DATA[0].MaxSpeed div 16))));
end;

end.
