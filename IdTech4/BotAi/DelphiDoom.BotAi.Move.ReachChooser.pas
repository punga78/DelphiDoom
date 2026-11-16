{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotReachabilityChooser, the reachability to the goal  }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotValidTravel and  }
{  BotGetReachabilityToGoal of code\botlib\be_ai_move.c. Based on the Quake    }
{  III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id         }
{  Software, Inc.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.ReachChooser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Move.Types,
  DelphiDoom.BotAi.Move.Context;

type
  /// <summary>
  ///   Which reachability of the area leads best towards the goal: the one with the shortest travel time (its own
  ///   time plus the time from its end to the goal), not one that goes back to the area the bot came from while the
  ///   goal is the same, not one the bot avoids, not one that goes towards an avoid spot.
  /// </summary>
  TBotReachabilityChooser = class
  strict private
    FContext: TBotMoveContext;
  public
    constructor Create(const AContext: TBotMoveContext);
    /// <summary>
    ///   BotValidTravel: the travel type and the contents of the area of the reachability are all allowed
    ///   by the travel flags
    /// </summary>
    function ValidTravel(const AReach: TAasReachability; const ATravelFlags: Integer): Boolean;
    /// <summary>
    ///   BotGetReachabilityToGoal: the number of the reachability, 0 if there is none; AFlags (may be nil) gets
    ///   MOVERESULT_BLOCKEDBYAVOIDSPOT if an avoid spot stopped one
    /// </summary>
    function GetReachabilityToGoal(const AOrigin: TVec3; const AAreaNum, ALastGoalAreaNum, ALastAreaNum: Integer;
      const AAvoidReach: array of Integer; const AAvoidReachTimes: array of Single;
      const AAvoidReachTries: array of Integer; const AGoal: TBotGoal; const ATravelFlags, AMoveTravelFlags: Integer;
      const AAvoidSpots: array of TBotAvoidSpot; const ANumAvoidSpots: Integer; const AFlags: PInteger): Integer;
  end;

implementation

uses
  DelphiDoom.Aas.Route.Types, DelphiDoom.BotAi.Move.AvoidSpots;

const
  /// <summary>AVOIDREACH_TRIES: a reachability that was used more times than this is avoided</summary>
  AVOIDREACH_TRIES = 4;

{ TBotReachabilityChooser }

constructor TBotReachabilityChooser.Create(const AContext: TBotMoveContext);
begin
  inherited Create;
  FContext := AContext;
end;

function TBotReachabilityChooser.ValidTravel(const AReach: TAasReachability; const ATravelFlags: Integer): Boolean;
begin
  // if the reachability uses an unwanted travel type
  if (FContext.World.Router.TravelFlagForType(AReach.TravelType) and not ATravelFlags) <> 0 then
    Exit(False);
  // don't go into areas with bad travel types
  if (FContext.World.Router.AreaContentsTravelFlags(AReach.AreaNum) and not ATravelFlags) <> 0 then
    Exit(False);
  Result := True;
end;

function TBotReachabilityChooser.GetReachabilityToGoal(const AOrigin: TVec3; const AAreaNum, ALastGoalAreaNum,
  ALastAreaNum: Integer; const AAvoidReach: array of Integer; const AAvoidReachTimes: array of Single;
  const AAvoidReachTries: array of Integer; const AGoal: TBotGoal; const ATravelFlags, AMoveTravelFlags: Integer;
  const AAvoidSpots: array of TBotAvoidSpot; const ANumAvoidSpots: Integer; const AFlags: PInteger): Integer;
var
  LTravelFlags: Integer;
  LMoveTravelFlags: Integer;
  LReachNum: Integer;
  LReach: TAasReachability;
  LIndex: Integer;
  LTime: Integer;
  LBestTime: Integer;
  LBestReachNum: Integer;
  LEnd: TVec3;
begin
  // if not in a valid area
  if AAreaNum = 0 then
    Exit(0);
  LTravelFlags := ATravelFlags;
  LMoveTravelFlags := AMoveTravelFlags;
  if (FContext.World.Areas.AreaDoNotEnter(AAreaNum)) or (FContext.World.Areas.AreaDoNotEnter(AGoal.AreaNum)) then
  begin
    LTravelFlags := LTravelFlags or TFL_DONOTENTER;
    LMoveTravelFlags := LMoveTravelFlags or TFL_DONOTENTER;
  end;
  // use the routing to find the next area to go to
  LBestTime := 0;
  LBestReachNum := 0;
  LReachNum := FContext.World.Router.NextAreaReachability(AAreaNum, 0);
  while LReachNum <> 0 do
  begin
    // check if it isn't an reachability to avoid
    LIndex := 0;
    while LIndex < MAX_AVOIDREACH do
    begin
      if (AAvoidReach[LIndex] = LReachNum) and (AAvoidReachTimes[LIndex] >= FContext.World.Time) then
        Break;
      Inc(LIndex);
    end;
    if (LIndex <> MAX_AVOIDREACH) and (AAvoidReachTries[LIndex] > AVOIDREACH_TRIES) then
    begin
      LReachNum := FContext.World.Router.NextAreaReachability(AAreaNum, LReachNum);
      Continue;
    end;
    // get the reachability from the number
    FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
    // NOTE: do not go back to the previous area if the goal didn't change
    if (ALastGoalAreaNum = AGoal.AreaNum) and (LReach.AreaNum = ALastAreaNum) then
    begin
      LReachNum := FContext.World.Router.NextAreaReachability(AAreaNum, LReachNum);
      Continue;
    end;
    // if the travel isn't valid
    if ValidTravel(LReach, LMoveTravelFlags) then
    begin
      // get the travel time
      LEnd := LReach.EndPoint;
      LTime := FContext.World.Router.AreaTravelTimeToGoalArea(LReach.AreaNum, @LEnd, AGoal.AreaNum, LTravelFlags);
      // if the goal area isn't reachable from the reachable area
      if LTime <> 0 then
      begin
        // if the bot should not use this reachability to avoid bad spots
        if TBotAvoidSpotChecker.Check(AOrigin, LReach, AAvoidSpots, ANumAvoidSpots) <> 0 then
        begin
          if Assigned(AFlags) then
            AFlags^ := AFlags^ or MOVERESULT_BLOCKEDBYAVOIDSPOT;
        end
        else
        begin
          // add the travel time towards the area
          LTime := LTime + LReach.TravelTime;
          // if the travel time is better than the ones already found
          if (LBestTime = 0) or (LTime < LBestTime) then
          begin
            LBestTime := LTime;
            LBestReachNum := LReachNum;
          end;
        end;
      end;
    end;
    LReachNum := FContext.World.Router.NextAreaReachability(AAreaNum, LReachNum);
  end;
  Result := LBestReachNum;
end;

end.
