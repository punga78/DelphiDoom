{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - contracts of the attacks and the projectiles      }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Combat.Intf;

interface

uses
  DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   What the attacks and the projectiles tell the game around the model: sounds and explosions. Optional (the model
  ///   works without one). The calls are rare (a blow, an impact), never per tic and unit
  /// </summary>
  IWarCombatEvents = interface
    ['{5D2E8A47-0B6C-4F19-9A53-C71E6B04D8A2}']
    /// <summary>wa_playAttackSound: the blow of a unit; ASoundStep is the WAR_ACTION_STEP_SOUND_* of the attack action</summary>
    procedure AttackSound(const APosition: TWarVec2; ASoundStep: Integer);
    /// <summary>The sound of an arrow or a spear that hits (WAR_ARROW_SPEAR_HIT)</summary>
    procedure ArrowHit(const APosition: TWarVec2);
    /// <summary>
    ///   An explosion (catapult or rain of fire): the animation entity is made by the model, this is the sound
    ///   (WAR_CATAPULT_FIRE_EXPLOSION)
    /// </summary>
    procedure Explosion(const APosition: TWarVec2; ARainOfFire: Boolean);
  end;

  /// <summary>
  ///   The blows of the units and the part of the tic that comes after the states (the steps of the actions and the
  ///   flight of the projectiles). The slots are those of the pool
  /// </summary>
  IWarCombatServices = interface
    ['{A94C1E73-6D58-4B20-8F3A-1B7D2E90C5F6}']
    /// <summary>we_meleeAttack: a blow that hits 4 times in 5 (always for a catapult) with the damage of the unit</summary>
    procedure MeleeAttack(AAttackerSlot, ATargetSlot: Integer);
    /// <summary>we_rangeAttack: a projectile from the attacker to the target (a magic unit pays 2 mana, or goes idle)</summary>
    procedure RangeAttack(AAttackerSlot, ATargetSlot: Integer);
    /// <summary>wproj_createProjectile: the slot of the new entity, 0 if the pool is full</summary>
    function CreateProjectile(AProjectileType: Integer; ASourceId, ATargetId: Word; const AOrigin, ATarget: TWarVec2): Integer;
    /// <summary>
    ///   What wmap_updateMap does after the states: the grid of the units, the actions of the units and the
    ///   projectiles
    /// </summary>
    procedure UpdateAfterStates;
  end;

implementation

end.
