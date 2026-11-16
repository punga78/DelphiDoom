{******************************************************************************}
{                                                                              }
{  DelphiDoom: zone library - shared types                                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Zone.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Static for the whole execution of the program</summary>
  ZONE_TAG_STATIC = 1;
  /// <summary>Static while a sound is playing</summary>
  ZONE_TAG_SOUND = 2;
  /// <summary>Static while a song is playing</summary>
  ZONE_TAG_MUSIC = 3;
  /// <summary>Anything else that has to stay</summary>
  ZONE_TAG_DAVE = 4;
  /// <summary>Static until the level is left</summary>
  ZONE_TAG_LEVEL = 50;
  /// <summary>A special thinker in a level</summary>
  ZONE_TAG_LEVSPEC = 51;
  /// <summary>From this tag up a block can be thrown away whenever needed</summary>
  ZONE_TAG_PURGELEVEL = 100;
  /// <summary>The cache</summary>
  ZONE_TAG_CACHE = 101;

type
  /// <summary>Raised when the zone is used in a wrong way or found damaged</summary>
  EZoneException = class(Exception);

  /// <summary>What the zone holds, for the commands that tell how the memory is used</summary>
  TZoneStatistics = record
    /// <summary>Number of blocks</summary>
    BlockCount: Integer;
    /// <summary>Bytes asked for by the callers, headers excluded</summary>
    UserBytes: Int64;
    /// <summary>Bytes taken from the memory source, headers included</summary>
    TotalBytes: Int64;
    /// <summary>Bytes (headers included) of the blocks with a purgable tag</summary>
    PurgableBytes: Int64;
  end;

implementation

end.
