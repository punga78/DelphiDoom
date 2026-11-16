{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the names of the log files              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.LogFileNames;

// The names that I_InitializeIO of i_io.pas gave to the error, debug and output files
// (issue #185). The game and the kind of program (software or OpenGL) are parameters:
// the old code chose them with the defines of the project.

interface

uses
  System.SysUtils, DelphiDoom.EngineSystem.Types;

type
  /// <summary>Where the engine writes what it says: DATA\LOGS\&lt;Game&gt;32_stderr.txt and the other two</summary>
  TLogFileNames = class
  public
    /// <summary>
    ///   AGameName is Doom, Heretic, Hexen or Strife; AOpenGl puts GL in front of the name;
    ///   AUsesDebugPlayerFile (-debugfile) numbers the debug file with AConsolePlayer;
    ///   ACdRomFolder, when it is not empty, goes in front of the three names (the game runs from a CD-ROM)
    /// </summary>
    class function Build(const AGameName: string; AOpenGl: Boolean; AUsesDebugPlayerFile: Boolean;
      AConsolePlayer: Integer; const ACdRomFolder: string): TLogFileSet; static;
  end;

implementation

{ TLogFileNames }

class function TLogFileNames.Build(const AGameName: string; AOpenGl: Boolean;
  AUsesDebugPlayerFile: Boolean; AConsolePlayer: Integer; const ACdRomFolder: string): TLogFileSet;
var
  LPrefix: string;
begin
  if AOpenGl then
    LPrefix := 'DATA\LOGS\GL'
  else
    LPrefix := 'DATA\LOGS\';

  if AUsesDebugPlayerFile then
    Result.DebugFile := Format('%s%s32_debug%d.txt', [LPrefix, AGameName, AConsolePlayer])
  else
    Result.DebugFile := Format('%s%s32_debug.txt', [LPrefix, AGameName]);
  Result.ErrorFile := Format('%s%s32_stderr.txt', [LPrefix, AGameName]);
  Result.StdoutFile := Format('%s%s32_stdout.txt', [LPrefix, AGameName]);

  Result.DebugFile := ACdRomFolder + Result.DebugFile;
  Result.ErrorFile := ACdRomFolder + Result.ErrorFile;
  Result.StdoutFile := ACdRomFolder + Result.StdoutFile;
end;

end.
