{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingPhysics                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Physics;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Tests.Racing.Fakes;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingPhysics = class(TObject)
  strict private
    FWorld: TRacingTestWorld;
    FCar: TRacingCarState;
    function Command(AAccelerate, ABrake, ADecelerate, ATurn: Integer): TRacingDrivingCommand;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonMuovereLaAutoFinoAllaPartenza;
    [Test]
    procedure DovrebbeFarAccelerareLaAuto;
    [Test]
    procedure DovrebbeDareLaQuantitaDiMotoNellaDirezioneDellAuto;
    [Test]
    procedure DovrebbeNonSuperareLaVelocitaMassima;
    [Test]
    procedure DovrebbeAndareIndietroFinoAlLimiteDellaRetromarcia;
    [Test]
    procedure DovrebbeFrenare;
    [Test]
    procedure DovrebbePerdereVelocitaSuUnTerrenoCheNonTiene;
    [Test]
    procedure DovrebbeSterzareDiPiuQuandoLAutoEFerma;
    [Test]
    procedure DovrebbeNonSterzareSeIlMotoreEFermo;
    [Test]
    procedure DovrebbeSterzareAlContrarioInRetromarcia;
    [Test]
    procedure DovrebbeFarGirareLeRuoteConLosterzo;
    [Test]
    procedure DovrebbeRaddrizzareLeRuoteSenzaSterzo;
    [Test]
    procedure DovrebbeLimitareLAngoloDelleRuote;
    [Test]
    procedure DovrebbeFarDerapareLaAutoAVelocita;
    [Test]
    procedure DovrebbeFarCalareLaDerapata;
    [Test]
    procedure DovrebbeFinireIlCambioDiMarcia;
    [Test]
    procedure DovrebbeFarGirareLeRuoteDiUnaFormulaPerLaVelocitaVera;
    [Test]
    procedure DovrebbeFarGirareLeQuattroRuoteDiUnaAutoDiSerie;
    [Test]
    procedure DovrebbeSuonareIlMotoreDelleAutoDelComputerVicinoAllaVista;
    [Test]
    procedure DovrebbeNonSuonareIlMotoreDelGiocatoreMaLaFrenata;
    [Test]
    procedure DovrebbeNonSuonareLontanoDallaVista;
    [Test]
    procedure DovrebbeSalvareIlComandoNellaAuto;
    [Test]
    procedure DovrebbeContareIGiriDellaPista;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.Trigonometry,
  DelphiDoom.Racing.CarData, DelphiDoom.Racing.Factory, DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingPhysics }

procedure TTestRacingPhysics.Setup;
begin
  FWorld := TRacingTestWorld.Create;
  FWorld.LoadSimpleTrack;
  FWorld.StartRace;
  FCar := TRacingScenarios.NewCar(0, 5000 * FIXED_ONE, 5000 * FIXED_ONE, 0);
  FCar.Gear := 1;
  FWorld.GeometryObject.ViewX := FCar.X;
  FWorld.GeometryObject.ViewY := FCar.Y;
end;

procedure TTestRacingPhysics.TearDown;
begin
  FWorld.Free;
end;

function TTestRacingPhysics.Command(AAccelerate, ABrake, ADecelerate, ATurn: Integer): TRacingDrivingCommand;
begin
  Result.Accelerate := AAccelerate;
  Result.Brake := ABrake;
  Result.Decelerate := ADecelerate;
  Result.Turn := ATurn;
end;

procedure TTestRacingPhysics.DovrebbeNonMuovereLaAutoFinoAllaPartenza;
begin
  FWorld.Race.SetStatus(TRacingStatus.Waiting);
  FCar.GearTics := 3;
  FWorld.Physics.Execute(FCar, Command(8192, 0, 0, 0));
  Assert.AreEqual(3, FCar.GearTics);
  Assert.AreEqual(0, FCar.EngineSpeed);
  Assert.AreEqual(0, FWorld.EffectLog.Log.Count);
end;

procedure TTestRacingPhysics.DovrebbeFarAccelerareLaAuto;
begin
  FWorld.Physics.Execute(FCar, Command(RACING_CAR_DATA[0].BaseAcceleration, 0, 0, 0));
  Assert.IsTrue(FCar.EngineSpeed > 7000);
  Assert.IsTrue(FCar.EngineSpeed <= RACING_CAR_DATA[0].BaseAcceleration);
  Assert.AreEqual(RACING_CAR_DATA[0].BaseAcceleration, FCar.CarAccelerate);
end;

procedure TTestRacingPhysics.DovrebbeDareLaQuantitaDiMotoNellaDirezioneDellAuto;
begin
  FWorld.Physics.Execute(FCar, Command(RACING_CAR_DATA[0].BaseAcceleration, 0, 0, 0));
  // The car is still and looks to the east: half of the speed of the engine, with the cosine and the sine of the angle 0
  Assert.AreEqual(TFixedMath.Mul(FCar.EngineSpeed, TTrigonometry.FineCosine(0)) div 2, FCar.MomentumX);
  Assert.AreEqual(TFixedMath.Mul(FCar.EngineSpeed, TTrigonometry.FineSine(0)) div 2, FCar.MomentumY);
end;

procedure TTestRacingPhysics.DovrebbeNonSuperareLaVelocitaMassima;
begin
  FCar.EngineSpeed := RACING_CAR_DATA[0].MaxSpeed - 10;
  FCar.OldX := FCar.X - RACING_CAR_DATA[0].MaxSpeed;
  FWorld.Physics.Execute(FCar, Command(RACING_CAR_DATA[0].BaseAcceleration, 0, 0, 0));
  Assert.IsTrue(FCar.EngineSpeed <= RACING_CAR_DATA[0].MaxSpeed);
end;

procedure TTestRacingPhysics.DovrebbeAndareIndietroFinoAlLimiteDellaRetromarcia;
var
  LIndex: Integer;
begin
  FCar.Gear := -1;
  for LIndex := 1 to 100 do
  begin
    FWorld.Physics.Execute(FCar, Command(-RACING_CAR_DATA[0].BaseAcceleration, 0, 0, 0));
    FCar.OldX := FCar.X;
    FCar.X := FCar.X + FCar.MomentumX;
  end;
  Assert.IsTrue(FCar.EngineSpeed < 0);
  Assert.IsTrue(FCar.EngineSpeed >= RACING_CAR_DATA[0].MaxReverseSpeed);
end;

procedure TTestRacingPhysics.DovrebbeFrenare;
begin
  FCar.EngineSpeed := 100000;
  FCar.OldX := FCar.X - 100000;
  FWorld.Physics.Execute(FCar, Command(0, RACING_CAR_DATA[0].BaseDeceleration, 0, 0));
  Assert.IsTrue(FCar.EngineSpeed < 100000);
  Assert.IsTrue(FCar.EngineSpeed >= 0);
end;

procedure TTestRacingPhysics.DovrebbePerdereVelocitaSuUnTerrenoCheNonTiene;
var
  LWorse: TRacingTestWorld;
  LCar: TRacingCarState;
begin
  LWorse := TRacingTestWorld.Create;
  try
    LWorse.LoadSimpleTrack;
    LWorse.StartRace;
    LWorse.Ground.SetMap(TRacingScenarios.GroundMap, RACING_GROUND_BYTES);
    // The column 520 has sand
    LCar := TRacingScenarios.NewCar(0, (520 * 2 + 40) * FIXED_ONE, (RACING_GROUND_SIZE - 1) * 2 * FIXED_ONE, 0);
    LCar.Gear := 1;
    LCar.EngineSpeed := 200000;
    LCar.OldX := LCar.X - 200000;
    LWorse.Physics.Execute(LCar, Command(0, 0, 0, 0));
    Assert.IsTrue(LCar.EngineSpeed < 200000);
  finally
    LWorse.Free;
  end;
end;

procedure TTestRacingPhysics.DovrebbeSterzareDiPiuQuandoLAutoEFerma;
var
  LAngle: Cardinal;
begin
  FCar.EngineSpeed := 200000;
  FCar.OldX := FCar.X - 100000;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 1000000));
  // The speed of the wheels is half of the one of the engine: the turn is 3/4 of the command
  LAngle := FCar.Angle;
  Assert.IsTrue(LAngle > 0);
  Assert.IsTrue(LAngle < 1000000);
end;

procedure TTestRacingPhysics.DovrebbeNonSterzareSeIlMotoreEFermo;
begin
  FWorld.Physics.Execute(FCar, Command(0, 0, 0, 1000000));
  Assert.AreEqual(Cardinal(0), FCar.Angle);
end;

procedure TTestRacingPhysics.DovrebbeSterzareAlContrarioInRetromarcia;
begin
  FCar.EngineSpeed := -100000;
  FCar.OldX := FCar.X + 100000;
  FCar.Gear := -1;
  FWorld.Physics.Execute(FCar, Command(-1, 0, 0, 1000000));
  Assert.IsTrue(FCar.Angle > Cardinal(High(Integer)));
end;

procedure TTestRacingPhysics.DovrebbeFarGirareLeRuoteConLosterzo;
begin
  FCar.EngineSpeed := 100000;
  FCar.OldX := FCar.X - 100000;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 1000000));
  Assert.AreEqual(500000, FCar.TireAngle);
end;

procedure TTestRacingPhysics.DovrebbeRaddrizzareLeRuoteSenzaSterzo;
begin
  FCar.EngineSpeed := 100000;
  FCar.OldX := FCar.X - 100000;
  FCar.TireAngle := 3 * ANG1;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 0));
  Assert.AreEqual(2 * ANG1, FCar.TireAngle);
end;

procedure TTestRacingPhysics.DovrebbeLimitareLAngoloDelleRuote;
begin
  FCar.EngineSpeed := 100000;
  FCar.OldX := FCar.X - 100000;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, High(Integer) div 2));
  Assert.AreEqual(20 * ANG1, FCar.TireAngle);
end;

procedure TTestRacingPhysics.DovrebbeFarDerapareLaAutoAVelocita;
begin
  FCar.EngineSpeed := 600000;
  FCar.OldX := FCar.X - 600000;
  FCar.TireAngle := 10 * ANG1;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 1));
  Assert.IsTrue(FCar.DriftAngle > 0);
  Assert.IsTrue(FCar.DriftAngle <= RACING_CAR_DATA[0].MaxDrift * ANG1);
end;

procedure TTestRacingPhysics.DovrebbeFarCalareLaDerapata;
begin
  FCar.EngineSpeed := 20000;
  FCar.OldX := FCar.X - 20000;
  FCar.DriftAngle := 16000;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 0));
  Assert.AreEqual(15000, FCar.DriftAngle);
end;

procedure TTestRacingPhysics.DovrebbeFinireIlCambioDiMarcia;
begin
  FCar.Gear := 1;
  FCar.DestinationGear := 2;
  FCar.GearTics := 2;
  FWorld.Physics.Execute(FCar, Command(0, 0, 0, 0));
  Assert.AreEqual(1, FCar.GearTics);
  Assert.AreEqual(1, FCar.Gear);
  FWorld.Physics.Execute(FCar, Command(0, 0, 0, 0));
  Assert.AreEqual(0, FCar.GearTics);
  Assert.AreEqual(2, FCar.Gear);
end;

procedure TTestRacingPhysics.DovrebbeFarGirareLeRuoteDiUnaFormulaPerLaVelocitaVera;
begin
  // Two wheels of a formula car follow the real speed (still: no turn), the other two the engine
  FCar.EngineSpeed := FIXED_ONE * 10;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 0));
  Assert.AreEqual(0.0, FCar.TireDistance[0], 0.0001);
  Assert.IsTrue(FCar.TireDistance[2] > 0);
end;

procedure TTestRacingPhysics.DovrebbeFarGirareLeQuattroRuoteDiUnaAutoDiSerie;
begin
  FCar.CarInfo := RACING_FORMULA_CAR_COUNT;
  FCar.EngineSpeed := FIXED_ONE * 10;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 0));
  Assert.IsTrue(FCar.TireDistance[0] > 0);
  Assert.AreEqual(FCar.TireDistance[0], FCar.TireDistance[2], 0.0001);
end;

procedure TTestRacingPhysics.DovrebbeSuonareIlMotoreDelleAutoDelComputerVicinoAllaVista;
begin
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 0));
  Assert.AreEqual(1, FWorld.EffectLog.Log.Count);
  Assert.AreEqual(TRacingScenarios.FormatEngineSound(TRacingScenarios.EngineSoundBase(True)),
    FWorld.EffectLog.Log[0]);
end;

procedure TTestRacingPhysics.DovrebbeNonSuonareIlMotoreDelGiocatoreMaLaFrenata;
begin
  FCar.IsPlayer := True;
  FWorld.Physics.Execute(FCar, Command(0, 1000, 0, 0));
  Assert.AreEqual(1, FWorld.EffectLog.Log.Count);
  Assert.AreEqual(Ord('B'), Ord(FWorld.EffectLog.Log[0][1]));
end;

procedure TTestRacingPhysics.DovrebbeNonSuonareLontanoDallaVista;
begin
  FWorld.GeometryObject.ViewX := 0;
  FWorld.GeometryObject.ViewY := 0;
  FWorld.Physics.Execute(FCar, Command(1, 0, 0, 0));
  Assert.AreEqual(0, FWorld.EffectLog.Log.Count);
end;

procedure TTestRacingPhysics.DovrebbeSalvareIlComandoNellaAuto;
begin
  FWorld.Physics.Execute(FCar, Command(11, 22, 33, 44));
  Assert.AreEqual(44, FCar.CarTurn);
  Assert.AreEqual(11, FCar.CarAccelerate);
  Assert.AreEqual(33, FCar.CarDecelerate);
  Assert.AreEqual(22, FCar.CarBrake);
end;

procedure TTestRacingPhysics.DovrebbeContareIGiriDellaPista;
begin
  FCar.CurrentPath := 0;
  FCar.PreviousPath := 7;
  FWorld.Physics.Execute(FCar, Command(0, 0, 0, 0));
  Assert.AreEqual(1, FCar.LapsCompleted);
end;

procedure TTestRacingPhysics.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePhysics(nil, FWorld.Ground, FWorld.Geometry, FWorld.Particles, FWorld.Sounds, FWorld.Track);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePhysics(FWorld.Race, nil, FWorld.Geometry, FWorld.Particles, FWorld.Sounds, FWorld.Track);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePhysics(FWorld.Race, FWorld.Ground, nil, FWorld.Particles, FWorld.Sounds, FWorld.Track);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePhysics(FWorld.Race, FWorld.Ground, FWorld.Geometry, nil, FWorld.Sounds, FWorld.Track);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePhysics(FWorld.Race, FWorld.Ground, FWorld.Geometry, FWorld.Particles, nil, FWorld.Track);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePhysics(FWorld.Race, FWorld.Ground, FWorld.Geometry, FWorld.Particles, FWorld.Sounds, nil);
    end, EArgumentNilException);
end;

end.
