{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the types of a saved game                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Save.Types;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types;

type
  /// <summary>The saved game is not usable (not a saved game, damaged, of another version or of other data)</summary>
  EWarSaveException = class(Exception);

  /// <summary>
  ///   The first bytes of a saved game. The game is saved as what makes it: how the program started (the seed of the
  ///   generator of random numbers and the mission asked for with -play) and, frame after frame, the time that passed
  ///   and what the player did with the mouse and the keyboard. The model of the game is deterministic, so loading
  ///   is playing the same frames again. No pointers, no strings: the same bytes at 32 and 64 bit
  /// </summary>
  TWarSaveHeader = packed record
    Magic: array[0..7] of AnsiChar;
    /// <summary>The layout of this file (WAR_SAVE_FORMAT_VERSION)</summary>
    FormatVersion: Word;
    /// <summary>The version of the rules the frames were played with (WAR_SAVE_MODEL_VERSION)</summary>
    ModelVersion: Word;
    Seed: Cardinal;
    /// <summary>The size of the DATA.WAR the game was played with: another file cannot play the same game</summary>
    DataSize: Cardinal;
    /// <summary>The mission asked for with -play: the race (1 humans, 2 orcs) or 0 for the title</summary>
    StartRace: Byte;
    StartMission: Byte;
    /// <summary>
    ///   Bit 0 (WAR_SAVE_FLAG_INTRODUCTION): the game went from the logo to the introduction. A file made before this
    ///   field had a meaning has 0 here, and that is the game it played (the logo, then the menu)
    /// </summary>
    Flags: Word;
    FrameCount: Cardinal;
    EventCount: Cardinal;
  end;

  /// <summary>What comes before the events of a frame</summary>
  TWarSaveFrameHeader = packed record
    /// <summary>The time of the frame in seconds, as the game was given it</summary>
    Delta: Single;
    EventCount: Word;
  end;

  /// <summary>An input event of the window as it is written in the file</summary>
  TWarSaveEventRecord = packed record
    Kind: Byte;
    /// <summary>Bits 0..2 the modifiers (shift, control, alt), 3..4 the mouse button, 5 focused, 6 minimized</summary>
    Flags: Byte;
    VirtualKey: Word;
    Character: Cardinal;
    X: SmallInt;
    Y: SmallInt;
  end;

  /// <summary>A frame in memory: the time and the events that came before it</summary>
  TWarSaveFrame = record
    Delta: Single;
    Events: TArray<TGameHostEvent>;
  end;

  /// <summary>A saved game in memory</summary>
  TWarSaveContent = record
    Seed: Cardinal;
    DataSize: Cardinal;
    StartRace: Byte;
    StartMission: Byte;
    /// <summary>The game started with the introduction after the logo (the flag of the header)</summary>
    Introduction: Boolean;
    Frames: TArray<TWarSaveFrame>;
  end;

const
  /// <summary>The first eight bytes of a saved game</summary>
  WAR_SAVE_MAGIC: array[0..7] of AnsiChar = ('W', 'A', 'R', '1', 'S', 'A', 'V', #26);
  /// <summary>The layout of the file; it changes when this unit changes</summary>
  WAR_SAVE_FORMAT_VERSION = 1;
  /// <summary>
  ///   It changes when the rules of the game change in a way that makes an old game play differently. 2: a sound that has a
  ///   place on the map makes no entity when the fog of war hides the place (wa_createAudioWithPosition), so the ids of
  ///   the entities that come after are not the ones of version 1
  /// </summary>
  WAR_SAVE_MODEL_VERSION = 2;
  /// <summary>The bit of TWarSaveHeader.Flags that says the game played the introduction after the logo</summary>
  WAR_SAVE_FLAG_INTRODUCTION = 1;
  /// <summary>The most events one frame can hold</summary>
  WAR_SAVE_MAX_EVENTS_PER_FRAME = 4096;

implementation

end.
