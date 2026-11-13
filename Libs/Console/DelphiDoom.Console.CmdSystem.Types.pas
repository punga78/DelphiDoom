{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 command system, shared types         }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.h.                }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.Types;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.CmdArgs;

const
  /// <summary>CMD_FL_ALL</summary>
  CMD_FL_ALL = -1;
  /// <summary>command is considered a cheat</summary>
  CMD_FL_CHEAT = 1 shl 0;
  /// <summary>system command</summary>
  CMD_FL_SYSTEM = 1 shl 1;
  /// <summary>renderer command</summary>
  CMD_FL_RENDERER = 1 shl 2;
  /// <summary>sound command</summary>
  CMD_FL_SOUND = 1 shl 3;
  /// <summary>game command</summary>
  CMD_FL_GAME = 1 shl 4;
  /// <summary>tool command</summary>
  CMD_FL_TOOL = 1 shl 5;

  /// <summary>idCmdSystemLocal::MAX_CMD_BUFFER</summary>
  CMD_MAX_BUFFER = $10000;

type
  /// <summary>cmdExecution_t: parameters for command buffer stuffing</summary>
  TCmdExecution = (
    /// <summary>CMD_EXEC_NOW: don't return until completed</summary>
    ceNow,
    /// <summary>CMD_EXEC_INSERT: insert at current position, but don't run yet</summary>
    ceInsert,
    /// <summary>CMD_EXEC_APPEND: add to end of the command buffer (normal case)</summary>
    ceAppend
  );

  /// <summary>The <c>void(*callback)(const char *s)</c> of the completion functions</summary>
  TCmdCompletionCallback = reference to procedure(const AText: AnsiString);

  /// <summary>
  ///   cmdFunction_t. A method of an object, not an anonymous method: AddCommand compares the
  ///   function of a name already defined with the new one, as the original compares pointers
  /// </summary>
  TCmdFunction = procedure(const AArgs: TIdCmdArgs) of object;

  /// <summary>argCompletion_t: gives the valid texts for the argument being typed to the callback</summary>
  TCmdArgCompletion = procedure(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback) of object;

  /// <summary>What a command is (a copy of a commandDef_t without the function)</summary>
  TCmdInfo = record
    Name: AnsiString;
    Description: AnsiString;
    Flags: Integer;
  end;

  /// <summary>
  ///   A wrong use of the command system that the original reports with common->FatalError (a bad
  ///   execution type)
  /// </summary>
  ECmdSystemException = class(Exception);

implementation

end.
