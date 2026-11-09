{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loading of a level of Doom                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.DoomRules;

interface

uses
  doomdata,
  r_defs,
  p_udmf,
  DelphiDoom.GameState.Intf,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Engine.Definitions.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   What the loading of a level does only in Doom: the switches of the lump SWITCHES, the
  ///   nodes and the block links of the old engine for the old demos, the fields of BOOM in the
  ///   sectors, the colormaps of the sides, the correction of the lines of the shareware E1M1
  ///   (flags over 511), the barrels drawn once and the steps printed with -devparm
  /// </summary>
  TDoomLevelRules = class(TInterfacedObject, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
  strict private
    FSwitches: IEngineSwitchListLoader;
    FAnimDefs: IEngineAnimDefsLoader;
    FVanillaNodes: ILevelVanillaNodes;
    FGame: IGameContext;
    FRandom: IGameRandom;
    procedure Trace(const AStep: string);
    class procedure HideDuplicateThings(AType: Integer); static;
  public
    /// <summary>
    ///   AGame says when the steps are printed (-devparm); ARandom gives the seed of the
    ///   random monsters that PrintLoading shows
    /// </summary>
    constructor Create(const ASwitches: IEngineSwitchListLoader; const AAnimDefs: IEngineAnimDefsLoader;
      const AVanillaNodes: ILevelVanillaNodes; const AGame: IGameContext;
      const ARandom: IGameRandom);
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
  d_think,
  g_game,
  info_h,
  p_mobj_h,
  p_mobj,
  p_tick,
  p_setup,
  udmf_spec,
  p_spec,
  po_man,
  z_zone,
  DelphiDoom.MathCore.Sha1,
  DelphiDoom.Engine.Level.TransparentLines,
  DelphiDoom.Engine.Level.ColormapLines;

const
  // the lines of E1M1 of the shareware 1.1 and of 1.2 to 1.9: the flags over 511 are cleared
  SHAREWARE_E1M1_LINES = 1764;
  SHAREWARE_E1M1_SHA1_12 = '86C7KC17C14E1B684A49A2481S9AA9LFB8FF4';
  SHAREWARE_E1M1_SHA1_11 = 'SAF04WA061FB7AF3E2BF5KC89349D25F5A9';

{ TDoomLevelRules }

constructor TDoomLevelRules.Create(const ASwitches: IEngineSwitchListLoader;
  const AAnimDefs: IEngineAnimDefsLoader; const AVanillaNodes: ILevelVanillaNodes;
  const AGame: IGameContext; const ARandom: IGameRandom);
begin
  inherited Create;
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  FRandom := ARandom;
  if not Assigned(ASwitches) then
    raise EArgumentNilException.Create('ASwitches');
  if not Assigned(AAnimDefs) then
    raise EArgumentNilException.Create('AAnimDefs');
  if not Assigned(AVanillaNodes) then
    raise EArgumentNilException.Create('AVanillaNodes');
  FSwitches := ASwitches;
  FAnimDefs := AAnimDefs;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  FVanillaNodes := AVanillaNodes;
  FGame := AGame;
end;

procedure TDoomLevelRules.Trace(const AStep: string);
begin
  if FGame.IsDeveloperMode then
    printf('  %s'#13#10, [AStep]);
end;

procedure TDoomLevelRules.InitializeData;
begin
  FSwitches.Load;
  P_InitPicAnims;
  FAnimDefs.Load; // Init flat and texture animations
end;

procedure TDoomLevelRules.ShutDownData;
begin
  FAnimDefs.Release;
end;

function TDoomLevelRules.TracesSteps: Boolean;
begin
  Result := True;
end;

function TDoomLevelRules.MapName(AEpisode, AMap: Integer): string;
begin
  Result := P_GetMapName(AEpisode, AMap);
end;

procedure TDoomLevelRules.PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
begin
  printf(#13#10'-------------'#13#10);
  printf('Loading %s'#13#10, [ALumpName]);
  if spawnrandommonsters then
    printf(' Random monsters seed=%d'#13#10, [FRandom.SystemSeed]);
end;

procedure TDoomLevelRules.ResetStatistics;
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
    players[LPlayer].lastsoundstepx := 0;
    players[LPlayer].lastsoundstepy := 0;
    players[LPlayer].lastbreath := 0;
  end;
end;

procedure TDoomLevelRules.ClearLevelData;
begin
  po_NumPolyobjs := 0;
  PolyBlockMap := nil;

  numvanillasegs := 0;
  vanillasegs := nil;

  numvanillasubsectors := 0;
  vanillasubsectors := nil;

  numvanillanodes := 0;
  vanillanodes := nil;

  hasvanillanodes := False;
end;

procedure TDoomLevelRules.AfterBlockmap;
var
  LCount: Integer;
begin
  Trace('P_InitVanillaBlockLinks');
  LCount := SizeOf(Pmobj_t) * bmapwidth * bmapheight;
  vanillablocklinks := Z_Malloc(LCount, PU_LEVEL, nil);
  ZeroMemory(vanillablocklinks, LCount);
end;

procedure TDoomLevelRules.AfterNodes(AMapLump: Integer);
begin
  if preparingdemoplayback and (G_PlayingEngineVersion < VERSION110) and (numlines < 32768) and
     (numsides < 32768) and not hasudmfdata then
    FVanillaNodes.Load(AMapLump);
end;

procedure TDoomLevelRules.BeforeThings;
begin
end;

procedure TDoomLevelRules.AfterThings;
begin
  Trace('PO_Init');
end;

procedure TDoomLevelRules.BeforeDeathmatchSpawn;
begin
end;

procedure TDoomLevelRules.SpawnDeathmatchPlayer(APlayer: Integer);
begin
  players[APlayer].mo := nil;
  G_DeathMatchSpawnPlayer(APlayer);
end;

procedure TDoomLevelRules.AfterDeathmatchSpawn;
begin
end;

procedure TDoomLevelRules.AfterSpecials;
begin
end;

procedure TDoomLevelRules.AfterLevel;
begin
  // Check if the level is a lightning level
  P_InitLightning;
end;

procedure TDoomLevelRules.InitializeSector(ASector: Psector_t);
begin
  ASector.lightninglightlevel := 255; // JVAL: 20220218 - Lightning
  ASector.touching_thinglist := nil;
  ASector.stairlock := 0;
  ASector.nextsec := -1; //jff 2/26/98 add fields to support locking out
  ASector.prevsec := -1; // stair retriggering until build completes
  ASector.floor_xoffs := 0;
  ASector.floor_yoffs := 0;
  ASector.ceiling_xoffs := 0;
  ASector.ceiling_yoffs := 0;
  ASector.heightsec := -1;
  ASector.floorlightsec := -1;   // sector used to get floor lighting
  ASector.topmap := -1;
  ASector.midmap := -1;
  ASector.bottommap := -1;
{$IFDEF OPENGL}
  ASector.floorlightlevel := ASector.lightlevel;
  ASector.ceilinglightlevel := ASector.lightlevel;
{$ENDIF}
  // killough 4/11/98 sector used to get ceiling lighting:
  ASector.ceilinglightsec := -1;
end;

procedure TDoomLevelRules.ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
begin
  TLevelColormapLines.ReadSideTextures(AMapSide, ASide);
end;

procedure TDoomLevelRules.FixLineDefs(AData: Pointer; ALumpSize, ACount: Integer);
var
  LSha1: string;
  LLine: Pmaplinedef_t;
  LIndex: Integer;
begin
  if ACount <> SHAREWARE_E1M1_LINES then
    Exit;
  LSha1 := strupper(readablestring(TSha1.ToRawString(TSha1.Calculate(AData^, ALumpSize))));
  if (LSha1 <> SHAREWARE_E1M1_SHA1_12) and (LSha1 <> SHAREWARE_E1M1_SHA1_11) then
    Exit;
  LLine := Pmaplinedef_t(AData);
  for LIndex := 0 to ACount - 1 do
  begin
    PWord(@LLine.flags)^ := PWord(@LLine.flags)^ and 511;
    Inc(LLine);
  end;
end;

procedure TDoomLevelRules.ReadLineArguments(AMapLine: Pmaplinedef_t; ALine: Pline_t);
begin
  ALine.tag := AMapLine.tag;
end;

procedure TDoomLevelRules.BeforeGroupLines;
var
  LIndex: Integer;
  LVanillaSeg: Pvanillaseg_t;
begin
  // look up sector number for each subsector - vanilla nodes
  if hasvanillanodes then
    for LIndex := 0 to numvanillasubsectors - 1 do
    begin
      LVanillaSeg := @vanillasegs[vanillasubsectors[LIndex].firstline];
      vanillasubsectors[LIndex].sector := LVanillaSeg.sidedef.sector;
    end;
end;

procedure TDoomLevelRules.MarkTransparentLines;
begin
  TLevelTransparentLines.Mark;
end;

function TDoomLevelRules.UsesInternalBlockCoordinates: Boolean;
begin
  // a blockmap read from the lump keeps the 32 bit arithmetic of the old engine
  Result := internalblockmapformat;
end;

procedure TDoomLevelRules.AfterGroupLines;
begin
  TLevelColormapLines.ApplyToSectors;
end;

procedure TDoomLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
begin
  if P_GameValidThing(AThing._type) then // Do spawn all other stuff.
    P_SpawnMapThing(AThing, AExtra);
end;

procedure TDoomLevelRules.AfterMapThingsSpawned;
begin
end;

class procedure TDoomLevelRules.HideDuplicateThings(AType: Integer);
var
  LIndex, LInner, LCount: Integer;
  LMobjs: Pmobj_tPArray;
  LThinker: Pthinker_t;
begin
  LCount := 0;
  LThinker := thinkercap.next;
  while LThinker <> @thinkercap do
  begin
    if @LThinker._function.acp1 = @P_MobjThinker then
      if Pmobj_t(LThinker)._type = AType then
        Inc(LCount);
    LThinker := LThinker.next;
  end;

  if LCount = 0 then
    Exit;

  LMobjs := Z_Malloc(LCount * SizeOf(Pmobj_t), PU_STATIC, nil);
  LIndex := 0;
  LThinker := thinkercap.next;
  while LThinker <> @thinkercap do
  begin
    if @LThinker._function.acp1 = @P_MobjThinker then
      if Pmobj_t(LThinker)._type = AType then
      begin
        LMobjs[LIndex] := Pmobj_t(LThinker);
        Inc(LIndex);
      end;
    LThinker := LThinker.next;
  end;

  for LIndex := 1 to LCount - 1 do
    for LInner := 0 to LIndex - 1 do
      if (LMobjs[LInner].x = LMobjs[LIndex].x) and
         (LMobjs[LInner].y = LMobjs[LIndex].y) and
         (LMobjs[LInner].z = LMobjs[LIndex].z) then
        LMobjs[LInner].flags2_ex := LMobjs[LInner].flags2_ex or MF2_EX_DONTDRAW;

  Z_Free(LMobjs);
end;

procedure TDoomLevelRules.AfterThingsLoaded;
begin
  if hidedoublicatedbarrels then
    HideDuplicateThings(Ord(MT_BARREL));
end;

end.
