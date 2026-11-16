{******************************************************************************}
{                                                                              }
{  DelphiDoom: Radix game - points of extension of the movement rules          }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.World.PhysicsExtension;

interface

uses
  m_fixed,
  p_mobj_h,
  r_defs;

type
  /// <summary>
  ///   The physics of Rad-X where the rules of Doom (TInterGameRules, TMapGameRules, TMobjGameRules)
  ///   ask for it (issue #169, the "Aggancio della fisica" of IdTech1\Radix\CLAUDE.md). The unit has the
  ///   name and the signatures of the one of IdTech1\Doom\ (which adds nothing and compiles to nothing); the
  ///   project of Radix lists this one, so the engine of the other games has no call at all. The
  ///   numbers are in the classes DelphiDoom.Radix.Physics.* of IdTech1\Radix, the state of the craft
  ///   and of the walls in radix_physics and radix_walls
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TPhysicsExtension = class sealed
  strict private
    class var FHitLine: Pline_t;
  public
    const
      /// <summary>Radix has physics of its own</summary>
      Enabled = True;

    /// <summary>
    ///   P_DamageMobj of Rad-X: a hit to a craft is scaled by the skill (damage * (1 + skill) div 5
    ///   below nightmare) and by a random factor ((128 + P_Random) div 384); never less than 1
    /// </summary>
    class function PlayerDamage(target, inflictor: Pmobj_t; damage: integer): integer; static;
    /// <summary>PIT_CheckThing of Rad-X: the touch damage of the two things that overlap</summary>
    class procedure ThingContact(thing, toucher: Pmobj_t); static;
    /// <summary>P_XYMovement of Rad-X: RX_PlaneHitWall</summary>
    class procedure PlayerHitWall(mo: Pmobj_t; tryx, tryy: fixed_t); static;
    /// <summary>
    ///   PIT_CheckLine and P_XYMovement of Rad-X, before the explosion: true when the line that
    ///   stopped the missile is a wall that can be shot (RX_ShootableLine). A one sided line is
    ///   TMapCheck.BounceLine; a two sided one whose opening does not hold the missile is found among the
    ///   lines of the place that was tried (a closed sector, or the panel under an opening, is how
    ///   the walls of Radix are made). The line is remembered, because the explosion runs states
    ///   that move things and change what the movement code leaves behind
    /// </summary>
    class function MissileBlocked(mo: Pmobj_t): boolean; static;
    /// <summary>P_ExplodeMissile of Rad-X: a missile that can damage walls damages the line that MissileBlocked remembered</summary>
    class procedure MissileExploded(mo: Pmobj_t); static;
  end;

implementation

uses
  d_player,
  g_game,
  m_rnd,
  radix_physics,
  radix_walls,
  DelphiDoom.Radix.Physics.Damage;

class function TPhysicsExtension.PlayerDamage(target, inflictor: Pmobj_t; damage: integer): integer;
var
  LRandom: integer;
begin
  LRandom := P_Random;
  result := TRadixDamageRules.CraftDamage(damage, Ord(TGameSession.GameSkill), LRandom);
end;

class procedure TPhysicsExtension.ThingContact(thing, toucher: Pmobj_t);
begin
  RX_ThingTouched(thing, toucher);
end;

class procedure TPhysicsExtension.PlayerHitWall(mo: Pmobj_t; tryx, tryy: fixed_t);
begin
  RX_PlayerHitsWall(Pplayer_t(mo.player), tryx, tryy);
end;

class function TPhysicsExtension.MissileBlocked(mo: Pmobj_t): boolean;
begin
  FHitLine := RX_MissileTargetLine(mo);
  result := FHitLine <> nil;
end;

class procedure TPhysicsExtension.MissileExploded(mo: Pmobj_t);
var
  LLine: Pline_t;
begin
  LLine := FHitLine;
  FHitLine := nil;
  if LLine <> nil then
    RX_MissileHitsLine(mo, LLine);
end;

end.
