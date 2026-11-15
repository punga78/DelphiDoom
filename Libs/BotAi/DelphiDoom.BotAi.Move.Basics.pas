{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotMoveBasics, the building blocks of the movement    }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): AngleDiff,          }
{  BotGapDistance, BotCheckBarrierJump, BotCheckBlocked, BotAirControl,        }
{  BotSwimInDirection, BotWalkInDirection and BotMoveInDirection of            }
{  code\botlib\be_ai_move.c. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc.                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Move.Basics;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Move.Types, DelphiDoom.BotAi.Move.Context, DelphiDoom.BotAi.Move.State;

type
  /// <summary>
  ///   The tests and the moves that the travel types share. Every float operation of the original is a float (rounded
  ///   on its own); the ones that have a double literal in them (0.5, 0.01, 0.7 ...) are doubles.
  /// </summary>
  TBotMoveBasics = class
  strict private
    FContext: TBotMoveContext;
  public
    constructor Create(const AContext: TBotMoveContext);
    /// <summary>AngleDiff: the signed difference of two angles in degrees (between -180 and 180)</summary>
    class function AngleDiff(const AAngle1, AAngle2: Single): Single; static;
    /// <summary>
    ///   BotGapDistance: the distance to a gap that is ahead in the direction (0: none, 1: the ground is not under
    ///   the bot at all)
    /// </summary>
    function GapDistance(const AOrigin, AHorDir: TVec3; const AEntNum: Integer): Single;
    /// <summary>BotCheckBarrierJump: if there is a barrier the bot can jump on, jumps (EA_Jump) and moves</summary>
    function CheckBarrierJump(const AState: TBotMoveState; const ADir: TVec3; const ASpeed: Single): Boolean;
    /// <summary>BotCheckBlocked: is an entity in the way (or under a bot that is not in an area)</summary>
    procedure CheckBlocked(const AState: TBotMoveState; const ADir: TVec3; const ACheckBottom: Boolean;
      var AResult: TBotMoveResult);
    /// <summary>
    ///   BotAirControl: the direction and the speed that bring a bot in the air (with this velocity) towards the
    ///   goal when it falls to its height; false (the null vector, speed 400) if it does not come down in 50 steps
    /// </summary>
    function AirControl(const AOrigin, AVelocity, AGoal: TVec3; out ADir: TVec3; out ASpeed: Single): Boolean;
    /// <summary>BotSwimInDirection</summary>
    function SwimInDirection(const AState: TBotMoveState; const ADir: TVec3; const ASpeed: Single): Boolean;
    /// <summary>BotWalkInDirection: predicts the move; false if the bot would fall, be hurt or not move</summary>
    function WalkInDirection(const AState: TBotMoveState; const ADir: TVec3; const ASpeed: Single;
      const AType: Integer): Boolean;
    /// <summary>The move of BotMoveInDirection once the state is known: swimming or walking</summary>
    function MoveInDirection(const AState: TBotMoveState; const ADir: TVec3; const ASpeed: Single;
      const AType: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.BoxMath,
  DelphiDoom.Aas.VectorMath, DelphiDoom.BotAi.Move.VectorMath;

const
  MASK_SOLID_PLAYERCLIP = $00010001;
  MASK_BLOCKED = $02010001;
  /// <summary>PREDICTIONTIME_JUMP / 0.1 as an int: 3 / 0.1 is 30 in doubles</summary>
  JUMP_MAXFRAMES = 30;
  K_0_01: Double = 0.01;
  K_0_1: Double = 0.1;
  K_0_7: Double = 0.7;

{ TBotMoveBasics }

constructor TBotMoveBasics.Create(const AContext: TBotMoveContext);
begin
  inherited Create;
  FContext := AContext;
end;

class function TBotMoveBasics.AngleDiff(const AAngle1, AAngle2: Single): Single;
var
  LDiff: Single;
begin
  LDiff := AAngle1 - AAngle2;
  if AAngle1 > AAngle2 then
  begin
    if LDiff > 180 then
      LDiff := LDiff - 360;
  end
  else
  begin
    if LDiff < -180 then
      LDiff := LDiff + 360;
  end;
  Result := LDiff;
end;

function TBotMoveBasics.GapDistance(const AOrigin, AHorDir: TVec3; const AEntNum: Integer): Single;
var
  LDist: Single;
  LStartZ: Single;
  LStart: TVec3;
  LEnd: TVec3;
  LTrace: TAasTrace;
  LDrop: Single;
  LLimit: Single;
begin
  // do gap checking
  LStartZ := AOrigin[2];
  // this enables walking down stairs more fluidly
  LStart := AOrigin;
  LEnd := AOrigin;
  LEnd[2] := LEnd[2] - 60;
  LTrace := FContext.World.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, AEntNum);
  if LTrace.Fraction >= 1 then
    Exit(1);
  LStartZ := LTrace.EndPos[2] + 1;
  LDist := 8;
  while LDist <= 100 do
  begin
    TBotVectorMath.MultiplyAdd(AOrigin, LDist, AHorDir, LStart);
    LStart[2] := LStartZ + 24;
    LEnd := LStart;
    LDrop := 48 + FContext.Vars.MaxBarrier;
    LEnd[2] := LEnd[2] - LDrop;
    LTrace := FContext.World.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, AEntNum);
    // if solid is found the bot can't walk any further and fall into a gap
    if not LTrace.StartSolid then
    begin
      // if it is a gap
      LLimit := LStartZ - FContext.Vars.MaxStep;
      LLimit := LLimit - 8;
      if LTrace.EndPos[2] < LLimit then
      begin
        LEnd := LTrace.EndPos;
        LEnd[2] := LEnd[2] - 20;
        if (FContext.World.Bsp.PointContents(LEnd) and BSP_CONTENTS_WATER) <> 0 then
          Break;
        // if a gap is found slow down
        Exit(LDist);
      end;
      LStartZ := LTrace.EndPos[2];
    end;
    LDist := LDist + 8;
  end;
  Result := 0;
end;

function TBotMoveBasics.CheckBarrierJump(const AState: TBotMoveState; const ADir: TVec3;
  const ASpeed: Single): Boolean;
var
  LStart: TVec3;
  LHorDir: TVec3;
  LEnd: TVec3;
  LTrace: TAasTrace;
  LRise: Single;
  LScale: Double;
  LProduct: Single;
begin
  LEnd := AState.Origin;
  LEnd[2] := LEnd[2] + FContext.Vars.MaxBarrier;
  // trace right up
  LTrace := FContext.World.Tracer.TraceClientBBox(AState.Origin, LEnd, PRESENCE_NORMAL, AState.EntityNum);
  // this shouldn't happen... but we check anyway
  if LTrace.StartSolid then
    Exit(False);
  // if very low ceiling it isn't possible to jump up to a barrier
  LRise := LTrace.EndPos[2] - AState.Origin[2];
  if LRise < FContext.Vars.MaxStep then
    Exit(False);
  LHorDir[0] := ADir[0];
  LHorDir[1] := ADir[1];
  LHorDir[2] := 0;
  TAasVectorMath.Normalize(LHorDir);
  LProduct := AState.ThinkTime * ASpeed;
  LScale := Double(LProduct) * 0.5;
  TBotVectorMath.MultiplyAddDouble(AState.Origin, LScale, LHorDir, LEnd);
  LStart := LTrace.EndPos;
  LEnd[2] := LTrace.EndPos[2];
  // trace from previous trace end pos horizontally in the move direction
  LTrace := FContext.World.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_NORMAL, AState.EntityNum);
  // again this shouldn't happen
  if LTrace.StartSolid then
    Exit(False);
  LStart := LTrace.EndPos;
  LEnd := LTrace.EndPos;
  LEnd[2] := AState.Origin[2];
  // trace down from the previous trace end pos
  LTrace := FContext.World.Tracer.TraceClientBBox(LStart, LEnd, PRESENCE_NORMAL, AState.EntityNum);
  // if solid
  if LTrace.StartSolid then
    Exit(False);
  // if no obstacle at all
  if LTrace.Fraction >= 1.0 then
    Exit(False);
  // if less than the maximum step height
  LRise := LTrace.EndPos[2] - AState.Origin[2];
  if LRise < FContext.Vars.MaxStep then
    Exit(False);
  FContext.Actions.Jump(AState.Client);
  FContext.Actions.Move(AState.Client, LHorDir, ASpeed);
  AState.MoveFlags := AState.MoveFlags or MFL_BARRIERJUMP;
  // there is a barrier
  Result := True;
end;

procedure TBotMoveBasics.CheckBlocked(const AState: TBotMoveState; const ADir: TVec3; const ACheckBottom: Boolean;
  var AResult: TBotMoveResult);
const
  UP: TVec3 = (0, 0, 1);
var
  LMins: TVec3;
  LMaxs: TVec3;
  LEnd: TVec3;
  LTrace: TAasBspTrace;
  LDot: Single;
begin
  // test for entities obstructing the bot's path
  TAasBoxMath.PresenceTypeBoundingBox(FContext.Import, AState.PresenceType, LMins, LMaxs);
  LDot := TAasVectorMath.Dot(ADir, UP);
  if Abs(Double(LDot)) < K_0_7 then
  begin
    // if the bot can step on
    LMins[2] := LMins[2] + FContext.Vars.MaxStep;
    // a little lower to avoid low ceiling
    LMaxs[2] := LMaxs[2] - 10;
  end;
  TBotVectorMath.MultiplyAdd(AState.Origin, 3, ADir, LEnd);
  LTrace := FContext.World.Bsp.Trace(AState.Origin, @LMins, @LMaxs, LEnd, AState.EntityNum, MASK_BLOCKED);
  // if not started in solid and not hitting the world entity
  if (not LTrace.StartSolid) and (LTrace.EntityNum <> ENTITYNUM_WORLD) and (LTrace.EntityNum <> ENTITYNUM_NONE) then
  begin
    AResult.Blocked := True;
    AResult.BlockEntity := LTrace.EntityNum;
  end
  // if not in an area with reachability
  else if ACheckBottom and (FContext.World.Areas.AreaReachability(AState.AreaNum) = 0) then
  begin
    // check if the bot is standing on something
    TAasBoxMath.PresenceTypeBoundingBox(FContext.Import, AState.PresenceType, LMins, LMaxs);
    TBotVectorMath.MultiplyAdd(AState.Origin, -3, UP, LEnd);
    LTrace := FContext.World.Bsp.Trace(AState.Origin, @LMins, @LMaxs, LEnd, AState.EntityNum, MASK_SOLID_PLAYERCLIP);
    if (not LTrace.StartSolid) and (LTrace.EntityNum <> ENTITYNUM_WORLD) and (LTrace.EntityNum <> ENTITYNUM_NONE) then
    begin
      AResult.Blocked := True;
      AResult.BlockEntity := LTrace.EntityNum;
      AResult.Flags := AResult.Flags or MOVERESULT_ONTOPOFOBSTACLE;
    end;
  end;
end;

function TBotMoveBasics.AirControl(const AOrigin, AVelocity, AGoal: TVec3; out ADir: TVec3;
  out ASpeed: Single): Boolean;
var
  LOrg: TVec3;
  LVel: TVec3;
  LDist: Single;
  LScale: Single;
  LStep: Double;
  LNext: Double;
  LIndex: Integer;
  LLoop: Integer;
begin
  LOrg := AOrigin;
  for LIndex := 0 to 2 do
    LVel[LIndex] := AVelocity[LIndex] * K_0_1;
  for LLoop := 0 to 49 do
  begin
    LStep := Double(FContext.Vars.Gravity) * K_0_01;
    LNext := Double(LVel[2]) - LStep;
    LVel[2] := LNext;
    // if going down and next position would be below the goal
    if (LVel[2] < 0) and (LOrg[2] + LVel[2] < AGoal[2]) then
    begin
      LScale := AGoal[2] - LOrg[2];
      LScale := LScale / LVel[2];
      for LIndex := 0 to 2 do
        LVel[LIndex] := LVel[LIndex] * LScale;
      for LIndex := 0 to 2 do
        LOrg[LIndex] := LOrg[LIndex] + LVel[LIndex];
      for LIndex := 0 to 2 do
        ADir[LIndex] := AGoal[LIndex] - LOrg[LIndex];
      LDist := TAasVectorMath.Normalize(ADir);
      if LDist > 32 then
        LDist := 32;
      LDist := 13 * LDist;
      LDist := 400 - LDist;
      ASpeed := 400 - LDist;
      Exit(True);
    end
    else
    begin
      for LIndex := 0 to 2 do
        LOrg[LIndex] := LOrg[LIndex] + LVel[LIndex];
    end;
  end;
  ADir[0] := 0;
  ADir[1] := 0;
  ADir[2] := 0;
  ASpeed := 400;
  Result := False;
end;

function TBotMoveBasics.SwimInDirection(const AState: TBotMoveState; const ADir: TVec3;
  const ASpeed: Single): Boolean;
var
  LNormDir: TVec3;
begin
  LNormDir := ADir;
  TAasVectorMath.Normalize(LNormDir);
  FContext.Actions.Move(AState.Client, LNormDir, ASpeed);
  Result := True;
end;

function TBotMoveBasics.WalkInDirection(const AState: TBotMoveState; const ADir: TVec3; const ASpeed: Single;
  const AType: Integer): Boolean;
var
  LType: Integer;
  LHorDir: TVec3;
  LCmdMove: TVec3;
  LVelocity: TVec3;
  LTmpDir: TVec3;
  LOrigin: TVec3;
  LPresenceType: Integer;
  LMaxFrames: Integer;
  LCmdFrames: Integer;
  LStopEvent: Integer;
  LMove: TAasClientMove;
  LDist: Single;
  LLength: Single;
  LLimit: Double;
  LProduct: Single;
begin
  LType := AType;
  if FContext.World.Movement.OnGround(AState.Origin, AState.PresenceType, AState.EntityNum) then
    AState.MoveFlags := AState.MoveFlags or MFL_ONGROUND;
  // if the bot is on the ground
  if (AState.MoveFlags and MFL_ONGROUND) <> 0 then
  begin
    // if there is a barrier the bot can jump on
    if CheckBarrierJump(AState, ADir, ASpeed) then
      Exit(True);
    // remove barrier jump flag
    AState.MoveFlags := AState.MoveFlags and not MFL_BARRIERJUMP;
    // get the presence type for the movement
    if ((LType and MOVE_CROUCH) <> 0) and ((LType and MOVE_JUMP) = 0) then
      LPresenceType := PRESENCE_CROUCH
    else
      LPresenceType := PRESENCE_NORMAL;
    // horizontal direction
    LHorDir[0] := ADir[0];
    LHorDir[1] := ADir[1];
    LHorDir[2] := 0;
    TAasVectorMath.Normalize(LHorDir);
    // if the bot is not supposed to jump
    if (LType and MOVE_JUMP) = 0 then
    begin
      // if there is a gap, try to jump over it
      if GapDistance(AState.Origin, LHorDir, AState.EntityNum) > 0 then
        LType := LType or MOVE_JUMP;
    end;
    // get command movement
    LCmdMove[0] := LHorDir[0] * ASpeed;
    LCmdMove[1] := LHorDir[1] * ASpeed;
    LCmdMove[2] := LHorDir[2] * ASpeed;
    LVelocity := AState.Velocity;
    if (LType and MOVE_JUMP) <> 0 then
    begin
      LCmdMove[2] := 400;
      LMaxFrames := JUMP_MAXFRAMES;
      LCmdFrames := 1;
      LStopEvent := SE_HITGROUND or SE_HITGROUNDDAMAGE or SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA;
    end
    else
    begin
      LMaxFrames := 2;
      LCmdFrames := 2;
      LStopEvent := SE_HITGROUNDDAMAGE or SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA;
    end;
    LOrigin := AState.Origin;
    LOrigin[2] := LOrigin[2] + 0.5;
    FContext.World.Movement.PredictClientMovement(LMove, AState.EntityNum, LOrigin, LPresenceType, True, LVelocity,
      LCmdMove, LCmdFrames, LMaxFrames, 0.1, LStopEvent, 0, False);
    // if prediction time wasn't enough to fully predict the movement
    if (LMove.Frames >= LMaxFrames) and ((LType and MOVE_JUMP) <> 0) then
      Exit(False);
    // don't enter slime or lava and don't fall from too high
    if (LMove.StopEvent and (SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE)) <> 0 then
      Exit(False);
    // if ground was hit
    if (LMove.StopEvent and SE_HITGROUND) <> 0 then
    begin
      // check for nearby gap
      TBotVectorMath.Normalize2(LMove.Velocity, LTmpDir);
      LDist := GapDistance(LMove.EndPos, LTmpDir, AState.EntityNum);
      if LDist > 0 then
        Exit(False);
      LDist := GapDistance(LMove.EndPos, LHorDir, AState.EntityNum);
      if LDist > 0 then
        Exit(False);
    end;
    // get horizontal movement
    LTmpDir[0] := LMove.EndPos[0] - AState.Origin[0];
    LTmpDir[1] := LMove.EndPos[1] - AState.Origin[1];
    LTmpDir[2] := 0;
    // the bot is blocked by something
    LLength := TAasVectorMath.Length(LTmpDir);
    LProduct := ASpeed * AState.ThinkTime;
    LLimit := Double(LProduct) * 0.5;
    if Double(LLength) < LLimit then
      Exit(False);
    // perform the movement
    if (LType and MOVE_JUMP) <> 0 then
      FContext.Actions.Jump(AState.Client);
    if (LType and MOVE_CROUCH) <> 0 then
      FContext.Actions.Crouch(AState.Client);
    FContext.Actions.Move(AState.Client, LHorDir, ASpeed);
    // movement was succesfull
    Result := True;
  end
  else
  begin
    if (AState.MoveFlags and MFL_BARRIERJUMP) <> 0 then
    begin
      // if near the top or going down
      if AState.Velocity[2] < 50 then
        FContext.Actions.Move(AState.Client, ADir, ASpeed);
    end;
    // FIXME: do air control to avoid hazards
    Result := True;
  end;
end;

function TBotMoveBasics.MoveInDirection(const AState: TBotMoveState; const ADir: TVec3; const ASpeed: Single;
  const AType: Integer): Boolean;
begin
  // if swimming
  if FContext.World.Movement.Swimming(AState.Origin) then
    Result := SwimInDirection(AState, ADir, ASpeed)
  else
    Result := WalkInDirection(AState, ADir, ASpeed, AType);
end;

end.
