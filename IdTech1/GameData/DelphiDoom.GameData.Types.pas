{******************************************************************************}
{                                                                              }
{  DelphiDoom: game data library - types shared by the library                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the patch builders that the forks Mars3D, Rad-X and Speed carried   }
{  as three copies (MARS_CreateDoomPatch, RX_CreateDoomPatch, SH_CreateDoom-   }
{  Patch)                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameData.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>Raised when the data given to the library cannot make a patch or a WAD</summary>
  EGameDataException = class(Exception);

  /// <summary>
  ///   The 8 bytes that start a patch (the picture format of Doom). The offsets are the pixels
  ///   to the left of the origin and below it
  /// </summary>
  TGamePatchHeader = packed record
    Width: SmallInt;
    Height: SmallInt;
    LeftOffset: SmallInt;
    TopOffset: SmallInt;
  end;

  /// <summary>
  ///   What differs between the three copies of the builder of the forks: the pixel that is a
  ///   hole when the patch is not solid (Mars 0, Rad-X 254, Speed 255) and the range of the
  ///   palette that a color may be matched to (Mars and Speed 16..239, Rad-X 0..255)
  /// </summary>
  TGamePatchOptions = record
    TransparentIndex: Byte;
    PaletteLow: Integer;
    PaletteHigh: Integer;
    class function Mars: TGamePatchOptions; static;
    class function Radix: TGamePatchOptions; static;
    class function Speed: TGamePatchOptions; static;
  end;

const
  /// <summary>As an offset: the default one (half the width to the left, the height below)</summary>
  GAMEDATA_PATCH_DEFAULT_OFFSET = -255;
  /// <summary>The longest column of a patch: a run is a byte, and 255 ends a column</summary>
  GAMEDATA_PATCH_MAX_HEIGHT = 255;
  GAMEDATA_PALETTE_SIZE = 768;
  GAMEDATA_PALETTE_COLORS = 256;

  SGameDataBadImage = 'The image of %d x %d needs %d bytes, there are %d';
  SGameDataBadHeight = 'A patch cannot be taller than %d (this one is %d)';
  SGameDataBadPalette = 'The palette needs %d bytes, there are %d';
  SGameDataBadLumpName = 'The lump name "%s" is not valid';

implementation

{ TGamePatchOptions }

class function TGamePatchOptions.Mars: TGamePatchOptions;
begin
  Result.TransparentIndex := 0;
  Result.PaletteLow := 16;
  Result.PaletteHigh := 239;
end;

class function TGamePatchOptions.Radix: TGamePatchOptions;
begin
  Result.TransparentIndex := 254;
  Result.PaletteLow := 0;
  Result.PaletteHigh := 255;
end;

class function TGamePatchOptions.Speed: TGamePatchOptions;
begin
  Result.TransparentIndex := 255;
  Result.PaletteLow := 16;
  Result.PaletteHigh := 239;
end;

end.
