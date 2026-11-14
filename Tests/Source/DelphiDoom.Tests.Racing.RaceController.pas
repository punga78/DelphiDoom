{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingRaceController                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.RaceController;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Racing.Types,
  DelphiDoom.Racing.Intf, DelphiDoom.Racing.RaceController, DelphiDoom.Racing.PlayerEventRelay,
  DelphiDoom.Tests.Racing.Fakes;

type
  /// <summary>Writes the events of the race as lines of text with the tic they happened at</summary>
  TFakeRaceEvents = class(TInterfacedObject, IRacingRaceEvents)
  strict private
    FLines: TStringList;
    FTic: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Countdown(AStep: TRacingCountdownStep);
    procedure RaceStarted;
    procedure LapCompleted(const AScore: TRacingScore; AIsRecord: Boolean);
    procedure RaceFinished(const AScore: TRacingScore; AWon: Boolean);
    procedure LeaveLevel;
    property Lines: TStringList read FLines;
    property Tic: Integer read FTic write FTic;
  end;

  [TestFixture]
  [Category('racing')]
  TTestRacingRaceController = class(TObject)
  strict private
    FWorld: TRacingTestWorld;
    FEvents: TFakeRaceEvents;
    FEventsReference: IRacingRaceEvents;
    FRelay: TRacingPlayerEventRelay;
    FRelayReference: IRacingPlayerEvents;
    FScores: IRacingScoreTable;
    FController: TRacingRaceController;
    function BuildController: TRacingRaceController;
    function GridCar(AIndex: Integer; AIsPlayer: Boolean): TRacingCarState;
    procedure Run(AFromTic, AToTic: Integer; AForward: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAnnunciareIPassiDellaPartenzaAiTicGiusti;
    [Test]
    procedure DovrebbeTenereFermeLeAutoFinoAlVia;
    [Test]
    procedure DovrebbeFarPartireLaGaraAlTicDelVia;
    [Test]
    procedure DovrebbeContareIlTempoDiGaraDalVia;
    [Test]
    procedure DovrebbeNumerareLePosizioniDaUno;
    [Test]
    procedure DovrebbeFarCorrereLeAutoDelComputer;
    [Test]
    procedure DovrebbeUsareIlComandoDelGiocatoreSoloPerLaSuaAuto;
    [Test]
    procedure DovrebbeRifiutareDueGiocatori;
    [Test]
    procedure DovrebbeRifiutareTroppeAuto;
    [Test]
    procedure DovrebbeFinireLaGaraEUscireDalLivello;
    [Test]
    procedure DovrebbeNonFinireInProva;
    [Test]
    procedure DovrebbeRifiutareGliOggettiNil;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Factory, DelphiDoom.Tests.Racing.Scenarios;

{ TFakeRaceEvents }

constructor TFakeRaceEvents.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TFakeRaceEvents.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TFakeRaceEvents.Countdown(AStep: TRacingCountdownStep);
begin
  FLines.Add(Format('%d countdown %d', [FTic, Ord(AStep)]));
end;

procedure TFakeRaceEvents.RaceStarted;
begin
  FLines.Add(Format('%d started', [FTic]));
end;

procedure TFakeRaceEvents.LapCompleted(const AScore: TRacingScore; AIsRecord: Boolean);
begin
  FLines.Add(Format('%d lap %d', [FTic, Ord(AIsRecord)]));
end;

procedure TFakeRaceEvents.RaceFinished(const AScore: TRacingScore; AWon: Boolean);
begin
  FLines.Add(Format('%d finished %d', [FTic, Ord(AWon)]));
end;

procedure TFakeRaceEvents.LeaveLevel;
begin
  FLines.Add(Format('%d leave', [FTic]));
end;

{ TTestRacingRaceController }

procedure TTestRacingRaceController.Setup;
begin
  FWorld := TRacingTestWorld.Create;
  FWorld.LoadSimpleTrack;
  FEvents := TFakeRaceEvents.Create;
  FEventsReference := FEvents;
  FRelay := TRacingPlayerEventRelay.Create;
  FRelayReference := FRelay;
  FScores := TRacingFactory.CreateScoreTable;
  FController := BuildController;
end;

procedure TTestRacingRaceController.TearDown;
begin
  FController.Free;
  FWorld.Free;
end;

function TTestRacingRaceController.BuildController: TRacingRaceController;
begin
  FWorld.Race.SetStatus(TRacingStatus.Waiting);
  FWorld.Race.SetNumLaps(2);
  Result := TRacingRaceController.Create(FWorld.Race, FWorld.Track, FWorld.Physics, FWorld.ComputerDriver,
    TRacingFactory.CreatePlayerDriver(FWorld.Race, FWorld.Track, FWorld.ComputerDriver, FRelayReference),
    FRelay, FEventsReference, FScores, 'ACE');
end;

function TTestRacingRaceController.GridCar(AIndex: Integer; AIsPlayer: Boolean): TRacingCarState;
var
  LPath: PRacingPath;
begin
  LPath := FWorld.Track.GetPath(0);
  Result := TRacingScenarios.NewCar(AIndex * 2, LPath.X, LPath.Y - AIndex * 40 * FIXED_ONE, LPath.Angle);
  Result.Key := Cardinal(100 + AIndex);
  Result.CarId := AIndex;
  Result.IsPlayer := AIsPlayer;
  Result.CurrentPath := FWorld.Track.GetPath(FWorld.Track.GetNextPath(Result.X, Result.Y)).Id;
  Result.PreviousPath := FWorld.Track.GetPath(Result.CurrentPath).Previous;
  Result.DestinationAngle := FWorld.Track.GetPath(Result.CurrentPath).Angle;
  Result.DestinationSpeed := FWorld.Track.GetPath(Result.CurrentPath).Speed;
  Result.LapsCompleted := -1;
end;

procedure TTestRacingRaceController.Run(AFromTic, AToTic: Integer; AForward: Integer);
var
  LTic, LCar: Integer;
  LInput: TRacingPlayerInput;
begin
  LInput.AngleTurn := 0;
  LInput.ForwardMove := AForward;
  LInput.Buttons := 0;
  for LTic := AFromTic to AToTic do
  begin
    FEvents.Tic := LTic;
    FController.Tick(LTic, LInput);
    // the game moves the objects
    for LCar := 0 to FController.Count - 1 do
    begin
      FController.Cars[LCar].X := FController.Cars[LCar].X + FController.Cars[LCar].MomentumX;
      FController.Cars[LCar].Y := FController.Cars[LCar].Y + FController.Cars[LCar].MomentumY;
    end;
  end;
end;

procedure TTestRacingRaceController.DovrebbeAnnunciareIPassiDellaPartenzaAiTicGiusti;
begin
  FController.AddCar(GridCar(0, True));
  Run(1, 210, 0);
  Assert.AreEqual('1 countdown 0', FEvents.Lines[0]);
  Assert.AreEqual('61 countdown 1', FEvents.Lines[1]);
  Assert.AreEqual('98 countdown 2', FEvents.Lines[2]);
  Assert.AreEqual('135 countdown 3', FEvents.Lines[3]);
  Assert.AreEqual('172 countdown 4', FEvents.Lines[4]);
  Assert.AreEqual('209 started', FEvents.Lines[5]);
end;

procedure TTestRacingRaceController.DovrebbeTenereFermeLeAutoFinoAlVia;
begin
  FController.AddCar(GridCar(0, False));
  Run(1, 100, 0);
  Assert.AreEqual<Integer>(0, FController.Cars[0].MomentumX);
  Assert.AreEqual<Integer>(0, FController.Cars[0].MomentumY);
end;

procedure TTestRacingRaceController.DovrebbeFarPartireLaGaraAlTicDelVia;
begin
  FController.AddCar(GridCar(0, False));
  Run(1, RACING_START_TIC - 1, 0);
  Assert.IsTrue(FWorld.Race.Status = TRacingStatus.Waiting);
  Run(RACING_START_TIC, RACING_START_TIC, 0);
  Assert.IsTrue(FWorld.Race.Status = TRacingStatus.Racing);
end;

procedure TTestRacingRaceController.DovrebbeContareIlTempoDiGaraDalVia;
begin
  FController.AddCar(GridCar(0, False));
  Run(1, RACING_START_TIC + 50, 0);
  Assert.AreEqual(50, FWorld.Race.RaceTime);
end;

procedure TTestRacingRaceController.DovrebbeNumerareLePosizioniDaUno;
var
  LIndex: Integer;
  LSum: Integer;
begin
  for LIndex := 0 to 3 do
    FController.AddCar(GridCar(LIndex, LIndex = 0));
  Run(1, RACING_START_TIC + 100, 0);
  LSum := 0;
  for LIndex := 0 to 3 do
    Inc(LSum, FController.Cars[LIndex].RacePosition);
  Assert.AreEqual(10, LSum);
end;

procedure TTestRacingRaceController.DovrebbeFarCorrereLeAutoDelComputer;
begin
  FController.AddCar(GridCar(0, False));
  Run(1, RACING_START_TIC + 200, 0);
  Assert.IsTrue(FController.Cars[0].EngineSpeed > 0, 'la macchina non accelera');
end;

procedure TTestRacingRaceController.DovrebbeUsareIlComandoDelGiocatoreSoloPerLaSuaAuto;
begin
  FController.AddCar(GridCar(0, True));
  FController.AddCar(GridCar(1, False));
  Run(1, RACING_START_TIC + 120, 0);
  // the player does not press the throttle: it stays still, the computer car runs
  Assert.AreEqual<Integer>(0, FController.Cars[0].EngineSpeed);
  Assert.IsTrue(FController.Cars[1].EngineSpeed > 0);
end;

procedure TTestRacingRaceController.DovrebbeRifiutareDueGiocatori;
begin
  FController.AddCar(GridCar(0, True));
  Assert.WillRaise(
    procedure
    begin
      FController.AddCar(GridCar(1, True));
    end, ERacingException);
end;

procedure TTestRacingRaceController.DovrebbeRifiutareTroppeAuto;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RACING_MAX_CARS - 1 do
    FController.AddCar(GridCar(LIndex, False));
  Assert.WillRaise(
    procedure
    begin
      FController.AddCar(GridCar(0, False));
    end, ERacingException);
end;

procedure TTestRacingRaceController.DovrebbeFinireLaGaraEUscireDalLivello;
var
  LFinish: Integer;
begin
  FController.AddCar(GridCar(0, True));
  FController.AddCar(GridCar(1, False));
  Run(1, RACING_START_TIC + 20, 50);
  // the player crosses the line for the last time
  FController.Cars[FController.PlayerIndex].LapsCompleted := 2;
  LFinish := RACING_START_TIC + 21;
  Run(LFinish, LFinish, 50);
  Assert.AreEqual(LFinish, FController.FinishTic);
  Assert.IsTrue(FWorld.Race.Status = TRacingStatus.PlayerFinished);
  Assert.AreEqual(0, Pos(' finished ', FEvents.Lines.Text), 'il risultato arriva subito');
  Run(LFinish + 1, LFinish + RACING_RESULT_DELAY_TICS, 50);
  Assert.IsTrue(Pos(Format('%d finished', [LFinish + RACING_RESULT_DELAY_TICS]), FEvents.Lines.Text) > 0);
  Assert.IsTrue(FController.HasFinalScore);
  Assert.AreEqual(0, Pos(' leave', FEvents.Lines.Text));
  Run(LFinish + RACING_RESULT_DELAY_TICS + 1, LFinish + RACING_RESULT_DELAY_TICS + RACING_LEAVE_DELAY_TICS, 50);
  Assert.IsTrue(Pos(Format('%d leave', [LFinish + RACING_RESULT_DELAY_TICS + RACING_LEAVE_DELAY_TICS]),
    FEvents.Lines.Text) > 0);
  Assert.IsTrue(Pos(' lap ', FEvents.Lines.Text) > 0, 'il giro non e annunciato');
end;

procedure TTestRacingRaceController.DovrebbeNonFinireInProva;
begin
  FWorld.Race.SetGameType(TRacingGameType.Practice);
  FController.AddCar(GridCar(0, True));
  Run(1, RACING_START_TIC + 20, 50);
  FController.Cars[0].LapsCompleted := 2;
  Run(RACING_START_TIC + 21, RACING_START_TIC + 600, 50);
  Assert.AreEqual<Integer>(-1, FController.FinishTic);
  Assert.AreEqual(0, Pos(' leave', FEvents.Lines.Text));
end;

procedure TTestRacingRaceController.DovrebbeRifiutareGliOggettiNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TRacingRaceController.Create(nil, FWorld.Track, FWorld.Physics, FWorld.ComputerDriver, nil, FRelay,
        FEventsReference, FScores, '');
    end, EArgumentNilException);
end;

end.
