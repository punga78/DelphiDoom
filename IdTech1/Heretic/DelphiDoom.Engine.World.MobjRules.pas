{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the rules of Heretic for the map objects (p_mobj)      }
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
  ///   What Heretic does differently in the code of the map objects of p_mobj. The unit of the
  ///   same name in the folder of each game is chosen by the project, so the calls are bound at
  ///   compile time: no virtual call and no interface, this is the path of every thing at
  ///   every tic
  /// </summary>
  /// <remarks>
  ///   The bodies are the lines of the old IdTech1\Heretic\p_mobj.pas, moved as they were: the methods keep
  ///   the names of the parameters and the style of the routine they come from. The methods
  ///   named after a routine of p_mobj (SpawnPuff, HitFloor...) are that routine of the game
  /// </remarks>
  TMobjGameRules = class sealed
  public
    const
      /// <summary>A seeker missile that does not move stops seeking</summary>
      SeekerNeedsSpeed = True;
      /// <summary>The flags of a thing that the floor does not slow down</summary>
      NoFrictionFlags = MF_MISSILE or MF_SKULLFLY;
      /// <summary>A thing whose state ends goes on through the states of no tics in the same tic</summary>
      CyclesStatesWhileNoTics = True;
      /// <summary>The dead monsters respawn (nightmare, -respawn)</summary>
      MonstersRespawn = True;
      /// <summary>P_ZMovement: the momentum under which a thing leaving a ladder stops</summary>
      LadderStopMomz = FRACUNIT div 8;

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
    /// <summary>P_SpawnPlayer: the bits of the color of the sprites of a player after the first</summary>
    class function PlayerTranslation(plnum: integer): integer; static;
    /// <summary>P_SpawnPlayer: the fields of the player that count the breath (only some games have them)</summary>
    class procedure ResetBreath(p: Pplayer_t); static;
    /// <summary>P_SpawnPlayer: what the game does when the player is ready (the keys of deathmatch, the interface)</summary>
    class procedure FinishPlayerSpawn(p: Pplayer_t; plnum: integer); static;
    /// <summary>P_SpawnMapThing of the game (the skeleton is TMobjMapThingSpawner)</summary>
    class function SpawnMapThing(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t; static;
    /// <summary>P_SpawnMapThing: what the game does to the options of the thing first</summary>
    class procedure MapThingPrologue(mthing: Pmapthing_t); static;
    /// <summary>P_SpawnMapThing: a type of thing the game ignores (players that are not played, type 0); true when the thing is ignored</summary>
    class function IgnoresMapThing(mthing: Pmapthing_t): boolean; static;
    /// <summary>P_SpawnMapThing: player starts (and what is placed on the map like them); true when the thing is done, with the thing spawned in spawned</summary>
    class function SpawnStartSpot(mthing: Pmapthing_t; uthing: Pextrathing_t; var spawned: Pmobj_t): boolean; static;
    /// <summary>P_SpawnMapThing: options of the thing that exclude it from this kind of net game; true when it is excluded</summary>
    class function ExcludedByNetOptions(mthing: Pmapthing_t): boolean; static;
    /// <summary>P_SpawnMapThing: a monster that -nomonsters removes</summary>
    class function SkipsMonster(const i: integer): boolean; static; inline;
    /// <summary>P_SpawnMapThing: a thing that the game does not place on the map as a mobj (spots of its own); true when it is not spawned</summary>
    class function KeepsMapThingOff(const i: integer; mthing: Pmapthing_t): boolean; static;
    /// <summary>P_SpawnMapThing: the flags of the new thing that come from the options of the map thing, after the ambush flag</summary>
    class procedure MapThingFlags(mo: Pmobj_t; mthing: Pmapthing_t); static;
    /// <summary>P_SpawnMapThing: counts the new thing as an item of the level (Strife has no item count)</summary>
    class procedure CountItem(mo: Pmobj_t); static; inline;
    /// <summary>P_SpawnPuff of the game</summary>
    class procedure SpawnPuff(x, y, z: fixed_t); static;
    /// <summary>P_SpawnMissile of the game</summary>
    class function SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t; static;
    /// <summary>P_SpawnMissile: spawns the missile in front of its source</summary>
    class function MissileOrigin(source: Pmobj_t; _type: integer): Pmobj_t; static;
    /// <summary>P_SpawnMissile: the angle of a shot at a player that cannot be seen well (a random error, or none)</summary>
    class function FuzzyAim(source: Pmobj_t; dest: Pmobj_t; an: angle_t): angle_t; static;
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
    class procedure BeforeStateCycle(mobj: Pmobj_t); static; inline;
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
    /// <summary>P_ZMovement: the player on a ladder and the smooth step up; gives the tics left on the ladder</summary>
    class function ZPrelude(mo: Pmobj_t): integer; static;
    /// <summary>P_ZMovement: what the game does after the height is adjusted (Strife: things standing on things)</summary>
    class procedure AfterZAdjust(mo: Pmobj_t); static;
    /// <summary>P_ZMovement: floating monsters go toward their target (the flying player bobs)</summary>
    class procedure ZFloat(mo: Pmobj_t); static;
    /// <summary>P_ZMovement: the thing is at or under the floor (landing, bounce, splash); false when P_ZMovement is over</summary>
    class function ZHitFloor(mo: Pmobj_t): boolean; static;
    /// <summary>P_ZMovement: the thing is in the air (gravity)</summary>
    class procedure ZGravity(mo: Pmobj_t); static;
    /// <summary>P_ZMovement: the height of the ceiling a thing hits</summary>
    class function CeilingLimit(mo: Pmobj_t): fixed_t; static;
    /// <summary>P_ZMovement: the thing hit the ceiling at this height</summary>
    class procedure ZHitCeiling(mo: Pmobj_t; ceilz: fixed_t); static;
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
// P_BlasterMobjThinker
//
//==============================================================================
procedure P_BlasterMobjThinker(mobj: Pmobj_t);

//==============================================================================
//
// P_SpawnMissileAngle
//
//==============================================================================
function P_SpawnMissileAngle(source: Pmobj_t; _type: integer; angle: angle_t; momz: fixed_t): Pmobj_t;

//==============================================================================
//
// P_SpawnBlood
//
//==============================================================================
procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer; const originator: Pmobj_t);

//==============================================================================
//
// P_BloodSplatter
//
//==============================================================================
procedure P_BloodSplatter(x, y, z: fixed_t; originator: Pmobj_t);

//==============================================================================
//
// P_RipperBlood
//
//==============================================================================
procedure P_RipperBlood(mo: Pmobj_t);

//==============================================================================
//
// P_SPMAngle
//
//==============================================================================
function P_SPMAngle(source: Pmobj_t; _type: integer; angle: angle_t): Pmobj_t;

var
  PuffType: mobjtype_t;
  MissileMobj: Pmobj_t;

implementation

uses
  d_delphi,
  c_cmds,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Engine.Scanner.Log,
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
  p_maputl,
  p_mobjlist,
  p_tick,
  p_pspr,
  DelphiDoom.Engine.World.PspriteRules,
  p_setup,
  p_common,
  p_ambient,
  p_enemy,
  DelphiDoom.Engine.World.EnemyRules,
  p_3dfloors, // JVAL: 3d floors
  p_slopes, // JVAL: Slopes
  po_man,
  p_params,
  p_ladder,
  p_musinfo,
  p_bouncing,
  r_sky,
  r_main,
  r_data,
  r_translations,
  hu_stuff,
  s_sound,
  sounddata,
  info,
  info_rnd,
  info_common,
  doomstat,
  p_mobj,
  DelphiDoom.Engine.World.Respawner,
  DelphiDoom.Engine.World.MissileSpawner,
  DelphiDoom.Engine.World.PlayerSpawner,
  DelphiDoom.Engine.World.MapThingSpawner;

//----------------------------------------------------------------------------
//
// FUNC P_SetMobjStateNF
//
// Same as P_SetMobjState, but does not call the state function.
//
//----------------------------------------------------------------------------
//
//==============================================================================
class function TMobjGameRules.SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;
begin
  result := P_SetMobjStateOnce(mobj, state);
end;


//
// P_XYMovement
//
const
  STOPSPEED = $1000;
  FRICTION_LOW = $f900;
  FRICTION_FLY = $eb00;
  windTab: array[0..2] of integer = (2048 * 5, 2048 * 10, 2048 * 25);


//----------------------------------------------------------------------------
//
// PROC P_FloorBounceMissile
//
//----------------------------------------------------------------------------
//
//==============================================================================
procedure P_FloorBounceMissile(mo: Pmobj_t);
begin
  mo.momz := -mo.momz;
  P_SetMobjState(mo, statenum_t(mobjinfo[mo._type].deathstate));
end;

//==============================================================================
//
// P_ZMovement
//
//==============================================================================
//==============================================================================
//
// P_ZMovement: the player on a ladder, the smooth step up; gives the tics left on the ladder
//
//==============================================================================
class function TMobjGameRules.ZPrelude(mo: Pmobj_t): integer;
var
  ladderticks: integer;
  player: Pplayer_t;
begin
  ladderticks := 0;
  player := Pplayer_t(mo.player);
  if player <> nil then
    if player.laddertics > 0 then
    begin
      Dec(player.laddertics);
      ladderticks := player.laddertics;
      if ladderticks = 0 then
        mo.momz := 0;
    end;

  // check for smooth step up
  if (player <> nil) and (mo.z < mo.floorz) and (ladderticks = 0) then
  begin
    player.viewheight := player.viewheight - (mo.floorz - mo.z);
    player.deltaviewheight :=
      _SHR((PVIEWHEIGHT - player.crouchheight - player.viewheight), 3);
  end;
  result := ladderticks;
end;

//==============================================================================
//
// P_ZMovement: after the height is adjusted (nothing in this game)
//
//==============================================================================
class procedure TMobjGameRules.AfterZAdjust(mo: Pmobj_t);
begin
end;

//==============================================================================
//
// P_ZMovement: floating monsters go toward their target
//
//==============================================================================
class procedure TMobjGameRules.ZFloat(mo: Pmobj_t);
var
  dist: fixed_t;
  delta: fixed_t;
  player: Pplayer_t;
begin
  player := Pplayer_t(mo.player);
  if (mo.flags and MF_FLOAT <> 0) and (mo.target <> nil) then
  begin
    // float down towards target if too close
    if (mo.flags and MF_SKULLFLY = 0) and
       (mo.flags and MF_INFLOAT = 0) then
    begin
      dist := P_AproxDistance(mo.x - mo.target.x, mo.y - mo.target.y);

      delta := (mo.target.z + _SHR1(mo.height)) - mo.z; // JVAL is it right ???

      if (delta < 0) and (dist < -(delta * 3)) then
        mo.z := mo.z - P_FloatSpeed(mo)
      else if (delta > 0) and (dist < (delta * 3)) then
        mo.z := mo.z + P_FloatSpeed(mo);
    end;
  end;

  if (player <> nil) and (mo.flags2 and MF2_FLY <> 0) and (mo.z > mo.floorz) and (leveltime and 2 <> 0) then
    mo.z := mo.z + finesine[(FINEANGLES div 20 * leveltime div 4) and FINEMASK];
end;

//==============================================================================
//
// P_ZMovement: the thing is at or under the floor; false when the routine is over
//
//==============================================================================
class function TMobjGameRules.ZHitFloor(mo: Pmobj_t): boolean;
var
  oldz: fixed_t;
  player: Pplayer_t;
begin
  result := false;
  player := Pplayer_t(mo.player);
    // hit the floor
    if mo.flags and MF_MISSILE <> 0 then
    begin
      mo.z := mo.floorz;
      if (mo.flags2 and MF2_FLOORBOUNCE <> 0) or (mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0) then
      begin
        P_FloorBounceMissile(mo);
        exit;
      end
      else if mo._type = Ord(MT_MNTRFX2) then
      begin // Minotaur floor fire can go up steps
        exit;
      end
      else
      begin
        P_ExplodeMissile(mo);
        exit;
      end;
    end;

    if mo.z - mo.momz > mo.floorz then
    begin // Spawn splashes, etc.
      P_HitFloor(mo);
    end;
    oldz := mo.z;
    mo.z := mo.floorz;
    if mo.momz < 0 then
    begin
      if (player <> nil) and (mo.momz < - P_GetMobjGravity(mo) * 8) and (mo.flags2 and MF2_FLY = 0) then // squat down
      begin
        player.deltaviewheight := mo.momz div 8;
        S_StartSound(mo, Ord(sfx_plroof));
        player.centering := true; // JVAL: check
      end;
      if mo.flags3_ex and MF3_EX_FLOORBOUNCE <> 0 then
      begin
        mo.momz := -mo.momz div 2;
        if G_PlayingEngineVersion >= VERSION207 then
          if mo.momz + oldz <= mo.floorz then
            mo.momz := 0;
      end
      else
        mo.momz := 0;
    end;

    // Note (id):
    //  somebody left this after the setting momz to 0,
    //  kinda useless there.
    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.momz := -mo.momz;
    end;

    if (mo.info.crashstate <> 0) and (mo.flags and MF_CORPSE <> 0) then
    begin
      P_SetMobjState(mo, statenum_t(mo.info.crashstate));
      exit;
    end;

    if mo.momz < 0 then
    begin
      if (player <> nil) and (mo.momz < -P_GetMobjGravity(mo) * 8) then
      begin
        // Squat down.
        // Decrease viewheight for a moment
        // after hitting the ground (hard),
        // and utter appropriate sound.
        player.deltaviewheight := _SHR(mo.momz, 3);

        // JVAL: 20211101 - Crouch
        if G_PlayingEngineVersion >= VERSION207 then
          player.deltaviewheight := FixedMul(player.deltaviewheight, FixedDiv(mo.height, mo.info.height));

        if leveltime > player.nextoof then
        begin
          S_StartSound(mo, Ord(sfx_plroof));
          player.nextoof := leveltime + 4 * TICRATE;
        end;
      end;
      mo.momz := 0;
    end;
    mo.z := mo.floorz;

    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and MF_NOCLIP = 0) then
    begin
      P_ExplodeMissile(mo);
      exit;
    end;
  result := true;
end;

//==============================================================================
//
// P_ZMovement: the thing is in the air
//
//==============================================================================
class procedure TMobjGameRules.ZGravity(mo: Pmobj_t);
var
  grav: integer;
  player: Pplayer_t;
begin
  player := Pplayer_t(mo.player);
  if (mo.flags2 and MF2_LOGRAV <> 0) or (mo.flags_ex and MF_EX_LOWGRAVITY <> 0) then
  begin
    if mo.momz = 0 then
      mo.momz := -(P_GetMobjGravity(mo) div 8) * 2
    else
      mo.momz := mo.momz - P_GetMobjGravity(mo) div 8;
  end
  else if mo.flags2_ex and MF2_EX_MEDIUMGRAVITY <> 0 then
  begin
    if mo.momz = 0 then
      mo.momz := -(P_GetMobjGravity(mo) div 8) * 4
    else
      mo.momz := mo.momz - P_GetMobjGravity(mo) div 4;
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
      mo.momz := - grav * 2
    else
      mo.momz := mo.momz - grav;

  end;
end;

//==============================================================================
//
// P_ZMovement: the height of the ceiling a thing hits
//
//==============================================================================
class function TMobjGameRules.CeilingLimit(mo: Pmobj_t): fixed_t;
begin
  result := mo.ceilingz + P_SectorJumpOverhead(Psubsector_t(mo.subsector).sector, mo.player);
end;

//==============================================================================
//
// P_ZMovement: the thing hit the ceiling
//
//==============================================================================
class procedure TMobjGameRules.ZHitCeiling(mo: Pmobj_t; ceilz: fixed_t);
begin
    // hit the ceiling
    if mo.momz > 0 then
    begin
      if mo.flags3_ex and MF3_EX_CEILINGBOUNCE <> 0 then
        mo.momz := -mo.momz div 2
      else
        mo.momz := 0;
    end;

    mo.z := ceilz - mo.height;

    if mo.flags and MF_SKULLFLY <> 0 then
      mo.momz := -mo.momz; // the skull slammed into something

//    if (mo.flags and MF_MISSILE <> 0) and (mo.flags and MF_NOCLIP = 0) then
    if mo.flags and MF_MISSILE <> 0 then
    begin
      if Psubsector_t(mo.subsector).sector.ceilingpic = skyflatnum then
      begin
        if mo._type = Ord(MT_BLOODYSKULL) then
        begin
          mo.momx := 0;
          mo.momy := 0;
          mo.momz := -FRACUNIT;
        end
        else
          P_RemoveMobj(mo);
        exit;
      end;
      P_ExplodeMissile(mo);
    end;
end;

//==============================================================================
//
// P_NightmareRespawn
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
//==============================================================================
class function TMobjGameRules.RespawnFogFloor(ss: Psector_t; fog: Pmobj_t): fixed_t;
begin
  result := P_FloorHeight(ss, fog.x, fog.y);
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
  else if mobj.flags2 and MF2_SPAWNFLOAT <> 0 then
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
  // killough 11/98: transfer friendliness from deceased
  if mobj.flags2_ex and MF2_EX_FRIEND = 0 then
    mo.flags2_ex := mo.flags2_ex and not MF2_EX_FRIEND
  else
    mo.flags2_ex := mo.flags2_ex or MF2_EX_FRIEND;
end;

//==============================================================================
//
// PROC P_BlasterMobjThinker
//
// Thinker for the ultra-fast blaster PL2 ripper-spawning missile.
//
//==============================================================================
procedure P_BlasterMobjThinker(mobj: Pmobj_t);
var
  i: integer;
  xfrac: fixed_t;
  yfrac: fixed_t;
  zfrac: fixed_t;
  z: fixed_t;
  changexy: boolean;
begin
  // Handle movement
  if (mobj.momx <> 0) or (mobj.momy <> 0) or
     (mobj.z <> mobj.floorz) or (mobj.momz <> 0) then
  begin
    xfrac := mobj.momx div 8;
    yfrac := mobj.momy div 8;
    zfrac := mobj.momz div 8;
    changexy := (xfrac <> 0) or (yfrac <> 0);
    for i := 0 to 7 do
    begin
      if changexy then
      begin
        if not P_TryMove(mobj, mobj.x + xfrac, mobj.y + yfrac) then
        begin // Blocked move
          P_ExplodeMissile(mobj);
          exit;
        end;
      end;
      mobj.z := mobj.z + zfrac;
      if mobj.z <= mobj.floorz then
      begin // Hit the floor
        mobj.z := mobj.floorz;
        P_HitFloor(mobj);
        P_ExplodeMissile(mobj);
        exit;
      end;
      if mobj.z + mobj.height > mobj.ceilingz then
      begin // Hit the ceiling
        mobj.z := mobj.ceilingz - mobj.height;
        P_ExplodeMissile(mobj);
        exit;
      end;
      if changexy and (P_Random < 64) then
      begin
        z := mobj.z - 8 * FRACUNIT;
        if z < mobj.floorz then
        begin
          z := mobj.floorz;
        end;
        P_SpawnMobj(mobj.x, mobj.y, z, Ord(MT_BLASTERSMOKE));
      end;
    end;
  end;
  // Advance the state
  if mobj.tics <> -1 then
  begin
    dec(mobj.tics);
    while mobj.tics = 0 do
    begin
      if not P_SetMobjState(mobj, statenum_t(mobj.state.nextstate)) then
      begin // mobj was removed
        exit;
      end;
    end;
  end;
end;


//==============================================================================
//
// P_SpawnPlayer
// Called when a player is spawned on the level.
// Most of the player structure stays unchanged
//  between levels.
//
//==============================================================================
class function TMobjGameRules.SpawnPlayer(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
begin
  result := TMobjPlayerSpawner.Spawn(mthing, uthing);
end;

//==============================================================================
//
// P_SpawnPlayer: the bits of the color of the sprites of a player after the first
//
//==============================================================================
class function TMobjGameRules.PlayerTranslation(plnum: integer): integer;
begin
  result := _SHL(plnum, MF_TRANSSHIFT);
end;

//==============================================================================
//
// P_SpawnPlayer: the fields of the player that count the breath
//
//==============================================================================
class procedure TMobjGameRules.ResetBreath(p: Pplayer_t);
begin
end;

//==============================================================================
//
// P_SpawnPlayer: what the game does when the player is ready (the keys of deathmatch, the interface)
//
//==============================================================================
class procedure TMobjGameRules.FinishPlayerSpawn(p: Pplayer_t; plnum: integer);
var
  i: integer;
begin
  // give all cards in death match mode
  if TGameSession.DeathMatch <> 0 then
    for i := 0 to Ord(NUMKEYCARDS) - 1 do
      p.keys[i] := true;

  if plnum = TGameSession.ConsolePlayer then
  begin
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
//==============================================================================
class function TMobjGameRules.SpawnMapThing(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
begin
  result := TMobjMapThingSpawner.Spawn(mthing, uthing);
end;

class procedure TMobjGameRules.MapThingPrologue(mthing: Pmapthing_t);
begin
end;

class function TMobjGameRules.IgnoresMapThing(mthing: Pmapthing_t): boolean;
begin
  result := False;
end;

class function TMobjGameRules.SpawnStartSpot(mthing: Pmapthing_t; uthing: Pextrathing_t; var spawned: Pmobj_t): boolean;
begin
  result := False;

  // check for players specially
  if mthing._type <= 4 then
  begin
    // save spots for respawning in network games
    playerstarts[mthing._type - 1] := mthing^;
    if TGameSession.DeathMatch = 0 then
      spawned := P_SpawnPlayer(mthing, uthing);
    result := True;
    exit;
  end;

  // Ambient sound sequences
  if (mthing._type >= 1200) and (mthing._type < 1300) then
  begin
    P_AddAmbientSfx(mthing._type - 1200);
    result := True;
    exit;
  end;

  // Check for boss spots
  if mthing._type = 56 then // Monster_BossSpot
  begin
    P_AddBossSpot(mthing.x * FRACUNIT, mthing.y * FRACUNIT,  ANG1 * mthing.angle);
    result := True;
    exit;
  end;
end;

class function TMobjGameRules.ExcludedByNetOptions(mthing: Pmapthing_t): boolean;
begin
  result := False;
end;

class function TMobjGameRules.SkipsMonster(const i: integer): boolean;
begin
  result := mobjinfo[i].flags and MF_COUNTKILL <> 0;
end;

class function TMobjGameRules.KeepsMapThingOff(const i: integer; mthing: Pmapthing_t): boolean;
begin
  result := False;
  case i of
  // Special stuff
    Ord(MT_WSKULLROD),
    Ord(MT_WPHOENIXROD),
    Ord(MT_AMSKRDWIMPY),
    Ord(MT_AMSKRDHEFTY),
    Ord(MT_AMPHRDWIMPY),
    Ord(MT_AMPHRDHEFTY),
    Ord(MT_AMMACEWIMPY),
    Ord(MT_AMMACEHEFTY),
    Ord(MT_ARTISUPERHEAL),
    Ord(MT_ARTITELEPORT),
    Ord(MT_ITEMSHIELD2):
      begin
        if gamemode = shareware then // Don't place on map in shareware version
          result := True;
      end;

    Ord(MT_WMACE):
      begin
        if gamemode <> shareware then // Put in the mace spot list
          P_AddMaceSpot(mthing);
        result := True;
      end;
  end;
end;

class procedure TMobjGameRules.MapThingFlags(mo: Pmobj_t; mthing: Pmapthing_t);
begin
end;


class procedure TMobjGameRules.CountItem(mo: Pmobj_t);
begin
  if mo.flags and MF_COUNTITEM <> 0 then
    P_World.Totals.CountItem;
end;
//==============================================================================
//
// GAME SPAWN FUNCTIONS
//
// P_SpawnPuff
//
//==============================================================================
class procedure TMobjGameRules.SpawnPuff(x, y, z: fixed_t);
var
  puff: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);

  puff := P_SpawnMobj(x, y, z, Ord(PuffType));
  if puff.info.attacksound <> 0 then
    S_StartSound(puff, puff.info.attacksound);

  case PuffType of
    MT_BEAKPUFF,
    MT_STAFFPUFF:
      puff.momz := FRACUNIT;
    MT_GAUNTLETPUFF1,
    MT_GAUNTLETPUFF2:
      puff.momz := 52428;
  end;
end;

//==============================================================================
//
// P_SpawnBlood
//
//==============================================================================
procedure P_SpawnBlood(x, y, z: fixed_t; damage: integer; const originator: Pmobj_t);
var
  th: Pmobj_t;
begin
  z := z + _SHL(P_Random - P_Random, 10);
  th := P_SpawnMobj(x, y, z, Ord(MT_BLOOD));

  if originator.bloodcolor <> 0 then
    R_SetMobjBloodTranslation(th, originator.bloodcolor);

  th.momz := FRACUNIT * 2;
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;

  if th.flags3_ex and MF3_EX_BLOODIGNOREDAMAGE = 0 then
  begin
    if (damage <= 12) and (damage >= 9) then
      P_SetMobjState(th, S_BLOOD2)
    else if damage < 9 then
      P_SetMobjState(th, S_BLOOD3);
  end;
end;

//==============================================================================
//
// PROC P_BloodSplatter
//
//==============================================================================
procedure P_BloodSplatter(x, y, z: fixed_t; originator: Pmobj_t);
var
  mo: Pmobj_t;
begin
  mo := P_SpawnMobj(x, y, z, Ord(MT_BLOODSPLATTER));

  if originator.bloodcolor <> 0 then
    R_SetMobjBloodTranslation(mo, originator.bloodcolor);

  mo.target := originator;
  mo.momx := (P_Random - P_Random) * 512;
  mo.momy := (P_Random - P_Random) * 512;
  mo.momz := FRACUNIT * 2;
end;

//==============================================================================
//
// PROC P_RipperBlood
//
//==============================================================================
procedure P_RipperBlood(mo: Pmobj_t);
var
  th: Pmobj_t;
  x, y, z: fixed_t;
begin
  x := mo.x + (P_Random - P_Random) * $1000;
  y := mo.y + (P_Random - P_Random) * $1000;
  z := mo.z + (P_Random - P_Random) * $1000;
  th := P_SpawnMobj(x, y, z, Ord(MT_BLOOD));
  th.flags := th.flags or MF_NOGRAVITY;
  th.momx := mo.momx div 2;
  th.momy := mo.momy div 2;
  th.tics := th.tics + P_Random and 3;
end;


//==============================================================================
//
// P_SpawnMissile
//
//==============================================================================
class function TMobjGameRules.SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
begin
  result := TMobjMissileSpawner.SpawnMissile(source, dest, _type);
end;

//==============================================================================
//
// P_SpawnMissile: the missile is spawned in front of its source
//
//==============================================================================
class function TMobjGameRules.MissileOrigin(source: Pmobj_t; _type: integer): Pmobj_t;
var
  z: fixed_t;
begin
  if source.info.missileheight = 0 then
  begin
    case _type of
      Ord(MT_MNTRFX1): // Minotaur swing attack missile
        z := source.z + 40 * FRACUNIT;
      Ord(MT_MNTRFX2): // Minotaur floor fire missile
        z := ONFLOORZ;
      Ord(MT_SRCRFX1): // Sorcerer Demon fireball
        z := source.z + 48 * FRACUNIT;
      Ord(MT_KNIGHTAXE), // Knight normal axe
      Ord(MT_REDAXE): // Knight red power axe
        z := source.z + 36 * FRACUNIT;
      else
        z := source.z + 32 * FRACUNIT;
    end;
  end
  else if source.info.missileheight < FRACUNIT div 2 then
    z := source.z + source.info.missileheight * FRACUNIT
  else
    z := source.z + source.info.missileheight;

  if source.flags2 and MF2_FEETARECLIPPED <> 0 then
    z := z - FOOTCLIPSIZE;

  result := P_SpawnMobj(source.x, source.y, z, _type);
end;

//==============================================================================
//
// P_SpawnMissile: a player that cannot be seen is aimed at with an error
//
//==============================================================================
class function TMobjGameRules.FuzzyAim(source: Pmobj_t; dest: Pmobj_t; an: angle_t): angle_t;
begin
  if dest.flags and MF_SHADOW <> 0 then
    if source.flags2_ex and MF2_EX_SEEINVISIBLE = 0 then
      an := an + _SHLW(P_Random - P_Random, 20);
  result := an;
end;

//==============================================================================
//
// FUNC P_SpawnMissileAngle
//
// Returns NULL if the missile exploded immediately, otherwise returns
// a mobj_t pointer to the missile.
//
//==============================================================================
function P_SpawnMissileAngle(source: Pmobj_t; _type: integer; angle: angle_t; momz: fixed_t): Pmobj_t;
var
  th: Pmobj_t;
  z: fixed_t;
begin
  if source.info.missileheight = 0 then
  begin
    case _type of
      Ord(MT_MNTRFX1): // Minotaur swing attack missile
        z := source.z + 40 * FRACUNIT;
      Ord(MT_MNTRFX2): // Minotaur floor fire missile
        z := ONFLOORZ;
      Ord(MT_SRCRFX1): // Sorcerer Demon fireball
        z := source.z + 48 * FRACUNIT;
      Ord(MT_KNIGHTAXE), // Knight normal axe
      Ord(MT_REDAXE): // Knight red power axe
        z := source.z + 36 * FRACUNIT;
      else
        z := source.z + 32 * FRACUNIT;
    end;
  end
  else if source.info.missileheight < FRACUNIT div 2 then
    z := source.z + source.info.missileheight * FRACUNIT
  else
    z := source.z + source.info.missileheight;

  if source.flags2 and MF2_FEETARECLIPPED <> 0 then
    z := z - FOOTCLIPSIZE;

  th := P_SpawnMobj(source.x, source.y, z, _type);
  if th.info.seesound <> 0 then
  begin
    if th.flags_ex and MF_EX_RANDOMSEESOUND <> 0 then
      P_RandomSound(th, th.info.seesound)
    else
      S_StartSound(th, th.info.seesound);
  end;

  th.target := source;  // where it came from
  th.angle := angle;
  angle := angle shr ANGLETOFINESHIFT;
  th.momx := FixedMul(th.info.speed, finecosine[angle]);
  th.momy := FixedMul(th.info.speed, finesine[angle]);
  th.momz := momz;
  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;
end;

//==============================================================================
//
// P_SpawnMissileXYZ
//
//==============================================================================
class function TMobjGameRules.SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
begin
  result := TMobjMissileSpawner.SpawnMissileXYZ(x, y, z, source, dest, _type);
end;


//==============================================================================
//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
//==============================================================================
class function TMobjGameRules.SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t;
var
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
begin
  // see which target is to be aimed at
  an := source.angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

  if TMapAim.LineTarget = nil then
  begin
    an := an + $4000000;
    slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

    if TMapAim.LineTarget = nil then
    begin
      an := an - $8000000;
      slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);

      if zaxisshift and (TMapAim.LineTarget = nil) then
      begin
        an := source.angle;
        slope := (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
      end;

    end;
  end;

  x := source.x;
  y := source.y;
  // Also z axis shift calculation
  if zaxisshift then
    z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173
  else
    z := source.z + 4 * 8 * FRACUNIT;

  if source.flags2 and MF2_FEETARECLIPPED <> 0 then
    z := z - FOOTCLIPSIZE;

  MissileMobj := P_SpawnMobj(x, y, z, _type);

  if MissileMobj <> nil then
  begin
    if MissileMobj.info.seesound <> 0 then
    begin
      if MissileMobj.flags_ex and MF_EX_RANDOMSEESOUND <> 0 then
        P_RandomSound(MissileMobj, MissileMobj.info.seesound)
      else
        S_StartSound(MissileMobj, MissileMobj.info.seesound);
    end;

    MissileMobj.target := source;
    MissileMobj.angle := an;
    MissileMobj.momx := FixedMul(MissileMobj.info.speed, finecosine[{$IFDEF FPC}_SHRW(an, ANGLETOFINESHIFT){$ELSE}an shr ANGLETOFINESHIFT{$ENDIF}]);
    MissileMobj.momy := FixedMul(MissileMobj.info.speed, finesine[{$IFDEF FPC}_SHRW(an, ANGLETOFINESHIFT){$ELSE}an shr ANGLETOFINESHIFT{$ENDIF}]);
    MissileMobj.momz := FixedMul(MissileMobj.info.speed, slope);

    if MissileMobj._type = Ord(MT_BLASTERFX1) then
    begin // Ultra-fast ripper spawning missile
      MissileMobj.x := MissileMobj.x + (MissileMobj.momx div 8);
      MissileMobj.y := MissileMobj.y + (MissileMobj.momy div 8);
      MissileMobj.z := MissileMobj.z + (MissileMobj.momz div 8);
    end
    else
    begin // Normal missile
      MissileMobj.x := MissileMobj.x + (MissileMobj.momx div 2);
      MissileMobj.y := MissileMobj.y + (MissileMobj.momy div 2);
      MissileMobj.z := MissileMobj.z + (MissileMobj.momz div 2);
    end;
    if not P_TryMove(MissileMobj, MissileMobj.x, MissileMobj.y) then
    begin // Exploded immediately
      P_ExplodeMissile(MissileMobj);
      result := nil;
      exit;
    end;
    result := MissileMobj;
  end
  else
    result := nil;
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
  // don't splash if has MF2_EX_NOHITFLOOR flag
  if thing.flags2_ex and MF2_EX_NOHITFLOOR <> 0 then
  begin
    result := FLOOR_SOLID;
    exit;
  end;

  ss := thing.subsector;
  sec := ss.sector;

  if thing.floorz <> sec.floorheight then
  begin // don't splash if landing on the edge above water/lava/etc....
    result := FLOOR_SOLID;
    exit;
  end;

  if ss.flags and SSF_BRIDGE <> 0 then
    if G_PlayingEngineVersion >= VERSION204 then
    begin
      result := FLOOR_SOLID;
      exit;
    end;

  // JVAL: 3d Floors
  if G_PlayingEngineVersion >= VERSION115 then
    z := thing.floorz
  else
    z := ONFLOORZ;

  case P_GetThingFloorType(thing) of
    FLOOR_WATER:
      begin
        P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASHBASE));
        mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASH));
        mo.target := thing;
        mo.momx := (P_Random - P_Random) * 256;
        mo.momy := (P_Random - P_Random) * 256;
        mo.momz := 2 * FRACUNIT + (P_Random * 256);
        S_StartSound(mo, Ord(sfx_gloop));
        result := FLOOR_WATER;
        exit;
      end;
    FLOOR_LAVA:
      begin
        P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASPLASH));
        mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASMOKE));
        mo.momz := FRACUNIT + (P_Random * 128);
        S_StartSound(mo, Ord(sfx_burn));
        result := FLOOR_LAVA;
        exit;
      end;
    FLOOR_SLUDGE:
      begin
        P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGESPLASH));
        mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGECHUNK));
        mo.target := thing;
        mo.momx := (P_Random - P_Random) * 256;
        mo.momy := (P_Random - P_Random) * 256;
        mo.momz := FRACUNIT + (P_Random * 256);
        result := FLOOR_SLUDGE;
        exit;
      end;
  end;
  result := FLOOR_SOLID;
end;


//==============================================================================
//
// PROC P_SPMAngle
//
//==============================================================================
function P_SPMAngle(source: Pmobj_t; _type: integer; angle: angle_t): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  x, y, z, slope: fixed_t;
begin
//
// see which target is to be aimed at
//
  an := angle;
  slope := P_AimLineAttack(source, an, 16 * 64 * FRACUNIT);
  if TMapAim.LineTarget = nil then
  begin
    an := an + (1 shl 26);
    slope := P_AimLineAttack (source, an, 16 * 64 * FRACUNIT);
    if TMapAim.LineTarget = nil then
    begin
      an := an - (2 shl 26);
      slope := P_AimLineAttack (source, an, 16 * 64 * FRACUNIT);
    end;
    if TMapAim.LineTarget = nil then
    begin
      an := angle;
      slope := (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
    end
  end;
  x := source.x;
  y := source.y;
  z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173;
  if source.flags2 and MF2_FEETARECLIPPED <> 0 then
    z := z - FOOTCLIPSIZE;

  th := P_SpawnMobj(x, y, z, _type);
  if th.info.seesound <> 0 then
    S_StartSound(th, th.info.seesound);

  th.target := source;
  th.angle := an;
  th.momx := FixedMul(th.info.speed, finecosine[an shr ANGLETOFINESHIFT]);
  th.momy := FixedMul(th.info.speed, finesine[an shr ANGLETOFINESHIFT]);
  th.momz := FixedMul(th.info.speed, slope);
  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;
end;


{ TMobjGameRules }

class procedure TMobjGameRules.KeepPreviousState(mobj: Pmobj_t);
begin
  mobj.prevstate := mobj.state;
end;

class function TMobjGameRules.DeathState(mo: Pmobj_t): statenum_t;
begin
  result := statenum_t(mobjinfo[Ord(mo._type)].deathstate);
end;

class procedure TMobjGameRules.RandomizeExplosionTics(mo: Pmobj_t);
begin
  mo.tics := mo.tics - (P_Random and 3);

  if mo.tics < 1 then
    mo.tics := 1;
end;

class procedure TMobjGameRules.ExplosionSound(mo: Pmobj_t);
begin
  if mo.info.deathsound <> 0 then
  begin
    if mo.flags_ex and MF_EX_RANDOMDEATHSOUND <> 0 then
      P_RandomSound(mo, mo.info.deathsound)
    else
      S_StartSound(mo, mo.info.deathsound);
  end;
end;

class procedure TMobjGameRules.BeforeRemove(mobj: Pmobj_t);
begin
  if ((mobj.flags and MF_SPECIAL) <> 0) and
     ((mobj.flags and MF_DROPPED) = 0) then
  begin
    P_World.ItemRespawn.Add(mobj.spawnpoint, leveltime);
  end;
end;

class procedure TMobjGameRules.ReleaseSectorList;
begin
end;

class function TMobjGameRules.ItemRespawnWaits(const AQueuedTime: integer): boolean;
begin
  result := leveltime - AQueuedTime < 30 * TICRATE;
end;

class procedure TMobjGameRules.SpawnItemFog(x, y, z: fixed_t; mthing: Pmapthing_t);
var
  mo: Pmobj_t;
begin
  mo := P_SpawnMobj(x, y, z, Ord(MT_TFOG), mthing);
  // initiate teleport sound
  S_StartSound(mo, Ord(sfx_telept));
end;

class function TMobjGameRules.SpawnHeightOfType(const i: integer): fixed_t;
begin
  if mobjinfo[i].flags and MF_SPAWNCEILING <> 0 then
    result := ONCEILINGZ
  else if mobjinfo[i].flags_ex and MF_EX_SPAWNFLOAT <> 0 then
    result := ONFLOATZ
  else if mobjinfo[i].flags2 and MF2_SPAWNFLOAT <> 0 then
    result := ONFLOATZ
  else
    result := ONFLOORZ;
end;

class procedure TMobjGameRules.RandomizeSpawnTics(th: Pmobj_t);
begin
  th.tics := th.tics - (P_Random and 3);

  if th.tics < 1 then
    th.tics := 1;
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
  if mo.info.seesound <> 0 then
  begin
    if mo.flags_ex and MF_EX_RANDOMSEESOUND <> 0 then
      P_RandomSound(mo, mo.info.seesound)
    else
      S_StartSound(mo, mo.info.seesound);
  end;
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
  result := (gamestate <> GS_LEVEL) or demoplayback or TGameSession.DemoRecording or TGameSession.NetGame;
end;

class function TMobjGameRules.StoppedBeforeMoving(mo: Pmobj_t): boolean;
begin
  result := false;
  if (mo.momx = 0) and (mo.momy = 0) then
  begin
    if mo.flags and MF_SKULLFLY <> 0 then
    begin
      // the skull slammed into something
      mo.flags := mo.flags and not MF_SKULLFLY;
      mo.momx := 0;
      mo.momy := 0;
      mo.momz := 0;

      P_SetMobjState(mo, statenum_t(mo.info.seestate));
    end;
    result := true;
  end;
end;

class function TMobjGameRules.SectorWind(mo: Pmobj_t): integer;
var
  special: integer;
begin
  special := Psubsector_t(mo.subsector).sector.special;
  if mo.flags2 and MF2_WINDTHRUST <> 0 then
  begin
    case special of
      40, 41, 42: // Wind_East
        P_ThrustMobj(mo, 0, windTab[special - 40]);
      43, 44, 45: // Wind_North
        P_ThrustMobj(mo, ANG90, windTab[special - 43]);
      46, 47, 48: // Wind_South
        P_ThrustMobj(mo, ANG270, windTab[special - 46]);
      49, 50, 51: // Wind_West
        P_ThrustMobj(mo, ANG180, windTab[special - 49]);
    end;
  end;
  result := special;
end;

class function TMobjGameRules.HasWindThrust(mo: Pmobj_t): boolean;
begin
  result := mo.flags2 and MF2_WINDTHRUST <> 0;
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
  else if (mo.flags3_ex and MF3_EX_SLIDING <> 0) or (mo.flags and MF_SLIDEONWALLS <> 0) or (mo.flags2 and MF2_SLIDE <> 0) and (mo.flags and MF_MISSILE = 0) then
  begin
    P_SlideMove(mo); // try to slide along it
  end
  // JVAL: 20211121 - New bounch on walls mechanics
  else if (G_PlayingEngineVersion >= VERSION207) and (mo.flags3_ex and MF3_EX_WALLBOUNCE <> 0) and (TMapCheck.BounceLine <> nil) then
  begin
    P_WallBounceMobj(mo, TMapCheck.BounceLine);
    xmove := 0;
    ymove := 0;
  end
  // JVAL: 20200308 - Bounce on walls
  else if mo.flags3_ex and MF3_EX_WALLBOUNCE <> 0 then
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
    // explode a missile
    if (TMapCheck.CeilingLine <> nil) and
       (TMapCheck.CeilingLine.backsector <> nil) and
       (TMapCheck.CeilingLine.backsector.ceilingpic = skyflatnum) then
    begin
      // Hack to prevent missiles exploding
      // against the sky.
      // Does not handle sky floors.
      if mo._type = Ord(MT_BLOODYSKULL) then
      begin
        mo.momx := 0;
        mo.momy := 0;
        mo.momz := -FRACUNIT;
      end
      else
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
end;

class function TMobjGameRules.FallsFree(mo: Pmobj_t; player: Pplayer_t): boolean;
begin
  result := not ((player <> nil) and (player.laddertics > 0)) and (mo.z > mo.floorz);
end;

class procedure TMobjGameRules.StopWalking(player: Pplayer_t);
begin
  // if in a walking frame, stop moving
  if player <> nil then
  begin
    if player.chickenTics <> 0 then
    begin
      if (LongWord((pDiff(player.mo.state, @states[0], SizeOf(states[0]))) - Ord(S_CHICPLAY_RUN1)) < 4) then
        P_SetMobjState(player.mo, S_CHICPLAY);
    end
    else
    begin
      if (LongWord((pDiff(player.mo.state, @states[0], SizeOf(states[0]))) - Ord(S_PLAY_RUN1)) < 4) then
        P_SetMobjState(player.mo, S_PLAY);
    end;
  end;
end;

class procedure TMobjGameRules.ApplyFriction(mo: Pmobj_t; special: integer);
begin
  if (mo.flags2 and MF2_FLY <> 0) and (mo.z > mo.floorz) and
     (mo.flags2 and MF2_ONMOBJ = 0) then
  begin
    mo.momx := FixedMul(mo.momx, FRICTION_FLY);
    mo.momy := FixedMul(mo.momy, FRICTION_FLY);
  end
  else if special = 15 then // Friction_Low
  begin
    mo.momx := FixedMul(mo.momx, FRICTION_LOW);
    mo.momy := FixedMul(mo.momy, FRICTION_LOW);
  end
  else
  begin
    mo.momx := FixedMul(mo.momx, mo.friction);
    mo.momy := FixedMul(mo.momy, mo.friction);
  end;
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
end;

class procedure TMobjGameRules.StandsStill(mobj: Pmobj_t);
begin
end;

class function TMobjGameRules.ZPhase(mobj: Pmobj_t): boolean;
var
  onmo: Pmobj_t;
  pl: Pplayer_t;
begin

  if (mobj.flags2 and MF2_FLOATBOB <> 0) or (mobj.flags_ex and MF_EX_FLOATBOB <> 0) then
  begin
    mobj.z := mobj.floorz + FloatBobOffsets[mobj.bob];
    mobj.bob := (mobj.bob + 1) and FLOATBOBMASK;
  end
  else if (mobj.z <> mobj.floorz) or (mobj.momz <> 0) then
  begin
    if ((mobj.player <> nil) and (G_PlayingEngineVersion >= VERSION207)) or (mobj.flags2 and MF2_PASSMOBJ <> 0) then
    begin
      onmo := P_CheckOnmobj(mobj);
      if onmo = nil then
      begin
        P_ZMovement(mobj);
        mobj.flags2_ex := mobj.flags2_ex and not MF2_ONMOBJ;
      end
      else
      begin
        pl := mobj.player;
        if (pl <> nil) and (mobj.momz < 0) then
        begin
          mobj.flags2 := mobj.flags2 or MF2_ONMOBJ;
          mobj.momz := 0;
        end;
        if (pl <> nil) and ((onmo.player <> nil) or (onmo._type = Ord(MT_POD))) then
        begin
          mobj.momx := onmo.momx;
          mobj.momy := onmo.momy;
          if onmo.z < onmo.floorz then
          begin
            mobj.z := mobj.z + onmo.floorz - onmo.z;
            if onmo.player <> nil then
            begin
              Pplayer_t(onmo.player).viewheight := Pplayer_t(onmo.player).viewheight - (onmo.floorz - onmo.z);
              Pplayer_t(onmo.player).deltaviewheight := (PVIEWHEIGHT - Pplayer_t(onmo.player).viewheight) div 8;
            end;
            onmo.z := onmo.floorz;
          end;
        end
        else if (pl <> nil) and (G_PlayingEngineVersion >= VERSION207) then
        begin
          if onmo.z + onmo.height - mobj.z <= 24 * FRACUNIT then
          begin
            pl.viewheight := pl.viewheight - onmo.z + onmo.height - mobj.z;
            pl.deltaviewheight := _SHR3(PVIEWHEIGHT - pl.viewheight);
            mobj.z := onmo.z + onmo.height;
            mobj.flags2_ex := mobj.flags2 or MF2_ONMOBJ;
            mobj.momz := 0;
          end
          else
          begin // hit the bottom of the blocking mobj
            mobj.momz := 0;
          end;
        end;
      end;
    end
    else
      P_ZMovement(mobj);

    if P_ThinkerIsRemoved(@mobj.thinker) then
      begin // mobj was removed
        result := false;
        exit;
      end;
  end;

  result := true;
end;

class procedure TMobjGameRules.BeforeStateCycle(mobj: Pmobj_t);
begin
end;

class function TMobjGameRules.NeverRespawns(mobj: Pmobj_t): boolean;
begin
  result := false;
end;

class function TMobjGameRules.RespawnTime: integer;
begin
  result := 12 * TICRATE;
end;

class procedure TMobjGameRules.InitGameFields(mobj: Pmobj_t; info: Pmobjinfo_t);
begin
  mobj.flags2 := info.flags2;
  // JVAL: Set MF_JUSTAPPEARED flag
  mobj.flags2_ex := info.flags2_ex or MF2_EX_JUSTAPPEARED;
  mobj.flags4_ex := info.flags4_ex;
  mobj.damage := info.damage;
end;

class procedure TMobjGameRules.InitBob(mobj: Pmobj_t);
begin
  if (mobj.flags2 and MF2_FLOATBOB <> 0) or (mobj.flags_ex and MF_EX_FLOATBOB <> 0) then
    mobj.bob := P_Random and FLOATBOBMASK;
end;

class function TMobjGameRules.HasReactionTime: boolean;
begin
  result := TGameSession.GameSkill <> sk_nightmare;
end;

class procedure TMobjGameRules.InitStateMemory(mobj: Pmobj_t; st: Pstate_t);
begin
  mobj.prevstate := st;
end;

class procedure TMobjGameRules.SpawnedOnFloor(mobj: Pmobj_t);
begin
end;

class function TMobjGameRules.RandomFloatHeight(space: fixed_t): fixed_t;
begin
  result := FixedMul(space, P_Random * 256);
end;

class function TMobjGameRules.SpawnZIsHeight(mobj: Pmobj_t): boolean;
begin
  result := false;
end;

class procedure TMobjGameRules.FootClipOnMidOrSlope(mobj: Pmobj_t);
begin
  if (mobj.flags2_ex and MF2_FOOTCLIP <> 0) and
     (P_GetThingFloorType(mobj) > FLOOR_SOLID) and
     (mobj.z = mobj.floorz) then
    mobj.flags2 := mobj.flags2 or MF2_FEETARECLIPPED
  else
    mobj.flags2 := mobj.flags2 and not MF2_FEETARECLIPPED;
end;

class procedure TMobjGameRules.FootClipOnFloor(mobj: Pmobj_t; sec: Psector_t);
begin
  if (mobj.flags2 and MF2_FOOTCLIP <> 0) and (P_GetThingFloorType(mobj) <> FLOOR_SOLID) and
     (mobj.floorz = sec.floorheight) then
    mobj.flags2 := mobj.flags2 or MF2_FEETARECLIPPED
  else
    mobj.flags2 := mobj.flags2 and not MF2_FEETARECLIPPED;
end;

end.
