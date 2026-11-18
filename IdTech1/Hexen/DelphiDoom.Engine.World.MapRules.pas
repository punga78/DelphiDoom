{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Hexen for movement and collisions         }
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
  /// <summary>
  ///   What Hexen does differently in the movement and collision code of p_map. The unit of the
  ///   same name in the folder of each game is chosen by the project, so the calls are bound at
  ///   compile time: no virtual call and no interface, this is the path of every moving thing
  /// </summary>
  /// <remarks>
  ///   The bodies are the lines of the old IdTech1\Hexen\p_map.pas, moved as they were: the methods keep
  ///   the names of the parameters and the style of the routine they come from
  /// </remarks>
  TMapGameRules = class sealed
  public
    const
      /// <summary>First version that checks the lines with the slopes and moves the sectors that depend on another</summary>
      SlopesVersion = VERSION142;
      /// <summary>A teleported thing is put on the floor of the destination</summary>
      TeleportSetsZ = False;
      /// <summary>The puff on a sky hack wall is spawned in the compatibility mode (Doom: out of it, and the shot always stops there)</summary>
      SkyHackPuffInCompatibility = True;
      /// <summary>The flags of a thing that runs no special of the lines it touches or crosses</summary>
      NoSpecHitFlags = MF_TELEPORT or MF_NOCLIP;
      /// <summary>A move stopped by a thing or by a wall pushes the lines it touched</summary>
      PushesLinesWhenBlocked = True;
      /// <summary>The dropoff a thing does not walk over</summary>
      DropoffHeight = 24 * FRACUNIT;
      /// <summary>What a thing that jumps down adds to it</summary>
      JumpDownMargin = 120 * FRACUNIT;
      /// <summary>The step a sliding thing climbs</summary>
      SlideStepMargin = 24 * FRACUNIT;
      /// <summary>The damage a sector that crushes a thing does to it every fourth tic</summary>
      CrushDamage = 1;

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

var
  PuffSpawned: Pmobj_t;
  BlockingMobj: Pmobj_t;

type
  /// <summary>
  ///   The routines of this unit as static methods with the text and the names of the old free routines (issue #185,
  ///   wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TMapRoutines = class sealed
  public
    //==============================================================================
    // P_CheckForPushSpecial
    //
    // CheckForPushSpecial
    //
    //==============================================================================
    class procedure P_CheckForPushSpecial(line: Pline_t; side: integer; mobj: Pmobj_t); static;

    //==============================================================================
    //
    // PIT_ThrustSpike
    //
    //==============================================================================
    class procedure PIT_ThrustSpike(actor: Pmobj_t); static;

    //==============================================================================
    //
    // P_UsePuzzleItem
    //
    //==============================================================================
    class function P_UsePuzzleItem(player: Pplayer_t; itemType: integer): boolean; static;

    //==============================================================================
    //
    // P_BounceWall
    //
    //==============================================================================
    class procedure P_BounceWall(mo: Pmobj_t); static;
  end;


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
  DelphiDoom.Engine.World.MobjRules,
  p_spec_h,
  DelphiDoom.Engine.World.SpecRules,
  p_spec,
  p_sight,
  p_3dfloors, // JVAL: 3d Floors
  p_slopes, // JVAL: Slopes
  p_tick,
  p_acs,
  p_sounds,
  ps_main,  // JVAL: Script Events
  r_main,
  r_sky,
  r_intrpl,
  r_translations,
  z_zone,
  p_map;

var
  tsthing: Pmobj_t;

  // Written by PTR_BounceTraverse and never read (as in the old p_map)
  secondslidefrac: fixed_t;
  secondslideline: Pline_t;

  bombdistance: integer;
  damagesource: boolean;
{ TMapGameRules }

class function TMapGameRules.PointInSector(const x, y: fixed_t): Psector_t;
begin
  result := R_PointInSubsector(x, y).sector;
end;

class function TMapGameRules.CanStomp(thing: Pmobj_t): boolean;
begin
  // Not allowed to stomp things
  result := TMapCheck.Thing.flags2 and MF2_TELESTOMP <> 0;
end;

class procedure TMapGameRules.MarkJustAppeared(thing: Pmobj_t);
begin
  thing.flags2_ex := thing.flags2_ex or MF2_EX_JUSTAPPEARED;
end;

class function TMapGameRules.HasFlightPower(const p: Pplayer_t): boolean;
begin
  result := p.powers[Ord(pw_flight)] <> 0;
end;

class function TMapGameRules.KeepsOldSameZ(const A, B: Pmobj_t): boolean;
begin
  result := false;
end;

class procedure TMapGameRules.BeginCheckPosition;
begin
end;

class function TMapGameRules.NoClipSkipsThings(const AFlags: integer): boolean;
begin
  result := (AFlags and MF_NOCLIP <> 0) and (AFlags and MF_SKULLFLY = 0);
end;

class function TMapGameRules.NoClipSkipsLines(const AFlags: integer): boolean;
begin
  result := AFlags and MF_NOCLIP <> 0;
end;

class procedure TMapGameRules.ClearBlockingThing;
begin
  BlockingMobj := nil;
end;

class function TMapGameRules.IsSkullFlying(mo: Pmobj_t): boolean;
begin
  result := mo.flags and MF_SKULLFLY <> 0;
end;

class function TMapGameRules.FlightBobs(mo: Pmobj_t): boolean;
begin
  result := mo.flags2 and MF2_FLY <> 0;
end;

class function TMapGameRules.HasLowGravity(mo: Pmobj_t): boolean;
begin
  result := (mo.flags2 and MF2_LOGRAV <> 0) or (mo.flags_ex and MF_EX_LOWGRAVITY <> 0);
end;

class procedure TMapGameRules.StoreFloorPic(thing: Pmobj_t);
begin
  thing.floorpic := TMapCheck.FloorPic;
end;

class function TMapGameRules.SnapsToFloor(thing: Pmobj_t): boolean;
begin
  result := (thing.z - thing.floorz < 9 * FRACUNIT) or
     (thing.flags and MF_NOGRAVITY <> 0);
end;

class function TMapGameRules.SkipsAimAt(th: Pmobj_t): boolean;
begin
  // don't aim at fellow co-op players
  result := (th.player <> nil) and TGameSession.NetGame and (TGameSession.DeathMatch = 0);
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
  result := t1.z + _SHR1(t1.height) + 8 * FRACUNIT - t1.floorclip ;
end;

class function TMapGameRules.LineAttackFlags(const damage: integer): integer;
begin
  result := PT_ADDLINES or PT_ADDTHINGS;
end;

class procedure TMapGameRules.LineAttackMissed(t1: Pmobj_t; x2, y2: fixed_t; slope: fixed_t;
  distance: fixed_t);
begin
  case PuffType of
    MT_PUNCHPUFF:
      S_StartSound(t1, Ord(SFX_FIGHTER_PUNCH_MISS));
    MT_HAMMERPUFF,
    MT_AXEPUFF,
    MT_AXEPUFF_GLOW:
      S_StartSound(t1, Ord(SFX_FIGHTER_HAMMER_MISS));
    MT_FLAMEPUFF:
      P_SpawnPuff(x2, y2, TMapAim.ShootZ + FixedMul(slope, distance));
  end;
end;

class procedure TMapGameRules.UseBlockedByWall(usething: Pmobj_t);
var
  sound: integer;
begin
  if usething.player <> nil then
  begin
    case Pplayer_t(usething.player)._class of
      PCLASS_FIGHTER:
        sound := Ord(SFX_PLAYER_FIGHTER_FAILED_USE);
      PCLASS_CLERIC:
        sound := Ord(SFX_PLAYER_CLERIC_FAILED_USE);
      PCLASS_MAGE:
        sound := Ord(SFX_PLAYER_MAGE_FAILED_USE);
      PCLASS_PIG:
        sound := Ord(SFX_PIG_ACTIVE1);
    else
      sound := Ord(SFX_NONE);
    end;
    S_StartSound(usething, sound);
  end;
end;

class procedure TMapGameRules.UseNonSpecialLine(usething: Pmobj_t);
var
  sound: integer;
  pheight: fixed_t;
begin
  if usething.player <> nil then
  begin
    pheight := usething.z + (usething.height div 2);
    if (opentop < pheight) or (openbottom > pheight) then
    begin
      case Pplayer_t(usething.player)._class of
        PCLASS_FIGHTER:
          sound := Ord(SFX_PLAYER_FIGHTER_FAILED_USE);
        PCLASS_CLERIC:
          sound := Ord(SFX_PLAYER_CLERIC_FAILED_USE);
        PCLASS_MAGE:
          sound := Ord(SFX_PLAYER_MAGE_FAILED_USE);
        PCLASS_PIG:
          sound := Ord(SFX_PIG_ACTIVE1);
      else
        sound := Ord(SFX_NONE);
      end;
      S_StartSound(usething, sound);
    end;
  end;
end;

class function TMapGameRules.UseSpecialLine(usething: Pmobj_t; li: Pline_t; side: integer): boolean;
begin
  if side = 1 then
  begin
    result := false;  // don't use back sides
    exit;
  end;

  P_ActivateLine(li, usething, 0, SPAC_USE);

  result := false;  // can't use for than one special line in a row
end;

class function TMapGameRules.IsConcussionProof(thing: Pmobj_t): boolean;
begin
  // Bosses take no damage from concussion.
  result := thing.flags2 and MF2_BOSS <> 0;
end;

class procedure TMapGameRules.SetBlastExtent(const distance: integer; const dmsource: boolean);
begin
  bombdistance := distance;
  damagesource := dmsource;
end;

class function TMapGameRules.OutOfBlast(thing, bombspot, bombsource: Pmobj_t): boolean;
begin
  if not damagesource and (thing = bombsource) then
  begin // don't damage the source of the explosion
    result := true;
    exit;
  end;

  if abs(thing.z - bombspot.z) > 2 * bombdistance * FRACUNIT then
  begin // too high/low
    result := true;
    exit;
  end;

  result := false;
end;

class function TMapGameRules.BlastDamage(thing: Pmobj_t; const bombdamage, dist: integer): integer;
begin
  // OK to damage, target is in direct path
  result := (bombdamage * (bombdistance - dist) div bombdistance) + 1;
  if thing.player <> nil then
    result := _SHR2(result);
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
  result := false;
end;

class procedure TMapGameRules.BlastedHitsWall(mo: Pmobj_t);
begin
  if mo.flags2 and MF2_BLASTED <> 0 then
    P_DamageMobj(mo, nil, nil, _SHR(mo.mass, 5));
end;

class function TMapGameRules.CheckLineBlocking(ld: Pline_t): boolean;
begin
  if G_PlayingEngineVersion <= VERSION206 then
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      begin
        if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
          P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
        TMapRoutines.P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
        result := false;  // explicitly blocking everything
        TMapCheck.BounceLine := ld;
        exit;
      end;
    end;

    if (TMapCheck.Thing.player = nil) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
    begin
      if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
        P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
      result := false;  // block monsters only
      TMapCheck.BounceLine := ld;
      exit;
    end;
  end
  else
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
        P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
      TMapRoutines.P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
      result := false;  // explicitly blocking everything
      TMapCheck.BounceLine := ld;
      exit;
    end;

    if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      if (TMapCheck.Thing.player = nil) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
      begin
        if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
          P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
        result := false;  // block monsters only
        TMapCheck.BounceLine := ld;
        exit;
      end;
  end;

  result := true;
end;

class function TMapGameRules.CheckLineBlockingTM(ld: Pline_t): boolean;
begin
  if G_PlayingEngineVersion <= VERSION206 then
  begin
    if ld.flags and ML_BLOCKING <> 0 then
      if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      begin
        if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
          P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
        TMapRoutines.P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
        result := false;  // explicitly blocking everything
        TMapCheck.BounceLine := ld;
        exit;
      end;

    if (TMapCheck.Thing.player = nil) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
    begin
      if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
        P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
      result := false;  // block monsters only
      TMapCheck.BounceLine := ld;
      exit;
    end;
  end
  else
  begin
    if ld.flags and ML_BLOCKING <> 0 then
    begin
      if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
        P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
      TMapRoutines.P_CheckForPushSpecial(ld, 0, TMapCheck.Thing);
      result := false;  // explicitly blocking everything
      TMapCheck.BounceLine := ld;
      exit;
    end;

    if TMapCheck.Thing.flags3_ex and MF3_EX_NOBLOCKMONST = 0 then
      if (TMapCheck.Thing.player = nil) and (ld.flags and ML_BLOCKMONSTERS <> 0) then
      begin
        if TMapCheck.Thing.flags2 and MF2_BLASTED <> 0 then
          P_DamageMobj(TMapCheck.Thing, nil, nil, _SHR(TMapCheck.Thing.mass, 5));
        result := false;  // block monsters only
        TMapCheck.BounceLine := ld;
        exit;
      end;
  end;

  result := true;
end;

class function TMapGameRules.StepsOnBlockingThing(thing: Pmobj_t): boolean;
begin
  if (BlockingMobj = nil) or
     (BlockingMobj.player <> nil) or
     (thing.player = nil) then
  begin
    result := false;
    exit;
  end;

  if (BlockingMobj.z + BlockingMobj.height - thing.z > 24 * FRACUNIT) or
     (Psubsector_t(BlockingMobj.subsector).sector.ceilingheight - (BlockingMobj.z + BlockingMobj.height) < thing.height) or
     (TMapCheck.CeilingZ - (BlockingMobj.z + BlockingMobj.height) < thing.height) then
  begin
    result := false;
    exit;
  end;

  result := true;
end;

class function TMapGameRules.IgnoresCeilingFit(thing: Pmobj_t): boolean;
begin
  result := (thing.flags and MF_TELEPORT <> 0) or
    (thing._type = Ord(MT_LIGHTNING_CEILING)) or
    (thing.flags2 and MF2_FLY <> 0);
end;

class function TMapGameRules.FlightBlocked(thing: Pmobj_t): boolean;
begin
  if thing.flags2 and MF2_FLY <> 0 then
  begin
    if thing.z + thing.height > TMapCheck.CeilingZ then
    begin
      thing.momz := thing.momz -8 * FRACUNIT;
      result := true;
      exit;
    end;

    if (thing.z < TMapCheck.FloorZ) and (TMapCheck.FloorZ - TMapCheck.DropOffZ > 24 * FRACUNIT) then
    begin
      thing.momz := 8 * FRACUNIT;
      result := true;
      exit;
    end;

  end;

  result := false;
end;

class function TMapGameRules.StepTooHighOnFoot(thing: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.IgnoresStepHeight(thing: Pmobj_t): boolean;
begin
  // The Minotaur floor fire (MT_MNTRFX2) can step up any amount
  result := (thing.flags and MF_TELEPORT <> 0) or
    (thing._type = Ord(MT_MNTRFX2)) or
    (thing._type = Ord(MT_LIGHTNING_FLOOR));
end;

class function TMapGameRules.MissileStepTooHigh(thing: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.IgnoresDropoff(thing: Pmobj_t): boolean;
begin
  // Can't move over a dropoff unless it's been blasted
  result := thing.flags2 and MF2_BLASTED <> 0;
end;

class function TMapGameRules.CannotLeaveFloorPic(thing: Pmobj_t): boolean;
begin
  result := thing.flags2 and MF2_CANTLEAVEFLOORPIC <> 0;
end;

class procedure TMapGameRules.UpdateFloorClip(thing: Pmobj_t);
begin
  if thing.flags2 and MF2_FLOORCLIP <> 0 then
  begin
    if (thing.z = Psubsector_t(thing.subsector).sector.floorheight) and
       (P_GetThingFloorType(thing) >= FLOOR_LIQUID) then
      thing.floorclip := FOOTCLIPSIZE
    else
      thing.floorclip := 0;
  end;
end;

class procedure TMapGameRules.CrossSpecialLine(ld: Pline_t; oldside: integer; thing: Pmobj_t);
begin
  if thing.player <> nil then
  begin
    P_ActivateLine(ld, thing, oldside, SPAC_CROSS);
  end
  else if thing.flags2 and MF2_MCROSS <> 0 then
  begin
    P_ActivateLine(ld, thing, oldside, SPAC_MCROSS);
  end
  else if thing.flags2 and MF2_PCROSS <> 0 then
  begin
    P_ActivateLine(ld, thing, oldside, SPAC_PCROSS);
  end;
end;

class function TMapGameRules.CheckThingContact(thing: Pmobj_t): boolean;
var
  damage: integer;
  lmo: Pmobj_t;
begin
  BlockingMobj := thing;

  if TMapCheck.Thing.flags2 and MF2_PASSMOBJ <> 0 then
  begin // check if a mobj passed over/under another object

    if (TMapCheck.Thing._type = Ord(MT_BISHOP)) and (thing._type = Ord(MT_BISHOP)) then
    begin // don't let bishops fly over other bishops
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
    if TMapCheck.Thing._type = Ord(MT_MINOTAUR) then
    begin
      // Slamming minotaurs shouldn't move non-creatures
      if  thing.flags and MF_COUNTKILL = 0 then
      begin
        result := false;
        exit;
      end;
    end
    else if TMapCheck.Thing._type = Ord(MT_HOLY_FX) then
    begin
      if (thing.flags and MF_SHOOTABLE <> 0) and (thing <> TMapCheck.Thing.target) then
      begin
        if TGameSession.NetGame and (TGameSession.DeathMatch = 0) and (thing.player <> nil) then
        begin // don't attack other co-op players
          result := true;
          exit;
        end;

        if (thing.flags2_ex and MF2_EX_REFLECTIVE <> 0) and
           ((thing.player <> nil) or (thing.flags2 and MF2_BOSS <> 0) or (thing.flags_ex and MF_EX_BOSS <> 0)) then
        begin
          TMapCheck.Thing.special1 := NativeInt(TMapCheck.Thing.target);
          TMapCheck.Thing.target := thing;
          result := true;
          exit;
        end;

        if (thing.flags and MF_COUNTKILL <> 0) or (thing.player <> nil) then
          TMapCheck.Thing.special1 := NativeInt(thing);

        if P_Random < 96 then
        begin
          damage := 12;
          if (thing.player <> nil) or (thing.flags2 and MF2_BOSS <> 0) or (thing.flags_ex and MF_EX_BOSS <> 0) then
          begin
            damage := 3;
            // ghost burns out faster when attacking players/bosses
            TMapCheck.Thing.health := TMapCheck.Thing.health - 6;
          end;
          P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, damage);
          if P_Random < 128 then
          begin
            P_SpawnMobj(TMapCheck.Thing.x, TMapCheck.Thing.y, TMapCheck.Thing.z, Ord(MT_HOLY_PUFF));
            S_StartSound(TMapCheck.Thing, Ord(SFX_SPIRIT_ATTACK));
            if (thing.flags and MF_COUNTKILL <> 0) and (P_Random < 128) and not S_GetSoundPlayingInfo(thing, Ord(SFX_PUPPYBEAT)) then
            begin
              if (thing._type = Ord(MT_CENTAUR)) or
                 (thing._type = Ord(MT_CENTAURLEADER)) or
                 (thing._type = Ord(MT_ETTIN)) then
                S_StartSound(thing, Ord(SFX_PUPPYBEAT));
            end;
          end;
        end;

        if thing.health <= 0 then
          TMapCheck.Thing.special1 := 0;
      end;
      result := true;
      exit;
    end;
    damage := ((P_Random mod 8) + 1) * TMapCheck.Thing.damage;
    P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing, damage);
    TMapCheck.Thing.flags := TMapCheck.Thing.flags and not MF_SKULLFLY;
    TMapCheck.Thing.momx := 0;
    TMapCheck.Thing.momy := 0;
    TMapCheck.Thing.momz := 0;
    P_SetMobjState(TMapCheck.Thing, statenum_t(TMapCheck.Thing.info.seestate));
    result := false;
    exit;
  end;

  // Check for blasted thing running into another
  if (TMapCheck.Thing.flags2 and MF2_BLASTED <> 0) and (thing.flags and MF_SHOOTABLE <> 0) then
  begin
    if (thing.flags2 and MF2_BOSS = 0) and
       (thing.flags_ex and MF_EX_BOSS = 0) and
       (thing.flags and MF_COUNTKILL <> 0) then
    begin
      thing.momx := thing.momx + TMapCheck.Thing.momx;
      thing.momy := thing.momy + TMapCheck.Thing.momy;
      if thing.momx + thing.momy > 3 * FRACUNIT then
      begin
        damage := (TMapCheck.Thing.mass div 100) + 1;
        P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing, damage);
        damage := (thing.mass div 100) + 1;
        P_DamageMobj(TMapCheck.Thing, thing, thing, _SHR2(damage));
      end;
      result := false;
      exit;
    end;
  end;

  // Check for missile
  if TMapCheck.Thing.flags and MF_MISSILE <> 0 then
  begin
    // Check for a non-shootable mobj
    if thing.flags2 and MF2_NONSHOOTABLE <> 0 then
    begin
      result := true;
      exit;
    end;

    // Check if it went over / under
    if TMapCheck.Thing.z > thing.z + thing.height then
    begin // Over thing
      result := true;
      exit;
    end;

    if TMapCheck.Thing.z + TMapCheck.Thing.height < thing.z then
    begin // Under thing
      result := true;
      exit;
    end;

    if TMapCheck.Thing.flags2 and MF2_FLOORBOUNCE <> 0 then
    begin
      result := (TMapCheck.Thing.target = thing) or (thing.flags and MF_SOLID = 0);
      exit;
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

    if (TMapCheck.Thing._type = Ord(MT_LIGHTNING_FLOOR)) or
       (TMapCheck.Thing._type = Ord(MT_LIGHTNING_CEILING)) then
    begin
      if (thing.flags and MF_SHOOTABLE <> 0) and (thing <> TMapCheck.Thing.target) then
      begin
        if thing.mass <> MAXINT then
        begin
          thing.momx := thing.momx + _SHR(TMapCheck.Thing.momx, 4);
          thing.momy := thing.momy + _SHR(TMapCheck.Thing.momy, 4);
        end;

        if (thing.player = nil) and
           (thing.flags2 and MF2_BOSS = 0) and
           (thing.flags_ex and MF_EX_BOSS = 0) and
           (TTickState.LevelTime and 1 = 0) then
        begin
          if (thing._type = Ord(MT_CENTAUR)) or
             (thing._type = Ord(MT_CENTAURLEADER)) then
          begin // Lightning does more damage to centaurs
            P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, 9);
          end
          else
          begin
            P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, 3);
          end;

          if not S_GetSoundPlayingInfo(TMapCheck.Thing, Ord(SFX_MAGE_LIGHTNING_ZAP)) then
            S_StartSound(TMapCheck.Thing, Ord(SFX_MAGE_LIGHTNING_ZAP));

          if (thing.flags and MF_COUNTKILL <> 0) and
             (P_Random < 64) and
             (not S_GetSoundPlayingInfo(thing, Ord(SFX_PUPPYBEAT))) then
          begin
            if (thing._type = Ord(MT_CENTAUR)) or
               (thing._type = Ord(MT_CENTAURLEADER)) or
               (thing._type = Ord(MT_ETTIN)) then
              S_StartSound(thing, Ord(SFX_PUPPYBEAT));
          end;
        end;
        dec(TMapCheck.Thing.health);
        if (TMapCheck.Thing.health <= 0) or (thing.health <= 0) then
        begin
          result := false;
          exit;
        end;
        if TMapCheck.Thing._type = Ord(MT_LIGHTNING_FLOOR) then
        begin
          if (TMapCheck.Thing.special2 <> 0) and
             (Pmobj_t(TMapCheck.Thing.special2).special1 = 0) then
            Pmobj_t(TMapCheck.Thing.special2).special1 := NativeInt(thing);
        end
        else if TMapCheck.Thing.special1 = 0 then
          TMapCheck.Thing.special1 := NativeInt(thing);
      end;
      result := true; // lightning zaps through all sprites
      exit;
    end
    else if TMapCheck.Thing._type = Ord(MT_LIGHTNING_ZAP) then
    begin
      if (thing.flags and MF_SHOOTABLE <> 0) and (thing <> TMapCheck.Thing.target) then
      begin
        lmo := Pmobj_t(TMapCheck.Thing.special2);
        if lmo <> nil then
        begin
          if lmo._type = Ord(MT_LIGHTNING_FLOOR) then
          begin
            if (lmo.special2 <> 0) and
               (Pmobj_t(lmo.special2).special1 = 0) then
              Pmobj_t(lmo.special2).special1 := NativeInt(thing);
          end
          else if lmo.special1 = 0 then
            lmo.special1 := NativeInt(thing);
          if TTickState.LevelTime and 3 = 0 then
            dec(lmo.health);
        end;
      end;
    end
    else if (TMapCheck.Thing._type = Ord(MT_MSTAFF_FX2)) and (thing <> TMapCheck.Thing.target) then
    begin
      if (thing.player = nil) and (thing.flags2 and MF2_BOSS = 0) and (thing.flags_ex and MF_EX_BOSS = 0) then
      begin
        case thing._type of
          Ord(MT_FIGHTER_BOSS),  // these not flagged boss
          Ord(MT_CLERIC_BOSS),  // so they can be blasted
          Ord(MT_MAGE_BOSS):
            begin
            end;
        else
          begin
            P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, 10);
            result := true;
            exit;
          end;
        end;
      end;
    end;

    if (TMapCheck.Thing.target <> nil) and (
	   (TMapCheck.Thing.target._type = thing._type) or
       // JVAL: 20211126 - Inherited actors do not hurt each other
       (Info_GetInheritance(TMapCheck.Thing.target.info) = Info_GetInheritance(thing.info))) then
    begin
      if (G_PlayingEngineVersion <= VERSION206) or TCommonFriendActions.P_ProjectileImmune(thing, TMapCheck.Thing.target) then
      begin
        // Don't hit same species as originator
        if thing = TMapCheck.Thing.target then
        begin // Don't missile self
          result := true;
          exit;
        end;

        // Hit same species as originator, explode, no damage
        if (thing.player = nil) and (thing.flags2_ex and MF2_EX_MISSILEHURTSPECIES = 0) then
        begin
          result := false;
          exit;
        end;
      end;
    end;

    if thing.flags and MF_SHOOTABLE = 0 then
    begin
      // Didn't do any damage
      result := thing.flags and MF_SOLID = 0;
      exit;
    end;

    if TMapCheck.Thing.flags2 and MF2_RIP <> 0 then
    begin
      if (thing.flags and MF_NOBLOOD = 0) and
         (thing.flags2_ex and MF2_EX_REFLECTIVE = 0) and
         (thing.flags2 and MF2_INVULNERABLE = 0) and
         (thing.flags_ex and MF_EX_INVULNERABLE = 0) then
      begin // Ok to spawn some blood
        TMobjRoutines.P_RipperBlood(TMapCheck.Thing);
      end;

      damage := ((P_Random and 3) + 2) * TMapCheck.Thing.damage;

      A_RipSound1(TMapCheck.Thing);

      P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, damage);

      P_PushByContact(thing);

      TMapCheck.NumSpecHit := 0;

      result := true;
      exit;
    end;

    // Do damage
    if TMapCheck.Thing.flags3_ex and MF3_EX_ABSOLUTEDAMAGE <> 0 then
      damage := TMapCheck.Thing.info.damage
    else if TMapCheck.Thing.flags3_ex and MF3_EX_STRIFEDAMAGE <> 0 then
      damage := ((P_Random mod 4) + 1) * TMapCheck.Thing.info.damage
    else
      damage := ((P_Random mod 8) + 1) * TMapCheck.Thing.damage;
    if damage > 0 then
    begin
      if (thing.flags and MF_NOBLOOD = 0) and
         (thing.flags2_ex and MF2_EX_REFLECTIVE = 0) and
         (thing.flags2 and MF2_INVULNERABLE = 0) and
         (thing.flags_ex and MF_EX_INVULNERABLE = 0) and
         (TMapCheck.Thing._type <> Ord(MT_TELOTHER_FX1)) and
         (TMapCheck.Thing._type <> Ord(MT_TELOTHER_FX2)) and
         (TMapCheck.Thing._type <> Ord(MT_TELOTHER_FX3)) and
         (TMapCheck.Thing._type <> Ord(MT_TELOTHER_FX4)) and
         (TMapCheck.Thing._type <> Ord(MT_TELOTHER_FX5)) and
         (P_Random < 192) then
        TMobjRoutines.P_BloodSplatter(TMapCheck.Thing.x, TMapCheck.Thing.y, TMapCheck.Thing.z, thing);
      P_DamageMobj(thing, TMapCheck.Thing, TMapCheck.Thing.target, damage);
    end;

    // don't traverse any more
    result := false;
    exit;
  end;

  P_PushByContact(thing);

  // check for special pickup
  result := P_ContactPickup(thing);
end;

class function TMapGameRules.CanBePushed(thing: Pmobj_t): boolean;
begin
  result := (thing.flags2 and MF2_PUSHABLE <> 0) and (TMapCheck.Thing.flags2 and MF2_CANNOTPUSH = 0);
end;

class function TMapGameRules.QuarterMomentum(const momentum: fixed_t): fixed_t;
begin
  result := _SHR2(momentum);
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
  P_ActivateLine(li, shootthing, 0, SPAC_IMPACT);
end;

class function TMapGameRules.ShotPassesThrough(th: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMapGameRules.ShotHitsThing(intr: Pintercept_t; th: Pmobj_t; x, y, z: fixed_t): boolean;
begin
  P_SpawnPuff(x, y, z);

  if TMapAim.Damage <> 0 then
  begin
    if (intr.d.thing.flags and MF_NOBLOOD = 0) and
       (intr.d.thing.flags2 and MF2_INVULNERABLE = 0) and
       (intr.d.thing.flags_ex and MF_EX_INVULNERABLE = 0) then
    begin
      if (PuffType = MT_AXEPUFF) or (PuffType = MT_AXEPUFF_GLOW) then
        TMobjRoutines.P_BloodSplatter2(x, y, z, intr.d.thing);
      if P_Random < 192 then
        TMobjRoutines.P_BloodSplatter(x, y, z, intr.d.thing);
    end;

    if PuffType = MT_FLAMEPUFF2 then
    // Cleric FlameStrike does fire damage
      P_DamageMobj(th, @LavaInflictor, TMapAim.ShootThing, TMapAim.Damage)
    else
      P_DamageMobj(th, TMapAim.ShootThing, TMapAim.ShootThing, TMapAim.Damage);
  end;

  result := false; // don't go any farther
end;

//==============================================================================
// P_CheckForPushSpecial
//
// CheckForPushSpecial
//
//==============================================================================
class procedure TMapRoutines.P_CheckForPushSpecial(line: Pline_t; side: integer; mobj: Pmobj_t);
begin
  if line.special <> 0 then
  begin
    if mobj.flags2 and MF2_PUSHWALL <> 0 then
      P_ActivateLine(line, mobj, side, SPAC_PUSH)
    else if mobj.flags2 and MF2_IMPACT <> 0 then
      P_ActivateLine(line, mobj, side, SPAC_IMPACT);
  end;
end;


//==============================================================================
//
// PIT_ChangeSector
//
//==============================================================================
class function TMapGameRules.IsCrushedBody(thing: Pmobj_t): boolean;
begin
  result := (thing.flags and MF_CORPSE <> 0) and (thing.health <= 0);
end;

class function TMapGameRules.CrunchBody(thing: Pmobj_t): boolean;
var
  st: integer;
begin
  if thing.flags and MF_NOBLOOD <> 0 then
    P_RemoveMobj(thing)
  else
  begin
    st := Ord(S_GIBS1);

    if G_PlayingEngineVersion >= VERSION207 then
    begin
      if thing.flags4_ex and MF4_EX_DONTGIB = 0 then
      begin
        if thing.info.crushstate > 0 then
        begin
          st := thing.info.crushstate;
          if thing.bloodcolor <> 0 then
            R_SetMobjBloodTranslation(thing, thing.bloodcolor);
        end;
        thing.flags4_ex := thing.flags4_ex or MF4_EX_DONTGIB;
      end
      else
      begin
        result := true;            // keep checking
        exit;
      end;
    end;

    if thing.state <> @states[st] then
    begin
      P_SetMobjState(thing, statenum_t(st));
      thing.height := 0;
      thing.radius := 0;
      S_StartSound(thing, Ord(SFX_PLAYER_FALLING_SPLAT));
    end;
  end;
  result := true;            // keep checking
  exit;
end;

class function TMapGameRules.IsDroppedItem(thing: Pmobj_t): boolean;
begin
  result := thing.flags2 and MF2_DROPPED <> 0;
end;

class procedure TMapGameRules.CrushBlood(thing: Pmobj_t);
var
  mo: Pmobj_t;
begin
  // spray blood in a random direction
  if (thing.flags and MF_NOBLOOD = 0) and
     (thing.flags2 and MF2_INVULNERABLE = 0) and
     (thing.flags_ex and MF_EX_INVULNERABLE = 0) then
  begin
    // spray blood in a random direction
    mo := P_SpawnMobj(thing.x, thing.y, thing.z + thing.height div 2, Ord(MT_BLOOD));

    mo.momx := _SHL(P_Random - P_Random, 12);
    mo.momy := _SHL(P_Random - P_Random, 12);
  end;
end;

type
  /// <summary>
  ///   The routines that only this unit calls, as static methods with the text and the names of the old free routines
  ///   (issue #185, wave 11): same unit, no virtual call and no interface, so the compiler produces the code it produced before
  /// </summary>
  TMapLocalRoutines = class sealed
  public
    class function PIT_ThrustStompThing(thing: Pmobj_t): boolean; static;
    class function PTR_PuzzleItemTraverse(intr: Pintercept_t): boolean; static;
    class function PTR_BounceTraverse(intr: Pintercept_t): boolean; static;
  end;

//==============================================================================
// PIT_ThrustStompThing
//
// MOVEMENT ITERATOR FUNCTIONS
//
//==============================================================================
class function TMapLocalRoutines.PIT_ThrustStompThing(thing: Pmobj_t): boolean;
var
  blockdist: fixed_t;
begin
  if thing.flags and MF_SHOOTABLE = 0 then
  begin
    result := true;
    exit;
  end;

  blockdist := thing.radius + tsthing.radius;
  if (abs(thing.x - tsthing.x) >= blockdist) or
      (abs(thing.y - tsthing.y) >= blockdist) or
      (thing.z > tsthing.z + tsthing.height) then
  begin
    result := true;            // didn't hit it
    exit;
  end;

  if thing = tsthing then
  begin
    result := true;            // don't clip against self
    exit;
  end;

  P_DamageMobj(thing, tsthing, tsthing, 10001);
  tsthing.args[1] := 1;  // Mark thrust thing as bloody

  result := true;
end;

//==============================================================================
//
// PIT_ThrustSpike
//
//==============================================================================
class procedure TMapRoutines.PIT_ThrustSpike(actor: Pmobj_t);
var
  xl, xh, yl, yh, bx, by: integer;
  x0, x2, y0, y2: integer;
  r: integer;
begin
  tsthing := actor;
  r := actor.info.radius;
  x0 := actor.x - r;
  x2 := actor.x + r;
  y0 := actor.y - r;
  y2 := actor.y + r;

  if internalblockmapformat then
  begin
    xl := MapBlockIntX(int64(x0) - int64(bmaporgx) - MAXRADIUS);
    xh := MapBlockIntX(int64(x2) - int64(bmaporgx) + MAXRADIUS);
    yl := MapBlockIntY(int64(y0) - int64(bmaporgy) - MAXRADIUS);
    yh := MapBlockIntY(int64(y2) - int64(bmaporgy) + MAXRADIUS);
  end
  else
  begin
    xl := MapBlockInt(x0 - bmaporgx - MAXRADIUS);
    xh := MapBlockInt(x2 - bmaporgx + MAXRADIUS);
    yl := MapBlockInt(y0 - bmaporgy - MAXRADIUS);
    yh := MapBlockInt(y2 - bmaporgy + MAXRADIUS);
  end;

  // stomp on any things contacted
  for bx := xl to xh do
    for by := yl to yh do
      P_BlockThingsIterator(bx, by, TMapLocalRoutines.PIT_ThrustStompThing);
end;

//
// PTR_PuzzleItemTraverse
//
const
  USE_PUZZLE_ITEM_SPECIAL = 129;

var
  PuzzleItemUser: Pmobj_t;
  PuzzleItemType: integer;
  PuzzleActivated: boolean;

//==============================================================================
//
// PTR_PuzzleItemTraverse
//
//==============================================================================
class function TMapLocalRoutines.PTR_PuzzleItemTraverse(intr: Pintercept_t): boolean;
var
  mobj: Pmobj_t;
  sound: integer;
begin
  if intr.isaline then
  begin // Check line
    if intr.d.line.special <> USE_PUZZLE_ITEM_SPECIAL then
    begin
      P_LineOpening(intr.d.line, true);
      if openrange <= 0 then
      begin
        sound := Ord(SFX_NONE);
        if PuzzleItemUser.player <> nil then
        begin
          case Pplayer_t(PuzzleItemUser.player)._class of
            PCLASS_FIGHTER:
              sound := Ord(SFX_PUZZLE_FAIL_FIGHTER);
            PCLASS_CLERIC:
              sound := Ord(SFX_PUZZLE_FAIL_CLERIC);
            PCLASS_MAGE:
              sound := Ord(SFX_PUZZLE_FAIL_MAGE);
          end;
          S_StartSound(PuzzleItemUser, sound);
        end;
        result := false; // can't use through a wall
        exit;
      end;

      result := true; // Continue searching
      exit;
    end;

    if P_PointOnLineSide(PuzzleItemUser.x, PuzzleItemUser.y, intr.d.line) = 1 then
    begin // Don't use back sides
      result := false;
      exit;
    end;

    if PuzzleItemType <> intr.d.line.arg1 then
    begin // Item type doesn't match
      result := false;
      exit;
    end;

    P_StartACS(intr.d.line.arg2, 0, @intr.d.line.arg3, PuzzleItemUser, intr.d.line, 0);
    intr.d.line.special := 0;
    PuzzleActivated := true;
    result := false; // Stop searching
    exit;
  end;

  // Check thing
  mobj := intr.d.thing;
  if mobj.special <> USE_PUZZLE_ITEM_SPECIAL then
  begin // Wrong special
    result := true;
    exit;
  end;

  if PuzzleItemType <> mobj.args[0] then
  begin // Item type doesn't match
    result := true;
    exit;
  end;

  P_StartACS(mobj.args[1], 0, @mobj.args[2], PuzzleItemUser, nil, 0);
  mobj.special := 0;
  PuzzleActivated := true;
  result := false; // Stop searching
end;

//==============================================================================
//
// P_UsePuzzleItem
//
// Returns true if the puzzle item was used on a line or a thing.
//
//==============================================================================
class function TMapRoutines.P_UsePuzzleItem(player: Pplayer_t; itemType: integer): boolean;
var
  angle: integer;
  x1, y1, x2, y2: fixed_t;
begin
  PuzzleItemType := itemType;
  PuzzleItemUser := player.mo;
  PuzzleActivated := false;
  angle := player.mo.angle shr ANGLETOFINESHIFT;
  x1 := player.mo.x;
  y1 := player.mo.y;
  x2 := x1 + USERANGEINT * finecosine[angle];
  y2 := y1 + USERANGEINT * finesine[angle];
  P_PathTraverse(x1, y1, x2, y2, PT_ADDLINES or PT_ADDTHINGS, TMapLocalRoutines.PTR_PuzzleItemTraverse);
  result := PuzzleActivated;
end;

//==============================================================================
//
// PTR_BounceTraverse
//
//==============================================================================
class function TMapLocalRoutines.PTR_BounceTraverse(intr: Pintercept_t): boolean;
var
  li: Pline_t;

  // the line does block movement, see if it is closer than best so far
  procedure bounceblocking;
  begin
    if intr.frac < TMapSlide.BestFrac then
    begin
      secondslidefrac := TMapSlide.BestFrac;
      secondslideline := TMapSlide.BestLine;
      TMapSlide.BestFrac := intr.frac;
      TMapSlide.BestLine := li;
    end;
  end;

begin
  if not intr.isaline then
    I_Error('PTR_BounceTraverse(): not a line?');

  li := intr.d.line;
  if li.flags and ML_TWOSIDED = 0 then
  begin
    if P_PointOnLineSide(TMapSlide.Mobj.x, TMapSlide.Mobj.y, li) <> 0 then
    begin
      result := true; // don't hit the back side
      exit;
    end;
    bounceblocking;
    result := false;
    exit;
  end;

  P_LineOpening(li, true);  // set openrange, opentop, openbottom
  if openrange < TMapSlide.Mobj.height then
  begin
    bounceblocking; // doesn't fit
    result := false;
    exit;
  end;

  if opentop - TMapSlide.Mobj.z < TMapSlide.Mobj.height then
  begin
    bounceblocking; // mobj is too high
    result := false;
    exit;
  end;

  result := true; // this line doesn't block movement
end;

//==============================================================================
//
// P_BounceWall
//
//==============================================================================
class procedure TMapRoutines.P_BounceWall(mo: Pmobj_t);
var
  leadx, leady: fixed_t;
  side: integer;
  lineangle, moveangle, deltaangle: angle_t;
  movelen: fixed_t;
begin
  TMapSlide.Mobj := mo;
//
// trace along the three leading corners
//
  if mo.momx > 0 then
    leadx := mo.x + mo.radius
  else
    leadx := mo.x - mo.radius;

  if mo.momy > 0 then
    leady := mo.y + mo.radius
  else
    leady := mo.y - mo.radius;

  TMapSlide.BestFrac := FRACUNIT + 1;
  P_PathTraverse(leadx, leady, leadx + mo.momx, leady + mo.momy, PT_ADDLINES, TMapLocalRoutines.PTR_BounceTraverse);

  side := P_PointOnLineSide(mo.x, mo.y, TMapSlide.BestLine);
  lineangle := R_PointToAngle2(0, 0, TMapSlide.BestLine.dx, TMapSlide.BestLine.dy);
  if side = 1 then
    lineangle := lineangle + ANG180;
  moveangle := R_PointToAngle2(0, 0, mo.momx, mo.momy);
  deltaangle := (2 * lineangle) - moveangle;

  deltaangle := deltaangle shr ANGLETOFINESHIFT;

  movelen := P_AproxDistance(mo.momx, mo.momy);
  movelen := FixedMul(movelen, 3 * FRACUNIT div 4); // friction
  if movelen < FRACUNIT then
    movelen := 2 * FRACUNIT;
  mo.momx := FixedMul(movelen, finecosine[deltaangle]);
  mo.momy := FixedMul(movelen, finesine[deltaangle]);
end;
end.
