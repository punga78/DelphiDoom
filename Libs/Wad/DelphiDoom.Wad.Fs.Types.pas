{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: shared types            }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): types and         }
{  constants of framework\FileSystem.cpp and FileSystem.h. Copyright (C)       }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>BASE_GAMEDIR of Licensee.h: the game folder that is always searched</summary>
  GAMEFS_BASE_GAMEDIR = 'base';
  /// <summary>FILE_HASH_SIZE: the buckets of the name hash of a pak</summary>
  GAMEFS_FILE_HASH_SIZE = 1024;
  /// <summary>ADDON_CONFIG: the file that makes a pak an addon</summary>
  GAMEFS_ADDON_CONFIG = 'addon.conf';
  /// <summary>The extension of the paks (the files that startup looks for in a game folder)</summary>
  GAMEFS_PAK_EXTENSION = '.pk4';

type
  /// <summary>Anything wrong with the file system, or a call before Startup (the FatalError of the original)</summary>
  EGameFsException = class(Exception);

  /// <summary>
  ///   The cvars of the file system that decide the search paths (fs_cdpath, fs_basepath, fs_devpath,
  ///   fs_savepath, fs_game_base, fs_game, fs_searchAddons). An empty string means "not set"
  /// </summary>
  TGameFsSettings = record
    CdPath: string;
    BasePath: string;
    DevPath: string;
    SavePath: string;
    GameBase: string;
    Game: string;
    /// <summary>fs_searchAddons: the addon paks stay in the search list (the original disables the addon functionality)</summary>
    SearchAddons: Boolean;
    /// <summary>
    ///   addonChecksums: the addon paks (by checksum) to put in the search list together with the paks they
    ///   depend on; used when <c>SearchAddons</c> is False (the original sets it for a restart with addons)
    /// </summary>
    AddonChecksums: TArray<Cardinal>;
    /// <summary>
    ///   The extension of the paks a game folder is searched for, with the dot ('.pk3' for Quake III, whose paks
    ///   are the same ZIP as a PK4); empty means <c>GAMEFS_PAK_EXTENSION</c>
    /// </summary>
    PakExtension: string;
  end;

  /// <summary>One mapDef of an addon.conf: the keys and values in the order they were set, the first key is "path"</summary>
  TGameAddonMapDef = record
    Keys: TArray<string>;
    Values: TArray<string>;
  end;

  /// <summary>addonInfo_t: what an addon.conf says (the pak checksums it depends on and its map declarations)</summary>
  TGameAddonInfo = record
    Depends: TArray<Cardinal>;
    MapDefs: TArray<TGameAddonMapDef>;
  end;

  /// <summary>idModList: the game folders that hold paks and their descriptions; the first entry is the base game</summary>
  TGameModList = record
    Mods: TArray<string>;
    Descriptions: TArray<string>;
  end;

  /// <summary>pureStatus_t of a pak</summary>
  TGamePureStatus = (
    /// <summary>PURE_UNKNOWN: not examined yet</summary>
    Unknown,
    /// <summary>PURE_NEUTRAL: in the pure list only when it was referenced</summary>
    Neutral,
    /// <summary>PURE_ALWAYS: a pak* file that has files a pure server cares about</summary>
    Always,
    /// <summary>PURE_NEVER: only files that never count (guis, languages, voice over, fonts...)</summary>
    Never);

  /// <summary>fsPureReply_t (without PURE_NODLL: the game code pak is not ported)</summary>
  TGamePureReply = (
    /// <summary>PURE_OK: the pure list is the one of the server</summary>
    Ok,
    /// <summary>PURE_RESTART: a restart in pure mode is needed</summary>
    Restart,
    /// <summary>PURE_MISSING: some paks the server uses are not installed</summary>
    Missing);

  /// <summary>Where a file is written: the cvar the original reads the base folder from (fs_savepath if it is empty)</summary>
  TGameWriteBase = (
    /// <summary>fs_savepath</summary>
    SavePath,
    /// <summary>fs_devpath</summary>
    DevPath,
    /// <summary>fs_basepath</summary>
    BasePath,
    /// <summary>fs_cdpath</summary>
    CdPath);

  /// <summary>The FSFLAG_* of the original (FSFLAG_BINARY_ONLY is not ported)</summary>
  TGameSearchFlag = (
    /// <summary>FSFLAG_SEARCH_DIRS</summary>
    SearchDirs,
    /// <summary>FSFLAG_SEARCH_PAKS</summary>
    SearchPaks,
    /// <summary>FSFLAG_PURE_NOREF: a pak where the file is found is not marked as referenced</summary>
    NoReference,
    /// <summary>FSFLAG_SEARCH_ADDONS: after the search list, the addon paks left out of it</summary>
    SearchAddons);
  TGameSearchFlags = set of TGameSearchFlag;

  /// <summary>One element of the search list, as the "path" command prints it (searchpath_t)</summary>
  TGameSearchPath = record
    IsDirectory: Boolean;
    /// <summary>Directory: fs_*path, e.g. c:\doom; pak: empty</summary>
    Path: string;
    /// <summary>Directory: the game folder, e.g. base; pak: empty</summary>
    GameDir: string;
    /// <summary>Pak: the file name of the pak; directory: empty</summary>
    PackFileName: string;
    /// <summary>Pak: the checksum (MD4 of the CRCs of its files)</summary>
    Checksum: Cardinal;
    /// <summary>Pak: it has an addon.conf</summary>
    IsAddon: Boolean;
  end;

const
  /// <summary>What the original reads and lists by default: files in folders and in paks</summary>
  GAMEFS_DEFAULT_FLAGS: TGameSearchFlags = [TGameSearchFlag.SearchDirs, TGameSearchFlag.SearchPaks];

implementation

end.
