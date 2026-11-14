{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the records of the states of the units            }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine.h, (c) 2019 Alejandro Coto   }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Types;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types;

type
  /// <summary>WarStateBase: the first member of every state (the storage reaches any state through it)</summary>
  TWarStateBase = record
    StateType: Integer;
    EntityId: Word;
    NextUpdateGameTime: Double;
    Delay: Single;
  end;

  PWarStateBase = ^TWarStateBase;

  TWarStateIdle = record
    Base: TWarStateBase;
    LookAround: Boolean;
  end;

  PWarStateIdle = ^TWarStateIdle;

  /// <summary>WarMoveProgress: how a move is going, to give up a unit that does not advance</summary>
  TWarMoveProgress = record
    BestDistanceSq: Single;
    NoProgressTime: Single;
    LowVelocityTime: Single;
    RecoveryAttempt: Byte;
  end;

  /// <summary>
  ///   WarStateMove. The debug fields of the avoidance (the candidates of the velocity and their collisions) are not
  ///   kept: they only feed the debug drawing of the original
  /// </summary>
  TWarStateMove = record
    Base: TWarStateBase;
    WaypointsIndex: Integer;
    WaypointsCount: Integer;
    Waypoints: array[0..WAR_MODEL_MAX_WAYPOINTS - 1] of TWarVec2;
    CheckForAttacks: Boolean;
    RvoVelocity: TWarVec2;
    Progress: TWarMoveProgress;
    ProgressGoalPosition: TWarVec2;
    ProgressWaypointIndex: Integer;
    RvoPreferredVelocity: TWarVec2;
    RvoAdjustedVelocity: TWarVec2;
  end;

  PWarStateMove = ^TWarStateMove;

  TWarStatePatrol = record
    Base: TWarStateBase;
    WaypointsIndex: Integer;
    WaypointsCount: Integer;
    Waypoints: array[0..WAR_MODEL_MAX_WAYPOINTS - 1] of TWarVec2;
    Dir: Integer;
  end;

  PWarStatePatrol = ^TWarStatePatrol;

  TWarStateFollow = record
    Base: TWarStateBase;
    TargetEntityId: Word;
    TargetPosition: TWarVec2;
    TargetDistance: Integer;
  end;

  PWarStateFollow = ^TWarStateFollow;

  TWarStateAttack = record
    Base: TWarStateBase;
    TargetEntityId: Word;
    TargetPosition: TWarVec2;
  end;

  PWarStateAttack = ^TWarStateAttack;

  TWarStateGold = record
    Base: TWarStateBase;
    GoldmineId: Word;
  end;

  TWarStateMining = record
    Base: TWarStateBase;
    GoldmineId: Word;
    MiningTime: Single;
  end;

  TWarStateWood = record
    Base: TWarStateBase;
    ForestId: Word;
    Position: TWarVec2;
  end;

  TWarStateChopping = record
    Base: TWarStateBase;
    ForestId: Word;
    Position: TWarVec2;
  end;

  TWarStateDeliver = record
    Base: TWarStateBase;
    TownHallId: Word;
    InsideBuilding: Boolean;
    Cycle: Boolean;
    SourceKind: TWarResourceKind;
    SourceId: Word;
    SourcePosition: TWarVec2;
  end;

  TWarStateDeath = record
    Base: TWarStateBase;
  end;

  PWarStateDeath = ^TWarStateDeath;

  TWarStateCollapse = record
    Base: TWarStateBase;
  end;

  /// <summary>Train, upgrade and build share the fields of a purchase that can be cancelled (the AI command is not kept)</summary>
  TWarStateTrain = record
    Base: TWarStateBase;
    UnitToBuild: Integer;
    BuildTime: Single;
    TotalBuildTime: Single;
    GoldCost: Integer;
    WoodCost: Integer;
    TransactionApplied: Boolean;
    OutputCommitted: Boolean;
    Cancelled: Boolean;
    AlreadyRefunded: Boolean;
  end;

  PWarStateTrain = ^TWarStateTrain;

  TWarStateUpgrade = record
    Base: TWarStateBase;
    UpgradeToBuild: Integer;
    BuildTime: Single;
    TotalBuildTime: Single;
    GoldCost: Integer;
    WoodCost: Integer;
    TransactionApplied: Boolean;
    OutputCommitted: Boolean;
    Cancelled: Boolean;
    AlreadyRefunded: Boolean;
  end;

  PWarStateUpgrade = ^TWarStateUpgrade;

  TWarStateBuild = record
    Base: TWarStateBase;
    WorkerId: Word;
    BuildTime: Single;
    TotalBuildTime: Single;
    GoldCost: Integer;
    WoodCost: Integer;
    TransactionApplied: Boolean;
    OutputCommitted: Boolean;
    Cancelled: Boolean;
    AlreadyRefunded: Boolean;
  end;

  PWarStateBuild = ^TWarStateBuild;

  TWarStateRepair = record
    Base: TWarStateBase;
    BuildingId: Word;
  end;

  TWarStateRepairing = record
    Base: TWarStateBase;
    BuildingId: Word;
    InsideBuilding: Boolean;
  end;

  TWarStateCast = record
    Base: TWarStateBase;
    SpellType: Integer;
    TargetEntityId: Word;
    TargetPosition: TWarVec2;
  end;

  TWarStateWait = record
    Base: TWarStateBase;
    WaitEndGameTime: Double;
  end;

  PWarStateWait = ^TWarStateWait;

implementation

end.
