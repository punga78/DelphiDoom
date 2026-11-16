{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - contracts                                       }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.MapInfo.Types,
  DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types;

type
  /// <summary>
  ///   The container RADIX.DAT: a directory of named lumps (header "NSRes:Radix"). Names are
  ///   compared exactly, the first lump with a name wins
  /// </summary>
  IRadixContainer = interface
    ['{2E7C91A4-5D38-4B06-8F1A-C4D92B07E651}']
    function GetCount: Integer;
    function GetInfo(AIndex: Integer): TRadixLumpInfo;
    /// <summary>The index of the first lump with that name; -1 when there is none</summary>
    function IndexOf(const AName: string): Integer;
    /// <summary>The bytes of a lump; ERadixException when it lies outside the container</summary>
    function Read(AIndex: Integer): TBytes;
    /// <summary>The bytes of the lump with that name; false when there is none</summary>
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
    /// <summary>A part of the container at a position (the tables of the wall bitmaps)</summary>
    function ReadAt(APosition, ASize: Integer): TBytes;
    property Count: Integer read GetCount;
    property Infos[AIndex: Integer]: TRadixLumpInfo read GetInfo;
  end;

  /// <summary>
  ///   The 22 palettes of the game, the 34 light tables of COLORMAP and the tables that bring
  ///   one palette to another (Rad-X: RX_CreateDoomPalette, RX_CreateTranslation)
  /// </summary>
  IRadixPaletteBuilder = interface
    ['{91B4E3D2-6A07-4F58-B3C1-0D5E7A82F946}']
    /// <summary>
    ///   Multiplies by 4 a palette of 768 bytes whose values are all below 64 (VGA); true when it
    ///   did. The palette is changed in place
    /// </summary>
    function Scale(var APalette: TBytes): Boolean;
    /// <summary>PLAYPAL: 22 palettes of 768 bytes (the base, the red, yellow, green and white flashes)</summary>
    function BuildPlayPal(const ABasePalette: TBytes): TBytes;
    /// <summary>COLORMAP: 32 light levels, the invulnerability map and a black one, 34 x 256 bytes</summary>
    function BuildColorMap(const ABasePalette: TBytes): TBytes;
    /// <summary>For every color of AToPalette the nearest of AFromPalette (256 bytes)</summary>
    function BuildTranslation(const AFromPalette, AToPalette: TBytes): TBytes;
  end;

  /// <summary>
  ///   Turns RADIX.DAT into a WAD held in memory, as the old converter of Rad-X did. The lumps
  ///   keep the order of the old converter. Only the parts that are ported are done: see the
  ///   README of the library
  /// </summary>
  IRadixTranslator = interface
    ['{A06D52F8-3E91-47C3-9B5A-7F18C4E0D2B3}']
    /// <summary>Converts the container; the result is a PWAD held in memory</summary>
    function Translate(const AContainer: IRadixContainer): IGameWadComposer;
    /// <summary>The pictures to add to the PAK file system (the title picture)</summary>
    function GetPakEntries: TArray<TRadixPakEntry>;
    /// <summary>The names of the textures, in the order of TEXTURE0</summary>
    function GetTextureNames: TArray<string>;
    property PakEntries: TArray<TRadixPakEntry> read GetPakEntries;
    property TextureNames: TArray<string> read GetTextureNames;
  end;

  /// <summary>Tells whether the WAD has a lump with that name (the aliases of missing lumps are dropped)</summary>
  TRadixLumpExists = reference to function(const ALumpName: string): Boolean;

  /// <summary>
  ///   The names that the pictures have in RADIX.DAT ("MainMenuButton1", longer than the 8
  ///   characters of a lump) brought to the lumps of the translated WAD (Rad-X: radix_alias)
  /// </summary>
  IRadixLumpAliases = interface
    ['{5C0B7E19-84D3-4A6F-9E21-3B7A60D4C8F2}']
    function GetCount: Integer;
    /// <summary>
    ///   Adds the lines "LUMP=name" of a lump RADIXINF. A name already known is not changed.
    ///   AExists (it can be nil: every line is taken) drops the lines of the lumps that are not there
    /// </summary>
    procedure AddText(const AText: string; const AExists: TRadixLumpExists);
    /// <summary>The lump of a name of RADIX.DAT, without case; false when the table does not have it</summary>
    function TryResolve(const ARadixName: string; out ALumpName: string): Boolean;
    property Count: Integer read GetCount;
  end;

  /// <summary>
  ///   Reads the lump RMAP that the translation writes for every level: what a sector and a wall
  ///   of Radix have more than those of Doom (Rad-X: RX_LoadRadixMapInfo)
  /// </summary>
  IRadixMapInfoReader = interface
    ['{B81F3D06-2A9C-4E57-9D40-6C3E1F7A85B9}']
    /// <summary>ERadixException when a statement has no number where it wants one</summary>
    function Read(const AText: string): TRadixMapInfo;
  end;

  /// <summary>
  ///   Reads the binary lumps that the translation writes after the map of every level: RACTION,
  ///   RTRIGGER, RGRID, RMAPGRID and RTHINGS (Rad-X: P_LoadRadixSprites, P_LoadRadixTriggers,
  ///   P_LoadGrid, P_LoadMapGrid and the extra data of P_LoadThings). An empty lump is a level
  ///   without that data; a lump of a size that is not the one of its records is an ERadixException
  /// </summary>
  IRadixLevelLumpReader = interface
    ['{5E0C7A91-3B64-4D2F-8A17-C9D2E6F4B103}']
    /// <summary>RACTION: the actions of the level, 168 bytes each</summary>
    function ReadActions(const ABytes: TBytes): TArray<TRadixLevelAction>;
    /// <summary>RTRIGGER: the triggers of the level, 1834 bytes each</summary>
    function ReadTriggers(const ABytes: TBytes): TArray<TRadixLevelTrigger>;
    /// <summary>RGRID: the trigger of every cell; a width and a height that do not make the 40960 cells are an error</summary>
    function ReadGrid(const ABytes: TBytes): TRadixTriggerGridData;
    /// <summary>RMAPGRID: the place in the Doom map of every cell of the grid (all zero for an empty lump)</summary>
    function ReadMapPoints(const ABytes: TBytes): TArray<TRadixLevelMapPoint>;
    /// <summary>RTHINGS: what a thing of Radix has more than one of Doom, one record for each thing of THINGS</summary>
    function ReadThingExtras(const ABytes: TBytes): TArray<TRadixDoomThingExtra>;
  end;

implementation

end.
