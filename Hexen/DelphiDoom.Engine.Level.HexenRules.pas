{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loading of a level of Hexen                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.HexenRules;

interface

uses
  doomdata,
  r_defs,
  p_udmf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   What the loading of a level does only in Hexen: MAPINFO, the animations of p_anim and
  ///   the lava, the arguments of the lines, the sound sequences of the sectors, the list of the
  ///   thing ids, the corpses, the starts of a deathmatch and its timer, the fade table of the
  ///   map. Hexen has no polyobject reset, no ANIMDEFS of Libs\Definitions, no special 260
  /// </summary>
  THexenLevelRules = class(TInterfacedObject, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
  public
    // ILevelGameRules
    procedure InitializeData;
    procedure ShutDownData;
    function TracesSteps: Boolean;
    function MapName(AEpisode, AMap: Integer): string;
    procedure PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
    procedure ResetStatistics;
    procedure ClearLevelData;
    procedure AfterBlockmap;
    procedure AfterNodes(AMapLump: Integer);
    procedure BeforeThings;
    procedure AfterThings;
    procedure BeforeDeathmatchSpawn;
    procedure SpawnDeathmatchPlayer(APlayer: Integer);
    procedure AfterDeathmatchSpawn;
    procedure AfterSpecials;
    procedure AfterLevel;
    // ILevelGeometryRules
    procedure InitializeSector(ASector: Psector_t);
    procedure ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
    procedure FixLineDefs(AData: Pointer; ALumpSize, ACount: Integer);
    procedure ReadLineArguments(AMapLine: Pmaplinedef_t; ALine: Pline_t);
    procedure BeforeGroupLines;
    procedure MarkTransparentLines;
    function UsesInternalBlockCoordinates: Boolean;
    procedure AfterGroupLines;
    // ILevelThingRules
    procedure SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
    procedure AfterMapThingsSpawned;
    procedure AfterThingsLoaded;
  end;

implementation

uses
  d_delphi,
  doomdef,
  d_player,
  g_game,
  i_system,
  info_h,
  m_argv,
  m_fixed,
  p_mobj_h,
  p_mobj,
  p_tick,
  p_setup,
  p_spec,
  p_switch,
  p_enemy,
  p_mapinfo,
  p_anim,
  r_data,
  s_sound,
  s_sndseq,
  w_wad;

{ THexenLevelRules }

procedure THexenLevelRules.InitializeData;
begin
  P_InitMapInfo;
  P_InitSwitchList;
  P_InitAnimations;
  P_InitFTAnims; // Init flat and texture animations
  P_InitLava;
end;

procedure THexenLevelRules.ShutDownData;
begin
  P_ShutDownAnimations;
end;

function THexenLevelRules.TracesSteps: Boolean;
begin
  Result := False;
end;

function THexenLevelRules.MapName(AEpisode, AMap: Integer): string;
begin
  Result := P_GetMapName(AMap);
end;

procedure THexenLevelRules.PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
begin
  printf(#13#10'-----------------------'#13#10);
  printf('Loading %s (%s)'#13#10, [ALumpName, P_GetMapDescName(AMap)]);
end;

procedure THexenLevelRules.ResetStatistics;
var
  LPlayer: Integer;
begin
  totalkills := 0;
  totalitems := 0;
  totalsecret := 0;

  wminfo.maxfrags := 0;
  wminfo.partime := 180;

  for LPlayer := 0 to MAXPLAYERS - 1 do
  begin
    players[LPlayer].killcount := 0;
    players[LPlayer].secretcount := 0;
    players[LPlayer].itemcount := 0;
  end;
end;

procedure THexenLevelRules.ClearLevelData;
begin
end;

procedure THexenLevelRules.AfterBlockmap;
begin
end;

procedure THexenLevelRules.AfterNodes(AMapLump: Integer);
begin
end;

procedure THexenLevelRules.BeforeThings;
begin
end;

procedure THexenLevelRules.AfterThings;
begin
end;

procedure THexenLevelRules.BeforeDeathmatchSpawn;
begin
  TimerGame := 0;
end;

procedure THexenLevelRules.SpawnDeathmatchPlayer(APlayer: Integer);
var
  LMobj: Pmobj_t;
begin
  // a body at the start of the player while the random start is chosen
  LMobj := P_SpawnMobj(playerstarts[0][APlayer].x * FRACUNIT, playerstarts[0][APlayer].y * FRACUNIT, 0,
    Ord(MT_PLAYER_FIGHTER));
  players[APlayer].mo := LMobj;
  G_DeathMatchSpawnPlayer(APlayer);
  P_RemoveMobj(LMobj);
end;

procedure THexenLevelRules.AfterDeathmatchSpawn;
var
  LParameter: Integer;
begin
  LParameter := M_CheckParm('-timer');
  if (LParameter > 0) and (LParameter < myargc - 1) then
    TimerGame := atoi(myargv[LParameter + 1]) * TICRATE * 60;
end;

procedure THexenLevelRules.AfterSpecials;
begin
  R_ChangeColormap(W_GetNameForNum(P_GetMapFadeTable(gamemap)));
end;

procedure THexenLevelRules.AfterLevel;
begin
  // Check if the level is a lightning level
  P_InitLightning;
  S_StopAllSounds;
  S_StopAllSequences;
end;

procedure THexenLevelRules.InitializeSector(ASector: Psector_t);
begin
  ASector.seqType := SEQTYPE_STONE; // default seqType
end;

procedure THexenLevelRules.ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
begin
  ASide.toptexture := R_TextureNumForName(AMapSide.toptexture);
  ASide.bottomtexture := R_TextureNumForName(AMapSide.bottomtexture);
  ASide.midtexture := R_TextureNumForName(AMapSide.midtexture);
end;

procedure THexenLevelRules.FixLineDefs(AData: Pointer; ALumpSize, ACount: Integer);
begin
end;

procedure THexenLevelRules.ReadLineArguments(AMapLine: Pmaplinedef_t; ALine: Pline_t);
begin
  ALine.arg1 := AMapLine.arg1;
  ALine.arg2 := AMapLine.arg2;
  ALine.arg3 := AMapLine.arg3;
  ALine.arg4 := AMapLine.arg4;
  ALine.arg5 := AMapLine.arg5;
end;

procedure THexenLevelRules.BeforeGroupLines;
begin
end;

procedure THexenLevelRules.MarkTransparentLines;
begin
end;

function THexenLevelRules.UsesInternalBlockCoordinates: Boolean;
begin
  Result := True;
end;

procedure THexenLevelRules.AfterGroupLines;
begin
end;

procedure THexenLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
begin
  if P_GameValidThing(AThing._type) then // Do spawn all other stuff.
    P_SpawnMapThing(AThing, AExtra);
end;

procedure THexenLevelRules.AfterMapThingsSpawned;
begin
  P_CreateTIDList;
  P_InitCreatureCorpseQueue(False); // false = do NOT scan for corpses
end;

procedure THexenLevelRules.AfterThingsLoaded;
var
  LPlayer: Integer;
  LPlayerCount: Integer;
begin
  if deathmatch = 0 then
    Exit;

  LPlayerCount := 0;
  for LPlayer := 0 to MAXPLAYERS - 1 do
    if playeringame[LPlayer] then
      Inc(LPlayerCount);

  if deathmatch_p < LPlayerCount then
    I_Error('P_LoadThings(): Player count (%d) exceeds deathmatch spots (%d)', [LPlayerCount, deathmatch_p]);
end;

end.
