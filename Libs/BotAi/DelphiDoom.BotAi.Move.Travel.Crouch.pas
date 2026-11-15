{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCrouchTravel, BotTravel_Crouch                     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Crouch;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_CROUCH: crouch and walk straight to the end of the reachability. In the air nothing is done.</summary>
  TBotCrouchTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotCrouchTravel }

function TBotCrouchTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
begin
  Result := Default(TBotMoveResult);
  // walk straight to reachability end
  LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
  TAasVectorMath.Normalize(LHorDir);
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  // elemantary actions
  FContext.Actions.Crouch(AState.Client);
  FContext.Actions.Move(AState.Client, LHorDir, 400);
  Result.MoveDir := LHorDir;
end;

end.
