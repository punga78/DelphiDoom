{******************************************************************************}
{                                                                              }
{  DelphiDoom: pmove library - the player movement of Quake III Arena          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): Pmove,          }
{  PmoveSingle, PM_DropTimers and the snap of the velocity of bg_pmove.c.      }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Pmove.Mover;

// float arithmetic as the C code does it: one operation at a time, into a Single
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Math, DelphiDoom.Collision.Q3.Types, DelphiDoom.Net.Q3.Types, DelphiDoom.Pmove.Types,
  DelphiDoom.Pmove.Intf, DelphiDoom.Pmove.State, DelphiDoom.Pmove.Parts;

type
  /// <summary>
  ///   Pmove: takes a player state and a user command and returns the modified player state. Used by the server
  ///   for the true movement and by the client game for the local prediction: the same code, the same bits
  /// </summary>
  TPmover = class(TInterfacedObject, IPmove)
  strict private
    FState: TPmoveState;
    FParts: TPmoveParts;
    function GetCounter: Integer;
    procedure DropTimers;
    procedure SnapVelocity;
    procedure PmoveSingle;
  public
    /// <summary>The mover owns AState and AParts (the parts were built on that state)</summary>
    constructor Create(const AState: TPmoveState; const AParts: TPmoveParts);
    destructor Destroy; override;
    procedure Execute(var APmove: TPmove);
    procedure UpdateViewAngles(var APlayerState: TQ3PlayerState; const ACommand: TQ3UserCmd);
    property Counter: Integer read GetCounter;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Pmove.ViewAngles;

const
  /// <summary>The longest step of Pmove, and the span of a command that is not cut</summary>
  MAX_STEP_MSEC = 66;

constructor TPmover.Create(const AState: TPmoveState; const AParts: TPmoveParts);
begin
  inherited Create;
  Assert(Assigned(AState) and Assigned(AParts));
  FState := AState;
  FParts := AParts;
end;

destructor TPmover.Destroy;
begin
  FParts.Free;
  FState.Free;
  inherited Destroy;
end;

function TPmover.GetCounter: Integer;
begin
  Result := FState.Counter;
end;

procedure TPmover.UpdateViewAngles(var APlayerState: TQ3PlayerState; const ACommand: TQ3UserCmd);
begin
  TPmoveViewAngles.Update(APlayerState, ACommand);
end;

procedure TPmover.DropTimers;
begin
  // drop misc timing counter
  if FState.Pm.Ps.PmTime <> 0 then
  begin
    if FState.Pml.Msec >= FState.Pm.Ps.PmTime then
    begin
      FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_ALL_TIMES);
      FState.Pm.Ps.PmTime := 0;
    end
    else
      Dec(FState.Pm.Ps.PmTime, FState.Pml.Msec);
  end;

  // drop animation counter
  if FState.Pm.Ps.LegsTimer > 0 then
  begin
    Dec(FState.Pm.Ps.LegsTimer, FState.Pml.Msec);
    if FState.Pm.Ps.LegsTimer < 0 then
      FState.Pm.Ps.LegsTimer := 0;
  end;

  if FState.Pm.Ps.TorsoTimer > 0 then
  begin
    Dec(FState.Pm.Ps.TorsoTimer, FState.Pml.Msec);
    if FState.Pm.Ps.TorsoTimer < 0 then
      FState.Pm.Ps.TorsoTimer := 0;
  end;
end;

procedure TPmover.SnapVelocity;
var
  LIndex: Integer;
  LValue: Single;
begin
  // trap_SnapVector of the engine (Sys_SnapVector): round to the nearest integer, ties to even; a value that
  // does not fit in 32 bits (or is not a number) gives the "integer indefinite" of the conversion, -2^31
  for LIndex := 0 to 2 do
  begin
    LValue := FState.Velocity^[LIndex];
    if (not (LValue < 2147483648.0)) or (LValue < -2147483648.0) then
      FState.Velocity^[LIndex] := -2147483648.0
    else
      FState.Velocity^[LIndex] := Round(LValue);
  end;
end;

procedure TPmover.PmoveSingle;
var
  LTime: Double;
begin
  // this counter lets us debug movement problems with a journal
  FState.Counter := FState.Counter + 1;

  // clear results
  FState.Pm.NumTouch := 0;
  FState.Pm.WaterType := 0;
  FState.Pm.WaterLevel := 0;

  if FState.Pm.Ps.Stats[Q3_STAT_HEALTH] <= 0 then
    FState.Pm.TraceMask := FState.Pm.TraceMask and (not Q3_CONTENTS_BODY); // corpses can fly through bodies

  // make sure walking button is clear if they are running, to avoid proxy no-footsteps cheats
  if (Abs(FState.Pm.Cmd.ForwardMove) > 64) or (Abs(FState.Pm.Cmd.RightMove) > 64) then
    FState.Pm.Cmd.Buttons := FState.Pm.Cmd.Buttons and (not Q3_BUTTON_WALKING);

  // set the talk balloon flag
  if (FState.Pm.Cmd.Buttons and Q3_BUTTON_TALK) <> 0 then
    FState.Pm.Ps.EFlags := FState.Pm.Ps.EFlags or Q3_EF_TALK
  else
    FState.Pm.Ps.EFlags := FState.Pm.Ps.EFlags and (not Q3_EF_TALK);

  // set the firing flag for continuous beam weapons
  if ((FState.Pm.Ps.PmFlags and Q3_PMF_RESPAWNED) = 0) and (FState.Pm.Ps.PmType <> Q3_PM_INTERMISSION) and
    ((FState.Pm.Cmd.Buttons and Q3_BUTTON_ATTACK) <> 0) and (FState.Pm.Ps.Ammo[FState.Pm.Ps.Weapon] <> 0) then
    FState.Pm.Ps.EFlags := FState.Pm.Ps.EFlags or Q3_EF_FIRING
  else
    FState.Pm.Ps.EFlags := FState.Pm.Ps.EFlags and (not Q3_EF_FIRING);

  // clear the respawned flag if attack and use are cleared
  if (FState.Pm.Ps.Stats[Q3_STAT_HEALTH] > 0) and
    ((FState.Pm.Cmd.Buttons and (Q3_BUTTON_ATTACK or Q3_BUTTON_USE_HOLDABLE)) = 0) then
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_RESPAWNED);

  // if talk button is down, dissallow all other input; this is to prevent any possible intercept proxy from
  // adding fake talk balloons
  if (FState.Pm.Cmd.Buttons and Q3_BUTTON_TALK) <> 0 then
  begin
    // keep the talk button set tho for when the cmd.serverTime > 66 msec and the same cmd is used multiple
    // times in Pmove
    FState.Pm.Cmd.Buttons := Q3_BUTTON_TALK;
    FState.Pm.Cmd.ForwardMove := 0;
    FState.Pm.Cmd.RightMove := 0;
    FState.Pm.Cmd.UpMove := 0;
  end;

  // clear all pmove local vars
  FillChar(FState.Pml^, SizeOf(TPmoveLocals), 0);

  // determine the time
  FState.Pml.Msec := FState.Pm.Cmd.ServerTime - FState.Pm.Ps.CommandTime;
  if FState.Pml.Msec < 1 then
    FState.Pml.Msec := 1
  else if FState.Pml.Msec > 200 then
    FState.Pml.Msec := 200;
  FState.Pm.Ps.CommandTime := FState.Pm.Cmd.ServerTime;

  // save old org in case we get stuck
  FState.Pml.PreviousOrigin := FState.Origin^;

  // save old velocity for crashlanding
  FState.Pml.PreviousVelocity := FState.Velocity^;

  // pml.msec * 0.001 is an int times a double constant
  LTime := FState.Pml.Msec * Q3_MSEC_TO_SECONDS;
  FState.Pml.FrameTime := LTime;

  // update the viewangles
  UpdateViewAngles(FState.Pm.Ps, FState.Pm.Cmd);

  TQ3Math.AngleVectors(FState.ViewAngles^, FState.Pml.Forward, FState.Pml.Right, FState.Pml.Up);

  if FState.Pm.Cmd.UpMove < 10 then
    // not holding jump
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_JUMP_HELD);

  // decide if backpedaling animations should be used
  if FState.Pm.Cmd.ForwardMove < 0 then
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags or Q3_PMF_BACKWARDS_RUN
  else if (FState.Pm.Cmd.ForwardMove > 0) or ((FState.Pm.Cmd.ForwardMove = 0) and (FState.Pm.Cmd.RightMove <> 0)) then
    FState.Pm.Ps.PmFlags := FState.Pm.Ps.PmFlags and (not Q3_PMF_BACKWARDS_RUN);

  if FState.Pm.Ps.PmType >= Q3_PM_DEAD then
  begin
    FState.Pm.Cmd.ForwardMove := 0;
    FState.Pm.Cmd.RightMove := 0;
    FState.Pm.Cmd.UpMove := 0;
  end;

  if FState.Pm.Ps.PmType = Q3_PM_SPECTATOR then
  begin
    FParts.Body.CheckDuck;
    FParts.Fly.Move;
    DropTimers;
    Exit;
  end;

  if FState.Pm.Ps.PmType = Q3_PM_NOCLIP then
  begin
    FParts.Fly.NoclipMove;
    DropTimers;
    Exit;
  end;

  if FState.Pm.Ps.PmType = Q3_PM_FREEZE then
    Exit; // no movement at all

  if (FState.Pm.Ps.PmType = Q3_PM_INTERMISSION) or (FState.Pm.Ps.PmType = Q3_PM_SPINTERMISSION) then
    Exit; // no movement at all

  // set watertype, and waterlevel
  FParts.Body.SetWaterLevel;
  FState.Pml.PreviousWaterLevel := FState.Pm.WaterLevel;

  // set mins, maxs, and viewheight
  FParts.Body.CheckDuck;

  // set groundentity
  FParts.Ground.GroundTrace;

  if FState.Pm.Ps.PmType = Q3_PM_DEAD then
    FParts.Walk.DeadMove;

  DropTimers;

  if FState.Pm.Ps.Powerups[Q3_PW_FLIGHT] <> 0 then
    // flight powerup doesn't allow jump and has different friction
    FParts.Fly.Move
  else if (FState.Pm.Ps.PmFlags and Q3_PMF_GRAPPLE_PULL) <> 0 then
  begin
    FParts.Air.GrappleMove;
    // We can wiggle a bit
    FParts.Air.Move;
  end
  else if (FState.Pm.Ps.PmFlags and Q3_PMF_TIME_WATERJUMP) <> 0 then
    FParts.Water.WaterJumpMove
  else if FState.Pm.WaterLevel > 1 then
    // swimming
    FParts.Water.Move
  else if FState.Pml.Walking then
    // walking on ground
    FParts.Walk.Move
  else
    // airborne
    FParts.Air.Move;

  FParts.Weapon.Animate;

  // set groundentity, watertype, and waterlevel
  FParts.Ground.GroundTrace;
  FParts.Body.SetWaterLevel;

  // weapons
  FParts.Weapon.Weapon;

  // torso animation
  FParts.Weapon.TorsoAnimation;

  // footstep events / legs animations
  FParts.Footsteps.Footsteps;

  // entering / leaving water splashes
  FParts.Footsteps.WaterEvents;

  // snap some parts of playerstate to save network bandwidth
  SnapVelocity;
end;

procedure TPmover.Execute(var APmove: TPmove);
var
  LFinalTime, LMsec: Integer;
  LMask: TArithmeticExceptionMask;
begin
  LFinalTime := APmove.Cmd.ServerTime;

  if LFinalTime < APmove.Ps.CommandTime then
    Exit; // should not happen

  FState.Pm^ := APmove;
  // the C code runs with the floating point exceptions masked: a state with values that are not finite
  // (a corrupt demo, a cheater) must give the IEEE result, not an exception
  LMask := SetExceptionMask(exAllArithmeticExceptions);
  try
    if LFinalTime > FState.Pm.Ps.CommandTime + 1000 then
      FState.Pm.Ps.CommandTime := LFinalTime - 1000;

    FState.Pm.Ps.PmoveFramecount := (FState.Pm.Ps.PmoveFramecount + 1) and ((1 shl Q3_PS_PMOVEFRAMECOUNTBITS) - 1);

    // chop the move up if it is too long, to prevent framerate dependent behavior
    while FState.Pm.Ps.CommandTime <> LFinalTime do
    begin
      LMsec := LFinalTime - FState.Pm.Ps.CommandTime;

      if FState.Pm.PmoveFixed then
      begin
        // the original never ends here: the time does not advance (0) or goes back (negative)
        if FState.Pm.PmoveMsec < 1 then
          raise EPmoveException.CreateFmt(SPmoveInvalidFixedMsec, [FState.Pm.PmoveMsec]);
        if LMsec > FState.Pm.PmoveMsec then
          LMsec := FState.Pm.PmoveMsec;
      end
      else if LMsec > MAX_STEP_MSEC then
        LMsec := MAX_STEP_MSEC;
      FState.Pm.Cmd.ServerTime := FState.Pm.Ps.CommandTime + LMsec;
      PmoveSingle;

      if (FState.Pm.Ps.PmFlags and Q3_PMF_JUMP_HELD) <> 0 then
        FState.Pm.Cmd.UpMove := 20;
    end;
  finally
    SetExceptionMask(LMask);
    APmove := FState.Pm^;
  end;
end;

end.
