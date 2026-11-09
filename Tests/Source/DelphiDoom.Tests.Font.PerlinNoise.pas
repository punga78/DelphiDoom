{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFontPerlinNoise (issue #167)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Font.PerlinNoise;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Font.PerlinNoise;

type
  /// <summary>
  ///   The noise is the function of the old FF_ExportFont (copied into the harness that made the golden file):
  ///   1000 positions, the bits of the Double that it gave
  /// </summary>
  [TestFixture]
  [Category('font')]
  TTestFontPerlinNoise = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLoStessoNumeroDelVecchioBitPerBit;
    [Test]
    procedure DovrebbeDareLoStessoNumeroOgniVolta;
    [Test]
    procedure DovrebbeRestareNelCampoDelleTreOttave;
    [Test]
    procedure DovrebbeAccettareCoordinateNegativeEGrandiSenzaEccezioni;
    [Test]
    procedure DovrebbeDareNumeriDiversiInPosizioniDiverse;
  end;

implementation

uses
  DelphiDoom.Tests.Font.Golden;

const
  GOLDEN_FILE = 'Font\font.golden.txt';

{ TTestFontPerlinNoise }

procedure TTestFontPerlinNoise.DovrebbeDareLoStessoNumeroDelVecchioBitPerBit;
var
  LLine: string;
  LWords: TArray<string>;
  LValue: Double;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in TFontGolden.Lines(GOLDEN_FILE, 'PERLIN') do
  begin
    LWords := TFontGolden.Words(LLine);
    LValue := TFontPerlinNoise.Value(StrToInt(LWords[1]), StrToInt(LWords[2]));
    Assert.AreEqual(LWords[3], IntToHex(PInt64(@LValue)^, 16), 'punto ' + LWords[1] + ',' + LWords[2]);
    Inc(LCount);
  end;
  Assert.AreEqual(1000, LCount);
end;

procedure TTestFontPerlinNoise.DovrebbeDareLoStessoNumeroOgniVolta;
begin
  Assert.AreEqual(TFontPerlinNoise.Value(17, 5), TFontPerlinNoise.Value(17, 5));
  Assert.AreEqual(TFontPerlinNoise.Value(0, 0), TFontPerlinNoise.Value(0, 0));
end;

procedure TTestFontPerlinNoise.DovrebbeRestareNelCampoDelleTreOttave;
var
  LX: Integer;
  LY: Integer;
  LValue: Double;
begin
  // each octave is between -1 and 1 and the three are 1, 1/2 and 1/4, all times 16
  for LY := 0 to 40 do
    for LX := 0 to 330 do
    begin
      LValue := TFontPerlinNoise.Value(LX, LY);
      Assert.IsTrue(Abs(LValue) <= 16 * 1.75 + 1E-9, Format('fuori campo in %d,%d: %g', [LX, LY, LValue]));
    end;
end;

procedure TTestFontPerlinNoise.DovrebbeAccettareCoordinateNegativeEGrandiSenzaEccezioni;
begin
  // the hash wraps around: it is not an overflow
  TFontPerlinNoise.Value(-1, -1);
  TFontPerlinNoise.Value(-1000, 777);
  TFontPerlinNoise.Value(1000000, 1000000);
  TFontPerlinNoise.Value(MaxInt div 8, MaxInt div 64);
  Assert.Pass;
end;

procedure TTestFontPerlinNoise.DovrebbeDareNumeriDiversiInPosizioniDiverse;
var
  LDistinct: Integer;
  LIndex: Integer;
begin
  LDistinct := 0;
  for LIndex := 1 to 50 do
    if TFontPerlinNoise.Value(LIndex, 3) <> TFontPerlinNoise.Value(LIndex - 1, 3) then
      Inc(LDistinct);
  Assert.IsTrue(LDistinct > 40, 'il rumore deve variare da un pixel all altro');
end;

end.
