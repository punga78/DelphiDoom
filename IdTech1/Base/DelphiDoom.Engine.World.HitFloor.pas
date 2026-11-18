{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a thing hits a liquid floor (P_HitFloor)               }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.HitFloor;

interface

uses
  p_mobj_h;

type
  /// <summary>
  ///   P_HitFloor for Doom and Strife (issue #185, step 2c-4): the two copies were one routine;
  ///   what a game does differently is in TMobjGameRules of the game (HitFloorIgnoredByVersion,
  ///   NukageSplashZ, NukageSplashSound). Heretic and Hexen have another routine (the order of
  ///   the checks, the splashes that are not asked for, the terrain of their own) and keep their
  ///   methods: their projects do not compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TMobjHitFloor = class sealed
  public
    /// <summary>
    ///   Called when a thing lands on the floor: splashes on water, lava, sludge and nukage.
    ///   Gives the type of floor (FLOOR_SOLID when there is no splash)
    /// </summary>
    class function Hit(thing: Pmobj_t): integer; static;
  end;

implementation

uses
  d_delphi,
  doomstat,
  doomdef,
  tables,
  m_fixed,
  info_h,
  r_defs,
  g_game,
  m_rnd,
  p_local,
  p_params,
  p_3dfloors,
  p_mobj,
  s_sound,
  sounddata,
  DelphiDoom.Engine.World.MobjRules;

class function TMobjHitFloor.Hit(thing: Pmobj_t): integer;
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

  if TMobjGameRules.HitFloorIgnoredByVersion then
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
        if allowterrainsplashes or TGameSession.DemoRecording or TGameSession.DemoPlayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASHBASE));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SPLASH));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := 2 * FRACUNIT + (P_Random * 256);
          TSoundRoutines.S_StartSound(mo, Ord(sfx_gloop));
        end;
        result := FLOOR_WATER;
        exit;
      end;
    FLOOR_LAVA:
      begin
        if allowterrainsplashes or TGameSession.DemoRecording or TGameSession.DemoPlayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_LAVASMOKE));
          mo.momz := FRACUNIT + (P_Random * 128);
          TSoundRoutines.S_StartSound(mo, Ord(sfx_burn));
        end;
        result := FLOOR_LAVA;
        exit;
      end;
    FLOOR_SLUDGE:
      begin
        if allowterrainsplashes or TGameSession.DemoRecording or TGameSession.DemoPlayback then
        begin
          P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGESPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, z, Ord(MT_SLUDGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          TSoundRoutines.S_StartSound(mo, Ord(sfx_sgloop));
        end;
        result := FLOOR_SLUDGE;
        exit;
      end;
    FLOOR_NUKAGE:
      begin
        if allowterrainsplashes or TGameSession.DemoRecording or TGameSession.DemoPlayback then
        begin
          P_SpawnMobj(thing.x, thing.y, TMobjGameRules.NukageSplashZ(z), Ord(MT_NUKAGESPLASH));
          mo := P_SpawnMobj(thing.x, thing.y, TMobjGameRules.NukageSplashZ(z), Ord(MT_NUKAGECHUNK));
          mo.target := thing;
          mo.momx := (P_Random - P_Random) * 256;
          mo.momy := (P_Random - P_Random) * 256;
          mo.momz := FRACUNIT + (P_Random * 256);
          TSoundRoutines.S_StartSound(mo, TMobjGameRules.NukageSplashSound);
        end;
        result := FLOOR_NUKAGE;
        exit;
      end;
  end;
end;

end.
