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
  doomdata,
  p_udmf,
  DelphiDoom.Engine.Level.Intf, DelphiDoom.Engine.Level.DoomRules;

type
  /// <summary>
  ///   A level of Radix is a map of Doom (the translation of RADIX.DAT writes it) followed by the
  ///   lumps of Radix. The rules are the ones of Doom, plus what the old P_SetupLevel of Rad-X did
  ///   with those lumps: for now RMAP (the sloped floors and ceilings and the angles of the flats),
  ///   read when the lines are grouped and the nodes are there. RTHINGS, RGRID, RMAPGRID, RACTION
  ///   and RTRIGGER are not read yet. A thing whose type has no definition (the actors of Radix
  ///   are not loaded yet) is not spawned: one line tells how many, instead of one warning each
  /// </summary>
  TRadixLevelRules = class(TDoomLevelRules, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
  strict private
    FMapLump: Integer;
    FUndefinedThings: Integer;
    class function IsSpawnedWithoutDefinition(AType: Integer): Boolean; static;
  public
    /// <summary>Remembers the lump of the map: the lumps of Radix are found from it</summary>
    procedure AfterNodes(AMapLump: Integer);
    procedure AfterGroupLines;
    procedure SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
    procedure AfterMapThingsSpawned;
  end;

implementation

uses
  d_delphi, info_common, radix_map_extra;

const
  // the place of RMAP after the lumps of a map of Doom (ML_RMAP of Rad-X)
  RADIX_MAP_INFO_OFFSET = Ord(ML_BLOCKMAP) + 1;
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

procedure TRadixLevelRules.AfterNodes(AMapLump: Integer);
begin
  FMapLump := AMapLump;
  FUndefinedThings := 0;
  inherited AfterNodes(AMapLump);
end;

procedure TRadixLevelRules.AfterGroupLines;
begin
  inherited AfterGroupLines;
  RX_LoadRadixMapInfo(RX_RadixLump(FMapLump + RADIX_MAP_INFO_OFFSET, RADIX_MAP_INFO_LUMP));
end;

procedure TRadixLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
begin
  if not IsSpawnedWithoutDefinition(AThing._type) and (Info_GetMobjNumForDoomNum(AThing._type) < 0) then
  begin
    Inc(FUndefinedThings);
    Exit;
  end;
  inherited SpawnMapThing(AThing, AExtra);
end;

procedure TRadixLevelRules.AfterMapThingsSpawned;
begin
  inherited AfterMapThingsSpawned;
  if FUndefinedThings > 0 then
    printf('TRadixLevelRules: %d things of the map have a type without definition and are not spawned'#13#10,
      [FUndefinedThings]);
end;

end.
