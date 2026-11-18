{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Radix for the loading of a level          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit DelphiDoom.Engine.Level.RadixRules;

interface

uses
  System.SysUtils,
  doomdata,
  p_udmf,
  DelphiDoom.Radix.Level.Types,
  DelphiDoom.Engine.Level.Intf, DelphiDoom.Engine.Level.DoomRules;

type
  /// <summary>
  ///   A level of Radix is a map of Doom (the translation of RADIX.DAT writes it) followed by the
  ///   lumps of Radix. The rules are the ones of Doom, plus what the old P_SetupLevel of Rad-X did
  ///   with those lumps: RMAP (the sloped floors and ceilings and the angles of the flats), read
  ///   when the lines are grouped and the nodes are there; RTHINGS (the height, the skill and the
  ///   number of every thing), read before the things are spawned; RGRID, RMAPGRID, RACTION and
  ///   RTRIGGER (the triggers and the actions of the level), read after them.
  ///   A thing of Radix is spawned through the extra data that the engine has for the things of a
  ///   text map: its height above the floor, and its number of RADIX.DAT as the identifier of the
  ///   mobj (the actions of the level name the enemies with it).
  ///   A thing whose type has no definition is not spawned: one line tells how many, instead of
  ///   one warning each
  /// </summary>
  TRadixLevelRules = class(TDoomLevelRules, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
  strict private
    FMapLump: Integer;
    FUndefinedThings: Integer;
    FThingIndex: Integer;
    FThingExtras: TArray<TRadixDoomThingExtra>;
    class function IsSpawnedWithoutDefinition(AType: Integer): Boolean; static;
    class function IsPlayerStart(AType: Integer): Boolean; static;
    procedure SpawnRadixThing(AThing: Pmapthing_t; const ARadix: TRadixDoomThingExtra);
  public
    /// <summary>Remembers the lump of the map: the lumps of Radix are found from it</summary>
    procedure AfterNodes(AMapLump: Integer);
    procedure AfterGroupLines;
    procedure SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
    procedure AfterMapThingsSpawned;
  end;

implementation

uses
  d_delphi, g_game, info_common, m_fixed, p_mobj_h, p_mobj, p_setup, r_main, w_wad,
  radix_map_extra, radix_pilot, radix_pickups, radix_logic, radix_briefing,
  DelphiDoom.Radix.Thing.Spawn;

const
  // the place of the last lump of a map of Doom: the lumps of Radix follow it (ML_RMAP... of Rad-X)
  LAST_DOOM_LUMP_OFFSET = Ord(ML_BLOCKMAP);
  RADIX_MAP_INFO_LUMP = 'RMAP';
  // the starts of the players and of the deathmatch, and the music changers, have no mobjinfo
  LAST_PLAYER_START = 4;
  DEATHMATCH_START = 11;
  FIRST_MUSIC_CHANGER = 14100;
  LAST_MUSIC_CHANGER = 14164;

{ TRadixLevelRules }

class function TRadixLevelRules.IsSpawnedWithoutDefinition(AType: Integer): Boolean;
begin
  Result := (AType <= LAST_PLAYER_START) or (AType = DEATHMATCH_START) or
    ((AType >= FIRST_MUSIC_CHANGER) and (AType <= LAST_MUSIC_CHANGER));
end;

class function TRadixLevelRules.IsPlayerStart(AType: Integer): Boolean;
begin
  Result := (AType >= 1) and (AType <= LAST_PLAYER_START);
end;

procedure TRadixLevelRules.AfterNodes(AMapLump: Integer);
var
  LThingCount: Integer;
begin
  FMapLump := AMapLump;
  FUndefinedThings := 0;
  FThingIndex := 0;
  totalradixkills := 0;
  // RTHINGS goes with THINGS record by record: another count is not the data of this map
  FThingExtras := RX_ReadThingExtras(FMapLump + LAST_DOOM_LUMP_OFFSET);
  LThingCount := W_LumpLength(FMapLump + Ord(ML_THINGS)) div SizeOf(mapthing_t);
  if Length(FThingExtras) <> LThingCount then
    FThingExtras := nil;
  // before the things of the map are spawned: the pickups of Radix must not be the ones of Doom
  RX_InitActors;
  inherited AfterNodes(AMapLump);
end;

procedure TRadixLevelRules.AfterGroupLines;
begin
  inherited AfterGroupLines;
  RX_LoadRadixMapInfo(RX_RadixLump(FMapLump + LAST_DOOM_LUMP_OFFSET + RADIX_LUMP_RMAP, RADIX_MAP_INFO_LUMP));
end;

procedure TRadixLevelRules.SpawnRadixThing(AThing: Pmapthing_t; const ARadix: TRadixDoomThingExtra);
var
  LExtra: extrathing_t;
  LIsPlayer: Boolean;
  LMobj: Pmobj_t;
begin
  LIsPlayer := IsPlayerStart(AThing._type);
  // the skill of RADIX.DAT takes the place of the skill flags of Doom; a craft is always there
  if not LIsPlayer and
    not TRadixThingSpawnRules.IsSpawnedAtSkill(ARadix.RadixSkill, Ord(TGameSession.GameSkill), TGameSession.NetGame) then
    Exit;
  if not P_GameValidThing(AThing._type) then
    Exit;

  ZeroMemory(@LExtra, SizeOf(LExtra));
  LExtra.extraflags := UDMF_TF_SKILL_MASK or UDMF_TF_SINGLE or UDMF_TF_DM or UDMF_TF_COOP or UDMF_TF_HASZ;
  LExtra.x := AThing.x * FRACUNIT;
  LExtra.y := AThing.y * FRACUNIT;
  LExtra.z := TRadixThingSpawnRules.Height(ARadix.Z,
    TRendererMain.R_PointInSubsector(LExtra.x, LExtra.y).sector.floorheight, LIsPlayer);
  LExtra.id := TRadixThingSpawnRules.ThingId(ARadix.RadixId);

  LMobj := P_SpawnMapThing(AThing, @LExtra);
  if Assigned(LMobj) and not Assigned(LMobj.player) and (LMobj.flags and MF_COUNTKILL <> 0) then
    Inc(totalradixkills);
end;

procedure TRadixLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
var
  LIndex: Integer;
begin
  LIndex := FThingIndex;
  Inc(FThingIndex);
  if not IsSpawnedWithoutDefinition(AThing._type) and (Info_GetMobjNumForDoomNum(AThing._type) < 0) then
  begin
    Inc(FUndefinedThings);
    Exit;
  end;
  if not Assigned(AExtra) and (LIndex < Length(FThingExtras)) then
    SpawnRadixThing(AThing, FThingExtras[LIndex])
  else
    inherited SpawnMapThing(AThing, AExtra);
end;

procedure TRadixLevelRules.AfterMapThingsSpawned;
begin
  inherited AfterMapThingsSpawned;
  FThingExtras := nil;
  RX_SpawnPilotThinker;
  // after the thinker of the crafts: the transporters of the level have the last word on a craft
  RX_LoadLevelLogic(FMapLump + LAST_DOOM_LUMP_OFFSET);
  if FUndefinedThings > 0 then
    printf('TRadixLevelRules: %d things of the map have a type without definition and are not spawned'#13#10,
      [FUndefinedThings]);
  // the mission briefing comes before the level (it draws the map of the level just loaded)
  RB_LevelLoaded(TGameSession.GameEpisode, TGameSession.GameMap);
end;

end.
