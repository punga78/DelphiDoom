{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - types of the PAK file system                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Pak.Types;

interface

{$SCOPEDENUMS ON}

const
  /// <summary>Number of the chains of the hash table of the short names (the old PAKHASHSIZE)</summary>
  PAK_HASH_SIZE = 8192;
  /// <summary>Folder of the files that HI_START/HI_END and TX_START/TX_END of a WAD become</summary>
  PAK_TEXTURE_PATH = 'TEXTURES\';

type
  /// <summary>
  ///   How a name is looked for (pakmode_t of the engine): the full path, the name of the file only,
  ///   the name of the file in the preferred folders first, or a folder that is given apart
  /// </summary>
  TPakLookupMode = (Full, Short, Preferred, Directory);

  /// <summary>One file of the PAK file system, as the index keeps it</summary>
  TPakIndexEntry = record
    /// <summary>The upper case name of the file that holds the entry</summary>
    Container: string;
    /// <summary>Upper case path with '\' (at most 255 characters, as the old ShortString)</summary>
    Name: string;
    /// <summary>The name after the last folder (at most 64 characters)</summary>
    ShortName: string;
    /// <summary>The number of the container, as the caller gave it</summary>
    Source: Integer;
    /// <summary>The number of the entry in its container</summary>
    Entry: Integer;
    Size: Integer;
    /// <summary>The hash of the short name (TPakNames.Hash)</summary>
    Hash: Integer;
  end;

  /// <summary>
  ///   The image of an entry of the old TPakManager that its global hash read byte by byte: the
  ///   strings are ShortString, zero filled after their end. It is not packed: there are 3 bytes
  ///   of padding (zero) before Offset, and the hash covers SizeOf(TPakEntryImage) = 588 bytes
  /// </summary>
  TPakEntryImage = record
    Pak: string[255];
    Name: string[255];
    ShortName: string[64];
    Offset: Integer;
    Size: Integer;
  end;

  /// <summary>Opens the file APath on disk; True when it could be opened</summary>
  TPakDiskOpener = reference to function(const APath: string): Boolean;
  /// <summary>Opens the entry number AIndex of the index; True when its bytes could be read</summary>
  TPakEntryOpener = reference to function(AIndex: Integer): Boolean;

implementation

end.
