{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingRgbaSampler and TImagingRgbaImage              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.RgbaSampler;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Rgba.Image,
  DelphiDoom.Imaging.Rgba.Sampler, DelphiDoom.Tests.IdImages.Golden;

type
  [TestFixture]
  [Category('IdImages')]
  TTestImagingRgbaSampler = class
  public
    [Test]
    procedure DovrebbeCoincidereConIlVeroDropsampleEResample;
    [Test]
    procedure DovrebbeCoincidereConIlVeroMipMap;
    [Test]
    procedure DovrebbeCoincidereConIlVeroBlendEFlip;
    [Test]
    procedure DovrebbeRifiutareIlMipMapDiUnPixel;
    [Test]
    procedure DovrebbeTagliareIlResampleA4096;
    [Test]
    procedure DovrebbeRifiutareLaRotazioneDiUnImmagineNonQuadrata;
    [Test]
    procedure DovrebbeGirareDueVolteLeFlipComeIdentita;
    [Test]
    procedure DovrebbeTrasporreConLaRotazione;
  end;

  [TestFixture]
  [Category('IdImages')]
  TTestImagingRgbaImage = class
  public
    [Test]
    procedure DovrebbeCreareUnImmagineAZero;
    [Test]
    procedure DovrebbeRifiutareLatiNonValidi;
    [Test]
    procedure DovrebbeRifiutareByteDiLunghezzaSbagliata;
    [Test]
    procedure DovrebbeConfrontareLeImmagini;
    [Test]
    procedure DovrebbeDireVuotaUnaImmagineNonCreata;
  end;

implementation

{ TTestImagingRgbaSampler }

procedure TTestImagingRgbaSampler.DovrebbeCoincidereConIlVeroDropsampleEResample;
const
  SAMPLES: array[0..8, 0..3] of Integer = ((8, 8, 4, 4), (8, 8, 2, 2), (16, 8, 8, 8), (5, 7, 8, 8),
    (8, 8, 16, 16), (3, 5, 2, 2), (4, 4, 5000, 2), (9, 3, 7, 11), (1, 1, 3, 3));
var
  LIndex: Integer;
  LSource: TImagingRgbaImage;
begin
  for LIndex := 0 to 8 do
  begin
    LSource := TIdImagesGolden.Generate(SAMPLES[LIndex, 0], SAMPLES[LIndex, 1], 100 + LIndex, False);
    TIdImagesGolden.Check('drop' + IntToStr(LIndex),
      TImagingRgbaSampler.Dropsample(LSource, SAMPLES[LIndex, 2], SAMPLES[LIndex, 3]));
    TIdImagesGolden.Check('resample' + IntToStr(LIndex),
      TImagingRgbaSampler.Resample(LSource, SAMPLES[LIndex, 2], SAMPLES[LIndex, 3]));
  end;
end;

procedure TTestImagingRgbaSampler.DovrebbeCoincidereConIlVeroMipMap;
const
  SIZES: array[0..8, 0..1] of Integer = ((8, 8), (8, 4), (4, 1), (1, 4), (2, 2), (6, 10), (2, 1),
    (1, 2), (16, 2));
var
  LIndex, LBorder: Integer;
  LSource: TImagingRgbaImage;
begin
  for LIndex := 0 to 8 do
    for LBorder := 0 to 1 do
    begin
      LSource := TIdImagesGolden.Generate(SIZES[LIndex, 0], SIZES[LIndex, 1], 200 + LIndex, False);
      TIdImagesGolden.Check(Format('mip%d_%d', [LIndex, LBorder]),
        TImagingRgbaSampler.MipMap(LSource, LBorder = 1));
    end;
end;

procedure TTestImagingRgbaSampler.DovrebbeCoincidereConIlVeroBlendEFlip;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TIdImagesGolden.Generate(5, 3, 300, False);
  TImagingRgbaSampler.BlendOver(LImage, [200, 100, 50, 77]);
  TIdImagesGolden.Check('blend', LImage);
  LImage := TIdImagesGolden.Generate(5, 3, 301, False);
  TImagingRgbaSampler.HorizontalFlip(LImage);
  TIdImagesGolden.Check('hflip', LImage);
  LImage := TIdImagesGolden.Generate(5, 3, 302, False);
  TImagingRgbaSampler.VerticalFlip(LImage);
  TIdImagesGolden.Check('vflip', LImage);
  LImage := TIdImagesGolden.Generate(6, 6, 303, False);
  TImagingRgbaSampler.RotatePic(LImage);
  TIdImagesGolden.Check('rotate', LImage);
end;

procedure TTestImagingRgbaSampler.DovrebbeRifiutareIlMipMapDiUnPixel;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TImagingRgbaImage.Create(1, 1);
  Assert.WillRaise(
    procedure
    begin
      TImagingRgbaSampler.MipMap(LImage, False);
    end, EImagingException);
end;

procedure TTestImagingRgbaSampler.DovrebbeTagliareIlResampleA4096;
var
  LResult: TImagingRgbaImage;
begin
  LResult := TImagingRgbaSampler.Resample(TImagingRgbaImage.Create(4, 4), 5000, 5000 * 0 + 1);
  Assert.AreEqual(IMAGING_RESAMPLE_MAX_DIMENSION, LResult.Width);
  Assert.AreEqual(1, LResult.Height);
end;

procedure TTestImagingRgbaSampler.DovrebbeRifiutareLaRotazioneDiUnImmagineNonQuadrata;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TImagingRgbaImage.Create(3, 2);
  Assert.WillRaise(
    procedure
    begin
      TImagingRgbaSampler.RotatePic(LImage);
    end, EImagingException);
end;

procedure TTestImagingRgbaSampler.DovrebbeGirareDueVolteLeFlipComeIdentita;
var
  LImage, LOriginal: TImagingRgbaImage;
begin
  LOriginal := TIdImagesGolden.Generate(7, 5, 9, False);
  LImage := TImagingRgbaImage.FromBytes(7, 5, LOriginal.Pixels);
  TImagingRgbaSampler.HorizontalFlip(LImage);
  Assert.IsFalse(LImage.SameAs(LOriginal));
  TImagingRgbaSampler.HorizontalFlip(LImage);
  TImagingRgbaSampler.VerticalFlip(LImage);
  TImagingRgbaSampler.VerticalFlip(LImage);
  Assert.IsTrue(LImage.SameAs(LOriginal));
end;

procedure TTestImagingRgbaSampler.DovrebbeTrasporreConLaRotazione;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TImagingRgbaImage.Create(2, 2);
  LImage.Pixels[4] := 9; // pixel (1, 0), red
  TImagingRgbaSampler.RotatePic(LImage);
  Assert.AreEqual<Integer>(9, LImage.Pixels[8]); // now pixel (0, 1)
  Assert.AreEqual<Integer>(0, LImage.Pixels[4]);
end;

{ TTestImagingRgbaImage }

procedure TTestImagingRgbaImage.DovrebbeCreareUnImmagineAZero;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TImagingRgbaImage.Create(3, 2);
  Assert.AreEqual(24, Length(LImage.Pixels));
  Assert.AreEqual<Integer>(0, LImage.Pixels[23]);
  Assert.IsFalse(LImage.IsEmpty);
end;

procedure TTestImagingRgbaImage.DovrebbeRifiutareLatiNonValidi;
begin
  Assert.WillRaise(
    procedure
    begin
      TImagingRgbaImage.Create(0, 4);
    end, EImagingException);
  Assert.WillRaise(
    procedure
    begin
      TImagingRgbaImage.Create(4, IMAGING_RGBA_MAX_SIDE + 1);
    end, EImagingException);
end;

procedure TTestImagingRgbaImage.DovrebbeRifiutareByteDiLunghezzaSbagliata;
begin
  Assert.WillRaise(
    procedure
    begin
      TImagingRgbaImage.FromBytes(2, 2, TBytes.Create(1, 2, 3));
    end, EImagingException);
end;

procedure TTestImagingRgbaImage.DovrebbeConfrontareLeImmagini;
var
  LA, LB: TImagingRgbaImage;
begin
  LA := TIdImagesGolden.Generate(3, 3, 1, False);
  LB := TImagingRgbaImage.FromBytes(3, 3, LA.Pixels);
  Assert.IsTrue(LA.SameAs(LB));
  LB.Pixels[5] := LB.Pixels[5] xor 1;
  Assert.IsFalse(LA.SameAs(LB));
  Assert.IsFalse(LA.SameAs(TImagingRgbaImage.Create(3, 2)));
end;

procedure TTestImagingRgbaImage.DovrebbeDireVuotaUnaImmagineNonCreata;
var
  LImage: TImagingRgbaImage;
begin
  LImage := Default(TImagingRgbaImage);
  Assert.IsTrue(LImage.IsEmpty);
  Assert.IsTrue(LImage.SameAs(Default(TImagingRgbaImage)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestImagingRgbaSampler);
  TDUnitX.RegisterTestFixture(TTestImagingRgbaImage);

end.
