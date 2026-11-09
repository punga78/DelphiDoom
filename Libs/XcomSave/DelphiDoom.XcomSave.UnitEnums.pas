{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the enumerations of a battle unit     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.UnitEnums;

interface

const
  // UnitStatus (BattleUnit.h)
  XcomStatusStanding = 0;
  XcomStatusWalking = 1;
  XcomStatusFlying = 2;
  XcomStatusTurning = 3;
  XcomStatusAiming = 4;
  XcomStatusCollapsing = 5;
  XcomStatusDead = 6;
  XcomStatusUnconscious = 7;
  XcomStatusPanicking = 8;
  XcomStatusBerserk = 9;
  XcomStatusIgnoreMe = 10;

  // UnitFaction
  XcomFactionPlayer = 0;
  XcomFactionHostile = 1;
  XcomFactionNeutral = 2;

  // UnitSide
  XcomSideFront = 0;
  XcomSideLeft = 1;
  XcomSideRight = 2;
  XcomSideRear = 3;
  XcomSideUnder = 4;

  // UnitBodyPart
  XcomBodyPartHead = 0;
  XcomBodyPartTorso = 1;
  XcomBodyPartRightArm = 2;
  XcomBodyPartLeftArm = 3;
  XcomBodyPartRightLeg = 4;
  XcomBodyPartLeftLeg = 5;

implementation

end.
