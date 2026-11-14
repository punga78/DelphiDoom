{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - the state of Radix in a saved game              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SaveGame.Types;

interface

uses
  DelphiDoom.Radix.Level.Types;

type
  TRadixSaveMagic = array[0..7] of AnsiChar;

const
  RADIX_SAVE_MAGIC: TRadixSaveMagic = 'RADIXSAV';
  /// <summary>The version of the format that is written; the only one that is read</summary>
  RADIX_SAVE_VERSION = 1;
  RADIX_SAVE_POWERUPS = 5;
  RADIX_SAVE_WEAPONS = 9;
  RADIX_SAVE_MESSAGES = 13;
  RADIX_SAVE_RANDOM_INDEXES = 4;

type
  TRadixSaveRandomIndexes = array[0..RADIX_SAVE_RANDOM_INDEXES - 1] of Integer;

  /// <summary>
  ///   The start of the file that stands beside a saved game of the engine. All the records of the
  ///   file are packed, have no pointers and have the same size in a program of 32 and of 64 bits;
  ///   the numbers are little endian. After the header: Players records TRadixSavePlayer, Players
  ///   records TRadixSaveLevelPlayer, Players last triggers (Integer), Actions records
  ///   TRadixLevelAction, Triggers records TRadixLevelTrigger, Walls records TRadixSaveWall, Shots
  ///   records TRadixSaveShot
  /// </summary>
  TRadixSaveHeader = packed record
    Magic: TRadixSaveMagic;
    Version: Integer;
    /// <summary>The level of the saved game: a file of another level is not read</summary>
    Episode: Integer;
    Map: Integer;
    Players: Integer;
    Actions: Integer;
    Triggers: Integer;
    Walls: Integer;
    Shots: Integer;
    /// <summary>The level that the action that ended this one named; 0 for none</summary>
    NamedLevel: Integer;
    /// <summary>
    ///   Where the random numbers of the game were (menu, play, not compatible, system): the saved
    ///   game of the engine does not keep them, and the actions of a level of Radix draw at every tic
    /// </summary>
    RandomIndexes: TRadixSaveRandomIndexes;
  end;

  /// <summary>
  ///   What the craft of a pilot has more than the marine of Doom (radixplayer_t). The target of
  ///   the crosshair is not kept: the game finds it again at the next tic
  /// </summary>
  TRadixSavePlayer = packed record
    Energy: Integer;
    EnergyReserve: Integer;
    Threat: Byte;
    ScannerJam: Byte;
    PlasmaBombDown: Byte;
    Afterburner: Byte;
    PlasmaEnergyCountdown: Integer;
    EnergyWeaponFireTics: Integer;
    ThrustMomZ: Integer;
    Powers: array[0..RADIX_SAVE_POWERUPS - 1] of Integer;
    PlasmaBombs: Integer;
    NeutronCannonLevel: Integer;
    NeutronSpreaderLevel: Integer;
    WeaponFlags: Cardinal;
    LastBonusTime: Integer;
    GravityWave: Integer;
    CrossTic: Integer;
    LastFire: array[0..RADIX_SAVE_WEAPONS - 1] of Integer;
    PlasmaBombCount: Integer;
    FloorSlideTics: Integer;
  end;

  /// <summary>
  ///   What the actions of a level keep for a player (radixlevelplayer_t). The body is not a
  ///   pointer here: HasBody says that the player had one, and the game gives it the body of the
  ///   player that the engine has loaded
  /// </summary>
  TRadixSaveLevelPlayer = packed record
    HasBody: Byte;
    SecondaryObjective: Byte;
    Reserved: Word;
    MessageTime: array[0..RADIX_SAVE_MESSAGES - 1] of Integer;
    TranspoStartX: Integer;
    TranspoStartY: Integer;
    TranspoStartZ: Integer;
    TranspoStartAngle: Cardinal;
    TranspoTargetX: Integer;
    TranspoTargetY: Integer;
    TranspoTargetZ: Integer;
    TranspoTargetAngle: Cardinal;
    TranspoStartTics: Integer;
    TranspoTics: Integer;
  end;

  /// <summary>What changes of a wall while the level is played (radixwallinfo)</summary>
  TRadixSaveWall = packed record
    Flags: Integer;
    HitPoints: Integer;
    Trigger: Integer;
  end;

  /// <summary>
  ///   A shot of a player that was flying at the last tic. The shot is named by the key that the
  ///   engine gives to every thing when it is born (and saves with it), never by its address
  /// </summary>
  TRadixSaveShot = packed record
    Key: Cardinal;
    X: Integer;
    Y: Integer;
    OldX: Integer;
    OldY: Integer;
    MomX: Integer;
    MomY: Integer;
  end;

  /// <summary>The state of Radix of a level that is being played, as the game gives and takes it</summary>
  TRadixSaveState = record
    Episode: Integer;
    Map: Integer;
    NamedLevel: Integer;
    RandomIndexes: TRadixSaveRandomIndexes;
    Players: TArray<TRadixSavePlayer>;
    LevelPlayers: TArray<TRadixSaveLevelPlayer>;
    /// <summary>The last trigger that each craft touched</summary>
    LastTriggers: TArray<Integer>;
    Actions: TArray<TRadixLevelAction>;
    Triggers: TArray<TRadixLevelTrigger>;
    Walls: TArray<TRadixSaveWall>;
    Shots: TArray<TRadixSaveShot>;
  end;

  /// <summary>A fingerprint of each part of a state, to tell in a log which part two states differ in</summary>
  TRadixSaveFingerprints = record
    Players: Cardinal;
    /// <summary>The level parts of the players and their last triggers</summary>
    LevelPlayers: Cardinal;
    Actions: Cardinal;
    Triggers: Cardinal;
    Walls: Cardinal;
    Shots: Cardinal;
  end;

implementation

end.
