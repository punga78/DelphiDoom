{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - what the mobjinfo functions of the scripts ask    }
{  of the engine                                                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  IScriptMobjInfoSource is the only door to mobjinfo[]: the library checks    }
{  the type numbers and builds what scripts see for a type that is not there,  }
{  the engine answers with the raw data.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.MobjInfo.Intf;

interface

uses
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>The fields of a mobjinfo that scripts can read (one for each GetMobjInfo* function)</summary>
  TScriptMobjInfoField = (
    mifName, mifInheritsFrom, mifDoomEdNum, mifSpawnState, mifSpawnHealth, mifSeeState,
    mifSeeSound, mifReactionTime, mifAttackSound, mifPainState, mifPainChance, mifPainSound,
    mifMeleeState, mifMissileState, mifDeathState, mifXdeathState, mifDeathSound, mifSpeed,
    mifVSpeed, mifMinMissileChance, mifPushFactor, mifScale, mifGravity, mifRadius, mifHeight,
    mifMass, mifDamage, mifActiveSound, mifRaiseState, mifCustomSound1, mifCustomSound2,
    mifCustomSound3, mifDropItem, mifMissiletype, mifExplosionDamage, mifExplosionRadius,
    mifMeleeDamage, mifMeleeSound, mifRenderStyle, mifAlpha, mifHealState, mifCrashState,
    mifCrushState, mifFloatSpeed, mifNormalSpeed, mifFastSpeed, mifObituary, mifHitObituary,
    mifGender, mifMeleeRange, mifMaxStepHeight, mifMaxDropOffHeight, mifGibHealth,
    mifMaxTargetRange, mifWeaveIndexXY, mifWeaveIndexZ, mifFriction, mifSpriteDX, mifSpriteDY,
    mifInteractState, mifInfightingGroup, mifProjectileGroup, mifSplashGroup, mifRipSound,
    mifMissileHeight, mifMeleeThreshold
  );

  /// <summary>How the value of a field reaches a script</summary>
  TScriptMobjInfoKind = (
    /// <summary>A number</summary>
    mikNumber,
    /// <summary>A mobj type that is a number, but a negative one means "none" and scripts see SCRIPT_INVALID_ID</summary>
    mikInheritance,
    /// <summary>A text</summary>
    mikText,
    /// <summary>The name of a sound (the engine turns the number of the sound into its name)</summary>
    mikSound
  );

  /// <summary>What the library needs of mobjinfo[], mobjtypes (the engine knows how a field is stored)</summary>
  IScriptMobjInfoSource = interface
    ['{6D2B7E41-93A8-4C05-B1F7-0E58A9D3C426}']
    /// <summary>The number of mobj types</summary>
    function Count: Integer;
    /// <summary>A field of kind mikNumber or mikInheritance of a type that exists, as stored (an enum gives its ordinal)</summary>
    function Number(const AType: Integer; const AField: TScriptMobjInfoField): Integer;
    /// <summary>A field of kind mikText or mikSound of a type that exists (a sound by name, empty for no sound)</summary>
    function Text(const AType: Integer; const AField: TScriptMobjInfoField): string;
    /// <summary>One of the flags of a type that exists (the number is the one of the flags of the scripts)</summary>
    function Flag(const AType: Integer; const AFlag: Integer): Boolean;
    /// <summary>The mobj type of an editor number (doomednum); a number that is no type can give any value</summary>
    function TypeFromEditorNumber(const ANumber: Integer): Integer;
  end;

  /// <summary>
  ///   The mobjinfo functions of the scripts (the names are the ones of the old PS_* without the
  ///   prefix and the field: the properties of the classes of the scripts in psi_game call them)
  /// </summary>
  IScriptMobjInfo = interface(IScriptFunctionSection)
    ['{B84E19F6-2C73-4A5D-9E08-F1D6A3C57B92}']
    function IsValidMobjType(const AType: Integer): Boolean;
    function GetMobjTypeFromEditorNumber(const ANumber: Integer): Integer;
    function GetEditorNumberFromMobjType(const AType: Integer): Integer;
    function GetMobjInfoCount: Integer;
    /// <summary>A number, as the old GetMobjInfo* gave it (SCRIPT_INVALID_ID, 0... for a type that is not there)</summary>
    function GetNumber(const AField: TScriptMobjInfoField; const AType: Integer): Integer;
    /// <summary>A text or the name of a sound, empty for a type that is not there</summary>
    function GetText(const AField: TScriptMobjInfoField; const AType: Integer): string;
    function GetMobjInfoFlag(const AType: Integer; const AFlag: Integer): Boolean;
  end;

implementation

end.