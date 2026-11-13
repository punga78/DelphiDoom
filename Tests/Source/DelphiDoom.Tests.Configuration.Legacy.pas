{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the configuration library - copy of the old code of    }
{  the table of the options, for the parity old/new                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Configuration.Legacy;

// A faithful copy of what the engine did on the table "defaults" of m_defs at 63a151cc:
// TEngineDefaults.Load (the loops after the file is read), Save, Reset, ForceBoolean,
// ForceInteger, ForceString (Base\DelphiDoom.Engine.Configuration.Defaults.pas),
// TEngineScriptConsole.GetString/GetInteger/GetBoolean (Base\DelphiDoom.Engine.Script.Console.pas)
// and TEngineConsoleVariable (Base\DelphiDoom.Engine.Console.Variable.pas). The world around it is
// fake: the globals, printf and the console are lists of this class; the record is the default_t
// of m_defs, with the pointers. Only the names of the identifiers that were globals changed.

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Configuration.Intf;

const
  LEGACY_DFS_NEVER = 0;
  LEGACY_DFS_SINGLEPLAYER = 1;
  LEGACY_DFS_NETWORK = 2;
  LEGACY_DFS_ALWAYS = 3;

type
  legacy_ttype_t = (tString, tInteger, tBoolean, tGroup);

  legacy_default_t = record
    name: string;
    location: pointer;
    oldlocation: pointer;
    setable: byte;
    defaultsvalue: string;
    defaultivalue: integer;
    defaultbvalue: boolean;
    _type: legacy_ttype_t;
  end;
  Plegacy_default_t = ^legacy_default_t;

  /// <summary>The old code on its own table; messages and console calls go to Log</summary>
  TLegacyDefaults = class
  strict private
    FFormat: IConfigurationFormat;
    FCommands: TStrings;
    FLog: TStrings;
  public
    defaults: TArray<legacy_default_t>;
    netgame: boolean;
    constructor Create(const AFormat: IConfigurationFormat; const ACommands, ALog: TStrings);
    function NUMDEFAULTS: Integer;
    procedure ResetAll;
    procedure Apply(const ADocument: IConfigurationDocument);
    procedure Save(const AWriter: IConfigurationWriter);
    procedure Reset(const AName: string);
    /// <summary>The names that ResetMatching gave to the mask matcher</summary>
    function MaskNames: TArray<string>;
    function ForceBoolean(const AName: string; const AValue: Boolean): Boolean;
    function ForceInteger(const AName: string; const AValue: Integer): Boolean;
    function ForceString(const AName: string; const AValue: string): Boolean;
    function ScriptGetString(const AName: string): string;
    function ScriptGetInteger(const AName: string): Integer;
    function ScriptGetBoolean(const AName: string): Boolean;
    function ConsoleGetInteger(const AIndex: Integer): Integer;
    procedure ConsoleSetInteger(const AIndex: Integer; AValue: Integer);
    function ConsoleGetBoolean(const AIndex: Integer): Boolean;
    procedure ConsoleSetBoolean(const AIndex: Integer; AValue: Boolean);
    function ConsoleGetString(const AIndex: Integer): string;
    procedure ConsoleSetString(const AIndex: Integer; const AValue: string);
  end;

const
  legacy_yesnostrings: array[boolean] of string = ('NO', 'YES');

implementation

function strlower(const S: string): string;
begin
  Result := LowerCase(S);
end;

function itoa(i: integer): string;
begin
  Result := IntToStr(i);
end;

// the scripts read a text as a number with d_delphi.atoi; the selection of the row is what is
// compared here, so both sides use the same conversion
function atoi(const s: string; const default: integer): integer;
begin
  Result := StrToIntDef(s, default);
end;

{ TLegacyDefaults }

constructor TLegacyDefaults.Create(const AFormat: IConfigurationFormat;
  const ACommands, ALog: TStrings);
begin
  inherited Create;
  FFormat := AFormat;
  FCommands := ACommands;
  FLog := ALog;
end;

function TLegacyDefaults.NUMDEFAULTS: Integer;
begin
  Result := Length(defaults);
end;

procedure TLegacyDefaults.ResetAll;
var
  LIndex: Integer;
begin
  // set everything to base values
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex]._type = tInteger then
      PInteger(defaults[LIndex].location)^ := defaults[LIndex].defaultivalue
    else if defaults[LIndex]._type = tBoolean then
      PBoolean(defaults[LIndex].location)^ := defaults[LIndex].defaultbvalue
    else if defaults[LIndex]._type = tString then
      PString(defaults[LIndex].location)^ := defaults[LIndex].defaultsvalue;
end;

procedure TLegacyDefaults.Apply(const ADocument: IConfigurationDocument);
var
  LIndex: Integer;
  LOption: Integer;
  LFound: Integer;
  LDefault: Plegacy_default_t;
  LName: string;
  LDocument: IConfigurationDocument;
begin
  LDocument := ADocument;
  for LIndex := 0 to LDocument.Count - 1 do
  begin
    LFound := -1;
    LName := LDocument.NameAt(LIndex);
    for LOption := 0 to NUMDEFAULTS - 1 do
      if defaults[LOption].name = LName then
      begin
        LFound := LOption;
        Break;
      end;

    if LFound > -1 then
    begin
      LDefault := @defaults[LFound];
      if LDefault._type = tInteger then
        PInteger(LDefault.location)^ := FFormat.ParseInteger(LDocument.ValueOf(LName))
      else if LDefault._type = tBoolean then
        PBoolean(LDefault.location)^ := FFormat.ParseBoolean(LDocument.ValueOf(LName))
      else if LDefault._type = tString then
        PString(LDefault.location)^ := LDocument.ValueOf(LName);
    end;
  end;
end;

procedure TLegacyDefaults.Save(const AWriter: IConfigurationWriter);
var
  LIndex: Integer;
  LDefault: Plegacy_default_t;
  LWriter: IConfigurationWriter;
begin
  LWriter := AWriter;
  LDefault := @defaults[0];
  for LIndex := 0 to NUMDEFAULTS - 1 do
  begin
    if LDefault._type = tInteger then
      LWriter.AddValue(LDefault.name, FFormat.FormatInteger(PInteger(LDefault.location)^))
    else if LDefault._type = tString then
      LWriter.AddValue(LDefault.name, PString(LDefault.location)^)
    else if LDefault._type = tBoolean then
      LWriter.AddValue(LDefault.name, FFormat.FormatBoolean(PBoolean(LDefault.location)^))
    else if LDefault._type = tGroup then
      LWriter.AddGroup(LDefault.name);
    Inc(LDefault);
  end;
end;

function TLegacyDefaults.MaskNames: TArray<string>;
var
  LNames: TArray<string>;
  LCount: Integer;
  LIndex: Integer;
  LDefault: Plegacy_default_t;
begin
  SetLength(LNames, NUMDEFAULTS);
  LCount := 0;
  LDefault := @defaults[0];
  for LIndex := 0 to NUMDEFAULTS - 1 do
  begin
    if LDefault._type <> tGroup then
    begin
      LNames[LCount] := LDefault.name;
      Inc(LCount);
    end;
    Inc(LDefault);
  end;
  SetLength(LNames, LCount);
  Result := LNames;
end;

procedure TLegacyDefaults.Reset(const AName: string);
var
  LIndex: Integer;
  LName: string;
  LParameter: string;
  LSetFlags: Byte;
begin
  // set the option to its base value
  if AName = '' then
  begin
    FLog.Add('Please specify the variable to reset to default value');
    Exit;
  end;

  if netgame then
    LSetFlags := LEGACY_DFS_NETWORK
  else
    LSetFlags := LEGACY_DFS_SINGLEPLAYER;

  // a mask: the engine filters MaskNames and calls Reset for each one (not copied here)

  LName := strlower(AName);
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex].name = LName then
    begin
      if defaults[LIndex].setable and LSetFlags <> 0 then
      begin
        if defaults[LIndex]._type = tInteger then
          PInteger(defaults[LIndex].location)^ := defaults[LIndex].defaultivalue
        else if defaults[LIndex]._type = tBoolean then
          PBoolean(defaults[LIndex].location)^ := defaults[LIndex].defaultbvalue
        else if defaults[LIndex]._type = tString then
          PString(defaults[LIndex].location)^ := defaults[LIndex].defaultsvalue
        else
          Exit; // Ouch!
        FLog.Add('Setting default value for ' + AName);
        FLog.Add('execute get ' + LName); // Display the default value
      end
      else if FCommands.IndexOf(LName) >= 0 then
      begin
        if defaults[LIndex]._type = tInteger then
          LParameter := itoa(defaults[LIndex].defaultivalue)
        else if defaults[LIndex]._type = tBoolean then
          LParameter := legacy_yesnostrings[defaults[LIndex].defaultbvalue]
        else if defaults[LIndex]._type = tString then
          LParameter := defaults[LIndex].defaultsvalue
        else
          Exit; // Ouch!
        FLog.Add('Setting default value for ' + AName);
        FLog.Add('execute ' + LName + ' ' + LParameter);
      end;
    end;
end;

function TLegacyDefaults.ForceBoolean(const AName: string; const AValue: Boolean): Boolean;
var
  LIndex: Integer;
  LName: string;
begin
  Result := False;
  LName := strlower(AName);
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex]._type = tBoolean then
      if defaults[LIndex].name = LName then
      begin
        if defaults[LIndex].oldlocation = nil then
        begin
          defaults[LIndex].oldlocation := defaults[LIndex].location;
          defaults[LIndex].defaultbvalue := PBoolean(defaults[LIndex].location)^;
          PBoolean(defaults[LIndex].location)^ := AValue;
          PBoolean(defaults[LIndex].location) := @defaults[LIndex].defaultbvalue;
          defaults[LIndex].setable := LEGACY_DFS_NEVER;
        end
        else
          PBoolean(defaults[LIndex].oldlocation)^ := AValue;
        Result := True;
      end;
end;

function TLegacyDefaults.ForceInteger(const AName: string; const AValue: Integer): Boolean;
var
  LIndex: Integer;
  LName: string;
begin
  Result := False;
  LName := strlower(AName);
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex]._type = tInteger then
      if defaults[LIndex].name = LName then
      begin
        if defaults[LIndex].oldlocation = nil then
        begin
          defaults[LIndex].oldlocation := defaults[LIndex].location;
          defaults[LIndex].defaultivalue := PInteger(defaults[LIndex].location)^;
          PInteger(defaults[LIndex].location)^ := AValue;
          PInteger(defaults[LIndex].location) := @defaults[LIndex].defaultivalue;
          defaults[LIndex].setable := LEGACY_DFS_NEVER;
        end
        else
          PInteger(defaults[LIndex].oldlocation)^ := AValue;
        Result := True;
      end;
end;

function TLegacyDefaults.ForceString(const AName: string; const AValue: string): Boolean;
var
  LIndex: Integer;
  LName: string;
begin
  Result := False;
  LName := strlower(AName);
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex]._type = tString then
      if defaults[LIndex].name = LName then
      begin
        if defaults[LIndex].oldlocation = nil then
        begin
          defaults[LIndex].oldlocation := defaults[LIndex].location;
          defaults[LIndex].defaultsvalue := PString(defaults[LIndex].location)^;
          PString(defaults[LIndex].location)^ := AValue;
          PString(defaults[LIndex].location) := @defaults[LIndex].defaultsvalue;
          defaults[LIndex].setable := LEGACY_DFS_NEVER;
        end
        else
          PString(defaults[LIndex].oldlocation)^ := AValue;
        Result := True;
      end;
end;

function TLegacyDefaults.ScriptGetString(const AName: string): string;
var
  i: integer;
  pd: Plegacy_default_t;
  cname: string;
  location: Pointer;
begin
  cname := strlower(AName);

  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd.name = cname then
    begin
      if pd.oldlocation <> nil then
        location := pd.oldlocation
      else
        location := pd.location;
      case pd._type of
        tString:
          begin
            Result := PString(location)^;
            Exit;
          end;
        tInteger:
          begin
            Result := itoa(PInteger(location)^);
            Exit;
          end;
        tBoolean:
          begin
            if PBoolean(location)^ then
              Result := 'true'
            else
              Result := 'false';
            Exit;
          end;
      end;
    end;
    inc(pd);
  end;
  Result := '';
end;

function TLegacyDefaults.ScriptGetInteger(const AName: string): Integer;
var
  i: integer;
  pd: Plegacy_default_t;
  cname: string;
  location: Pointer;
begin
  cname := strlower(AName);

  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd.name = cname then
    begin
      if pd.oldlocation <> nil then
        location := pd.oldlocation
      else
        location := pd.location;
      case pd._type of
        tString:
          begin
            Result := atoi(PString(location)^, 0);
            Exit;
          end;
        tInteger:
          begin
            Result := PInteger(location)^;
            Exit;
          end;
        tBoolean:
          begin
            if PBoolean(location)^ then
              Result := 1
            else
              Result := 0;
            Exit;
          end;
      end;
    end;
    inc(pd);
  end;
  Result := 0;
end;

function TLegacyDefaults.ScriptGetBoolean(const AName: string): Boolean;
var
  i: integer;
  pd: Plegacy_default_t;
  cname: string;
  location: Pointer;
begin
  cname := strlower(AName);

  pd := @defaults[0];
  for i := 0 to NUMDEFAULTS - 1 do
  begin
    if pd.name = cname then
    begin
      if pd.oldlocation <> nil then
        location := pd.oldlocation
      else
        location := pd.location;
      case pd._type of
        tString:
          begin
            Result := PString(location)^ <> '';
            Exit;
          end;
        tInteger:
          begin
            Result := PInteger(location)^ <> 0;
            Exit;
          end;
        tBoolean:
          begin
            Result := PBoolean(location)^;
            Exit;
          end;
      end;
    end;
    inc(pd);
  end;
  Result := False;
end;

// TEngineConsoleVariable: the row is defaults[AIndex]
function TLegacyDefaults.ConsoleGetInteger(const AIndex: Integer): Integer;
begin
  Result := PInteger(defaults[AIndex].location)^;
end;

procedure TLegacyDefaults.ConsoleSetInteger(const AIndex: Integer; AValue: Integer);
begin
  PInteger(defaults[AIndex].location)^ := AValue;
end;

function TLegacyDefaults.ConsoleGetBoolean(const AIndex: Integer): Boolean;
begin
  Result := PBoolean(defaults[AIndex].location)^;
end;

procedure TLegacyDefaults.ConsoleSetBoolean(const AIndex: Integer; AValue: Boolean);
begin
  PBoolean(defaults[AIndex].location)^ := AValue;
end;

function TLegacyDefaults.ConsoleGetString(const AIndex: Integer): string;
begin
  Result := PString(defaults[AIndex].location)^;
end;

procedure TLegacyDefaults.ConsoleSetString(const AIndex: Integer; const AValue: string);
begin
  PString(defaults[AIndex].location)^ := AValue;
end;

end.
