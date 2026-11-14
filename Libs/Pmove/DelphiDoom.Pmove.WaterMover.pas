{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - swimming and the jump out of the water          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): PM_WaterMove,   }
{  PM_CheckWaterJump and PM_WaterJumpMove of bg_pmove.c. Copyright (C)         }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.WaterMover;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf,
  DelphiDoom.Pmove.State, DelphiDoom.Pmove.Physics, DelphiDoom.Pmove.Slider;

type
  /// <summary>Under water (the water level is over 1): swimming, and the jump onto a ledge</summary>
  TPmoveWaterMover = class(TSingletonImplementation, IPmoveWaterMovement)
  strict private
    FState: TPmoveState;
    FPhysics: TPmovePhysics;
    FSlider: TPmoveSlider;
    function CheckWaterJump: Boolean;
  public
    constructor Create(const AState: TPmoveState; const APhysics: TPmovePhysics; const ASlider: TPmoveSlider);
    /// <summary>PM_WaterMove</summary>
    procedure Move;
    /// <summary>PM_WaterJumpMove</summary>
    procedure WaterJumpMove;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;

constructor TPmoveWaterMover.Create(const AState: TPmoveState; const APhysics: TPmovePhysics;
  const ASlider: TPmoveSlider);
begin
  inherited Create;
  FState := AState;
  FPhysics := APhysics;
  FSlider := ASlider;
end;

function TPmoveWaterMover.CheckWaterJump: Boolean;
var
  LSpot, LFlatForward: TQ3Vec3;
  LContents: Integer;
begin
  if FState.Pm.Ps.PmTime <> 0 then
    Exit(False);

  // check for water jump
  if FState.Pm.WaterLevel <> 2 then
    Exit(False);

  LFlatForward[0] := FState.Pml.Forward[0];
  LFlatForward[1] := FState.Pml.Forward[1];
  LFlatForward[2] := 0;
  TPmoveVector.Normalize(LFlatForward);

  TPmoveVector.MultiplyAdd(FState.Origin^, 30, LFlatForward, LSpot);
  LSpot[2] := LSpot[2] + 4;
  LContents := FState.PointContents(LSpot);
  if (LContents and Q3_CONTENTS_SOLID) = 0 then
    Exit(False);

  LSpot[2] := LSpot[2] + 16;
  LContents := FState.PointContents(LSpot);
  if LContents <> 0 then
    Exit(False);

  // jump out of water
  TPmoveVector.Scale(FState.Pml.Forward, 200, FState.Velocity^);
  FState.Velocity^[2] := 350;

  FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_TIME_WATERJUMP;
  FState.Pm.Ps.PmTime := 2000;

  Result := True;
end;

procedure TPmoveWaterMover.WaterJumpMove;
var
  LGravity, LStep: Single;
begin
  // waterjump has no control, but falls
  FSlider.StepSlideMove(True);

  LGravity := FState.Pm.Ps.Gravity;
  LStep := LGravity * FState.Pml.FrameTime;
  FState.Velocity^[2] := FState.Velocity^[2] - LStep;
  if FState.Velocity^[2] < 0 then
  begin
    // cancel as soon as we are falling down again
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_ALL_TIMES);
    FState.Pm.Ps.PmTime := 0;
  end;
end;

procedure TPmoveWaterMover.Move;
var
  LIndex: Integer;
  LWishVelocity, LWishDirection: TQ3Vec3;
  LWishSpeed, LScale, LVel, LTerm, LOther, LLimit, LDirection: Single;
  LVelocity: PQ3Vec3;
begin
  if CheckWaterJump then
  begin
    WaterJumpMove;
    Exit;
  end;
  LVelocity := FState.Velocity;

  FPhysics.Friction;

  LScale := FPhysics.CmdScale(FState.Pm.Cmd);
  // user intentions
  if LScale = 0 then
  begin
    LWishVelocity[0] := 0;
    LWishVelocity[1] := 0;
    LWishVelocity[2] := -60; // sink towards bottom
  end
  else
  begin
    for LIndex := 0 to 2 do
    begin
      LTerm := LScale * FState.Pml.Forward[LIndex];
      LTerm := LTerm * FState.Pm.Cmd.ForwardMove;
      LOther := LScale * FState.Pml.Right[LIndex];
      LOther := LOther * FState.Pm.Cmd.RightMove;
      LWishVelocity[LIndex] := LTerm + LOther;
    end;

    LTerm := LScale * FState.Pm.Cmd.UpMove;
    LWishVelocity[2] := LWishVelocity[2] + LTerm;
  end;

  TPmoveVector.Copy(LWishVelocity, LWishDirection);
  LWishSpeed := TPmoveVector.Normalize(LWishDirection);

  LLimit := FState.Pm.Ps.Speed;
  LLimit := LLimit * FState.Tuning.SwimScale;
  if LWishSpeed > LLimit then
    LWishSpeed := LLimit;

  FPhysics.Accelerate(LWishDirection, LWishSpeed, FState.Tuning.WaterAccelerate);

  // make sure we can go up slopes easily under water
  if FState.Pml.GroundPlane then
  begin
    LDirection := TPmoveVector.Dot(LVelocity^, FState.Pml.GroundTrace.Plane.Normal);
    if LDirection < 0 then
    begin
      LVel := TPmoveVector.Length(LVelocity^);
      // slide along the ground plane
      TPmoveVector.ClipVelocity(LVelocity^, FState.Pml.GroundTrace.Plane.Normal, LVelocity^, Q3_OVERCLIP);

      TPmoveVector.Normalize(LVelocity^);
      TPmoveVector.Scale(LVelocity^, LVel, LVelocity^);
    end;
  end;

  FSlider.SlideMove(False);
end;

end.
