{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingProgramOperations                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ProgramOperations;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Rgba.Image,
  DelphiDoom.Imaging.ImageProgram.Operations, DelphiDoom.Tests.IdImages.Golden;

type
  [TestFixture]
  [Category('IdImages')]
  TTestImagingProgramOperations = class
  strict private
    class function Pixel(const ARed, AGreen, ABlue, AAlpha: Byte): TImagingRgbaImage; static;
  public
    [Test]
    procedure DovrebbeCoincidereConIlVeroHeightmap;
    [Test]
    procedure DovrebbeCoincidereConIlVeroScale;
    [Test]
    procedure DovrebbeCoincidereConIlVeroInvertAlphaEInvertColor;
    [Test]
    procedure DovrebbeCoincidereConIlVeroAddEAddNormals;
    [Test]
    procedure DovrebbeCoincidereConIlVeroSmoothNormals;
    [Test]
    procedure DovrebbeCoincidereConIlVeroMakeIntensityEMakeAlpha;
    [Test]
    procedure DovrebbeFarGirareScaleNelByteInveceDiSaturare;
    [Test]
    procedure DovrebbeSommareConSaturazione;
    [Test]
    procedure DovrebbeDareUnaNormaleVersoLAltoDaUnaAltezzaPiatta;
    [Test]
    procedure DovrebbeInvertireIlColoreSenzaToccareLAlfa;
    [Test]
    procedure DovrebbeCopiareIlRossoConMakeIntensity;
    [Test]
    procedure DovrebbeMediareIlColoreInAlfaConMakeAlpha;
  end;

implementation

{ TTestImagingProgramOperations }

class function TTestImagingProgramOperations.Pixel(const ARed, AGreen, ABlue,
  AAlpha: Byte): TImagingRgbaImage;
begin
  Result := TImagingRgbaImage.Create(1, 1);
  Result.Pixels[0] := ARed;
  Result.Pixels[1] := AGreen;
  Result.Pixels[2] := ABlue;
  Result.Pixels[3] := AAlpha;
end;

procedure TTestImagingProgramOperations.DovrebbeCoincidereConIlVeroHeightmap;
const
  SIZES: array[0..4, 0..1] of Integer = ((8, 8), (8, 8), (16, 4), (4, 16), (32, 32));
  SCALES: array[0..4] of Single = (1.0, 4.0, 0.5, 2.0, 8.0);
var
  LIndex: Integer;
  LImage: TImagingRgbaImage;
begin
  for LIndex := 0 to 4 do
  begin
    LImage := TIdImagesGolden.Generate(SIZES[LIndex, 0], SIZES[LIndex, 1], 400 + LIndex, False);
    TImagingProgramOperations.HeightmapToNormalMap(LImage, SCALES[LIndex]);
    TIdImagesGolden.Check('heightmap' + IntToStr(LIndex), LImage);
  end;
end;

procedure TTestImagingProgramOperations.DovrebbeCoincidereConIlVeroScale;
const
  SCALES: array[0..4, 0..3] of Single = ((1.5, 0.5, 2.0, 1.0), (3, 3, 3, 3), (-1, -1, -1, -1),
    (0.25, 0.5, 0.75, 1.25), (100, 0, 1, 100));
var
  LIndex: Integer;
  LImage: TImagingRgbaImage;
begin
  for LIndex := 0 to 4 do
  begin
    LImage := TIdImagesGolden.Generate(7, 5, 500 + LIndex, False);
    TImagingProgramOperations.Scale(LImage, SCALES[LIndex]);
    TIdImagesGolden.Check('scale' + IntToStr(LIndex), LImage);
  end;
end;

procedure TTestImagingProgramOperations.DovrebbeCoincidereConIlVeroInvertAlphaEInvertColor;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TIdImagesGolden.Generate(7, 5, 510, False);
  TImagingProgramOperations.InvertAlpha(LImage);
  TIdImagesGolden.Check('invertalpha', LImage);
  LImage := TIdImagesGolden.Generate(7, 5, 511, False);
  TImagingProgramOperations.InvertColor(LImage);
  TIdImagesGolden.Check('invertcolor', LImage);
end;

procedure TTestImagingProgramOperations.DovrebbeCoincidereConIlVeroAddEAddNormals;
const
  SIZES: array[0..4, 0..3] of Integer = ((8, 8, 8, 8), (8, 8, 4, 4), (4, 4, 8, 8), (8, 4, 3, 5),
    (16, 16, 16, 16));
var
  LIndex: Integer;
  LFirst, LSecond: TImagingRgbaImage;
begin
  for LIndex := 0 to 4 do
  begin
    LFirst := TIdImagesGolden.Generate(SIZES[LIndex, 0], SIZES[LIndex, 1], 600 + LIndex, True);
    LSecond := TIdImagesGolden.Generate(SIZES[LIndex, 2], SIZES[LIndex, 3], 700 + LIndex, True);
    TImagingProgramOperations.AddNormalMaps(LFirst, LSecond);
    if LIndex = 4 then
      // 1 byte of 1024 is one unit away from the C++ built for the x87 (which keeps some
      // intermediate values of the normalization in extended precision)
      TIdImagesGolden.CheckClose('addnormals4raw', LFirst, 1, 2)
    else
      TIdImagesGolden.Check('addnormals' + IntToStr(LIndex), LFirst);
    LFirst := TIdImagesGolden.Generate(SIZES[LIndex, 0], SIZES[LIndex, 1], 600 + LIndex, True);
    TImagingProgramOperations.Add(LFirst, LSecond);
    TIdImagesGolden.Check('add' + IntToStr(LIndex), LFirst);
  end;
end;

procedure TTestImagingProgramOperations.DovrebbeCoincidereConIlVeroSmoothNormals;
const
  SIZES: array[0..4, 0..1] of Integer = ((8, 8), (4, 8), (16, 4), (1, 1), (2, 2));
var
  LIndex: Integer;
  LImage: TImagingRgbaImage;
begin
  for LIndex := 0 to 4 do
  begin
    LImage := TIdImagesGolden.Generate(SIZES[LIndex, 0], SIZES[LIndex, 1], 800 + LIndex, True);
    TImagingProgramOperations.SmoothNormalMap(LImage);
    TIdImagesGolden.Check('smooth' + IntToStr(LIndex), LImage);
  end;
end;

procedure TTestImagingProgramOperations.DovrebbeCoincidereConIlVeroMakeIntensityEMakeAlpha;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TIdImagesGolden.Generate(6, 4, 900, False);
  TImagingProgramOperations.MakeIntensity(LImage);
  TIdImagesGolden.Check('intensity', LImage);
  LImage := TIdImagesGolden.Generate(6, 4, 901, False);
  TImagingProgramOperations.MakeAlpha(LImage);
  TIdImagesGolden.Check('makealpha', LImage);
end;

procedure TTestImagingProgramOperations.DovrebbeFarGirareScaleNelByteInveceDiSaturare;
var
  LImage: TImagingRgbaImage;
begin
  // 200 * 2 = 400 = $190: the C++ keeps the low byte ($90); the clamp after it never fires
  LImage := Pixel(200, 100, 0, 255);
  TImagingProgramOperations.Scale(LImage, [2, 2, 2, 2]);
  Assert.AreEqual<Integer>($90, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(200, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(254, LImage.Pixels[3]);
  LImage := Pixel(10, 0, 0, 0);
  TImagingProgramOperations.Scale(LImage, [-1, 1, 1, 1]);
  Assert.AreEqual<Integer>(246, LImage.Pixels[0]);
end;

procedure TTestImagingProgramOperations.DovrebbeSommareConSaturazione;
var
  LImage: TImagingRgbaImage;
begin
  LImage := Pixel(200, 10, 0, 255);
  TImagingProgramOperations.Add(LImage, Pixel(100, 20, 0, 255));
  Assert.AreEqual<Integer>(255, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(30, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[3]);
end;

procedure TTestImagingProgramOperations.DovrebbeDareUnaNormaleVersoLAltoDaUnaAltezzaPiatta;
var
  LImage: TImagingRgbaImage;
  LIndex: Integer;
begin
  LImage := TImagingRgbaImage.Create(4, 4);
  for LIndex := 0 to 15 do
  begin
    LImage.Pixels[LIndex * 4] := 77;
    LImage.Pixels[LIndex * 4 + 1] := 77;
    LImage.Pixels[LIndex * 4 + 2] := 77;
  end;
  TImagingProgramOperations.HeightmapToNormalMap(LImage, 4);
  for LIndex := 0 to 15 do
  begin
    // (0, 0, 1) is 128, 128, 255 and alpha 255; the fast square root is a little off 1.0
    Assert.AreEqual<Integer>(128, LImage.Pixels[LIndex * 4]);
    Assert.AreEqual<Integer>(128, LImage.Pixels[LIndex * 4 + 1]);
    Assert.IsTrue(LImage.Pixels[LIndex * 4 + 2] >= 254);
    Assert.AreEqual<Integer>(255, LImage.Pixels[LIndex * 4 + 3]);
  end;
end;

procedure TTestImagingProgramOperations.DovrebbeInvertireIlColoreSenzaToccareLAlfa;
var
  LImage: TImagingRgbaImage;
begin
  LImage := Pixel(0, 100, 255, 40);
  TImagingProgramOperations.InvertColor(LImage);
  Assert.AreEqual<Integer>(255, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(155, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(0, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(40, LImage.Pixels[3]);
  TImagingProgramOperations.InvertAlpha(LImage);
  Assert.AreEqual<Integer>(215, LImage.Pixels[3]);
end;

procedure TTestImagingProgramOperations.DovrebbeCopiareIlRossoConMakeIntensity;
var
  LImage: TImagingRgbaImage;
begin
  LImage := Pixel(90, 1, 2, 3);
  TImagingProgramOperations.MakeIntensity(LImage);
  Assert.AreEqual<Integer>(90, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(90, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(90, LImage.Pixels[3]);
end;

procedure TTestImagingProgramOperations.DovrebbeMediareIlColoreInAlfaConMakeAlpha;
var
  LImage: TImagingRgbaImage;
begin
  LImage := Pixel(10, 20, 33, 0);
  TImagingProgramOperations.MakeAlpha(LImage);
  Assert.AreEqual<Integer>(21, LImage.Pixels[3]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[2]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestImagingProgramOperations);

end.
