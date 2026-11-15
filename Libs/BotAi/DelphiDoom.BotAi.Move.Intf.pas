{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - contract of the movement AI (be_ai_move.h)             }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Move.Types;

type
  /// <summary>The area a bot is in, for the goal AI (BotReachabilityArea)</summary>
  IBotReachabilityLocator = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F95}']
    /// <summary>
    ///   BotFuzzyPointReachabilityArea: the area of the point, or a near one, that has reachabilities; the first
    ///   area it found if none has
    /// </summary>
    function FuzzyPointReachabilityArea(const AOrigin: TVec3): Integer;
    /// <summary>
    ///   BotReachabilityArea: the area the bot is in; on a func_plat or a func_bobbing the area the reachability of
    ///   the mover points to
    /// </summary>
    function ReachabilityArea(const AOrigin: TVec3; const AClient: Integer): Integer;
  end;

  /// <summary>
  ///   The movement AI: the movement state of each bot (handles 1 to 64 as in the original) and the movement towards
  ///   a goal that sends the elementary actions (Libs\BotAi, <c>IBotElementaryActions</c>).
  /// </summary>
  IBotMoveSystem = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F96}']
    /// <summary>
    ///   BotSetupMoveAI: finds the types of the brush models of the map and makes the library variables
    ///   <c>sv_step</c>, <c>sv_maxbarrier</c>, <c>sv_gravity</c> ... (BLERR_NOERROR)
    /// </summary>
    function Setup: Integer;
    /// <summary>BotShutdownMoveAI</summary>
    procedure Shutdown;
    /// <summary>BotSetBrushModelTypes: must be called at every map change</summary>
    procedure SetBrushModelTypes;
    /// <summary>BotAllocMoveState: the handle, 0 if there is none free</summary>
    function AllocMoveState: Integer;
    /// <summary>BotFreeMoveState</summary>
    procedure FreeMoveState(const AHandle: Integer);
    /// <summary>BotInitMoveState: before any movement of the frame</summary>
    procedure InitMoveState(const AHandle: Integer; const AInit: TBotInitMove);
    /// <summary>BotResetMoveState</summary>
    procedure ResetMoveState(const AHandle: Integer);
    /// <summary>BotResetAvoidReach</summary>
    procedure ResetAvoidReach(const AHandle: Integer);
    /// <summary>BotResetLastAvoidReach</summary>
    procedure ResetLastAvoidReach(const AHandle: Integer);
    /// <summary>BotAddAvoidSpot: AVOID_CLEAR as the type removes all the spots</summary>
    procedure AddAvoidSpot(const AHandle: Integer; const AOrigin: TVec3; const ARadius: Single; const AType: Integer);
    /// <summary>
    ///   BotMoveToGoal: the elementary actions of the frame (the goal may be nil: the result is a failure)
    /// </summary>
    function MoveToGoal(const AHandle: Integer; const AGoal: PBotGoal; const ATravelFlags: Integer): TBotMoveResult;
    /// <summary>BotMoveInDirection: with the type MOVE_*; False if the movement is not possible</summary>
    function MoveInDirection(const AHandle: Integer; const ADir: TVec3; const ASpeed: Single;
      const AType: Integer): Boolean;
    /// <summary>BotMovementViewTarget: the point to look at while moving to the goal</summary>
    function MovementViewTarget(const AHandle: Integer; const AGoal: PBotGoal; const ATravelFlags: Integer;
      const ALookAhead: Single; out ATarget: TVec3): Boolean;
    /// <summary>BotPredictVisiblePosition: a point of the way to the goal that the goal can see</summary>
    function PredictVisiblePosition(const AOrigin: TVec3; const AAreaNum: Integer; const AGoal: PBotGoal;
      const ATravelFlags: Integer; out ATarget: TVec3): Boolean;
    /// <summary>BotReachabilityArea</summary>
    function ReachabilityArea(const AOrigin: TVec3; const AClient: Integer): Integer;
    /// <summary>The locator of the areas (BotFuzzyPointReachabilityArea, BotReachabilityArea)</summary>
    function Locator: IBotReachabilityLocator;
  end;

implementation

end.
