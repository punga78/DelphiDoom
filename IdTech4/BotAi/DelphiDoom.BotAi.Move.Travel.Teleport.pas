{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotTeleportTravel, BotTravel_Teleport                 }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software):                 }
{  code\botlib\be_ai_move.c. Copyright (C) 1999-2005 Id Software, Inc. This    }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Teleport;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>TRAVEL_TELEPORT: walk to the center of the teleporter (slowly when near); in the air nothing is done</summary>
  TBotTeleportTravel = class(TBotTravelBase)
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.VectorMath;

{ TBotTeleportTravel }

function TBotTeleportTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LHorDir: TVec3;
  LDist: Single;
begin
  Result := Default(TBotMoveResult);
  // if the bot is being teleported
  if (AState.MoveFlags and MFL_TELEPORTED) <> 0 then
    Exit;
  // walk straight to center of the teleporter
  TAasVectorMath.Subtract(AReach.StartPoint, AState.Origin, LHorDir);
  if (AState.MoveFlags and MFL_SWIMMING) = 0 then
    LHorDir[2] := 0;
  LDist := TAasVectorMath.Normalize(LHorDir);
  FBasics.CheckBlocked(AState, LHorDir, True, Result);
  if LDist < 30 then
    FContext.Actions.Move(AState.Client, LHorDir, 200)
  else
    FContext.Actions.Move(AState.Client, LHorDir, 400);
  if (AState.MoveFlags and MFL_SWIMMING) <> 0 then
    Result.Flags := Result.Flags or MOVERESULT_SWIMVIEW;
  Result.MoveDir := LHorDir;
end;

end.
