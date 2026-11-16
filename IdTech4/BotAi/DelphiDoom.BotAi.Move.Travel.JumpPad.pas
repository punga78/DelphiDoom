{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotJumpPadTravel, BotTravel_JumpPad                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.JumpPad;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_JUMPPAD: walk to the pad; in the air steer with the air control towards the end</summary>
  TBotJumpPadTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotJumpPadTravel }

function TBotJumpPadTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  // first walk straight to the reachability start
  LHorDir := HorizontalDelta(AReach.StartPoint, AState.Origin);
  TAasVectorMath.Normalize(LHorDir);
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  // elemantary action move in direction
  FContext.Actions.Move(AState.Client, LHorDir, 400);
  Result.MoveDir := LHorDir;
end;

function TBotJumpPadTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LSpeed: Single;
begin
  Result := Default(TBotMoveResult);
  if not FBasics.AirControl(AState.Origin, AState.Velocity, AReach.EndPoint, LHorDir, LSpeed) then
  begin
    LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
    TAasVectorMath.Normalize(LHorDir);
    LSpeed := 400;
  end;
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  // elemantary action move in direction
  FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  Result.MoveDir := LHorDir;
end;

end.
