{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loading of a level of Strife                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.StrifeRules;

interface

uses
  doomdata,
  r_defs,
  p_udmf,
  DelphiDoom.Engine.Definitions.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   What the loading of a level does only in Strife: the allegiance of the players, the
  ///   spots of the rifts (things 118..127, haleyjd 08/24/10), the fields of BOOM in the
  ///   sectors and the colormaps of the sides; Strife has no count of the items
  /// </summary>
  TStrifeLevelRules = class(TInterfacedObject, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
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
  p_animdefs,
  po_man,
  DelphiDoom.Engine.Level.TransparentLines,
  DelphiDoom.Engine.Level.ColormapLines;

const
  // haleyjd 08/24/2010: the things that mark the spots of the rifts
  FIRST_RIFT_THING = 118;
  LAST_RIFT_THING = 127;
  // STRIFE-TODO: mystery array of 90xx objects
  FIRST_MYSTERY_THING = 9001;
  LAST_MYSTERY_THING = 9010;

{ TStrifeLevelRules }

constructor TStrifeLevelRules.Create(const AAnimDefs: IEngineAnimDefsLoader);
begin
  inherited Create;
  if not Assigned(AAnimDefs) then
    raise EArgumentNilException.Create('AAnimDefs');
  FAnimDefs := AAnimDefs;
end;

procedure TStrifeLevelRules.InitializeData;
begin
  P_InitSwitchList;
  P_InitPicAnims;
  P_InitAnimations;
  FAnimDefs.Load; // Init flat and texture animations
end;

procedure TStrifeLevelRules.ShutDownData;
begin
  P_ShutDownAnimations;
end;

function TStrifeLevelRules.TracesSteps: Boolean;
begin
  Result := False;
end;

function TStrifeLevelRules.MapName(AEpisode, AMap: Integer): string;
begin
  Result := P_GetMapName(AMap);
end;

procedure TStrifeLevelRules.PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
begin
  printf(#13#10'-------------'#13#10);
  printf('Loading %s'#13#10, [ALumpName]);
  if spawnrandommonsters then
    printf(' Random monsters seed=%d'#13#10, [M_GetSystemRandomSeed]);
end;

procedure TStrifeLevelRules.ResetStatistics;
var
  LPlayer: Integer;
begin
  totalkills := 0;
  totalsecret := 0;

  for LPlayer := 0 to MAXPLAYERS - 1 do
  begin
    players[LPlayer].allegiance := LPlayer;
    players[LPlayer].killcount := 0;
    players[LPlayer].lastbreath := 0;
  end;
end;

procedure TStrifeLevelRules.ClearLevelData;
begin
  po_NumPolyobjs := 0;
  PolyBlockMap := nil;
end;

procedure TStrifeLevelRules.AfterBlockmap;
begin
end;

procedure TStrifeLevelRules.AfterNodes(AMapLump: Integer);
begin
end;

procedure TStrifeLevelRules.BeforeThings;
begin
end;

procedure TStrifeLevelRules.AfterThings;
begin
end;

procedure TStrifeLevelRules.BeforeDeathmatchSpawn;
begin
end;

procedure TStrifeLevelRules.SpawnDeathmatchPlayer(APlayer: Integer);
begin
  players[APlayer].mo := nil;
  G_DeathMatchSpawnPlayer(APlayer);
end;

procedure TStrifeLevelRules.AfterDeathmatchSpawn;
begin
end;

procedure TStrifeLevelRules.AfterSpecials;
begin
end;

procedure TStrifeLevelRules.AfterLevel;
begin
  // Check if the level is a lightning level
  P_InitLightning;
end;

procedure TStrifeLevelRules.InitializeSector(ASector: Psector_t);
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

procedure TStrifeLevelRules.ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
begin
  TLevelColormapLines.ReadSideTextures(AMapSide, ASide);
end;

procedure TStrifeLevelRules.FixLineDefs(AData: Pointer; ALumpSize, ACount: Integer);
begin
end;

procedure TStrifeLevelRules.ReadLineArguments(AMapLine: Pmaplinedef_t; ALine: Pline_t);
begin
  ALine.tag := AMapLine.tag;
end;

procedure TStrifeLevelRules.BeforeGroupLines;
begin
end;

procedure TStrifeLevelRules.MarkTransparentLines;
begin
  TLevelTransparentLines.Mark;
end;

function TStrifeLevelRules.UsesInternalBlockCoordinates: Boolean;
begin
  Result := True;
end;

procedure TStrifeLevelRules.AfterGroupLines;
begin
  TLevelColormapLines.ApplyToSectors;
end;

procedure TStrifeLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
var
  LRift: Integer;
begin
  if (AThing._type >= FIRST_RIFT_THING) and (AThing._type <= LAST_RIFT_THING) then
  begin
    // initialize riftSpots
    LRift := AThing._type - FIRST_RIFT_THING;
    AThing._type := 1;
    riftSpots[LRift] := AThing^;
  end
  else if (AThing._type >= FIRST_MYSTERY_THING) and (AThing._type <= LAST_MYSTERY_THING) then
  begin
    // STRIFE-TODO: mystery array of 90xx objects
  end
  else if P_GameValidThing(AThing._type) then // Do spawn all other stuff.
    P_SpawnMapThing(AThing, AExtra);
end;

procedure TStrifeLevelRules.AfterMapThingsSpawned;
begin
end;

procedure TStrifeLevelRules.AfterThingsLoaded;
begin
end;

end.
