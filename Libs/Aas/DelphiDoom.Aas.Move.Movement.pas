{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the prediction of the movement of a client        }
{                                                                              }
{  Port of be_aas_move.c: AAS_DropToFloor, AAS_AgainstLadder, AAS_OnGround,    }
{  AAS_Swimming, AAS_SetMovedir, AAS_JumpReachRunStart,                        }
{  AAS_WeaponJumpZVelocity, AAS_Accelerate, AAS_ApplyFriction,                 }
{  AAS_ClipToBBox, AAS_ClientMovementPrediction, AAS_PredictClientMovement,    }
{  AAS_ClientMovementHitBBox and AAS_HorizontalVelocityForJump. Based on the   }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{  The physics are the ones of the botlib and not those of Libs\Pmove (the     }
{  player movement of the game): the bots predict with their own simplified    }
{  rules and the result has to be that of the C code to the bit.               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Move.Movement;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf;

type
  /// <summary>
  ///   The movement prediction of the bots. The file, the sampler, the tracer, the face tester, the world and
  ///   the import are not owned
  /// </summary>
  TAasMovement = class(TInterfacedObject, IAasMovement)
  strict private
    FFile: IAasFile;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FFaces: IAasFaceTester;
    FWorld: IAasBspWorld;
    FImport: IBotImport;
    FSettings: TAasMoveSettings;
    function PlaneFromNum(const APlaneNum: Integer): TAasPlane;
    function ClientMovementPrediction(out AMove: TAasClientMove; const AEntNum: Integer; const AOrigin: TVec3;
      const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
      const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AStopEvent, AStopAreaNum: Integer;
      const AMins, AMaxs: TVec3; const AVisualize: Boolean): Boolean;
    procedure Stop(var AMove: TAasClientMove; const AEndPos: TVec3; const AEndArea: Integer;
      const AVelocity: TVec3; const ATrace: TAasTrace; const APresenceType, AStopEvent, AFrame: Integer;
      const AFrameTime: Single);
    function GetSettings: TAasMoveSettings;
  public
    constructor Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
      const AFaces: IAasFaceTester; const AWorld: IAasBspWorld; const AImport: IBotImport;
      const ASettings: TAasMoveSettings);
    /// <summary>AAS_Accelerate: the velocity gets the acceleration towards the wish direction</summary>
    class procedure Accelerate(var AVelocity: TVec3; const AFrameTime: Single; const AWishDir: TVec3;
      const AWishSpeed, AAccel: Single); static;
    /// <summary>AAS_ApplyFriction: ground friction on the horizontal velocity</summary>
    class procedure ApplyFriction(var AVel: TVec3; const AFriction, AStopSpeed, AFrameTime: Single); static;
    property Settings: TAasMoveSettings read GetSettings;
    function DropToFloor(var AOrigin: TVec3; const AMins, AMaxs: TVec3): Boolean;
    function AgainstLadder(const AOrigin: TVec3): Boolean;
    function OnGround(const AOrigin: TVec3; const APresenceType, APassEnt: Integer): Boolean;
    function Swimming(const AOrigin: TVec3): Boolean;
    procedure SetMovedir(const AAngles: TVec3; out AMoveDir: TVec3);
    procedure JumpReachRunStart(const AReach: TAasReachability; out ARunStart: TVec3);
    function WeaponJumpZVelocity(const AOrigin: TVec3; const ARadiusDamage: Single): Single;
    function RocketJumpZVelocity(const AOrigin: TVec3): Single;
    function BFGJumpZVelocity(const AOrigin: TVec3): Single;
    function ClipToBBox(var ATrace: TAasTrace; const AStart, AEnd: TVec3; const APresenceType: Integer;
      const AMins, AMaxs: TVec3): Boolean;
    function PredictClientMovement(out AMove: TAasClientMove; const AEntNum: Integer; const AOrigin: TVec3;
      const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
      const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AStopEvent, AStopAreaNum: Integer;
      const AVisualize: Boolean): Boolean;
    function ClientMovementHitBBox(out AMove: TAasClientMove; const AEntNum: Integer; const AOrigin: TVec3;
      const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
      const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AMins, AMaxs: TVec3;
      const AVisualize: Boolean): Boolean;
    function HorizontalVelocityForJump(const AZVel: Single; const AStart, AEnd: TVec3; out AVelocity: Single): Boolean;
  end;

implementation

uses
  System.Math, DelphiDoom.BotAi.Types, DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Math, DelphiDoom.Aas.VectorMath,
  DelphiDoom.Aas.BoxMath, DelphiDoom.Aas.Route.Types;

resourcestring
  SPlaneOutOfRange = 'AAS movement: plane %d is not in the file';
  SStartSolid = 'PredictMovement: start solid'#10;

const
  // the literals of the C code: 0.1 and 0.25 are doubles, 0.1f and 0.7 are not (the settings are floats)
  CTenth: Double = 0.1;
  CQuarter: Double = 0.25;
  CHalf: Double = 0.5;
  CTenThousandth: Double = 0.0001;
  CTenthFloat: Single = 0.100000001490116119384765625;
  CLadderEpsilon: Single = 0.100000001490116119384765625;

{ TAasMovement }

constructor TAasMovement.Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
  const AFaces: IAasFaceTester; const AWorld: IAasBspWorld; const AImport: IBotImport;
  const ASettings: TAasMoveSettings);
begin
  inherited Create;
  FFile := AFile;
  FSampler := ASampler;
  FTracer := ATracer;
  FFaces := AFaces;
  FWorld := AWorld;
  FImport := AImport;
  FSettings := ASettings;
end;

function TAasMovement.GetSettings: TAasMoveSettings;
begin
  Result := FSettings;
end;

function TAasMovement.PlaneFromNum(const APlaneNum: Integer): TAasPlane;
begin
  if (APlaneNum < 0) or (APlaneNum >= Length(FFile.Planes)) then
    raise EAasMoveException.Create(Format(SPlaneOutOfRange, [APlaneNum]));
  Result := FFile.Planes[APlaneNum];
end;

function TAasMovement.DropToFloor(var AOrigin: TVec3; const AMins, AMaxs: TVec3): Boolean;
var
  LEnd: TVec3;
  LTrace: TAasBspTrace;
  LMins, LMaxs: TVec3;
begin
  LEnd := AOrigin;
  LEnd[2] := LEnd[2] - 100;
  LMins := AMins;
  LMaxs := AMaxs;
  LTrace := FWorld.Trace(AOrigin, @LMins, @LMaxs, LEnd, 0, BSP_CONTENTS_SOLID);
  if LTrace.StartSolid then
    Exit(False);
  AOrigin := LTrace.EndPos;
  Result := True;
end;

function TAasMovement.AgainstLadder(const AOrigin: TVec3): Boolean;
var
  LAreaNum, LIndex, LFaceNum, LSide: Integer;
  LOrg: TVec3;
  LPlane: TAasPlane;
  LFace: TAasFace;
  LArea: TAasArea;
  LDistance: Single;
  LFaceIndex: TArray<Integer>;
begin
  LOrg := AOrigin;
  LAreaNum := FSampler.PointAreaNum(LOrg);
  if LAreaNum = 0 then
  begin
    LOrg[0] := LOrg[0] + 1;
    LAreaNum := FSampler.PointAreaNum(LOrg);
    if LAreaNum = 0 then
    begin
      LOrg[1] := LOrg[1] + 1;
      LAreaNum := FSampler.PointAreaNum(LOrg);
      if LAreaNum = 0 then
      begin
        LOrg[0] := LOrg[0] - 2;
        LAreaNum := FSampler.PointAreaNum(LOrg);
        if LAreaNum = 0 then
        begin
          LOrg[1] := LOrg[1] - 2;
          LAreaNum := FSampler.PointAreaNum(LOrg);
        end;
      end;
    end;
  end;
  // if in solid... wrrr shouldn't happen
  if LAreaNum = 0 then
    Exit(False);
  // if not in a ladder area
  if (FFile.AreaSettings[LAreaNum].AreaFlags and AREA_LADDER) = 0 then
    Exit(False);
  // if a crouch only area
  if (FFile.AreaSettings[LAreaNum].PresenceType and PRESENCE_NORMAL) = 0 then
    Exit(False);
  LArea := FFile.Areas[LAreaNum];
  LFaceIndex := FFile.FaceIndex;
  for LIndex := 0 to LArea.NumFaces - 1 do
  begin
    LFaceNum := LFaceIndex[LArea.FirstFace + LIndex];
    LSide := Ord(LFaceNum < 0);
    LFace := FFile.Faces[Abs(LFaceNum)];
    // if the face isn't a ladder face
    if (LFace.FaceFlags and FACE_LADDER) = 0 then
      Continue;
    // get the plane the face is in
    LPlane := PlaneFromNum(LFace.PlaneNum xor LSide);
    // if the origin is pretty close to the plane: abs() of the original is the integer one
    LDistance := TAasVectorMath.Dot(LPlane.Normal, AOrigin);
    LDistance := LDistance - LPlane.Dist;
    if Abs(Trunc(LDistance)) < 3 then
      if FFaces.PointInsideFace(Abs(LFaceNum), AOrigin, CLadderEpsilon) then
        Exit(True);
  end;
  Result := False;
end;

function TAasMovement.OnGround(const AOrigin: TVec3; const APresenceType, APassEnt: Integer): Boolean;
var
  LTrace: TAasTrace;
  LEnd: TVec3;
  LPlane: TAasPlane;
  LUp: TVec3;
  LDot: Single;
  LDifference: Single;
begin
  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 1;
  LEnd := AOrigin;
  LEnd[2] := LEnd[2] - 10;
  LTrace := FTracer.TraceClientBBox(AOrigin, LEnd, APresenceType, APassEnt);
  // if in solid
  if LTrace.StartSolid then
    Exit(False);
  // if nothing hit at all
  if LTrace.Fraction >= 1.0 then
    Exit(False);
  // if too far from the hit plane
  LDifference := AOrigin[2] - LTrace.EndPos[2];
  if LDifference > 10 then
    Exit(False);
  // check if the plane isn't too steep
  LPlane := PlaneFromNum(LTrace.PlaneNum);
  LDot := TAasVectorMath.Dot(LPlane.Normal, LUp);
  if LDot < FSettings.PhysMaxSteepness then
    Exit(False);
  // the bot is on the ground
  Result := True;
end;

function TAasMovement.Swimming(const AOrigin: TVec3): Boolean;
var
  LTestOrg: TVec3;
begin
  LTestOrg := AOrigin;
  LTestOrg[2] := LTestOrg[2] - 2;
  Result := (FWorld.PointContents(LTestOrg) and (BSP_CONTENTS_LAVA or BSP_CONTENTS_SLIME or BSP_CONTENTS_WATER)) <> 0;
end;

procedure TAasMovement.SetMovedir(const AAngles: TVec3; out AMoveDir: TVec3);
var
  LForward, LRight, LUp: TQ3Vec3;
begin
  // VEC_UP is (0, -1, 0) and VEC_DOWN (0, -2, 0)
  if (AAngles[0] = 0) and (AAngles[1] = -1) and (AAngles[2] = 0) then
  begin
    AMoveDir[0] := 0;
    AMoveDir[1] := 0;
    AMoveDir[2] := 1;
  end
  else if (AAngles[0] = 0) and (AAngles[1] = -2) and (AAngles[2] = 0) then
  begin
    AMoveDir[0] := 0;
    AMoveDir[1] := 0;
    AMoveDir[2] := -1;
  end
  else
  begin
    TQ3Math.AngleVectors(TQ3Vec3(AAngles), LForward, LRight, LUp);
    AMoveDir := TVec3(LForward);
  end;
end;

procedure TAasMovement.JumpReachRunStart(const AReach: TAasReachability; out ARunStart: TVec3);
var
  LHorDir, LStart, LCmdMove, LZero: TVec3;
  LMove: TAasClientMove;
begin
  LHorDir[0] := AReach.StartPoint[0] - AReach.EndPoint[0];
  LHorDir[1] := AReach.StartPoint[1] - AReach.EndPoint[1];
  LHorDir[2] := 0;
  TAasVectorMath.Normalize(LHorDir);
  // start point
  LStart := AReach.StartPoint;
  LStart[2] := LStart[2] + 1;
  // get command movement
  LCmdMove[0] := LHorDir[0] * 400;
  LCmdMove[1] := LHorDir[1] * 400;
  LCmdMove[2] := LHorDir[2] * 400;
  LZero[0] := 0;
  LZero[1] := 0;
  LZero[2] := 0;
  PredictClientMovement(LMove, -1, LStart, PRESENCE_NORMAL, True, LZero, LCmdMove, 1, 2, CTenthFloat,
    SE_ENTERWATER or SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE or SE_GAP, 0, False);
  ARunStart := LMove.EndPos;
  // don't enter slime or lava and don't fall from too high
  if (LMove.StopEvent and (SE_ENTERSLIME or SE_ENTERLAVA or SE_HITGROUNDDAMAGE)) <> 0 then
    ARunStart := LStart;
end;

function TAasMovement.WeaponJumpZVelocity(const AOrigin: TVec3; const ARadiusDamage: Single): Single;
const
  ROCKET_OFFSET: array[0..2] of Single = (8, 8, -8);
  BOT_MINS: array[0..2] of Single = (-16, -16, -24);
  BOT_MAXS: array[0..2] of Single = (16, 16, 32);
var
  LKVel, LV, LStart, LEnd, LViewAngles, LDir: TVec3;
  LForward, LRight, LUp: TQ3Vec3;
  LTrace: TAasBspTrace;
  LMass, LKnockback, LPoints, LScale: Single;
  LTerm, LSum, LProduct: Single;
  LDouble, LScaleD: Double;
  LIndex: Integer;
begin
  // look down (90 degrees)
  LViewAngles[0] := 90;
  LViewAngles[1] := 0;
  LViewAngles[2] := 0;
  // get the start point shooting from
  LStart := AOrigin;
  LStart[2] := LStart[2] + 8; // view offset Z
  TQ3Math.AngleVectors(TQ3Vec3(LViewAngles), LForward, LRight, LUp);
  LTerm := LForward[0] * ROCKET_OFFSET[0];
  LProduct := LRight[0] * ROCKET_OFFSET[1];
  LSum := LTerm + LProduct;
  LStart[0] := LStart[0] + LSum;
  LTerm := LForward[1] * ROCKET_OFFSET[0];
  LProduct := LRight[1] * ROCKET_OFFSET[1];
  LSum := LTerm + LProduct;
  LStart[1] := LStart[1] + LSum;
  LTerm := LForward[2] * ROCKET_OFFSET[0];
  LProduct := LRight[2] * ROCKET_OFFSET[1];
  LSum := LTerm + LProduct;
  LSum := LSum + ROCKET_OFFSET[2];
  LStart[2] := LStart[2] + LSum;
  // end point of the trace: VectorMA( start, 500, forward, end ) with an int scale
  for LIndex := 0 to 2 do
  begin
    LProduct := LForward[LIndex] * 500;
    LEnd[LIndex] := LStart[LIndex] + LProduct;
  end;
  // trace a line to get the impact point
  LTrace := FWorld.Trace(LStart, nil, nil, LEnd, 1, BSP_CONTENTS_SOLID);
  // calculate the damage the bot will get from the rocket impact
  for LIndex := 0 to 2 do
    LV[LIndex] := BOT_MINS[LIndex] + BOT_MAXS[LIndex];
  // VectorMA( origin, 0.5, v, v ): the scale is a double
  TAasVectorMath.MultiplyAdd(AOrigin, LV, CHalf, LV);
  TAasVectorMath.Subtract(LTrace.EndPos, LV, LV);
  // points = radiusdamage - 0.5 * VectorLength(v);
  LDouble := CHalf * TAasVectorMath.Length(LV);
  LDouble := ARadiusDamage - LDouble;
  LPoints := LDouble;
  if LPoints < 0 then
    LPoints := 0;
  // the owner of the rocket gets half the damage
  LDouble := LPoints * CHalf;
  LPoints := LDouble;
  // mass of the bot (p_client.c: PutClientInServer)
  LMass := 200;
  // knockback is the same as the damage points
  LKnockback := LPoints;
  // direction of the damage (from trace.endpos to bot origin)
  TAasVectorMath.Subtract(AOrigin, LTrace.EndPos, LDir);
  TAasVectorMath.Normalize(LDir);
  // damage velocity: VectorScale( dir, 1600.0 * (float)knockback / mass, kvel ) with a double scale
  LScaleD := 1600.0;
  LScaleD := LScaleD * LKnockback;
  LScaleD := LScaleD / LMass;
  for LIndex := 0 to 2 do
  begin
    LDouble := LDir[LIndex] * LScaleD;
    LKVel[LIndex] := LDouble;
  end;
  LScale := LKVel[2];
  // rocket impact velocity + jump velocity
  Result := LScale + FSettings.PhysJumpVel;
end;

function TAasMovement.RocketJumpZVelocity(const AOrigin: TVec3): Single;
begin
  // rocket radius damage is 120 (p_weapon.c: Weapon_RocketLauncher_Fire)
  Result := WeaponJumpZVelocity(AOrigin, 120);
end;

function TAasMovement.BFGJumpZVelocity(const AOrigin: TVec3): Single;
begin
  // bfg radius damage is 1000 (p_weapon.c: weapon_bfg_fire), the original passes 120
  Result := WeaponJumpZVelocity(AOrigin, 120);
end;

class procedure TAasMovement.Accelerate(var AVelocity: TVec3; const AFrameTime: Single; const AWishDir: TVec3;
  const AWishSpeed, AAccel: Single);
var
  LIndex: Integer;
  LAddSpeed, LAccelSpeed, LCurrentSpeed, LStep: Single;
begin
  // q2 style
  LCurrentSpeed := TAasVectorMath.Dot(AVelocity, AWishDir);
  LAddSpeed := AWishSpeed - LCurrentSpeed;
  if LAddSpeed <= 0 then
    Exit;
  LAccelSpeed := AAccel * AFrameTime;
  LAccelSpeed := LAccelSpeed * AWishSpeed;
  if LAccelSpeed > LAddSpeed then
    LAccelSpeed := LAddSpeed;
  for LIndex := 0 to 2 do
  begin
    LStep := LAccelSpeed * AWishDir[LIndex];
    AVelocity[LIndex] := AVelocity[LIndex] + LStep;
  end;
end;

class procedure TAasMovement.ApplyFriction(var AVel: TVec3; const AFriction, AStopSpeed, AFrameTime: Single);
var
  LSpeed, LControl, LNewSpeed, LSum, LFall: Single;
  LRoot: Double;
begin
  // horizontal speed
  LSum := AVel[0] * AVel[0];
  LFall := AVel[1] * AVel[1];
  LSum := LSum + LFall;
  LRoot := Sqrt(Double(LSum));
  LSpeed := LRoot;
  if LSpeed <> 0 then
  begin
    if LSpeed < AStopSpeed then
      LControl := AStopSpeed
    else
      LControl := LSpeed;
    LFall := AFrameTime * LControl;
    LFall := LFall * AFriction;
    LNewSpeed := LSpeed - LFall;
    if LNewSpeed < 0 then
      LNewSpeed := 0;
    LNewSpeed := LNewSpeed / LSpeed;
    AVel[0] := AVel[0] * LNewSpeed;
    AVel[1] := AVel[1] * LNewSpeed;
  end;
end;

function TAasMovement.ClipToBBox(var ATrace: TAasTrace; const AStart, AEnd: TVec3; const APresenceType: Integer;
  const AMins, AMaxs: TVec3): Boolean;
var
  LIndex, LJ, LSide: Integer;
  LFront, LBack, LFrac, LPlaneDist, LStep: Single;
  LBBoxMins, LBBoxMaxs, LAbsMins, LAbsMaxs, LDir, LMid: TVec3;
begin
  TAasBoxMath.PresenceTypeBoundingBox(FImport, APresenceType, LBBoxMins, LBBoxMaxs);
  TAasVectorMath.Subtract(AMins, LBBoxMaxs, LAbsMins);
  TAasVectorMath.Subtract(AMaxs, LBBoxMins, LAbsMaxs);
  ATrace.EndPos := AEnd;
  ATrace.Fraction := 1;
  for LIndex := 0 to 2 do
  begin
    if (AStart[LIndex] < LAbsMins[LIndex]) and (AEnd[LIndex] < LAbsMins[LIndex]) then
      Exit(False);
    if (AStart[LIndex] > LAbsMaxs[LIndex]) and (AEnd[LIndex] > LAbsMaxs[LIndex]) then
      Exit(False);
  end;
  // check bounding box collision
  TAasVectorMath.Subtract(AEnd, AStart, LDir);
  LFrac := 1;
  LMid[0] := 0;
  LMid[1] := 0;
  LMid[2] := 0;
  LIndex := 0;
  while LIndex < 3 do
  begin
    // get plane to test collision with for the current axis direction
    if LDir[LIndex] > 0 then
      LPlaneDist := LAbsMins[LIndex]
    else
      LPlaneDist := LAbsMaxs[LIndex];
    // calculate collision fraction
    LFront := AStart[LIndex] - LPlaneDist;
    LBack := AEnd[LIndex] - LPlaneDist;
    LStep := LFront - LBack;
    LFrac := LFront / LStep;
    // check if between bounding planes of next axis
    LSide := LIndex + 1;
    if LSide > 2 then
      LSide := 0;
    LStep := LDir[LSide] * LFrac;
    LMid[LSide] := AStart[LSide] + LStep;
    if (not IsNan(LMid[LSide])) and (LMid[LSide] > LAbsMins[LSide]) and (LMid[LSide] < LAbsMaxs[LSide]) then
    begin
      // check if between bounding planes of next axis
      Inc(LSide);
      if LSide > 2 then
        LSide := 0;
      LStep := LDir[LSide] * LFrac;
      LMid[LSide] := AStart[LSide] + LStep;
      if (not IsNan(LMid[LSide])) and (LMid[LSide] > LAbsMins[LSide]) and (LMid[LSide] < LAbsMaxs[LSide]) then
      begin
        LMid[LIndex] := LPlaneDist;
        Break;
      end;
    end;
    Inc(LIndex);
  end;
  // if there was a collision
  if LIndex <> 3 then
  begin
    ATrace.StartSolid := False;
    ATrace.Fraction := LFrac;
    ATrace.Ent := 0;
    ATrace.PlaneNum := 0;
    ATrace.Area := 0;
    ATrace.LastArea := 0;
    // trace endpos
    for LJ := 0 to 2 do
    begin
      LStep := LDir[LJ] * LFrac;
      ATrace.EndPos[LJ] := AStart[LJ] + LStep;
    end;
    Exit(True);
  end;
  Result := False;
end;

procedure TAasMovement.Stop(var AMove: TAasClientMove; const AEndPos: TVec3; const AEndArea: Integer;
  const AVelocity: TVec3; const ATrace: TAasTrace; const APresenceType, AStopEvent, AFrame: Integer;
  const AFrameTime: Single);
begin
  AMove.EndPos := AEndPos;
  AMove.EndArea := AEndArea;
  AMove.Velocity := AVelocity;
  AMove.Trace := ATrace;
  AMove.StopEvent := AStopEvent;
  AMove.PresenceType := APresenceType;
  AMove.EndContents := 0;
  AMove.Time := AFrame * AFrameTime;
  AMove.Frames := AFrame;
end;

function TAasMovement.ClientMovementPrediction(out AMove: TAasClientMove; const AEntNum: Integer;
  const AOrigin: TVec3; const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
  const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AStopEvent, AStopAreaNum: Integer;
  const AMins, AMaxs: TVec3; const AVisualize: Boolean): Boolean;
var
  LFrictionValue, LStopSpeed, LGravityValue, LWaterFriction, LWaterGravity: Single;
  LWalkAccelerate, LAirAccelerate, LSwimAccelerate: Single;
  LMaxWalkVelocity, LMaxCrouchVelocity, LMaxSwimVelocity: Single;
  LMaxStep, LMaxSteepness, LJumpVel, LFriction: Single;
  LGravity, LDelta, LMaxVel, LWishSpeed, LAccelerate, LInverse, LFrameTime: Single;
  LOldVelocity: Single;
  LDouble: Double;
  N, I, J, PC, LEvent, LJumpFrame, LAreaNum, LNumAreas, LAxis: Integer;
  LStep, LSwimming, LCrouch, LOnGround: Boolean;
  LPresenceType: Integer;
  LAreas: TArray<Integer>;
  LPoints: TArray<TVec3>;
  LOrg, LEnd, LFeet, LStart, LStepEnd, LLastOrg, LWishDir, LFrameTestVel, LOldFrameTestVel, LLeftTestVel: TVec3;
  LUp: TVec3;
  LPlane, LPlane2: TAasPlane;
  LTrace, LStepTrace, LGapTrace: TAasTrace;
  LMove: TAasClientMove;
  LProduct, LScale: Single;
  LDot: Single;
  LPlaneHit: Boolean;
  LGuard: Integer;

  function Done(const AEndPos: TVec3; const AEndArea: Integer; const AVel: TVec3; const AStopEventValue: Integer;
    const ATraceValue: TAasTrace): Boolean;
  begin
    Stop(AMove, AEndPos, AEndArea, AVel, ATraceValue, LPresenceType, AStopEventValue, N, LFrameTime);
    Result := True;
  end;

  function VelocityPerSecond: TVec3;
  var
    LK: Integer;
    LInv: Single;
  begin
    LInv := 1 / LFrameTime;
    for LK := 0 to 2 do
      Result[LK] := LFrameTestVel[LK] * LInv;
  end;

  procedure ScaleFrameVelocity(const AScaleValue: Single);
  var
    LK: Integer;
  begin
    for LK := 0 to 2 do
      LFrameTestVel[LK] := LFrameTestVel[LK] * AScaleValue;
  end;

begin
  LFrameTime := AFrameTime;
  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 1;
  if LFrameTime <= 0 then
    LFrameTime := CTenthFloat;
  LFrictionValue := FSettings.PhysFriction;
  LStopSpeed := FSettings.PhysStopSpeed;
  LGravityValue := FSettings.PhysGravity;
  LWaterFriction := FSettings.PhysWaterFriction;
  LWaterGravity := FSettings.PhysWaterGravity;
  LMaxWalkVelocity := FSettings.PhysMaxWalkVelocity;
  LMaxCrouchVelocity := FSettings.PhysMaxCrouchVelocity;
  LMaxSwimVelocity := FSettings.PhysMaxSwimVelocity;
  LWalkAccelerate := FSettings.PhysWalkAccelerate;
  LAirAccelerate := FSettings.PhysAirAccelerate;
  LSwimAccelerate := FSettings.PhysSwimAccelerate;
  LMaxStep := FSettings.PhysMaxStep;
  LMaxSteepness := FSettings.PhysMaxSteepness;
  LJumpVel := FSettings.PhysJumpVel * LFrameTime;
  FillChar(AMove, SizeOf(AMove), 0);
  FillChar(LTrace, SizeOf(LTrace), 0);
  FillChar(LMove, SizeOf(LMove), 0);
  LPresenceType := APresenceType;
  LOnGround := AOnGround;
  // start at the current origin
  LOrg := AOrigin;
  LOrg[2] := LOrg[2] + 0.25;
  // velocity to test for the first frame
  for I := 0 to 2 do
    LFrameTestVel[I] := AVelocity[I] * LFrameTime;
  LJumpFrame := -1;
  LLastOrg := LOrg;
  LLeftTestVel := LFrameTestVel;
  LOldFrameTestVel := LFrameTestVel;
  // predict a maximum of 'maxframes' ahead
  N := 0;
  while N < AMaxFrames do
  begin
    LSwimming := Swimming(LOrg);
    // get gravity depending on swimming or not
    if LSwimming then
      LGravity := LWaterGravity
    else
      LGravity := LGravityValue;
    // apply gravity at the START of the frame
    LDouble := LGravity * CTenth;
    LDouble := LDouble * LFrameTime;
    LDouble := LFrameTestVel[2] - LDouble;
    LFrameTestVel[2] := LDouble;
    // if on the ground or swimming
    if LOnGround or LSwimming then
    begin
      if LSwimming then
        LFriction := LFrictionValue
      else
        LFriction := LWaterFriction;
      // apply friction
      LInverse := 1 / LFrameTime;
      ScaleFrameVelocity(LInverse);
      ApplyFriction(LFrameTestVel, LFriction, LStopSpeed, LFrameTime);
      ScaleFrameVelocity(LFrameTime);
    end;
    LCrouch := False;
    // apply command movement
    if N < ACmdFrames then
    begin
      LAxis := 0;
      LMaxVel := LMaxWalkVelocity;
      LAccelerate := LAirAccelerate;
      LWishDir := ACmdMove;
      if LOnGround then
      begin
        if ACmdMove[2] < -300 then
        begin
          LCrouch := True;
          LMaxVel := LMaxCrouchVelocity;
        end;
        // if not swimming and upmove is positive then jump
        if (not LSwimming) and (ACmdMove[2] > 1) then
        begin
          // jump velocity minus the gravity for one frame + 5 for safety
          LDouble := LGravity * CTenth;
          LDouble := LDouble * LFrameTime;
          LDouble := LJumpVel - LDouble;
          LDouble := LDouble + 5;
          LFrameTestVel[2] := LDouble;
          LJumpFrame := N;
          // jumping so air accelerate
          LAccelerate := LAirAccelerate;
        end
        else
          LAccelerate := LWalkAccelerate;
        LAxis := 2;
      end;
      if LSwimming then
      begin
        LMaxVel := LMaxSwimVelocity;
        LAccelerate := LSwimAccelerate;
        LAxis := 3;
      end
      else
        LWishDir[2] := 0;
      LWishSpeed := TAasVectorMath.Normalize(LWishDir);
      if LWishSpeed > LMaxVel then
        LWishSpeed := LMaxVel;
      LInverse := 1 / LFrameTime;
      ScaleFrameVelocity(LInverse);
      Accelerate(LFrameTestVel, LFrameTime, LWishDir, LWishSpeed, LAccelerate);
      ScaleFrameVelocity(LFrameTime);
    end;
    if LCrouch then
      LPresenceType := PRESENCE_CROUCH
    else if LPresenceType = PRESENCE_CROUCH then
      if (FSampler.PointPresenceType(LOrg) and PRESENCE_NORMAL) <> 0 then
        LPresenceType := PRESENCE_NORMAL;
    // save the current origin
    LLastOrg := LOrg;
    // move linear during one frame
    LLeftTestVel := LFrameTestVel;
    J := 0;
    repeat
      for I := 0 to 2 do
        LEnd[I] := LOrg[I] + LLeftTestVel[I];
      // trace a bounding box
      LTrace := FTracer.TraceClientBBox(LOrg, LEnd, LPresenceType, AEntNum);
      if AVisualize then
        if LTrace.StartSolid then
          FImport.Print(PRT_MESSAGE, AnsiString(SStartSolid));
      if (AStopEvent and (SE_ENTERAREA or SE_TOUCHJUMPPAD or SE_TOUCHTELEPORTER or SE_TOUCHCLUSTERPORTAL)) <> 0 then
      begin
        LNumAreas := FTracer.TraceAreas(LOrg, LTrace.EndPos, 20, LAreas, LPoints);
        for I := 0 to LNumAreas - 1 do
        begin
          if (AStopEvent and SE_ENTERAREA) <> 0 then
            if LAreas[I] = AStopAreaNum then
              Exit(Done(LPoints[I], LAreas[I], VelocityPerSecond, SE_ENTERAREA, LTrace));
          // NOTE: if not the first frame
          if ((AStopEvent and SE_TOUCHJUMPPAD) <> 0) and (N <> 0) then
            if (FFile.AreaSettings[LAreas[I]].Contents and AREACONTENTS_JUMPPAD) <> 0 then
              Exit(Done(LPoints[I], LAreas[I], VelocityPerSecond, SE_TOUCHJUMPPAD, LTrace));
          if (AStopEvent and SE_TOUCHTELEPORTER) <> 0 then
            if (FFile.AreaSettings[LAreas[I]].Contents and AREACONTENTS_TELEPORTER) <> 0 then
              Exit(Done(LPoints[I], LAreas[I], VelocityPerSecond, SE_TOUCHTELEPORTER, LTrace));
          if (AStopEvent and SE_TOUCHCLUSTERPORTAL) <> 0 then
            if (FFile.AreaSettings[LAreas[I]].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
              Exit(Done(LPoints[I], LAreas[I], VelocityPerSecond, SE_TOUCHCLUSTERPORTAL, LTrace));
        end;
      end;
      if (AStopEvent and SE_HITBOUNDINGBOX) <> 0 then
        if ClipToBBox(LTrace, LOrg, LTrace.EndPos, LPresenceType, AMins, AMaxs) then
          Exit(Done(LTrace.EndPos, FSampler.PointAreaNum(LTrace.EndPos), VelocityPerSecond, SE_HITBOUNDINGBOX, LTrace));
      // move the entity to the trace end point
      LOrg := LTrace.EndPos;
      // if there was a collision
      if LTrace.Fraction < 1.0 then
      begin
        // get the plane the bounding box collided with
        LPlane := PlaneFromNum(LTrace.PlaneNum);
        if (AStopEvent and SE_HITGROUNDAREA) <> 0 then
        begin
          LDot := TAasVectorMath.Dot(LPlane.Normal, LUp);
          if LDot > LMaxSteepness then
          begin
            LStart := LOrg;
            LStart[2] := LStart[2] + 0.5;
            if FSampler.PointAreaNum(LStart) = AStopAreaNum then
              Exit(Done(LStart, AStopAreaNum, VelocityPerSecond, SE_HITGROUNDAREA, LTrace));
          end;
        end;
        // assume there's no step
        LStep := False;
        // if it is a vertical plane and the bot didn't jump recently
        if (LPlane.Normal[2] = 0) and ((LJumpFrame < 0) or (N - LJumpFrame > 2)) then
        begin
          // check for a step: VectorMA( org, -0.25, plane->normal, start ) with a double scale
          TAasVectorMath.MultiplyAdd(LOrg, LPlane.Normal, -CQuarter, LStart);
          LStepEnd := LStart;
          LStart[2] := LStart[2] + LMaxStep;
          LStepTrace := FTracer.TraceClientBBox(LStart, LStepEnd, LPresenceType, AEntNum);
          if not LStepTrace.StartSolid then
          begin
            LPlane2 := PlaneFromNum(LStepTrace.PlaneNum);
            LDot := TAasVectorMath.Dot(LPlane2.Normal, LUp);
            if LDot > LMaxSteepness then
            begin
              TAasVectorMath.Subtract(LEnd, LStepTrace.EndPos, LLeftTestVel);
              LLeftTestVel[2] := 0;
              LFrameTestVel[2] := 0;
              LOrg[2] := LStepTrace.EndPos[2];
              LStep := True;
            end;
          end;
        end;
        if not LStep then
        begin
          // velocity left to test for this frame is the projection of the current test velocity into the hit plane
          // VectorMA( v, -DotProduct( v, n ), n, v ): the macro evaluates the scale for every component, and the first
          // components are already changed when the next ones are computed
          for I := 0 to 2 do
          begin
            LScale := TAasVectorMath.Dot(LLeftTestVel, LPlane.Normal);
            LScale := -LScale;
            LProduct := LPlane.Normal[I] * LScale;
            LLeftTestVel[I] := LLeftTestVel[I] + LProduct;
          end;
          // store the old velocity for landing check
          LOldFrameTestVel := LFrameTestVel;
          // test velocity for the next frame is the projection of the velocity of the current frame into the hit plane
          for I := 0 to 2 do
          begin
            LScale := TAasVectorMath.Dot(LFrameTestVel, LPlane.Normal);
            LScale := -LScale;
            LProduct := LPlane.Normal[I] * LScale;
            LFrameTestVel[I] := LFrameTestVel[I] + LProduct;
          end;
          // check for a landing on an almost horizontal floor
          LDot := TAasVectorMath.Dot(LPlane.Normal, LUp);
          if LDot > LMaxSteepness then
            LOnGround := True;
          if (AStopEvent and SE_HITGROUNDDAMAGE) <> 0 then
          begin
            LDelta := 0;
            if (LOldFrameTestVel[2] < 0) and (LFrameTestVel[2] > LOldFrameTestVel[2]) and (not LOnGround) then
              LDelta := LOldFrameTestVel[2]
            else if LOnGround then
              LDelta := LFrameTestVel[2] - LOldFrameTestVel[2];
            if LDelta <> 0 then
            begin
              LDelta := LDelta * 10;
              LDouble := LDelta * LDelta;
              LDouble := LDouble * CTenThousandth;
              LDelta := LDouble;
              if LSwimming then
                LDelta := 0;
              if LDelta > 40 then
                Exit(Done(LOrg, FSampler.PointAreaNum(LOrg), LFrameTestVel, SE_HITGROUNDDAMAGE, LTrace));
            end;
          end;
        end;
      end;
      // extra check to prevent endless loop
      Inc(J);
      if J > 20 then
        Exit(False);
      // while there is a plane hit
    until not (LTrace.Fraction < 1.0);
    // if going down
    if LFrameTestVel[2] <= 10 then
    begin
      // check for a liquid at the feet of the bot
      LFeet := LOrg;
      LFeet[2] := LFeet[2] - 22;
      PC := FWorld.PointContents(LFeet);
      // get event from pc
      LEvent := SE_NONE;
      if (PC and BSP_CONTENTS_LAVA) <> 0 then
        LEvent := LEvent or SE_ENTERLAVA;
      if (PC and BSP_CONTENTS_SLIME) <> 0 then
        LEvent := LEvent or SE_ENTERSLIME;
      if (PC and BSP_CONTENTS_WATER) <> 0 then
        LEvent := LEvent or SE_ENTERWATER;
      LAreaNum := FSampler.PointAreaNum(LOrg);
      if (FFile.AreaSettings[LAreaNum].Contents and AREACONTENTS_LAVA) <> 0 then
        LEvent := LEvent or SE_ENTERLAVA;
      if (FFile.AreaSettings[LAreaNum].Contents and AREACONTENTS_SLIME) <> 0 then
        LEvent := LEvent or SE_ENTERSLIME;
      if (FFile.AreaSettings[LAreaNum].Contents and AREACONTENTS_WATER) <> 0 then
        LEvent := LEvent or SE_ENTERWATER;
      // if in lava or slime
      if (LEvent and AStopEvent) <> 0 then
      begin
        // the original does not store the trace here: it stays zero
        Stop(AMove, LOrg, LAreaNum, VelocityPerSecond, LMove.Trace, LPresenceType, LEvent and AStopEvent, N,
          LFrameTime);
        AMove.EndContents := PC;
        Exit(True);
      end;
    end;
    LOnGround := OnGround(LOrg, LPresenceType, AEntNum);
    // if onground and on the ground for at least one whole frame
    if LOnGround then
    begin
      if (AStopEvent and SE_HITGROUND) <> 0 then
        Exit(Done(LOrg, FSampler.PointAreaNum(LOrg), VelocityPerSecond, SE_HITGROUND, LTrace));
    end
    else if (AStopEvent and SE_LEAVEGROUND) <> 0 then
      Exit(Done(LOrg, FSampler.PointAreaNum(LOrg), VelocityPerSecond, SE_LEAVEGROUND, LTrace))
    else if (AStopEvent and SE_GAP) <> 0 then
    begin
      LStart := LOrg;
      LEnd := LStart;
      LDouble := 48;
      LDouble := LDouble + FSettings.PhysMaxBarrier;
      LEnd[2] := LEnd[2] - LDouble;
      LGapTrace := FTracer.TraceClientBBox(LStart, LEnd, PRESENCE_CROUCH, -1);
      // if solid is found the bot cannot walk any further and will not fall into a gap
      if not LGapTrace.StartSolid then
      begin
        // if it is a gap (lower than one step height)
        LDelta := LOrg[2] - FSettings.PhysMaxStep;
        LDelta := LDelta - 1;
        if LGapTrace.EndPos[2] < LDelta then
          if (FWorld.PointContents(LEnd) and BSP_CONTENTS_WATER) = 0 then
            Exit(Done(LLastOrg, FSampler.PointAreaNum(LLastOrg), VelocityPerSecond, SE_GAP, LTrace));
      end;
    end;
    Inc(N);
  end;
  AMove.EndPos := LOrg;
  AMove.EndArea := FSampler.PointAreaNum(LOrg);
  AMove.Velocity := VelocityPerSecond;
  AMove.StopEvent := SE_NONE;
  AMove.PresenceType := LPresenceType;
  AMove.EndContents := 0;
  AMove.Time := N * LFrameTime;
  AMove.Frames := N;
  Result := True;
end;

function TAasMovement.PredictClientMovement(out AMove: TAasClientMove; const AEntNum: Integer;
  const AOrigin: TVec3; const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
  const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AStopEvent, AStopAreaNum: Integer;
  const AVisualize: Boolean): Boolean;
var
  LMins, LMaxs: TVec3;
begin
  // the box is not used without SE_HITBOUNDINGBOX
  FillChar(LMins, SizeOf(LMins), 0);
  FillChar(LMaxs, SizeOf(LMaxs), 0);
  Result := ClientMovementPrediction(AMove, AEntNum, AOrigin, APresenceType, AOnGround, AVelocity, ACmdMove,
    ACmdFrames, AMaxFrames, AFrameTime, AStopEvent, AStopAreaNum, LMins, LMaxs, AVisualize);
end;

function TAasMovement.ClientMovementHitBBox(out AMove: TAasClientMove; const AEntNum: Integer;
  const AOrigin: TVec3; const APresenceType: Integer; const AOnGround: Boolean; const AVelocity, ACmdMove: TVec3;
  const ACmdFrames, AMaxFrames: Integer; const AFrameTime: Single; const AMins, AMaxs: TVec3;
  const AVisualize: Boolean): Boolean;
begin
  Result := ClientMovementPrediction(AMove, AEntNum, AOrigin, APresenceType, AOnGround, AVelocity, ACmdMove,
    ACmdFrames, AMaxFrames, AFrameTime, SE_HITBOUNDINGBOX, 0, AMins, AMaxs, AVisualize);
end;

function TAasMovement.HorizontalVelocityForJump(const AZVel: Single; const AStart, AEnd: TVec3;
  out AVelocity: Single): Boolean;
var
  LGravity, LMaxVelocity, LMaxJump, LHeight2Fall, LT, LTop, LRatio, LSum, LTimeSum: Single;
  LDouble: Double;
  LDir: TVec3;
begin
  LGravity := FSettings.PhysGravity;
  LMaxVelocity := FSettings.PhysMaxVelocity;
  // maximum height a player can jump with the given initial z velocity
  LRatio := AZVel / LGravity;
  LDouble := CHalf * LGravity;
  LDouble := LDouble * LRatio;
  LDouble := LDouble * LRatio;
  LMaxJump := LDouble;
  // top of the parabolic jump
  LTop := AStart[2] + LMaxJump;
  // height the bot will fall from the top
  LHeight2Fall := LTop - AEnd[2];
  // if the goal is to high to jump to
  if LHeight2Fall < 0 then
  begin
    AVelocity := LMaxVelocity;
    Exit(False);
  end;
  // time a player takes to fall the height
  LDouble := CHalf * LGravity;
  LDouble := LHeight2Fall / LDouble;
  LT := Sqrt(LDouble);
  // direction from start to end
  TAasVectorMath.Subtract(AEnd, AStart, LDir);
  LTimeSum := AZVel / LGravity;
  LTimeSum := LT + LTimeSum;
  if LTimeSum = 0 then
  begin
    AVelocity := LMaxVelocity;
    Exit(False);
  end;
  // calculate horizontal speed
  LSum := LDir[0] * LDir[0];
  LRatio := LDir[1] * LDir[1];
  LSum := LSum + LRatio;
  LDouble := Sqrt(Double(LSum));
  LDouble := LDouble / LTimeSum;
  AVelocity := LDouble;
  // the horizontal speed must be lower than the max speed
  if AVelocity > LMaxVelocity then
  begin
    AVelocity := LMaxVelocity;
    Exit(False);
  end;
  Result := True;
end;

end.
