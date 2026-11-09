{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the font data and of the steps of the big fonts, the   }
{  DOS fonts and TRN_MENU (TRadixFontData, TRadixPerlinNoise, TRadixFontTinter,}
{  TRadixBigFontPart, TRadixDosFontPart, TRadixMenuTranslationPart)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.FontParts;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.GameData.Intf, DelphiDoom.Palette.Intf, DelphiDoom.Palette.Factory,
  DelphiDoom.Radix.Context, DelphiDoom.Radix.FontData, DelphiDoom.Radix.PerlinNoise, DelphiDoom.Radix.FontTinter,
  DelphiDoom.Radix.BigFontPart, DelphiDoom.Radix.DosFontPart, DelphiDoom.Radix.MenuTranslationPart,
  DelphiDoom.Tests.Radix.DatBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixFontParts = class(TObject)
  strict private
    FMatcher: IColorMatcher;
    FPalette: TBytes;
    FColors: TArray<Cardinal>;
    function Run(const APart: IRadixPart): IGameWadComposer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLeTreImmaginiDeiFontDellaDimensioneGiusta;
    [Test]
    procedure DovrebbeTrovareIlPrimoPixelDelFontDos;
    [Test]
    procedure DovrebbeDareLoStessoRumoreAOgniChiamata;
    [Test]
    procedure DovrebbeTenereIlRumoreNelCampoPrevisto;
    [Test]
    procedure DovrebbeFareUnBucoDelPixelACero;
    [Test]
    procedure DovrebbeFareUnBucoDelColoreNero;
    [Test]
    procedure DovrebbeUsareIlRumoreSoloSuiPixelAl255;
    [Test]
    procedure DovrebbeScrivereTreFontGrandiDaTrentatreACentoventotto;
    [Test]
    procedure DovrebbeFareUnaLetteraVuotaDi5ColonneSeIlCarattereNonCe;
    [Test]
    procedure DovrebbeScrivereLeLettereDelFontDosGrandeEPiccoloInDueColori;
    [Test]
    procedure DovrebbeFareLeLettereDosGrandiDi14x14ELePiccoleDi8x8;
    [Test]
    procedure DovrebbeFareLaTabellaDelMenu;
    [Test]
    procedure DovrebbeDareErroreSenzaIlRicercatoreDiColori;
  end;

implementation

{ TTestRadixFontParts }

procedure TTestRadixFontParts.Setup;
var
  LIndex: Integer;
begin
  FMatcher := TPaletteFactory.CreateColorMatcher;
  SetLength(FPalette, 768);
  SetLength(FColors, 256);
  for LIndex := 0 to 255 do
  begin
    FPalette[LIndex * 3] := LIndex;
    FPalette[LIndex * 3 + 1] := LIndex;
    FPalette[LIndex * 3 + 2] := LIndex;
    FColors[LIndex] := Cardinal(LIndex) * $010101;
  end;
end;

function TTestRadixFontParts.Run(const APart: IRadixPart): IGameWadComposer;
var
  LBuilder: TRadixDatBuilder;
  LAliases: TArray<string>;
begin
  LBuilder := TRadixDatBuilder.Create;
  try
    LBuilder.Add('Unused', TBytes.Create(1));
    Result := TRadixPartRunner.Run(APart, LBuilder.ToBytes, FPalette, LAliases);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestRadixFontParts.DovrebbeDareLeTreImmaginiDeiFontDellaDimensioneGiusta;
begin
  Assert.AreEqual(65536, Length(TRadixFontData.DosFont));
  Assert.AreEqual(16384, Length(TRadixFontData.SmallDosFont));
  Assert.AreEqual(35712, Length(TRadixFontData.BigFont));
end;

procedure TTestRadixFontParts.DovrebbeTrovareIlPrimoPixelDelFontDos;
var
  LFont: TBytes;
  LIndex: Integer;
begin
  LFont := TRadixFontData.DosFont;
  LIndex := 0;
  while LFont[LIndex] = 0 do
    Inc(LIndex);
  // the first lit pixel of the image of the original: row 20, column 6, value 16
  Assert.AreEqual(20 * 16 + 6, LIndex);
  Assert.AreEqual(16, Integer(LFont[LIndex]));
end;

procedure TTestRadixFontParts.DovrebbeDareLoStessoRumoreAOgniChiamata;
begin
  Assert.AreEqual(TRadixPerlinNoise.Value(100, 7), TRadixPerlinNoise.Value(100, 7), 0.0);
end;

procedure TTestRadixFontParts.DovrebbeTenereIlRumoreNelCampoPrevisto;
var
  LX: Integer;
  LY: Integer;
begin
  // each octave is a smoothed noise in -1..1 times 0.5^n: the sum is below 1.75, times 16
  for LX := 0 to 40 do
    for LY := 0 to 20 do
      Assert.IsTrue(Abs(TRadixPerlinNoise.Value(LX * 13, LY)) <= 28.0);
end;

procedure TTestRadixFontParts.DovrebbeFareUnBucoDelPixelACero;
var
  LTinted: TBytes;
begin
  LTinted := TRadixFontTinter.Tint(TBytes.Create(0, 128), $FFFFFF, FColors, FMatcher, nil);
  Assert.AreEqual(254, Integer(LTinted[0]));
  Assert.AreEqual(128, Integer(LTinted[1]));
end;

procedure TTestRadixFontParts.DovrebbeFareUnBucoDelColoreNero;
var
  LTinted: TBytes;
begin
  // the color of the pixel is black: the palette has black at 0, that is a hole too
  LTinted := TRadixFontTinter.Tint(TBytes.Create(1), $000000, FColors, FMatcher, nil);
  Assert.AreEqual(254, Integer(LTinted[0]));
end;

procedure TTestRadixFontParts.DovrebbeUsareIlRumoreSoloSuiPixelAl255;
var
  LTinted: TBytes;
begin
  LTinted := TRadixFontTinter.Tint(TBytes.Create(255, 128), $808080, FColors, FMatcher,
    function(AIndex: Integer): Double
    begin
      Result := 10.0;
    end);
  // 0x80 * 255 / 256 = 127.5, plus 10: rounded to 138; the other pixel has no noise: 64
  Assert.AreEqual(138, Integer(LTinted[0]));
  Assert.AreEqual(64, Integer(LTinted[1]));
end;

procedure TTestRadixFontParts.DovrebbeScrivereTreFontGrandiDaTrentatreACentoventotto;
var
  LWad: IGameWadComposer;
begin
  LWad := Run(TRadixBigFontPart.Create(FMatcher));
  Assert.AreEqual(3 * 96, LWad.Count);
  Assert.IsTrue(LWad.IndexOf('BIGFA033') >= 0);
  Assert.IsTrue(LWad.IndexOf('BIGFB065') >= 0);
  Assert.IsTrue(LWad.IndexOf('BIGFC128') >= 0);
end;

procedure TTestRadixFontParts.DovrebbeFareUnaLetteraVuotaDi5ColonneSeIlCarattereNonCe;
var
  LGlyph: TBytes;
begin
  // 128 is not a character of the font
  LGlyph := Run(TRadixBigFontPart.Create(FMatcher)).LumpData[95];
  Assert.AreEqual(5, Integer(PSmallInt(@LGlyph[0])^));
  Assert.AreEqual(21, Integer(PSmallInt(@LGlyph[2])^));
end;

procedure TTestRadixFontParts.DovrebbeScrivereLeLettereDelFontDosGrandeEPiccoloInDueColori;
var
  LWad: IGameWadComposer;
begin
  LWad := Run(TRadixDosFontPart.Create(FMatcher));
  Assert.AreEqual(4 * 96, LWad.Count);
  Assert.IsTrue(LWad.IndexOf('DOSFA033') >= 0);
  Assert.IsTrue(LWad.IndexOf('DOSFB128') >= 0);
  Assert.IsTrue(LWad.IndexOf('DOSSA033') >= 0);
  Assert.IsTrue(LWad.IndexOf('DOSSB128') >= 0);
end;

procedure TTestRadixFontParts.DovrebbeFareLeLettereDosGrandiDi14x14ELePiccoleDi8x8;
var
  LWad: IGameWadComposer;
  LLarge: TBytes;
  LSmall: TBytes;
begin
  LWad := Run(TRadixDosFontPart.Create(FMatcher));
  LLarge := LWad.LumpData[LWad.IndexOf('DOSFA065')];
  LSmall := LWad.LumpData[LWad.IndexOf('DOSSA065')];
  Assert.AreEqual(14, Integer(PSmallInt(@LLarge[0])^));
  Assert.AreEqual(14, Integer(PSmallInt(@LLarge[2])^));
  Assert.AreEqual(8, Integer(PSmallInt(@LSmall[0])^));
  Assert.AreEqual(8, Integer(PSmallInt(@LSmall[2])^));
end;

procedure TTestRadixFontParts.DovrebbeFareLaTabellaDelMenu;
var
  LTable: TBytes;
  LWad: IGameWadComposer;
begin
  LWad := Run(TRadixMenuTranslationPart.Create);
  LTable := LWad.LumpData[LWad.IndexOf('TRN_MENU')];
  Assert.AreEqual(256, Length(LTable));
  Assert.AreEqual(207, Integer(LTable[207]));
  Assert.AreEqual(128, Integer(LTable[208]));
  Assert.AreEqual(143, Integer(LTable[223]));
  Assert.AreEqual(224, Integer(LTable[224]));
end;

procedure TTestRadixFontParts.DovrebbeDareErroreSenzaIlRicercatoreDiColori;
begin
  Assert.WillRaise(
    procedure
    begin
      TRadixBigFontPart.Create(nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TRadixDosFontPart.Create(nil);
    end, EArgumentNilException);
end;

end.

