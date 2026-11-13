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
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Configuration.Intf,
  DelphiDoom.Console.Intf,
  DelphiDoom.Engine.Configuration.Intf;

type
  /// <summary>
  ///   M_LoadDefaults, M_SaveDefaults, M_SetDefault and M_ForceDefault* of the old m_misc.pas:
  ///   the rows of the options are an IConfigurationTable (built from the data of m_defs by the
  ///   composition root), what is done on them is the IConfigurationTableStore of
  ///   Libs\Configuration; here stay the file on disk, the command line, the messages, the
  ///   commands "get" and "setdefault" of the console and what the games do after the load
  /// </summary>
  TEngineDefaults = class(TInterfacedObject, IEngineDefaults, IConfigurationResetSink)
  strict private
    FFormat: IConfigurationFormat;
    FTable: IConfigurationTable;
    FStore: IConfigurationTableStore;
    FRegistry: ICommandRegistry;
    FInterpreter: IConsoleInterpreter;
    FCommandLine: ICommandLine;
    FFileName: string;
    FConfigNotFound: Boolean;
    procedure ResetMatching(const AMask: string);
    { IConfigurationResetSink: the messages and the console of a reset }
    procedure ValueReset(const AName, ALowerName: string);
    function HasCommand(const ALowerName: string): Boolean;
    procedure CommandReset(const AName, ALowerName: string; const AItem: IConfigurationItem);
  public
    /// <param name="ATable">The rows of the options</param>
    /// <param name="AStore">Load, save and force on ATable</param>
    /// <param name="ARegistry">Where the commands of the defaults go and where Reset looks for a command</param>
    /// <param name="AInterpreter">Runs "get" and the command of an option after Reset</param>
    /// <param name="ACommandLine">Where -defaultvalues and -config are looked for</param>
    /// <remarks>Raises EArgumentNilException if one of them is nil</remarks>
    constructor Create(const AFormat: IConfigurationFormat; const ATable: IConfigurationTable;
      const AStore: IConfigurationTableStore; const ARegistry: ICommandRegistry;
      const AInterpreter: IConsoleInterpreter; const ACommandLine: ICommandLine);
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
    function Table: IConfigurationTable;
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
  m_base,
  m_defs,
  m_misc,
  i_system,
{$IFDEF OPENGL}
  gl_defs,
{$ENDIF}
  DelphiDoom.Configuration.Types,
  DelphiDoom.Console.MaskMatcher;

const
  SFormatIsNil = 'TEngineDefaults: the format of the configuration is nil';
  STableIsNil = 'TEngineDefaults: the table of the options is nil';
  SStoreIsNil = 'TEngineDefaults: the store of the table is nil';
  SRegistryIsNil = 'TEngineDefaults: the registry of the commands is nil';
  SInterpreterIsNil = 'TEngineDefaults: the interpreter is nil';
  SCommandLineIsNil = 'TEngineDefaults: the command line is nil';

{ TEngineDefaults }

constructor TEngineDefaults.Create(const AFormat: IConfigurationFormat;
  const ATable: IConfigurationTable; const AStore: IConfigurationTableStore;
  const ARegistry: ICommandRegistry; const AInterpreter: IConsoleInterpreter;
  const ACommandLine: ICommandLine);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create(SCommandLineIsNil);
  FCommandLine := ACommandLine;
  if not Assigned(AFormat) then
    raise EArgumentNilException.Create(SFormatIsNil);
  if not Assigned(ATable) then
    raise EArgumentNilException.Create(STableIsNil);
  if not Assigned(AStore) then
    raise EArgumentNilException.Create(SStoreIsNil);
  if not Assigned(ARegistry) then
    raise EArgumentNilException.Create(SRegistryIsNil);
  if not Assigned(AInterpreter) then
    raise EArgumentNilException.Create(SInterpreterIsNil);
  FFormat := AFormat;
  FTable := ATable;
  FStore := AStore;
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

function TEngineDefaults.Table: IConfigurationTable;
begin
  Result := FTable;
end;

procedure TEngineDefaults.Save;
var
  LIndex: Integer;
  LText: TDStringList;
  LWriter: IConfigurationWriter;
  LLines: TArray<string>;
begin
  LWriter := FFormat.CreateWriter(FFormat.FormatHeader(AppTitle, D_EngineVersion));
  FStore.Write(LWriter);

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
  LMatching: TArray<string>;
  LIndex: Integer;
begin
  LMatching := TConsoleMaskMatcher.Filter(FStore.Names, AMask);
  for LIndex := 0 to High(LMatching) do
    Reset(LMatching[LIndex]);
end;

procedure TEngineDefaults.Reset(const AName: string);
var
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

  FStore.Reset(AName, LSetFlags, Self);
end;

procedure TEngineDefaults.ValueReset(const AName, ALowerName: string);
begin
  printf('Setting default value for %s'#13#10, [AName]);
  FInterpreter.Execute('get', ALowerName); // Display the default value
end;

function TEngineDefaults.HasCommand(const ALowerName: string): Boolean;
begin
  Result := FRegistry.Contains(ALowerName);
end;

procedure TEngineDefaults.CommandReset(const AName, ALowerName: string;
  const AItem: IConfigurationItem);
var
  LParameter: string;
begin
  case AItem.Kind of
    cikInteger: LParameter := itoa(AItem.Defaults.IntegerValue);
    cikBoolean: LParameter := yesnostrings[AItem.Defaults.BooleanValue];
  else
    LParameter := AItem.Defaults.StringValue;
  end;
  printf('Setting default value for %s'#13#10, [AName]);
  FInterpreter.Execute(ALowerName, LParameter);
end;

procedure TEngineDefaults.Load;
var
  LIndex: Integer;
  LText: TDStringList;
  LDocument: IConfigurationDocument;
  LLines: TArray<string>;
begin
  // set everything to base values
  FStore.ResetAll;

  if FCommandLine.IndexOf('-defaultvalues') > 0 then
    Exit;

  // check for a custom default file
  LIndex := FCommandLine.IndexOf('-config');
  if (LIndex > 0) and (LIndex < FCommandLine.Count - 1) then
  begin
    FFileName := FCommandLine[LIndex + 1];
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
        FStore.Apply(LDocument);
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
begin
  Result := FStore.ForceBoolean(AName, AValue);
end;

function TEngineDefaults.ForceInteger(const AName: string; const AValue: Integer): Boolean;
begin
  Result := FStore.ForceInteger(AName, AValue);
end;

function TEngineDefaults.ForceString(const AName: string; const AValue: string): Boolean;
begin
  Result := FStore.ForceString(AName, AValue);
end;

end.
