{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegSequentialDecoder                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.SequentialDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.BitReader,
  DelphiDoom.Jpeg.ByteSource, DelphiDoom.Jpeg.EntropyDecoder, DelphiDoom.Jpeg.Frame,
  DelphiDoom.Jpeg.MarkerReader, DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegSequentialDecoder = class(TObject)
  private
    FData: TBytes;
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FMarkers: TJpegMarkerReader;
    FBits: TJpegBitReader;
    FDecoder: IJpegEntropyDecoder;
    FBlock: TJpegBlock;
    procedure Open(ADc: Integer);
    procedure DecodeOne;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestDecodesThePositiveDcAndTheEndOfBlock;
    [Test]
    procedure TestDecodesTheNegativeDc;
    [Test]
    procedure TestDecodesADcOfZero;
    [Test]
    procedure TestDecodesTheLargestSizeOfTheTable;
    [Test]
    procedure TestMissingTableIsAnError;
    [Test]
    procedure TestTableThatIsNotValidIsAnError;
  end;

implementation

uses
  DelphiDoom.Jpeg.SequentialDecoder, DelphiDoom.Tests.Jpeg.TinyStream;

{ TTestJpegSequentialDecoder }

procedure TTestJpegSequentialDecoder.Open(ADc: Integer);
begin
  TearDown;
  FData := TJpegTinyStream.Build(ADc, False);
  FSource := TJpegByteSource.Create(Pointer(FData), Length(FData));
  FFrame := TJpegFrame.Create;
  FMarkers := TJpegMarkerReader.Create(FSource, FFrame);
  FBits := TJpegBitReader.Create(FSource, FMarkers);
  FMarkers.ReadMarkers;
  FFrame.PrepareGeometry;
  FFrame.ChooseColorSpace;
  FFrame.PrepareScan;
  FFrame.LatchQuantizationTables;
  FDecoder := TJpegSequentialDecoder.Create(FFrame, FMarkers, FBits);
  FDecoder.StartScan;
end;

procedure TTestJpegSequentialDecoder.DecodeOne;
var
  LBlocks: TJpegBlockPointers;
begin
  FillChar(FBlock, SizeOf(FBlock), 0);
  LBlocks[0] := @FBlock;
  FDecoder.DecodeMcu(LBlocks);
end;

procedure TTestJpegSequentialDecoder.TearDown;
begin
  FDecoder := nil;
  FreeAndNil(FBits);
  FreeAndNil(FMarkers);
  FreeAndNil(FFrame);
  FreeAndNil(FSource);
end;

procedure TTestJpegSequentialDecoder.TestDecodesThePositiveDcAndTheEndOfBlock;
var
  LIndex: Integer;
begin
  Open(8);
  DecodeOne;
  Assert.AreEqual(8, FBlock[0]);
  for LIndex := 1 to 63 do
    Assert.AreEqual(0, FBlock[LIndex]);
end;

procedure TTestJpegSequentialDecoder.TestDecodesTheNegativeDc;
begin
  Open(-8);
  DecodeOne;
  Assert.AreEqual(-8, FBlock[0]);
  Open(-1);
  DecodeOne;
  Assert.AreEqual(-1, FBlock[0]);
end;

procedure TTestJpegSequentialDecoder.TestDecodesADcOfZero;
begin
  Open(0);
  DecodeOne;
  Assert.AreEqual(0, FBlock[0]);
end;

procedure TTestJpegSequentialDecoder.TestDecodesTheLargestSizeOfTheTable;
begin
  Open(2047);
  DecodeOne;
  Assert.AreEqual(2047, FBlock[0]);
  Open(-2047);
  DecodeOne;
  Assert.AreEqual(-2047, FBlock[0]);
end;

procedure TTestJpegSequentialDecoder.TestMissingTableIsAnError;
var
  LRaised: Boolean;
begin
  Open(8);
  FFrame.AcDefinition[0]^.Defined := False;
  LRaised := False;
  try
    FDecoder.StartScan;
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(jdeMissingHuffmanTable), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestJpegSequentialDecoder.TestTableThatIsNotValidIsAnError;
var
  LRaised: Boolean;
begin
  Open(8);
  // A DC symbol that is not a size
  FFrame.DcDefinition[0]^.Values[0] := 30;
  LRaised := False;
  try
    FDecoder.StartScan;
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(jdeBadHuffmanTable), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised);
end;

end.
