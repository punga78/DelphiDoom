{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the choice of the sounds: contracts               }
{                                                                              }
{  Port of the choices of war_audio.c, war1 (acoto87/war1), (c) 2019 Alejandro  }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an     }
{  altered version, not the original.                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Sound.Intf;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Types;

type
  /// <summary>
  ///   The random numbers of the game, given from outside so that a test (or a recorded game) gives the same
  ///   sounds: SDL_rand of the original
  /// </summary>
  IWarRandom = interface
    ['{5B8D2E41-7C09-4A36-9E15-D4F0A3C682B7}']
    /// <summary>A number from 0 to ALimit - 1 (SDL_rand(ALimit)); 0 if ALimit is not positive</summary>
    function Below(ALimit: Integer): Integer;
  end;

  /// <summary>What an event plays: the table of the original, as data</summary>
  IWarSoundTable = interface
    ['{E2A7C913-48B5-4D0F-81C6-3F95B0D7A214}']
    /// <summary>
    ///   The sounds of AEvent; a race other than the humans is read as the orcs (isHumanPlayer is the only test of
    ///   the original), and an event that has one sound for both ignores it
    /// </summary>
    function Choice(AEvent: TWarSoundEvent; ARace: TWarRace): TWarSoundChoice;
    /// <summary>
    ///   Every range of two or more sounds the table has (what randomFromId / randomToId of the original are):
    ///   each one once, in the order of the events
    /// </summary>
    function RandomRanges: TArray<TWarSoundChoice>;
  end;

  /// <summary>
  ///   The functions wa_play* of the original that choose the sound, with the random number given from outside.
  ///   Each one returns the record of the sound, or WAR_SND_NONE if nothing is played
  /// </summary>
  IWarSoundPicker = interface
    ['{91C4F6A8-0D2E-4B73-A5E9-7821B3C0D456}']
    /// <summary>The sound of an event (a random one if the choice has a range)</summary>
    function Pick(AEvent: TWarSoundEvent; ARace: TWarRace): Integer;
    /// <summary>wa_playAttackSound: a step that is not a sound of attack plays nothing</summary>
    function AttackSound(AStep: TWarActionStep): Integer;
    /// <summary>
    ///   wa_playDudeSelectionSound: the unit that is the only one selected and is selected again annoys, else the
    ///   unit answers the selection
    /// </summary>
    function DudeSelectionSound(ARace: TWarRace; AIsTheOnlySelected: Boolean): Integer;
    /// <summary>wa_playBuildingSelectionSound</summary>
    function BuildingSelectionSound(const ABuilding: TWarBuildingSoundState): Integer;
    /// <summary>The sound of a unit that dies (war_entities.c): a spider or a scorpion, a catapult, anything else</summary>
    function DeathSound(AUnitType: Integer; ARace: TWarRace): Integer;
    /// <summary>The briefing of a mission, 1 to 12 (data.briefingAudioId); WAR_SND_NONE outside</summary>
    function BriefingSound(ARace: TWarRace; AMission: Integer): Integer;
  end;

implementation

end.
