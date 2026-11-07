{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegProgressiveDecoder                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.ProgressiveDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.BitReader,
  DelphiDoom.Jpeg.ByteSource, DelphiDoom.Jpeg.EntropyDecoder, DelphiDoom.Jpeg.Frame,
  DelphiDoom.Jpeg.MarkerReader, DelphiDoom.Jpeg.ProgressiveDecoder,
  DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegProgressiveDecoder = class(TObject)
  private
    FData: TBytes;
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FMarkers: TJpegMarkerReader;
    FBits: TJpegBitReader;
    FDecoder: TJpegProgressiveDecoder;
    FInterface: IJpegEntropyDecoder;
    FBlock: TJpegBlock;
    procedure Open(ADc: Integer);
    procedure DecodeOne;
    procedure AssertStartFails(AExpected: TJpegDecodeError);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDecodesTheFirstScanOfTheDc;
    [Test]
    procedure TestTheDcIsShiftedByTheApproximation;
    [Test]
    procedure TestRemembersWhatIsKnownOfTheCoefficients;
    [Test]
    procedure TestRefinementAddsTheNextBitOfTheDc;
    [Test]
    procedure TestParametersThatAreNotValidAreRefused;
  end;

implementation

uses
  DelphiDoom.Tests.Jpeg.TinyStream;

{ TTestJpegProgressiveDecoder }

procedure TTestJpegProgressiveDecoder.Open(ADc: Integer);
begin
  TearDown;
  FData := TJpegTinyStream.Build(ADc, True);
  FSource := TJpegByteSource.Create(Pointer(FData), Length(FData));
  FFrame := TJpegFrame.Create;
  FMarkers := TJpegMarkerReader.Create(FSource, FFrame);
  FBits := TJpegBitReader.Create(FSource, FMarkers);
  FMarkers.ReadMarkers;
  FFrame.PrepareGeometry;
  FFrame.ChooseColorSpace;
  FFrame.PrepareScan;
  FFrame.LatchQuantizationTables;
  FDecoder := TJpegProgressiveDecoder.Create(FFrame, FMarkers, FBits);
  FInterface := FDecoder;
end;

procedure TTestJpegProgressiveDecoder.DecodeOne;
var
  LBlocks: TJpegBlockPointers;
begin
  LBlocks[0] := @FBlock;
  FInterface.DecodeMcu(LBlocks);
end;

procedure TTestJpegProgressiveDecoder.TearDown;
begin
  FInterface := nil;
  FDecoder := nil;
  FreeAndNil(FBits);
  FreeAndNil(FMarkers);
  FreeAndNil(FFrame);
  FreeAndNil(FSource);
end;

procedure TTestJpegProgressiveDecoder.AssertStartFails(AExpected: TJpegDecodeError);
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    FInterface.StartScan;
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(AExpected), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised, 'The error was not raised');
end;

procedure TTestJpegProgressiveDecoder.TestDecodesTheFirstScanOfTheDc;
begin
  Open(8);
  FInterface.StartScan;
  FillChar(FBlock, SizeOf(FBlock), 0);
  DecodeOne;
  Assert.AreEqual(8, FBlock[0]);
  Assert.AreEqual(0, FBlock[1]);
end;

procedure TTestJpegProgressiveDecoder.TestTheDcIsShiftedByTheApproximation;
begin
  Open(5);
  FFrame.Scan^.ApproximationLow := 2;
  FInterface.StartScan;
  FillChar(FBlock, SizeOf(FBlock), 0);
  DecodeOne;
  Assert.AreEqual(20, FBlock[0]);
end;

procedure TTestJpegProgressiveDecoder.TestRemembersWhatIsKnownOfTheCoefficients;
begin
  Open(8);
  Assert.AreEqual(-1, FDecoder.CoefficientBit(0, 0));
  FFrame.Scan^.ApproximationLow := 1;
  FInterface.StartScan;
  Assert.AreEqual(1, FDecoder.CoefficientBit(0, 0), 'The DC lacks one bit');
  Assert.AreEqual(-1, FDecoder.CoefficientBit(0, 1), 'The AC were not sent');
  Assert.AreEqual(-1, FDecoder.CoefficientBit(1, 0), 'Another component');
end;

procedure TTestJpegProgressiveDecoder.TestRefinementAddsTheNextBitOfTheDc;
begin
  // A refinement scan of the DC (Ah = 1, Al = 0) reads one bit for each block
  // and adds it at the position Al. The first bit of the data of the test
  // stream is the first bit of the code of the size of the DC: 0 for the sizes
  // up to 7 (codes 0000 to 0111), 1 from the size 8 on
  Open(8);
  FFrame.Scan^.ApproximationHigh := 1;
  FFrame.Scan^.ApproximationLow := 0;
  FInterface.StartScan;
  FBlock[0] := 6;
  DecodeOne;
  Assert.AreEqual(6, FBlock[0], 'Bit 0');

  Open(200);
  FFrame.Scan^.ApproximationHigh := 1;
  FFrame.Scan^.ApproximationLow := 0;
  FInterface.StartScan;
  FBlock[0] := 6;
  DecodeOne;
  Assert.AreEqual(7, FBlock[0], 'Bit 1');
end;

procedure TTestJpegProgressiveDecoder.TestParametersThatAreNotValidAreRefused;
begin
  // The DC with a band of more than one coefficient
  Open(8);
  FFrame.Scan^.SpectralEnd := 5;
  AssertStartFails(jdeBadProgression);

  // Refinement that is not of the previous bit
  Open(8);
  FFrame.Scan^.ApproximationHigh := 3;
  FFrame.Scan^.ApproximationLow := 0;
  AssertStartFails(jdeBadProgression);

  // Al of more than 13
  Open(8);
  FFrame.Scan^.ApproximationLow := 14;
  AssertStartFails(jdeBadProgression);

  // AC coefficients of more than one component
  Open(8);
  FFrame.Scan^.SpectralStart := 1;
  FFrame.Scan^.SpectralEnd := 5;
  FFrame.Scan^.ComponentCount := 2;
  AssertStartFails(jdeBadProgression);

  // Band that goes past the block
  Open(8);
  FFrame.Scan^.SpectralStart := 1;
  FFrame.Scan^.SpectralEnd := 64;
  AssertStartFails(jdeBadProgression);
end;

end.
