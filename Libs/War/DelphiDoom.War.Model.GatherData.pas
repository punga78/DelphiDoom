{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - steps of the harvest action, carrying images     }
{  (GENERATED)                                                                 }
{                                                                              }
{  Port of war1 (acoto87/war1), war_actions.c and war_units.c, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Written by Tools\Verifica\194\Make-WarGatherTables.ps1 from the output of   }
{  the original C code (Tests\Data\War\gather.tables.golden.txt): do not edit  }
{  by hand                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.GatherData;

interface

const
  /// <summary>The most steps that a definition of the table has</summary>
  WAR_ACTION_STEPS_MAX = 16;

type
  /// <summary>WarUnitActionStep: the type (WAR_ACTION_STEP_*) and its parameter (a frame, a number of frames)</summary>
  TWarActionStepData = record
    StepType: Integer;
    Param: Integer;
  end;

  /// <summary>The part of a WarUnitActionDef that the update of the action reads</summary>
  TWarActionDefinition = record
    UnitType: Integer;
    Directional: Boolean;
    Loop: Boolean;
    Count: Integer;
    Steps: array[0..WAR_ACTION_STEPS_MAX - 1] of TWarActionStepData;
  end;

  /// <summary>WarWorkerData: the images of a worker that carries wood or gold</summary>
  TWarWorkerSprites = record
    UnitType: Integer;
    CarryingWood: Integer;
    CarryingGold: Integer;
  end;

const
  /// <summary>gUnitActionDefs[type][WAR_ACTION_TYPE_HARVEST] of war_actions.c: the unit types that have it</summary>
  WAR_HARVEST_ACTIONS: array[0..1] of TWarActionDefinition = (
    (UnitType: 2; Directional: True; Loop: True; Count: 16;
      Steps: ((StepType: 2; Param: 5), (StepType: 1; Param: 5), (StepType: 2; Param: 6), (StepType: 1; Param: 20), (StepType: 2; Param: 6), (StepType: 1; Param: 35), (StepType: 3; Param: 0), (StepType: 7; Param: 0), (StepType: 2; Param: 6), (StepType: 1; Param: 50), (StepType: 2; Param: 6), (StepType: 2; Param: 6), (StepType: 1; Param: 0), (StepType: 2; Param: 1), (StepType: 1; Param: 0), (StepType: 2; Param: 1))),
    (UnitType: 3; Directional: True; Loop: True; Count: 16;
      Steps: ((StepType: 2; Param: 5), (StepType: 1; Param: 5), (StepType: 2; Param: 6), (StepType: 1; Param: 20), (StepType: 2; Param: 6), (StepType: 1; Param: 35), (StepType: 3; Param: 0), (StepType: 7; Param: 0), (StepType: 2; Param: 6), (StepType: 1; Param: 50), (StepType: 2; Param: 6), (StepType: 2; Param: 6), (StepType: 1; Param: 0), (StepType: 2; Param: 1), (StepType: 1; Param: 0), (StepType: 2; Param: 1)))
  );

  /// <summary>workersData of war_units.c</summary>
  WAR_WORKER_SPRITES: array[0..1] of TWarWorkerSprites = (
    (UnitType: 2; CarryingWood: 327; CarryingGold: 329),
    (UnitType: 3; CarryingWood: 328; CarryingGold: 330)
  );

implementation

end.
