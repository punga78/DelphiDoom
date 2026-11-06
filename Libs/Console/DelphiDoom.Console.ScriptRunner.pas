{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - command files and texts                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.ScriptRunner;

interface

uses
  System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Runs the lines of a ".con" file (old C_ExecCommandFile) or of a text (old C_ExecCommands):
  ///   one command per line, the empty lines and the lines that start with "//" are skipped.
  ///   A file that runs itself, directly or not, is refused
  /// </summary>
  TConsoleScriptRunner = class(TInterfacedObject, IConsoleScriptRunner)
  private
    FInterpreter: IConsoleInterpreter;
    FFileSystem: IConsoleFileSystem;
    FOutput: IConsoleOutput;
    FLog: ILog;
    FRunning: TList<string>;
    procedure RunLines(const ALines: TArray<string>);
  public
    constructor Create(const AInterpreter: IConsoleInterpreter; const AFileSystem: IConsoleFileSystem;
      const AOutput: IConsoleOutput; const ALog: ILog);
    destructor Destroy; override;
    procedure RunFile(const AFileName: string);
    procedure RunText(const AText: string);
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Console.Text;

const
  LINE_BREAK = #13#10;
  COMMAND_FILE_EXTENSION = '.CON';
  COMMENT_PREFIX = '//';

{ TConsoleScriptRunner }

constructor TConsoleScriptRunner.Create(const AInterpreter: IConsoleInterpreter;
  const AFileSystem: IConsoleFileSystem; const AOutput: IConsoleOutput; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create('AInterpreter');
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FInterpreter := AInterpreter;
  FFileSystem := AFileSystem;
  FOutput := AOutput;
  FLog := ALog;
  FRunning := TList<string>.Create;
end;

destructor TConsoleScriptRunner.Destroy;
begin
  FRunning.Free;
  inherited Destroy;
end;

procedure TConsoleScriptRunner.RunLines(const ALines: TArray<string>);
var
  LLine: string;
  LCommand: string;
begin
  for LLine in ALines do
  begin
    LCommand := TConsoleText.Trim(LLine);
    if LCommand <> '' then
      if not TConsoleText.StartsWith(COMMENT_PREFIX, LCommand) then
        FInterpreter.Execute(LCommand);
  end;
end;

procedure TConsoleScriptRunner.RunFile(const AFileName: string);
var
  LName: string;
begin
  if AFileName = '' then
  begin
    FOutput.Write('Usage:' + LINE_BREAK + ' exec [command file(*.con)]' + LINE_BREAK);
    Exit;
  end;

  LName := FFileSystem.ExpandFileName(AFileName);
  if not FFileSystem.FileExists(LName) then
  begin
    LName := LName + COMMAND_FILE_EXTENSION;
    if not FFileSystem.FileExists(LName) then
    begin
      FOutput.Write(' Command file not found: ' + AFileName + LINE_BREAK);
      Exit;
    end;
  end;

  LName := TConsoleText.UpperCase(LName);
  if FRunning.IndexOf(LName) >= 0 then
  begin
    FLog.Warning(' Recursive calls of con files are not allowed(' + AFileName + ')' + LINE_BREAK);
    Exit;
  end;

  FRunning.Add(LName);
  try
    FOutput.Write(' Running command file: ' + LName + LINE_BREAK);
    RunLines(FFileSystem.ReadLines(LName));
  finally
    FRunning.Delete(FRunning.IndexOf(LName));
  end;
end;

procedure TConsoleScriptRunner.RunText(const AText: string);
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    RunLines(LLines.ToStringArray);
  finally
    LLines.Free;
  end;
end;

end.
