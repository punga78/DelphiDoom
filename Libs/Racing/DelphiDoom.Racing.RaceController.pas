{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the race, tic after tic                        }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  What MT_RACESTART, MT_CHECKLAPRECORD, MT_YOUWIN, MT_GAMEOVER and            }
{  SH_CalculatePositions did in the GLSpeed fork, as one class without the     }
{  states of the actors                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.RaceController;

// The positions are 16.16 fixed point and wrap as in the old code
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf, DelphiDoom.Racing.PlayerEventRelay;

const
  /// <summary>The tic of the level of "Start your engines" (the first state of MT_RACESTART)</summary>
  RACING_COUNTDOWN_ENGINES_TIC = 1;
  /// <summary>The tic of the level of the "3" (60 tics of the engines, as in the fork)</summary>
  RACING_COUNTDOWN_THREE_TIC = 61;
  RACING_COUNTDOWN_TWO_TIC = 98;
  RACING_COUNTDOWN_ONE_TIC = 135;
  RACING_COUNTDOWN_GO_TIC = 172;
  /// <summary>The tic of the level at which the race begins (A_StartRace)</summary>
  RACING_START_TIC = 209;
  /// <summary>Tics from the last line to the result (MT_CHECKLAPRECORD: 1 + 10 + 1 + 35)</summary>
  RACING_RESULT_DELAY_TICS = 47;
  /// <summary>Tics from the result to the exit (the "you win" or "game over" picture: about 110)</summary>
  RACING_LEAVE_DELAY_TICS = 110;

type
  /// <summary>What a race controller remembers besides the state of the cars</summary>
  TRacingControllerState = record
    FinishTic: Integer;
    ResultGiven: Boolean;
    Left: Boolean;
    HasFinalScore: Boolean;
    FinalScore: TRacingScore;
    PlayerState: TRacingPlayerState;
  end;

  /// <summary>
  ///   The cars of a race and the rules around them. The game copies the position of every car
  ///   from its object, calls Tick, and copies the momentum and the angle back; the controller
  ///   does not know the world. Not a reference counted class: the game owns it
  /// </summary>
  TRacingRaceController = class
  strict private
    FRace: IRacingRaceSettings;
    FTrack: IRacingTrack;
    FPhysics: IRacingPhysics;
    FAiDriver: IRacingDriver;
    FPlayerDriver: IRacingPlayerDriver;
    FEvents: IRacingRaceEvents;
    FScores: IRacingScoreTable;
    FPilotName: string;
    FCars: TArray<TRacingCarState>;
    FCount: Integer;
    FPlayerIndex: Integer;
    FPlayerState: TRacingPlayerState;
    FFinishTic: Integer;
    FResultGiven: Boolean;
    FLeft: Boolean;
    FFinalScore: TRacingScore;
    FHasFinalScore: Boolean;
    FInputs: TArray<TRacingPositionInput>;
    FTouching: TArray<Boolean>;
    FCollisions: Boolean;
    procedure UpdateTimeline(ALevelTime: Integer);
    procedure UpdatePositions;
    procedure ResolveCollisions;
    procedure CheckPlayerFinish(ALevelTime: Integer);
    procedure PlayerLapCompleted(const AScore: TRacingScore);
    procedure PlayerScoreChanged(const AScore: TRacingScore);
    function GetCar(AIndex: Integer): PRacingCarState;
    function GetState: TRacingControllerState;
    procedure SetState(const AValue: TRacingControllerState);
  public
    /// <param name="ARelay">
    ///   The relay that the player driver was made with: the controller sets its procedures
    /// </param>
    /// <exception cref="EArgumentNilException">An argument is nil</exception>
    constructor Create(const ARace: IRacingRaceSettings; const ATrack: IRacingTrack;
      const APhysics: IRacingPhysics; const AAiDriver: IRacingDriver;
      const APlayerDriver: IRacingPlayerDriver; const ARelay: TRacingPlayerEventRelay;
      const AEvents: IRacingRaceEvents; const AScores: IRacingScoreTable; const APilotName: string);
    /// <summary>Adds a car; the one with IsPlayer set is driven with the input of the player (one at most)</summary>
    /// <returns>The index of the car</returns>
    function AddCar(const ACar: TRacingCarState): Integer;
    /// <summary>One tic of the level: the drivers, the physics, the positions and the rules of the race</summary>
    procedure Tick(ALevelTime: Integer; const APlayerInput: TRacingPlayerInput);
    /// <summary>The car with the given index, to copy its fields to and from the object of the game</summary>
    property Cars[AIndex: Integer]: PRacingCarState read GetCar;
    property Count: Integer read FCount;
    /// <summary>The cars that touch push each other away and bump (on by default)</summary>
    property Collisions: Boolean read FCollisions write FCollisions;
    /// <summary>The index of the car of the player, -1 if there is none</summary>
    property PlayerIndex: Integer read FPlayerIndex;
    /// <summary>The result of the player once the race is over (HasFinalScore)</summary>
    property FinalScore: TRacingScore read FFinalScore;
    property HasFinalScore: Boolean read FHasFinalScore;
    /// <summary>The tic of the level at which the player completed the last lap, -1 before</summary>
    property FinishTic: Integer read FFinishTic;
    property PlayerState: TRacingPlayerState read FPlayerState;
    /// <summary>What the controller remembers besides the cars (for a saved game); setting it puts it back</summary>
    property State: TRacingControllerState read GetState write SetState;
    /// <summary>The track and the race of the controller, for the code that saves them</summary>
    property Track: IRacingTrack read FTrack;
    property Race: IRacingRaceSettings read FRace;
  end;

implementation

uses
  DelphiDoom.Racing.CarData, DelphiDoom.Racing.CarCollisions;

{ TRacingRaceController }

constructor TRacingRaceController.Create(const ARace: IRacingRaceSettings; const ATrack: IRacingTrack;
  const APhysics: IRacingPhysics; const AAiDriver: IRacingDriver;
  const APlayerDriver: IRacingPlayerDriver; const ARelay: TRacingPlayerEventRelay;
  const AEvents: IRacingRaceEvents; const AScores: IRacingScoreTable; const APilotName: string);
begin
  inherited Create;
  if not Assigned(ARace) then
    raise EArgumentNilException.Create('ARace');
  if not Assigned(ATrack) then
    raise EArgumentNilException.Create('ATrack');
  if not Assigned(APhysics) then
    raise EArgumentNilException.Create('APhysics');
  if not Assigned(AAiDriver) then
    raise EArgumentNilException.Create('AAiDriver');
  if not Assigned(APlayerDriver) then
    raise EArgumentNilException.Create('APlayerDriver');
  if not Assigned(ARelay) then
    raise EArgumentNilException.Create('ARelay');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AScores) then
    raise EArgumentNilException.Create('AScores');
  FRace := ARace;
  FTrack := ATrack;
  FPhysics := APhysics;
  FAiDriver := AAiDriver;
  FPlayerDriver := APlayerDriver;
  FEvents := AEvents;
  FScores := AScores;
  FPilotName := APilotName;
  FPlayerIndex := -1;
  FFinishTic := -1;
  FCollisions := True;
  ARelay.OnLapCompleted := PlayerLapCompleted;
  ARelay.OnScoreChanged := PlayerScoreChanged;
end;

function TRacingRaceController.GetCar(AIndex: Integer): PRacingCarState;
begin
  Result := @FCars[AIndex];
end;

function TRacingRaceController.GetState: TRacingControllerState;
begin
  Result.FinishTic := FFinishTic;
  Result.ResultGiven := FResultGiven;
  Result.Left := FLeft;
  Result.HasFinalScore := FHasFinalScore;
  Result.FinalScore := FFinalScore;
  Result.PlayerState := FPlayerState;
end;

procedure TRacingRaceController.SetState(const AValue: TRacingControllerState);
begin
  FFinishTic := AValue.FinishTic;
  FResultGiven := AValue.ResultGiven;
  FLeft := AValue.Left;
  FHasFinalScore := AValue.HasFinalScore;
  FFinalScore := AValue.FinalScore;
  FPlayerState := AValue.PlayerState;
end;

function TRacingRaceController.AddCar(const ACar: TRacingCarState): Integer;
begin
  if FCount >= RACING_MAX_CARS then
    raise ERacingException.CreateFmt('Too many cars in the race (%d)', [FCount + 1]);
  if Length(FCars) <= FCount then
  begin
    SetLength(FCars, RACING_MAX_CARS);
    SetLength(FInputs, RACING_MAX_CARS);
  end;
  FCars[FCount] := ACar;
  if ACar.IsPlayer then
  begin
    if FPlayerIndex >= 0 then
      raise ERacingException.Create('The race has only one player');
    FPlayerIndex := FCount;
  end;
  Result := FCount;
  Inc(FCount);
end;

procedure TRacingRaceController.UpdateTimeline(ALevelTime: Integer);
begin
  case ALevelTime of
    RACING_COUNTDOWN_ENGINES_TIC: FEvents.Countdown(TRacingCountdownStep.Engines);
    RACING_COUNTDOWN_THREE_TIC: FEvents.Countdown(TRacingCountdownStep.Three);
    RACING_COUNTDOWN_TWO_TIC: FEvents.Countdown(TRacingCountdownStep.Two);
    RACING_COUNTDOWN_ONE_TIC: FEvents.Countdown(TRacingCountdownStep.One);
    RACING_COUNTDOWN_GO_TIC: FEvents.Countdown(TRacingCountdownStep.Go);
  end;
  if (ALevelTime >= RACING_START_TIC) and (FRace.Status = TRacingStatus.Waiting) then
  begin
    FRace.SetStatus(TRacingStatus.Racing);
    FEvents.RaceStarted;
  end;
  if ALevelTime >= RACING_START_TIC then
    FRace.SetRaceTime(ALevelTime - RACING_START_TIC);
end;

procedure TRacingRaceController.UpdatePositions;
var
  LIndex: Integer;
  LItems: TArray<TRacingPositionItem>;
begin
  for LIndex := 0 to FCount - 1 do
  begin
    FInputs[LIndex].Key := FCars[LIndex].Key;
    FInputs[LIndex].CarInfo := FCars[LIndex].CarInfo;
    FInputs[LIndex].LapsCompleted := FCars[LIndex].LapsCompleted;
    FInputs[LIndex].CurrentPath := FCars[LIndex].CurrentPath;
    FInputs[LIndex].X := FCars[LIndex].X;
    FInputs[LIndex].Y := FCars[LIndex].Y;
  end;
  LItems := FTrack.CalculatePositions(Copy(FInputs, 0, FCount));
  for LIndex := 0 to High(LItems) do
    FCars[LItems[LIndex].Index].RacePosition := LIndex + 1;
end;

procedure TRacingRaceController.PlayerLapCompleted(const AScore: TRacingScore);
var
  LLap: Integer;
  LIsRecord: Boolean;
begin
  LLap := FCars[FPlayerIndex].LapsCompleted;
  LIsRecord := False;
  if (LLap >= 1) and (LLap <= RACING_MAX_LAPS) then
    LIsRecord := FScores.CheckLapRecord(AScore.Episode, AScore.Map,
      RACING_CAR_DATA[AScore.CarInfo].CarType, AScore.LapTimes[LLap - 1]);
  FEvents.LapCompleted(AScore, LIsRecord);
end;

procedure TRacingRaceController.PlayerScoreChanged(const AScore: TRacingScore);
begin
  FFinalScore := AScore;
  FHasFinalScore := True;
end;

procedure TRacingRaceController.CheckPlayerFinish(ALevelTime: Integer);
var
  LWon: Boolean;
begin
  if (FPlayerIndex < 0) or (FRace.GameType = TRacingGameType.Practice) then
    Exit;
  if (FFinishTic < 0) and (FCars[FPlayerIndex].LapsCompleted >= FRace.NumLaps) then
  begin
    FFinishTic := ALevelTime;
    FRace.SetStatus(TRacingStatus.PlayerFinished);
  end;
  if FFinishTic < 0 then
    Exit;
  if not FResultGiven and (ALevelTime >= FFinishTic + RACING_RESULT_DELAY_TICS) then
  begin
    FResultGiven := True;
    LWon := FCars[FPlayerIndex].RacePosition = 1;
    if FHasFinalScore then
      FScores.Update(FFinalScore, FPilotName, FRace.Skill);
    FEvents.RaceFinished(FFinalScore, LWon);
  end;
  if FResultGiven and not FLeft and
     (ALevelTime >= FFinishTic + RACING_RESULT_DELAY_TICS + RACING_LEAVE_DELAY_TICS) then
  begin
    FLeft := True;
    FEvents.LeaveLevel;
  end;
end;

procedure TRacingRaceController.Tick(ALevelTime: Integer; const APlayerInput: TRacingPlayerInput);
var
  LIndex: Integer;
  LCommand: TRacingDrivingCommand;
begin
  FRace.SetLevelTime(ALevelTime);
  UpdateTimeline(ALevelTime);
  for LIndex := 0 to FCount - 1 do
  begin
    if LIndex = FPlayerIndex then
      FPlayerDriver.BuildCommand(FCars[LIndex], FPlayerState, APlayerInput, LCommand)
    else
      FAiDriver.BuildCommand(FCars[LIndex], LCommand);
    FPhysics.Execute(FCars[LIndex], LCommand);
    // the game moves the object: the next tic the speed is the distance from here
    FCars[LIndex].OldX := FCars[LIndex].X;
    FCars[LIndex].OldY := FCars[LIndex].Y;
  end;
  ResolveCollisions;
  UpdatePositions;
  CheckPlayerFinish(ALevelTime);
end;

procedure TRacingRaceController.ResolveCollisions;
var
  LCars: array of PRacingCarState;
  LIndex: Integer;
  LBumps: TArray<TRacingBump>;
  LNow: TArray<Boolean>;
begin
  if (FCount < 2) or not FCollisions then
    Exit;
  SetLength(LCars, FCount);
  for LIndex := 0 to FCount - 1 do
    LCars[LIndex] := @FCars[LIndex];
  LNow := nil;
  LBumps := TRacingCarCollisions.Resolve(LCars, FTouching, LNow);
  FTouching := LNow;
  for LIndex := 0 to High(LBumps) do
    FEvents.Collision(LBumps[LIndex].KeyA, LBumps[LIndex].KeyB);
end;

end.
