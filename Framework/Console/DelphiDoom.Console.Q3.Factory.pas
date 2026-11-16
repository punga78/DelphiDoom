{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, composition                }
{                                                                              }
{  Assembles the command buffer, the command list, the tokenizer and the       }
{  cvars of Quake III. The one place that knows the concrete classes.          }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.CommandArguments,
  DelphiDoom.Console.Q3.CommandBuffer, DelphiDoom.Console.Q3.CommandSystem, DelphiDoom.Console.Q3.StandardCommands,
  DelphiDoom.Console.Q3.CVarSystem, DelphiDoom.Console.Q3.CVarCommands;

type
  /// <summary>
  ///   The Quake III profile of the console: the command buffer and list (cmd.c) and the cvars (cvar.c)
  ///   that know each other through interfaces: a line that is not a command is a variable, vstr reads
  ///   variables, set and toggle are commands. Separate from the console of the DelphiDoom engine
  ///   (<c>ICommandRegistry</c>) and from the idTech 4 profile, and not a singleton: make as many as needed.
  ///   Log, files, game commands and info string writer are optional (nil = silent, no files, nothing
  ///   handles the unknown lines, no info strings)
  /// </summary>
  TQ3Console = class
  strict private
    FArguments: IQ3CommandArguments;
    FCommandSystem: TQ3CommandSystem;
    FRegistry: IQ3CommandRegistry;
    FBuffer: IQ3CommandBuffer;
    FCVars: IQ3CVarSystem;
    FStandardCommands: TQ3StandardCommands;
    FCVarCommands: TQ3CVarCommands;
  public
    constructor Create(const ALog: IQ3ConsoleLog = nil; const AFiles: IQ3FileSystem = nil;
      const AUnhandled: IQ3UnhandledCommands = nil; const AInfoWriter: IQ3InfoStringWriter = nil);
    destructor Destroy; override;
    /// <summary>Cmd_Init and Cvar_Init: the commands of both, sv_cheats</summary>
    procedure Init;
    property Arguments: IQ3CommandArguments read FArguments;
    property Commands: IQ3CommandRegistry read FRegistry;
    property Buffer: IQ3CommandBuffer read FBuffer;
    property CVars: IQ3CVarSystem read FCVars;
  end;

implementation

{ TQ3Console }

constructor TQ3Console.Create(const ALog: IQ3ConsoleLog; const AFiles: IQ3FileSystem;
  const AUnhandled: IQ3UnhandledCommands; const AInfoWriter: IQ3InfoStringWriter);
begin
  inherited Create;
  FArguments := TQ3CommandArguments.Create;
  FCommandSystem := TQ3CommandSystem.Create(FArguments, ALog, AUnhandled);
  // the interface keeps the command system alive; the object is only the way to set its variable handler
  FRegistry := FCommandSystem;
  FBuffer := TQ3CommandBuffer.Create(FRegistry, ALog);
  FCVars := TQ3CVarSystem.Create(ALog, AInfoWriter);
  FStandardCommands := TQ3StandardCommands.Create(FRegistry, FBuffer, FArguments, FCVars, ALog, AFiles);
  FCVarCommands := TQ3CVarCommands.Create(FRegistry, FCVars, FArguments, ALog);
  FCommandSystem.CVarHandler := FCVarCommands;
end;

destructor TQ3Console.Destroy;
begin
  FCommandSystem.CVarHandler := nil;
  FCVarCommands.Free;
  FStandardCommands.Free;
  FBuffer := nil;
  FCVars := nil;
  FRegistry := nil;
  FArguments := nil;
  inherited Destroy;
end;

procedure TQ3Console.Init;
begin
  FStandardCommands.Init;
  FCVars.Init;
  FCVarCommands.Init;
end;

end.
