{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotGrappleTravel, BotTravel_Grapple                   }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): GrappleState,        }
{  BotResetGrapple and BotTravel_Grapple of code\botlib\be_ai_move.c. Based on }
{  the Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005  }
{  Id Software, Inc.                                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Travel.Grapple;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Aas.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.State, DelphiDoom.BotAi.Move.Travel.Intf,
  DelphiDoom.BotAi.Move.Travel.Base;

type
  /// <summary>
  ///   TRAVEL_GRAPPLEHOOK: go to the start of the reachability, look at its end, fire the hook and let it pull; the
  ///   same function is used in the air. With <c>offhandgrapple</c> the hook is a command, otherwise the weapon.
  /// </summary>
  TBotGrappleTravel = class(TBotTravelBase, IBotGrappleReset)
  strict private
    function GrappleState(const AState: TBotMoveState): Integer;
  public
    function Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    function FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult; override;
    /// <summary>
    ///   BotResetGrapple: if the bot is not using the grapple hook reachability any more, the hook is put away
    /// </summary>
    procedure ResetGrapple(const AState: TBotMoveState);
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Entity.Types, DelphiDoom.Aas.VectorMath,
  DelphiDoom.BotAi.Move.Basics, DelphiDoom.BotAi.Move.VectorMath;

const
  K_0_4: Double = 0.4;
  CONTENTS_SOLID = 1;

{ TBotGrappleTravel }

function TBotGrappleTravel.GrappleState(const AState: TBotMoveState): Integer;
var
  LEntity: Integer;
  LInfo: TAasEntityInfo;
begin
  // 0 no valid grapple hook visible, 1 the grapple hook is still flying, 2 the grapple hooked into a wall
  // if the grapple hook is pulling
  if (AState.MoveFlags and MFL_GRAPPLEPULL) <> 0 then
    Exit(2);
  // check for a visible grapple missile entity or visible grapple entity
  LEntity := FContext.World.Entities.NextEntity(0);
  while LEntity <> 0 do
  begin
    if FContext.World.Entities.EntityType(LEntity) = FContext.Vars.EntityTypeMissile then
    begin
      LInfo := FContext.World.Entities.EntityInfo(LEntity);
      if LInfo.Weapon = FContext.Vars.WeaponIndexGrapple then
        Exit(1);
    end;
    LEntity := FContext.World.Entities.NextEntity(LEntity);
  end;
  // no valid grapple at all
  Result := 0;
end;

procedure TBotGrappleTravel.ResetGrapple(const AState: TBotMoveState);
var
  LReach: TAasReachability;
begin
  FContext.World.Router.ReachabilityFromNum(AState.LastReachNum, LReach);
  // if not using the grapple hook reachability anymore
  if (LReach.TravelType and TRAVELTYPE_MASK) <> TRAVEL_GRAPPLEHOOK then
  begin
    if ((AState.MoveFlags and MFL_ACTIVEGRAPPLE) <> 0) or (AState.GrappleVisibleTime <> 0) then
    begin
      if FContext.Vars.OffhandGrapple <> 0 then
        FContext.Actions.Command(AState.Client, FContext.Vars.GrappleOffCommand);
      AState.MoveFlags := AState.MoveFlags and not MFL_ACTIVEGRAPPLE;
      AState.GrappleVisibleTime := 0;
    end;
  end;
end;

function TBotGrappleTravel.Travel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
var
  LDist: Single;
  LSpeed: Single;
  LDir: TVec3;
  LViewDir: TVec3;
  LOrg: TVec3;
  LState: Integer;
  LAreaNum: Integer;
  LTrace: TAasBspTrace;
  LLimit: Double;
begin
  Result := Default(TBotMoveResult);
  if (AState.MoveFlags and MFL_GRAPPLERESET) <> 0 then
  begin
    if FContext.Vars.OffhandGrapple <> 0 then
      FContext.Actions.Command(AState.Client, FContext.Vars.GrappleOffCommand);
    AState.MoveFlags := AState.MoveFlags and not MFL_ACTIVEGRAPPLE;
    Exit;
  end;
  if Trunc(FContext.Vars.OffhandGrapple) = 0 then
  begin
    Result.Weapon := FContext.Vars.WeaponIndexGrapple;
    Result.Flags := Result.Flags or MOVERESULT_MOVEMENTWEAPON;
  end;
  if (AState.MoveFlags and MFL_ACTIVEGRAPPLE) <> 0 then
  begin
    LState := GrappleState(AState);
    TAasVectorMath.Subtract(AReach.EndPoint, AState.Origin, LDir);
    LDir[2] := 0;
    LDist := TAasVectorMath.Length(LDir);
    // if very close to the grapple end or the grappled is hooked and the bot doesn't get any closer
    if (LState <> 0) and (LDist < 48) then
    begin
      if AState.LastGrappleDist - LDist < 1 then
      begin
        if FContext.Vars.OffhandGrapple <> 0 then
          FContext.Actions.Command(AState.Client, FContext.Vars.GrappleOffCommand);
        AState.MoveFlags := AState.MoveFlags and not MFL_ACTIVEGRAPPLE;
        AState.MoveFlags := AState.MoveFlags or MFL_GRAPPLERESET;
        // end the reachability
        AState.ReachabilityTime := 0;
        Exit;
      end;
    end
    // if no valid grapple at all, or the grapple hooked and the bot isn't moving anymore
    else if (LState = 0) or ((LState = 2) and (LDist > AState.LastGrappleDist - 2)) then
    begin
      LLimit := Double(FContext.World.Time) - K_0_4;
      if Double(AState.GrappleVisibleTime) < LLimit then
      begin
        if FContext.Vars.OffhandGrapple <> 0 then
          FContext.Actions.Command(AState.Client, FContext.Vars.GrappleOffCommand);
        AState.MoveFlags := AState.MoveFlags and not MFL_ACTIVEGRAPPLE;
        AState.MoveFlags := AState.MoveFlags or MFL_GRAPPLERESET;
        // end the reachability
        AState.ReachabilityTime := 0;
        Exit;
      end;
    end
    else
      AState.GrappleVisibleTime := FContext.World.Time;
    if Trunc(FContext.Vars.OffhandGrapple) = 0 then
      FContext.Actions.Attack(AState.Client);
    // remember the current grapple distance
    AState.LastGrappleDist := LDist;
  end
  else
  begin
    AState.GrappleVisibleTime := FContext.World.Time;
    TAasVectorMath.Subtract(AReach.StartPoint, AState.Origin, LDir);
    if (AState.MoveFlags and MFL_SWIMMING) = 0 then
      LDir[2] := 0;
    LOrg[0] := AState.Origin[0] + AState.ViewOffset[0];
    LOrg[1] := AState.Origin[1] + AState.ViewOffset[1];
    LOrg[2] := AState.Origin[2] + AState.ViewOffset[2];
    TAasVectorMath.Subtract(AReach.EndPoint, LOrg, LViewDir);
    LDist := TAasVectorMath.Normalize(LDir);
    TBotVectorMath.ToAngles(LViewDir, Result.IdealViewAngles);
    Result.Flags := Result.Flags or MOVERESULT_MOVEMENTVIEW;
    if (LDist < 5) and (Abs(TBotMoveBasics.AngleDiff(Result.IdealViewAngles[0], AState.ViewAngles[0])) < 2) and
      (Abs(TBotMoveBasics.AngleDiff(Result.IdealViewAngles[1], AState.ViewAngles[1])) < 2) then
    begin
      // check if the grapple missile path is clear
      LOrg[0] := AState.Origin[0] + AState.ViewOffset[0];
      LOrg[1] := AState.Origin[1] + AState.ViewOffset[1];
      LOrg[2] := AState.Origin[2] + AState.ViewOffset[2];
      LTrace := FContext.World.Bsp.Trace(LOrg, nil, nil, AReach.EndPoint, AState.EntityNum, CONTENTS_SOLID);
      TAasVectorMath.Subtract(AReach.EndPoint, LTrace.EndPos, LDir);
      if TAasVectorMath.Length(LDir) > 16 then
      begin
        Result.Failure := True;
        Exit;
      end;
      // activate the grapple
      if FContext.Vars.OffhandGrapple <> 0 then
        FContext.Actions.Command(AState.Client, FContext.Vars.GrappleOnCommand)
      else
        FContext.Actions.Attack(AState.Client);
      AState.MoveFlags := AState.MoveFlags or MFL_ACTIVEGRAPPLE;
      AState.LastGrappleDist := 999999;
    end
    else
    begin
      if LDist < 70 then
        LSpeed := Ramp(300, 300, 4, LDist)
      else
        LSpeed := 400;
      FBasics.CheckBlocked(AState, LDir, True, Result);
      // elemantary action move in direction
      FContext.Actions.Move(AState.Client, LDir, LSpeed);
      Result.MoveDir := LDir;
    end;
    // if in another area before actually grappling
    LAreaNum := FContext.World.Sampler.PointAreaNum(AState.Origin);
    if (LAreaNum <> 0) and (LAreaNum <> AState.ReachAreaNum) then
      AState.ReachabilityTime := 0;
  end;
end;

function TBotGrappleTravel.FinishTravel(const AState: TBotMoveState; const AReach: TAasReachability): TBotMoveResult;
begin
  Result := Travel(AState, AReach);
end;

end.
