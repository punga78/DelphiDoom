{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the scrollers as the old code   }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.OldScroll;

// The statements are the ones of T_Scroll, P_AddWallScroller and of the head of the loop of
// P_SpawnScrollers (Doom and Strife p_scroll.pas, the same text) before the library, copied as
// they were. Only what they touch is replaced: sectors, sides and things are records of the test
// with the same field names, and the list of the things of a sector is a plain linked list
{$Q-}
{$R-}

interface

type
  fixed_t = Integer;

  Pmobj_t = ^mobj_t;
  mobj_t = record
    flags: Integer;
    z: fixed_t;
    momx, momy: fixed_t;
  end;

  Pmsecnode_t = ^msecnode_t;
  msecnode_t = record
    m_thing: Pmobj_t;
    m_snext: Pmsecnode_t;
  end;

  Psector_t = ^sector_t;
  sector_t = record
    floorheight, ceilingheight: fixed_t;
    floor_xoffs, floor_yoffs: fixed_t;
    ceiling_xoffs, ceiling_yoffs: fixed_t;
    heightsec: Integer;
    touching_thinglist: Pmsecnode_t;
  end;

  Pside_t = ^side_t;
  side_t = record
    textureoffset, rowoffset: fixed_t;
  end;

  scrolltype_e = (
    sc_side,
    sc_floor,
    sc_ceiling,
    sc_carry,
    sc_carry_ceiling
  );

  Pscroll_t = ^scroll_t;
  scroll_t = record
    dx, dy: fixed_t;
    affectee: Integer;
    control: Integer;
    last_height: fixed_t;
    vdx, vdy: fixed_t;
    accel: Integer;
    _type: scrolltype_e;
  end;

  /// <summary>The world of a test: the old code reads these as the globals of the engine</summary>
  TOldScrollWorld = record
    sectors: array[0..3] of sector_t;
    sides: array[0..3] of side_t;
    things: array[0..7] of mobj_t;
    nodes: array[0..7] of msecnode_t;
  end;
  POldScrollWorld = ^TOldScrollWorld;

const
  MF_NOGRAVITY = $200;
  MF_NOCLIP = $1000;

/// <summary>T_Scroll of the old code on the world of the test</summary>
procedure OldScroll(AWorld: POldScrollWorld; s: Pscroll_t);
/// <summary>The arithmetic of the old P_AddWallScroller: the speeds of the new scroller</summary>
procedure OldWallScroller(dx, dy: fixed_t; ldx, ldy: fixed_t; out x, y: fixed_t);
/// <summary>The head of the loop of the old P_SpawnScrollers: control (0 or 1) instead of the sector</summary>
procedure OldDecodeSpecial(var special: Integer; out accel, control: Integer);
/// <summary>dx of the old P_SpawnScrollers (l.dx div SCROLL_FACTOR)</summary>
function OldLineSpeed(ldx: fixed_t): fixed_t;
/// <summary>FixedMul(dx, CARRYFACTOR) of the old P_SpawnScrollers</summary>
function OldCarrySpeed(dx: fixed_t): fixed_t;

implementation

uses
  DelphiDoom.MathCore.FixedMath, DelphiDoom.MathCore.TableFineSine,
  DelphiDoom.MathCore.TableTanToAngle;

const
  MININT = Integer($80000000);
  ANG90 = $40000000;
  ANGLETOFINESHIFT = 19;
  DRANGE = 1 shl 5;
  SCROLL_SHIFT = 5;
  SCROLL_FACTOR = 1 shl SCROLL_SHIFT;
  CARRYFACTOR = 6144;

function FixedMul(const a, b: fixed_t): fixed_t;
begin
  Result := TFixedMath.Mul(a, b);
end;

function FixedDiv(const a, b: fixed_t): fixed_t;
begin
  Result := TFixedMath.Divide(a, b);
end;

procedure OldScroll(AWorld: POldScrollWorld; s: Pscroll_t);
var
  dx, dy: fixed_t;
  height: fixed_t;
  delta: fixed_t;
  side: Pside_t;
  sec: Psector_t;
  waterheight: fixed_t;
  thing: Pmobj_t;
  node: Pmsecnode_t;
begin
  dx := s.dx;
  dy := s.dy;

  if s.control <> -1 then
  begin   // compute scroll amounts based on a sector's height changes
    height := AWorld.sectors[s.control].floorheight + AWorld.sectors[s.control].ceilingheight;
    delta := height - s.last_height;
    s.last_height := height;
    dx := FixedMul(dx, delta);
    dy := FixedMul(dy, delta);
  end;

  // killough 3/14/98: Add acceleration
  if s.accel <> 0 then
  begin
    dx := dx + s.vdx;
    dy := dy + s.vdy;
    s.vdx := dx;
    s.vdy := dy;
  end;

  if dx or dy = 0 then // no-op if both (x,y) offsets
    exit;

  case s._type of
    sc_side:                   // killough 3/7/98: Scroll wall texture
      begin
        side := @AWorld.sides[s.affectee];
        side.textureoffset := side.textureoffset + dx;
        side.rowoffset := side.rowoffset + dy;
      end;

    sc_floor:                  // killough 3/7/98: Scroll floor texture
      begin
        sec := @AWorld.sectors[s.affectee];
        sec.floor_xoffs := sec.floor_xoffs + dx;
        sec.floor_yoffs := sec.floor_yoffs + dy;
      end;

    sc_ceiling:               // killough 3/7/98: Scroll ceiling texture
      begin
        sec := @AWorld.sectors[s.affectee];
        sec.ceiling_xoffs := sec.ceiling_xoffs + dx;
        sec.ceiling_yoffs := sec.ceiling_yoffs + dy;
      end;

    sc_carry:
      begin
        sec := @AWorld.sectors[s.affectee];
        height := sec.floorheight;
        if (sec.heightsec > -1) and (AWorld.sectors[sec.heightsec].floorheight > height) then
          waterheight := AWorld.sectors[sec.heightsec].floorheight
        else
          waterheight := MININT;

        node := sec.touching_thinglist;
        while node <> nil do
        begin
          thing := node.m_thing;
          if (thing.flags and MF_NOCLIP = 0) and
            (not ((thing.flags and MF_NOGRAVITY <> 0) or (thing.z > height)) or
             (thing.z < waterheight)) then
          begin
            // Move objects only if on floor or underwater,
            // non-floating, and clipped.
            thing.momx := thing.momx + dx;
            thing.momy := thing.momy + dy;
          end;
          node := node.m_snext;
        end;

      end;
  end;
end;

procedure OldWallScroller(dx, dy: fixed_t; ldx, ldy: fixed_t; out x, y: fixed_t);
var
  d: fixed_t;
begin
  // proff: Changed abs to D_abs (see m_fixed.h)
  x := abs(ldx);
  y := abs(ldy);
  if y > x then
  begin
    d := x;
    x := y;
    y := d;
  end;
  d := FixedDiv(x, FINE_SINE_TABLE[LongWord(TAN_TO_ANGLE_TABLE[FixedDiv(y,x) div DRANGE] + ANG90) shr ANGLETOFINESHIFT]);
  x := -FixedDiv(FixedMul(dy, ldy) + FixedMul(dx, ldx), d);
  y := -FixedDiv(FixedMul(dx, ldy) - FixedMul(dy, ldx), d);
end;

procedure OldDecodeSpecial(var special: Integer; out accel, control: Integer);
begin
  if (special >= 245) and (special <= 249) then // displacement scrollers
  begin
    accel := 0;
    special := special + (250 - 245);
    control := 1;
  end
  else if (special >= 214) and (special <= 218) then // accelerative scrollers
  begin
    accel := 1;
    special := special + (250 - 214);
    control := 1;
  end
  else
  begin
    accel := 0;     // no acceleration
    control := -1;  // no control sector
  end;
end;

function OldLineSpeed(ldx: fixed_t): fixed_t;
begin
  Result := ldx div SCROLL_FACTOR;
end;

function OldCarrySpeed(dx: fixed_t): fixed_t;
begin
  Result := FixedMul(dx, CARRYFACTOR);
end;

end.
