{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the CRC-32                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Crc32;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the old GetCRC32 of m_crc32 (golden file checksums.golden.txt: the CRC of
  ///   files of various sizes) and the known values of the standard
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreCrc32 = class(TObject)
  public
    [Test]
    procedure DovrebbeDareLoStessoCrcDelVecchioGetCrc32;
    [Test]
    procedure DovrebbeDareIlValoreNotoDelloStandard;
    [Test]
    procedure DovrebbeDareLoStessoCrcSeIDatiArrivanoAPezzi;
    [Test]
    procedure DovrebbeRipartireDaZeroConReset;
    [Test]
    procedure DovrebbeScrivereOttoCifreEsadecimaliMinuscole;
    [Test]
    procedure DovrebbeDareSuUnoStreamLoStessoCrcDelVecchioGetCrc32;
    [Test]
    procedure DovrebbeLeggereLoStreamDallaPosizioneCorrente;
    [Test]
    procedure DovrebbeRifiutareUnoStreamNil;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.MathCore.Crc32,DelphiDoom.Tests.MathCore.Golden, DelphiDoom.Tests.MathCore.Samples;

const
  CRC_SIZES: array[0..12] of Integer = (0, 1, 2, 3, 255, 256, 257, 510, 511, 512, 1000, 4097, 65543);

{ TTestMathCoreCrc32 }

procedure TTestMathCoreCrc32.DovrebbeDareLoStessoCrcDelVecchioGetCrc32;
var
  LGolden: TGoldenFile;
  LBuffer: TBytes;
  LSize, LIndex, LByte: Integer;
  LState: Cardinal;
begin
  LGolden := TGoldenFile.Create('checksums.golden.txt');
  try
    for LIndex := 0 to High(CRC_SIZES) do
    begin
      LSize := CRC_SIZES[LIndex];
      SetLength(LBuffer, LSize);
      LState := TMathCoreSamples.INITIAL_STATE + Cardinal(LSize);
      for LByte := 0 to LSize - 1 do
        LBuffer[LByte] := Byte(TMathCoreSamples.NextRandom(LState));
      if LSize > 0 then
        LGolden.Check('crc32.size' + IntToStr(LSize), TCrc32.ToHex(TCrc32.Calculate(LBuffer[0], LSize)))
      else
        LGolden.Check('crc32.size0', TCrc32.ToHex(TCrc32.Calculate(LSize, 0)));
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestMathCoreCrc32.DovrebbeDareIlValoreNotoDelloStandard;
var
  LText: AnsiString;
begin
  LText := '123456789';
  Assert.AreEqual(Cardinal($CBF43926), TCrc32.Calculate(LText[1], Length(LText)));
  Assert.AreEqual('cbf43926', TCrc32.ToHex(TCrc32.Calculate(LText[1], Length(LText))));
end;

procedure TTestMathCoreCrc32.DovrebbeDareLoStessoCrcSeIDatiArrivanoAPezzi;
var
  LText: AnsiString;
  LCrc: TCrc32;
begin
  LText := '123456789';
  LCrc := TCrc32.Create;
  try
    LCrc.Update(LText[1], 4);
    LCrc.Update(LText[5], 5);
    Assert.AreEqual(Cardinal($CBF43926), LCrc.Value);
  finally
    LCrc.Free;
  end;
end;

procedure TTestMathCoreCrc32.DovrebbeRipartireDaZeroConReset;
var
  LText: AnsiString;
  LCrc: TCrc32;
begin
  LText := '123456789';
  LCrc := TCrc32.Create;
  try
    LCrc.Update(LText[1], 3);
    LCrc.Reset;
    LCrc.Update(LText[1], 9);
    Assert.AreEqual(Cardinal($CBF43926), LCrc.Value);
  finally
    LCrc.Free;
  end;
end;

procedure TTestMathCoreCrc32.DovrebbeScrivereOttoCifreEsadecimaliMinuscole;
begin
  Assert.AreEqual('00000000', TCrc32.ToHex(0));
  Assert.AreEqual('0000abcd', TCrc32.ToHex($ABCD));
  Assert.AreEqual('ffffffff', TCrc32.ToHex($FFFFFFFF));
end;

procedure TTestMathCoreCrc32.DovrebbeDareSuUnoStreamLoStessoCrcDelVecchioGetCrc32;
var
  LGolden: TGoldenFile;
  LStream: TBytesStream;
  LBuffer: TBytes;
  LSize, LIndex, LByte: Integer;
  LState: Cardinal;
begin
  // the golden values are the CRC that the old GetCRC32 gave for files with these bytes;
  // 65543 bytes need more than one read of the stream
  LGolden := TGoldenFile.Create('checksums.golden.txt');
  try
    for LIndex := 0 to High(CRC_SIZES) do
    begin
      LSize := CRC_SIZES[LIndex];
      SetLength(LBuffer, LSize);
      LState := TMathCoreSamples.INITIAL_STATE + Cardinal(LSize);
      for LByte := 0 to LSize - 1 do
        LBuffer[LByte] := Byte(TMathCoreSamples.NextRandom(LState));
      LStream := TBytesStream.Create(LBuffer);
      try
        LGolden.Check('crc32.size' + IntToStr(LSize), TCrc32.ToHex(TCrc32.CalculateStream(LStream)));
      finally
        LStream.Free;
      end;
    end;
  finally
    LGolden.Free;
  end;
end;

procedure TTestMathCoreCrc32.DovrebbeLeggereLoStreamDallaPosizioneCorrente;
var
  LText: AnsiString;
  LStream: TMemoryStream;
begin
  LText := 'xyz123456789';
  LStream := TMemoryStream.Create;
  try
    LStream.WriteBuffer(LText[1], Length(LText));
    LStream.Position := 3;
    Assert.AreEqual(Cardinal($CBF43926), TCrc32.CalculateStream(LStream));
    Assert.AreEqual(Int64(Length(LText)), LStream.Position);
  finally
    LStream.Free;
  end;
end;

procedure TTestMathCoreCrc32.DovrebbeRifiutareUnoStreamNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TCrc32.CalculateStream(nil);
    end, EArgumentNilException);
end;

end.
