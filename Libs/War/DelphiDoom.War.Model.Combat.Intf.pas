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
  System.Generics.Collections, DelphiDoom.War.Model.Types;

type
  /// <summary>
  ///   What the spells tell the game around the model (the sounds: the model makes the entities of the effects itself).
  ///   Optional: the events object given to the factory is asked whether it supports it. Never per tic and unit
  /// </summary>
  IWarSpellEvents = interface
    ['{3F81C6A2-7E5D-4B09-A1C4-9D2B60E7F518}']
    /// <summary>WAR_NORMAL_SPELL at a position: a spell has been cast there</summary>
    procedure SpellCast(const APosition: TWarVec2);
    /// <summary>WAR_DEAD_SPIDER_SCORPION: a summoned spider or scorpion ran out of mana and dies</summary>
    procedure SummonExpired(const APosition: TWarVec2; AUnitType: Integer);
  end;

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
    /// <summary>wgrid_build of wmap_updateMap: the grid of the units that the attacks and the projectiles search in</summary>
    procedure BuildNearUnits;
    /// <summary>updateProjectiles of wmap_updateMap: the flight of every projectile</summary>
    procedure UpdateProjectiles;
    /// <summary>we_getNearUnits: the slots of the units within the distance (tiles) of the tile, from the grid of this tic</summary>
    procedure CollectNearUnits(const ATile: TWarVec2; ADistance: Integer; AResult: TList<Integer>);
    /// <summary>we_takeDamage</summary>
    procedure TakeDamage(ASlot, AMinDamage, ARndDamage: Integer);
    /// <summary>we_increaseUnitHp and we_decreaseUnitHp</summary>
    procedure IncreaseHp(ASlot, AHp: Integer);
    procedure DecreaseHp(ASlot, AHp: Integer);
    /// <summary>we_decreaseUnitMana: False (and the message) if the unit has less</summary>
    function DecreaseMana(ASlot, AMana: Integer): Boolean;
    /// <summary>we_meleeWallAttack: a blow on the piece of wall of that index (4 times in 5, always for a catapult)</summary>
    procedure MeleeWallAttack(AAttackerSlot, APieceIndex: Integer);
    /// <summary>we_rangeWallAttack: a projectile from the attacker to the centre of the tile of the piece</summary>
    procedure RangeWallAttack(AAttackerSlot, AWallSlot, APieceIndex: Integer);
  end;

implementation

end.
