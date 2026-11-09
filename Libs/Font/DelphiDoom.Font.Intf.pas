{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the contracts                                     }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings;

type
  /// <summary>
  ///   Draws a character with a font: the only part of DD_FONT that needs GDI (TCanvas.TextOut, the fonts that
  ///   are installed on the machine). The rest of the library works on the pictures it gives
  /// </summary>
  IFontRasterizer = interface
    ['{5B7E21C4-90D3-4A68-B1F5-3C8D6A0E47F2}']
    /// <summary>
    ///   The character in a picture of ASettings.DrawWidth by ASettings.DrawHeight pixels: the background is
    ///   ASettings.BackColor, the character is drawn in ASettings.FrontColor, in the font that the settings
    ///   say (name, size, style, pitch, charset), with its top left corner in the top left corner
    /// </summary>
    function RenderCharacter(const ASettings: TFontSettings; ACharacter: Char): TFontImage;
  end;

  /// <summary>Draws a text as a row of characters (DrawStringToBitmap of TFontEngine)</summary>
  IFontTextComposer = interface
    ['{A0C94E53-6D18-4F72-8B3A-D5E1479C0B26}']
    /// <summary>
    ///   The characters side by side, each one cut on the right unless AFixedPitch (a character is not cut
    ///   narrower than half of the size of the font), and the picture cut at AMaxWidth pixels. The height is
    ///   ASettings.DrawHeight. An empty text gives a picture without width
    /// </summary>
    function Compose(const ASettings: TFontSettings; const AText: string; AFixedPitch: Boolean;
      AMaxWidth: Integer): TFontImage;
  end;

  /// <summary>Draws the grid of the characters of a font (DrawToBitmap of TFontEngine)</summary>
  IFontGridComposer = interface
    ['{E3478D91-1A5C-4B06-9C27-F80B6D3E5A14}']
    /// <summary>
    ///   ASettings.GridWidth by ASettings.GridHeight cells of ASettings.DrawWidth by ASettings.DrawHeight
    ///   pixels; the cell number n holds the character with the code n, row by row, from the first
    /// </summary>
    function Compose(const ASettings: TFontSettings): TFontImage;
  end;

  /// <summary>Makes the patch of a text (FF_ExportFont of DD_FONT)</summary>
  IFontExporter = interface
    ['{7F1B05A8-C2E4-4D39-A6B0-94D82E3C1F57}']
    /// <summary>
    ///   The text is drawn white on black, cut to the width of the screen of Doom, turned to gray, stretched,
    ///   colored with the two colors of the settings (and the noise, if asked) and each pixel above the
    ///   threshold becomes the nearest color of the palette inside its range; the others are transparent.
    ///   The result is a patch of Doom. A palette that is not valid raises EFontException
    /// </summary>
    function ExportText(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
      const AText: string; const AOptions: TFontExportOptions): TBytes;
  end;

  /// <summary>Makes the WAD of a font (DoGenerateWAD of DD_FONT)</summary>
  IFontWadGenerator = interface
    ['{2D69C3E0-8B47-4A15-9F8E-0C5A71B2E634}']
    /// <summary>
    ///   A PWAD with the lump DDFONT (the settings) and a patch for each text: the one of the request, the
    ///   characters from ! to DEL with the names prefix + the code on three digits, or the digits 0 to 9 with
    ///   the names prefix + the digit. The offsets of the patches are 0 and 3. The names of the lumps are
    ///   upper case and at most 8 characters long. A text that is only spaces raises EFontException
    /// </summary>
    function Generate(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
      const ARequest: TFontGenerationRequest): TBytes;
  end;

implementation

end.
