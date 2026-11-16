{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBigFontPart                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateBigFonts of radix_xlat_wad.pas                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.BigFontPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf, DelphiDoom.Radix.Context;

type
  /// <summary>BIGFA, BIGFB and BIGFC (characters 33..128): the big font in three colors, with noise</summary>
  TRadixBigFontPart = class(TInterfacedObject, IRadixPart)
  strict private
    FMatcher: IColorMatcher;
  public
    /// <param name="AMatcher">Finds the nearest color of the palette; EArgumentNilException when nil</param>
    constructor Create(const AMatcher: IColorMatcher);
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.BitmapOps, DelphiDoom.Radix.FontData, DelphiDoom.Radix.FontTinter,
  DelphiDoom.Radix.PerlinNoise;

const
  GlyphWidth = 18;
  GlyphHeight = 21;
  StripHeight = 1984;
  Colors: array[0..2] of Cardinal = ($800000, $808080, $C47C0C);
  // the characters of the image in order (the star is twice: the first one is used)
  Characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+*/<>.,\[]|;:''"{}';

{ TRadixBigFontPart }

constructor TRadixBigFontPart.Create(const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FMatcher := AMatcher;
end;

procedure TRadixBigFontPart.Build(const AContext: TRadixTranslationContext);
var
  LGrey: TBytes;
  LTinted: TBytes;
  LGlyph: TBytes;
  LColor: Integer;
  LCode: Integer;
  LPosition: Integer;
  LWidth: Integer;
  LLast: Integer;
  LName: string;
begin
  LGrey := TRadixFontData.BigFont;
  for LColor := 0 to High(Colors) do
  begin
    LTinted := TRadixFontTinter.Tint(LGrey, Colors[LColor], AContext.PaletteColors, FMatcher,
      function(AIndex: Integer): Double
      begin
        Result := TRadixPerlinNoise.Value(AIndex mod StripHeight, AIndex div StripHeight);
      end);
    for LCode := 33 to 128 do
    begin
      LPosition := Pos(Chr(LCode), Characters);
      if LPosition > 0 then
      begin
        LGlyph := TRadixBitmapOps.Blt(LTinted, StripHeight, 0, GlyphWidth - 1,
          4 + (LPosition - 1) * GlyphHeight, 4 + (LPosition - 1) * GlyphHeight + GlyphHeight - 1);
        // right trim of the image
        LLast := GlyphWidth * GlyphHeight - 1;
        while LLast > 0 do
        begin
          if LGlyph[LLast] <> 254 then
            Break;
          Dec(LLast);
        end;
        if LLast < 16 * GlyphHeight then
        begin
          LWidth := (LLast div GlyphHeight) + 1;
          AContext.Wad.AddLump(Format('BIGF%s%.3d', [Chr(Ord('A') + LColor), LCode]),
            AContext.Patches.FromColumns(Copy(LGlyph, 0, LWidth * GlyphHeight), LWidth, GlyphHeight,
              False, 4, 1));
          Continue;
        end;
        AContext.Wad.AddLump(Format('BIGF%s%.3d', [Chr(Ord('A') + LColor), LCode]),
          AContext.Patches.FromColumns(LGlyph, GlyphWidth, GlyphHeight, False, 4, 1));
      end
      else
      begin
        // a character that is not in the font: a hole 5 columns wide
        SetLength(LGlyph, 5 * GlyphHeight);
        FillChar(LGlyph[0], Length(LGlyph), 254);
        LName := Format('BIGF%s%.3d', [Chr(Ord('A') + LColor), LCode]);
        AContext.Wad.AddLump(LName, AContext.Patches.FromColumns(LGlyph, 5, GlyphHeight, False, 4, 1));
      end;
    end;
  end;
end;

end.
