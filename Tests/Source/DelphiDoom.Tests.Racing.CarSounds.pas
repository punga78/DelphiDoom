{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingCarSounds                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.CarSounds;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf,
  DelphiDoom.Tests.Racing.Fakes;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingCarSounds = class(TObject)
  strict private
    FEffects: TFakeRacingEffects;
    FEffectsRef: IRacingEffects;
    FSounds: IRacingCarSounds;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeSuonareIlMotoreDiUnaFormulaAlMinimoSenzaAcceleratore;
    [Test]
    procedure DovrebbeSceglierelSuonoDalNumeroDiGiri;
    [Test]
    procedure DovrebbeUsareIlSuonoDelleAutoDiSerie;
    [Test]
    procedure DovrebbeAspettareLaFineDelSuonoPrimaDiRipeterlo;
    [Test]
    procedure DovrebbeSuonareLaFrenataSoloSeSiFrena;
    [Test]
    procedure DovrebbeAspettareLaFineDelSuonoDellaFrenata;
    [Test]
    procedure DovrebbePortareLaOrigineDelSuonoSotto;
    [Test]
    procedure DovrebbeRifiutareGliEffettiNil;
  end;

implementation

uses
  DelphiDoom.Racing.Factory, DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingCarSounds }

procedure TTestRacingCarSounds.Setup;
begin
  FEffects := TFakeRacingEffects.Create;
  FEffectsRef := FEffects;
  FSounds := TRacingFactory.CreateCarSounds(FEffectsRef);
end;

procedure TTestRacingCarSounds.DovrebbeSuonareIlMotoreDiUnaFormulaAlMinimoSenzaAcceleratore;
var
  LCar: TRacingCarState;
  LCountdown: Integer;
begin
  LCar := TRacingScenarios.NewCar(0, 0, 0, 0);
  LCar.Rpm := 9000;
  LCountdown := 0;
  FSounds.EngineSound(LCar, LCountdown);
  Assert.AreEqual(1, FEffects.Log.Count);
  Assert.AreEqual(TRacingScenarios.FormatEngineSound(TRacingScenarios.EngineSoundBase(True)), FEffects.Log[0]);
end;

procedure TTestRacingCarSounds.DovrebbeSceglierelSuonoDalNumeroDiGiri;
var
  LCar: TRacingCarState;
  LCountdown: Integer;
begin
  LCar := TRacingScenarios.NewCar(0, 0, 0, 0);
  LCar.CarAccelerate := 100;
  LCar.Rpm := RACING_MAX_RPM;
  LCountdown := 0;
  FSounds.EngineSound(LCar, LCountdown);
  Assert.AreEqual(TRacingScenarios.FormatEngineSound(TRacingScenarios.EngineSoundBase(True) + 9), FEffects.Log[0]);
  FEffects.Log.Clear;
  LCar.Rpm := 4300;
  LCountdown := 0;
  FSounds.EngineSound(LCar, LCountdown);
  Assert.AreEqual(TRacingScenarios.FormatEngineSound(TRacingScenarios.EngineSoundBase(True) + 3), FEffects.Log[0]);
end;

procedure TTestRacingCarSounds.DovrebbeUsareIlSuonoDelleAutoDiSerie;
var
  LCar: TRacingCarState;
  LCountdown: Integer;
begin
  LCar := TRacingScenarios.NewCar(RACING_FORMULA_CAR_COUNT, 0, 0, 0);
  LCountdown := 0;
  FSounds.EngineSound(LCar, LCountdown);
  Assert.AreEqual(TRacingScenarios.FormatEngineSound(TRacingScenarios.EngineSoundBase(False)), FEffects.Log[0]);
end;

procedure TTestRacingCarSounds.DovrebbeAspettareLaFineDelSuonoPrimaDiRipeterlo;
var
  LCar: TRacingCarState;
  LCountdown: Integer;
  LDuration: Integer;
begin
  LCar := TRacingScenarios.NewCar(0, 0, 0, 0);
  LCountdown := 0;
  FSounds.EngineSound(LCar, LCountdown);
  LDuration := TRacingScenarios.SoundDuration(TRacingScenarios.EngineSoundBase(True));
  // The countdown is the duration, less the tic of the call
  Assert.AreEqual(LDuration - 1, LCountdown);
  FSounds.EngineSound(LCar, LCountdown);
  Assert.AreEqual(1, FEffects.Log.Count);
  Assert.AreEqual(LDuration - 2, LCountdown);
end;

procedure TTestRacingCarSounds.DovrebbeSuonareLaFrenataSoloSeSiFrena;
var
  LCar: TRacingCarState;
begin
  LCar := TRacingScenarios.NewCar(0, 0, 0, 0);
  FSounds.BrakeSound(LCar);
  Assert.AreEqual(0, FEffects.Log.Count);
  LCar.CarBrake := 1000;
  FSounds.BrakeSound(LCar);
  Assert.AreEqual(1, FEffects.Log.Count);
  Assert.AreEqual(TRacingScenarios.SoundDuration(TRacingScenarios.BrakeSoundNumber), LCar.BrakeSoundCountdown);
end;

procedure TTestRacingCarSounds.DovrebbeAspettareLaFineDelSuonoDellaFrenata;
var
  LCar: TRacingCarState;
begin
  LCar := TRacingScenarios.NewCar(0, 0, 0, 0);
  LCar.CarBrake := 1000;
  LCar.BrakeSoundCountdown := 3;
  FSounds.BrakeSound(LCar);
  Assert.AreEqual(0, FEffects.Log.Count);
  Assert.AreEqual(2, LCar.BrakeSoundCountdown);
end;

procedure TTestRacingCarSounds.DovrebbePortareLaOrigineDelSuonoSotto;
var
  LCar: TRacingCarState;
begin
  LCar := TRacingScenarios.NewCar(0, 123, 456, 0);
  LCar.Z := 789;
  FSounds.BrakeSound(LCar);
  Assert.AreEqual(123, LCar.BrakeSoundX);
  Assert.AreEqual(456, LCar.BrakeSoundY);
  Assert.AreEqual(789, LCar.BrakeSoundZ);
end;

procedure TTestRacingCarSounds.DovrebbeRifiutareGliEffettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateCarSounds(nil);
    end, EArgumentNilException);
end;

end.
