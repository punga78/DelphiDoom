{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - missiles aimed at a target (P_SpawnMissile, XYZ)       }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.MissileSpawner;

interface

uses
  m_fixed,
  p_mobj_h;

type
  /// <summary>
  ///   P_SpawnMissile and P_SpawnMissileXYZ for Doom, Heretic and Strife (issue #185, step 2c-3):
  ///   the three copies were the same routines with other rules, which are in TMobjGameRules of
  ///   the game (MissileOrigin, FuzzyAim, MissileSeeSound, SaveRandom, RestoreRandom) and in
  ///   TMapGameRules (SlopesVersion). Hexen aims its missiles in another way and keeps its own:
  ///   its project does not compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface. The random
  ///   numbers are drawn in the order of the old routines
  /// </remarks>
  TMobjMissileSpawner = class sealed
  public
    /// <summary>Spawns a missile of this type at the source and throws it at the destination</summary>
    class function SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t; static;
    /// <summary>Spawns a missile at x, y, z, with the velocity that reaches the destination in a straight line</summary>
    class function SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t; static;
  end;

implementation

uses
  d_delphi,
  tables,
  doomdef,
  g_game,
  m_rnd,
  DelphiDoom.MathCore.Types,
  DelphiDoom.MathCore.VectorMath,
  p_local,
  p_maputl,
  r_defs,
  r_main,
  info_h,
  info,
  p_mobj,
  DelphiDoom.Engine.World.MapRules,
  DelphiDoom.Engine.World.MobjRules;

class function TMobjMissileSpawner.SpawnMissile(source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
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

  th := TMobjGameRules.MissileOrigin(source, _type);

  TMobjGameRules.MissileSeeSound(th);

  th.target := source;  // where it came from
  an := TRendererMain.R_PointToAngle2(source.x, source.y, dest.x, dest.y);

  // fuzzy player
  an := TMobjGameRules.FuzzyAim(source, dest, an);

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

class function TMobjMissileSpawner.SpawnMissileXYZ(x, y, z: fixed_t; source: Pmobj_t; dest: Pmobj_t; _type: integer): Pmobj_t;
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

  th := P_SpawnMobj(x, y, z, _type);

  TMobjGameRules.MissileSeeSound(th);

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

  th.angle := TRendererMain.R_PointToAngle2(0, 0, th.momx, th.momy);

  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;

  TMobjGameRules.RestoreRandom;
end;

end.
