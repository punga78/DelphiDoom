{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGoalChooser, the choice of the goal item           }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotChooseLTGItem    }
{  and BotChooseNBGItem of code\botlib\be_ai_goal.c. Based on the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc.                                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Goal.Chooser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.World.Intf,
  DelphiDoom.BotAi.Weight.Evaluator, DelphiDoom.BotAi.Move.Intf, DelphiDoom.BotAi.Goal.Types,
  DelphiDoom.BotAi.Goal.LevelItems, DelphiDoom.BotAi.Goal.Context, DelphiDoom.BotAi.Goal.State;

type
  /// <summary>
  ///   Chooses the goal item with the fuzzy weights of the bot: the weight of the item is divided by its travel time
  ///   (the AAS), the items the bot avoids for a while do not count, and a dropped item weighs more. The caller
  ///   pushes the goal on the stack of the bot (the original does it at the end of the same function).
  ///   Doubles of the original kept: <c>avoidtime - t * 0.009</c> and <c>weight / (t * 0.01)</c> are doubles.
  /// </summary>
  TBotGoalChooser = class
  strict private
    FWorld: IBotAasWorld;
    FLibVars: IBotLibVars;
    FLocator: IBotReachabilityLocator;
    FContext: TBotGoalContext;
    FEvaluator: TBotFuzzyEvaluator;
    function ItemUsable(const AItem: PBotLevelItem): Boolean;
    function ItemWeight(const AState: TBotGoalState; const AItem: PBotLevelItem; const AInventory: TArray<Integer>;
      out AWeight: Single): Boolean;
    function BotArea(const AState: TBotGoalState; const AOrigin: TVec3): Integer;
    procedure MakeGoal(const AState: TBotGoalState; const AItem: PBotLevelItem; out AGoal: TBotGoal);
  public
    constructor Create(const AWorld: IBotAasWorld; const ALibVars: IBotLibVars;
      const ALocator: IBotReachabilityLocator; const AContext: TBotGoalContext);
    destructor Destroy; override;
    /// <summary>
    ///   BotChooseLTGItem: the area of the bot, the weights of all the usable items; false if there is no goal (the
    ///   goal is then cleared); otherwise the chosen goal is added to the goals to avoid for a while
    /// </summary>
    function ChooseLongTerm(const AState: TBotGoalState; const AOrigin: TVec3; const AInventory: TArray<Integer>;
      const ATravelFlags: Integer; out AGoal: TBotGoal): Boolean;
    /// <summary>
    ///   BotChooseNBGItem: the item may not be further away than AMaxTime and the way from it to the long term goal
    ///   may not be longer than the way from the bot (ALtg nil: no limit)
    /// </summary>
    function ChooseNearby(const AState: TBotGoalState; const AOrigin: TVec3; const AInventory: TArray<Integer>;
      const ATravelFlags: Integer; const ALtg: PBotGoal; const AMaxTime: Single; out AGoal: TBotGoal): Boolean;
  end;

implementation

uses
  DelphiDoom.BotAi.Exceptions, DelphiDoom.BotAi.Goal.ItemConfig;

const
  /// <summary>TRAVELTIME_SCALE: a double literal in the original</summary>
  TRAVELTIME_SCALE: Double = 0.01;
  /// <summary>The factor of the travel time in the test of the avoid time: a double literal in the original</summary>
  AVOID_TRAVELTIME_FACTOR: Double = 0.009;

resourcestring
  SNoWeightIndex = 'The item weights have no weight index for the item %d';

{ TBotGoalChooser }

constructor TBotGoalChooser.Create(const AWorld: IBotAasWorld; const ALibVars: IBotLibVars;
  const ALocator: IBotReachabilityLocator; const AContext: TBotGoalContext);
begin
  inherited Create;
  FWorld := AWorld;
  FLibVars := ALibVars;
  FLocator := ALocator;
  FContext := AContext;
  // FuzzyWeight does not use the generator
  FEvaluator := TBotFuzzyEvaluator.Create(nil);
end;

destructor TBotGoalChooser.Destroy;
begin
  FEvaluator.Free;
  inherited Destroy;
end;

function TBotGoalChooser.ItemUsable(const AItem: PBotLevelItem): Boolean;
begin
  Result := False;
  if FContext.GameType = GT_SINGLE_PLAYER then
  begin
    if (AItem.Flags and IFL_NOTSINGLE) <> 0 then
      Exit;
  end
  else if FContext.GameType >= GT_TEAM then
  begin
    if (AItem.Flags and IFL_NOTTEAM) <> 0 then
      Exit;
  end
  else
  begin
    if (AItem.Flags and IFL_NOTFREE) <> 0 then
      Exit;
  end;
  if (AItem.Flags and IFL_NOTBOT) <> 0 then
    Exit;
  // if the item is not in a possible goal area
  if AItem.GoalAreaNum = 0 then
    Exit;
  // items that never spawned into the game (f.i. CTF flags in obelisk)
  if (AItem.EntityNum = 0) and ((AItem.Flags and IFL_ROAM) = 0) then
    Exit;
  Result := True;
end;

function TBotGoalChooser.ItemWeight(const AState: TBotGoalState; const AItem: PBotLevelItem;
  const AInventory: TArray<Integer>; out AWeight: Single): Boolean;
var
  LNumber: Integer;
  LWeightNum: Integer;
begin
  AWeight := 0;
  // get the fuzzy weight function for this item
  LNumber := FContext.ItemConfig.Info(AItem.ItemInfo).Number;
  if (LNumber < 0) or (LNumber >= Length(AState.ItemWeightIndex)) then
    raise EBotAiException.CreateFmt(SNoWeightIndex, [LNumber]);
  LWeightNum := AState.ItemWeightIndex[LNumber];
  if LWeightNum < 0 then
    Exit(False);
  AWeight := FEvaluator.FuzzyWeight(AInventory, AState.ItemWeightConfig, LWeightNum);
  // HACK: to make dropped items more attractive
  if AItem.Timeout <> 0 then
    AWeight := AWeight + FLibVars.GetValue('droppedweight');
  // use weight scale for item_botroam
  if (AItem.Flags and IFL_ROAM) <> 0 then
    AWeight := AWeight * AItem.Weight;
  Result := True;
end;

function TBotGoalChooser.BotArea(const AState: TBotGoalState; const AOrigin: TVec3): Integer;
begin
  // get the area the bot is in
  Result := FLocator.ReachabilityArea(AOrigin, AState.Client);
  // if the bot is in solid or if the area the bot is in has no reachability links
  if (Result = 0) or (FWorld.Areas.AreaReachability(Result) = 0) then
    // use the last valid area the bot was in
    Result := AState.LastReachabilityArea;
  // remember the last area with reachabilities the bot was in
  AState.LastReachabilityArea := Result;
end;

procedure TBotGoalChooser.MakeGoal(const AState: TBotGoalState; const AItem: PBotLevelItem; out AGoal: TBotGoal);
var
  LInfo: TBotItemInfo;
  LAvoidTime: Single;
begin
  LInfo := FContext.ItemConfig.Info(AItem.ItemInfo);
  AGoal := Default(TBotGoal);
  // create a bot goal for this item
  AGoal.Origin := AItem.GoalOrigin;
  AGoal.Mins := LInfo.Mins;
  AGoal.Maxs := LInfo.Maxs;
  AGoal.AreaNum := AItem.GoalAreaNum;
  AGoal.EntityNum := AItem.EntityNum;
  AGoal.Number := AItem.Number;
  AGoal.Flags := GFL_ITEM;
  if AItem.Timeout <> 0 then
    AGoal.Flags := AGoal.Flags or GFL_DROPPED;
  if (AItem.Flags and IFL_ROAM) <> 0 then
    AGoal.Flags := AGoal.Flags or GFL_ROAM;
  AGoal.ItemInfo := AItem.ItemInfo;
  // if it's a dropped item
  if AItem.Timeout <> 0 then
    LAvoidTime := AVOID_DROPPED_TIME
  else
  begin
    LAvoidTime := LInfo.RespawnTime;
    if LAvoidTime = 0 then
      LAvoidTime := AVOID_DEFAULT_TIME;
    if LAvoidTime < AVOID_MINIMUM_TIME then
      LAvoidTime := AVOID_MINIMUM_TIME;
  end;
  // add the chosen goal to the goals to avoid for a while
  AState.AddToAvoidGoals(AItem.Number, LAvoidTime, FWorld.Time);
end;


function TBotGoalChooser.ChooseLongTerm(const AState: TBotGoalState; const AOrigin: TVec3;
  const AInventory: TArray<Integer>; const ATravelFlags: Integer; out AGoal: TBotGoal): Boolean;
var
  LOrigin: TVec3;
  LAreaNum: Integer;
  LWeight: Single;
  LBestWeight: Single;
  LAvoidTime: Single;
  LTime: Integer;
  LDivisor: Double;
  LQuotient: Double;
  LCurrent: Integer;
  LThis: Integer;
  LBestItem: Integer;
  LItem: PBotLevelItem;
begin
  AGoal := Default(TBotGoal);
  LOrigin := AOrigin;
  if not Assigned(AState.ItemWeightConfig) then
    Exit(False);
  LAreaNum := BotArea(AState, LOrigin);
  // if still in solid
  if LAreaNum = 0 then
    Exit(False);
  // the item configuration
  if not Assigned(FContext.ItemConfig) then
    Exit(False);
  // best weight and item so far
  LBestWeight := 0;
  LBestItem := TBotLevelItems.NoItem;
  // go through the items in the level
  LCurrent := FContext.LevelItems.Head;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LThis := LCurrent;
    LItem := FContext.LevelItems.Item(LThis);
    LCurrent := LItem.Next;
    if not ItemUsable(LItem) then
      Continue;
    if not ItemWeight(AState, LItem, AInventory, LWeight) then
      Continue;
    if LWeight > 0 then
    begin
      // get the travel time towards the goal area
      LTime := FWorld.Router.AreaTravelTimeToGoalArea(LAreaNum, @LOrigin, LItem.GoalAreaNum, ATravelFlags);
      // if the goal is reachable
      if LTime > 0 then
      begin
        // if this item won't respawn before we get there
        LAvoidTime := AState.AvoidGoalTime(LItem.Number, FWorld.Time);
        if Double(LAvoidTime) - Double(LTime) * AVOID_TRAVELTIME_FACTOR > 0 then
          Continue;
        LDivisor := Double(Single(LTime)) * TRAVELTIME_SCALE;
        LQuotient := Double(LWeight) / LDivisor;
        LWeight := LQuotient;
        if LWeight > LBestWeight then
        begin
          LBestWeight := LWeight;
          LBestItem := LThis;
        end;
      end;
    end;
  end;
  // if no goal item found (the roam goal of the original is commented out)
  if LBestItem = TBotLevelItems.NoItem then
    Exit(False);
  MakeGoal(AState, FContext.LevelItems.Item(LBestItem), AGoal);
  Result := True;
end;

function TBotGoalChooser.ChooseNearby(const AState: TBotGoalState; const AOrigin: TVec3;
  const AInventory: TArray<Integer>; const ATravelFlags: Integer; const ALtg: PBotGoal; const AMaxTime: Single;
  out AGoal: TBotGoal): Boolean;
var
  LOrigin: TVec3;
  LAreaNum: Integer;
  LWeight: Single;
  LBestWeight: Single;
  LAvoidTime: Single;
  LTime: Integer;
  LLtgTime: Integer;
  LDivisor: Double;
  LQuotient: Double;
  LCurrent: Integer;
  LThis: Integer;
  LBestItem: Integer;
  LItem: PBotLevelItem;
begin
  AGoal := Default(TBotGoal);
  LOrigin := AOrigin;
  if not Assigned(AState.ItemWeightConfig) then
    Exit(False);
  LAreaNum := BotArea(AState, LOrigin);
  // if still in solid
  if LAreaNum = 0 then
    Exit(False);
  if Assigned(ALtg) then
    LLtgTime := FWorld.Router.AreaTravelTimeToGoalArea(LAreaNum, @LOrigin, ALtg.AreaNum, ATravelFlags)
  else
    LLtgTime := 99999;
  // the item configuration
  if not Assigned(FContext.ItemConfig) then
    Exit(False);
  // best weight and item so far
  LBestWeight := 0;
  LBestItem := TBotLevelItems.NoItem;
  // go through the items in the level
  LCurrent := FContext.LevelItems.Head;
  while LCurrent <> TBotLevelItems.NoItem do
  begin
    LThis := LCurrent;
    LItem := FContext.LevelItems.Item(LThis);
    LCurrent := LItem.Next;
    if not ItemUsable(LItem) then
      Continue;
    if not ItemWeight(AState, LItem, AInventory, LWeight) then
      Continue;
    if LWeight > 0 then
    begin
      // get the travel time towards the goal area
      LTime := FWorld.Router.AreaTravelTimeToGoalArea(LAreaNum, @LOrigin, LItem.GoalAreaNum, ATravelFlags);
      // if the goal is reachable
      if (LTime > 0) and (Single(LTime) < AMaxTime) then
      begin
        // if this item won't respawn before we get there
        LAvoidTime := AState.AvoidGoalTime(LItem.Number, FWorld.Time);
        if Double(LAvoidTime) - Double(LTime) * AVOID_TRAVELTIME_FACTOR > 0 then
          Continue;
        LDivisor := Double(Single(LTime)) * TRAVELTIME_SCALE;
        LQuotient := Double(LWeight) / LDivisor;
        LWeight := LQuotient;
        if LWeight > LBestWeight then
        begin
          LTime := 0;
          if Assigned(ALtg) and (LItem.Timeout = 0) then
            // get the travel time from the goal to the long term goal
            LTime := FWorld.Router.AreaTravelTimeToGoalArea(LItem.GoalAreaNum, @LItem.GoalOrigin, ALtg.AreaNum,
              ATravelFlags);
          // if the travel back is possible and doesn't take too long
          if LTime <= LLtgTime then
          begin
            LBestWeight := LWeight;
            LBestItem := LThis;
          end;
        end;
      end;
    end;
  end;
  // if no goal item found
  if LBestItem = TBotLevelItems.NoItem then
    Exit(False);
  MakeGoal(AState, FContext.LevelItems.Item(LBestItem), AGoal);
  Result := True;
end;

end.
