{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - header of a compiled script                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The constants that the compiler writes and the interpreter and the tools    }
{  that load the DLLs of the compilers read. No dependencies: the editor and   }
{  ddc.exe link it without the rest of the library.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Compiled;

interface

const
  /// <summary>The first four bytes of a compiled script: 'DDPS'</summary>
  SCRIPT_COMPILED_ID = 1397769284;
  /// <summary>The version of the format of the compiled scripts (the compilers and the interpreter must agree)</summary>
  SCRIPT_COMPILED_VERSION = 103;

implementation

end.
