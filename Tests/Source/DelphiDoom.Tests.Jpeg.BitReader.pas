{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegBitReader                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.BitReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.BitReader,
  DelphiDoom.Jpeg.ByteSource, DelphiDoom.Jpeg.Frame, DelphiDoom.Jpeg.MarkerReader;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegBitReader = class(TObject)
  private
    FData: TBytes;
    FSource: TJpegByteSource;
    FFrame: TJpegFrame;
    FMarkers: TJpegMarkerReader;
    FReader: TJpegBitReader;
    procedure Open(const AData: array of Byte);
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestReadsBitsFromTheMostSignificant;
    [Test]
    procedure TestAZeroAfterFFIsDropped;
    [Test]
    procedure TestAMarkerStopsTheDataAndGivesZeros;
    [Test]
    procedure TestRunningOutOfBytesCutsTheStream;
    [Test]
    procedure TestDiscardBitsDropsTheBytesThatWereRead;
    [Test]
    procedure TestDecodesShortAndLongCodes;
    [Test]
    procedure TestStartForgetsTheLostData;
  end;

implementation

uses
  DelphiDoom.Jpeg.HuffmanTable, DelphiDoom.Jpeg.Types;

{ TTestJpegBitReader }

procedure TTestJpegBitReader.Open(const AData: array of Byte);
var
  LIndex: Integer;
begin
  TearDown;
  SetLength(FData, Length(AData));
  for LIndex := 0 to High(AData) do
    FData[LIndex] := AData[LIndex];
  FSource := TJpegByteSource.Create(Pointer(FData), Length(FData));
  FFrame := TJpegFrame.Create;
  FMarkers := TJpegMarkerReader.Create(FSource, FFrame);
  FReader := TJpegBitReader.Create(FSource, FMarkers);
  FReader.Start;
end;

procedure TTestJpegBitReader.TearDown;
begin
  FreeAndNil(FReader);
  FreeAndNil(FMarkers);
  FreeAndNil(FFrame);
  FreeAndNil(FSource);
end;

procedure TTestJpegBitReader.TestReadsBitsFromTheMostSignificant;
begin
  Open([$A5, $3C, $F0, $0F]);
  Assert.AreEqual($A, FReader.ReadBits(4));
  Assert.AreEqual($5, FReader.ReadBits(4));
  Assert.AreEqual($3C, FReader.ReadBits(8));
  Assert.AreEqual($F00F, FReader.ReadBits(16));
end;

procedure TTestJpegBitReader.TestAZeroAfterFFIsDropped;
begin
  Open([$FF, $00, $80, $01]);
  Assert.AreEqual($FF, FReader.ReadBits(8));
  Assert.AreEqual($80, FReader.ReadBits(8));
  Assert.IsFalse(FReader.InsufficientData);
end;

procedure TTestJpegBitReader.TestAMarkerStopsTheDataAndGivesZeros;
begin
  Open([$12, $FF, $D0, $34]);
  Assert.AreEqual($12, FReader.ReadBits(8));
  Assert.IsFalse(FReader.InsufficientData, 'The bits that were asked for were there');
  Assert.AreEqual($D0, FMarkers.UnreadMarker);
  Assert.AreEqual(0, FReader.ReadBits(8));
  Assert.IsTrue(FReader.InsufficientData);
end;

procedure TTestJpegBitReader.TestRunningOutOfBytesCutsTheStream;
begin
  Open([$12]);
  Assert.AreEqual($12, FReader.ReadBits(8));
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadBits(8);
    end, EJpegDecodeException);
end;

procedure TTestJpegBitReader.TestDiscardBitsDropsTheBytesThatWereRead;
begin
  // The reader takes two bytes at least; those that were not used are padding
  Open([$11, $22, $33, $44]);
  Assert.AreEqual($1, FReader.ReadBits(4));
  FReader.DiscardBits;
  Assert.AreEqual($33, FReader.ReadBits(8));
end;

procedure TTestJpegBitReader.TestDecodesShortAndLongCodes;
var
  LDefinition: TJpegHuffmanDefinition;
  LTable: TJpegHuffmanTable;
  LIndex: Integer;
begin
  // The DC table of annex K for the luminance; the bits are 00 110 111111110
  LDefinition := Default(TJpegHuffmanDefinition);
  LDefinition.Defined := True;
  LDefinition.Bits[2] := 1;
  LDefinition.Bits[3] := 5;
  for LIndex := 4 to 9 do
    LDefinition.Bits[LIndex] := 1;
  for LIndex := 0 to 11 do
    LDefinition.Values[LIndex] := Byte(LIndex);
  LTable := TJpegHuffmanTable.Create(LDefinition, True);
  try
    Open([$37, $FB]);
    Assert.AreEqual(0, FReader.DecodeSymbol(LTable));
    Assert.AreEqual(5, FReader.DecodeSymbol(LTable));
    Assert.AreEqual(11, FReader.DecodeSymbol(LTable));
  finally
    LTable.Free;
  end;
end;

procedure TTestJpegBitReader.TestStartForgetsTheLostData;
begin
  Open([$FF, $D9]);
  Assert.AreEqual(0, FReader.ReadBits(4));
  Assert.IsTrue(FReader.InsufficientData);
  FReader.Start;
  Assert.IsFalse(FReader.InsufficientData);
end;

end.
