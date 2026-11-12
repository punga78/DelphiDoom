{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - the characters of a second   }
{  source laid over a font of the game                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.FontOverlayBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf,
  DelphiDoom.XcomSurface.FontOverlayBuilder, DelphiDoom.Tests.XcomSurface.FakeRasterizer;

type
  /// <summary>
  ///   The original font of the tests has cells of 6 x 8 in rows of four; the fake rasterizer draws every
  ///   character as a rectangle of 3 x 5 on the row 2, so with the tolerance of 25% the limits are 7 x 10
  /// </summary>
  [TestFixture]
  [Category('xcom-surface')]
  TTestXcomSurfaceFontOverlayBuilder = class(TObject)
  strict private
    FFont: TXcomFont;
    FRasterizer: TFakeGlyphRasterizer;
    FRasterizerRef: IXcomGlyphRasterizer;
    FBuilder: TXcomFontOverlayBuilder;
    FSettings: TXcomFontOverlaySettings;
    FReport: TXcomFontOverlayReport;
    procedure MakeFont(const AChars: string; AOutlined: Boolean; ASpacing: Integer = 1);
    procedure AddPage(const AChars: string; AWidth: Integer);
    function Apply: Boolean;
    function CharOf(ACode: Cardinal): TXcomFontChar;
    function MaxLevel(AImage: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAggiungereUnImmagineConICaratteriNuovi;
    [Test]
    procedure DovrebbeTenereAltezzaLarghezzaESpazioDelFontOriginale;
    [Test]
    procedure DovrebbeLasciareIlFontComeEraSeTroppoAlto;
    [Test]
    procedure DovrebbeLasciareIlFontComeEraSeLeLettereSonoTroppoLarghe;
    [Test]
    procedure DovrebbeAccettareUnFontPiuGrandeEntroLaTolleranza;
    [Test]
    procedure DovrebbeRifiutareSeMancanoICaratteriDiRiferimento;
    [Test]
    procedure DovrebbeTenereLOriginaleDiUnCarattereMancante;
    [Test]
    procedure DovrebbeTenereLOriginaleDiUnCarattereCopertoTroppoPoco;
    [Test]
    procedure DovrebbeTenereLOriginaleDiUnCarattereTroppoLargo;
    [Test]
    procedure DovrebbeRifilareOgniCarattereAlleColonneUsate;
    [Test]
    procedure DovrebbeUsareTuttaLaCellaSeIlFontEMonospazio;
    [Test]
    procedure DovrebbeMettereIlContornoSeLOriginaleLoHa;
    [Test]
    procedure DovrebbeNonMettereIlContornoSeLOriginaleNonLoHa;
    [Test]
    procedure DovrebbeSeguireLOpzioneDelContorno;
    [Test]
    procedure DovrebbeTogliereIlContornoSeLeOpzioniLoDicono;
    [Test]
    [TestCase('come l''originale', '0,1,1')]
    [TestCase('contorno aggiunto', '1,1,-1')]
    [TestCase('contorno tolto', '2,-1,1')]
    procedure DovrebbeDerivareLaSpaziaturaDallOriginale(AOutline, AOriginal, AExpected: Integer);
    [Test]
    procedure DovrebbeUsareLaSpaziaturaDelleOpzioni;
    [Test]
    procedure DovrebbeTagliareLeRigheFuoriDallaCella;
    [Test]
    procedure DovrebbeSpostareICaratteriInBassoConLOffset;
    [Test]
    procedure DovrebbeFareUnImmaginePerOgniImmagineOriginale;
    [Test]
    procedure DovrebbeNonContareGliSpaziComeCaratteri;
    [Test]
    procedure DovrebbeElencareICaratteriDiUnImmagineInOrdine;
    [Test]
    procedure DovrebbeRifiutareUnFontSenzaImmagini;
    [Test]
    procedure DovrebbeRifiutareUnRasterizzatoreNil;
  end;

implementation

const
  CELL_WIDTH = 6;
  CELL_HEIGHT = 8;
  COLUMNS = 4;

procedure TTestXcomSurfaceFontOverlayBuilder.Setup;
begin
  FFont := TXcomFont.Create;
  FRasterizer := TFakeGlyphRasterizer.Create(3, 5, 2);
  FRasterizerRef := FRasterizer;
  FBuilder := TXcomFontOverlayBuilder.Create;
  FSettings := TXcomFontOverlaySettings.Make('FONT_TEST', 'Fake', 8);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.TearDown;
begin
  FBuilder.Free;
  FRasterizerRef := nil;
  FFont.Free;
end;

procedure TTestXcomSurfaceFontOverlayBuilder.AddPage(const AChars: string; AWidth: Integer);
var
  LSurface: TXcomSurface;
  LCodes: TArray<Cardinal>;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
begin
  LCodes := TXcomFont.CodePoints(AChars);
  LSurface := TXcomSurface.Create(COLUMNS * AWidth, ((Length(LCodes) + COLUMNS - 1) div COLUMNS) * CELL_HEIGHT);
  // every cell: a body of 2 x 4 pixels of level 1
  for LIndex := 0 to High(LCodes) do
    for LY := 1 to 4 do
      for LX := 1 to 2 do
        LSurface.SetPixel(LIndex mod COLUMNS * AWidth + LX, LIndex div COLUMNS * CELL_HEIGHT + LY, 1);
  FFont.Init(FFont.AddImage(AWidth, CELL_HEIGHT, 0, LSurface), LCodes);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.MakeFont(const AChars: string; AOutlined: Boolean; ASpacing: Integer);
var
  LSurface: TXcomSurface;
  LCodes: TArray<Cardinal>;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
begin
  LCodes := TXcomFont.CodePoints(AChars);
  LSurface := TXcomSurface.Create(COLUMNS * CELL_WIDTH, ((Length(LCodes) + COLUMNS - 1) div COLUMNS) * CELL_HEIGHT);
  for LIndex := 0 to High(LCodes) do
  begin
    for LY := 1 to 4 do
      for LX := 1 to 2 do
        LSurface.SetPixel(LIndex mod COLUMNS * CELL_WIDTH + LX, LIndex div COLUMNS * CELL_HEIGHT + LY, 1);
    if AOutlined then
      LSurface.SetPixel(LIndex mod COLUMNS * CELL_WIDTH, LIndex div COLUMNS * CELL_HEIGHT + 1, 4);
  end;
  FFont.Init(FFont.AddImage(CELL_WIDTH, CELL_HEIGHT, ASpacing, LSurface), LCodes);
end;

function TTestXcomSurfaceFontOverlayBuilder.Apply: Boolean;
begin
  Result := FBuilder.Apply(FFont, FRasterizerRef, FSettings, FReport);
end;

function TTestXcomSurfaceFontOverlayBuilder.CharOf(ACode: Cardinal): TXcomFontChar;
begin
  Assert.IsTrue(FFont.TryGetChar(ACode, Result), 'the font lost a character');
end;

function TTestXcomSurfaceFontOverlayBuilder.MaxLevel(AImage: Integer): Integer;
var
  LPixel: Byte;
begin
  Result := 0;
  for LPixel in FFont.ImageSurface(AImage).Pixels do
    if LPixel > Result then
      Result := LPixel;
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeAggiungereUnImmagineConICaratteriNuovi;
begin
  MakeFont('AB?', False);
  Assert.IsTrue(Apply);
  Assert.AreEqual(Ord(frNone), Ord(FReport.Refusal));
  Assert.AreEqual(2, FFont.ImageCount);
  Assert.AreEqual(3, FReport.Replaced);
  Assert.AreEqual(0, FReport.Missing);
  Assert.AreEqual(1, CharOf(Ord('A')).ImageIndex);
  Assert.AreEqual(1, CharOf(Ord('?')).ImageIndex);
  // the cell is as large as the largest character and as tall as the reference characters
  Assert.AreEqual(3, FFont.Image(1).Width);
  Assert.AreEqual(5, FFont.Image(1).Height);
  Assert.AreEqual(5, FReport.Height);
  Assert.AreEqual(3, FReport.Width);
  Assert.AreEqual(1, Integer(FFont.GetChar(Ord('A')).GetPixel(0, 0)));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeTenereAltezzaLarghezzaESpazioDelFontOriginale;
var
  LSpace: TXcomRect;
begin
  MakeFont('AB?', False, 1);
  LSpace := FFont.GetCharSize(32);
  Assert.IsTrue(Apply);
  // the layout of the screens: the line and the space are the ones of the first picture
  Assert.AreEqual(CELL_WIDTH, FFont.Width);
  Assert.AreEqual(CELL_HEIGHT, FFont.Height);
  Assert.AreEqual(1, FFont.Spacing);
  Assert.AreEqual(Integer(LSpace.W), Integer(FFont.GetCharSize(32).W));
  Assert.AreEqual(Integer(LSpace.H), Integer(FFont.GetCharSize(10).H));
  // a character takes its own width plus the spacing of its picture
  Assert.AreEqual(4, Integer(FFont.GetCharSize(Ord('A')).W));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeLasciareIlFontComeEraSeTroppoAlto;
begin
  MakeFont('AB?', False);
  FRasterizer.DefaultHeight := 11;
  Assert.IsFalse(Apply);
  Assert.AreEqual(Ord(frTooTall), Ord(FReport.Refusal));
  Assert.AreEqual(11, FReport.Height);
  Assert.AreEqual(10, FReport.HeightLimit);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.AreEqual(0, CharOf(Ord('A')).ImageIndex);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeLasciareIlFontComeEraSeLeLettereSonoTroppoLarghe;
begin
  MakeFont('AB?', False);
  FRasterizer.Define(Ord('B'), 8, 5, 2);
  Assert.IsFalse(Apply);
  Assert.AreEqual(Ord(frTooWide), Ord(FReport.Refusal));
  Assert.AreEqual(8, FReport.Width);
  Assert.AreEqual(7, FReport.WidthLimit);
  Assert.AreEqual(1, FFont.ImageCount);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeAccettareUnFontPiuGrandeEntroLaTolleranza;
begin
  MakeFont('AB?', False);
  FRasterizer.DefaultHeight := 11;
  FRasterizer.DefaultWidth := 9;
  FSettings.Tolerance := 50;
  Assert.IsTrue(Apply);
  Assert.AreEqual(12, FReport.HeightLimit);
  Assert.AreEqual(9, FReport.WidthLimit);
  Assert.AreEqual(11, FFont.Image(1).Height);
  Assert.AreEqual(9, FFont.Image(1).Width);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeRifiutareSeMancanoICaratteriDiRiferimento;
begin
  MakeFont('AB', False);
  FRasterizer.Remove(Ord('A'));
  FRasterizer.Remove(Ord('B'));
  Assert.IsFalse(Apply);
  Assert.AreEqual(Ord(frNoGlyphs), Ord(FReport.Refusal));
  Assert.AreEqual(2, FReport.Missing);
  Assert.AreEqual(1, FFont.ImageCount);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeTenereLOriginaleDiUnCarattereMancante;
begin
  MakeFont('AB?', False);
  FRasterizer.Remove(Ord('B'));
  Assert.IsTrue(Apply);
  Assert.AreEqual(2, FReport.Replaced);
  Assert.AreEqual(1, FReport.Missing);
  Assert.AreEqual(0, CharOf(Ord('B')).ImageIndex);
  Assert.AreEqual(1, CharOf(Ord('A')).ImageIndex);
  // the original character is still the body of 2 pixels of its cell
  Assert.AreEqual(2, Integer(CharOf(Ord('B')).Rect.W));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeTenereLOriginaleDiUnCarattereCopertoTroppoPoco;
begin
  MakeFont('AB?', False);
  FRasterizer.Define(Ord('B'), 3, 5, 2, 40);
  Assert.IsTrue(Apply);
  Assert.AreEqual(1, FReport.Missing);
  Assert.AreEqual(0, CharOf(Ord('B')).ImageIndex);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeTenereLOriginaleDiUnCarattereTroppoLargo;
begin
  MakeFont('A#', False);
  // not a letter: it does not refuse the font, it only stays the original one
  FRasterizer.Define(Ord('#'), 9, 5, 2);
  Assert.IsTrue(Apply);
  Assert.AreEqual(1, FReport.TooWide);
  Assert.AreEqual(1, FReport.Replaced);
  Assert.AreEqual(0, CharOf(Ord('#')).ImageIndex);
  Assert.AreEqual(3, FFont.Image(1).Width);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeRifilareOgniCarattereAlleColonneUsate;
begin
  MakeFont('AB', False);
  FRasterizer.Define(Ord('A'), 2, 5, 2);
  Assert.IsTrue(Apply);
  Assert.AreEqual(2, Integer(CharOf(Ord('A')).Rect.W));
  Assert.AreEqual(3, Integer(CharOf(Ord('B')).Rect.W));
  Assert.AreEqual(5, Integer(CharOf(Ord('A')).Rect.H));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeUsareTuttaLaCellaSeIlFontEMonospazio;
begin
  FFont.Monospace := True;
  MakeFont('AB', False);
  FRasterizer.Define(Ord('A'), 2, 5, 2);
  Assert.IsTrue(Apply);
  Assert.AreEqual(3, Integer(CharOf(Ord('A')).Rect.W));
  Assert.AreEqual(3, Integer(CharOf(Ord('B')).Rect.W));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeMettereIlContornoSeLOriginaleLoHa;
begin
  MakeFont('AB', True);
  Assert.IsTrue(TXcomFontOverlayBuilder.IsOutlined(FFont));
  Assert.IsTrue(Apply);
  Assert.AreEqual(XCOM_GLYPH_LEVEL_CORNER, MaxLevel(1));
  // a pixel more on every side
  Assert.AreEqual(5, Integer(CharOf(Ord('A')).Rect.W));
  Assert.AreEqual(7, FFont.Image(1).Height);
  Assert.AreEqual(7, FReport.Height);
  Assert.AreEqual(5, FReport.Width);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeNonMettereIlContornoSeLOriginaleNonLoHa;
begin
  MakeFont('AB', False);
  Assert.IsFalse(TXcomFontOverlayBuilder.IsOutlined(FFont));
  Assert.IsTrue(Apply);
  Assert.AreEqual(1, MaxLevel(1));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeSeguireLOpzioneDelContorno;
begin
  MakeFont('AB', False);
  FSettings.Outline := goOn;
  Assert.IsTrue(Apply);
  Assert.AreEqual(XCOM_GLYPH_LEVEL_CORNER, MaxLevel(1));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeTogliereIlContornoSeLeOpzioniLoDicono;
begin
  MakeFont('AB', True);
  FSettings.Outline := goOff;
  Assert.IsTrue(Apply);
  Assert.AreEqual(1, MaxLevel(1));
  Assert.AreEqual(3, Integer(CharOf(Ord('A')).Rect.W));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeDerivareLaSpaziaturaDallOriginale(AOutline, AOriginal,
  AExpected: Integer);
begin
  // 0: as the original (not outlined), 1: outline added to a font without, 2: outline taken from a font with it
  MakeFont('AB', AOutline = 2, AOriginal);
  if AOutline = 1 then
    FSettings.Outline := goOn
  else if AOutline = 2 then
    FSettings.Outline := goOff;
  Assert.IsTrue(Apply);
  Assert.AreEqual(AExpected, FFont.Image(1).Spacing);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeUsareLaSpaziaturaDelleOpzioni;
begin
  MakeFont('AB', False, 1);
  FSettings.HasSpacing := True;
  FSettings.Spacing := 3;
  Assert.IsTrue(Apply);
  Assert.AreEqual(3, FFont.Image(1).Spacing);
  Assert.AreEqual(1, FFont.Spacing);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeTagliareLeRigheFuoriDallaCella;
var
  LGlyph: TXcomSurface;
  LRect: TXcomRect;
begin
  // an accented capital: two rows above the reference characters
  MakeFont('A' + Char($C9), False);
  FRasterizer.DefineRows($C9, 0, ['999', '000', '999', '999', '999', '999', '999']);
  Assert.IsTrue(Apply);
  Assert.AreEqual(1, FReport.Clipped);
  Assert.AreEqual(2, FReport.Replaced);
  Assert.AreEqual(5, FFont.Image(1).Height);
  LRect := CharOf($C9).Rect;
  LGlyph := FFont.GetChar($C9);
  // the row of the cell is the row 2 of the character
  Assert.AreEqual(1, Integer(LGlyph.GetPixel(LRect.X, LRect.Y)));
  Assert.AreEqual(5, Integer(LRect.H));
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeSpostareICaratteriInBassoConLOffset;
var
  LRect: TXcomRect;
begin
  MakeFont('A', False);
  FSettings.OffsetY := 1;
  Assert.IsTrue(Apply);
  LRect := CharOf(Ord('A')).Rect;
  Assert.AreEqual(0, Integer(FFont.ImageSurface(1).GetPixel(LRect.X, LRect.Y)));
  Assert.AreEqual(1, Integer(FFont.ImageSurface(1).GetPixel(LRect.X, LRect.Y + 1)));
  // the last row went out of the cell
  Assert.AreEqual(1, FReport.Clipped);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeFareUnImmaginePerOgniImmagineOriginale;
begin
  MakeFont('AB', False);
  // a second picture with wider cells: its characters may be wider (10 x 125% = 12)
  AddPage(Char($3042) + Char($3044), 10);
  FRasterizer.Define($3042, 12, 5, 2);
  FRasterizer.Define($3044, 13, 5, 2);
  Assert.IsTrue(Apply);
  Assert.AreEqual(4, FFont.ImageCount);
  Assert.AreEqual(2, CharOf(Ord('A')).ImageIndex);
  Assert.AreEqual(3, CharOf($3042).ImageIndex);
  Assert.AreEqual(12, FFont.Image(3).Width);
  // one pixel too wide for its picture
  Assert.AreEqual(1, CharOf($3044).ImageIndex);
  Assert.AreEqual(1, FReport.TooWide);
  Assert.AreEqual(3, FReport.Replaced);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeNonContareGliSpaziComeCaratteri;
begin
  // the line feed that ends the list of the characters of Font.dat takes a cell in the original picture
  MakeFont('AB'#10, False);
  Assert.IsTrue(Apply);
  Assert.AreEqual(2, FReport.Replaced);
  Assert.AreEqual(0, FReport.Missing);
  Assert.AreEqual(0, CharOf(10).ImageIndex);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeElencareICaratteriDiUnImmagineInOrdine;
var
  LCodes: TArray<Cardinal>;
begin
  MakeFont('BA?', False);
  LCodes := FFont.CodesOfImage(0);
  Assert.AreEqual(3, Integer(Length(LCodes)));
  Assert.AreEqual(Ord('?'), Integer(LCodes[0]));
  Assert.AreEqual(Ord('A'), Integer(LCodes[1]));
  Assert.AreEqual(Ord('B'), Integer(LCodes[2]));
  Assert.AreEqual(0, Integer(Length(FFont.CodesOfImage(1))));
  Assert.AreEqual(CELL_WIDTH, FFont.Image(0).Width);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeRifiutareUnFontSenzaImmagini;
begin
  Assert.WillRaise(
    procedure
    begin
      Apply;
    end, EXcomSurfaceException);
end;

procedure TTestXcomSurfaceFontOverlayBuilder.DovrebbeRifiutareUnRasterizzatoreNil;
begin
  MakeFont('A', False);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Apply(FFont, nil, FSettings, FReport);
    end, EArgumentNilException);
end;

end.
