{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Strife for the map objects (p_mobj)       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.MobjRules;

interface

// The same units, in the same order, as the old p_mobj.pas of the game: a name that two units
// declare is found where it was found before
uses
  p_mobj_h,
  tables,
// We need the WAD data structure for Map things,
// from the THINGS lump.
  doomdata,
// States are tied to finite states are
//  tied to animation frames.
// Needs precompiled tables/data structures.
  info_h,
  p_udmf,
  m_fixed,
  d_player,
  r_defs;

type
  /// <summary>
  ///   What Strife does differently in the code of the map objects of p_mobj. The unit of the
  ///   same name in the folder of each game is chosen by the project, so the calls are bound at
  ///   compile time: no virtual call and no interface, this is the path of every thing at
  ///   every tic
  /// </summary>
  /// <remarks>
  ///   The bodies are the lines of the old Strife\p_mobj.pas, moved as they were: the methods keep
  ///   the names of the parameters and the style of the routine they come from. The methods
  ///   named after a routine of p_mobj (SpawnPuff, HitFloor...) are that routine of the game
  /// </remarks>
  TMobjGameRules = class sealed
  public
    const
      /// <summary>A seeker missile that does not move stops seeking</summary>
      SeekerNeedsSpeed = True;
      /// <summary>The flags of a thing that the floor does not slow down</summary>
      NoFrictionFlags = MF_MISSILE or MF_BOUNCE;
      /// <summary>A thing whose state ends goes on through the states of no tics in the same tic</summary>
      CyclesStatesWhileNoTics = False;
      /// <summary>The dead monsters respawn (nightmare, -respawn)</summary>
      MonstersRespawn = True;

    /// <summary>P_SetMobjState: what the thing remembers of the state it leaves</summary>
    class procedure KeepPreviousState(mobj: Pmobj_t); static; inline;
    /// <summary>P_SetMobjStateNF: sets a state without calling its action</summary>
    class function SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean; static;
    /// <summary>The state of a missile that explodes</summary>
    class function DeathState(mo: Pmobj_t): statenum_t; static; inline;
    /// <summary>The tics of an exploding missile: shortened at random and never less than one, or not</summary>
    class procedure RandomizeExplosionTics(mo: Pmobj_t); static;
    /// <summary>The sound of a missile that explodes</summary>
    class procedure ExplosionSound(mo: Pmobj_t); static;
    /// <summary>What P_RemoveMobj does first: the queue of the items that respawn, the lists of the game</summary>
    class procedure BeforeRemove(mobj: Pmobj_t); static;
    /// <summary>Frees the list of the sectors touched by the last move (the games with the sector nodes of Boom)</summary>
    class procedure ReleaseSectorList; static;
    /// <summary>An item queued at this time does not respawn yet</summary>
    class function ItemRespawnWaits(const AQueuedTime: integer): boolean; static; inline;
    /// <summary>The fog and the sound of an item that respawns</summary>
    class procedure SpawnItemFog(x, y, z: fixed_t; mthing: Pmapthing_t); static;
    /// <summary>ONFLOORZ, ONCEILINGZ or the floating height a thing of this type is spawned at</summary>
    class function SpawnHeightOfType(const i: integer): fixed_t; static;
    /// <summary>The tics of a missile just spawned: shortened at random, or not</summary>
    class procedure RandomizeSpawnTics(th: Pmobj_t); static;
    /// <summary>A new missile moves half a step with "div 2" (true) or with a shift (false)</summary>
    class function HalvesMissileStepByDivision: boolean; static; inline;
    /// <summary>P_SpawnMissileAngleZSpeed keeps the random generator as it was (Hexen does not)</summary>
    class procedure SaveRandom; static; inline;
    /// <summary>Puts back what SaveRandom kept</summary>
    class procedure RestoreRandom; static; inline;
    /// <summary>The sound of a missile that is spawned</summary>
    class procedure MissileSeeSound(mo: Pmobj_t); static;
    /// <summary>The thing a seeker missile follows</summary>
    class function SeekerTarget(actor: Pmobj_t): Pmobj_t; static; inline;
    /// <summary>The speed a seeker missile turns with</summary>
    class function SeekerSpeed(actor: Pmobj_t): fixed_t; static; inline;
    /// <summary>The flat that gives the terrain under a thing</summary>
    class function TerrainFloorPic(thing: Pmobj_t): integer; static;
    /// <summary>spawnmobj: the word asks for the floating height</summary>
    class function IsFloatHeightName(const tmp: string): boolean; static;
    /// <summary>spawnmobj: the floating height</summary>
    class function FloatSpawnZ: fixed_t; static; inline;
    /// <summary>summon: the radius of the player that summons</summary>
    class function SummonerRadius: fixed_t; static;
    /// <summary>Rebuilds the list of the things with a TID (only Hexen has one)</summary>
    class procedure CreateTIDList; static;

    /// <summary>spawnmobj and summon are refused now (no level, a demo, a net game)</summary>
    class function ConsoleSpawnForbidden: boolean; static;
    /// <summary>P_SpawnPlayer of the game</summary>
    class function SpawnPlayer(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t; static;
    /// <summary>P_SpawnMapThing of the game</summary>
    class function SpawnMapThing(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t; static;
    /// <summary>P_SpawnPuff of the game</summary>
    class procedure SpawnPuff(x, y, z: fixed_t); static;
    /// <summary>P_SpawnMissile of the game</summary>
    class function SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t; static;
    /// <summary>P_SpawnMissileXYZ of the game</summary>
    class function SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t; static;
    /// <summary>P_SpawnPlayerMissile of the game</summary>
    class function SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t; static;
    /// <summary>P_HitFloor of the game</summary>
    class function HitFloor(thing: Pmobj_t): integer; static;
    /// <summary>P_XYMovement: the thing has no momentum (a monster thrown at its target stops here); true when there is nothing to move</summary>
    class function StoppedBeforeMoving(mo: Pmobj_t): boolean; static;
    /// <summary>P_XYMovement: the wind of the sector special pushes the thing; gives the special of the sector (0 where the game has no such winds)</summary>
    class function SectorWind(mo: Pmobj_t): integer; static;
    /// <summary>The thing is pushed by the wind of a sector</summary>
    class function HasWindThrust(mo: Pmobj_t): boolean; static; inline;
    /// <summary>A fast move backwards is done in two halves like a fast move forwards</summary>
    class function HalvesBackwardMoves: boolean; static; inline;
    /// <summary>P_XYMovement: the move was blocked (slide, bounce, explode, stop); true when the thing is gone or the movement is over</summary>
    class function BlockedMove(mo: Pmobj_t; ptryx, ptryy: fixed_t; var xmove, ymove: fixed_t): boolean; static;
    /// <summary>P_XYMovement: the friction of a thing in the air where the game has one (Strife); true when there is no more friction to apply</summary>
    class function AirborneFriction(mo: Pmobj_t; player: Pplayer_t; wasonfloorz, wasonslope: boolean; oldsector: Psector_t): boolean; static;
    /// <summary>P_XYMovement: the thing is in the air and gets no friction (unless it only left a sloped floor)</summary>
    class function FallsFree(mo: Pmobj_t; player: Pplayer_t): boolean; static; inline;
    /// <summary>P_XYMovement: a player that stops leaves the walking frames</summary>
    class procedure StopWalking(player: Pplayer_t); static;
    /// <summary>P_XYMovement: the friction of the floor (special is what SectorWind gave)</summary>
    class procedure ApplyFriction(mo: Pmobj_t; special: integer); static;
    /// <summary>P_MobjThinker: the thing is no more "just appeared"</summary>
    class procedure ClearJustAppeared(mobj: Pmobj_t); static; inline;
    /// <summary>P_MobjThinker: what is cleared before the thing moves (Hexen: the blocking thing)</summary>
    class procedure BeginThink; static; inline;
    /// <summary>P_MobjThinker: after a move the thing is still there (Strife: the feet sink in the terrain)</summary>
    class procedure AfterXYMovement(mobj: Pmobj_t); static;
    /// <summary>P_MobjThinker: the thing has no momentum (Hexen: it is no more "blasted")</summary>
    class procedure StandsStill(mobj: Pmobj_t); static;
    /// <summary>P_MobjThinker: floating bob, z movement and gravity, standing on things; false when the thing was removed</summary>
    class function ZPhase(mobj: Pmobj_t): boolean; static;
    /// <summary>P_MobjThinker: before the state of the thing ends (Strife: the stonecold cheat)</summary>
    class procedure BeforeStateCycle(mobj: Pmobj_t); static;
    /// <summary>P_MobjThinker: a monster that waits to respawn does not respawn for a reason of the game (asked after the dice)</summary>
    class function NeverRespawns(mobj: Pmobj_t): boolean; static; inline;
    /// <summary>P_NightmareRespawn of the game</summary>
    class procedure NightmareRespawn(mobj: Pmobj_t); static;
    /// <summary>P_NightmareRespawn: the fog spawned at the old spot of the monster</summary>
    class function RespawnOldFog(mobj: Pmobj_t): Pmobj_t; static;
    /// <summary>P_NightmareRespawn: the height of the fog at the new spot (fog is the old one)</summary>
    class function RespawnFogFloor(ss: Psector_t; fog: Pmobj_t): fixed_t; static;
    /// <summary>P_NightmareRespawn: where the new monster is spawned</summary>
    class function RespawnSpawnZ(mobj: Pmobj_t): fixed_t; static;
    /// <summary>P_NightmareRespawn: what the new monster inherits from the map thing and the old one, after the ambush flag</summary>
    class procedure RespawnInherit(mo, mobj: Pmobj_t; mthing: Pmapthing_t); static;
    /// <summary>The tics a dead monster waits before it may respawn</summary>
    class function RespawnTime: integer; static; inline;
    /// <summary>P_SpawnMobj: the flags of the game, the "just appeared" flag and the fields only some games copy from the info</summary>
    class procedure InitGameFields(mobj: Pmobj_t; info: Pmobjinfo_t); static;
    /// <summary>P_SpawnMobj: where a floating thing starts to bob (a random draw, or nothing)</summary>
    class procedure InitBob(mobj: Pmobj_t); static;
    /// <summary>P_SpawnMobj: the thing gets the reaction time of its type</summary>
    class function HasReactionTime: boolean; static; inline;
    /// <summary>P_SpawnMobj: what the thing remembers of its first state, and the list of the sectors it touches</summary>
    class procedure InitStateMemory(mobj: Pmobj_t; st: Pstate_t); static;
    /// <summary>P_SpawnMobj: a thing spawned on the floor (Strife: its feet sink in the terrain)</summary>
    class procedure SpawnedOnFloor(mobj: Pmobj_t); static;
    /// <summary>P_SpawnMobj: the random part of the height of a floating thing in this space</summary>
    class function RandomFloatHeight(space: fixed_t): fixed_t; static;
    /// <summary>P_SpawnMobj: z is a height over the floor (the floating items of Hexen)</summary>
    class function SpawnZIsHeight(mobj: Pmobj_t): boolean; static; inline;
    /// <summary>P_SpawnMobj: the feet of a thing spawned in a sector with a 3d floor or a slope</summary>
    class procedure FootClipOnMidOrSlope(mobj: Pmobj_t); static;
    /// <summary>P_SpawnMobj: the feet of a thing spawned in a plain sector</summary>
    class procedure FootClipOnFloor(mobj: Pmobj_t; sec: Psector_t); static;
  end;

//==============================================================================
//
// P_SpawnBlood
//
//==============================================================================
procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer; const originator: Pmobj_t);

//==============================================================================
//
// P_SpawnGreenBlood
//
//==============================================================================
procedure P_SpawnGreenBlood(x, y, z: fixed_t; damage: integer);

//==============================================================================
//
// P_SpawnBlueBlood
//
//==============================================================================
procedure P_SpawnBlueBlood(x, y, z: fixed_t; damage: integer);

//==============================================================================
//
// P_GetTerrainType
//
//==============================================================================
function P_GetTerrainType(mobj: Pmobj_t): integer;

//==============================================================================
//
// P_SpawnMortar
//
//==============================================================================
function P_SpawnMortar(source: Pmobj_t; _type: integer): Pmobj_t;

//==============================================================================
//
// P_SpawnFacingMissile
//
//==============================================================================
function P_SpawnFacingMissile(source: Pmobj_t; target: Pmobj_t; _type: integer): Pmobj_t;

//==============================================================================
//
// P_SpawnSparkPuff
//
//==============================================================================
function P_SpawnSparkPuff(x, y, z: fixed_t): Pmobj_t;

implementation

uses
  d_delphi,
  c_cmds,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Engine.Scanner.Log,
  doomstat,
  d_think,
  d_main,
  DelphiDoom.MathCore.Types,
  DelphiDoom.MathCore.VectorMath,
  g_game,
  i_system,
  z_zone,
  m_rnd,
  doomdef,
  p_playertrace,
  p_gravity,
  p_local,
  p_map,
  DelphiDoom.Engine.World.MapRules,
  p_secnodes,
  p_maputl,
  p_mobjlist,
  p_tick,
  p_pspr,
  p_setup,
  p_common,
  p_sounds,
  p_3dfloors, // JVAL: 3d floors
  p_slopes, // JVAL: Slopes
  po_man,
  p_spec,
  p_inter,
  p_params,
  p_ladder,
  p_musinfo,
  p_bouncing,
  ps_main,
  r_sky,
  r_main,
  r_data,
  r_translations,
  st_stuff,
  hu_stuff,
  s_sound,
  sounddata,
  info,
  info_rnd,
  info_common,
  p_mobj,
  DelphiDoom.Engine.World.Respawner;

//
// P_XYMovement
//
// [STRIFE] Modifications for:
// * No SKULLFLY logic (replaced by BOUNCE flag)
// * Missiles can activate G1/GR line types
// * Player walking logic
// * Air friction for players
//
const
  STOPSPEED = $1000;
  FRICTION = $e800;
  AIRFRICTION = $fff0; // [STRIFE]


//==============================================================================
//
// P_ZMovement
//
// [STRIFE] Modifications for:
// * 3D Object Clipping
// * Different momz handling
// * No SKULLFLY logic (replaced with BOUNCE)
// * Missiles don't hit sky flats
//
//==============================================================================
procedure P_ZMovement(mo: Pmobj_t);
var
  dist: fixed_t;
  delta: fixed_t;
  ceilz: fixed_t;
  grav: integer;
  momomz: fixed_t;
  laddertics: integer;
  player: Pplayer_t;
begin
  laddertics := 0;
  player := Pplayer_t(mo.player);
  if player <> nil then
    if player.laddertics > 0 then
    begin
      Dec(player.laddertics);
      laddertics := player.laddertics;
      if laddertics = 0 then
        mo.momz := 0;
    end;

  // check for smooth step up
  if (player <> nil) and (mo.z < mo.floorz) and (laddertics = 0) then
  begin
    player.viewheight := player.viewheight - (mo.floorz - mo.z);
    player.deltaviewheight :=
      _SHR3(PVIEWHEIGHT - player.crouchheight - player.viewheight);
  end;

  // adjust height
  if laddertics > 0 then
  begin
    mo.z := mo.z + mo.momz;
    mo.momz := (mo.momz * 7) div 8;
    if mo.momz < FRACUNIT div 8 then
      mo.momz := 0;
  end
  else
    mo.z := mo.z + mo.momz;

  // adjust height
  // villsa [STRIFE] check for things standing on top of other things
  if not P_CheckPositionZ(mo, mo.z + mo.momz) then
  begin
    if mo.momz >= 0 then
      mo.ceilingz := mo.height + mo.z
    else
      mo.floorz := mo.z;
  end;

  if (mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin
    // float down towards target if too close
    if mo.flags and MF_INFLOAT = 0 then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);

      delta := mo.target.z + (mo.height div 2) - mo.z;

      if (delta < 0) and (dist < -(delta * 3)) then
        mo.z := mo.z - P_FloatSpeed(mo)
      else if (delta > 0) and (dist < (delta * 3)) then
        mo.z := mo.z + P_FloatSpeed(mo);
    end;
  end;

  // clip movement
  if mo.z <= mo.floorz then
  begin
    // hit the floor

    if (mo.flags and MF_BOUNCE <> 0) and (mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0) then
    begin
      // villsa [STRIFE] affect reactiontime
      // momz is also shifted by 1
      mo.momz := -mo.momz div 2;
      mo.reactiontime := mo.reactiontime div 2;

      if G_PlayingEngineVersion >= VERSION207 then
        if mo.momz + mo.z <= mo.floorz then
        begin
          mo.momz := 0;
          mo.z := mo.floorz;
        end;

      // villsa [STRIFE] get terrain type
      if P_GetTerrainType(mo) <> FLOOR_SOLID then
        mo.flags := mo.flags and not MF_BOUNCE;
    end;

    momomz := mo.momz;
    if mo.momz < 0 then
    begin
      if (player <> nil) and (mo.momz < -P_GetMobjGravity(mo) * 8) then
      begin
        // Squat down.
        // Decrease viewheight for a moment
        // after hitting the ground (hard),
        // and utter appropriate sound.
        player.deltaviewheight := _SHR3(mo.momz);
        // JVAL: 20211101 - Crouch
        if G_PlayingEngineVersion >= VERSION207 then
          player.deltaviewheight := FixedMul(player.deltaviewheight, FixedDiv(mo.height, mo.info.height));

        // villsa [STRIFE] fall damage
        // haleyjd 09/18/10: Repaired calculation
        if mo.momz < -20 * FRACUNIT then
          P_DamageMobj(mo, nil, mo, -(mo.momz div 25000));

        // haleyjd 20110224: *Any* fall centers your view, not just
        // damaging falls (moved outside the above if).
        Pplayer_t(mo.player).centerview := true;

        if leveltime > player.nextoof then
        begin
          S_StartSound(mo, Ord(sfx_oof));
          player.nextoof := leveltime + 4 * TICRATE;
        end;
      end;
      mo.momz := 0;
    end;

    if mo.z - momomz > mo.floorz then
    begin // Spawn splashes, etc.
      P_HitFloor(mo);
    end;

    mo.z := mo.floorz;

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and (MF_NOCLIP or MF_BOUNCE) = 0) then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;

    if (mo.info.crashstate > 0) and
       (mo.flags and MF_CORPSE <> 0) then
    begin
      P_SetMobjState(mo, statenum_t(mo.info.crashstate));
      exit;
    end;

  end
  else if mo.flags and MF_NOGRAVITY = 0 then
  begin
    grav := P_GetMobjGravity(mo);
    // JVAL
    // Low gravity cheat
    if player <> nil then
      if player.cheats and CF_LOWGRAVITY <> 0 then
        grav := grav div 2;

    if mo.momz = 0 then
      mo.momz := -grav * 2
    else
      mo.momz := mo.momz - grav;

    // JVAL
    // Low gravity flag
    if mo.flags_ex and MF_EX_LOWGRAVITY <> 0 then
      mo.momz := mo.momz div 2
    else if mo.flags2_ex and MF2_EX_MEDIUMGRAVITY <> 0 then
      mo.momz := mo.momz * 3 div 4;

  end;

  ceilz := mo.ceilingz + P_SectorJumpOverhead(Psubsector_t(mo.subsector).sector);

  if mo.z + mo.height > ceilz then
  begin
    // villsa [STRIFE] replace skullfly flag with MF_BOUNCE
    if mo.flags and MF_BOUNCE <> 0 then
    begin
      // villsa [STRIFE] affect reactiontime
      // momz is also shifted by 1
      mo.momz := -mo.momz div 2;
      mo.reactiontime := mo.reactiontime div 2;
    end;

    // hit the ceiling
    if mo.momz > 0 then
    if mo.momz > 0 then
    begin
      if mo.flags3_ex and MF3_EX_CEILINGBOUNCE <> 0 then
        mo.momz := -mo.momz div 2
      else
        mo.momz := 0;
    end;
    mo.z := ceilz - mo.height;

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and (MF_NOCLIP or MF_BOUNCE) = 0) then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;
  end;
end;

//==============================================================================
//
// P_NightmareRespawn
//
// [STRIFE] Modifications for:
// * Destination fog z coordinate
// * Restoration of all Strife mapthing flags
//
//==============================================================================
class procedure TMobjGameRules.NightmareRespawn(mobj: Pmobj_t);
begin
  TMobjRespawner.Respawn(mobj);
end;

//==============================================================================
//
// P_NightmareRespawn: the fog at the old spot
//
//==============================================================================
class function TMobjGameRules.RespawnOldFog(mobj: Pmobj_t): Pmobj_t;
begin
  result := P_SpawnMobj(mobj.x, mobj.y, mobj.z, Ord(MT_TFOG));
end;

//==============================================================================
//
// P_NightmareRespawn: the height of the fog at the new spot
//
// haleyjd [STRIFE]: Uses ONFLOORZ instead of ss->sector->floorheight
//
//==============================================================================
class function TMobjGameRules.RespawnFogFloor(ss: Psector_t; fog: Pmobj_t): fixed_t;
begin
  result := ONFLOORZ;
end;

//==============================================================================
//
// P_NightmareRespawn: where the new monster is spawned
//
//==============================================================================
class function TMobjGameRules.RespawnSpawnZ(mobj: Pmobj_t): fixed_t;
begin
  if mobj.flags and MF_SPAWNCEILING <> 0 then
    result := ONCEILINGZ
  else if mobj.flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    result := ONFLOATZ
  else
    result := ONFLOORZ;
end;

//==============================================================================
//
// P_NightmareRespawn: what the new monster inherits from the map thing and the old one
//
//==============================================================================
class procedure TMobjGameRules.RespawnInherit(mo, mobj: Pmobj_t; mthing: Pmapthing_t);
begin
  if mthing.options and MTF_STAND <> 0 then       // [STRIFE] Standing mode, for NPCs
    mo.flags := mo.flags or MF_STAND;
  if mthing.options and MTF_ALLY <> 0 then      // [STRIFE] Allies
    mo.flags := mo.flags or MF_ALLY;
  if mthing.options and MTF_FRIEND <> 0 then
    mo.flags2_ex := mo.flags2_ex or MF2_EX_FRIEND;
  if mthing.options and MTF_TRANSLUCENT <> 0 then // [STRIFE] Translucent object
    mo.flags := mo.flags or MF_SHADOW;
  if mthing.options and MTF_MVIS <> 0 then        // [STRIFE] Alt. Translucency
    mo.flags := mo.flags or MF_MVIS;
end;


//==============================================================================
//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//
// [STRIFE] Modifications for:
// * stonecold cheat, -workparm
// * default inventory/questflags
//
//==============================================================================
class function TMobjGameRules.SpawnPlayer(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
var
  p: Pplayer_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  i: integer;
  plnum: integer;
  ss: Psubsector_t;
begin
  // not playing?
  if not playeringame[mthing._type - 1] then
  begin
    result := nil;
    exit;
  end;

  plnum := mthing._type - 1;
  p := @players[plnum];

  if p.playerstate = PST_REBORN then
    G_PlayerReborn(plnum);

  if uthing <> nil then
  begin
    x := uthing.x;
    y := uthing.y;
    if uthing.extraflags and UDMF_TF_HASZ <> 0 then
      z := uthing.z
    else
      z := ONFLOORZ;
  end
  else
  begin
    x := mthing.x * FRACUNIT;
    y := mthing.y * FRACUNIT;
    z := ONFLOORZ;
  end;

  // JVAL: 20191209 - 3d floors - Fixed Player spawned in 3d floor
  ss := R_PointInSubsector(x, y);
  if ss.sector.midsec >= 0 then
    if mthing.options and MTF_ONMIDSECTOR <> 0 then
      z := sectors[ss.sector.midsec].ceilingheight;

  result := P_SpawnMobj(x, y, z, Ord(MT_PLAYER), @mthing);

  // set color translations for player sprites
  if mthing._type > 1 then
    result.flags := result.flags or _SHLW(plnum, MF_TRANSSHIFT);

  if result.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    result.angle := ANG1 * mthing.angle
  else
    result.angle := ANG45 * (mthing.angle div 45);
  result.player := p;
  result.health := p.health;
  result.customparams := nil; // JVAL: Should keep the old params!

  p.mo := result;
  p.playerstate := PST_LIVE;
  p.refire := 0;
  p._message := '';
  p.damagecount := 0;
  p.bonuscount := 0;
  p.extralight := 0;
  p.fixedcolormap := 0;
  p.viewheight := PVIEWHEIGHT;
  // JVAL: 20211117 - Reset extra player fields when spawning player
  p.lastbreath := 0;
  p.hardbreathtics := 0;
  p.angletargetticks := 0;
  p.laddertics := 0;
  p.slopetics := 0;
  p.teleporttics := 0;
  p.nextoof := 0;
  p.quakeintensity := 0;
  p.quaketics := 0;
  p.oldcrouch := 0;
  p.lastongroundtime := 0;
  p.lastautocrouchtime := 0;
  p.crouchheight := 0;
  p.plinetarget := nil;
  p.pcrosstic := leveltime;
  // JVAL: 20211224 - Clear player history
  P_ClearPlayerHistory(p);
  p.nextfire := 0;

  // JVAL: 20220123 - Gravity & Health from UDMF
  if uthing <> nil then
  begin
    if uthing.extraflags and UDMF_TF_HASGRAVITY <> 0 then
    begin
      if uthing.gravity < 0.0 then
        p.mo.gravity := -Round(uthing.gravity * FRACUNIT)
      else
        p.mo.gravity := Round(p.mo.gravity * uthing.gravity);
    end;
    if uthing.extraflags and UDMF_TF_HASHEALTH <> 0 then
    begin
      if uthing.health < 0.0 then
      begin
        p.health := -Round(uthing.health);
        p.mo.health := p.health;
      end
      else
      begin
        p.health := Round(p.health * uthing.health);
        p.mo.health := p.health;
      end
    end;
    p.mo.tid := uthing.id;
  end;

  // setup gun psprite
  P_SetupPsprites(p);

  // villsa [STRIFE]
  stonecold := false;

  // villsa [STRIFE] what a nasty hack...
  if gamemap = 10 then
    p.weaponowned[Ord(wp_sigil)] := true;

  // give all cards in death match mode
  // villsa [STRIFE] instead of just giving cards in deathmatch mode, also
  // set accuracy to 50 and give all quest flags
  if deathmatch <> 0 then
  begin
    p.accuracy := 50;
    p.questflags := QF_ALLQUESTS; // 0x7fffffff
    for i := 0 to Ord(NUMCARDS) - 1 do
      p.cards[i] := true;
  end;

  // villsa [STRIFE] set godmode?
  if workparm then
    p.cheats := p.cheats or CF_GODMODE;

  if plnum = consoleplayer then
  begin
    // wake up the status bar
    ST_Start;
    // wake up the heads up text
    HU_Start;

    p_justspawned := true;
  end;
end;

//==============================================================================
//
// P_SpawnMapThing
// The fields of the mapthing should
// already be in host byte order.
//
// [STRIFE] Modifications for:
// * No Lost Souls, item count
// * New mapthing_t flag bits
// * 8-player support
//
//==============================================================================
class function TMobjGameRules.SpawnMapThing(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
var
  i: integer;
  bit: integer;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psubsector_t; // JVAL: 3d floors
  msec: Psector_t;  // JVAL: 3d floors
  musinfoparam: integer;
begin
  // Count deathmatch start positions
  if mthing._type = 11 then
  begin
    if deathmatch_p < MAX_DEATHMATCH_STARTS then
    begin
      memcpy(@deathmatchstarts[deathmatch_p], mthing, SizeOf(mthing^));
      if uthing <> nil then
        memcpy(@udeathmatchstarts[deathmatch_p], uthing, SizeOf(uthing^))
      else
      begin
        ZeroMemory(@udeathmatchstarts[deathmatch_p], SizeOf(uthing^));
        if mthing.options and 1 <> 0 then
          udeathmatchstarts[deathmatch_p].extraflags :=
            udeathmatchstarts[deathmatch_p].extraflags or UDMF_TF_SKILL1 or UDMF_TF_SKILL2;
        if mthing.options and 2 <> 0 then
          udeathmatchstarts[deathmatch_p].extraflags :=
            udeathmatchstarts[deathmatch_p].extraflags or UDMF_TF_SKILL3;
        if mthing.options and 4 <> 0 then
          udeathmatchstarts[deathmatch_p].extraflags :=
            udeathmatchstarts[deathmatch_p].extraflags or UDMF_TF_SKILL4 or UDMF_TF_SKILL5;
        udeathmatchstarts[deathmatch_p].x := mthing.x * FRACUNIT;
        udeathmatchstarts[deathmatch_p].y := mthing.y * FRACUNIT;
      end;
      inc(deathmatch_p);
    end;
    result := nil;
    exit;
  end;

  if mthing._type <= 0 then
  begin
    // Thing type 0 is actually "player -1 start".
    // For some reason, Vanilla Doom accepts/ignores this.
    result := nil;
    exit;
  end;

  if mthing._type = PO_ANCHOR_TYPE then
  begin // Polyobj Anchor Pt.
    result := nil;
    exit;
  end
  else if (mthing._type = PO_SPAWN_TYPE) or
          (mthing._type = PO_SPAWNCRUSH_TYPE) then
  begin // Polyobj Anchor Pt.
    inc(po_NumPolyobjs);
    result := nil;
    exit;
  end;

  // check for players specially
  // haleyjd 20120209: [STRIFE] 8 player starts
  if mthing._type <= 8 then
  begin
    // save spots for respawning in network games
    playerstarts[mthing._type - 1] := mthing^;
    if uthing <> nil then
      uplayerstarts[mthing._type - 1] := uthing^
    else
    begin
      ZeroMemory(@uplayerstarts[mthing._type - 1], SizeOf(uplayerstarts[mthing._type - 1]));
      uplayerstarts[mthing._type - 1].x := mthing.x * FRACUNIT;
      uplayerstarts[mthing._type - 1].y := mthing.y * FRACUNIT;
    end;
    if deathmatch = 0 then
      result := P_SpawnPlayer(mthing, uthing)
    else
      result := nil;
    exit;
  end;

  if uthing <> nil then
  begin
    if not netgame then
      if uthing.extraflags and UDMF_TF_SINGLE = 0 then
      begin
        result := nil;
        exit;
      end;

    if netgame and (deathmatch <> 0) then
      if uthing.extraflags and UDMF_TF_DM = 0 then
      begin
        result := nil;
        exit;
      end;

    if netgame and (deathmatch = 0) then
      if uthing.extraflags and UDMF_TF_COOP = 0 then
      begin
        result := nil;
        exit;
      end;
  end
  else
  begin
    // check for apropriate skill level
    if not netgame and (mthing.options and 16 <> 0) then
    begin
      result := nil;
      exit;
    end;
  end;

  if uthing <> nil then
  begin
    bit := _SHL(1, Ord(gameskill));
    if bit and uthing.extraflags = 0 then
    begin
      result := nil;
      exit;
    end;
  end
  else
  begin
    if gameskill = sk_baby then
      bit := 1
    else if gameskill = sk_nightmare then
      bit := 4
    else
      bit := _SHL(1, Ord(gameskill) - 1);

    if mthing.options and bit = 0 then
    begin
      result := nil;
      exit;
    end;
  end;

  musinfoparam := -1;
  if (mthing._type >= MUSICCHANGER_LO) and (mthing._type <= MUSICCHANGER_HI) then
  begin
    musinfoparam := mthing._type - MUSICCHANGER_LO;
    mthing._type := MUSICCHANGER;
  end;

  // find which type to spawn
  i := Info_GetMobjNumForDoomNum(mthing._type);
  if i < 0 then
  begin
    I_Warning('P_SpawnMapThing(): Unknown type %d at (%d, %d)'#13#10,
      [mthing._type, mthing.x, mthing.y]);
    i := Info_GetMobjNumForName('UNKNOWN');
    if i < 0 then
    begin
      result := nil;
      exit;
    end;
  end;

  // don't spawn keycards and players in deathmatch
  if (deathmatch <> 0) and (mobjinfo[i].flags and MF_NOTDMATCH <> 0) then
  begin
    result := nil;
    exit;
  end;

  // don't spawn any monsters if -nomonsters
  if nomonsters and (mobjinfo[i].flags and MF_COUNTKILL <> 0) then
  begin
    result := nil;
    exit;
  end;

  // spawn it
  if uthing <> nil then
  begin
    x := uthing.x;
    y := uthing.y;
  end
  else
  begin
    x := mthing.x * FRACUNIT;
    y := mthing.y * FRACUNIT;
  end;

  // JVAL
  // Random map enemies
  if spawnrandommonsters and Info_IsMonster(i) then
    i := Info_SelectRandomMonster(i);

  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    z := ONCEILINGZ
  else if mobjinfo[i].flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    z := ONFLOATZ
  else
    z := ONFLOORZ;

  if uthing <> nil then
    if uthing.extraflags and UDMF_TF_HASZ <> 0 then
      z := uthing.z;

// JVAL: 3d floors
  ss := R_PointInSubsector(x, y);
  if ss.sector.midsec >= 0 then
  begin
    msec := @sectors[ss.sector.midsec];
    if mthing.options and MTF_ONMIDSECTOR <> 0 then
    begin
      if z = ONFLOATZ then
        z := (msec.ceilingheight + P_CeilingHeight(ss.sector, x, y)) div 2
      else if z = ONFLOORZ then
        z := msec.ceilingheight;
    end
    else
    begin
      if z = ONFLOATZ then
        z := (P_FloorHeight(ss.sector, x, y) + msec.floorheight) div 2
      else if z = ONCEILINGZ then
        z := msec.floorheight;
    end;
  end;

  result := P_SpawnMobj(x, y, z, i, mthing);
  result.spawnpoint := mthing^;

  if musinfoparam >= 0 then
    P_SetMobjCustomParam(result, S_MUSINFO_PARAM, musinfoparam);

  if result.tics > 0 then
    result.tics := 1 + (P_Random mod result.tics);
  if result.flags and MF_COUNTKILL <> 0 then
    inc(totalkills);

  if result.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    result.angle := ANG1 * mthing.angle
  else
    result.angle := ANG45 * (mthing.angle div 45);

  if mthing.options and MTF_DONOTTRIGGERSCRIPTS <> 0 then
    result.flags2_ex := result.flags2_ex or MF2_EX_DONTRUNSCRIPTS;

  if mthing.options and MTF_AMBUSH <> 0 then
    result.flags := result.flags or MF_AMBUSH;
  if mthing.options and MTF_STAND <> 0 then       // [STRIFE] Standing mode, for NPCs
    result.flags := result.flags or MF_STAND;
  if mthing.options and MTF_ALLY <> 0 then        // [STRIFE] Allies
    result.flags := result.flags or MF_ALLY;
  if mthing.options and MTF_FRIEND <> 0 then
    result.flags2_ex := result.flags2_ex or MF2_EX_FRIEND;
  if mthing.options and MTF_TRANSLUCENT <> 0 then // [STRIFE] Translucent object
    result.flags := result.flags or MF_SHADOW;
  if mthing.options and MTF_MVIS <> 0 then        // [STRIFE] Alt. Translucency
    result.flags := result.flags or MF_MVIS;

  // JVAL: 20220123 - Gravity & Health from UDMF
  if uthing <> nil then
  begin
    if uthing.extraflags and UDMF_TF_HASGRAVITY <> 0 then
    begin
      if uthing.gravity < 0.0 then
        result.gravity := -Round(uthing.gravity * FRACUNIT)
      else
        result.gravity := Round(result.gravity * uthing.gravity);
    end;
    if uthing.extraflags and UDMF_TF_HASHEALTH <> 0 then
    begin
      if uthing.health < 0.0 then
        result.health := -Round(uthing.health)
      else
        result.health := Round(result.health * uthing.health);
    end;
    result.special := uthing.special;
    result.args[0] := uthing.arg1;
    result.args[1] := uthing.arg2;
    result.args[2] := uthing.arg3;
    result.args[3] := uthing.arg4;
    result.args[4] := uthing.arg5;
    result.tid := uthing.id;
  end;
end;

//==============================================================================
//
// GAME SPAWN FUNCTIONS
//
// P_SpawnPuff
//
// [STRIFE] Modifications for:
// * No spawn tics randomization
// * Player melee behavior
//
//==============================================================================
class procedure TMobjGameRules.SpawnPuff(x, y, z: fixed_t);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);

  th := P_SpawnMobj(x, y, z, Ord(MT_STRIFEPUFF)); // [STRIFE]: new type

  // don't make punches spark on the wall
  // [STRIFE] Use a separate melee attack range for the player
  if attackrange = PLAYERMELEERANGE then
    P_SetMobjState(th, S_POW2_00);
end;

//==============================================================================
//
// P_SpawnSparkPuff
//
// villsa [STRIFE] new function
//
//==============================================================================
function P_SpawnSparkPuff(x, y, z: fixed_t): Pmobj_t;
begin
  result := P_SpawnMobj(x, y, z + _SHL(P_Random - P_Random, 10), Ord(MT_SPARKPUFF));
end;

//==============================================================================
//
// P_SpawnBlood
//
// [STRIFE] Modifications for:
// * No spawn tics randomization
// * Different damage ranges for state setting
//
//==============================================================================
procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer; const originator: Pmobj_t);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);
  th := P_SpawnMobj(x, y, z, Ord(MT_BLOOD_DEATH));

  if originator.bloodcolor <> 0 then
    R_SetMobjBloodTranslation(th, originator.bloodcolor);

  th.momz := FRACUNIT * 2;

  if th.flags3_ex and MF3_EX_BLOODIGNOREDAMAGE = 0 then
  begin
    // villsa [STRIFE] different checks for damage range
    if (damage >= 10) and (damage <= 13) then
      P_SetMobjState(th, S_BLOD_00)
    else if (damage >= 7) and (damage < 10) then
      P_SetMobjState(th, S_BLOD_01)
    else if damage < 7 then
      P_SetMobjState(th, S_BLOD_02);
  end;
end;

//==============================================================================
//
// P_SpawnGreenBlood
//
//==============================================================================
procedure P_SpawnGreenBlood(x, y, z: fixed_t; damage: integer);
var
  th: Pmobj_t;
begin
  z := z + _SHL(N_Random - N_Random, 10);

  th := P_SpawnMobj(x, y, z, Ord(MT_GREENBLOOD));
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (N_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if th.flags3_ex and MF3_EX_BLOODIGNOREDAMAGE = 0 then
  begin
    if (damage <= 12) and (damage >= 9) then
      P_SetMobjState(th, S_GREENBLOOD2)
    else if damage < 9 then
      P_SetMobjState(th, S_GREENBLOOD3);
  end;
end;

//==============================================================================
//
// P_SpawnBlueBlood
//
//==============================================================================
procedure P_SpawnBlueBlood(x, y, z: fixed_t; damage: integer);
var
  th: Pmobj_t;
begin
  z := z + _SHL(N_Random - N_Random, 10);

  th := P_SpawnMobj(x, y, z, Ord(MT_BLUEBLOOD));
  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (N_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if th.flags3_ex and MF3_EX_BLOODIGNOREDAMAGE = 0 then
  begin
    if (damage <= 12) and (damage >= 9) then
      P_SetMobjState(th, S_BLUEBLOOD2)
    else if damage < 9 then
      P_SetMobjState(th, S_BLUEBLOOD3);
  end;
end;


//==============================================================================
//
// P_SpawnMissile
//
// [STRIFE] Added MVIS inaccuracy
//
//==============================================================================
class function TMobjGameRules.SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  dist: integer;
begin
  // JVAL: Prevent savegame bug
  if dest = nil then
  begin
    result := nil;
    exit;
  end;

  if source.info.missileheight = 0 then
    th := P_SpawnMobj(source.x, source.y, source.z + 4 * 8 * FRACUNIT, _type)
  else if source.info.missileheight < FRACUNIT div 2 then
    th := P_SpawnMobj(source.x, source.y, source.z + source.info.missileheight * FRACUNIT, _type)
  else
    th := P_SpawnMobj(source.x, source.y, source.z + source.info.missileheight, _type);

  A_SeeSound1(th);

  th.target := source;  // where it came from
  an := R_PointToAngle2(source.x, source.y, dest.x, dest.y);

  // fuzzy player
  if source.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
  begin
    if dest.flags and MF_SHADOW <> 0 then
      an := an + _SHLW(P_Random - P_Random, 21);
    if dest.flags and MF_MVIS <> 0 then
      an := an + _SHLW(P_Random - P_Random, 22);
  end;

  th.angle := an;
  {$IFDEF FPC}
  an := _SHRW(an, ANGLETOFINESHIFT);
  {$ELSE}
  an := an shr ANGLETOFINESHIFT;
  {$ENDIF}
  th.momx := FixedMul(th.info.speed, finecosine[an]);
  th.momy := FixedMul(th.info.speed, finesine[an]);

  dist := P_AproxDistance(dest.x - source.x, dest.y - source.y);
  // JVAL: If forgot to set custom missile speed we use default (12 * FRACUNIT)
  if th.info.speed = 0 then
    dist := dist div (12 * FRACUNIT)
  else
    dist := dist div th.info.speed;

  if dist < 1 then
    dist := 1;

  th.momz := (dest.z - source.z) div dist;
  P_CheckMissileSpawn(th);

  result := th;
end;

//==============================================================================
//
// P_SpawnMissileXYZ
//
//==============================================================================
class function TMobjGameRules.SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
var
  flags_ex: integer;
  th: Pmobj_t;
  velocity: TVec3;
  speed: float;
  an: angle_t;
begin
  // JVAL: Prevent savegame bug
  if dest = nil then
  begin
    result := nil;
    exit;
  end;

  P_SaveRandom;

  flags_ex := mobjinfo[Ord(_type)].flags_ex;

  if flags_ex and MF_EX_FLOORHUGGER <> 0 then
  begin
    if G_PlayingEngineVersion >= VERSION122 then
      z := source.floorz
    else
      z := ONFLOORZ;
  end
  else if flags_ex and MF_EX_CEILINGHUGGER <> 0 then
  begin
    if G_PlayingEngineVersion >= VERSION122 then
      z := source.ceilingz
    else
      z := ONCEILINGZ;
  end
  else if z <> ONFLOORZ then
    z := z - source.floorz;

  th := P_SpawnMobj(x, y, z, _type);

  A_SeeSound1(th);

  th.target := source;  // record missile's originator

  speed := th.info.speed;

  velocity[0] := dest.x - source.x;
  velocity[1] := dest.y - source.y;
  // Floor and ceiling huggers should never have a vertical component to their velocity
  if flags_ex and (MF_EX_FLOORHUGGER or MF_EX_CEILINGHUGGER) <> 0 then
    velocity[2] := 0.0
  else
  begin
    velocity[2] := dest.z - source.z;
    if dest.height <= z - source.z then
      velocity[2] := velocity[2] + dest.height - z + source.z;
  end;

  TVectorMath.Normalize3(velocity);
  th.momx := round(velocity[0] * speed);
  th.momy := round(velocity[1] * speed);
  th.momz := round(velocity[2] * speed);

  // fuzzy player
  if dest.flags and MF_SHADOW <> 0 then
    if source.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
    begin
      an := _SHLW(P_Random - P_Random, 20);
      an := an shr ANGLETOFINESHIFT;
      th.momx := th.momx + FixedMul(th.info.speed, finecosine[an]);
      th.momy := th.momy + FixedMul(th.info.speed, finesine[an]);
    end;

  th.angle := R_PointToAngle2(0, 0, th.momx, th.momy);

  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;

  P_RestoreRandom;
end;


//==============================================================================
//
// P_SpawnFacingMissile
//
// villsa [STRIFE] new function
// Spawn a missile based on source's angle
//
//==============================================================================
function P_SpawnFacingMissile(source: Pmobj_t; target: Pmobj_t; _type: integer): Pmobj_t;
var
  an: angle_t;
  dist: fixed_t;
begin
  result := P_SpawnMobj(source.x, source.y, source.z + (32 * FRACUNIT), _type);

  A_SeeSound1(result);

  result.target := source;    // where it came from
  result.angle := source.angle; // haleyjd 09/06/10: fix0red
  an := result.angle;

  // fuzzy player
  if source.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
  begin
    if target.flags and MF_SHADOW <> 0 then
    begin
      an := an + _SHLW(P_Random - P_Random, 21);
    end
    // villsa [STRIFE] check for heavily transparent things
    else if target.flags and MF_MVIS <> 0 then
    begin
      an := an + _SHLW(P_Random - P_Random, 22);
    end;
  end;

  an := an shr ANGLETOFINESHIFT;

  result.momx := FixedMul(result.info.speed, finecosine[an]);
  result.momy := FixedMul(result.info.speed, finesine[an]);

  dist := P_AproxDistance(target.x - source.x, target.y - source.y);
  if result.info.speed = 0 then
    dist := 1
  else
  begin
    dist := dist div result.info.speed;
    if dist < 1 then
      dist := 1;
  end;

  result.momz := (target.z - source.z) div dist;
  P_CheckMissileSpawn(result);
end;

//==============================================================================
//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
// Tries to aim at a nearby monster
// villsa [STRIFE] now returns a mobj
// * Also modified to allow up/down look, and to account for foot-clipping
//   by liquid terrain.
//
//==============================================================================
class function TMobjGameRules.SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if linetarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if linetarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

      if zaxisshift and (linetarget = nil) then
      begin
        an := source.angle;
        slope := (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
      end;

    end;
  end;

  // villsa [STRIFE]
  if linetarget <> nil then
    source.target := linetarget;

  x := source.x;
  y := source.y;
  // Also z axis shift calculation
  if zaxisshift then
    z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173
  else
    z := source.z + 4 * 8 * FRACUNIT;

  if source.flags and MF_FEETCLIPPED <> 0 then
    z := z - source.floorclip;

  th := P_SpawnMobj(x, y, z, _type);

  A_SeeSound1(th);

  th.target := source;
  th.angle := an;
  th.momx := FixedMul(th.info.speed, finecosine[{$IFDEF FPC}_SHRW(an, ANGLETOFINESHIFT){$ELSE}an shr ANGLETOFINESHIFT{$ENDIF}]);
  th.momy := FixedMul(th.info.speed, finesine[{$IFDEF FPC}_SHRW(an, ANGLETOFINESHIFT){$ELSE}an shr ANGLETOFINESHIFT{$ENDIF}]);
  th.momz := FixedMul(th.info.speed, slope);

  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;
end;

//==============================================================================
//
// P_SpawnMortar
//
// villsa [STRIFE] new function
// Spawn a high-arcing ballistic projectile
//
//==============================================================================
function P_SpawnMortar(source: Pmobj_t; _type: integer): Pmobj_t;
var
  an: angle_t;
  slope: fixed_t;
begin
  an := source.angle;

  result := P_SpawnMobj(source.x, source.y, source.z, _type);
  result.target := source;
  result.angle := an;
  an := an div ANGLETOFINEUNIT;

  // haleyjd 20110203: corrected order of function calls
  result.momx := FixedMul(result.info.speed, finecosine[an]);
  result.momy := FixedMul(result.info.speed, finesine[an]);

  P_CheckMissileSpawn(result);

  slope := P_AimLineAttack(source, source.angle, 1024 * FRACUNIT);
  result.momz := FixedMul(result.info.speed, slope);
end;


//==============================================================================
//
// P_GetTerrainType
//
// The terrain under a thing that stands on the floor (it was in Strife\p_terrain.pas, where it
// looked the name of the flat up at every call: terraintype is the same answer, given by
// r_data when the flat was loaded)
//
//==============================================================================
function P_GetTerrainType(mobj: Pmobj_t): integer;
var
  ss: Psubsector_t;
begin
  ss := mobj.subsector;
  if mobj.z <= ss.sector.floorheight then
    result := flats[ss.sector.floorpic].terraintype
  else
    result := FLOOR_SOLID;
end;

//==============================================================================
//
// FUNC P_HitFloor
//
//==============================================================================
class function TMobjGameRules.HitFloor(thing: Pmobj_t): integer;
var
  mo: Pmobj_t;
  sec: Psector_t;
  z: fixed_t; // JVAL: 3d Floors
  ss: Psubsector_t;
begin
  result := FLOOR_SOLID;

  // don't splash if has MF2_EX_NOHITFLOOR flag
  if thing.flags2_ex and MF2_EX_NOHITFLOOR <> 0 then
    exit;

  // Exit if playing old engine demo or in compatibility mode
  if G_NeedsCompatibilityMode then
    exit;

  ss := thing.subsector;

  if ss.flags and SSF_BRIDGE <> 0 then
    if G_PlayingEngineVersion >= VERSION204 then
      exit;

  sec := ss.sector;
  // don't splash if landing on the edge above water/lava/etc....
  if thing.floorz <> sec.floorheight then
    exit;

  if sec.heightsec <> -1 then
    exit;

  // JVAL: 3d Floors
  if G_PlayingEngineVersion >= VERSION122 then
    z := thing.floorz
  else
    z := ONFLOORZ;

  case P_GetThingFloorType(thing) of
    FLOOR_WATER:
      begin
      // JVAL
      // If we record a demo or playing demo (version > 114)
      // then we force splashes
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASHBASE));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASH));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := 2 * FRACUNIT + (P_Random * 256);
          S_StartSound(mo, Ord(sfx_gloop));
        end;
        result := FLOOR_WATER;
        exit;
      end;
    FLOOR_LAVA:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASMOKE));
          mo.momz := FRACUNIT + (P_Random * 128);
          S_StartSound(mo, Ord(sfx_burn));
        end;
        result := FLOOR_LAVA;
        exit;
      end;
    FLOOR_SLUDGE:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGESPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          S_StartSound(mo, Ord(sfx_sgloop));
        end;
        result := FLOOR_SLUDGE;
        exit;
      end;
    FLOOR_NUKAGE:
      begin
        if allowterrainsplashes or demorecording or demoplayback then
        begin
          P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_NUKAGESPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, ONFLOORZ, Ord(MT_NUKAGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          S_StartSound(mo, Ord(sfx_sgloop));
        end;
        result := FLOOR_NUKAGE;
        exit;
      end;
  end;
end;


{ TMobjGameRules }

class procedure TMobjGameRules.KeepPreviousState(mobj: Pmobj_t);
begin
  if mobj.validcount <> validcount then
  begin
    mobj.validcount := validcount;
    mobj.prevstate := mobj.state;
  end;
end;

class function TMobjGameRules.SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;
begin
  // Strife had no P_SetMobjStateNF: nothing calls it
  result := P_DoSetMobjState(mobj, state, false);
end;

class function TMobjGameRules.DeathState(mo: Pmobj_t): statenum_t;
begin
  result := statenum_t(mobjinfo[Ord(mo._type)].deathstate);
end;

class procedure TMobjGameRules.RandomizeExplosionTics(mo: Pmobj_t);
begin
  if mo.tics < 1 then
    mo.tics := 1;
end;

class procedure TMobjGameRules.ExplosionSound(mo: Pmobj_t);
begin
  A_DeathSound1(mo);
end;

class procedure TMobjGameRules.BeforeRemove(mobj: Pmobj_t);
var
  _type: word;
  options: smallint;
begin
  if ((mobj.flags and MF_SPECIAL) <> 0) and
     ((mobj.flags and MF_DROPPED) = 0) then
  begin
    itemrespawnque[iquehead] := mobj.spawnpoint;
    itemrespawntime[iquehead] := leveltime + 30 * TICRATE;  // [STRIFE]

    // [STRIFE] haleyjd 20130915
    // -random parameter affects the behavior of respawning items here.
    if randomparm and (iquehead <> iquetail) then
    begin
      _type := itemrespawnque[iquehead]._type;
      options := itemrespawnque[iquehead].options;

      // swap the type and options of iquehead and iquetail
      itemrespawnque[iquehead]._type := itemrespawnque[iquetail]._type;
      itemrespawnque[iquehead].options := itemrespawnque[iquetail].options;
      itemrespawnque[iquetail]._type := _type;
      itemrespawnque[iquetail].options := options;
    end;

    iquehead := (iquehead + 1) and (ITEMQUESIZE - 1);

    // lose one off the end?
    if iquehead = iquetail then
      iquetail := (iquetail + 1) and (ITEMQUESIZE - 1);
  end;
end;

class procedure TMobjGameRules.ReleaseSectorList;
begin
  if sector_list <> nil then
    while sector_list <> nil do
      sector_list := P_DelSecnode(sector_list);
end;

class function TMobjGameRules.ItemRespawnWaits(const AQueuedTime: integer): boolean;
begin
  // haleyjd [STRIFE]: 30 second wait is not accounted for here, see above.
  result := leveltime < AQueuedTime;
end;

class procedure TMobjGameRules.SpawnItemFog(x, y, z: fixed_t; mthing: Pmapthing_t);
var
  mo: Pmobj_t;
begin
  mo := P_SpawnMobj(x, y, z, Ord(MT_IFOG), mthing);
  S_StartSound(mo, Ord(sfx_itmbk));
end;

class function TMobjGameRules.SpawnHeightOfType(const i: integer): fixed_t;
begin
  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    result := ONCEILINGZ
  else if mobjinfo[i].flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    result := ONFLOATZ
  else
    result := ONFLOORZ;
end;

class procedure TMobjGameRules.RandomizeSpawnTics(th: Pmobj_t);
begin
end;

class function TMobjGameRules.HalvesMissileStepByDivision: boolean;
begin
  result := true;
end;

class procedure TMobjGameRules.SaveRandom;
begin
  P_SaveRandom;
end;

class procedure TMobjGameRules.RestoreRandom;
begin
  P_RestoreRandom;
end;

class procedure TMobjGameRules.MissileSeeSound(mo: Pmobj_t);
begin
  A_SeeSound1(mo);
end;

class function TMobjGameRules.SeekerTarget(actor: Pmobj_t): Pmobj_t;
begin
  result := actor.tracer;
end;

class function TMobjGameRules.SeekerSpeed(actor: Pmobj_t): fixed_t;
begin
  result := P_AproxDistance(actor.momx, actor.momy);
end;

class function TMobjGameRules.TerrainFloorPic(thing: Pmobj_t): integer;
begin
  result := Psubsector_t(thing.subsector).sector.floorpic;
end;

class function TMobjGameRules.IsFloatHeightName(const tmp: string): boolean;
begin
  result := (tmp = 'ONFLOATZ') or (tmp = 'FLOATZ');
end;

class function TMobjGameRules.FloatSpawnZ: fixed_t;
begin
  result := ONFLOATZ;
end;

class function TMobjGameRules.SummonerRadius: fixed_t;
begin
  result := mobjinfo[Ord(MT_PLAYER)].radius;
end;

class procedure TMobjGameRules.CreateTIDList;
begin
end;

class function TMobjGameRules.ConsoleSpawnForbidden: boolean;
begin
  result := (gamestate <> GS_LEVEL) or demoplayback or demorecording or netgame;
end;

class function TMobjGameRules.StoppedBeforeMoving(mo: Pmobj_t): boolean;
begin
  // Strife has no thing thrown at its target: P_XYMovement is called only with a momentum
  result := false;
end;

class function TMobjGameRules.SectorWind(mo: Pmobj_t): integer;
begin
  result := 0;
end;

class function TMobjGameRules.HasWindThrust(mo: Pmobj_t): boolean;
begin
  result := mo.flags4_ex and MF4_EX_WINDTHRUST <> 0;
end;

class function TMobjGameRules.HalvesBackwardMoves: boolean;
begin
  result := false;
end;

class function TMobjGameRules.BlockedMove(mo: Pmobj_t; ptryx, ptryy: fixed_t; var xmove, ymove: fixed_t): boolean;
begin
  result := false;
  // blocked move
  if mo.player <> nil then
  begin
    if not P_LadderMove(mo) then
      P_SlideMove(mo); // try to slide along it
  end
  // JVAL: 20210209 - Sliding monsters
  else if (mo.flags3_ex and (MF3_EX_SLIDING or MF3_EX_SLIDE or MF3_EX_SLIDEONWALLS) <> 0) and (mo.flags and MF_MISSILE = 0) then
  begin
    P_SlideMove(mo); // try to slide along it
  end
  // JVAL: 20211121 - New bounch on walls mechanics
  else if (G_PlayingEngineVersion >= VERSION207) and (mo.flags3_ex and MF3_EX_WALLBOUNCE <> 0) and (tmbounceline <> nil) and
    (mo.flags and MF_BOUNCE = 0) then
  begin
    P_WallBounceMobj(mo, tmbounceline);
    xmove := 0;
    ymove := 0;
  end
  // villsa [STRIFE] check for bouncy missiles
  else if (mo.flags and MF_BOUNCE <> 0) or (mo.flags3_ex and MF3_EX_WALLBOUNCE <> 0) then
  begin
    mo.momx := mo.momx div 8;
    mo.momy := mo.momy div 8;

    if P_TryMove(mo, mo.x - xmove, ymove + mo.y) then
      mo.momy := -mo.momy
    else
      mo.momx := -mo.momx;

    xmove := 0;
    ymove := 0;
  end
  else if mo.flags and MF_MISSILE <> 0 then
  begin
    // haley 20110203: [STRIFE]
    // This modification allows missiles to activate shoot specials.
    // *** BUG: In vanilla Strife the second condition is simply
    // if(numspechit). However, numspechit can be negative, and
    // when it is, this accesses spechit[-2]. This always causes the
    // DOS exe to read from NULL, and the 'special' value there (in
    // DOS 6.22 at least) is 0x70, which does nothing.
    if blockingline <> nil then
    begin
      if blockingline.flags and ML_TRIGGERSCRIPTS <> 0 then
        if mo.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
          PS_EventShootLine(mo, pDiff(blockingline, lines, SizeOf(line_t)), P_PointOnLineSide(mo.x, mo.y, blockingline));

      if blockingline.special <> 0 then
        P_ShootSpecialLine(mo, blockingline);
    end;

    if numspechit > 0 then
    begin
      if spechit[numspechit - 1].flags and ML_TRIGGERSCRIPTS <> 0 then
        if mo.flags2_ex and MF2_EX_DONTRUNSCRIPTS = 0 then
          PS_EventShootLine(mo, pDiff(spechit[numspechit - 1], lines, SizeOf(line_t)), P_PointOnLineSide(mo.x, mo.y, spechit[numspechit - 1]));

      P_ShootSpecialLine(mo, spechit[numspechit - 1]);
    end;

    // explode a missile
    if (ceilingline <> nil) and
       (ceilingline.backsector <> nil) and
       (ceilingline.backsector.ceilingpic = skyflatnum) then
    begin
      // Hack to prevent missiles exploding
      // against the sky.
      // Does not handle sky floors.
      P_RemoveMobj(mo);
      begin
        result := true;
        exit;
      end;
    end;
    P_ExplodeMissile(mo);
  end
  else
  begin
    mo.momx := 0;
    mo.momy := 0;
  end;
end;

class function TMobjGameRules.AirborneFriction(mo: Pmobj_t; player: Pplayer_t; wasonfloorz, wasonslope: boolean; oldsector: Psector_t): boolean;
begin
  result := false;
  // haleyjd 20110224: [STRIFE] players experience friction even in the air,
  // although less than when on the ground. With this fix, the 1.2-and-up
  // IWAD demo is now in sync!
  if G_PlayingEngineVersion > VERSION203 then
    if wasonfloorz and wasonslope and (oldsector = Psubsector_t(mo.subsector).sector) then
      if oldsector.flags and SF_SLIPSLOPEDESCENT = 0 then
        mo.z := mo.floorz;

  if mo.z > mo.floorz then
  begin
    if player <> nil then
    begin
      mo.momx := FixedMul(mo.momx, AIRFRICTION);
      mo.momy := FixedMul(mo.momy, AIRFRICTION);
    end;
    result := true; // no friction when airborne
  end;
end;

class function TMobjGameRules.FallsFree(mo: Pmobj_t; player: Pplayer_t): boolean;
begin
  result := false;
end;

class procedure TMobjGameRules.StopWalking(player: Pplayer_t);
begin
  // if in a walking frame, stop moving
  // villsa [STRIFE]: different player state (haleyjd - verified 20110202)
  if (player <> nil) and
     (LongWord((pDiff(player.mo.state, @states[0], SizeOf(states[0]))) - Ord(S_PLAY_01)) < 4) then
    P_SetMobjState(player.mo, S_PLAY_00);
end;

class procedure TMobjGameRules.ApplyFriction(mo: Pmobj_t; special: integer);
begin
  mo.momx := FixedMul(mo.momx, FRICTION);
  mo.momy := FixedMul(mo.momy, FRICTION);
end;

class procedure TMobjGameRules.ClearJustAppeared(mobj: Pmobj_t);
begin
  mobj.flags2_ex := mobj.flags2_ex and not MF2_EX_JUSTAPPEARED;
end;

class procedure TMobjGameRules.BeginThink;
begin
end;

class procedure TMobjGameRules.AfterXYMovement(mobj: Pmobj_t);
begin
  // villsa [STRIFE] terrain clipping
  if P_GetTerrainType(mobj) = FLOOR_SOLID then
  begin
    mobj.flags := mobj.flags and not MF_FEETCLIPPED;
    mobj.floorclip := 0;
  end
  else
  begin
    mobj.flags := mobj.flags or MF_FEETCLIPPED;
    mobj.floorclip := FOOTCLIPSIZE;
  end;
end;

class procedure TMobjGameRules.StandsStill(mobj: Pmobj_t);
begin
end;

class function TMobjGameRules.ZPhase(mobj: Pmobj_t): boolean;
begin

  if mobj.flags_ex and MF_EX_FLOATBOB <> 0 then
  begin
    mobj.z := mobj.floorz + FloatBobOffsets[mobj.bob];
    mobj.bob := (mobj.bob + 1) and FLOATBOBMASK;
  end
  else if ((mobj.z <> mobj.floorz) and (mobj.flags and MF_NOGRAVITY = 0)) or (mobj.momz <> 0) then
  begin
    P_ZMovement(mobj);

    if P_ThinkerIsRemoved(@mobj.thinker) then
      begin // mobj was removed
        result := false;
        exit;
      end;

    // villsa [STRIFE] terrain clipping and sounds
    if P_GetTerrainType(mobj) = FLOOR_SOLID then
    begin
      mobj.flags := mobj.flags and not MF_FEETCLIPPED;
      mobj.floorclip := 0;
    end
    else
    begin
      S_StartSound(mobj, Ord(sfx_wsplsh));
//      if mobj.flags2_ex and MF2_EX_ // JVAL SOS
      mobj.flags := mobj.flags or MF_FEETCLIPPED;
      mobj.floorclip := FOOTCLIPSIZE;
    end;

  end;

  result := true;
end;

class procedure TMobjGameRules.BeforeStateCycle(mobj: Pmobj_t);
begin
  // villsa [STRIFE] stonecold cheat
  if stonecold then
    if mobj.flags and MF_COUNTKILL <> 0 then
      P_DamageMobj(mobj, mobj, mobj, 10);
end;

class function TMobjGameRules.NeverRespawns(mobj: Pmobj_t): boolean;
begin
  // haleyjd [STRIFE]: NOTDMATCH things don't respawn
  result := mobj.flags and MF_NOTDMATCH <> 0;
end;

class function TMobjGameRules.RespawnTime: integer;
begin
  // haleyjd [STRIFE]: respawn time increased from 12 to 16
  result := 16 * TICRATE;
end;

class procedure TMobjGameRules.InitGameFields(mobj: Pmobj_t; info: Pmobjinfo_t);
begin
// JVAL: Set MF2_EX_JUSTAPPEARED flag
  mobj.flags2_ex := info.flags2_ex or MF2_EX_JUSTAPPEARED;
  mobj.flags4_ex := info.flags4_ex;
end;

class procedure TMobjGameRules.InitBob(mobj: Pmobj_t);
begin
  if mobj.flags_ex and MF_EX_FLOATBOB <> 0 then
    mobj.bob := N_Random and FLOATBOBMASK;
end;

class function TMobjGameRules.HasReactionTime: boolean;
begin
  result := true;
end;

class procedure TMobjGameRules.InitStateMemory(mobj: Pmobj_t; st: Pstate_t);
begin
  mobj.prevstate := st;
  mobj.validcount := validcount;
  mobj.touching_sectorlist := nil; // NULL head of sector list // phares 3/13/98
end;

class procedure TMobjGameRules.SpawnedOnFloor(mobj: Pmobj_t);
begin
  // villsa [STRIFE]
  if P_GetTerrainType(mobj) <> FLOOR_SOLID then
  begin
    mobj.flags := mobj.flags or MF_FEETCLIPPED;
    mobj.floorclip := FOOTCLIPSIZE;
  end
  else
    mobj.floorclip := 0;
end;

class function TMobjGameRules.RandomFloatHeight(space: fixed_t): fixed_t;
begin
  result := FixedMul(space, N_Random * 256);
end;

class function TMobjGameRules.SpawnZIsHeight(mobj: Pmobj_t): boolean;
begin
  result := false;
end;

class procedure TMobjGameRules.FootClipOnMidOrSlope(mobj: Pmobj_t);
begin
  if (mobj.flags and MF_FEETCLIPPED <> 0) and
     (P_GetThingFloorType(mobj) > FLOOR_SOLID) and
     (mobj.z = mobj.floorz) then
    mobj.floorclip := FOOTCLIPSIZE
  else
    mobj.floorclip := 0;
end;

class procedure TMobjGameRules.FootClipOnFloor(mobj: Pmobj_t; sec: Psector_t);
begin
  if (mobj.flags and MF_FEETCLIPPED <> 0) and
     (P_GetThingFloorType(mobj) > FLOOR_SOLID) and
     (mobj.z = sec.floorheight) then
    mobj.floorclip := FOOTCLIPSIZE
  else
    mobj.floorclip := 0;
end;

end.
