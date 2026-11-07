{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegFancyUpsamplerH2V1                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.FancyUpsamplerH2V1;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegFancyUpsamplerH2V1 = class(TObject)
  public
    [Test]
    procedure TestTriangleFilter;
    [Test]
    procedure TestFlatRowStaysFlat;
  end;

implementation

uses
  DelphiDoom.Jpeg.FancyUpsamplerH2V1, DelphiDoom.Jpeg.RowUpsampler,
  DelphiDoom.Tests.Jpeg.Rows;

{ TTestJpegFancyUpsamplerH2V1 }

procedure TTestJpegFancyUpsamplerH2V1.TestTriangleFilter;
var
  LUpsampler: IJpegRowUpsampler;
  LInput: TBytes;
  LOutput: TBytes;
begin
  // The ends are kept; each other sample is 3/4 of the nearest and 1/4 of
  // the next: (3 * 10 + 20 + 2) / 4 = 13, (3 * 20 + 10 + 1) / 4 = 17 ...
  LUpsampler := TJpegFancyUpsamplerH2V1.Create(3);
  LInput := TBytes.Create(10, 20, 30);
  SetLength(LOutput, 6);
  LUpsampler.UpsampleRow(@LInput[0], nil, @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([10, 13, 17, 23, 27, 30], LOutput);
end;

procedure TTestJpegFancyUpsamplerH2V1.TestFlatRowStaysFlat;
var
  LUpsampler: IJpegRowUpsampler;
  LInput: TBytes;
  LOutput: TBytes;
begin
  LUpsampler := TJpegFancyUpsamplerH2V1.Create(4);
  LInput := TBytes.Create(77, 77, 77, 77);
  SetLength(LOutput, 8);
  LUpsampler.UpsampleRow(@LInput[0], nil, @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([77, 77, 77, 77, 77, 77, 77, 77], LOutput);
end;

end.
