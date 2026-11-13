{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of the heads-up display of this game         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Hud.Rules;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>
  ///   The constants of hu_stuff.pas and doomdef.pas that Libs\Hud takes as rules: this is the one
  ///   place where the game is chosen, by the define of the project
  /// </summary>
  TEngineHudRules = class
  public
    /// <summary>The rules of the game this program is</summary>
    class function Build: THudRules; static;
  end;

implementation

uses
  doomdef,
  hu_stuff;

{ TEngineHudRules }

class function TEngineHudRules.Build: THudRules;
begin
  Result.MessageTimeout := HU_MSGTIMEOUT;
  Result.TicRate := TICRATE;
{$IFDEF HEXEN}
  Result.FpsLongHistory := 128;
{$ELSE}
  Result.FpsLongHistory := 512;
{$ENDIF}
  Result.Broadcast := HU_BROADCAST;
{$IFDEF STRIFE}
  Result.LastDestination := HU_CHANGENAME;
{$ELSE}
  Result.LastDestination := HU_BROADCAST;
{$ENDIF}
  Result.MessageRefreshKey := HU_MSGREFRESH;
  Result.InputToggleKey := Ord('t');
  Result.MaxPlayers := MAXPLAYERS;
  Result.Keys.Enter := KEY_ENTER;
  Result.Keys.Escape := KEY_ESCAPE;
  Result.Keys.Backspace := KEY_BACKSPACE;
  Result.Keys.RightShift := KEY_RSHIFT;
  Result.Keys.RightAlt := KEY_RALT;
  Result.Keys.LeftAlt := KEY_LALT;
end;

end.
