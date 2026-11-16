{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotBfgJumpTravel, BotTravel_BFGJump                   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.BfgJump;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_BFGJUMP: as the rocket jump with the BFG. Defect of the original kept: the test of the view uses the
  ///   ideal view angles before they are set, so they are zero (the original reads what the result held; the result
  ///   is cleared here and in the tool that gave the golden files).
  /// </summary>
  TBotBfgJumpTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.Basics, DelphiDoom.BotAi.Move.VectorMath,
  DelphiDoom.BotAi.Move.Travel.WeaponJump;

{ TBotBfgJumpTravel }

function TBotBfgJumpTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LDist: Single;
  LSpeed: Single;
begin
  Result := Default(TBotMoveResult);
  LHorDir := HorizontalDelta(AReach.StartPoint, AState.Origin);
  LDist := TAasVectorMath.Normalize(LHorDir);
  if (LDist < 5) and (Abs(TBotMoveBasics.AngleDiff(Result.IdealViewAngles[0], AState.ViewAngles[0])) < 5) and
    (Abs(TBotMoveBasics.AngleDiff(Result.IdealViewAngles[1], AState.ViewAngles[1])) < 5) then
  begin
    LHorDir := HorizontalDelta(AReach.EndPoint, AState.Origin);
    TAasVectorMath.Normalize(LHorDir);
    // elemantary action jump
    FContext.Actions.Jump(AState.Client);
    FContext.Actions.Attack(AState.Client);
    FContext.Actions.Move(AState.Client, LHorDir, 800);
    AState.JumpReach := AState.LastReachNum;
  end
  else
  begin
    if LDist > 80 then
      LDist := 80;
    LSpeed := Ramp(400, 400, 5, LDist);
    FContext.Actions.Move(AState.Client, LHorDir, LSpeed);
  end;
  // look in the movement direction
  TBotVectorMath.ToAngles(LHorDir, Result.IdealViewAngles);
  // look straight down
  Result.IdealViewAngles[0] := 90;
  // set the view angles directly
  FContext.Actions.View(AState.Client, Result.IdealViewAngles);
  // view is important for the movment
  Result.Flags := Result.Flags or MOVERESULT_MOVEMENTVIEWSET;
  // select the bfg
  FContext.Actions.SelectWeapon(AState.Client, FContext.Vars.WeaponIndexBfg);
  // weapon is used for movement
  Result.Weapon := FContext.Vars.WeaponIndexBfg;
  Result.Flags := Result.Flags or MOVERESULT_MOVEMENTWEAPON;
  Result.MoveDir := LHorDir;
end;

function TBotBfgJumpTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := TBotWeaponJumpFinish.FinishTravel(FContext, FBasics, AState, AReach);
end;

end.
