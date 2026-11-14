{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - a player fires a missile (P_SpawnPlayerMissile)        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PlayerMissileSpawner;

interface

uses
  p_mobj_h;

type
  /// <summary>
  ///   P_SpawnPlayerMissile for Doom and Strife (issue #185, step 2c-4): the two copies were one
  ///   routine; what a game does differently is in TMobjGameRules of the game
  ///   (AimWithoutTarget, AfterAim, AdjustMissileZ and the MissileSeeSound of P_SpawnMissile).
  ///   Heretic and Hexen aim and spawn the missile in another way (their own sounds, the first
  ///   step of the missile, the foot clip) and keep their methods: their projects do not
  ///   compile this unit
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TMobjPlayerMissileSpawner = class sealed
  public
    /// <summary>
    ///   Spawns a missile of this type in front of the player, aimed at the target the player
    ///   can see (up, down or in front of him). Gives nil when the missile explodes at once
    /// </summary>
    class function Spawn(source: Pmobj_t; _type: integer): Pmobj_t; static;
  end;

implementation

uses
  d_delphi,
  doomstat,
  doomdef,
  tables,
  m_fixed,
  info_h,
  d_player,
  g_game,
  p_local,
  p_map,
  p_mobj,
  DelphiDoom.Engine.World.MobjRules;

class function TMobjPlayerMissileSpawner.Spawn(source: Pmobj_t; _type: integer): Pmobj_t;
var
  th: Pmobj_t;
  an: angle_t;
  x: fixed_t;
  y: fixed_t;
  z: fixed_t;
  slope: fixed_t;
  speed: fixed_t;
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

      TMobjGameRules.AimWithoutTarget(source, an, slope);

    end;
  end;

  TMobjGameRules.AfterAim(source);

  x := source.x;
  y := source.y;
  // Also z axis shift calculation
  if zaxisshift then
    z := source.z + 4 * 8 * FRACUNIT + (Pplayer_t(source.player).lookdir * FRACUNIT) div 173
  else
    z := source.z + 4 * 8 * FRACUNIT;

  TMobjGameRules.AdjustMissileZ(source, z);

  th := P_SpawnMobj(x, y, z, _type);

  TMobjGameRules.MissileSeeSound(th);

  th.target := source;
  th.angle := an;
  an := an shr ANGLETOFINESHIFT;
  speed := th.info.speed;
  th.momx := FixedMul(speed, finecosine[an]);
  th.momy := FixedMul(speed, finesine[an]);
  th.momz := FixedMul(speed, slope);

  if P_CheckMissileSpawn(th) then
    result := th
  else
    result := nil;
end;

end.
