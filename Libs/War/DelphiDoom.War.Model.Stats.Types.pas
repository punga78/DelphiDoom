{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - records of the statistics of the game             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.h, (c) 2019 Alejandro Coto Gutierrez,}
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Stats.Types;

interface

type
  /// <summary>WarUnitStats of war_units.h, all the fields (the map keeps only a part in TWarUnitStats)</summary>
  TWarUnitStatsFull = record
    UnitType: Integer;
    Range: Integer;
    Sight: Integer;
    Armor: Integer;
    Hp: Integer;
    Mana: Integer;
    MinDamage: Integer;
    RndDamage: Integer;
    /// <summary>In program cycles times 80 / 1000 (the original writes __bts(600)); -1 if the unit cannot be trained</summary>
    BuildTime: Integer;
    GoldCost: Integer;
    WoodCost: Integer;
    Decay: Integer;
    /// <summary>Pixels per second for the three levels of speed (horses and wolves raise the level)</summary>
    Speeds: array[0..2] of Single;
  end;

  /// <summary>WarBuildingStats of war_units.h</summary>
  TWarBuildingStatsFull = record
    UnitType: Integer;
    Armor: Integer;
    Sight: Integer;
    Hp: Integer;
    BuildTime: Integer;
    GoldCost: Integer;
    WoodCost: Integer;
  end;

  /// <summary>WarUpgradeStats and the maximum level of WarUpgradeData</summary>
  TWarUpgradeStats = record
    UpgradeType: Integer;
    BuildTime: Integer;
    GoldCost1: Integer;
    GoldCost2: Integer;
    MaxLevel: Integer;
  end;

  /// <summary>WarSpellStats and, for the summons, the unit of WarSpellMapping</summary>
  TWarSpellStats = record
    SpellType: Integer;
    ManaCost: Integer;
    Time: Single;
    Range: Integer;
    MappedUnit: Integer;
  end;

implementation

end.
