{******************************************************************************}
{                                                                              }
{  DelphiDoom: demo library - shared types of the demo format                  }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Demo.Types;

interface

const
  /// <summary>The byte that ends the stream of the commands of a demo</summary>
  DEMO_MARKER = $80;

  /// <summary>The most players a demo header can list (Hexen has the most: 8)</summary>
  DEMO_MAX_PLAYERS = 8;

  /// <summary>The bit of the buttons byte that marks a special command; it never goes in a demo</summary>
  DEMO_BUTTON_SPECIAL = 128;

type
  /// <summary>
  ///   The layout of the commands in a demo: Hexen has the one of Heretic, the other games have their own
  /// </summary>
  TDemoLayout = (dlDoom, dlHeretic, dlStrife);

  /// <summary>
  ///   What differs from game to game in the header of a demo (the old code had four copies of it)
  /// </summary>
  TDemoHeaderProfile = record
    /// <summary>The four bytes the file starts with ('DEMO', 'HDEM', 'XDEM')</summary>
    Magic: Cardinal;
    /// <summary>The header has the episode (Strife has no episodes)</summary>
    HasEpisode: Boolean;
    /// <summary>The header has the two bytes of the dogs (Doom only)</summary>
    HasDogs: Boolean;
    /// <summary>The first version that has the dogs</summary>
    DogsMinVersion: Integer;
    /// <summary>The first version that has the byte of spawnrandommonsters (0: all of them)</summary>
    SpawnRandomMinVersion: Integer;
    /// <summary>The first version that has the byte of the random seed (0: all of them)</summary>
    SeedMinVersion: Integer;
    /// <summary>How many players the game has: the header lists as many bytes</summary>
    PlayerCount: Integer;
  end;

  /// <summary>
  ///   The fields of a demo header, as numbers of the file, with no relation to the globals of the engine
  /// </summary>
  TDemoHeader = record
    Version: Byte;
    Skill: Byte;
    Episode: Byte;
    Map: Byte;
    Deathmatch: Byte;
    Respawn: Boolean;
    Fast: Boolean;
    NoMonsters: Boolean;
    Compatibility: Boolean;
    SpawnRandomMonsters: Boolean;
    /// <summary>The header has the byte of the random seed</summary>
    HasSeed: Boolean;
    Seed: Byte;
    Dogs: Byte;
    DogJumping: Byte;
    ConsolePlayer: Byte;
    PlayersInGame: array[0..DEMO_MAX_PLAYERS - 1] of Boolean;
  end;

  /// <summary>
  ///   One command of a demo (what <c>ticcmd_t</c> keeps of it); the fields of a layout that
  ///   another layout does not have are zero
  /// </summary>
  TDemoCommand = record
    ForwardMove: ShortInt;
    SideMove: ShortInt;
    AngleTurn: SmallInt;
    Buttons: Byte;
    Buttons2: Byte;
    Inventory: Integer;
    LookFly: Byte;
    Arti: Byte;
    LookUpDown: Byte;
    LookUpDown16: Word;
    LookLeftRight: Byte;
    JumpCrouch: Byte;
  end;

implementation

end.
