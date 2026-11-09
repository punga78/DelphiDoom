{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixDosFontPart                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateDosFonts of radix_xlat_wad.pas                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.DosFontPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf, DelphiDoom.Radix.Context;

type
  /// <summary>DOSFA, DOSFB (14x14) and DOSSA, DOSSB (8x8): the fonts of the terminal in two colors</summary>
  TRadixDosFontPart = class(TInterfacedObject, IRadixPart)
  strict private
    FMatcher: IColorMatcher;
  public
    /// <param name="AMatcher">Finds the nearest color of the palette; EArgumentNilException when nil</param>
    constructor Create(const AMatcher: IColorMatcher);
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.BitmapOps, DelphiDoom.Radix.FontData, DelphiDoom.Radix.FontTinter;

const
  // the first color was written as 192 shl 16 + 14 shl 8 + 14 shl 8 (that is $C01C00): kept
  Colors: array[0..1] of Cardinal = ($C01C00, $FFFFFF);

{ TRadixDosFontPart }

constructor TRadixDosFontPart.Create(const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FMatcher := AMatcher;
end;

procedure TRadixDosFontPart.Build(const AContext: TRadixTranslationContext);
var
  LTinted: TBytes;
  LGlyph: TBytes;
  LColor: Integer;
  LCode: Integer;
  LX: Integer;
  LY: Integer;
  LRow: Integer;
  LColumn: Integer;
  LPosition: Integer;
begin
  // the big font: glyphs of 14 x 14 in an image of 256 x 256
  for LColor := 0 to High(Colors) do
  begin
    LTinted := TRadixFontTinter.Tint(TRadixFontData.DosFont, Colors[LColor], AContext.PaletteColors,
      FMatcher, nil);
    for LCode := 33 to 128 do
    begin
      LX := LCode mod 16;
      LY := LCode div 16;
      LGlyph := TRadixBitmapOps.Blt(LTinted, 256, LX * 16 + 1, LX * 16 + 14, LY * 16 + 2, LY * 16 + 15);
      AContext.Wad.AddLump(Format('DOSF%s%.3d', [Chr(Ord('A') + LColor), LCode]),
        AContext.Patches.FromColumns(LGlyph, 14, 14, False, 3, 1));
    end;
  end;

  // the small font: glyphs of 8 x 8 in an image of 128 x 128, rows turned to columns
  SetLength(LGlyph, 8 * 8);
  for LColor := 0 to High(Colors) do
  begin
    LTinted := TRadixFontTinter.Tint(TRadixFontData.SmallDosFont, Colors[LColor], AContext.PaletteColors,
      FMatcher, nil);
    for LCode := 33 to 128 do
    begin
      LX := (LCode - 1) mod 16;
      LY := (LCode - 1) div 16;
      for LRow := 0 to 7 do
      begin
        LPosition := LX * 8 + (LY * 8 + LRow) * 128;
        for LColumn := 0 to 7 do
        begin
          LGlyph[LColumn * 8 + LRow] := LTinted[LPosition];
          Inc(LPosition);
        end;
      end;
      AContext.Wad.AddLump(Format('DOSS%s%.3d', [Chr(Ord('A') + LColor), LCode]),
        AContext.Patches.FromColumns(Copy(LGlyph), 8, 8, False, 0, 0));
    end;
  end;
end;

end.
