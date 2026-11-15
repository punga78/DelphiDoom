{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotElevatorTravel, BotTravel_Elevator                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Elevator;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_ELEVATOR: wait for the plat to come down, walk onto its center, ride it and step off at the end. Defect
  ///   of the original kept: the height test <c>abs(origin[2] - end[2]) &lt; sv_maxbarrier</c> uses the integer abs
  ///   (the difference is cut to an int).
  /// </summary>
  TBotElevatorTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotElevatorTravel }

function TBotElevatorTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
  LDir1: TVec3;
  LDir2: TVec3;
  LHorDir: TVec3;
  LBottomCenter: TVec3;
  LDist: Single;
  LDist1: Single;
  LDist2: Single;
  LSpeed: Single;
  LHeight: Single;
  LDot: Single;
begin
  Result := Default(TBotMoveResult);
  // if standing on the plat
  if FMovers.OnMover(AState.Origin, AState.EntityNum, AReach) then
  begin
    // if vertically not too far from the end point
    LHeight := AState.Origin[2] - AReach.EndPoint[2];
    if Abs(Trunc(LHeight)) < FContext.Vars.MaxBarrier then
    begin
      // move to the end point
      LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
      TAasVectorMath.Normalize(LHorDir);
      if not FBasics.CheckBarrierJump(AState, LHorDir, 100) then
        FContext.Actions.Move(AState.Client, LHorDir, 400);
      Result.MoveDir := LHorDir;
    end
    // if not really close to the center of the elevator
    else
    begin
      FMovers.MoverBottomCenter(AReach, LBottomCenter);
      LHorDir := HorizontalDelta(LBottomCenter, AState.Origin);
      LDist := TAasVectorMath.Normalize(LHorDir);
      if LDist > 10 then
      begin
        // move to the center of the plat
        if LDist > 100 then
          LDist := 100;
        LSpeed := Ramp(400, 400, 4, LDist);
        FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
        Result.MoveDir := LHorDir;
      end;
    end;
  end
  else
  begin
    // if very near the reachability end
    TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LDir);
    LDist := TAasVectorMath.Length(LDir);
    if LDist < 64 then
    begin
      if LDist > 60 then
        LDist := 60;
      LSpeed := Ramp(360, 360, 6, LDist);
      if ((AState.MoveFlags and MFL_SWIMMING) <> 0) or (not FBasics.CheckBarrierJump(AState, LDir, 50)) then
      begin
        if LSpeed > 5 then
          FContext.Actions.Move(AState.Client, LDir, LSpeed);
      end;
      Result.MoveDir := LDir;
      if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
        Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
      // stop using this reachability
      AState.ReachabilityTime := 0;
      Exit;
    end;
    // get direction and distance to reachability start
    TAasVectorMath.Subtract(AReach.StartPoint, AState.Origin, LDir1);
    if (AState.MoveFlags and MFL_SWIMMING) = 0 then
      LDir1[2] := 0;
    LDist1 := TAasVectorMath.Normalize(LDir1);
    // if the elevator isn't down
    if not FMovers.MoverDown(AReach) then
    begin
      LDist := LDist1;
      LDir := LDir1;
      FBasics.CheckBlocked(AState, LDir, False, Result);
      if LDist > 60 then
        LDist := 60;
      LSpeed := Ramp(360, 360, 6, LDist);
      if ((AState.MoveFlags and MFL_SWIMMING) = 0) and (not FBasics.CheckBarrierJump(AState, LDir, 50)) then
      begin
        if LSpeed > 5 then
          FContext.Actions.Move(AState.Client, LDir, LSpeed);
      end;
      Result.MoveDir := LDir;
      if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
        Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
      // this isn't a failure... just wait till the elevator comes down
      Result.ResultType := RESULTTYPE_ELEVATORUP;
      Result.Flags := Result.Flags or MOVERESULT_WAITING;
      Exit;
    end;
    // get direction and distance to elevator bottom center
    FMovers.MoverBottomCenter(AReach, LBottomCenter);
    TAasVectorMath.Subtract(LBottomCenter, AState.Origin, LDir2);
    if (AState.MoveFlags and MFL_SWIMMING) = 0 then
      LDir2[2] := 0;
    LDist2 := TAasVectorMath.Normalize(LDir2);
    LDot := TAasVectorMath.Dot(LDir1, LDir2);
    // if very close to the reachability start or closer to the elevator center or between the start and the center
    if (LDist1 < 20) or (LDist2 < LDist1) or (LDot < 0) then
    begin
      LDist := LDist2;
      LDir := LDir2;
    end
    // closer to the reachability start
    else
    begin
      LDist := LDist1;
      LDir := LDir1;
    end;
    FBasics.CheckBlocked(AState, LDir, False, Result);
    if LDist > 60 then
      LDist := 60;
    LSpeed := Ramp(400, 400, 6, LDist);
    if ((AState.MoveFlags and MFL_SWIMMING) = 0) and (not FBasics.CheckBarrierJump(AState, LDir, 50)) then
      FContext.Actions.Move(AState.Client, LDir, LSpeed);
    Result.MoveDir := LDir;
    if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
      Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
  end;
end;

function TBotElevatorTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LBottomCenter: TVec3;
  LBottomDir: TVec3;
  LTopDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  FMovers.MoverBottomCenter(AReach, LBottomCenter);
  TAasVectorMath.Subtract(LBottomCenter, AState.Origin, LBottomDir);
  TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LTopDir);
  if Abs(LBottomDir[2]) < Abs(LTopDir[2]) then
  begin
    TAasVectorMath.Normalize(LBottomDir);
    FContext.Actions.Move(AState.Client, LBottomDir, 300);
  end
  else
  begin
    TAasVectorMath.Normalize(LTopDir);
    FContext.Actions.Move(AState.Client, LTopDir, 300);
  end;
end;

end.
