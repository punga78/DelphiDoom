{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - flying: the flight powerup, spectators, noclip  }
{                                                                              }
{  Port of PM_FlyMove and PM_NoclipMove of bg_pmove.c, from the Quake III      }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.FlyMover;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Defaults, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.Intf,
  DelphiDoom.Pmove.State, DelphiDoom.Pmove.Physics, DelphiDoom.Pmove.Slider;

type
  /// <summary>Movement that does not walk: with the flight powerup, as a spectator, without clipping</summary>
  TPmoveFlyMover = class(TSingletonImplementation, IPmoveMovement)
  strict private
    FState: TPmoveState;
    FPhysics: TPmovePhysics;
    FSlider: TPmoveSlider;
  public
    constructor Create(const AState: TPmoveState; const APhysics: TPmovePhysics; const ASlider: TPmoveSlider);
    /// <summary>PM_FlyMove: only with the flight powerup, and for the spectators</summary>
    procedure Move;
    /// <summary>PM_NoclipMove: free movement through the walls</summary>
    procedure NoclipMove;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;

constructor TPmoveFlyMover.Create(const AState: TPmoveState; const APhysics: TPmovePhysics;
  const ASlider: TPmoveSlider);
begin
  inherited Create;
  FState := AState;
  FPhysics := APhysics;
  FSlider := ASlider;
end;

procedure TPmoveFlyMover.Move;
var
  LIndex: Integer;
  LWishVelocity, LWishDirection: TQ3Vec3;
  LWishSpeed, LScale, LTerm, LOther: Single;
begin
  // normal slowdown
  FPhysics.Friction;

  LScale := FPhysics.CmdScale(FState.Pm.Cmd);
  // user intentions
  if LScale = 0 then
  begin
    LWishVelocity[0] := 0;
    LWishVelocity[1] := 0;
    LWishVelocity[2] := 0;
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

  FPhysics.Accelerate(LWishDirection, LWishSpeed, FState.Tuning.FlyAccelerate);

  FSlider.StepSlideMove(False);
end;

procedure TPmoveFlyMover.NoclipMove;
var
  LIndex: Integer;
  LWishVelocity, LWishDirection: TQ3Vec3;
  LSpeed, LDrop, LFriction, LControl, LNewSpeed, LForwardMove, LSideMove, LWishSpeed, LScale, LTerm, LOther: Single;
  LDoubleFriction: Double;
  LVelocity: PQ3Vec3;
begin
  LVelocity := FState.Velocity;
  FState.Pm.Ps.ViewHeight := Q3_DEFAULT_VIEWHEIGHT;

  // friction
  LSpeed := TPmoveVector.Length(LVelocity^);
  if LSpeed < 1 then
    TPmoveVector.Clear(LVelocity^)
  else
  begin
    LDrop := 0;

    // extra friction: pm_friction*1.5 is a double expression
    LDoubleFriction := Double(FState.Tuning.Friction) * 1.5;
    LFriction := LDoubleFriction;
    if LSpeed < FState.Tuning.StopSpeed then
      LControl := FState.Tuning.StopSpeed
    else
      LControl := LSpeed;
    LTerm := LControl * LFriction;
    LTerm := LTerm * FState.Pml.FrameTime;
    LDrop := LDrop + LTerm;

    // scale the velocity
    LNewSpeed := LSpeed - LDrop;
    if LNewSpeed < 0 then
      LNewSpeed := 0;
    LNewSpeed := LNewSpeed / LSpeed;

    TPmoveVector.Scale(LVelocity^, LNewSpeed, LVelocity^);
  end;

  // accelerate
  LScale := FPhysics.CmdScale(FState.Pm.Cmd);

  LForwardMove := FState.Pm.Cmd.ForwardMove;
  LSideMove := FState.Pm.Cmd.RightMove;

  for LIndex := 0 to 2 do
  begin
    LTerm := FState.Pml.Forward[LIndex] * LForwardMove;
    LOther := FState.Pml.Right[LIndex] * LSideMove;
    LWishVelocity[LIndex] := LTerm + LOther;
  end;
  LTerm := FState.Pm.Cmd.UpMove;
  LWishVelocity[2] := LWishVelocity[2] + LTerm;

  TPmoveVector.Copy(LWishVelocity, LWishDirection);
  LWishSpeed := TPmoveVector.Normalize(LWishDirection);
  LWishSpeed := LWishSpeed * LScale;

  FPhysics.Accelerate(LWishDirection, LWishSpeed, FState.Tuning.Accelerate);

  // move
  TPmoveVector.MultiplyAdd(FState.Origin^, FState.Pml.FrameTime, LVelocity^, FState.Origin^);
end;

end.
