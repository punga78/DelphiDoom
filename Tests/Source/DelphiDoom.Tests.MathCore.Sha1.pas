{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the SHA-1                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Sha1;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the old SHA1_CalcSHA1Buf of m_sha1 (golden file checksums.golden.txt: the
  ///   digests of buffers of 0..130 bytes and of some bigger ones) and the vectors of FIPS 180
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreSha1 = class(TObject)
  private
    function Digest(const ASize: Integer): string;
  public
    [Test]
    procedure DovrebbeDareGliStessiDigestDelVecchioSha1PerLeLunghezzeFinoA130;
    [Test]
    procedure DovrebbeDareGliStessiDigestDelVecchioSha1PerBufferGrandi;
    [Test]
    procedure DovrebbeDareIlDigestDiAbc;
    [Test]
    procedure DovrebbeDareIlDigestDelTestoVuoto;
    [Test]
    procedure DovrebbeDareIlDigestDelTestoDiDueBlocchi;
    [Test]
    procedure DovrebbeDareLoStessoDigestSeIDatiArrivanoAPezzi;
    [Test]
    procedure DovrebbeDareLoStessoRisultatoDopoUnaSecondaChiamata;
    [Test]
    procedure DovrebbeDareLeVentiByteNellaFormaDelVecchioSha1String;
  end;

implementation

uses
  DelphiDoom.MathCore.Sha1, DelphiDoom.Tests.MathCore.Golden, DelphiDoom.Tests.MathCore.Samples;

{ TTestMathCoreSha1 }

function TTestMathCoreSha1.Digest(const ASize: Integer): string;
var
  LBuffer: TBytes;
  LByte: Integer;
  LState: Cardinal;
begin
  SetLength(LBuffer, ASize);
  LState := TMathCoreSamples.INITIAL_STATE + Cardinal(ASize) * 7;
  for LByte := 0 to ASize - 1 do
    LBuffer[LByte] := Byte(TMathCoreSamples.NextRandom(LState));
  if ASize > 0 then
    Result := TSha1.ToHex(TSha1.Calculate(LBuffer[0], ASize))
  else
    Result := TSha1.ToHex(TSha1.Calculate(ASize, 0));
end;

procedure TTestMathCoreSha1.DovrebbeDareGliStessiDigestDelVecchioSha1PerLeLunghezzeFinoA130;
var
  LGolden: TGoldenFile;
  LSize: Integer;
begin
  LGolden := TGoldenFile.Create('checksums.golden.txt');
  try
    for LSize := 0 to 130 do
      LGolden.Check('sha1.size' + IntToStr(LSize), Digest(LSize));
  finally
    LGolden.Free;
  end;
end;

procedure TTestMathCoreSha1.DovrebbeDareGliStessiDigestDelVecchioSha1PerBufferGrandi;
var
  LGolden: TGoldenFile;
begin
  LGolden := TGoldenFile.Create('checksums.golden.txt');
  try
    LGolden.Check('sha1.size1000', Digest(1000));
    LGolden.Check('sha1.size4099', Digest(4099));
    LGolden.Check('sha1.size65599', Digest(65599));
  finally
    LGolden.Free;
  end;
end;

procedure TTestMathCoreSha1.DovrebbeDareIlDigestDiAbc;
begin
  Assert.AreEqual('a9993e364706816aba3e25717850c26c9cd0d89d', TSha1.ToHex(TSha1.CalculateAnsi('abc')));
end;

procedure TTestMathCoreSha1.DovrebbeDareIlDigestDelTestoVuoto;
begin
  Assert.AreEqual('da39a3ee5e6b4b0d3255bfef95601890afd80709', TSha1.ToHex(TSha1.CalculateAnsi('')));
end;

procedure TTestMathCoreSha1.DovrebbeDareIlDigestDelTestoDiDueBlocchi;
begin
  Assert.AreEqual('84983e441c3bd26ebaae4aa1f95129e5e54670f1',
    TSha1.ToHex(TSha1.CalculateAnsi('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq')));
end;

procedure TTestMathCoreSha1.DovrebbeDareLoStessoDigestSeIDatiArrivanoAPezzi;
var
  LSha: TSha1;
  LText: AnsiString;
begin
  LText := 'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq';
  LSha := TSha1.Create;
  try
    LSha.Update(LText[1], 1);
    LSha.Update(LText[2], 30);
    LSha.Update(LText[32], Length(LText) - 31);
    Assert.AreEqual('84983e441c3bd26ebaae4aa1f95129e5e54670f1', TSha1.ToHex(LSha.Finish));
  finally
    LSha.Free;
  end;
end;

procedure TTestMathCoreSha1.DovrebbeDareLoStessoRisultatoDopoUnaSecondaChiamata;
var
  LSha: TSha1;
  LText: AnsiString;
begin
  LText := 'abc';
  LSha := TSha1.Create;
  try
    LSha.Update(LText[1], 3);
    LSha.Finish;
    LSha.Update(LText[1], 3);
    Assert.AreEqual('a9993e364706816aba3e25717850c26c9cd0d89d', TSha1.ToHex(LSha.Finish));
  finally
    LSha.Free;
  end;
end;

procedure TTestMathCoreSha1.DovrebbeDareLeVentiByteNellaFormaDelVecchioSha1String;
var
  LRaw: AnsiString;
begin
  LRaw := TSha1.ToRawString(TSha1.CalculateAnsi('abc'));
  Assert.AreEqual(20, Length(LRaw));
  Assert.AreEqual(Byte($A9), Byte(LRaw[1]));
  Assert.AreEqual(Byte($9D), Byte(LRaw[20]));
end;

end.
