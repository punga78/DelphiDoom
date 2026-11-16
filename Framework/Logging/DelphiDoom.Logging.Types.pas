{******************************************************************************}
{                                                                              }
{  DelphiDoom: logging library - channels and prefixes                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Logging.Types;

interface

{$SCOPEDENUMS ON}

const
  /// <summary>What a warning starts with in the output and in the error file</summary>
  LOG_WARNING_PREFIX = 'I_Warning: ';
  /// <summary>What an error starts with in the output and in the error file</summary>
  LOG_ERROR_PREFIX = 'I_Error: ';
  LOG_LINE_BREAK = #13#10;

type
  /// <summary>Where a message goes: a sink decides what each channel means</summary>
  TLogChannel = (
    /// <summary>The standard output: the console of the game, the startup window, the stdout file</summary>
    Output,
    /// <summary>The file of the errors and warnings</summary>
    ErrorFile,
    /// <summary>A message box, for the error that ends the game</summary>
    Dialog
  );

implementation

end.
