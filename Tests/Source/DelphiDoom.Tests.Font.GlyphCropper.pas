{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontGlyphCropper (issue #167)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.GlyphCropper;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.GlyphCropper;

type
  /// <summary>
  ///   The cut of the empty columns on the right of a character. The same cut is checked against the old tool in
  ///   the tests of TFontTextComposer (the golden file of the composed texts)
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontGlyphCropper = class(TObject)
  strict private
    /// <summary>A picture of AWidth by 4 with the background everywhere, but for the columns that are listed</summary>
    function Picture(AWidth: Integer; const AFilledColumns: array of Integer): TFontImage;
  public
    [Test]
    procedure DovrebbeTagliareLeColonneVuoteLasciandoneUna;
    [Test]
    procedure DovrebbeNonTagliareUnaImmagineCheRiempieLaCella;
    [Test]
    procedure DovrebbeLasciareUnaColonnaVuotaAncheSeLUltimaEPiena;
    [Test]
    procedure DovrebbeFermarsiAlMinimoDiTreColonne;
    [Test]
    procedure DovrebbeFermarsiAMetaDellaDimensioneDelFontMenoUno;
    [Test]
    procedure DovrebbeNonToccareUnaImmagineStrettaDelMinimo;
    [Test]
    procedure DovrebbeTagliareUnaImmagineVuotaFinoAlMinimo;
    [Test]
    procedure DovrebbeNonTagliareSeUnaColonnaDiMezzoEPiena;
    [Test]
    procedure DovrebbeConfrontareIPixelColSoloColoreNonConLAlfa;
    [Test]
    procedure DovrebbeRifiutareUnImmagineNonValida;
  end;

implementation

const
  BACKGROUND = $102030;
  FOREGROUND = $FFFFFF;

{ TTestFontGlyphCropper }

function TTestFontGlyphCropper.Picture(AWidth: Integer; const AFilledColumns: array of Integer): TFontImage;
var
  LIndex: Integer;
begin
  Result := TFontImage.Create(AWidth, 4);
  for LIndex := 0 to Length(Result.Pixels) - 1 do
    Result.Pixels[LIndex] := BACKGROUND;
  for LIndex := 0 to High(AFilledColumns) do
    Result.Pixels[AFilledColumns[LIndex] + 2 * AWidth] := FOREGROUND;
end;

procedure TTestFontGlyphCropper.DovrebbeTagliareLeColonneVuoteLasciandoneUna;
begin
  // columns 0 to 3 have a pixel: the picture keeps them and one empty column
  Assert.AreEqual(5, TFontGlyphCropper.CroppedWidth(Picture(10, [0, 1, 2, 3]), BACKGROUND, 8));
end;

procedure TTestFontGlyphCropper.DovrebbeNonTagliareUnaImmagineCheRiempieLaCella;
begin
  Assert.AreEqual(8, TFontGlyphCropper.CroppedWidth(Picture(8, [0, 1, 2, 3, 4, 5, 6, 7]), BACKGROUND, 8));
end;

procedure TTestFontGlyphCropper.DovrebbeLasciareUnaColonnaVuotaAncheSeLUltimaEPiena;
begin
  // the last column has a pixel: nothing to cut. With only the one before: the last one is the empty one
  Assert.AreEqual(6, TFontGlyphCropper.CroppedWidth(Picture(6, [5]), BACKGROUND, 8));
  Assert.AreEqual(6, TFontGlyphCropper.CroppedWidth(Picture(6, [4]), BACKGROUND, 8));
  Assert.AreEqual(6, TFontGlyphCropper.CroppedWidth(Picture(8, [4]), BACKGROUND, 8), 'colonne 0..4 e una vuota');
end;

procedure TTestFontGlyphCropper.DovrebbeFermarsiAlMinimoDiTreColonne;
begin
  Assert.AreEqual(3, TFontGlyphCropper.CroppedWidth(Picture(16, [0]), BACKGROUND, 4), 'il minimo e 3 anche con il font piccolo');
end;

procedure TTestFontGlyphCropper.DovrebbeFermarsiAMetaDellaDimensioneDelFontMenoUno;
begin
  // a font of size 20: 20 div 2 - 1 = 9
  Assert.AreEqual(9, TFontGlyphCropper.CroppedWidth(Picture(16, [0]), BACKGROUND, 20));
  // a font of size 12: 12 div 2 - 1 = 5
  Assert.AreEqual(5, TFontGlyphCropper.CroppedWidth(Picture(16, [0]), BACKGROUND, 12));
end;

procedure TTestFontGlyphCropper.DovrebbeNonToccareUnaImmagineStrettaDelMinimo;
begin
  Assert.AreEqual(8, TFontGlyphCropper.CroppedWidth(Picture(8, []), BACKGROUND, 20), 'minimo 9, larghezza 8');
  Assert.AreEqual(2, TFontGlyphCropper.CroppedWidth(Picture(2, []), BACKGROUND, 4));
end;

procedure TTestFontGlyphCropper.DovrebbeTagliareUnaImmagineVuotaFinoAlMinimo;
begin
  Assert.AreEqual(3, TFontGlyphCropper.CroppedWidth(Picture(12, []), BACKGROUND, 8));
end;

procedure TTestFontGlyphCropper.DovrebbeNonTagliareSeUnaColonnaDiMezzoEPiena;
begin
  // an empty column in the middle does not count: what is after the last pixel is cut, and one column is left
  Assert.AreEqual(7, TFontGlyphCropper.CroppedWidth(Picture(9, [4, 5]), BACKGROUND, 8));
  Assert.AreEqual(8, TFontGlyphCropper.CroppedWidth(Picture(10, [1, 6]), BACKGROUND, 8));
end;

procedure TTestFontGlyphCropper.DovrebbeConfrontareIPixelColSoloColoreNonConLAlfa;
var
  LImage: TFontImage;
  LIndex: Integer;
begin
  LImage := Picture(8, []);
  for LIndex := 0 to Length(LImage.Pixels) - 1 do
    LImage.Pixels[LIndex] := LImage.Pixels[LIndex] or $FF000000;
  Assert.AreEqual(3, TFontGlyphCropper.CroppedWidth(LImage, BACKGROUND, 8));
end;

procedure TTestFontGlyphCropper.DovrebbeRifiutareUnImmagineNonValida;
var
  LImage: TFontImage;
begin
  LImage.Width := 4;
  LImage.Height := 4;
  SetLength(LImage.Pixels, 15);
  Assert.WillRaise(
    procedure
    begin
      TFontGlyphCropper.CroppedWidth(LImage, BACKGROUND, 8);
    end, EFontException);
end;

end.
