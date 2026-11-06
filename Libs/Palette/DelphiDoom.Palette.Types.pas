{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - shared types and constants                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Colors of a palette of the game</summary>
  PALETTE_COLOR_COUNT = 256;
  /// <summary>Bytes of a palette of the game (R, G, B for each color)</summary>
  PALETTE_BYTE_COUNT = PALETTE_COLOR_COUNT * 3;
  /// <summary>Bytes of a row of a colormap, and of a translation table</summary>
  COLORMAP_ROW_SIZE = 256;
  /// <summary>Light rows of a generated colormap (the others are the gray row and the black row)</summary>
  COLORMAP_LIGHT_COUNT = 32;
  /// <summary>Rows of a generated colormap: lights, gray, black</summary>
  COLORMAP_GENERATED_ROWS = COLORMAP_LIGHT_COUNT + 2;
  /// <summary>Colormap rows the renderer wants at least (NUMCOLORMAPS)</summary>
  COLORMAP_MIN_ROWS = 32;

  /// <summary>Palettes of PLAYPAL of Doom, Heretic and Strife</summary>
  PLAYPAL_COUNT_DOOM = 14;
  /// <summary>Palettes of PLAYPAL of Hexen</summary>
  PLAYPAL_COUNT_HEXEN = 28;

  // The indexes of the color regions (CR_*): the order of crange_idx_e of r_draw.pas
  REGION_BRICK = 0;
  REGION_TAN = 1;
  REGION_GRAY = 2;
  REGION_GREEN = 3;
  REGION_BROWN = 4;
  REGION_GOLD = 5;
  REGION_RED = 6;
  REGION_BLUE = 7;
  REGION_ORANGE = 8;
  REGION_YELLOW = 9;
  REGION_BLUE2 = 10;
  REGION_BLACK = 11;
  REGION_PURPL = 12;
  REGION_WHITE = 13;
  REGION_TRANS0 = 14;
  REGION_TRANS9 = 23;
  REGION_COUNT = 24;

  /// <summary>Different blood colors the engine knows (index 0 is the red of the sprites)</summary>
  BLOOD_COLOR_COUNT = 9;

resourcestring
  SPaletteTooShort = 'The palette has %d bytes, %d needed';
  SPaletteRangeInvalid = 'The color range %d..%d is not inside the palette';
  SColormapTooShort = 'The colormap has %d bytes, at least %d needed';
  SColormapRowInvalid = 'The colormap has no row %d';
  SViewWidthInvalid = 'The width of the view must be positive (%d)';
  SGammaLevelInvalid = 'The gamma level %d does not exist';
  SFogLongerThanColormap = 'The fog map (%d bytes) is longer than the colormap (%d bytes)';
  SChannelInvalid = 'The channel %d does not exist';

type
  /// <summary>Something wrong in the arguments of a palette operation</summary>
  EPaletteException = class(Exception);

  /// <summary>
  ///   One extra palette of PLAYPAL: the base palette moved toward (R, G, B) by Shift / Steps
  ///   (the damage flashes, the bonus flash, the radiation suit, the Hexen effects)
  /// </summary>
  TPaletteShift = record
    /// <summary>Index of the palette in PLAYPAL (the base palette is 0)</summary>
    TargetIndex: Integer;
    Red: Integer;
    Green: Integer;
    Blue: Integer;
    Shift: Integer;
    Steps: Integer;
  end;

  /// <summary>
  ///   What changes between the games in the generation of the palettes: injected, not an IFDEF.
  ///   Doom, Heretic and Strife share a profile; Hexen has its own
  /// </summary>
  TPaletteProfile = record
    /// <summary>Palettes in PLAYPAL, the base one included</summary>
    PaletteCount: Integer;
    Shifts: TArray<TPaletteShift>;
    /// <summary>Hexen: the color 255 of the colormap is shaded as the color 0 (it is the transparent one)</summary>
    LastColorShadesAsFirst: Boolean;
    /// <summary>Doom, Heretic, Strife: the gray row of the colormap is the negative (the invulnerability)</summary>
    InvertedGrayRow: Boolean;
  end;

  /// <summary>What the generation makes from a palette</summary>
  TPaletteSet = record
    /// <summary>
    ///   The base palette as it was used: the old code multiplied by 4 a palette of 6 bits (all
    ///   the values under 64) writing on its input. 768 bytes
    /// </summary>
    BasePalette: TBytes;
    /// <summary>PaletteCount palettes of 768 bytes: the base, the flashes</summary>
    Playpal: TBytes;
    /// <summary>34 rows of 256 bytes, empty if not asked</summary>
    Colormap: TBytes;
    /// <summary>34 rows of 256 bytes, empty if not asked</summary>
    Fogmap: TBytes;
  end;

  /// <summary>A fog map with its colors, from TColormapPreparer.PrepareFog</summary>
  TFogMapData = record
    Indexes: TBytes;
    /// <summary>Each index through the colors of the palette, $00RRGGBB</summary>
    Colors: TArray<Cardinal>;
  end;

  /// <summary>The numbers of the light tables of the renderer (r_main.pas)</summary>
  TLightTableConfig = record
    NumColorMaps: Integer;
    LightLevels: Integer;
    MaxLightScale: Integer;
    MaxLightZ: Integer;
    LightZShift: Integer;
    LightScaleShift: Integer;
    DistMap: Integer;
    HiResMaxLightZ: Integer;
    HiResLightZShift: Integer;
    HiResLightScaleShift: Integer;
    /// <summary>The 16.16 fixed point unit (FRACUNIT)</summary>
    FracUnit: Integer;
    /// <summary>The half of the 320 pixels of the reference screen: 160 in the original</summary>
    ReferenceHalfWidth: Integer;
    /// <summary>The values of the engine: 32 colormaps, 16 light levels, 48 scales, 128 z steps</summary>
    class function Default: TLightTableConfig; static;
  end;

implementation

{ TLightTableConfig }

class function TLightTableConfig.Default: TLightTableConfig;
begin
  Result.NumColorMaps := 32;
  Result.LightLevels := 16;
  Result.MaxLightScale := 48;
  Result.MaxLightZ := 128;
  Result.LightZShift := 20;
  Result.LightScaleShift := 12;
  Result.DistMap := 2;
  Result.HiResMaxLightZ := 128 * 64;
  Result.HiResLightZShift := 12;
  Result.HiResLightScaleShift := 3;
  Result.FracUnit := 1 shl 16;
  Result.ReferenceHalfWidth := 160;
end;

end.
