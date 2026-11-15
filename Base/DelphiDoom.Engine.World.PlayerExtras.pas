{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the player code Doom and Strife share (p_user)         }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerExtras;

interface

uses
  m_fixed,
  p_mobj_h,
  d_player;

var
  allowplayerbreath: Boolean = false;

//==============================================================================
//
// P_GetMoveFactor
//
//==============================================================================
function P_GetMoveFactor(const mo: Pmobj_t): fixed_t;

//==============================================================================
//
// A_PlayerBreath
//
//==============================================================================
procedure A_PlayerBreath(p: Pplayer_t);

//==============================================================================
//
// P_AngleTarget
//
//==============================================================================
procedure P_AngleTarget(player: Pplayer_t);

//==============================================================================
//
// P_PlayerFaceMobj
//
//==============================================================================
procedure P_PlayerFaceMobj(const player: Pplayer_t; const face: Pmobj_t; const ticks: integer);

implementation

uses
  tables,
  m_rnd,
  p_local,
  p_tick,
  p_maputl,
  p_spec,
  r_main,
  sounds,
  s_sound,
  doomdef,
  doomstat;

//==============================================================================
//
// P_GetMoveFactor
//
//==============================================================================
function P_GetMoveFactor(const mo: Pmobj_t): fixed_t;
var
  momentum, friction: integer;
begin
  result := ORIG_FRICTION_FACTOR;

  // If the floor is icy or muddy, it's harder to get moving. This is where
  // the different friction factors are applied to 'trying to move'. In
  // p_mobj.c, the friction factors are applied as you coast and slow down.

  if (mo.flags and (MF_NOGRAVITY or MF_NOCLIP) = 0) and
     (mo.flags_ex and MF_EX_LOWGRAVITY = 0) then
  begin
    friction := mo.friction;
    if friction = ORIG_FRICTION then            // normal floor

    else if friction > ORIG_FRICTION then       // ice
    begin
      result := mo.movefactor;
      mo.movefactor := ORIG_FRICTION_FACTOR;    // reset
    end
    else                                        // sludge
    begin

      // phares 3/11/98: you start off slowly, then increase as
      // you get better footing

      momentum := P_AproxDistance(mo.momx, mo.momy);
      result := mo.movefactor;
      if momentum > MORE_FRICTION_MOMENTUM shl 2 then
        result := result shl 3
      else if momentum > MORE_FRICTION_MOMENTUM shl 1 then
        result := result shl 2
      else if momentum > MORE_FRICTION_MOMENTUM then
        result := result shl 1;

      mo.movefactor := ORIG_FRICTION_FACTOR;  // reset
    end;
  end;
end;

var
  brsnd: integer = -1;
  brsnd2: integer = -1;
  rnd_breath: Integer = 0;

//==============================================================================
//
// A_PlayerBreath
//
//==============================================================================
procedure A_PlayerBreath(p: Pplayer_t);
var
  sndidx: integer;
begin
  if p.health <= 0 then
    exit;

  if p.playerstate = PST_DEAD then
    exit;

  if leveltime - p.lastbreath < 3 * TICRATE + (C_Random(rnd_breath) mod TICRATE) then
    exit;

  p.lastbreath := leveltime;

  if allowplayerbreath then
  begin
    if p.hardbreathtics > 0 then
    begin
      if brsnd2 < 0 then
        brsnd2 := S_GetSoundNumForName('player/breath2');
      sndidx := brsnd2;
    end
    else
    begin
      if brsnd < 0 then
        brsnd := S_GetSoundNumForName('player/breath');
      sndidx := brsnd;
    end;
    if sndidx > 0 then
      S_StartSound(p.mo, sndidx);
  end;
end;

//==============================================================================
//
// P_AngleTarget
//
//==============================================================================
procedure P_AngleTarget(player: Pplayer_t);
var
  ticks: LongWord;
  angle: angle_t;
  diff: angle_t;
begin
  if player.angletargetticks <= 0 then
    exit;

  player.cmd.angleturn := 0;
  angle := R_PointToAngle2(player.mo.x, player.mo.y, player.angletargetx, player.angletargety);
  diff := player.mo.angle - angle;

  ticks := player.angletargetticks;
  if diff > ANG180 then
  begin
    diff := ANGLE_MAX - diff;
    player.mo.angle := player.mo.angle + (diff div ticks);
  end
  else
    player.mo.angle := player.mo.angle - (diff div ticks);

  dec(player.angletargetticks);
end;

//==============================================================================
//
// P_PlayerFaceMobj
//
//==============================================================================
procedure P_PlayerFaceMobj(const player: Pplayer_t; const face: Pmobj_t; const ticks: integer);
begin
  player.angletargetx := face.x;
  player.angletargety := face.y;
  player.angletargetticks := ticks;
end;

end.
