{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the lines with a width of the finer drawings       }
{  (issue 183)                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.Stroke;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Stroke;

type
  [TestFixture]
  [Category('XcomSurface')]
  TTestXcomStroke = class
  strict private
    FSurface: TXcomSurface;
    function Count(AColor: Byte): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('uno', '1,1')]
    [TestCase('due', '2,1')]
    [TestCase('tre', '3,2')]
    [TestCase('quattro', '4,2')]
    [TestCase('otto', '8,4')]
    [TestCase('zero', '0,1')]
    procedure LaLarghezzaDovrebbeEssereMetaDellaScala(AScale, AWidth: Integer);
    [Test]
    procedure UnPuntoDovrebbeEssereUnQuadratoDellaLarghezza;
    [Test]
    procedure UnaLineaLargaUnoDovrebbeAvereUnPixelPerPasso;
    [Test]
    procedure LeDueDirezioniDovrebberoDareLaStessaLinea;
    [Test]
    procedure CioCheEsceDallaSuperficieDovrebbeEssereTagliato;
    [Test]
    procedure UnaLineaOrizzontaleInScalaDovrebbeEssereQuellaIngrandita;
    [Test]
    procedure UnaLineaInScalaPiuSottileDovrebbeStareAlCentroDelPixel;
  end;

implementation

procedure TTestXcomStroke.Setup;
begin
  FSurface := TXcomSurface.Create(64, 48);
end;

procedure TTestXcomStroke.TearDown;
begin
  FSurface.Free;
end;

function TTestXcomStroke.Count(AColor: Byte): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FSurface.Pixels) do
    if FSurface.Pixels[LIndex] = AColor then
      Inc(Result);
end;

procedure TTestXcomStroke.LaLarghezzaDovrebbeEssereMetaDellaScala(AScale, AWidth: Integer);
begin
  Assert.AreEqual(AWidth, TXcomStroke.WidthOf(AScale));
end;

procedure TTestXcomStroke.UnPuntoDovrebbeEssereUnQuadratoDellaLarghezza;
begin
  TXcomStroke.Line(FSurface, 10, 12, 10, 12, 3, 7);
  Assert.AreEqual(9, Count(7));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(10, 12)));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(12, 14)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(9, 12)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(13, 14)));
end;

procedure TTestXcomStroke.UnaLineaLargaUnoDovrebbeAvereUnPixelPerPasso;
begin
  TXcomStroke.Line(FSurface, 2, 3, 22, 13, 1, 7);
  Assert.AreEqual(21, Count(7));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(2, 3)));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(22, 13)));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(12, 8)));
end;

procedure TTestXcomStroke.LeDueDirezioniDovrebberoDareLaStessaLinea;
var
  LOther: TXcomSurface;
  LIndex: Integer;
begin
  LOther := TXcomSurface.Create(64, 48);
  try
    TXcomStroke.Line(FSurface, 3, 40, 50, 5, 2, 7);
    TXcomStroke.Line(LOther, 50, 5, 3, 40, 2, 7);
    for LIndex := 0 to High(FSurface.Pixels) do
      if FSurface.Pixels[LIndex] <> LOther.Pixels[LIndex] then
        Assert.Fail(Format('pixel %d', [LIndex]));
  finally
    LOther.Free;
  end;
end;

procedure TTestXcomStroke.CioCheEsceDallaSuperficieDovrebbeEssereTagliato;
begin
  TXcomStroke.Line(FSurface, -20, -20, 100, 80, 4, 7);
  Assert.IsTrue(Count(7) > 0);
  TXcomStroke.Line(FSurface, 200, 200, 300, 300, 4, 8);
  Assert.AreEqual(0, Count(8));
  TXcomStroke.Line(FSurface, 1, 1, 5, 5, 0, 9);
  Assert.AreEqual(0, Count(9));
end;

procedure TTestXcomStroke.UnaLineaOrizzontaleInScalaDovrebbeEssereQuellaIngrandita;
begin
  // the pixels 2..9 of the row 3, four times larger, with a pen as wide as the scale
  TXcomStroke.ScaledLine(FSurface, 2, 3, 9, 3, 4, 4, 7);
  Assert.AreEqual(8 * 4 * 4, Count(7));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(8, 12)));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(39, 15)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(7, 12)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(40, 12)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(8, 11)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(8, 16)));
end;

procedure TTestXcomStroke.UnaLineaInScalaPiuSottileDovrebbeStareAlCentroDelPixel;
begin
  // a pen of 2 in a pixel that became 4 x 4: one pixel free on each side
  TXcomStroke.ScaledLine(FSurface, 2, 3, 2, 3, 4, 2, 7);
  Assert.AreEqual(4, Count(7));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(9, 13)));
  Assert.AreEqual(7, Integer(FSurface.GetPixel(10, 14)));
  Assert.AreEqual(0, Integer(FSurface.GetPixel(8, 12)));
end;

end.
