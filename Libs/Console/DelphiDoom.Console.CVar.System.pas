{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvar system                          }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.cpp              }
{  (idCVarSystemLocal, without its commands: see CVar.Commands).               }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.System;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Text.CmdArgs,
  DelphiDoom.Scanner.IdDict, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CmdSystem.Intf,
  DelphiDoom.Console.CmdSystem.Completions, DelphiDoom.Console.CVar.Types, DelphiDoom.Console.CVar.Context,
  DelphiDoom.Console.CVar.Variable, DelphiDoom.Console.CVar.Intf;

type
  /// <summary>
  ///   idCVarSystemLocal as an object: the variables (in the order they were made, found by name
  ///   without regard to case), the modified flags, and the line command. It is also the
  ///   reader of values that the command system and the lexer use ("$name"). Use it through the
  ///   interfaces (it counts references).
  /// </summary>
  TCVarSystem = class(TInterfacedObject, ICVarSystem, ICVarReader, IIdLibCVars, ICVarCommand)
  strict private
    FLog: IIdLibLog;
    FContext: TCVarContext;
    FInitialized: Boolean;
    FVariables: TObjectList<TCVar>;
    FIndex: TDictionary<AnsiString, TCVar>;
    FBooleanCompletion: TCmdCompletions;
    FMoveToDict: TIdDict;
    function Key(const AName: AnsiString): AnsiString;
    function FindInternal(const AName: AnsiString): TCVar;
    procedure SetInternal(const AName, AValue: AnsiString; const AFlags: Integer);
    procedure AddVariable(const AVariable: TCVar);
    function LookupBool(const AName: AnsiString): Boolean;
  public
    /// <summary>The log and the session are optional (nil: silent, single player)</summary>
    constructor Create(const ALog: IIdLibLog = nil; const ASession: IConsoleSession = nil);
    destructor Destroy; override;

    // ICVarSystem
    procedure Init;
    procedure Shutdown;
    function IsInitialized: Boolean;
    function Register(const ADefinition: TCVarDefinition): TCVar;
    function Find(const AName: AnsiString): TCVar;
    procedure SetCVarString(const AName, AValue: AnsiString; const AFlags: Integer = 0);
    procedure SetCVarBool(const AName: AnsiString; const AValue: Boolean; const AFlags: Integer = 0);
    procedure SetCVarInteger(const AName: AnsiString; const AValue: Integer; const AFlags: Integer = 0);
    procedure SetCVarFloat(const AName: AnsiString; const AValue: Single; const AFlags: Integer = 0);
    procedure CommandCompletion(const ACallback: TCmdCompletionCallback);
    procedure ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
    procedure SetModifiedFlags(const AFlags: Integer);
    function GetModifiedFlags: Integer;
    procedure ClearModifiedFlags(const AFlags: Integer);
    procedure ResetFlaggedVariables(const AFlags: Integer);
    procedure RemoveFlaggedAutoCompletion(const AFlags: Integer);
    function WriteFlaggedVariables(const AFlags: Integer; const ASetCommand: AnsiString): AnsiString;
    function MoveCVarsToDict(const AFlags: Integer): TIdDict;
    procedure SetCVarsFromDict(const ADict: TIdDict);
    function Count: Integer;
    function Item(const AIndex: Integer): TCVar;
    procedure Restart;

    // ICVarReader (and IIdLibCVars)
    function GetCVarString(const AName: AnsiString): AnsiString;
    function GetCVarBool(const AName: AnsiString): Boolean;
    function GetCVarInteger(const AName: AnsiString): Integer;
    function GetCVarFloat(const AName: AnsiString): Single;

    // ICVarCommand
    function Command(const AArgs: TIdCmdArgs): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

{ TCVarSystem }

constructor TCVarSystem.Create(const ALog: IIdLibLog; const ASession: IConsoleSession);
begin
  inherited Create;
  FLog := ALog;
  FContext := TCVarContext.Create(ALog, ASession);
  FContext.BoolLookup := LookupBool;
  FVariables := TObjectList<TCVar>.Create(True);
  FIndex := TDictionary<AnsiString, TCVar>.Create;
  FBooleanCompletion := TCmdCompletions.Create;
  FMoveToDict := TIdDict.Create(ALog);
end;

destructor TCVarSystem.Destroy;
begin
  FMoveToDict.Free;
  FBooleanCompletion.Free;
  FIndex.Free;
  FVariables.Free;
  FContext.Free;
  inherited Destroy;
end;

function TCVarSystem.Key(const AName: AnsiString): AnsiString;
begin
  Result := TIdStrings.ToLower(AName);
end;

function TCVarSystem.FindInternal(const AName: AnsiString): TCVar;
begin
  if not FIndex.TryGetValue(Key(AName), Result) then
    Result := nil;
end;

procedure TCVarSystem.AddVariable(const AVariable: TCVar);
begin
  FVariables.Add(AVariable);
  FIndex.AddOrSetValue(Key(AVariable.Name), AVariable);
end;

function TCVarSystem.LookupBool(const AName: AnsiString): Boolean;
begin
  Result := GetCVarBool(AName);
end;

procedure TCVarSystem.SetInternal(const AName, AValue: AnsiString; const AFlags: Integer);
var
  LVariable: TCVar;
begin
  LVariable := FindInternal(AName);
  if Assigned(LVariable) then
  begin
    LVariable.SetString(AValue);
    LVariable.AddFlags(AFlags and not CVAR_STATIC);
    LVariable.UpdateCheat;
  end
  else
    AddVariable(TCVar.Create(FContext, AName, AValue, AFlags));
end;

procedure TCVarSystem.Init;
begin
  FContext.ModifiedFlags := 0;
  FInitialized := True;
end;

procedure TCVarSystem.Shutdown;
begin
  FIndex.Clear;
  FVariables.Clear;
  FMoveToDict.Clear;
  FInitialized := False;
end;

function TCVarSystem.IsInitialized: Boolean;
begin
  Result := FInitialized;
end;

function TCVarSystem.Register(const ADefinition: TCVarDefinition): TCVar;
var
  LDefinition: TCVarDefinition;
begin
  LDefinition := ADefinition;
  // idCVar( ... ): a boolean variable without completion gets the boolean one
  if not Assigned(LDefinition.ValueCompletion) and ((LDefinition.Flags and CVAR_BOOL) <> 0) then
    LDefinition.ValueCompletion := FBooleanCompletion.CompleteBoolean;
  Result := FindInternal(LDefinition.Name);
  if Assigned(Result) then
    Result.Update(LDefinition)
  else
  begin
    Result := TCVar.Create(FContext, LDefinition);
    AddVariable(Result);
  end;
end;

function TCVarSystem.Find(const AName: AnsiString): TCVar;
begin
  Result := FindInternal(AName);
end;

procedure TCVarSystem.SetCVarString(const AName, AValue: AnsiString; const AFlags: Integer);
begin
  SetInternal(AName, AValue, AFlags);
end;

procedure TCVarSystem.SetCVarBool(const AName: AnsiString; const AValue: Boolean; const AFlags: Integer);
begin
  if AValue then
    SetInternal(AName, '1', AFlags)
  else
    SetInternal(AName, '0', AFlags);
end;

procedure TCVarSystem.SetCVarInteger(const AName: AnsiString; const AValue: Integer; const AFlags: Integer);
begin
  SetInternal(AName, AnsiString(IntToStr(AValue)), AFlags);
end;

procedure TCVarSystem.SetCVarFloat(const AName: AnsiString; const AValue: Single; const AFlags: Integer);
begin
  SetInternal(AName, TIdStrings.FloatToText(AValue), AFlags);
end;

function TCVarSystem.GetCVarString(const AName: AnsiString): AnsiString;
var
  LVariable: TCVar;
begin
  LVariable := FindInternal(AName);
  if Assigned(LVariable) then
    Result := LVariable.GetString
  else
    Result := '';
end;

function TCVarSystem.GetCVarBool(const AName: AnsiString): Boolean;
var
  LVariable: TCVar;
begin
  LVariable := FindInternal(AName);
  Result := Assigned(LVariable) and LVariable.GetBool;
end;

function TCVarSystem.GetCVarInteger(const AName: AnsiString): Integer;
var
  LVariable: TCVar;
begin
  LVariable := FindInternal(AName);
  if Assigned(LVariable) then
    Result := LVariable.GetInteger
  else
    Result := 0;
end;

function TCVarSystem.GetCVarFloat(const AName: AnsiString): Single;
var
  LVariable: TCVar;
begin
  LVariable := FindInternal(AName);
  if Assigned(LVariable) then
    Result := LVariable.GetFloat
  else
    Result := 0.0;
end;

function TCVarSystem.Command(const AArgs: TIdCmdArgs): Boolean;
var
  LVariable: TCVar;
begin
  LVariable := FindInternal(AArgs.Argv(0));
  if not Assigned(LVariable) then
    Exit(False);

  if AArgs.Argc = 1 then
  begin
    // print the variable
    FContext.Print('"' + string(LVariable.Name) + '" is:"' + string(LVariable.GetString) + '"^7 default:"' +
      string(LVariable.ResetString) + '"'#10);
    if Length(LVariable.Description) > 0 then
      FContext.Print('^7' + string(LVariable.Description) + #10);
  end
  else
    // set the value
    LVariable.SetValue(AArgs.Args, False, False);
  Result := True;
end;

procedure TCVarSystem.CommandCompletion(const ACallback: TCmdCompletionCallback);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FVariables.Count - 1 do
    ACallback(FVariables[LIndex].Name);
end;

procedure TCVarSystem.ArgCompletion(const ACommandString: AnsiString; const ACallback: TCmdCompletionCallback);
var
  LArgs: TIdCmdArgs;
  LIndex: Integer;
begin
  LArgs := TIdCmdArgs.Create(Self);
  try
    LArgs.TokenizeString(ACommandString, False);
    for LIndex := 0 to FVariables.Count - 1 do
    begin
      if not Assigned(FVariables[LIndex].ValueCompletion) then
        Continue;
      if TIdStrings.Icmp(LArgs.Argv(0), FVariables[LIndex].Name) = 0 then
      begin
        FVariables[LIndex].ValueCompletion(LArgs, ACallback);
        Break;
      end;
    end;
  finally
    LArgs.Free;
  end;
end;

procedure TCVarSystem.SetModifiedFlags(const AFlags: Integer);
begin
  FContext.SetModifiedFlags(AFlags);
end;

function TCVarSystem.GetModifiedFlags: Integer;
begin
  Result := FContext.ModifiedFlags;
end;

procedure TCVarSystem.ClearModifiedFlags(const AFlags: Integer);
begin
  FContext.ModifiedFlags := FContext.ModifiedFlags and not AFlags;
end;

procedure TCVarSystem.ResetFlaggedVariables(const AFlags: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FVariables.Count - 1 do
    if (FVariables[LIndex].Flags and AFlags) <> 0 then
      FVariables[LIndex].SetToResetValue(True, True);
end;

procedure TCVarSystem.RemoveFlaggedAutoCompletion(const AFlags: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FVariables.Count - 1 do
    if (FVariables[LIndex].Flags and AFlags) <> 0 then
      FVariables[LIndex].ClearValueCompletion;
end;

function TCVarSystem.WriteFlaggedVariables(const AFlags: Integer; const ASetCommand: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FVariables.Count - 1 do
    if (FVariables[LIndex].Flags and AFlags) <> 0 then
      Result := Result + ASetCommand + ' ' + FVariables[LIndex].Name + ' "' + FVariables[LIndex].GetString + '"'#10;
end;

function TCVarSystem.MoveCVarsToDict(const AFlags: Integer): TIdDict;
var
  LIndex: Integer;
begin
  FMoveToDict.Clear;
  for LIndex := 0 to FVariables.Count - 1 do
    if (FVariables[LIndex].Flags and AFlags) <> 0 then
      FMoveToDict.SetValue(FVariables[LIndex].Name, FVariables[LIndex].GetString);
  Result := FMoveToDict;
end;

procedure TCVarSystem.SetCVarsFromDict(const ADict: TIdDict);
var
  LIndex: Integer;
  LKeyValue: TIdKeyValue;
  LVariable: TCVar;
begin
  for LIndex := 0 to ADict.GetNumKeyVals - 1 do
    if ADict.TryGetKeyVal(LIndex, LKeyValue) then
    begin
      LVariable := FindInternal(LKeyValue.Key);
      if Assigned(LVariable) then
        LVariable.ServerSetString(LKeyValue.Value);
    end;
end;

function TCVarSystem.Count: Integer;
begin
  Result := FVariables.Count;
end;

function TCVarSystem.Item(const AIndex: Integer): TCVar;
begin
  Result := FVariables[AIndex];
end;

procedure TCVarSystem.Restart;
var
  LIndex: Integer;
  LVariable: TCVar;
begin
  LIndex := 0;
  while LIndex < FVariables.Count do
  begin
    LVariable := FVariables[LIndex];

    // don't mess with rom values
    if (LVariable.Flags and (CVAR_ROM or CVAR_INIT)) <> 0 then
    begin
      Inc(LIndex);
      Continue;
    end;

    // throw out any variables the user created
    if (LVariable.Flags and CVAR_STATIC) = 0 then
    begin
      FIndex.Remove(Key(LVariable.Name));
      FVariables.Delete(LIndex);
      Continue;
    end;

    LVariable.Reset;
    Inc(LIndex);
  end;
end;

end.
