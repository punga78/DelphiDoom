{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, the list of commands       }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cmd.c           }
{  (Cmd_AddCommand, Cmd_RemoveCommand, Cmd_CommandCompletion,                  }
{  Cmd_ExecuteString).                                                         }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.CommandSystem;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   The commands and the way a line is run: the tokens, then the command with that name (names ignore
  ///   case; the command that runs moves to the head of the list), then the variables, then what the game
  ///   does with the rest. Adding a name that exists keeps the first (and says so unless the new function is
  ///   nil, which is a command only the game handles); names are compared exactly when adding and removing
  /// </summary>
  TQ3CommandSystem = class(TInterfacedObject, IQ3CommandRegistry)
  strict private
    type
      TEntry = class
        Name: AnsiString;
        Func: TQ3CommandFunction;
      end;
    var
      FArguments: IQ3CommandArguments;
      FLog: IQ3ConsoleLog;
      FUnhandled: IQ3UnhandledCommands;
      FCVarHandler: IQ3CVarCommandHandler;
      FEntries: TObjectList<TEntry>;
    class function SameName(const AFirst, ASecond: AnsiString): Boolean; static;
    procedure Print(const AText: string);
  public
    /// <summary>The arguments are the ones the commands read; log and unhandled commands are optional</summary>
    constructor Create(const AArguments: IQ3CommandArguments; const ALog: IQ3ConsoleLog = nil;
      const AUnhandled: IQ3UnhandledCommands = nil);
    destructor Destroy; override;
    procedure AddCommand(const AName: AnsiString; const AFunction: TQ3CommandFunction);
    procedure RemoveCommand(const AName: AnsiString);
    procedure ExecuteString(const AText: AnsiString);
    function CommandNames: TArray<AnsiString>;
    /// <summary>
    ///   Who handles a line that is not a command (Cvar_Command). Set once the variable commands exist;
    ///   it is not counted, so clear it before the handler goes away
    /// </summary>
    property CVarHandler: IQ3CVarCommandHandler read FCVarHandler write FCVarHandler;
  end;

implementation

{ TQ3CommandSystem }

constructor TQ3CommandSystem.Create(const AArguments: IQ3CommandArguments; const ALog: IQ3ConsoleLog;
  const AUnhandled: IQ3UnhandledCommands);
begin
  inherited Create;
  if not Assigned(AArguments) then
    raise EArgumentNilException.Create('AArguments');
  FArguments := AArguments;
  FLog := ALog;
  FUnhandled := AUnhandled;
  FEntries := TObjectList<TEntry>.Create(True);
end;

destructor TQ3CommandSystem.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

class function TQ3CommandSystem.SameName(const AFirst, ASecond: AnsiString): Boolean;
var
  LIndex: Integer;
  LFirst: AnsiChar;
  LSecond: AnsiChar;
begin
  Result := Length(AFirst) = Length(ASecond);
  if not Result then
    Exit;
  for LIndex := 1 to Length(AFirst) do
  begin
    LFirst := AFirst[LIndex];
    LSecond := ASecond[LIndex];
    if LFirst in ['a'..'z'] then
      LFirst := AnsiChar(Ord(LFirst) - 32);
    if LSecond in ['a'..'z'] then
      LSecond := AnsiChar(Ord(LSecond) - 32);
    if LFirst <> LSecond then
      Exit(False);
  end;
end;

procedure TQ3CommandSystem.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

procedure TQ3CommandSystem.AddCommand(const AName: AnsiString; const AFunction: TQ3CommandFunction);
var
  LIndex: Integer;
  LEntry: TEntry;
begin
  for LIndex := 0 to FEntries.Count - 1 do
    if FEntries[LIndex].Name = AName then
    begin
      // completion-only commands may be doubled without a word
      if Assigned(AFunction) then
        Print('Cmd_AddCommand: ' + string(AName) + ' already defined'#10);
      Exit;
    end;
  LEntry := TEntry.Create;
  LEntry.Name := AName;
  LEntry.Func := AFunction;
  FEntries.Insert(0, LEntry);
end;

procedure TQ3CommandSystem.RemoveCommand(const AName: AnsiString);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FEntries.Count - 1 do
    if FEntries[LIndex].Name = AName then
    begin
      FEntries.Delete(LIndex);
      Exit;
    end;
end;

function TQ3CommandSystem.CommandNames: TArray<AnsiString>;
var
  LIndex: Integer;
begin
  SetLength(Result, FEntries.Count);
  for LIndex := 0 to FEntries.Count - 1 do
    Result[LIndex] := FEntries[LIndex].Name;
end;

procedure TQ3CommandSystem.ExecuteString(const AText: AnsiString);
var
  LIndex: Integer;
  LEntry: TEntry;
  LFunction: TQ3CommandFunction;
begin
  FArguments.Tokenize(AText);
  if FArguments.Count = 0 then
    Exit;
  for LIndex := 0 to FEntries.Count - 1 do
    if SameName(FArguments.Argv(0), FEntries[LIndex].Name) then
    begin
      // the command moves to the head of the list so that it is found sooner next time
      LEntry := FEntries[LIndex];
      FEntries.Extract(LEntry);
      FEntries.Insert(0, LEntry);
      LFunction := LEntry.Func;
      if not Assigned(LFunction) then
        Break;
      LFunction;
      Exit;
    end;
  if Assigned(FCVarHandler) and FCVarHandler.Command then
    Exit;
  if Assigned(FUnhandled) then
    FUnhandled.Execute(AText);
end;

end.
