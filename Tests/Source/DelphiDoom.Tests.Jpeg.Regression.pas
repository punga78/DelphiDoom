{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the defects of the old JPEG decoder (JPEGLIB) that     }
{  the new decoder does not have                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Regression;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf;

type
  /// <summary>
  ///   The old decoder was a translation of libjpeg 6b into Pascal that kept
  ///   the behavior of the C code except in a few places, where the
  ///   translation went wrong. They are corrected; each has a test
  /// </summary>
  [TestFixture]
  [Category('jpeg')]
  TTestJpegRegression = class(TObject)
  private
    function Decode(const AStream: TBytes; out AInfo: TJpegInfo): TBytes;
  public
    [Test]
    [TestCase('Jfif', 'E0')]
    [TestCase('Adobe', 'EE')]
    procedure TestApplicationMarkerWithoutDataIsSkipped(AMarker: string);
    [Test]
    procedure TestApplicationMarkerWithALengthBelowTwoIsSkipped;
    [Test]
    procedure TestComponentThatTheScanOfASingleScanImageDoesNotHaveIsGray;
    [Test]
    procedure TestComponentAfterOneWithoutScanKeepsItsQuantizationTable;
  end;

implementation

uses
  DelphiDoom.Jpeg.Decoder, DelphiDoom.Tests.Jpeg.Synthesizer,
  DelphiDoom.Tests.Jpeg.TinyStream;

{ TTestJpegRegression }

function TTestJpegRegression.Decode(const AStream: TBytes; out AInfo: TJpegInfo): TBytes;
begin
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.ReadInfo(Pointer(AStream), Length(AStream), AInfo));
  SetLength(Result, AInfo.Width * AInfo.Height * AInfo.Components);
  Assert.AreEqual(DDJPEG_OK, TJpegDecoder.Decode(Pointer(AStream), Length(AStream),
    Pointer(Result), Length(Result), AInfo));
end;

procedure TTestJpegRegression.TestApplicationMarkerWithoutDataIsSkipped(AMarker: string);
var
  LStream: TBytes;
  LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  // A segment that is only its length (2): the old decoder read the bytes of
  // the marker in a loop of 4 billion turns and overwrote the memory
  LStream := TJpegTinyStream.Build(8, False, TBytes.Create($FF, Byte(StrToInt('$' + AMarker)), $00, $02));
  LPixels := Decode(LStream, LInfo);
  Assert.AreEqual(Integer(TJpegTinyStream.ExpectedSample(8)), Integer(LPixels[0]));
end;

procedure TTestJpegRegression.TestApplicationMarkerWithALengthBelowTwoIsSkipped;
var
  LPixels: TBytes;
  LInfo: TJpegInfo;
begin
  LPixels := Decode(TJpegTinyStream.Build(8, False, TBytes.Create($FF, $E0, $00, $01)), LInfo);
  Assert.AreEqual(Integer(TJpegTinyStream.ExpectedSample(8)), Integer(LPixels[0]));
  LPixels := Decode(TJpegTinyStream.Build(8, False, TBytes.Create($FF, $EE, $00, $00)), LInfo);
  Assert.AreEqual(Integer(TJpegTinyStream.ExpectedSample(8)), Integer(LPixels[0]));
end;

procedure TTestJpegRegression.TestComponentThatTheScanOfASingleScanImageDoesNotHaveIsGray;
var
  LSpec: TJpegSpec;
  LStream: TBytes;
  LPixels: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  // The scan names the second component twice and never the first. Its
  // samples were memory that nobody wrote in the old decoder; now they are
  // 128 as in an image with many scans, so that with the components as RGB
  // the first channel is 128 everywhere
  LSpec := TJpegSpec.Make(16, 16, 3, 7);
  LSpec.Marker := jcmAdobeTransform0;
  LStream := TJpegSynthesizer.Build(LSpec);
  // The scan header: 03, then the identifier and the tables of each component
  LIndex := 0;
  while not ((LStream[LIndex] = $FF) and (LStream[LIndex + 1] = $DA)) do
    Inc(LIndex);
  LStream[LIndex + 5] := 2;
  LPixels := Decode(LStream, LInfo);
  for LIndex := 0 to 16 * 16 - 1 do
    Assert.AreEqual(128, Integer(LPixels[LIndex * 3]), 'Pixel ' + IntToStr(LIndex));
end;

procedure TTestJpegRegression.TestComponentAfterOneWithoutScanKeepsItsQuantizationTable;
var
  LAll, LMissing: TJpegSpec;
  LFull, LPartial: TBytes;
  LInfo: TJpegInfo;
  LIndex: Integer;
begin
  // Components as RGB (Adobe, transform 0) show the planes as they are. The
  // second component has no scan in LMissing. The old decoder, in the loop
  // that builds the tables of the inverse DCT, did not move on to the next
  // component after one that has no table, so the third component got no
  // table and came out gray. Both images have the same coefficients (same
  // seed), so the third channel must be the same
  LAll := TJpegSpec.Make(24, 24, 3, 11);
  LAll.Marker := jcmAdobeTransform0;
  SetLength(LAll.Scans, 3);
  LAll.Scans[0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LAll.Scans[1] := TJpegScanSpec.Make([1], 0, 63, 0, 0);
  LAll.Scans[2] := TJpegScanSpec.Make([2], 0, 63, 0, 0);
  LMissing := LAll;
  SetLength(LMissing.Scans, 2);
  LMissing.Scans[0] := TJpegScanSpec.Make([0], 0, 63, 0, 0);
  LMissing.Scans[1] := TJpegScanSpec.Make([2], 0, 63, 0, 0);

  LFull := Decode(TJpegSynthesizer.Build(LAll), LInfo);
  LPartial := Decode(TJpegSynthesizer.Build(LMissing), LInfo);
  for LIndex := 0 to 24 * 24 - 1 do
  begin
    Assert.AreEqual(Integer(LFull[LIndex * 3]), Integer(LPartial[LIndex * 3]), 'First component');
    Assert.AreEqual(Integer(LFull[LIndex * 3 + 2]), Integer(LPartial[LIndex * 3 + 2]),
      'Third component, pixel ' + IntToStr(LIndex));
    Assert.AreEqual(128, Integer(LPartial[LIndex * 3 + 1]), 'Second component');
  end;
end;

end.
