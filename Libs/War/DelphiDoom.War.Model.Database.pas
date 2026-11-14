{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the statistics of the game                        }
{                                                                              }
{  Port of war1 (acoto87/war1), the tables and the wu_get*Stats functions of   }
{  war_units.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see           }
{  Libs\War\LICENSE-war1.txt). This is an altered version.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Database;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Map.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.Intf;

type
  /// <summary>IWarDatabase over the generated tables (FIND_BY_TYPE of the original: a search by type)</summary>
  TWarDatabase = class(TInterfacedObject, IWarDatabase)
  public
    function GetUnitStats(AUnitType: Integer): TWarUnitStatsFull;
    function TryGetUnitStats(AUnitType: Integer; out AStats: TWarUnitStatsFull): Boolean;
    function GetBuildingStats(AUnitType: Integer): TWarBuildingStatsFull;
    function GetUpgradeStats(AUpgradeType: Integer): TWarUpgradeStats;
    function GetSpellStats(ASpellType: Integer): TWarSpellStats;
    function TryGetUnitSize(AUnitType: Integer; out ASizeX, ASizeY: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Model.StatData, DelphiDoom.War.Map.UnitData;

{ TWarDatabase }

function TWarDatabase.TryGetUnitStats(AUnitType: Integer; out AStats: TWarUnitStatsFull): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_UNIT_STAT_DATA) to High(WAR_UNIT_STAT_DATA) do
    if WAR_UNIT_STAT_DATA[LIndex].UnitType = AUnitType then
    begin
      AStats := WAR_UNIT_STAT_DATA[LIndex];
      Exit(True);
    end;
  AStats := Default(TWarUnitStatsFull);
  Result := False;
end;

function TWarDatabase.GetUnitStats(AUnitType: Integer): TWarUnitStatsFull;
begin
  if not TryGetUnitStats(AUnitType, Result) then
    raise EWarException.CreateFmt(SWarModelNoUnitStats, [AUnitType]);
end;

function TWarDatabase.GetBuildingStats(AUnitType: Integer): TWarBuildingStatsFull;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_BUILDING_STAT_DATA) to High(WAR_BUILDING_STAT_DATA) do
    if WAR_BUILDING_STAT_DATA[LIndex].UnitType = AUnitType then
      Exit(WAR_BUILDING_STAT_DATA[LIndex]);
  raise EWarException.CreateFmt(SWarModelNoBuildingStats, [AUnitType]);
end;

function TWarDatabase.GetUpgradeStats(AUpgradeType: Integer): TWarUpgradeStats;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_UPGRADE_STAT_DATA) to High(WAR_UPGRADE_STAT_DATA) do
    if WAR_UPGRADE_STAT_DATA[LIndex].UpgradeType = AUpgradeType then
      Exit(WAR_UPGRADE_STAT_DATA[LIndex]);
  raise EWarException.CreateFmt(SWarModelNoUpgradeStats, [AUpgradeType]);
end;

function TWarDatabase.GetSpellStats(ASpellType: Integer): TWarSpellStats;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_SPELL_STAT_DATA) to High(WAR_SPELL_STAT_DATA) do
    if WAR_SPELL_STAT_DATA[LIndex].SpellType = ASpellType then
      Exit(WAR_SPELL_STAT_DATA[LIndex]);
  raise EWarException.CreateFmt(SWarModelNoSpellStats, [ASpellType]);
end;

function TWarDatabase.TryGetUnitSize(AUnitType: Integer; out ASizeX, ASizeY: Integer): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := Low(WAR_UNIT_DATA) to High(WAR_UNIT_DATA) do
    if WAR_UNIT_DATA[LIndex].UnitType = AUnitType then
    begin
      ASizeX := WAR_UNIT_DATA[LIndex].SizeX;
      ASizeY := WAR_UNIT_DATA[LIndex].SizeY;
      Exit(True);
    end;
  ASizeX := 0;
  ASizeY := 0;
  Result := False;
end;

end.
