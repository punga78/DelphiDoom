{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the default palette in 32 bits                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Palette.Intf;

{$I Doom32.inc}

interface

type
  /// <summary>The 256 colors of a palette, $00RRGGBB (the old palette_t of r_palette)</summary>
  TEnginePalette = array[0..255] of LongWord;
  PEnginePalette = ^TEnginePalette;

  /// <summary>
  ///   The first palette of PLAYPAL in 32 bits, read once: the composition root gives it to the
  ///   colormaps (r_data, r_colormaps) and to the voxels of the software renderer (r_voxels).
  ///   It was the facade r_palette.pas
  /// </summary>
  IEngineDefaultPalette = interface
    ['{93B07E2D-4A16-4C58-8F3D-E2A15B6C0D79}']
    /// <summary>The colors; the palette is read from the WAD the first time (R_DefaultPalette)</summary>
    function Colors: PEnginePalette;
  end;

implementation

end.
