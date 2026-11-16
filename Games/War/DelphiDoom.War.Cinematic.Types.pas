{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the animations of the game: types                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Cinematic.Types;

interface

uses
  DelphiDoom.War.Level.Types, DelphiDoom.War.Sound.Types;

type
  /// <summary>How the sound of an animation is chosen</summary>
  TWarCinematicSoundKind = (
    /// <summary>No sound</summary>
    wcsNone,
    /// <summary>The sound of one record of DATA.WAR</summary>
    wcsFixed,
    /// <summary>The sound of an event of the game (the victory of the player's race)</summary>
    wcsEvent
  );

  /// <summary>One animation of the game (the files DATA\NAME.WAR) and the sound that goes with it</summary>
  TWarCinematicEntry = record
    Name: string;
    /// <summary>The animation is a loop that holds the screen (the fires of a gate, the flags): it plays until it is skipped</summary>
    Looping: Boolean;
    SoundKind: TWarCinematicSoundKind;
    /// <summary>The record of DATA.WAR when SoundKind is wcsFixed</summary>
    Sound: Integer;
    /// <summary>The event when SoundKind is wcsEvent</summary>
    SoundEvent: TWarSoundEvent;
    /// <summary>
    ///   The race of an event sound; wraNeutral means the race of the player (WIN and LOSE have one file for both
    ///   races, the voice is the one of the player)
    /// </summary>
    SoundRace: TWarRace;
  end;

implementation

end.
