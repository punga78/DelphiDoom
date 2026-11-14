{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a thing of the map is spawned (P_SpawnMapThing)        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.MapThingSpawner;

interface

uses
  doomdata,
  p_mobj_h,
  p_udmf;

type
  /// <summary>
  ///   P_SpawnMapThing for Doom, Heretic and Strife (issue #185, step 2c-4): the three copies had
  ///   the same skeleton (deathmatch starts, polyobjects, player starts, filters of the game
  ///   type and of the skill, type to spawn, height, 3d floors, fields of the new thing); what a
  ///   game does differently is in TMobjGameRules of the game (MapThingPrologue,
  ///   IgnoresMapThing, SpawnStartSpot, ExcludedByNetOptions, SkipsMonster, KeepsMapThingOff,
  ///   MapThingFlags, CountItem). The order of the random draws is the one of every game.
  ///   Hexen has another skeleton (classes, spawn flags of its own, dormant things, floating
  ///   bob) and keeps its method: its project does not compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TMobjMapThingSpawner = class sealed
  public
    /// <summary>
    ///   Called when the things of the level are loaded: spawns the thing of the map, or records
    ///   it (deathmatch starts, player starts, polyobjects). The fields of the mapthing should
    ///   already be in host byte order. Gives nil when nothing is spawned
    /// </summary>
    class function Spawn(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t; static;
  end;

implementation

uses
  d_delphi,
  doomstat,
  doomdef,
  tables,
  m_fixed,
  info_h,
  info,
  info_common,
  info_rnd,
  r_defs,
  r_main,
  i_system,
  g_game,
  d_main,
  m_rnd,
  p_local,
  p_setup,
  p_params,
  p_musinfo,
  p_slopes,
  p_3dfloors, // JVAL: 3d floors
  po_man,
  p_mobj,
  DelphiDoom.Engine.World.MapRules,
  DelphiDoom.Engine.World.MobjRules;

class function TMobjMapThingSpawner.Spawn(mthing: Pmapthing_t; uthing: Pextrathing_t): Pmobj_t;
var
  i: integer;
  bit: integer;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psector_t; // JVAL: 3d floors
  msec: Psector_t;  // JVAL: 3d floors
  musinfoparam: integer;
begin
  result := nil;

  TMobjGameRules.MapThingPrologue(mthing);

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
    exit;
  end;

  if TMobjGameRules.IgnoresMapThing(mthing) then
    exit;

  if mthing._type = PO_ANCHOR_TYPE then
  begin // Polyobj Anchor Pt.
    exit;
  end
  else if (mthing._type = PO_SPAWN_TYPE) or
          (mthing._type = PO_SPAWNCRUSH_TYPE) then
  begin // Polyobj Anchor Pt.
    inc(po_NumPolyobjs);
    exit;
  end;

  if TMobjGameRules.SpawnStartSpot(mthing, uthing, result) then
    exit;

  if uthing <> nil then
  begin
    if not netgame then
      if uthing.extraflags and UDMF_TF_SINGLE = 0 then
        exit;

    if netgame and (deathmatch <> 0) then
      if uthing.extraflags and UDMF_TF_DM = 0 then
        exit;

    if netgame and (deathmatch = 0) then
      if uthing.extraflags and UDMF_TF_COOP = 0 then
        exit;
  end
  else
  begin
    // check for apropriate skill level
    if not netgame and (mthing.options and 16 <> 0) then
      exit;

    if TMobjGameRules.ExcludedByNetOptions(mthing) then
      exit;
  end;

  if uthing <> nil then
  begin
    bit := _SHL(1, Ord(gameskill));
    if bit and uthing.extraflags = 0 then
      exit;
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
      exit;
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
      exit;
  end;

  // don't spawn keycards and players in deathmatch
  if (deathmatch <> 0) and (mobjinfo[i].flags and MF_NOTDMATCH <> 0) then
    exit;

  // don't spawn any monsters if -nomonsters
  if nomonsters and TMobjGameRules.SkipsMonster(i) then
    exit;

  if TMobjGameRules.KeepsMapThingOff(i, mthing) then
    exit;

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

  z := TMobjGameRules.SpawnHeightOfType(i);

  if uthing <> nil then
    if uthing.extraflags and UDMF_TF_HASZ <> 0 then
      z := uthing.z;

// JVAL: 3d floors
  ss := TMapGameRules.PointInSector(x, y);
  if ss.midsec >= 0 then
  begin
    msec := @sectors[ss.midsec];
    if mthing.options and MTF_ONMIDSECTOR <> 0 then
    begin
      if z = ONFLOATZ then
        z := (msec.ceilingheight + P_CeilingHeight(ss, x, y)) div 2
      else if z = ONFLOORZ then
        z := msec.ceilingheight;
    end
    else
    begin
      if z = ONFLOATZ then
        z := (P_FloorHeight(ss, x, y) + msec.floorheight) div 2
      else if z = ONCEILINGZ then
        z := msec.floorheight;
    end;
  end;

  result := P_SpawnMobj(x, y, z, i, mthing);
  result.spawnpoint := mthing^;

  if mthing.options and MTF_FRIEND <> 0 then
    result.flags2_ex := result.flags2_ex or MF2_EX_FRIEND;

  if musinfoparam >= 0 then
    P_SetMobjCustomParam(result, S_MUSINFO_PARAM, musinfoparam);

  if result.tics > 0 then
    result.tics := 1 + (P_Random mod result.tics);
  if result.flags and MF_COUNTKILL <> 0 then
    inc(totalkills);
  TMobjGameRules.CountItem(result);

  if result.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    result.angle := ANG1 * mthing.angle
  else
    result.angle := ANG45 * (mthing.angle div 45);

  if mthing.options and MTF_DONOTTRIGGERSCRIPTS <> 0 then
    result.flags2_ex := result.flags2_ex or MF2_EX_DONTRUNSCRIPTS;

  if mthing.options and MTF_AMBUSH <> 0 then
    result.flags := result.flags or MF_AMBUSH;

  TMobjGameRules.MapThingFlags(result, mthing);

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

end.
