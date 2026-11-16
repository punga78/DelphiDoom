{******************************************************************************}
{                                                                              }
{  DelphiDoom: thinkers library - what each game has for its platforms         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Thinkers.Platform.Games;

interface

uses
  System.SysUtils, DelphiDoom.Thinkers.Platform.Types;

type
  /// <summary>
  ///   The rules of the classic platforms of each game (the differences of the three p_plats): the
  ///   profile replaces the compiler switches and the copies of the code
  /// </summary>
  TPlatGames = class
  public
    /// <summary>DOOM, HERETIC or STRIFE (Hexen has no classic platforms)</summary>
    class function NameOf(AGame: TPlatGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the three</summary>
    class function TryFromName(const AName: string; out AGame: TPlatGame): Boolean; static;
    /// <summary>The rules of a game</summary>
    class function ProfileOf(AGame: TPlatGame): TPlatProfile; static;
  end;

implementation

const
  GAME_NAMES: array[TPlatGame] of string = ('DOOM', 'HERETIC', 'STRIFE');

{ TPlatGames }

class function TPlatGames.NameOf(AGame: TPlatGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TPlatGames.TryFromName(const AName: string; out AGame: TPlatGame): Boolean;
var
  LGame: TPlatGame;
begin
  Result := False;
  AGame := TPlatGame.Doom;
  for LGame := Low(TPlatGame) to High(TPlatGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Result := True;
      Break;
    end;
end;

class function TPlatGames.ProfileOf(AGame: TPlatGame): TPlatProfile;
begin
  case AGame of
    TPlatGame.Heretic:
      begin
        Result.MoveSoundWhileRising := [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange];
        Result.MoveSoundWhileLowering := [];
        Result.RemovedAtTop := [TPlatKind.BlazeDownWaitUpStay, TPlatKind.DownWaitUpStay,
          TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange];
        Result.RemovedAtBottom := [];
        Result.RemovalAtBottomNeedsModernEngine := False;
        Result.HasToggle := False;
        Result.ToggleReversesOnWake := False;
        Result.LowStartsAtFloor := False;
      end;
    TPlatGame.Strife:
      begin
        Result.MoveSoundWhileRising := [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange,
          TPlatKind.SlowDownWaitUpStay];
        Result.MoveSoundWhileLowering := [TPlatKind.SlowDownWaitUpStay];
        Result.RemovedAtTop := [TPlatKind.BlazeDownWaitUpStay, TPlatKind.DownWaitUpStay,
          TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange, TPlatKind.GenericLift,
          TPlatKind.SlowDownWaitUpStay];
        Result.RemovedAtBottom := [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange,
          TPlatKind.UpWaitDownStay];
        Result.RemovalAtBottomNeedsModernEngine := False;
        Result.HasToggle := True;
        Result.ToggleReversesOnWake := False;
        Result.LowStartsAtFloor := True;
      end;
  else
    begin
      Result.MoveSoundWhileRising := [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange];
      Result.MoveSoundWhileLowering := [];
      Result.RemovedAtTop := [TPlatKind.BlazeDownWaitUpStay, TPlatKind.DownWaitUpStay,
        TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange, TPlatKind.GenericLift];
      Result.RemovedAtBottom := [TPlatKind.RaiseAndChange, TPlatKind.RaiseToNearestAndChange];
      Result.RemovalAtBottomNeedsModernEngine := True;
      Result.HasToggle := True;
      Result.ToggleReversesOnWake := True;
      Result.LowStartsAtFloor := True;
    end;
  end;
end;

end.
