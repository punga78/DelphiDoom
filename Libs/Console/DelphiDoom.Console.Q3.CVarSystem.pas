{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - Quake III profile, the cvar system            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cvar.c          }
{  (everything but the console commands and Cvar_Command).                     }
{  Copyright (C) 1999-2005 id Software, Inc.                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.Q3.CVarSystem;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Console.Q3.Types,
  DelphiDoom.Console.Q3.CVar, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>
  ///   The console variables of Quake III. A name is a key without case; a name with a backslash, a double
  ///   quote or a semicolon becomes <c>BADNAME</c>. A variable that already exists keeps its value on
  ///   <c>Get</c> (the flags are or'ed in), a latched value takes effect on the next <c>Get</c>, a forced
  ///   <c>Set</c> ignores ROM, INIT, LATCH and CHEAT. At most 1024 variables can be created; a variable
  ///   thrown out by <c>Restart</c> keeps its slot. Differences from the original: the slot of a removed
  ///   variable is marked <c>Removed</c> (the original zeroes only the first pointer of the structure and
  ///   leaves freed strings), a cheat variable is protected (cheats off) until <c>Init</c> has created sv_cheats (the
  ///   original crashes) and <c>Cvar_Get</c>'s NULL-parameter error cannot happen
  /// </summary>
  TQ3CVarSystem = class(TInterfacedObject, IQ3CVarReader, IQ3CVarSystem)
  strict private
    FLog: IQ3ConsoleLog;
    FInfoWriter: IQ3InfoStringWriter;
    FVars: TList<TQ3CVar>;
    FIndexes: TObjectList<TQ3CVar>;
    FByName: TDictionary<AnsiString, TQ3CVar>;
    FModifiedFlags: Integer;
    FCheats: TQ3CVar;
    class function KeyOf(const AName: AnsiString): AnsiString; static;
    class function IsValidName(const AName: AnsiString): Boolean; static;
    class function TruncateText(const AText: AnsiString; ASize: Integer): AnsiString; static;
    procedure Print(const AText: string);
    procedure DevPrint(const AText: string);
    procedure ApplyValue(AVar: TQ3CVar; const AValue: AnsiString);
    function SetInternal(const AName, AValue: AnsiString; AHasValue, AForce: Boolean): TQ3CVar;
    function BuildInfo(ABit: Integer; ABig: Boolean): AnsiString;
  public
    /// <summary>The log and the info string writer are optional</summary>
    constructor Create(const ALog: IQ3ConsoleLog = nil; const AInfoWriter: IQ3InfoStringWriter = nil);
    destructor Destroy; override;
    function GetModifiedFlags: Integer;
    procedure SetModifiedFlags(AValue: Integer);
    procedure Init;
    function Get(const AName, AValue: AnsiString; AFlags: Integer): TQ3CVar;
    function Find(const AName: AnsiString): TQ3CVar;
    function Set2(const AName, AValue: AnsiString; AForce: Boolean): TQ3CVar;
    procedure SetValueText(const AName, AValue: AnsiString);
    procedure SetLatched(const AName, AValue: AnsiString);
    procedure SetNumber(const AName: AnsiString; AValue: Single);
    procedure Reset(const AName: AnsiString);
    procedure SetCheatState;
    procedure Restart;
    function VariableValue(const AName: AnsiString): Single;
    function VariableIntegerValue(const AName: AnsiString): Integer;
    function VariableString(const AName: AnsiString): AnsiString;
    function VariableStringBuffer(const AName: AnsiString; ASize: Integer): AnsiString;
    function WriteVariables: AnsiString;
    function InfoString(ABit: Integer): AnsiString;
    function InfoStringBig(ABit: Integer): AnsiString;
    function InfoStringBuffer(ABit: Integer; ASize: Integer): AnsiString;
    procedure Register(var AVmCvar: TQ3VmCvar; const AName, ADefault: AnsiString; AFlags: Integer);
    procedure Update(var AVmCvar: TQ3VmCvar);
    function Variables: TArray<TQ3CVar>;
    function IndexCount: Integer;
  end;

implementation

{ TQ3CVarSystem }

constructor TQ3CVarSystem.Create(const ALog: IQ3ConsoleLog; const AInfoWriter: IQ3InfoStringWriter);
begin
  inherited Create;
  FLog := ALog;
  FInfoWriter := AInfoWriter;
  FVars := TList<TQ3CVar>.Create;
  FIndexes := TObjectList<TQ3CVar>.Create(True);
  FByName := TDictionary<AnsiString, TQ3CVar>.Create;
end;

destructor TQ3CVarSystem.Destroy;
begin
  FByName.Free;
  FIndexes.Free;
  FVars.Free;
  inherited Destroy;
end;

class function TQ3CVarSystem.KeyOf(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  // Q_stricmp: ASCII letters only
  Result := AName;
  for LIndex := 1 to Length(Result) do
    if Result[LIndex] in ['a'..'z'] then
      Result[LIndex] := AnsiChar(Ord(Result[LIndex]) - 32);
end;

class function TQ3CVarSystem.IsValidName(const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 1 to Length(AName) do
    if AName[LIndex] in ['\', '"', ';'] then
      Exit(False);
end;

class function TQ3CVarSystem.TruncateText(const AText: AnsiString; ASize: Integer): AnsiString;
begin
  // Q_strncpyz
  Result := Copy(AText, 1, ASize - 1);
end;

procedure TQ3CVarSystem.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Print(AText);
end;

procedure TQ3CVarSystem.DevPrint(const AText: string);
begin
  if Assigned(FLog) then
    FLog.DevPrint(AText);
end;

function TQ3CVarSystem.GetModifiedFlags: Integer;
begin
  Result := FModifiedFlags;
end;

procedure TQ3CVarSystem.SetModifiedFlags(AValue: Integer);
begin
  FModifiedFlags := AValue;
end;

procedure TQ3CVarSystem.Init;
begin
  FCheats := Get('sv_cheats', '1', Q3_CVAR_ROM or Q3_CVAR_SYSTEMINFO);
end;

procedure TQ3CVarSystem.ApplyValue(AVar: TQ3CVar; const AValue: AnsiString);
begin
  AVar.StringValue := AValue;
  AVar.Value := TIdCNumbers.Atof(AValue);
  AVar.IntegerValue := TIdCNumbers.Atoi(AValue);
end;

function TQ3CVarSystem.Find(const AName: AnsiString): TQ3CVar;
begin
  if not FByName.TryGetValue(KeyOf(AName), Result) then
    Result := nil;
end;

function TQ3CVarSystem.Get(const AName, AValue: AnsiString; AFlags: Integer): TQ3CVar;
var
  LName: AnsiString;
  LLatched: AnsiString;
begin
  LName := AName;
  if not IsValidName(LName) then
  begin
    Print('invalid cvar name string: ' + string(LName) + #10);
    LName := 'BADNAME';
  end;
  Result := Find(LName);
  if Assigned(Result) then
  begin
    // the code now names a variable that the user already set: its value becomes the reset value
    if ((Result.Flags and Q3_CVAR_USER_CREATED) <> 0) and ((AFlags and Q3_CVAR_USER_CREATED) = 0)
      and (AValue <> '') then
    begin
      Result.Flags := Result.Flags and not Q3_CVAR_USER_CREATED;
      Result.ResetString := AValue;
      FModifiedFlags := FModifiedFlags or AFlags;
    end;
    Result.Flags := Result.Flags or AFlags;
    if Result.ResetString = '' then
      Result.ResetString := AValue
    else if (AValue <> '') and (Result.ResetString <> AValue) then
      DevPrint(Format('Warning: cvar "%s" given initial values: "%s" and "%s"'#10,
        [string(LName), string(Result.ResetString), string(AValue)]));
    if Result.HasLatched then
    begin
      LLatched := Result.LatchedString;
      Result.HasLatched := False;
      Set2(LName, LLatched, True);
    end;
    Exit;
  end;
  if FIndexes.Count >= Q3_MAX_CVARS then
    raise EQ3ConsoleException.Create(SQ3ConsoleMaxCVars);
  Result := TQ3CVar.Create;
  FIndexes.Add(Result);
  Result.Name := LName;
  Result.Modified := True;
  Result.ModificationCount := 1;
  ApplyValue(Result, AValue);
  Result.ResetString := AValue;
  FVars.Insert(0, Result);
  Result.Flags := AFlags;
  FByName.Add(KeyOf(LName), Result);
end;

function TQ3CVarSystem.SetInternal(const AName, AValue: AnsiString; AHasValue, AForce: Boolean): TQ3CVar;
var
  LName: AnsiString;
  LValue: AnsiString;
begin
  LName := AName;
  LValue := AValue;
  if AHasValue then
    DevPrint('Cvar_Set2: ' + string(LName) + ' ' + string(LValue) + #10)
  else
    DevPrint('Cvar_Set2: ' + string(LName) + ' (null)'#10);
  if not IsValidName(LName) then
  begin
    Print('invalid cvar name string: ' + string(LName) + #10);
    LName := 'BADNAME';
  end;
  Result := Find(LName);
  if not Assigned(Result) then
  begin
    if not AHasValue then
      Exit;
    if not AForce then
      Result := Get(LName, LValue, Q3_CVAR_USER_CREATED)
    else
      Result := Get(LName, LValue, 0);
    Exit;
  end;
  if not AHasValue then
    LValue := Result.ResetString;
  if LValue = Result.StringValue then
    Exit;
  // the kinds of variables that were modified (userinfo, archive, serverinfo, systeminfo)
  FModifiedFlags := FModifiedFlags or Result.Flags;
  if not AForce then
  begin
    if (Result.Flags and Q3_CVAR_ROM) <> 0 then
    begin
      Print(string(LName) + ' is read only.'#10);
      Exit;
    end;
    if (Result.Flags and Q3_CVAR_INIT) <> 0 then
    begin
      Print(string(LName) + ' is write protected.'#10);
      Exit;
    end;
    if (Result.Flags and Q3_CVAR_LATCH) <> 0 then
    begin
      if Result.HasLatched then
      begin
        if LValue = Result.LatchedString then
          Exit;
      end
      else if LValue = Result.StringValue then
        Exit;
      Print(string(LName) + ' will be changed upon restarting.'#10);
      Result.LatchedString := LValue;
      Result.HasLatched := True;
      Result.Modified := True;
      Result.ModificationCount := Result.ModificationCount + 1;
      Exit;
    end;
    if ((Result.Flags and Q3_CVAR_CHEAT) <> 0) and ((not Assigned(FCheats)) or (FCheats.IntegerValue = 0)) then
    begin
      Print(string(LName) + ' is cheat protected.'#10);
      Exit;
    end;
  end
  else
    Result.HasLatched := False;
  if LValue = Result.StringValue then
    Exit;
  Result.Modified := True;
  Result.ModificationCount := Result.ModificationCount + 1;
  ApplyValue(Result, LValue);
end;

function TQ3CVarSystem.Set2(const AName, AValue: AnsiString; AForce: Boolean): TQ3CVar;
begin
  Result := SetInternal(AName, AValue, True, AForce);
end;

procedure TQ3CVarSystem.SetValueText(const AName, AValue: AnsiString);
begin
  SetInternal(AName, AValue, True, True);
end;

procedure TQ3CVarSystem.SetLatched(const AName, AValue: AnsiString);
begin
  SetInternal(AName, AValue, True, False);
end;

procedure TQ3CVarSystem.SetNumber(const AName: AnsiString; AValue: Single);
var
  LText: AnsiString;
begin
  if (Abs(AValue) < 2147483648.0) and (AValue = Trunc(AValue)) then
    LText := AnsiString(IntToStr(Trunc(AValue)))
  else
    LText := AnsiString(Format('%.6f', [Double(AValue)], TFormatSettings.Invariant));
  SetValueText(AName, LText);
end;

procedure TQ3CVarSystem.Reset(const AName: AnsiString);
begin
  SetInternal(AName, '', False, False);
end;

procedure TQ3CVarSystem.SetCheatState;
var
  LVar: TQ3CVar;
begin
  for LVar in Variables do
    if (LVar.Flags and Q3_CVAR_CHEAT) <> 0 then
    begin
      // a latched cheat variable would escape the reset below with its latched string
      LVar.HasLatched := False;
      if LVar.ResetString <> LVar.StringValue then
        SetValueText(LVar.Name, LVar.ResetString);
    end;
end;

procedure TQ3CVarSystem.Restart;
var
  LVar: TQ3CVar;
begin
  for LVar in Variables do
  begin
    // read only and init values hold communication between modules
    if (LVar.Flags and (Q3_CVAR_ROM or Q3_CVAR_INIT or Q3_CVAR_NORESTART)) <> 0 then
      Continue;
    if (LVar.Flags and Q3_CVAR_USER_CREATED) <> 0 then
    begin
      FVars.Remove(LVar);
      FByName.Remove(KeyOf(LVar.Name));
      LVar.Removed := True;
      LVar.Name := '';
      LVar.StringValue := '';
      LVar.LatchedString := '';
      LVar.HasLatched := False;
      LVar.ResetString := '';
      Continue;
    end;
    SetValueText(LVar.Name, LVar.ResetString);
  end;
end;

function TQ3CVarSystem.VariableValue(const AName: AnsiString): Single;
var
  LVar: TQ3CVar;
begin
  LVar := Find(AName);
  if Assigned(LVar) then
    Result := LVar.Value
  else
    Result := 0;
end;

function TQ3CVarSystem.VariableIntegerValue(const AName: AnsiString): Integer;
var
  LVar: TQ3CVar;
begin
  LVar := Find(AName);
  if Assigned(LVar) then
    Result := LVar.IntegerValue
  else
    Result := 0;
end;

function TQ3CVarSystem.VariableString(const AName: AnsiString): AnsiString;
var
  LVar: TQ3CVar;
begin
  LVar := Find(AName);
  if Assigned(LVar) then
    Result := LVar.StringValue
  else
    Result := '';
end;

function TQ3CVarSystem.VariableStringBuffer(const AName: AnsiString; ASize: Integer): AnsiString;
begin
  Result := TruncateText(VariableString(AName), ASize);
end;

function TQ3CVarSystem.WriteVariables: AnsiString;
const
  LBufferSize = 1024;
var
  LVar: TQ3CVar;
  LValue: AnsiString;
  LLine: AnsiString;
begin
  Result := '';
  for LVar in FVars do
  begin
    if KeyOf(LVar.Name) = 'CL_CDKEY' then
      Continue;
    if (LVar.Flags and Q3_CVAR_ARCHIVE) = 0 then
      Continue;
    // the latched value is written, even if it has not taken effect yet
    if LVar.HasLatched then
      LValue := LVar.LatchedString
    else
      LValue := LVar.StringValue;
    LLine := 'seta ' + LVar.Name + ' "' + LValue + '"'#10;
    if Length(LLine) >= LBufferSize then
    begin
      Print(Format('Com_sprintf: overflow of %d in %d'#10, [Length(LLine), LBufferSize]));
      LLine := TruncateText(LLine, LBufferSize);
    end;
    Result := Result + LLine;
  end;
end;

function TQ3CVarSystem.BuildInfo(ABit: Integer; ABig: Boolean): AnsiString;
var
  LVar: TQ3CVar;
begin
  if not Assigned(FInfoWriter) then
    raise EQ3ConsoleException.Create(SQ3ConsoleNoInfoWriter);
  Result := '';
  for LVar in FVars do
    if (LVar.Flags and ABit) <> 0 then
      FInfoWriter.SetValueForKey(Result, LVar.Name, LVar.StringValue, ABig);
end;

function TQ3CVarSystem.InfoString(ABit: Integer): AnsiString;
begin
  Result := BuildInfo(ABit, False);
end;

function TQ3CVarSystem.InfoStringBig(ABit: Integer): AnsiString;
begin
  Result := BuildInfo(ABit, True);
end;

function TQ3CVarSystem.InfoStringBuffer(ABit: Integer; ASize: Integer): AnsiString;
begin
  Result := TruncateText(InfoString(ABit), ASize);
end;

procedure TQ3CVarSystem.Register(var AVmCvar: TQ3VmCvar; const AName, ADefault: AnsiString; AFlags: Integer);
var
  LVar: TQ3CVar;
begin
  LVar := Get(AName, ADefault, AFlags);
  AVmCvar.Handle := FIndexes.IndexOf(LVar);
  AVmCvar.ModificationCount := -1;
  Update(AVmCvar);
end;

procedure TQ3CVarSystem.Update(var AVmCvar: TQ3VmCvar);
var
  LVar: TQ3CVar;
begin
  if (AVmCvar.Handle < 0) or (AVmCvar.Handle >= FIndexes.Count) then
    raise EQ3ConsoleException.Create(SQ3ConsoleBadHandle);
  LVar := FIndexes[AVmCvar.Handle];
  if LVar.ModificationCount = AVmCvar.ModificationCount then
    Exit;
  // the variable might have been cleared by a cvar_restart
  if LVar.Removed then
    Exit;
  AVmCvar.ModificationCount := LVar.ModificationCount;
  if Length(LVar.StringValue) + 1 > Q3_MAX_CVAR_VALUE_STRING then
    raise EQ3ConsoleException.CreateFmt(SQ3ConsoleValueTooLong, [string(LVar.StringValue), Length(LVar.StringValue)]);
  AVmCvar.StringValue := LVar.StringValue;
  AVmCvar.Value := LVar.Value;
  AVmCvar.IntegerValue := LVar.IntegerValue;
end;

function TQ3CVarSystem.Variables: TArray<TQ3CVar>;
begin
  Result := FVars.ToArray;
end;

function TQ3CVarSystem.IndexCount: Integer;
begin
  Result := FIndexes.Count;
end;

end.
