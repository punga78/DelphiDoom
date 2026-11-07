{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the errors of the JPEG decoder                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Jpeg.Types;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Jpeg.Intf, DelphiDoom.Jpeg.Types;

type
  [TestFixture]
  [Category('jpeg')]
  TTestJpegDecodeError = class(TObject)
  public
    [Test]
    procedure TestTruncatedStreamHasItsOwnCode;
    [Test]
    procedure TestFeaturesThatAreNotSupportedHaveTheirCode;
    [Test]
    procedure TestOtherErrorsAreDataErrors;
    [Test]
    procedure TestEveryErrorHasAText;
    [Test]
    procedure TestFailRaisesTheErrorThatWasAskedFor;
    [Test]
    procedure TestNaturalOrderIsAPermutationFollowedByTheLastEntry;
  end;

implementation

{ TTestJpegDecodeError }

procedure TTestJpegDecodeError.TestTruncatedStreamHasItsOwnCode;
begin
  Assert.AreEqual(DDJPEG_ERR_TRUNCATED, EJpegDecodeException.ResultCodeOf(jdeTruncated));
end;

procedure TTestJpegDecodeError.TestFeaturesThatAreNotSupportedHaveTheirCode;
var
  LError: TJpegDecodeError;
begin
  for LError in [jdeUnsupportedFrame, jdeImageTooBig, jdeBadPrecision,
    jdeBadProgression, jdeArithmeticCoding, jdeColorConversion] do
    Assert.AreEqual(DDJPEG_ERR_UNSUPPORTED, EJpegDecodeException.ResultCodeOf(LError),
      'Error ' + IntToStr(Ord(LError)));
end;

procedure TTestJpegDecodeError.TestOtherErrorsAreDataErrors;
var
  LError: TJpegDecodeError;
begin
  for LError in [jdeNotJpeg, jdeBadLength, jdeBadHuffmanTable, jdeBadSampling,
    jdeBadMcuSize, jdeFractionalSampling, jdeNoImage, jdeMissingHuffmanTable] do
    Assert.AreEqual(DDJPEG_ERR_DATA, EJpegDecodeException.ResultCodeOf(LError),
      'Error ' + IntToStr(Ord(LError)));
end;

procedure TTestJpegDecodeError.TestEveryErrorHasAText;
var
  LError: TJpegDecodeError;
begin
  for LError := Low(TJpegDecodeError) to High(TJpegDecodeError) do
    Assert.IsTrue(EJpegDecodeException.Create(LError).Message <> '', 'Error ' + IntToStr(Ord(LError)));
end;

procedure TTestJpegDecodeError.TestFailRaisesTheErrorThatWasAskedFor;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    EJpegDecodeException.Fail(jdeBadLength);
  except
    on E: EJpegDecodeException do
    begin
      LRaised := True;
      Assert.AreEqual(Ord(jdeBadLength), Ord(E.Error));
    end;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestJpegDecodeError.TestNaturalOrderIsAPermutationFollowedByTheLastEntry;
var
  LSeen: array[0..63] of Boolean;
  LIndex: Integer;
begin
  FillChar(LSeen, SizeOf(LSeen), 0);
  for LIndex := 0 to 63 do
  begin
    Assert.IsFalse(LSeen[JPEG_NATURAL_ORDER[LIndex]]);
    LSeen[JPEG_NATURAL_ORDER[LIndex]] := True;
  end;
  // The streams that go past the end of a block land on the last coefficient
  for LIndex := 64 to 79 do
    Assert.AreEqual(63, JPEG_NATURAL_ORDER[LIndex]);
end;

end.
