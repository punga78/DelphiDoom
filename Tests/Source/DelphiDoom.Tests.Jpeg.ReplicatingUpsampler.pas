{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegReplicatingUpsampler                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.ReplicatingUpsampler;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegReplicatingUpsampler = class(TObject)
  public
    [Test]
    procedure TestRepeatsEachSampleTwice;
    [Test]
    procedure TestOddWidthWritesTheWholeLastGroup;
    [Test]
    procedure TestRepeatsEachSampleThreeTimes;
  end;

implementation

uses
  DelphiDoom.Jpeg.ReplicatingUpsampler, DelphiDoom.Jpeg.RowUpsampler,
  DelphiDoom.Tests.Jpeg.Rows;

{ TTestJpegReplicatingUpsampler }

procedure TTestJpegReplicatingUpsampler.TestRepeatsEachSampleTwice;
var
  LUpsampler: IJpegRowUpsampler;
  LInput: TBytes;
  LOutput: TBytes;
begin
  LUpsampler := TJpegReplicatingUpsampler.Create(2, 6);
  LInput := TBytes.Create(10, 20, 30);
  SetLength(LOutput, 8);
  LUpsampler.UpsampleRow(@LInput[0], nil, @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([10, 10, 20, 20, 30, 30], LOutput);
end;

procedure TTestJpegReplicatingUpsampler.TestOddWidthWritesTheWholeLastGroup;
var
  LUpsampler: IJpegRowUpsampler;
  LInput: TBytes;
  LOutput: TBytes;
begin
  // 5 pixels: three samples; the sixth byte is written too
  LUpsampler := TJpegReplicatingUpsampler.Create(2, 5);
  LInput := TBytes.Create(10, 20, 30, 99);
  SetLength(LOutput, 8);
  FillChar(LOutput[0], 8, 7);
  LUpsampler.UpsampleRow(@LInput[0], nil, @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([10, 10, 20, 20, 30, 30, 7], LOutput);
end;

procedure TTestJpegReplicatingUpsampler.TestRepeatsEachSampleThreeTimes;
var
  LUpsampler: IJpegRowUpsampler;
  LInput: TBytes;
  LOutput: TBytes;
begin
  LUpsampler := TJpegReplicatingUpsampler.Create(3, 6);
  LInput := TBytes.Create(1, 2);
  SetLength(LOutput, 8);
  LUpsampler.UpsampleRow(@LInput[0], nil, @LOutput[0]);
  TJpegRowChecks.AssertStartsWith([1, 1, 1, 2, 2, 2], LOutput);
end;

end.
