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
//  Map Objects, MObj, definition and handling.
//  Moving object handling. Spawn functions.
//
//  One copy for Doom, Heretic, Hexen and Strife (issue #185, step 2c-2): what a game does
//  differently is in TMobjGameRules, the unit DelphiDoom.Engine.World.MobjRules of its folder
//  (bound at compile time by the search path of the project: no virtual call, no interface).
//  A routine that is all of one game is a method of the rules with the text of the game, and
//  the routine here only calls it: the callers find every name where it was.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit p_mobj;

interface

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
  m_fixed;

//==============================================================================
//
// P_DoSetMobjState
//
//==============================================================================
function P_DoSetMobjState(mobj: Pmobj_t; state: statenum_t; const runthinker: boolean): boolean;

//==============================================================================
//
// P_SetMobjState
//
//==============================================================================
function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;

//==============================================================================
//
// P_SetMobjStateNF
//
//==============================================================================
function P_SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;

//==============================================================================
//
// P_SetMobjStateOnce
// Sets one state without calling its action and without going on through the
// states of no tics (the P_SetMobjStateNF of Heretic and Hexen)
//
//==============================================================================
function P_SetMobjStateOnce(mobj: Pmobj_t; state: statenum_t): boolean;
//==============================================================================
//
// P_ExplodeMissile
//
//==============================================================================
procedure P_ExplodeMissile(mo: Pmobj_t);

//==============================================================================
//
// P_ZMovement
//
//==============================================================================
procedure P_ZMovement(mo: Pmobj_t);

//==============================================================================
//
// P_MobjThinker
//
//==============================================================================
procedure P_MobjThinker(mobj: Pmobj_t);

//==============================================================================
//
// P_SpawnMobj
//
//==============================================================================
function P_SpawnMobj(x, y, z: fixed_t; _type: integer; const mthing: Pmapthing_t = nil): Pmobj_t;

//==============================================================================
//
// P_RemoveMobj
//
//==============================================================================
procedure P_RemoveMobj(mobj: Pmobj_t);

//==============================================================================
//
// P_SpawnPlayer
//
//==============================================================================
function P_SpawnPlayer(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;

//==============================================================================
//
// P_SpawnMapThing
//
//==============================================================================
function P_SpawnMapThing(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;

//==============================================================================
//
// P_SpawnPuff
//
//==============================================================================
procedure P_SpawnPuff(x, y, z: fixed_t);

//==============================================================================
//
// P_SpawnMissile
//
//==============================================================================
function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;

//==============================================================================
//
// P_SpawnMissileXYZ
//
//==============================================================================
function P_SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;

//==============================================================================
//
// P_SpawnMissileAngleZ
//
//==============================================================================
function P_SpawnMissileAngleZ(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t): Pmobj_t;

//==============================================================================
//
// P_SpawnMissileAngleZSpeed
//
//==============================================================================
function P_SpawnMissileAngleZSpeed(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t; owner: Pmobj_t): Pmobj_t;

//==============================================================================
//
// P_SpawnPlayerMissile
//
//==============================================================================
function P_SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t;

//==============================================================================
//
// P_RespawnSpecials
//
//==============================================================================
procedure P_RespawnSpecials;

//==============================================================================
//
// P_CheckMissileSpawn
//
//==============================================================================
function P_CheckMissileSpawn(th: Pmobj_t): boolean;

//==============================================================================
//
// P_SeekerMissile
//
//==============================================================================
function P_SeekerMissile(actor: Pmobj_t; thresh, turnMax: angle_t): boolean;

//==============================================================================
//
// P_HitFloor
//
//==============================================================================
function P_HitFloor(thing: Pmobj_t): integer;

//==============================================================================
//
// P_GetThingFloorType
//
//==============================================================================
function P_GetThingFloorType(thing: Pmobj_t): integer;

//==============================================================================
//
// P_CreateTIDList
//
// Only Hexen keeps a list of the things with a TID (TMobjGameRules.CreateTIDList):
// the name stays here because Hexen\sv_save.pas calls it and finds it in p_mobj
//
//==============================================================================
procedure P_CreateTIDList;

//==============================================================================
//
// MObj_Init
//
//==============================================================================
procedure MObj_Init;

//==============================================================================
//
// MObj_ShutDown
//
//==============================================================================
procedure MObj_ShutDown;

// The queue of the items that respawn is World.ItemRespawn (DelphiDoom.Engine.World):
// the rules of the game put the items in it (TMobjGameRules.BeforeRemove)

//==============================================================================
//
// P_FindMobjFromKey
//
//==============================================================================
function P_FindMobjFromKey(const key: LongWord): Pmobj_t;

implementation

// Only units that every game has; the rules of the game last, so that a name of the
// old p_mobj.pas is not found there before it is found in the units it came from
uses
  d_delphi,
  c_cmds,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Engine.Scanner.Log,
  doomstat,
  d_player,
  d_think,
  d_main,
  g_game,
  i_system,
  z_zone,
  m_rnd,
  doomdef,
  p_gravity,
  p_local,
  p_map,
  DelphiDoom.Engine.World.MapRules,
  p_maputl,
  p_mobjlist,
  DelphiDoom.Thinkers.RespawnQueue,
  p_tick,
  p_pspr,
  p_setup,
  p_common,
  p_3dfloors, // JVAL: 3d floors
  p_slopes, // JVAL: Slopes
  po_man,
  p_params,
  r_defs,
  r_sky,
  r_main,
  r_data,
  r_translations,
  s_sound,
  sounddata,
  info,
  info_rnd,
  info_common,
  DelphiDoom.Engine.World.MobjRules;

// From Chocolate-Doom
// Use a heuristic approach to detect infinite state cycles: Count the number
// of times the loop in P_SetMobjState() executes and exit with an error once
// an arbitrary very large limit is reached.
const
  MOBJ_CYCLE_LIMIT = 1000000;

//==============================================================================
//
// P_SpawnMissileAngleZ
//
//==============================================================================
function P_SpawnMissileAngleZ(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t): Pmobj_t;
begin
  result := P_SpawnMissileAngleZSpeed(source, z, _type, angle, momz, mobjinfo[Ord(_type)].speed, nil);
end;


//==============================================================================
//
// CmdSpawnMobj
//
//==============================================================================
procedure CmdSpawnMobj(const parm1, parm2: string);
var
  sc: TScriptScanner;
  x, y, z: fixed_t;
  mobjno, dn: integer;
  angle: angle_t;
  parm, tmp: string;
  mo: Pmobj_t;
begin
  if TMobjGameRules.ConsoleSpawnForbidden then
  begin
    printf('You can''t specify the command at this time.'#13#10);
    exit;
  end;

  parm := strtrim(parm1 + ' ' + parm2);
  if parm = '' then
  begin
    printf('Usage:'#13#10' spawnmobj [x y z angle doomednum/doomname]'#13#10);
    exit;
  end;

  sc := TScriptScanner.Create(parm, TEngineScannerLog.Create);
  sc.MustGetInteger;
  x := sc.AsInteger * FRACUNIT;
  sc.MustGetInteger;
  y := sc.AsInteger * FRACUNIT;
  sc.MustGetString;
  tmp := strupper(sc.AsString);
  if (tmp = 'ONFLOORZ') or (tmp = 'FLOORZ') then
    z := ONFLOORZ
  else if TMobjGameRules.IsFloatHeightName(tmp) then
    z := TMobjGameRules.FloatSpawnZ
  else if (tmp = 'ONCEILINGZ') or (tmp = 'CEILINGZ') then
    z := ONCEILINGZ
  else
    z := atoi(tmp, ONFLOORZ) * FRACUNIT;

  sc.MustGetInteger;
  angle := sc.AsInteger * ANG1;

  tmp := '';
  while sc.GetString do
    tmp := tmp + sc.AsString + ' ';
  trimprocU(tmp);

  dn := atoi(tmp, 0);
  if dn >= 1 then
    mobjno := Info_GetMobjNumForDoomNum(dn)
  else
    mobjno := Info_GetMobjNumForName(tmp);
  if (mobjno > 0) and (mobjno < nummobjtypes) then
  begin
    mo := P_SpawnMobj(x, y, z, mobjno);
    if mo <> nil then
    begin
      mo.angle := angle;
      printf('spawnmobj: mobj %s spawned, key=%d'#13#10, [tmp, mo.key]);
    end
    else
      printf('spawnmobj: mobj %s can not be spawned'#13#10, [tmp]);
  end
  else
    printf('Unknown mobj %s'#13#10, [tmp]);
  sc.Free;
end;

//==============================================================================
//
// CmdSummon
//
//==============================================================================
procedure CmdSummon(const parm1, parm2: string);
var
  x, y, z: fixed_t;
  mobjno, dn: integer;
  an, angle: angle_t;
  parm: string;
  mo: Pmobj_t;
  dist: fixed_t;
begin
  if TMobjGameRules.ConsoleSpawnForbidden then
  begin
    printf('You can''t specify the command at this time.'#13#10);
    exit;
  end;

  parm := strtrim(parm1);
  if parm = '' then
  begin
    printf('Usage:'#13#10' summon doomednum/doomname'#13#10);
    exit;
  end;

  dn := atoi(parm, 0);
  if dn >= 1 then
    mobjno := Info_GetMobjNumForDoomNum(dn)
  else
    mobjno := Info_GetMobjNumForName(parm);

  if (mobjno <= 0) or (mobjno >= nummobjtypes) then
  begin
    printf('Unknown mobj %s'#13#10, [parm]);
    exit;
  end;

  if players[consoleplayer].mo = nil then
    exit;

  angle := players[consoleplayer].mo.angle;
  an := angle shr ANGLETOFINESHIFT;
  dist := TMobjGameRules.SummonerRadius + mobjinfo[mobjno].radius + 32 * FRACUNIT;
  x := players[consoleplayer].mo.x + FixedMul(dist, finecosine[an]);
  y := players[consoleplayer].mo.y + FixedMul(dist, finesine[an]);
  z := TMobjGameRules.SpawnHeightOfType(mobjno);

  mo := P_SpawnMobj(x, y, z, mobjno);
  if mo <> nil then
  begin
    mo.angle := angle;
    printf('summon: mobj %s spawned, key=%d'#13#10, [parm, mo.key]);
  end
  else
    printf('summon: mobj %s can not be spawned'#13#10, [parm]);
end;

//==============================================================================
//
// MObj_Init
//
//==============================================================================
procedure MObj_Init;
begin
  mobjlist := TMobjList.Create;
  C_AddCmd('spawnmobj, p_spawnmobj', @CmdSpawnMobj);
  C_AddCmd('summon', @CmdSummon);
end;

//==============================================================================
//
// MObj_ShutDown
//
//==============================================================================
procedure MObj_ShutDown;
begin
  mobjlist.Free;
end;

//==============================================================================
//
// FUNC P_FindMobjFromKey
//
//==============================================================================
function P_FindMobjFromKey(const key: LongWord): Pmobj_t;
var
  currentthinker: Pthinker_t;
begin
  currentthinker := thinkercap.next;
  while Pointer(currentthinker) <> Pointer(@thinkercap) do
  begin
    if (@currentthinker._function.acp1 = @P_MobjThinker) and
       (Pmobj_t(currentthinker).key = key) then
    begin
      result := Pmobj_t(currentthinker);
      exit;
    end;
    currentthinker := currentthinker.next;
  end;

  result := nil;
end;

//==============================================================================
// P_DoSetMobjState
//
// P_SetMobjState
// Returns true if the mobj is still present.
//
//==============================================================================
function P_DoSetMobjState(mobj: Pmobj_t; state: statenum_t; const runthinker: boolean): boolean;
var
  st: Pstate_t;
  cycle_counter: integer;
begin
  cycle_counter := 0;
  repeat
    if state = S_NULL then
    begin
      if mobj.flags_ex and MF_EX_DONOTREMOVE = 0 then // JVAL Do not remove missile
      begin
        mobj.state := @states[Ord(S_NULL)];
        P_RemoveMobj(mobj);
      end;
      result := false;
      exit;
    end;

    TMobjGameRules.KeepPreviousState(mobj);

    st := @states[Ord(state)];

    mobj.state := st;
    mobj.tics := P_TicsFromState(st);
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;

    // Modified handling.
    // Call action functions when the state is set
    if Assigned(st.action.acp1) and runthinker then
    begin
      if st.params <> nil then
        st.params.Actor := mobj;
      st.action.acp2(mobj, nil);
    end;

    state := st.nextstate;

    inc(cycle_counter);
    if cycle_counter > MOBJ_CYCLE_LIMIT then
      I_Error('P_SetMobjState(): Infinite state cycle detected in object "%s"!', [Info_GetMobjName(mobj.info)]);
  until mobj.tics <> 0;

  result := true;
end;

//==============================================================================
//
// P_SetMobjState
//
//==============================================================================
function P_SetMobjState(mobj: Pmobj_t; state: statenum_t): boolean;
begin
  result := P_DoSetMobjState(mobj, state, true);
end;

//==============================================================================
//
// P_SetMobjStateNF
//
//==============================================================================
function P_SetMobjStateNF(mobj: Pmobj_t; state: statenum_t): boolean;
begin
  result := TMobjGameRules.SetMobjStateNF(mobj, state);
end;

//==============================================================================
//
// P_SetMobjStateOnce
//
//==============================================================================
function P_SetMobjStateOnce(mobj: Pmobj_t; state: statenum_t): boolean;
var
  st: Pstate_t;
begin
  if state = S_NULL then
  begin // Remove mobj
    mobj.state := @states[Ord(S_NULL)];
    P_RemoveMobj(mobj);
    result := false;
  end
  else
  begin
    st := @states[Ord(state)];
    mobj.state := st;
    mobj.tics := P_TicsFromState(st);
    mobj.sprite := st.sprite;
    mobj.frame := st.frame;
    result := true;
  end;
end;
//==============================================================================
//
// P_ExplodeMissile
//
//==============================================================================
procedure P_ExplodeMissile(mo: Pmobj_t);
begin
  mo.momx := 0;
  mo.momy := 0;
  mo.momz := 0;

  P_SetMobjState(mo, TMobjGameRules.DeathState(mo));

  TMobjGameRules.RandomizeExplosionTics(mo);

  mo.flags := mo.flags and not MF_MISSILE;

  TMobjGameRules.ExplosionSound(mo);
end;

//
// P_XYMovement
//
const
  STOPSPEED = $1000;

//==============================================================================
//
// P_XYMovement
//
//==============================================================================
procedure P_XYMovement(mo: Pmobj_t);
var
  ptryx: fixed_t;
  ptryy: fixed_t;
  player: Pplayer_t;
  xmove: fixed_t;
  ymove: fixed_t;
  special: integer;
  wasonfloorz: boolean;
  wasonslope: boolean;
  oldsector: Psector_t;
begin
  if TMobjGameRules.StoppedBeforeMoving(mo) then
    exit;

  special := TMobjGameRules.SectorWind(mo);

  wasonfloorz := mo.z <= mo.floorz;
  oldsector := Psubsector_t(mo.subsector).sector;

  // JVAL: 20220222 - Wind thrust
  if TMobjGameRules.HasWindThrust(mo) then
    if oldsector.windthrust <> 0 then
      P_ThrustMobj(mo, oldsector.windangle, oldsector.windthrust);

  wasonslope := oldsector.renderflags and SRF_SLOPED <> 0;

  player := mo.player;

  if mo.flags3_ex and MF3_EX_NOMAXMOVE = 0 then
  begin
    if mo.momx > MAXMOVE then
      mo.momx := MAXMOVE
    else if mo.momx < -MAXMOVE then
      mo.momx := -MAXMOVE;

    if mo.momy > MAXMOVE then
      mo.momy := MAXMOVE
    else if mo.momy < -MAXMOVE then
      mo.momy := -MAXMOVE;
  end;

  xmove := mo.momx;
  ymove := mo.momy;

  repeat
    if (xmove > MAXMOVE div 2) or (ymove > MAXMOVE div 2) or
       (TMobjGameRules.HalvesBackwardMoves and ((xmove < -MAXMOVE div 2) or (ymove < -MAXMOVE div 2))) then
    begin
    // JVAL 20180107
    // Please do not change, the div and the _SHR1, problem with demo compatibility..
      ptryx := mo.x + xmove div 2;
      ptryy := mo.y + ymove div 2;
      xmove := _SHR1(xmove);
      ymove := _SHR1(ymove);
    end
    else
    begin
      ptryx := mo.x + xmove;
      ptryy := mo.y + ymove;
      xmove := 0;
      ymove := 0;
    end;

    // JVAL: Slopes
    // JVAL 20191209 - Fix 3d floor problem
    tmfloorz := P_3dFloorHeight(ptryx, ptryy, mo.z);
    tmceilingz := P_3dCeilingHeight(ptryx, ptryy, mo.z);

    if not P_TryMove(mo, ptryx, ptryy) then
      if TMobjGameRules.BlockedMove(mo, ptryx, ptryy, xmove, ymove) then
        exit;
  until not ((xmove <> 0) or (ymove <> 0));

  // slow down
  if (player <> nil) and (player.cheats and CF_NOMOMENTUM <> 0) then
  begin
    // debug option for no sliding at all
    mo.momx := 0;
    mo.momy := 0;
    exit;
  end;

  if mo.flags and TMobjGameRules.NoFrictionFlags <> 0 then
    exit; // no friction for missiles ever

  if mo.flags3_ex and MF3_EX_BOUNCE <> 0 then
    if G_PlayingEngineVersion <= VERSION206 then
      exit; // no friction for bouncing objects

  if TMobjGameRules.AirborneFriction(mo, player, wasonfloorz, wasonslope, oldsector) then
    exit;

  if TMobjGameRules.FallsFree(mo, player) then
  begin
    if G_PlayingEngineVersion <= VERSION203 then
      exit; // no friction when airborne
    if wasonfloorz and wasonslope and (oldsector = Psubsector_t(mo.subsector).sector) then
    begin
      if oldsector.flags and SF_SLIPSLOPEDESCENT <> 0 then
        exit; // Slip sector while descenting slope
      mo.z := mo.floorz;
    end
    else
      exit;
  end;

  if mo.flags and MF_CORPSE <> 0 then
  begin
    // do not stop sliding
    //  if halfway off a step with some momentum
    if (mo.momx > FRACUNIT div 4) or
       (mo.momx < -FRACUNIT div 4) or
       (mo.momy > FRACUNIT div 4) or
       (mo.momy < -FRACUNIT div 4) then
    begin
      if mo.floorz <> P_3dFloorHeight(mo) then // JVAL: 3d floors
        exit;
    end;
  end;

  if (mo.momx > -STOPSPEED) and
     (mo.momx < STOPSPEED) and
     (mo.momy > -STOPSPEED) and
     (mo.momy < STOPSPEED) and
     ((player = nil) or
      ((player.cmd.forwardmove = 0) and
       (player.cmd.sidemove = 0))) then
  begin
    TMobjGameRules.StopWalking(player);

    mo.momx := 0;
    mo.momy := 0;
  end
  else
    TMobjGameRules.ApplyFriction(mo, special);
end;

//==============================================================================
//
// P_ZMovement
//
// One routine for Doom, Heretic, Hexen and Strife (issue #185, step 2c-3): the four games did the
// same things in the same order; what a game does at each stage is in TMobjGameRules. The floor
// stage, the longest, is a rule of its own because the order of what happens when a thing lands
// (splash, state, bounce, damage, explosion) is different in every game and decides states and sounds.
//
//==============================================================================
procedure P_ZMovement(mo: Pmobj_t);
var
  ladderticks: integer;
  ceilz: fixed_t;
begin
  ladderticks := TMobjGameRules.ZPrelude(mo);

  // adjust height
  if ladderticks > 0 then
  begin
    mo.z := mo.z + mo.momz;
    mo.momz := (mo.momz * 7) div 8;
    if mo.momz < TMobjGameRules.LadderStopMomz then
      mo.momz := 0;
  end
  else
    mo.z := mo.z + mo.momz;

  TMobjGameRules.AfterZAdjust(mo);

  TMobjGameRules.ZFloat(mo);

  // clip movement
  if mo.z <= mo.floorz then
  begin
    if not TMobjGameRules.ZHitFloor(mo) then
      exit;
  end
  else
    TMobjGameRules.ZGravity(mo);

  ceilz := TMobjGameRules.CeilingLimit(mo);

  if mo.z + mo.height > ceilz then
    TMobjGameRules.ZHitCeiling(mo, ceilz);
end;

//==============================================================================
//
// P_MobjThinker
//
// The one thinker of the map objects: its address is what marks a thinker as a mobj
//
//==============================================================================
procedure P_MobjThinker(mobj: Pmobj_t);
begin
  // JVAL: Clear just spawned flag
  TMobjGameRules.ClearJustAppeared(mobj);

  // momentum movement
  TMobjGameRules.BeginThink;
  if (mobj.momx <> 0) or
     (mobj.momy <> 0) or
     TMapGameRules.IsSkullFlying(mobj) then
  begin
    P_XYMovement(mobj);

    if P_ThinkerIsRemoved(@mobj.thinker) then
      exit; // mobj was removed

    TMobjGameRules.AfterXYMovement(mobj);
  end
  else
    TMobjGameRules.StandsStill(mobj);

  if not TMobjGameRules.ZPhase(mobj) then
    exit; // mobj was removed

  // cycle through states,
  // calling action functions at transitions
  if mobj.tics <> -1 then
  begin
    dec(mobj.tics);

    TMobjGameRules.BeforeStateCycle(mobj);

    // you can cycle through multiple states in a tic
    if TMobjGameRules.CyclesStatesWhileNoTics then
    begin
      while mobj.tics = 0 do
        if not P_SetMobjState(mobj, mobj.state.nextstate) then
          exit; // freed itself
    end
    else if mobj.tics = 0 then
      if not P_SetMobjState(mobj, mobj.state.nextstate) then
        exit; // freed itself
  end
  else if TMobjGameRules.MonstersRespawn then
  begin
    // check for nightmare respawn
    if mobj.flags and MF_COUNTKILL = 0 then
      exit;

    if not respawnmonsters then
      exit;

    mobj.movecount := mobj.movecount + 1;

    if mobj.movecount < TMobjGameRules.RespawnTime then
      exit;

    if leveltime and 31 <> 0 then
      exit;

    if P_Random > 4 then
      exit;

    if TMobjGameRules.NeverRespawns(mobj) then
      exit;

    TMobjGameRules.NightmareRespawn(mobj);
  end;
end;

//==============================================================================
//
// P_SpawnMobj
//
//==============================================================================
function P_SpawnMobj(x, y, z: fixed_t; _type: integer; const mthing: Pmapthing_t = nil): Pmobj_t;
var
  mobj: Pmobj_t;
  st: Pstate_t;
  info: Pmobjinfo_t;
  space: fixed_t;
  sec: Psector_t;
  msec: Psector_t;  // JVAL: 3d floors
  lowfloorheight, hifloorheight: fixed_t; // JVAL: 3d floors
  onmidfloor: Boolean;
  spawnfloorheight, spawnceilingheight: fixed_t;  // JVAL: Slopes
begin
  mobj := Z_Malloc(SizeOf(mobj_t), PU_LEVEL, nil);

  ZeroMemory(mobj, SizeOf(mobj_t));

  mobj.key := P_GenGlobalMobjKey;

  info := @mobjinfo[_type];
  mobj._type := _type;
  mobj.info := info;
  mobj.x := x;
  mobj.y := y;
  mobj.radius := info.radius;
  mobj.height := info.height;
  mobj.flags := info.flags;
  mobj.flags_ex := info.flags_ex;
  // The flags of the game, the "just appeared" flag, the fields only some games have
  TMobjGameRules.InitGameFields(mobj, info);
  mobj.flags3_ex := info.flags3_ex;
  mobj.flags5_ex := info.flags5_ex;
  mobj.flags6_ex := info.flags6_ex;
  mobj.scale := info.scale;
  mobj.gravity := info.gravity;
  mobj.pushfactor := info.pushfactor;
  mobj.friction := info.friction;
  mobj.renderstyle := info.renderstyle;
  mobj.alpha := info.alpha;
  TMobjGameRules.InitBob(mobj);
  mobj.health := info.spawnhealth;
  mobj.mass := info.mass;
  mobj.WeaveIndexXY := info.WeaveIndexXY;
  mobj.WeaveIndexZ := info.WeaveIndexZ;
  mobj.painchance := info.painchance;
  mobj.spriteDX := info.spriteDX;
  mobj.spriteDY := info.spriteDY;
  // mbf21+
  mobj.infighting_group := info.infighting_group;
  mobj.projectile_group := info.projectile_group;
  mobj.splash_group := info.splash_group;
  mobj.bloodcolor := info.bloodcolor;
  mobj.translationname := info.translationname;
  R_InitMobjTranslation(mobj);

  if TMobjGameRules.HasReactionTime then
    mobj.reactiontime := info.reactiontime;

  mobj.lastlook := P_Random mod MAXPLAYERS;
  // do not set the state with P_SetMobjState,
  // because action routines can not be called yet

  // Set the state, but do not use P_SetMobjState, because action
  // routines can't be called yet.  If the spawnstate has an action
  // routine, it will not be called.
  st := @states[info.spawnstate];

  mobj.state := st;
  mobj.tics := P_TicsFromState(st);
  mobj.sprite := st.sprite;
  mobj.frame := st.frame;
  TMobjGameRules.InitStateMemory(mobj, st);

  // set subsector and/or block links
  P_SetThingPosition(mobj);

  sec := Psubsector_t(mobj.subsector).sector;

  // JVAL: Slopes
  spawnfloorheight := P_FloorHeight(sec, x, y);
  spawnceilingheight := P_CeilingHeight(sec, x, y);
  mobj.floorz := spawnfloorheight;  // JVAL: Slopes
  mobj.ceilingz := spawnceilingheight;  // JVAL: Slopes
  onmidfloor := false;

// JVAL: 3d floors
  if sec.midsec >= 0 then
  begin
    msec := @sectors[sec.midsec];
    if mthing <> nil then
      if mthing.options and MTF_ONMIDSECTOR <> 0 then
        onmidfloor := true;
    if onmidfloor then
      mobj.floorz := msec.ceilingheight
    else if not onmidfloor and (z = ONCEILINGZ) then
      mobj.ceilingz := msec.floorheight
    else if z = TMobjGameRules.FloatSpawnZ then
    begin
      lowfloorheight := msec.floorheight - spawnfloorheight;  // JVAL: Slopes
      hifloorheight := spawnceilingheight - msec.ceilingheight; // JVAL: Slopes
      if lowfloorheight < mobj.info.height then
        mobj.floorz := msec.ceilingheight
      else if hifloorheight < mobj.info.height then
        mobj.ceilingz := msec.floorheight
      else if mthing = nil then
      begin
        if N_Random < Round(lowfloorheight / (lowfloorheight + hifloorheight) * 255) then
          mobj.ceilingz := msec.floorheight
        else
          mobj.floorz := msec.ceilingheight;
      end;
    end
    else
    begin
      if z > msec.floorheight then
        mobj.floorz := msec.ceilingheight
      else
        mobj.ceilingz := msec.floorheight;
    end;
  end
  else
    msec := nil;

  if z = ONFLOORZ then
  begin
    mobj.z := mobj.floorz;
    TMobjGameRules.SpawnedOnFloor(mobj);
  end
  else if z = ONCEILINGZ then
    mobj.z := mobj.ceilingz - mobj.info.height
  else if z = TMobjGameRules.FloatSpawnZ then
  begin
    space := mobj.ceilingz - mobj.info.height - mobj.floorz;
    if space > 48 * FRACUNIT then
    begin
      space := space - 40 * FRACUNIT;
      mobj.z := TMobjGameRules.RandomFloatHeight(space) + mobj.floorz + 40 * FRACUNIT;
    end
    else
      mobj.z := mobj.floorz
  end
  else if TMobjGameRules.SpawnZIsHeight(mobj) then
    mobj.z := mobj.floorz + z    // artifact z passed in as height
  else
    mobj.z := z;

  if (msec <> nil) or (sec.renderflags and SRF_SLOPED <> 0) then  // JVAL: Slopes
  begin
    if mobj.z > mobj.ceilingz - mobj.info.height then
      mobj.z := mobj.ceilingz - mobj.info.height;
    if mobj.z < mobj.floorz then
      mobj.z := mobj.floorz;

    TMobjGameRules.FootClipOnMidOrSlope(mobj);
  end
  else
    TMobjGameRules.FootClipOnFloor(mobj, sec);

  mobj.momz := mobj.info.vspeed;

  mobj.thinker._function.acp1 := @P_MobjThinker;

  P_AddThinker(@mobj.thinker);

  mobj.prevx := mobj.x;
  mobj.prevy := mobj.y;
  mobj.prevz := mobj.z;
  mobj.nextx := mobj.x;
  mobj.nexty := mobj.y;
  mobj.nextz := mobj.z;
  mobj.prevangle := mobj.angle;
  mobj.nextangle := mobj.angle;
  mobj.intrplcnt := 0;

  result := mobj;
end;

//==============================================================================
//
// P_RemoveMobj
//
//==============================================================================
procedure P_RemoveMobj(mobj: Pmobj_t);
begin
  TMobjGameRules.BeforeRemove(mobj);

  // unlink from sector and block lists
  P_UnsetThingPosition(mobj);

  // Delete all nodes on the current sector_list               phares 3/16/98

  TMobjGameRules.ReleaseSectorList;

  if mobj.flags4_ex and MF4_EX_ALWAYSFINISHSOUND <> 0 then
    S_UnlinkSound(mobj)
  else if mobj.flags4_ex and MF4_EX_NEVERFINISHSOUND <> 0 then
    S_StopSound(mobj)
  // From Woof: [FG] removed map objects may finish their sounds
  else if full_sounds then
    S_UnlinkSound(mobj)
  else
    // stop any playing sound
    S_StopSound(mobj);

  P_RemoveMobjCustomParams(mobj.customparams);

  // free block
  P_RemoveThinker(Pthinker_t(mobj));
end;

//==============================================================================
//
// P_RespawnSpecials
//
//==============================================================================
procedure P_RespawnSpecials;
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psector_t;
  mo: Pmobj_t;
  mthing: Pmapthing_t;
  i: integer;
  queue: TRespawnQueue<mapthing_t>;
begin
  // only respawn items in deathmatch
  if deathmatch <> 2 then
    exit; //

  queue := P_World.ItemRespawn;

  // nothing left to respawn?
  if queue.IsEmpty then
    exit;

  // wait at least 30 seconds
  if TMobjGameRules.ItemRespawnWaits(queue.OldestTime) then
    exit;

  mthing := Pmapthing_t(queue.Oldest);

  x := mthing.x * FRACUNIT;
  y := mthing.y * FRACUNIT;

  // spawn a teleport fog at the new spot
  ss := TMapGameRules.PointInSector(x, y);
  TMobjGameRules.SpawnItemFog(x, y, ss.floorheight, mthing);

  // find which type to spawn
  i := 0;
  while i < nummobjtypes do
  begin
    if mthing._type = mobjinfo[i].doomednum then
      break;
    inc(i);
  end;

  // spawn it
  z := TMobjGameRules.SpawnHeightOfType(i);

  mo := P_SpawnMobj(x, y, z, i, mthing);
  mo.spawnpoint := mthing^;
  if mo.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    mo.angle := ANG1 * mthing.angle
  else
    mo.angle := ANG45 * (mthing.angle div 45);

  // pull it from the que
  queue.DropOldest;
end;

//==============================================================================
//
// P_SpawnPlayer
//
//==============================================================================
function P_SpawnPlayer(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
begin
  result := TMobjGameRules.SpawnPlayer(mthing, uthing);
end;

//==============================================================================
//
// P_SpawnMapThing
//
//==============================================================================
function P_SpawnMapThing(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
begin
  result := TMobjGameRules.SpawnMapThing(mthing, uthing);
end;

//
// GAME SPAWN FUNCTIONS
//

//==============================================================================
//
// P_SpawnPuff
//
//==============================================================================
procedure P_SpawnPuff(x, y, z: fixed_t);
begin
  TMobjGameRules.SpawnPuff(x, y, z);
end;

//==============================================================================
//
// P_CheckMissileSpawn
// Moves the missile forward a bit
//  and possibly explodes it right there.
//
//==============================================================================
function P_CheckMissileSpawn(th: Pmobj_t): boolean;
begin
  TMobjGameRules.RandomizeSpawnTics(th);

  // move a little forward so an angle can
  // be computed if it immediately explodes
  if TMobjGameRules.HalvesMissileStepByDivision then
  begin
    th.x := th.x + th.momx div 2;
    th.y := th.y + th.momy div 2;
    th.z := th.z + th.momz div 2;
  end
  else
  begin
    th.x := th.x + _SHR1(th.momx);
    th.y := th.y + _SHR1(th.momy);
    th.z := th.z + _SHR1(th.momz);
  end;

  if not P_TryMove(th, th.x, th.y) then
  begin
    P_ExplodeMissile(th);
    result := false;
  end
  else
    result := true;
end;

//==============================================================================
//
// P_SpawnMissile
//
//==============================================================================
function P_SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
begin
  result := TMobjGameRules.SpawnMissile(source, dest, _type);
end;

//==============================================================================
//
// P_SpawnMissileXYZ
//
//==============================================================================
function P_SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
begin
  result := TMobjGameRules.SpawnMissileXYZ(x, y, z, source, dest, _type);
end;

//==============================================================================
//
// P_SpawnMissileAngleZSpeed
//
//==============================================================================
function P_SpawnMissileAngleZSpeed(source: Pmobj_t; z: fixed_t; _type: integer; angle: angle_t;
  momz: fixed_t; speed: fixed_t; owner: Pmobj_t): Pmobj_t;
var
  mo: Pmobj_t;
  flags_ex: integer;
begin
  TMobjGameRules.SaveRandom;

  flags_ex := mobjinfo[Ord(_type)].flags_ex;

  if flags_ex and MF_EX_FLOORHUGGER <> 0 then
  begin
    if G_PlayingEngineVersion >= TMapGameRules.SlopesVersion then
      z := source.floorz
    else
      z := ONFLOORZ;
  end
  else if flags_ex and MF_EX_CEILINGHUGGER <> 0 then
  begin
    if G_PlayingEngineVersion >= TMapGameRules.SlopesVersion then
      z := source.ceilingz
    else
      z := ONCEILINGZ;
  end
  else if z <> ONFLOORZ then
    z := z - source.floorz;

  mo := P_SpawnMobj(source.x, source.y, z, _type);

  TMobjGameRules.MissileSeeSound(mo);

  if owner <> nil then
    mo.target := owner
  else
    mo.target := source;  // Originator
  mo.angle := angle;
  angle := angle shr ANGLETOFINESHIFT;
  mo.momx := FixedMul(speed, finecosine[angle]);
  mo.momy := FixedMul(speed, finesine[angle]);
  mo.momz := momz;
  if P_CheckMissileSpawn(mo) then
    result := mo
  else
    result := nil;

  TMobjGameRules.RestoreRandom;
end;

//==============================================================================
//
// P_SpawnPlayerMissile
// Tries to aim at a nearby monster
//
//==============================================================================
function P_SpawnPlayerMissile(source: Pmobj_t; _type: integer): Pmobj_t;
begin
  result := TMobjGameRules.SpawnPlayerMissile(source, _type);
end;

//==============================================================================
//
// FUNC P_SeekerMissile
//
// The missile's tracer field must be the target.  Returns true if
// target was tracked, false if not.
//
//==============================================================================
function P_SeekerMissile(actor: Pmobj_t; thresh, turnMax: angle_t): boolean;
var
  dir: integer;
  dist: integer;
  delta: angle_t;
  angle: angle_t;
  target: Pmobj_t;
  speed: fixed_t;
begin
  target := TMobjGameRules.SeekerTarget(actor);
  speed := TMobjGameRules.SeekerSpeed(actor);
  if (target = nil) or (TMobjGameRules.SeekerNeedsSpeed and (speed = 0)) then
  begin
    result := false;
    exit;
  end;

  if target.flags and MF_SHOOTABLE = 0 then
  begin // Target died
    actor.tracer := nil;
    result := false;
    exit;
  end;

  dir := P_FaceMobj(actor, target, delta);
  if delta > thresh then
  begin
    delta := delta shr 1;
    if delta > turnMax then
      delta := turnMax;
  end;

  if dir <> 0 then
  begin // Turn clockwise
    actor.angle := actor.angle + delta;
  end
  else
  begin // Turn counter clockwise
    actor.angle := actor.angle - delta;
  end;

  angle := actor.angle shr ANGLETOFINESHIFT;
  actor.momx := FixedMul(speed, finecosine[angle]);
  actor.momy := FixedMul(speed, finesine[angle]);
  if (actor.z + actor.height < target.z) or
     (target.z + target.height < actor.z) then
  begin // Need to seek vertically
    dist := P_AproxDistance(target.x - actor.x, target.y - actor.y);
    if speed = 0 then
      dist := 1
    else
    begin
      dist := dist div speed;
      if dist < 1 then
        dist := 1;
    end;
    actor.momz := ((target.z + target.height div 2) - (actor.z + actor.height div 2)) div dist;
  end;
  result := true;
end;

//==============================================================================
//
// FUNC P_GetThingFloorType
//
// JVAL: 9 December 2007, Added terrain types
//
//==============================================================================
function P_GetThingFloorType(thing: Pmobj_t): integer;
begin
  result := flats[TMobjGameRules.TerrainFloorPic(thing)].terraintype;
end;

//==============================================================================
//
// FUNC P_HitFloor
//
//==============================================================================
function P_HitFloor(thing: Pmobj_t): integer;
begin
  result := TMobjGameRules.HitFloor(thing);
end;

//==============================================================================
//
// P_CreateTIDList
//
//==============================================================================
procedure P_CreateTIDList;
begin
  TMobjGameRules.CreateTIDList;
end;

end.

