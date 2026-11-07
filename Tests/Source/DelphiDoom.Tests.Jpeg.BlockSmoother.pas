{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegBlockSmoother                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.BlockSmoother;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.BitReader,
  DelphiDoom.Jpeg.BlockSmoother, DelphiDoom.Jpeg.ByteSource,
  DelphiDoom.Jpeg.ComponentBuffers, DelphiDoom.Jpeg.EntropyDecoder,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.MarkerReader,
  DelphiDoom.Jpeg.ProgressiveDecoder, DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegBlockSmoother = class(TObject)
  private
    FData: TBytes;
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FMarkers: TJpegMarkerReader;
    FBits: TJpegBitReader;
    FDecoder: TJpegProgressiveDecoder;
    FInterface: IJpegEntropyDecoder;
    FBuffers: TJpegComponentBuffers;
    FSmoother: TJpegBlockSmoother;
    procedure Open(AStartScan: Boolean);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestNothingToEstimateBeforeTheDcIsKnown;
    [Test]
    procedure TestNothingToEstimateWhenAQuantizerIsZero;
    [Test]
    procedure TestEstimatesTheHorizontalGradientFromTheNeighbours;
    [Test]
    procedure TestCoefficientsThatAreNotZeroAreKept;
    [Test]
    procedure TestBlocksAtTheEdgesUseThemselvesInPlaceOfTheMissingNeighbours;
  end;

implementation

uses
  DelphiDoom.Tests.Jpeg.TinyStream;

{ TTestJpegBlockSmoother }

procedure TTestJpegBlockSmoother.Open(AStartScan: Boolean);
var
  LColumn: Integer;
begin
  TearDown;
  // The headers of a progressive image of one block, made three blocks wide
  FData := TJpegTinyStream.Build(8, True);
  FSource := TJpegByteSource.Create(Pointer(FData), Length(FData));
  FFrame := TJpegFrame.Create;
  FMarkers := TJpegMarkerReader.Create(FSource, FFrame);
  FBits := TJpegBitReader.Create(FSource, FMarkers);
  FMarkers.ReadMarkers;
  FFrame.PrepareGeometry;
  FFrame.ChooseColorSpace;
  FFrame.PrepareScan;
  FFrame.LatchQuantizationTables;
  FFrame.ComponentByIndex[0]^.WidthInBlocks := 3;

  FDecoder := TJpegProgressiveDecoder.Create(FFrame, FMarkers, FBits);
  FInterface := FDecoder;
  if AStartScan then
    FInterface.StartScan;

  FBuffers := TJpegComponentBuffers.Create(3, 1);
  FBuffers.AllocateCoefficients(3, 1);
  for LColumn := 0 to 2 do
    FBuffers.Block(0, LColumn)^[0] := LColumn * 80;
end;

procedure TTestJpegBlockSmoother.TearDown;
begin
  FreeAndNil(FSmoother);
  FreeAndNil(FBuffers);
  FInterface := nil;
  FDecoder := nil;
  FreeAndNil(FBits);
  FreeAndNil(FMarkers);
  FreeAndNil(FFrame);
  FreeAndNil(FSource);
end;

procedure TTestJpegBlockSmoother.TestNothingToEstimateBeforeTheDcIsKnown;
begin
  Open(False);
  FSmoother := TJpegBlockSmoother.TryCreate(FFrame, FDecoder);
  Assert.IsNull(FSmoother);
end;

procedure TTestJpegBlockSmoother.TestNothingToEstimateWhenAQuantizerIsZero;
begin
  Open(True);
  FFrame.ComponentByIndex[0]^.Quantization[8] := 0;
  FSmoother := TJpegBlockSmoother.TryCreate(FFrame, FDecoder);
  Assert.IsNull(FSmoother);
end;

procedure TTestJpegBlockSmoother.TestEstimatesTheHorizontalGradientFromTheNeighbours;
var
  LBlock: TJpegBlock;
  LIndex: Integer;
begin
  // DC of 0, 80 and 160 with quantizers of 1: the block in the middle has 0
  // on its left and 160 on its right. 36 * 1 * (0 - 160) = -5760;
  // (128 + 5760) / 256 = 23, with the sign of the gradient: -23
  Open(True);
  FSmoother := TJpegBlockSmoother.TryCreate(FFrame, FDecoder);
  Assert.IsNotNull(FSmoother);
  FSmoother.SmoothBlock(0, FFrame.ComponentByIndex[0], FBuffers, 0, 1, LBlock);
  Assert.AreEqual(80, LBlock[0]);
  Assert.AreEqual(-23, LBlock[1]);
  for LIndex := 2 to 63 do
    Assert.AreEqual(0, LBlock[LIndex], 'Coefficient ' + IntToStr(LIndex));
end;

procedure TTestJpegBlockSmoother.TestCoefficientsThatAreNotZeroAreKept;
var
  LBlock: TJpegBlock;
begin
  Open(True);
  FBuffers.Block(0, 1)^[1] := 5;
  FSmoother := TJpegBlockSmoother.TryCreate(FFrame, FDecoder);
  FSmoother.SmoothBlock(0, FFrame.ComponentByIndex[0], FBuffers, 0, 1, LBlock);
  Assert.AreEqual(5, LBlock[1]);
end;

procedure TTestJpegBlockSmoother.TestBlocksAtTheEdgesUseThemselvesInPlaceOfTheMissingNeighbours;
var
  LBlock: TJpegBlock;
begin
  // The first block has no block on its left: it is taken to be itself, so
  // the gradient is (0 - 80), the half of that of the block in the middle:
  // 36 * (0 - 80) = -2880; (128 + 2880) / 256 = 11, with the sign: -11
  Open(True);
  FSmoother := TJpegBlockSmoother.TryCreate(FFrame, FDecoder);
  FSmoother.SmoothBlock(0, FFrame.ComponentByIndex[0], FBuffers, 0, 0, LBlock);
  Assert.AreEqual(-11, LBlock[1]);
end;

end.
