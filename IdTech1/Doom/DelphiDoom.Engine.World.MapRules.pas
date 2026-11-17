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

// The same units, in the same order, as the old p_map.pas of the game: a name that two units
// declare is found where it was found before
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
  bloodtype_t = (bt_puff, bt_red, bt_blue, bt_green);
  /// <summary>
  ///   What Doom does differently in the movement and collision code of p_map. The unit of the
  ///   same name in the folder of each game is chosen by the project, so the calls are bound at
  ///   compile time: no virtual call and no interface, this is the path of every moving thing
  /// </summary>
  /// <remarks>
  ///   The bodies are the lines of the old IdTech1\Doom\p_map.pas, moved as they were: the methods keep
  ///   the names of the parameters and the style of the routine they come from
  /// </remarks>
  TMapGameRules = class sealed
  public
    const
      /// <summary>First version that checks the lines with the slopes and moves the sectors that depend on another</summary>
      SlopesVersion = VERSION122;
      /// <summary>A teleported thing is put on the floor of the destination</summary>
      TeleportSetsZ = False;
      /// <summary>The puff on a sky hack wall is spawned in the compatibility mode (Doom: out of it, and the shot always stops there)</summary>
      SkyHackPuffInCompatibility = False;
      /// <summary>The flags of a thing that runs no special of the lines it touches or crosses</summary>
      NoSpecHitFlags = MF_TELEPORT or MF_NOCLIP;
      /// <summary>A move stopped by a thing or by a wall pushes the lines it touched</summary>
      PushesLinesWhenBlocked = False;
      /// <summary>The dropoff a thing does not walk over</summary>
      DropoffHeight = 24 * FRACUNIT;
      /// <summary>What a thing that jumps down adds to it</summary>
      JumpDownMargin = 120 * FRACUNIT;
      /// <summary>The step a sliding thing climbs</summary>
      SlideStepMargin = 24 * FRACUNIT;
      /// <summary>The damage a sector that crushes a thing does to it every fourth tic</summary>
      CrushDamage = 10;

    /// <summary>The sector of a point (Doom follows the original nodes while an old demo plays)</summary>
    class function PointInSector(const x, y: fixed_t): Psector_t; static; inline;
    /// <summary>The thing being teleported (TMapCheck.Thing) may kill the thing in its way</summary>
    class function CanStomp(thing: Pmobj_t): boolean; static;
    /// <summary>Marks a thing that has just been teleported (the renderer does not interpolate it)</summary>
    class procedure MarkJustAppeared(thing: Pmobj_t); static; inline;
    /// <summary>The player flies: no room for a jump is added under the sky</summary>
    class function HasFlightPower(const p: Pplayer_t): boolean; static; inline;
    /// <summary>P_ThingsInSameZ compares the two things as the versions before 2.07 did</summary>
    class function KeepsOldSameZ(const A, B: Pmobj_t): boolean; static; inline;
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
    /// <summary>A thing thrown by a blast hurts itself against a wall (only Hexen)</summary>
    class procedure BlastedHitsWall(mo: Pmobj_t); static; inline;
    /// <summary>
    ///   The part of PIT_CheckLine for the things that are not missiles: false when the line
    ///   blocks TMapCheck.Thing (TMapCheck.BounceLine is set and the push specials are run)
    /// </summary>
    class function CheckLineBlocking(ld: Pline_t): boolean; static;
    /// <summary>The same for PIT_CheckLineTM (the check that knows the slopes)</summary>
    class function CheckLineBlockingTM(ld: Pline_t): boolean; static;
    /// <summary>The position is taken by a thing the mover can step on (only Hexen)</summary>
    class function StepsOnBlockingThing(thing: Pmobj_t): boolean; static;
    /// <summary>The thing moves even where the ceiling is lower than its head</summary>
    class function IgnoresCeilingFit(thing: Pmobj_t): boolean; static; inline;
    /// <summary>A flying thing hits the ceiling or the edge of a floor and is pushed back (only Hexen)</summary>
    class function FlightBlocked(thing: Pmobj_t): boolean; static;
    /// <summary>The step is too high for a thing on foot (Strife: 16 units for what is not a robot)</summary>
    class function StepTooHighOnFoot(thing: Pmobj_t): boolean; static; inline;
    /// <summary>The thing climbs a step of any height</summary>
    class function IgnoresStepHeight(thing: Pmobj_t): boolean; static; inline;
    /// <summary>The step is too high for a missile (only Strife)</summary>
    class function MissileStepTooHigh(thing: Pmobj_t): boolean; static; inline;
    /// <summary>The thing goes over a dropoff of any height</summary>
    class function IgnoresDropoff(thing: Pmobj_t): boolean; static; inline;
    /// <summary>The thing stays on the kind of floor it is on</summary>
    class function CannotLeaveFloorPic(thing: Pmobj_t): boolean; static; inline;
    /// <summary>After a move: the feet of the thing sink in the floor it is on, or not</summary>
    class procedure UpdateFloorClip(thing: Pmobj_t); static;
    /// <summary>The thing crossed a special line</summary>
    class procedure CrossSpecialLine(ld: Pline_t; oldside: integer; thing: Pmobj_t); static;
    /// <summary>
    ///   The second half of PIT_CheckThing, after the checks that are the same in every game:
    ///   what happens when TMapCheck.Thing touches the thing; false when TMapCheck.Thing is blocked
    /// </summary>
    class function CheckThingContact(thing: Pmobj_t): boolean; static;
    /// <summary>PIT_CheckThing: a thing that the moving thing pushes when it touches it</summary>
    class function CanBePushed(thing: Pmobj_t): boolean; static; inline;
    /// <summary>PIT_CheckThing: the part of the momentum a thing that is not a pushable weight gets (a quarter; Hexen shifts, the others divide)</summary>
    class function QuarterMomentum(const momentum: fixed_t): fixed_t; static; inline;
    /// <summary>PIT_CheckThing: the moving thing can pick up a special thing it touches</summary>
    class function PicksUpOnContact: boolean; static; inline;
    /// <summary>The puff of a shot that hit a wall</summary>
    class procedure SpawnWallPuff(x, y, z: fixed_t); static;
    /// <summary>A shot hit a special line</summary>
    class procedure ShootSpecialLine(shootthing: Pmobj_t; li: Pline_t); static;
    /// <summary>A shot goes through this thing (Strife: the spectral ones)</summary>
    class function ShotPassesThrough(th: Pmobj_t): boolean; static; inline;
    /// <summary>A shot hit the thing at this point: puff or blood, and the damage; the result of PTR_ShootTraverse</summary>
    class function ShotHitsThing(intr: Pintercept_t; th: Pmobj_t; x, y, z: fixed_t): boolean; static;
    /// <summary>
    ///   Rechecks the things of a sector that moved through the list of the things that touch
    ///   it; false when the caller has to walk the blockmap instead
    /// </summary>
    class function ChangeSectorByThingList(sector: Psector_t): boolean; static;
    /// <summary>PIT_ChangeSector: the thing is a body that the moving sector crunches (to giblets or to nothing)</summary>
    class function IsCrushedBody(thing: Pmobj_t): boolean; static; inline;
    /// <summary>PIT_ChangeSector: the body is crunched; gives what PIT_ChangeSector gives (true to go on, false to stop: the sector does not fit)</summary>
    class function CrunchBody(thing: Pmobj_t): boolean; static;
    /// <summary>PIT_ChangeSector: the thing is a dropped item, that the moving sector crunches</summary>
    class function IsDroppedItem(thing: Pmobj_t): boolean; static; inline;
    /// <summary>PIT_ChangeSector: the blood a crushed thing sprays (nothing for a thing without blood or invulnerable)</summary>
    class procedure CrushBlood(thing: Pmobj_t); static;
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
  DelphiDoom.Engine.World.BloodSpawner,
  DelphiDoom.Engine.World.PhysicsExtension,
  doomdata,
  doomstat,
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
  DelphiDoom.Engine.World.MobjRules,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  p_sight,
  p_3dfloors, // JVAL: 3d Floors
  p_slopes, // JVAL: Slopes
  DelphiDoom.Engine.World.SwitchRules,
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
  z_zone,
  p_secnodes,
  p_map;

{ TMapGameRules }

class function TMapGameRules.PointInSector(const x, y: fixed_t): Psector_t;
begin
  result := P_PointInSector(x, y);
end;

class function TMapGameRules.CanStomp(thing: Pmobj_t): boolean;
begin
  // monsters don't stomp things except on boss level
  result := not ((TMapCheck.Thing.player = nil) and (TGameSession.GameMap <> 30));
end;

class procedure TMapGameRules.MarkJustAppeared(thing: Pmobj_t);
begin
  thing.flags4_ex := thing.flags4_ex or MF4_EX_JUSTAPPEARED;
end;

class function TMapGameRules.HasFlightPower(const p: Pplayer_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.KeepsOldSameZ(const A, B: Pmobj_t): boolean;
begin
  result := (A.flags2_ex and MF2_EX_ONMOBJ = 0) and (B.flags2_ex and MF2_EX_ONMOBJ = 0);
end;

class procedure TMapGameRules.BeginCheckPosition;
begin
end;

class function TMapGameRules.NoClipSkipsThings(const AFlags: integer): boolean;
begin
  // a game with the physics of its own: this is the first rule that P_CheckPosition asks after it
  // has set the planes of the sector, so the planes are moved here (Radix: missiles and things
  // that fly through a sky)
  if TPhysicsExtension.Enabled then
    TPhysicsExtension.AdjustCheckedPlanes;
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

class procedure TMapGameRules.BlastedHitsWall(mo: Pmobj_t);
begin
end;

class function TMapGameRules.CheckLineBlocking(ld: Pline_t): boolean;
begin
  if G_PlayingEngineVersion <= VERSION206 then
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      begin
        P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
        result := false;  // explicitly blocking everything
        TMapCheck.BounceLine := ld;
        exit;
      end;
    end;

    // killough 8/9/98: monster-blockers don't affect friends
    if (TMapCheck.Thing.player = nil) and (TMapCheck.Thing.flags2_ex and MF2_EX_FRIEND = 0) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
    begin
      result := false;  // block monsters only
      TMapCheck.BounceLine := ld;
      exit;
    end;
  end
  else
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
      result := false;  // explicitly blocking everything
      TMapCheck.BounceLine := ld;
      exit;
    end;

    if (TMapCheck.Thing.player <> nil) and (ld.flags and ML_BLOCKPLAYERS <> 0) then
    begin
      result := false;  // blocking players
      TMapCheck.BounceLine := ld;
      exit;
    end;

    // killough 8/9/98: monster-blockers don't affect friends
    if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      if (TMapCheck.Thing.player = nil) and (TMapCheck.Thing.flags2_ex and MF2_EX_FRIEND = 0) then
      begin
        if ld.flags and ML_BLOCKMONSTERS <> 0 then
        begin
          result := false;  // block monsters only
          TMapCheck.BounceLine := ld;
          exit;
        end;
        if (ld.flags and ML_BLOCKLANDMONSTERS <> 0) and (TMapCheck.Thing.flags and MF_INFLOAT = 0) then
        begin
          result := false;  // block land monsters only
          TMapCheck.BounceLine := ld;
          exit;
        end;
      end;
  end;

  result := true;
end;

class function TMapGameRules.CheckLineBlockingTM(ld: Pline_t): boolean;
begin
  if G_PlayingEngineVersion <= VERSION206 then
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      begin
        P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
        result := false;  // explicitly blocking everything
        TMapCheck.BounceLine := ld;
        exit;
      end;
    end;

    // killough 8/9/98: monster-blockers don't affect friends
    if (TMapCheck.Thing.player = nil) and (TMapCheck.Thing.flags2_ex and MF2_EX_FRIEND = 0) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
    begin
      result := false;  // block monsters only
      TMapCheck.BounceLine := ld;
      exit;
    end;
  end
  else
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      result := false;  // explicitly blocking everything
      TMapCheck.BounceLine := ld;
      exit;
    end;

    if (TMapCheck.Thing.player <> nil) and (ld.flags and ML_BLOCKPLAYERS <> 0) then
    begin
      result := false;  // blocking players
      TMapCheck.BounceLine := ld;
      exit;
    end;

    // killough 8/9/98: monster-blockers don't affect friends
    if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      if (TMapCheck.Thing.player = nil) and (TMapCheck.Thing.flags2_ex and MF2_EX_FRIEND = 0) then
      begin
        if ld.flags and ML_BLOCKMONSTERS <> 0 then
        begin
          result := false;  // block monsters only
          TMapCheck.BounceLine := ld;
          exit;
        end;
        if (ld.flags and ML_BLOCKLANDMONSTERS <> 0) and (TMapCheck.Thing.flags and MF_INFLOAT = 0) then
        begin
          result := false;  // block land monsters only
          TMapCheck.BounceLine := ld;
          exit;
        end;
      end;
  end;

  result := true;
end;

class function TMapGameRules.StepsOnBlockingThing(thing: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.IgnoresCeilingFit(thing: Pmobj_t): boolean;
begin
  result := thing.flags and MF_TELEPORT <> 0;
  // a game with the physics of its own: a craft that slides on floors and ceilings (Radix)
  if TPhysicsExtension.Enabled then
    result := result or TPhysicsExtension.SlidesOnPlanes(thing);
end;

class function TMapGameRules.FlightBlocked(thing: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.StepTooHighOnFoot(thing: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.IgnoresStepHeight(thing: Pmobj_t): boolean;
begin
  result := thing.flags and MF_TELEPORT <> 0;
  if TPhysicsExtension.Enabled then
    result := result or TPhysicsExtension.SlidesOnPlanes(thing);
end;

class function TMapGameRules.MissileStepTooHigh(thing: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.IgnoresDropoff(thing: Pmobj_t): boolean;
begin
  result := false;
  if TPhysicsExtension.Enabled then
    result := TPhysicsExtension.SlidesOnPlanes(thing);
end;

class function TMapGameRules.CannotLeaveFloorPic(thing: Pmobj_t): boolean;
begin
  // JVAL: Version 204
  result := (G_PlayingEngineVersion >= VERSION204) and (thing.flags2_ex and MF2_EX_CANTLEAVEFLOORPIC <> 0);
end;

class procedure TMapGameRules.UpdateFloorClip(thing: Pmobj_t);
begin
  if thing.flags2_ex and MF2_EX_FLOORCLIP <> 0 then
  begin
    if (thing.z = Psubsector_t(thing.subsector).sector.floorheight) and
       (P_GetThingFloorType(thing) > FLOOR_SOLID) then
      thing.floorclip := FOOTCLIPSIZE
    else
      thing.floorclip := 0;
  end;
end;

class procedure TMapGameRules.CrossSpecialLine(ld: Pline_t; oldside: integer; thing: Pmobj_t);
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

class function TMapGameRules.CheckThingContact(thing: Pmobj_t): boolean;
var
  damage: integer;
  doslam: boolean;
begin
  if G_PlayingEngineVersion > VERSION120 then
    if TMapCheck.Thing.flags2_ex and MF2_EX_PASSMOBJ <> 0 then
    begin // check if a mobj passed over/under another object

      if ((TMapCheck.Thing._type = Ord(MT_HEAD)) or (TMapCheck.Thing._type = Ord(MT_SKULL)) or (TMapCheck.Thing._type = Ord(MT_PAIN))) and
         ((thing._type = Ord(MT_HEAD)) or (thing._type = Ord(MT_SKULL)) or (thing._type = Ord(MT_PAIN))) then
      begin // don't let cacodemons / skull / pain elementals fly over other imps/wizards
        result := false;
        exit;
      end;

      if (TMapCheck.Thing.z > thing.z + thing.height) and
         (thing.flags and MF_SPECIAL = 0) then
      begin
        result := true;
        exit;
      end;

      if (TMapCheck.Thing.z + TMapCheck.Thing.height < thing.z) and
         (thing.flags and MF_SPECIAL = 0) then
      begin // under thing
        result := true;
        exit;
      end;
    end;

  // check for skulls slamming into things
  if TMapCheck.Thing.flags and MF_SKULLFLY <> 0 then
  begin
    if (TMapCheck.Thing.flags2_ex and MF2_EX_PASSMOBJ <> 0) and (G_PlayingEngineVersion >=  VERSION205) then
    // If the MF2_EX_PASSMOBJ flag is set:
    //  -Skulls do no slam to pickable objects if the
    //  -Skulls must be in same "Z"
      doslam := (thing.flags and MF_SPECIAL = 0) and P_ThingsInSameZ(TMapCheck.Thing, thing)
    else
      doslam := true;

    if doslam then
    begin
      if TPhysicsExtension.Enabled then
        damage := ((P_Random mod 8) + 1) * TPhysicsExtension.ThingDamage(TMapCheck.Thing)
      else
        damage := ((P_Random mod 8) + 1) * TMapCheck.Thing.info.damage;
      P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing, damage);

      TMapCheck.Thing.flags := TMapCheck.Thing.flags and not MF_SKULLFLY;
      TMapCheck.Thing.momx := 0;
      TMapCheck.Thing.momy := 0;
      TMapCheck.Thing.momz := 0;

      P_SetMobjState(TMapCheck.Thing, statenum_t(TMapCheck.Thing.info.spawnstate));

      result := false;  // stop moving
      exit;
    end;
  end;

  // missiles can hit other things
  if TMapCheck.Thing.flags and MF_MISSILE <> 0 then
  begin
    if (thing.flags_ex and MF_EX_GHOST <> 0) and (TMapCheck.Thing.flags_ex and MF_EX_THRUGHOST <> 0) then
    begin
      result := true;
      exit;
    end;

    // see if it went over / under
    if TMapCheck.Thing.z > thing.z + thing.height then
    begin
      result := true; // overhead
      exit;
    end;

    if TMapCheck.Thing.z + TMapCheck.Thing.height < thing.z then
    begin
      result := true; // underneath
      exit;
    end;

    if G_PlayingEngineVersion <= VERSION206 then
    begin
      if (TMapCheck.Thing.target <> nil) and (
          (TMapCheck.Thing.target._type = thing._type) or
          ((TMapCheck.Thing.target._type = Ord(MT_KNIGHT)) and (thing._type = Ord(MT_BRUISER))) or
          ((TMapCheck.Thing.target._type = Ord(MT_BRUISER)) and (thing._type = Ord(MT_KNIGHT))) or
          // JVAL: 20211126 - Inherited actors do not hurt each other
      (Info_GetInheritance(TMapCheck.Thing.target.info) = Info_GetInheritance(thing.info))) then
      begin
        // Don't hit same species as originator.
        if thing = TMapCheck.Thing.target then
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
      if (TMapCheck.Thing.target <> nil) and
        (P_ProjectileImmune(thing, TMapCheck.Thing.target) or
         (Info_GetInheritance(TMapCheck.Thing.target.info) = Info_GetInheritance(thing.info))) then
      begin
        // Don't hit same species as originator.
        if thing = TMapCheck.Thing.target then
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

    if TMapCheck.Thing.flags3_ex and MF3_EX_FREEZEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFREEZEDAMAGE <> 0 then
      begin
        result := true;
        exit;
      end;

    if TMapCheck.Thing.flags3_ex and MF3_EX_FLAMEDAMAGE <> 0 then
      if thing.flags3_ex and MF3_EX_NOFLAMEDAMAGE <> 0 then
      begin
        result := true;
        exit;
      end;

    // mbf21: ripper projectile
    if TMapCheck.Thing.flags4_ex and MF4_EX_RIP <> 0 then
    begin
      damage := ((P_Random and 3) + 2) * TMapCheck.Thing.info.damage;
      if (thing.flags and MF_NOBLOOD = 0) and
         (thing.flags_ex and MF_EX_INVULNERABLE = 0) then
      begin
        case P_BloodType(thing) of
          bt_red: TBloodSpawner.SpawnRed(TMapCheck.Thing.x, TMapCheck.Thing.y, TMapCheck.Thing.z, damage, thing);
          bt_blue: P_SpawnBlueBlood(TMapCheck.Thing.x, TMapCheck.Thing.y, TMapCheck.Thing.z, damage);
          bt_green: P_SpawnGreenBlood(TMapCheck.Thing.x, TMapCheck.Thing.y, TMapCheck.Thing.z, damage);
        end;
      end;

      A_RipSound1(TMapCheck.Thing);

      P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, damage);

      // JVAL: Pushable things
      P_PushByContact(thing);

      TMapCheck.NumSpecHit := 0;

      result := true;
      exit;
    end;

    // damage / explode
    if TMapCheck.Thing.flags3_ex and MF3_EX_ABSOLUTEDAMAGE <> 0 then
      damage := TMapCheck.Thing.info.damage
    else if TMapCheck.Thing.flags3_ex and MF3_EX_STRIFEDAMAGE <> 0 then
      damage := ((P_Random mod 4) + 1) * TMapCheck.Thing.info.damage
    else if TPhysicsExtension.Enabled then
      damage := ((P_Random mod 8) + 1) * TPhysicsExtension.ThingDamage(TMapCheck.Thing)
    else
      damage := ((P_Random mod 8) + 1) * TMapCheck.Thing.info.damage;
    P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, damage);

    // don't traverse any more
    result := false;
    exit;
  end;

  // JVAL: Pushable things
  P_PushByContact(thing);

  // a game with the physics of its own (Radix: touch damage)
  if TPhysicsExtension.Enabled then
    TPhysicsExtension.ThingContact(thing, TMapCheck.Thing);

  // check for special pickup
  result := P_ContactPickup(thing);
end;

class function TMapGameRules.CanBePushed(thing: Pmobj_t): boolean;
begin
  result := (thing.flags2_ex and MF2_EX_PUSHABLE <> 0) and (TMapCheck.Thing.flags2_ex and MF2_EX_CANNOTPUSH = 0);
end;

class function TMapGameRules.QuarterMomentum(const momentum: fixed_t): fixed_t;
begin
  result := momentum div 4;
end;

class function TMapGameRules.PicksUpOnContact: boolean;
begin
  result := TMapCheck.Flags and MF_PICKUP <> 0;
end;

class procedure TMapGameRules.SpawnWallPuff(x, y, z: fixed_t);
begin
  P_SpawnPuff(x, y, z);
end;

class procedure TMapGameRules.ShootSpecialLine(shootthing: Pmobj_t; li: Pline_t);
begin
  P_ShootSpecialLine(shootthing, li);
  P_ActivateLine(li, shootthing, 0, ULAC_IMPACT);
end;

class function TMapGameRules.ShotPassesThrough(th: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.ShotHitsThing(intr: Pintercept_t; th: Pmobj_t; x, y, z: fixed_t): boolean;
begin
  // Spawn bullet puffs or blood spots,
  // depending on target type.
  case P_BloodType(intr.d.thing) of
    bt_puff: P_SpawnPuff(x, y, z);
    bt_red: TBloodSpawner.SpawnRed(x, y, z, TMapAim.Damage, intr.d.thing);
    bt_blue: P_SpawnBlueBlood(x, y, z, TMapAim.Damage);
    bt_green: P_SpawnGreenBlood(x, y, z, TMapAim.Damage);
  end;

  if TMapAim.Damage <> 0 then
    P_DamageMobj(th, TMapAim.ShootThing, TMapAim.ShootThing, TMapAim.Damage);

  // don't go any farther
  result := false;
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
// PIT_ChangeSector
//
//==============================================================================
class function TMapGameRules.IsCrushedBody(thing: Pmobj_t): boolean;
begin
  result := thing.health <= 0;
end;

class function TMapGameRules.CrunchBody(thing: Pmobj_t): boolean;
var
  st: integer;
  bt: bloodtype_t;
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

class function TMapGameRules.IsDroppedItem(thing: Pmobj_t): boolean;
begin
  result := thing.flags and MF_DROPPED <> 0;
end;

class procedure TMapGameRules.CrushBlood(thing: Pmobj_t);
var
  mo: Pmobj_t;
  plr: Pplayer_t;
begin
  if G_PlayingEngineVersion >= VERSION115 then
  begin

    if (thing.flags and MF_NOBLOOD <> 0) or
       (thing.flags_ex and MF_EX_INVULNERABLE <> 0) then
      begin
        exit;
      end;

    plr := thing.player;
    if plr <> nil then
      if (plr.cheats and CF_GODMODE <> 0) or (plr.powers[Ord(pw_invulnerability)] <> 0) then
      begin
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
      if TGameSession.DemoPlayback or TGameSession.DemoRecording then
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
