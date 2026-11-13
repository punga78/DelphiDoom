{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRoqCodebook                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.Codebook;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Cinematic.YuvConverter,
  DelphiDoom.Cinematic.Codebook;

type
  [TestFixture]
  [Category('cinematic')]
  TTestRoqCodebook = class(TObject)
  strict private
    FConverter: TRoqYuvConverter;
    FCodebook: TRoqCodebook;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePartireVuotoENonCaricato;
    [Test]
    procedure DovrebbeCostruireIVettori2x2DaiColori;
    [Test]
    procedure DovrebbeRipetereIlVettore2x2NelQuattroPerQuattro;
    [Test]
    procedure DovrebbeRaddoppiareIPixelNelVettoreOttoPerOtto;
    [Test]
    procedure DovrebbeUsare256SeIFlagSonoZero;
    [Test]
    procedure DovrebbeUsare256SeIlByteAltoDeiFlagEZero;
    [Test]
    procedure DovrebbeLasciareLeVociNonRiscritteDiUnCodebookPrecedente;
    [Test]
    procedure DovrebbeSollevareSeIDatiSonoTroncati;
    [Test]
    procedure DovrebbeDimenticareTuttoConClear;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types;

{ TTestRoqCodebook }

procedure TTestRoqCodebook.Setup;
begin
  FConverter := TRoqYuvConverter.Create($FF);
  FCodebook := TRoqCodebook.Create(FConverter);
end;

procedure TTestRoqCodebook.TearDown;
begin
  FCodebook.Free;
  FConverter.Free;
end;

procedure TTestRoqCodebook.DovrebbePartireVuotoENonCaricato;
begin
  Assert.IsFalse(FCodebook.Loaded);
  Assert.AreEqual(256 * 4, Integer(Length(FCodebook.Vq2)));
  Assert.AreEqual(256 * 16, Integer(Length(FCodebook.Vq4)));
  Assert.AreEqual(256 * 64, Integer(Length(FCodebook.Vq8)));
  Assert.AreEqual(Cardinal(0), FCodebook.Vq8[100]);
end;

procedure TTestRoqCodebook.DovrebbeCostruireIVettori2x2DaiColori;
begin
  // one 2x2 vector: Y 1, 2, 3, 4, Cr 100, Cb 150; one pair of vectors (0, 0)
  FCodebook.Decode(TBytes.Create(1, 2, 3, 4, 100, 150, 0, 0, 0, 0), $0100 or 1);
  Assert.IsTrue(FCodebook.Loaded);
  Assert.AreEqual(FConverter.ToPixel(1, 100, 150), FCodebook.Vq2[0]);
  Assert.AreEqual(FConverter.ToPixel(2, 100, 150), FCodebook.Vq2[1]);
  Assert.AreEqual(FConverter.ToPixel(3, 100, 150), FCodebook.Vq2[2]);
  Assert.AreEqual(FConverter.ToPixel(4, 100, 150), FCodebook.Vq2[3]);
end;

procedure TTestRoqCodebook.DovrebbeRipetereIlVettore2x2NelQuattroPerQuattro;
var
  LRow, LColumn: Integer;
begin
  FCodebook.Decode(TBytes.Create(1, 2, 3, 4, 100, 150, 0, 0, 0, 0), $0100 or 1);
  // vector 0 of 4x4 = the 2x2 vector twice on each axis: pixel (x, y) is vq2[(y mod 2) * 2 + x mod 2]
  for LRow := 0 to 3 do
    for LColumn := 0 to 3 do
      Assert.AreEqual(FCodebook.Vq2[(LRow mod 2) * 2 + LColumn mod 2],
        FCodebook.Vq4[LRow * 4 + LColumn]);
end;

procedure TTestRoqCodebook.DovrebbeRaddoppiareIPixelNelVettoreOttoPerOtto;
var
  LRow, LColumn: Integer;
begin
  FCodebook.Decode(TBytes.Create(1, 2, 3, 4, 100, 150, 0, 0, 0, 0), $0100 or 1);
  for LRow := 0 to 7 do
    for LColumn := 0 to 7 do
      Assert.AreEqual(FCodebook.Vq2[((LRow div 2) mod 2) * 2 + (LColumn div 2) mod 2],
        FCodebook.Vq8[LRow * 8 + LColumn]);
end;

procedure TTestRoqCodebook.DovrebbeUsare256SeIFlagSonoZero;
var
  LData: TBytes;
begin
  SetLength(LData, 256 * 6 + 256 * 4);
  LData[255 * 6] := 77;
  FCodebook.Decode(LData, 0);
  Assert.AreEqual(FConverter.ToPixel(77, 0, 0), FCodebook.Vq2[255 * 4]);
end;

procedure TTestRoqCodebook.DovrebbeUsare256SeIlByteAltoDeiFlagEZero;
var
  LData: TBytes;
begin
  SetLength(LData, 256 * 6 + 4 * 4);
  LData[255 * 6 + 1] := 55;
  FCodebook.Decode(LData, $0004);
  Assert.AreEqual(FConverter.ToPixel(55, 0, 0), FCodebook.Vq2[255 * 4 + 1]);
end;

procedure TTestRoqCodebook.DovrebbeLasciareLeVociNonRiscritteDiUnCodebookPrecedente;
var
  LFirst: Cardinal;
begin
  FCodebook.Decode(TBytes.Create(1, 2, 3, 4, 100, 150, 9, 9, 9, 9, 100, 100, 0, 0, 0, 0),
    $0200 or 1);
  LFirst := FCodebook.Vq2[4];
  FCodebook.Decode(TBytes.Create(200, 200, 200, 200, 10, 10, 0, 0, 0, 0), $0100 or 1);
  Assert.AreEqual(FConverter.ToPixel(200, 10, 10), FCodebook.Vq2[0]);
  Assert.AreEqual(LFirst, FCodebook.Vq2[4]);
end;

procedure TTestRoqCodebook.DovrebbeSollevareSeIDatiSonoTroncati;
begin
  Assert.WillRaise(
    procedure
    begin
      FCodebook.Decode(TBytes.Create(1, 2, 3), $0101);
    end, ERoqTruncatedException);
  Assert.IsFalse(FCodebook.Loaded);
end;

procedure TTestRoqCodebook.DovrebbeDimenticareTuttoConClear;
begin
  FCodebook.Decode(TBytes.Create(1, 2, 3, 4, 100, 150, 0, 0, 0, 0), $0100 or 1);
  FCodebook.Clear;
  Assert.IsFalse(FCodebook.Loaded);
  Assert.AreEqual(Cardinal(0), FCodebook.Vq2[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestRoqCodebook);

end.
