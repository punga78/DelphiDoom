{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the commands that need only the console       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.StandardCommands;

interface

uses
  DelphiDoom.Console.Intf, DelphiDoom.Console.CommandLister;

type
  /// <summary>
  ///   "cmdlist, list, listcmds", "exec, execcommandfile" and "printf, write, writeln": the
  ///   commands of the console that do not depend on the game
  /// </summary>
  TConsoleStandardCommands = class
  private
    FRegistry: ICommandRegistry;
    FOutput: IConsoleOutput;
    FRunner: IConsoleScriptRunner;
    FLister: TConsoleCommandLister;
  public
    constructor Create(const ARegistry: ICommandRegistry; const AOutput: IConsoleOutput;
      const ARunner: IConsoleScriptRunner);
    destructor Destroy; override;
    /// <summary>Text, a space and the rest of the line, then a line break (old C_CmdPrintf)</summary>
    procedure Print(const AParam1, AParam2: string);
    procedure Register;
  end;

implementation

uses
  System.SysUtils;

const
  LINE_BREAK = #13#10;

{ TConsoleStandardCommands }

constructor TConsoleStandardCommands.Create(const ARegistry: ICommandRegistry;
  const AOutput: IConsoleOutput; const ARunner: IConsoleScriptRunner);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(ARunner) then
    raise EArgumentNilException.Create('ARunner');
  FRegistry := ARegistry;
  FOutput := AOutput;
  FRunner := ARunner;
  FLister := TConsoleCommandLister.Create(ARegistry, AOutput);
end;

destructor TConsoleStandardCommands.Destroy;
begin
  FLister.Free;
  inherited Destroy;
end;

procedure TConsoleStandardCommands.Print(const AParam1, AParam2: string);
begin
  if AParam2 = '' then
    FOutput.Write(AParam1 + LINE_BREAK)
  else
    FOutput.Write(AParam1 + ' ' + AParam2 + LINE_BREAK);
end;

procedure TConsoleStandardCommands.Register;
begin
  FRegistry.Add('cmdlist, list, listcmds',
    procedure(const AParam1, AParam2: string)
    begin
      FLister.List(AParam1);
    end);
  FRegistry.Add('exec, execcommandfile',
    procedure(const AParam1, AParam2: string)
    begin
      FRunner.RunFile(AParam1);
    end);
  FRegistry.Add('printf, write, writeln', Print);
end;

end.
