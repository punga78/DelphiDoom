{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the ground under the player                     }
{                                                                              }
{  Port of PM_GroundTrace, PM_GroundTraceMissed, PM_CorrectAllSolid,           }
{  PM_CrashLand and PM_FootstepForSurface of bg_pmove.c, from the Quake III    }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Ground;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.State,
  DelphiDoom.Pmove.Events;

type
  /// <summary>Finds what the player stands on, lands on it (the hard landings make events) and falls when it is gone</summary>
  TPmoveGround = class
  strict private
    FState: TPmoveState;
    FEvents: TPmoveEvents;
    procedure CrashLand;
    function CorrectAllSolid(var ATrace: TQ3Trace): Boolean;
    procedure GroundTraceMissed;
  public
    constructor Create(const AState: TPmoveState; const AEvents: TPmoveEvents);
    /// <summary>PM_GroundTrace: sets the ground entity, the ground plane and whether the player walks</summary>
    procedure GroundTrace;
    /// <summary>PM_FootstepForSurface: the event for the ground surface (0 when it makes no steps)</summary>
    function FootstepForSurface: Integer;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector, DelphiDoom.Collision.Q3.Math;

constructor TPmoveGround.Create(const AState: TPmoveState; const AEvents: TPmoveEvents);
begin
  inherited Create;
  FState := AState;
  FEvents := AEvents;
end;

function TPmoveGround.FootstepForSurface: Integer;
begin
  if (FState.Pml.GroundTrace.SurfaceFlags and Q3_SURF_NOSTEPS) <> 0 then
    Exit(0);
  if (FState.Pml.GroundTrace.SurfaceFlags and Q3_SURF_METALSTEPS) <> 0 then
    Exit(Q3_EV_FOOTSTEP_METAL);
  Result := Q3_EV_FOOTSTEP;
end;

procedure TPmoveGround.CrashLand;
var
  LDelta, LDistance, LVelocity, LAcceleration, LA, LB, LC, LDenominator, LTwoA, LSquare, LProduct: Single;
  LTime: Single;
  LNumerator, LQuotient, LDeltaProduct: Double;
  LNotANumber: Boolean;
begin
  // decide which landing animation to use
  if (FState.Pm.Ps.PmFlags and Q3_PMF_BACKWARDS_JUMP) <> 0 then
    FEvents.ForceLegsAnim(Q3_LEGS_LANDB)
  else
    FEvents.ForceLegsAnim(Q3_LEGS_LAND);

  FState.Pm.Ps.LegsTimer := Q3_TIMER_LAND;

  // calculate the exact velocity on landing
  LDistance := FState.Origin^[2] - FState.Pml.PreviousOrigin[2];
  LVelocity := FState.Pml.PreviousVelocity[2];
  LAcceleration := -FState.Pm.Ps.Gravity;

  LA := LAcceleration / 2;
  LB := LVelocity;
  LC := -LDistance;

  LSquare := LB * LB;
  LProduct := 4 * LA;
  LProduct := LProduct * LC;
  LDenominator := LSquare - LProduct;
  if LDenominator < 0 then
    Exit;
  LTwoA := 2 * LA;
  LNotANumber := LTwoA = 0;
  LDelta := 0;
  if not LNotANumber then
  begin
    LNumerator := -Double(LB) - Sqrt(Double(LDenominator));
    LQuotient := LNumerator / LTwoA;
    LTime := LQuotient;

    LProduct := LTime * LAcceleration;
    LDelta := LVelocity + LProduct;
    LSquare := LDelta * LDelta;
    LDeltaProduct := Double(LSquare) * Q3_FALL_SCALE;
    LDelta := LDeltaProduct;
  end;
  // with no gravity the original divides by zero: the time is infinite or not a number, and the delta
  // not a number, which no comparison below accepts (the landing is then a footstep)

  // ducking while falling doubles damage
  if (FState.Pm.Ps.PmFlags and Q3_PMF_DUCKED) <> 0 then
    LDelta := LDelta * 2;

  // never take falling damage if completely underwater
  if FState.Pm.WaterLevel = 3 then
    Exit;

  // reduce falling damage if there is standing water
  if FState.Pm.WaterLevel = 2 then
    LDelta := LDelta * 0.25;
  if FState.Pm.WaterLevel = 1 then
    LDelta := LDelta * 0.5;

  if (not LNotANumber) and (LDelta < 1) then
    Exit;

  // create a local entity event to play the sound

  // SURF_NODAMAGE is used for bounce pads where you don't ever want to take damage or play a crunch sound
  if (FState.Pml.GroundTrace.SurfaceFlags and Q3_SURF_NODAMAGE) = 0 then
  begin
    if (not LNotANumber) and (LDelta > 60) then
      FEvents.AddEvent(Q3_EV_FALL_FAR)
    else if (not LNotANumber) and (LDelta > 40) then
    begin
      // this is a pain grunt, so don't play it if dead
      if FState.Pm.Ps.Stats[Q3_STAT_HEALTH] > 0 then
        FEvents.AddEvent(Q3_EV_FALL_MEDIUM);
    end
    else if (not LNotANumber) and (LDelta > 7) then
      FEvents.AddEvent(Q3_EV_FALL_SHORT)
    else
      FEvents.AddEvent(FootstepForSurface);
  end;

  // start footstep cycle over
  FState.Pm.Ps.BobCycle := 0;
end;

function TPmoveGround.CorrectAllSolid(var ATrace: TQ3Trace): Boolean;
var
  LI, LJ, LK: Integer;
  LPoint: TQ3Vec3;
  LOffset: Single;
  LOrigin: PQ3Vec3;
begin
  if FState.Debugging then
    FState.DebugPrint(Format('%d:allsolid'#10, [FState.Counter]));
  LOrigin := FState.Origin;

  // jitter around
  for LI := -1 to 1 do
    for LJ := -1 to 1 do
      for LK := -1 to 1 do
      begin
        TPmoveVector.Copy(LOrigin^, LPoint);
        LOffset := LI;
        LPoint[0] := LPoint[0] + LOffset;
        LOffset := LJ;
        LPoint[1] := LPoint[1] + LOffset;
        LOffset := LK;
        LPoint[2] := LPoint[2] + LOffset;
        ATrace := FState.Trace(LPoint, FState.Pm.Mins, FState.Pm.Maxs, LPoint);
        if not ATrace.AllSolid then
        begin
          LPoint[0] := LOrigin^[0];
          LPoint[1] := LOrigin^[1];
          LPoint[2] := LOrigin^[2] - 0.25;

          ATrace := FState.Trace(LOrigin^, FState.Pm.Mins, FState.Pm.Maxs, LPoint);
          FState.Pml.GroundTrace := ATrace;
          Exit(True);
        end;
      end;

  FState.Pm.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  FState.Pml.GroundPlane := False;
  FState.Pml.Walking := False;
  Result := False;
end;

procedure TPmoveGround.GroundTraceMissed;
var
  LTrace: TQ3Trace;
  LPoint: TQ3Vec3;
begin
  if FState.Pm.Ps.GroundEntityNum <> Q3_ENTITYNUM_NONE then
  begin
    // we just transitioned into freefall
    if FState.Debugging then
      FState.DebugPrint(Format('%d:lift'#10, [FState.Counter]));

    // if they aren't in a jumping animation and the ground is a ways away, force into it; if we didn't do the
    // trace, the player would be backflipping down staircases
    TPmoveVector.Copy(FState.Origin^, LPoint);
    LPoint[2] := LPoint[2] - 64;

    LTrace := FState.Trace(FState.Origin^, FState.Pm.Mins, FState.Pm.Maxs, LPoint);
    if LTrace.Fraction = 1.0 then
    begin
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
    end;
  end;

  FState.Pm.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
  FState.Pml.GroundPlane := False;
  FState.Pml.Walking := False;
end;

procedure TPmoveGround.GroundTrace;
var
  LPoint: TQ3Vec3;
  LTrace: TQ3Trace;
  LOrigin, LVelocity: PQ3Vec3;
begin
  LOrigin := FState.Origin;
  LVelocity := FState.Velocity;
  LPoint[0] := LOrigin^[0];
  LPoint[1] := LOrigin^[1];
  LPoint[2] := LOrigin^[2] - 0.25;

  LTrace := FState.Trace(LOrigin^, FState.Pm.Mins, FState.Pm.Maxs, LPoint);
  FState.Pml.GroundTrace := LTrace;

  // do something corrective if the trace starts in a solid...
  if LTrace.AllSolid then
    if not CorrectAllSolid(LTrace) then
      Exit;

  // if the trace didn't hit anything, we are in free fall
  if LTrace.Fraction = 1.0 then
  begin
    GroundTraceMissed;
    FState.Pml.GroundPlane := False;
    FState.Pml.Walking := False;
    Exit;
  end;

  // check if getting thrown off the ground
  if (LVelocity^[2] > 0) and (TPmoveVector.Dot(LVelocity^, LTrace.Plane.Normal) > 10) then
  begin
    if FState.Debugging then
      FState.DebugPrint(Format('%d:kickoff'#10, [FState.Counter]));
    // go into jump animation
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

    FState.Pm.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
    FState.Pml.GroundPlane := False;
    FState.Pml.Walking := False;
    Exit;
  end;

  // slopes that are too steep will not be considered onground
  if LTrace.Plane.Normal[2] < Q3_MIN_WALK_NORMAL then
  begin
    if FState.Debugging then
      FState.DebugPrint(Format('%d:steep'#10, [FState.Counter]));
    // FIXME: if they can't slide down the slope, let them walk (sharp crevices)
    FState.Pm.Ps.GroundEntityNum := Q3_ENTITYNUM_NONE;
    FState.Pml.GroundPlane := True;
    FState.Pml.Walking := False;
    Exit;
  end;

  FState.Pml.GroundPlane := True;
  FState.Pml.Walking := True;

  // hitting solid ground will end a waterjump
  if (FState.Pm.Ps.PmFlags and Q3_PMF_TIME_WATERJUMP) <> 0 then
  begin
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not (Q3_PMF_TIME_WATERJUMP or Q3_PMF_TIME_LAND));
    FState.Pm.Ps.PmTime := 0;
  end;

  if FState.Pm.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE then
  begin
    // just hit the ground
    if FState.Debugging then
      FState.DebugPrint(Format('%d:Land'#10, [FState.Counter]));

    CrashLand;

    // don't do landing time if we were just going down a slope
    if FState.Pml.PreviousVelocity[2] < -200 then
    begin
      // don't allow another jump for a little while
      FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_TIME_LAND;
      FState.Pm.Ps.PmTime := 250;
    end;
  end;

  FState.Pm.Ps.GroundEntityNum := LTrace.EntityNum;

  // don't reset the z velocity for slopes

  FEvents.AddTouchEnt(LTrace.EntityNum);
end;

end.
