{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - the factory: the composition root                 }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.Factory;

interface

uses
  DelphiDoom.Wad.Intf,
  DelphiDoom.Font.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the font library</summary>
  TFontFactory = class sealed
  public
    class function CreateTextComposer(const ARasterizer: IFontRasterizer): IFontTextComposer; static;
    class function CreateGridComposer(const ARasterizer: IFontRasterizer): IFontGridComposer; static;
    /// <summary>The exporter with the nearest color search of the palette library and the patch writer of the imaging library</summary>
    class function CreateExporter(const ARasterizer: IFontRasterizer): IFontExporter; static;
    /// <param name="ABuilder">The builder that the WAD is made with (the WAD library makes one)</param>
    class function CreateWadGenerator(const ARasterizer: IFontRasterizer;
      const ABuilder: IWadBuilder): IFontWadGenerator; static;
  end;

implementation

uses
  DelphiDoom.Palette.ColorMatcher, DelphiDoom.Imaging.PatchWriter,
  DelphiDoom.Font.TextComposer, DelphiDoom.Font.GridComposer, DelphiDoom.Font.Exporter,
  DelphiDoom.Font.WadGenerator;

{ TFontFactory }

class function TFontFactory.CreateTextComposer(const ARasterizer: IFontRasterizer): IFontTextComposer;
begin
  Result := TFontTextComposer.Create(ARasterizer);
end;

class function TFontFactory.CreateGridComposer(const ARasterizer: IFontRasterizer): IFontGridComposer;
begin
  Result := TFontGridComposer.Create(ARasterizer);
end;

class function TFontFactory.CreateExporter(const ARasterizer: IFontRasterizer): IFontExporter;
begin
  Result := TFontExporter.Create(CreateTextComposer(ARasterizer), TColorMatcher.Create, TImagingPatchWriter.Create);
end;

class function TFontFactory.CreateWadGenerator(const ARasterizer: IFontRasterizer;
  const ABuilder: IWadBuilder): IFontWadGenerator;
begin
  Result := TFontWadGenerator.Create(CreateExporter(ARasterizer), ABuilder);
end;

end.
