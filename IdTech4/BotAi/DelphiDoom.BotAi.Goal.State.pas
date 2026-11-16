{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGoalState, the goal state of a bot                 }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_goalstate_t     }
{  and the avoid goals (BotAddToAvoidGoals, BotRemoveFromAvoidGoals,           }
{  BotAvoidGoalTime, BotResetAvoidGoals) of code\botlib\be_ai_goal.c. Based on }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc.                                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.State;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.BotAi.Weight.Config, DelphiDoom.BotAi.Goal.Types;

type
  /// <summary>
  ///   The state of one bot: its item weights (owned by the cache of weight files), the goal stack and the goals to
  ///   avoid for a while. A cleared goal state (GetClearedMemory) is the one that is made.
  /// </summary>
  TBotGoalState = class
  strict private
    FAvoidGoals: array[0..MAX_AVOIDGOALS - 1] of Integer;
    FAvoidGoalTimes: array[0..MAX_AVOIDGOALS - 1] of Single;
  public
    /// <summary>The weight configuration of the items; not owned (the cache of weight files owns it)</summary>
    ItemWeightConfig: TBotWeightConfig;
    /// <summary>Index from the item to its weight</summary>
    ItemWeightIndex: TArray<Integer>;
    /// <summary>The client using this goal state</summary>
    Client: Integer;
    /// <summary>The last area with reachabilities the bot was in</summary>
    LastReachabilityArea: Integer;
    GoalStack: array[0..MAX_GOALSTACK - 1] of TBotGoal;
    /// <summary>The top of the goal stack (0: empty; the first goal is in entry 1)</summary>
    GoalStackTop: Integer;
    /// <summary>BotResetAvoidGoals</summary>
    procedure ResetAvoidGoals;
    /// <summary>
    ///   BotAddToAvoidGoals: the goal number is stored (or its time updated) for AAvoidTime seconds from ATime; with
    ///   no free entry nothing is stored
    /// </summary>
    procedure AddToAvoidGoals(const ANumber: Integer; const AAvoidTime, ATime: Single);
    /// <summary>BotRemoveFromAvoidGoals</summary>
    procedure RemoveFromAvoidGoals(const ANumber: Integer; const ATime: Single);
    /// <summary>BotAvoidGoalTime: the seconds left that the goal is avoided, 0 if it is not</summary>
    function AvoidGoalTime(const ANumber: Integer; const ATime: Single): Single;
    /// <summary>The goal avoided in the entry, for the dump</summary>
    function AvoidGoalNumber(const AIndex: Integer): Integer;
    /// <summary>The time the entry is avoided until</summary>
    function AvoidGoalUntil(const AIndex: Integer): Single;
  end;

implementation

{ TBotGoalState }

procedure TBotGoalState.ResetAvoidGoals;
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_AVOIDGOALS - 1 do
  begin
    FAvoidGoals[LIndex] := 0;
    FAvoidGoalTimes[LIndex] := 0;
  end;
end;

procedure TBotGoalState.AddToAvoidGoals(const ANumber: Integer; const AAvoidTime, ATime: Single);
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_AVOIDGOALS - 1 do
  begin
    // if the avoid goal is already stored
    if FAvoidGoals[LIndex] = ANumber then
    begin
      FAvoidGoals[LIndex] := ANumber;
      FAvoidGoalTimes[LIndex] := ATime + AAvoidTime;
      Exit;
    end;
  end;
  for LIndex := 0 to MAX_AVOIDGOALS - 1 do
  begin
    // if this avoid goal has expired
    if FAvoidGoalTimes[LIndex] < ATime then
    begin
      FAvoidGoals[LIndex] := ANumber;
      FAvoidGoalTimes[LIndex] := ATime + AAvoidTime;
      Exit;
    end;
  end;
end;

procedure TBotGoalState.RemoveFromAvoidGoals(const ANumber: Integer; const ATime: Single);
var
  LIndex: Integer;
begin
  // don't use the goals the bot wants to avoid
  for LIndex := 0 to MAX_AVOIDGOALS - 1 do
  begin
    if (FAvoidGoals[LIndex] = ANumber) and (FAvoidGoalTimes[LIndex] >= ATime) then
    begin
      FAvoidGoalTimes[LIndex] := 0;
      Exit;
    end;
  end;
end;

function TBotGoalState.AvoidGoalTime(const ANumber: Integer; const ATime: Single): Single;
var
  LIndex: Integer;
begin
  // don't use the goals the bot wants to avoid
  for LIndex := 0 to MAX_AVOIDGOALS - 1 do
  begin
    if (FAvoidGoals[LIndex] = ANumber) and (FAvoidGoalTimes[LIndex] >= ATime) then
    begin
      Result := FAvoidGoalTimes[LIndex] - ATime;
      Exit;
    end;
  end;
  Result := 0;
end;

function TBotGoalState.AvoidGoalNumber(const AIndex: Integer): Integer;
begin
  Result := FAvoidGoals[AIndex];
end;

function TBotGoalState.AvoidGoalUntil(const AIndex: Integer): Single;
begin
  Result := FAvoidGoalTimes[AIndex];
end;

end.
