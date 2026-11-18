{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the race shows and does to the level              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Speed.RaceEvents;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>How the race of the player ended, for the display</summary>
  TSpeedRaceOutcome = (soNone, soWon, soLost);

  /// <summary>
  ///   The events of the race on the engine: the messages of the console player (the old
  ///   A_ConsolePlayerMessage), the end of the level (A_ExitLevel) and the facts that the display
  ///   draws (the number of the start, the picture of the result). It reads the historical
  ///   globals of the engine: this is a class of the engine
  /// </summary>
  TEngineSpeedRaceEvents = class(TInterfacedObject, IRacingRaceEvents)
  strict private
    FLog: ILog;
    FFindCar: TFunc<Cardinal, Pointer>;
    FCountdownStep: Integer;
    FCountdownTic: Integer;
    FOutcome: TSpeedRaceOutcome;
    FOutcomeTic: Integer;
    FLapRecordTic: Integer;
    FLapCompletedTic: Integer;
    FLeft: Boolean;
    procedure Say(const AText: string);
  public
    /// <exception cref="EArgumentNilException">ALog is nil</exception>
    constructor Create(const ALog: ILog; const AFindCar: TFunc<Cardinal, Pointer>);
    procedure Countdown(AStep: TRacingCountdownStep);
    procedure RaceStarted;
    procedure LapCompleted(const AScore: TRacingScore; AIsRecord: Boolean);
    procedure RaceFinished(const AScore: TRacingScore; AWon: Boolean);
    procedure Collision(AKeyA, AKeyB: Cardinal);
    procedure LeaveLevel;
    /// <summary>The last step of the start that was announced (Ord of TRacingCountdownStep), -1 before the first</summary>
    property CountdownStep: Integer read FCountdownStep;
    /// <summary>The tic of the level at which it was announced</summary>
    property CountdownTic: Integer read FCountdownTic;
    property Outcome: TSpeedRaceOutcome read FOutcome;
    property OutcomeTic: Integer read FOutcomeTic;
    property LapRecordTic: Integer read FLapRecordTic;
    property LapCompletedTic: Integer read FLapCompletedTic;
    /// <summary>True once the level has been asked to end</summary>
    property Left: Boolean read FLeft;
  end;

implementation

uses
  d_player,
  g_game,
  p_tick,
  s_sound;

resourcestring
  SSpeedStartEngines = 'Start your engines';
  SSpeedGo = 'GO!';
  SSpeedLapRecord = 'Lap Record';
  SSpeedYouWin = 'You win';
  SSpeedGameOver = 'Game over';

{ TEngineSpeedRaceEvents }

constructor TEngineSpeedRaceEvents.Create(const ALog: ILog; const AFindCar: TFunc<Cardinal, Pointer>);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
  if not Assigned(AFindCar) then
    raise EArgumentNilException.Create('AFindCar');
  FFindCar := AFindCar;
  FCountdownStep := -1;
  FLapRecordTic := -1;
  FLapCompletedTic := -1;
  FOutcomeTic := -1;
end;

procedure TEngineSpeedRaceEvents.Say(const AText: string);
begin
  TGameSession.Players[TGameSession.ConsolePlayer]._message := ShortString(AText);
end;

procedure TEngineSpeedRaceEvents.Countdown(AStep: TRacingCountdownStep);
begin
  FCountdownStep := Ord(AStep);
  FCountdownTic := TTickState.LevelTime;
  case AStep of
    TRacingCountdownStep.Engines: begin Say(SSpeedStartEngines); TSoundRoutines.S_StartSound(nil, 'speedhaste/STARTECH.RAW'); end;
    TRacingCountdownStep.Three: begin Say('3'); TSoundRoutines.S_StartSound(nil, 'speedhaste/THREE.RAW'); end;
    TRacingCountdownStep.Two: begin Say('2'); TSoundRoutines.S_StartSound(nil, 'speedhaste/TWO.RAW'); end;
    TRacingCountdownStep.One: begin Say('1'); TSoundRoutines.S_StartSound(nil, 'speedhaste/ONE.RAW'); end;
    TRacingCountdownStep.Go: begin Say(SSpeedGo); TSoundRoutines.S_StartSound(nil, 'speedhaste/GO.RAW'); end;
  end;
end;

procedure TEngineSpeedRaceEvents.RaceStarted;
begin
  FLog.Info(Format('Speed Haste: the race starts at tic %d'#13#10, [TTickState.LevelTime]));
end;

procedure TEngineSpeedRaceEvents.LapCompleted(const AScore: TRacingScore; AIsRecord: Boolean);
begin
  FLapCompletedTic := TTickState.LevelTime;
  if AIsRecord then
  begin
    FLapRecordTic := TTickState.LevelTime;
    Say(SSpeedLapRecord);
    TSoundRoutines.S_StartSound(nil, 'speedhaste/LAPREC.RAW');
  end;
end;

procedure TEngineSpeedRaceEvents.RaceFinished(const AScore: TRacingScore; AWon: Boolean);
begin
  FOutcomeTic := TTickState.LevelTime;
  if AWon then
  begin
    FOutcome := soWon;
    Say(SSpeedYouWin);
    TSoundRoutines.S_StartSound(nil, 'speedhaste/UNBELI.RAW');
  end
  else
  begin
    FOutcome := soLost;
    Say(SSpeedGameOver);
    TSoundRoutines.S_StartSound(nil, 'speedhaste/GAMEOVER.RAW');
  end;
  FLog.Info(Format('Speed Haste: race over at tic %d, position %d, total time %d tics'#13#10,
    [TTickState.LevelTime, AScore.RacePosition, AScore.TotalTime]));
end;

procedure TEngineSpeedRaceEvents.Collision(AKeyA, AKeyB: Cardinal);
begin
  TSoundRoutines.S_StartSound(FFindCar(AKeyA), 'speedhaste/CRASH.RAW');
end;

procedure TEngineSpeedRaceEvents.LeaveLevel;
begin
  FLeft := True;
  G_ExitLevel;
end;

end.
