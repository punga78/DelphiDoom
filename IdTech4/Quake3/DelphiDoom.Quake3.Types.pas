{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - shared types                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>The program cannot start with what it was given (a folder that is not there ...)</summary>
  EQ3ProgramException = class(Exception);

const
  /// <summary>The program ran to its end (the frames were done or "quit" was executed)</summary>
  Q3_EXIT_OK = 0;
  /// <summary>A module raised Com_Error (the game or the botlib gave up)</summary>
  Q3_EXIT_COM_ERROR = 1;
  /// <summary>A module made a system call the host does not serve</summary>
  Q3_EXIT_UNSERVED_TRAP = 2;
  /// <summary>Anything else that stopped the program (no map, no game files, a fault of the machine)</summary>
  Q3_EXIT_FAILURE = 3;
  /// <summary>The command line was not understood</summary>
  Q3_EXIT_USAGE = 4;

  /// <summary>TQ3ProgramOptions.Frames when the program runs until "quit"</summary>
  Q3_FRAMES_UNLIMITED = -1;

type
  /// <summary>What the command line asked for</summary>
  TQ3ProgramOptions = record
    /// <summary>The "+" commands, each a complete line (set, map, addbot ...), in the order they were given</summary>
    Commands: TArray<AnsiString>;
    /// <summary>The number of frames of the main loop to run; Q3_FRAMES_UNLIMITED: until "quit"</summary>
    Frames: Integer;
    /// <summary>No client in the process: only the server (and its bots) runs</summary>
    NoClient: Boolean;
    /// <summary>-help: print the usage and stop</summary>
    Help: Boolean;
  end;

implementation

end.
