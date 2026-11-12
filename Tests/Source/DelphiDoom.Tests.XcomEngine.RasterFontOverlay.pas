{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomRasterFontOverlay (which font of the game     }
{  takes the characters of a font of the system, and the fallbacks)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.RasterFontOverlay;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomSurface.Font,
  DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf,
  DelphiDoom.XcomSurface.FontOverlay.Intf, DelphiDoom.XcomEngine.RasterFontOverlay,
  DelphiDoom.Tests.XcomSurface.FakeRasterizer, DelphiDoom.Tests.XcomEngine.FontFakes;

type
  /// <summary>
  ///   The font of the fixtures has cells of 6 x 8 and the fake rasterizer draws rectangles of 3 x 5: with the
  ///   default tolerance a font fits up to 8 x 10
  /// </summary>
  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomRasterFontOverlay = class
  strict private
    FLog: TFontTestLog;
    FLogRef: IXcomLog;
    FRasterizer: TFakeGlyphRasterizer;
    FFactory: TFakeGlyphRasterizerFactory;
    FFactoryRef: IXcomGlyphRasterizerFactory;
    FFont: TXcomFont;
    function Overlay(const ASettings: TArray<TXcomFontOverlaySettings>): IXcomFontOverlay;
    function Small(const AName: string = 'Tahoma'; ASize: Integer = 8): TXcomFontOverlaySettings;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLasciareLeImmaginiAiFontNonElencati;
    [Test]
    procedure DovrebbeMettereICaratteriDelFontDiSistemaNelFontElencato;
    [Test]
    procedure DovrebbeChiedereIlFontDelleOpzioniAScalaUno;
    [Test]
    procedure DovrebbeRiconoscereLIdSenzaGuardareLeMaiuscole;
    [Test]
    procedure DovrebbeUsareLUltimaVoceDiUnFontScrittoDueVolte;
    [Test]
    procedure DovrebbeRipiegareSullOriginaleSeIlFontNonEsiste;
    [Test]
    procedure DovrebbeRipiegareSullOriginaleSeIlFontETroppoAlto;
    [Test]
    procedure DovrebbeRipiegareSullOriginaleSeIlFontETroppoLargo;
    [Test]
    procedure DovrebbeRipiegareSullOriginaleSeIlFontNonHaICaratteri;
    [Test]
    procedure DovrebbeAvvisareDeiCaratteriRimastiOriginali;
    [Test]
    procedure ConLaRiduzioneDovrebbeProvareMisurePiuPiccoleFinoAEntrare;
    [Test]
    procedure ConLaRiduzioneNonDovrebbeScendereSottoLaMisuraMinima;
    [Test]
    procedure SenzaLaRiduzioneUnFontTroppoAltoDovrebbeEssereChiestoUnaVolta;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
    [Test]
    procedure DovrebbeRifiutareUnaFabbricaNil;
  end;

implementation

procedure TTestXcomRasterFontOverlay.Setup;
begin
  FLog := TFontTestLog.Create;
  FLogRef := FLog;
  FRasterizer := TFakeGlyphRasterizer.Create(3, 5, 2);
  FFactory := TFakeGlyphRasterizerFactory.Create;
  FFactoryRef := FFactory;
  FFactory.Rasterizer := FRasterizer;
  FFont := TFontFixtures.Font('AB?');
end;

procedure TTestXcomRasterFontOverlay.TearDown;
begin
  FFont.Free;
  FFactoryRef := nil;
  FLogRef := nil;
end;

function TTestXcomRasterFontOverlay.Overlay(const ASettings: TArray<TXcomFontOverlaySettings>): IXcomFontOverlay;
begin
  Result := TXcomRasterFontOverlay.Create(ASettings, FFactoryRef, FLogRef);
end;

function TTestXcomRasterFontOverlay.Small(const AName: string; ASize: Integer): TXcomFontOverlaySettings;
begin
  Result := TXcomFontOverlaySettings.Make('FONT_SMALL', AName, ASize);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeLasciareLeImmaginiAiFontNonElencati;
begin
  Overlay([Small]).Apply('FONT_BIG', FFont);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.AreEqual(0, FFactory.Calls);
  Assert.AreEqual(0, FLog.Lines.Count);
  // and without any font in the options
  Overlay(nil).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFont.ImageCount);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeMettereICaratteriDelFontDiSistemaNelFontElencato;
var
  LChar: TXcomFontChar;
begin
  Overlay([Small]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(2, FFont.ImageCount);
  Assert.IsTrue(FFont.TryGetChar(Ord('A'), LChar));
  Assert.AreEqual(1, LChar.ImageIndex);
  Assert.AreEqual(3, Integer(LChar.Rect.W));
  Assert.AreEqual(1, FLog.Count('INFO', 'font FONT_SMALL: "Tahoma" 8, 3 characters (3 x 5)'));
  Assert.AreEqual(0, FLog.Count('WARN', ''));
end;

procedure TTestXcomRasterFontOverlay.DovrebbeChiedereIlFontDelleOpzioniAScalaUno;
var
  LSettings: TXcomFontOverlaySettings;
begin
  LSettings := Small('Consolas', 7);
  LSettings.Face.Bold := True;
  LSettings.Face.Antialias := False;
  LSettings.Face.FileName := 'c.ttf';
  Overlay([LSettings]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFactory.Calls);
  Assert.AreEqual('Consolas', FFactory.LastFace.Name);
  Assert.AreEqual('c.ttf', FFactory.LastFace.FileName);
  Assert.AreEqual(7, FFactory.LastFace.Size);
  Assert.IsTrue(FFactory.LastFace.Bold);
  Assert.IsFalse(FFactory.LastFace.Antialias);
  Assert.AreEqual(1, FFactory.LastScale);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeRiconoscereLIdSenzaGuardareLeMaiuscole;
begin
  Overlay([Small]).Apply('font_small', FFont);
  Assert.AreEqual(2, FFont.ImageCount);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeUsareLUltimaVoceDiUnFontScrittoDueVolte;
begin
  Overlay([Small('Tahoma', 8), Small('Verdana', 9)]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFactory.Calls);
  Assert.AreEqual('Verdana', FFactory.LastFace.Name);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeRipiegareSullOriginaleSeIlFontNonEsiste;
begin
  FFactory.Rasterizer := nil;
  FFactory.Reason := 'no such font';
  Overlay([Small('Inesistente')]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.AreEqual(1, FLog.Count('WARN', 'font FONT_SMALL: "Inesistente" 8 not used (no such font): the original font stays'));
end;

procedure TTestXcomRasterFontOverlay.DovrebbeRipiegareSullOriginaleSeIlFontETroppoAlto;
var
  LChar: TXcomFontChar;
begin
  FRasterizer.DefaultHeight := 11;
  Overlay([Small]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.IsTrue(FFont.TryGetChar(Ord('A'), LChar));
  Assert.AreEqual(0, LChar.ImageIndex);
  Assert.AreEqual(1, FLog.Count('WARN', 'is 11 pixels tall and the limit is 10: the original font stays'));
  Assert.AreEqual(0, FLog.Count('INFO', ''));
end;

procedure TTestXcomRasterFontOverlay.DovrebbeRipiegareSullOriginaleSeIlFontETroppoLargo;
begin
  FRasterizer.DefaultWidth := 9;
  Overlay([Small]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.AreEqual(1, FLog.Count('WARN', 'has letters 9 pixels wide and the limit is 8: the original font stays'));
end;

procedure TTestXcomRasterFontOverlay.DovrebbeRipiegareSullOriginaleSeIlFontNonHaICaratteri;
begin
  FRasterizer.Remove(Ord('A'));
  FRasterizer.Remove(Ord('B'));
  FRasterizer.Remove(Ord('?'));
  Overlay([Small]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.AreEqual(1, FLog.Count('WARN', 'has none of the characters of the font: the original font stays'));
end;

procedure TTestXcomRasterFontOverlay.ConLaRiduzioneDovrebbeProvareMisurePiuPiccoleFinoAEntrare;
var
  LSettings: TXcomFontOverlaySettings;
  LTall: IXcomGlyphRasterizer;
  LChar: TXcomFontChar;
begin
  // at 8 and at 7 pixels the font is 11 rows tall (the limit is 10); at 6 it is the one of the fixture
  LTall := TFakeGlyphRasterizer.Create(3, 11, 2);
  FFactory.BySize := [nil, nil, nil, nil, nil, nil, nil, LTall, LTall];
  LSettings := Small('Tahoma', 8);
  LSettings.Shrink := True;
  Overlay([LSettings]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(3, FFactory.Calls);
  Assert.AreEqual(6, FFactory.LastFace.Size);
  Assert.AreEqual(2, FFont.ImageCount);
  Assert.IsTrue(FFont.TryGetChar(Ord('A'), LChar));
  Assert.AreEqual(1, LChar.ImageIndex);
  Assert.AreEqual(1, FLog.Count('INFO', 'font FONT_SMALL: too large for the cells at 8 pixels, reduced to 6'));
  Assert.AreEqual(1, FLog.Count('INFO', 'font FONT_SMALL: "Tahoma" 6, 3 characters'));
  Assert.AreEqual(2, FLog.Lines.Count);
end;

procedure TTestXcomRasterFontOverlay.ConLaRiduzioneNonDovrebbeScendereSottoLaMisuraMinima;
var
  LSettings: TXcomFontOverlaySettings;
begin
  FRasterizer.DefaultHeight := 11;
  LSettings := Small('Tahoma', 8);
  LSettings.Shrink := True;
  Overlay([LSettings]).Apply('FONT_SMALL', FFont);
  // 8, 7, 6, 5 and 4
  Assert.AreEqual(5, FFactory.Calls);
  Assert.AreEqual(XCOM_FONT_SMALLEST_SIZE, FFactory.LastFace.Size);
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.AreEqual(1, FLog.Count('WARN', '"Tahoma" 4 is 11 pixels tall and the limit is 10: the original font stays'));
  // said once, for the last size tried
  Assert.AreEqual(1, FLog.Lines.Count);
end;

procedure TTestXcomRasterFontOverlay.SenzaLaRiduzioneUnFontTroppoAltoDovrebbeEssereChiestoUnaVolta;
begin
  FRasterizer.DefaultHeight := 11;
  Overlay([Small]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(1, FFactory.Calls);
  Assert.AreEqual(8, FFactory.LastFace.Size);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeAvvisareDeiCaratteriRimastiOriginali;
var
  LChar: TXcomFontChar;
begin
  FRasterizer.Remove(Ord('B'));
  Overlay([Small]).Apply('FONT_SMALL', FFont);
  Assert.AreEqual(2, FFont.ImageCount);
  Assert.IsTrue(FFont.TryGetChar(Ord('B'), LChar));
  Assert.AreEqual(0, LChar.ImageIndex);
  Assert.AreEqual(1, FLog.Count('WARN', 'font FONT_SMALL: 1 characters are not in "Tahoma" 8'));
end;

procedure TTestXcomRasterFontOverlay.DovrebbeFunzionareSenzaLog;
var
  LOverlay: IXcomFontOverlay;
begin
  LOverlay := TXcomRasterFontOverlay.Create([Small], FFactoryRef, nil);
  LOverlay.Apply('FONT_SMALL', FFont);
  Assert.AreEqual(2, FFont.ImageCount);
  FFactory.Rasterizer := nil;
  LOverlay.Apply('FONT_SMALL', FFont);
  Assert.AreEqual(2, FFont.ImageCount);
end;

procedure TTestXcomRasterFontOverlay.DovrebbeRifiutareUnaFabbricaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomRasterFontOverlay.Create(nil, nil, FLogRef);
    end, EArgumentNilException);
end;

end.
