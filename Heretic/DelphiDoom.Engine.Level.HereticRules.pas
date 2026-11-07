{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loading of a level of Heretic                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.HereticRules;

interface

uses
  doomdata,
  r_defs,
  p_udmf,
  DelphiDoom.Engine.Definitions.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   What the loading of a level does only in Heretic: the title of the map, the ambient
  ///   sounds, the monsters and the weapons placed in the map, the textures of the sides
  ///   without colormaps
  /// </summary>
  THereticLevelRules = class(TInterfacedObject, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
  strict private
    FAnimDefs: IEngineAnimDefsLoader;
  public
    constructor Create(const AAnimDefs: IEngineAnimDefsLoader);
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
  System.SysUtils,
  d_delphi,
  doomdef,
  doomstat,
  d_player,
  g_game,
  m_rnd,
  p_mobj_h,
  p_mobj,
  p_setup,
  udmf_spec,
  p_spec,
  p_switch,
  p_ambient,
  p_enemy,
  p_pspr,
  p_animdefs,
  po_man,
  r_data,
  DelphiDoom.Engine.Level.TransparentLines;

{ THereticLevelRules }

constructor THereticLevelRules.Create(const AAnimDefs: IEngineAnimDefsLoader);
begin
  inherited Create;
  if not Assigned(AAnimDefs) then
    raise EArgumentNilException.Create('AAnimDefs');
  FAnimDefs := AAnimDefs;
end;

procedure THereticLevelRules.InitializeData;
begin
  P_InitSwitchList;
  P_InitPicAnims;
  P_InitAnimations;
  FAnimDefs.Load; // Init flat and texture animations
end;

procedure THereticLevelRules.ShutDownData;
begin
  P_ShutDownAnimations;
end;

function THereticLevelRules.TracesSteps: Boolean;
begin
  Result := False;
end;

function THereticLevelRules.MapName(AEpisode, AMap: Integer): string;
begin
  Result := P_GetMapName(AEpisode, AMap);
end;

procedure THereticLevelRules.PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
begin
  printf(#13#10'-------------'#13#10);
  printf('Loading %s (%s)'#13#10, [ALumpName, P_GetMapTitle(AEpisode, AMap)]);
  if spawnrandommonsters then
    printf(' Random monsters seed=%d'#13#10, [M_GetSystemRandomSeed]);
end;

procedure THereticLevelRules.ResetStatistics;
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

procedure THereticLevelRules.ClearLevelData;
begin
  po_NumPolyobjs := 0;
  PolyBlockMap := nil;
end;

procedure THereticLevelRules.AfterBlockmap;
begin
end;

procedure THereticLevelRules.AfterNodes(AMapLump: Integer);
begin
end;

procedure THereticLevelRules.BeforeThings;
begin
  P_InitAmbientSound;
  P_InitMonsters;
  P_OpenWeapons;
end;

procedure THereticLevelRules.AfterThings;
begin
  P_CloseWeapons;
end;

procedure THereticLevelRules.BeforeDeathmatchSpawn;
begin
end;

procedure THereticLevelRules.SpawnDeathmatchPlayer(APlayer: Integer);
begin
  players[APlayer].mo := nil;
  G_DeathMatchSpawnPlayer(APlayer);
end;

procedure THereticLevelRules.AfterDeathmatchSpawn;
begin
end;

procedure THereticLevelRules.AfterSpecials;
begin
end;

procedure THereticLevelRules.AfterLevel;
begin
  // Check if the level is a lightning level
  P_InitLightning;
end;

procedure THereticLevelRules.InitializeSector(ASector: Psector_t);
begin
  ASector.lightninglightlevel := 255; // JVAL: 20220218 - Lightning
end;

procedure THereticLevelRules.ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
begin
  ASide.toptexture := R_TextureNumForName(AMapSide.toptexture);
  ASide.bottomtexture := R_TextureNumForName(AMapSide.bottomtexture);
  ASide.midtexture := R_TextureNumForName(AMapSide.midtexture);
end;

procedure THereticLevelRules.FixLineDefs(AData: Pointer; ALumpSize, ACount: Integer);
begin
end;

procedure THereticLevelRules.ReadLineArguments(AMapLine: Pmaplinedef_t; ALine: Pline_t);
begin
  ALine.tag := AMapLine.tag;
end;

procedure THereticLevelRules.BeforeGroupLines;
begin
end;

procedure THereticLevelRules.MarkTransparentLines;
begin
  TLevelTransparentLines.Mark;
end;

function THereticLevelRules.UsesInternalBlockCoordinates: Boolean;
begin
  Result := True;
end;

procedure THereticLevelRules.AfterGroupLines;
begin
end;

procedure THereticLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
begin
  if P_GameValidThing(AThing._type) then // Do spawn all other stuff.
    P_SpawnMapThing(AThing, AExtra);
end;

procedure THereticLevelRules.AfterMapThingsSpawned;
begin
end;

procedure THereticLevelRules.AfterThingsLoaded;
begin
end;

end.
