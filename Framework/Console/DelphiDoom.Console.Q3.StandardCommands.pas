{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, the commands of cmd.c      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cmd.c           }
{  (Cmd_List_f, Cmd_Exec_f, Cmd_Vstr_f, Cmd_Echo_f, Cmd_Wait_f, Cmd_Init).     }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.StandardCommands;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   <c>cmdlist</c>, <c>exec</c>, <c>vstr</c>, <c>echo</c> and <c>wait</c>. The file of exec is cut to 63
  ///   characters and gets ".cfg" unless its last path part has an extension; an empty name is not handled
  ///   by the original (it reads before the buffer), here it gets the extension. The log, the files and the
  ///   variables are optional: without them the command only does what it can
  /// </summary>
  TQ3StandardCommands = class
  strict private
    FRegistry: IQ3CommandRegistry;
    FBuffer: IQ3CommandBuffer;
    FArguments: IQ3CommandArguments;
    FCVars: IQ3CVarReader;
    FLog: IQ3ConsoleLog;
    FFiles: IQ3FileSystem;
    procedure Print(const AText: string);
    function WithDefaultExtension(const APath: AnsiString): AnsiString;
  public
    constructor Create(const ARegistry: IQ3CommandRegistry; const ABuffer: IQ3CommandBuffer;
      const AArguments: IQ3CommandArguments; const ACVars: IQ3CVarReader = nil; const ALog: IQ3ConsoleLog = nil;
      const AFiles: IQ3FileSystem = nil);
    /// <summary>Cmd_Init: registers the five commands</summary>
    procedure Init;
    /// <summary>Cmd_List_f</summary>
    procedure List;
    /// <summary>Cmd_Exec_f</summary>
    procedure Exec;
    /// <summary>Cmd_Vstr_f</summary>
    procedure Vstr;
    /// <summary>Cmd_Echo_f</summary>
    procedure Echo;
    /// <summary>Cmd_Wait_f</summary>
    procedure Wait;
  end;

implementation

{ TQ3StandardCommands }

constructor TQ3StandardCommands.Create(const ARegistry: IQ3CommandRegistry; const ABuffer: IQ3CommandBuffer;
  const AArguments: IQ3CommandArguments; const ACVars: IQ3CVarReader; const ALog: IQ3ConsoleLog;
  const AFiles: IQ3FileSystem);
begin
  inherited Create;
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create('ARegistry');
  if not Assigned(ABuffer) then
    raise EArgumentNilException.Create('ABuffer');
  if not Assigned(AArguments) then
    raise EArgumentNilException.Create('AArguments');
  FRegistry := ARegistry;
  FBuffer := ABuffer;
  FArguments := AArguments;
  FCVars := ACVars;
  FLog := ALog;
  FFiles := AFiles;
end;

procedure TQ3StandardCommands.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

procedure TQ3StandardCommands.Init;
begin
  FRegistry.AddCommand('cmdlist', List);
  FRegistry.AddCommand('exec', Exec);
  FRegistry.AddCommand('vstr', Vstr);
  FRegistry.AddCommand('echo', Echo);
  FRegistry.AddCommand('wait', Wait);
end;

procedure TQ3StandardCommands.List;
var
  LName: AnsiString;
  LMatch: AnsiString;
  LHasMatch: Boolean;
  LCount: Integer;
begin
  LHasMatch := FArguments.Count > 1;
  if LHasMatch then
    LMatch := FArguments.Argv(1);
  LCount := 0;
  for LName in FRegistry.CommandNames do
  begin
    if LHasMatch and not TIdStrings.Filter(LMatch, LName, False) then
      Continue;
    Print(string(LName) + #10);
    Inc(LCount);
  end;
  Print(Format('%d commands'#10, [LCount]));
end;

function TQ3StandardCommands.WithDefaultExtension(const APath: AnsiString): AnsiString;
var
  LIndex: Integer;
  LCombined: AnsiString;
begin
  Result := APath;
  // COM_DefaultExtension: only the last path part is searched, never the first character
  LIndex := Length(APath);
  while LIndex >= 2 do
  begin
    if APath[LIndex] = '/' then
      Break;
    if APath[LIndex] = '.' then
      Exit;
    Dec(LIndex);
  end;
  LCombined := APath + '.cfg';
  if Length(LCombined) >= Q3_MAX_QPATH then
  begin
    Print(Format('Com_sprintf: overflow of %d in %d'#10, [Length(LCombined), Q3_MAX_QPATH]));
    LCombined := Copy(LCombined, 1, Q3_MAX_QPATH - 1);
  end;
  Result := LCombined;
end;

procedure TQ3StandardCommands.Exec;
var
  LName: AnsiString;
  LText: AnsiString;
begin
  if FArguments.Count <> 2 then
  begin
    Print('exec <filename> : execute a script file'#10);
    Exit;
  end;
  LName := WithDefaultExtension(Copy(FArguments.Argv(1), 1, Q3_MAX_QPATH - 1));
  if (not Assigned(FFiles)) or (not FFiles.TryReadFile(LName, LText)) then
  begin
    Print('couldn''t exec ' + string(FArguments.Argv(1)) + #10);
    Exit;
  end;
  Print('execing ' + string(FArguments.Argv(1)) + #10);
  FBuffer.InsertText(LText);
end;

procedure TQ3StandardCommands.Vstr;
var
  LValue: AnsiString;
begin
  if FArguments.Count <> 2 then
  begin
    Print('vstr <variablename> : execute a variable command'#10);
    Exit;
  end;
  if Assigned(FCVars) then
    LValue := FCVars.VariableString(FArguments.Argv(1))
  else
    LValue := '';
  FBuffer.InsertText(LValue + #10);
end;

procedure TQ3StandardCommands.Echo;
var
  LIndex: Integer;
begin
  for LIndex := 1 to FArguments.Count - 1 do
    Print(string(FArguments.Argv(LIndex)) + ' ');
  Print(#10);
end;

procedure TQ3StandardCommands.Wait;
begin
  if FArguments.Count = 2 then
    FBuffer.Wait := TIdCNumbers.Atoi(FArguments.Argv(1))
  else
    FBuffer.Wait := 1;
end;

end.
