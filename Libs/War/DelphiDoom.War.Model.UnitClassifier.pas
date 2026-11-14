{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what kind of unit a unit type is                  }
{                                                                              }
{  Port of war1 (acoto87/war1), the wu_is*UnitType functions, wu_getUnitType-  }
{  Race and wu_getUnitTypeForRace of war_units.c, (c) 2019 Alejandro Coto      }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitClassifier;

interface

uses
  DelphiDoom.War.Level.Types;

type
  /// <summary>
  ///   The classification of the unit types. The functions are static and use sets: the loops of the states call them
  ///   for every unit at every tic, so there is no object and no interface in between
  /// </summary>
  TWarUnitClassifier = class
  public
    class function IsDude(AType: Integer): Boolean; static;
    class function IsBuilding(AType: Integer): Boolean; static;
    class function IsWorker(AType: Integer): Boolean; static;
    class function IsWarrior(AType: Integer): Boolean; static;
    class function IsRange(AType: Integer): Boolean; static;
    class function IsMelee(AType: Integer): Boolean; static;
    class function IsFist(AType: Integer): Boolean; static;
    class function IsSword(AType: Integer): Boolean; static;
    class function IsMagic(AType: Integer): Boolean; static;
    class function IsCorpse(AType: Integer): Boolean; static;
    class function IsCatapult(AType: Integer): Boolean; static;
    class function IsConjurerOrWarlock(AType: Integer): Boolean; static;
    class function IsClericOrNecrolyte(AType: Integer): Boolean; static;
    class function IsSummon(AType: Integer): Boolean; static;
    class function IsSkeleton(AType: Integer): Boolean; static;
    /// <summary>wu_getUnitTypeRace: the race that has the unit type (neutral for the rest)</summary>
    class function RaceOf(AType: Integer): TWarRace; static;
    /// <summary>wu_getUnitTypeForRace: the equivalent of a unit type for the other race (the type itself if it has none)</summary>
    class function TypeForRace(AType: Integer; ARace: TWarRace): Integer; static;
  end;

implementation

type
  TWarTypeSet = set of Byte;

const
  DUDES: TWarTypeSet = [0..28];
  BUILDINGS: TWarTypeSet = [32..50];
  WORKERS: TWarTypeSet = [WAR_UNIT_PEASANT, WAR_UNIT_PEON];
  WARRIORS: TWarTypeSet = [WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS,
    WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER, WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN, WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK,
    WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE, WAR_UNIT_MEDIVH, WAR_UNIT_LOTHAR, WAR_UNIT_WOUNDED, WAR_UNIT_OGRE,
    WAR_UNIT_SPIDER, WAR_UNIT_SLIME, WAR_UNIT_FIRE_ELEMENTAL, WAR_UNIT_SCORPION, WAR_UNIT_BRIGAND, WAR_UNIT_THE_DEAD,
    WAR_UNIT_SKELETON, WAR_UNIT_DAEMON, WAR_UNIT_WATER_ELEMENTAL];
  RANGED: TWarTypeSet = [WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN,
    WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE, WAR_UNIT_MEDIVH,
    WAR_UNIT_WATER_ELEMENTAL];
  MELEE: TWarTypeSet = [WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER, WAR_UNIT_CLERIC,
    WAR_UNIT_LOTHAR, WAR_UNIT_OGRE, WAR_UNIT_SPIDER, WAR_UNIT_SLIME, WAR_UNIT_FIRE_ELEMENTAL, WAR_UNIT_SCORPION,
    WAR_UNIT_BRIGAND, WAR_UNIT_SKELETON, WAR_UNIT_DAEMON];
  FISTS: TWarTypeSet = [WAR_UNIT_OGRE, WAR_UNIT_SPIDER, WAR_UNIT_SLIME, WAR_UNIT_FIRE_ELEMENTAL, WAR_UNIT_SCORPION];
  SWORDS: TWarTypeSet = [WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT, WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER, WAR_UNIT_LOTHAR,
    WAR_UNIT_BRIGAND, WAR_UNIT_SKELETON, WAR_UNIT_DAEMON];
  MAGIC: TWarTypeSet = [WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE, WAR_UNIT_SCORPION,
    WAR_UNIT_SPIDER, WAR_UNIT_WATER_ELEMENTAL, WAR_UNIT_DAEMON, WAR_UNIT_THE_DEAD];
  CORPSES: TWarTypeSet = [WAR_UNIT_HUMAN_CORPSE, WAR_UNIT_ORC_CORPSE];
  CATAPULTS: TWarTypeSet = [WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS];
  CONJURERS: TWarTypeSet = [WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK];
  CLERICS: TWarTypeSet = [WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE];
  SUMMONS: TWarTypeSet = [WAR_UNIT_SCORPION, WAR_UNIT_SPIDER, WAR_UNIT_WATER_ELEMENTAL, WAR_UNIT_DAEMON,
    WAR_UNIT_THE_DEAD];
  HUMANS: TWarTypeSet = [WAR_UNIT_FOOTMAN, WAR_UNIT_PEASANT, WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_KNIGHT,
    WAR_UNIT_ARCHER, WAR_UNIT_CONJURER, WAR_UNIT_CLERIC, WAR_UNIT_LOTHAR, WAR_UNIT_SCORPION, WAR_UNIT_WATER_ELEMENTAL,
    WAR_UNIT_HUMAN_CORPSE, WAR_UNIT_FARM_HUMANS, WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_CHURCH, WAR_UNIT_TOWER_HUMANS,
    WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_STABLE, WAR_UNIT_BLACKSMITH_HUMANS,
    WAR_UNIT_STORMWIND];
  ORCS: TWarTypeSet = [WAR_UNIT_GRUNT, WAR_UNIT_PEON, WAR_UNIT_CATAPULT_ORCS, WAR_UNIT_RAIDER, WAR_UNIT_SPEARMAN,
    WAR_UNIT_WARLOCK, WAR_UNIT_NECROLYTE, WAR_UNIT_GRIZELDA, WAR_UNIT_GARONA, WAR_UNIT_SPIDER, WAR_UNIT_DAEMON,
    WAR_UNIT_ORC_CORPSE, WAR_UNIT_FARM_ORCS, WAR_UNIT_BARRACKS_ORCS, WAR_UNIT_TEMPLE, WAR_UNIT_TOWER_ORCS,
    WAR_UNIT_TOWNHALL_ORCS, WAR_UNIT_LUMBERMILL_ORCS, WAR_UNIT_KENNEL, WAR_UNIT_BLACKSMITH_ORCS, WAR_UNIT_BLACKROCK];

  // pairs (human type, orc type) for wu_getUnitTypeForRace
  PAIRS: array[0..15, 0..1] of Integer = (
    (WAR_UNIT_FOOTMAN, WAR_UNIT_GRUNT), (WAR_UNIT_PEASANT, WAR_UNIT_PEON),
    (WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS), (WAR_UNIT_KNIGHT, WAR_UNIT_RAIDER),
    (WAR_UNIT_ARCHER, WAR_UNIT_SPEARMAN), (WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK),
    (WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE), (WAR_UNIT_FARM_HUMANS, WAR_UNIT_FARM_ORCS),
    (WAR_UNIT_BARRACKS_HUMANS, WAR_UNIT_BARRACKS_ORCS), (WAR_UNIT_CHURCH, WAR_UNIT_TEMPLE),
    (WAR_UNIT_TOWER_HUMANS, WAR_UNIT_TOWER_ORCS), (WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS),
    (WAR_UNIT_LUMBERMILL_HUMANS, WAR_UNIT_LUMBERMILL_ORCS), (WAR_UNIT_STABLE, WAR_UNIT_KENNEL),
    (WAR_UNIT_BLACKSMITH_HUMANS, WAR_UNIT_BLACKSMITH_ORCS), (WAR_UNIT_HUMAN_CORPSE, WAR_UNIT_ORC_CORPSE));

{ TWarUnitClassifier }

class function TWarUnitClassifier.IsDude(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in DUDES);
end;

class function TWarUnitClassifier.IsBuilding(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in BUILDINGS);
end;

class function TWarUnitClassifier.IsWorker(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in WORKERS);
end;

class function TWarUnitClassifier.IsWarrior(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in WARRIORS);
end;

class function TWarUnitClassifier.IsRange(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in RANGED);
end;

class function TWarUnitClassifier.IsMelee(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in MELEE);
end;

class function TWarUnitClassifier.IsFist(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in FISTS);
end;

class function TWarUnitClassifier.IsSword(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in SWORDS);
end;

class function TWarUnitClassifier.IsMagic(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in MAGIC);
end;

class function TWarUnitClassifier.IsCorpse(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in CORPSES);
end;

class function TWarUnitClassifier.IsCatapult(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in CATAPULTS);
end;

class function TWarUnitClassifier.IsConjurerOrWarlock(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in CONJURERS);
end;

class function TWarUnitClassifier.IsClericOrNecrolyte(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in CLERICS);
end;

class function TWarUnitClassifier.IsSummon(AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType <= 255) and (Byte(AType) in SUMMONS);
end;

class function TWarUnitClassifier.IsSkeleton(AType: Integer): Boolean;
begin
  Result := AType = WAR_UNIT_SKELETON;
end;

class function TWarUnitClassifier.RaceOf(AType: Integer): TWarRace;
begin
  Result := wraNeutral;
  if (AType >= 0) and (AType <= 255) then
  begin
    if Byte(AType) in HUMANS then
      Result := wraHumans
    else if Byte(AType) in ORCS then
      Result := wraOrcs;
  end;
end;

class function TWarUnitClassifier.TypeForRace(AType: Integer; ARace: TWarRace): Integer;
var
  LIndex: Integer;
begin
  Result := AType;
  // the original logs a warning and gives the type back for a neutral race
  if ARace = wraHumans then
  begin
    for LIndex := 0 to High(PAIRS) do
      if PAIRS[LIndex, 1] = AType then
        Exit(PAIRS[LIndex, 0]);
  end
  else if ARace = wraOrcs then
  begin
    for LIndex := 0 to High(PAIRS) do
      if PAIRS[LIndex, 0] = AType then
        Exit(PAIRS[LIndex, 1]);
  end;
end;

end.
