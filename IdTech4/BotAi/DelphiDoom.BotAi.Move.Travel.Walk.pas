{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWalkTravel, BotTravel_Walk                         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Walk;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_WALK: first walk straight to the start of the reachability, then to its end. Both while the bot is on
  ///   the ground and in the air (the original calls BotTravel_Walk from both; BotFinishTravel_Walk is never used).
  /// </summary>
  TBotWalkTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotWalkTravel }

function TBotWalkTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDist: Single;
  LSpeed: Single;
  LHorDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  // first walk straight to the reachability start
  LHorDir := HorizontalDelta(AReach.StartPoint, AState.Origin);
  LDist := TAasVectorMath.Normalize(LHorDir);
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  if LDist < 10 then
  begin
    // walk straight to the reachability end
    LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
    LDist := TAasVectorMath.Normalize(LHorDir);
  end;
  // if going towards a crouch area
  if (FContext.World.Areas.AreaPresenceType(AReach.AreaNum) and PRESENCE_NORMAL) = 0 then
  begin
    // if pretty close to the reachable area
    if LDist < 20 then
      FContext.Actions.Crouch(AState.Client);
  end;
  LDist := FBasics.GapDistance(AState.Origin, LHorDir, AState.EntityNum);
  if (AState.MoveFlags and MFL_WALK) <> 0 then
  begin
    if LDist > 0 then
      LSpeed := Ramp(200, 180, 1, LDist)
    else
      LSpeed := 200;
    FContext.Actions.Walk(AState.Client);
  end
  else
  begin
    if LDist > 0 then
      LSpeed := Ramp(400, 360, 2, LDist)
    else
      LSpeed := 400;
  end;
  // elemantary action move in direction
  FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  Result.MoveDir := LHorDir;
end;

function TBotWalkTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := Travel(AState, AReach);
end;

end.
