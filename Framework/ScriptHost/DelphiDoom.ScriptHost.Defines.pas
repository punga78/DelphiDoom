{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the defines of the preprocessor of the scripts    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Defines;

interface

uses
  DelphiDoom.ScriptHost.Types;

type
  /// <summary>
  ///   The names that a script can test with {$IFDEF} (the game, DOOM_OR_HERETIC...): they were
  ///   the four {$IFDEF} blocks of TDoomCompiler.CompileDoomScript, now a function of the game
  /// </summary>
  TScriptDefines = class
  public
    /// <summary>
    ///   The defines of a script, in the order the old compiler added them: the name of the game,
    ///   DEBUG, DEVPARM, the six "X_OR_Y" names that have the game in them (the ones of the other
    ///   three games, then the same with the game first) and OPENGL
    /// </summary>
    class function ForGame(const AGameName: string; const AGame: TScriptGame; const ADebug, ADevParm,
      AOpenGL: Boolean): TArray<string>; static;
  end;

implementation

uses
  System.SysUtils;

const
  // for each game: the names that its scripts see, in the order of the old code
  GAME_DEFINES: array[TScriptGame] of array[0..5] of string = (
    ('DOOM_OR_HERETIC', 'DOOM_OR_HEXEN', 'DOOM_OR_STRIFE', 'HERETIC_OR_DOOM', 'HEXEN_OR_DOOM', 'STRIFE_OR_DOOM'),
    ('HERETIC_OR_DOOM', 'HERETIC_OR_HEXEN', 'HERETIC_OR_STRIFE', 'DOOM_OR_HERETIC', 'HEXEN_OR_HERETIC',
      'STRIFE_OR_HERETIC'),
    ('HEXEN_OR_DOOM', 'HEXEN_OR_HERETIC', 'HEXEN_OR_STRIFE', 'DOOM_OR_HEXEN', 'HERETIC_OR_HEXEN',
      'STRIFE_OR_HEXEN'),
    ('STRIFE_OR_DOOM', 'STRIFE_OR_HERETIC', 'STRIFE_OR_HEXEN', 'DOOM_OR_STRIFE', 'HERETIC_OR_STRIFE',
      'HEXEN_OR_STRIFE')
  );

{ TScriptDefines }

class function TScriptDefines.ForGame(const AGameName: string; const AGame: TScriptGame; const ADebug,
  ADevParm, AOpenGL: Boolean): TArray<string>;
var
  LNames: TArray<string>;
  LDefine: string;
begin
  LNames := [UpperCase(AGameName)];
  if ADebug then
    LNames := LNames + ['DEBUG'];
  if ADevParm then
    LNames := LNames + ['DEVPARM'];
  for LDefine in GAME_DEFINES[AGame] do
    LNames := LNames + [LDefine];
  if AOpenGL then
    LNames := LNames + ['OPENGL'];
  Result := LNames;
end;

end.
