{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the neutral catalog of the tables         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The bits of the frame of a state: the sprite frame (A is 0) and the bright flag</summary>
  EXPORT_FRAME_MASK = $7FFF;
  EXPORT_FRAME_FULLBRIGHT = $8000;
  /// <summary>Bits of the engine flags of a state: the duration is a random one</summary>
  EXPORT_STATE_RANDOM_SELECT = $40;
  EXPORT_STATE_RANDOM_RANGE = $80;
  /// <summary>The bit of the MBF21 flags of a state that makes it fast in the skill 5</summary>
  EXPORT_STATE_SKILL5FAST = 1;
  /// <summary>The value of fixed point 1.0</summary>
  EXPORT_FRACUNIT = 65536;
  /// <summary>The default push factor and friction of a thing (the engine constants)</summary>
  EXPORT_DEFAULT_PUSHFACTOR = EXPORT_FRACUNIT div 4;
  EXPORT_ORIGINAL_FRICTION = $E800;

type
  /// <summary>Raised when the tables cannot be written (a source or a profile is missing)</summary>
  ETableExportException = class(Exception);

  /// <summary>The numbers of a thing (mobjinfo): fixed point values and states are numbers too</summary>
  TExportThingField = (
    tfInheritsFrom, tfDoomedNum, tfSpawnState, tfSpawnHealth, tfSeeState, tfSeeSound, tfReactionTime,
    tfAttackSound, tfPainState, tfPainChance, tfPainSound, tfMeleeState, tfMissileState, tfDeathState,
    tfXDeathState, tfDeathSound, tfSpeed, tfRadius, tfHeight, tfMass, tfDamage, tfActiveSound,
    tfRaiseState, tfFlags, tfFlags2, tfFlagsEx, tfFlags2Ex, tfFlags3Ex, tfFlags4Ex, tfFlags5Ex,
    tfFlags6Ex, tfCustomSound1, tfCustomSound2, tfCustomSound3, tfExplosionDamage, tfExplosionRadius,
    tfMeleeDamage, tfMeleeSound, tfRenderStyle, tfAlpha, tfDropItem, tfMissileType, tfHealState,
    tfCrashState, tfCrushState, tfInteractState, tfMissileHeight, tfVSpeed, tfPushFactor, tfFriction,
    tfScale, tfGravity, tfMinMissileChance, tfFloatSpeed, tfNormalSpeed, tfFastSpeed, tfGender,
    tfMeleeRange, tfMaxStepHeight, tfMaxDropoffHeight, tfGibHealth, tfMaxTargetRange, tfWeaveIndexXY,
    tfWeaveIndexZ, tfSpriteDX, tfSpriteDY, tfInfightingGroup, tfProjectileGroup, tfSplashGroup,
    tfRipSound, tfBloodColor, tfMeleeThreshold);

  /// <summary>The texts of a thing</summary>
  TExportThingText = (ttName, ttName2, ttObituary, ttHitObituary, ttTranslation);

  /// <summary>A thing as the tables of the game have it; a game without a field leaves it at zero</summary>
  TExportThing = record
    Numbers: array[TExportThingField] of Integer;
    Texts: array[TExportThingText] of string;
  end;

  /// <summary>The numbers of a state</summary>
  TExportStateField = (sfSprite, sfFrame, sfTics, sfTics2, sfNextState, sfMisc1, sfMisc2, sfFlagsEx,
    sfMbf21Bits);

  /// <summary>A state of the table of the states</summary>
  TExportState = record
    Numbers: array[TExportStateField] of Integer;
    /// <summary>The state has an action pointer (even the one of the NULL action)</summary>
    HasAction: Boolean;
    /// <summary>The name of the action in upper case, as the table of the actions knows it; empty if it does not</summary>
    ActionName: string;
    /// <summary>The state has a list of arguments for its action</summary>
    HasParams: Boolean;
    /// <summary>The list of arguments as it is written after the name of the action</summary>
    Params: string;
    /// <summary>The name of the sprite (four characters)</summary>
    SpriteName: string;
  end;

  /// <summary>The numbers of a weapon</summary>
  TExportWeaponField = (wfAmmo, wfUpState, wfDownState, wfReadyState, wfAttackState, wfHoldAttackState,
    wfFlashState, wfAmmoPerShot, wfMbf21Bits);

  /// <summary>One entry of the table of the weapons (Heretic has two levels and Hexen four classes)</summary>
  TExportWeapon = record
    Numbers: array[TExportWeaponField] of Integer;
    /// <summary>The number of the weapon (WP_...)</summary>
    WeaponNo: Integer;
    /// <summary>Only Heretic: 1 or 2</summary>
    Level: Integer;
    /// <summary>Only Hexen: the class of the player</summary>
    PlayerClass: Integer;
  end;

  /// <summary>The lists of names of flags: each has the bits of one field</summary>
  TExportFlagSet = (fsMobjFlags, fsMobjFlags2, fsMobjFlagsEx, fsMobjFlags2Ex, fsMobjFlags3Ex,
    fsMobjFlags4Ex, fsMobjFlags5Ex, fsMobjFlags6Ex, fsStateFlagsEx, fsStateFlagsMbf21, fsWeaponFlagsMbf21);

  /// <summary>The enumerations of the engine whose names the exports write</summary>
  TExportEnum = (eeState, eeSprite, eeSound, eeMobj, eeGender, eeRenderStyle, eeWeapon, eePlayerClass,
    eeAmmo);

  /// <summary>The three groups of the MBF21 things</summary>
  TExportGroup = (egInfighting, egProjectile, egSplash);

  /// <summary>A label of the states of a thing or of a weapon and the state that it starts at</summary>
  TExportStateLabel = record
    Name: string;
    State: Integer;
  end;

implementation

end.
