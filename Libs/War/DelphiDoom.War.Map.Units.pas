{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the units of the game                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c (wu_is*UnitType, wu_getUnit*) and  }
{  we_createUnit of war_entities.c, (c) 2019 Alejandro Coto Gutierrez, zlib    }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Units;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Map.Intf;

type
  /// <summary>The tables of units of war_units.c behind IWarUnitCatalog</summary>
  TWarUnitCatalog = class(TInterfacedObject, IWarUnitCatalog)
  strict private
    function FindStats(AUnitType: Integer; out AStats: TWarUnitStats): Boolean;
    function FindBuilding(AUnitType: Integer; out AStats: TWarBuildingStats): Boolean;
  public
    function TryGetData(AUnitType: Integer; out AData: TWarUnitData): Boolean;
    function IsDudeType(AUnitType: Integer): Boolean;
    function IsBuildingType(AUnitType: Integer): Boolean;
    function IsSummonType(AUnitType: Integer): Boolean;
    function IsCorpseType(AUnitType: Integer): Boolean;
    function SightRange(AUnitType: Integer): Integer;
    function CreateUnit(AId: Word; AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AResourceKind: TWarResourceKind;
      AAmount: Cardinal): TWarMapUnit;
  end;

implementation

uses
  DelphiDoom.War.Map.UnitData;

{ TWarUnitCatalog }

function TWarUnitCatalog.TryGetData(AUnitType: Integer; out AData: TWarUnitData): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_UNIT_DATA) to High(WAR_UNIT_DATA) do
    if WAR_UNIT_DATA[LIndex].UnitType = AUnitType then
    begin
      AData := WAR_UNIT_DATA[LIndex];
      Exit(True);
    end;
  AData := Default(TWarUnitData);
  Result := False;
end;

function TWarUnitCatalog.FindStats(AUnitType: Integer; out AStats: TWarUnitStats): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_UNIT_STATS) to High(WAR_UNIT_STATS) do
    if WAR_UNIT_STATS[LIndex].UnitType = AUnitType then
    begin
      AStats := WAR_UNIT_STATS[LIndex];
      Exit(True);
    end;
  AStats := Default(TWarUnitStats);
  Result := False;
end;

function TWarUnitCatalog.FindBuilding(AUnitType: Integer; out AStats: TWarBuildingStats): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_BUILDING_STATS) to High(WAR_BUILDING_STATS) do
    if WAR_BUILDING_STATS[LIndex].UnitType = AUnitType then
    begin
      AStats := WAR_BUILDING_STATS[LIndex];
      Exit(True);
    end;
  AStats := Default(TWarBuildingStats);
  Result := False;
end;

function TWarUnitCatalog.IsDudeType(AUnitType: Integer): Boolean;
begin
  Result := (AUnitType >= WAR_UNIT_FOOTMAN) and (AUnitType <= WAR_UNIT_WATER_ELEMENTAL);
end;

function TWarUnitCatalog.IsBuildingType(AUnitType: Integer): Boolean;
begin
  Result := (AUnitType >= WAR_UNIT_FARM_HUMANS) and (AUnitType <= WAR_UNIT_GOLDMINE);
end;

function TWarUnitCatalog.IsSummonType(AUnitType: Integer): Boolean;
begin
  Result := AUnitType in [WAR_UNIT_SCORPION, WAR_UNIT_SPIDER, WAR_UNIT_WATER_ELEMENTAL, WAR_UNIT_DAEMON, WAR_UNIT_THE_DEAD];
end;

function TWarUnitCatalog.IsCorpseType(AUnitType: Integer): Boolean;
begin
  Result := (AUnitType = WAR_UNIT_HUMAN_CORPSE) or (AUnitType = WAR_UNIT_ORC_CORPSE);
end;

function TWarUnitCatalog.SightRange(AUnitType: Integer): Integer;
var
  LBuilding: TWarBuildingStats;
  LStats: TWarUnitStats;
begin
  // wu_getUnitSightRange: a building has the sight of its table, the rest the sight of the units that move
  if IsBuildingType(AUnitType) then
  begin
    if not FindBuilding(AUnitType, LBuilding) then
      raise EWarException.CreateFmt(SWarMapUnitUnknown, [AUnitType]);
    Result := LBuilding.Sight;
  end
  else
  begin
    if not FindStats(AUnitType, LStats) then
      raise EWarException.CreateFmt(SWarMapUnitUnknown, [AUnitType]);
    Result := LStats.Sight;
  end;
end;

function TWarUnitCatalog.CreateUnit(AId: Word; AUnitType, ATileX, ATileY: Integer; APlayer: Byte;
  AResourceKind: TWarResourceKind; AAmount: Cardinal): TWarMapUnit;
var
  LData: TWarUnitData;
  LStats: TWarUnitStats;
  LBuilding: TWarBuildingStats;
begin
  if not TryGetData(AUnitType, LData) then
    raise EWarException.CreateFmt(SWarMapUnitUnknown, [AUnitType]);
  Result := Default(TWarMapUnit);
  Result.Id := AId;
  Result.UnitType := AUnitType;
  Result.TileX := ATileX;
  Result.TileY := ATileY;
  Result.SizeX := LData.SizeX;
  Result.SizeY := LData.SizeY;
  Result.Player := APlayer;
  Result.ResourceKind := AResourceKind;
  Result.Amount := Integer(AAmount);
  if IsDudeType(AUnitType) then
  begin
    if not FindStats(AUnitType, LStats) then
      raise EWarException.CreateFmt(SWarMapUnitUnknown, [AUnitType]);
    Result.MaxHp := LStats.Hp;
    Result.Hp := LStats.Hp;
    Result.MaxMana := LStats.Mana;
    if IsSummonType(AUnitType) then
      Result.Mana := LStats.Mana
    else
      Result.Mana := 100;
    Result.Armor := LStats.Armor;
    Result.Range := LStats.Range;
    Result.MinDamage := LStats.MinDamage;
    Result.RndDamage := LStats.RndDamage;
    Result.Decay := LStats.Decay;
    Result.ManaTime := 1;
  end
  else if IsBuildingType(AUnitType) then
  begin
    if not FindBuilding(AUnitType, LBuilding) then
      raise EWarException.CreateFmt(SWarMapUnitUnknown, [AUnitType]);
    Result.MaxHp := LBuilding.Hp;
    Result.Hp := LBuilding.Hp;
    Result.Armor := LBuilding.Armor;
  end;
end;

end.
