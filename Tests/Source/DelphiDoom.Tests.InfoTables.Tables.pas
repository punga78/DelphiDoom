{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the info tables - the tables of a test game            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.InfoTables.Tables;

interface

uses
  System.SysUtils,
  DelphiDoom.Info.Intf,
  DelphiDoom.Info.Types,
  DelphiDoom.Tests.InfoTables.LegacyInfo;

type
  /// <summary>The tables of the old code (mobjinfo, states, sprnames of LegacyInfo) seen through the contracts of the library</summary>
  TTestInfoTables = class(TInterfacedObject, IInfoMobjSource, IInfoStateSource, IInfoSpriteSource)
  public
    function Count: Integer;
    function BuiltInCount: Integer;
    function Get(const AIndex: Integer): TInfoMobj;
    function Name(const AIndex: Integer): string;
    function DoomedNum(const AIndex: Integer): Integer;
    function InheritsFrom(const AIndex: Integer): Integer;
  strict private
    function StateCount: Integer;
    function StateGet(const AIndex: Integer): TInfoState;
    function SpriteCount: Integer;
    function SpriteCode(const AIndex: Integer): Integer;
    function IInfoStateSource.Count = StateCount;
    function IInfoStateSource.Get = StateGet;
    function IInfoSpriteSource.Count = SpriteCount;
    function IInfoSpriteSource.Code = SpriteCode;
  public
    function IsOwnedBy(const AState, AMobj: Integer): Boolean;
  end;

/// <summary>Fills the tables of LegacyInfo with a random game; FreeScenario releases them</summary>
procedure BuildScenario(const ASeed: Integer);
procedure FreeScenario;

implementation

uses
  System.Classes,
  d_delphi,
  DelphiDoom.Tests.InfoTables.LegacyTokens;

const
  Names: array[0..13] of string = (
    'ZOMBIE', 'Imp', 'demon ', 'SHOTGUN GUY', '', 'Cacodemon', 'Lost Soul', 'a b', 'ZOMBIE', ' Imp',
    'baron', 'ARCH VILE', 'S P A C E', 'x');

procedure SetName(var AInfo: mobjinfo_t; const AName: string);
var
  LIndex: Integer;
begin
  FillChar(AInfo.name, SizeOf(AInfo.name), 0);
  for LIndex := 1 to Length(AName) do
    if LIndex <= MOBJINFONAMESIZE then
      AInfo.name[LIndex - 1] := AnsiChar(AName[LIndex]);
end;

procedure BuildScenario(const ASeed: Integer);
var
  LIndex: Integer;
  LState: Integer;
  LOwners: Integer;
begin
  RandSeed := ASeed;
  nummobjtypes := DO_NUMMOBJTYPES + Random(40);
  numstates := 12 + Random(40);
  numsprites := 3 + Random(5);
  mobjinfo := mallocz(MAXTABLE * SizeOf(mobjinfo_t));
  states := mallocz(MAXTABLE * SizeOf(state_t));
  sprnames := mallocz((numsprites + 1) * 4);
  for LIndex := 0 to numsprites - 1 do
    sprnames[LIndex] := Ord('A') + Ord(Chr(Ord('A') + LIndex)) shl 8 + Ord('R') shl 16 + Ord('S') shl 24;

  for LIndex := 0 to nummobjtypes - 1 do
  begin
    SetName(mobjinfo[LIndex], Names[Random(Length(Names))] + IntToStr(Random(3) - 1));
    if Random(4) = 0 then
      SetName(mobjinfo[LIndex], Names[Random(Length(Names))]);
    mobjinfo[LIndex].inheritsfrom := -1;
    if (LIndex >= DO_NUMMOBJTYPES) and (Random(3) > 0) then
      mobjinfo[LIndex].inheritsfrom := Random(nummobjtypes);
    mobjinfo[LIndex].doomednum := Random(30) - 1;
    mobjinfo[LIndex].spawnhealth := Random(3000);
    mobjinfo[LIndex].flags := Random(2) * MF_SHOOTABLE + Random(2) * MF_COUNTKILL;
    mobjinfo[LIndex].spawnstate := Random(numstates) - Random(2);
    mobjinfo[LIndex].seestate := Random(numstates);
    mobjinfo[LIndex].painstate := Random(numstates);
    mobjinfo[LIndex].meleestate := Random(numstates) * Random(2);
    mobjinfo[LIndex].missilestate := Random(numstates) * Random(2);
    mobjinfo[LIndex].deathstate := Random(numstates);
    mobjinfo[LIndex].xdeathstate := Random(numstates);
    mobjinfo[LIndex].raisestate := Random(numstates);
    mobjinfo[LIndex].healstate := Random(numstates);
    mobjinfo[LIndex].crashstate := Random(numstates);
    mobjinfo[LIndex].crushstate := Random(numstates);
    mobjinfo[LIndex].interactstate := Random(numstates);
  end;

  for LState := 0 to numstates - 1 do
  begin
    states[LState].sprite := Random(numsprites);
    states[LState].frame := Random(30) + Random(2) * $8000;
    states[LState].tics := Random(4) - 1;
    states[LState].nextstate := Random(numstates) * Random(3) div 2;
    if Random(3) = 0 then
    begin
      states[LState].owners := TDNumberList.Create;
      for LOwners := 0 to Random(4) do
        states[LState].owners.Add(Random(nummobjtypes));
    end;
  end;

  // sometimes a loop of states that never waits
  if Random(4) = 0 then
  begin
    LState := 1 + Random(numstates - 1);
    LOwners := 1 + Random(numstates - 1);
    states[LState].tics := 0;
    states[LState].nextstate := LOwners;
    states[LOwners].tics := 0;
    states[LOwners].nextstate := LState;
  end;

  legacy_statenames := TLegacyTokenList.Create;
  for LState := 0 to numstates - 1 do
    if Random(3) = 0 then
      legacy_statenames.Add('S_X' + IntToStr(LState) + ', s_alias' + IntToStr(LState))
    else
      legacy_statenames.Add('S_' + Names[Random(Length(Names))] + '_SPAWN' + IntToStr(LState));
  infighting_groups := TDTextList.Create;
  infighting_groups.Add('IG_DEFAULT');
  infighting_groups.Add('IG_ONE');
  projectile_groups := TDTextList.Create;
  projectile_groups.Add('PG_DEFAULT');
  splash_groups := TDTextList.Create;
  splash_groups.Add('SG_DEFAULT');
  LegacyLog := TStringList.Create;
end;

procedure FreeScenario;
var
  LState: Integer;
begin
  for LState := 0 to numstates - 1 do
    states[LState].owners.Free;
  memfree(pointer(mobjinfo), MAXTABLE * SizeOf(mobjinfo_t));
  memfree(pointer(states), MAXTABLE * SizeOf(state_t));
  memfree(pointer(sprnames), (numsprites + 1) * 4);
  legacy_statenames.Free;
  infighting_groups.Free;
  projectile_groups.Free;
  splash_groups.Free;
  LegacyLog.Free;
end;

{ TTestInfoTables }

function TTestInfoTables.Count: Integer;
begin
  Result := nummobjtypes;
end;

function TTestInfoTables.BuiltInCount: Integer;
begin
  Result := DO_NUMMOBJTYPES;
end;

function TTestInfoTables.Get(const AIndex: Integer): TInfoMobj;
begin
  Result.Name := Legacy_Info_GetMobjName(AIndex);
  Result.DoomedNum := mobjinfo[AIndex].doomednum;
  Result.InheritsFrom := mobjinfo[AIndex].inheritsfrom;
  Result.SpawnHealth := mobjinfo[AIndex].spawnhealth;
  Result.Flags := mobjinfo[AIndex].flags;
  Result.SpawnState := mobjinfo[AIndex].spawnstate;
  Result.SeeState := mobjinfo[AIndex].seestate;
  Result.PainState := mobjinfo[AIndex].painstate;
  Result.MeleeState := mobjinfo[AIndex].meleestate;
  Result.MissileState := mobjinfo[AIndex].missilestate;
  Result.DeathState := mobjinfo[AIndex].deathstate;
  Result.XDeathState := mobjinfo[AIndex].xdeathstate;
  Result.RaiseState := mobjinfo[AIndex].raisestate;
  Result.HealState := mobjinfo[AIndex].healstate;
  Result.CrashState := mobjinfo[AIndex].crashstate;
  Result.CrushState := mobjinfo[AIndex].crushstate;
  Result.InteractState := mobjinfo[AIndex].interactstate;
end;

function TTestInfoTables.Name(const AIndex: Integer): string;
begin
  Result := Legacy_Info_GetMobjName(AIndex);
end;

function TTestInfoTables.DoomedNum(const AIndex: Integer): Integer;
begin
  Result := mobjinfo[AIndex].doomednum;
end;

function TTestInfoTables.InheritsFrom(const AIndex: Integer): Integer;
begin
  Result := mobjinfo[AIndex].inheritsfrom;
end;

function TTestInfoTables.StateCount: Integer;
begin
  Result := numstates;
end;

function TTestInfoTables.StateGet(const AIndex: Integer): TInfoState;
begin
  Result.Sprite := states[AIndex].sprite;
  Result.Frame := states[AIndex].frame and FF_FRAMEMASK;
  Result.NextState := states[AIndex].nextstate;
  Result.Tics := states[AIndex].tics;
end;

function TTestInfoTables.IsOwnedBy(const AState, AMobj: Integer): Boolean;
begin
  Result := (states[AState].owners <> nil) and (states[AState].owners.IndexOf(AMobj) >= 0);
end;

function TTestInfoTables.SpriteCount: Integer;
begin
  Result := numsprites;
end;

function TTestInfoTables.SpriteCode(const AIndex: Integer): Integer;
begin
  Result := sprnames[AIndex];
end;

end.
