{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the contracts                               }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Intf;

interface

uses
  DelphiDoom.MapInfo.Types;

type
  /// <summary>Tells if a text is the name of a map of the game (MAP01, E1M1...)</summary>
  IMapNameValidator = interface
    ['{5E1B7A30-94C2-4D68-B0F3-2A8C6D1E7F45}']
    function IsValidMapName(const AName: string): Boolean;
  end;

  /// <summary>Tells if a lump exists in the loaded files</summary>
  IMapLumpCatalog = interface
    ['{C3D8A2F6-17B4-4E90-8A5D-6F2B09E4C731}']
    function LumpExists(const AName: string): Boolean;
  end;

  /// <summary>The number the game gives to a music, by its name</summary>
  IMapMusicResolver = interface
    ['{9A4F6E12-D3C8-47B5-A1E0-5B7C28D93F64}']
    function MusicNumberFor(const AName: string): Integer;
  end;

  /// <summary>The number of a thing type by its name (bossaction)</summary>
  IMapActorResolver = interface
    ['{2D7C5B94-E618-4A3F-9C02-B18F6A4D5E70}']
    /// <param name="AUpperName">The name in upper case</param>
    /// <returns>The number, or a negative one if the game has no such thing</returns>
    function ActorTypeFor(const AUpperName: string): Integer;
  end;

  /// <summary>Where "episode" goes: the list of episodes of the menu. A game without one gives none</summary>
  IMapEpisodeSink = interface
    ['{F6B21D83-5A7E-4C49-8E10-D39A4C7B2F58}']
    procedure ClearEpisodes;
    procedure AddEpisode(const AMapName, APicture, AText: string; AKey: Char);
  end;

  /// <summary>
  ///   Which "bossaction" lines the game takes. Doom and Heretic ask a tag, unless the special
  ///   ends the level; the other games take every one
  /// </summary>
  IMapBossActionRule = interface
    ['{80E5C9A7-3B14-4D26-A7F9-1C6E2B58D043}']
    function IsAccepted(ASpecial, ATag: Integer): Boolean;
  end;

  /// <summary>What the parser needs from the game; every service but the episodes is required</summary>
  TMapInfoServices = record
    Validator: IMapNameValidator;
    Lumps: IMapLumpCatalog;
    Music: IMapMusicResolver;
    Actors: IMapActorResolver;
    BossRule: IMapBossActionRule;
    /// <summary>May be nil: then "episode" is a property like the unknown ones, skipped</summary>
    Episodes: IMapEpisodeSink;
  end;

  /// <summary>Where the texts of the lumps of a name come from</summary>
  IMapInfoTextSource = interface
    ['{47A9E0D5-6C23-4B81-93F7-E5D2A0C8B614}']
    /// <summary>The text of every WAD lump with that name (in upper case), in the order of the directory</summary>
    function WadLumpTexts(const AUpperName: string): TArray<string>;
    /// <summary>The text of every entry of the PAK/PK3 files with that file name, one by one</summary>
    function PakTexts(const AFileName: string): TArray<string>;
  end;

  /// <summary>
  ///   The common preprocessor of the scripts (#define, #include...), done before the parser:
  ///   it belongs to the scanner library and to the engine, not to this one
  /// </summary>
  IMapInfoTextFilter = interface
    ['{1B3E8F47-A5D0-4C92-B6E4-7D09C3A1F258}']
    function Filter(const AText: string): string;
  end;

  /// <summary>Reads the text of an UMAPINFO lump into the entries it describes</summary>
  IMapInfoParser = interface
    ['{D5C07B3A-8E91-4F26-A340-9B2E6F1D7C85}']
    /// <summary>
    ///   The entries in the order of the text; what is wrong is a warning to the log and the
    ///   entry is skipped. Episodes go to the sink as they are read
    /// </summary>
    function Parse(const AText: string): TArray<TMapInfoEntry>;
  end;

  /// <summary>The maps of UMAPINFO and the defaults of UMAPDEF</summary>
  IMapInfoCatalog = interface
    ['{6F2A94C1-0D78-4B35-8E6A-C41B7D5093F2}']
    /// <summary>
    ///   An entry that was read. A default is kept as it is. A map is merged with the default
    ///   that is at the same position in the list (as the old code did, even if that default
    ///   is of another map), and replaces the map of that name if there is one
    /// </summary>
    procedure AddParsed(const AEntry: TMapInfoEntry; AIsDefault: Boolean);
    /// <summary>Forgets the maps; the defaults stay (as U_FreeMapInfo did)</summary>
    procedure ClearMaps;
    procedure ClearDefaults;
    function MapCount: Integer;
    function GetMap(AIndex: Integer): TMapInfoEntry;
    function DefaultCount: Integer;
    function GetDefault(AIndex: Integer): TMapInfoEntry;
    /// <summary>The position of a map by its name (as it is written in the entry), or -1</summary>
    function IndexOfMap(const AMapName: string): Integer;
    function IndexOfDefault(const AMapName: string): Integer;
  end;

  /// <summary>Finds the lumps of a name and feeds the catalog with them</summary>
  IMapInfoLoader = interface
    ['{B8F4D126-3C5A-4E07-91D8-A62E0F7B4C93}']
    /// <summary>
    ///   The WAD lumps of that name are one text, the PAK entries of that name and of that name
    ///   with ".txt" are one text each
    /// </summary>
    procedure Load(const ALumpName: string; AIsDefault: Boolean);
  end;

implementation

end.
