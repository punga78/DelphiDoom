{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelData                                 }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  What RX_CreateDoomLevel read of a level of Radix before it built the map    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.Data;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Types;

type
  /// <summary>A level of Radix as the file has it (WorldData[i][j])</summary>
  TRadixLevelData = class
  public
    Name: string;
    /// <summary>CRC-32 of the bytes of the level: it says which version of the game it comes from</summary>
    Crc: Cardinal;
    Header: TRadixLevelHeader;
    Sectors: TArray<TRadixLevelSector>;
    Walls: TArray<TRadixLevelWall>;
    Things: TArray<TRadixLevelThing>;
    Actions: TArray<TRadixLevelAction>;
    Triggers: TArray<TRadixLevelTrigger>;
    PlayerStarts: packed array[0..RADIX_PLAYER_STARTS - 1] of TRadixLevelPlayerStart;
    TriggerGrid: TRadixLevelGrid;
    /// <summary>The size of the grids: 320 x 128 or 1280 x 32</summary>
    GridWidth: Integer;
    GridHeight: Integer;
  end;

implementation

end.
