{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotWeaponJumpFinish, BotFinishTravel_WeaponJump       }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.WeaponJump;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Context,
  DelphiDoom.BotAi.Move.Basics;

type
  /// <summary>
  ///   The part of a rocket jump or a BFG jump in the air (the two types share it): if the bot jumped, steer with
  ///   the air control towards the end of the reachability
  /// </summary>
  TBotWeaponJumpFinish = class
  public
    /// <summary>BotFinishTravel_WeaponJump</summary>
    class function FinishTravel(const AContext: TBotMoveContext; const ABasics: TBotMoveBasics;
      const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotWeaponJumpFinish }

class function TBotWeaponJumpFinish.FinishTravel(const AContext: TBotMoveContext; const ABasics: TBotMoveBasics;
  const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LSpeed: Single;
begin
  Result := Default(TBotMoveResult);
  // if not jumped yet
  if AState.JumpReach = 0 then
    Exit;
  if not ABasics.AirControl(AState.Origin, AState.Velocity, AReach.EndPoint, LHorDir, LSpeed) then
  begin
    // go straight to the reachability end
    TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LHorDir);
    LHorDir[2] := 0;
    TAasVectorMath.Normalize(LHorDir);
    LSpeed := 400;
  end;
  AContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  Result.MoveDir := LHorDir;
end;

end.
