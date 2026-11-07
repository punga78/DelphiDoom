{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegMarkerReader                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.MarkerReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.ByteSource,
  DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.MarkerReader;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegMarkerReader = class(TObject)
  private
    FData: TBytes;
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FReader: TJpegMarkerReader;
    procedure Open(const AData: TBytes);
    procedure OpenBytes(const AData: array of Byte);
    procedure AssertFails(AError: Integer; const AData: array of Byte);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestReadsTheHeadersUpToTheScan;
    [Test]
    procedure TestReadsTheTables;
    [Test]
    procedure TestEndOfImageBeforeAScan;
    [Test]
    procedure TestFillBytesAndGarbageBetweenMarkersAreSkipped;
    [Test]
    procedure TestJfifAndAdobeMarkersAreRecognized;
    [Test]
    procedure TestOtherApplicationMarkersAndCommentsAreSkipped;
    [Test]
    procedure TestRestartIntervalIsKept;
    [Test]
    procedure TestNotJpeg;
    [Test]
    procedure TestWrongMarkersAreRefused;
    [Test]
    procedure TestRestartMarkerThatIsExpectedIsUsed;
    [Test]
    procedure TestRestartMarkerOfALaterNumberIsLeftWhereItIs;
    [Test]
    procedure TestRestartMarkerOfAnEarlierNumberIsSkipped;
    [Test]
    procedure TestRestartMarkersWrapAroundAfterSeven;
  end;

implementation

uses
  DelphiDoom.Jpeg.Types, DelphiDoom.Tests.Jpeg.TinyStream;

{ TTestJpegMarkerReader }

procedure TTestJpegMarkerReader.Open(const AData: TBytes);
begin
  TearDown;
  FData := AData;
  FSource := TJpegByteSource.Create(Pointer(FData), Length(FData));
  FFrame := TJpegFrame.Create;
  FReader := TJpegMarkerReader.Create(FSource, FFrame);
end;

procedure TTestJpegMarkerReader.OpenBytes(const AData: array of Byte);
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AData));
  for LIndex := 0 to High(AData) do
    LBytes[LIndex] := AData[LIndex];
  Open(LBytes);
end;

procedure TTestJpegMarkerReader.AssertFails(AError: Integer; const AData: array of Byte);
var
  LExpected: TJpegDecodeError;
  LRaised: Boolean;
begin
  LExpected := TJpegDecodeError(AError);
  OpenBytes(AData);
  LRaised := False;
  try
    FReader.ReadMarkers;
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(LExpected), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised, 'The error was not raised');
end;

procedure TTestJpegMarkerReader.TearDown;
begin
  FreeAndNil(FReader);
  FreeAndNil(FFrame);
  FreeAndNil(FSource);
end;

procedure TTestJpegMarkerReader.TestReadsTheHeadersUpToTheScan;
begin
  Open(TJpegTinyStream.Build(8, False));
  Assert.AreEqual(Ord(jmsStartOfScan), Ord(FReader.ReadMarkers));
  Assert.IsTrue(FReader.SawFrame);
  Assert.AreEqual(8, FFrame.ImageWidth);
  Assert.AreEqual(8, FFrame.ImageHeight);
  Assert.AreEqual(8, FFrame.Precision);
  Assert.AreEqual(1, FFrame.ComponentCount);
  Assert.IsFalse(FFrame.IsProgressive);
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.Id);
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.Horizontal);
  Assert.AreEqual(1, FFrame.ComponentByIndex[0]^.Vertical);
  Assert.AreEqual(1, FFrame.Scan^.ComponentCount);
  Assert.AreEqual(0, FFrame.Scan^.Components[0]);
  Assert.AreEqual(0, FFrame.Scan^.SpectralStart);
  Assert.AreEqual(63, FFrame.Scan^.SpectralEnd);
  Assert.AreEqual(0, FFrame.Scan^.ApproximationHigh);
  Assert.AreEqual(0, FFrame.Scan^.ApproximationLow);
  Assert.AreEqual(0, FReader.UnreadMarker);
end;

procedure TTestJpegMarkerReader.TestReadsTheTables;
begin
  Open(TJpegTinyStream.Build(8, False));
  FReader.ReadMarkers;
  Assert.IsTrue(FFrame.Quantization[0]^.Defined);
  Assert.AreEqual(1, Integer(FFrame.Quantization[0]^.Values[63]));
  Assert.IsFalse(FFrame.Quantization[1]^.Defined);
  Assert.IsTrue(FFrame.DcDefinition[0]^.Defined);
  Assert.AreEqual(12, Integer(FFrame.DcDefinition[0]^.Bits[4]));
  Assert.IsTrue(FFrame.AcDefinition[0]^.Defined);
  Assert.AreEqual(1, Integer(FFrame.AcDefinition[0]^.Bits[1]));
  Assert.IsFalse(FFrame.DcDefinition[1]^.Defined);
end;

procedure TTestJpegMarkerReader.TestEndOfImageBeforeAScan;
begin
  OpenBytes([$FF, $D8, $FF, $D9]);
  Assert.AreEqual(Ord(jmsEndOfImage), Ord(FReader.ReadMarkers));
  Assert.IsFalse(FReader.SawFrame);
end;

procedure TTestJpegMarkerReader.TestFillBytesAndGarbageBetweenMarkersAreSkipped;
begin
  // FF FF before a marker is fill; bytes that are not FF are dropped
  OpenBytes([$FF, $D8, $FF, $FF, $FF, $DD, $00, $04, $00, $07, 1, 2, 3, $FF, $00, $FF, $D9]);
  Assert.AreEqual(Ord(jmsEndOfImage), Ord(FReader.ReadMarkers));
  Assert.AreEqual(7, FFrame.RestartInterval);
end;

procedure TTestJpegMarkerReader.TestJfifAndAdobeMarkersAreRecognized;
begin
  OpenBytes([$FF, $D8,
    $FF, $E0, $00, $10, $4A, $46, $49, $46, $00, 1, 1, 0, 0, 1, 0, 1, 0, 0,
    $FF, $EE, $00, $0E, $41, $64, $6F, $62, $65, 0, 100, 0, 0, 0, 0, 2,
    $FF, $D9]);
  FReader.ReadMarkers;
  Assert.IsTrue(FFrame.SawJfif);
  Assert.IsTrue(FFrame.SawAdobe);
  Assert.AreEqual(2, FFrame.AdobeTransform);
end;

procedure TTestJpegMarkerReader.TestOtherApplicationMarkersAndCommentsAreSkipped;
begin
  // An APP0 that is not JFIF, an APP1, a comment
  OpenBytes([$FF, $D8,
    $FF, $E0, $00, $08, $4A, $46, $58, $58, $00, $10,
    $FF, $E1, $00, $05, 1, 2, 3,
    $FF, $FE, $00, $04, 65, 66,
    $FF, $D9]);
  Assert.AreEqual(Ord(jmsEndOfImage), Ord(FReader.ReadMarkers));
  Assert.IsFalse(FFrame.SawJfif);
  Assert.IsFalse(FFrame.SawAdobe);
end;

procedure TTestJpegMarkerReader.TestRestartIntervalIsKept;
begin
  OpenBytes([$FF, $D8, $FF, $DD, $00, $04, $01, $2C, $FF, $D9]);
  FReader.ReadMarkers;
  Assert.AreEqual(300, FFrame.RestartInterval);
end;

procedure TTestJpegMarkerReader.TestNotJpeg;
begin
  AssertFails(Ord(jdeNotJpeg), [$12, $34, $56]);
  AssertFails(Ord(jdeNotJpeg), [$FF, $D9]);
end;

procedure TTestJpegMarkerReader.TestWrongMarkersAreRefused;
begin
  AssertFails(Ord(jdeDuplicateStartOfImage), [$FF, $D8, $FF, $D8]);
  AssertFails(Ord(jdeUnknownMarker), [$FF, $D8, $FF, $02, $00, $02]);
  AssertFails(Ord(jdeUnsupportedFrame), [$FF, $D8, $FF, $C3, $00, $02]);
  AssertFails(Ord(jdeUnsupportedFrame), [$FF, $D8, $FF, $C5, $00, $02]);
  AssertFails(Ord(jdeScanBeforeFrame), [$FF, $D8, $FF, $DA, $00, $08, 1, 1, 0, 0, 63, 0]);
  AssertFails(Ord(jdeBadLength), [$FF, $D8, $FF, $DD, $00, $05, 0, 0, 0]);
  AssertFails(Ord(jdeEmptyImage), [$FF, $D8, $FF, $C0, $00, $0B, 8, 0, 0, 0, 8, 1, 1, $11, 0]);
  AssertFails(Ord(jdeBadQuantizationTableIndex), [$FF, $D8, $FF, $DB, $00, $43, $04]);
end;

procedure TTestJpegMarkerReader.TestRestartMarkerThatIsExpectedIsUsed;
begin
  OpenBytes([$FF, $D0, $AA]);
  FReader.ReadRestartMarker;
  Assert.AreEqual(0, FReader.UnreadMarker);
end;

procedure TTestJpegMarkerReader.TestRestartMarkerOfALaterNumberIsLeftWhereItIs;
begin
  // RST0 expected, RST2 found: data of a restart interval was lost, so the
  // marker stays for the next one
  OpenBytes([$FF, $D2, $AA]);
  FReader.ReadRestartMarker;
  Assert.AreEqual($D2, FReader.UnreadMarker);
end;

procedure TTestJpegMarkerReader.TestRestartMarkerOfAnEarlierNumberIsSkipped;
begin
  // RST0 and RST1 are used, then RST0 is found where RST2 is expected: it is
  // too old, so the reader goes on to the next marker
  OpenBytes([$FF, $D0, $FF, $D1, $FF, $D0, $55, $FF, $D2]);
  FReader.ReadRestartMarker;
  FReader.ReadRestartMarker;
  FReader.ReadRestartMarker;
  Assert.AreEqual(0, FReader.UnreadMarker);
end;

procedure TTestJpegMarkerReader.TestRestartMarkersWrapAroundAfterSeven;
var
  LIndex: Integer;
begin
  OpenBytes([$FF, $D0, $FF, $D1, $FF, $D2, $FF, $D3, $FF, $D4, $FF, $D5, $FF, $D6,
    $FF, $D7, $FF, $D0]);
  for LIndex := 0 to 8 do
    FReader.ReadRestartMarker;
  Assert.AreEqual(0, FReader.UnreadMarker);
end;

end.
