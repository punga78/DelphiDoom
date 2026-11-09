{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixPalettePart                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GeneratePalette and GenerateTranslationTables of                    }
{  radix_xlat_wad.pas                                                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.PalettePart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   The first lumps of the WAD: PALETTE and SHADES from the lump "Palette[1]" and the tables
  ///   that bring the blue of the ships to red, green and yellow
  /// </summary>
  TRadixPalettePart = class(TInterfacedObject, IRadixPart)
  strict private
    FBuilder: IRadixPaletteBuilder;
    FPaletteName: string;
    FColorMapName: string;
    procedure BuildTranslations(const AContext: TRadixTranslationContext);
  public
    /// <param name="ABuilder">Makes the palettes; EArgumentNilException when nil</param>
    constructor Create(const ABuilder: IRadixPaletteBuilder); overload;
    /// <param name="APaletteName">The name of the lump of the palettes (PALETTE in the old game)</param>
    /// <param name="AColorMapName">The name of the lump of the color maps (SHADES in the old game)</param>
    constructor Create(const ABuilder: IRadixPaletteBuilder; const APaletteName,
      AColorMapName: string); overload;
    /// <summary>ERadixException when the container has no lump "Palette[1]"</summary>
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.Types;

const
  SRadixNoPalette = 'The container has no lump "Palette[1]"';

{ TRadixPalettePart }

constructor TRadixPalettePart.Create(const ABuilder: IRadixPaletteBuilder);
begin
  Create(ABuilder, RADIX_PALETTE_LUMP, RADIX_COLORMAP_LUMP);
end;

constructor TRadixPalettePart.Create(const ABuilder: IRadixPaletteBuilder; const APaletteName,
  AColorMapName: string);
begin
  inherited Create;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  FBuilder := ABuilder;
  FPaletteName := APaletteName;
  FColorMapName := AColorMapName;
end;

procedure TRadixPalettePart.BuildTranslations(const AContext: TRadixTranslationContext);
var
  LRed: TBytes;
  LGreen: TBytes;
  LYellow: TBytes;
begin
  if not (AContext.Container.TryRead('RedFromBluePal', LRed) and
    AContext.Container.TryRead('GreenFromBluePal', LGreen) and
    AContext.Container.TryRead('YellowFromBluePal', LYellow)) then
    Exit;
  FBuilder.Scale(LRed);
  FBuilder.Scale(LGreen);
  FBuilder.Scale(LYellow);
  AContext.Wad.AddLump('TRN_RED', FBuilder.BuildTranslation(AContext.Palette, LRed));
  AContext.Wad.AddLump('TRN_GREE', FBuilder.BuildTranslation(AContext.Palette, LGreen));
  AContext.Wad.AddLump('TRN_YELL', FBuilder.BuildTranslation(AContext.Palette, LYellow));
end;

procedure TRadixPalettePart.Build(const AContext: TRadixTranslationContext);
var
  LPalette: TBytes;
begin
  if not AContext.Container.TryRead('Palette[1]', LPalette) then
    raise ERadixException.Create(SRadixNoPalette);
  // the tables are made from the base palette after it has been scaled
  AContext.Wad.AddLump(FPaletteName, FBuilder.BuildPlayPal(LPalette));
  AContext.Wad.AddLump(FColorMapName, FBuilder.BuildColorMap(LPalette));
  FBuilder.Scale(LPalette);
  AContext.SetPalette(LPalette);
  BuildTranslations(AContext);
end;

end.
