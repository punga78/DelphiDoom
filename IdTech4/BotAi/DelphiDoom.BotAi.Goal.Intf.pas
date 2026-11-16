{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - contract of the goal AI (be_ai_goal.h)                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Goal.ItemConfig;

type
  /// <summary>
  ///   The goal AI: the items of the level, the goal stack of each bot (handles 1 to 64 as in the original), the
  ///   choice of the long term and of the nearby goal item, and the item weights.
  /// </summary>
  IBotGoalSystem = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F94}']
    /// <summary>
    ///   BotSetupGoalAI: reads <c>g_gametype</c>, loads the item config (<c>itemconfig</c>, items.c) and reads
    ///   <c>droppedweight</c>; BLERR_CANNOTLOADITEMCONFIG if the config cannot be read
    /// </summary>
    function Setup: Integer;
    /// <summary>BotShutdownGoalAI</summary>
    procedure Shutdown;
    /// <summary>BotAllocGoalState: the handle, 0 if there is none free</summary>
    function AllocGoalState(const AClient: Integer): Integer;
    /// <summary>BotFreeGoalState</summary>
    procedure FreeGoalState(const AHandle: Integer);
    /// <summary>BotResetGoalState: empties the stack and the avoid goals, keeps the item weights</summary>
    procedure ResetGoalState(const AHandle: Integer);
    /// <summary>BotResetAvoidGoals</summary>
    procedure ResetAvoidGoals(const AHandle: Integer);
    /// <summary>BotRemoveFromAvoidGoals</summary>
    procedure RemoveFromAvoidGoals(const AHandle, ANumber: Integer);
    /// <summary>BotPushGoal: "goal heap overflow" (and the stack to the log) with eight goals</summary>
    procedure PushGoal(const AHandle: Integer; const AGoal: TBotGoal);
    /// <summary>BotPopGoal</summary>
    procedure PopGoal(const AHandle: Integer);
    /// <summary>BotEmptyGoalStack</summary>
    procedure EmptyGoalStack(const AHandle: Integer);
    /// <summary>BotDumpAvoidGoals: to the log</summary>
    procedure DumpAvoidGoals(const AHandle: Integer);
    /// <summary>BotDumpGoalStack: to the log</summary>
    procedure DumpGoalStack(const AHandle: Integer);
    /// <summary>
    ///   BotGoalName: the name of the item of the goal with the number, cut at ASize - 1 characters; empty if
    ///   there is none
    /// </summary>
    function GoalName(const ANumber, ASize: Integer): AnsiString;
    /// <summary>BotGetTopGoal</summary>
    function GetTopGoal(const AHandle: Integer; out AGoal: TBotGoal): Boolean;
    /// <summary>BotGetSecondGoal</summary>
    function GetSecondGoal(const AHandle: Integer; out AGoal: TBotGoal): Boolean;
    /// <summary>
    ///   BotChooseLTGItem: pushes the best long term goal item on the stack; false if there is none
    /// </summary>
    function ChooseLTGItem(const AHandle: Integer; const AOrigin: TVec3; const AInventory: TArray<Integer>;
      const ATravelFlags: Integer): Boolean;
    /// <summary>
    ///   BotChooseNBGItem: pushes the best nearby goal item (not further than AMaxTime; ALtg is the long term goal,
    ///   nil for none)
    /// </summary>
    function ChooseNBGItem(const AHandle: Integer; const AOrigin: TVec3; const AInventory: TArray<Integer>;
      const ATravelFlags: Integer; const ALtg: PBotGoal; const AMaxTime: Single): Boolean;
    /// <summary>BotTouchingGoal</summary>
    function TouchingGoal(const AOrigin: TVec3; const AGoal: TBotGoal): Boolean;
    /// <summary>BotItemGoalInVisButNotVisible</summary>
    function ItemGoalInVisButNotVisible(const AViewer: Integer; const AEye, AViewAngles: TVec3;
      const AGoal: TBotGoal): Boolean;
    /// <summary>
    ///   BotGetLevelItemGoal: the goal of the next level item that has the name (after the item with the number
    ///   AIndex, or from the start if AIndex is negative); its number, or -1
    /// </summary>
    function GetLevelItemGoal(const AIndex: Integer; const AName: AnsiString; var AGoal: TBotGoal): Integer;
    /// <summary>BotGetNextCampSpotGoal: the number to ask for the next one, 0 at the end</summary>
    function GetNextCampSpotGoal(const ANum: Integer; var AGoal: TBotGoal): Integer;
    /// <summary>BotGetMapLocationGoal</summary>
    function GetMapLocationGoal(const AName: AnsiString; var AGoal: TBotGoal): Boolean;
    /// <summary>BotAvoidGoalTime</summary>
    function AvoidGoalTime(const AHandle, ANumber: Integer): Single;
    /// <summary>BotSetAvoidGoalTime: a negative time is the respawn time of the item (at least 10, 30 if none)</summary>
    procedure SetAvoidGoalTime(const AHandle, ANumber: Integer; const AAvoidTime: Single);
    /// <summary>BotInitLevelItems: the items of the loaded map (the map must be loaded first)</summary>
    procedure InitLevelItems;
    /// <summary>BotUpdateEntityItems: dropped items; call it every frame</summary>
    procedure UpdateEntityItems;
    /// <summary>BotInterbreedGoalFuzzyLogic</summary>
    procedure InterbreedGoalFuzzyLogic(const AParent1, AParent2, AChild: Integer);
    /// <summary>BotSaveGoalFuzzyLogic: does nothing in the original (the call that writes is commented out)</summary>
    procedure SaveGoalFuzzyLogic(const AHandle: Integer; const AFileName: AnsiString);
    /// <summary>BotMutateGoalFuzzyLogic</summary>
    procedure MutateGoalFuzzyLogic(const AHandle: Integer; const ARange: Single);
    /// <summary>BotLoadItemWeights: BLERR_CANNOTLOADITEMWEIGHTS if the file or the item config is missing</summary>
    function LoadItemWeights(const AHandle: Integer; const AFileName: AnsiString): Integer;
    /// <summary>BotFreeItemWeights</summary>
    procedure FreeItemWeights(const AHandle: Integer);
    /// <summary>itemconfig: nil before Setup or if it could not be loaded</summary>
    function ItemConfig: TBotItemConfig;
    /// <summary>numlevelitems</summary>
    function LevelItemCount: Integer;
  end;

implementation

end.
