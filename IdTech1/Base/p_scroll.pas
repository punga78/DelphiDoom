//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_scroll;

interface

uses
  d_think,
  m_fixed;

type
// killough 3/7/98: Add generalized scroll effects

  scrolltype_e = (
    sc_side,
    sc_floor,
    sc_ceiling,
    sc_carry,
    sc_carry_ceiling  // killough 4/11/98: carry objects hanging on ceilings
  );

  scroll_t = record
    thinker: thinker_t;   // Thinker structure for scrolling
    dx, dy: fixed_t;      // (dx,dy) scroll speeds
    affectee: integer;    // Number of affected sidedef, sector, tag, or whatever
    control: integer;     // Control sector (-1 if none) used to control scrolling
    last_height: fixed_t; // Last known height of control sector
    vdx, vdy: fixed_t;    // Accumulated velocity if accelerative
    accel: integer;       // Whether it's accelerative
    _type: scrolltype_e;  // Type of scroll effect
  end;
  Pscroll_t = ^scroll_t;

//==============================================================================
//
// P_SpawnScrollers
//
//==============================================================================
procedure P_SpawnScrollers;

//==============================================================================
//
// T_Scroll
//
//==============================================================================
procedure T_Scroll(s: Pscroll_t);

implementation

uses
  d_delphi,
  i_system,
  p_mobj_h,
  p_setup,
  DelphiDoom.Engine.World.SectorSearch,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  p_tick,
  r_defs,
  z_zone,
  DelphiDoom.Thinkers.Scroll.Step,
  DelphiDoom.Thinkers.Scroll.Spawner;

//==============================================================================
// T_Scroll
//
// killough 2/28/98:
//
// This function, with the help of r_plane.c and r_bsp.c, supports generalized
// scrolling floors and walls, with optional mobj-carrying properties, e.g.
// conveyor belts, rivers, etc. A linedef with a special type affects all
// tagged sectors the same way, by creating scrolling and/or object-carrying
// properties. Multiple linedefs may be used on the same sector and are
// cumulative, although the special of scrolling a floor and carrying
// things on it, requires only one linedef. The linedef's direction determines
// the scrolling direction, and the linedef's length determines the scrolling
// speed. This was designed so that an edge around the sector could be used to
// control the direction of the sector's scrolling, which is usually what is
// desired.
//
// Process the active scrollers.
//
// This is the main scrolling code
// killough 3/7/98
//
//==============================================================================
procedure T_Scroll(s: Pscroll_t);
var
  dx, dy: fixed_t;
  height: fixed_t;
  side: Pside_t;
  sec: Psector_t;
  waterheight: fixed_t;
  thing: Pmobj_t;
  node: Pmsecnode_t;
begin
  dx := s.dx;
  dy := s.dy;

  // compute scroll amounts based on a sector's height changes
  if s.control <> -1 then
    height := sectors[s.control].floorheight + sectors[s.control].ceilingheight
  else
    height := 0;

  // the amounts of this tic (control sector, killough 3/14/98: acceleration)
  // are TScrollStep (IdTech1\Thinkers); no-op if both (x,y) offsets
  if not TScrollStep.Advance(dx, dy, s.control <> -1, height, s.last_height,
    s.accel <> 0, s.vdx, s.vdy) then
    exit;

  case s._type of
    sc_side:                   // killough 3/7/98: Scroll wall texture
      begin
        side := @sides[s.affectee];
        side.textureoffset := side.textureoffset + dx;
        side.rowoffset := side.rowoffset + dy;
      end;

    sc_floor:                  // killough 3/7/98: Scroll floor texture
      begin
        sec := @sectors[s.affectee];
        sec.floor_xoffs := sec.floor_xoffs + dx;
        sec.floor_yoffs := sec.floor_yoffs + dy;
      end;

    sc_ceiling:               // killough 3/7/98: Scroll ceiling texture
      begin
        sec := @sectors[s.affectee];
        sec.ceiling_xoffs := sec.ceiling_xoffs + dx;
        sec.ceiling_yoffs := sec.ceiling_yoffs + dy;
      end;

    sc_carry:
      begin
        // killough 3/7/98: Carry things on floor
        // killough 3/20/98: use new sector list which reflects true members
        // killough 3/27/98: fix carrier bug
        // killough 4/4/98: Underwater, carry things even w/o gravity

        sec := @sectors[s.affectee];
        height := sec.floorheight;
        if sec.heightsec > -1 then
          waterheight := TScrollStep.WaterHeight(true, sectors[sec.heightsec].floorheight, height)
        else
          waterheight := TScrollStep.WaterHeight(false, 0, height);

        node := sec.touching_thinglist;
        while node <> nil do
        begin
          thing := node.m_thing;
          if TScrollStep.Carries(thing.flags and MF_NOCLIP <> 0,
            thing.flags and MF_NOGRAVITY <> 0, thing.z, height, waterheight) then
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

//==============================================================================
//
// P_AddScroller
//
// Add a generalized scroller to the thinker list.
//
// type: the enumerated type of scrolling: floor, ceiling, floor carrier,
//   wall, floor carrier & scroller
//
// (dx,dy): the direction and speed of the scrolling or its acceleration
//
// control: the sector whose heights control this scroller's effect
//   remotely, or -1 if no control sector
//
// affectee: the index of the affected object (sector or sidedef)
//
// accel: non-zero if this is an accelerative effect
//
//==============================================================================
procedure P_AddScroller(_type: scrolltype_e; dx, dy: fixed_t; control: integer;
  affectee: integer; accel: integer);
var
  s: Pscroll_t;
begin
  s := Z_Malloc(SizeOf(scroll_t), PU_LEVSPEC, nil);
  s.thinker._function.acp1 := @T_Scroll;
  s._type := _type;
  s.dx := dx;
  s.dy := dy;
  s.accel := accel;
  s.vdx := 0;
  s.vdy := 0;
  s.control := control;
  if control <> -1 then
    s.last_height := sectors[control].floorheight + sectors[control].ceilingheight;
  s.affectee := affectee;
  P_AddThinker(@s.thinker);
end;

//==============================================================================
// P_AddWallScroller
//
// Adds wall scroller. Scroll amount is rotated with respect to wall's
// linedef first, so that scrolling towards the wall in a perpendicular
// direction is translated into vertical motion, while scrolling along
// the wall in a parallel direction is translated into horizontal motion.
//
// killough 5/25/98: cleaned up arithmetic to avoid drift due to roundoff
//
//==============================================================================
procedure P_AddWallScroller(dx, dy: fixed_t; l: Pline_t;
  control: integer; accel: integer);
var
  x, y: fixed_t;
begin
  TScrollSpawner.WallVector(dx, dy, l.dx, l.dy, x, y);
  P_AddScroller(sc_side, x, y, control, l.sidenum[0], accel);
end;

//==============================================================================
// P_SpawnScrollers
//
// Initialize the scrollers
//
//==============================================================================
procedure P_SpawnScrollers;
var
  i: integer;
  l: Pline_t;
  dx, dy: fixed_t;
  control: integer;
  accel: integer;
  special: integer;
  s: integer;
  kind: TScrollControl;
begin
  for i := 0 to numlines - 1 do
  begin
    l := @lines[i];
    dx := TScrollSpawner.LineSpeed(l.dx);  // direction and speed of scrolling
    dy := TScrollSpawner.LineSpeed(l.dy);
    special := l.special;

    // killough 3/7/98: Types 245-249 are same as 250-254 except that the
    // first side's sector's heights cause scrolling when they change, and
    // this linedef controls the direction and speed of the scrolling. The
    // most complicated linedef since donuts, but powerful :)
    //
    // killough 3/15/98: Add acceleration. Types 214-218 are the same but
    // are accelerative.

    special := TScrollSpawner.Decode(special, kind);
    if kind = TScrollControl.Accelerative then // accelerative scrollers
      accel := 1
    else
      accel := 0;     // no acceleration
    if kind <> TScrollControl.None then // displacement scrollers
      control := pDiff(sides[l.sidenum[0]].sector, sectors, SizeOf(sector_t))
    else
      control := -1;  // no control sector

    case special of

      250:   // scroll effect ceiling
        begin
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            P_AddScroller(sc_ceiling, -dx, dy, control, s, accel);
        end;

      251:   // scroll effect floor
        begin
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            P_AddScroller(sc_floor, -dx, dy, control, s, accel);
        end;

      252: // carry objects on floor
        begin
          dx := TScrollSpawner.CarrySpeed(dx);
          dy := TScrollSpawner.CarrySpeed(dy);
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            P_AddScroller(sc_carry, dx, dy, control, s, accel);
        end;

      253:   // scroll and carry objects on floor
        begin
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            P_AddScroller(sc_floor, -dx, dy, control, s, accel);
          dx := TScrollSpawner.CarrySpeed(dx);
          dy := TScrollSpawner.CarrySpeed(dy);
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            P_AddScroller(sc_carry, dx, dy, control, s, accel);
        end;

          // killough 3/1/98: scroll wall according to linedef
          // (same direction and speed as scrolling floors)
      254:
        begin
          s := -1;
          while P_FindLineFromLineTag2(l, s) >= 0 do
            if s <> i then
              P_AddWallScroller(dx, dy, @lines[s], control, accel);
        end;

      255:    // killough 3/2/98: scroll according to sidedef offsets
        begin
          s := lines[i].sidenum[0];
          P_AddScroller(sc_side, -sides[s].textureoffset,
                        sides[s].rowoffset, -1, s, accel);
        end;

     1024, // special 255 with tag control
     1025,
     1026:
        begin
          if l.tag = 0 then
            I_Warning('P_SpawnScrollers(): Line %d with special %d is missing a tag!'#13#10, [i, special])
          else
          begin
            s := lines[i].sidenum[0];
            if special > 1024 then
              control := sides[s].sector.iSectorID;

            if special = 1026 then
              accel := 1;

            dx := -sides[s].textureoffset div 8;
            dy := sides[s].rowoffset div 8;

            s := -1;
            while P_FindLineFromLineTag2(l, s) >= 0 do
              if s <> i then
                P_AddScroller(sc_side, dx, dy, control, lines[s].sidenum[0], accel);
          end;
        end;
    end;

  end;

end;

end.
