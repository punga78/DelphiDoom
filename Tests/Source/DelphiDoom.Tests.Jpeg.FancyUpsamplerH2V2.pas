{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegFancyUpsamplerH2V2                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.FancyUpsamplerH2V2;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegFancyUpsamplerH2V2 = class(TObject)
  public
    [Test]
    procedure TestTriangleFilterWithTheNeighbourRow;
    [Test]
    procedure TestFlatRowsStayFlat;
  end;

implementation

uses
  DelphiDoom.Jpeg.FancyUpsamplerH2V2, DelphiDoom.Jpeg.RowUpsampler,
  DelphiDoom.Tests.Jpeg.Rows;

{ TTestJpegFancyUpsamplerH2V2 }

procedure TTestJpegFancyUpsamplerH2V2.TestTriangleFilterWithTheNeighbourRow;
var
  LUpsampler: IJpegRowUpsampler;
  LRow, LNeighbour: TBytes;
  LOutput: TBytes;
begin
  // The sums of the columns are 3 * row + neighbour: 48, 96, 144. The first
  // is (48 * 4 + 8) / 16 = 12, then (48 * 3 + 96 + 7) / 16 = 15 ...
  LUpsampler := TJpegFancyUpsamplerH2V2.Create(3);
  LRow := TBytes.Create(16, 32, 48);
  LNeighbour := TBytes.Create(0, 0, 0);
  SetLength(LOutput, 6);
  LUpsampler.UpsampleRow(@LRow[0], @LNeighbour[0], @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([12, 15, 21, 27, 33, 36], LOutput);
end;

procedure TTestJpegFancyUpsamplerH2V2.TestFlatRowsStayFlat;
var
  LUpsampler: IJpegRowUpsampler;
  LRow: TBytes;
  LOutput: TBytes;
begin
  LUpsampler := TJpegFancyUpsamplerH2V2.Create(4);
  LRow := TBytes.Create(50, 50, 50, 50);
  SetLength(LOutput, 8);
  LUpsampler.UpsampleRow(@LRow[0], @LRow[0], @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([50, 50, 50, 50, 50, 50, 50, 50], LOutput);
end;

end.
