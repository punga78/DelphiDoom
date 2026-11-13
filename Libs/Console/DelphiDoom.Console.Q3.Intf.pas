{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, contracts                  }
{                                                                              }
{  Small interfaces between the parts of cmd.c and cvar.c (the command text    }
{  buffer, the tokenizer, the command list, the cvars) and what they need from }
{  the engine (print, files, game commands, info strings).                     }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.CVar;

type
  /// <summary>Where <c>Com_Printf</c> and <c>Com_DPrintf</c> go</summary>
  IQ3ConsoleLog = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E301}']
    /// <summary>Com_Printf: the text as the original formats it, with its line feeds</summary>
    procedure Print(const AText: string);
    /// <summary>Com_DPrintf: printed only in developer mode, the log decides</summary>
    procedure DevPrint(const AText: string);
  end;

  /// <summary>The tokenized command line (Cmd_TokenizeString, Cmd_Argc, Cmd_Argv, ...)</summary>
  IQ3CommandArguments = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E302}']
    /// <summary>Cmd_TokenizeString: splits a line into tokens; an empty line leaves no token</summary>
    procedure Tokenize(const AText: AnsiString);
    /// <summary>Cmd_Argc</summary>
    function Count: Integer;
    /// <summary>Cmd_Argv: a token, or an empty string if out of range</summary>
    function Argv(AIndex: Integer): AnsiString;
    /// <summary>Cmd_Args: the tokens from the second one, joined by spaces</summary>
    function Args: AnsiString;
    /// <summary>Cmd_ArgsFrom: the tokens from the given one (below 0 is 0), joined by spaces</summary>
    function ArgsFrom(AIndex: Integer): AnsiString;
    /// <summary>Cmd_Cmd: the line as it was received, cut to BIG_INFO_STRING - 1 characters</summary>
    function Cmd: AnsiString;
  end;

  /// <summary>The list of commands (Cmd_AddCommand, Cmd_RemoveCommand, Cmd_ExecuteString)</summary>
  IQ3CommandRegistry = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E303}']
    /// <summary>
    ///   Cmd_AddCommand: a nil function is a command that only the game handles (it still completes).
    ///   A name already defined is not replaced and says so unless the function is nil
    /// </summary>
    procedure AddCommand(const AName: AnsiString; const AFunction: TQ3CommandFunction);
    /// <summary>Cmd_RemoveCommand</summary>
    procedure RemoveCommand(const AName: AnsiString);
    /// <summary>Cmd_ExecuteString: runs one command line</summary>
    procedure ExecuteString(const AText: AnsiString);
    /// <summary>Cmd_CommandCompletion: the names, in the order of the list (last used first)</summary>
    function CommandNames: TArray<AnsiString>;
  end;

  /// <summary>The command text buffer (Cbuf_*)</summary>
  IQ3CommandBuffer = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E304}']
    function GetWait: Integer;
    procedure SetWait(AValue: Integer);
    /// <summary>Cbuf_AddText: at the end, without a final line feed</summary>
    procedure AddText(const AText: AnsiString);
    /// <summary>Cbuf_InsertText: right after the current command, with a line feed</summary>
    procedure InsertText(const AText: AnsiString);
    /// <summary>Cbuf_ExecuteText</summary>
    procedure ExecuteText(AWhen: TQ3Execution; const AText: AnsiString);
    /// <summary>Cbuf_Execute: runs the lines of the buffer, unless a wait is pending</summary>
    procedure Execute;
    /// <summary>The text still to run (cmd_text)</summary>
    function Pending: AnsiString;
    /// <summary>cmd_wait: the frames the rest of the buffer waits</summary>
    property Wait: Integer read GetWait write SetWait;
  end;

  /// <summary>What the commands and the vstr command need to read of the variables</summary>
  IQ3CVarReader = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E305}']
    /// <summary>Cvar_VariableValue: 0 if the variable does not exist</summary>
    function VariableValue(const AName: AnsiString): Single;
    /// <summary>Cvar_VariableIntegerValue</summary>
    function VariableIntegerValue(const AName: AnsiString): Integer;
    /// <summary>Cvar_VariableString: empty if the variable does not exist</summary>
    function VariableString(const AName: AnsiString): AnsiString;
    /// <summary>Cvar_VariableStringBuffer: the string cut to ASize - 1 characters</summary>
    function VariableStringBuffer(const AName: AnsiString; ASize: Integer): AnsiString;
  end;

  /// <summary>The cvar system (cvar.c without the console commands)</summary>
  IQ3CVarSystem = interface(IQ3CVarReader)
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E306}']
    function GetModifiedFlags: Integer;
    procedure SetModifiedFlags(AValue: Integer);
    /// <summary>Cvar_Init: creates sv_cheats</summary>
    procedure Init;
    /// <summary>Cvar_Get: the variable, created if it does not exist</summary>
    function Get(const AName, AValue: AnsiString; AFlags: Integer): TQ3CVar;
    /// <summary>Cvar_FindVar: nil if there is no such variable (names ignore case)</summary>
    function Find(const AName: AnsiString): TQ3CVar;
    /// <summary>Cvar_Set2 with a value (the NULL value is <c>Reset</c>); the variable it set or created</summary>
    function Set2(const AName, AValue: AnsiString; AForce: Boolean): TQ3CVar;
    /// <summary>Cvar_Set (forced)</summary>
    procedure SetValueText(const AName, AValue: AnsiString);
    /// <summary>Cvar_SetLatched</summary>
    procedure SetLatched(const AName, AValue: AnsiString);
    /// <summary>Cvar_SetValue: a float, as an integer when it has no fraction</summary>
    procedure SetNumber(const AName: AnsiString; AValue: Single);
    /// <summary>Cvar_Reset: back to the reset string (not forced)</summary>
    procedure Reset(const AName: AnsiString);
    /// <summary>Cvar_SetCheatState: the cheat variables go back to their safe values</summary>
    procedure SetCheatState;
    /// <summary>Cvar_Restart_f without the print</summary>
    procedure Restart;
    /// <summary>Cvar_WriteVariables: the lines "seta name value" of the archived variables, as one text</summary>
    function WriteVariables: AnsiString;
    /// <summary>Cvar_InfoString (needs an info string writer)</summary>
    function InfoString(ABit: Integer): AnsiString;
    /// <summary>Cvar_InfoString_Big</summary>
    function InfoStringBig(ABit: Integer): AnsiString;
    /// <summary>Cvar_InfoStringBuffer: the info string cut to ASize - 1 characters</summary>
    function InfoStringBuffer(ABit: Integer; ASize: Integer): AnsiString;
    /// <summary>Cvar_Register: Cvar_Get and the first update of the copy</summary>
    procedure Register(var AVmCvar: TQ3VmCvar; const AName, ADefault: AnsiString; AFlags: Integer);
    /// <summary>Cvar_Update</summary>
    procedure Update(var AVmCvar: TQ3VmCvar);
    /// <summary>The variables in the order of the list (last created first), including none of the removed</summary>
    function Variables: TArray<TQ3CVar>;
    /// <summary>cvar_numIndexes</summary>
    function IndexCount: Integer;
    /// <summary>cvar_modifiedFlags: the flags of the variables changed since the engine cleared them</summary>
    property ModifiedFlags: Integer read GetModifiedFlags write SetModifiedFlags;
  end;

  /// <summary>Cvar_Command: a line that starts with a variable name prints or sets it</summary>
  IQ3CVarCommandHandler = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E307}']
    /// <summary>True if the first token of the current line is a variable</summary>
    function Command: Boolean;
  end;

  /// <summary>
  ///   What follows when a line is neither a command nor a variable: the client game, the server game
  ///   and the ui commands, and the forwarding to the server (<c>CL_ForwardCommandToServer</c>)
  /// </summary>
  IQ3UnhandledCommands = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E308}']
    /// <summary>Gets the line (the text, not the tokens); the result is only informative</summary>
    function Execute(const AText: AnsiString): Boolean;
  end;

  /// <summary>FS_ReadFile as the exec command uses it</summary>
  IQ3FileSystem = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E309}']
    /// <summary>The text of a file; false if it does not exist</summary>
    function TryReadFile(const AName: AnsiString; out AText: AnsiString): Boolean;
  end;

  /// <summary>
  ///   Info_SetValueForKey and Info_SetValueForKey_Big of q_shared.c (<c>TQ3InfoString</c> of
  ///   <c>Libs\Net</c> does it); the console does not depend on that library
  /// </summary>
  IQ3InfoStringWriter = interface
    ['{5E1B7A52-2C3D-4B8E-9A60-7D41C0A2E30A}']
    /// <summary>Changes or adds a pair; false if it was refused</summary>
    function SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString; ABig: Boolean): Boolean;
  end;

implementation

end.
