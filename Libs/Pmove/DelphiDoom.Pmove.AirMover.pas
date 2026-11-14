{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the movement in the air and on the grapple      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): PM_AirMove and  }
{  PM_GrappleMove of bg_pmove.c. Copyright (C) 1999-2005 Id Software, Inc.     }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.AirMover;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf,
  DelphiDoom.Pmove.State, DelphiDoom.Pmove.Physics, DelphiDoom.Pmove.Slider;

type
  /// <summary>Not on the ground: little control over the velocity, and the pull of the grapple</summary>
  TPmoveAirMover = class(TSingletonImplementation, IPmoveMovement)
  strict private
    FState: TPmoveState;
    FPhysics: TPmovePhysics;
    FSlider: TPmoveSlider;
  public
    constructor Create(const AState: TPmoveState; const APhysics: TPmovePhysics; const ASlider: TPmoveSlider);
    /// <summary>PM_AirMove</summary>
    procedure Move;
    /// <summary>PM_GrappleMove: the velocity towards the grapple point</summary>
    procedure GrappleMove;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;

constructor TPmoveAirMover.Create(const AState: TPmoveState; const APhysics: TPmovePhysics;
  const ASlider: TPmoveSlider);
begin
  inherited Create;
  FState := AState;
  FPhysics := APhysics;
  FSlider := ASlider;
end;

procedure TPmoveAirMover.Move;
var
  LIndex: Integer;
  LWishVelocity, LWishDirection: TQ3Vec3;
  LForwardMove, LSideMove, LWishSpeed, LScale, LTerm, LOther: Single;
  LCommand: TQ3UserCmd;
  LVelocity: PQ3Vec3;
begin
  LVelocity := FState.Velocity;
  FPhysics.Friction;

  LForwardMove := FState.Pm.Cmd.ForwardMove;
  LSideMove := FState.Pm.Cmd.RightMove;

  LCommand := FState.Pm.Cmd;
  LScale := FPhysics.CmdScale(LCommand);

  // set the movementDir so clients can rotate the legs for strafing
  FPhysics.SetMovementDir;

  // project moves down to flat plane
  FState.Pml.Forward[2] := 0;
  FState.Pml.Right[2] := 0;
  TPmoveVector.Normalize(FState.Pml.Forward);
  TPmoveVector.Normalize(FState.Pml.Right);

  for LIndex := 0 to 1 do
  begin
    LTerm := FState.Pml.Forward[LIndex] * LForwardMove;
    LOther := FState.Pml.Right[LIndex] * LSideMove;
    LWishVelocity[LIndex] := LTerm + LOther;
  end;
  LWishVelocity[2] := 0;

  TPmoveVector.Copy(LWishVelocity, LWishDirection);
  LWishSpeed := TPmoveVector.Normalize(LWishDirection);
  LWishSpeed := LWishSpeed * LScale;

  // not on ground, so little effect on velocity
  FPhysics.Accelerate(LWishDirection, LWishSpeed, FState.Tuning.AirAccelerate);

  // we may have a ground plane that is very steep, even though we don't have a groundentity: slide along the
  // steep plane
  if FState.Pml.GroundPlane then
    TPmoveVector.ClipVelocity(LVelocity^, FState.Pml.GroundTrace.Plane.Normal, LVelocity^, Q3_OVERCLIP);

  FSlider.StepSlideMove(True);
end;

procedure TPmoveAirMover.GrappleMove;
var
  LVelocity, LOffset: TQ3Vec3;
  LLength, LFactor: Single;
begin
  TPmoveVector.Scale(FState.Pml.Forward, -16, LOffset);
  TPmoveVector.Add(FState.GrapplePoint^, LOffset, LOffset);
  TPmoveVector.Subtract(LOffset, FState.Origin^, LVelocity);
  LLength := TPmoveVector.Length(LVelocity);
  TPmoveVector.Normalize(LVelocity);

  if LLength <= 100 then
  begin
    LFactor := 10 * LLength;
    TPmoveVector.Scale(LVelocity, LFactor, LVelocity);
  end
  else
    TPmoveVector.Scale(LVelocity, 800, LVelocity);

  TPmoveVector.Copy(LVelocity, FState.Velocity^);

  FState.Pml.GroundPlane := False;
end;

end.
