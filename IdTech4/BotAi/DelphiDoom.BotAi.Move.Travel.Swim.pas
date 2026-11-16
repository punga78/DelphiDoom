{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotSwimTravel, BotTravel_Swim                         }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Swim;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_SWIM: swim straight to the start of the reachability looking where the bot goes (both in and out of the water)</summary>
  TBotSwimTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.VectorMath;

{ TBotSwimTravel }

function TBotSwimTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  // swim straight to reachability end
  TAasVectorMath.Subtract(AReach.StartPoint, AState.Origin, LDir);
  TAasVectorMath.Normalize(LDir);
  FBasics.CheckBlocked(AState, LDir, True, Result);
  // elemantary actions
  FContext.Actions.Move(AState.Client, LDir, 400);
  Result.MoveDir := LDir;
  TBotVectorMath.ToAngles(LDir, Result.IdealViewAngles);
  Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
end;

function TBotSwimTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := Travel(AState, AReach);
end;

end.
