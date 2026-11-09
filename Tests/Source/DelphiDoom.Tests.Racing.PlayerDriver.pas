{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingPlayerDriver                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.PlayerDriver;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Tests.Racing.Fakes;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingPlayerDriver = class(TObject)
  strict private
    FWorld: TRacingTestWorld;
    FCar: TRacingCarState;
    FPlayer: TRacingPlayerState;
    FInput: TRacingPlayerInput;
    FCommand: TRacingDrivingCommand;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNonGuidareFinoAllaPartenza;
    [Test]
    procedure DovrebbeAccelerareConIlTastoAvanti;
    [Test]
    procedure DovrebbeInserireLaPrimaDallaRetromarcia;
    [Test]
    procedure DovrebbeUsareIlCambioAutomatico;
    [Test]
    procedure DovrebbeUsareIlCambioManuale;
    [Test]
    procedure DovrebbeFrenareConIlTastoIndietroSeLAutoVaAvanti;
    [Test]
    procedure DovrebbeInserireLaRetromarciaSeLAutoENonVaAvanti;
    [Test]
    procedure DovrebbeRallentareSenzaTasti;
    [Test]
    procedure DovrebbeMettereLaFolleQuandoLAutoEFerma;
    [Test]
    procedure DovrebbeSterzareConIlComandoDelGiocatore;
    [Test]
    procedure DovrebbeLimitareLoSterzoACausaDellaVelocita;
    [Test]
    procedure DovrebbeDireAlGiocoCheSiEFinitoUnGiro;
    [Test]
    procedure DovrebbeDireUnGiroUnaVolaSola;
    [Test]
    procedure DovrebbeDareITempiNelRisultato;
    [Test]
    procedure DovrebbeFarGuidareIlComputerAGaraFinita;
    [Test]
    procedure DovrebbeTenereIlPuntoDelPercorso;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.CarData, DelphiDoom.Racing.Factory,
  DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingPlayerDriver }

procedure TTestRacingPlayerDriver.Setup;
begin
  FWorld := TRacingTestWorld.Create;
  FWorld.LoadSimpleTrack;
  FWorld.StartRace;
  FCar := TRacingScenarios.NewCar(0, FWorld.Track.GetPath(0).X, FWorld.Track.GetPath(0).Y, 0);
  FCar.IsPlayer := True;
  FillChar(FPlayer, SizeOf(FPlayer), 0);
  FillChar(FInput, SizeOf(FInput), 0);
end;

procedure TTestRacingPlayerDriver.TearDown;
begin
  FWorld.Free;
end;

procedure TTestRacingPlayerDriver.DovrebbeNonGuidareFinoAllaPartenza;
begin
  FWorld.Race.SetStatus(TRacingStatus.Waiting);
  FInput.ForwardMove := 1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(0, FCommand.Accelerate);
end;

procedure TTestRacingPlayerDriver.DovrebbeAccelerareConIlTastoAvanti;
begin
  FInput.ForwardMove := 1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(RACING_CAR_DATA[0].BaseAcceleration, FCommand.Accelerate);
  Assert.AreEqual(0, FCommand.Brake);
  Assert.AreEqual(0, FCommand.Decelerate);
end;

procedure TTestRacingPlayerDriver.DovrebbeInserireLaPrimaDallaRetromarcia;
begin
  FCar.Gear := -1;
  FInput.ForwardMove := 1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(1, FCar.DestinationGear);
  Assert.AreEqual(RACING_AUTO_GEAR_CHANGE_TICS, FCar.GearTics);
end;

procedure TTestRacingPlayerDriver.DovrebbeUsareIlCambioAutomatico;
begin
  FCar.Gear := 1;
  FCar.EngineSpeed := 5 * (RACING_CAR_DATA[0].MaxSpeed div 16);
  FInput.ForwardMove := 1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(2, FCar.DestinationGear);
  Assert.AreEqual(RACING_AUTO_GEAR_CHANGE_TICS, FCar.GearTics);
end;

procedure TTestRacingPlayerDriver.DovrebbeUsareIlCambioManuale;
begin
  FWorld.Race.SetTransmissionType(RACING_TRANSMISSION_MANUAL);
  FCar.Gear := 1;
  FCar.EngineSpeed := 5 * (RACING_CAR_DATA[0].MaxSpeed div 16);
  FInput.ForwardMove := 1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  // The manual gearbox changes only with the buttons
  Assert.AreEqual(0, FCar.GearTics);
  FInput.Buttons := RACING_BUTTON_GEAR_UP;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(2, FCar.DestinationGear);
  Assert.AreEqual(RACING_MANUAL_GEAR_CHANGE_TICS, FCar.GearTics);
end;

procedure TTestRacingPlayerDriver.DovrebbeFrenareConIlTastoIndietroSeLAutoVaAvanti;
begin
  FCar.Gear := 2;
  FCar.EngineSpeed := 100000;
  FInput.ForwardMove := -1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(RACING_CAR_DATA[0].BaseDeceleration div 4, FCommand.Brake);
  Assert.AreEqual(0, FCommand.Accelerate);
end;

procedure TTestRacingPlayerDriver.DovrebbeInserireLaRetromarciaSeLAutoENonVaAvanti;
begin
  FInput.ForwardMove := -1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(-RACING_CAR_DATA[0].BaseAcceleration div 6, FCommand.Accelerate);
  Assert.AreEqual(-1, FCar.DestinationGear);
end;

procedure TTestRacingPlayerDriver.DovrebbeRallentareSenzaTasti;
begin
  FCar.Gear := 2;
  FCar.EngineSpeed := 100000;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(RACING_CAR_DATA[0].BaseDeceleration div 32, FCommand.Decelerate);
  Assert.AreEqual(0, FCommand.Accelerate);
  Assert.AreEqual(0, FCommand.Brake);
end;

procedure TTestRacingPlayerDriver.DovrebbeMettereLaFolleQuandoLAutoEFerma;
begin
  FCar.Gear := 2;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(0, FCar.DestinationGear);
  Assert.AreEqual(RACING_AUTO_GEAR_CHANGE_TICS, FCar.GearTics);
  Assert.AreEqual(0, FCommand.Decelerate);
end;

procedure TTestRacingPlayerDriver.DovrebbeSterzareConIlComandoDelGiocatore;
begin
  FInput.AngleTurn := 10;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(10 * FIXED_ONE, FCommand.Turn);
  FInput.AngleTurn := -10;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(-10 * FIXED_ONE, FCommand.Turn);
end;

procedure TTestRacingPlayerDriver.DovrebbeLimitareLoSterzoACausaDellaVelocita;
var
  LLimit: Integer;
begin
  FInput.AngleTurn := 30000;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  LLimit := RACING_CAR_DATA[0].TurnSpeed - 150 * FIXED_ONE;
  Assert.AreEqual(LLimit, FCommand.Turn);
  // Faster: less steering (one unit of 65536 for every 8 km/h)
  FCar.EngineSpeed := RACING_CAR_DATA[0].MaxSpeed;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(LLimit - 38 * FIXED_ONE, FCommand.Turn);
end;

procedure TTestRacingPlayerDriver.DovrebbeDireAlGiocoCheSiEFinitoUnGiro;
begin
  FCar.LapsCompleted := 1;
  FCar.CurrentPath := 3;
  FWorld.Race.SetRaceTime(700);
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(1, FWorld.EventLog.LapsCompleted);
  Assert.AreEqual(1, FWorld.EventLog.Score.Episode);
  Assert.AreEqual(2, FWorld.EventLog.Score.Map);
  Assert.AreEqual(3, FWorld.EventLog.Score.NumLaps);
  Assert.IsTrue(FPlayer.LapRecordChecked[0]);
end;

procedure TTestRacingPlayerDriver.DovrebbeDireUnGiroUnaVolaSola;
begin
  FCar.LapsCompleted := 1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(1, FWorld.EventLog.LapsCompleted);
end;

procedure TTestRacingPlayerDriver.DovrebbeDareITempiNelRisultato;
var
  LVisitor: TRacingCarState;
begin
  // The car goes across the finish line at 500
  LVisitor := FCar;
  LVisitor.CurrentPath := 0;
  LVisitor.PreviousPath := 7;
  FWorld.Race.SetRaceTime(500);
  FWorld.Track.Notify(LVisitor);
  LVisitor.RacePosition := 3;
  FWorld.PlayerDriver.BuildCommand(LVisitor, FPlayer, FInput, FCommand);
  Assert.AreEqual(500, FWorld.EventLog.Score.LapTimes[0]);
  Assert.AreEqual(500, FWorld.EventLog.Score.TotalTime);
  Assert.AreEqual(3, FWorld.EventLog.Score.RacePosition);
end;

procedure TTestRacingPlayerDriver.DovrebbeFarGuidareIlComputerAGaraFinita;
begin
  FCar.LapsCompleted := 3;
  FInput.ForwardMove := -1;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(1, FWorld.EventLog.ScoresChanged);
  // The computer accelerates, not the player that wants to go back
  Assert.IsTrue(FCommand.Accelerate > 0);
end;

procedure TTestRacingPlayerDriver.DovrebbeTenereIlPuntoDelPercorso;
begin
  FCar.CurrentPath := 5;
  FWorld.PlayerDriver.BuildCommand(FCar, FPlayer, FInput, FCommand);
  Assert.AreEqual(1, FCar.CurrentPath);
  Assert.AreEqual(5, FCar.PreviousPath);
end;

procedure TTestRacingPlayerDriver.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePlayerDriver(nil, FWorld.Track, FWorld.ComputerDriver, FWorld.Events);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePlayerDriver(FWorld.Race, nil, FWorld.ComputerDriver, FWorld.Events);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePlayerDriver(FWorld.Race, FWorld.Track, nil, FWorld.Events);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRacingFactory.CreatePlayerDriver(FWorld.Race, FWorld.Track, FWorld.ComputerDriver, nil);
    end, EArgumentNilException);
end;

end.
