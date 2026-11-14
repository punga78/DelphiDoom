{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingSaveGameCodec                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.SaveGameCodec;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf,
  DelphiDoom.Racing.RaceController, DelphiDoom.Racing.PlayerEventRelay, DelphiDoom.Tests.Racing.Fakes,
  DelphiDoom.Tests.Racing.RaceController;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingSaveGameCodec = class(TObject)
  strict private
    FWorldA, FWorldB: TRacingTestWorld;
    FEvents: IRacingRaceEvents;
    FRelayA, FRelayB: TRacingPlayerEventRelay;
    FRelayAReference, FRelayBReference: IRacingPlayerEvents;
    FControllerA, FControllerB: TRacingRaceController;
    function Build(const AWorld: TRacingTestWorld; const ARelay: TRacingPlayerEventRelay;
      const ARelayReference: IRacingPlayerEvents): TRacingRaceController;
    procedure Fill(const AController: TRacingRaceController; AWorld: TRacingTestWorld);
    procedure Run(const AController: TRacingRaceController; AFrom, ATo: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRimettereLeAutoComeEranoDopoUnaCorsa;
    [Test]
    procedure DovrebbeRimettereITempiAiPuntiDelPercorso;
    [Test]
    procedure DovrebbeRimettereLoStatoDellaGara;
    [Test]
    procedure DovrebbeFarContinuareLaGaraComeSeNonSiFosseFermata;
    [Test]
    procedure DovrebbeRifiutareByteTroppoCorti;
    [Test]
    procedure DovrebbeRifiutareUnaFirmaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiAutoDiverso;
    [Test]
    procedure NonDovrebbeCambiareNienteSeIByteSonoTroncati;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Racing.Factory, DelphiDoom.Racing.SaveGameCodec,
  DelphiDoom.Tests.Racing.Scenarios;

{ TTestRacingSaveGameCodec }

procedure TTestRacingSaveGameCodec.Setup;
begin
  FWorldA := TRacingTestWorld.Create;
  FWorldA.LoadSimpleTrack;
  FWorldB := TRacingTestWorld.Create;
  FWorldB.LoadSimpleTrack;
  FEvents := TFakeRaceEvents.Create;
  FRelayA := TRacingPlayerEventRelay.Create;
  FRelayAReference := FRelayA;
  FRelayB := TRacingPlayerEventRelay.Create;
  FRelayBReference := FRelayB;
  FControllerA := Build(FWorldA, FRelayA, FRelayAReference);
  FControllerB := Build(FWorldB, FRelayB, FRelayBReference);
  Fill(FControllerA, FWorldA);
  Fill(FControllerB, FWorldB);
end;

procedure TTestRacingSaveGameCodec.TearDown;
begin
  FControllerA.Free;
  FControllerB.Free;
  FWorldA.Free;
  FWorldB.Free;
end;

function TTestRacingSaveGameCodec.Build(const AWorld: TRacingTestWorld; const ARelay: TRacingPlayerEventRelay;
  const ARelayReference: IRacingPlayerEvents): TRacingRaceController;
begin
  AWorld.Race.SetStatus(TRacingStatus.Waiting);
  AWorld.Race.SetNumLaps(2);
  Result := TRacingRaceController.Create(AWorld.Race, AWorld.Track, AWorld.Physics, AWorld.ComputerDriver,
    TRacingFactory.CreatePlayerDriver(AWorld.Race, AWorld.Track, AWorld.ComputerDriver, ARelayReference),
    ARelay, FEvents, TRacingFactory.CreateScoreTable, 'ACE');
end;

procedure TTestRacingSaveGameCodec.Fill(const AController: TRacingRaceController; AWorld: TRacingTestWorld);
var
  LIndex: Integer;
  LCar: TRacingCarState;
  LPath: PRacingPath;
begin
  LPath := AWorld.Track.GetPath(0);
  for LIndex := 0 to 2 do
  begin
    LCar := TRacingScenarios.NewCar(LIndex * 2, LPath.X, LPath.Y - LIndex * 40 * FIXED_ONE, LPath.Angle);
    LCar.Key := Cardinal(100 + LIndex);
    LCar.CarId := LIndex;
    LCar.IsPlayer := LIndex = 0;
    LCar.CurrentPath := AWorld.Track.GetPath(AWorld.Track.GetNextPath(LCar.X, LCar.Y)).Id;
    LCar.PreviousPath := AWorld.Track.GetPath(LCar.CurrentPath).Previous;
    LCar.LapsCompleted := -1;
    AController.AddCar(LCar);
  end;
end;

procedure TTestRacingSaveGameCodec.Run(const AController: TRacingRaceController; AFrom, ATo: Integer);
var
  LTic, LCar: Integer;
  LInput: TRacingPlayerInput;
begin
  LInput.AngleTurn := 0;
  LInput.ForwardMove := 50;
  LInput.Buttons := 0;
  for LTic := AFrom to ATo do
  begin
    AController.Tick(LTic, LInput);
    for LCar := 0 to AController.Count - 1 do
    begin
      AController.Cars[LCar].X := AController.Cars[LCar].X + AController.Cars[LCar].MomentumX;
      AController.Cars[LCar].Y := AController.Cars[LCar].Y + AController.Cars[LCar].MomentumY;
    end;
  end;
end;

procedure TTestRacingSaveGameCodec.DovrebbeRimettereLeAutoComeEranoDopoUnaCorsa;
var
  LIndex: Integer;
begin
  Run(FControllerA, 1, 600);
  Assert.IsTrue(TRacingSaveGameCodec.Decode(FControllerB, TRacingSaveGameCodec.Encode(FControllerA)));
  for LIndex := 0 to 2 do
  begin
    Assert.AreEqual(FControllerA.Cars[LIndex].X, FControllerB.Cars[LIndex].X);
    Assert.AreEqual(FControllerA.Cars[LIndex].EngineSpeed, FControllerB.Cars[LIndex].EngineSpeed);
    Assert.AreEqual(FControllerA.Cars[LIndex].Gear, FControllerB.Cars[LIndex].Gear);
    Assert.AreEqual(FControllerA.Cars[LIndex].CurrentPath, FControllerB.Cars[LIndex].CurrentPath);
    Assert.AreEqual(FControllerA.Cars[LIndex].TireDistance[2], FControllerB.Cars[LIndex].TireDistance[2], 0);
    Assert.AreEqual(FControllerA.Cars[LIndex].IsPlayer, FControllerB.Cars[LIndex].IsPlayer);
    Assert.AreEqual(FControllerA.Cars[LIndex].Key, FControllerB.Cars[LIndex].Key);
  end;
end;

procedure TTestRacingSaveGameCodec.DovrebbeRimettereITempiAiPuntiDelPercorso;
var
  LPathA, LPathB: PRacingPath;
begin
  Run(FControllerA, 1, 900);
  Assert.IsTrue(TRacingSaveGameCodec.Decode(FControllerB, TRacingSaveGameCodec.Encode(FControllerA)));
  LPathA := FWorldA.Track.GetPath(1);
  LPathB := FWorldB.Track.GetPath(1);
  Assert.IsTrue(LPathA.Visits[2][0].EnterTime > 0, 'la prova non ha visitato il punto');
  Assert.AreEqual(LPathA.Visits[2][0].EnterTime, LPathB.Visits[2][0].EnterTime);
  Assert.AreEqual(LPathA.Visits[2][0].ExitTime, LPathB.Visits[2][0].ExitTime);
end;

procedure TTestRacingSaveGameCodec.DovrebbeRimettereLoStatoDellaGara;
begin
  Run(FControllerA, 1, 400);
  Assert.IsTrue(TRacingSaveGameCodec.Decode(FControllerB, TRacingSaveGameCodec.Encode(FControllerA)));
  Assert.IsTrue(FWorldB.Race.Status = TRacingStatus.Racing);
  Assert.AreEqual(FWorldA.Race.RaceTime, FWorldB.Race.RaceTime);
  Assert.AreEqual(FWorldA.Race.NumLaps, FWorldB.Race.NumLaps);
end;

procedure TTestRacingSaveGameCodec.DovrebbeFarContinuareLaGaraComeSeNonSiFosseFermata;
var
  LIndex: Integer;
begin
  Run(FControllerA, 1, 500);
  Assert.IsTrue(TRacingSaveGameCodec.Decode(FControllerB, TRacingSaveGameCodec.Encode(FControllerA)));
  Run(FControllerA, 501, 800);
  Run(FControllerB, 501, 800);
  for LIndex := 0 to 2 do
  begin
    // the random numbers of the ground (the grip of the dirt) are not in the state: the cars go on
    // along the same road, not along the same line to the last bit (about 20 units in 300 tics)
    Assert.IsTrue(Abs(Int64(FControllerA.Cars[LIndex].X) - FControllerB.Cars[LIndex].X) < 1500000, 'x ' + IntToStr(LIndex));
    Assert.IsTrue(Abs(Int64(FControllerA.Cars[LIndex].Y) - FControllerB.Cars[LIndex].Y) < 1500000, 'y ' + IntToStr(LIndex));
    Assert.AreEqual(FControllerA.Cars[LIndex].LapsCompleted, FControllerB.Cars[LIndex].LapsCompleted);
    Assert.AreEqual(FControllerA.Cars[LIndex].RacePosition, FControllerB.Cars[LIndex].RacePosition);
  end;
end;

procedure TTestRacingSaveGameCodec.DovrebbeRifiutareByteTroppoCorti;
begin
  Assert.IsFalse(TRacingSaveGameCodec.Decode(FControllerB, nil));
  Assert.IsFalse(TRacingSaveGameCodec.Decode(FControllerB, TBytes.Create(1, 2, 3)));
end;

procedure TTestRacingSaveGameCodec.DovrebbeRifiutareUnaFirmaSbagliata;
var
  LBytes: TBytes;
begin
  LBytes := TRacingSaveGameCodec.Encode(FControllerA);
  LBytes[0] := Ord('X');
  Assert.IsFalse(TRacingSaveGameCodec.Decode(FControllerB, LBytes));
end;

procedure TTestRacingSaveGameCodec.DovrebbeRifiutareUnNumeroDiAutoDiverso;
var
  LBytes: TBytes;
  LCar: TRacingCarState;
begin
  LBytes := TRacingSaveGameCodec.Encode(FControllerA);
  LCar := FControllerB.Cars[1]^;
  LCar.IsPlayer := False;
  FControllerB.AddCar(LCar);
  Assert.IsFalse(TRacingSaveGameCodec.Decode(FControllerB, LBytes));
end;

procedure TTestRacingSaveGameCodec.NonDovrebbeCambiareNienteSeIByteSonoTroncati;
var
  LBytes: TBytes;
  LBefore: Integer;
begin
  Run(FControllerA, 1, 300);
  LBytes := TRacingSaveGameCodec.Encode(FControllerA);
  SetLength(LBytes, Length(LBytes) - 5);
  LBefore := FControllerB.Cars[0].X;
  Assert.IsFalse(TRacingSaveGameCodec.Decode(FControllerB, LBytes));
  Assert.AreEqual(LBefore, FControllerB.Cars[0].X);
  Assert.IsTrue(FWorldB.Race.Status = TRacingStatus.Waiting);
end;

end.
