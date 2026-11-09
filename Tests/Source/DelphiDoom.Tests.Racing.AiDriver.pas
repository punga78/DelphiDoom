{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingAiDriver                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.AiDriver;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Tests.Racing.Fakes;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingAiDriver = class(TObject)
  strict private
    FWorld: TRacingTestWorld;
    function CarOnPath(APath: Integer): TRacingCarState;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonGuidareFinoAllaPartenza;
    [Test]
    procedure DovrebbeAccelerareSeVaPiuPianoDelPunto;
    [Test]
    procedure DovrebbeNonAccelerareOltreLaSpintaMassima;
    [Test]
    procedure DovrebbeFrenareSeVaPiuForteDelPunto;
    [Test]
    procedure DovrebbeFrenareDiPiuSeLaDifferenzaEGrande;
    [Test]
    procedure DovrebbeSterzareVersoIlPunto;
    [Test]
    procedure DovrebbeNonSterzareSeELaDirezioneGiusta;
    [Test]
    procedure DovrebbeCambiareMarciaDaSolo;
    [Test]
    procedure DovrebbeTenereIlPuntoDelPercorso;
    [Test]
    procedure DovrebbeSpingereMenoNelleDifficoltaBasse;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.CarData, DelphiDoom.Racing.Factory,
  DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingAiDriver }

procedure TTestRacingAiDriver.Setup;
begin
  FWorld := TRacingTestWorld.Create;
  FWorld.LoadSimpleTrack;
  FWorld.StartRace;
  FWorld.Race.SetSkill(TRacingSkill.Medium);
end;

procedure TTestRacingAiDriver.TearDown;
begin
  FWorld.Free;
end;

function TTestRacingAiDriver.CarOnPath(APath: Integer): TRacingCarState;
begin
  Result := TRacingScenarios.NewCar(0, FWorld.Track.GetPath(APath).X, FWorld.Track.GetPath(APath).Y,
    FWorld.Track.GetPath(APath).Angle);
  Result.CurrentPath := APath;
end;

procedure TTestRacingAiDriver.DovrebbeNonGuidareFinoAllaPartenza;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  FWorld.Race.SetStatus(TRacingStatus.Waiting);
  LCar := CarOnPath(0);
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.AreEqual(0, LCommand.Accelerate);
  Assert.AreEqual(0, LCommand.Brake);
  Assert.AreEqual(0, LCommand.Turn);
end;

procedure TTestRacingAiDriver.DovrebbeAccelerareSeVaPiuPianoDelPunto;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  LCar := CarOnPath(0);
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.IsTrue(LCommand.Accelerate > 0);
  Assert.AreEqual(0, LCommand.Brake);
end;

procedure TTestRacingAiDriver.DovrebbeNonAccelerareOltreLaSpintaMassima;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  LCar := CarOnPath(0);
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  // 61440 / 65536 of the acceleration of the car, in the medium skill
  Assert.IsTrue(LCommand.Accelerate <= RACING_CAR_DATA[0].BaseAcceleration);
end;

procedure TTestRacingAiDriver.DovrebbeFrenareSeVaPiuForteDelPunto;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  LCar := CarOnPath(0);
  LCar.OldX := LCar.X - 500 * RACING_KMH_TO_FIXED;
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.IsTrue(LCommand.Brake > 0);
  Assert.AreEqual(0, LCommand.Accelerate);
end;

procedure TTestRacingAiDriver.DovrebbeFrenareDiPiuSeLaDifferenzaEGrande;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  LCar := CarOnPath(0);
  LCar.OldX := LCar.X - 100000000;
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.AreEqual(RACING_CAR_DATA[0].BaseDeceleration, LCommand.Brake);
end;

procedure TTestRacingAiDriver.DovrebbeSterzareVersoIlPunto;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  // The car looks away from the path
  LCar := CarOnPath(0);
  LCar.Angle := LCar.Angle + ANG90;
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.IsTrue(LCommand.Turn <> 0);
end;

procedure TTestRacingAiDriver.DovrebbeNonSterzareSeELaDirezioneGiusta;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
  LTarget: Cardinal;
begin
  LCar := CarOnPath(0);
  // The target is the next point: the car looks to it
  LTarget := FWorld.Geometry.PointToAngle(LCar.X, LCar.Y, FWorld.Track.GetPath(1).X, FWorld.Track.GetPath(1).Y);
  LCar.Angle := LTarget;
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.AreEqual(0, LCommand.Turn);
end;

procedure TTestRacingAiDriver.DovrebbeCambiareMarciaDaSolo;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  LCar := CarOnPath(0);
  LCar.Gear := 1;
  LCar.EngineSpeed := 5 * (RACING_CAR_DATA[0].MaxSpeed div 16);
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.AreEqual(2, LCar.DestinationGear);
end;

procedure TTestRacingAiDriver.DovrebbeTenereIlPuntoDelPercorso;
var
  LCar: TRacingCarState;
  LCommand: TRacingDrivingCommand;
begin
  LCar := CarOnPath(0);
  LCar.CurrentPath := 5;
  FWorld.ComputerDriver.BuildCommand(LCar, LCommand);
  Assert.AreEqual(1, LCar.CurrentPath);
  Assert.AreEqual(5, LCar.PreviousPath);
end;

procedure TTestRacingAiDriver.DovrebbeSpingereMenoNelleDifficoltaBasse;
var
  LCar: TRacingCarState;
  LEasy, LHard: TRacingDrivingCommand;
begin
  FWorld.Race.SetSkill(TRacingSkill.Baby);
  LCar := CarOnPath(0);
  FWorld.ComputerDriver.BuildCommand(LCar, LEasy);
  FWorld.Race.SetSkill(TRacingSkill.Nightmare);
  LCar := CarOnPath(0);
  FWorld.ComputerDriver.BuildCommand(LCar, LHard);
  Assert.IsTrue(LEasy.Accelerate < LHard.Accelerate);
end;

procedure TTestRacingAiDriver.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateAiDriver(nil, FWorld.Track, FWorld.Geometry);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateAiDriver(FWorld.Race, nil, FWorld.Geometry);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreateAiDriver(FWorld.Race, FWorld.Track, nil);
    end, EArgumentNilException);
end;

end.
