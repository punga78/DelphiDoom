{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL call recorder - sizes of pixels             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.OpenGl.PixelFormats;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.OpenGl.Recorder.PixelFormats;

type
  [TestFixture]
  [Category('opengl')]
  TTestOpenGlPixelFormats = class(TObject)
  public
    [TestCase('byte', '5121,1')]
    [TestCase('short', '5122,2')]
    [TestCase('unsigned int', '5125,4')]
    [TestCase('float', '5126,4')]
    [TestCase('double', '5130,8')]
    [TestCase('bitmap', '6656,0')]
    [TestCase('tipo impacchettato', '32818,0')]
    procedure DovrebbeDareLaDimensioneDelTipo(const AType, AExpected: Integer);
    [TestCase('rgba', '6408,4')]
    [TestCase('rgb', '6407,3')]
    [TestCase('bgra', '32993,4')]
    [TestCase('luminance alpha', '6410,2')]
    [TestCase('luminance', '6409,1')]
    [TestCase('indice di colore', '6400,1')]
    [TestCase('formato sconosciuto', '1,0')]
    procedure DovrebbeDareIlNumeroDiComponenti(const AFormat, AExpected: Integer);
    [Test]
    procedure DovrebbeArrotondareLaRigaAllAllineamento;
    [Test]
    procedure DovrebbeTenereLaRigaSeGiaAllineata;
    [Test]
    procedure DovrebbeNonArrotondareConAllineamentoUno;
    [Test]
    procedure DovrebbeUsareUnoSeLAllineamentoNonEValido;
    [Test]
    procedure DovrebbeDareFalsoPerUnFormatoSconosciuto;
    [Test]
    procedure DovrebbeDareFalsoPerUnTipoImpacchettato;
    [Test]
    procedure DovrebbeDareFalsoPerUnaLarghezzaNegativa;
    [Test]
    procedure DovrebbeDareFalsoPerUnaLarghezzaEnorme;
  end;

implementation

{ TTestOpenGlPixelFormats }

procedure TTestOpenGlPixelFormats.DovrebbeDareLaDimensioneDelTipo(const AType, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TGlPixelFormats.TypeSize(Cardinal(AType)));
end;

procedure TTestOpenGlPixelFormats.DovrebbeDareIlNumeroDiComponenti(const AFormat, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TGlPixelFormats.ComponentCount(Cardinal(AFormat)));
end;

procedure TTestOpenGlPixelFormats.DovrebbeArrotondareLaRigaAllAllineamento;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  // 3 pixel RGB a 8 bit: 9 byte, con allineamento 4 la riga dopo comincia a 12
  Assert.IsTrue(TGlPixelFormats.MeasureRow(3, $1907, $1401, 4, LRowBytes, LStride));
  Assert.AreEqual(Int64(9), LRowBytes);
  Assert.AreEqual(Int64(12), LStride);
end;

procedure TTestOpenGlPixelFormats.DovrebbeTenereLaRigaSeGiaAllineata;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsTrue(TGlPixelFormats.MeasureRow(2, $1908, $1401, 4, LRowBytes, LStride));
  Assert.AreEqual(Int64(8), LRowBytes);
  Assert.AreEqual(Int64(8), LStride);
end;

procedure TTestOpenGlPixelFormats.DovrebbeNonArrotondareConAllineamentoUno;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsTrue(TGlPixelFormats.MeasureRow(3, $1907, $1401, 1, LRowBytes, LStride));
  Assert.AreEqual(Int64(9), LStride);
end;

procedure TTestOpenGlPixelFormats.DovrebbeUsareUnoSeLAllineamentoNonEValido;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsTrue(TGlPixelFormats.MeasureRow(3, $1907, $1401, 0, LRowBytes, LStride));
  Assert.AreEqual(Int64(9), LStride);
end;

procedure TTestOpenGlPixelFormats.DovrebbeDareFalsoPerUnFormatoSconosciuto;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsFalse(TGlPixelFormats.MeasureRow(3, 1, $1401, 4, LRowBytes, LStride));
  Assert.AreEqual(Int64(0), LRowBytes);
end;

procedure TTestOpenGlPixelFormats.DovrebbeDareFalsoPerUnTipoImpacchettato;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsFalse(TGlPixelFormats.MeasureRow(3, $1908, $8033, 4, LRowBytes, LStride));
end;

procedure TTestOpenGlPixelFormats.DovrebbeDareFalsoPerUnaLarghezzaNegativa;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsFalse(TGlPixelFormats.MeasureRow(-1, $1908, $1401, 4, LRowBytes, LStride));
end;

procedure TTestOpenGlPixelFormats.DovrebbeDareFalsoPerUnaLarghezzaEnorme;
var
  LRowBytes: Int64;
  LStride: Int64;
begin
  Assert.IsFalse(TGlPixelFormats.MeasureRow(1000000, $1908, $1401, 4, LRowBytes, LStride));
end;

end.
