{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of TXcomInkPainter and of the buffer of ink (the      }
{  characters of a text at the resolution of the display)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.InkPainter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.Ink.Types, DelphiDoom.XcomSurface.DetailGlyphBuilder,
  DelphiDoom.XcomSurface.InkPainter;

type
  [TestFixture]
  [Category('XcomSurface')]
  TTestXcomSurfaceInkPainter = class
  strict private
    function Glyph(ACoverage: Byte; AOutline: Boolean; AScale: Integer): TXcomDetailGlyph;
    function Whole(const ABuffer: TXcomInkBuffer): TXcomRect;
  public
    [Test]
    procedure IlColoreDovrebbeEssereQuelloDiPaletteShift;
    [Test]
    procedure IlCorpoDovrebbeAvereIlLivelloUnoELaCoperturaComeAlpha;
    [Test]
    procedure IlContornoDovrebbeEssereLInchiostroDiDietro;
    [Test]
    procedure IlTestoInvertitoDovrebbeScambiareILivelli;
    [Test]
    procedure IlCarattereDovrebbeAndareAllaPosizioneDellaCella;
    [Test]
    procedure NullaDovrebbeUscireDalRitaglio;
    [Test]
    procedure IlBufferDovrebbeSegnareIPixelDelGiocoCheHannoInchiostro;
    [Test]
    procedure UnBufferVuotoDovrebbeDirlo;
    [Test]
    procedure IlContornoDelCarattereDopoNonDovrebbeCoprireIlCorpoDiPrima;
    [Test]
    procedure UnImmagineOriginaleDovrebbeEssereIngranditaConIPropriLivelli;
    [Test]
    procedure SuUnaSuperficieAIndiciLaCoperturaDovrebbeDareILivelliDelGioco;
    [Test]
    procedure SuUnaSuperficieAIndiciLImmagineOriginaleDovrebbeEssereIngrandita;
  end;

implementation

function TTestXcomSurfaceInkPainter.Glyph(ACoverage: Byte; AOutline: Boolean; AScale: Integer): TXcomDetailGlyph;
var
  LCoverage: TXcomGlyphBitmap;
begin
  LCoverage := TXcomGlyphBitmap.Make(1, 1, 0);
  LCoverage.Pixels[0] := ACoverage;
  Result := TXcomDetailGlyphBuilder.Build(LCoverage, AOutline, AScale);
end;

function TTestXcomSurfaceInkPainter.Whole(const ABuffer: TXcomInkBuffer): TXcomRect;
begin
  Result := TXcomRect.Make(0, 0, ABuffer.Width * ABuffer.Scale, ABuffer.Height * ABuffer.Scale);
end;

procedure TTestXcomSurfaceInkPainter.IlColoreDovrebbeEssereQuelloDiPaletteShift;
begin
  Assert.AreEqual(101, Integer(TXcomInkColor.Make(100, 1, 0).IndexOf(1)));
  Assert.AreEqual(112, Integer(TXcomInkColor.Make(100, 3, 0).IndexOf(4)));
  // inverted around 3: the level 1 becomes the 5
  Assert.AreEqual(105, Integer(TXcomInkColor.Make(100, 1, 3).IndexOf(1)));
  Assert.AreEqual(101, Integer(TXcomInkColor.Make(100, 1, 3).IndexOf(5)));
  // wrapped to a byte, as the C++
  Assert.AreEqual(4, Integer(TXcomInkColor.Make(255, 1, 0).IndexOf(5)));
end;

procedure TTestXcomSurfaceInkPainter.IlCorpoDovrebbeAvereIlLivelloUnoELaCoperturaComeAlpha;
var
  LBuffer: TXcomInkBuffer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  TXcomInkPainter.PaintGlyph(LBuffer, Glyph(77, False, 2), 2, 2, TXcomInkColor.Make(100, 1, 0), Whole(LBuffer));
  Assert.AreEqual(TXcomInkBuffer.Pack(101, 77, 0, 0), LBuffer.Pixels[2 * 8 + 2]);
end;

procedure TTestXcomSurfaceInkPainter.IlContornoDovrebbeEssereLInchiostroDiDietro;
var
  LBuffer: TXcomInkBuffer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  // the cell at (2, 2): the body at (2, 2), the outline two pixels around it
  TXcomInkPainter.PaintGlyph(LBuffer, Glyph(255, True, 2), 2, 2, TXcomInkColor.Make(100, 1, 0), Whole(LBuffer));
  Assert.AreEqual(TXcomInkBuffer.Pack(101, 255, 104, 255), LBuffer.Pixels[2 * 8 + 2]);
  Assert.AreEqual(TXcomInkBuffer.Pack(101, 0, 104, 255), LBuffer.Pixels[2 * 8 + 0]);
  Assert.AreEqual(TXcomInkBuffer.Pack(101, 0, 105, 255), LBuffer.Pixels[1]);
  // the corner of the square has no outline
  Assert.AreEqual(Cardinal(0), LBuffer.Pixels[0]);
end;

procedure TTestXcomSurfaceInkPainter.IlTestoInvertitoDovrebbeScambiareILivelli;
var
  LBuffer: TXcomInkBuffer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  TXcomInkPainter.PaintGlyph(LBuffer, Glyph(255, True, 2), 2, 2, TXcomInkColor.Make(100, 1, 3), Whole(LBuffer));
  // body 1 -> 5, outline 4 -> 2
  Assert.AreEqual(TXcomInkBuffer.Pack(105, 255, 102, 255), LBuffer.Pixels[2 * 8 + 2]);
end;

procedure TTestXcomSurfaceInkPainter.IlCarattereDovrebbeAndareAllaPosizioneDellaCella;
var
  LBuffer: TXcomInkBuffer;
  LGlyph: TXcomDetailGlyph;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  LGlyph := Glyph(255, False, 2);
  LGlyph.Left := 3;
  LGlyph.Top := 1;
  TXcomInkPainter.PaintGlyph(LBuffer, LGlyph, 2, 4, TXcomInkColor.Make(100, 1, 0), Whole(LBuffer));
  Assert.AreNotEqual(Cardinal(0), LBuffer.Pixels[5 * 8 + 5]);
  Assert.AreEqual(Cardinal(0), LBuffer.Pixels[4 * 8 + 2]);
end;

procedure TTestXcomSurfaceInkPainter.NullaDovrebbeUscireDalRitaglio;
var
  LBuffer: TXcomInkBuffer;
  LIndex: Integer;
  LCount: Integer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  // the outline is 5 x 5 from (0, 0); the clip keeps the 2 x 2 at (2, 2)
  TXcomInkPainter.PaintGlyph(LBuffer, Glyph(255, True, 2), 2, 2, TXcomInkColor.Make(100, 1, 0),
    TXcomRect.Make(2, 2, 2, 2));
  LCount := 0;
  for LIndex := 0 to High(LBuffer.Pixels) do
    if LBuffer.Pixels[LIndex] <> 0 then
      Inc(LCount);
  Assert.AreEqual(4, LCount);
  // and outside the buffer nothing is written
  TXcomInkPainter.PaintGlyph(LBuffer, Glyph(255, True, 2), 7, 7, TXcomInkColor.Make(100, 1, 0),
    TXcomRect.Make(-100, -100, 1000, 1000));
  Assert.AreNotEqual(Cardinal(0), LBuffer.Pixels[7 * 8 + 7]);
end;

procedure TTestXcomSurfaceInkPainter.IlBufferDovrebbeSegnareIPixelDelGiocoCheHannoInchiostro;
var
  LBuffer: TXcomInkBuffer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 3, 3);
  LBuffer.Put(7, 4, TXcomInkBuffer.Pack(9, 200, 0, 0));
  // (7, 4) at three times is the pixel (2, 1) of the game
  Assert.AreEqual(1, Integer(LBuffer.Cells[1 * 4 + 2]));
  Assert.AreEqual(0, Integer(LBuffer.Cells[0]));
  Assert.IsFalse(LBuffer.IsEmpty);
end;

procedure TTestXcomSurfaceInkPainter.UnBufferVuotoDovrebbeDirlo;
var
  LBuffer: TXcomInkBuffer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 3, 3);
  Assert.IsTrue(LBuffer.IsEmpty);
  Assert.AreEqual(4 * 3 * 3 * 3, Integer(Length(LBuffer.Pixels)));
  LBuffer.Put(0, 0, 0);
  LBuffer.Put(-1, 0, 5);
  LBuffer.Put(12, 0, 5);
  Assert.IsTrue(LBuffer.IsEmpty);
  Assert.IsTrue(Default(TXcomInkBuffer).IsEmpty);
end;

procedure TTestXcomSurfaceInkPainter.IlContornoDelCarattereDopoNonDovrebbeCoprireIlCorpoDiPrima;
var
  LBuffer: TXcomInkBuffer;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  LBuffer.Put(3, 3, TXcomInkBuffer.Pack(101, 255, 104, 255));
  // only an outline, weaker, of another color
  LBuffer.Put(3, 3, TXcomInkBuffer.Pack(201, 0, 204, 100));
  Assert.AreEqual(TXcomInkBuffer.Pack(101, 255, 104, 255), LBuffer.Pixels[3 * 8 + 3]);
  // a stronger body takes the front, the back stays
  LBuffer.Put(2, 3, TXcomInkBuffer.Pack(101, 50, 104, 255));
  LBuffer.Put(2, 3, TXcomInkBuffer.Pack(201, 90, 204, 10));
  Assert.AreEqual(TXcomInkBuffer.Pack(201, 90, 104, 255), LBuffer.Pixels[3 * 8 + 2]);
end;

procedure TTestXcomSurfaceInkPainter.UnImmagineOriginaleDovrebbeEssereIngranditaConIPropriLivelli;
var
  LBuffer: TXcomInkBuffer;
  LPicture: TXcomSurface;
begin
  LBuffer := TXcomInkBuffer.Make(4, 4, 2);
  LPicture := TXcomSurface.Create(4, 2);
  try
    LPicture.SetPixel(2, 0, 2);
    LPicture.SetPixel(3, 1, 5);
    // the character is the right half of the picture
    LPicture.Crop := TXcomRect.Make(2, 0, 2, 2);
    TXcomInkPainter.PaintEnlarged(LBuffer, LPicture, 2, 2, TXcomInkColor.Make(100, 1, 0), Whole(LBuffer));
    Assert.AreEqual(TXcomInkBuffer.Pack(102, 255, 0, 0), LBuffer.Pixels[2 * 8 + 2]);
    Assert.AreEqual(TXcomInkBuffer.Pack(102, 255, 0, 0), LBuffer.Pixels[3 * 8 + 3]);
    Assert.AreEqual(TXcomInkBuffer.Pack(105, 255, 0, 0), LBuffer.Pixels[4 * 8 + 4]);
    Assert.AreEqual(Cardinal(0), LBuffer.Pixels[2 * 8 + 4]);
  finally
    LPicture.Free;
  end;
end;

procedure TTestXcomSurfaceInkPainter.SuUnaSuperficieAIndiciLaCoperturaDovrebbeDareILivelliDelGioco;
var
  LTarget: TXcomSurface;
  LGlyph: TXcomDetailGlyph;
  LCoverage: TXcomGlyphBitmap;
begin
  LTarget := TXcomSurface.Create(12, 8);
  try
    LCoverage := TXcomGlyphBitmap.Make(4, 1, 0);
    LCoverage.Pixels[0] := 255;
    LCoverage.Pixels[1] := 100;
    LCoverage.Pixels[2] := 50;
    LCoverage.Pixels[3] := 10;
    LGlyph := TXcomDetailGlyphBuilder.Build(LCoverage, True, 2);
    TXcomInkPainter.DrawGlyph(LTarget, LGlyph, 2, 2, TXcomInkColor.Make(100, 1, 0));
    Assert.AreEqual(101, Integer(LTarget.GetPixel(2, 2)));
    Assert.AreEqual(102, Integer(LTarget.GetPixel(3, 2)));
    Assert.AreEqual(103, Integer(LTarget.GetPixel(4, 2)));
    // too little for the body, and the outline of the weak pixels beside it covers less than half: nothing
    Assert.AreEqual(0, Integer(LTarget.GetPixel(5, 2)));
    Assert.AreEqual(104, Integer(LTarget.GetPixel(0, 2)));
    Assert.AreEqual(105, Integer(LTarget.GetPixel(1, 0)));
  finally
    LTarget.Free;
  end;
end;

procedure TTestXcomSurfaceInkPainter.SuUnaSuperficieAIndiciLImmagineOriginaleDovrebbeEssereIngrandita;
var
  LTarget: TXcomSurface;
  LPicture: TXcomSurface;
begin
  LTarget := TXcomSurface.Create(12, 8);
  LPicture := TXcomSurface.Create(2, 2);
  try
    LPicture.SetPixel(1, 0, 3);
    TXcomInkPainter.DrawEnlarged(LTarget, LPicture, 1, 1, 3, TXcomInkColor.Make(100, 1, 0));
    Assert.AreEqual(103, Integer(LTarget.GetPixel(4, 1)));
    Assert.AreEqual(103, Integer(LTarget.GetPixel(6, 3)));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(3, 1)));
    Assert.AreEqual(0, Integer(LTarget.GetPixel(7, 1)));
  finally
    LPicture.Free;
  end;
  LTarget.Free;
end;

end.
