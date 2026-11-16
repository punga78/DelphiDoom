{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the games that have their own script functions    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Games;

interface

uses
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>Finds a game of the scripts from its name</summary>
  TScriptGames = class
  public
    /// <summary>The game of a name (Doom, Heretic, Hexen, Strife: the case does not matter); false for any other name</summary>
    class function TryFromName(const AName: string; out AGame: TScriptGame): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

const
  GAME_NAMES: array[TScriptGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');

{ TScriptGames }

class function TScriptGames.TryFromName(const AName: string; out AGame: TScriptGame): Boolean;
var
  LGame: TScriptGame;
begin
  for LGame := Low(TScriptGame) to High(TScriptGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Result := True;
      Exit;
    end;
  AGame := sgDoom;
  Result := False;
end;

end.
