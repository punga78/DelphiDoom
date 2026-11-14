{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - sliding along the walls and over steps          }
{                                                                              }
{  Port of PM_SlideMove and PM_StepSlideMove of bg_slidemove.c, from the       }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Slider;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Collision.Q3.Types, DelphiDoom.Pmove.Types, DelphiDoom.Pmove.State,
  DelphiDoom.Pmove.Events;

type
  /// <summary>
  ///   Moves the player along its velocity against the world: up to four bumps, the planes it slid along are
  ///   remembered so that it never turns against them; over a step of up to STEPSIZE it tries the move again
  ///   from a step higher
  /// </summary>
  TPmoveSlider = class
  strict private
    FState: TPmoveState;
    FEvents: TPmoveEvents;
  public
    constructor Create(const AState: TPmoveState; const AEvents: TPmoveEvents);
    /// <summary>PM_SlideMove: True if the velocity was clipped in some way</summary>
    function SlideMove(const AGravity: Boolean): Boolean;
    /// <summary>PM_StepSlideMove</summary>
    procedure StepSlideMove(const AGravity: Boolean);
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;

const
  MAX_CLIP_PLANES = 5;

constructor TPmoveSlider.Create(const AState: TPmoveState; const AEvents: TPmoveEvents);
begin
  inherited Create;
  FState := AState;
  FEvents := AEvents;
end;

function TPmoveSlider.SlideMove(const AGravity: Boolean): Boolean;
var
  LBumpCount, LNumBumps, LNumPlanes, LIndex, LSecond, LThird: Integer;
  LDirection, LPrimalVelocity, LClipVelocity, LEnd, LEndVelocity, LEndClipVelocity: TQ3Vec3;
  LPlanes: array[0..MAX_CLIP_PLANES - 1] of TQ3Vec3;
  LTrace: TQ3Trace;
  LTimeLeft, LInto, LDistance, LGravity, LStep, LNegated: Single;
  LOrigin, LVelocity: PQ3Vec3;
  LSamePlane, LHandled: Boolean;
begin
  LOrigin := FState.Origin;
  LVelocity := FState.Velocity;
  LNumBumps := 4;
  // the original leaves endVelocity unset when there is no gravity: it is not used then
  TPmoveVector.Clear(LEndVelocity);
  TPmoveVector.Clear(LEndClipVelocity);
  TPmoveVector.Copy(LVelocity^, LPrimalVelocity);

  if AGravity then
  begin
    TPmoveVector.Copy(LVelocity^, LEndVelocity);
    LGravity := FState.Pm.Ps.Gravity;
    LStep := LGravity * FState.Pml.FrameTime;
    LEndVelocity[2] := LEndVelocity[2] - LStep;
    LStep := LVelocity^[2] + LEndVelocity[2];
    LVelocity^[2] := LStep * 0.5;
    LPrimalVelocity[2] := LEndVelocity[2];
    if FState.Pml.GroundPlane then
      // slide along the ground plane
      TPmoveVector.ClipVelocity(LVelocity^, FState.Pml.GroundTrace.Plane.Normal, LVelocity^, Q3_OVERCLIP);
  end;

  LTimeLeft := FState.Pml.FrameTime;

  // never turn against the ground plane
  if FState.Pml.GroundPlane then
  begin
    LNumPlanes := 1;
    TPmoveVector.Copy(FState.Pml.GroundTrace.Plane.Normal, LPlanes[0]);
  end
  else
    LNumPlanes := 0;

  // never turn against original velocity
  TPmoveVector.Normalize2(LVelocity^, LPlanes[LNumPlanes]);
  Inc(LNumPlanes);

  LBumpCount := 0;
  while LBumpCount < LNumBumps do
  begin
    // calculate position we are trying to move to
    TPmoveVector.MultiplyAdd(LOrigin^, LTimeLeft, LVelocity^, LEnd);

    // see if we can make it there
    LTrace := FState.Trace(LOrigin^, FState.Pm.Mins, FState.Pm.Maxs, LEnd);

    if LTrace.AllSolid then
    begin
      // entity is completely trapped in another solid
      LVelocity^[2] := 0; // don't build up falling damage, but allow sideways acceleration
      Exit(True);
    end;

    if LTrace.Fraction > 0 then
      // actually covered some distance
      TPmoveVector.Copy(LTrace.EndPos, LOrigin^);

    if LTrace.Fraction = 1 then
      Break; // moved the entire distance

    // save entity for contact
    FEvents.AddTouchEnt(LTrace.EntityNum);

    LStep := LTimeLeft * LTrace.Fraction;
    LTimeLeft := LTimeLeft - LStep;

    if LNumPlanes >= MAX_CLIP_PLANES then
    begin
      // this shouldn't really happen
      TPmoveVector.Clear(LVelocity^);
      Exit(True);
    end;

    // if this is the same plane we hit before, nudge velocity out along it, which fixes some epsilon issues
    // with non-axial planes
    LSamePlane := False;
    for LIndex := 0 to LNumPlanes - 1 do
      if Double(TPmoveVector.Dot(LTrace.Plane.Normal, LPlanes[LIndex])) > Q3_SAME_PLANE then
      begin
        TPmoveVector.Add(LTrace.Plane.Normal, LVelocity^, LVelocity^);
        LSamePlane := True;
        Break;
      end;
    if LSamePlane then
    begin
      Inc(LBumpCount);
      Continue;
    end;
    TPmoveVector.Copy(LTrace.Plane.Normal, LPlanes[LNumPlanes]);
    Inc(LNumPlanes);

    // modify velocity so it parallels all of the clip planes: find a plane that it enters
    for LIndex := 0 to LNumPlanes - 1 do
    begin
      LInto := TPmoveVector.Dot(LVelocity^, LPlanes[LIndex]);
      if Double(LInto) >= Q3_CLIP_INTO then
        Continue; // move doesn't interact with the plane

      // see how hard we are hitting things
      LNegated := -LInto;
      if LNegated > FState.Pml.ImpactSpeed then
        FState.Pml.ImpactSpeed := LNegated;

      // slide along the plane
      TPmoveVector.ClipVelocity(LVelocity^, LPlanes[LIndex], LClipVelocity, Q3_OVERCLIP);
      TPmoveVector.ClipVelocity(LEndVelocity, LPlanes[LIndex], LEndClipVelocity, Q3_OVERCLIP);

      // see if there is a second plane that the new move enters
      for LSecond := 0 to LNumPlanes - 1 do
      begin
        if LSecond = LIndex then
          Continue;
        if Double(TPmoveVector.Dot(LClipVelocity, LPlanes[LSecond])) >= Q3_CLIP_INTO then
          Continue; // move doesn't interact with the plane

        // try clipping the move to the plane
        TPmoveVector.ClipVelocity(LClipVelocity, LPlanes[LSecond], LClipVelocity, Q3_OVERCLIP);
        TPmoveVector.ClipVelocity(LEndClipVelocity, LPlanes[LSecond], LEndClipVelocity, Q3_OVERCLIP);

        // see if it goes back into the first clip plane
        if TPmoveVector.Dot(LClipVelocity, LPlanes[LIndex]) >= 0 then
          Continue;

        // slide the original velocity along the crease
        TPmoveVector.Cross(LPlanes[LIndex], LPlanes[LSecond], LDirection);
        TPmoveVector.Normalize(LDirection);
        LDistance := TPmoveVector.Dot(LDirection, LVelocity^);
        TPmoveVector.Scale(LDirection, LDistance, LClipVelocity);

        TPmoveVector.Cross(LPlanes[LIndex], LPlanes[LSecond], LDirection);
        TPmoveVector.Normalize(LDirection);
        LDistance := TPmoveVector.Dot(LDirection, LEndVelocity);
        TPmoveVector.Scale(LDirection, LDistance, LEndClipVelocity);

        // see if there is a third plane the the new move enters
        for LThird := 0 to LNumPlanes - 1 do
        begin
          if (LThird = LIndex) or (LThird = LSecond) then
            Continue;
          if Double(TPmoveVector.Dot(LClipVelocity, LPlanes[LThird])) >= Q3_CLIP_INTO then
            Continue; // move doesn't interact with the plane

          // stop dead at a tripple plane interaction
          TPmoveVector.Clear(LVelocity^);
          Exit(True);
        end;
      end;

      // if we have fixed all interactions, try another move
      TPmoveVector.Copy(LClipVelocity, LVelocity^);
      TPmoveVector.Copy(LEndClipVelocity, LEndVelocity);
      Break;
    end;
    Inc(LBumpCount);
  end;

  if AGravity then
    TPmoveVector.Copy(LEndVelocity, LVelocity^);

  // don't change velocity if in a timer (FIXME: is this correct?)
  if FState.Pm.Ps.PmTime <> 0 then
    TPmoveVector.Copy(LPrimalVelocity, LVelocity^);

  LHandled := LBumpCount <> 0;
  Result := LHandled;
end;

procedure TPmoveSlider.StepSlideMove(const AGravity: Boolean);
var
  LStartOrigin, LStartVelocity, LUp, LDown: TQ3Vec3;
  LTrace: TQ3Trace;
  LStepSize, LDelta: Single;
  LOrigin, LVelocity: PQ3Vec3;
begin
  LOrigin := FState.Origin;
  LVelocity := FState.Velocity;
  TPmoveVector.Copy(LOrigin^, LStartOrigin);
  TPmoveVector.Copy(LVelocity^, LStartVelocity);

  if not SlideMove(AGravity) then
    Exit; // we got exactly where we wanted to go first try

  TPmoveVector.Copy(LStartOrigin, LDown);
  LDown[2] := LDown[2] - Q3_STEPSIZE;
  LTrace := FState.Trace(LStartOrigin, FState.Pm.Mins, FState.Pm.Maxs, LDown);
  LUp[0] := 0;
  LUp[1] := 0;
  LUp[2] := 1;
  // never step up when you still have up velocity
  if (LVelocity^[2] > 0) and ((LTrace.Fraction = 1.0) or (Double(TPmoveVector.Dot(LTrace.Plane.Normal, LUp)) < Q3_STEP_NORMAL)) then
    Exit;

  TPmoveVector.Copy(LStartOrigin, LUp);
  LUp[2] := LUp[2] + Q3_STEPSIZE;

  // test the player position if they were a stepheight higher
  LTrace := FState.Trace(LStartOrigin, FState.Pm.Mins, FState.Pm.Maxs, LUp);
  if LTrace.AllSolid then
  begin
    if FState.Debugging then
      FState.DebugPrint(Format('%d:bend can''t step'#10, [FState.Counter]));
    Exit; // can't step up
  end;

  LStepSize := LTrace.EndPos[2] - LStartOrigin[2];
  // try slidemove from this position
  TPmoveVector.Copy(LTrace.EndPos, LOrigin^);
  TPmoveVector.Copy(LStartVelocity, LVelocity^);

  SlideMove(AGravity);

  // push down the final amount
  TPmoveVector.Copy(LOrigin^, LDown);
  LDown[2] := LDown[2] - LStepSize;
  LTrace := FState.Trace(LOrigin^, FState.Pm.Mins, FState.Pm.Maxs, LDown);
  if not LTrace.AllSolid then
    TPmoveVector.Copy(LTrace.EndPos, LOrigin^);
  if LTrace.Fraction < 1.0 then
    TPmoveVector.ClipVelocity(LVelocity^, LTrace.Plane.Normal, LVelocity^, Q3_OVERCLIP);

  // use the step move
  LDelta := LOrigin^[2] - LStartOrigin[2];
  if LDelta > 2 then
  begin
    if LDelta < 7 then
      FEvents.AddEvent(Q3_EV_STEP_4)
    else if LDelta < 11 then
      FEvents.AddEvent(Q3_EV_STEP_8)
    else if LDelta < 15 then
      FEvents.AddEvent(Q3_EV_STEP_12)
    else
      FEvents.AddEvent(Q3_EV_STEP_16);
  end;
  if FState.Debugging then
    FState.DebugPrint(Format('%d:stepped'#10, [FState.Counter]));
end;

end.
