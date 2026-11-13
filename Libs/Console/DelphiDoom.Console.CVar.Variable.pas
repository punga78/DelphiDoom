{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvars, one variable                  }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.h,               }
{  CVarSystem.cpp (idCVar and idInternalCVar, joined: the declaration is a     }
{  TCVarDefinition, the variable the system holds is a TCVar).                 }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.Variable;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Console.CmdSystem.Types, DelphiDoom.Console.CVar.Types,
  DelphiDoom.Console.CVar.Context;

type
  /// <summary>
  ///   A console variable: a value kept as text with its integer and float readings, a type (the
  ///   flags CVAR_BOOL, CVAR_INTEGER, CVAR_FLOAT, else a string), an optional range or list of
  ///   valid strings, a reset value and the flags. Setting a value applies the rules of the
  ///   flags: read only, write protected (init), cheats and network sync in a multiplayer game,
  ///   the range, and the normalization of the text. The system owns the variables; a reference
  ///   is good until the system shuts down or "cvar_restart" removes a variable that the user
  ///   created.
  /// </summary>
  TCVar = class
  strict private
    FContext: TCVarContext;
    FName: AnsiString;
    FResetString: AnsiString;
    FValueString: AnsiString;
    FDescription: AnsiString;
    FFlags: Integer;
    FValueMin: Single;
    FValueMax: Single;
    FValueStrings: TArray<AnsiString>;
    FValueCompletion: TCmdArgCompletion;
    FIntegerValue: Integer;
    FFloatValue: Single;
    procedure UpdateValue;
    procedure DoSet(const ANewValue: AnsiString; const AForce, AFromServer: Boolean);
  public
    /// <summary>idInternalCVar( name, value, flags ): a variable made by "set", not declared</summary>
    constructor Create(const AContext: TCVarContext; const AName, AValue: AnsiString; const AFlags: Integer); overload;
    /// <summary>idInternalCVar( const idCVar * ): a variable made from a declaration</summary>
    constructor Create(const AContext: TCVarContext; const ADefinition: TCVarDefinition); overload;

    /// <summary>Merges a second declaration of the variable (idInternalCVar::Update)</summary>
    procedure Update(const ADefinition: TCVarDefinition);
    procedure UpdateCheat;
    /// <summary>
    ///   The value rules (idInternalCVar::Set). With AForce the read only and init protection is
    ///   ignored; AFromServer lets a multiplayer client change the variable
    /// </summary>
    procedure SetValue(const ANewValue: AnsiString; const AForce, AFromServer: Boolean);
    /// <summary>Set( NULL, ... ): sets the reset value</summary>
    procedure SetToResetValue(const AForce, AFromServer: Boolean);
    /// <summary>idInternalCVar::Reset: the reset value, without checks and without the modified flag</summary>
    procedure Reset;

    // idCVar::SetString and the others: forced, not from the server
    procedure SetString(const AValue: AnsiString);
    procedure SetBool(const AValue: Boolean);
    procedure SetInteger(const AValue: Integer);
    procedure SetFloat(const AValue: Single);
    /// <summary>InternalServerSetString: forced, from the server</summary>
    procedure ServerSetString(const AValue: AnsiString);

    function GetString: AnsiString;
    function GetBool: Boolean;
    function GetInteger: Integer;
    function GetFloat: Single;
    function IsModified: Boolean;
    procedure SetModified;
    procedure ClearModified;
    /// <summary>flags := flags or AFlags (the commands "sets", "setu", "sett" do it)</summary>
    procedure AddFlags(const AFlags: Integer);
    procedure ClearValueCompletion;

    property Name: AnsiString read FName;
    property Description: AnsiString read FDescription;
    property ResetString: AnsiString read FResetString;
    property Flags: Integer read FFlags;
    property ValueMin: Single read FValueMin;
    property ValueMax: Single read FValueMax;
    property ValueStrings: TArray<AnsiString> read FValueStrings;
    property ValueCompletion: TCmdArgCompletion read FValueCompletion;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Str, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers;

// (int) of a float: the value the processor gives when it does not fit is $80000000
function FloatToInteger(const AValue: Single): Integer;
begin
  if (AValue <> AValue) or (AValue >= 2147483648.0) or (AValue < -2147483648.0) then
    Result := Low(Integer)
  else
    Result := Trunc(AValue);
end;

function BooleanText(const AValue: Boolean): AnsiString;
begin
  if AValue then
    Result := '1'
  else
    Result := '0';
end;

{ TCVar }

constructor TCVar.Create(const AContext: TCVarContext; const AName, AValue: AnsiString; const AFlags: Integer);
begin
  inherited Create;
  FContext := AContext;
  FName := AName;
  FValueString := AValue;
  FResetString := AValue;
  FDescription := '';
  FFlags := (AFlags and not CVAR_STATIC) or CVAR_MODIFIED;
  FValueMin := 1;
  FValueMax := -1;
  UpdateValue;
  UpdateCheat;
end;

constructor TCVar.Create(const AContext: TCVarContext; const ADefinition: TCVarDefinition);
begin
  inherited Create;
  FContext := AContext;
  FName := ADefinition.Name;
  FValueString := ADefinition.Value;
  FResetString := ADefinition.Value;
  FDescription := ADefinition.Description;
  FFlags := ADefinition.Flags or CVAR_MODIFIED;
  FValueMin := ADefinition.ValueMin;
  FValueMax := ADefinition.ValueMax;
  FValueStrings := Copy(ADefinition.ValueStrings);
  FValueCompletion := ADefinition.ValueCompletion;
  UpdateValue;
  UpdateCheat;
end;

procedure TCVar.Update(const ADefinition: TCVarDefinition);
begin
  // if this is a statically declared variable
  if (ADefinition.Flags and CVAR_STATIC) <> 0 then
  begin
    if (FFlags and CVAR_STATIC) <> 0 then
    begin
      // the code has more than one static declaration of the same variable, make sure they have the same properties
      if TIdStrings.Icmp(FResetString, ADefinition.Value) <> 0 then
        FContext.Warning('CVar ''' + string(FName) + ''' declared multiple times with different initial value');
      if (FFlags and (CVAR_BOOL or CVAR_INTEGER or CVAR_FLOAT)) <>
        (ADefinition.Flags and (CVAR_BOOL or CVAR_INTEGER or CVAR_FLOAT)) then
        FContext.Warning('CVar ''' + string(FName) + ''' declared multiple times with different type');
      if (FValueMin <> ADefinition.ValueMin) or (FValueMax <> ADefinition.ValueMax) then
        FContext.Warning('CVar ''' + string(FName) + ''' declared multiple times with different minimum/maximum');
    end;

    // the code is now specifying a variable that the user already set a value for, take the new value as the reset value
    FResetString := ADefinition.Value;
    FDescription := ADefinition.Description;
    FValueMin := ADefinition.ValueMin;
    FValueMax := ADefinition.ValueMax;
    FValueStrings := Copy(ADefinition.ValueStrings);
    FValueCompletion := ADefinition.ValueCompletion;
    UpdateValue;
    FContext.SetModifiedFlags(ADefinition.Flags);
  end;

  FFlags := FFlags or ADefinition.Flags;

  UpdateCheat;

  // only allow one non-empty reset string without a warning
  if Length(FResetString) = 0 then
    FResetString := ADefinition.Value
  else if (Length(ADefinition.Value) > 0) and (TIdStrings.Cmp(FResetString, ADefinition.Value) <> 0) then
    FContext.Warning('cvar "' + string(FName) + '" given initial values: "' + string(FResetString) + '" and "' +
      string(ADefinition.Value) + '"'#10);
end;

procedure TCVar.UpdateValue;
var
  LClamped: Boolean;
  LIndex: Integer;
begin
  LClamped := False;

  if (FFlags and CVAR_BOOL) <> 0 then
  begin
    FIntegerValue := Ord(TIdCNumbers.Atoi(FValueString) <> 0);
    FFloatValue := FIntegerValue;
    if (TIdStrings.Icmp(FValueString, '0') <> 0) and (TIdStrings.Icmp(FValueString, '1') <> 0) then
      FValueString := BooleanText(FIntegerValue <> 0);
  end
  else if (FFlags and CVAR_INTEGER) <> 0 then
  begin
    FIntegerValue := TIdCNumbers.Atoi(FValueString);
    if FValueMin < FValueMax then
    begin
      if Single(FIntegerValue) < FValueMin then
      begin
        FIntegerValue := FloatToInteger(FValueMin);
        LClamped := True;
      end
      else if Single(FIntegerValue) > FValueMax then
      begin
        FIntegerValue := FloatToInteger(FValueMax);
        LClamped := True;
      end;
    end;
    // the original tests idStr::FindChar( value, '.' ) as a boolean: it is -1 (true) when there is
    // no dot, so the text of an integer variable is always rewritten, except for a dot at the start
    if LClamped or not TIdStrings.IsNumeric(FValueString) or (TIdStrings.FindChar(FValueString, '.') <> 0) then
      FValueString := AnsiString(IntToStr(FIntegerValue));
    FFloatValue := FIntegerValue;
  end
  else if (FFlags and CVAR_FLOAT) <> 0 then
  begin
    FFloatValue := TIdCNumbers.Atof(FValueString);
    if FValueMin < FValueMax then
    begin
      if FFloatValue < FValueMin then
      begin
        FFloatValue := FValueMin;
        LClamped := True;
      end
      else if FFloatValue > FValueMax then
      begin
        FFloatValue := FValueMax;
        LClamped := True;
      end;
    end;
    if LClamped or not TIdStrings.IsNumeric(FValueString) then
      FValueString := TIdStrings.FloatToText(FFloatValue);
    FIntegerValue := FloatToInteger(FFloatValue);
  end
  else
  begin
    if (Length(FValueStrings) > 0) then
    begin
      FIntegerValue := 0;
      for LIndex := 0 to High(FValueStrings) do
        if TIdStrings.Icmp(FValueString, FValueStrings[LIndex]) = 0 then
        begin
          FIntegerValue := LIndex;
          Break;
        end;
      FValueString := FValueStrings[FIntegerValue];
      FFloatValue := FIntegerValue;
    end
    else if Length(FValueString) < 32 then
    begin
      FFloatValue := TIdCNumbers.Atof(FValueString);
      FIntegerValue := FloatToInteger(FFloatValue);
    end
    else
    begin
      FFloatValue := 0.0;
      FIntegerValue := 0;
    end;
  end;
end;

procedure TCVar.UpdateCheat;
begin
  // all variables are considered cheats except for a few types
  if (FFlags and (CVAR_NOCHEAT or CVAR_INIT or CVAR_ROM or CVAR_ARCHIVE or CVAR_USERINFO or CVAR_SERVERINFO or
    CVAR_NETWORKSYNC)) <> 0 then
    FFlags := FFlags and not CVAR_CHEAT
  else
    FFlags := FFlags or CVAR_CHEAT;
end;

procedure TCVar.DoSet(const ANewValue: AnsiString; const AForce, AFromServer: Boolean);
begin
  if FContext.IsMultiplayer and not AFromServer then
  begin
    if ((FFlags and CVAR_NETWORKSYNC) <> 0) and FContext.IsNetworkClientActive then
    begin
      FContext.Print(string(FName) + ' is a synced over the network and cannot be changed on a multiplayer client.'#10);
      Exit;
    end;
    if ((FFlags and CVAR_CHEAT) <> 0) and not FContext.GetCVarBool('net_allowCheats') then
    begin
      FContext.Print(string(FName) + ' cannot be changed in multiplayer.'#10);
      Exit;
    end;
  end;

  if not AForce then
  begin
    if (FFlags and CVAR_ROM) <> 0 then
    begin
      FContext.Print(string(FName) + ' is read only.'#10);
      Exit;
    end;
    if (FFlags and CVAR_INIT) <> 0 then
    begin
      FContext.Print(string(FName) + ' is write protected.'#10);
      Exit;
    end;
  end;

  if TIdStrings.Icmp(FValueString, ANewValue) = 0 then
    Exit;

  FValueString := ANewValue;
  UpdateValue;

  SetModified;
  FContext.SetModifiedFlags(FFlags);
end;

procedure TCVar.SetValue(const ANewValue: AnsiString; const AForce, AFromServer: Boolean);
begin
  DoSet(ANewValue, AForce, AFromServer);
end;

procedure TCVar.SetToResetValue(const AForce, AFromServer: Boolean);
begin
  DoSet(FResetString, AForce, AFromServer);
end;

procedure TCVar.Reset;
begin
  FValueString := FResetString;
  UpdateValue;
end;

procedure TCVar.SetString(const AValue: AnsiString);
begin
  DoSet(AValue, True, False);
end;

procedure TCVar.SetBool(const AValue: Boolean);
begin
  DoSet(BooleanText(AValue), True, False);
end;

procedure TCVar.SetInteger(const AValue: Integer);
begin
  DoSet(AnsiString(IntToStr(AValue)), True, False);
end;

procedure TCVar.SetFloat(const AValue: Single);
begin
  DoSet(TIdStrings.FloatToText(AValue), True, False);
end;

procedure TCVar.ServerSetString(const AValue: AnsiString);
begin
  DoSet(AValue, True, True);
end;

function TCVar.GetString: AnsiString;
begin
  Result := FValueString;
end;

function TCVar.GetBool: Boolean;
begin
  Result := FIntegerValue <> 0;
end;

function TCVar.GetInteger: Integer;
begin
  Result := FIntegerValue;
end;

function TCVar.GetFloat: Single;
begin
  Result := FFloatValue;
end;

function TCVar.IsModified: Boolean;
begin
  Result := (FFlags and CVAR_MODIFIED) <> 0;
end;

procedure TCVar.SetModified;
begin
  FFlags := FFlags or CVAR_MODIFIED;
end;

procedure TCVar.ClearModified;
begin
  FFlags := FFlags and not CVAR_MODIFIED;
end;

procedure TCVar.AddFlags(const AFlags: Integer);
begin
  FFlags := FFlags or AFlags;
end;

procedure TCVar.ClearValueCompletion;
begin
  FValueCompletion := nil;
end;

end.
