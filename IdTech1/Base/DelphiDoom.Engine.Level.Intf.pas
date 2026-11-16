{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the contracts of the loading of a level                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.Intf;

interface

uses
  doomdef,
  doomdata,
  r_defs,
  p_udmf,
  DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   Loads a level in the global structures of the engine (sectors[], lines[], sides[],
  ///   segs[], subsectors[], nodes[], the blockmap, the reject and the things) and prepares
  ///   the data that the play loop reads. It was P_SetupLevel, P_Init and P_ShutDown of
  ///   p_setup.pas; the composition root gives it to g_game and d_main
  /// </summary>
  ILevelLoader = interface
    ['{5B0E2C71-8A43-4F6D-9E1B-7C24D80A3F16}']
    /// <summary>
    ///   The data of the play loop read once at the start: switches, animations of flats and
    ///   textures, sprites, MUSINFO and the commands of the console (P_Init)
    /// </summary>
    procedure Initialize;
    /// <summary>Frees what Initialize made (P_ShutDown)</summary>
    procedure ShutDown;
    /// <summary>
    ///   Loads the map of the episode and number given (Hexen and Strife have no episodes: the
    ///   value is ignored) and spawns its things (P_SetupLevel)
    /// </summary>
    procedure SetupLevel(AEpisode, AMap, APlayerMask: Integer; ASkill: skill_t);
  end;

  /// <summary>
  ///   The steps of the loading of a level that are not the same in Doom, Heretic, Hexen and
  ///   Strife: one class for each game answers
  /// </summary>
  ILevelGameRules = interface
    ['{E6F31A09-2C5D-4B87-A4D0-91B6E83C5F27}']
    /// <summary>The start of the data of the game, before the sprites (first part of P_Init)</summary>
    procedure InitializeData;
    /// <summary>Frees what InitializeData made</summary>
    procedure ShutDownData;
    /// <summary>True when the steps of the loading are printed with -devparm (only Doom)</summary>
    function TracesSteps: Boolean;
    /// <summary>The name of the lump of the map</summary>
    function MapName(AEpisode, AMap: Integer): string;
    /// <summary>The lines printed when the loading starts</summary>
    procedure PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
    /// <summary>Clears the statistics of the level and of the players</summary>
    procedure ResetStatistics;
    /// <summary>Clears the data of the previous level, after the zone memory of the level is freed</summary>
    procedure ClearLevelData;
    /// <summary>After the blockmap is loaded</summary>
    procedure AfterBlockmap;
    /// <summary>After the nodes (GL, GWA or of the map) are loaded</summary>
    procedure AfterNodes(AMapLump: Integer);
    /// <summary>Before the things are spawned</summary>
    procedure BeforeThings;
    /// <summary>After the things are spawned and the easy angles and winds are adjusted</summary>
    procedure AfterThings;
    /// <summary>Before the players of a deathmatch are spawned, also when it is not a deathmatch</summary>
    procedure BeforeDeathmatchSpawn;
    /// <summary>Spawns a player of a deathmatch at a random start</summary>
    procedure SpawnDeathmatchPlayer(APlayer: Integer);
    /// <summary>After the players of a deathmatch are spawned</summary>
    procedure AfterDeathmatchSpawn;
    /// <summary>After the specials of the sectors and of the lines are spawned</summary>
    procedure AfterSpecials;
    /// <summary>The last step of the loading: the lightning of the level (and in Hexen the sounds stop)</summary>
    procedure AfterLevel;
  end;

  /// <summary>
  ///   The fields of sectors, sides and lines that are not the same in every game, and the
  ///   steps of the grouping of the lines that depend on the game
  /// </summary>
  ILevelGeometryRules = interface
    ['{7A2D94E5-1B6C-4F03-8D7E-C5F02B91A468}']
    /// <summary>The fields of the sector that only the game has (called after the common ones)</summary>
    procedure InitializeSector(ASector: Psector_t);
    /// <summary>The textures of a side, from the names of the lump</summary>
    procedure ReadSideTextures(AMapSide: Pmapsidedef_t; ASide: Pside_t);
    /// <summary>Corrects the lump LINEDEFS before it is read (it may be changed in place)</summary>
    procedure FixLineDefs(AData: Pointer; ALumpSize, ACount: Integer);
    /// <summary>The tag or the arguments of the special of a line</summary>
    procedure ReadLineArguments(AMapLine: Pmaplinedef_t; ALine: Pline_t);
    /// <summary>Before the subsectors are given their sectors</summary>
    procedure BeforeGroupLines;
    /// <summary>Marks the lines drawn as transparent, after the lines of each sector are counted</summary>
    procedure MarkTransparentLines;
    /// <summary>
    ///   True when the block boxes of the sectors are calculated as for a blockmap built by the
    ///   engine (64 bit arithmetic), false for the old way of a blockmap read from the lump
    /// </summary>
    function UsesInternalBlockCoordinates: Boolean;
    /// <summary>After the lines are grouped in the sectors</summary>
    procedure AfterGroupLines;
  end;

  /// <summary>How the game spawns the things of the map</summary>
  ILevelThingRules = interface
    ['{C4B81F36-9E02-4A75-B3D8-6F1E07A25C93}']
    /// <summary>Spawns a thing of the lump; AExtra has the values of a text map or is nil</summary>
    procedure SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
    /// <summary>After every thing is spawned, while the lump is still in memory</summary>
    procedure AfterMapThingsSpawned;
    /// <summary>After every thing is spawned and the lump is freed</summary>
    procedure AfterThingsLoaded;
  end;

  /// <summary>The lumps of a classic map in the structures of the engine</summary>
  ILevelMapReader = interface
    ['{2F9C6E18-D403-4B5A-8E71-A0C3B5D947E2}']
    procedure LoadVertexes(ALump: Integer);
    procedure LoadSectors(ALump: Integer);
    procedure LoadSideDefs(ALump: Integer);
    procedure LoadLineDefs(ALump: Integer);
    procedure LoadSubsectors(ALump: Integer);
    procedure LoadNodes(ALump: Integer);
    procedure LoadSegs(ALump: Integer);
    procedure LoadReject(ALump: Integer);
    /// <summary>The lines of each sector, the sector of each subsector and the block boxes</summary>
    procedure GroupLines;
  end;

  /// <summary>The things of the map: the easy slopes first, then every thing</summary>
  ILevelThings = interface
    ['{91E5D2A4-6C17-4F38-B0E9-3D84A7C1F052}']
    procedure Load(ALump: Integer);
  end;

  /// <summary>
  ///   The nodes of the level: the ones built by glBSP (GWA), the GL nodes in the WAD and the
  ///   check that a map has its nodes. It was the level part of nd_main.pas
  /// </summary>
  ILevelNodes = interface
    ['{0D6A3B87-E25F-4C19-9A4E-B78C21F6D3A5}']
    /// <summary>Builds the nodes of a map that has none and loads them (ND_NodesCheck)</summary>
    procedure CheckNodes(const AMapName: string);
    /// <summary>The GWA of the map, built by glBSP if it is not there; nil if it fails</summary>
    function FindGwa(const AMapName: string): INodesGwa;
    /// <summary>The lump GL_xxx of the map, -1 if it is not there</summary>
    function FindGlMapLump(AMapLump: Integer): Integer;
    /// <summary>The version of the GL nodes after the lump GL_xxx, 0 if there are none</summary>
    function DetectGlNodesVersion(AGlMapLump: Integer): Integer;
    procedure LoadVertexes(ALump: Integer; const AGwa: INodesGwa);
    procedure LoadSubsectors(const AGwa: INodesGwa);
    procedure LoadNodes(const AGwa: INodesGwa);
    procedure LoadSegs(const AGwa: INodesGwa);
  end;

  /// <summary>The nodes of the old engine, for the demos of the versions before 1.10 (only Doom)</summary>
  ILevelVanillaNodes = interface
    ['{B3E07D52-4A96-4E1C-8F25-1C69D0A8E7B4}']
    procedure Load(AMapLump: Integer);
  end;

  /// <summary>The blockmap of the level and the removal of the slime trails</summary>
  ILevelBlockmap = interface
    ['{6E14A8C3-B759-4D20-91F6-E2A0C47B3D85}']
    procedure Load(ALump: Integer);
    procedure RemoveSlimeTrails;
  end;

  /// <summary>
  ///   A map in the UDMF text format: converted in a PWAD loaded at runtime, then the extra
  ///   values applied to the structures. It was the facade p_udmf.pas
  /// </summary>
  ILevelUdmf = interface
    ['{F2C59E07-3D18-4A6B-BE40-857D1A3C9F62}']
    /// <summary>
    ///   Reads the extra lumps of the map, or converts its TEXTMAP; true when the map is a text
    ///   map (UDMF_Check)
    /// </summary>
    function Prepare(const AMapName: string): Boolean;
    function ApplySides: Boolean;
    function ApplyLines: Boolean;
    function ApplySegs: Boolean;
    function ApplySectors: Boolean;
  end;

implementation

end.
