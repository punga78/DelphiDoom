{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TJpegByteSource                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.ByteSource;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.ByteSource;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegByteSource = class(TObject)
  private
    FData: TBytes;
    FSource: TJpegByteSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestReadsTheBytesInOrder;
    [Test]
    procedure TestIsNotExhaustedUntilMoreBytesAreAsked;
    [Test]
    procedure TestGivesEndOfImageWhenTheBytesAreOver;
    [Test]
    procedure TestSkipGoesOverBytes;
    [Test]
    procedure TestSkipOfNothingOrLessDoesNothing;
    [Test]
    procedure TestSkipPastTheEndEmptiesTheBufferAndTheNextByteStartsAnEndOfImage;
    [Test]
    procedure TestSkipAtTheEndDoesNotSpendTheEndOfImage;
  end;

implementation

{ TTestJpegByteSource }

procedure TTestJpegByteSource.Setup;
begin
  FData := TBytes.Create(1, 2, 3, 4, 5);
  FSource := TJpegByteSource.Create(Pointer(FData), Length(FData));
end;

procedure TTestJpegByteSource.TearDown;
begin
  FSource.Free;
end;

procedure TTestJpegByteSource.TestReadsTheBytesInOrder;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 5 do
    Assert.AreEqual(LIndex, FSource.ReadByte);
end;

procedure TTestJpegByteSource.TestIsNotExhaustedUntilMoreBytesAreAsked;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 5 do
    FSource.ReadByte;
  Assert.IsFalse(FSource.Exhausted, 'All the bytes were read, no more were asked');
  FSource.ReadByte;
  Assert.IsTrue(FSource.Exhausted);
end;

procedure TTestJpegByteSource.TestGivesEndOfImageWhenTheBytesAreOver;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 5 do
    FSource.ReadByte;
  // FF D9 once and again
  Assert.AreEqual($FF, FSource.ReadByte);
  Assert.AreEqual($D9, FSource.ReadByte);
  Assert.AreEqual($FF, FSource.ReadByte);
  Assert.AreEqual($D9, FSource.ReadByte);
end;

procedure TTestJpegByteSource.TestSkipGoesOverBytes;
begin
  FSource.Skip(3);
  Assert.AreEqual(4, FSource.ReadByte);
  Assert.IsFalse(FSource.Exhausted);
end;

procedure TTestJpegByteSource.TestSkipOfNothingOrLessDoesNothing;
begin
  FSource.Skip(0);
  FSource.Skip(-7);
  Assert.AreEqual(1, FSource.ReadByte);
end;

procedure TTestJpegByteSource.TestSkipPastTheEndEmptiesTheBufferAndTheNextByteStartsAnEndOfImage;
begin
  FSource.Skip(100);
  Assert.IsFalse(FSource.Exhausted, 'Skipping does not ask for bytes');
  Assert.AreEqual($FF, FSource.ReadByte);
  Assert.AreEqual($D9, FSource.ReadByte);
  Assert.IsTrue(FSource.Exhausted);
end;

procedure TTestJpegByteSource.TestSkipAtTheEndDoesNotSpendTheEndOfImage;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 5 do
    FSource.ReadByte;
  FSource.Skip(1);
  Assert.AreEqual($FF, FSource.ReadByte);
  Assert.AreEqual($D9, FSource.ReadByte);
end;

end.
