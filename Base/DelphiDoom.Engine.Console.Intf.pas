{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the console on the screen                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Intf;

{$I Doom32.inc}

interface

uses
  d_event;

type
  /// <summary>
  ///   The console of the game: the text that it shows, the line that the player types, how it
  ///   comes down and goes up, and its drawing. The composition root gives it to the main loop
  ///   (d_main starts it, gives it the keys, draws it and frees it), to the loop of the network
  ///   (its tic), to the video (its size), to the game (p_tick pauses while it is down) and to
  ///   the scripts (the commands they queue). It was the facade c_con.pas
  /// </summary>
  IEngineConsole = interface
    ['{2E9B4C71-58A3-4D0F-9C16-7B3F0E8D5A24}']
    /// <summary>
    ///   Empties the text, takes the output of the program (outproc) and registers the commands
    ///   of the console (C_Init)
    /// </summary>
    procedure Initialize;
    /// <summary>Frees the objects of Libs\Console that the console owns (C_ShutDown)</summary>
    procedure Shutdown;
    /// <summary>The size of the console from the size of its screen (C_AdjustScreenSize)</summary>
    procedure AdjustScreenSize;
    /// <summary>Queues a command line, run at the next key (C_AddCommand); nothing before Initialize</summary>
    procedure AddCommand(const ACommand: string);
    /// <summary>Adds the text to the console, CR ends a line and LF is skipped (C_AddText)</summary>
    procedure AddText(const AText: string);
    /// <summary>Draws the console on the screen, if it is down (C_Drawer)</summary>
    procedure Draw;
    /// <summary>One tic: the console comes down or goes up, the cursor blinks (C_Ticker)</summary>
    procedure Tick;
    /// <summary>Takes a key if the console wants it (C_Responder)</summary>
    function Respond(const AEvent: Pevent_t): Boolean;
    /// <summary>True if the console is not all up (C_IsConsoleActive)</summary>
    function IsActive: Boolean;
    /// <summary>The bottom of the console, in pixels of its screen (C_ConsolePos)</summary>
    function Position: Integer;
  end;

implementation

end.
