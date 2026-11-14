{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - images of the buildings under construction       }
{  (GENERATED)                                                                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c, (c) 2019 Alejandro Coto          }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Written by Tools\Verifica\194\Make-WarConstructionTables.ps1 from the       }
{  output of the original C code (Tests\Data\War\                              }
{  model.construction.tables.golden.txt): do not edit by hand                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.BuildingResources.Data;

interface

const
  /// <summary>buildingsData of war_units.c: the resource of the image of a building under construction, by unit type, counting from the type that WAR_BUILDING_FIRST_TYPE names</summary>
  WAR_BUILDING_FIRST_TYPE = 32;
  WAR_BUILDING_CONSTRUCTION_RESOURCES: array[0..15] of Integer = (331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346);

implementation

end.
