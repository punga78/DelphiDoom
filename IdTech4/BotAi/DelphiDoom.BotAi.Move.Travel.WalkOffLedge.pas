{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWalkOffLedgeTravel, BotTravel_WalkOffLedge         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.WalkOffLedge;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_WALKOFFLEDGE: walk to the ledge and off it; in the air steer with the air control</summary>
  TBotWalkOffLedgeTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.VectorMath;

{ TBotWalkOffLedgeTravel }

function TBotWalkOffLedgeTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LDir: TVec3;
  LDist: Single;
  LSpeed: Single;
  LReachHorDist: Single;
begin
  Result := Default(TBotMoveResult);
  LSpeed := 0;
  // check if the bot is blocked by anything
  TAasVectorMath.Subtract(AReach.StartPoint, AState.Origin, LDir);
  TAasVectorMath.Normalize(LDir);
  FBasics.CheckBlocked(AState, LDir, True, Result);
  // if the reachability start and end are practially above each other
  TAasVectorMath.Subtract(AReach.EndPoint, AReach.StartPoint, LDir);
  LDir[2] := 0;
  LReachHorDist := TAasVectorMath.Length(LDir);
  // walk straight to the reachability start
  LHorDir := HorizontalDelta(AReach.StartPoint, AState.Origin);
  LDist := TAasVectorMath.Normalize(LHorDir);
  // if pretty close to the start focus on the reachability end
  if LDist < 48 then
  begin
    LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
    TAasVectorMath.Normalize(LHorDir);
    if LReachHorDist < 20 then
      LSpeed := 100
    else if not FContext.World.Movement.HorizontalVelocityForJump(0, AReach.StartPoint, AReach.EndPoint, LSpeed) then
      LSpeed := 400;
  end
  else
  begin
    if LReachHorDist < 20 then
    begin
      if LDist > 64 then
        LDist := 64;
      LSpeed := Ramp(400, 256, 4, LDist);
    end
    else
      LSpeed := 400;
  end;
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  // elemantary action
  FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  Result.MoveDir := LHorDir;
end;

function TBotWalkOffLedgeTravel.FinishTravel(const AState: TBotMoveState;
  const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
  LHorDir: TVec3;
  LEnd: TVec3;
  LV: TVec3;
  LDist: Single;
  LSpeed: Single;
begin
  Result := Default(TBotMoveResult);
  TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LDir);
  FBasics.CheckBlocked(AState, LDir, True, Result);
  TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LV);
  LV[2] := 0;
  LDist := TAasVectorMath.Normalize(LV);
  if LDist > 16 then
    TBotVectorMath.MultiplyAdd(AReach.EndPoint, 16, LV, LEnd)
  else
    LEnd := AReach.EndPoint;
  if not FBasics.AirControl(AState.Origin, AState.Velocity, LEnd, LHorDir, LSpeed) then
  begin
    // go straight to the reachability end
    LHorDir := LDir;
    LHorDir[2] := 0;
    TAasVectorMath.Normalize(LHorDir);
    LSpeed := 400;
  end;
  FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  Result.MoveDir := LHorDir;
end;

end.
