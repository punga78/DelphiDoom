{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the events of the player driver as procedures  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.PlayerEventRelay;

interface

uses
  System.SysUtils, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>A method that gets the result of the player</summary>
  TRacingScoreEvent = procedure(const AScore: TRacingScore) of object;

  /// <summary>
  ///   The driver of the player needs its events when it is made, and the race controller needs the
  ///   driver: the relay is made first and the controller fills its procedures in afterwards (no
  ///   reference cycle between the two)
  /// </summary>
  TRacingPlayerEventRelay = class(TInterfacedObject, IRacingPlayerEvents)
  strict private
    FOnLapCompleted: TRacingScoreEvent;
    FOnScoreChanged: TRacingScoreEvent;
  public
    procedure LapCompleted(const AScore: TRacingScore);
    procedure ScoreChanged(const AScore: TRacingScore);
    /// <summary>Called when the player completes a lap; nil does nothing</summary>
    property OnLapCompleted: TRacingScoreEvent read FOnLapCompleted write FOnLapCompleted;
    /// <summary>Called at every tic after the end of the race, with the result; nil does nothing</summary>
    property OnScoreChanged: TRacingScoreEvent read FOnScoreChanged write FOnScoreChanged;
  end;

implementation

{ TRacingPlayerEventRelay }

procedure TRacingPlayerEventRelay.LapCompleted(const AScore: TRacingScore);
begin
  if Assigned(FOnLapCompleted) then
    FOnLapCompleted(AScore);
end;

procedure TRacingPlayerEventRelay.ScoreChanged(const AScore: TRacingScore);
begin
  if Assigned(FOnScoreChanged) then
    FOnScoreChanged(AScore);
end;

end.
