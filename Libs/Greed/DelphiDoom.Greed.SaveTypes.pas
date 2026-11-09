{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the records of the saved games                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): protos_h.pas                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.SaveTypes;

interface

uses
  DelphiDoom.Greed.Types;

const
  /// <summary>MAXPLAYERS</summary>
  GREED_MAX_PLAYERS = 8;
  /// <summary>MAXINVENTORY</summary>
  GREED_MAX_INVENTORY = 13;
  /// <summary>MAXSAVEGAMES: the saved games of the menu</summary>
  GREED_MAX_SAVE_GAMES = 10;
  /// <summary>The longest name of a saved game (string[22])</summary>
  GREED_SAVE_NAME_LENGTH = 22;

type
  /// <summary>
  ///   player_t of xGreed: the saved game is this record written as it is, 20996 bytes (little endian, 32 bit
  ///   integers, no padding, no pointers: the same at 32 and 64 bit). The maps have a byte for each tile of the 64 x 64
  ///   map; SaveSprites is the state of monsters, doors and elevators as sprite types of the map
  /// </summary>
  TGreedPlayerRecord = packed record
    X: TGreedFixed;
    Y: TGreedFixed;
    Z: TGreedFixed;
    MapSpot: Integer;
    Angle: Integer;
    Height: TGreedFixed;
    CurrentWeapon: Integer;
    Shield: Integer;
    Angst: Integer;
    MaxShield: Integer;
    MaxAngst: Integer;
    Map: Integer;
    Mission: Integer;
    CharType: Integer;
    LevelScore: Integer;
    Difficulty: Integer;
    Weapons: array[0..4] of Integer;
    Ammo: array[0..2] of Integer;
    BodyCount: Integer;
    TimeCount: Integer;
    Score: Integer;
    NorthMap: packed array[0..GREED_MAP_TILES - 1] of Byte;
    WestMap: packed array[0..GREED_MAP_TILES - 1] of Byte;
    NorthWall: packed array[0..GREED_MAP_TILES - 1] of Byte;
    WestWall: packed array[0..GREED_MAP_TILES - 1] of Byte;
    SaveSprites: packed array[0..GREED_MAP_TILES - 1] of Byte;
    ScrollMin: Integer;
    ScrollMax: Integer;
    Primaries: array[0..1] of Integer;
    Secondaries: array[0..6] of Integer;
    Frags: array[0..GREED_MAX_PLAYERS - 1] of Integer;
    RunMod: Integer;
    WalkMod: Integer;
    Inventory: array[0..GREED_MAX_INVENTORY - 1] of Integer;
    Status: Integer;
    HoloPic: Integer;
    HoloScale: Integer;
    JumpMod: TGreedFixed;
    Events: packed array[0..255] of Byte;
  end;

  /// <summary>One name of a saved game: a Pascal short string of 22 characters, 23 bytes</summary>
  TGreedSaveName = string[GREED_SAVE_NAME_LENGTH];

  /// <summary>The names of the saved games of the menu (savedir), 230 bytes in the file SAVEGAME.DIR</summary>
  TGreedSaveDirectory = packed array[0..GREED_MAX_SAVE_GAMES - 1] of TGreedSaveName;

  /// <summary>
  ///   pevent_t: what a player tells the others in a net game (52 bytes). It is here because the saved games and the net
  ///   game share the player; the net game itself is not ported
  /// </summary>
  TGreedPlayerEvent = packed record
    Id: Integer;
    PlayerId: Integer;
    X: TGreedFixed;
    Y: TGreedFixed;
    Z: TGreedFixed;
    Angle: Integer;
    Angst: Integer;
    CharType: Integer;
    Status: Integer;
    HoloPic: Integer;
    HoloScale: Integer;
    Height: TGreedFixed;
    SpecialEffect: Integer;
  end;

implementation

end.
