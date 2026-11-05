{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the words of variable size of Ogg                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ogg.BitPacker;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Ogg.Types;

type
  [TestFixture]
  [Category('ogg')]
  TTestOggBitPacker = class(TObject)
  private
    FBuffer: TOggPackBuffer;
    FData: TBytes;
    function ContentOf(const ABuffer: POggPackBuffer): TBytes;
    procedure StartReading(const ABytes: array of Byte);
    // Goes on from what was written: reads it back
    procedure SwitchToReading;
  public
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestScriveDueParoleNelloStessoByte;
    [Test]
    procedure TestLeggeCioCheHaScritto;
    [Test]
    procedure TestParolaDa32Bit;
    [Test]
    procedure TestPiuDi256ByteFannoCrescereLoSpazio;
    [Test]
    procedure TestIBitFuoriDalLimiteAzzerannoIlBuffer;
    [Test]
    procedure TestLookNonAvanza;
    [Test]
    procedure TestAdvanceEAdvance1;
    [Test]
    procedure TestRead1ELook1;
    [Test]
    procedure TestLeggereOltreLaFineDaMenoUno;
    [Test]
    procedure TestBytesEBits;
    [Test]
    procedure TestTroncaScartaIBitInPiu;
    [Test]
    procedure TestAllineaRiempieIlByte;
    [Test]
    procedure TestCopiaConIBitAllineati;
    [Test]
    procedure TestCopiaConIBitNonAllineati;
    [Test]
    procedure TestResetRicominciaDaCapo;
    [Test]
    procedure TestWriteCheck;
  end;

implementation

uses
  DelphiDoom.Ogg.BitPacker;

{ TTestOggBitPacker }

procedure TTestOggBitPacker.TearDown;
begin
  // A buffer that reads belongs to FData, not to the packer
  if (Length(FData) = 0) or (FBuffer.Buffer <> @FData[0]) then
    TOggBitPacker.WriteClear(@FBuffer);
  FData := nil;
end;

function TTestOggBitPacker.ContentOf(const ABuffer: POggPackBuffer): TBytes;
begin
  SetLength(Result, TOggBitPacker.Bytes(ABuffer));
  if Length(Result) > 0 then
    Move(TOggBitPacker.GetBuffer(ABuffer)^, Result[0], Length(Result));
end;

procedure TTestOggBitPacker.StartReading(const ABytes: array of Byte);
begin
  SetLength(FData, Length(ABytes));
  Move(ABytes[0], FData[0], Length(ABytes));
  TOggBitPacker.ReadInit(@FBuffer, @FData[0], Length(FData));
end;

procedure TTestOggBitPacker.SwitchToReading;
begin
  FData := ContentOf(@FBuffer);
  TOggBitPacker.WriteClear(@FBuffer);
  TOggBitPacker.ReadInit(@FBuffer, @FData[0], Length(FData));
end;

procedure TTestOggBitPacker.TestScriveDueParoleNelloStessoByte;
var
  LContent: TBytes;
begin
  TOggBitPacker.WriteInit(@FBuffer);

  // 5 (101) in the three low bits, 17 (10001) in the five high ones
  TOggBitPacker.Write(@FBuffer, 5, 3);
  TOggBitPacker.Write(@FBuffer, 17, 5);

  LContent := ContentOf(@FBuffer);
  Assert.AreEqual(1, Length(LContent));
  Assert.AreEqual($8D, Integer(LContent[0]));
end;

procedure TTestOggBitPacker.TestLeggeCioCheHaScritto;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, 5, 3);
  TOggBitPacker.Write(@FBuffer, 1000, 12);
  TOggBitPacker.Write(@FBuffer, 1, 1);
  TOggBitPacker.Write(@FBuffer, $ABCD, 16);

  SwitchToReading;

  Assert.AreEqual(5, Integer(TOggBitPacker.Read(@FBuffer, 3)));
  Assert.AreEqual(1000, Integer(TOggBitPacker.Read(@FBuffer, 12)));
  Assert.AreEqual(1, Integer(TOggBitPacker.Read(@FBuffer, 1)));
  Assert.AreEqual($ABCD, Integer(TOggBitPacker.Read(@FBuffer, 16)));
end;

procedure TTestOggBitPacker.TestParolaDa32Bit;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, 3, 2);
  TOggBitPacker.Write(@FBuffer, $DEADBEEF, 32);

  SwitchToReading;
  Assert.AreEqual(3, Integer(TOggBitPacker.Read(@FBuffer, 2)));

  // The 32 bits come back as a long: the same bits
  Assert.AreEqual(Int64($DEADBEEF), Int64(Cardinal(TOggBitPacker.Read(@FBuffer, 32))));
end;

procedure TTestOggBitPacker.TestPiuDi256ByteFannoCrescereLoSpazio;
var
  LIndex: Integer;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  for LIndex := 0 to 999 do
    TOggBitPacker.Write(@FBuffer, LIndex and $FF, 8);
  FData := ContentOf(@FBuffer);

  Assert.AreEqual(1000, Length(FData));
  Assert.IsTrue(FBuffer.Storage > 1000);
  for LIndex := 0 to 999 do
    Assert.AreEqual(LIndex and $FF, Integer(FData[LIndex]));
end;

procedure TTestOggBitPacker.TestIBitFuoriDalLimiteAzzerannoIlBuffer;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, 1, 4);

  // More than 32 bits is an error: the buffer is cleared
  TOggBitPacker.Write(@FBuffer, 1, 33);

  Assert.IsNull(FBuffer.Buffer);
  Assert.AreEqual(-1, TOggBitPacker.WriteCheck(@FBuffer));
end;

procedure TTestOggBitPacker.TestLookNonAvanza;
begin
  StartReading([$B4, $6D, $01, $02, $03, $04]);

  Assert.AreEqual($4, Integer(TOggBitPacker.Look(@FBuffer, 4)));
  Assert.AreEqual($4, Integer(TOggBitPacker.Look(@FBuffer, 4)));
  Assert.AreEqual($6DB4 and $FFF, Integer(TOggBitPacker.Look(@FBuffer, 12)));
  Assert.AreEqual(0, Integer(TOggBitPacker.Bits(@FBuffer)));
end;

procedure TTestOggBitPacker.TestAdvanceEAdvance1;
begin
  StartReading([$FF, $0F, $00, $00, $00, $00]);

  TOggBitPacker.Advance(@FBuffer, 10);
  Assert.AreEqual(10, Integer(TOggBitPacker.Bits(@FBuffer)));
  TOggBitPacker.Advance1(@FBuffer);
  Assert.AreEqual(11, Integer(TOggBitPacker.Bits(@FBuffer)));
  // The bit 11 is the last of the four ones of the low nibble of $0F, the next four are zeros
  Assert.AreEqual(1, Integer(TOggBitPacker.Read(@FBuffer, 5)));
end;

procedure TTestOggBitPacker.TestRead1ELook1;
begin
  StartReading([$05]);

  Assert.AreEqual(1, Integer(TOggBitPacker.Look1(@FBuffer)));
  Assert.AreEqual(1, Integer(TOggBitPacker.Read1(@FBuffer)));
  Assert.AreEqual(0, Integer(TOggBitPacker.Read1(@FBuffer)));
  Assert.AreEqual(1, Integer(TOggBitPacker.Read1(@FBuffer)));
end;

procedure TTestOggBitPacker.TestLeggereOltreLaFineDaMenoUno;
begin
  StartReading([$FF, $FF]);

  Assert.AreEqual(-1, Integer(TOggBitPacker.Read(@FBuffer, 17)));
  // The buffer is at its end for good
  Assert.IsNull(FBuffer.Ptr);
  Assert.AreEqual(-1, Integer(TOggBitPacker.Read(@FBuffer, 1)));
end;

procedure TTestOggBitPacker.TestBytesEBits;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, 0, 3);
  Assert.AreEqual(1, Integer(TOggBitPacker.Bytes(@FBuffer)));
  Assert.AreEqual(3, Integer(TOggBitPacker.Bits(@FBuffer)));

  TOggBitPacker.Write(@FBuffer, 0, 13);
  Assert.AreEqual(2, Integer(TOggBitPacker.Bytes(@FBuffer)));
  Assert.AreEqual(16, Integer(TOggBitPacker.Bits(@FBuffer)));
end;

procedure TTestOggBitPacker.TestTroncaScartaIBitInPiu;
var
  LContent: TBytes;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, $FFFF, 16);

  TOggBitPacker.WriteTruncate(@FBuffer, 11);

  LContent := ContentOf(@FBuffer);
  Assert.AreEqual(11, Integer(TOggBitPacker.Bits(@FBuffer)));
  Assert.AreEqual(2, Length(LContent));
  Assert.AreEqual($FF, Integer(LContent[0]));
  Assert.AreEqual($07, Integer(LContent[1]));
end;

procedure TTestOggBitPacker.TestAllineaRiempieIlByte;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, 3, 2);

  TOggBitPacker.WriteAlign(@FBuffer);

  Assert.AreEqual(8, Integer(TOggBitPacker.Bits(@FBuffer)));
  TOggBitPacker.WriteAlign(@FBuffer);
  Assert.AreEqual(8, Integer(TOggBitPacker.Bits(@FBuffer)));
end;

procedure TTestOggBitPacker.TestCopiaConIBitAllineati;
const
  SOURCE: array[0..3] of Byte = ($11, $22, $33, $44);
var
  LContent: TBytes;
begin
  TOggBitPacker.WriteInit(@FBuffer);

  TOggBitPacker.WriteCopy(@FBuffer, @SOURCE[0], 32);

  LContent := ContentOf(@FBuffer);
  Assert.AreEqual(4, Length(LContent));
  Assert.AreEqual($11, Integer(LContent[0]));
  Assert.AreEqual($44, Integer(LContent[3]));
end;

procedure TTestOggBitPacker.TestCopiaConIBitNonAllineati;
const
  SOURCE: array[0..1] of Byte = ($FF, $01);
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, 0, 4);

  // 9 bits of the source: the whole $FF and the low bit of $01
  TOggBitPacker.WriteCopy(@FBuffer, @SOURCE[0], 9);

  Assert.AreEqual(13, Integer(TOggBitPacker.Bits(@FBuffer)));
  SwitchToReading;
  Assert.AreEqual(0, Integer(TOggBitPacker.Read(@FBuffer, 4)));
  Assert.AreEqual($1FF, Integer(TOggBitPacker.Read(@FBuffer, 9)));
end;

procedure TTestOggBitPacker.TestResetRicominciaDaCapo;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  TOggBitPacker.Write(@FBuffer, $1234, 16);

  TOggBitPacker.Reset(@FBuffer);

  Assert.AreEqual(0, Integer(TOggBitPacker.Bits(@FBuffer)));
  TOggBitPacker.Write(@FBuffer, 1, 1);
  Assert.AreEqual(1, Integer(TOggBitPacker.GetBuffer(@FBuffer)^));
end;

procedure TTestOggBitPacker.TestWriteCheck;
begin
  TOggBitPacker.WriteInit(@FBuffer);
  Assert.AreEqual(0, TOggBitPacker.WriteCheck(@FBuffer));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOggBitPacker);

end.
