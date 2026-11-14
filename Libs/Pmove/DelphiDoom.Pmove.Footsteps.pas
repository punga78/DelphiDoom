{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - footsteps, legs animations and water events     }
{                                                                              }
{  Port of PM_Footsteps and PM_WaterEvents of bg_pmove.c, from the Quake III   }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Footsteps;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Pmove.Types, DelphiDoom.Pmove.State, DelphiDoom.Pmove.Events,
  DelphiDoom.Pmove.Ground;

type
  /// <summary>The cycle of the steps (bobCycle) and what the player hears and shows while it moves or enters the water</summary>
  TPmoveFootsteps = class
  strict private
    FState: TPmoveState;
    FEvents: TPmoveEvents;
    FGround: TPmoveGround;
  public
    constructor Create(const AState: TPmoveState; const AEvents: TPmoveEvents; const AGround: TPmoveGround);
    /// <summary>PM_Footsteps: the speed on the ground, the cycle of the steps, the legs animations and the sounds</summary>
    procedure Footsteps;
    /// <summary>PM_WaterEvents: the events for entering and leaving water</summary>
    procedure WaterEvents;
  end;

implementation

uses
  DelphiDoom.Pmove.Vector;

constructor TPmoveFootsteps.Create(const AState: TPmoveState; const AEvents: TPmoveEvents;
  const AGround: TPmoveGround);
begin
  inherited Create;
  FState := AState;
  FEvents := AEvents;
  FGround := AGround;
end;

procedure TPmoveFootsteps.Footsteps;
var
  LBobMove, LSquareX, LSquareY, LSum, LProduct, LSteps: Single;
  LOld: Integer;
  LFootstep: Boolean;
begin
  // calculate speed and cycle to be used for all cyclic walking effects
  LSquareX := FState.Velocity^[0] * FState.Velocity^[0];
  LSquareY := FState.Velocity^[1] * FState.Velocity^[1];
  LSum := LSquareX + LSquareY;
  FState.Pm.XySpeed := TPmoveVector.SquareRoot(LSum);

  if FState.Pm.Ps.GroundEntityNum = Q3_ENTITYNUM_NONE then
  begin
    if FState.Pm.Ps.Powerups[Q3_PW_INVULNERABILITY] <> 0 then
      FEvents.ContinueLegsAnim(Q3_LEGS_IDLECR);
    // airborne leaves position in cycle intact, but doesn't advance
    if FState.Pm.WaterLevel > 1 then
      FEvents.ContinueLegsAnim(Q3_LEGS_SWIM);
    Exit;
  end;

  // if not trying to move
  if (FState.Pm.Cmd.ForwardMove = 0) and (FState.Pm.Cmd.RightMove = 0) then
  begin
    if FState.Pm.XySpeed < 5 then
    begin
      FState.Pm.Ps.BobCycle := 0; // start at beginning of cycle again
      if (FState.Pm.Ps.PmFlags and Q3_PMF_DUCKED) <> 0 then
        FEvents.ContinueLegsAnim(Q3_LEGS_IDLECR)
      else
        FEvents.ContinueLegsAnim(Q3_LEGS_IDLE);
    end;
    Exit;
  end;

  LFootstep := False;

  if (FState.Pm.Ps.PmFlags and Q3_PMF_DUCKED) <> 0 then
  begin
    LBobMove := 0.5; // ducked characters bob much faster
    if (FState.Pm.Ps.PmFlags and Q3_PMF_BACKWARDS_RUN) <> 0 then
      FEvents.ContinueLegsAnim(Q3_LEGS_BACKCR)
    else
      FEvents.ContinueLegsAnim(Q3_LEGS_WALKCR);
    // ducked characters never play footsteps
  end
  else if (FState.Pm.Cmd.Buttons and Q3_BUTTON_WALKING) = 0 then
  begin
    LBobMove := 0.4; // faster speeds bob faster
    if (FState.Pm.Ps.PmFlags and Q3_PMF_BACKWARDS_RUN) <> 0 then
      FEvents.ContinueLegsAnim(Q3_LEGS_BACK)
    else
      FEvents.ContinueLegsAnim(Q3_LEGS_RUN);
    LFootstep := True;
  end
  else
  begin
    LBobMove := 0.3; // walking bobs slow
    if (FState.Pm.Ps.PmFlags and Q3_PMF_BACKWARDS_RUN) <> 0 then
      FEvents.ContinueLegsAnim(Q3_LEGS_BACKWALK)
    else
      FEvents.ContinueLegsAnim(Q3_LEGS_WALK);
  end;

  // check for footstep / splash sounds
  LOld := FState.Pm.Ps.BobCycle;
  LProduct := FState.Pml.Msec;
  LProduct := LBobMove * LProduct;
  LSteps := LOld;
  LSteps := LSteps + LProduct;
  FState.Pm.Ps.BobCycle := Trunc(LSteps) and 255;

  // if we just crossed a cycle boundary, play an apropriate footstep event
  if (((LOld + 64) xor (FState.Pm.Ps.BobCycle + 64)) and 128) <> 0 then
  begin
    if FState.Pm.WaterLevel = 0 then
    begin
      // on ground will only play sounds if running
      if LFootstep and (not FState.Pm.NoFootsteps) then
        FEvents.AddEvent(FGround.FootstepForSurface);
    end
    else if FState.Pm.WaterLevel = 1 then
      // splashing
      FEvents.AddEvent(Q3_EV_FOOTSPLASH)
    else if FState.Pm.WaterLevel = 2 then
      // wading / swimming at surface
      FEvents.AddEvent(Q3_EV_SWIM);
    // no sound when completely underwater
  end;
end;

procedure TPmoveFootsteps.WaterEvents;
begin
  // if just entered a water volume, play a sound
  if (FState.Pml.PreviousWaterLevel = 0) and (FState.Pm.WaterLevel <> 0) then
    FEvents.AddEvent(Q3_EV_WATER_TOUCH);

  // if just completely exited a water volume, play a sound
  if (FState.Pml.PreviousWaterLevel <> 0) and (FState.Pm.WaterLevel = 0) then
    FEvents.AddEvent(Q3_EV_WATER_LEAVE);

  // check for head just going under water
  if (FState.Pml.PreviousWaterLevel <> 3) and (FState.Pm.WaterLevel = 3) then
    FEvents.AddEvent(Q3_EV_WATER_UNDER);

  // check for head just coming out of water
  if (FState.Pml.PreviousWaterLevel = 3) and (FState.Pm.WaterLevel <> 3) then
    FEvents.AddEvent(Q3_EV_WATER_CLEAR);
end;

end.
