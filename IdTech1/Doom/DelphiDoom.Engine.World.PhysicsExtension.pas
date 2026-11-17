{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - points of extension of the movement rules (no game)    }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
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
  ///   The places of the rules of Doom (TInterGameRules, TMapGameRules, TMobjGameRules) where a game
  ///   that is built on them can add its own physics (issue #169, the "Aggancio della fisica" of
  ///   IdTech1\Radix\CLAUDE.md). This is the version of the games that add nothing: Enabled is a
  ///   constant False and every method is empty, so the code that tests Enabled is not compiled
  ///   and no call is left in the movement of Doom, GLDoom, Speed Haste and the compilers.
  ///   The version of Radix has the same name and the same signatures and sits in IdTech1\Radix\: the
  ///   project chooses between the two, with no conditional compilation
  /// </summary>
  /// <remarks>
  ///   Class of static methods, chosen by the project: no virtual call, no interface
  /// </remarks>
  TPhysicsExtension = class sealed
  public
    const
      /// <summary>The game has physics of its own: the callers test it before calling the methods</summary>
      Enabled = False;
      /// <summary>A thing bounced in the vertical movement (never, here: a constant, so that the tests of it are not compiled)</summary>
      Bouncing = False;
      /// <summary>The missile of the last WallBounce has been removed (never, here)</summary>
      Removed = False;

    /// <summary>
    ///   TInterGameRules.DamageMobj: what is left of a hit to a player (the damage of the hit, before
    ///   the armor); replaces the halving of the baby skill
    /// </summary>
    class function PlayerDamage(target, inflictor: Pmobj_t; damage: integer): integer; static; inline;
    /// <summary>
    ///   TMapGameRules.CheckThingContact: a thing that moves (toucher) overlaps another one, after
    ///   the push and before the pickup
    /// </summary>
    class procedure ThingContact(thing, toucher: Pmobj_t); static; inline;
    /// <summary>
    ///   TMobjGameRules.BlockedMove: the move of a player is blocked and the player slides along
    ///   the wall (the place tried is tryx, tryy)
    /// </summary>
    class procedure PlayerHitWall(mo: Pmobj_t; tryx, tryy: fixed_t); static; inline;
    /// <summary>
    ///   TMobjGameRules.BlockedMove, before the explosion: a missile was stopped; true when what
    ///   stopped it is a wall that can be shot (a target is not a mirror for the missiles that bounce).
    ///   The line is remembered for MissileExploded
    /// </summary>
    class function MissileBlocked(mo: Pmobj_t): boolean; static; inline;
    /// <summary>
    ///   TMobjGameRules.BlockedMove, after the explosion: the line that MissileBlocked remembered takes
    ///   the damage of the missile
    /// </summary>
    class procedure MissileExploded(mo: Pmobj_t); static; inline;
    /// <summary>TMobjGameRules.AfterZAdjust: a new vertical movement starts</summary>
    class procedure BeginZMovement; static; inline;
    /// <summary>TMobjGameRules.ZHitFloor: the bounce on the floor; false when the missile exploded</summary>
    class function FloorBounce(mo: Pmobj_t): boolean; static; inline;
    /// <summary>TMobjGameRules.ZHitCeiling: the bounce on the ceiling; false when the missile exploded</summary>
    class function CeilingBounce(mo: Pmobj_t): boolean; static; inline;
    /// <summary>
    ///   TMobjGameRules.BlockedMove: a thing with MF3_EX_WALLBOUNCE was blocked; true when the game
    ///   has done all of it (the bounce, or the explosion of the missile), Removed tells that the
    ///   missile has been removed and the movement is over
    /// </summary>
    class function WallBounce(mo: Pmobj_t; var xmove, ymove: fixed_t): boolean; static; inline;
  end;

implementation

class function TPhysicsExtension.PlayerDamage(target, inflictor: Pmobj_t; damage: integer): integer;
begin
  result := damage;
end;

class procedure TPhysicsExtension.ThingContact(thing, toucher: Pmobj_t);
begin
end;

class procedure TPhysicsExtension.PlayerHitWall(mo: Pmobj_t; tryx, tryy: fixed_t);
begin
end;

class function TPhysicsExtension.MissileBlocked(mo: Pmobj_t): boolean;
begin
  result := false;
end;

class procedure TPhysicsExtension.MissileExploded(mo: Pmobj_t);
begin
end;

class procedure TPhysicsExtension.BeginZMovement;
begin
end;

class function TPhysicsExtension.FloorBounce(mo: Pmobj_t): boolean;
begin
  result := true;
end;

class function TPhysicsExtension.CeilingBounce(mo: Pmobj_t): boolean;
begin
  result := true;
end;

class function TPhysicsExtension.WallBounce(mo: Pmobj_t; var xmove, ymove: fixed_t): boolean;
begin
  result := false;
end;

end.
