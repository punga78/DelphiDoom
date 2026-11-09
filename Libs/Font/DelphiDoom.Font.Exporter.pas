{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the patch of a text                               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.Exporter;

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf;

type
  /// <summary>
  ///   FF_ExportFont of DD_FONT: the text is drawn white on black (whatever the colors of the settings are:
  ///   they are the colors of the patch, and the gray level of the drawing says how much of each), the picture
  ///   is taken to palette indices by TFontColorizer and written as a patch
  /// </summary>
  TFontExporter = class(TInterfacedObject, IFontExporter)
  strict private
    FComposer: IFontTextComposer;
    FMatcher: IColorMatcher;
    FPatchWriter: IImagingPatchWriter;
  public
    constructor Create(const AComposer: IFontTextComposer; const AMatcher: IColorMatcher;
      const APatchWriter: IImagingPatchWriter);
    function ExportText(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
      const AText: string; const AOptions: TFontExportOptions): TBytes;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Font.Colorizer;

{ TFontExporter }

constructor TFontExporter.Create(const AComposer: IFontTextComposer; const AMatcher: IColorMatcher;
  const APatchWriter: IImagingPatchWriter);
begin
  inherited Create;
  if not Assigned(AComposer) then
    raise EArgumentNilException.Create('AComposer');
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  if not Assigned(APatchWriter) then
    raise EArgumentNilException.Create('APatchWriter');
  FComposer := AComposer;
  FMatcher := AMatcher;
  FPatchWriter := APatchWriter;
end;

function TFontExporter.ExportText(const ASettings: TFontSettings; const APalette: TFontPaletteSelection;
  const AText: string; const AOptions: TFontExportOptions): TBytes;
var
  LDrawing: TFontSettings;
  LPalette: TFontPaletteSelection;
  LImage: TFontImage;
  LGray: TBytes;
  LIndexes: TBytes;
begin
  if not APalette.IsValid then
    raise EFontException.Create(SFontBadPalette);
  // the index 0 is kept for the transparency
  LPalette := TFontPaletteSelection.Create(APalette.Colors, Max(1, APalette.FirstIndex), APalette.LastIndex);
  if not LPalette.IsValid then
    raise EFontException.Create(SFontBadPalette);
  LDrawing := ASettings;
  LDrawing.FrontColor := FONT_COLOR_WHITE;
  LDrawing.BackColor := FONT_COLOR_BLACK;
  LImage := FComposer.Compose(LDrawing, AText, AOptions.FixedPitch, FONT_MAX_PATCH_WIDTH);
  LGray := TFontColorizer.Grayscale(LImage);
  TFontColorizer.StretchToMaximum(LGray);
  LIndexes := TFontColorizer.ToPaletteIndexes(LGray, LImage.Width, LImage.Height, ASettings.FrontColor,
    ASettings.BackColor, AOptions.PerlinNoise, LPalette, FMatcher);
  if AOptions.DefaultOffsets then
    Result := FPatchWriter.Build(LIndexes, LImage.Width, LImage.Height, AOptions.Solid)
  else
    Result := FPatchWriter.Build(LIndexes, LImage.Width, LImage.Height, AOptions.Solid, AOptions.OffsetX,
      AOptions.OffsetY);
end;

end.
