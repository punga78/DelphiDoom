{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegYccConverter                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.YccConverter;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegYccConverter = class(TObject)
  private
    procedure Convert(AY, ACb, ACr: Integer; out ABlue, AGreen, ARed: Integer);
    function Limited(AValue: Double): Double;
  public
    [Test]
    procedure TestNeutralChromaGivesGray;
    [Test]
    procedure TestWritesBlueGreenRed;
    [Test]
    procedure TestAgreesWithTheFormulaOfJfif;
    [Test]
    procedure TestValuesOutOfRangeAreLimited;
  end;

implementation

uses
  DelphiDoom.Jpeg.ColorConverter, DelphiDoom.Jpeg.YccConverter;

{ TTestJpegYccConverter }

procedure TTestJpegYccConverter.Convert(AY, ACb, ACr: Integer; out ABlue,
  AGreen, ARed: Integer);
var
  LConverter: IJpegColorConverter;
  LY, LCb, LCr: TBytes;
  LOutput: TBytes;
begin
  LConverter := TJpegYccConverter.Create;
  LY := TBytes.Create(AY);
  LCb := TBytes.Create(ACb);
  LCr := TBytes.Create(ACr);
  SetLength(LOutput, 3);
  LConverter.ConvertRow([@LY[0], @LCb[0], @LCr[0]], @LOutput[0], 1);
  ABlue := LOutput[0];
  AGreen := LOutput[1];
  ARed := LOutput[2];
end;

function TTestJpegYccConverter.Limited(AValue: Double): Double;
begin
  if AValue < 0 then
    Result := 0
  else if AValue > 255 then
    Result := 255
  else
    Result := AValue;
end;

procedure TTestJpegYccConverter.TestNeutralChromaGivesGray;
var
  LBlue, LGreen, LRed: Integer;
begin
  Convert(77, 128, 128, LBlue, LGreen, LRed);
  Assert.AreEqual(77, LBlue);
  Assert.AreEqual(77, LGreen);
  Assert.AreEqual(77, LRed);
end;

procedure TTestJpegYccConverter.TestWritesBlueGreenRed;
var
  LBlue, LGreen, LRed: Integer;
begin
  // A lot of Cr is red, a lot of Cb is blue
  Convert(128, 128, 255, LBlue, LGreen, LRed);
  Assert.IsTrue(LRed > LBlue);
  Convert(128, 255, 128, LBlue, LGreen, LRed);
  Assert.IsTrue(LBlue > LRed);
end;

procedure TTestJpegYccConverter.TestAgreesWithTheFormulaOfJfif;
var
  LY, LCb, LCr: Integer;
  LBlue, LGreen, LRed: Integer;
begin
  for LY := 0 to 15 do
    for LCb := 0 to 15 do
      for LCr := 0 to 15 do
      begin
        Convert(LY * 17, LCb * 17, LCr * 17, LBlue, LGreen, LRed);
        Assert.IsTrue(Abs(LRed - Limited(LY * 17 + 1.402 * (LCr * 17 - 128))) <= 1.0, 'Red');
        Assert.IsTrue(Abs(LGreen - Limited(LY * 17 - 0.344136 * (LCb * 17 - 128) -
          0.714136 * (LCr * 17 - 128))) <= 1.0, 'Green');
        Assert.IsTrue(Abs(LBlue - Limited(LY * 17 + 1.772 * (LCb * 17 - 128))) <= 1.0, 'Blue');
      end;
end;

procedure TTestJpegYccConverter.TestValuesOutOfRangeAreLimited;
var
  LBlue, LGreen, LRed: Integer;
begin
  Convert(255, 255, 255, LBlue, LGreen, LRed);
  Assert.AreEqual(255, LBlue);
  Assert.AreEqual(255, LRed);
  Convert(0, 0, 0, LBlue, LGreen, LRed);
  Assert.AreEqual(0, LBlue);
  Assert.AreEqual(0, LRed);
end;

end.
