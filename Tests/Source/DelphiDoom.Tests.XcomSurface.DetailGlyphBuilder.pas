{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomDetailGlyphBuilder (the character of the      }
{  text at the resolution of the display: coverage to alpha, the outline)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.DetailGlyphBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.Ink.Types,
  DelphiDoom.XcomSurface.DetailGlyphBuilder;

type
  [TestFixture]
  [Category('XcomSurface')]
  TTestXcomSurfaceDetailGlyphBuilder = class
  strict private
    function Coverage(AWidth, AHeight: Integer; const AValues: array of Byte): TXcomGlyphBitmap;
  public
    [Test]
    procedure LaCoperturaDovrebbeDiventareLAlphaDelCorpoSenzaLivelli;
    [Test]
    procedure SenzaContornoIlRettangoloDovrebbeEssereQuelloDellaCopertura;
    [Test]
    [TestCase('doppio', '2')]
    [TestCase('triplo', '3')]
    [TestCase('quadruplo', '4')]
    procedure IlContornoDovrebbeEssereLargoQuantoLaScala(AScale: Integer);
    [Test]
    procedure IlContornoDovrebbeAvereIlLivelloQuattroAccantoEIlCinqueSugliAngoli;
    [Test]
    procedure LAlphaDelContornoDovrebbeEssereLaCoperturaDelCorpoVicino;
  end;

implementation

function TTestXcomSurfaceDetailGlyphBuilder.Coverage(AWidth, AHeight: Integer;
  const AValues: array of Byte): TXcomGlyphBitmap;
var
  LIndex: Integer;
begin
  Result := TXcomGlyphBitmap.Make(AWidth, AHeight, 0);
  for LIndex := 0 to High(AValues) do
    Result.Pixels[LIndex] := AValues[LIndex];
end;

procedure TTestXcomSurfaceDetailGlyphBuilder.LaCoperturaDovrebbeDiventareLAlphaDelCorpoSenzaLivelli;
var
  LGlyph: TXcomDetailGlyph;
begin
  // 10 and 39 would be thrown away by the levels of the pictures, 100 would become the level 2
  LGlyph := TXcomDetailGlyphBuilder.Build(Coverage(4, 1, [10, 39, 100, 255]), False, 2);
  Assert.AreEqual(10, Integer(LGlyph.Body[0]));
  Assert.AreEqual(39, Integer(LGlyph.Body[1]));
  Assert.AreEqual(100, Integer(LGlyph.Body[2]));
  Assert.AreEqual(255, Integer(LGlyph.Body[3]));
end;

procedure TTestXcomSurfaceDetailGlyphBuilder.SenzaContornoIlRettangoloDovrebbeEssereQuelloDellaCopertura;
var
  LGlyph: TXcomDetailGlyph;
begin
  LGlyph := TXcomDetailGlyphBuilder.Build(Coverage(3, 2, [1, 2, 3, 4, 5, 6]), False, 3);
  Assert.AreEqual(3, LGlyph.Width);
  Assert.AreEqual(2, LGlyph.Height);
  Assert.AreEqual(0, LGlyph.Left);
  Assert.AreEqual(0, LGlyph.Top);
  Assert.AreEqual(0, Integer(Length(LGlyph.Outline)));
  Assert.AreEqual(0, Integer(Length(LGlyph.OutlineLevel)));
end;

procedure TTestXcomSurfaceDetailGlyphBuilder.IlContornoDovrebbeEssereLargoQuantoLaScala(AScale: Integer);
var
  LGlyph: TXcomDetailGlyph;
  LMiddle: Integer;
begin
  LGlyph := TXcomDetailGlyphBuilder.Build(Coverage(1, 1, [255]), True, AScale);
  Assert.AreEqual(1 + 2 * AScale, LGlyph.Width);
  Assert.AreEqual(1 + 2 * AScale, LGlyph.Height);
  Assert.AreEqual(-AScale, LGlyph.Left);
  Assert.AreEqual(-AScale, LGlyph.Top);
  // the row of the body: outline from the first to the last column
  LMiddle := AScale * LGlyph.Width;
  Assert.AreEqual(255, Integer(LGlyph.Outline[LMiddle]));
  Assert.AreEqual(255, Integer(LGlyph.Outline[LMiddle + LGlyph.Width - 1]));
  Assert.AreEqual(255, Integer(LGlyph.Body[LMiddle + AScale]));
  Assert.AreEqual(0, Integer(LGlyph.Body[LMiddle]));
end;

procedure TTestXcomSurfaceDetailGlyphBuilder.IlContornoDovrebbeAvereIlLivelloQuattroAccantoEIlCinqueSugliAngoli;
var
  LGlyph: TXcomDetailGlyph;
begin
  LGlyph := TXcomDetailGlyphBuilder.Build(Coverage(1, 1, [255]), True, 2);
  // 5 x 5 with the body in the middle: beside it (two pixels away on a side) 4, a little farther 5, and the
  // corners of the square nothing
  Assert.AreEqual(XCOM_GLYPH_LEVEL_OUTLINE, Integer(LGlyph.OutlineLevel[2 * 5 + 0]));
  Assert.AreEqual(XCOM_GLYPH_LEVEL_OUTLINE, Integer(LGlyph.OutlineLevel[0 * 5 + 2]));
  Assert.AreEqual(XCOM_GLYPH_LEVEL_OUTLINE, Integer(LGlyph.OutlineLevel[1 * 5 + 1]));
  Assert.AreEqual(XCOM_GLYPH_LEVEL_CORNER, Integer(LGlyph.OutlineLevel[1]));
  Assert.AreEqual(XCOM_GLYPH_LEVEL_CORNER, Integer(LGlyph.OutlineLevel[4 * 5 + 3]));
  Assert.AreEqual(255, Integer(LGlyph.Outline[1]));
  Assert.AreEqual(0, Integer(LGlyph.Outline[0]));
  Assert.AreEqual(0, Integer(LGlyph.Outline[4 * 5 + 4]));
end;

procedure TTestXcomSurfaceDetailGlyphBuilder.LAlphaDelContornoDovrebbeEssereLaCoperturaDelCorpoVicino;
var
  LGlyph: TXcomDetailGlyph;
begin
  // a half covered pixel on the left, a full one on the right, far enough not to reach the left edge
  LGlyph := TXcomDetailGlyphBuilder.Build(Coverage(4, 1, [128, 0, 0, 255]), True, 2);
  // width 8: the first column only sees the half covered pixel
  Assert.AreEqual(128, Integer(LGlyph.Outline[2 * 8 + 0]));
  Assert.AreEqual(255, Integer(LGlyph.Outline[2 * 8 + 7]));
end;

end.
