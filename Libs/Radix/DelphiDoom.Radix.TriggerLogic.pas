{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixTriggerLogic                              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of radix_logic.pas of Rad-X (RX_RunTrigger, RX_RunTriggers and the     }
{  test of RX_RunActions) and of the scan of P_LoadRadixSprites, without the   }
{  globals of the engine                                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.TriggerLogic;

interface

uses
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types, DelphiDoom.Radix.TriggerGrid;

type
  /// <summary>
  ///   The actions and the triggers of a level while the game runs. A trigger that is not
  ///   suspended, when it is run, wakes up, suspends or toggles its actions; an action runs every
  ///   tic while it is enabled and not suspended. The records are the ones of RACTION and RTRIGGER
  ///   and are owned here: the code of an action keeps its own state in the parameters after the
  ///   ones of the lump (they are zero there), as the old code did.
  ///   Differences from the old code: a trigger or an action that the level does not have is
  ///   skipped instead of being read out of the array
  /// </summary>
  TRadixTriggerLogic = class
  strict private
    FActions: TArray<TRadixLevelAction>;
    FTriggers: TArray<TRadixLevelTrigger>;
    FLastTrigger: TArray<Integer>;
    function GetActionCount: Integer;
    function GetTriggerCount: Integer;
    procedure ApplyTriggerAction(const ATriggerAction: TRadixLevelTriggerAction);
  public
    const
      /// <summary>
      ///   The "last trigger" of a craft that has just been put in the level. The old P_SpawnPlayer
      ///   set 0, not -1: the trigger 0 is not set off by a craft that starts on it
      /// </summary>
      SPAWN_LAST_TRIGGER = 0;
  public
    constructor Create(const AActions: TArray<TRadixLevelAction>; const ATriggers: TArray<TRadixLevelTrigger>;
      APlayers: Integer);
    function IsAction(AAction: Integer): Boolean;
    function IsTrigger(ATrigger: Integer): Boolean;
    /// <summary>The record of an action, to run it; nil for an action that the level does not have</summary>
    function Action(AAction: Integer): PRadixLevelAction;
    function Trigger(ATrigger: Integer): PRadixLevelTrigger;
    /// <summary>True for an action that is enabled and not suspended: it runs this tic</summary>
    function IsActionRunnable(AAction: Integer): Boolean;
    /// <summary>The first action that runs from AFrom on; ActionCount when there is none</summary>
    function NextRunnable(AFrom: Integer): Integer;
    /// <summary>What an action does when it has finished: it does not run until a trigger wakes it up</summary>
    procedure SuspendAction(AAction: Integer);
    function IsTriggerSuspended(ATrigger: Integer): Boolean;
    /// <summary>A trigger that can be run from now on (it is not run)</summary>
    procedure ActivateTrigger(ATrigger: Integer);
    procedure DeactivateTrigger(ATrigger: Integer);
    /// <summary>Applies the actions of a trigger that is not suspended; true when it was applied</summary>
    function RunTrigger(ATrigger: Integer): Boolean;
    /// <summary>What a wall, a kill count or a moving surface do: the trigger is activated and run</summary>
    procedure ActivateAndRunTrigger(ATrigger: Integer);
    /// <summary>
    ///   The cells that a craft is in during this tic. A cell whose trigger is not the last one
    ///   that the craft touched becomes the last and, when it has a trigger, runs it (once for a
    ///   tic). Leaving a trigger for a cell without one lets it be set off again. Returns how many
    ///   triggers were run; a cell outside the grid is skipped
    /// </summary>
    function PlayerCrosses(APlayer: Integer; const AGrid: TRadixTriggerGrid; const ACells: TRadixGridPositions): Integer;
    /// <summary>A craft that is put in the level (a new level, a pilot born again)</summary>
    procedure ResetPlayer(APlayer: Integer);
    function LastTrigger(APlayer: Integer): Integer;
    function HasActionOfKind(AKind: Integer): Boolean;
    /// <summary>
    ///   The walls (lines of the Doom map) of the actions that fire missiles from a wall, each
    ///   once in the order of the actions; a negative wall is left out
    /// </summary>
    function MissileWalls: TArray<Integer>;
    /// <summary>True when a trigger has, among its actions, one of the given kind (a force field is found so)</summary>
    function TriggerHasActionOfKind(ATrigger: Integer; AKind: Integer): Boolean;
    property ActionCount: Integer read GetActionCount;
    property TriggerCount: Integer read GetTriggerCount;
  end;

implementation

const
  ACTION_ENABLED = 1;
  ACTION_RUNNING = 0;
  // not the $FFFF of RADIX.DAT (an action that waits for its trigger): one that has finished
  ACTION_SUSPENDED = 1;
  TRIGGER_ACTIVE = 0;
  TRIGGER_SUSPENDED = 1;

{ TRadixTriggerLogic }

constructor TRadixTriggerLogic.Create(const AActions: TArray<TRadixLevelAction>;
  const ATriggers: TArray<TRadixLevelTrigger>; APlayers: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FActions := Copy(AActions);
  FTriggers := Copy(ATriggers);
  SetLength(FLastTrigger, APlayers);
  for LIndex := 0 to APlayers - 1 do
    FLastTrigger[LIndex] := SPAWN_LAST_TRIGGER;
end;

function TRadixTriggerLogic.GetActionCount: Integer;
begin
  Result := Length(FActions);
end;

function TRadixTriggerLogic.GetTriggerCount: Integer;
begin
  Result := Length(FTriggers);
end;

function TRadixTriggerLogic.IsAction(AAction: Integer): Boolean;
begin
  Result := (AAction >= 0) and (AAction < Length(FActions));
end;

function TRadixTriggerLogic.IsTrigger(ATrigger: Integer): Boolean;
begin
  Result := (ATrigger >= 0) and (ATrigger < Length(FTriggers));
end;

function TRadixTriggerLogic.Action(AAction: Integer): PRadixLevelAction;
begin
  if IsAction(AAction) then
    Result := @FActions[AAction]
  else
    Result := nil;
end;

function TRadixTriggerLogic.Trigger(ATrigger: Integer): PRadixLevelTrigger;
begin
  if IsTrigger(ATrigger) then
    Result := @FTriggers[ATrigger]
  else
    Result := nil;
end;

function TRadixTriggerLogic.IsActionRunnable(AAction: Integer): Boolean;
begin
  Result := IsAction(AAction) and (FActions[AAction].Enabled = ACTION_ENABLED) and
    (FActions[AAction].Suspend = ACTION_RUNNING);
end;

function TRadixTriggerLogic.NextRunnable(AFrom: Integer): Integer;
begin
  Result := AFrom;
  if Result < 0 then
    Result := 0;
  while Result < Length(FActions) do
  begin
    if (FActions[Result].Enabled = ACTION_ENABLED) and (FActions[Result].Suspend = ACTION_RUNNING) then
      Exit;
    Inc(Result);
  end;
  Result := Length(FActions);
end;

procedure TRadixTriggerLogic.SuspendAction(AAction: Integer);
begin
  if IsAction(AAction) then
    FActions[AAction].Suspend := ACTION_SUSPENDED;
end;

function TRadixTriggerLogic.IsTriggerSuspended(ATrigger: Integer): Boolean;
begin
  Result := not IsTrigger(ATrigger) or (FTriggers[ATrigger].Suspended <> TRIGGER_ACTIVE);
end;

procedure TRadixTriggerLogic.ActivateTrigger(ATrigger: Integer);
begin
  if IsTrigger(ATrigger) then
    FTriggers[ATrigger].Suspended := TRIGGER_ACTIVE;
end;

procedure TRadixTriggerLogic.DeactivateTrigger(ATrigger: Integer);
begin
  if IsTrigger(ATrigger) then
    FTriggers[ATrigger].Suspended := TRIGGER_SUSPENDED;
end;

procedure TRadixTriggerLogic.ApplyTriggerAction(const ATriggerAction: TRadixLevelTriggerAction);
var
  LAction: PRadixLevelAction;
begin
  LAction := Action(ATriggerAction.ActionId);
  if not Assigned(LAction) then
    Exit;
  case ATriggerAction.ActivationFlags of
    RADIX_TRIGGER_ACTIVATE:
      begin
        LAction.Suspend := ACTION_RUNNING;
        LAction.Enabled := ACTION_ENABLED;
      end;
    RADIX_TRIGGER_DEACTIVATE:
      LAction.Suspend := ACTION_SUSPENDED;
    RADIX_TRIGGER_TOGGLE:
      if LAction.Suspend = ACTION_RUNNING then
        LAction.Suspend := ACTION_SUSPENDED
      else
      begin
        LAction.Suspend := ACTION_RUNNING;
        LAction.Enabled := ACTION_ENABLED;
      end;
    // RADIX_TRIGGER_ACTIVATE_ON_SPACE: nothing in the old code either
  end;
end;

function TRadixTriggerLogic.RunTrigger(ATrigger: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := not IsTriggerSuspended(ATrigger);
  if not Result then
    Exit;
  for LIndex := 0 to FTriggers[ATrigger].NumActions - 1 do
    if LIndex < RADIX_MAX_TRIGGER_ACTIONS then
      ApplyTriggerAction(FTriggers[ATrigger].Actions[LIndex]);
end;

procedure TRadixTriggerLogic.ActivateAndRunTrigger(ATrigger: Integer);
begin
  ActivateTrigger(ATrigger);
  RunTrigger(ATrigger);
end;

function TRadixTriggerLogic.PlayerCrosses(APlayer: Integer; const AGrid: TRadixTriggerGrid;
  const ACells: TRadixGridPositions): Integer;
var
  LIndex: Integer;
  LTrigger: Integer;
  LRun: TRadixGridPositions;
  LCount: Integer;
begin
  Result := 0;
  if (APlayer < 0) or (APlayer >= Length(FLastTrigger)) then
    Exit;
  LRun := TRadixGridPositions.Empty;
  for LIndex := 0 to ACells.Count - 1 do
  begin
    if not AGrid.IsCell(ACells.Cells[LIndex]) then
      Continue;
    LTrigger := AGrid.TriggerAt(ACells.Cells[LIndex]);
    if FLastTrigger[APlayer] = LTrigger then
      Continue;
    FLastTrigger[APlayer] := LTrigger;
    if LTrigger < 0 then
      Continue;
    // a trigger is not run twice in a tic by the same craft (JVAL: 20200408)
    LCount := LRun.Count;
    LRun.Add(LTrigger);
    if LRun.Count = LCount then
      Continue;
    RunTrigger(LTrigger);
    Inc(Result);
  end;
end;

procedure TRadixTriggerLogic.ResetPlayer(APlayer: Integer);
begin
  if (APlayer >= 0) and (APlayer < Length(FLastTrigger)) then
    FLastTrigger[APlayer] := SPAWN_LAST_TRIGGER;
end;

function TRadixTriggerLogic.LastTrigger(APlayer: Integer): Integer;
begin
  if (APlayer >= 0) and (APlayer < Length(FLastTrigger)) then
    Result := FLastTrigger[APlayer]
  else
    Result := RADIX_NO_TRIGGER;
end;

function TRadixTriggerLogic.HasActionOfKind(AKind: Integer): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FActions) do
    if FActions[LIndex].ActionType = AKind then
      Exit(True);
  Result := False;
end;

function TRadixTriggerLogic.MissileWalls: TArray<Integer>;
var
  LIndex: Integer;
  LSeen: Integer;
  LWall: Integer;
  LCount: Integer;
  LKnown: Boolean;
begin
  SetLength(Result, Length(FActions));
  LCount := 0;
  for LIndex := 0 to High(FActions) do
    case FActions[LIndex].ActionType of
      RADIX_ACTION_COMPLETE_MISSILE_WALL, RADIX_ACTION_FLOOR_MISSILE_WALL,
      RADIX_ACTION_CEILING_MISSILE_WALL, RADIX_ACTION_SEEK_COMPLETE_MISSILE_WALL:
        begin
          LWall := FActions[LIndex].Params[0];
          if LWall < 0 then
            Continue;
          LKnown := False;
          for LSeen := 0 to LCount - 1 do
            if Result[LSeen] = LWall then
              LKnown := True;
          if not LKnown then
          begin
            Result[LCount] := LWall;
            Inc(LCount);
          end;
        end;
    end;
  SetLength(Result, LCount);
end;

function TRadixTriggerLogic.TriggerHasActionOfKind(ATrigger: Integer; AKind: Integer): Boolean;
var
  LIndex: Integer;
  LAction: PRadixLevelAction;
begin
  Result := False;
  if not IsTrigger(ATrigger) then
    Exit;
  for LIndex := 0 to FTriggers[ATrigger].NumActions - 1 do
  begin
    if LIndex >= RADIX_MAX_TRIGGER_ACTIONS then
      Break;
    LAction := Action(FTriggers[ATrigger].Actions[LIndex].ActionId);
    if Assigned(LAction) and (LAction.ActionType = AKind) then
      Exit(True);
  end;
end;

end.
