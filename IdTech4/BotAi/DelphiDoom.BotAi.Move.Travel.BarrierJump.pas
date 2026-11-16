{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotBarrierJumpTravel, BotTravel_BarrierJump           }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.BarrierJump;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_BARRIERJUMP: walk to the barrier and jump on it, then go on to the end of the reachability</summary>
  TBotBarrierJumpTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotBarrierJumpTravel }

function TBotBarrierJumpTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDist: Single;
  LSpeed: Single;
  LHorDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  // walk straight to reachability start
  LHorDir := HorizontalDelta(AReach.StartPoint, AState.Origin);
  LDist := TAasVectorMath.Normalize(LHorDir);
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  // if pretty close to the barrier
  if LDist < 9 then
    FContext.Actions.Jump(AState.Client)
  else
  begin
    if LDist > 60 then
      LDist := 60;
    LSpeed := Ramp(360, 360, 6, LDist);
    FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  end;
  Result.MoveDir := LHorDir;
end;

function TBotBarrierJumpTravel.FinishTravel(const AState: TBotMoveState;
  const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  // if near the top or going down
  if AState.Velocity[2] < 250 then
  begin
    LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
    TAasVectorMath.Normalize(LHorDir);
    FBasics.CheckBlocked(AState, LHorDir, True, Result);
    FContext.Actions.Move(AState.Client, LHorDir, 400);
    Result.MoveDir := LHorDir;
  end;
end;

end.
