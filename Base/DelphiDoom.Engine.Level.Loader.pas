{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loading of a level                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.Loader;

interface

uses
  doomdef,
  DelphiDoom.Console.Intf,
  DelphiDoom.GameState.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.MusInfo.Intf,
  DelphiDoom.Nodes.Intf,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   The loading of a level, in the order that most of the steps need: the text map and the
  ///   nodes are prepared, the lumps of the map are read (with the GL nodes, a GWA or the
  ///   nodes of the map), then the lines are grouped, the slopes, the 3d floors and the things
  ///   are set up, the specials spawned and the graphics precached. The composition root gives
  ///   the readers of the lumps, the nodes, the blockmap, the text maps, MUSINFO and the rules
  ///   of the game. It was P_SetupLevel, P_Init and P_ShutDown of p_setup.pas
  /// </summary>
  TLevelLoader = class(TInterfacedObject, ILevelLoader)
  strict private
    FGame: IGameContext;
    FRules: ILevelGameRules;
    FMap: ILevelMapReader;
    FThings: ILevelThings;
    FNodes: ILevelNodes;
    FBlockmap: ILevelBlockmap;
    FUdmf: ILevelUdmf;
    FMusInfo: IMusInfoLoader;
    FCommands: ICommandRegistry;
    FRandom: IGameRandom;
    FLumps: IEngineLumps;
    FZone: IZoneAllocator;
    procedure Trace(const AStep: string);
    procedure ResetLevel;
    function FindNodes(AMapLump: Integer; const AMapName: string): INodesGwa;
    procedure LoadVertexes(AMapLump: Integer; const AGwa: INodesGwa);
    procedure LoadNodes(AMapLump: Integer; const AGwa: INodesGwa);
    procedure SetupGeometry;
    procedure SpawnThings(AMapLump: Integer);
    procedure SpawnDeathmatchPlayers;
    procedure FinishLevel;
  public
    /// <summary>
    ///   AGame says when the steps are printed (-devparm); ARules is the class of the game;
    ///   ACommands gets the console commands of the level; ARandom gives the seed of the
    ///   random monsters; ALumps finds the label of the map and reloads the development maps,
    ///   AZone frees the memory of the previous level
    /// </summary>
    constructor Create(const AGame: IGameContext; const ARules: ILevelGameRules;
      const AMap: ILevelMapReader; const AThings: ILevelThings; const ANodes: ILevelNodes;
      const ABlockmap: ILevelBlockmap; const AUdmf: ILevelUdmf; const AMusInfo: IMusInfoLoader;
      const ACommands: ICommandRegistry; const ARandom: IGameRandom;
      const ALumps: IEngineLumps; const AZone: IZoneAllocator);
    procedure Initialize;
    procedure ShutDown;
    procedure SetupLevel(AEpisode, AMap, APlayerMask: Integer; ASkill: skill_t);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  doomdata,
  doomstat,
  d_player,
  g_game,
  i_system,
  info,
  p_local,
  p_mobj_h,
  p_mobj,
  p_setup,
  p_tick,
  p_spec,
  p_inter,
  p_maputl,
  p_adjust,
  p_bridge,
  p_acs,
  p_3dfloors,
  p_slopes,
  p_easyangle,
  p_easywind,
  p_affectees,
  p_udmf,
  po_man,
  ps_main,
  r_data,
  r_things,
  mt_utils,
{$IFNDEF OPENGL}
  r_cache_main,
  r_segs2,
{$ENDIF}
  r_intrpl,
{$IFDEF OPENGL}
  gl_setup,
  gl_render,
{$ENDIF}
  r_subsectors,
  nd_main,
  s_sound,
  DelphiDoom.Zone.Types;

{ TLevelLoader }

constructor TLevelLoader.Create(const AGame: IGameContext; const ARules: ILevelGameRules;
  const AMap: ILevelMapReader; const AThings: ILevelThings; const ANodes: ILevelNodes;
  const ABlockmap: ILevelBlockmap; const AUdmf: ILevelUdmf; const AMusInfo: IMusInfoLoader;
  const ACommands: ICommandRegistry; const ARandom: IGameRandom; const ALumps: IEngineLumps;
  const AZone: IZoneAllocator);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(AZone) then
    raise EArgumentNilException.Create('AZone');
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  if not Assigned(ARules) then
    raise EArgumentNilException.Create('ARules');
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  if not Assigned(AThings) then
    raise EArgumentNilException.Create('AThings');
  if not Assigned(ANodes) then
    raise EArgumentNilException.Create('ANodes');
  if not Assigned(ABlockmap) then
    raise EArgumentNilException.Create('ABlockmap');
  if not Assigned(AUdmf) then
    raise EArgumentNilException.Create('AUdmf');
  if not Assigned(AMusInfo) then
    raise EArgumentNilException.Create('AMusInfo');
  if not Assigned(ACommands) then
    raise EArgumentNilException.Create('ACommands');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FGame := AGame;
  FRules := ARules;
  FMap := AMap;
  FThings := AThings;
  FNodes := ANodes;
  FBlockmap := ABlockmap;
  FUdmf := AUdmf;
  FMusInfo := AMusInfo;
  FCommands := ACommands;
  FRandom := ARandom;
  FLumps := ALumps;
  FZone := AZone;
end;

procedure TLevelLoader.Trace(const AStep: string);
begin
  if FRules.TracesSteps and FGame.IsDeveloperMode then
    printf('  %s'#13#10, [AStep]);
end;

procedure TLevelLoader.Initialize;
begin
  FRules.InitializeData;
  R_InitSprites(sprnames);
  FMusInfo.Load;
  // the commands have always been called with both parameters, whatever their own declaration
  FCommands.Add('suicide',
    procedure(const AParameter1, AParameter2: string)
    begin
      P_CmdSuicide;
    end);
  FCommands.Add('doadjustmissingtextures',
    procedure(const AParameter1, AParameter2: string)
    begin
      P_AdjustMissingTextures;
    end);
end;

procedure TLevelLoader.ShutDown;
begin
  FRules.ShutDownData;
end;

procedure TLevelLoader.ResetLevel;
begin
  FRules.ResetStatistics;

  isgamefreezed := False;

  if not preparingdemoplayback then
    FRandom.SystemSeed := FRandom.NextUnpredictable;

  // Initial height of PointOfView will be set by player think.
  players[consoleplayer].viewz := 1;

  // Make sure all sounds are stopped before Z_FreeTags.
  Trace('S_Start');
  S_Start;

{$IFDEF OPENGL}
  gld_CleanMemory; // JVAL OPENGL
{$ENDIF}

  Trace('MT_WaitTasks');
  MT_WaitTasks;

  Trace('Z_FreeTags');
  FZone.FreeTags(ZONE_TAG_LEVEL, ZONE_TAG_PURGELEVEL - 1);

  FRules.ClearLevelData;

  Trace('R_SetupLevel');
  R_SetupLevel;

  Trace('P_InitThinkers');
  P_InitThinkers;
  Trace('P_InitIntercepts');
  P_InitIntercepts;

  // if working with a devlopment map, reload it
  Trace('W_Reload');
  FLumps.Reload;
end;

function TLevelLoader.FindNodes(AMapLump: Integer; const AMapName: string): INodesGwa;
var
  LGlNodesLoaded: Boolean;
begin
  LGlNodesLoaded := False;
{$IFDEF OPENGL}
  if useglnodesifavailable and not G_NeedsCompatibilityMode and not hasudmfdata then
  begin
    glmapnum := FNodes.FindGlMapLump(AMapLump);
    glnodesver := FNodes.DetectGlNodesVersion(glmapnum);
    LGlNodesLoaded := glnodesver > 0;
  end
  else
  begin
    glmapnum := -1;
    glnodesver := 0;
  end;
{$ENDIF}

  leveltime := 0;

  Result := nil;
  if not LGlNodesLoaded then
  begin
    Trace('ND_GetNodes');
    Result := FNodes.FindGwa(AMapName);
  end;
end;

procedure TLevelLoader.LoadVertexes(AMapLump: Integer; const AGwa: INodesGwa);
begin
  if AGwa <> nil then
    FNodes.LoadVertexes(AMapLump + Ord(ML_VERTEXES), AGwa)
  else
{$IFDEF OPENGL}
    P_GLLoadVertexes(AMapLump + Ord(ML_VERTEXES), glmapnum + Ord(ML_GL_VERTS));
{$ELSE}
    FMap.LoadVertexes(AMapLump + Ord(ML_VERTEXES));
{$ENDIF}
end;

procedure TLevelLoader.LoadNodes(AMapLump: Integer; const AGwa: INodesGwa);
{$IFDEF OPENGL}
var
  LGlMapName: string;
{$ENDIF}
begin
{$IFDEF OPENGL}
  if (glnodesver > 0) and (glmapnum <> - 1) then
  begin
    LGlMapName := FLumps.NameOf(glmapnum);
    printf(' GL nodes v%d found (%s)'#13#10, [glnodesver, LGlMapName]);
    if glnodesver >= 3 then
      P_LoadSubsectorsV3V5(glmapnum + Ord(ML_GL_SSECT))
    else
      FMap.LoadSubsectors(glmapnum + Ord(ML_GL_SSECT));
    if glnodesver >= 4 then
      P_LoadNodesV4V5(glmapnum + Ord(ML_GL_NODES))
    else
      FMap.LoadNodes(glmapnum + Ord(ML_GL_NODES));
    P_LoadGLSegs(glmapnum + Ord(ML_GL_SEGS));
    Exit;
  end;
{$ENDIF}

  if AGwa <> nil then
  begin
    FNodes.LoadSubsectors(AGwa);
    FNodes.LoadNodes(AGwa);
    FNodes.LoadSegs(AGwa);
    Exit;
  end;

{$IFDEF OPENGL}
  printf(' GL nodes not found, using standard nodes'#13#10);
{$ENDIF}
  Trace('P_LoadSubsectors');
  FMap.LoadSubsectors(AMapLump + Ord(ML_SSECTORS));
  Trace('P_LoadNodes');
  FMap.LoadNodes(AMapLump + Ord(ML_NODES));
  Trace('P_LoadSegs');
  FMap.LoadSegs(AMapLump + Ord(ML_SEGS));
end;

procedure TLevelLoader.SetupGeometry;
begin
  Trace('UDMF_MakeLines');
  FUdmf.ApplyLines;
  Trace('P_GroupLines');
  FMap.GroupLines;

  Trace('UDMF_MakeSegs');
  FUdmf.ApplySegs;

  Trace('P_3dFloorSetupSegs');
  P_3dFloorSetupSegs; // JVAL: 3d Floors

  Trace('P_RemoveSlimeTrails');
  FBlockmap.RemoveSlimeTrails; // killough 10/98: remove slime trails from wad

{$IFNDEF OPENGL}
  Trace('R_CalcSectors');
  R_CalcSectors; // JVAL 20200105 - Check the map boundaries
  Trace('R_PrecalcSegs');
  R_PrecalcSegs; // https://www.doomworld.com/forum/topic/70288-dynamic-wiggletall-sector-fix-for-fixed-point-software-renderer/?do=findComment&comment=1340433
{$ENDIF}

  Trace('P_SlopesSetup');
  P_SlopesSetup; // JVAL: Slopes

  Trace('UDMF_MakeSectors');
  FUdmf.ApplySectors;

  Trace('P_SetupSectorAffectees');
  P_SetupSectorAffectees;

  if autoadjustmissingtextures then
    P_AdjustMissingTextures;

  Trace('P_CalcSubSectorsBridge');
  P_CalcSubSectorsBridge;

  Trace('R_PrecalcPointInSubSector');
  R_PrecalcPointInSubSector;
end;

procedure TLevelLoader.SpawnDeathmatchPlayers;
var
  LPlayer: Integer;
begin
  // if deathmatch, randomly spawn the active players
  FRules.BeforeDeathmatchSpawn;
  if deathmatch = 0 then
    Exit;

  for LPlayer := 0 to MAXPLAYERS - 1 do
    if playeringame[LPlayer] then
      FRules.SpawnDeathmatchPlayer(LPlayer);
  FRules.AfterDeathmatchSpawn;
end;

procedure TLevelLoader.SpawnThings(AMapLump: Integer);
begin
  bodyqueslot := 0;
  po_NumPolyobjs := 0;
  deathmatch_p := 0;
  FRules.BeforeThings;

  if FGame.IsDeveloperMode then
    printf('P_LoadThings()'#13#10);
  FThings.Load(AMapLump + Ord(ML_THINGS));

  // JVAL: 20201229 - Easy floor and ceiling texture angle
  P_AdjustEasyAngle;

  // JVAL: 20220222 - Easy wind
  P_AdjustEasyWind;

  FRules.AfterThings;
  PO_Init(AMapLump + Ord(ML_THINGS)); // Initialize the polyobjs
  Trace('P_LoadACScripts');
  P_LoadACScripts(AMapLump + Ord(ML_BEHAVIOR)); // ACS object code

  SpawnDeathmatchPlayers;

  // clear special respawning que
  iquehead := 0;
  iquetail := 0;
end;

procedure TLevelLoader.FinishLevel;
begin
  // set up world state
  if FGame.IsDeveloperMode then
    printf('P_SpawnSpecials()'#13#10);
  Trace('P_SpawnSpecials');
  P_SpawnSpecials;
  FRules.AfterSpecials;

{$IFNDEF OPENGL}
  if FGame.IsDeveloperMode then
    printf('R_Clear32Cache()'#13#10);
  Trace('R_Clear32Cache');
  R_Clear32Cache;
{$ENDIF}

  // preload graphics
  // JVAL
  // Precache if we have external textures
  if precache or externalpakspresent then
  begin
    if FGame.IsDeveloperMode then
      printf('R_PrecacheLevel()'#13#10);
    Trace('R_PrecacheLevel');
    R_PrecacheLevel;
    if FGame.IsDeveloperMode then
      printf('S_PrecacheSounds()'#13#10);
    Trace('S_PrecacheSounds');
    S_PrecacheSounds;
  end;

{$IFDEF OPENGL}
  if FGame.IsDeveloperMode then
    printf('gld_PreprocessLevel()'#13#10);
  gld_PreprocessLevel; // JVAL OPENGL
{$ENDIF}

  R_SetInterpolateSkipTicks(2);

  FRules.AfterLevel;
end;

procedure TLevelLoader.SetupLevel(AEpisode, AMap, APlayerMask: Integer; ASkill: skill_t);
var
  LMapName: string;
  LMapLump: Integer;
  LGwa: INodesGwa;
begin
  ResetLevel;

  // find map name
  LMapName := FRules.MapName(AEpisode, AMap);
  FRules.PrintLoading(LMapName, AEpisode, AMap);

  Trace('UDMF_Check');
  FUdmf.Prepare(LMapName);
  Trace('ND_NodesCheck');
  FNodes.CheckNodes(LMapName);
  Trace('PS_LinkScriptEvents');
  PS_LinkScriptEvents(LMapName); // JVAL: Script Events

  Trace('W_GetNumForName');
  LMapLump := FLumps.GetNumForName(LMapName);

  LGwa := FindNodes(LMapLump, LMapName);

  // note: most of this ordering is important
  LoadVertexes(LMapLump, LGwa);
  Trace('P_LoadSectors');
  FMap.LoadSectors(LMapLump + Ord(ML_SECTORS));
  Trace('P_LoadSideDefs');
  FMap.LoadSideDefs(LMapLump + Ord(ML_SIDEDEFS));
  Trace('UDMF_MakeSides');
  FUdmf.ApplySides;
  Trace('P_LoadLineDefs');
  FMap.LoadLineDefs(LMapLump + Ord(ML_LINEDEFS));
  Trace('P_LoadBlockMap');
  FBlockmap.Load(LMapLump + Ord(ML_BLOCKMAP));
  FRules.AfterBlockmap;
  LoadNodes(LMapLump, LGwa);
  LGwa := nil;
  FRules.AfterNodes(LMapLump);

  FMap.LoadReject(LMapLump + Ord(ML_REJECT));

  SetupGeometry;
  SpawnThings(LMapLump);
  FinishLevel;
end;

end.
