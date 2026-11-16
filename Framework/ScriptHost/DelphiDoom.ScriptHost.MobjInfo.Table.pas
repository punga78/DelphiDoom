{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the table of the mobjinfo functions               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  What was a function for each field of mobjinfo (66 PS_GetMobjInfo* that     }
{  differ in the field, in the type of the value and in what a type that is    }
{  not there gives) is a row of data: the declaration the scripts read, the    }
{  field and the games that have it.                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.MobjInfo.Table;

interface

uses
  DelphiDoom.ScriptHost.MobjInfo.Intf,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.World.Intf;

type
  /// <summary>How a field is stored and what scripts see for a type that is not there</summary>
  TScriptMobjInfoFieldInfo = record
    Kind: TScriptMobjInfoKind;
    /// <summary>The number for a type that is not there (texts and sounds give the empty text)</summary>
    Invalid: Integer;
  end;

  /// <summary>The shape of the function that scripts call</summary>
  TScriptMobjInfoShape = (
    /// <summary>function Name(const typ: integer): integer or string, of the field</summary>
    msField,
    /// <summary>function GetMobjInfoFlag(const typ: Integer; const flg: integer): boolean</summary>
    msFlag
  );

  /// <summary>One of the functions that scripts call (after IsValidMobjType and the other three)</summary>
  TScriptMobjInfoFunction = record
    Declaration: string;
    Shape: TScriptMobjInfoShape;
    Field: TScriptMobjInfoField;
    Games: TScriptGameSet;
  end;

const
  /// <summary>The fields of mobjinfo, in the order of the enum</summary>
  SCRIPT_MOBJINFO_FIELDS: array[TScriptMobjInfoField] of TScriptMobjInfoFieldInfo = (
    (Kind: mikText; Invalid: 0), // mifName
    (Kind: mikInheritance; Invalid: SCRIPT_INVALID_ID), // mifInheritsFrom
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifDoomEdNum
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifSpawnState
    (Kind: mikNumber; Invalid: 0), // mifSpawnHealth
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifSeeState
    (Kind: mikSound; Invalid: 0), // mifSeeSound
    (Kind: mikNumber; Invalid: 0), // mifReactionTime
    (Kind: mikSound; Invalid: 0), // mifAttackSound
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifPainState
    (Kind: mikNumber; Invalid: 0), // mifPainChance
    (Kind: mikSound; Invalid: 0), // mifPainSound
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifMeleeState
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifMissileState
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifDeathState
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifXdeathState
    (Kind: mikSound; Invalid: 0), // mifDeathSound
    (Kind: mikNumber; Invalid: 0), // mifSpeed
    (Kind: mikNumber; Invalid: 0), // mifVSpeed
    (Kind: mikNumber; Invalid: 0), // mifMinMissileChance
    (Kind: mikNumber; Invalid: 0), // mifPushFactor
    (Kind: mikNumber; Invalid: 0), // mifScale
    (Kind: mikNumber; Invalid: 0), // mifGravity
    (Kind: mikNumber; Invalid: 0), // mifRadius
    (Kind: mikNumber; Invalid: 0), // mifHeight
    (Kind: mikNumber; Invalid: 0), // mifMass
    (Kind: mikNumber; Invalid: 0), // mifDamage
    (Kind: mikSound; Invalid: 0), // mifActiveSound
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifRaiseState
    (Kind: mikSound; Invalid: 0), // mifCustomSound1
    (Kind: mikSound; Invalid: 0), // mifCustomSound2
    (Kind: mikSound; Invalid: 0), // mifCustomSound3
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifDropItem
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifMissiletype
    (Kind: mikNumber; Invalid: 0), // mifExplosionDamage
    (Kind: mikNumber; Invalid: 0), // mifExplosionRadius
    (Kind: mikNumber; Invalid: 0), // mifMeleeDamage
    (Kind: mikSound; Invalid: 0), // mifMeleeSound
    (Kind: mikNumber; Invalid: 0), // mifRenderStyle
    (Kind: mikNumber; Invalid: 0), // mifAlpha
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifHealState
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifCrashState
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifCrushState
    (Kind: mikNumber; Invalid: 0), // mifFloatSpeed
    (Kind: mikNumber; Invalid: 0), // mifNormalSpeed
    (Kind: mikNumber; Invalid: 0), // mifFastSpeed
    (Kind: mikText; Invalid: 0), // mifObituary
    (Kind: mikText; Invalid: 0), // mifHitObituary
    (Kind: mikNumber; Invalid: 0), // mifGender
    (Kind: mikNumber; Invalid: 0), // mifMeleeRange
    (Kind: mikNumber; Invalid: 0), // mifMaxStepHeight
    (Kind: mikNumber; Invalid: 0), // mifMaxDropOffHeight
    (Kind: mikNumber; Invalid: 0), // mifGibHealth
    (Kind: mikNumber; Invalid: 0), // mifMaxTargetRange
    (Kind: mikNumber; Invalid: 0), // mifWeaveIndexXY
    (Kind: mikNumber; Invalid: 0), // mifWeaveIndexZ
    (Kind: mikNumber; Invalid: 0), // mifFriction
    (Kind: mikNumber; Invalid: 0), // mifSpriteDX
    (Kind: mikNumber; Invalid: 0), // mifSpriteDY
    (Kind: mikNumber; Invalid: SCRIPT_INVALID_ID), // mifInteractState
    (Kind: mikNumber; Invalid: 0), // mifInfightingGroup
    (Kind: mikNumber; Invalid: 0), // mifProjectileGroup
    (Kind: mikNumber; Invalid: 0), // mifSplashGroup
    (Kind: mikSound; Invalid: 0), // mifRipSound
    (Kind: mikNumber; Invalid: 0), // mifMissileHeight
    (Kind: mikNumber; Invalid: 0) // mifMeleeThreshold
  );

  /// <summary>The functions of the unit PS_GAME that read mobjinfo, in the order scripts have always seen them</summary>
  SCRIPT_MOBJINFO_FUNCTIONS: array[0..66] of TScriptMobjInfoFunction = (
    (Declaration: 'function GetMobjInfoName(const typ: integer): string;'; Shape: msField; Field: mifName; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoName2(const typ: integer): string;'; Shape: msField; Field: mifName; Games: [sgStrife]),
    (Declaration: 'function GetMobjInfoInheritsFrom(const typ: integer): integer;'; Shape: msField; Field: mifInheritsFrom; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoDoomEdNum(const typ: integer): integer;'; Shape: msField; Field: mifDoomEdNum; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSpawnState(const typ: integer): integer;'; Shape: msField; Field: mifSpawnState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSpawnHealth(const typ: integer): integer;'; Shape: msField; Field: mifSpawnHealth; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSeeState(const typ: integer): integer;'; Shape: msField; Field: mifSeeState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSeeSound(const typ: integer): string;'; Shape: msField; Field: mifSeeSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoReactionTime(const typ: integer): integer;'; Shape: msField; Field: mifReactionTime; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoAttackSound(const typ: integer): string;'; Shape: msField; Field: mifAttackSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoPainState(const typ: integer): integer;'; Shape: msField; Field: mifPainState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoPainChance(const typ: integer): integer;'; Shape: msField; Field: mifPainChance; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoPainSound(const typ: integer): string;'; Shape: msField; Field: mifPainSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMeleeState(const typ: integer): integer;'; Shape: msField; Field: mifMeleeState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMissileState(const typ: integer): integer;'; Shape: msField; Field: mifMissileState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoDeathState(const typ: integer): integer;'; Shape: msField; Field: mifDeathState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoXdeathState(const typ: integer): integer;'; Shape: msField; Field: mifXdeathState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoDeathSound(const typ: integer): string;'; Shape: msField; Field: mifDeathSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSpeed(const typ: integer): integer;'; Shape: msField; Field: mifSpeed; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoRadius(const typ: integer): integer;'; Shape: msField; Field: mifRadius; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoHeight(const typ: integer): integer;'; Shape: msField; Field: mifHeight; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMass(const typ: integer): integer;'; Shape: msField; Field: mifMass; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoDamage(const typ: integer): integer;'; Shape: msField; Field: mifDamage; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoActiveSound(const typ: integer): string;'; Shape: msField; Field: mifActiveSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoFlag(const typ: Integer; const flg: integer): boolean;'; Shape: msFlag; Field: mifName; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoRaiseState(const typ: integer): integer;'; Shape: msField; Field: mifRaiseState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoCustomSound1(const typ: integer): string;'; Shape: msField; Field: mifCustomSound1; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoCustomSound2(const typ: integer): string;'; Shape: msField; Field: mifCustomSound2; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoCustomSound3(const typ: integer): string;'; Shape: msField; Field: mifCustomSound3; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoDropItem(const typ: integer): integer;'; Shape: msField; Field: mifDropItem; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMissiletype(const typ: integer): integer;'; Shape: msField; Field: mifMissiletype; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoExplosionDamage(const typ: integer): integer;'; Shape: msField; Field: mifExplosionDamage; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoExplosionRadius(const typ: integer): integer;'; Shape: msField; Field: mifExplosionRadius; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMeleeDamage(const typ: integer): integer;'; Shape: msField; Field: mifMeleeDamage; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMeleeSound(const typ: integer): string;'; Shape: msField; Field: mifMeleeSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoRenderStyle(const typ: integer): integer;'; Shape: msField; Field: mifRenderStyle; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoAlpha(const typ: integer): integer;'; Shape: msField; Field: mifAlpha; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoHealState(const typ: integer): integer;'; Shape: msField; Field: mifHealState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoCrashState(const typ: integer): integer;'; Shape: msField; Field: mifCrashState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoCrushState(const typ: integer): integer;'; Shape: msField; Field: mifCrushState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoVSpeed(const typ: integer): integer;'; Shape: msField; Field: mifVSpeed; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMinMissileChance(const typ: integer): integer;'; Shape: msField; Field: mifMinMissileChance; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoPushFactor(const typ: integer): integer;'; Shape: msField; Field: mifPushFactor; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoScale(const typ: integer): integer;'; Shape: msField; Field: mifScale; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoInteractState(const typ: integer): integer;'; Shape: msField; Field: mifInteractState; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMissileHeight(const typ: integer): integer;'; Shape: msField; Field: mifMissileHeight; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoFloatSpeed(const typ: integer): integer;'; Shape: msField; Field: mifFloatSpeed; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoNormalSpeed(const typ: integer): integer;'; Shape: msField; Field: mifNormalSpeed; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoFastSpeed(const typ: integer): integer;'; Shape: msField; Field: mifFastSpeed; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoObituary(const typ: integer): string;'; Shape: msField; Field: mifObituary; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoHitObituary(const typ: integer): string;'; Shape: msField; Field: mifHitObituary; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoGender(const typ: integer): integer;'; Shape: msField; Field: mifGender; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMeleeRange(const typ: integer): integer;'; Shape: msField; Field: mifMeleeRange; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMaxStepHeight(const typ: integer): integer;'; Shape: msField; Field: mifMaxStepHeight; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMaxDropOffHeight(const typ: integer): integer;'; Shape: msField; Field: mifMaxDropOffHeight; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoGibHealth(const typ: integer): integer;'; Shape: msField; Field: mifGibHealth; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMaxTargetRange(const typ: integer): integer;'; Shape: msField; Field: mifMaxTargetRange; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoWeaveIndexXY(const typ: integer): integer;'; Shape: msField; Field: mifWeaveIndexXY; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoWeaveIndexZ(const typ: integer): integer;'; Shape: msField; Field: mifWeaveIndexZ; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoFriction(const typ: integer): integer;'; Shape: msField; Field: mifFriction; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSpriteDX(const dx: integer): integer;'; Shape: msField; Field: mifSpriteDX; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSpriteDY(const dy: integer): integer;'; Shape: msField; Field: mifSpriteDY; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoInfightingGroup(const typ: integer): Integer;'; Shape: msField; Field: mifInfightingGroup; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoProjectileGroup(const typ: integer): Integer;'; Shape: msField; Field: mifProjectileGroup; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoSplashGroup(const typ: integer): Integer;'; Shape: msField; Field: mifSplashGroup; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoRipSound(const typ: integer): string;'; Shape: msField; Field: mifRipSound; Games: [sgDoom, sgHeretic, sgHexen, sgStrife]),
    (Declaration: 'function GetMobjInfoMeleeThreshold(const typ: integer): integer;'; Shape: msField; Field: mifMeleeThreshold; Games: [sgDoom, sgHeretic, sgHexen, sgStrife])
  );

implementation

end.