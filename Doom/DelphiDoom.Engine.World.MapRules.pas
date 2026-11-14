{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Doom for movement and collisions (p_map)  }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.MapRules;

interface

uses
  doomdef,
  m_fixed,
  p_local,
  p_mobj_h,
  d_player,
  r_defs;

type
  bloodtype_t = (bt_puff, bt_red, bt_blue, bt_green);
  /// <summary>
  ///   What Doom does differently in the movement and collision code of p_map. The unit of the
  ///   same name in the folder of each game is chosen by the project, so the calls are bound at
  ///   compile time: no virtual call and no interface, this is the path of every moving thing
  /// </summary>
  /// <remarks>
  ///   The bodies are the lines of the old Doom\p_map.pas, moved as they were: the methods keep
  ///   the names of the parameters and the style of the routine they come from
  /// </remarks>
  TMapGameRules = class sealed
  public
    const
      /// <summary>First version that checks the lines with the slopes and moves the sectors that depend on another</summary>
      SlopesVersion = VERSION122;
      /// <summary>A teleported thing is put on the floor of the destination</summary>
      TeleportSetsZ = False;
      /// <summary>The step a sliding thing climbs</summary>
      SlideStepMargin = 24 * FRACUNIT;

    /// <summary>The sector of a point (Doom follows the original nodes while an old demo plays)</summary>
    class function PointInSector(const x, y: fixed_t): Psector_t; static; inline;
    /// <summary>The thing being teleported (tmthing) may kill the thing in its way</summary>
    class function CanStomp(thing: Pmobj_t): boolean; static;
    /// <summary>Marks a thing that has just been teleported (the renderer does not interpolate it)</summary>
    class procedure MarkJustAppeared(thing: Pmobj_t); static; inline;
    /// <summary>The player flies: no room for a jump is added under the sky</summary>
    class function HasFlightPower(const p: Pplayer_t): boolean; static; inline;
    /// <summary>The two things overlap in height</summary>
    class function ThingsInSameZ(const A, B: Pmobj_t): boolean; static;
    /// <summary>What P_CheckPosition clears before it starts (Strife: the blocking line)</summary>
    class procedure BeginCheckPosition; static; inline;
    /// <summary>A thing with these flags is checked against nothing</summary>
    class function NoClipSkipsThings(const AFlags: integer): boolean; static; inline;
    /// <summary>A thing with these flags, checked against the things, is not checked against the lines</summary>
    class function NoClipSkipsLines(const AFlags: integer): boolean; static; inline;
    /// <summary>Forgets the thing that blocked the last check (only Hexen keeps it)</summary>
    class procedure ClearBlockingThing; static; inline;
    /// <summary>The thing is a monster thrown at its target (Strife has none)</summary>
    class function IsSkullFlying(mo: Pmobj_t): boolean; static; inline;
    /// <summary>The fake z movement bobs a flying player</summary>
    class function FlightBobs(mo: Pmobj_t): boolean; static; inline;
    /// <summary>The thing falls with low gravity</summary>
    class function HasLowGravity(mo: Pmobj_t): boolean; static; inline;
    /// <summary>Keeps in the thing the floor it stands on (only Hexen has the field)</summary>
    class procedure StoreFloorPic(thing: Pmobj_t); static; inline;
    /// <summary>A thing that was on the floor follows the floor that moved</summary>
    class function SnapsToFloor(thing: Pmobj_t): boolean; static; inline;
    /// <summary>The autoaim ignores this thing</summary>
    class function SkipsAimAt(th: Pmobj_t): boolean; static; inline;
    /// <summary>The height an aim starts from</summary>
    class function AimOriginZ(t1: Pmobj_t): fixed_t; static; inline;
    /// <summary>The slope of an aim that found no target</summary>
    class function NoTargetSlope(t1: Pmobj_t): fixed_t; static; inline;
    /// <summary>The height a shot starts from</summary>
    class function AttackOriginZ(t1: Pmobj_t): fixed_t; static; inline;
    /// <summary>What a shot of this damage is traced against (PT_ADDLINES, PT_ADDTHINGS)</summary>
    class function LineAttackFlags(const damage: integer): integer; static; inline;
    /// <summary>A shot went to the end of its range and hit nothing</summary>
    class procedure LineAttackMissed(t1: Pmobj_t; x2, y2: fixed_t; slope: fixed_t;
      distance: fixed_t); static;
    /// <summary>A use was stopped by a wall</summary>
    class procedure UseBlockedByWall(usething: Pmobj_t); static;
    /// <summary>A use went through a line that is not special</summary>
    class procedure UseNonSpecialLine(usething: Pmobj_t); static;
    /// <summary>Uses a special line; true when the use goes on to the next line</summary>
    class function UseSpecialLine(usething: Pmobj_t; li: Pline_t; side: integer): boolean; static;
    /// <summary>A boss that an explosion does not hurt</summary>
    class function IsConcussionProof(thing: Pmobj_t): boolean; static; inline;
    /// <summary>Keeps the distance and the "hurts its source" of an explosion (only Hexen uses them)</summary>
    class procedure SetBlastExtent(const distance: integer; const dmsource: boolean); static;
    /// <summary>The thing is out of the reach of the explosion for a reason of the game</summary>
    class function OutOfBlast(thing, bombspot, bombsource: Pmobj_t): boolean; static;
    /// <summary>The damage of an explosion to a thing at this distance</summary>
    class function BlastDamage(thing: Pmobj_t; const bombdamage, dist: integer): integer; static;
    /// <summary>What follows an explosion (Strife breaks the glass around)</summary>
    class procedure AfterRadiusAttack(spot: Pmobj_t; dist: fixed_t); static;
    /// <summary>P_TestMobjLocation picks nothing up while it tests: takes the pickup flag away and gives the flags to put back</summary>
    class function SuspendPickup(mobj: Pmobj_t): integer; static; inline;
    /// <summary>Puts back the flags that SuspendPickup gave</summary>
    class procedure RestorePickup(mobj: Pmobj_t; const AFlags: integer); static; inline;
    /// <summary>
    ///   Rechecks the things of a sector that moved through the list of the things that touch
    ///   it; false when the caller has to walk the blockmap instead
    /// </summary>
    class function ChangeSectorByThingList(sector: Psector_t): boolean; static;
  end;

//==============================================================================
// P_CheckForPushSpecial
//
// CheckForPushSpecial
//
//==============================================================================
procedure P_CheckForPushSpecial(line: Pline_t; side: integer; mobj: Pmobj_t);

//==============================================================================
//
// PIT_ChangeSector
//
//==============================================================================
function PIT_ChangeSector(thing: Pmobj_t): boolean;

function PIT_CheckLine(ld: Pline_t): boolean;
function PIT_CheckLineTM(ld: Pline_t): boolean;
function PIT_CheckThing(thing: Pmobj_t): boolean;
function P_TryMoveGame(thing: Pmobj_t; x, y: fixed_t): boolean;
function PTR_ShootTraverse(intr: Pintercept_t): boolean;

//==============================================================================
//
// P_BloodType
//
//==============================================================================
function P_BloodType(const th: Pmobj_t): bloodtype_t;

//==============================================================================
//
// P_PointInSector
//
//==============================================================================
function P_PointInSector(const x: fixed_t; const y: fixed_t): Psector_t;

var
  p_confcoloredblood: boolean = true;
implementation

uses
  d_delphi,
  DelphiDoom.MathCore.Types,
  doomdata,
  doomstat,
  g_game,
  i_system,
  info_h,
  info,
  info_common,
  info_rnd,
  m_rnd,
  p_common,
  p_gravity,
  p_setup,
  p_map,
  p_maputl,
  p_inter,
  p_mobj,
  p_secnodes,
  p_spec,
  p_sight,
  p_3dfloors, // JVAL: 3d Floors
  p_slopes, // JVAL: Slopes
  p_switch,
  p_tick,
  p_sounds,
  p_udmf,
  udmf_spec,
  ps_main,  // JVAL: Script Events
  r_main,
  r_sky,
  r_intrpl,
  r_translations,
  s_sound,
  sounddata,
  tables,
  z_zone;

{ TMapGameRules }

class function TMapGameRules.PointInSector(const x, y: fixed_t): Psector_t;
begin
  result := P_PointInSector(x, y);
end;

class function TMapGameRules.CanStomp(thing: Pmobj_t): boolean;
begin
  // monsters don't stomp things except on boss level
  result := not ((tmthing.player = nil) and (gamemap <> 30));
end;

class procedure TMapGameRules.MarkJustAppeared(thing: Pmobj_t);
begin
  thing.flags4_ex := thing.flags4_ex or MF4_EX_JUSTAPPEARED;
end;

class function TMapGameRules.HasFlightPower(const p: Pplayer_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.ThingsInSameZ(const A, B: Pmobj_t): boolean;
var
  Az1, Az2, Bz1, Bz2: fixed_t;

  function _getheightoffs(const mo: Pmobj_t): fixed_t;
  begin
    if (G_PlayingEngineVersion < VERSION207) or ((A.flags2_ex and MF2_EX_ONMOBJ = 0) and (B.flags2_ex and MF2_EX_ONMOBJ = 0)) then
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

  if (G_PlayingEngineVersion < VERSION207) or ((A.flags2_ex and MF2_EX_ONMOBJ = 0) and (B.flags2_ex and MF2_EX_ONMOBJ = 0)) then
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

class procedure TMapGameRules.BeginCheckPosition;
begin
end;

class function TMapGameRules.NoClipSkipsThings(const AFlags: integer): boolean;
begin
  result := AFlags and MF_NOCLIP <> 0;
end;

class function TMapGameRules.NoClipSkipsLines(const AFlags: integer): boolean;
begin
  result := false;
end;

class procedure TMapGameRules.ClearBlockingThing;
begin
end;

class function TMapGameRules.IsSkullFlying(mo: Pmobj_t): boolean;
begin
  result := mo.flags and MF_SKULLFLY <> 0;
end;

class function TMapGameRules.FlightBobs(mo: Pmobj_t): boolean;
begin
  result := G_PlayingEngineVersion <= VERSION204;
end;

class function TMapGameRules.HasLowGravity(mo: Pmobj_t): boolean;
begin
  result := mo.flags_ex and MF_EX_LOWGRAVITY <> 0;
end;

class procedure TMapGameRules.StoreFloorPic(thing: Pmobj_t);
begin
end;

class function TMapGameRules.SnapsToFloor(thing: Pmobj_t): boolean;
begin
  result := true;
end;

class function TMapGameRules.SkipsAimAt(th: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.AimOriginZ(t1: Pmobj_t): fixed_t;
begin
  result := t1.z + _SHR1(t1.height) + 8 * FRACUNIT;
end;

class function TMapGameRules.NoTargetSlope(t1: Pmobj_t): fixed_t;
begin
  result := 0;
end;

class function TMapGameRules.AttackOriginZ(t1: Pmobj_t): fixed_t;
begin
  result := t1.z + _SHR1(t1.height) + 8 * FRACUNIT;
end;

class function TMapGameRules.LineAttackFlags(const damage: integer): integer;
begin
  result := PT_ADDLINES or PT_ADDTHINGS;
end;

class procedure TMapGameRules.LineAttackMissed(t1: Pmobj_t; x2, y2: fixed_t; slope: fixed_t;
  distance: fixed_t);
begin
end;

class procedure TMapGameRules.UseBlockedByWall(usething: Pmobj_t);
begin
  S_StartSound(usething, Ord(sfx_noway));
end;

class procedure TMapGameRules.UseNonSpecialLine(usething: Pmobj_t);
begin
end;

class function TMapGameRules.UseSpecialLine(usething: Pmobj_t; li: Pline_t; side: integer): boolean;
begin
  P_UseSpecialLine(usething, li, side);
  P_ActivateLine(li, usething, 0, ULAC_USE);

  // can't use for than one special line in a row
  //WAS can't use for than one special line in a row
  //jff 3/21/98 NOW multiple use allowed with enabling line flag

  result := not G_NeedsCompatibilityMode and (li.flags and ML_PASSUSE <> 0);
end;

class function TMapGameRules.IsConcussionProof(thing: Pmobj_t): boolean;
begin
  // Boss spider and cyborg
  // take no damage from concussion.
  result := (thing._type = Ord(MT_CYBORG)) or (thing._type = Ord(MT_SPIDER));
end;

class procedure TMapGameRules.SetBlastExtent(const distance: integer; const dmsource: boolean);
begin
end;

class function TMapGameRules.OutOfBlast(thing, bombspot, bombsource: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.BlastDamage(thing: Pmobj_t; const bombdamage, dist: integer): integer;
begin
  result := bombdamage - dist;
end;

class procedure TMapGameRules.AfterRadiusAttack(spot: Pmobj_t; dist: fixed_t);
begin
end;

class function TMapGameRules.SuspendPickup(mobj: Pmobj_t): integer;
begin
  result := mobj.flags;
  mobj.flags := mobj.flags and not MF_PICKUP;
end;

class procedure TMapGameRules.RestorePickup(mobj: Pmobj_t; const AFlags: integer);
begin
  mobj.flags := AFlags;
end;

class function TMapGameRules.ChangeSectorByThingList(sector: Psector_t): boolean;
begin
  result := not G_NeedsCompatibilityMode;
  if result then
    P_ChangeSectorNodes(sector);
end;

//==============================================================================
// P_CheckForPushSpecial
//
// CheckForPushSpecial
//
//==============================================================================
procedure P_CheckForPushSpecial(line: Pline_t; side: integer; mobj: Pmobj_t);
begin
  if line.special <> 0 then
  begin
    if mobj.flags5_ex and MF5_EX_PUSHWALL <> 0 then
      P_ActivateLine(line, mobj, side, ULAC_PUSH or ULAC_MPUSH)
    else if mobj.flags5_ex and MF5_EX_IMPACT <> 0 then
      P_ActivateLine(line, mobj, side, ULAC_IMPACT);
  end;
end;

//==============================================================================
//
// MOVEMENT ITERATOR FUNCTIONS
//
// PIT_CheckLine
// Adjusts tmfloorz and tmceilingz as lines are contacted
//
//==============================================================================
function PIT_CheckLine(ld: Pline_t): boolean;
begin
  if (tmbbox[BOX_RIGHT] <= ld.bbox[BOX_LEFT]) or
     (tmbbox[BOX_LEFT] >= ld.bbox[BOX_RIGHT]) or
     (tmbbox[BOX_TOP] <= ld.bbox[BOX_BOTTOM]) or
     (tmbbox[BOX_BOTTOM] >= ld.bbox[BOX_TOP]) then
  begin
    result := true;
    exit;
  end;

  if P_BoxOnLineSide(@tmbbox, ld) <> -1 then
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
    P_CheckForPushSpecial(ld, 0, tmthing);
    result := false;  // one sided line
    tmbounceline := ld;
    exit;
  end;

  if tmthing.flags and MF_MISSILE = 0 then
  begin
    if G_PlayingEngineVersion <= VERSION206 then
    begin
      if ld.flags and ML_BLOCKING <> 0 then
      begin
        if tmthing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
        begin
          P_CheckForPushSpecial(ld, 0, tmthing);
          result := false;  // explicitly blocking everything
          tmbounceline := ld;
          exit;
        end;
      end;

      // killough 8/9/98: monster-blockers don't affect friends
      if (tmthing.player = nil) and (tmthing.flags2_ex and MF2_EX_FRIEND = 0) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
      begin
        result := false;  // block monsters only
        tmbounceline := ld;
        exit;
      end;
    end
    else
    begin
      if ld.flags and ML_BLOCKING <> 0 then
      begin
        P_CheckForPushSpecial(ld, 0, tmthing);
        result := false;  // explicitly blocking everything
        tmbounceline := ld;
        exit;
      end;

      if (tmthing.player <> nil) and (ld.flags and ML_BLOCKPLAYERS <> 0) then
      begin
        result := false;  // blocking players
        tmbounceline := ld;
        exit;
      end;

      // killough 8/9/98: monster-blockers don't affect friends
      if tmthing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
        if (tmthing.player = nil) and (tmthing.flags2_ex and MF2_EX_FRIEND = 0) then
        begin
          if ld.flags and ML_BLOCKMONSTERS <> 0 then
          begin
            result := false;  // block monsters only
            tmbounceline := ld;
            exit;
          end;
          if (ld.flags and ML_BLOCKLANDMONSTERS <> 0) and (tmthing.flags and MF_INFLOAT = 0) then
          begin
            result := false;  // block land monsters only
            tmbounceline := ld;
            exit;
          end;
        end;
    end;
  end;

  // set openrange, opentop, openbottom
  P_LineOpening(ld, true);

  // adjust floor / ceiling heights
  if opentop < tmceilingz then
  begin
    tmceilingz := opentop;
    ceilingline := ld;
  end;

  if openbottom > tmfloorz then
    tmfloorz := openbottom;

  if lowfloor < tmdropoffz then
    tmdropoffz := lowfloor;

  // if contacted a special line, add it to the list
  if (ld.special <> 0) or (ld.flags and ML_TRIGGERSCRIPTS <> 0) then
  begin
    if maxspechit = 0 then
    begin
      maxspechit := 64;
      spechit := Z_Malloc(64 * SizeOf(Pline_t), PU_STATIC, nil);
    end
    else if numspechit = maxspechit then
    begin
      maxspechit := maxspechit + 8;
      spechit := Z_ReAlloc(spechit, maxspechit * SizeOf(Pline_t), PU_STATIC, nil)
    end;

    spechit[numspechit] := ld;
    inc(numspechit);

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
  if (tmbbox[BOX_RIGHT] <= ld.bbox[BOX_LEFT]) or
     (tmbbox[BOX_LEFT] >= ld.bbox[BOX_RIGHT]) or
     (tmbbox[BOX_TOP] <= ld.bbox[BOX_BOTTOM]) or
     (tmbbox[BOX_BOTTOM] >= ld.bbox[BOX_TOP]) then
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

  if P_BoxOnLineSide(@tmbbox, ld) <> -1 then
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
    P_CheckForPushSpecial(ld, 0, tmthing);
    result := false;  // one sided line
    tmbounceline := ld;
    exit;
  end;

  if tmthing.flags and MF_MISSILE = 0 then
  begin
    if G_PlayingEngineVersion <= VERSION206 then
    begin
      if ld.flags and ML_BLOCKING <> 0 then
      begin
        if tmthing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
        begin
          P_CheckForPushSpecial(ld, 0, tmthing);
          result := false;  // explicitly blocking everything
          tmbounceline := ld;
          exit;
        end;
      end;

      // killough 8/9/98: monster-blockers don't affect friends
      if (tmthing.player = nil) and (tmthing.flags2_ex and MF2_EX_FRIEND = 0) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
      begin
        result := false;  // block monsters only
        tmbounceline := ld;
        exit;
      end;
    end
    else
    begin
      if ld.flags and ML_BLOCKING <> 0 then
      begin
        result := false;  // explicitly blocking everything
        tmbounceline := ld;
        exit;
      end;

      if (tmthing.player <> nil) and (ld.flags and ML_BLOCKPLAYERS <> 0) then
      begin
        result := false;  // blocking players
        tmbounceline := ld;
        exit;
      end;

      // killough 8/9/98: monster-blockers don't affect friends
      if tmthing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
        if (tmthing.player = nil) and (tmthing.flags2_ex and MF2_EX_FRIEND = 0) then
        begin
          if ld.flags and ML_BLOCKMONSTERS <> 0 then
          begin
            result := false;  // block monsters only
            tmbounceline := ld;
            exit;
          end;
          if (ld.flags and ML_BLOCKLANDMONSTERS <> 0) and (tmthing.flags and MF_INFLOAT = 0) then
          begin
            result := false;  // block land monsters only
            tmbounceline := ld;
            exit;
          end;
        end;
    end;
  end;

  // set openrange, opentop, openbottom
{  if G_PlayingEngineVersion >= VERSION205 then
    P_LineOpeningTM206(ld, true)
  else}
    P_LineOpeningTM(ld, true);

  // adjust floor / ceiling heights
  if opentop < tmceilingz then
  begin
    tmceilingz := opentop;
    ceilingline := ld;
  end;

  if openbottom > tmfloorz then
    tmfloorz := openbottom;

  if lowfloor < tmdropoffz then
    tmdropoffz := lowfloor;

  // if contacted a special line, add it to the list
  if (ld.special <> 0) or (ld.flags and ML_TRIGGERSCRIPTS <> 0) then
  begin
    if maxspechit = 0 then
    begin
      maxspechit := 64;
      spechit := Z_Malloc(64 * SizeOf(Pline_t), PU_STATIC, nil);
    end
    else if numspechit = maxspechit then
    begin
      maxspechit := maxspechit + 8;
      spechit := Z_ReAlloc(spechit, maxspechit * SizeOf(Pline_t), PU_STATIC, nil)
    end;

    spechit[numspechit] := ld;
    inc(numspechit);

  end;

  result := true;
end;

//==============================================================================
//
// PIT_CheckThing
//
//==============================================================================
function PIT_CheckThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
  solid: boolean;
  damage: integer;
  pushfactor: fixed_t;
  doslam: boolean;
begin
  if thing.flags and (MF_SOLID or MF_SPECIAL or MF_SHOOTABLE) = 0 then
  begin
    result := true;
    exit;
  end;

  // don't clip against self
  if thing = tmthing then
  begin
    result := true;
    exit;
  end;

  if G_PlayingEngineVersion >= VERSION205 then
    if (thing.player <> nil) or (tmthing.player <> nil) then  // Only if a player is involved
      if not P_ThingsInSameZ(thing, tmthing) then // JVAL: 20200413 -> Check z axis
      begin
        result := true;
        exit;
      end;

  // JVAL: 20200130 - MF2_EX_DONTBLOCKPLAYER flag - does not block players
  if (thing.flags2_ex and MF2_EX_DONTBLOCKPLAYER <> 0) and (tmthing.player <> nil) then
  begin
    result := true;
    exit;
  end;

  if (tmthing.flags2_ex and MF2_EX_DONTBLOCKPLAYER <> 0) and (thing.player <> nil) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUACTORS flag - does not colide with actors
  if (tmthing.flags3_ex and MF3_EX_THRUACTORS <> 0) or (thing.flags3_ex and MF3_EX_THRUACTORS <> 0) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (tmthing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(thing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20211031 - MF4_EX_THRUMONSTERS flag - does not colide with monsters
  if (thing.flags4_ex and MF4_EX_THRUMONSTERS <> 0) and Info_IsMonster(tmthing._type) then
  begin
    result := true;
    exit;
  end;

  // JVAL: 20210209 - MF3_EX_THRUSPECIES flag - does not colide with same species (also inheritance)
  if tmthing.flags3_ex and MF3_EX_THRUSPECIES <> 0 then
  begin
    if tmthing._type = thing._type then
    begin
      result := true;
      exit;
    end;
    if Info_GetInheritance(tmthing.info) = Info_GetInheritance(thing.info) then
    begin
      result := true;
      exit;
    end;
  end;

  blockdist := thing.radius + tmthing.radius;

  if (abs(thing.x - tmx) >= blockdist) or (abs(thing.y - tmy) >= blockdist) then
  begin
    // didn't hit it
    result := true;
    exit;
  end;

  // JVAL: 3d Floors
  if G_PlayingEngineVersion >= VERSION122 then
  begin
    if (tmthing.player <> nil) or (thing.player <> nil) then
      if tmfloorz <> thing.floorz then
      begin
        if tmthing.z > thing.z + thing.height then
        begin
          result := true;
          exit;
        end;

        if tmthing.z + tmthing.height < thing.z then
        begin // under thing
          result := true;
          exit;
        end;
      end;
  end;

  if G_PlayingEngineVersion > VERSION120 then
    if tmthing.flags2_ex and MF2_EX_PASSMOBJ <> 0 then
    begin // check if a mobj passed over/under another object

      if ((tmthing._type = Ord(MT_HEAD)) or (tmthing._type = Ord(MT_SKULL)) or (tmthing._type = Ord(MT_PAIN))) and
         ((thing._type = Ord(MT_HEAD)) or (thing._type = Ord(MT_SKULL)) or (thing._type = Ord(MT_PAIN))) then
      begin // don't let cacodemons / skull / pain elementals fly over other imps/wizards
        result := false;
        exit;
      end;

      if (tmthing.z > thing.z + thing.height) and
         (thing.flags and MF_SPECIAL = 0) then
      begin
        result := true;
        exit;
      end;

      if (tmthing.z + tmthing.height < thing.z) and
         (thing.flags and MF_SPECIAL = 0) then
      begin // under thing
        result := true;
        exit;
      end;
    end;

  // check for skulls slamming into things
  if tmthing.flags and MF_SKULLFLY <> 0 then
  begin
    if (tmthing.flags2_ex and MF2_EX_PASSMOBJ <> 0) and (G_PlayingEngineVersion >=  VERSION205) then
    // If the MF2_EX_PASSMOBJ flag is set:
    //  -Skulls do no slam to pickable objects if the
    //  -Skulls must be in same "Z"
      doslam := (thing.flags and MF_SPECIAL = 0) and P_ThingsInSameZ(tmthing, thing)
    else
      doslam := true;

    if doslam then
    begin
      damage := ((P_Random mod 8) + 1) * tmthing.info.damage;
      P_DamageMobj(thing, tmthing, tmthing, damage);

      tmthing.flags := tmthing.flags and not MF_SKULLFLY;
      tmthing.momx := 0;
      tmthing.momy := 0;
      tmthing.momz := 0;

      P_SetMobjState(tmthing, statenum_t(tmthing.info.spawnstate));

      result := false;  // stop moving
      exit;
    end;
  end;

  // missiles can hit other things
  if tmthing.flags and MF_MISSILE <> 0 then
  begin
    if (thing.flags_ex and MF_EX_GHOST <> 0) and (tmthing.flags_ex and MF_EX_THRUGHOST <> 0) then
    begin
      result := true;
      exit;
    end;

    // see if it went over / under
    if tmthing.z > thing.z + thing.height then
    begin
      result := true; // overhead
      exit;
    end;

    if tmthing.z + tmthing.height < thing.z then
    begin
      result := true; // underneath
      exit;
    end;

    if G_PlayingEngineVersion <= VERSION206 then
    begin
      if (tmthing.target <> nil) and (
          (tmthing.target._type = thing._type) or
          ((tmthing.target._type = Ord(MT_KNIGHT)) and (thing._type = Ord(MT_BRUISER))) or
          ((tmthing.target._type = Ord(MT_BRUISER)) and (thing._type = Ord(MT_KNIGHT))) or
          // JVAL: 20211126 - Inherited actors do not hurt each other
      (Info_GetInheritance(tmthing.target.info) = Info_GetInheritance(thing.info))) then
      begin
        // Don't hit same species as originator.
        if thing = tmthing.target then
        begin
          result := true;
          exit;
        end;

        if (thing._type <> Ord(MT_PLAYER)) and (thing.flags2_ex and MF2_EX_MISSILEHURTSPECIES = 0) then
        begin
          // Explode, but do no damage.
          // Let players missile other players.
          result := false;
          exit;
        end;
      end;
    end
    else
    begin
      if (tmthing.target <> nil) and
        (P_ProjectileImmune(thing, tmthing.target) or
         (Info_GetInheritance(tmthing.target.info) = Info_GetInheritance(thing.info))) then
      begin
        // Don't hit same species as originator.
        if thing = tmthing.target then
        begin
          result := true;
          exit;
        end;

        if (thing._type <> Ord(MT_PLAYER)) and (thing.flags2_ex and MF2_EX_MISSILEHURTSPECIES = 0) then
        begin
          // Explode, but do no damage.
          // Let players missile other players.
          result := false;
          exit;
        end;
      end;
    end;

    if thing.flags and MF_SHOOTABLE = 0 then
    begin
      // didn't do any damage
      result := thing.flags and MF_SOLID = 0;
      exit;
    end;

    if tmthing.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then
      begin
        result := true;
        exit;
      end;

    if tmthing.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then
      begin
        result := true;
        exit;
      end;

    // mbf21: ripper projectile
    if tmthing.flags4_ex and MF4_EX_RIP <> 0 then
    begin
      damage := ((P_Random and 3) + 2) * tmthing.info.damage;
      if (thing.flags and MF_NOBLOOD = 0) and
         (thing.flags_ex and MF_EX_INVULNERABLE = 0) then
      begin
        case P_BloodType(thing) of
          bt_red: P_SpawnBlood(tmthing.x, tmthing.y, tmthing.z, damage, thing);
          bt_blue: P_SpawnBlueBlood(tmthing.x, tmthing.y, tmthing.z, damage);
          bt_green: P_SpawnGreenBlood(tmthing.x, tmthing.y, tmthing.z, damage);
        end;
      end;

      A_RipSound1(tmthing);

      P_DamageMobj(thing, tmthing, tmthing.target, damage);

      // JVAL: Pushable things
      if (thing.flags2_ex and MF2_EX_PUSHABLE <> 0) and (tmthing.flags2_ex and MF2_EX_CANNOTPUSH = 0) then
      begin // Push thing
        pushfactor := thing.pushfactor;
        if pushfactor <= 0 then
        begin
          thing.momx := thing.momx + tmthing.momx div 4;
          thing.momy := thing.momy + tmthing.momy div 4;
        end
        else
        begin
          thing.momx := thing.momx + FixedMul(tmthing.momx, pushfactor);
          thing.momy := thing.momy + FixedMul(tmthing.momy, pushfactor);
        end;
      end;

      numspechit := 0;

      result := true;
      exit;
    end;

    // damage / explode
    if tmthing.flags3_ex and MF3_EX_ABSOLUTEDAMAGE <> 0 then
      damage := tmthing.info.damage
    else if tmthing.flags3_ex and MF3_EX_STRIFEDAMAGE <> 0 then
      damage := ((P_Random mod 4) + 1) * tmthing.info.damage
    else
      damage := ((P_Random mod 8) + 1) * tmthing.info.damage;
    P_DamageMobj(thing, tmthing, tmthing.target, damage);

    // don't traverse any more
    result := false;
    exit;
  end;

  // JVAL: Pushable things
  if (thing.flags2_ex and MF2_EX_PUSHABLE <> 0) and (tmthing.flags2_ex and MF2_EX_CANNOTPUSH = 0) then
  begin // Push thing
    pushfactor := thing.pushfactor;
    if pushfactor <= 0 then
    begin
      thing.momx := thing.momx + tmthing.momx div 4;
      thing.momy := thing.momy + tmthing.momy div 4;
    end
    else
    begin
      thing.momx := thing.momx + FixedMul(tmthing.momx, pushfactor);
      thing.momy := thing.momy + FixedMul(tmthing.momy, pushfactor);
    end;
  end;

  // check for special pickup
  if thing.flags and MF_SPECIAL <> 0 then
  begin
    solid := thing.flags and MF_SOLID <> 0;
    if tmflags and MF_PICKUP <> 0 then
    begin
      // can remove thing
      P_TouchSpecialThing(thing, tmthing);
    end;
    result := not solid;
  end
  else
    result := thing.flags and MF_SOLID = 0;
end;

//==============================================================================
//
// P_TryMove
// Attempt to move to a new position,
// crossing special lines unless MF_TELEPORT is set.
//
//==============================================================================
function P_TryMoveGame(thing: Pmobj_t; x, y: fixed_t): boolean;
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
    if thing.flags and (MF_TELEPORT or MF_NOCLIP) = 0 then
    begin
      numSpecHitTemp := numspechit;
      while numSpecHitTemp > 0 do
      begin
        dec(numSpecHitTemp);
        // see if the line was crossed
        ld := spechit[numSpecHitTemp];
        side := P_PointOnLineSide(thing.x, thing.y, ld);
        P_CheckForPushSpecial(ld, side, thing);
      end;
    end;
  end;

begin
  floatok := false;
  if not P_CheckPosition(thing, x, y) then
  begin
    result := false;  // solid wall or thing
    exit;
  end;

  if thing.flags and MF_NOCLIP = 0 then
  begin
    if tmceilingz - tmfloorz < thing.height then
    begin
      pushline;
      result := false;  // doesn't fit
      exit;
    end;

    floatok := true;

    if (thing.flags and MF_TELEPORT = 0) and
       (tmceilingz - thing.z < thing.height) then
    begin
      pushline;
      result := false;  // mobj must lower itself to fit
      exit;
    end;

    // JVAL: Do not step up in ladder movement
    p := thing.player;
    if p <> nil then
      if p.laddertics > 0 then
        if tmfloorz > thing.z then
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

    if (thing.flags and MF_TELEPORT = 0) and
       (tmfloorz - thing.z > jumpupmargin) then
    begin
      pushline;
      result := false;  // too big a step up
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
        dropoffmargin := 24 * FRACUNIT;
    end;

    // JVAL: Version 204
    if G_PlayingEngineVersion >= VERSION204 then
      if (thing.flags2_ex and MF2_EX_JUMPDOWN <> 0) and (N_Random > 20) then
        dropoffmargin := dropoffmargin + 120 * FRACUNIT;

    if (thing.flags and (MF_DROPOFF or MF_FLOAT) = 0) and
       (tmfloorz - tmdropoffz > dropoffmargin) then
    begin
      result := false;  // don't stand over a dropoff
      exit;
    end;

    // JVAL: Version 204
    if G_PlayingEngineVersion >= VERSION204 then
      if (thing.flags2_ex and MF2_EX_CANTLEAVEFLOORPIC <> 0) and
         ((tmfloorpic <> Psubsector_t(thing.subsector).sector.floorpic) or
           (tmfloorz - thing.z <> 0)) then
      begin // must stay within a sector of a certain floor type
        result := false;
        exit;
      end;

  end;

  // the move is ok,
  // so link the thing into its new position
  oldfloorz := P_FloorHeight(thing.x, thing.y); // JVAL: Slopes
  oldonfloorz := oldfloorz >= thing.z; // JVAL: Slopes
  P_UnsetThingPosition(thing);

  oldx := thing.x;
  oldy := thing.y;

  thing.floorz := tmfloorz;
  thing.ceilingz := tmceilingz;

  thing.x := x;
  thing.y := y;

  P_SetThingPosition(thing);

  // JVAL: Slopes
  if Psubsector_t(thing.subsector).sector.renderflags and SRF_SLOPED <> 0 then
  begin
    p := thing.player;
    if p = nil then
    begin
      if thing.z < tmfloorz then
        thing.z := tmfloorz;
    end
    else
    begin
      p.slopetics := SLOPECOUNTDOWN;
      if oldonfloorz then
        if oldfloorz > tmfloorz then
          thing.momz := thing.momz + (tmfloorz - oldfloorz);
    end;

  end;

  // JVAL: Slopes - 3d Floors SOS -> Get right P_GetThingFloorType()
  if thing.flags2_ex and MF2_EX_FLOORCLIP <> 0 then
  begin
    if (thing.z = Psubsector_t(thing.subsector).sector.floorheight) and
       (P_GetThingFloorType(thing) > FLOOR_SOLID) then
      thing.floorclip := FOOTCLIPSIZE
    else
      thing.floorclip := 0;
  end;

  // if any special lines were hit, do the effect
  if thing.flags and (MF_TELEPORT or MF_NOCLIP) = 0 then
  begin
    while numspechit > 0 do
    begin
      // see if the line was crossed
      dec(numspechit);
      ld := spechit[numspechit];
      side := P_PointOnLineSide(thing.x, thing.y, ld);
      oldside := P_PointOnLineSide(oldx, oldy, ld);
      if side <> oldside then
      begin
        // JVAL: Script Events
        if ld.flags and ML_TRIGGERSCRIPTS <> 0 then
          if thing.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
            PS_EventCrossLine(thing, pDiff(ld, lines, SizeOf(line_t)), oldside);

        if ld.special <> 0 then
        begin
          P_CrossSpecialLine(pDiff(ld, lines, SizeOf(line_t)), oldside, thing);
          if thing.player <> nil then
          begin
            P_ActivateLine(ld, thing, oldside, ULAC_CROSS);
          end
          else if thing.flags5_ex and MF5_EX_MCROSS <> 0 then
          begin
            P_ActivateLine(ld, thing, oldside, ULAC_MCROSS);
          end
          else if thing.flags5_ex and MF5_EX_PCROSS <> 0 then
          begin
            P_ActivateLine(ld, thing, oldside, ULAC_PCROSS);
          end;
        end;
      end;
    end;
  end;

  result := true;
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
        if (FixedDiv(midfront.ceilingheight - shootz, dist) <= aimslope) or
           (FixedDiv(midfront.floorheight - shootz, dist) >= aimslope) then
        else
          ok := false;
        if midback <> nil then
        begin
          if (FixedDiv(midback.ceilingheight - shootz, dist) <= aimslope) or
             (FixedDiv(midback.floorheight - shootz, dist) >= aimslope) then
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
    frac := intr.frac - FixedDiv(4 * FRACUNIT, attackrange);
    x := trace.x + FixedMul(trace.dx, frac);
    y := trace.y + FixedMul(trace.dy, frac);
    z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

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
        if not G_NeedsCompatibilityMode then
        begin
          P_SaveRandom;
          zoffs := (li.backsector.ceilingheight - z) * P_Random div 256;
          if zoffs > dist div 2 then
            zoffs := dist div 2;
          P_SpawnPuff(x, y, z + zoffs);
          P_RestoreRandom;
        end;
        result := false;
        exit;
      end;
    end;
    // Spawn bullet puffs.
    P_SpawnPuff(x, y, z);

    // don't go any farther
    result := false;
  end;

begin
  if intr.isaline then
  begin
    li := intr.d.line;

    if li.flags and ML_TRIGGERSCRIPTS <> 0 then
      if shootthing.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
        PS_EventShootLine(shootthing, pDiff(li, lines, SizeOf(line_t)), P_PointOnLineSide(shootthing.x, shootthing.y, li));

    if li.special <> 0 then
    begin
      P_ShootSpecialLine(shootthing, li);
      P_ActivateLine(li, shootthing, 0, ULAC_IMPACT);
    end;

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

    dist := FixedMul(attackrange, intr.frac);

    if li.frontsector.floorheight <> li.backsector.floorheight then
    begin
      slope := FixedDiv(openbottom - shootz, dist);
      if slope > aimslope then
      begin
        result := hitline(true);
        exit;
      end;
    end;

    if li.frontsector.ceilingheight <> li.backsector.ceilingheight then
    begin
      slope := FixedDiv(opentop - shootz, dist);
      if slope < aimslope then
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
  if th = shootthing then
  begin
    result := true; // can't shoot self
    exit;
  end;

  if th.flags and MF_SHOOTABLE = 0 then
  begin
    result := true; // corpse or something
    exit;
  end;

  // check angles to see if the thing can be aimed at
  dist := FixedMul(attackrange, intr.frac);
  thingtopslope := FixedDiv(th.z + th.height - shootz, dist);

  if thingtopslope < aimslope then
  begin
    result := true; // shot over the thing
    exit;
  end;

  thingbottomslope := FixedDiv(th.z - shootz, dist);

  if thingbottomslope > aimslope then
  begin
    result := true; // shot under the thing
    exit;
  end;

  // JVAL: 3d Floors
  // Can not shoot if in same subsector but different floor
  if shootthing.subsector = th.subsector then
  begin
    midn := Psubsector_t(shootthing.subsector).sector.midsec;

    if midn > -1 then
    begin
      mid := @sectors[midn];
      if ((shootz <= mid.floorheight) and (th.z >= mid.ceilingheight)) or
         ((th.z + th.height <= mid.floorheight) and (shootz >= mid.ceilingheight)) then
      begin
        result := false;
        exit;
      end;
    end;
  end;

  // hit thing
  // position a bit closer
  frac := intr.frac - FixedDiv(10 * FRACUNIT, attackrange);

  x := trace.x + FixedMul(trace.dx, frac);
  y := trace.y + FixedMul(trace.dy, frac);
  z := shootz + FixedMul(aimslope, FixedMul(frac, attackrange));

  // Spawn bullet puffs or blood spots,
  // depending on target type.
  case P_BloodType(intr.d.thing) of
    bt_puff: P_SpawnPuff(x, y, z);
    bt_red: P_SpawnBlood(x, y, z, la_damage, intr.d.thing);
    bt_blue: P_SpawnBlueBlood(x, y, z, la_damage);
    bt_green: P_SpawnGreenBlood(x, y, z, la_damage);
  end;

  if la_damage <> 0 then
    P_DamageMobj(th, shootthing, shootthing, la_damage);

  // don't go any farther
  result := false;
end;

//==============================================================================
//
// PIT_ChangeSector
//
//==============================================================================
function PIT_ChangeSector(thing: Pmobj_t): boolean;
var
  mo: Pmobj_t;
  plr: Pplayer_t;
  st: integer;
  bt: bloodtype_t;
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
  if thing.health <= 0 then
  begin
    if G_PlayingEngineVersion >= VERSION207 then
    begin
      if thing.flags4_ex and MF4_EX_DONTGIB = 0 then
      begin
        // JVAL: 20220113 - No gibs in Chex Quest
        if not (customgame in [cg_chex, cg_chex2]) or (thing.info.crushstate > 0) then
        begin
          if thing.info.crushstate > 0 then
          begin
            st := thing.info.crushstate;
            if thing.bloodcolor <> 0 then
              R_SetMobjBloodTranslation(thing, thing.bloodcolor);
          end
          else
          begin
            bt := P_BloodType(thing);
            if (bt = bt_green) and (MT_GREENGIBS <> Ord(MT_NONE)) then
              st := mobjinfo[MT_GREENGIBS].spawnstate
            else if (bt = bt_blue) and (MT_BLUEGIBS <> Ord(MT_NONE)) then
              st := mobjinfo[MT_BLUEGIBS].spawnstate
            else
            begin
              st := Ord(S_GIBS);
              if thing.bloodcolor <> 0 then
                R_SetMobjBloodTranslation(thing, thing.bloodcolor);
            end;
          end;
          if thing.state <> @states[st] then
            P_SetMobjState(thing, statenum_t(st));
        end;
        thing.flags4_ex := thing.flags4_ex or MF4_EX_DONTGIB;
      end;
    end
    else
    begin
      P_SetMobjState(thing, S_GIBS);
      if thing.bloodcolor <> 0 then
        R_SetMobjBloodTranslation(thing, thing.bloodcolor);
    end;

    thing.flags := thing.flags and not MF_SOLID;
    thing.height := 0;
    thing.radius := 0;

    // keep checking
    result := true;
    exit;
  end;

  // crunch dropped items
  if thing.flags and MF_DROPPED <> 0 then
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

  nofit := true;

  if crushchange and (leveltime and 3 = 0) then
  begin
    P_DamageMobj(thing, nil, nil, 10);

    if G_PlayingEngineVersion >= VERSION115 then
    begin

      if (thing.flags and MF_NOBLOOD <> 0) or
         (thing.flags_ex and MF_EX_INVULNERABLE <> 0) then
        begin
          result := true;
          exit;
        end;

      plr := thing.player;
      if plr <> nil then
        if (plr.cheats and CF_GODMODE <> 0) or (plr.powers[Ord(pw_invulnerability)] <> 0) then
        begin
          result := true;
          exit;
        end;

    end;

    // spray blood in a random direction
    // JVAL: player with custom blood color :)
    if thing.flags2_ex and MF2_EX_BLUEBLOOD <> 0 then
      mo := P_SpawnMobj(thing.x, thing.y, thing.z + thing.height div 2, MT_BLUEBLOOD)
    else if thing.flags2_ex and MF2_EX_GREENBLOOD <> 0 then
      mo := P_SpawnMobj(thing.x, thing.y, thing.z + thing.height div 2, MT_GREENBLOOD)
    else
      mo := P_SpawnMobj(thing.x, thing.y, thing.z + thing.height div 2, Ord(MT_BLOOD));

    mo.momx := _SHL(P_Random - P_Random, 12);
    mo.momy := _SHL(P_Random - P_Random, 12);
  end;

  // keep checking (crush other things)
  result := true;
end;

//==============================================================================
//
// P_BloodType
//
//==============================================================================
function P_BloodType(const th: Pmobj_t): bloodtype_t;
var
  confcoloredblood: boolean;
begin
  if th.flags and MF_NOBLOOD <> 0 then
    result := bt_puff
  else
  begin
    // JVAL 18/09/2009 Added Blue and Green blood spawners
    if G_PlayingEngineVersion < VERSION110 then
      result := bt_red
    else if G_PlayingEngineVersion < VERSION206 then
    begin
      if th.flags2_ex and MF2_EX_BLUEBLOOD <> 0 then
        result := bt_blue
      else if th.flags2_ex and MF2_EX_GREENBLOOD <> 0 then
        result := bt_green
      else
        result := bt_red;
    end
    else
    begin
      if demoplayback or demorecording then
        confcoloredblood := true
      else
        confcoloredblood := p_confcoloredblood;
      if (th.flags2_ex and MF2_EX_BLUEBLOOD <> 0) or (confcoloredblood and (th.flags3_ex and MF3_EX_CONFBLUEBLOOD <> 0)) then
        result := bt_blue
      else if (th.flags2_ex and MF2_EX_GREENBLOOD <> 0) or (confcoloredblood and (th.flags3_ex and MF3_EX_CONFGREENBLOOD <> 0)) then
        result := bt_green
      else
        result := bt_red
    end;
  end;
end;

//==============================================================================
//
// P_PointInSectorVanilla
//
//==============================================================================
function P_PointInSectorVanilla(const x: fixed_t; const y: fixed_t): Psector_t;
var
  node: Pvanillanode_t;
  nodenum: LongWord;
begin
  nodenum := numvanillanodes - 1;

  while nodenum and NF_SUBSECTOR = 0 do
  begin
    node := @vanillanodes[nodenum];
    if R_PointOnSideVanilla(x, y, node) then
      nodenum := node.children[1]
    else
      nodenum := node.children[0]
  end;

  result := vanillasubsectors[nodenum and not NF_SUBSECTOR].sector; // JVAL: glbsp
end;

//==============================================================================
//
// P_PointInSector
//
//==============================================================================
function P_PointInSector(const x: fixed_t; const y: fixed_t): Psector_t;
begin
  if G_IsOldDemoPlaying and hasvanillanodes then
    result := P_PointInSectorVanilla(x, y)
  else
    result := R_PointInSubSector(x, y).sector;
end;
end.
