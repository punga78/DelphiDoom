{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - the coverage of a character  }
{  reduced to the levels of the fonts of the game                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.GlyphLevels;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.Glyph.Types, DelphiDoom.XcomSurface.GlyphLevels;

type
  [TestFixture]
  [Category('xcom-surface')]
  TTestXcomSurfaceGlyphLevels = class(TObject)
  strict private
    function Glyph(ATop: Integer; const ARows: array of Integer; AWidth: Integer): TXcomGlyphBitmap;
    function Text(const AGlyph: TXcomGlyphBitmap): string;
  public
    [Test]
    [TestCase('piena', '255,1')]
    [TestCase('soglia del livello 1', '120,1')]
    [TestCase('appena sotto', '119,2')]
    [TestCase('soglia del livello 2', '72,2')]
    [TestCase('sotto il 2', '71,3')]
    [TestCase('soglia del corpo', '40,3')]
    [TestCase('troppo poco', '39,0')]
    [TestCase('niente', '0,0')]
    procedure DovrebbeDareIlLivelloDellaCopertura(ACoverage, ALevel: Integer);
    [Test]
    procedure DovrebbeDareSoloLivelloUnoSenzaAntialiasing;
    [Test]
    procedure DovrebbeRidurreSenzaContornoTenendoMisuraERiga;
    [Test]
    procedure DovrebbeMettereQuattroAiLatiECinqueAgliAngoli;
    [Test]
    procedure DovrebbeNonUsareIlContornoPerIPixelPocoCoperti;
    [Test]
    procedure DovrebbeRifilareLeRigheELeColonneRimasteVuote;
    [Test]
    procedure DovrebbeDareMisuraZeroSeNonRestaNulla;
    [Test]
    procedure DovrebbeLeggereZeroFuoriDalRettangolo;
  end;

implementation

function TTestXcomSurfaceGlyphLevels.Glyph(ATop: Integer; const ARows: array of Integer;
  AWidth: Integer): TXcomGlyphBitmap;
var
  LIndex: Integer;
begin
  Result := TXcomGlyphBitmap.Make(AWidth, Length(ARows) div AWidth, ATop);
  for LIndex := 0 to High(ARows) do
    Result.Pixels[LIndex] := Byte(ARows[LIndex]);
end;

function TTestXcomSurfaceGlyphLevels.Text(const AGlyph: TXcomGlyphBitmap): string;
var
  LX: Integer;
  LY: Integer;
begin
  Result := '';
  for LY := 0 to AGlyph.Height - 1 do
  begin
    if LY > 0 then
      Result := Result + '/';
    for LX := 0 to AGlyph.Width - 1 do
      Result := Result + IntToStr(AGlyph.At(LX, LY));
  end;
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeDareIlLivelloDellaCopertura(ACoverage, ALevel: Integer);
begin
  Assert.AreEqual(ALevel, Integer(TXcomGlyphLevels.LevelOf(Byte(ACoverage))));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeDareSoloLivelloUnoSenzaAntialiasing;
var
  LResult: TXcomGlyphBitmap;
begin
  LResult := TXcomGlyphLevels.Reduce(Glyph(0, [255, 0, 255, 255, 255, 255], 3), False);
  Assert.AreEqual('101/111', Text(LResult));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeRidurreSenzaContornoTenendoMisuraERiga;
var
  LResult: TXcomGlyphBitmap;
begin
  LResult := TXcomGlyphLevels.Reduce(Glyph(3, [255, 100, 50, 60, 0, 255], 3), False);
  Assert.AreEqual(3, LResult.Width);
  Assert.AreEqual(2, LResult.Height);
  Assert.AreEqual(3, LResult.Top);
  Assert.AreEqual('123/301', Text(LResult));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeMettereQuattroAiLatiECinqueAgliAngoli;
var
  LResult: TXcomGlyphBitmap;
begin
  // one pixel of body: the outline is a pixel larger on every side and starts a row higher
  LResult := TXcomGlyphLevels.Reduce(Glyph(2, [255], 1), True);
  Assert.AreEqual(3, LResult.Width);
  Assert.AreEqual(3, LResult.Height);
  Assert.AreEqual(1, LResult.Top);
  Assert.AreEqual('545/414/545', Text(LResult));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeNonUsareIlContornoPerIPixelPocoCoperti;
var
  LResult: TXcomGlyphBitmap;
begin
  // the pixel covered too little is not body: it becomes outline as any other pixel beside the body
  LResult := TXcomGlyphLevels.Reduce(Glyph(0, [255, 30], 2), True);
  Assert.AreEqual('545/414/545', Text(LResult));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeRifilareLeRigheELeColonneRimasteVuote;
var
  LResult: TXcomGlyphBitmap;
begin
  // the first row and the first column are covered too little
  LResult := TXcomGlyphLevels.Reduce(Glyph(5, [10, 20, 30, 35, 255, 100, 30, 100, 255], 3), False);
  Assert.AreEqual(2, LResult.Width);
  Assert.AreEqual(2, LResult.Height);
  Assert.AreEqual(6, LResult.Top);
  Assert.AreEqual('12/21', Text(LResult));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeDareMisuraZeroSeNonRestaNulla;
var
  LResult: TXcomGlyphBitmap;
begin
  LResult := TXcomGlyphLevels.Reduce(Glyph(0, [10, 20, 30, 39], 2), True);
  Assert.AreEqual(0, LResult.Width);
  Assert.AreEqual(0, LResult.Height);
  Assert.AreEqual(0, Integer(Length(LResult.Pixels)));
end;

procedure TTestXcomSurfaceGlyphLevels.DovrebbeLeggereZeroFuoriDalRettangolo;
var
  LGlyph: TXcomGlyphBitmap;
begin
  LGlyph := Glyph(0, [7, 8], 2);
  Assert.AreEqual(8, Integer(LGlyph.At(1, 0)));
  Assert.AreEqual(0, Integer(LGlyph.At(2, 0)));
  Assert.AreEqual(0, Integer(LGlyph.At(0, 1)));
  Assert.AreEqual(0, Integer(LGlyph.At(-1, 0)));
end;

end.
