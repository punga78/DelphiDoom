{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegCoefficientTarget and TJpegSampleTarget           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.McuTargets;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.ComponentBuffers,
  DelphiDoom.Jpeg.EntropyDecoder, DelphiDoom.Jpeg.Frame;

type
  /// <summary>
  ///   The base of the fixtures of the two targets: the frame of a 33 x 17
  ///   image at 4:2:0 whose scan has the three components
  /// </summary>
  TJpegTargetFixture = class(TObject)
  protected
    FFrame: TJpegFrame;
    FBuffers: TArray<TJpegComponentBuffers>;
    procedure Prepare;
  public
    [TearDown]
    procedure TearDown;
  end;

  [TestFixture]
  [Category('jpeg')]
  TTestJpegCoefficientTarget = class(TJpegTargetFixture)
  public
    [Test]
    procedure TestBlocksOfAMcuAreTheBlocksOfTheComponents;
    [Test]
    procedure TestSecondMcuIsTwoBlocksToTheRightForLuminance;
  end;

  [TestFixture]
  [Category('jpeg')]
  TTestJpegSampleTarget = class(TJpegTargetFixture)
  public
    [Test]
    procedure TestBlocksStartAtZero;
    [Test]
    procedure TestBlocksInsideTheImageGoToThePlane;
    [Test]
    procedure TestBlocksOutsideTheImageAreDropped;
  end;

implementation

{$POINTERMATH ON}

uses
  DelphiDoom.Jpeg.CoefficientTarget, DelphiDoom.Jpeg.InverseDct,
  DelphiDoom.Jpeg.McuTarget, DelphiDoom.Jpeg.SampleTarget,
  DelphiDoom.Jpeg.SlowInverseDct, DelphiDoom.Jpeg.Types;

{ TJpegTargetFixture }

procedure TJpegTargetFixture.Prepare;
var
  LIndex: Integer;
  LCoefficient: Integer;
  LComponent: PJpegComponentInfo;
begin
  TearDown;
  FFrame := TJpegFrame.Create;
  FFrame.StartOfImage;
  FFrame.SetFrameHeader(33, 17, 8, 3, False, False);
  for LIndex := 0 to 2 do
  begin
    FFrame.ComponentByIndex[LIndex]^.Id := LIndex + 1;
    if LIndex = 0 then
    begin
      FFrame.ComponentByIndex[LIndex]^.Horizontal := 2;
      FFrame.ComponentByIndex[LIndex]^.Vertical := 2;
    end
    else
    begin
      FFrame.ComponentByIndex[LIndex]^.Horizontal := 1;
      FFrame.ComponentByIndex[LIndex]^.Vertical := 1;
    end;
    FFrame.Scan^.Components[LIndex] := LIndex;
  end;
  FFrame.Scan^.ComponentCount := 3;
  FFrame.PrepareGeometry;
  FFrame.PrepareScan;

  SetLength(FBuffers, 3);
  for LIndex := 0 to 2 do
  begin
    LComponent := FFrame.ComponentByIndex[LIndex];
    FBuffers[LIndex] := TJpegComponentBuffers.Create(LComponent^.WidthInBlocks,
      LComponent^.HeightInBlocks);
    FBuffers[LIndex].AllocatePlane;
    FBuffers[LIndex].FillPlane(0);
    FBuffers[LIndex].AllocateCoefficients(
      (LComponent^.WidthInBlocks + LComponent^.Horizontal - 1) div LComponent^.Horizontal *
        LComponent^.Horizontal,
      (LComponent^.HeightInBlocks + LComponent^.Vertical - 1) div LComponent^.Vertical *
        LComponent^.Vertical);
    // Quantizers of one
    for LCoefficient := 0 to 63 do
      LComponent^.Quantization[LCoefficient] := 1;
  end;
end;

procedure TJpegTargetFixture.TearDown;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FBuffers) do
    FBuffers[LIndex].Free;
  FBuffers := nil;
  FreeAndNil(FFrame);
end;

{ TTestJpegCoefficientTarget }

procedure TTestJpegCoefficientTarget.TestBlocksOfAMcuAreTheBlocksOfTheComponents;
var
  LTarget: IJpegMcuTarget;
  LBlocks: TJpegBlockPointers;
begin
  Prepare;
  LTarget := TJpegCoefficientTarget.Create(FFrame, FBuffers);
  LTarget.BeginMcu(1, 2, LBlocks);
  // Luminance: a square of 2 x 2 blocks at the row 2 and the column 4;
  // chroma: one block at the row 1 and the column 2
  Assert.IsTrue(LBlocks[0] = FBuffers[0].Block(2, 4));
  Assert.IsTrue(LBlocks[1] = FBuffers[0].Block(2, 5));
  Assert.IsTrue(LBlocks[2] = FBuffers[0].Block(3, 4));
  Assert.IsTrue(LBlocks[3] = FBuffers[0].Block(3, 5));
  Assert.IsTrue(LBlocks[4] = FBuffers[1].Block(1, 2));
  Assert.IsTrue(LBlocks[5] = FBuffers[2].Block(1, 2));
end;

procedure TTestJpegCoefficientTarget.TestSecondMcuIsTwoBlocksToTheRightForLuminance;
var
  LTarget: IJpegMcuTarget;
  LFirst, LSecond: TJpegBlockPointers;
begin
  Prepare;
  LTarget := TJpegCoefficientTarget.Create(FFrame, FBuffers);
  LTarget.BeginMcu(0, 0, LFirst);
  LTarget.BeginMcu(0, 1, LSecond);
  Assert.IsTrue(LSecond[0] = FBuffers[0].Block(0, 2));
  Assert.IsTrue(LFirst[0] = FBuffers[0].Block(0, 0));
end;

{ TTestJpegSampleTarget }

procedure TTestJpegSampleTarget.TestBlocksStartAtZero;
var
  LTarget: IJpegMcuTarget;
  LBlocks: TJpegBlockPointers;
  LIndex: Integer;
begin
  Prepare;
  LTarget := TJpegSampleTarget.Create(FFrame, FBuffers, TJpegSlowInverseDct.Create);
  LTarget.BeginMcu(0, 0, LBlocks);
  LBlocks[0]^[0] := 77;
  LTarget.EndMcu(0, 0);
  // The next MCU starts again from zero blocks
  LTarget.BeginMcu(0, 1, LBlocks);
  for LIndex := 0 to 63 do
    Assert.AreEqual(0, LBlocks[0]^[LIndex]);
end;

procedure TTestJpegSampleTarget.TestBlocksInsideTheImageGoToThePlane;
var
  LTarget: IJpegMcuTarget;
  LBlocks: TJpegBlockPointers;
begin
  Prepare;
  LTarget := TJpegSampleTarget.Create(FFrame, FBuffers, TJpegSlowInverseDct.Create);
  LTarget.BeginMcu(0, 0, LBlocks);
  // The second luminance block of the MCU (at the right of the first) with a
  // DC of 80: the samples are 138
  LBlocks[1]^[0] := 80;
  LTarget.EndMcu(0, 0);
  Assert.AreEqual(138, Integer(FBuffers[0].PlaneRow(0)[8]));
  Assert.AreEqual(138, Integer(FBuffers[0].PlaneRow(7)[15]));
  // The first block has DC 0: gray
  Assert.AreEqual(128, Integer(FBuffers[0].PlaneRow(0)[0]));
end;

procedure TTestJpegSampleTarget.TestBlocksOutsideTheImageAreDropped;
var
  LTarget: IJpegMcuTarget;
  LBlocks: TJpegBlockPointers;
begin
  Prepare;
  // 33 x 17 samples are 5 x 3 blocks of luminance; the last MCU of a row is at
  // the column 2 (blocks 4 and 5): the block 5 is outside of the image
  LTarget := TJpegSampleTarget.Create(FFrame, FBuffers, TJpegSlowInverseDct.Create);
  LTarget.BeginMcu(0, 2, LBlocks);
  LBlocks[0]^[0] := 80;
  LBlocks[1]^[0] := 80;
  LTarget.EndMcu(0, 2);
  Assert.AreEqual(138, Integer(FBuffers[0].PlaneRow(0)[32]), 'Block 4');
  // The plane is 40 samples wide: the block 5 would have gone at the start of
  // the next row
  Assert.AreEqual(40, FBuffers[0].PlaneStride);
  Assert.AreEqual(0, Integer(FBuffers[0].PlaneRow(1)[0]), 'Block 5');
end;

end.
