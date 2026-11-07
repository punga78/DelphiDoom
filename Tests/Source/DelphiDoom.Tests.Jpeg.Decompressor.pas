{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegDecompressor                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Decompressor;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Decompressor,
  DelphiDoom.Tests.Jpeg.Synthesizer;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegDecompressor = class(TObject)
  private
    function DecodeBytes(const AStream: TBytes; out AWidth, AHeight, AComponents: Integer): TBytes;
    procedure AssertSameImage(const ASpecA, ASpecB: TJpegSpec);
  public
    [Test]
    procedure TestHeaderGivesSizeAndOutputComponents;
    [Test]
    procedure TestCmykHasNoConversionButItsHeaderIsRead;
    [Test]
    procedure TestSequentialScansInAnyOrderGiveTheSameImage;
    [Test]
    procedure TestProgressiveImageEqualsTheSequentialOne;
    [Test]
    procedure TestProgressiveImageWithSpectralSelectionEqualsTheSequentialOne;
    [Test]
    procedure TestProgressiveWithRestartIntervalEqualsTheSequentialOne;
    [Test]
    procedure TestSubsampledProgressiveImageEqualsTheSequentialOne;
    [Test]
    procedure TestRestartIntervalDoesNotChangeTheImage;
    [Test]
    procedure TestEndOfImageBeforeAnyScan;
    [Test]
    procedure TestImageThatIsCutIsTruncated;
  end;

implementation

uses
  DelphiDoom.Jpeg.Types;

{ TTestJpegDecompressor }

function TTestJpegDecompressor.DecodeBytes(const AStream: TBytes; out AWidth,
  AHeight, AComponents: Integer): TBytes;
var
  LDecompressor: TJpegDecompressor;
begin
  LDecompressor := TJpegDecompressor.Create(Pointer(AStream), Length(AStream));
  try
    LDecompressor.ReadHeader;
    AWidth := LDecompressor.Width;
    AHeight := LDecompressor.Height;
    AComponents := LDecompressor.OutputComponents;
    SetLength(Result, AWidth * AHeight * AComponents);
    LDecompressor.Decompress(Pointer(Result), AWidth * AComponents);
  finally
    LDecompressor.Free;
  end;
end;

procedure TTestJpegDecompressor.AssertSameImage(const ASpecA, ASpecB: TJpegSpec);
var
  LFirst, LSecond: TBytes;
  LWidth, LHeight, LComponents: Integer;
begin
  LFirst := DecodeBytes(TJpegSynthesizer.Build(ASpecA), LWidth, LHeight, LComponents);
  LSecond := DecodeBytes(TJpegSynthesizer.Build(ASpecB), LWidth, LHeight, LComponents);
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  Assert.IsTrue(CompareMem(Pointer(LFirst), Pointer(LSecond), Length(LFirst)),
    'The pixels differ');
end;

procedure TTestJpegDecompressor.TestHeaderGivesSizeAndOutputComponents;
var
  LStream: TBytes;
  LDecompressor: TJpegDecompressor;
begin
  LStream := TJpegSynthesizer.Build(TJpegSpec.Make(37, 21, 3, 1));
  LDecompressor := TJpegDecompressor.Create(Pointer(LStream), Length(LStream));
  try
    LDecompressor.ReadHeader;
    Assert.AreEqual(37, LDecompressor.Width);
    Assert.AreEqual(21, LDecompressor.Height);
    Assert.AreEqual(3, LDecompressor.OutputComponents);
  finally
    LDecompressor.Free;
  end;

  LStream := TJpegSynthesizer.Build(TJpegSpec.Make(9, 9, 1, 2));
  LDecompressor := TJpegDecompressor.Create(Pointer(LStream), Length(LStream));
  try
    LDecompressor.ReadHeader;
    Assert.AreEqual(1, LDecompressor.OutputComponents);
  finally
    LDecompressor.Free;
  end;
end;

procedure TTestJpegDecompressor.TestCmykHasNoConversionButItsHeaderIsRead;
var
  LStream: TBytes;
  LDecompressor: TJpegDecompressor;
  LPixels: TBytes;
  LRaised: Boolean;
begin
  LStream := TJpegSynthesizer.Build(TJpegSpec.Make(8, 8, 4, 3));
  LDecompressor := TJpegDecompressor.Create(Pointer(LStream), Length(LStream));
  try
    LDecompressor.ReadHeader;
    Assert.AreEqual(8, LDecompressor.Width);
    SetLength(LPixels, 8 * 8 * 3);
    LRaised := False;
    try
      LDecompressor.Decompress(Pointer(LPixels), 24);
    except
      on E: EJpegDecodeException do
      begin
        LRaised := True;
        Assert.AreEqual(Ord(jdeColorConversion), Ord(E.Error));
      end;
    end;
    Assert.IsTrue(LRaised);
  finally
    LDecompressor.Free;
  end;
end;

procedure TTestJpegDecompressor.TestSequentialScansInAnyOrderGiveTheSameImage;
var
  LInterleaved, LSeparate, LReversed: TJpegSpec;
begin
  LInterleaved := TJpegSpec.Make(37, 26, 3, 40);
  LInterleaved.SetSampling(0, 2, 2);
  LSeparate := LInterleaved;
  SetLength(LSeparate.Scans, 3);
  LSeparate.Scans[0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LSeparate.Scans[1] := TJpegScanSpec.Make([1], 0, 63, 0, 0);
  LSeparate.Scans[2] := TJpegScanSpec.Make([2], 0, 63, 0, 0);
  LReversed := LInterleaved;
  SetLength(LReversed.Scans, 2);
  LReversed.Scans[0] := TJpegScanSpec.Make([2, 1], 0, 63, 0, 0);
  LReversed.Scans[1] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  AssertSameImage(LInterleaved, LSeparate);
  AssertSameImage(LInterleaved, LReversed);
end;

procedure TTestJpegDecompressor.TestProgressiveImageEqualsTheSequentialOne;
var
  LSequential, LProgressive: TJpegSpec;
begin
  // The same coefficients sent in the progression of libjpeg, with all the
  // bits: once every scan is read the image is the sequential one
  LSequential := TJpegSpec.Make(41, 29, 3, 41);
  LProgressive := LSequential;
  LProgressive.FrameKind := jfkProgressive;
  LProgressive.Scans := TJpegSynthesizer.StandardProgression(3);
  AssertSameImage(LSequential, LProgressive);

  LSequential := TJpegSpec.Make(41, 29, 1, 42);
  LProgressive := LSequential;
  LProgressive.FrameKind := jfkProgressive;
  LProgressive.Scans := TJpegSynthesizer.StandardProgression(1);
  AssertSameImage(LSequential, LProgressive);
end;

procedure TTestJpegDecompressor.TestProgressiveImageWithSpectralSelectionEqualsTheSequentialOne;
var
  LSequential, LProgressive: TJpegSpec;
begin
  LSequential := TJpegSpec.Make(30, 30, 3, 43);
  LProgressive := LSequential;
  LProgressive.FrameKind := jfkProgressive;
  LProgressive.Scans := TJpegSynthesizer.SpectralProgression(3);
  AssertSameImage(LSequential, LProgressive);
end;

procedure TTestJpegDecompressor.TestProgressiveWithRestartIntervalEqualsTheSequentialOne;
var
  LSequential, LProgressive: TJpegSpec;
begin
  LSequential := TJpegSpec.Make(48, 40, 3, 44);
  LSequential.RestartInterval := 3;
  LProgressive := LSequential;
  LProgressive.FrameKind := jfkProgressive;
  LProgressive.Scans := TJpegSynthesizer.StandardProgression(3);
  AssertSameImage(LSequential, LProgressive);
end;

procedure TTestJpegDecompressor.TestSubsampledProgressiveImageEqualsTheSequentialOne;
var
  LSequential, LProgressive: TJpegSpec;
begin
  LSequential := TJpegSpec.Make(45, 37, 3, 45);
  LSequential.SetSampling(0, 2, 2);
  LProgressive := LSequential;
  LProgressive.FrameKind := jfkProgressive;
  LProgressive.Scans := TJpegSynthesizer.StandardProgression(3);
  AssertSameImage(LSequential, LProgressive);

  LSequential := TJpegSpec.Make(45, 37, 3, 46);
  LSequential.SetSampling(0, 2, 1);
  LProgressive := LSequential;
  LProgressive.FrameKind := jfkProgressive;
  LProgressive.Scans := TJpegSynthesizer.StandardProgression(3);
  AssertSameImage(LSequential, LProgressive);
end;

procedure TTestJpegDecompressor.TestRestartIntervalDoesNotChangeTheImage;
var
  LPlain, LRestarts: TJpegSpec;
begin
  LPlain := TJpegSpec.Make(50, 33, 3, 47);
  LPlain.SetSampling(0, 2, 2);
  LRestarts := LPlain;
  LRestarts.RestartInterval := 2;
  AssertSameImage(LPlain, LRestarts);
end;

procedure TTestJpegDecompressor.TestEndOfImageBeforeAnyScan;
var
  LStream: TBytes;
  LDecompressor: TJpegDecompressor;
  LRaised: Boolean;
begin
  LStream := TBytes.Create($FF, $D8, $FF, $D9);
  LDecompressor := TJpegDecompressor.Create(Pointer(LStream), Length(LStream));
  try
    LRaised := False;
    try
      LDecompressor.ReadHeader;
    except
      on E: EJpegDecodeException do
      begin
        LRaised := True;
        Assert.AreEqual(Ord(jdeNoImage), Ord(E.Error));
      end;
    end;
    Assert.IsTrue(LRaised);
  finally
    LDecompressor.Free;
  end;
end;

procedure TTestJpegDecompressor.TestImageThatIsCutIsTruncated;
var
  LStream: TBytes;
  LWidth, LHeight, LComponents: Integer;
  LRaised: Boolean;
begin
  LStream := TJpegSynthesizer.Build(TJpegSpec.Make(32, 32, 3, 48));
  SetLength(LStream, Length(LStream) div 2);
  LRaised := False;
  try
    DecodeBytes(LStream, LWidth, LHeight, LComponents);
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(jdeTruncated), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised);
end;

end.
