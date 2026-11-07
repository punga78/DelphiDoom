{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegFrame                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Frame;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegFrame = class(TObject)
  private
    FFrame: TJpegFrame;
    procedure SetUpFrame(AWidth, AHeight, ACount: Integer; const AHorizontal,
      AVertical: array of Integer; AProgressive: Boolean = False);
    procedure SetScan(const AComponents: array of Integer);
    procedure AssertFails(AExpected: TJpegDecodeError; AAction: TProc);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestGeometryOfAnImageWithChromaSubsampling;
    [Test]
    procedure TestSingleScanOfAllComponentsIsNotMultiple;
    [Test]
    procedure TestPartialScanOrProgressiveFrameIsMultiple;
    [Test]
    procedure TestPrepareScanOfAllComponents;
    [Test]
    procedure TestPrepareScanOfOneComponent;
    [Test]
    procedure TestColorSpaceFromTheComponentsAndTheMarkers;
    [Test]
    procedure TestLimitsOfTheGeometry;
    [Test]
    procedure TestTooManyBlocksInAMcu;
    [Test]
    procedure TestQuantizationTableIsKeptFromTheFirstScan;
    [Test]
    procedure TestMissingQuantizationTable;
  end;

implementation

{ TTestJpegFrame }

procedure TTestJpegFrame.Setup;
begin
  FFrame := TJpegFrame.Create;
end;

procedure TTestJpegFrame.TearDown;
begin
  FFrame.Free;
end;

procedure TTestJpegFrame.SetUpFrame(AWidth, AHeight, ACount: Integer;
  const AHorizontal, AVertical: array of Integer; AProgressive: Boolean);
var
  LIndex: Integer;
begin
  FFrame.StartOfImage;
  FFrame.SetFrameHeader(AWidth, AHeight, 8, ACount, AProgressive, False);
  for LIndex := 0 to ACount - 1 do
  begin
    FFrame.ComponentByIndex[LIndex]^.Id := LIndex + 1;
    FFrame.ComponentByIndex[LIndex]^.Horizontal := AHorizontal[LIndex];
    FFrame.ComponentByIndex[LIndex]^.Vertical := AVertical[LIndex];
  end;
end;

procedure TTestJpegFrame.SetScan(const AComponents: array of Integer);
var
  LIndex: Integer;
begin
  FFrame.Scan^.ComponentCount := Length(AComponents);
  for LIndex := 0 to High(AComponents) do
    FFrame.Scan^.Components[LIndex] := AComponents[LIndex];
end;

procedure TTestJpegFrame.AssertFails(AExpected: TJpegDecodeError; AAction: TProc);
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    AAction();
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(AExpected), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised, 'The error was not raised');
end;

procedure TTestJpegFrame.TestGeometryOfAnImageWithChromaSubsampling;
begin
  SetUpFrame(33, 17, 3, [2, 1, 1], [2, 1, 1]);
  SetScan([0, 1, 2]);
  FFrame.PrepareGeometry;

  Assert.AreEqual(2, FFrame.MaxHorizontal);
  Assert.AreEqual(2, FFrame.MaxVertical);
  Assert.AreEqual(2, FFrame.TotalMcuRows);
  // Luminance: 33 x 17 samples are 5 x 3 blocks; chroma is half: 17 x 9
  Assert.AreEqual(5, FFrame.ComponentByIndex[0]^.WidthInBlocks);
  Assert.AreEqual(3, FFrame.ComponentByIndex[0]^.HeightInBlocks);
  Assert.AreEqual(33, FFrame.ComponentByIndex[0]^.DownsampledWidth);
  Assert.AreEqual(17, FFrame.ComponentByIndex[0]^.DownsampledHeight);
  Assert.AreEqual(3, FFrame.ComponentByIndex[1]^.WidthInBlocks);
  Assert.AreEqual(2, FFrame.ComponentByIndex[1]^.HeightInBlocks);
  Assert.AreEqual(17, FFrame.ComponentByIndex[1]^.DownsampledWidth);
  Assert.AreEqual(9, FFrame.ComponentByIndex[1]^.DownsampledHeight);
end;

procedure TTestJpegFrame.TestSingleScanOfAllComponentsIsNotMultiple;
begin
  SetUpFrame(16, 16, 3, [1, 1, 1], [1, 1, 1]);
  SetScan([0, 1, 2]);
  FFrame.PrepareGeometry;
  Assert.IsFalse(FFrame.HasMultipleScans);
end;

procedure TTestJpegFrame.TestPartialScanOrProgressiveFrameIsMultiple;
begin
  SetUpFrame(16, 16, 3, [1, 1, 1], [1, 1, 1]);
  SetScan([0]);
  FFrame.PrepareGeometry;
  Assert.IsTrue(FFrame.HasMultipleScans);

  SetUpFrame(16, 16, 1, [1], [1], True);
  SetScan([0]);
  FFrame.PrepareGeometry;
  Assert.IsTrue(FFrame.HasMultipleScans);
end;

procedure TTestJpegFrame.TestPrepareScanOfAllComponents;
var
  LScan: PJpegScanInfo;
begin
  SetUpFrame(33, 17, 3, [2, 1, 1], [2, 1, 1]);
  SetScan([0, 1, 2]);
  FFrame.PrepareGeometry;
  FFrame.PrepareScan;

  LScan := FFrame.Scan;
  Assert.AreEqual(3, LScan^.McusPerRow);
  Assert.AreEqual(2, LScan^.McuRowsInScan);
  Assert.AreEqual(6, LScan^.BlocksInMcu);
  // Four blocks of luminance, one of each chroma
  Assert.AreEqual(0, LScan^.McuMembership[0]);
  Assert.AreEqual(0, LScan^.McuMembership[3]);
  Assert.AreEqual(1, LScan^.McuMembership[4]);
  Assert.AreEqual(2, LScan^.McuMembership[5]);
  Assert.AreEqual(2, FFrame.ComponentByIndex[0]^.McuWidth);
  Assert.AreEqual(4, FFrame.ComponentByIndex[0]^.McuBlocks);
  // 5 blocks across: the last MCU has one; 3 down: the last has one
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.LastColumnWidth);
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.LastRowHeight);
  Assert.AreEqual(1, FFrame.ComponentByIndex[1]^.LastColumnWidth);
end;

procedure TTestJpegFrame.TestPrepareScanOfOneComponent;
var
  LScan: PJpegScanInfo;
begin
  SetUpFrame(33, 17, 3, [2, 1, 1], [2, 1, 1]);
  SetScan([0]);
  FFrame.PrepareGeometry;
  FFrame.PrepareScan;

  // One block per MCU: the blocks of the component, not of the image
  LScan := FFrame.Scan;
  Assert.AreEqual(5, LScan^.McusPerRow);
  Assert.AreEqual(3, LScan^.McuRowsInScan);
  Assert.AreEqual(1, LScan^.BlocksInMcu);
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.McuWidth);
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.McuHeight);
end;

procedure TTestJpegFrame.TestColorSpaceFromTheComponentsAndTheMarkers;
begin
  SetUpFrame(8, 8, 1, [1], [1]);
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsGrayscale), Ord(FFrame.ColorSpace));

  SetUpFrame(8, 8, 3, [1, 1, 1], [1, 1, 1]);
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsYCbCr), Ord(FFrame.ColorSpace), 'Identifiers 1, 2, 3');

  FFrame.ComponentByIndex[0]^.Id := 82;
  FFrame.ComponentByIndex[1]^.Id := 71;
  FFrame.ComponentByIndex[2]^.Id := 66;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsRgb), Ord(FFrame.ColorSpace), 'Identifiers R, G, B');

  FFrame.SawJfif := True;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsYCbCr), Ord(FFrame.ColorSpace), 'JFIF');

  FFrame.SawJfif := False;
  FFrame.SawAdobe := True;
  FFrame.AdobeTransform := 0;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsRgb), Ord(FFrame.ColorSpace), 'Adobe 0');
  FFrame.AdobeTransform := 1;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsYCbCr), Ord(FFrame.ColorSpace), 'Adobe 1');
  FFrame.AdobeTransform := 9;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsYCbCr), Ord(FFrame.ColorSpace), 'Adobe, any other code');

  SetUpFrame(8, 8, 4, [1, 1, 1, 1], [1, 1, 1, 1]);
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsCmyk), Ord(FFrame.ColorSpace));
  FFrame.SawAdobe := True;
  FFrame.AdobeTransform := 2;
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsYcck), Ord(FFrame.ColorSpace));

  SetUpFrame(8, 8, 2, [1, 1], [1, 1]);
  FFrame.ChooseColorSpace;
  Assert.AreEqual(Ord(jcsUnknown), Ord(FFrame.ColorSpace));
end;

procedure TTestJpegFrame.TestLimitsOfTheGeometry;
begin
  SetScan([0]);
  SetUpFrame(70000, 8, 1, [1], [1]);
  FFrame.Scan^.ComponentCount := 1;
  AssertFails(jdeImageTooBig, procedure begin FFrame.PrepareGeometry; end);

  SetUpFrame(8, 8, 1, [1], [1]);
  FFrame.Scan^.ComponentCount := 1;
  FFrame.SetFrameHeader(8, 8, 12, 1, False, False);
  FFrame.ComponentByIndex[0]^.Horizontal := 1;
  FFrame.ComponentByIndex[0]^.Vertical := 1;
  AssertFails(jdeBadPrecision, procedure begin FFrame.PrepareGeometry; end);

  SetUpFrame(8, 8, 1, [5], [1]);
  FFrame.Scan^.ComponentCount := 1;
  AssertFails(jdeBadSampling, procedure begin FFrame.PrepareGeometry; end);

  SetUpFrame(8, 8, 1, [0], [1]);
  FFrame.Scan^.ComponentCount := 1;
  AssertFails(jdeBadSampling, procedure begin FFrame.PrepareGeometry; end);
end;

procedure TTestJpegFrame.TestTooManyBlocksInAMcu;
begin
  // Three components of 4 x 1 blocks make 12 blocks in a MCU
  SetUpFrame(32, 8, 3, [4, 4, 4], [1, 1, 1]);
  SetScan([0, 1, 2]);
  FFrame.PrepareGeometry;
  AssertFails(jdeBadMcuSize, procedure begin FFrame.PrepareScan; end);
end;

procedure TTestJpegFrame.TestQuantizationTableIsKeptFromTheFirstScan;
begin
  SetUpFrame(8, 8, 1, [1], [1]);
  SetScan([0]);
  FFrame.PrepareGeometry;
  FFrame.Quantization[0]^.Defined := True;
  FFrame.Quantization[0]^.Values[5] := 7;
  FFrame.LatchQuantizationTables;
  Assert.AreEqual(7, FFrame.ComponentByIndex[0]^.Quantization[5]);

  // A table sent later with the same number does not change what the
  // component has
  FFrame.Quantization[0]^.Values[5] := 99;
  FFrame.LatchQuantizationTables;
  Assert.AreEqual(7, FFrame.ComponentByIndex[0]^.Quantization[5]);
end;

procedure TTestJpegFrame.TestMissingQuantizationTable;
begin
  SetUpFrame(8, 8, 1, [1], [1]);
  SetScan([0]);
  FFrame.PrepareGeometry;
  AssertFails(jdeMissingQuantizationTable, procedure begin FFrame.LatchQuantizationTables; end);

  FFrame.ComponentByIndex[0]^.QuantizationNumber := 9;
  FFrame.Quantization[0]^.Defined := True;
  AssertFails(jdeMissingQuantizationTable, procedure begin FFrame.LatchQuantizationTables; end);
end;

end.
