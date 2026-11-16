{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - types of the specials of the sectors              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  What the scripts can ask of doors, ceilings, floors, lights, platforms,     }
{  pillars and polyobjects (the PS_Door_*, PS_Ceiling_*, ... of psi_map.pas):  }
{  the kind of each special and the 8 bytes of arguments that the specials of  }
{  the map take. The kinds are the ones of the engine, by name: the gateway    }
{  of the engine turns them into its own constants.                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Types;

interface

type
  /// <summary>The arguments of a special of a line, as the engine reads them (8 bytes)</summary>
  TScriptSpecialArguments = array[0..7] of Byte;

  /// <summary>The kinds of ceiling that a script can start (the CLEV_* of the engine)</summary>
  TScriptCeilingKind = (
    sckCrushAndRaise,
    sckCrushRaiseAndStay,
    sckLowerAndCrush,
    sckLowerByValue,
    sckLowerByValueTimes8,
    sckLowerToFloor,
    sckLowerToMaxFloor,
    sckLowerToLowest,
    sckMoveToValueAndCrush,
    sckMoveToValue,
    sckMoveToValueTimes8,
    sckRaiseByValue,
    sckRaiseByValueTimes8,
    sckRaiseToHighestFloor,
    sckRaiseToHighest
  );

  /// <summary>The kinds of door (the DREV_* of the engine)</summary>
  TScriptDoorKind = (
    sdkClose,
    sdkCloseWaitThenOpen,
    sdkOpen,
    sdkNormal
  );

  /// <summary>The kinds of floor (the FLEV_* of the engine)</summary>
  TScriptFloorKind = (
    sfkLowerFloorByValue,
    sfkLowerByValueTimes8,
    sfkLowerFloorToHighest,
    sfkLowerFloorToLowestCeiling,
    sfkLowerFloorToLowest,
    sfkLowerFloor,
    sfkMoveToValue,
    sfkMoveToValueTimes8,
    sfkRaiseFloorCrushDoom,
    sfkRaiseFloorCrush,
    sfkRaiseToTexture,
    sfkRaiseFloorByValue,
    sfkRaiseFloorByValueTimes8,
    sfkRaiseTimes8Instant,
    sfkLowerTimes8Instant,
    sfkRaiseToCeiling,
    sfkRaiseFloor,
    sfkRaiseToLowestCeiling,
    sfkRaiseFloorToNearest,
    sfkFloorToCeilingInstant
  );

  /// <summary>The kinds of light (the LITE_* of the engine)</summary>
  TScriptLightKind = (
    slkChangeToValue,
    slkFade,
    slkFlicker,
    slkGlow,
    slkLowerByValue,
    slkMaxNeighbor,
    slkMinNeighbor,
    slkRaiseByValue,
    slkStrobe,
    slkStrobeDoom
  );

  /// <summary>The kinds of platform (the PLAT_* of the engine)</summary>
  TScriptPlatKind = (
    spkDownByValueWaitUpStay,
    spkDownWaitUpStay,
    spkDownWaitUpStayLip,
    spkPerpetualRaise,
    spkPerpetualRaiseLip,
    spkUpByValueWaitDownStay,
    spkUpNearestWaitDownStay,
    spkUpWaitDownStay
  );

  /// <summary>The kinds of door of a polyobject (the PODOOR_* of the engine)</summary>
  TScriptPolyDoorKind = (
    spdSlide,
    spdSwing
  );

implementation

end.
