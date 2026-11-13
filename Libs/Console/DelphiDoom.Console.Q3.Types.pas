{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, shared types               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cmd.c, cvar.c,  }
{  q_shared.h (cvar flags, vmCvar_t), qcommon.h (cbufExec_t).                  }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>CVAR_ARCHIVE: set to cause it to be saved to a config file</summary>
  Q3_CVAR_ARCHIVE = 1;
  /// <summary>CVAR_USERINFO: sent to the server on connect or change</summary>
  Q3_CVAR_USERINFO = 2;
  /// <summary>CVAR_SERVERINFO: sent in response to front end requests</summary>
  Q3_CVAR_SERVERINFO = 4;
  /// <summary>CVAR_SYSTEMINFO: duplicated on all clients</summary>
  Q3_CVAR_SYSTEMINFO = 8;
  /// <summary>CVAR_INIT: cannot be changed from the console at all, only set at startup</summary>
  Q3_CVAR_INIT = 16;
  /// <summary>CVAR_LATCH: changes only when the code next asks for the variable (Cvar_Get)</summary>
  Q3_CVAR_LATCH = 32;
  /// <summary>CVAR_ROM: display only, cannot be set by the user at all</summary>
  Q3_CVAR_ROM = 64;
  /// <summary>CVAR_USER_CREATED: created by a set command</summary>
  Q3_CVAR_USER_CREATED = 128;
  /// <summary>CVAR_TEMP: can be set even when cheats are disabled, but is not archived</summary>
  Q3_CVAR_TEMP = 256;
  /// <summary>CVAR_CHEAT: cannot be changed if cheats are disabled</summary>
  Q3_CVAR_CHEAT = 512;
  /// <summary>CVAR_NORESTART: not cleared by cvar_restart</summary>
  Q3_CVAR_NORESTART = 1024;

  /// <summary>MAX_CMD_BUFFER: the size of the command text buffer</summary>
  Q3_MAX_CMD_BUFFER = 16384;
  /// <summary>MAX_CMD_LINE: a command line longer than this minus one is cut</summary>
  Q3_MAX_CMD_LINE = 1024;
  /// <summary>MAX_STRING_TOKENS: tokens of a command line; the rest is ignored</summary>
  Q3_MAX_STRING_TOKENS = 1024;
  /// <summary>BIG_INFO_STRING: the size of the buffer of the original command (Cmd_Cmd)</summary>
  Q3_BIG_INFO_STRING = 8192;
  /// <summary>MAX_CVARS: the cvar slots; slots of removed variables are not reused</summary>
  Q3_MAX_CVARS = 1024;
  /// <summary>MAX_CVAR_VALUE_STRING: the string of a vmCvar_t</summary>
  Q3_MAX_CVAR_VALUE_STRING = 256;
  /// <summary>MAX_QPATH: the name of the file of the exec command is cut to this minus one</summary>
  Q3_MAX_QPATH = 64;
  /// <summary>The color code that the cvar print appends to the strings (S_COLOR_WHITE)</summary>
  Q3_COLOR_WHITE = '^7';

  SQ3ConsoleBadExecution = 'Cbuf_ExecuteText: bad exec_when';
  SQ3ConsoleMaxCVars = 'MAX_CVARS';
  SQ3ConsoleBadHandle = 'Cvar_Update: handle out of range';
  SQ3ConsoleValueTooLong = 'Cvar_Update: src %s length %d exceeds MAX_CVAR_VALUE_STRING';
  SQ3ConsoleNoInfoWriter = 'The info strings need an IQ3InfoStringWriter';

type
  /// <summary>Everything the Quake III console reports with <c>Com_Error</c></summary>
  EQ3ConsoleException = class(Exception);

  /// <summary>cbufExec_t: when a command text is executed</summary>
  TQ3Execution = (
    /// <summary>EXEC_NOW: do not return until completed (an empty text runs the whole buffer)</summary>
    qeNow,
    /// <summary>EXEC_INSERT: insert at the current position, but do not run yet</summary>
    qeInsert,
    /// <summary>EXEC_APPEND: add to the end of the buffer (the normal case)</summary>
    qeAppend
  );

  /// <summary>xcommand_t: a command function. A method, so that commands can be compared like pointers</summary>
  TQ3CommandFunction = procedure of object;

  /// <summary>
  ///   vmCvar_t: the copy of a cvar that the modules which cannot see the cvar itself hold. <c>Handle</c>
  ///   is the index of the cvar slot
  /// </summary>
  TQ3VmCvar = record
    Handle: Integer;
    ModificationCount: Integer;
    Value: Single;
    IntegerValue: Integer;
    StringValue: AnsiString;
  end;

implementation

end.
