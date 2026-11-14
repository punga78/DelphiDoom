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
  DelphiDoom.Logging.Intf, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

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
    constructor Create(const ALog: ILog);
    procedure Countdown(AStep: TRacingCountdownStep);
    procedure RaceStarted;
    procedure LapCompleted(const AScore: TRacingScore; AIsRecord: Boolean);
    procedure RaceFinished(const AScore: TRacingScore; AWon: Boolean);
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
  System.SysUtils,
  d_player,
  g_game,
  p_tick;

resourcestring
  SSpeedStartEngines = 'Start your engines';
  SSpeedGo = 'GO!';
  SSpeedLapRecord = 'Lap Record';
  SSpeedYouWin = 'You win';
  SSpeedGameOver = 'Game over';

{ TEngineSpeedRaceEvents }

constructor TEngineSpeedRaceEvents.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
  FCountdownStep := -1;
  FLapRecordTic := -1;
  FLapCompletedTic := -1;
  FOutcomeTic := -1;
end;

procedure TEngineSpeedRaceEvents.Say(const AText: string);
begin
  players[consoleplayer]._message := ShortString(AText);
end;

procedure TEngineSpeedRaceEvents.Countdown(AStep: TRacingCountdownStep);
begin
  FCountdownStep := Ord(AStep);
  FCountdownTic := leveltime;
  case AStep of
    TRacingCountdownStep.Engines: Say(SSpeedStartEngines);
    TRacingCountdownStep.Three: Say('3');
    TRacingCountdownStep.Two: Say('2');
    TRacingCountdownStep.One: Say('1');
    TRacingCountdownStep.Go: Say(SSpeedGo);
  end;
end;

procedure TEngineSpeedRaceEvents.RaceStarted;
begin
  FLog.Info(Format('Speed Haste: the race starts at tic %d'#13#10, [leveltime]));
end;

procedure TEngineSpeedRaceEvents.LapCompleted(const AScore: TRacingScore; AIsRecord: Boolean);
begin
  FLapCompletedTic := leveltime;
  if AIsRecord then
  begin
    FLapRecordTic := leveltime;
    Say(SSpeedLapRecord);
  end;
end;

procedure TEngineSpeedRaceEvents.RaceFinished(const AScore: TRacingScore; AWon: Boolean);
begin
  FOutcomeTic := leveltime;
  if AWon then
  begin
    FOutcome := soWon;
    Say(SSpeedYouWin);
  end
  else
  begin
    FOutcome := soLost;
    Say(SSpeedGameOver);
  end;
  FLog.Info(Format('Speed Haste: race over at tic %d, position %d, total time %d tics'#13#10,
    [leveltime, AScore.RacePosition, AScore.TotalTime]));
end;

procedure TEngineSpeedRaceEvents.LeaveLevel;
begin
  FLeft := True;
  G_ExitLevel;
end;

end.
