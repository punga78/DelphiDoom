{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegBitmapBuilder                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.JpegBitmap;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Client;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegBitmapBuilder = class(TObject)
  private
    function MakeImage(AWidth, AHeight, AComponents: Integer): TJpegImage;
    function WordAt(const ABitmap: TBytes; AOffset: Integer): Integer;
    function CardinalAt(const ABitmap: TBytes; AOffset: Integer): Cardinal;
  public
    [Test]
    procedure TestColorHeaders;
    [Test]
    procedure TestColorSizeIncludesRowPadding;
    [Test]
    procedure TestColorRowsAreBottomUpAndColumnsReversed;
    [Test]
    procedure TestGrayHasLinearPalette;
    [Test]
    procedure TestGrayRowsAreBottomUpAndColumnsReversed;
    [Test]
    procedure TestPaddingBytesAreZero;
    [Test]
    procedure TestInvalidComponentsRaise;
    [Test]
    procedure TestTooFewPixelsRaise;
  end;

implementation

uses
  DelphiDoom.Jpeg.Intf, DelphiDoom.Texture.JpegBitmap;

const
  FILE_HEADER_SIZE = 14;
  INFO_HEADER_SIZE = 40;

{ TTestJpegBitmapBuilder }

function TTestJpegBitmapBuilder.MakeImage(AWidth, AHeight,
  AComponents: Integer): TJpegImage;
var
  LIndex: Integer;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Components := AComponents;
  SetLength(Result.Pixels, AWidth * AHeight * AComponents);
  // Every byte is different, so a wrong position shows up
  for LIndex := 0 to High(Result.Pixels) do
    Result.Pixels[LIndex] := Byte(LIndex + 1);
end;

function TTestJpegBitmapBuilder.WordAt(const ABitmap: TBytes;
  AOffset: Integer): Integer;
begin
  Result := ABitmap[AOffset] or (ABitmap[AOffset + 1] shl 8);
end;

function TTestJpegBitmapBuilder.CardinalAt(const ABitmap: TBytes;
  AOffset: Integer): Cardinal;
begin
  Result := Cardinal(WordAt(ABitmap, AOffset)) or
    (Cardinal(WordAt(ABitmap, AOffset + 2)) shl 16);
end;

procedure TTestJpegBitmapBuilder.TestColorHeaders;
var
  LBitmap: TBytes;
begin
  LBitmap := TJpegBitmapBuilder.Build(MakeImage(4, 3, 3));
  Assert.AreEqual($4D42, WordAt(LBitmap, 0));
  Assert.AreEqual(Cardinal(FILE_HEADER_SIZE + INFO_HEADER_SIZE),
    CardinalAt(LBitmap, 10));
  Assert.AreEqual(Cardinal(INFO_HEADER_SIZE), CardinalAt(LBitmap, 14));
  Assert.AreEqual(Cardinal(4), CardinalAt(LBitmap, 18));
  Assert.AreEqual(Cardinal(3), CardinalAt(LBitmap, 22));
  Assert.AreEqual(1, WordAt(LBitmap, 26));
  Assert.AreEqual(24, WordAt(LBitmap, 28));
end;

procedure TTestJpegBitmapBuilder.TestColorSizeIncludesRowPadding;
var
  LBitmap: TBytes;
begin
  // 3 pixels * 3 bytes = 9 bytes per row, padded to 12
  LBitmap := TJpegBitmapBuilder.Build(MakeImage(3, 2, 3));
  Assert.AreEqual(FILE_HEADER_SIZE + INFO_HEADER_SIZE + 12 * 2, Length(LBitmap));
  Assert.AreEqual(Cardinal(Length(LBitmap)), CardinalAt(LBitmap, 2));
end;

procedure TTestJpegBitmapBuilder.TestColorRowsAreBottomUpAndColumnsReversed;
var
  LBitmap: TBytes;
  LBase: Integer;
begin
  // Source: row 0 = bytes 1..6 (pixels 1,2,3 | 4,5,6), row 1 = bytes 7..12
  LBitmap := TJpegBitmapBuilder.Build(MakeImage(2, 2, 3));
  LBase := FILE_HEADER_SIZE + INFO_HEADER_SIZE;
  // File row 0 is source row 1, with its two pixels swapped
  Assert.AreEqual(10, Integer(LBitmap[LBase + 0]));
  Assert.AreEqual(11, Integer(LBitmap[LBase + 1]));
  Assert.AreEqual(12, Integer(LBitmap[LBase + 2]));
  Assert.AreEqual(7, Integer(LBitmap[LBase + 3]));
  Assert.AreEqual(8, Integer(LBitmap[LBase + 4]));
  Assert.AreEqual(9, Integer(LBitmap[LBase + 5]));
  // File row 1 is source row 0 (row size 8: 6 bytes + 2 of padding)
  Assert.AreEqual(4, Integer(LBitmap[LBase + 8]));
  Assert.AreEqual(1, Integer(LBitmap[LBase + 11]));
end;

procedure TTestJpegBitmapBuilder.TestGrayHasLinearPalette;
var
  LBitmap: TBytes;
  LPalette: Integer;
begin
  LBitmap := TJpegBitmapBuilder.Build(MakeImage(4, 2, 1));
  Assert.AreEqual(8, WordAt(LBitmap, 28));
  Assert.AreEqual(Cardinal(256), CardinalAt(LBitmap, 46));
  Assert.AreEqual(Cardinal(FILE_HEADER_SIZE + INFO_HEADER_SIZE + 256 * 4),
    CardinalAt(LBitmap, 10));
  LPalette := FILE_HEADER_SIZE + INFO_HEADER_SIZE;
  Assert.AreEqual(0, Integer(LBitmap[LPalette]));
  Assert.AreEqual(77, Integer(LBitmap[LPalette + 77 * 4]));
  Assert.AreEqual(77, Integer(LBitmap[LPalette + 77 * 4 + 2]));
  Assert.AreEqual(255, Integer(LBitmap[LPalette + 255 * 4 + 1]));
end;

procedure TTestJpegBitmapBuilder.TestGrayRowsAreBottomUpAndColumnsReversed;
var
  LBitmap: TBytes;
  LBase: Integer;
begin
  // Source: row 0 = 1,2,3 ; row 1 = 4,5,6 (row size 3, padded to 4)
  LBitmap := TJpegBitmapBuilder.Build(MakeImage(3, 2, 1));
  LBase := FILE_HEADER_SIZE + INFO_HEADER_SIZE + 256 * 4;
  Assert.AreEqual(6, Integer(LBitmap[LBase + 0]));
  Assert.AreEqual(5, Integer(LBitmap[LBase + 1]));
  Assert.AreEqual(4, Integer(LBitmap[LBase + 2]));
  Assert.AreEqual(3, Integer(LBitmap[LBase + 4]));
  Assert.AreEqual(1, Integer(LBitmap[LBase + 6]));
end;

procedure TTestJpegBitmapBuilder.TestPaddingBytesAreZero;
var
  LBitmap: TBytes;
  LBase: Integer;
begin
  LBitmap := TJpegBitmapBuilder.Build(MakeImage(3, 2, 1));
  LBase := FILE_HEADER_SIZE + INFO_HEADER_SIZE + 256 * 4;
  Assert.AreEqual(0, Integer(LBitmap[LBase + 3]));
  Assert.AreEqual(0, Integer(LBitmap[LBase + 7]));
end;

procedure TTestJpegBitmapBuilder.TestInvalidComponentsRaise;
begin
  Assert.WillRaise(
    procedure
    begin
      TJpegBitmapBuilder.Build(MakeImage(2, 2, 2));
    end, EJpegException);
end;

procedure TTestJpegBitmapBuilder.TestTooFewPixelsRaise;
var
  LImage: TJpegImage;
begin
  LImage := MakeImage(4, 4, 3);
  SetLength(LImage.Pixels, 10);
  Assert.WillRaise(
    procedure
    begin
      TJpegBitmapBuilder.Build(LImage);
    end, EJpegException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJpegBitmapBuilder);

end.
