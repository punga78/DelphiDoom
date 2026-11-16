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
{  Rad-X damaged a wall from P_ExplodeMissile, when a missile was stopped by   }
{  a line: the rule is TPhysicsExtension.MissileHitLine of                     }
{  TMobjGameRules.BlockedMove (issue #169; the guess that stood here, a        }
{  tracker of the shots of the players run by the level thinker, is gone).     }
{  Not ported: the damage of a hitscan shot, the lines with the specials       }
{  286..290 of Rad-X (RWF_SHOOTABLE)                                           }
{                                                                              }
{******************************************************************************}

{$I Doom32.inc}

unit radix_walls;

interface

uses
  p_mobj_h,
  r_defs;

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
// RX_MissileTargetLine
// The line that has stopped a missile, when it is a wall that can be shot: a
// one sided line (TMapCheck.BounceLine) or a two sided one that closes the opening
// (TMapCheck.CeilingLine: the walls of Radix are closed sectors); nil for any other
//
//==============================================================================
function RX_MissileTargetLine(const mo: Pmobj_t): Pline_t;

//==============================================================================
//
// RX_MissileHitsLine
// A missile has exploded against a line (TMapCheck.BounceLine of P_XYMovement): when the
// kind of the missile can damage walls the line takes the damage of the missile
// times 1..3 (P_ExplodeMissile of Rad-X)
//
//==============================================================================
procedure RX_MissileHitsLine(const mo: Pmobj_t; const line: Pline_t);

implementation

uses
  d_delphi,
  d_think,
  m_fixed,
  m_rnd,
  tables,
  p_mobj,
  p_map,
  p_maputl,
  p_setup,
  p_tick,
  r_main,
  radix_codepointers,
  radix_logic,
  radix_map_extra,
  radix_pickups,
  p_local,
  DelphiDoom.MathCore.Types,
  DelphiDoom.Radix.LevelLogic.Types,
  DelphiDoom.Radix.Action.Rules,
  DelphiDoom.Radix.Physics.Contact;

const
  WALLEXPLOSIONOFFSET = 24;

const
  LEF_DELAY = 0;
  LEF_NODELAY = 1;

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

var
  targetmissile: Pmobj_t;
  targetline: Pline_t;

//==============================================================================
//
// PIT_RadixTargetLine
// A line of the tried place of a missile that can be shot and that stops it: a
// one sided line, or a two sided one whose opening does not hold the missile
// (the panel under the opening of a two sided line is how Radix makes a target)
//
//==============================================================================
function PIT_RadixTargetLine(ld: Pline_t): boolean;
begin
  result := true;
  if (TMapCheck.BBox[BOX_RIGHT] <= ld.bbox[BOX_LEFT]) or
     (TMapCheck.BBox[BOX_LEFT] >= ld.bbox[BOX_RIGHT]) or
     (TMapCheck.BBox[BOX_TOP] <= ld.bbox[BOX_BOTTOM]) or
     (TMapCheck.BBox[BOX_BOTTOM] >= ld.bbox[BOX_TOP]) then
    exit;

  if P_BoxOnLineSide(@TMapCheck.BBox, ld) <> -1 then
    exit;

  if not RX_ShootableLine(pDiff(ld, @lines[0], SizeOf(line_t))) then
    exit;

  if (ld.backsector <> nil) and (ld.frontsector <> nil) then
  begin
    if not TRadixContactRules.LineStopsMissile(true, targetmissile.z, targetmissile.height,
      ld.frontsector.floorheight, ld.backsector.floorheight,
      ld.frontsector.ceilingheight, ld.backsector.ceilingheight) then
      exit; // the missile is in the opening
  end;

  targetline := ld;
  result := false;
end;

//==============================================================================
//
// RX_MissileTargetLine
// PIT_CheckLine of Rad-X remembered the line that stopped a move (tmline,
// TMapCheck.BounceLine) for any kind of line; the engine knows only the one sided ones,
// so the lines of the place that was tried are looked at again, once, for the
// missile that was stopped
//
//==============================================================================
function RX_MissileTargetLine(const mo: Pmobj_t): Pline_t;
var
  xl, xh, yl, yh: integer;
  bx, by: integer;
begin
  targetmissile := mo;
  targetline := nil;
  if internalblockmapformat then
  begin
    xl := MapBlockIntX(int64(TMapCheck.BBox[BOX_LEFT]) - int64(bmaporgx));
    xh := MapBlockIntX(int64(TMapCheck.BBox[BOX_RIGHT]) - int64(bmaporgx));
    yl := MapBlockIntY(int64(TMapCheck.BBox[BOX_BOTTOM]) - int64(bmaporgy));
    yh := MapBlockIntY(int64(TMapCheck.BBox[BOX_TOP]) - int64(bmaporgy));
  end
  else
  begin
    xl := MapBlockInt(TMapCheck.BBox[BOX_LEFT] - bmaporgx);
    xh := MapBlockInt(TMapCheck.BBox[BOX_RIGHT] - bmaporgx);
    yl := MapBlockInt(TMapCheck.BBox[BOX_BOTTOM] - bmaporgy);
    yh := MapBlockInt(TMapCheck.BBox[BOX_TOP] - bmaporgy);
  end;

  inc(validcount);
  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockLinesIterator(bx, by, PIT_RadixTargetLine) then
      begin
        result := targetline;
        exit;
      end;
  result := nil;
end;

//==============================================================================
//
// RX_MissileHitsLine
//
//==============================================================================
procedure RX_MissileHitsLine(const mo: Pmobj_t; const line: Pline_t);
var
  rnd: integer;
begin
  if not RX_ActorCanDamageWalls(mo._type) then
    exit;

  rnd := (P_Random mod 3) + 1;
  RX_DamageLine(pDiff(line, @lines[0], SizeOf(line_t)), mo.info.damage * rnd);
end;

end.
