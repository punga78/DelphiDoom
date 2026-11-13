{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the font metrics                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.Font;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Font.Types, DelphiDoom.War.Font.Intf;

type
  [TestFixture]
  [Category('war')]
  TTestWarFontMetrics = class(TObject)
  private
    FMetrics: IWarFontMetrics;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereDueFont;
    [Test]
    procedure DovrebbeDareLeDimensioniDelPrimoFont;
    [Test]
    procedure DovrebbeDareLeDimensioniDelSecondoFont;
    [Test]
    procedure DovrebbeRifiutareUnFontCheNonCe;
    [Test]
    procedure DovrebbeDareLIndiceDelGlifoDeiCaratteriStampabili;
    [Test]
    procedure DovrebbeDareIlGlifoZeroPerLoSpazioEPerIlByteZero;
    [Test]
    procedure DovrebbeDareIlGlifoZeroPerICaratteriDa128InSu;
    [Test]
    procedure DovrebbeDareUnIndiceFuoriTabellaPerIControlloEIlDel;
    [Test]
    procedure DovrebbeTrovareIlGlifoDiUnaLettera;
    [Test]
    procedure DovrebbeTrovareIlGlifoDellUltimoCarattere;
    [Test]
    procedure DovrebbeNonTrovareUnGlifoPerUnControlloUnDelOUnFontCheNonCe;
    [Test]
    procedure DovrebbeUguagliareLaTabellaDelCodiceOriginale;
    [Test]
    procedure DovrebbeUsareLaTabellaDataAlCostruttore;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.War.Factory, DelphiDoom.War.Font.Metrics, DelphiDoom.Tests.War.RealData;

{ TTestWarFontMetrics }

procedure TTestWarFontMetrics.Setup;
begin
  FMetrics := TWarFactory.CreateFontMetrics;
end;

procedure TTestWarFontMetrics.DovrebbeAvereDueFont;
begin
  Assert.AreEqual(2, FMetrics.FontCount);
end;

procedure TTestWarFontMetrics.DovrebbeDareLeDimensioniDelPrimoFont;
var
  LFont: TWarFontData;
begin
  Assert.IsTrue(FMetrics.TryGetFont(0, LFont));
  Assert.AreEqual(512, LFont.SpriteWidth);
  Assert.AreEqual(512, LFont.SpriteHeight);
  Assert.AreEqual(48, LFont.LineHeight);
  Assert.AreEqual(8, LFont.Advance);
end;

procedure TTestWarFontMetrics.DovrebbeDareLeDimensioniDelSecondoFont;
var
  LFont: TWarFontData;
begin
  Assert.IsTrue(FMetrics.TryGetFont(1, LFont));
  Assert.AreEqual(768, LFont.SpriteHeight);
  Assert.AreEqual(80, LFont.LineHeight);
end;

procedure TTestWarFontMetrics.DovrebbeRifiutareUnFontCheNonCe;
var
  LFont: TWarFontData;
begin
  Assert.IsFalse(FMetrics.TryGetFont(2, LFont));
  Assert.IsFalse(FMetrics.TryGetFont(-1, LFont));
  Assert.AreEqual(0, LFont.LineHeight);
end;

procedure TTestWarFontMetrics.DovrebbeDareLIndiceDelGlifoDeiCaratteriStampabili;
begin
  Assert.AreEqual(33, FMetrics.GlyphIndex('A'));
  Assert.AreEqual(1, FMetrics.GlyphIndex('!'));
  Assert.AreEqual(94, FMetrics.GlyphIndex('~'));
end;

procedure TTestWarFontMetrics.DovrebbeDareIlGlifoZeroPerLoSpazioEPerIlByteZero;
begin
  Assert.AreEqual(0, FMetrics.GlyphIndex(' '));
  Assert.AreEqual(0, FMetrics.GlyphIndex(#0));
end;

procedure TTestWarFontMetrics.DovrebbeDareIlGlifoZeroPerICaratteriDa128InSu;
begin
  // char ha il segno nel remake: da 128 in su e' negativo
  Assert.AreEqual(0, FMetrics.GlyphIndex(#128));
  Assert.AreEqual(0, FMetrics.GlyphIndex(#255));
end;

procedure TTestWarFontMetrics.DovrebbeDareUnIndiceFuoriTabellaPerIControlloEIlDel;
begin
  // il remake leggeva la tabella prima e dopo i suoi limiti
  Assert.AreEqual(-22, FMetrics.GlyphIndex(#10));
  Assert.AreEqual(95, FMetrics.GlyphIndex(#127));
end;

procedure TTestWarFontMetrics.DovrebbeTrovareIlGlifoDiUnaLettera;
var
  LGlyph: TWarGlyph;
begin
  Assert.IsTrue(FMetrics.TryGetGlyph(0, 'A', LGlyph));
  Assert.AreEqual(184, Integer(LGlyph.X));
  Assert.AreEqual(96, Integer(LGlyph.Y));
  Assert.AreEqual(40, Integer(LGlyph.Width));
  Assert.AreEqual(48, Integer(LGlyph.Height));
end;

procedure TTestWarFontMetrics.DovrebbeTrovareIlGlifoDellUltimoCarattere;
var
  LGlyph: TWarGlyph;
begin
  Assert.IsTrue(FMetrics.TryGetGlyph(1, '~', LGlyph));
  Assert.AreEqual(80, Integer(LGlyph.X));
  Assert.AreEqual(640, Integer(LGlyph.Y));
  Assert.AreEqual(56, Integer(LGlyph.Width));
  Assert.AreEqual(80, Integer(LGlyph.Height));
end;

procedure TTestWarFontMetrics.DovrebbeNonTrovareUnGlifoPerUnControlloUnDelOUnFontCheNonCe;
var
  LGlyph: TWarGlyph;
begin
  Assert.IsFalse(FMetrics.TryGetGlyph(0, #10, LGlyph));
  Assert.IsFalse(FMetrics.TryGetGlyph(0, #127, LGlyph));
  Assert.IsFalse(FMetrics.TryGetGlyph(2, 'A', LGlyph));
  Assert.IsFalse(FMetrics.TryGetGlyph(-1, 'A', LGlyph));
  Assert.AreEqual(0, Integer(LGlyph.Width));
end;

procedure TTestWarFontMetrics.DovrebbeUguagliareLaTabellaDelCodiceOriginale;
var
  LGolden: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LFont: TWarFontData;
  LGlyphCount: Integer;
begin
  // fonts.golden.txt: la tabella fontsData[] di war_font.c stampata dal C originale compilato (Tools\Verifica\192)
  LGolden := TStringList.Create;
  try
    LGolden.LoadFromFile(TWarRealData.GoldenPath('fonts.golden.txt'));
    LGlyphCount := 0;
    for LLine in LGolden do
    begin
      LParts := LLine.Split([' ']);
      if LParts[0] = 'F' then
      begin
        Assert.IsTrue(FMetrics.TryGetFont(StrToInt(LParts[1]), LFont));
        Assert.AreEqual(StrToInt(LParts[2]), LFont.SpriteWidth, LLine);
        Assert.AreEqual(StrToInt(LParts[3]), LFont.SpriteHeight, LLine);
        Assert.AreEqual(StrToInt(LParts[4]), LFont.LineHeight, LLine);
        Assert.AreEqual(StrToInt(LParts[5]), LFont.Advance, LLine);
      end
      else if LParts[0] = 'G' then
      begin
        Assert.IsTrue(FMetrics.TryGetFont(StrToInt(LParts[1]), LFont));
        Assert.AreEqual(StrToInt(LParts[3]), Integer(LFont.Glyphs[StrToInt(LParts[2])].X), LLine);
        Assert.AreEqual(StrToInt(LParts[4]), Integer(LFont.Glyphs[StrToInt(LParts[2])].Y), LLine);
        Assert.AreEqual(StrToInt(LParts[5]), Integer(LFont.Glyphs[StrToInt(LParts[2])].Width), LLine);
        Assert.AreEqual(StrToInt(LParts[6]), Integer(LFont.Glyphs[StrToInt(LParts[2])].Height), LLine);
        Inc(LGlyphCount);
      end;
    end;
    Assert.AreEqual(190, LGlyphCount);
  finally
    LGolden.Free;
  end;
end;

procedure TTestWarFontMetrics.DovrebbeUsareLaTabellaDataAlCostruttore;
var
  LFonts: TArray<TWarFontData>;
  LMetrics: IWarFontMetrics;
  LGlyph: TWarGlyph;
begin
  SetLength(LFonts, 1);
  LFonts[0].LineHeight := 7;
  LFonts[0].Glyphs[1].X := 99;
  LMetrics := TWarFontMetrics.Create(LFonts);
  Assert.AreEqual(1, LMetrics.FontCount);
  Assert.IsTrue(LMetrics.TryGetGlyph(0, '!', LGlyph));
  Assert.AreEqual(99, Integer(LGlyph.X));
  Assert.IsFalse(LMetrics.TryGetGlyph(1, '!', LGlyph));
end;

end.
