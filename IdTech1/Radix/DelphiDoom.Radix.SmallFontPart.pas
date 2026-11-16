{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSmallFontPart                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateSmallFont of radix_xlat_wad.pas                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SmallFontPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   The small font of the menus: the lump "SmallFont" is a strip of 368 x 6 pixels (by
  ///   columns, 5 columns for a letter) that becomes the patch SMALLFNT and a patch FNTAnnn for
  ///   every character from 33 to 128 (a blank one for the characters the strip does not have,
  ///   none for % ( ) * + # / &lt; = &gt;)
  /// </summary>
  TRadixSmallFontPart = class(TInterfacedObject, IRadixPart)
  public
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

const
  SmallFontLength = 2222;
  StripWidth = 368;
  GlyphWidth = 5;
  GlyphHeight = 6;
  // the characters of the strip, in order (a space is a character that is not in the font)
  StripCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.?[]!:;"`,-0123456789_';
  // the characters that have no glyph at all
  SkippedCharacters = '%()*+#/<=>';
  Hole = 254;

{ TRadixSmallFontPart }

procedure TRadixSmallFontPart.Build(const AContext: TRadixTranslationContext);
var
  LLump: TBytes;
  LStrip: TBytes;
  LGlyph: TBytes;
  LCharacters: string;
  LCode: Integer;
  LPosition: Integer;
  LIndex: Integer;
  LName: string;
begin
  if not AContext.Container.TryRead('SmallFont', LLump) then
    Exit;
  if Length(LLump) <> SmallFontLength then
    Exit;
  // the last letter (the underscore) takes its 4th column one past the strip: the 6 bytes that
  // follow it in the lump, which keep their colors (only the strip is cleaned)
  LStrip := Copy(LLump, 8, StripWidth * GlyphHeight + GlyphHeight);
  for LIndex := 0 to StripWidth * GlyphHeight - 1 do
    if LStrip[LIndex] in [0, 1, 6, 28] then
      LStrip[LIndex] := Hole;
  AContext.Wad.AddLump('SMALLFNT', AContext.Patches.FromColumns(LStrip, StripWidth, GlyphHeight, False, 0, 0));

  SetLength(LGlyph, GlyphWidth * GlyphHeight);
  FillChar(LGlyph[0], Length(LGlyph), Hole);
  LCharacters := StripCharacters;
  for LCode := 33 to 128 do
  begin
    LPosition := 0;
    for LIndex := 1 to Length(LCharacters) do
      if (LCharacters[LIndex] <> ' ') and (Ord(LCharacters[LIndex]) = LCode) then
      begin
        LPosition := LIndex;
        Break;
      end;
    LName := 'FNTA' + Format('%.3d', [LCode]);
    if LPosition > 0 then
    begin
      // 4 columns of the strip; the fifth column of the glyph stays a hole
      Move(LStrip[(LPosition - 1) * GlyphWidth * GlyphHeight], LGlyph[0], (GlyphWidth - 1) * GlyphHeight);
      for LIndex := 0 to High(LGlyph) do
        if LGlyph[LIndex] = 0 then
          LGlyph[LIndex] := Hole;
      AContext.Wad.AddLump(LName, AContext.Patches.FromColumns(LGlyph, GlyphWidth, GlyphHeight, False, 0, 0));
      LCharacters[LPosition] := ' ';
    end
    else if Pos(Chr(LCode), SkippedCharacters) = 0 then
    begin
      FillChar(LGlyph[0], Length(LGlyph), Hole);
      AContext.Wad.AddLump(LName, AContext.Patches.FromColumns(LGlyph, GlyphWidth, GlyphHeight, False, 0, 0));
    end;
  end;
end;

end.
