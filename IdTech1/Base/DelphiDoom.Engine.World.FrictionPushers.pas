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
// DESCRIPTION:
//  Friction and push/pull effects of the sector specials (BOOM, phares 3/12/98).
//
//  Same code in Doom and Strife (issue #185, step 2g): one copy in Base, compiled
//  by the projects of those two games only. The records friction_t and pusher_t are
//  in the unit p_spec_h of the folder of the game.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.World.FrictionPushers;

interface

uses
  p_mobj_h,
  p_spec_h;

//==============================================================================
//
// T_Friction
//
//==============================================================================
procedure T_Friction(f: Pfriction_t);

//==============================================================================
//
// T_Pusher
//
//==============================================================================
procedure T_Pusher(p: Ppusher_t);

//==============================================================================
//
// P_SpawnFriction
//
//==============================================================================
procedure P_SpawnFriction;

//==============================================================================
//
// P_SpawnPushers
//
//==============================================================================
procedure P_SpawnPushers;

//==============================================================================
//
// P_GetPushThing
//
//==============================================================================
function P_GetPushThing(const snum: integer): Pmobj_t;

implementation

uses
  d_delphi,
  d_player,
  doomdata,
  doomdef,
  m_fixed,
  info_h,
  DelphiDoom.MathCore.Types,
  p_genlin,
  p_local,
  r_defs,
  r_main,
  p_setup,
  p_maputl,
  p_map,
  p_mobj,
  p_sight,
  p_tick,
  p_spec,
  tables,
  z_zone;

////////////////////////////////////////////////////////////////////////////
//
// FRICTION EFFECTS
//
// phares 3/12/98: Start of friction effects

// As the player moves, friction is applied by decreasing the x and y
// momentum values on each tic. By varying the percentage of decrease,
// we can simulate muddy or icy conditions. In mud, the player slows
// down faster. In ice, the player slows down more slowly.
//
// The amount of friction change is controlled by the length of a linedef
// with type 223. A length < 100 gives you mud. A length > 100 gives you ice.
//
// Also, each sector where these effects are to take place is given a
// new special type _______. Changing the type value at runtime allows
// these effects to be turned on or off.
//
// Sector boundaries present problems. The player should experience these
// friction changes only when his feet are touching the sector floor. At
// sector boundaries where floor height changes, the player can find
// himself still 'in' one sector, but with his feet at the floor level
// of the next sector (steps up or down). To handle this, Thinkers are used
// in icy/muddy sectors. These thinkers examine each object that is touching
// their sectors, looking for players whose feet are at the same level as
// their floors. Players satisfying this condition are given new friction
// values that are applied by the player movement code later.

//==============================================================================
//
// T_Friction
//
// This is where abnormal friction is applied to objects in the sectors.
// A friction thinker has been spawned for each sector where less or
// more friction should be applied. The amount applied is proportional to
// the length of the controlling linedef.
//
//==============================================================================
procedure T_Friction(f: Pfriction_t);
var
  sec: Psector_t;
  thing: Pmobj_t;
  node: Pmsecnode_t;
begin
  sec := @sectors[f.affectee];

  // Be sure the special sector type is still turned on. If so, proceed.
  // Else, bail out; the sector type has been changed on us.

  if sec.special and FRICTION_MASK = 0 then
    exit;

  // Assign the friction value to players on the floor, non-floating,
  // and clipped. Normally the object's friction value is kept at
  // ORIG_FRICTION and this thinker changes it for icy or muddy floors.

  // In Phase II, you can apply friction to Things other than players.

  // When the object is straddling sectors with the same
  // floorheight that have different frictions, use the lowest
  // friction value (muddy has precedence over icy).

  node := sec.touching_thinglist;
  while node <> nil do
  begin
    thing := node.m_thing;
    if (thing.player <> nil) and
       (thing.flags and (MF_NOGRAVITY or MF_NOCLIP) = 0) and
       (thing.z <= sec.floorheight) then
    begin
      if (thing.friction = ORIG_FRICTION) or     // normal friction?
         (f.friction < thing.friction) then
      begin
        thing.friction := f.friction;
        thing.movefactor := f.movefactor;
      end;
    end;
    node := node.m_snext;
  end;
end;

//==============================================================================
//
// Add a friction thinker to the thinker list
//
// Add_Friction adds a new friction thinker to the list of active thinkers.
//
//==============================================================================
procedure Add_Friction(friction: integer; movefactor: integer; affectee: integer);
var
  f: Pfriction_t;
begin
  f := Z_Malloc(SizeOf(friction_t), PU_LEVSPEC, nil);

  f.thinker._function.acp1 := @T_Friction;
  f.friction := friction;
  f.movefactor := movefactor;
  f.affectee := affectee;
  TTickRoutines.P_AddThinker(@f.thinker);
end;

//==============================================================================
//
// P_SpawnFriction
//
// Initialize the sectors where friction is increased or decreased
//
//==============================================================================
procedure P_SpawnFriction;
var
  l, le: Pline_t;
  s: integer;
  len: integer;        // line length controls magnitude
  friction: integer;   // friction value to be applied during movement
  movefactor: integer; // applied to each player move to simulate inertia
begin
  l := @lines[0];
  le := @lines[numlines];

  while l <> le do
  begin
    if l.special = 223 then
    begin
      len := TMapUtilRoutines.P_AproxDistance(l.dx, l.dy) div FRACUNIT;
      friction := ($1EB8 * len) div $80 + $D000;

      // The following check might seem odd. At the time of movement,
      // the move distance is multiplied by 'friction/0x10000', so a
      // higher friction value actually means 'less friction'.

      if friction > ORIG_FRICTION then       // ice
        movefactor := (($10092 - friction) * $70) div $158
      else
        movefactor := ((friction - $DB34) * $A) div $80;
      s := -1;
      while P_FindSectorFromLineTag2(l, s) >= 0 do
        Add_Friction(friction, movefactor, s);
    end;
    inc(l);
  end;
end;

//
// phares 3/12/98: End of friction effects
//
////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////
//
// PUSH/PULL EFFECT
//
// phares 3/20/98: Start of push/pull effects
//
// This is where push/pull effects are applied to objects in the sectors.
//
// There are four kinds of push effects
//
// 1) Pushing Away
//
//    Pushes you away from a point source defined by the location of an
//    MT_PUSH Thing. The force decreases linearly with distance from the
//    source. This force crosses sector boundaries and is felt w/in a circle
//    whose center is at the MT_PUSH. The force is felt only if the point
//    MT_PUSH can see the target object.
//
// 2) Pulling toward
//
//    Same as Pushing Away except you're pulled toward an MT_PULL point
//    source. This force crosses sector boundaries and is felt w/in a circle
//    whose center is at the MT_PULL. The force is felt only if the point
//    MT_PULL can see the target object.
//
// 3) Wind
//
//    Pushes you in a constant direction. Full force above ground, half
//    force on the ground, nothing if you're below it (water).
//
// 4) Current
//
//    Pushes you in a constant direction. No force above ground, full
//    force if on the ground or below it (water).
//
// The magnitude of the force is controlled by the length of a controlling
// linedef. The force vector for types 3 & 4 is determined by the angle
// of the linedef, and is constant.
//
// For each sector where these effects occur, the sector special type has
// to have the PUSH_MASK bit set. If this bit is turned off by a switch
// at run-time, the effect will not occur. The controlling sector for
// types 1 & 2 is the sector containing the MT_PUSH/MT_PULL Thing.

const
  PUSH_FACTOR = 7;

// tmpusher belongs to the point source (MT_PUSH/MT_PULL).
//
var
  tmpusher: Ppusher_t = nil; // pusher structure for blockmap searches

//==============================================================================
//
// PIT_PushThing determines the angle and magnitude of the effect.
// The object's x and y momentum values are changed.
//
//==============================================================================
function PIT_PushThing(thing: Pmobj_t): boolean;
var
  pushangle: angle_t;
  dist: integer;
  speed: integer;
  sx, sy: integer;
begin
  if thing.player = nil then
  begin
    result := false;
    exit;
  end;

  if (thing.flags and (MF_NOGRAVITY or MF_NOCLIP)) <> 0 then
  begin
    result := false;
    exit;
  end;

  sx := tmpusher.x;
  sy := tmpusher.y;
  dist := TMapUtilRoutines.P_AproxDistance(thing.x - sx,thing.y - sy);
  speed := (tmpusher.magnitude - (dist div (2 * FRACUNIT))) * (1 shl (FRACBITS - PUSH_FACTOR - 1));

  // If speed <= 0, you're outside the effective radius. You also have
  // to be able to see the push/pull source point.

  if (speed > 0) and P_CheckSight(thing, tmpusher.source) then
  begin
    pushangle := TRendererMain.R_PointToAngle2(thing.x, thing.y, sx, sy);
    if tmpusher.source._type = Ord(MT_PUSH) then
      pushangle := pushangle + ANG180;    // away
    pushangle := pushangle shr ANGLETOFINESHIFT;
    thing.momx := thing.momx + FixedMul(speed, finecosine[pushangle]);
    thing.momy := thing.momy + FixedMul(speed, finesine[pushangle]);
  end;

  result := true;
end;

//==============================================================================
//
// T_Pusher looks for all objects that are inside the radius of
// the effect.
//
//==============================================================================
procedure T_Pusher(p: Ppusher_t);
var
  sec: Psector_t;
  thing: Pmobj_t;
  node: Pmsecnode_t;
  xspeed, yspeed: integer;
  xl, xh, yl, yh, bx, by: integer;
  radius: integer;
  ht: integer;
begin
  sec := @sectors[p.affectee];

  // Be sure the special sector type is still turned on. If so, proceed.
  // Else, bail out; the sector type has been changed on us.
  if sec.special and PUSH_MASK = 0 then
    exit;

  // For constant pushers (wind/current) there are 3 situations:
  //
  // 1) Affected Thing is above the floor.
  //
  //    Apply the full force if wind, no force if current.
  //
  // 2) Affected Thing is on the ground.
  //
  //    Apply half force if wind, full force if current.
  //
  // 3) Affected Thing is below the ground (underwater effect).
  //
  //    Apply no force if wind, full force if current.
  //
  // Apply the effect to clipped players only for now.
  //
  // In Phase II, you can apply these effects to Things other than players.

  if p._type = p_push then
  begin

    // Seek out all pushable things within the force radius of this
    // point pusher. Crosses sectors, so use blockmap.

    tmpusher := p; // MT_PUSH/MT_PULL point source
    radius := p.radius; // where force goes to zero
    TMapCheck.BBox[BOX_TOP] := p.y + radius;
    TMapCheck.BBox[BOX_BOTTOM] := p.y - radius;
    TMapCheck.BBox[BOX_RIGHT] := p.x + radius;
    TMapCheck.BBox[BOX_LEFT] := p.x - radius;

    if internalblockmapformat then
    begin
      xl := MapBlockIntX(int64(TMapCheck.BBox[BOX_LEFT]) - int64(bmaporgx) - MAXRADIUS);
      xh := MapBlockIntX(int64(TMapCheck.BBox[BOX_RIGHT]) - int64(bmaporgx) + MAXRADIUS);
      yl := MapBlockIntY(int64(TMapCheck.BBox[BOX_BOTTOM]) - int64(bmaporgy) - MAXRADIUS);
      yh := MapBlockIntY(int64(TMapCheck.BBox[BOX_TOP]) - int64(bmaporgy) + MAXRADIUS);
    end
    else
    begin
      xl := MapBlockInt(TMapCheck.BBox[BOX_LEFT] - bmaporgx - MAXRADIUS);
      xh := MapBlockInt(TMapCheck.BBox[BOX_RIGHT] - bmaporgx + MAXRADIUS);
      yl := MapBlockInt(TMapCheck.BBox[BOX_BOTTOM] - bmaporgy - MAXRADIUS);
      yh := MapBlockInt(TMapCheck.BBox[BOX_TOP] - bmaporgy + MAXRADIUS);
    end;

    bx := xl;
    while bx <= xh do
    begin
      by := yl;
      while by <= yh do
      begin
        TMapUtilRoutines.P_BlockThingsIterator(bx, by, PIT_PushThing);
        inc(by);
      end;
      inc(bx);
    end;

    exit;
  end;

  // constant pushers p_wind and p_current

  if sec.heightsec <> -1 then // special water sector?
    ht := sectors[sec.heightsec].floorheight
  else
    ht := 0;
  node := sec.touching_thinglist; // things touching this sector
  while node <> nil do
  begin
    thing := node.m_thing;
    if (thing.player = nil) or (thing.flags and (MF_NOGRAVITY or MF_NOCLIP) <> 0) then
    begin
      node := node.m_snext;
      continue;
    end;

    if p._type = p_wind then
    begin
      if sec.heightsec = -1 then // NOT special water sector
      begin
        if thing.z > thing.floorz then // above ground
        begin
          xspeed := p.x_mag; // full force
          yspeed := p.y_mag;
        end
        else // on ground
        begin
          xspeed := p.x_mag div 2; // half force
          yspeed := p.y_mag div 2;
        end;
      end
      else // special water sector
      begin
        if thing.z > ht then // above ground
        begin
          xspeed := p.x_mag; // full force
          yspeed := p.y_mag;
        end
        else if Pplayer_t(thing.player).viewz < ht then  // underwater
        begin
          xspeed := 0;
          yspeed := 0 // no force
        end
        else // wading in water
        begin
          xspeed := p.x_mag div 2; // half force
          yspeed := p.y_mag div 2;
        end;
      end;
    end
    else // p_current
    begin
      if sec.heightsec = -1 then // NOT special water sector
      begin
        if thing.z > sec.floorheight then // above ground
        begin
          xspeed := 0;
          yspeed := 0; // no force
        end
        else // on ground
        begin
          xspeed := p.x_mag; // full force
          yspeed := p.y_mag;
        end
      end
      else // special water sector
      begin
        if thing.z > ht then // above ground
        begin
          xspeed := 0;
          yspeed := 0; // no force
        end
        else // underwater
        begin
          xspeed := p.x_mag; // full force
          yspeed := p.y_mag;
        end;
      end;
    end;

    thing.momx := thing.momx + (xspeed * (1 shl (FRACBITS - PUSH_FACTOR)));
    thing.momy := thing.momy + (yspeed * (1 shl (FRACBITS - PUSH_FACTOR)));
    node := node.m_snext
  end;
end;

//==============================================================================
//
// Add_Pusher
//
// Add a push thinker to the thinker list
//
//==============================================================================
procedure Add_Pusher(_type: pushertype_e; x_mag, y_mag: integer; source: Pmobj_t; affectee: integer);
var
  p: Ppusher_t;
begin
  p := Z_Malloc(SizeOf(pusher_t), PU_LEVSPEC, nil);

  p.thinker._function.acp1 := @T_Pusher;
  p.source := source;
  p._type := _type;
  p.x_mag := x_mag div FRACUNIT;
  p.y_mag := y_mag div FRACUNIT;
  p.magnitude := TMapUtilRoutines.P_AproxDistance(p.x_mag, p.y_mag);
  if source <> nil then // point source exist?
  begin
    p.radius := p.magnitude * (FRACUNIT * 2); // where force goes to zero
    p.x := p.source.x;
    p.y := p.source.y;
  end;
  p.affectee := affectee;
  TTickRoutines.P_AddThinker(@p.thinker);
end;

//==============================================================================
//
// P_GetPushThing returns a pointer to an MT_PUSH or MT_PULL thing,
// nil otherwise.
//
//==============================================================================
function P_GetPushThing(const snum: integer): Pmobj_t;
var
  thing: Pmobj_t;
  sec: Psector_t;
begin
  sec := @sectors[snum];
  thing := sec.thinglist;
  while thing <> nil do
  begin
    case thing._type of
      Ord(MT_PUSH), Ord(MT_PULL):
        begin
          result := thing;
          exit;
        end;
    else
      thing := thing.snext;
    end;
  end;

  result := nil;
end;

//==============================================================================
//
// P_SpawnPushers
//
// Initialize the sectors where pushers are present
//
//==============================================================================
procedure P_SpawnPushers;
var
  l, le: Pline_t;
  s: integer;
  thing: Pmobj_t;
begin
  l := @lines[0];
  le := @lines[numlines];
  while l <> le do
  begin
    case l.special of
      224: // wind
        begin
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            Add_Pusher(p_wind, l.dx, l.dy, nil, s);
        end;
      225: // current
        begin
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
            Add_Pusher(p_current, l.dx, l.dy, nil, s);
        end;
      226: // push/pull
        begin
          s := -1;
          while P_FindSectorFromLineTag2(l, s) >= 0 do
          begin
            thing := P_GetPushThing(s);
            if thing <> nil then // No MT_P* means no effect
              Add_Pusher(p_push, l.dx, l.dy, thing, s);
          end;
        end;
    end;
    inc(l);
  end;
end;

end.
