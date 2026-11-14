{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts of the game model                       }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Intf;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Stats.Types;

type
  /// <summary>The statistics of the game (the tables of war_units.c)</summary>
  IWarDatabase = interface
    ['{7C3E9A21-5B84-4F6D-A1D7-2E90B8C4F356}']
    /// <summary>wu_getUnitStats: EWarModelException if the type has none (the original stops on an assert)</summary>
    function GetUnitStats(AUnitType: Integer): TWarUnitStatsFull;
    /// <summary>wu_getUnitStats without the exception: False if the type has none</summary>
    function TryGetUnitStats(AUnitType: Integer; out AStats: TWarUnitStatsFull): Boolean;
    /// <summary>wu_getBuildingStats: EWarModelException if the type has none</summary>
    function GetBuildingStats(AUnitType: Integer): TWarBuildingStatsFull;
    /// <summary>wu_getUpgradeStats and the maximum level of wu_getUpgradeData</summary>
    function GetUpgradeStats(AUpgradeType: Integer): TWarUpgradeStats;
    /// <summary>wu_getSpellStats and wu_getSpellMapping</summary>
    function GetSpellStats(ASpellType: Integer): TWarSpellStats;
    /// <summary>wu_getUnitData: the size in tiles of a unit type; False if the type is not in the table</summary>
    function TryGetUnitSize(AUnitType: Integer; out ASizeX, ASizeY: Integer): Boolean;
  end;

  /// <summary>Questions about the units that the states ask (slots of the pool; 0 means nobody)</summary>
  IWarUnitQueries = interface
    ['{2F6A8D14-93B7-4C05-A8E1-5D70C93B1F68}']
    /// <summary>we_getNearEnemy</summary>
    function NearEnemy(ASlot: Integer): Integer;
    /// <summary>we_getAttacker</summary>
    function Attacker(ASlot: Integer): Integer;
    /// <summary>wu_areEnemies</summary>
    function AreEnemies(ASlot, AOtherSlot: Integer): Boolean;
    /// <summary>wu_canAttack</summary>
    function CanAttack(ASlot, ATargetSlot: Integer): Boolean;
    /// <summary>wu_getTotalNumberOfDudes</summary>
    function CountDudes(APlayer: Integer): Integer;
    /// <summary>wu_getNumberOfBuildingsOfType</summary>
    function CountBuildingsOfType(APlayer, AUnitType: Integer; AAlreadyBuilt: Boolean): Integer;
    /// <summary>wu_getNumberOfUnitsOfType</summary>
    function CountUnitsOfType(APlayer, AUnitType: Integer): Integer;
  end;

  /// <summary>Creating and removing the units, as the states need (a corpse when a unit dies, the removal of the dead)</summary>
  IWarEntityManager = interface
    ['{8B1D5E72-4A09-47C3-B6F8-0C93A5E2D471}']
    /// <summary>we_createUnit; 0 if the pool is full</summary>
    function CreateUnit(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AResourceKind: TWarResourceKind;
      AAmount: Cardinal; AAddToMap: Boolean): Integer;
    /// <summary>we_createDude</summary>
    function CreateDude(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AIsGoingToTrain: Boolean): Integer;
    /// <summary>we_createBuilding</summary>
    function CreateBuilding(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AIsGoingToBuild: Boolean): Integer;
    /// <summary>we_setInitialIdleState</summary>
    procedure SetInitialIdle(ASlot: Integer);
    /// <summary>we_removeEntity</summary>
    procedure RemoveEntity(ASlot: Integer);
    /// <summary>we_removeEntityById</summary>
    procedure RemoveEntityById(AId: Word);
  end;
  /// <summary>What the model tells the game around it. The calls are rare (a death, a purchase), never per tic and unit</summary>
  IWarModelEvents = interface
    ['{B1D44F70-9A3C-4E58-8C26-47F1E05A9D83}']
    /// <summary>wmui_setFlashStatus</summary>
    procedure FlashStatus(AMessage: TWarStatusMessage);
    /// <summary>wmap_removeEntityFromSelection: the entity can not be selected any more</summary>
    procedure EntityLeftSelection(AEntityId: Word);
    /// <summary>A unit has died (the sound of the death is the business of who listens)</summary>
    procedure UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    /// <summary>A building has no hit points: it starts to collapse</summary>
    procedure BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    /// <summary>A building has been hurt and is still standing: the percent of hit points left (0..100)</summary>
    procedure BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
  end;

  /// <summary>The tiles that the units stand on (the wpath_setStaticEntity and wpath_setFreeTiles of the original)</summary>
  IWarOccupancy = interface
    ['{4A9F1C86-D2E7-43B5-9061-8E7A3B5C2D14}']
    procedure SetStaticEntity(AStartX, AStartY, AWidth, AHeight: Integer; AId: Word);
    procedure SetFreeTiles(AStartX, AStartY, AWidth, AHeight: Integer);
  end;

  /// <summary>
  ///   How a unit that moves chooses its velocity when there are obstacles or other units (the flow field and the
  ///   avoidance of the original, issue #195). Without one the unit goes straight to its next waypoint
  /// </summary>
  IWarMovementSteering = interface
    ['{E5B07D39-1C84-4A62-B3F9-6D2A8E4C0715}']
    /// <summary>
    ///   The velocity (pixels per second) that the unit with the given center, last velocity and maximum speed will
    ///   have; ANextWaypoint and AGoal are centers in pixels. False if there is no way: the move ends with NO_PATH
    /// </summary>
    function Steer(AEntityId: Word; const APosition, ANextWaypoint, AGoal, ALastVelocity: TWarVec2;
      AIsLastLeg: Boolean; AMaxSpeed, ARadius: Single; ADeltaTime: Single; out AVelocity: TWarVec2): Boolean;
  end;

implementation

end.
