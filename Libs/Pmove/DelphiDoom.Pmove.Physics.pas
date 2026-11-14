{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - friction, acceleration and the scale of the     }
{  moves                                                                       }
{                                                                              }
{  Port of PM_Friction, PM_Accelerate, PM_CmdScale and PM_SetMovementDir of    }
{  bg_pmove.c, from the Quake III Arena GPL Source Code (id Software).         }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Physics;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types,
  DelphiDoom.Pmove.State;

type
  /// <summary>The rules every kind of movement shares: how a velocity slows down and speeds up</summary>
  TPmovePhysics = class
  strict private
    FState: TPmoveState;
  public
    constructor Create(const AState: TPmoveState);
    /// <summary>PM_Friction: handles both ground friction and water friction</summary>
    procedure Friction;
    /// <summary>PM_Accelerate: handles user intended acceleration (the Q2 style)</summary>
    procedure Accelerate(const AWishDirection: TQ3Vec3; const AWishSpeed, AAccelerate: Single);
    /// <summary>
    ///   PM_CmdScale: the scale factor to apply to the command moves, so that the axial -127 to 127 values of
    ///   all the directions give no sqrt(2) distortion in speed
    /// </summary>
    function CmdScale(const ACommand: TQ3UserCmd): Single;
    /// <summary>PM_SetMovementDir: the rotation of the legs relative to the facing direction</summary>
    procedure SetMovementDir;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;

constructor TPmovePhysics.Create(const AState: TPmoveState);
begin
  inherited Create;
  FState := AState;
end;

procedure TPmovePhysics.Friction;
var
  LVec: TQ3Vec3;
  LVelocity: PQ3Vec3;
  LSpeed, LNewSpeed, LControl, LDrop, LTerm, LWaterLevel: Single;
  LTuning: TPmoveTuning;
begin
  LTuning := FState.Tuning;
  LVelocity := FState.Velocity;

  TPmoveVector.Copy(LVelocity^, LVec);
  if FState.Pml.Walking then
    LVec[2] := 0; // ignore slope movement

  LSpeed := TPmoveVector.Length(LVec);
  if LSpeed < 1 then
  begin
    LVelocity^[0] := 0;
    LVelocity^[1] := 0; // allow sinking underwater
    // FIXME: still have z friction underwater?
    Exit;
  end;

  LDrop := 0;

  // apply ground friction
  if FState.Pm.WaterLevel <= 1 then
  begin
    if FState.Pml.Walking and ((FState.Pml.GroundTrace.SurfaceFlags and Q3_SURF_SLICK) = 0) then
    begin
      // if getting knocked back, no friction
      if (FState.Pm.Ps.PmFlags and Q3_PMF_TIME_KNOCKBACK) = 0 then
      begin
        if LSpeed < LTuning.StopSpeed then
          LControl := LTuning.StopSpeed
        else
          LControl := LSpeed;
        LTerm := LControl * LTuning.Friction;
        LTerm := LTerm * FState.Pml.FrameTime;
        LDrop := LDrop + LTerm;
      end;
    end;
  end;

  // apply water friction even if just wading
  if FState.Pm.WaterLevel <> 0 then
  begin
    LWaterLevel := FState.Pm.WaterLevel;
    LTerm := LSpeed * LTuning.WaterFriction;
    LTerm := LTerm * LWaterLevel;
    LTerm := LTerm * FState.Pml.FrameTime;
    LDrop := LDrop + LTerm;
  end;

  // apply flying friction
  if FState.Pm.Ps.Powerups[Q3_PW_FLIGHT] <> 0 then
  begin
    LTerm := LSpeed * LTuning.FlightFriction;
    LTerm := LTerm * FState.Pml.FrameTime;
    LDrop := LDrop + LTerm;
  end;

  if FState.Pm.Ps.PmType = Q3_PM_SPECTATOR then
  begin
    LTerm := LSpeed * LTuning.SpectatorFriction;
    LTerm := LTerm * FState.Pml.FrameTime;
    LDrop := LDrop + LTerm;
  end;

  // scale the velocity
  LNewSpeed := LSpeed - LDrop;
  if LNewSpeed < 0 then
    LNewSpeed := 0;
  LNewSpeed := LNewSpeed / LSpeed;

  LTerm := LVelocity^[0] * LNewSpeed;
  LVelocity^[0] := LTerm;
  LTerm := LVelocity^[1] * LNewSpeed;
  LVelocity^[1] := LTerm;
  LTerm := LVelocity^[2] * LNewSpeed;
  LVelocity^[2] := LTerm;
end;

procedure TPmovePhysics.Accelerate(const AWishDirection: TQ3Vec3; const AWishSpeed, AAccelerate: Single);
var
  LVelocity: PQ3Vec3;
  LAddSpeed, LAccelSpeed, LCurrentSpeed, LTerm: Single;
begin
  LVelocity := FState.Velocity;
  LCurrentSpeed := TPmoveVector.Dot(LVelocity^, AWishDirection);
  LAddSpeed := AWishSpeed - LCurrentSpeed;
  if LAddSpeed <= 0 then
    Exit;
  LAccelSpeed := AAccelerate * FState.Pml.FrameTime;
  LAccelSpeed := LAccelSpeed * AWishSpeed;
  if LAccelSpeed > LAddSpeed then
    LAccelSpeed := LAddSpeed;

  LTerm := LAccelSpeed * AWishDirection[0];
  LVelocity^[0] := LVelocity^[0] + LTerm;
  LTerm := LAccelSpeed * AWishDirection[1];
  LVelocity^[1] := LVelocity^[1] + LTerm;
  LTerm := LAccelSpeed * AWishDirection[2];
  LVelocity^[2] := LVelocity^[2] + LTerm;
end;

function TPmovePhysics.CmdScale(const ACommand: TQ3UserCmd): Single;
var
  LMax, LForward, LRight, LUp: Integer;
  LSpeed, LProduct, LTotal: Single;
  LRoot, LDenominator, LScale: Double;
begin
  LForward := ACommand.ForwardMove;
  LRight := ACommand.RightMove;
  LUp := ACommand.UpMove;
  LMax := Abs(LForward);
  if Abs(LRight) > LMax then
    LMax := Abs(LRight);
  if Abs(LUp) > LMax then
    LMax := Abs(LUp);
  if LMax = 0 then
    Exit(0);

  // total is a float: the double square root of the integer sum is rounded to it
  LRoot := Sqrt(Double(LForward * LForward + LRight * LRight + LUp * LUp));
  LTotal := LRoot;
  // (float)speed * max is a float product; 127.0 * total and the division are doubles
  LSpeed := FState.Pm.Ps.Speed;
  LProduct := LSpeed * LMax;
  LDenominator := 127.0 * LTotal;
  LScale := Double(LProduct) / LDenominator;
  Result := LScale;
end;

procedure TPmovePhysics.SetMovementDir;
var
  LForward, LRight: Integer;
begin
  LForward := FState.Pm.Cmd.ForwardMove;
  LRight := FState.Pm.Cmd.RightMove;
  if (LForward <> 0) or (LRight <> 0) then
  begin
    if (LRight = 0) and (LForward > 0) then
      FState.Pm.Ps.MovementDir := 0
    else if (LRight < 0) and (LForward > 0) then
      FState.Pm.Ps.MovementDir := 1
    else if (LRight < 0) and (LForward = 0) then
      FState.Pm.Ps.MovementDir := 2
    else if (LRight < 0) and (LForward < 0) then
      FState.Pm.Ps.MovementDir := 3
    else if (LRight = 0) and (LForward < 0) then
      FState.Pm.Ps.MovementDir := 4
    else if (LRight > 0) and (LForward < 0) then
      FState.Pm.Ps.MovementDir := 5
    else if (LRight > 0) and (LForward = 0) then
      FState.Pm.Ps.MovementDir := 6
    else if (LRight > 0) and (LForward > 0) then
      FState.Pm.Ps.MovementDir := 7;
  end
  else
  begin
    // if they aren't actively going directly sideways, change the animation to the diagonal so they don't
    // stop too crooked
    if FState.Pm.Ps.MovementDir = 2 then
      FState.Pm.Ps.MovementDir := 1
    else if FState.Pm.Ps.MovementDir = 6 then
      FState.Pm.Ps.MovementDir := 7;
  end;
end;

end.
