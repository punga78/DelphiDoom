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
//  Movement, collision handling.
//  Shooting and aiming.
//
//  One copy for Doom, Heretic, Hexen and Strife (issue #185, step 2c-1): what
//  a game does differently is in TMapGameRules, in the unit
//  DelphiDoom.Engine.World.MapRules of the folder of the game (chosen by the
//  project: static calls, no virtual call and no interface in this path).
//  The routines only one game has are in that unit too; the lists of the
//  sectors a thing touches (Doom, Strife) are in p_secnodes.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_map;

interface

uses
  DelphiDoom.MathCore.Types,
  m_rnd,
  i_system,
  doomdef,
  p_local,
  p_mobj_h,
  s_sound,
  m_fixed,
  tables,
  d_player,
  r_defs,
// Data.
  sounddata;

type
  /// <summary>
  /// The state of the position check (P_CheckPosition, P_TryMove, ...): the former
  /// globals tmthing, tmbbox, tmx, tmy, tmfloorz, ... (issue #244). It is declared
  /// here, in the unit of the routines that run for every line and thing of every
  /// blockmap cell, and as class variables on purpose: a variable of another unit is
  /// reached with one more load (the address is read from a slot), a variable of the
  /// same unit has an absolute address (docs\PIANO_TUTTO_A_CLASSI.md, par. 11.16).
  /// Scratch space of one call: P_CheckPosition sets it every time, never saved.
  /// </summary>
  TMapCheck = class sealed
  public
    /// <summary>The thing that is being checked or moved.</summary>
    class var Thing: Pmobj_t;
    /// <summary>The flags of the thing being checked (the thing's own or the caller's).</summary>
    class var Flags: integer;
    /// <summary>The position being checked.</summary>
    class var X: fixed_t;
    class var Y: fixed_t;
    /// <summary>The bounding box of the thing at the position being checked.</summary>
    class var BBox: array[0..3] of fixed_t;
    /// <summary>Highest floor, lowest ceiling and lowest drop off found under the thing.</summary>
    class var FloorZ: fixed_t;
    class var CeilingZ: fixed_t;
    class var DropOffZ: fixed_t;
    /// <summary>The flat of the floor that gave FloorZ.</summary>
    class var FloorPic: integer;
    /// <summary>The line a bouncing thing has hit.</summary>
    class var BounceLine: Pline_t;
    /// <summary>The line that lowers the ceiling, so that missiles do not explode against sky hack walls.</summary>
    class var CeilingLine: Pline_t;
    /// <summary>The special lines crossed by the move (a dynamic array, grown by PIT_CheckLine).</summary>
    class var SpecHit: Pline_tPArray;
    class var NumSpecHit: integer;
    class var MaxSpecHit: integer;
    /// <summary>True if the move would be ok when within FloorZ and CeilingZ.</summary>
    class var FloatOk: boolean;
    /// <summary>The thing a thing has landed on (P_CheckOnmobj; used for landing on pods and players).</summary>
    class var OnMobj: Pmobj_t;
    /// <summary>P_ChangeSector: crush the things that do not fit, and true if one does not fit.</summary>
    class var CrushChange: boolean;
    class var NoFit: boolean;
  end;

  /// <summary>
  /// The state of P_UseLines and PTR_UseTraverse: the former global usething (issue #244).
  /// Declared here as a class variable for the same reason as TMapCheck.
  /// </summary>
  TMapUse = class sealed
  public
    /// <summary>The thing that uses the lines.</summary>
    class var Thing: Pmobj_t;
  end;

  /// <summary>
  /// The state of the radius attacks (P_RadiusAttack and its variants, PIT_RadiusAttack): the
  /// former globals bombsource, bombspot, bombdamage and bombradius (issue #244). Declared here
  /// as class variables for the same reason as TMapCheck. Scratch space of one call.
  /// </summary>
  TMapBlast = class sealed
  public
    /// <summary>The creature that caused the explosion.</summary>
    class var Source: Pmobj_t;
    /// <summary>The thing that explodes, the damage at its centre and the radius.</summary>
    class var Spot: Pmobj_t;
    class var Damage: integer;
    class var Radius: integer;
  end;

  /// <summary>
  /// The state of the shots and of the aim (P_AimLineAttack, P_LineAttack and their traverse
  /// functions): the former globals linetarget, attackrange, shootthing, shootz, la_damage,
  /// aimslope, topslope, bottomslope and aim_flags_mask2_ex (issue #244). Declared here as
  /// class variables for the same reason as TMapCheck. Scratch space of one call, except
  /// LineTarget, that the callers read after the call (who got hit, or nil). The topslope
  /// and bottomslope of p_sight are another thing, and stay there.
  /// </summary>
  TMapAim = class sealed
  public
    /// <summary>Who got hit (or nil).</summary>
    class var LineTarget: Pmobj_t;
    /// <summary>The range of the attack, and where it starts from.</summary>
    class var AttackRange: fixed_t;
    class var ShootThing: Pmobj_t;
    /// <summary>Height if not aiming up or down (???: use slope for monsters?).</summary>
    class var ShootZ: fixed_t;
    /// <summary>The damage of the shot of P_LineAttack.</summary>
    class var Damage: integer;
    /// <summary>The slope of the aim and the limits of the slopes (to the top and bottom of the target).</summary>
    class var AimSlope: fixed_t;
    class var TopSlope: fixed_t;
    class var BottomSlope: fixed_t;
    /// <summary>MBF21: the flags2_ex that friends do not aim at (killough 8/2/98).</summary>
    class var AimFlagsMask2Ex: integer;
  end;

  /// <summary>
  /// The state of P_SlideMove, P_HitSlideLine and PTR_SlideTraverse: the former globals
  /// bestslidefrac, bestslideline, slidemo, tmxmove and tmymove (issue #244). Declared here
  /// as class variables for the same reason as TMapCheck. Scratch space of one call.
  /// </summary>
  TMapSlide = class sealed
  public
    /// <summary>The nearest line the slide has hit, and how far along the move it is.</summary>
    class var BestFrac: fixed_t;
    class var BestLine: Pline_t;
    /// <summary>The thing that slides.</summary>
    class var Mobj: Pmobj_t;
    /// <summary>The move that is left after the slide line has been hit.</summary>
    class var XMove: fixed_t;
    class var YMove: fixed_t;
  end;

//==============================================================================
//
// P_TeleportMove
//
//==============================================================================
function P_TeleportMove(thing: Pmobj_t; x, y: fixed_t): boolean;

//==============================================================================
//
// P_CheckPosition
//
//==============================================================================
function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;

//==============================================================================
//
// P_TryMove
//
//==============================================================================
function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;

//==============================================================================
//
// P_AimLineAttack
//
//==============================================================================
function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t; mask2_ex: integer = 0): fixed_t;

//==============================================================================
//
// P_LineAttack
//
//==============================================================================
procedure P_LineAttack(t1: Pmobj_t; angle: angle_t;
  distance: fixed_t; slope: fixed_t; damage: integer);

//==============================================================================
//
// P_UseLines
//
//==============================================================================
procedure P_UseLines(player: Pplayer_t);

//==============================================================================
//
// P_RadiusAttack
//
//==============================================================================
procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; const damage: integer;
  const distance: integer = 0; const dmsource: boolean = true);

//==============================================================================
//
// P_RadiusAttackEx
//
//==============================================================================
procedure P_RadiusAttackEx(spot: Pmobj_t; source: Pmobj_t; const damage, distance: integer);

//==============================================================================
//
// P_RadiusAttackPlayer
//
//==============================================================================
procedure P_RadiusAttackPlayer(spot: Pmobj_t; source: Pmobj_t; const damage, distance: integer);

//==============================================================================
//
// PIT_ChangeSector
//
//==============================================================================
function PIT_ChangeSector(thing: Pmobj_t): boolean;

//==============================================================================
//
// P_ChangeSector
//
//==============================================================================
function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;

//==============================================================================
//
// P_SlideMove
//
//==============================================================================
procedure P_SlideMove(mo: Pmobj_t);

//==============================================================================
//
// P_CheckOnmobj
//
//==============================================================================
function P_CheckOnmobj(thing: Pmobj_t): Pmobj_t;

//==============================================================================
//
// P_TestMobjLocation
//
//==============================================================================
function P_TestMobjLocation(mobj: Pmobj_t): boolean;

//==============================================================================
//
// P_ThingsInSameZ
//
//==============================================================================
function P_ThingsInSameZ(const A, B: Pmobj_t): boolean;

//==============================================================================
//
// P_ThingHeightClip
//
//==============================================================================
function P_ThingHeightClip(thing: Pmobj_t): boolean;

//==============================================================================
//
// P_PushByContact
// The moving thing pushes a thing that can be pushed (the last part of
// PIT_CheckThing, and the ripper missiles)
//
//==============================================================================
procedure P_PushByContact(thing: Pmobj_t);

//==============================================================================
//
// P_ContactPickup
// A special thing that is touched: picked up, or not; gives what
// PIT_CheckThing gives (true when the thing does not block the move)
//
//==============================================================================
function P_ContactPickup(thing: Pmobj_t): boolean;
//==============================================================================
//
// PIT_CheckThing
//
//==============================================================================
function PIT_CheckThing(thing: Pmobj_t): boolean;

// (linetarget, attackrange, shootthing, shootz and la_damage are in TMapAim, and
// floatok, spechit and ceilingline in TMapCheck)
// If "TMapCheck.FloatOk" true, move would be ok
// if within "TMapCheck.FloorZ - TMapCheck.CeilingZ".

//==============================================================================
//
// P_SectorJumpOverhead
//
//==============================================================================
function P_SectorJumpOverhead(const s: Psector_t; const p: Pplayer_t = nil): integer;

implementation

uses
  d_delphi,
  doomdata,
  g_game,
  info_h,
  info,
  info_common,
  info_rnd,
  p_common,
  p_gravity,
  p_setup,
  p_maputl,
  p_inter,
  p_mobj,
  p_spec_h,
  p_spec,
  p_sight,
  p_3dfloors, // JVAL: 3d Floors
  p_slopes, // JVAL: Slopes
  p_tick,
  p_sounds,
  ps_main,  // JVAL: Script Events
  r_main,
  r_sky,
  r_intrpl,
  r_translations,
  z_zone,
  DelphiDoom.Engine.World.MapRules;

//==============================================================================
//
// TELEPORT MOVE
//
// PIT_StompThing
//
//==============================================================================
function PIT_StompThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
// Can't shoot it? Can't stomp it!
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUACTORS flag - does not colide with actors
  if (TMapCheck.Thing.flags3_ex and MF3_EX_THRUACTORS <> 0) or (thing.flags3_ex and MF3_EX_THRUACTORS <> 0) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (TMapCheck.Thing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(thing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (thing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(TMapCheck.Thing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUSPECIES flag - does not colide with same species (also inheritance)
  if TMapCheck.Thing.flags3_ex and MF3_EX_THRUSPECIES <> 0 then
  begin
    if TMapCheck.Thing._type = thing._type then
    begin
      result := true;
      exit;
    end;
    if Info_GetInheritance(TMapCheck.Thing.info) = Info_GetInheritance(thing.info) then
    begin
      result := true;
      exit;
    end;
  end;

  blockdist := thing.radius + TMapCheck.Thing.radius;

  if (abs(thing.x - TMapCheck.X) >= blockdist) or (abs(thing.y - TMapCheck.Y) >= blockdist) then
  begin
    // didn't hit it
    result := true;
    exit;
  end;

  // don't clip against self
  if thing = TMapCheck.Thing then
  begin
    result := true;
    exit;
  end;

  if not TMapGameRules.CanStomp(thing) then
  begin
    result := false;
    exit;
  end;

  P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing, 10000);

  result := true;
end;

//==============================================================================
//
// P_TeleportMove
//
//==============================================================================
function P_TeleportMove(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  newsec: Psector_t;
  r: fixed_t;
begin
  // kill anything occupying the position
  TMapCheck.Thing := thing;
  TMapCheck.Flags := thing.flags;

  TMapCheck.X := x;
  TMapCheck.Y := y;

  r := TMapCheck.Thing.radius;
  TMapCheck.BBox[BOX_TOP] := y + r;
  TMapCheck.BBox[BOX_BOTTOM] := y - r;
  TMapCheck.BBox[BOX_RIGHT] := x + r;
  TMapCheck.BBox[BOX_LEFT] := x - r;

  newsec := TMapGameRules.PointInSector(x, y);
  TMapCheck.CeilingLine := nil;

  // The base floor/ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  //**TMapCheck.DropOffZ := newsubsec.sector.floorheight;
  TMapCheck.DropOffZ := TSlopeRoutines.P_FloorHeight(newsec, x, y); // JVAL: Slopes
  TMapCheck.FloorZ := TMapCheck.DropOffZ;

  //**TMapCheck.CeilingZ := newsubsec.sector.ceilingheight + P_SectorJumpOverhead(newsubsec.sector);
  TMapCheck.CeilingZ := TSlopeRoutines.P_CeilingHeight(newsec, x, y) + P_SectorJumpOverhead(newsec, thing.player);  // JVAL: Slopes
  TMapCheck.FloorPic := newsec.floorpic;

  inc(validcount);
  TMapCheck.NumSpecHit := 0;

  // stomp on any things contacted
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

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_StompThing) then
      begin
        result := false;
        exit;
      end;

  // the move is ok,
  // so link the thing into its new position
  P_UnsetThingPosition(thing);

  thing.floorz := TMapCheck.FloorZ;
  thing.ceilingz := TMapCheck.CeilingZ;
  thing.x := x;
  thing.y := y;
  if TMapGameRules.TeleportSetsZ then
    thing.z := TMapCheck.FloorZ;

  P_SetThingPosition(thing);

  if thing.player = viewplayer then
    TRendererInterpolation.R_SetInterpolateSkipTicks(1);

  TMapGameRules.MarkJustAppeared(thing);
  thing.intrplcnt := 0;

  result := true;
end;

//==============================================================================
//
// MOVEMENT ITERATOR FUNCTIONS
//
// PIT_CheckLine
// Adjusts TMapCheck.FloorZ and TMapCheck.CeilingZ as lines are contacted
//
//==============================================================================
function PIT_CheckLine(ld: Pline_t): boolean;
begin
  if (TMapCheck.BBox[BOX_RIGHT] <= ld.bbox[BOX_LEFT]) or
     (TMapCheck.BBox[BOX_LEFT] >= ld.bbox[BOX_RIGHT]) or
     (TMapCheck.BBox[BOX_TOP] <= ld.bbox[BOX_BOTTOM]) or
     (TMapCheck.BBox[BOX_BOTTOM] >= ld.bbox[BOX_TOP]) then
  begin
    result := true;
    exit;
  end;

  if P_BoxOnLineSide(@TMapCheck.BBox, ld) <> -1 then
  begin
    result := true;
    exit;
  end;

  // A line has been hit

  // The moving thing's destination position will cross
  // the given line.
  // If this should not be allowed, return false.
  // If the line is special, keep track of it
  // to process later if the move is proven ok.
  // NOTE: specials are NOT sorted by order,
  // so two special lines that are only 8 pixels apart
  // could be crossed in either order.

  if ld.backsector = nil then
  begin
    TMapGameRules.BlastedHitsWall(TMapCheck.Thing);
    TMapRoutines.P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
    result := false;  // one sided line
    TMapCheck.BounceLine := ld;
    exit;
  end;

  if TMapCheck.Thing.flags and MF_MISSILE = 0 then
    if not TMapGameRules.CheckLineBlocking(ld) then
    begin
      result := false;
      exit;
    end;

  // set openrange, opentop, openbottom
  P_LineOpening(ld, true);

  // adjust floor / ceiling heights
  if opentop < TMapCheck.CeilingZ then
  begin
    TMapCheck.CeilingZ := opentop;
    TMapCheck.CeilingLine := ld;
  end;

  if openbottom > TMapCheck.FloorZ then
    TMapCheck.FloorZ := openbottom;

  if lowfloor < TMapCheck.DropOffZ then
    TMapCheck.DropOffZ := lowfloor;

  // if contacted a special line, add it to the list
  if (ld.special <> 0) or (ld.flags and ML_TRIGGERSCRIPTS <> 0) then
  begin
    if TMapCheck.MaxSpecHit = 0 then
    begin
      TMapCheck.MaxSpecHit := 64;
      TMapCheck.SpecHit := Z_Malloc(64 * SizeOf(Pline_t), PU_STATIC, nil);
    end
    else if TMapCheck.NumSpecHit = TMapCheck.MaxSpecHit then
    begin
      TMapCheck.MaxSpecHit := TMapCheck.MaxSpecHit + 8;
      TMapCheck.SpecHit := Z_ReAlloc(TMapCheck.SpecHit, TMapCheck.MaxSpecHit * SizeOf(Pline_t), PU_STATIC, nil)
    end;

    TMapCheck.SpecHit[TMapCheck.NumSpecHit] := ld;
    inc(TMapCheck.NumSpecHit);

  end;

  result := true;
end;

//==============================================================================
// PIT_CheckLineTM
//
// JVAL: Slopes
//
//==============================================================================
function PIT_CheckLineTM(ld: Pline_t): boolean;
begin
  if (TMapCheck.BBox[BOX_RIGHT] <= ld.bbox[BOX_LEFT]) or
     (TMapCheck.BBox[BOX_LEFT] >= ld.bbox[BOX_RIGHT]) or
     (TMapCheck.BBox[BOX_TOP] <= ld.bbox[BOX_BOTTOM]) or
     (TMapCheck.BBox[BOX_BOTTOM] >= ld.bbox[BOX_TOP]) then
  begin
    result := true;
    exit;
  end;

  // JVAL: VERSION 206
  if ld.flags and ML_NOCLIP <> 0 then
  begin
    result := true;
    exit;
  end;

  if P_BoxOnLineSide(@TMapCheck.BBox, ld) <> -1 then
  begin
    result := true;
    exit;
  end;

  // A line has been hit

  // The moving thing's destination position will cross
  // the given line.
  // If this should not be allowed, return false.
  // If the line is special, keep track of it
  // to process later if the move is proven ok.
  // NOTE: specials are NOT sorted by order,
  // so two special lines that are only 8 pixels apart
  // could be crossed in either order.

  if ld.backsector = nil then
  begin
    TMapGameRules.BlastedHitsWall(TMapCheck.Thing);
    TMapRoutines.P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
    result := false;  // one sided line
    TMapCheck.BounceLine := ld;
    exit;
  end;

  if TMapCheck.Thing.flags and MF_MISSILE = 0 then
    if not TMapGameRules.CheckLineBlockingTM(ld) then
    begin
      result := false;
      exit;
    end;

  // set openrange, opentop, openbottom
{  if G_PlayingEngineVersion >= VERSION205 then
    P_LineOpeningTM206(ld, true)
  else}
    P_LineOpeningTM(ld, true);

  // adjust floor / ceiling heights
  if opentop < TMapCheck.CeilingZ then
  begin
    TMapCheck.CeilingZ := opentop;
    TMapCheck.CeilingLine := ld;
  end;

  if openbottom > TMapCheck.FloorZ then
    TMapCheck.FloorZ := openbottom;

  if lowfloor < TMapCheck.DropOffZ then
    TMapCheck.DropOffZ := lowfloor;

  // if contacted a special line, add it to the list
  if (ld.special <> 0) or (ld.flags and ML_TRIGGERSCRIPTS <> 0) then
  begin
    if TMapCheck.MaxSpecHit = 0 then
    begin
      TMapCheck.MaxSpecHit := 64;
      TMapCheck.SpecHit := Z_Malloc(64 * SizeOf(Pline_t), PU_STATIC, nil);
    end
    else if TMapCheck.NumSpecHit = TMapCheck.MaxSpecHit then
    begin
      TMapCheck.MaxSpecHit := TMapCheck.MaxSpecHit + 8;
      TMapCheck.SpecHit := Z_ReAlloc(TMapCheck.SpecHit, TMapCheck.MaxSpecHit * SizeOf(Pline_t), PU_STATIC, nil)
    end;

    TMapCheck.SpecHit[TMapCheck.NumSpecHit] := ld;
    inc(TMapCheck.NumSpecHit);

  end;

  result := true;
end;

//==============================================================================
//
// P_ThingsInSameZ
//
//==============================================================================
function P_ThingsInSameZ(const A, B: Pmobj_t): boolean;
var
  Az1, Az2, Bz1, Bz2: fixed_t;

  function _getheightoffs(const mo: Pmobj_t): fixed_t;
  begin
    if (G_PlayingEngineVersion < VERSION207) or TMapGameRules.KeepsOldSameZ(A, B) then
      result := mo.height div 2
    else if mo.flags and MF_SPAWNCEILING <> 0 then
      result := mo.height
    else
      result := 0;
  end;

begin
  Az1 := A.z - _getheightoffs(A);
  if Az1 < A.floorz then
    Az1 := A.floorz;
  Az2 := Az1 + A.height;
  if Az2 > A.ceilingz then
  begin
    Az2 := A.ceilingz;
    Az1 := Az2 - A.height;
    if Az1 < A.floorz then
      Az1 := A.floorz;
  end;

  Bz1 := B.z - _getheightoffs(B);
  if Bz1 < B.floorz then
    Bz1 := B.floorz;
  Bz2 := Bz1 + B.height;
  if Bz2 > B.ceilingz then
  begin
    Bz2 := B.ceilingz;
    Bz1 := Bz2 - B.height;
    if Bz1 < B.floorz then
      Bz1 := B.floorz;
  end;

  if (G_PlayingEngineVersion < VERSION207) or TMapGameRules.KeepsOldSameZ(A, B) then
    result :=
      IsIntegerInRange(Az1, Bz1, Bz2) or
      IsIntegerInRange(Az2, Bz1, Bz2) or
      IsIntegerInRange(Bz1, Az1, Az2) or
      IsIntegerInRange(Bz2, Az1, Az2)
  else
    result :=
      IsIntegerInRange(Az1, Bz1 + 1, Bz2 - 1) or
      IsIntegerInRange(Az2, Bz1 + 1, Bz2 - 1) or
      IsIntegerInRange(Bz1, Az1 + 1, Az2 - 1) or
      IsIntegerInRange(Bz2, Az1 + 1, Az2 - 1)
end;

//==============================================================================
//
// P_PushByContact
//
//==============================================================================
procedure P_PushByContact(thing: Pmobj_t);
var
  pushfactor: fixed_t;
begin
  if TMapGameRules.CanBePushed(thing) then
  begin // Push thing
    pushfactor := thing.pushfactor;
    if pushfactor <= 0 then
    begin
      thing.momx := thing.momx + TMapGameRules.QuarterMomentum(TMapCheck.Thing.momx);
      thing.momy := thing.momy + TMapGameRules.QuarterMomentum(TMapCheck.Thing.momy);
    end
    else
    begin
      thing.momx := thing.momx + FixedMul(TMapCheck.Thing.momx, pushfactor);
      thing.momy := thing.momy + FixedMul(TMapCheck.Thing.momy, pushfactor);
    end;
  end;
end;

//==============================================================================
//
// P_ContactPickup
//
//==============================================================================
function P_ContactPickup(thing: Pmobj_t): boolean;
var
  solid: boolean;
begin
  // check for special pickup
  if thing.flags and MF_SPECIAL <> 0 then
  begin
    solid := thing.flags and MF_SOLID <> 0;
    if TMapGameRules.PicksUpOnContact then
    begin
      // can remove thing
      P_TouchSpecialThing(thing, TMapCheck.Thing);
    end;
    result := not solid;
  end
  else
    result := thing.flags and MF_SOLID = 0;
end;
//==============================================================================
//
// PIT_CheckThing
//
//==============================================================================
function PIT_CheckThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
  if thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE) = 0 then
  begin
    result := true;
    exit;
  end;

  // don't clip against self
  if thing = TMapCheck.Thing then
  begin
    result := true;
    exit;
  end;

  if G_PlayingEngineVersion >= VERSION205 then
    if (thing.player <> nil) or (TMapCheck.Thing.player <> nil) then  // Only if a player is involved
      if not P_ThingsInSameZ(thing, TMapCheck.Thing) then // JVAL: 20200413 -> Check z axis
      begin
        result := true;
        exit;
      end;

  // JVAL: 20200130 - MF2_EX_DONTBLOCKPLAYER flag - does not block players
  if (thing.flags2_ex and MF2_EX_DONTBLOCKPLAYER <> 0) and (TMapCheck.Thing.player <> nil) then
  begin
    result := true;
    exit;
  end;

  if (TMapCheck.Thing.flags2_ex and MF2_EX_DONTBLOCKPLAYER <> 0) and (thing.player <> nil) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUACTORS flag - does not colide with actors
  if (TMapCheck.Thing.flags3_ex and MF3_EX_THRUACTORS <> 0) or (thing.flags3_ex and MF3_EX_THRUACTORS <> 0) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (TMapCheck.Thing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(thing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (thing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(TMapCheck.Thing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUSPECIES flag - does not colide with same species (also inheritance)
  if TMapCheck.Thing.flags3_ex and MF3_EX_THRUSPECIES <> 0 then
  begin
    if TMapCheck.Thing._type = thing._type then
    begin
      result := true;
      exit;
    end;
    if Info_GetInheritance(TMapCheck.Thing.info) = Info_GetInheritance(thing.info) then
    begin
      result := true;
      exit;
    end;
  end;

  blockdist := thing.radius + TMapCheck.Thing.radius;

  if (abs(thing.x - TMapCheck.X) >= blockdist) or (abs(thing.y - TMapCheck.Y) >= blockdist) then
  begin
    // didn't hit it
    result := true;
    exit;
  end;

  // JVAL: 3d Floors
  if G_PlayingEngineVersion >= TMapGameRules.SlopesVersion then
  begin
    if (TMapCheck.Thing.player <> nil) or (thing.player <> nil) then
      if TMapCheck.FloorZ <> thing.floorz then
      begin
        if TMapCheck.Thing.z > thing.z + thing.height then
        begin
          result := true;
          exit;
        end;

        if TMapCheck.Thing.z + TMapCheck.Thing.height < thing.z then
        begin // under thing
          result := true;
          exit;
        end;
      end;
  end;

  result := TMapGameRules.CheckThingContact(thing);
end;

//
// MOVEMENT CLIPPING
//

//==============================================================================
//
// P_CheckPosition
// This is purely informative, nothing is modified
// (except things picked up).
//
// in:
//  a mobj_t (can be valid or invalid)
//  a position to be checked
//   (doesn't need to be related to the mobj_t->x,y)
//
// during:
//  special things are touched if MF_PICKUP
//  early out on solid lines?
//
// out:
//  newsubsec
//  floorz
//  ceilingz
//  TMapCheck.DropOffZ
//   the lowest point contacted
//   (monsters won't move to a dropoff)
//  speciallines[]
//  numspeciallines
//
//==============================================================================
function P_CheckPosition(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  bx: integer;
  by: integer;
  newsec: Psector_t;
  msec: Psector_t;
  r: fixed_t;
begin
  TMapCheck.Thing := thing;
  TMapCheck.Flags := thing.flags;

  TMapCheck.X := x;
  TMapCheck.Y := y;

  r := TMapCheck.Thing.radius;
  TMapCheck.BBox[BOX_TOP] := y + r;
  TMapCheck.BBox[BOX_BOTTOM] := y - r;
  TMapCheck.BBox[BOX_RIGHT] := x + r;
  TMapCheck.BBox[BOX_LEFT] := x - r;

  newsec := TMapGameRules.PointInSector(x, y);

  TMapGameRules.BeginCheckPosition;
  TMapCheck.CeilingLine := nil;

  // The base floor / ceiling is from the subsector
  // that contains the point.
  // Any contacted lines the step closer together
  // will adjust them.
  // JVAL 20191209 - Fix 3d floor problems with A_SpawnItem & A_SpawnItemEx
  TMapCheck.DropOffZ := T3dFloorRoutines.P_3dFloorHeight(newsec, x, y, thing.z); // JVAL: Slopes
  TMapCheck.FloorZ := TMapCheck.DropOffZ;
  TMapCheck.CeilingZ := T3dFloorRoutines.P_3dCeilingHeight(newsec, x, y, thing.z) + P_SectorJumpOverhead(newsec, thing.player);

  TMapCheck.BounceLine := nil;

  if newsec.midsec >= 0 then
  begin
    msec := @sectors[newsec.midsec];
    if thing.z < msec.ceilingheight then
      TMapCheck.FloorPic := newsec.floorpic
    else
      TMapCheck.FloorPic := msec.ceilingpic
  end
  else
    TMapCheck.FloorPic := newsec.floorpic;

  inc(validcount);
  TMapCheck.NumSpecHit := 0;

  if TMapGameRules.NoClipSkipsThings(TMapCheck.Flags) then
  begin
    result := true;
    exit;
  end;

  // Check things first, possibly picking things up.
  // The bounding box is extended by MAXRADIUS
  // because mobj_ts are grouped into mapblocks
  // based on their origin point, and can overlap
  // into adjacent blocks by up to MAXRADIUS units.
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

  TMapGameRules.ClearBlockingThing;
  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_CheckThing) then
      begin
        result := false;
        exit;
      end;

  // check lines
  if TMapGameRules.NoClipSkipsLines(TMapCheck.Flags) then
  begin
    result := true;
    exit;
  end;

  TMapGameRules.ClearBlockingThing;
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

  // JVAL: Slopes
  if G_PlayingEngineVersion >= TMapGameRules.SlopesVersion then
  begin
    for bx := xl to xh do
      for by := yl to yh do
        if not P_BlockLinesIterator(bx, by, PIT_CheckLineTM) then // JVAL: Slopes
        begin
          result := false;
          exit;
        end;
  end
  else
  begin
    for bx := xl to xh do
      for by := yl to yh do
        if not P_BlockLinesIterator(bx, by, PIT_CheckLine) then
        begin
          result := false;
          exit;
        end;
  end;

  result := true;
end;

//==============================================================================
//
// P_FakeZMovement
//
//     Fake the zmovement so that we can check if a move is legal
//
//==============================================================================
procedure P_FakeZMovement(mo: Pmobj_t);
var
  dist: integer;
  delta: integer;
begin
//
// adjust height
//
  mo.z := mo.z + mo.momz;
  if(mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin  // float down towards target if too close
    if not TMapGameRules.IsSkullFlying(mo) and (mo.flags and MF_INFLOAT = 0) then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);
      delta := mo.target.z + (mo.height div 2) - mo.z;
      if (delta < 0) and (dist < -delta * 3) then
        mo.z := mo.z - TCommonMovementActions.P_FloatSpeed(mo)
      else if (delta > 0) and (dist < delta * 3) then
        mo.z := mo.z + TCommonMovementActions.P_FloatSpeed(mo);
    end;
  end;
  if TMapGameRules.FlightBobs(mo) then
    if (mo.player <> nil) and (mo.z > mo.floorz) and (TTickState.LevelTime and 2 <> 0) then
      mo.z := mo.z + finesine[(FINEANGLES div 20 * TTickState.LevelTime div 4) and FINEMASK];

//
// clip movement
//
  if mo.z <= mo.floorz then
  begin // Hit the floor
    mo.z := mo.floorz;
    if mo.momz < 0 then
      mo.momz := 0;
    if TMapGameRules.IsSkullFlying(mo) then // The skull slammed into something
      mo.momz := -mo.momz;
    if (mo.info.crashstate <> 0) and (mo.flags and MF_CORPSE <> 0) then
      exit;
  end
  else if TMapGameRules.HasLowGravity(mo) then
  begin
    if mo.momz = 0 then
      mo.momz := -(P_GetMobjGravity(mo) div 8) * 2
    else
      mo.momz := mo.momz - P_GetMobjGravity(mo) div 8;
  end
  else if mo.flags and MF_NOGRAVITY = 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -P_GetMobjGravity(mo) * 2
    else
      mo.momz := mo.momz - P_GetMobjGravity(mo);
  end
  else if mo.flags2_ex and MF2_EX_MEDIUMGRAVITY <> 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -(P_GetMobjGravity(mo) div 8) * 4
    else
      mo.momz := mo.momz - P_GetMobjGravity(mo) div 4;
  end;

  if mo.z + mo.height > mo.ceilingz then
  begin  // hit the ceiling
    if mo.momz > 0 then
      mo.momz := 0;
    mo.z := mo.ceilingz - mo.height;
    if TMapGameRules.IsSkullFlying(mo) then // the skull slammed into something
      mo.momz := -mo.momz;
  end;
end;

//==============================================================================
//
// PIT_CheckOnmobjZ
//
//==============================================================================
function PIT_CheckOnmobjZ(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
  if thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE) = 0 then
  begin // Can't hit thing
    result := true;
    exit;
  end;

  blockdist := thing.radius + TMapCheck.Thing.radius;
  if (abs(thing.x - TMapCheck.X) >= blockdist) or (abs(thing.y - TMapCheck.Y) >= blockdist) then
  begin // Didn't hit thing
    result := true;
    exit;
  end;

  if thing = TMapCheck.Thing then
  begin // Don't clip against self
    result := true;
    exit;
  end;

  if TMapCheck.Thing.z > thing.z + thing.height then
  begin
    result := true;
    exit;
  end
  else if TMapCheck.Thing.z + TMapCheck.Thing.height < thing.z then
  begin // under thing
    result := true;
    exit;
  end;

  result := thing.flags and MF_SOLID = 0;
  if not result then
    TMapCheck.OnMobj := thing;

end;

//==============================================================================
//
// P_CheckOnmobj(mobj_t *thing)
//
//     Checks if the new Z position is legal
//
//==============================================================================
function P_CheckOnmobj(thing: Pmobj_t): Pmobj_t;
var
  xl, xh, yl, yh, bx, by: integer;
  newsec: Psector_t;
  x: fixed_t;
  y: fixed_t;
  oldmo: mobj_t;
  r: fixed_t;
begin
  x := thing.x;
  y := thing.y;
  TMapCheck.Thing := thing;
  TMapCheck.Flags := thing.flags;
  oldmo := thing^; // save the old mobj before the fake zmovement
  P_FakeZMovement(TMapCheck.Thing);

  TMapCheck.X := x;
  TMapCheck.Y := y;

  r := TMapCheck.Thing.radius;
  TMapCheck.BBox[BOX_TOP] := y + r;
  TMapCheck.BBox[BOX_BOTTOM] := y - r;
  TMapCheck.BBox[BOX_RIGHT] := x + r;
  TMapCheck.BBox[BOX_LEFT] := x - r;

  newsec := TMapGameRules.PointInSector(x, y);
  TMapCheck.CeilingLine := nil;

//
// the base floor / ceiling is from the subsector that contains the
// point.  Any contacted lines the step closer together will adjust them
//
  TMapCheck.FloorZ := TSlopeRoutines.P_FloorHeight(newsec, x, y);  // JVAL: Slopes
  TMapCheck.DropOffZ := TMapCheck.FloorZ;
  TMapCheck.CeilingZ := TSlopeRoutines.P_CeilingHeight(newsec, x, y);  // JVAL: Slopes

  inc(validcount);
  TMapCheck.NumSpecHit := 0;

  if TMapCheck.Flags and MF_NOCLIP <> 0 then
  begin
    result := nil;
    exit;
  end;

//
// check things first, possibly picking things up
// the bounding box is extended by MAXRADIUS because mobj_ts are grouped
// into mapblocks based on their origin point, and can overlap into adjacent
// blocks by up to MAXRADIUS units
//
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

  for bx := xl to xh do
    for by := yl to yh do
      if not P_BlockThingsIterator(bx, by, PIT_CheckOnmobjZ) then
      begin
        TMapCheck.Thing^ := oldmo;
        result := TMapCheck.OnMobj;
        exit;
      end;

  TMapCheck.Thing^ := oldmo;
  result := nil;
end;

//==============================================================================
//
// P_TryMove
// Attempt to move to a new position,
// crossing special lines unless MF_TELEPORT is set.
//
//==============================================================================
function P_TryMove(thing: Pmobj_t; x, y: fixed_t): boolean;
var
  oldx: fixed_t;
  oldy: fixed_t;
  side: integer;
  oldside: integer;
  ld: Pline_t;
  p: Pplayer_t;
  oldfloorz: fixed_t; // JVAL: Slopes
  oldonfloorz: boolean;
  dropoffmargin: fixed_t;
  jumpupmargin: fixed_t;

  procedure pushline;
  var
    numSpecHitTemp: integer;
  begin
    if thing.flags and TMapGameRules.NoSpecHitFlags = 0 then
    begin
      TMapGameRules.BlastedHitsWall(TMapCheck.Thing);
      numSpecHitTemp := TMapCheck.NumSpecHit;
      while numSpecHitTemp > 0 do
      begin
        dec(numSpecHitTemp);
        // see if the line was crossed
        ld := TMapCheck.SpecHit[numSpecHitTemp];
        side := P_PointOnLineSide(thing.x, thing.y, ld);
        TMapRoutines.P_CheckForPushSpecial(ld, side, thing);
      end;
    end;
  end;

begin
  TMapCheck.FloatOk := false;
  if not P_CheckPosition(thing, x, y) then
    if not TMapGameRules.StepsOnBlockingThing(thing) then
    begin
      if TMapGameRules.PushesLinesWhenBlocked then
        pushline;
      result := false;  // solid wall or thing
      exit;
    end;

  if thing.flags and MF_NOCLIP = 0 then
  begin
    if TMapCheck.CeilingZ - TMapCheck.FloorZ < thing.height then
    begin
      pushline;
      result := false;  // doesn't fit
      exit;
    end;

    TMapCheck.FloatOk := true;

    if not TMapGameRules.IgnoresCeilingFit(thing) and
       (TMapCheck.CeilingZ - thing.z < thing.height) then
    begin
      pushline;
      result := false;  // mobj must lower itself to fit
      exit;
    end;

    if TMapGameRules.FlightBlocked(thing) then
    begin
      pushline;
      result := false;
      exit;
    end;

    if TMapGameRules.StepTooHighOnFoot(thing) then
    begin
      result := false;
      exit;
    end;

    // JVAL: Do not step up in ladder movement
    p := thing.player;
    if p <> nil then
      if p.laddertics > 0 then
        if TMapCheck.FloorZ > thing.z then
        begin
          result := false;
          exit;
        end;

    // JVAL: 20210210 - maxstepheight field
    if thing.flags4_ex and MF4_EX_CANNOTSTEP <> 0 then
      jumpupmargin := 0
    else
    begin
      if thing.info.maxstepheight > 0 then
      begin
        jumpupmargin := thing.info.maxstepheight;
        if jumpupmargin < 64 then
          jumpupmargin := jumpupmargin * FRACUNIT;
      end
      else
        jumpupmargin := 24 * FRACUNIT;
    end;

    // JVAL: Version 205
    if G_PlayingEngineVersion >= VERSION205 then
      if (thing.flags2_ex and MF2_EX_JUMPUP <> 0) and (N_Random > 20) then
        jumpupmargin := jumpupmargin + 32 * FRACUNIT;

    if not TMapGameRules.IgnoresStepHeight(thing) and
       (TMapCheck.FloorZ - thing.z > jumpupmargin) then
    begin
      pushline;
      result := false;  // too big a step up
      exit;
    end;

    if TMapGameRules.MissileStepTooHigh(thing) then
    begin
      result := false;
      exit;
    end;

    if thing.flags4_ex and MF4_EX_CANNOTDROPOFF <> 0 then
      dropoffmargin := 0
    else
    begin
      // JVAL: 20210210 - maxdropoffheight field
      if thing.info.maxdropoffheight > 0 then
      begin
        dropoffmargin := thing.info.maxdropoffheight;
        if dropoffmargin < 64 then
          dropoffmargin := dropoffmargin * FRACUNIT;
      end
      else
        dropoffmargin := TMapGameRules.DropoffHeight;
    end;

    // JVAL: Version 204
    if G_PlayingEngineVersion >= VERSION204 then
      if (thing.flags2_ex and MF2_EX_JUMPDOWN <> 0) and (N_Random > 20) then
        dropoffmargin := dropoffmargin + TMapGameRules.JumpDownMargin;

    if (thing.flags and (MF_DROPOFF or MF_FLOAT) = 0) and
       (TMapCheck.FloorZ - TMapCheck.DropOffZ > dropoffmargin) and
       not TMapGameRules.IgnoresDropoff(thing) then
    begin
      result := false;  // don't stand over a dropoff
      exit;
    end;

    // JVAL: Version 204
    if TMapGameRules.CannotLeaveFloorPic(thing) and
       ((TMapCheck.FloorPic <> Psubsector_t(thing.subsector).sector.floorpic) or
         (TMapCheck.FloorZ - thing.z <> 0)) then
    begin // must stay within a sector of a certain floor type
      result := false;
      exit;
    end;

  end;

  // the move is ok,
  // so link the thing into its new position
  oldfloorz := TSlopeRoutines.P_FloorHeight(thing.x, thing.y); // JVAL: Slopes
  oldonfloorz := oldfloorz >= thing.z; // JVAL: Slopes
  P_UnsetThingPosition(thing);

  oldx := thing.x;
  oldy := thing.y;

  thing.floorz := TMapCheck.FloorZ;
  thing.ceilingz := TMapCheck.CeilingZ;

  TMapGameRules.StoreFloorPic(thing);
  thing.x := x;
  thing.y := y;

  P_SetThingPosition(thing);

  // JVAL: Slopes
  if Psubsector_t(thing.subsector).sector.renderflags and SRF_SLOPED <> 0 then
  begin
    p := thing.player;
    if p = nil then
    begin
      if thing.z < TMapCheck.FloorZ then
        thing.z := TMapCheck.FloorZ;
    end
    else
    begin
      p.slopetics := SLOPECOUNTDOWN;
      if oldonfloorz then
        if oldfloorz > TMapCheck.FloorZ then
          thing.momz := thing.momz + (TMapCheck.FloorZ - oldfloorz);
    end;

  end;

  // JVAL: Slopes - 3d Floors SOS -> Get right P_GetThingFloorType()
  TMapGameRules.UpdateFloorClip(thing);

  // if any special lines were hit, do the effect
  if thing.flags and TMapGameRules.NoSpecHitFlags = 0 then
  begin
    while TMapCheck.NumSpecHit > 0 do
    begin
      // see if the line was crossed
      dec(TMapCheck.NumSpecHit);
      ld := TMapCheck.SpecHit[TMapCheck.NumSpecHit];
      side := P_PointOnLineSide(thing.x, thing.y, ld);
      oldside := P_PointOnLineSide(oldx, oldy, ld);
      if side <> oldside then
      begin
        // JVAL: Script Events
        if ld.flags and ML_TRIGGERSCRIPTS <> 0 then
          if thing.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
            PS_EventCrossLine(thing, pDiff(ld, lines, SizeOf(line_t)), oldside);

        if ld.special <> 0 then
          TMapGameRules.CrossSpecialLine(ld, oldside, thing);
      end;
    end;
  end;

  result := true;
end;

//==============================================================================
//
// P_ThingHeightClip
// Takes a valid thing and adjusts the thing->floorz,
// thing->ceilingz, and possibly thing->z.
// This is called for all nearby monsters
// whenever a sector changes height.
// If the thing doesn't fit,
// the z will be set to the lowest value
// and false will be returned.
//
//==============================================================================
function P_ThingHeightClip(thing: Pmobj_t): boolean;
var
  onfloor: boolean;
begin
  onfloor := thing.z = thing.floorz;

  P_CheckPosition(thing, thing.x, thing.y);
  // what about stranding a monster partially off an edge?

  thing.floorz := TMapCheck.FloorZ;
  thing.ceilingz := TMapCheck.CeilingZ;
  TMapGameRules.StoreFloorPic(thing);

  if onfloor then
  begin
    // walking monsters rise and fall with the floor
    if TMapGameRules.SnapsToFloor(thing) then
      thing.z := thing.floorz;
  end
  else
  begin
    // don't adjust a floating monster unless forced to
    if thing.z + thing.height > thing.ceilingz then
      thing.z := thing.ceilingz - thing.height;
  end;

  result := thing.ceilingz - thing.floorz >= thing.height;
end;

//
// SLIDE MOVE
// Allows the player to slide along any angled walls.
// (its state is in TMapSlide)
//

//==============================================================================
//
// P_HitSlideLine
// Adjusts the xmove / ymove
// so that the next move will slide along the wall.
//
//==============================================================================
procedure P_HitSlideLine(ld: Pline_t);
var
  side: integer;
  lineangle: angle_t;
  moveangle: angle_t;
  deltaangle: angle_t;
  movelen: fixed_t;
  newlen: fixed_t;
begin
  if ld.slopetype = ST_HORIZONTAL then
  begin
    TMapSlide.YMove := 0;
    exit;
  end;

  if ld.slopetype = ST_VERTICAL then
  begin
    TMapSlide.XMove := 0;
    exit;
  end;

  side := P_PointOnLineSide(TMapSlide.Mobj.x, TMapSlide.Mobj.y, ld);

  lineangle := TRendererMain.R_PointToAngle2(0, 0, ld.dx, ld.dy);

  if side = 1 then
    lineangle := lineangle + ANG180;

  moveangle := TRendererMain.R_PointToAngle2(0, 0, TMapSlide.XMove, TMapSlide.YMove);
  deltaangle := moveangle - lineangle;

  if deltaangle > ANG180 then
    deltaangle := deltaangle + ANG180;
    //  I_Error ("SlideLine: ang>ANG180");

  {$IFDEF FPC}
  lineangle := _SHRW(lineangle, ANGLETOFINESHIFT);
  deltaangle := _SHRW(deltaangle, ANGLETOFINESHIFT);
  {$ELSE}
  lineangle := lineangle shr ANGLETOFINESHIFT;
  deltaangle := deltaangle shr ANGLETOFINESHIFT;
  {$ENDIF}

  movelen := P_AproxDistance(TMapSlide.XMove, TMapSlide.YMove);
  newlen := FixedMul(movelen, finecosine[deltaangle]);

  TMapSlide.XMove := FixedMul(newlen, finecosine[lineangle]);
  TMapSlide.YMove := FixedMul(newlen, finesine[lineangle]);
end;

//==============================================================================
//
// PTR_SlideTraverse
//
//==============================================================================
function PTR_SlideTraverse(intr: Pintercept_t): boolean;
var
  li: Pline_t;
  margin: integer;

  procedure isblocking;
  begin
    // the line does block movement,
    // see if it is closer than best so far
    if intr.frac < TMapSlide.BestFrac then
    begin
      TMapSlide.BestFrac := intr.frac;
      TMapSlide.BestLine := li;
    end;
  end;

begin
  if not intr.isaline then
    I_Error('PTR_SlideTraverse(): not a line?');

  li := intr.d.line;

  if li.flags and ML_TWOSIDED = 0 then
  begin
    if P_PointOnLineSide(TMapSlide.Mobj.x, TMapSlide.Mobj.y, li) <> 0 then
    begin
      // don't hit the back side
      result := true;
      exit;
    end;
    isblocking;
    result := false; // stop
    exit;
  end;

  // set openrange, opentop, openbottom
  P_LineOpening(li, true);

  if openrange < TMapSlide.Mobj.height then
  begin
    isblocking; // doesn't fit
    result := false; // stop
    exit;
  end;

  if opentop - TMapSlide.Mobj.z < TMapSlide.Mobj.height then
  begin
    isblocking; // mobj is too high
    result := false; // stop
    exit;
  end;

  if TMapSlide.Mobj.flags4_ex and MF4_EX_CANNOTSTEP <> 0 then
    margin := 0
  else
  begin
    margin := TMapGameRules.SlideStepMargin;
    if G_PlayingEngineVersion >= VERSION207 then
      if TMapSlide.Mobj.info.maxstepheight > 0 then
      begin
        margin := TMapSlide.Mobj.info.maxstepheight;
        if margin < 64 then
          margin := margin * FRACUNIT
      end;
  end;

  if openbottom - TMapSlide.Mobj.z > margin then
  begin
    isblocking; // too big a step up
    result := false; // stop
    exit;
  end;

  // this line doesn't block movement
  result := true;
end;

//==============================================================================
//
// P_SlideMove
// The momx / momy move is bad, so try to slide
// along a wall.
// Find the first line hit, move flush to it,
// and slide along it
//
// This is a kludgy mess.
//
//==============================================================================
procedure P_SlideMove(mo: Pmobj_t);
var
  leadx: fixed_t;
  leady: fixed_t;
  trailx: fixed_t;
  traily: fixed_t;
  newx: fixed_t;
  newy: fixed_t;
  hitcount: integer;

  procedure stairstep;
  begin
    if not P_TryMove(mo, mo.x, mo.y + mo.momy) then
      P_TryMove(mo, mo.x + mo.momx, mo.y);
  end;

begin
  TMapSlide.Mobj := mo;
  hitcount := 0;

  repeat
    inc(hitcount);

    if hitcount = 3 then
    begin
      stairstep;
      exit;  // don't loop forever
    end;

    // trace along the three leading corners
    if mo.momx > 0 then
    begin
      leadx := mo.x + mo.radius;
      trailx := mo.x - mo.radius;
    end
    else
    begin
      leadx := mo.x - mo.radius;
      trailx := mo.x + mo.radius;
    end;

    if mo.momy > 0 then
    begin
      leady := mo.y + mo.radius;
      traily := mo.y - mo.radius;
    end
    else
    begin
      leady := mo.y - mo.radius;
      traily := mo.y + mo.radius;
    end;

    TMapSlide.BestFrac := FRACUNIT + 1;

    P_PathTraverse(leadx, leady, leadx + mo.momx, leady + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);
    P_PathTraverse(trailx, leady, trailx + mo.momx, leady + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);
    P_PathTraverse(leadx, traily, leadx + mo.momx, traily + mo.momy,
      PT_ADDLINES, PTR_SlideTraverse);

    // move up to the wall
    if TMapSlide.BestFrac = FRACUNIT + 1 then
    begin
      // the move most have hit the middle, so stairstep
      stairstep;
      exit;
    end;

    // fudge a bit to make sure it doesn't hit
    TMapSlide.BestFrac := TMapSlide.BestFrac - $800;
    if TMapSlide.BestFrac > 0 then
    begin
      newx := FixedMul(mo.momx, TMapSlide.BestFrac);
      newy := FixedMul(mo.momy, TMapSlide.BestFrac);

      if not P_TryMove(mo, mo.x + newx, mo.y + newy) then
      begin
        stairstep;
        exit;
      end;
    end;

    // Now continue along the wall.
    // First calculate remainder.
    TMapSlide.BestFrac := FRACUNIT - (TMapSlide.BestFrac + $800);

    if TMapSlide.BestFrac > FRACUNIT then
      TMapSlide.BestFrac := FRACUNIT;

    if TMapSlide.BestFrac <= 0 then
      exit;

    TMapSlide.XMove := FixedMul(mo.momx, TMapSlide.BestFrac);
    TMapSlide.YMove := FixedMul(mo.momy, TMapSlide.BestFrac);

    P_HitSlideLine(TMapSlide.BestLine);  // clip the moves

    mo.momx := TMapSlide.XMove;
    mo.momy := TMapSlide.YMove;

  until P_TryMove(mo, mo.x + TMapSlide.XMove, mo.y + TMapSlide.YMove);

end;

//
// P_LineAttack
// (its state is in TMapAim)
//

// JVAL: 3d floors : Moved from P_Sight

//==============================================================================
//
// PTR_AimTraverse
// Sets linetaget and TMapAim.AimSlope when a target is aimed at.
//
//==============================================================================
function PTR_AimTraverse(intr: Pintercept_t): boolean;
var
  li: Pline_t;
  th: Pmobj_t;
  slope: fixed_t;
  thingtopslope: fixed_t;
  thingbottomslope: fixed_t;
  dist: fixed_t;
begin
  if intr.isaline then
  begin
    li := intr.d.line;

    if li.flags and ML_TWOSIDED = 0 then
    begin
      result := false; // stop
      exit;
    end;

    if li.backsector = nil then
    begin
      result := false; // stop
      exit;
    end;

    // Crosses a two sided line.
    // A two sided line will restrict
    // the possible target ranges.
    P_LineOpening(li, false); // JVAL: 3dFloors We do not aim at the side of the midsec

    if openbottom >= opentop then
    begin
      result := false; // stop
      exit;
    end;

    dist := FixedMul(TMapAim.AttackRange, intr.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - TMapAim.ShootZ, dist);
      if slope > TMapAim.BottomSlope then
        TMapAim.BottomSlope := slope;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - TMapAim.ShootZ, dist);
      if slope < TMapAim.TopSlope then
        TMapAim.TopSlope := slope;
    end;

    if TMapAim.TopSlope <= TMapAim.BottomSlope then
    begin
      result := false; // stop
      exit;
    end;

    result := true;  // shot continues
    exit;
  end;

  // shoot a thing
  th := intr.d.thing;
  if th = TMapAim.ShootThing then
  begin
    result := true;  // can't shoot self
    exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    result := true; // corpse or something
    exit;
  end;

  // killough 7/19/98, 8/2/98:
  // friends don't aim at friends (except players), at least not first
  if (th.flags2_ex and TMapAim.ShootThing.flags2_ex and TMapAim.AimFlagsMask2Ex <> 0) and (th.player = nil) then
  begin
    result := true; // corpse or something
    exit;
  end;

  // JVAL: 20210210 - MF3_EX_NOTAUTOAIMED flag
  if th.flags3_ex and MF3_EX_NOTAUTOAIMED <> 0 then
  begin
    result := true; // Do not subject actor to autoaim
    exit;
  end;

  if TMapGameRules.SkipsAimAt(th) then
  begin
    result := true;
    exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(TMapAim.AttackRange, intr.frac);
  thingtopslope := FixedDiv(th.z + th.height - TMapAim.ShootZ, dist);

  if thingtopslope < TMapAim.BottomSlope then
  begin
    result := true; // shot over the thing
    exit;
  end;

  thingbottomslope := FixedDiv(th.z - TMapAim.ShootZ, dist);

  if thingbottomslope > TMapAim.TopSlope then
  begin
    result := true; // shot under the thing
    exit;
  end;

  // this thing can be hit!
  if thingtopslope > TMapAim.TopSlope then
    thingtopslope := TMapAim.TopSlope;

  if thingbottomslope < TMapAim.BottomSlope then
    thingbottomslope := TMapAim.BottomSlope;

  TMapAim.AimSlope := (thingtopslope + thingbottomslope) div 2;
  TMapAim.LineTarget := th;

  result := false; // don't go any farther
end;

//==============================================================================
//
// PTR_ShootTraverse
//
//==============================================================================
function PTR_ShootTraverse(intr: Pintercept_t): boolean;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  frac: fixed_t;
  li: Pline_t;
  th: Pmobj_t;
  slope: fixed_t;
  dist: fixed_t;
  thingtopslope: fixed_t;
  thingbottomslope: fixed_t;
  mid: Psector_t;  // JVAL: 3d Floors
  midn: integer;

  function hitline(const check3dfloors: boolean): boolean;
  var
    zoffs: fixed_t;
    midfront: Psector_t;
    midback: Psector_t;
    ok: boolean;
  begin
    if check3dfloors then
    begin
      // JVAL: 3d Floors
      if li.frontsector.midsec >= 0 then
        midfront := @sectors[li.frontsector.midsec]
      else
        midfront := nil;

      if li.backsector.midsec >= 0 then
        midback := @sectors[li.backsector.midsec]
      else
        midback := nil;

      if (midfront <> nil) or (midback <> nil) then
      begin
        if midfront = nil then
        begin
          midfront := midback;
          midback := nil;
        end;
        ok := true;
        if (FixedDiv(midfront.ceilingheight - TMapAim.ShootZ, dist) <= TMapAim.AimSlope) or
           (FixedDiv(midfront.floorheight - TMapAim.ShootZ, dist) >= TMapAim.AimSlope) then
        else
          ok := false;
        if midback <> nil then
        begin
          if (FixedDiv(midback.ceilingheight - TMapAim.ShootZ, dist) <= TMapAim.AimSlope) or
             (FixedDiv(midback.floorheight - TMapAim.ShootZ, dist) >= TMapAim.AimSlope) then
            ok := true
          else
            ok := false;
        end;
        if ok then
        begin
          result := true;
          exit;
        end;
      end;
    end;

    // hit line
    // position a bit closer
    frac := intr.frac - FixedDiv(4 * FRACUNIT, TMapAim.AttackRange);
    x := trace.x + FixedMul(trace.dx, frac);
    y := trace.y + FixedMul(trace.dy, frac);
    z := TMapAim.ShootZ + FixedMul(TMapAim.AimSlope, FixedMul(frac, TMapAim.AttackRange));

    if li.frontsector.ceilingpic = skyflatnum then
    begin
      // don't shoot the sky!
      if z > li.frontsector.ceilingheight then
      begin
        result := false;
        exit;
      end;

      // it's a sky hack wall
      if (li.backsector <> nil) and (li.backsector.ceilingpic = skyflatnum) then
      begin
        if li.backsector.ceilingheight < z then
        begin
          result := false;
          exit;
        end;
      // JVAL: Spawn puff to lower textures.
        // Doom spawns the puff out of the compatibility mode and always stops the shot here;
        // the other games spawn it in the compatibility mode, and only then the shot stops here
        if G_NeedsCompatibilityMode = TMapGameRules.SkyHackPuffInCompatibility then
        begin
          P_SaveRandom;
          zoffs := (li.backsector.ceilingheight - z) * P_Random div 256;
          if zoffs > dist div 2 then
            zoffs := dist div 2;
          P_SpawnPuff(x, y, z + zoffs);
          P_RestoreRandom;
          result := false;
          exit;
        end;
        if not TMapGameRules.SkyHackPuffInCompatibility then
        begin
          result := false;
          exit;
        end;
      end;
    end;
    // Spawn bullet puffs.
    TMapGameRules.SpawnWallPuff(x, y, z);

    // don't go any farther
    result := false;
  end;

begin
  if intr.isaline then
  begin
    li := intr.d.line;

    if li.flags and ML_TRIGGERSCRIPTS <> 0 then
      if TMapAim.ShootThing.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
        PS_EventShootLine(TMapAim.ShootThing, pDiff(li, lines, SizeOf(line_t)), P_PointOnLineSide(TMapAim.ShootThing.x, TMapAim.ShootThing.y, li));

    if li.special <> 0 then
      TMapGameRules.ShootSpecialLine(TMapAim.ShootThing, li);

    if li.flags and ML_TWOSIDED = 0 then
    begin
      result := hitline(false);
      exit;
    end;

    if li.backsector = nil then
    begin
      result := hitline(false);
      exit;
    end;

    // crosses a two sided line
    P_LineOpening(li, false);

    dist := FixedMul(TMapAim.AttackRange, intr.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - TMapAim.ShootZ, dist);
      if slope > TMapAim.AimSlope then
      begin
        result := hitline(true);
        exit;
      end;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - TMapAim.ShootZ, dist);
      if slope < TMapAim.AimSlope then
      begin
        result := hitline(true);
        exit;
      end;
    end;

    // shot continues
    result := true;
    exit;
  end;

  // shoot a thing
  th := intr.d.thing;
  if th = TMapAim.ShootThing then
  begin
    result := true; // can't shoot self
    exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    result := true; // corpse or something
    exit;
  end;

  if TMapGameRules.ShotPassesThrough(th) then
  begin
    result := true;
    exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(TMapAim.AttackRange, intr.frac);
  thingtopslope := FixedDiv(th.z + th.height - TMapAim.ShootZ, dist);

  if thingtopslope < TMapAim.AimSlope then
  begin
    result := true; // shot over the thing
    exit;
  end;

  thingbottomslope := FixedDiv(th.z - TMapAim.ShootZ, dist);

  if thingbottomslope > TMapAim.AimSlope then
  begin
    result := true; // shot under the thing
    exit;
  end;

  // JVAL: 3d Floors
  // Can not shoot if in same subsector but different floor
  if TMapAim.ShootThing.subsector = th.subsector then
  begin
    midn := Psubsector_t(TMapAim.ShootThing.subsector).sector.midsec;

    if midn > -1 then
    begin
      mid := @sectors[midn];
      if ((TMapAim.ShootZ <= mid.floorheight) and (th.z >= mid.ceilingheight)) or
         ((th.z + th.height <= mid.floorheight) and (TMapAim.ShootZ >= mid.ceilingheight)) then
      begin
        result := false;
        exit;
      end;
    end;
  end;

  // hit thing
  // position a bit closer
  frac := intr.frac - FixedDiv(10 * FRACUNIT, TMapAim.AttackRange);

  x := trace.x + FixedMul(trace.dx, frac);
  y := trace.y + FixedMul(trace.dy, frac);
  z := TMapAim.ShootZ + FixedMul(TMapAim.AimSlope, FixedMul(frac, TMapAim.AttackRange));

  // Puff or blood, and the damage: never goes any farther
  result := TMapGameRules.ShotHitsThing(intr, th, x, y, z);
end;

//==============================================================================
//
// P_AimLineAttack
//
//==============================================================================
function P_AimLineAttack(t1: Pmobj_t; angle: angle_t; distance: fixed_t; mask2_ex: integer = 0): fixed_t;
var
  x2: fixed_t;
  y2: fixed_t;
begin
  {$IFDEF FPC}
  angle := _SHRW(angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  TMapAim.ShootThing := t1;

  x2 := t1.x + FixedInt(distance) * finecosine[angle];
  y2 := t1.y + FixedInt(distance) * finesine[angle];
  TMapAim.ShootZ := TMapGameRules.AimOriginZ(t1);

  // can't shoot outside view angles
  TMapAim.TopSlope := (100 * FRACUNIT) div 160;
  TMapAim.BottomSlope := -TMapAim.TopSlope; // JVAL

  TMapAim.AttackRange := distance;
  TMapAim.LineTarget := nil;

  // killough 8/2/98: prevent friends from aiming at friends
  TMapAim.AimFlagsMask2Ex := mask2_ex;

  P_PathTraverse(t1.x, t1.y, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_AimTraverse);

  if TMapAim.LineTarget <> nil then
    result := TMapAim.AimSlope
  else
    result := TMapGameRules.NoTargetSlope(t1);
end;

//==============================================================================
//
// P_LineAttack
// If damage == 0, it is just a test trace
// that will leave TMapAim.LineTarget set.
//
//==============================================================================
procedure P_LineAttack(t1: Pmobj_t; angle: angle_t;
  distance: fixed_t; slope: fixed_t; damage: integer);
var
  x2: fixed_t;
  y2: fixed_t;
begin
  {$IFDEF FPC}
  angle := _SHRW(angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := angle shr ANGLETOFINESHIFT;
  {$ENDIF}
  TMapAim.ShootThing := t1;
  TMapAim.Damage := damage;
  x2 := t1.x + FixedInt(distance) * finecosine[angle];
  y2 := t1.y + FixedInt(distance) * finesine[angle];
  TMapAim.ShootZ := TMapGameRules.AttackOriginZ(t1);
  TMapAim.AttackRange := distance;
  TMapAim.AimSlope := slope;

  if P_PathTraverse(t1.x, t1.y, x2, y2, TMapGameRules.LineAttackFlags(damage), PTR_ShootTraverse) then
    TMapGameRules.LineAttackMissed(t1, x2, y2, slope, distance);
end;

//
// USE LINES
//
//==============================================================================
//
// PTR_UseTraverse
//
//==============================================================================
function PTR_UseTraverse(intr: Pintercept_t): boolean;
var
  side: integer;
  li: Pline_t;
begin
  side := P_PointOnLineSide(TMapUse.Thing.x, TMapUse.Thing.y, intr.d.line);
  li := intr.d.line;

  if li.flags and ML_TRIGGERSCRIPTS <> 0 then
    if TMapUse.Thing.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
      PS_EventUseLine(TMapUse.Thing, pDiff(li, lines, SizeOf(line_t)), side);

  if li.special = 0 then
  begin
    P_LineOpening(li, true);
    if openrange <= 0 then
    begin
      TMapGameRules.UseBlockedByWall(TMapUse.Thing);
      // can't use through a wall
      result := false;
      exit;
    end;
    TMapGameRules.UseNonSpecialLine(TMapUse.Thing);
    // not a special line, but keep checking
    result := true;
    exit;
  end;

  result := TMapGameRules.UseSpecialLine(TMapUse.Thing, li, side);
end;

//==============================================================================
// PTR_UseThingTraverse
//
// JVAL: mobjs interaction
//
//==============================================================================
function PTR_UseThingTraverse(intr: Pintercept_t): boolean;
var
  mobj: Pmobj_t;
  p: Pplayer_t;
begin
  if intr.isaline then
    if intr.d.line.flags and ML_TWOSIDED <> 0 then
    begin
      P_LineOpening(intr.d.line, true);
      if openrange <= 0 then
      begin
        // can't use through a wall
        result := false;
        Exit;
      end;
      // not a special line, but keep checking
      result := true;
      Exit;
    end
    else
    begin
      result := True;
      exit;
    end;

  mobj := intr.d.thing;
  if mobj.health <= 0 then
  begin
    result := true;
    exit;
  end;
  if mobj.flags2_ex and MF2_EX_INTERACTIVE = 0 then
  begin
    result := true;
    exit;
  end;
  if mobj.info.interactstate <= 0 then
  begin
    result := true;
    exit;
  end;
  // Height.
  if (TMapUse.Thing.z >= mobj.z + mobj.height) or
     (TMapUse.Thing.z + TMapUse.Thing.height <= mobj.z) then
  begin
    result := true;
    exit;
  end;
  mobj.target := TMapUse.Thing;
  P_SetMobjState(mobj, statenum_t(mobj.info.interactstate));
  p := TMapUse.Thing.player;
  if p <> nil then
    if G_PlayingEngineVersion >= VERSION207 then
      p.nextfire := TTickState.LevelTime + TICRATE div 2;
  result := false;
end;

//==============================================================================
//
// P_UseLines
// Looks for special lines in front of the player to activate.
//
//==============================================================================
procedure P_UseLines(player: Pplayer_t);
var
  angle: angle_t;
  x1: fixed_t;
  y1: fixed_t;
  x2: fixed_t;
  y2: fixed_t;
begin
  TMapUse.Thing := player.mo;

  {$IFDEF FPC}
  angle := _SHRW(player.mo.angle, ANGLETOFINESHIFT);
  {$ELSE}
  angle := player.mo.angle shr ANGLETOFINESHIFT;
  {$ENDIF}

  x1 := player.mo.x;
  y1 := player.mo.y;

  // JVAL: mobjs interaction!
  x2 := x1 + USETHINGRANGEINT * finecosine[angle];
  y2 := y1 + USETHINGRANGEINT * finesine[angle];
  P_PathTraverse(x1, y1, x2, y2, PT_ADDLINES or PT_ADDTHINGS, PTR_UseThingTraverse);

  x2 := x1 + USERANGEINT * finecosine[angle];
  y2 := y1 + USERANGEINT * finesine[angle];

  P_PathTraverse(x1, y1, x2, y2, PT_ADDLINES, PTR_UseTraverse);
end;

//
// RADIUS ATTACK
//
//==============================================================================
//
// PIT_RadiusAttack
// "TMapBlast.Source" is the creature
// that caused the explosion at "TMapBlast.Spot".
//
//==============================================================================
function PIT_RadiusAttack(thing: Pmobj_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  dist: fixed_t;
begin
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    result := true;
    exit;
  end;

  if TCommonFriendActions.P_SplashImmune(thing, TMapBlast.Spot) then
  begin
    result := true;
    exit;
  end;

  // The bosses of the game take no damage from concussion.
  if TMapGameRules.IsConcussionProof(thing) then
  begin
    result := true;
    exit;
  end;

  // Other bosses
  if thing.flags_ex and MF_EX_BOSS <> 0 then
  begin
    result := true;
    exit;
  end;

  if thing.flags_ex and MF_EX_NORADIUSDMG <> 0 then
  begin
    if TMapBlast.Source <> nil then
    begin
      if TMapBlast.Source.flags4_ex and MF4_EX_FORCERADIUSDMG = 0 then
      begin
        result := true;
        exit;
      end;
    end
    else
    begin
      result := true;
      exit;
    end;
  end;

  if TMapGameRules.OutOfBlast(thing, TMapBlast.Spot, TMapBlast.Source) then
  begin
    result := true;
    exit;
  end;

  if TMapBlast.Source <> nil then
  begin
    if TMapBlast.Source.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then
      begin
        result := true;
        exit;
      end;

    if TMapBlast.Source.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then
      begin
        result := true;
        exit;
      end;

    if thing.player = nil then
      if TMapBlast.Source.info.doomednum > 0 then
      begin
        if TMapBlast.Source.flags_ex and MF_EX_DONTHURTSPECIES <> 0 then
          if Info_GetInheritance(thing.info) = Info_GetInheritance(TMapBlast.Source.info) then
          begin
            result := true;
            exit;
          end;
      end;
  end;

  dx := abs(thing.x - TMapBlast.Spot.x);
  dy := abs(thing.y - TMapBlast.Spot.y);

  if dx > dy then
    dist := dx
  else
    dist := dy;
  dist := FixedInt(dist - thing.radius);

  if dist < 0 then
    dist := 0;

  if dist >= TMapBlast.Damage then
  begin
    result := true; // out of range
    exit;
  end;

  if P_CheckSight(thing, TMapBlast.Spot) then
  begin
    // must be in direct path
    P_DamageMobj(thing, TMapBlast.Spot, TMapBlast.Source, TMapGameRules.BlastDamage(thing, TMapBlast.Damage, dist));
  end;

  result := true;
end;

//==============================================================================
//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//
//==============================================================================
procedure P_RadiusAttack(spot: Pmobj_t; source: Pmobj_t; const damage: integer;
  const distance: integer = 0; const dmsource: boolean = true);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := (damage + MAXRADIUS) * FRACUNIT;
  if internalblockmapformat then
  begin
    yh := MapBlockIntY(int64(spot.y) + int64(dist) - int64(bmaporgy));
    yl := MapBlockIntY(int64(spot.y) - int64(dist) - int64(bmaporgy));
    xh := MapBlockIntX(int64(spot.x) + int64(dist) - int64(bmaporgx));
    xl := MapBlockIntX(int64(spot.x) - int64(dist) - int64(bmaporgx));
  end
  else
  begin
    yh := MapBlockInt(spot.y + dist - bmaporgy);
    yl := MapBlockInt(spot.y - dist - bmaporgy);
    xh := MapBlockInt(spot.x + dist - bmaporgx);
    xl := MapBlockInt(spot.x - dist - bmaporgx);
  end;

  TMapBlast.Spot := spot;
  TMapBlast.Source := source;
  TMapBlast.Damage := damage;
  TMapGameRules.SetBlastExtent(distance, dmsource);

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_RadiusAttack);

  TMapGameRules.AfterRadiusAttack(spot, dist);
end;

//==============================================================================
// P_RadiusAttackEx
//
// P_RadiusAttack
// Source is the creature that caused the explosion at spot.
//
//==============================================================================
procedure P_RadiusAttackEx(spot: Pmobj_t; source: Pmobj_t; const damage, distance: integer);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := distance * FRACUNIT;
  if internalblockmapformat then
  begin
    yh := MapBlockIntY(int64(spot.y) + int64(dist) - int64(bmaporgy));
    yl := MapBlockIntY(int64(spot.y) - int64(dist) - int64(bmaporgy));
    xh := MapBlockIntX(int64(spot.x) + int64(dist) - int64(bmaporgx));
    xl := MapBlockIntX(int64(spot.x) - int64(dist) - int64(bmaporgx));
  end
  else
  begin
    yh := MapBlockInt(spot.y + dist - bmaporgy);
    yl := MapBlockInt(spot.y - dist - bmaporgy);
    xh := MapBlockInt(spot.x + dist - bmaporgx);
    xl := MapBlockInt(spot.x - dist - bmaporgx);
  end;

  TMapBlast.Spot := spot;
  TMapBlast.Source := source;
  TMapBlast.Damage := damage;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_RadiusAttack);

  TMapGameRules.AfterRadiusAttack(spot, dist);
end;

//==============================================================================
//
// PIT_RadiusAttackPlayer
//
//==============================================================================
function PIT_RadiusAttackPlayer(thing: Pmobj_t): boolean;
var
  dx: fixed_t;
  dy: fixed_t;
  dist: fixed_t;
  cl: fixed_t;
  damage: integer;
begin
  if thing.player = nil then
  begin
    result := true;
    exit;
  end;

  if TCommonFriendActions.P_SplashImmune(thing, TMapBlast.Spot) then
  begin
    result := true;
    exit;
  end;

  dx := abs(thing.x - TMapBlast.Spot.x);
  dy := abs(thing.y - TMapBlast.Spot.y);

  if dx > dy then
    dist := dx
  else
    dist := dy;
  dist := FixedInt(dist - thing.radius);

  if dist < 0 then
    dist := 0;

  if dist >= TMapBlast.Radius then
  begin
    result := true; // out of range
    exit;
  end;

  if thing.flags_ex and MF_EX_NORADIUSDMG <> 0 then
  begin
    if TMapBlast.Source <> nil then
    begin
      if TMapBlast.Source.flags4_ex and MF4_EX_FORCERADIUSDMG = 0 then
      begin
        result := true;
        exit;
      end;
    end
    else
    begin
      result := true;
      exit;
    end;
  end;

  if TMapBlast.Source.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then
    if thing.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then
    begin
      result := true;
      exit;
    end;

  if TMapBlast.Source.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then
    if thing.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then
    begin
      result := true;
      exit;
    end;

  if P_CheckSight(thing, TMapBlast.Spot) then
  begin
    // must be in direct path
    if TMapBlast.Radius = 0 then
      P_DamageMobj(thing, TMapBlast.Spot, TMapBlast.Source, TMapBlast.Damage)
    else
    begin
      cl := FixedDiv((TMapBlast.Radius - dist) * FRACUNIT, TMapBlast.Radius * FRACUNIT);
      damage := FixedInt(FixedMul(TMapBlast.Damage * FRACUNIT, cl));
      if damage < 1 then
        damage := 1;
      P_DamageMobj(thing, TMapBlast.Spot, TMapBlast.Source, damage);
    end;
  end;

  result := true;
end;

//==============================================================================
//
// P_RadiusAttackPlayer
//
//==============================================================================
procedure P_RadiusAttackPlayer(spot: Pmobj_t; source: Pmobj_t; const damage, distance: integer);
var
  x: integer;
  y: integer;
  xl: integer;
  xh: integer;
  yl: integer;
  yh: integer;
  dist: fixed_t;
begin
  dist := distance * FRACUNIT;
  if internalblockmapformat then
  begin
    yh := MapBlockIntY(int64(spot.y) + int64(dist) - int64(bmaporgy));
    yl := MapBlockIntY(int64(spot.y) - int64(dist) - int64(bmaporgy));
    xh := MapBlockIntX(int64(spot.x) + int64(dist) - int64(bmaporgx));
    xl := MapBlockIntX(int64(spot.x) - int64(dist) - int64(bmaporgx));
  end
  else
  begin
    yh := MapBlockInt(spot.y + dist - bmaporgy);
    yl := MapBlockInt(spot.y - dist - bmaporgy);
    xh := MapBlockInt(spot.x + dist - bmaporgx);
    xl := MapBlockInt(spot.x - dist - bmaporgx);
  end;

  TMapBlast.Spot := spot;
  TMapBlast.Source := source;
  TMapBlast.Damage := damage;
  TMapBlast.Radius := distance;

  for y := yl to yh do
    for x := xl to xh do
      P_BlockThingsIterator(x, y, PIT_RadiusAttackPlayer);
end;

//
// SECTOR HEIGHT CHANGING
// After modifying a sectors floor or ceiling height,
// call this routine to adjust the positions
// of all things that touch the sector.
//
// If anything doesn't fit anymore, true will be returned.
// If crunch is true, they will take damage
//  as they are being crushed.
// If Crunch is false, you should set the sector height back
//  the way it was and call P_ChangeSector again
//  to undo the changes.
//

//==============================================================================
//
// PIT_ChangeSector
//
//==============================================================================
function PIT_ChangeSector(thing: Pmobj_t): boolean;
begin
  if P_ThingHeightClip(thing) then
  begin
    // keep checking
    result := true;
    exit;
  end;

  // JVAL: 20200329 - New flag, can not be crushed by sector
  if thing.flags3_ex and MF3_EX_NOCRUSH <> 0 then
  begin
    result := true;
    exit;
  end;

  // crunch bodies to giblets
  if TMapGameRules.IsCrushedBody(thing) then
  begin
    result := TMapGameRules.CrunchBody(thing);
    exit;
  end;

  // crunch dropped items
  if TMapGameRules.IsDroppedItem(thing) then
  begin
    P_RemoveMobj(thing);

    // keep checking
    result := true;
    exit;
  end;

  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    // assume it is bloody gibs or something
    result := true;
    exit;
  end;

  TMapCheck.NoFit := true;

  if TMapCheck.CrushChange and (TTickState.LevelTime and 3 = 0) then
  begin
    P_DamageMobj(thing, nil, nil, TMapGameRules.CrushDamage);

    TMapGameRules.CrushBlood(thing);
  end;

  // keep checking (crush other things)
  result := true;
end;
//==============================================================================
// P_DoChangeSector
//
// P_ChangeSector
//
//==============================================================================
procedure P_DoChangeSector(sector: Psector_t; crunch: boolean);
var
  x: integer;
  y: integer;
  pbox: PIntegerArray;
begin
  // The games with the lists of the things of a sector (Boom) walk those lists, out of the
  // compatibility mode; the others, and the compatibility mode, walk the blockmap
  if not TMapGameRules.ChangeSectorByThingList(sector) then
  begin
    // re-check heights for all things near the moving sector
    pbox := @sector.blockbox;
    for x := pbox[BOX_LEFT] to pbox[BOX_RIGHT] do
      for y := pbox[BOX_BOTTOM] to pbox[BOX_TOP] do
        P_BlockThingsIterator(x, y, PIT_ChangeSector);
  end;
end;

//==============================================================================
//
// P_ChangeSector
//
//==============================================================================
function P_ChangeSector(sector: Psector_t; crunch: boolean): boolean;
var
  i: integer;
begin
  TMapCheck.NoFit := false;
  TMapCheck.CrushChange := crunch;

  if (G_PlayingEngineVersion >= TMapGameRules.SlopesVersion) and (sector.num_saffectees > 0) then
  begin
    for i := 0 to sector.num_saffectees - 1 do
      P_DoChangeSector(@sectors[sector.saffectees[i]], crunch);
  end
  else
    P_DoChangeSector(sector, crunch);

  result := TMapCheck.NoFit;
end;

//==============================================================================
// P_SectorJumpOverhead
//
// JVAL Allow jumps in sectors with sky ceiling.... (7/8/2007)
//
//==============================================================================
function P_SectorJumpOverhead(const s: Psector_t; const p: Pplayer_t = nil): integer;
begin
  // JVAL: 3d floors
  if s.midsec >= 0 then
  begin
    result := 0;
    Exit;
  end;

  if s.ceilingpic = skyflatnum then
  begin
    if p <> nil then
      if TMapGameRules.HasFlightPower(p) then
      begin
        result := 0;
        exit;
      end;
    if not G_NeedsCompatibilityMode then
    begin
      // JVAL: 20200107 - No just overhead for version > 205
      if G_PlayingEngineVersion <= VERSION204 then
        result := 128 * FRACUNIT
      else
        result := 0;
      exit;
    end;
  end;
  result := 0;
end;

//==============================================================================
//
// FUNC P_TestMobjLocation
//
// Returns true if the mobj is not blocked by anything at its current
// location, otherwise returns false.
//
//
//==============================================================================
function P_TestMobjLocation(mobj: Pmobj_t): boolean;
var
  flags: integer;
begin
  flags := TMapGameRules.SuspendPickup(mobj);
  if P_CheckPosition(mobj, mobj.x, mobj.y) then
  begin // XY is ok, now check Z
    TMapGameRules.RestorePickup(mobj, flags);
    if (mobj.z < mobj.floorz) or
       (mobj.z + mobj.height > mobj.ceilingz) then
    begin // Bad Z
      result := false;
      exit;
    end;
    result := true;
    exit;
  end;
  TMapGameRules.RestorePickup(mobj, flags);
  result := false;
end;

end.
