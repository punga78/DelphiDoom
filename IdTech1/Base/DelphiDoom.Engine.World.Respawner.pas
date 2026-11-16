{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a dead monster respawns (P_NightmareRespawn)           }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.Respawner;

interface

uses
  p_mobj_h;

type
  /// <summary>
  ///   P_NightmareRespawn for Doom, Heretic and Strife (issue #185, step 2c-3): the three copies
  ///   did the same things in the same order, and what differs is in TMobjGameRules of the game
  ///   (RespawnOldFog, RespawnFogFloor, RespawnSpawnZ, RespawnInherit). Hexen never respawns a
  ///   monster: its project does not compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface. The order
  ///   of the calls that draw random numbers (every P_SpawnMobj) is the one of the old routines
  /// </remarks>
  TMobjRespawner = class sealed
  public
    /// <summary>Respawns the monster at its spawn point, with the fogs, and removes the old body</summary>
    class procedure Respawn(mobj: Pmobj_t); static;
  end;

implementation

uses
  doomdata,
  doomdef,
  tables,
  m_fixed,
  info_h,
  r_defs,
  p_setup,
  r_main,
  p_map,
  p_slopes,
  s_sound,
  sounddata,
  p_mobj,
  DelphiDoom.Engine.World.MapRules,
  DelphiDoom.Engine.World.MobjRules;

class procedure TMobjRespawner.Respawn(mobj: Pmobj_t);
var
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  ss: Psector_t;
  mo: Pmobj_t;
  mthing: Pmapthing_t;
  h: fixed_t; // JVAL: 3d floors
begin
  x := mobj.spawnpoint.x * FRACUNIT;
  y := mobj.spawnpoint.y * FRACUNIT;

  // somthing is occupying it's position?
  if not P_CheckPosition(mobj, x, y) then
    exit; // no respwan

  // spawn a teleport fog at old spot
  // because of removal of the body?
  mo := TMobjGameRules.RespawnOldFog(mobj);

  // initiate teleport sound
  S_StartSound(mo, Ord(sfx_telept));

  // spawn a teleport fog at the new spot
  ss := TMapGameRules.PointInSector(x, y);

// JVAL: 3d floors
  h := TMobjGameRules.RespawnFogFloor(ss, mo);
  if ss.midsec >= 0 then
    if mobj.spawnpoint.options and MTF_ONMIDSECTOR <> 0 then
      h := sectors[ss.midsec].ceilingheight;

  mo := P_SpawnMobj(x, y, h, Ord(MT_TFOG));

  S_StartSound(mo, Ord(sfx_telept));

  // spawn the new monster
  mthing := @(mobj.spawnpoint);

  // spawn it
  z := TMobjGameRules.RespawnSpawnZ(mobj);

  // inherit attributes from deceased one
  mo := P_SpawnMobj(x, y, z, Ord(mobj._type), mthing);
  mo.spawnpoint := mobj.spawnpoint;
  if mo.flags2_ex and MF2_EX_PRECISESPAWNANGLE <> 0 then
    mo.angle := ANG1 * mthing.angle
  else
    mo.angle := ANG45 * (mthing.angle div 45);

  if mthing.options and MTF_DONOTTRIGGERSCRIPTS <> 0 then
    mobj.flags2_ex := mobj.flags2_ex or MF2_EX_DONTRUNSCRIPTS;

  if mthing.options and MTF_AMBUSH <> 0 then
    mo.flags := mo.flags or MF_AMBUSH;

  TMobjGameRules.RespawnInherit(mo, mobj, mthing);

  mo.reactiontime := 18;

  // remove the old monster,
  P_RemoveMobj(mobj);
end;

end.
