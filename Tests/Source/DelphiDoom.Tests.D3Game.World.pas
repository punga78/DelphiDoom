{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - the fake engine (entityDefs, }
{  script names, spawn functions, map file, cvars, map steps, events) that     }
{  writes down every call in the format of Tools\Verifica\255\harness_game.cpp }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.World;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Scanner.IdDict,
  DelphiDoom.DoomScript.EventDef, DelphiDoom.D3Game.Intf;

type
  /// <summary>The text of a golden: the escapes of the harness (\\ \n \r \t \" and \xHH)</summary>
  TD3GameEscape = class
  public
    class function Escape(const AText: AnsiString): string; static;
    class function Unescape(const AText: string): AnsiString; static;
  end;

  /// <summary>An entityDef of the fake declarations: a name, an index and the dictionary of defaults</summary>
  TD3GameFakeEntityDef = class(TInterfacedObject, ID3EntityDef)
  strict private
    FName: AnsiString;
    FIndex: Integer;
    FDict: TIdDict;
  public
    constructor Create(const AName: AnsiString; const AIndex: Integer);
    destructor Destroy; override;
    function GetName: AnsiString;
    function GetIndex: Integer;
    function GetDict: TIdDict;
  end;

  /// <summary>
  ///   Every service that the game uses, in one object that the test owns (the interfaces are not reference counted).
  ///   Every call is written to Trace, one line per fact, as the C++ harness does.
  /// </summary>
  TD3GameFakeWorld = class(TObject, IInterface, ID3GamePrinter, ID3EntityDefs, ID3SpawnFunctions, ID3ScriptNames,
    ID3MapSource, ID3GameSettings, ID3MapSteps, ID3EventCanceller, ID3EventPoster)
  strict private
    FDefs: TList<ID3EntityDef>;
    FFunctions: TStringList;
    FMapEntities: TObjectList<TIdDict>;
  protected
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    Trace: TStringList;
    Skill: Integer;
    Multiplayer: Boolean;
    CinematicEnabled: Boolean;
    /// <summary>Nothing is written while it is set (the harness does the same for a long fill)</summary>
    Quiet: Boolean;
    constructor Create;
    destructor Destroy; override;
    procedure Line(const AText: string);
    procedure AddDef(const AName: AnsiString; const AKeysAndValues: array of AnsiString);
    procedure AddFunction(const AName: AnsiString);
    function NewMapFile: Boolean;
    procedure ClearMapFile;
    function HasMapFile: Boolean;
    procedure AddMapEntity(const AKeysAndValues: array of AnsiString);
    { ID3GamePrinter }
    procedure Printf(const AText: AnsiString);
    procedure Warning(const AText: AnsiString);
    procedure Error(const AText: AnsiString);
    { ID3EntityDefs }
    function FindEntityDef(const AName: AnsiString): ID3EntityDef;
    function FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
    { ID3SpawnFunctions }
    function StartSpawnFunction(const AName: AnsiString): Boolean;
    { ID3ScriptNames }
    procedure SetEntity(const AName: AnsiString; const AEntityNumber: Integer);
    { ID3MapSource }
    function GetNumEntities: Integer;
    function GetEntityEpairs(const AIndex: Integer): TIdDict;
    { ID3GameSettings }
    function GetSkill: Integer;
    function GetIsMultiplayer: Boolean;
    function GetCinematicEnabled: Boolean;
    { ID3MapSteps }
    procedure SetSkill(const ASkill: Integer);
    procedure CacheDictionaryMedia(const ADict: TIdDict);
    procedure SpreadLocations;
    procedure RandomizeInitialSpawns;
    procedure SetSkipSpecular(const AValue: Boolean);
    procedure ServiceEvents;
    { ID3EventCanceller }
    procedure CancelEvents(const AObject: TObject);
    { ID3EventPoster }
    procedure PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef; const ATime: Integer);
  end;

implementation

{ TD3GameEscape }

class function TD3GameEscape.Escape(const AText: AnsiString): string;
var
  LIndex: Integer;
  LCode: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LCode := Byte(AText[LIndex]);
    case LCode of
      Ord('\'): Result := Result + '\\';
      10: Result := Result + '\n';
      13: Result := Result + '\r';
      9: Result := Result + '\t';
      Ord('"'): Result := Result + '\"';
    else
      if (LCode < 32) or (LCode > 126) then
        Result := Result + '\x' + IntToHex(LCode, 2)
      else
        Result := Result + Char(LCode);
    end;
  end;
end;

class function TD3GameEscape.Unescape(const AText: string): AnsiString;
var
  LIndex: Integer;
  LChar: Char;
begin
  Result := '';
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] <> '\') or (LIndex = Length(AText)) then
    begin
      Result := Result + AnsiChar(AText[LIndex]);
      Inc(LIndex);
      Continue;
    end;
    Inc(LIndex);
    LChar := AText[LIndex];
    if LChar = 'n' then
      Result := Result + #10
    else if LChar = 't' then
      Result := Result + #9
    else if LChar = 'r' then
      Result := Result + #13
    else if LChar = '"' then
      Result := Result + '"'
    else if LChar = '\' then
      Result := Result + '\'
    else if (LChar = 'x') and (LIndex + 2 < Length(AText) + 1) then
    begin
      Result := Result + AnsiChar(StrToInt('$' + Copy(AText, LIndex + 1, 2)));
      Inc(LIndex, 2);
    end
    else
      Result := Result + '\' + AnsiChar(LChar);
    Inc(LIndex);
  end;
end;

{ TD3GameFakeEntityDef }

constructor TD3GameFakeEntityDef.Create(const AName: AnsiString; const AIndex: Integer);
begin
  inherited Create;
  FName := AName;
  FIndex := AIndex;
  FDict := TIdDict.Create;
end;

destructor TD3GameFakeEntityDef.Destroy;
begin
  FDict.Free;
  inherited Destroy;
end;

function TD3GameFakeEntityDef.GetName: AnsiString;
begin
  Result := FName;
end;

function TD3GameFakeEntityDef.GetIndex: Integer;
begin
  Result := FIndex;
end;

function TD3GameFakeEntityDef.GetDict: TIdDict;
begin
  Result := FDict;
end;

{ TD3GameFakeWorld }

constructor TD3GameFakeWorld.Create;
begin
  inherited Create;
  Trace := TStringList.Create;
  FDefs := TList<ID3EntityDef>.Create;
  FFunctions := TStringList.Create;
  Skill := 1;
  CinematicEnabled := True;
end;

destructor TD3GameFakeWorld.Destroy;
begin
  FMapEntities.Free;
  FFunctions.Free;
  FDefs.Free;
  Trace.Free;
  inherited Destroy;
end;

function TD3GameFakeWorld.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TD3GameFakeWorld._AddRef: Integer;
begin
  Result := -1;
end;

function TD3GameFakeWorld._Release: Integer;
begin
  Result := -1;
end;

procedure TD3GameFakeWorld.Line(const AText: string);
begin
  if not Quiet then
    Trace.Add(AText);
end;

procedure TD3GameFakeWorld.AddDef(const AName: AnsiString; const AKeysAndValues: array of AnsiString);
var
  LDef: TD3GameFakeEntityDef;
  LIndex: Integer;
begin
  LDef := TD3GameFakeEntityDef.Create(AName, FDefs.Count);
  FDefs.Add(LDef);
  LIndex := 0;
  while LIndex + 1 <= High(AKeysAndValues) do
  begin
    LDef.GetDict.SetValue(AKeysAndValues[LIndex], AKeysAndValues[LIndex + 1]);
    Inc(LIndex, 2);
  end;
end;

procedure TD3GameFakeWorld.AddFunction(const AName: AnsiString);
begin
  FFunctions.Add(string(AName));
end;

function TD3GameFakeWorld.NewMapFile: Boolean;
begin
  FreeAndNil(FMapEntities);
  FMapEntities := TObjectList<TIdDict>.Create(True);
  Result := True;
end;

procedure TD3GameFakeWorld.ClearMapFile;
begin
  FreeAndNil(FMapEntities);
end;

function TD3GameFakeWorld.HasMapFile: Boolean;
begin
  Result := Assigned(FMapEntities);
end;

procedure TD3GameFakeWorld.AddMapEntity(const AKeysAndValues: array of AnsiString);
var
  LDict: TIdDict;
  LIndex: Integer;
begin
  LDict := TIdDict.Create;
  FMapEntities.Add(LDict);
  LIndex := 0;
  while LIndex + 1 <= High(AKeysAndValues) do
  begin
    LDict.SetValue(AKeysAndValues[LIndex], AKeysAndValues[LIndex + 1]);
    Inc(LIndex, 2);
  end;
end;

procedure TD3GameFakeWorld.Printf(const AText: AnsiString);
begin
  Line('PRINT ' + TD3GameEscape.Escape(AText));
end;

procedure TD3GameFakeWorld.Warning(const AText: AnsiString);
begin
  Line('WARNING ' + TD3GameEscape.Escape(AText));
end;

procedure TD3GameFakeWorld.Error(const AText: AnsiString);
begin
  Quiet := False;
  Line('ERROR ' + TD3GameEscape.Escape(AText));
end;

function TD3GameFakeWorld.FindEntityDef(const AName: AnsiString): ID3EntityDef;
var
  LDef: ID3EntityDef;
begin
  for LDef in FDefs do
    if SameText(string(LDef.GetName), string(AName)) then
      Exit(LDef);
  Result := nil;
end;

function TD3GameFakeWorld.FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
begin
  Result := FDefs[AIndex];
end;

function TD3GameFakeWorld.StartSpawnFunction(const AName: AnsiString): Boolean;
begin
  Result := FFunctions.IndexOf(string(AName)) >= 0;
  if Result then
  begin
    Line('CALL idThread ' + string(AName));
    Line('CALL idThread.DelayedStart 0');
  end;
end;

procedure TD3GameFakeWorld.SetEntity(const AName: AnsiString; const AEntityNumber: Integer);
begin
  Line(Format('CALL program.SetEntity %s %d', [string(AName), AEntityNumber]));
end;

function TD3GameFakeWorld.GetNumEntities: Integer;
begin
  Result := FMapEntities.Count;
end;

function TD3GameFakeWorld.GetEntityEpairs(const AIndex: Integer): TIdDict;
begin
  Result := FMapEntities[AIndex];
end;

function TD3GameFakeWorld.GetSkill: Integer;
begin
  Result := Skill;
end;

function TD3GameFakeWorld.GetIsMultiplayer: Boolean;
begin
  Result := Multiplayer;
end;

function TD3GameFakeWorld.GetCinematicEnabled: Boolean;
begin
  Result := CinematicEnabled;
end;

procedure TD3GameFakeWorld.SetSkill(const ASkill: Integer);
begin
  Line(Format('CALL SetSkill %d', [ASkill]));
end;

procedure TD3GameFakeWorld.CacheDictionaryMedia(const ADict: TIdDict);
begin
  Line('CALL CacheDictionaryMedia ' + TD3GameEscape.Escape(ADict.GetString('classname')));
end;

procedure TD3GameFakeWorld.SpreadLocations;
begin
  Line('CALL SpreadLocations');
end;

procedure TD3GameFakeWorld.RandomizeInitialSpawns;
begin
  Line('CALL RandomizeInitialSpawns');
end;

procedure TD3GameFakeWorld.SetSkipSpecular(const AValue: Boolean);
begin
  Line(Format('CALL cvar.SetBool r_skipSpecular %d', [Ord(AValue)]));
end;

procedure TD3GameFakeWorld.ServiceEvents;
begin
  Line('CALL idEvent.ServiceEvents');
end;

procedure TD3GameFakeWorld.CancelEvents(const AObject: TObject);
begin
  Line('CALL idEvent.CancelEvents');
end;

procedure TD3GameFakeWorld.PostEventMS(const AObject: TObject; const AEvent: TDoomScriptEventDef;
  const ATime: Integer);
begin
  Line('CALL PostEventMS ' + TD3GameEscape.Escape(AEvent.Name));
end;

end.
