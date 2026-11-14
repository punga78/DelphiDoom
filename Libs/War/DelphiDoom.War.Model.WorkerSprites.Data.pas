{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - images of the workers that carry (GENERATED)      }
{                                                                              }
{  Port of war1 (acoto87/war1), war_units.c, (c) 2019 Alejandro Coto           }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Written by Tools\Verifica\194\Make-WarGatherTables.ps1 from the output of   }
{  the original C code (Tests\Data\War\gather.tables.golden.txt): do not edit  }
{  by hand                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.WorkerSprites.Data;

interface

type
  /// <summary>WarWorkerData: the images of a worker that carries wood or gold</summary>
  TWarWorkerSprites = record
    UnitType: Integer;
    CarryingWood: Integer;
    CarryingGold: Integer;
  end;

const
  /// <summary>workersData of war_units.c</summary>
  WAR_WORKER_SPRITES: array[0..1] of TWarWorkerSprites = (
    (UnitType: 2; CarryingWood: 327; CarryingGold: 329),
    (UnitType: 3; CarryingWood: 328; CarryingGold: 330)
  );

implementation

end.
