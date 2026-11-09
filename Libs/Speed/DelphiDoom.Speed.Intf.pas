{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - contracts                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.GameData.Intf, DelphiDoom.Speed.Types;

type
  /// <summary>
  ///   The container SPEEDH.JCL: a directory of files kept back to front. The entries are in the
  ///   order of the old translator: by the number a name starts with (a name that does not start
  ///   with a number counts 0) and then by name
  /// </summary>
  ISpeedContainer = interface
    ['{7D2A4E91-5B03-4C68-A1F7-93E0C5B82D16}']
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TSpeedContainerEntry;
    function GetSize: Integer;
    /// <summary>The first entry with that name (the comparison is exact); -1 when there is none</summary>
    function IndexOf(const AName: string): Integer;
    /// <summary>The bytes of an entry; ESpeedException when it lies outside the container</summary>
    function Read(AIndex: Integer): TBytes;
    /// <summary>
    ///   The bytes of an entry, at least AMinimumSize of them when the container has so many after the
    ///   start of the entry (the directory of the real container gives a size that is too small for
    ///   some pictures, which say their own length)
    /// </summary>
    function ReadAtLeast(AIndex, AMinimumSize: Integer): TBytes;
    /// <summary>The bytes of the entry with that name; false when there is none</summary>
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
    property Count: Integer read GetCount;
    property Entries[AIndex: Integer]: TSpeedContainerEntry read GetEntry;
    /// <summary>The size of the whole container in bytes</summary>
    property Size: Integer read GetSize;
  end;

  /// <summary>What the game keeps of the palette of GRAFS.PAL</summary>
  TSpeedPalette = record
    /// <summary>768 bytes, 0..255 (the file has 0..63 and is multiplied by 4)</summary>
    Source: TBytes;
    /// <summary>PLAYPAL: 14 palettes of 768 bytes</summary>
    PlayPal: TBytes;
    /// <summary>COLORMAP: 34 maps of 256 bytes</summary>
    ColorMap: TBytes;
    /// <summary>The 256 colors as $00RRGGBB</summary>
    Colors: TArray<Cardinal>;
  end;

  /// <summary>PLAYPAL, COLORMAP and the colors from the palette of the game</summary>
  ISpeedPaletteBuilder = interface
    ['{E3B81F60-27C4-4D95-8A0E-6C1D5F9B7A32}']
    /// <param name="AFilePalette">At least 768 bytes</param>
    function Build(const AFilePalette: TBytes): TSpeedPalette;
  end;

  /// <summary>A picture by columns: the pixel (X, Y) is Pixels[X * Height + Y]; 255 is a hole</summary>
  TSpeedBitmap = record
    Width: Integer;
    Height: Integer;
    Pixels: TBytes;
  end;

  /// <summary>Reads the .IS2 pictures</summary>
  ISpeedBitmapDecoder = interface
    ['{19C7D4A8-6E52-4B30-9F81-D2A05E3B46C7}']
    /// <summary>False when the data are not an .IS2 picture (the wrong signature or too short)</summary>
    function DecodeIs2(const AData: TBytes; out ABitmap: TSpeedBitmap): Boolean;
  end;

  /// <summary>The floor of a circuit made of its tiles</summary>
  ISpeedMapBitmapBuilder = interface
    ['{2D8E5A13-9C47-4F60-B7A2-C1F084D3E965}']
    /// <summary>
    ///   AMapData is a .DAT file (the tiles and their angles come first) and ATiles the tiles
    ///   (GRAFS.DAT, 4096 bytes each). ABitmap is 4096 x 4096 pixels, stored by columns;
    ///   AFirstTile is the tile at the corner. False when AMapData is too short
    /// </summary>
    function Build(const AMapData, ATiles: TBytes; out ABitmap: TBytes; out AFirstTile: Integer): Boolean;
  end;

  /// <summary>Reads CIRCUITS.LST</summary>
  ISpeedCircuitReader = interface
    ['{5A0E73B2-C8D1-4F46-B39A-14E6D80C7F25}']
    /// <summary>At most SPEED_MAX_CIRCUITS circuits; the missing fields are 0 or empty</summary>
    function Parse(const AText: string): TArray<TSpeedCircuit>;
  end;

  /// <summary>One circuit as a level of Doom: THINGS, LINEDEFS, SIDEDEFS, VERTEXES, SECTORS and PATH</summary>
  ISpeedLevelBuilder = interface
    ['{C4F2A915-3D70-48E6-B1A9-07E5D63B9C48}']
    /// <summary>
    ///   Appends the lumps of the level to AWad. False (and a warning) when the files of the
    ///   circuit are not good: nothing is appended
    /// </summary>
    function Build(const ALevelName, APrefix: string; const AMapData, ASectorData, APathData: TBytes;
      AScale: Integer; const AExtraFlat: string; const AWad: IGameWadComposer): Boolean;
  end;

  /// <summary>The fonts of the game as patches: SFNT (8 x 8) and BFNT (16 x 16), in five colors</summary>
  ISpeedFontBuilder = interface
    ['{8B6D3E07-F5A1-4C92-A740-2E9C1D58B3F6}']
    /// <param name="AColors">The 256 colors of the palette of the game, $00RRGGBB</param>
    procedure Build(const AColors: TArray<Cardinal>; const AWad: IGameWadComposer);
  end;

  /// <summary>The whole game: SPEEDH.JCL into the lumps of a WAD</summary>
  ISpeedTranslator = interface
    ['{F1A9C605-4E83-4D27-8B5C-70D2E96A13B4}']
    /// <summary>
    ///   Appends the lumps to AWad. The files that the engine must read from the container by
    ///   itself (the 3D models) are the result; their names are MODELS\name
    /// </summary>
    function Translate(const AContainer: ISpeedContainer;
      const AWad: IGameWadComposer): TArray<TSpeedPakEntry>;
  end;

implementation

end.
