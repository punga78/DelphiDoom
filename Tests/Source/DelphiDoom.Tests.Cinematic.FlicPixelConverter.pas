{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TFlicPixelConverter (issue #199)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicPixelConverter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('cinematic')]
  TTestFlicPixelConverter = class(TObject)
  public
    [Test]
    procedure DovrebbeMettereIlRossoNelByteBassoEAlphaOpaco;
    [Test]
    procedure DovrebbeDareUnPixelPerOgniIndiceConLaPalette;
    [Test]
    procedure DovrebbeDareUnaImmagineVuotaPerUnBufferVuoto;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Flic.Types,
  DelphiDoom.Cinematic.Flic.PixelConverter;

{ TTestFlicPixelConverter }

procedure TTestFlicPixelConverter.DovrebbeMettereIlRossoNelByteBassoEAlphaOpaco;
begin
  Assert.AreEqual(Cardinal($FFCC8811), TFlicPixelConverter.ColorToPixel($11, $88, $CC));
end;

procedure TTestFlicPixelConverter.DovrebbeDareUnPixelPerOgniIndiceConLaPalette;
var
  LPalette: TFlicPalette;
  LPixels: TArray<Cardinal>;
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    LPalette[LIndex] := TFlicPixelConverter.ColorToPixel(LIndex, 255 - LIndex, 7);
  LPixels := TFlicPixelConverter.ToPixels(TBytes.Create(0, 255, 3, 3), LPalette);
  Assert.AreEqual<Integer>(4, Length(LPixels));
  Assert.AreEqual(LPalette[0], LPixels[0]);
  Assert.AreEqual(LPalette[255], LPixels[1]);
  Assert.AreEqual(LPalette[3], LPixels[2]);
  Assert.AreEqual(LPalette[3], LPixels[3]);
end;

procedure TTestFlicPixelConverter.DovrebbeDareUnaImmagineVuotaPerUnBufferVuoto;
var
  LPalette: TFlicPalette;
begin
  FillChar(LPalette, SizeOf(LPalette), 0);
  Assert.AreEqual<Integer>(0, Length(TFlicPixelConverter.ToPixels(nil, LPalette)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFlicPixelConverter);

end.
