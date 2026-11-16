{******************************************************************************}
{                                                                              }
{  DelphiDoom: command line library - shared constants and exception          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.CommandLine.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The engine keeps at most this many arguments (the program name is the first)</summary>
  COMMANDLINE_MAX_ARGUMENTS = 1024;
  /// <summary>Put before the arguments that come from the default file, so that they can be told apart</summary>
  COMMANDLINE_DEFAULT_MARKER = '-DEFAULTCMDMARKER';

type
  /// <summary>Raised for bad positions and for arguments that cannot be kept</summary>
  ECommandLineException = class(Exception);

implementation

end.
