{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotLadderTravel, BotTravel_Ladder                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Ladder;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_LADDER: look up or down the ladder (three times the height) and go forward; the same in the air</summary>
  TBotLadderTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.VectorMath;

{ TBotLadderTravel }

function TBotLadderTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
  LViewDir: TVec3;
  LOrigin: TVec3;
begin
  Result := Default(TBotMoveResult);
  LOrigin := Default(TVec3);
  TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LDir);
  TAasVectorMath.Normalize(LDir);
  // set the ideal view angles, facing the ladder up or down
  LViewDir[0] := LDir[0];
  LViewDir[1] := LDir[1];
  LViewDir[2] := 3 * LDir[2];
  TBotVectorMath.ToAngles(LViewDir, Result.IdealViewAngles);
  // elemantary action
  FContext.Actions.Move(AState.Client, LOrigin, 0);
  FContext.Actions.MoveForward(AState.Client);
  // set movement view flag so the AI can see the view is focussed
  Result.Flags := Result.Flags or MOVERESULT_MOVEMENTVIEW;
  // save the movement direction
  Result.MoveDir := LDir;
end;

function TBotLadderTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := Travel(AState, AReach);
end;

end.
