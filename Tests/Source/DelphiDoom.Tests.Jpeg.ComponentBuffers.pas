{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegComponentBuffers                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.ComponentBuffers;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegComponentBuffers = class(TObject)
  public
    [Test]
    procedure TestPlaneHasAWholeNumberOfBlocks;
    [Test]
    procedure TestRowsOfThePlaneFollowEachOther;
    [Test]
    procedure TestFillPlaneSetsEverySample;
    [Test]
    procedure TestCoefficientsStartAtZeroAndBlocksDoNotOverlap;
    [Test]
    procedure TestHugePlaneIsOutOfMemory;
  end;

implementation

{$POINTERMATH ON}

uses
  DelphiDoom.Jpeg.ComponentBuffers, DelphiDoom.Jpeg.Types;

{ TTestJpegComponentBuffers }

procedure TTestJpegComponentBuffers.TestPlaneHasAWholeNumberOfBlocks;
var
  LBuffers: TJpegComponentBuffers;
begin
  LBuffers := TJpegComponentBuffers.Create(3, 2);
  try
    Assert.AreEqual(24, LBuffers.PlaneStride);
    Assert.AreEqual(16, LBuffers.PlaneRows);
  finally
    LBuffers.Free;
  end;
end;

procedure TTestJpegComponentBuffers.TestRowsOfThePlaneFollowEachOther;
var
  LBuffers: TJpegComponentBuffers;
begin
  LBuffers := TJpegComponentBuffers.Create(2, 2);
  try
    LBuffers.AllocatePlane;
    LBuffers.PlaneRow(0)^ := 1;
    LBuffers.PlaneRow(5)^ := 2;
    LBuffers.PlaneRow(15)[15] := 3;
    Assert.AreEqual(16, Integer(LBuffers.PlaneRow(1) - LBuffers.PlaneRow(0)));
    Assert.AreEqual(1, Integer(LBuffers.PlaneRow(0)^));
    Assert.AreEqual(2, Integer(LBuffers.PlaneRow(5)^));
    Assert.AreEqual(3, Integer((LBuffers.PlaneRow(15) + 15)^));
  finally
    LBuffers.Free;
  end;
end;

procedure TTestJpegComponentBuffers.TestFillPlaneSetsEverySample;
var
  LBuffers: TJpegComponentBuffers;
begin
  LBuffers := TJpegComponentBuffers.Create(1, 1);
  try
    LBuffers.AllocatePlane;
    LBuffers.FillPlane(128);
    Assert.AreEqual(128, Integer(LBuffers.PlaneRow(0)^));
    Assert.AreEqual(128, Integer((LBuffers.PlaneRow(7) + 7)^));
  finally
    LBuffers.Free;
  end;
end;

procedure TTestJpegComponentBuffers.TestCoefficientsStartAtZeroAndBlocksDoNotOverlap;
var
  LBuffers: TJpegComponentBuffers;
  LIndex: Integer;
begin
  LBuffers := TJpegComponentBuffers.Create(3, 2);
  try
    LBuffers.AllocateCoefficients(4, 3);
    Assert.AreEqual(4, LBuffers.BlockColumns);
    Assert.AreEqual(3, LBuffers.BlockRows);
    for LIndex := 0 to 63 do
      Assert.AreEqual(0, LBuffers.Block(2, 3)^[LIndex]);
    LBuffers.Block(1, 2)^[63] := 9;
    Assert.AreEqual(0, LBuffers.Block(1, 3)^[0]);
    Assert.AreEqual(9, LBuffers.Block(1, 2)^[63]);
    Assert.AreEqual(64 * 4 * SizeOf(Integer), Integer(PByte(LBuffers.Block(1, 0)) -
      PByte(LBuffers.Block(0, 0))));
  finally
    LBuffers.Free;
  end;
end;

procedure TTestJpegComponentBuffers.TestHugePlaneIsOutOfMemory;
var
  LBuffers: TJpegComponentBuffers;
begin
  LBuffers := TJpegComponentBuffers.Create(60000, 60000);
  try
    Assert.WillRaise(
      procedure
      begin
        LBuffers.AllocatePlane;
      end, EOutOfMemory);
  finally
    LBuffers.Free;
  end;
end;

end.
