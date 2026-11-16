{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotJumpTravel, BotTravel_Jump                         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Jump;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_JUMP: run to the run start point (the start of the reachability pushed back by up to 80 units, as far
  ///   as the area goes) and jump at the start; in the air go straight on at full speed
  /// </summary>
  TBotJumpTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.VectorMath;

const
  K_0_8: Double = 0.8;
  K_0_5: Double = 0.5;

{ TBotJumpTravel }

function TBotJumpTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LDir1: TVec3;
  LDir2: TVec3;
  LStart: TVec3;
  LEnd: TVec3;
  LRunStart: TVec3;
  LDist1: Single;
  LDist2: Single;
  LSpeed: Single;
  LDot: Single;
begin
  Result := Default(TBotMoveResult);
  FContext.World.Movement.JumpReachRunStart(AReach, LRunStart);
  LHorDir[0] := LRunStart[0] - AReach.StartPoint[0];
  LHorDir[1] := LRunStart[1] - AReach.StartPoint[1];
  LHorDir[2] := 0;
  TAasVectorMath.Normalize(LHorDir);
  LStart := AReach.StartPoint;
  LStart[2] := LStart[2] + 1;
  TBotVectorMath.MultiplyAdd(AReach.StartPoint, 80, LHorDir, LRunStart);
  // check for a gap
  LEnd := LStart;
  LDist1 := 0;
  while LDist1 < 80 do
  begin
    TBotVectorMath.MultiplyAdd(LStart, LDist1 + 10, LHorDir, LEnd);
    LEnd[2] := LEnd[2] + 1;
    if FContext.World.Sampler.PointAreaNum(LEnd) <> AState.ReachAreaNum then
      Break;
    LDist1 := LDist1 + 10;
  end;
  if LDist1 < 80 then
    TBotVectorMath.MultiplyAdd(AReach.StartPoint, LDist1, LHorDir, LRunStart);
  TAasVectorMath.Subtract(AState.Origin, AReach.StartPoint, LDir1);
  LDir1[2] := 0;
  LDist1 := TAasVectorMath.Normalize(LDir1);
  TAasVectorMath.Subtract(AState.Origin, LRunStart, LDir2);
  LDir2[2] := 0;
  LDist2 := TAasVectorMath.Normalize(LDir2);
  LDot := TAasVectorMath.Dot(LDir1, LDir2);
  // if just before the reachability start
  if (Double(LDot) < -K_0_8) or (LDist2 < 5) then
  begin
    LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
    TAasVectorMath.Normalize(LHorDir);
    // elemantary action jump
    if LDist1 < 24 then
      FContext.Actions.Jump(AState.Client)
    else if LDist1 < 32 then
      FContext.Actions.DelayedJump(AState.Client);
    FContext.Actions.Move(AState.Client, LHorDir, 600);
    AState.JumpReach := AState.LastReachNum;
  end
  else
  begin
    LHorDir := HorizontalDelta(LRunStart, AState.Origin);
    TAasVectorMath.Normalize(LHorDir);
    if LDist2 > 80 then
      LDist2 := 80;
    LSpeed := Ramp(400, 400, 5, LDist2);
    FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  end;
  Result.MoveDir := LHorDir;
end;

function TBotJumpTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LHorDir2: TVec3;
  LDist: Single;
  LDot: Single;
begin
  Result := Default(TBotMoveResult);
  // if not jumped yet
  if AState.JumpReach = 0 then
    Exit;
  // go straight to the reachability end
  LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
  LDist := TAasVectorMath.Normalize(LHorDir);
  LHorDir2 := HorizontalDelta(AReach.EndPoint, AReach.StartPoint);
  TAasVectorMath.Normalize(LHorDir2);
  LDot := TAasVectorMath.Dot(LHorDir, LHorDir2);
  if (Double(LDot) < -K_0_5) and (LDist < 24) then
    Exit;
  // always use max speed when traveling through the air
  FContext.Actions.Move(AState.Client, LHorDir, 800);
  Result.MoveDir := LHorDir;
end;

end.
