{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - walking, jumping and the dead on the ground     }
{                                                                              }
{  Port of PM_WalkMove, PM_CheckJump and PM_DeadMove of bg_pmove.c, from the   }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.WalkMover;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf,
  DelphiDoom.Pmove.State, DelphiDoom.Pmove.Events, DelphiDoom.Pmove.Physics, DelphiDoom.Pmove.Slider;

type
  /// <summary>
  ///   On the ground: the wish speed follows the slope, ducking and the water slow it down, a jump leaves the
  ///   ground into the air or the water movement
  /// </summary>
  TPmoveWalkMover = class(TSingletonImplementation, IPmoveMovement)
  strict private
    FState: TPmoveState;
    FEvents: TPmoveEvents;
    FPhysics: TPmovePhysics;
    FSlider: TPmoveSlider;
    FWater: IPmoveMovement;
    FAir: IPmoveMovement;
    function CheckJump: Boolean;
  public
    /// <summary>AWater and AAir are the movements a jump or a deep water change to</summary>
    constructor Create(const AState: TPmoveState; const AEvents: TPmoveEvents; const APhysics: TPmovePhysics;
      const ASlider: TPmoveSlider; const AWater, AAir: IPmoveMovement);
    /// <summary>PM_WalkMove</summary>
    procedure Move;
    /// <summary>PM_DeadMove: the extra friction of a corpse that lies on the ground</summary>
    procedure DeadMove;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;


constructor TPmoveWalkMover.Create(const AState: TPmoveState; const AEvents: TPmoveEvents;
  const APhysics: TPmovePhysics; const ASlider: TPmoveSlider; const AWater, AAir: IPmoveMovement);
begin
  inherited Create;
  FState := AState;
  FEvents := AEvents;
  FPhysics := APhysics;
  FSlider := ASlider;
  FWater := AWater;
  FAir := AAir;
end;

function TPmoveWalkMover.CheckJump: Boolean;
begin
  if (FState.Pm.Ps.PmFlags and Q3_PMF_RESPAWNED) <> 0 then
    Exit(False); // don't allow jump until all buttons are up

  if FState.Pm.Cmd.UpMove < 10 then
    // not holding jump
    Exit(False);

  // must wait for jump to be released
  if (FState.Pm.Ps.PmFlags and Q3_PMF_JUMP_HELD) <> 0 then
  begin
    // clear upmove so cmdscale doesn't lower running speed
    FState.Pm.Cmd.UpMove := 0;
    Exit(False);
  end;

  FState.Pml.GroundPlane := False; // jumping away
  FState.Pml.Walking := False;
  FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_JUMP_HELD;

  FState.Pm.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  FState.Velocity^[2] := Q3_JUMP_VELOCITY;
  FEvents.AddEvent(Q3_EV_JUMP);

  if FState.Pm.Cmd.ForwardMove >= 0 then
  begin
    FEvents.ForceLegsAnim(Q3_LEGS_JUMP);
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_BACKWARDS_JUMP);
  end
  else
  begin
    FEvents.ForceLegsAnim(Q3_LEGS_JUMPB);
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_BACKWARDS_JUMP;
  end;

  Result := True;
end;

procedure TPmoveWalkMover.Move;
var
  LIndex: Integer;
  LWishVelocity, LWishDirection: TQ3Vec3;
  LForwardMove, LSideMove, LWishSpeed, LScale, LTerm, LOther, LAccelerate, LVel, LLimit, LWaterScale, LGravity,
    LStep: Single;
  LDoubleScale: Double;
  LCommand: TQ3UserCmd;
  LVelocity: PQ3Vec3;
  LSlick: Boolean;
begin
  if (FState.Pm.WaterLevel > 2) and (TPmoveVector.Dot(FState.Pml.Forward, FState.Pml.GroundTrace.Plane.Normal) > 0) then
  begin
    // begin swimming
    FWater.Move;
    Exit;
  end;

  if CheckJump then
  begin
    // jumped away
    if FState.Pm.WaterLevel > 1 then
      FWater.Move
    else
      FAir.Move;
    Exit;
  end;

  FPhysics.Friction;
  LVelocity := FState.Velocity;

  LForwardMove := FState.Pm.Cmd.ForwardMove;
  LSideMove := FState.Pm.Cmd.RightMove;

  LCommand := FState.Pm.Cmd;
  LScale := FPhysics.CmdScale(LCommand);

  // set the movementDir so clients can rotate the legs for strafing
  FPhysics.SetMovementDir;

  // project moves down to flat plane
  FState.Pml.Forward[2] := 0;
  FState.Pml.Right[2] := 0;

  // project the forward and right directions onto the ground plane
  TPmoveVector.ClipVelocity(FState.Pml.Forward, FState.Pml.GroundTrace.Plane.Normal, FState.Pml.Forward, Q3_OVERCLIP);
  TPmoveVector.ClipVelocity(FState.Pml.Right, FState.Pml.GroundTrace.Plane.Normal, FState.Pml.Right, Q3_OVERCLIP);

  TPmoveVector.Normalize(FState.Pml.Forward);
  TPmoveVector.Normalize(FState.Pml.Right);

  for LIndex := 0 to 2 do
  begin
    LTerm := FState.Pml.Forward[LIndex] * LForwardMove;
    LOther := FState.Pml.Right[LIndex] * LSideMove;
    LWishVelocity[LIndex] := LTerm + LOther;
  end;
  // when going up or down slopes the wish velocity should Not be zero

  TPmoveVector.Copy(LWishVelocity, LWishDirection);
  LWishSpeed := TPmoveVector.Normalize(LWishDirection);
  LWishSpeed := LWishSpeed * LScale;

  // clamp the speed lower if ducking
  if (FState.Pm.Ps.PmFlags and Q3_PMF_DUCKED) <> 0 then
  begin
    LLimit := FState.Pm.Ps.Speed;
    LLimit := LLimit * FState.Tuning.DuckScale;
    if LWishSpeed > LLimit then
      LWishSpeed := LLimit;
  end;

  // clamp the speed lower if wading or walking on the bottom
  if FState.Pm.WaterLevel <> 0 then
  begin
    // waterScale is a float assigned from double expressions
    LDoubleScale := FState.Pm.WaterLevel / Q3_WATER_DIVISOR;
    LWaterScale := LDoubleScale;
    LDoubleScale := 1.0 - Double(FState.Tuning.SwimScale);
    LDoubleScale := LDoubleScale * Double(LWaterScale);
    LDoubleScale := 1.0 - LDoubleScale;
    LWaterScale := LDoubleScale;
    LLimit := FState.Pm.Ps.Speed;
    LLimit := LLimit * LWaterScale;
    if LWishSpeed > LLimit then
      LWishSpeed := LLimit;
  end;

  // when a player gets hit, they temporarily lose full control, which allows them to be moved a bit
  LSlick := ((FState.Pml.GroundTrace.SurfaceFlags and Q3_SURF_SLICK) <> 0) or
    ((FState.Pm.Ps.PmFlags and Q3_PMF_TIME_KNOCKBACK) <> 0);
  if LSlick then
    LAccelerate := FState.Tuning.AirAccelerate
  else
    LAccelerate := FState.Tuning.Accelerate;

  FPhysics.Accelerate(LWishDirection, LWishSpeed, LAccelerate);

  if LSlick then
  begin
    LGravity := FState.Pm.Ps.Gravity;
    LStep := LGravity * FState.Pml.FrameTime;
    LVelocity^[2] := LVelocity^[2] - LStep;
  end;
  // don't reset the z velocity for slopes

  LVel := TPmoveVector.Length(LVelocity^);

  // slide along the ground plane
  TPmoveVector.ClipVelocity(LVelocity^, FState.Pml.GroundTrace.Plane.Normal, LVelocity^, Q3_OVERCLIP);

  // don't decrease velocity when going up or down a slope
  TPmoveVector.Normalize(LVelocity^);
  TPmoveVector.Scale(LVelocity^, LVel, LVelocity^);

  // don't do anything if standing still
  if (LVelocity^[0] = 0) and (LVelocity^[1] = 0) then
    Exit;

  FSlider.StepSlideMove(False);
end;

procedure TPmoveWalkMover.DeadMove;
var
  LForward: Single;
  LVelocity: PQ3Vec3;
begin
  if not FState.Pml.Walking then
    Exit;

  // extra friction
  LVelocity := FState.Velocity;
  LForward := TPmoveVector.Length(LVelocity^);
  LForward := LForward - 20;
  if LForward <= 0 then
    TPmoveVector.Clear(LVelocity^)
  else
  begin
    TPmoveVector.Normalize(LVelocity^);
    TPmoveVector.Scale(LVelocity^, LForward, LVelocity^);
  end;
end;

end.
