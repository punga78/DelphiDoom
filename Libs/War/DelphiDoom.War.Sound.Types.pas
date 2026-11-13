{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the game plays and when: types               }
{                                                                              }
{  Port of the choices of war_audio.c, war1 (acoto87/war1), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.Types;

interface

type
  /// <summary>
  ///   What happens in the game that has a sound. The sounds of an event are the ones the original plays for it
  ///   (the table is DelphiDoom.War.Sound.Table); the race decides only the events that have a sound for each
  /// </summary>
  TWarSoundEvent = (
    wseAttackSword, wseAttackFist, wseAttackFireball, wseAttackCatapult, wseAttackArrow,
    /// <summary>A unit is selected</summary>
    wseSelected,
    /// <summary>The only unit selected is clicked again</summary>
    wseAnnoyed,
    /// <summary>A unit answers an order</summary>
    wseAcknowledgement,
    wseBuildingConstruction, wseBuildingBurning,
    /// <summary>The church of the humans, the temple of the orcs</summary>
    wseChurchOrTemple,
    /// <summary>The stable of the humans, the kennel of the orcs</summary>
    wseStableOrKennel,
    wseBlacksmith,
    /// <summary>A building that has no sound of its own is selected: the click</summary>
    wseBuildingGeneric,
    wseUnitDeath, wseSpiderOrScorpionDeath,
    /// <summary>A building falls (also a catapult that dies, a construction that is cancelled)</summary>
    wseCollapse,
    wseTreeChopping,
    /// <summary>The worker has finished a building (only the player 0 hears it)</summary>
    wseWorkComplete,
    /// <summary>A unit has been trained (only the player 0 hears it)</summary>
    wseUnitReady,
    wseVictory, wseDefeat,
    wseSpell, wseBuildRoad, wseUiClick, wseUiCancel, wseCatapultExplosion, wseArrowHit
  );

  /// <summary>WarUnitActionStepType of war_enums.h: the step of an action that makes a sound (the values are the ones of the original)</summary>
  TWarActionStep = (
    wasNone = 0, wasFrame = 1, wasWait = 2, wasAttack = 3, wasSoundSword = 4, wasSoundFist = 5, wasSoundFireball = 6,
    wasSoundChopping = 7, wasSoundCatapult = 8, wasSoundArrow = 9, wasSoundLightning = 10
  );

  /// <summary>
  ///   The sounds an event can play, as the original asks for them: First = Last is that sound, First &lt; Last is
  ///   one of them picked at random (randomi(First, Last + 1)); First = -1 is no sound
  /// </summary>
  TWarSoundChoice = record
    First: Integer;
    Last: Integer;
    function IsNone: Boolean;
    function IsRandom: Boolean;
    class function None: TWarSoundChoice; static;
    class function Fixed(ASound: Integer): TWarSoundChoice; static;
    class function Range(AFirst, ALast: Integer): TWarSoundChoice; static;
  end;

  /// <summary>What wa_playBuildingSelectionSound looks at in a building</summary>
  TWarBuildingSoundState = record
    /// <summary>It is being built, or a worker is going to build it (wst_isBuilding, wst_isGoingToBuild)</summary>
    UnderConstruction: Boolean;
    Hp: Integer;
    MaxHp: Integer;
    /// <summary>WAR_UNIT_* of the building</summary>
    UnitType: Integer;
  end;

implementation

{ TWarSoundChoice }

function TWarSoundChoice.IsNone: Boolean;
begin
  Result := First < 0;
end;

function TWarSoundChoice.IsRandom: Boolean;
begin
  Result := (First >= 0) and (Last > First);
end;

class function TWarSoundChoice.None: TWarSoundChoice;
begin
  Result.First := -1;
  Result.Last := -1;
end;

class function TWarSoundChoice.Fixed(ASound: Integer): TWarSoundChoice;
begin
  Result.First := ASound;
  Result.Last := ASound;
end;

class function TWarSoundChoice.Range(AFirst, ALast: Integer): TWarSoundChoice;
begin
  Result.First := AFirst;
  Result.Last := ALast;
end;

end.
