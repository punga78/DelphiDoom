{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - a font taken back to the     }
{  pictures of the game after a font of the system was laid over it             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.FontRestore;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Font, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphRasterizer.Intf,
  DelphiDoom.XcomSurface.FontOverlayBuilder, DelphiDoom.XcomSurface.FontDetail.Intf,
  DelphiDoom.Tests.XcomSurface.FakeRasterizer;

type
  [TestFixture]
  [Category('xcom-surface')]
  TTestXcomSurfaceFontRestore = class(TObject)
  strict private
    FFont: TXcomFont;
    FRasterizer: IXcomGlyphRasterizer;
    procedure Overlay(ASize: Integer = 8);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnFontMaiSostituitoNonDovrebbeCambiare;
    [Test]
    procedure DovrebbeTogliereLeImmaginiAggiunte;
    [Test]
    procedure DovrebbeRiavereICaratteriOriginali;
    [Test]
    procedure DovrebbeTogliereIlDettaglioEL_Originale;
    [Test]
    procedure DopoIlRipristinoDovrebbeEssereUnAltroFontDiSistema;
    [Test]
    procedure RipristinareDueVolteDovrebbeEssereLoStesso;
    [Test]
    procedure LeMisureDelFontDovrebberoRestareQuelleDelGioco;
  end;

implementation

procedure TTestXcomSurfaceFontRestore.Setup;
var
  LSurface: TXcomSurface;
  LCell: Integer;
  LX: Integer;
  LY: Integer;
begin
  // cells of 6 x 8, a body of 2 x 4 pixels in each: the font of the other tests of the fonts
  LSurface := TXcomSurface.Create(24, 8);
  for LCell := 0 to 2 do
    for LY := 1 to 4 do
      for LX := 1 to 2 do
        LSurface.SetPixel(LCell * 6 + LX, LY, 1);
  FFont := TXcomFont.Create;
  FFont.Init(FFont.AddImage(6, 8, 1, LSurface), [Ord('A'), Ord('B'), Ord('?')]);
  FRasterizer := TFakeGlyphRasterizer.Create(3, 5, 2);
end;

procedure TTestXcomSurfaceFontRestore.TearDown;
begin
  FRasterizer := nil;
  FFont.Free;
end;

procedure TTestXcomSurfaceFontRestore.Overlay(ASize: Integer);
var
  LBuilder: TXcomFontOverlayBuilder;
  LReport: TXcomFontOverlayReport;
begin
  LBuilder := TXcomFontOverlayBuilder.Create;
  try
    Assert.IsTrue(LBuilder.Apply(FFont, FRasterizer, TXcomFontOverlaySettings.Make('FONT_SMALL', 'Tahoma', ASize),
      LReport));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestXcomSurfaceFontRestore.UnFontMaiSostituitoNonDovrebbeCambiare;
begin
  FFont.Restore;
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.IsNull(FFont.Original);
end;

procedure TTestXcomSurfaceFontRestore.DovrebbeTogliereLeImmaginiAggiunte;
begin
  Overlay;
  Assert.AreEqual(2, FFont.ImageCount);
  FFont.Restore;
  Assert.AreEqual(1, FFont.ImageCount);
end;

procedure TTestXcomSurfaceFontRestore.DovrebbeRiavereICaratteriOriginali;
var
  LChar: TXcomFontChar;
begin
  Overlay;
  Assert.IsTrue(FFont.TryGetChar(Ord('A'), LChar));
  Assert.AreEqual(1, LChar.ImageIndex);
  FFont.Restore;
  Assert.IsTrue(FFont.TryGetChar(Ord('A'), LChar));
  Assert.AreEqual(0, LChar.ImageIndex);
  Assert.AreEqual(2, Integer(LChar.Rect.W));
end;

procedure TTestXcomSurfaceFontRestore.DovrebbeTogliereIlDettaglioEL_Originale;
begin
  Overlay;
  Assert.IsNotNull(FFont.Original);
  FFont.Restore;
  Assert.IsNull(FFont.Original);
  Assert.IsFalse(Assigned(FFont.Detail));
end;

procedure TTestXcomSurfaceFontRestore.DopoIlRipristinoDovrebbeEssereUnAltroFontDiSistema;
var
  LChar: TXcomFontChar;
begin
  Overlay;
  FFont.Restore;
  FRasterizer := TFakeGlyphRasterizer.Create(4, 6, 1);
  Overlay;
  Assert.AreEqual(2, FFont.ImageCount);
  Assert.IsTrue(FFont.TryGetChar(Ord('A'), LChar));
  Assert.AreEqual(1, LChar.ImageIndex);
  Assert.AreEqual(4, Integer(LChar.Rect.W));
  // the original font is again the one of the pictures of the game
  Assert.IsNotNull(FFont.Original);
  Assert.AreEqual(1, FFont.Original.ImageCount);
end;

procedure TTestXcomSurfaceFontRestore.RipristinareDueVolteDovrebbeEssereLoStesso;
begin
  Overlay;
  FFont.Restore;
  FFont.Restore;
  Assert.AreEqual(1, FFont.ImageCount);
  Assert.IsNull(FFont.Original);
end;

procedure TTestXcomSurfaceFontRestore.LeMisureDelFontDovrebberoRestareQuelleDelGioco;
begin
  Overlay;
  FFont.Restore;
  Assert.AreEqual(6, FFont.Width);
  Assert.AreEqual(8, FFont.Height);
  Assert.AreEqual(1, FFont.Spacing);
end;

end.
