{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotFuncBobTravel, BotTravel_FuncBobbing               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.FuncBob;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_FUNCBOB: ride a func_bobbing from its start to its end. Defects of the original kept:
  ///   <c>BotFinishTravel_FuncBobbing</c> moves along <c>dir</c> (the way the bob is from its end) and not along the
  ///   direction it just worked out. Without an entity for the model the original uses an origin that was never
  ///   set; here it is zero.
  /// </summary>
  TBotFuncBobTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotFuncBobTravel }

function TBotFuncBobTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
  LDir1: TVec3;
  LDir2: TVec3;
  LHorDir: TVec3;
  LBottomCenter: TVec3;
  LBobStart: TVec3;
  LBobEnd: TVec3;
  LBobOrigin: TVec3;
  LDist: Single;
  LDist1: Single;
  LDist2: Single;
  LSpeed: Single;
  LDot: Single;
begin
  Result := Default(TBotMoveResult);
  LBobOrigin := Default(TVec3);
  FMovers.FuncBobStartEnd(AReach, LBobStart, LBobEnd, LBobOrigin);
  // if standing ontop of the func_bobbing
  if FMovers.OnMover(AState.Origin, AState.EntityNum, AReach) then
  begin
    // if near end point of reachability
    TAasVectorMath.Subtract(LBobOrigin, LBobEnd, LDir);
    if TAasVectorMath.Length(LDir) < 24 then
    begin
      // move to the end point
      TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LHorDir);
      LHorDir[2] := 0;
      TAasVectorMath.Normalize(LHorDir);
      if not FBasics.CheckBarrierJump(AState, LHorDir, 100) then
        FContext.Actions.Move(AState.Client, LHorDir, 400);
      Result.MoveDir := LHorDir;
    end
    // if not really close to the center of the elevator
    else
    begin
      FMovers.MoverBottomCenter(AReach, LBottomCenter);
      TAasVectorMath.Subtract(LBottomCenter, AState.Origin, LHorDir);
      LHorDir[2] := 0;
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
      // if swimming or no barrier jump
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
    // if func_bobbing is Not it's start position
    TAasVectorMath.Subtract(LBobOrigin, LBobStart, LDir);
    if TAasVectorMath.Length(LDir) > 16 then
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
      // this isn't a failure... just wait till the func_bobbing arrives
      Result.ResultType := RESULTTYPE_WAITFORFUNCBOBBING;
      Result.Flags := Result.Flags or MOVERESULT_WAITING;
      Exit;
    end;
    // get direction and distance to func_bob bottom center
    FMovers.MoverBottomCenter(AReach, LBottomCenter);
    TAasVectorMath.Subtract(LBottomCenter, AState.Origin, LDir2);
    if (AState.MoveFlags and MFL_SWIMMING) = 0 then
      LDir2[2] := 0;
    LDist2 := TAasVectorMath.Normalize(LDir2);
    LDot := TAasVectorMath.Dot(LDir1, LDir2);
    // if very close to the reachability start or closer to the center or between the start and the center
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

function TBotFuncBobTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LBobOrigin: TVec3;
  LBobStart: TVec3;
  LBobEnd: TVec3;
  LDir: TVec3;
  LHorDir: TVec3;
  LBottomCenter: TVec3;
  LDist: Single;
  LSpeed: Single;
begin
  Result := Default(TBotMoveResult);
  LBobOrigin := Default(TVec3);
  FMovers.FuncBobStartEnd(AReach, LBobStart, LBobEnd, LBobOrigin);
  TAasVectorMath.Subtract(LBobOrigin, LBobEnd, LDir);
  LDist := TAasVectorMath.Length(LDir);
  // if the func_bobbing is near the end
  if LDist < 16 then
  begin
    TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LHorDir);
    if (AState.MoveFlags and MFL_SWIMMING) = 0 then
      LHorDir[2] := 0;
    LDist := TAasVectorMath.Normalize(LHorDir);
    if LDist > 60 then
      LDist := 60;
    LSpeed := Ramp(360, 360, 6, LDist);
    // the original sends dir, not hordir
    if LSpeed > 5 then
      FContext.Actions.Move(AState.Client, LDir, LSpeed);
    Result.MoveDir := LDir;
    if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
      Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
  end
  else
  begin
    FMovers.MoverBottomCenter(AReach, LBottomCenter);
    TAasVectorMath.Subtract(LBottomCenter, AState.Origin, LHorDir);
    if (AState.MoveFlags and MFL_SWIMMING) = 0 then
      LHorDir[2] := 0;
    LDist := TAasVectorMath.Normalize(LHorDir);
    if LDist > 5 then
    begin
      // move to the center of the plat
      if LDist > 100 then
        LDist := 100;
      LSpeed := Ramp(400, 400, 4, LDist);
      FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
      Result.MoveDir := LHorDir;
    end;
  end;
end;

end.
