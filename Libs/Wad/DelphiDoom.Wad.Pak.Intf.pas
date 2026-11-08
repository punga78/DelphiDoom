{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - contract of the PAK file system                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Pak.Intf;

interface

uses
  DelphiDoom.Wad.Pak.Types;

type
  /// <summary>
  ///   The files of the PAK file system (the entries of PAK, PK3, WAD2/3 and the WAD lumps named by
  ///   PK3ENTRY, HI_START and TX_START) with the rules of the engine to find them by name. The
  ///   names are compared as the old TPakManager did: upper case ASCII, '\' as folder separator,
  ///   the short name through a hash table of PAK_HASH_SIZE chains; the last entry added wins
  /// </summary>
  IPakIndex = interface
    ['{7B0C35E2-94A1-4C3D-8F52-1D6E0A9B4C71}']
    /// <summary>
    ///   Adds the entry AEntry (ASize bytes) of the container number ASource, named AContainer:
    ///   AName becomes upper case with '\' and is cut at 255 characters, its short name at 64
    /// </summary>
    procedure Add(const AName, AContainer: string; ASource, AEntry, ASize: Integer);
    function Count: Integer;
    /// <summary>Raises EWadException when AIndex is not an entry</summary>
    function Entry(AIndex: Integer): TPakIndexEntry;
    /// <summary>The last entry whose path is AName (in any case); -1 if none</summary>
    function FindFull(const AName: string): Integer;
    /// <summary>The last entry whose short name is the one of AName; -1 if none</summary>
    function FindShort(const AName: string): Integer;
    /// <summary>
    ///   The last entry named as the short name of AName, alone or after a folder (the folders of
    ///   AName are not compared, as in the old code); -1 if none
    /// </summary>
    function FindWithDirectory(const AName: string): Integer;
    /// <summary>
    ///   Among the entries with the short name of AName: first one that is right inside a
    ///   preferred folder (in the order of APreferred), then one whose path contains it, then
    ///   any; the last added wins a tie. -1 if none
    /// </summary>
    function FindPreferred(const AName: string; const APreferred: TArray<string>): Integer;
    /// <summary>
    ///   The other rule of the old serial search: the first preferred folder that the path
    ///   contains, then any; -1 if none
    /// </summary>
    function FindPreferredSerial(const AName: string; const APreferred: TArray<string>): Integer;
    /// <summary>Every entry with the short name of AName, from the first added</summary>
    function Matching(const AName: string): TArray<Integer>;
    /// <summary>
    ///   The hash of all the entries added, byte by byte on their old image (TPakEntryImage):
    ///   the cache files of the PK3 textures carry it in their names
    /// </summary>
    function GlobalHash: Cardinal;
  end;

  /// <summary>
  ///   The rules of TPakStream to open a name: a file on disk wins over the PAK file system,
  ///   then the mode, then the folder given apart
  /// </summary>
  IPakPathResolver = interface
    ['{2E86F4A9-5D17-4B60-A3C8-90F2B6D17E45}']
    /// <summary>
    ///   Tries the disk and the entries of the index in the order of the old code: ADisk opens a
    ///   path on disk, AEntry an entry of the index. True when one of them answered True
    /// </summary>
    function Resolve(const AName: string; AMode: TPakLookupMode; const APreferred: TArray<string>;
      const ADirectory: string; const ADisk: TPakDiskOpener; const AEntry: TPakEntryOpener): Boolean;
  end;

implementation

end.
