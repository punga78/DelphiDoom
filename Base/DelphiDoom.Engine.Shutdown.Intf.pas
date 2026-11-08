{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - how a class of the engine stops the game               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Shutdown.Intf;

interface

type
  /// <summary>
  ///   The two ways out of the game that a class of the engine needs: a fatal error and the
  ///   request to close the program. ILog.Error only writes the message, it does not stop
  ///   anything, so a class that used I_Error receives this one beside the log
  /// </summary>
  IEngineShutdown = interface
    ['{5C1E7A42-8D3B-4F6A-9B05-2E71C4D8A913}']
    /// <summary>
    ///   Writes the message to the error file, the dialog and the output and shuts the game
    ///   down (I_Error). The message is used as it is: it is not a format string
    /// </summary>
    procedure Fail(const AText: string);
    /// <summary>Asks the main window to close, the game ends normally (I_Quit)</summary>
    procedure Quit;
  end;

implementation

end.
