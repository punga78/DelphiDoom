{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the contracts                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types;

type
  /// <summary>The nearest color of a palette</summary>
  IColorMatcher = interface
    ['{6D2A8F31-4B97-4C05-A1E3-5F70C9B2D814}']
    /// <summary>
    ///   V_BestColor: the index (ALow..AHigh) of the color of APalette (R, G, B bytes) with the
    ///   least squared distance from the given one; the first of the equals; the exact match wins
    ///   at once. If every color is farther than twice the length of the color from black, the
    ///   result is 0 (the original "last resort")
    /// </summary>
    function BestColor(ARed, AGreen, ABlue: Byte; const APalette: TBytes;
      ALow, AHigh: Integer): Byte;
    /// <summary>
    ///   V_FindAproxColorIndex: AColors and AColor are $00RRGGBB (the original calls the low byte
    ///   "red" for both: the distance does not change). Returns the first index of ALow..AHigh
    ///   with the least squared distance; an exact match stops the search
    /// </summary>
    function FindApproximateIndex(const AColors: TArray<Cardinal>; AColor: Cardinal;
      ALow, AHigh: Integer): Integer;
  end;

  /// <summary>PLAYPAL, COLORMAP and FOGMAP from the palette of the game (V_CreateDoomPalette)</summary>
  IPaletteBuilder = interface
    ['{B3E71C94-08D5-4A62-9F1B-2C84D6A07E53}']
    /// <param name="ABasePalette">At least 768 bytes (only the first 768 are used)</param>
    function Build(const ABasePalette: TBytes; AWithColormap, AWithFogmap: Boolean): TPaletteSet;
  end;

  /// <summary>Translation tables: for each color of a palette the nearest of another</summary>
  ITranslationBuilder = interface
    ['{4F9C0A27-E618-4D3B-8A75-91D2B3C6E048}']
    /// <summary>V_CreateTranslation: for each color of AToPalette its nearest in AFromPalette (256 bytes)</summary>
    function Build(const AFromPalette, AToPalette: TBytes): TBytes;
    /// <summary>The table that changes nothing (when the lumps of the regions are missing)</summary>
    function Identity: TBytes;
  end;

  /// <summary>The translation tables of the players (R_InitTranslationTables), of one game</summary>
  IPlayerTranslations = interface
    ['{C81D5E40-7A39-4F26-B0E4-3A6F92D1C875}']
    /// <summary>The number of tables (of 256 bytes)</summary>
    function TableCount: Integer;
    /// <summary>TableCount tables one after the other (like translationtables[])</summary>
    function Build: TBytes;
  end;

  /// <summary>Gamma ramps</summary>
  IGammaTables = interface
    ['{19B7D3E6-52C0-4A8F-96D4-E07A18F3B259}']
    function LevelCount: Integer;
    /// <summary>The 256 bytes of a level; EPaletteException if it does not exist</summary>
    function Table(ALevel: Integer): TBytes;
  end;

  /// <summary>Colormaps: the corrections made after reading COLORMAP, a custom colormap or FOGMAP</summary>
  IColormapPreparer = interface
    ['{7E40B9A5-3D12-4C68-B5F7-A8D96C20E134}']
    /// <summary>Every 0 becomes ABlack (the black of the engine is not the index 0)</summary>
    function ReplaceZeros(const AColormap: TBytes; ABlack: Byte): TBytes;
    /// <summary>
    ///   Fewer than AMinRows full rows: the last full row is repeated up to AMinRows
    ///   (R_InitCustomColormaps). AMapCount is the number of rows after the call (the length div
    ///   256 of the input if it was enough). EPaletteException if the colormap has no full row
    /// </summary>
    function ExpandRows(const AColormap: TBytes; AMinRows: Integer; out AMapCount: Integer): TBytes;
    /// <summary>The colors ($00RRGGBB) of the 256 entries of a row of the colormap, through the palette colors</summary>
    function RowColors(const AColormap: TBytes; ARow: Integer;
      const APaletteColors: TArray<Cardinal>): TArray<Cardinal>;
    /// <summary>
    ///   The fog map of the engine: zeros and entries that are black in the colormap become ABlack,
    ///   and the colors of every entry
    /// </summary>
    function PrepareFog(const AFog, AColormap: TBytes; ABlack: Byte;
      const APaletteColors: TArray<Cardinal>): TFogMapData;
  end;

  /// <summary>Which colormap each light level and each distance or scale use</summary>
  ILightTableCalculator = interface
    ['{A5F2C813-94E7-4B30-8D6A-1B7E40C9D352}']
    /// <summary>
    ///   zlight: LightLevels * MaxLightZ colormap indexes (0..NumColorMaps - 1), row by row;
    ///   the colormap offset is the index * 256
    /// </summary>
    function ZLight(const AConfig: TLightTableConfig): TArray<Integer>;
    /// <summary>
    ///   scalelight: LightLevels * MaxLightScale indexes for a view; AScreenWidth is SCREENWIDTH.
    ///   EPaletteException if AViewWidth is not positive
    /// </summary>
    function ScaleLight(const AConfig: TLightTableConfig; AViewWidth, AScreenWidth: Integer): TArray<Integer>;
    /// <summary>zlightlevels: LightLevels * HiResMaxLightZ fixed point light levels (0..FracUnit - 1)</summary>
    function HiResZLight(const AConfig: TLightTableConfig): TArray<Integer>;
  end;

  /// <summary>The names of the color regions and of the blood colors (r_translations.pas)</summary>
  ITranslationNames = interface
    ['{E0638D17-B2A4-4F59-8C31-7D95A4F6C280}']
    /// <summary>
    ///   Finds the slot of a name: first as is (upper case), then without CR_, then without CR
    ///   (every strip on the result of the previous one, as the old code). The slots of the
    ///   regions are their REGION_* index. AKey is the name after the strips that were made:
    ///   the name under which a new table has to be remembered (see AddSlot). -1 if unknown
    /// </summary>
    function FindSlot(const AName: string; out AKey: string): Integer;
    /// <summary>Remembers a table loaded from a lump under the key given by FindSlot; returns its slot (REGION_COUNT, ...)</summary>
    function AddSlot(const AKey: string): Integer;
    /// <summary>
    ///   The lump names to try, in order, to load a table: the name, then CR_X without the
    ///   underscore, or CRX with it, or CR + name and CR_ + name (R_GetTranslationTable)
    /// </summary>
    function LumpCandidates(const AName: string): TArray<string>;
  end;

  /// <summary>The tables of r_precalc.pas</summary>
  IPrecalcTables = interface
    ['{5B90E2D8-6C14-4F7A-A3B5-08C1D7E946F2}']
    /// <summary>precalc32_r/g/b: [light * 256 + color], light 0..255; AChannel 0 red, 1 green, 2 blue</summary>
    function Multiply(AChannel: Integer): TArray<Integer>;
    /// <summary>precalc_fog_r/g/b, same layout</summary>
    function Fog(AChannel: Integer): TArray<Integer>;
    /// <summary>R_GetPrecalc32Tables: the light (16.16) as the index of a row, 0..255</summary>
    function LightIndex(ALight: Integer): Integer;
    /// <summary>precal8_tolong: the byte repeated 4 times</summary>
    function ByteToLong: TArray<Cardinal>;
    /// <summary>precal8_toword: the byte repeated 2 times</summary>
    function ByteToWord: TArray<Cardinal>;
    /// <summary>precal32_ic: 768 gray levels of the inverse colormap</summary>
    function InverseColor: TArray<Cardinal>;
    /// <summary>average_byte, average_r, average_g, average_b (512 each): AChannel 0 byte, 1 red, 2 green, 3 blue</summary>
    function Average(AChannel: Integer): TArray<Cardinal>;
    /// <summary>add32_c: the sum of two bytes, at most 255 (512 entries)</summary>
    function AddClamp: TBytes;
  end;

  /// <summary>V_FixBufferPalette: the reserved colors of a strip take the color on the left</summary>
  IPaletteBufferFixer = interface
    ['{F2A4693B-8D05-4E71-B9C6-3E18D70A5B94}']
    procedure Fix(var ABuffer: TBytes; AFrom, ATo: Integer);
  end;

  /// <summary>The colors of the palette, packed, without gamma (R_DefaultPalette)</summary>
  IPaletteUnpacker = interface
    ['{08D6B1F4-A7C3-4E92-85D0-C41E9A62B7F3}']
    /// <summary>256 colors $00RRGGBB from 768 bytes</summary>
    function Unpack(const APalette: TBytes): TArray<Cardinal>;
  end;

implementation

end.
