{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the defaults of the configuration file over            }
{  Libs\Configuration                                                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Configuration.Defaults;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.Configuration.Intf,
  DelphiDoom.Console.Intf,
  DelphiDoom.Engine.Configuration.Intf;

type
  /// <summary>
  ///   M_LoadDefaults, M_SaveDefaults, M_SetDefault and M_ForceDefault* of the old m_misc.pas:
  ///   the table of the options (with the pointers to their variables) stays in m_defs, the
  ///   format of the file comes from Libs\Configuration and the commands "get" and "setdefault"
  ///   go to the console
  /// </summary>
  TEngineDefaults = class(TInterfacedObject, IEngineDefaults)
  strict private
    FFormat: IConfigurationFormat;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FFileName: string;
    FConfigNotFound: Boolean;
    procedure ResetMatching(const AMask: string);
  public
    /// <param name="ARegistry">Where the commands of the defaults go and where Reset looks for a command</param>
    /// <param name="AInterpreter">Runs "get" and the command of an option after Reset</param>
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const AFormat: IConfigurationFormat; const ARegistry: ICommandRegistry;
      const AInterpreter: IConsoleInterpreter);
    /// <summary>
    ///   The commands "defaults, setdefaults" and "default, setdefault": both reset every option,
    ///   as in the old code (they were registered by the menus)
    /// </summary>
    procedure RegisterCommands;
    procedure Load;
    procedure Save;
    procedure Reset(const AName: string);
    function ForceBoolean(const AName: string; const AValue: Boolean): Boolean;
    function ForceInteger(const AName: string; const AValue: Integer): Boolean;
    function ForceString(const AName: string; const AValue: string): Boolean;
    function ConfigNotFound: Boolean;
  end;

implementation

uses
  d_delphi,
  doomdef,
{$IFDEF DOOM}
  doomstat,
{$ENDIF}
  d_main,
  d_player,
  g_game,
  m_argv,
  m_base,
  m_defs,
  m_misc,
  i_system,
{$IFDEF OPENGL}
  gl_defs,
{$ENDIF}
  DelphiDoom.Console.MaskMatcher;

const
  SFormatIsNil = 'TEngineDefaults: the format of the configuration is nil';
  SRegistryIsNil = 'TEngineDefaults: the registry of the commands is nil';
  SInterpreterIsNil = 'TEngineDefaults: the interpreter is nil';

{ TEngineDefaults }

constructor TEngineDefaults.Create(const AFormat: IConfigurationFormat;
  const ARegistry: ICommandRegistry; const AInterpreter: IConsoleInterpreter);
begin
  inherited Create;
  if not Assigned(AFormat) then
    raise EArgumentNilException.Create(SFormatIsNil);
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create(SRegistryIsNil);
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create(SInterpreterIsNil);
  FFormat := AFormat;
  FRegistry := ARegistry;
  FInterpreter := AInterpreter;
  FConfigNotFound := True;
end;

procedure TEngineDefaults.RegisterCommands;
begin
  FRegistry.Add('defaults, setdefaults',
    procedure(const AParam1, AParam2: string)
    begin
      Reset('*');
    end);
  FRegistry.Add('default, setdefault',
    procedure(const AParam1, AParam2: string)
    begin
      Reset('*');
    end);
end;

function TEngineDefaults.ConfigNotFound: Boolean;
begin
  Result := FConfigNotFound;
end;

procedure TEngineDefaults.Save;
var
  LIndex: Integer;
  LDefault: Pdefault_t;
  LText: TDStringList;
  LWriter: IConfigurationWriter;
  LLines: TArray<string>;
begin
  LWriter := FFormat.CreateWriter(FFormat.FormatHeader(AppTitle, D_EngineVersion));
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

  LText := TDStringList.Create;
  try
    LLines := LWriter.Lines;
    for LIndex := 0 to High(LLines) do
      LText.Add(LLines[LIndex]);
    LText.SaveToFile(FFileName);
  finally
    LText.Free;
  end;
end;

procedure TEngineDefaults.ResetMatching(const AMask: string);
var
  LNames: TArray<string>;
  LMatching: TArray<string>;
  LCount: Integer;
  LIndex: Integer;
  LDefault: Pdefault_t;
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

  LMatching := TConsoleMaskMatcher.Filter(LNames, AMask);
  for LIndex := 0 to High(LMatching) do
    Reset(LMatching[LIndex]);
end;

procedure TEngineDefaults.Reset(const AName: string);
var
  LIndex: Integer;
  LName: string;
  LParameter: string;
  LSetFlags: Byte;
begin
  // set the option to its base value
  if AName = '' then
  begin
    printf('Please specify the variable to reset to default value'#13#10);
    Exit;
  end;

  if netgame then
    LSetFlags := DFS_NETWORK
  else
    LSetFlags := DFS_SINGLEPLAYER;

  // a mask
  if CharPos('*', AName) > 0 then
  begin
    ResetMatching(AName);
    Exit;
  end;

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
        printf('Setting default value for %s'#13#10, [AName]);
        FInterpreter.Execute('get', LName); // Display the default value
      end
      else if FRegistry.Contains(LName) then
      begin
        if defaults[LIndex]._type = tInteger then
          LParameter := itoa(defaults[LIndex].defaultivalue)
        else if defaults[LIndex]._type = tBoolean then
          LParameter := yesnostrings[defaults[LIndex].defaultbvalue]
        else if defaults[LIndex]._type = tString then
          LParameter := defaults[LIndex].defaultsvalue
        else
          Exit; // Ouch!
        printf('Setting default value for %s'#13#10, [AName]);
        FInterpreter.Execute(LName, LParameter);
      end;
    end;
end;

procedure TEngineDefaults.Load;
var
  LIndex: Integer;
  LOption: Integer;
  LFound: Integer;
  LDefault: Pdefault_t;
  LText: TDStringList;
  LName: string;
  LDocument: IConfigurationDocument;
  LLines: TArray<string>;
begin
  // set everything to base values
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex]._type = tInteger then
      PInteger(defaults[LIndex].location)^ := defaults[LIndex].defaultivalue
    else if defaults[LIndex]._type = tBoolean then
      PBoolean(defaults[LIndex].location)^ := defaults[LIndex].defaultbvalue
    else if defaults[LIndex]._type = tString then
      PString(defaults[LIndex].location)^ := defaults[LIndex].defaultsvalue;

  if M_CheckParm('-defaultvalues') > 0 then
    Exit;

  // check for a custom default file
  LIndex := M_CheckParm('-config');
  if (LIndex > 0) and (LIndex < myargc - 1) then
  begin
    FFileName := myargv[LIndex + 1];
    printf(' default file: %s'#13#10, [FFileName]);
  end
  else
    FFileName := basedefault;

  LText := TDStringList.Create;
  try
    // read the file in, overriding any set defaults
    if fexists(FFileName) then
      LText.LoadFromFile(FFileName);

    if LText.Count > 1 then
    begin
      SetLength(LLines, LText.Count);
      for LIndex := 0 to LText.Count - 1 do
        LLines[LIndex] := LText[LIndex];
      LDocument := FFormat.Parse(LLines);
      if FFormat.AcceptsHeader(LDocument.Header, D_EngineVersion) then
      begin
        FConfigNotFound := False;

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
    end;
  finally
    LText.Free;
  end;
{$IFNDEF STRIFE}
  if FConfigNotFound then
    G_SetKeyboardMode(1);
{$ENDIF}
{$IFNDEF DEBUG}
{$IFDEF OPENGL}
  gl_drawsky := true;
{$ENDIF}
{$ENDIF}
  defaultskill := GetIntegerInRange(defaultskill, Ord(sk_baby), Ord(sk_nightmare));
  startskill := skill_t(defaultskill);
  gameskill := startskill;
end;

function TEngineDefaults.ForceBoolean(const AName: string; const AValue: Boolean): Boolean;
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
          defaults[LIndex].setable := DFS_NEVER;
        end
        else
          PBoolean(defaults[LIndex].oldlocation)^ := AValue;
        Result := True;
      end;
end;

function TEngineDefaults.ForceInteger(const AName: string; const AValue: Integer): Boolean;
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
          defaults[LIndex].setable := DFS_NEVER;
        end
        else
          PInteger(defaults[LIndex].oldlocation)^ := AValue;
        Result := True;
      end;
end;

function TEngineDefaults.ForceString(const AName: string; const AValue: string): Boolean;
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
          defaults[LIndex].setable := DFS_NEVER;
        end
        else
          PString(defaults[LIndex].oldlocation)^ := AValue;
        Result := True;
      end;
end;

end.
