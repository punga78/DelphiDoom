{******************************************************************************}
{                                                                              }
{  DelphiDoom: MUSINFO library - the types of the model                       }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MusInfo.Types;

interface

const
  /// <summary>The name of the lump with the music of the music changer actors</summary>
  MUSINFO_LUMP_NAME = 'MUSINFO';
  /// <summary>How many (map, music id) pairs the catalog keeps (the old fixed array)</summary>
  MUSINFO_MAX_ENTRIES = 1024;
  /// <summary>
  ///   The highest music id: the music changer actors are MUSICCHANGER_LO..MUSICCHANGER_HI
  ///   (14100..14164), that is 65 ids, 0..64
  /// </summary>
  MUSINFO_MAX_MUSIC_ID = 64;
  /// <summary>The longest name of a map or of a music (the names of the lumps)</summary>
  MUSINFO_NAME_LENGTH = 8;

type
  /// <summary>One line of MUSINFO: the music to play for an id on a map</summary>
  TMusInfoEntry = record
    /// <summary>Name of the map, in upper case (E1M1, MAP01)</summary>
    MapName: string;
    /// <summary>The id of the music changer, 0..MUSINFO_MAX_MUSIC_ID</summary>
    MusicId: Integer;
    /// <summary>Name of the music as written in the lump, in upper case</summary>
    MusicName: string;
    /// <summary>The number the game gives to the music: given by the catalog, not by the parser</summary>
    MusicNumber: Integer;
  end;

implementation

end.
