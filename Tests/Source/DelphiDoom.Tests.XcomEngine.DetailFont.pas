{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomDetailFont (the characters of a font of the   }
{  system at the scale of the display, on the cells of the 320 x 200 pictures)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.DetailFont;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf,
  DelphiDoom.XcomSurface.FontOverlay.Intf, DelphiDoom.XcomSurface.FontDetail.Intf,
  DelphiDoom.XcomEngine.TrueColor.Intf, DelphiDoom.XcomEngine.RasterFontOverlay, DelphiDoom.XcomEngine.DetailFont,
  DelphiDoom.Tests.XcomSurface.FakeRasterizer, DelphiDoom.Tests.XcomEngine.FontFakes,
  DelphiDoom.Tests.XcomEngine.DetailFakes;

type
  /// <summary>
  ///   The font of the fixtures has cells of 6 x 8. At 320 x 200 the fake rasterizer draws rectangles of 3 x 5 from
  ///   the row 2 with the baseline at the row 7; at twice the size rectangles of 4 x 10 from the row 5 with the
  ///   baseline at 14, at three times 9 x 15 from the row 6 with the baseline at 21
  /// </summary>
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomDetailFont = class
  strict private
    FLog: TFontTestLog;
    FLogRef: IXcomLog;
    FSmall: TFakeGlyphRasterizer;
    FDouble: TFakeGlyphRasterizer;
    FTriple: TFakeGlyphRasterizer;
    FFactory: TFakeGlyphRasterizerFactory;
    FFactoryRef: IXcomGlyphRasterizerFactory;
    FDisplay: TFakeDetailDisplay;
    FDisplayRef: IXcomDetailLayers;
    FLayers: IXcomInkLayers;
    FFont: TXcomFont;
    procedure Apply(AOutline: TXcomGlyphOutline = goAuto);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure SenzaSchermoAColoriIlFontNonDovrebbeAvereDettaglio;
    [Test]
    procedure UnFontRifiutatoNonDovrebbeAvereDettaglio;
    [Test]
    procedure IlFontApplicatoDovrebbeAvereIlDettaglioConLaScalaDelloSchermo;
    [Test]
    procedure AScalaUnoNonDovrebbeDareCaratteri;
    [Test]
    procedure DovrebbeChiedereIlRasterizzatoreAllaScalaDelloSchermo;
    [Test]
    procedure IlCarattereDovrebbeStareSulleColonneDelCorpoESullaLineaDiBase;
    [Test]
    procedure ATreVolteDovrebbeUsareIlRasterizzatoreDiQuellaScala;
    [Test]
    procedure IlContornoDovrebbeAllargareIlRettangoloDiUnaScalaPerLato;
    [Test]
    procedure LaCoperturaDovrebbeRestareAlpha;
    [Test]
    procedure UnCarattereRimastoOriginaleNonDovrebbeAvereDettaglio;
    [Test]
    procedure UnCarattereCheIlFontNonHaAllaScalaNonDovrebbeAvereDettaglio;
    [Test]
    procedure DovrebbeDisegnareOgniCarattereUnaVoltaSola;
    [Test]
    procedure AlCambioDiScalaDovrebbeRiaprireIlFont;
    [Test]
    procedure SeIlFontNonSiApreAllaScalaDovrebbeAvvisareERipiegare;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
  end;

implementation

procedure TTestXcomDetailFont.Setup;
begin
  FLog := TFontTestLog.Create;
  FLogRef := FLog;
  FSmall := TFakeGlyphRasterizer.Create(3, 5, 2);
  FSmall.BaselineRow := 7;
  FDouble := TFakeGlyphRasterizer.Create(4, 10, 5);
  FDouble.BaselineRow := 14;
  FTriple := TFakeGlyphRasterizer.Create(9, 15, 6);
  FTriple.BaselineRow := 21;
  FFactory := TFakeGlyphRasterizerFactory.Create;
  FFactoryRef := FFactory;
  FFactory.Rasterizer := FSmall;
  FFactory.ByScale := [nil, FSmall, FDouble, FTriple];
  FDisplay := TFakeDetailDisplay.Create(2);
  FDisplayRef := FDisplay;
  FLayers := TFakeInkLayers.Create;
  FFont := TFontFixtures.Font('AB?');
end;

procedure TTestXcomDetailFont.TearDown;
begin
  FFont.Free;
  FLayers := nil;
  FDisplayRef := nil;
  FFactoryRef := nil;
  FLogRef := nil;
end;

procedure TTestXcomDetailFont.Apply(AOutline: TXcomGlyphOutline);
var
  LSettings: TXcomFontOverlaySettings;
  LOverlay: IXcomFontOverlay;
begin
  LSettings := TXcomFontOverlaySettings.Make('FONT_SMALL', 'Tahoma', 8);
  LSettings.Outline := AOutline;
  LOverlay := TXcomRasterFontOverlay.Create([LSettings], FFactoryRef, FLogRef, FDisplayRef, FLayers);
  LOverlay.Apply('FONT_SMALL', FFont);
end;

procedure TTestXcomDetailFont.SenzaSchermoAColoriIlFontNonDovrebbeAvereDettaglio;
var
  LOverlay: IXcomFontOverlay;
begin
  LOverlay := TXcomRasterFontOverlay.Create([TXcomFontOverlaySettings.Make('FONT_SMALL', 'Tahoma', 8)], FFactoryRef,
    FLogRef);
  LOverlay.Apply('FONT_SMALL', FFont);
  Assert.AreEqual(2, FFont.ImageCount);
  Assert.IsFalse(Assigned(FFont.Detail));
end;

procedure TTestXcomDetailFont.UnFontRifiutatoNonDovrebbeAvereDettaglio;
begin
  FSmall.DefaultHeight := 11;
  Apply;
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.IsFalse(Assigned(FFont.Detail));
end;

procedure TTestXcomDetailFont.IlFontApplicatoDovrebbeAvereIlDettaglioConLaScalaDelloSchermo;
begin
  Apply;
  Assert.IsTrue(Assigned(FFont.Detail));
  Assert.AreEqual(2, FFont.Detail.Scale);
  FDisplay.ScaleValue := 4;
  Assert.AreEqual(4, FFont.Detail.Scale);
  Assert.IsTrue(FFont.Detail.Layers = FLayers);
end;

procedure TTestXcomDetailFont.AScalaUnoNonDovrebbeDareCaratteri;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  FDisplay.ScaleValue := 1;
  Assert.IsFalse(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  // the font was opened once, for the pictures
  Assert.AreEqual(1, FFactory.Calls);
end;

procedure TTestXcomDetailFont.DovrebbeChiedereIlRasterizzatoreAllaScalaDelloSchermo;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  Assert.AreEqual(1, FFactory.LastScale);
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(2, FFactory.Calls);
  Assert.AreEqual(2, FFactory.LastScale);
  Assert.AreEqual('Tahoma', FFactory.LastFace.Name);
  Assert.AreEqual(8, FFactory.LastFace.Size);
end;

procedure TTestXcomDetailFont.IlCarattereDovrebbeStareSulleColonneDelCorpoESullaLineaDiBase;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(4, LGlyph.Width);
  Assert.AreEqual(10, LGlyph.Height);
  // the picture is 3 columns wide: at twice the size 6, and the 4 of the character are in the middle
  Assert.AreEqual(1, LGlyph.Left);
  // the baseline of the picture is 5 rows under the first row of the cell: 10 at twice the size; the character
  // starts 9 rows above its own baseline
  Assert.AreEqual(1, LGlyph.Top);
end;

procedure TTestXcomDetailFont.ATreVolteDovrebbeUsareIlRasterizzatoreDiQuellaScala;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  FDisplay.ScaleValue := 3;
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(9, LGlyph.Width);
  Assert.AreEqual(15, LGlyph.Height);
  Assert.AreEqual(0, LGlyph.Left);
  // 6 - 21 + 3 * 5
  Assert.AreEqual(0, LGlyph.Top);
end;

procedure TTestXcomDetailFont.IlContornoDovrebbeAllargareIlRettangoloDiUnaScalaPerLato;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply(goOn);
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(4 + 4, LGlyph.Width);
  Assert.AreEqual(10 + 4, LGlyph.Height);
  Assert.AreEqual(Integer(Length(LGlyph.Body)), Integer(Length(LGlyph.Outline)));
  // the picture has the outline in its first column and row: the body is one pixel in, two at twice the size;
  // the rectangle with the outline starts two pixels before the body, that is centered as without the outline
  Assert.AreEqual(1, LGlyph.Left);
  Assert.AreEqual(1, LGlyph.Top);
end;

procedure TTestXcomDetailFont.LaCoperturaDovrebbeRestareAlpha;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  FDouble.DefineRows(Ord('A'), 5, ['1359']);
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(1 * 255 div 9, Integer(LGlyph.Body[0]));
  Assert.AreEqual(3 * 255 div 9, Integer(LGlyph.Body[1]));
  Assert.AreEqual(255, Integer(LGlyph.Body[3]));
end;

procedure TTestXcomDetailFont.UnCarattereRimastoOriginaleNonDovrebbeAvereDettaglio;
var
  LGlyph: TXcomDetailGlyph;
begin
  FSmall.Remove(Ord('B'));
  Apply;
  // the font at twice the size would have it, but the text draws the picture of the game
  Assert.IsFalse(FFont.Detail.TryGetGlyph(Ord('B'), LGlyph));
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  // and a character the font of the game does not have at all
  Assert.IsFalse(FFont.Detail.TryGetGlyph(Ord('Z'), LGlyph));
end;

procedure TTestXcomDetailFont.UnCarattereCheIlFontNonHaAllaScalaNonDovrebbeAvereDettaglio;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  FDouble.Remove(Ord('A'));
  Assert.IsFalse(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('B'), LGlyph));
end;

procedure TTestXcomDetailFont.DovrebbeDisegnareOgniCarattereUnaVoltaSola;
var
  LGlyph: TXcomDetailGlyph;
  LSecond: TXcomDetailGlyph;
begin
  Apply;
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(1, FDouble.Rasterized);
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LSecond));
  Assert.AreEqual(1, FDouble.Rasterized);
  Assert.AreEqual(LGlyph.Width, LSecond.Width);
  Assert.AreEqual(2, FFactory.Calls);
end;

procedure TTestXcomDetailFont.AlCambioDiScalaDovrebbeRiaprireIlFont;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  FDisplay.ScaleValue := 3;
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(3, FFactory.Calls);
  Assert.AreEqual(3, FFactory.LastScale);
  Assert.AreEqual(9, LGlyph.Width);
  FDisplay.ScaleValue := 2;
  Assert.IsTrue(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.AreEqual(4, LGlyph.Width);
  Assert.AreEqual(2, FDouble.Rasterized);
end;

procedure TTestXcomDetailFont.SeIlFontNonSiApreAllaScalaDovrebbeAvvisareERipiegare;
var
  LGlyph: TXcomDetailGlyph;
begin
  Apply;
  FFactory.Rasterizer := nil;
  FFactory.ByScale := nil;
  FFactory.Reason := 'gone';
  Assert.IsFalse(FFont.Detail.TryGetGlyph(Ord('A'), LGlyph));
  Assert.IsFalse(FFont.Detail.TryGetGlyph(Ord('B'), LGlyph));
  // said once, not for every character
  Assert.AreEqual(1, FLog.Count('WARN', 'font "Tahoma" 8 at 2 times: gone'));
  Assert.AreEqual(2, FFactory.Calls);
end;

procedure TTestXcomDetailFont.DovrebbeRifiutareLeDipendenzeNil;
var
  LReport: TXcomFontOverlayReport;
  LFace: TXcomFontFace;
begin
  LReport := Default(TXcomFontOverlayReport);
  LFace := Default(TXcomFontFace);
  Assert.WillRaise(
    procedure
    begin
      TXcomDetailFont.Create(nil, LFace, LReport, FFactoryRef, FDisplayRef, FLayers, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomDetailFont.Create(FFont, LFace, LReport, nil, FDisplayRef, FLayers, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomDetailFont.Create(FFont, LFace, LReport, FFactoryRef, nil, FLayers, nil);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomDetailFont.Create(FFont, LFace, LReport, FFactoryRef, FDisplayRef, nil, nil);
    end, EArgumentNilException);
end;

end.
