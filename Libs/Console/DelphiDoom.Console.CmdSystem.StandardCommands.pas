{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 own commands of the command system   }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CmdSystem.cpp               }
{  (List_f, Exec_f, Vstr_f, Echo_f, Parse_f, Wait_f and Init).                 }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CmdSystem.StandardCommands;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf,
  DelphiDoom.Console.CmdSystem.FolderCompletion;

type
  /// <summary>
  ///   The commands that idCmdSystemLocal::Init registers: listCmds and its variants by group,
  ///   exec, vstr, echo, parse and wait. They are methods of this object, registered in a
  ///   command system with <c>Register</c>. The file system, the cvars and the completion of
  ///   file names are optional (without them exec says "couldn't exec", vstr gives an empty
  ///   command and exec has no completion).
  /// </summary>
  TCmdStandardCommands = class
  strict private
    FCommands: ICmdCommands;
    FBuffer: ICmdBuffer;
    FLog: IIdLibLog;
    FFileSystem: IIdLibFileSystem;
    FCVars: ICVarReader;
    FFolderCompletion: TCmdFolderCompletion;
    procedure Print(const AText: string);
    procedure ListByFlags(const AArgs: TIdCmdArgs; const AFlags: Integer);
    procedure CompleteConfigName(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
  public
    /// <summary>
    ///   AFolderCompletion is not owned (nil: exec has no completion)
    /// </summary>
    constructor Create(const ACommands: ICmdCommands; const ABuffer: ICmdBuffer; const ALog: IIdLibLog;
      const AFileSystem: IIdLibFileSystem = nil; const ACVars: ICVarReader = nil;
      const AFolderCompletion: TCmdFolderCompletion = nil);
    /// <summary>The body of idCmdSystemLocal::Init: adds the eleven commands</summary>
    procedure Register;
    procedure ListCommands(const AArgs: TIdCmdArgs);
    procedure ListSystemCommands(const AArgs: TIdCmdArgs);
    procedure ListRendererCommands(const AArgs: TIdCmdArgs);
    procedure ListSoundCommands(const AArgs: TIdCmdArgs);
    procedure ListGameCommands(const AArgs: TIdCmdArgs);
    procedure ListToolCommands(const AArgs: TIdCmdArgs);
    procedure Exec(const AArgs: TIdCmdArgs);
    procedure Vstr(const AArgs: TIdCmdArgs);
    procedure Echo(const AArgs: TIdCmdArgs);
    procedure Parse(const AArgs: TIdCmdArgs);
    procedure Wait(const AArgs: TIdCmdArgs);
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, DelphiDoom.IdLib.Text.Str,
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers;

function PadRight(const AText: AnsiString; const AWidth: Integer): string;
begin
  Result := string(AText);
  if Length(Result) < AWidth then
    Result := Result + StringOfChar(' ', AWidth - Length(Result));
end;

{ TCmdStandardCommands }

constructor TCmdStandardCommands.Create(const ACommands: ICmdCommands; const ABuffer: ICmdBuffer;
  const ALog: IIdLibLog; const AFileSystem: IIdLibFileSystem; const ACVars: ICVarReader;
  const AFolderCompletion: TCmdFolderCompletion);
begin
  inherited Create;
  FCommands := ACommands;
  FBuffer := ABuffer;
  FLog := ALog;
  FFileSystem := AFileSystem;
  FCVars := ACVars;
  FFolderCompletion := AFolderCompletion;
end;

procedure TCmdStandardCommands.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

procedure TCmdStandardCommands.Register;
begin
  FCommands.AddCommand('listCmds', ListCommands, CMD_FL_SYSTEM, 'lists commands');
  FCommands.AddCommand('listSystemCmds', ListSystemCommands, CMD_FL_SYSTEM, 'lists system commands');
  FCommands.AddCommand('listRendererCmds', ListRendererCommands, CMD_FL_SYSTEM, 'lists renderer commands');
  FCommands.AddCommand('listSoundCmds', ListSoundCommands, CMD_FL_SYSTEM, 'lists sound commands');
  FCommands.AddCommand('listGameCmds', ListGameCommands, CMD_FL_SYSTEM, 'lists game commands');
  FCommands.AddCommand('listToolCmds', ListToolCommands, CMD_FL_SYSTEM, 'lists tool commands');
  if Assigned(FFolderCompletion) then
    FCommands.AddCommand('exec', Exec, CMD_FL_SYSTEM, 'executes a config file', CompleteConfigName)
  else
    FCommands.AddCommand('exec', Exec, CMD_FL_SYSTEM, 'executes a config file');
  FCommands.AddCommand('vstr', Vstr, CMD_FL_SYSTEM, 'inserts the current value of a cvar as command text');
  FCommands.AddCommand('echo', Echo, CMD_FL_SYSTEM, 'prints text');
  FCommands.AddCommand('parse', Parse, CMD_FL_SYSTEM, 'prints tokenized string');
  FCommands.AddCommand('wait', Wait, CMD_FL_SYSTEM, 'delays remaining buffered commands one or more frames');
end;

procedure TCmdStandardCommands.CompleteConfigName(const AArgs: TIdCmdArgs; const ACallback: TCmdCompletionCallback);
begin
  // ArgCompletion_ConfigName
  FFolderCompletion.Complete(AArgs, ACallback, '/', True, ['.cfg']);
end;

procedure TCmdStandardCommands.ListByFlags(const AArgs: TIdCmdArgs; const AFlags: Integer);
var
  LMatch: TIdStr;
  LAll, LListed: TArray<TCmdInfo>;
  LIndex, LCount: Integer;
begin
  if AArgs.Argc > 1 then
  begin
    LMatch := TIdStr.Create(AArgs.Args(1, -1));
    LMatch.Replace(' ', '');
  end
  else
    LMatch := TIdStr.Create('');

  LAll := FCommands.Commands;
  SetLength(LListed, Length(LAll));
  LCount := 0;
  for LIndex := 0 to High(LAll) do
  begin
    if (LAll[LIndex].Flags and AFlags) = 0 then
      Continue;
    if (LMatch.Length > 0) and not TIdStrings.Filter(LMatch, LAll[LIndex].Name, False) then
      Continue;
    LListed[LCount] := LAll[LIndex];
    Inc(LCount);
  end;
  SetLength(LListed, LCount);

  // idList::Sort is a qsort: equal names (that differ in case) have no defined order, here the
  // order of the list is kept
  TArray.Sort<TCmdInfo>(LListed, TComparer<TCmdInfo>.Construct(
    function(const ALeft, ARight: TCmdInfo): Integer
    begin
      Result := TIdStrings.Icmp(ALeft.Name, ARight.Name);
    end));

  for LIndex := 0 to High(LListed) do
    Print('  ' + PadRight(LListed[LIndex].Name, 21) + ' ' + string(LListed[LIndex].Description) + #10);
  Print(IntToStr(Length(LListed)) + ' commands'#10);
end;

procedure TCmdStandardCommands.ListCommands(const AArgs: TIdCmdArgs);
begin
  ListByFlags(AArgs, CMD_FL_ALL);
end;

procedure TCmdStandardCommands.ListSystemCommands(const AArgs: TIdCmdArgs);
begin
  ListByFlags(AArgs, CMD_FL_SYSTEM);
end;

procedure TCmdStandardCommands.ListRendererCommands(const AArgs: TIdCmdArgs);
begin
  ListByFlags(AArgs, CMD_FL_RENDERER);
end;

procedure TCmdStandardCommands.ListSoundCommands(const AArgs: TIdCmdArgs);
begin
  ListByFlags(AArgs, CMD_FL_SOUND);
end;

procedure TCmdStandardCommands.ListGameCommands(const AArgs: TIdCmdArgs);
begin
  ListByFlags(AArgs, CMD_FL_GAME);
end;

procedure TCmdStandardCommands.ListToolCommands(const AArgs: TIdCmdArgs);
begin
  ListByFlags(AArgs, CMD_FL_TOOL);
end;

procedure TCmdStandardCommands.Exec(const AArgs: TIdCmdArgs);
var
  LFileName: TIdStr;
  LData: TIdLibFileData;
  LText: AnsiString;
begin
  if AArgs.Argc <> 2 then
  begin
    Print('exec <filename> : execute a script file'#10);
    Exit;
  end;

  LFileName := TIdStr.Create(AArgs.Argv(1));
  LFileName.DefaultFileExtension('.cfg');
  if not (Assigned(FFileSystem) and FFileSystem.TryReadFile(LFileName, False, LData)) then
  begin
    Print('couldn''t exec ' + string(AArgs.Argv(1)) + #10);
    Exit;
  end;
  Print('execing ' + string(AArgs.Argv(1)) + #10);

  SetString(LText, PAnsiChar(LData.Data), Length(LData.Data));
  FBuffer.BufferCommandText(ceInsert, LText);
end;

procedure TCmdStandardCommands.Vstr(const AArgs: TIdCmdArgs);
var
  LValue: AnsiString;
begin
  if AArgs.Argc <> 2 then
  begin
    Print('vstr <variablename> : execute a variable command'#10);
    Exit;
  end;

  if Assigned(FCVars) then
    LValue := FCVars.GetCVarString(AArgs.Argv(1))
  else
    LValue := '';
  FBuffer.BufferCommandText(ceAppend, LValue + #10);
end;

procedure TCmdStandardCommands.Echo(const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
begin
  for LIndex := 1 to AArgs.Argc - 1 do
    Print(string(AArgs.Argv(LIndex)) + ' ');
  Print(#10);
end;

procedure TCmdStandardCommands.Parse(const AArgs: TIdCmdArgs);
var
  LIndex: Integer;
begin
  for LIndex := 0 to AArgs.Argc - 1 do
    Print(IntToStr(LIndex) + ': ' + string(AArgs.Argv(LIndex)) + #10);
end;

procedure TCmdStandardCommands.Wait(const AArgs: TIdCmdArgs);
begin
  if AArgs.Argc = 2 then
    FBuffer.SetWait(TIdCNumbers.Atoi(AArgs.Argv(1)))
  else
    FBuffer.SetWait(1);
end;

end.
