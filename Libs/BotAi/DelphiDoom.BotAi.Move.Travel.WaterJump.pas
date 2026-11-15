{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWaterJumpTravel, BotTravel_WaterJump               }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.WaterJump;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_WATERJUMP: swim towards the end of the reachability with a little random up and down; out of the
  ///   water move at the end with a random wobble (crandom() is a double: the sums are doubles)
  /// </summary>
  TBotWaterJumpTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.VectorMath;

const
  CONTENTS_LAVA_SLIME_WATER = BSP_CONTENTS_LAVA or BSP_CONTENTS_SLIME or BSP_CONTENTS_WATER;

{ TBotWaterJumpTravel }

function TBotWaterJumpTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
  LHorDir: TVec3;
  LDist: Single;
  LWobble: Double;
  LSum: Double;
begin
  Result := Default(TBotMoveResult);
  // swim straight to reachability end
  TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LDir);
  LHorDir := LDir;
  LHorDir[2] := 0;
  LWobble := FContext.CRandom * 40;
  LSum := 15 + LWobble;
  LDir[2] := Double(LDir[2]) + LSum;
  TAasVectorMath.Normalize(LDir);
  LDist := TAasVectorMath.Normalize(LHorDir);
  // elemantary actions
  FContext.Actions.MoveForward(AState.Client);
  // move up if close to the actual out of water jump spot
  if LDist < 40 then
    FContext.Actions.MoveUp(AState.Client);
  // set the ideal view angles
  TBotVectorMath.ToAngles(LDir, Result.IdealViewAngles);
  Result.Flags := Result.Flags or MOVERESULT_MOVEMENTVIEW;
  Result.MoveDir := LDir;
end;

function TBotWaterJumpTravel.FinishTravel(const AState: TBotMoveState;
  const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
  LPoint: TVec3;
  LWobble: Double;
  LSum: Double;
begin
  Result := Default(TBotMoveResult);
  // if waterjumping there's nothing to do
  if (AState.MoveFlags and MFL_WATERJUMP) <> 0 then
    Exit;
  // if not touching any water anymore don't do anything, otherwise the bot sometimes keeps jumping?
  LPoint := AState.Origin;
  // extra for q2dm4 near red armor/mega health
  LPoint[2] := LPoint[2] - 32;
  if (FContext.World.Bsp.PointContents(LPoint) and CONTENTS_LAVA_SLIME_WATER) = 0 then
    Exit;
  // swim straight to reachability end
  TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LDir);
  LWobble := FContext.CRandom * 10;
  LDir[0] := Double(LDir[0]) + LWobble;
  LWobble := FContext.CRandom * 10;
  LDir[1] := Double(LDir[1]) + LWobble;
  LWobble := FContext.CRandom * 10;
  LSum := 70 + LWobble;
  LDir[2] := Double(LDir[2]) + LSum;
  TAasVectorMath.Normalize(LDir);
  // elemantary actions
  FContext.Actions.Move(AState.Client, LDir, 400);
  // set the ideal view angles
  TBotVectorMath.ToAngles(LDir, Result.IdealViewAngles);
  Result.Flags := Result.Flags or MOVERESULT_MOVEMENTVIEW;
  Result.MoveDir := LDir;
end;

end.
