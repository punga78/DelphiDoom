{******************************************************************************}
{                                                                              }
{  DelphiDoom: game state library - the contract                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameState.Intf;

interface

type
  /// <summary>
  ///   What a class needs to know of the game that is running, without reading the globals of
  ///   the engine (devparm, netgame, demorecording...). Only what is the same in every game:
  ///   Doom, Heretic, Hexen and Strife. The answers are read when asked, they change all the time
  /// </summary>
  IGameContext = interface
    ['{D8A3F571-2B9C-4E04-A6D7-91C5E0B83F26}']
    /// <summary>Started with -devparm</summary>
    function IsDeveloperMode: Boolean;
    /// <summary>True only if packets are broadcast</summary>
    function IsNetGame: Boolean;
    function IsDemoRecording: Boolean;
    function IsDemoPlayback: Boolean;
    function IsPaused: Boolean;
    /// <summary>The tic of the game</summary>
    function GameTic: Integer;
  end;

implementation

end.
