{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the font metrics                                  }
{                                                                              }
{  Port of war1 (acoto87/war1), getFontData and getCharIndex of war_font.c,    }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Font.Metrics;

interface

uses
  System.SysUtils, DelphiDoom.War.Font.Types, DelphiDoom.War.Font.Intf;

type
  /// <summary>The glyph tables are given to the constructor, so a test can give its own</summary>
  TWarFontMetrics = class(TInterfacedObject, IWarFontMetrics)
  strict private
    FFonts: TArray<TWarFontData>;
  public
    constructor Create(const AFonts: TArray<TWarFontData>);
    function GetFontCount: Integer;
    function TryGetFont(AFont: Integer; out AData: TWarFontData): Boolean;
    function GlyphIndex(AChar: AnsiChar): Integer;
    function TryGetGlyph(AFont: Integer; AChar: AnsiChar; out AGlyph: TWarGlyph): Boolean;
  end;

implementation

{ TWarFontMetrics }

constructor TWarFontMetrics.Create(const AFonts: TArray<TWarFontData>);
begin
  inherited Create;
  FFonts := Copy(AFonts);
end;

function TWarFontMetrics.GetFontCount: Integer;
begin
  Result := Length(FFonts);
end;

function TWarFontMetrics.TryGetFont(AFont: Integer; out AData: TWarFontData): Boolean;
begin
  Result := (AFont >= 0) and (AFont < Length(FFonts));
  if Result then
    AData := FFonts[AFont]
  else
    AData := Default(TWarFontData);
end;

function TWarFontMetrics.GlyphIndex(AChar: AnsiChar): Integer;
var
  LSigned: Integer;
begin
  // char of the original has a sign: from 128 up it is negative, and a character <= 0 is the glyph 0
  LSigned := ShortInt(Byte(AChar));
  if LSigned > 0 then
    Result := LSigned - 32
  else
    Result := 0;
end;

function TWarFontMetrics.TryGetGlyph(AFont: Integer; AChar: AnsiChar; out AGlyph: TWarGlyph): Boolean;
var
  LIndex: Integer;
begin
  AGlyph := Default(TWarGlyph);
  LIndex := GlyphIndex(AChar);
  Result := (AFont >= 0) and (AFont < Length(FFonts)) and (LIndex >= 0) and (LIndex < WAR_FONT_GLYPH_COUNT);
  if Result then
    AGlyph := FFonts[AFont].Glyphs[LIndex];
end;

end.
