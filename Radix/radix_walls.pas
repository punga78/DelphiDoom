{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - the walls that can be shot                         }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of RX_DamageLine, RX_ShootableLine, RX_LineExplosion and               }
{  RX_ExplosionParade of radix_map_extra.pas of Rad-X. The hit points, the     }
{  flags and the trigger of a wall (fields of the line_t of Rad-X) are the     }
{  ones of RMAP in radixwallinfo.                                              }
{                                                                              }
{  Rad-X damaged a wall from P_XYMovement, when a missile was stopped by a     }
{  line, and from the hitscan trace. The movement code of the engine is not    }
{  touched here: RX_TrackShots, run every tic by the thinker of the level,     }
{  remembers the missiles of the players that fly and, when one of them has    }
{  exploded, looks for the wall that can be shot in front of it. Not ported:   }
{  the damage of a hitscan shot, the lines with the specials 286..290 of       }
{  Rad-X (RWF_SHOOTABLE), the flag MF3_EX_CANDAMAGEWALLS (every missile of a   }
{  player damages the walls)                                                   }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_walls;

interface

//==============================================================================
//
// RX_InitWalls
// To call when the level is loaded, after the walls that fire missiles are
// marked: finds the walls that can be shot and forgets the shots
//
//==============================================================================
procedure RX_InitWalls;

//==============================================================================
//
// RX_ValidLine
//
//==============================================================================
function RX_ValidLine(const lineid: integer): boolean;

//==============================================================================
//
// RX_LineHitPoints
// What is left of a wall; 0 for a line that the level does not have
//
//==============================================================================
function RX_LineHitPoints(const lineid: integer): integer;

//==============================================================================
//
// RX_ShootableLine
//
//==============================================================================
function RX_ShootableLine(const lineid: integer): boolean;

//==============================================================================
//
// RX_DamageLine
// A wall that can be shot loses hit points; when none is left it runs its
// trigger and explodes
//
//==============================================================================
procedure RX_DamageLine(const lineid: integer; const damage: integer);

//==============================================================================
//
// RX_TrackShots
// Every tic: the missiles of the players that have exploded damage the wall in
// front of them
//
//==============================================================================
procedure RX_TrackShots;

implementation

uses
  d_delphi,
  d_think,
  m_fixed,
  m_rnd,
  tables,
  p_mobj_h,
  p_mobj,
  p_maputl,
  p_setup,
  p_tick,
  r_defs,
  r_main,
  radix_codepointers,
  radix_logic,
  radix_map_extra,
  DelphiDoom.Radix.LevelLogic.Types,
  DelphiDoom.Radix.Action.Rules;

const
  WALLEXPLOSIONOFFSET = 24;

const
  LEF_DELAY = 0;
  LEF_NODELAY = 1;

const
  // how far past its own step and radius an exploded shot reaches a wall (map units)
  SHOTREACHMARGIN = 16;

type
  trackedshot_t = record
    key: LongWord;
    x, y: fixed_t;        // where it is now
    oldx, oldy: fixed_t;  // where it was a tic ago (where it is now, for a new shot)
    momx, momy: fixed_t;
  end;
  trackedshot_tArray = array of trackedshot_t;

var
  shootablelines: array of integer;
  shots: trackedshot_tArray;
  numshots: integer = 0;
  prevshots: trackedshot_tArray;
  numprevshots: integer = 0;

//==============================================================================
//
// RX_ValidLine
//
//==============================================================================
function RX_ValidLine(const lineid: integer): boolean;
begin
  result := (lineid >= 0) and (lineid < numlines) and (lineid < Length(radixwallinfo));
end;

//==============================================================================
//
// RX_LineHitPoints
//
//==============================================================================
function RX_LineHitPoints(const lineid: integer): integer;
begin
  if RX_ValidLine(lineid) then
    result := radixwallinfo[lineid].HitPoints
  else
    result := 0;
end;

//==============================================================================
//
// RX_ShootableLine
//
//==============================================================================
function RX_ShootableLine(const lineid: integer): boolean;
begin
  result := false;
  if not RX_ValidLine(lineid) then
    exit;
  if radixwallinfo[lineid].Flags and (RWF_ACTIVATETRIGGER or RWF_MISSILEWALL) = 0 then
    exit;
  result := radixwallinfo[lineid].HitPoints > 0;
end;

//==============================================================================
//
// RX_InitWalls
//
//==============================================================================
procedure RX_InitWalls;
var
  i: integer;
  cnt: integer;
begin
  numshots := 0;
  numprevshots := 0;
  SetLength(shootablelines, numlines);
  cnt := 0;
  for i := 0 to numlines - 1 do
    if RX_ShootableLine(i) then
    begin
      shootablelines[cnt] := i;
      inc(cnt);
    end;
  SetLength(shootablelines, cnt);
end;

//==============================================================================
//
// RX_ExplosionParade
//
//==============================================================================
procedure RX_ExplosionParade(const x1, x2, y1, y2, z1, z2: integer; const side: integer;
  const fracdensity: integer; const flags: LongWord);
var
  i: integer;
  area, cnt: integer;
  mo: Pmobj_t;
  x, y, z: integer;
  dx, dy, dz: integer;
  angle: angle_t;
  c, s: fixed_t;
begin
  dx := x2 div FRACUNIT - x1 div FRACUNIT;
  dy := y2 div FRACUNIT - y1 div FRACUNIT;
  dz := z2 div FRACUNIT - z1 div FRACUNIT;

  // Every 64x64 px area 1 explosion when fracdensity = FRACUNIT
  area := (P_AproxDistance(x2 - x1, y2 - y1) div FRACUNIT * dz) div (64 * 64);
  cnt := (area * fracdensity) div FRACUNIT;
  if cnt <= 0 then
    cnt := 1;  // At least one explosion

  for i := 0 to cnt - 1 do
  begin
    x := x1 + dx * Sys_Random * 256;
    y := y1 + dy * Sys_Random * 256;
    z := z1 + dz * Sys_Random * 256;
    if side = 0 then
      angle := R_PointToAngle2(x1, y1, x2, y2) - ANG90
    else
      angle := R_PointToAngle2(x1, y1, x2, y2) + ANG90;
    angle := angle shr ANGLETOFINESHIFT;
    c := finecosine[angle];
    s := finesine[angle];
    x := x + WALLEXPLOSIONOFFSET * c;
    y := y + WALLEXPLOSIONOFFSET * s;
    mo := RX_SpawnRadixBigExplosion(x, y, z);
    if mo = nil then
      break;  // the actors of Radix are not loaded
    if flags and LEF_NODELAY <> 0 then
    begin
      if mo.tics > 0 then
        mo.tics := P_Random mod mo.tics;
      if mo.tics <= 0 then
        mo.tics := 1;
    end
    else
      mo.tics := mo.tics + (P_Random and 63); // Some delay
  end;

  RX_AmbientSound(x1 div 2 + x2 div 2, y1 div 2 + y2 div 2, 'radix/SndExplode');
end;

//==============================================================================
//
// RX_LineExplosion
//
//==============================================================================
procedure RX_LineExplosion(const l: Pline_t; const flags: LongWord);
var
  x1, x2, y1, y2: integer;
  front, back: Psector_t;
begin
  x1 := l.v1.x;
  y1 := l.v1.y;
  x2 := l.v2.x;
  y2 := l.v2.y;

  front := l.frontsector;
  back := l.backsector;
  if front = nil then
    exit;

  if back = nil then
  begin
    RX_ExplosionParade(x1, x2, y1, y2, front.floorheight, front.ceilingheight, 0, 2 * FRACUNIT, flags);
    exit;
  end;

  if front.ceilingheight < back.ceilingheight then
    RX_ExplosionParade(x1, x2, y1, y2, front.ceilingheight, back.ceilingheight, 1, 2 * FRACUNIT, flags);
  if front.ceilingheight > back.ceilingheight then
    RX_ExplosionParade(x1, x2, y1, y2, back.ceilingheight, front.ceilingheight, 0, 2 * FRACUNIT, flags);
  if front.floorheight < back.floorheight then
    RX_ExplosionParade(x1, x2, y1, y2, front.floorheight, back.floorheight, 0, 2 * FRACUNIT, flags);
  if front.floorheight > back.floorheight then
    RX_ExplosionParade(x1, x2, y1, y2, back.floorheight, front.floorheight, 1, 2 * FRACUNIT, flags);
end;

//==============================================================================
//
// RX_DamageLine
//
//==============================================================================
procedure RX_DamageLine(const lineid: integer; const damage: integer);
var
  flags: integer;
begin
  if not RX_ValidLine(lineid) then
    exit;

  flags := radixwallinfo[lineid].Flags;
  if flags and (RWF_ACTIVATETRIGGER or RWF_MISSILEWALL) = 0 then
    exit;

  radixwallinfo[lineid].HitPoints := radixwallinfo[lineid].HitPoints -
    TRadixActionRules.WallDamage(damage, P_Random);

  if radixwallinfo[lineid].HitPoints <= 0 then
  begin
    if flags and RWF_ACTIVATETRIGGER <> 0 then
    begin
      flags := flags and not RWF_ACTIVATETRIGGER;
      RX_ActivateAndRunTrigger(radixwallinfo[lineid].Trigger);
    end;

    RX_LineExplosion(@lines[lineid], LEF_DELAY);

    radixwallinfo[lineid].Flags := flags and not (RWF_MISSILEWALL or RWF_SHOOTABLE);
  end;
end;

//==============================================================================
//
// RX_ShotPassesLine
// True when the shot is in the opening of a two sided line
//
//==============================================================================
function RX_ShotPassesLine(const mo: Pmobj_t; const l: Pline_t): boolean;
var
  top, bottom: fixed_t;
begin
  result := false;
  if (l.backsector = nil) or (l.frontsector = nil) then
    exit;
  top := l.frontsector.ceilingheight;
  if l.backsector.ceilingheight < top then
    top := l.backsector.ceilingheight;
  bottom := l.frontsector.floorheight;
  if l.backsector.floorheight > bottom then
    bottom := l.backsector.floorheight;
  result := (mo.z >= bottom) and (mo.z + mo.height <= top);
end;

//==============================================================================
//
// RX_ShotHitsWall
// A missile of a player has exploded: the first wall that can be shot on its
// way, within its last step from where it was seen flying, is damaged
//
//==============================================================================
procedure RX_ShotHitsWall(const mo: Pmobj_t; const shot: trackedshot_t);
var
  i: integer;
  lineid: integer;
  l: Pline_t;
  best: integer;
  bestdist: double;
  dist: double;
  reach: double;
  speed: double;
  flown: double;
  px, py, dx, dy: double;
  rnd: integer;
begin
  // The way of the shot starts where it was two tics before it exploded: a fast and small
  // shot (56 units a tic, radius 13: the engine moves it 28 units at a time) goes through a
  // one sided wall and explodes against the next one, inside the solid part of the map
  px := shot.oldx / FRACUNIT;
  py := shot.oldy / FRACUNIT;
  dx := shot.momx / FRACUNIT;
  dy := shot.momy / FRACUNIT;
  speed := sqrt(dx * dx + dy * dy);
  if speed <= 0.0 then
    exit;
  flown := sqrt(sqr(shot.x / FRACUNIT - px) + sqr(shot.y / FRACUNIT - py));
  reach := flown + speed + mo.radius / FRACUNIT + SHOTREACHMARGIN;

  best := -1;
  bestdist := reach;
  for i := 0 to Length(shootablelines) - 1 do
  begin
    lineid := shootablelines[i];
    if not RX_ShootableLine(lineid) then
      continue;
    l := @lines[lineid];
    if not TRadixActionRules.WallOnPath(px, py, px + dx / speed * reach, py + dy / speed * reach,
         l.v1.x / FRACUNIT, l.v1.y / FRACUNIT, l.v2.x / FRACUNIT, l.v2.y / FRACUNIT,
         mo.radius / FRACUNIT, dist) then
      continue;
    if dist > bestdist then
      continue;
    if RX_ShotPassesLine(mo, l) then
      continue;
    best := lineid;
    bestdist := dist;
  end;

  if best < 0 then
    exit;

  rnd := (P_Random mod 3) + 1;
  RX_DamageLine(best, mo.info.damage * rnd);
end;

//==============================================================================
//
// RX_RememberShot
//
//==============================================================================
procedure RX_RememberShot(const mo: Pmobj_t);
var
  i: integer;
begin
  if numshots >= Length(shots) then
    SetLength(shots, numshots + 64);
  shots[numshots].key := mo.key;
  shots[numshots].x := mo.x;
  shots[numshots].y := mo.y;
  shots[numshots].oldx := mo.x;
  shots[numshots].oldy := mo.y;
  for i := 0 to numprevshots - 1 do
    if prevshots[i].key = mo.key then
    begin
      shots[numshots].oldx := prevshots[i].x;
      shots[numshots].oldy := prevshots[i].y;
      break;
    end;
  shots[numshots].momx := mo.momx;
  shots[numshots].momy := mo.momy;
  inc(numshots);
end;

//==============================================================================
//
// RX_TrackShots
//
//==============================================================================
procedure RX_TrackShots;
var
  think: Pthinker_t;
  mo: Pmobj_t;
  i: integer;
  tmp: trackedshot_tArray;
begin
  // a level without walls to shoot has nothing to track
  if Length(shootablelines) = 0 then
    exit;

  numshots := 0;
  think := thinkercap.next;
  while think <> @thinkercap do
  begin
    if @think._function.acp1 = @P_MobjThinker then
    begin
      mo := Pmobj_t(think);
      if mo.flags and MF_MISSILE <> 0 then
      begin
        if (mo.target <> nil) and (mo.target.player <> nil) then
          if (mo.momx <> 0) or (mo.momy <> 0) then
            RX_RememberShot(mo);
      end
      else if numprevshots > 0 then
      begin
        for i := 0 to numprevshots - 1 do
          if prevshots[i].key = mo.key then
          begin
            RX_ShotHitsWall(mo, prevshots[i]);
            break;
          end;
      end;
    end;
    think := think.next;
  end;

  tmp := prevshots;
  prevshots := shots;
  shots := tmp;
  numprevshots := numshots;
  numshots := 0;
end;

end.
