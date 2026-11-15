{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMovePredictor, where the bot will be going         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): BotAddToTarget,     }
{  BotMovementViewTarget, BotVisible and BotPredictVisiblePosition of          }
{  code\botlib\be_ai_move.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Predictor;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Goal.Types, DelphiDoom.BotAi.Move.Context, DelphiDoom.BotAi.Move.State,
  DelphiDoom.BotAi.Move.ReachChooser;

type
  /// <summary>The point of the way to the goal that the bot should look at, and where the goal can be seen from</summary>
  TBotMovePredictor = class
  strict private
    FContext: TBotMoveContext;
    FChooser: TBotReachabilityChooser;
    class function AddToTarget(const AStart, AEnd: TVec3; const AMaxDist: Single; var ADist: Single;
      var ATarget: TVec3): Boolean; static;
    function Visible(const AEntity: Integer; const AEye, ATarget: TVec3): Boolean;
  public
    constructor Create(const AContext: TBotMoveContext; const AChooser: TBotReachabilityChooser);
    /// <summary>
    ///   BotMovementViewTarget: follows the reachabilities from the last one the bot used towards the goal for
    ///   ALookAhead units; the point where the distance is used up
    /// </summary>
    function MovementViewTarget(const AState: TBotMoveState; const AGoal: PBotGoal; const ATravelFlags: Integer;
      const ALookAhead: Single; out ATarget: TVec3): Boolean;
    /// <summary>
    ///   BotPredictVisiblePosition: up to 20 hops from the area towards the goal: the start or the end of the first
    ///   reachability that the goal can see (or the end of the one that enters the goal area)
    /// </summary>
    function PredictVisiblePosition(const AOrigin: TVec3; const AAreaNum: Integer; const AGoal: PBotGoal;
      const ATravelFlags: Integer; out ATarget: TVec3): Boolean;
  end;

implementation

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.Types,
  DelphiDoom.BotAi.Move.VectorMath;

const
  MASK_SOLID_PLAYERCLIP = $00010001;
  /// <summary>Only 20 hops</summary>
  MAX_HOPS = 20;

{ TBotMovePredictor }

constructor TBotMovePredictor.Create(const AContext: TBotMoveContext; const AChooser: TBotReachabilityChooser);
begin
  inherited Create;
  FContext := AContext;
  FChooser := AChooser;
end;

class function TBotMovePredictor.AddToTarget(const AStart, AEnd: TVec3; const AMaxDist: Single; var ADist: Single;
  var ATarget: TVec3): Boolean;
var
  LDir: TVec3;
  LCurDist: Single;
  LSum: Single;
  LRemaining: Single;
begin
  TAasVectorMath.Subtract(AEnd, AStart, LDir);
  LCurDist := TAasVectorMath.Normalize(LDir);
  LSum := ADist + LCurDist;
  if LSum < AMaxDist then
  begin
    ATarget := AEnd;
    ADist := LSum;
    Result := False;
  end
  else
  begin
    LRemaining := AMaxDist - ADist;
    TBotVectorMath.MultiplyAdd(AStart, LRemaining, LDir, ATarget);
    ADist := AMaxDist;
    Result := True;
  end;
end;

function TBotMovePredictor.Visible(const AEntity: Integer; const AEye, ATarget: TVec3): Boolean;
var
  LTrace: TAasBspTrace;
begin
  LTrace := FContext.World.Bsp.Trace(AEye, nil, nil, ATarget, AEntity, MASK_SOLID_PLAYERCLIP);
  Result := LTrace.Fraction >= 1;
end;

function TBotMovePredictor.MovementViewTarget(const AState: TBotMoveState; const AGoal: PBotGoal;
  const ATravelFlags: Integer; const ALookAhead: Single; out ATarget: TVec3): Boolean;
var
  LReach: TAasReachability;
  LReachNum: Integer;
  LLastAreaNum: Integer;
  LEnd: TVec3;
  LDist: Single;
  LKind: Integer;
  LNoSpots: array[0..0] of TBotAvoidSpot;
begin
  ATarget := Default(TVec3);
  // if the bot has no goal or no last reachability
  if (AState.LastReachNum = 0) or (not Assigned(AGoal)) then
    Exit(False);
  LNoSpots[0] := Default(TBotAvoidSpot);
  LReachNum := AState.LastReachNum;
  LEnd := AState.Origin;
  LLastAreaNum := AState.LastAreaNum;
  LDist := 0;
  while (LReachNum <> 0) and (LDist < ALookAhead) do
  begin
    FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
    if AddToTarget(LEnd, LReach.StartPoint, ALookAhead, LDist, ATarget) then
      Exit(True);
    LKind := LReach.TravelType and TRAVELTYPE_MASK;
    // never look beyond teleporters
    if LKind = TRAVEL_TELEPORT then
      Exit(True);
    // never look beyond the weapon jump point
    if LKind = TRAVEL_ROCKETJUMP then
      Exit(True);
    if LKind = TRAVEL_BFGJUMP then
      Exit(True);
    // don't add jump pad distances
    if (LKind <> TRAVEL_JUMPPAD) and (LKind <> TRAVEL_ELEVATOR) and (LKind <> TRAVEL_FUNCBOB) then
    begin
      if AddToTarget(LReach.StartPoint, LReach.EndPoint, ALookAhead, LDist, ATarget) then
        Exit(True);
    end;
    LReachNum := FChooser.GetReachabilityToGoal(LReach.EndPoint, LReach.AreaNum, AState.LastGoalAreaNum, LLastAreaNum,
      AState.AvoidReach, AState.AvoidReachTimes, AState.AvoidReachTries, AGoal^, ATravelFlags, ATravelFlags,
      LNoSpots, 0, nil);
    LEnd := LReach.EndPoint;
    LLastAreaNum := LReach.AreaNum;
    if LLastAreaNum = AGoal.AreaNum then
    begin
      AddToTarget(LReach.EndPoint, AGoal.Origin, ALookAhead, LDist, ATarget);
      Exit(True);
    end;
  end;
  Result := False;
end;

function TBotMovePredictor.PredictVisiblePosition(const AOrigin: TVec3; const AAreaNum: Integer;
  const AGoal: PBotGoal; const ATravelFlags: Integer; out ATarget: TVec3): Boolean;
var
  LReach: TAasReachability;
  LReachNum: Integer;
  LLastGoalAreaNum: Integer;
  LLastAreaNum: Integer;
  LAreaNum: Integer;
  LIndex: Integer;
  LAvoidReach: array[0..MAX_AVOIDREACH - 1] of Integer;
  LAvoidReachTimes: array[0..MAX_AVOIDREACH - 1] of Single;
  LAvoidReachTries: array[0..MAX_AVOIDREACH - 1] of Integer;
  LNoSpots: array[0..0] of TBotAvoidSpot;
  LEnd: TVec3;
  LStart: TVec3;
begin
  ATarget := Default(TVec3);
  // if the bot has no goal or no last reachability
  if not Assigned(AGoal) then
    Exit(False);
  // if the areanum is not valid
  if AAreaNum = 0 then
    Exit(False);
  // if the goal areanum is not valid
  if AGoal.AreaNum = 0 then
    Exit(False);
  for LIndex := 0 to MAX_AVOIDREACH - 1 do
  begin
    LAvoidReach[LIndex] := 0;
    // only the reachabilities are cleared in the original; the times and the tries are never read while the
    // reachability is 0, which is never the number of a reachability
    LAvoidReachTimes[LIndex] := 0;
    LAvoidReachTries[LIndex] := 0;
  end;
  LNoSpots[0] := Default(TBotAvoidSpot);
  LLastGoalAreaNum := AGoal.AreaNum;
  LLastAreaNum := AAreaNum;
  LAreaNum := AAreaNum;
  LEnd := AOrigin;
  // only do 20 hops
  LIndex := 0;
  while (LIndex < MAX_HOPS) and (LAreaNum <> AGoal.AreaNum) do
  begin
    LReachNum := FChooser.GetReachabilityToGoal(LEnd, LAreaNum, LLastGoalAreaNum, LLastAreaNum, LAvoidReach,
      LAvoidReachTimes, LAvoidReachTries, AGoal^, ATravelFlags, ATravelFlags, LNoSpots, 0, nil);
    if LReachNum = 0 then
      Exit(False);
    FContext.World.Router.ReachabilityFromNum(LReachNum, LReach);
    LStart := LReach.StartPoint;
    if Visible(AGoal.EntityNum, AGoal.Origin, LStart) then
    begin
      ATarget := LReach.StartPoint;
      Exit(True);
    end;
    if Visible(AGoal.EntityNum, AGoal.Origin, LReach.EndPoint) then
    begin
      ATarget := LReach.EndPoint;
      Exit(True);
    end;
    if LReach.AreaNum = AGoal.AreaNum then
    begin
      ATarget := LReach.EndPoint;
      Exit(True);
    end;
    LLastAreaNum := LAreaNum;
    LAreaNum := LReach.AreaNum;
    LEnd := LReach.EndPoint;
    Inc(LIndex);
  end;
  Result := False;
end;

end.
