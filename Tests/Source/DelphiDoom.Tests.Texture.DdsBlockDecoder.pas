{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TDdsBlockDecoder (blocks worked out by hand)           }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.DdsBlockDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Dds.Types,
  DelphiDoom.Texture.Dds.BlockDecoder, DelphiDoom.Imaging.Rgba.Image;

type
  [TestFixture]
  [Category('IdImages')]
  TTestDdsBlockDecoder = class
  strict private
    class procedure CheckTexel(const APixels: TDdsBlockPixels; const ATexel: Integer; const ARed,
      AGreen, ABlue, AAlpha: Integer); static;
    class function ColorBlock(const AColor0, AColor1: Word; const AIndexByte: Byte): TBytes; static;
  public
    [Test]
    procedure DovrebbeDecodificareDxt1ABauQuattroColori;
    [Test]
    procedure DovrebbeDecodificareDxt1ATreColoriConIlNeroTrasparente;
    [Test]
    procedure DovrebbeDecodificareLAlfaAQuattroBitDiDxt3;
    [Test]
    procedure DovrebbeDecodificareLAlfaDiDxt5ConOttoValori;
    [Test]
    procedure DovrebbeDecodificareLAlfaDiDxt5ConSeiValoriPiuZeroEDuecentocinquantacinque;
    [Test]
    procedure DovrebbeUsareSempreQuattroColoriNeiBlocchiDxt3EDxt5;
    [Test]
    procedure DovrebbeEspandereIl565RipetendoIBitAlti;
    [Test]
    procedure DovrebbeTagliareLeSuperficiNonMultipleDiQuattro;
    [Test]
    procedure DovrebbeRifiutareUnaSuperficieTroncata;
    [Test]
    procedure DovrebbeDareLeDimensioniDeiBlocchi;
    [Test]
    procedure DovrebbeRifiutareUnFormatoNonCompresso;
  end;

implementation

{ TTestDdsBlockDecoder }

class procedure TTestDdsBlockDecoder.CheckTexel(const APixels: TDdsBlockPixels;
  const ATexel: Integer; const ARed, AGreen, ABlue, AAlpha: Integer);
begin
  Assert.AreEqual<Integer>(ARed, APixels[ATexel * 4], Format('texel %d red', [ATexel]));
  Assert.AreEqual<Integer>(AGreen, APixels[ATexel * 4 + 1], Format('texel %d green', [ATexel]));
  Assert.AreEqual<Integer>(ABlue, APixels[ATexel * 4 + 2], Format('texel %d blue', [ATexel]));
  Assert.AreEqual<Integer>(AAlpha, APixels[ATexel * 4 + 3], Format('texel %d alpha', [ATexel]));
end;

class function TTestDdsBlockDecoder.ColorBlock(const AColor0, AColor1: Word;
  const AIndexByte: Byte): TBytes;
begin
  SetLength(Result, 8);
  Result[0] := Byte(AColor0);
  Result[1] := Byte(AColor0 shr 8);
  Result[2] := Byte(AColor1);
  Result[3] := Byte(AColor1 shr 8);
  Result[4] := AIndexByte;
  Result[5] := AIndexByte;
  Result[6] := AIndexByte;
  Result[7] := AIndexByte;
end;

procedure TTestDdsBlockDecoder.DovrebbeDecodificareDxt1ABauQuattroColori;
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
begin
  // red and blue; each row of codes is 0, 1, 2, 3 = $E4
  LBlock := ColorBlock($F800, $001F, $E4);
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt1, @LBlock[0], LPixels);
  CheckTexel(LPixels, 0, 255, 0, 0, 255);
  CheckTexel(LPixels, 1, 0, 0, 255, 255);
  // (2a + b) / 3 and (a + 2b) / 3
  CheckTexel(LPixels, 2, 170, 0, 85, 255);
  CheckTexel(LPixels, 3, 85, 0, 170, 255);
  CheckTexel(LPixels, 15, 85, 0, 170, 255);
end;

procedure TTestDdsBlockDecoder.DovrebbeDecodificareDxt1ATreColoriConIlNeroTrasparente;
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
begin
  LBlock := ColorBlock($001F, $F800, $E4);
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt1, @LBlock[0], LPixels);
  CheckTexel(LPixels, 0, 0, 0, 255, 255);
  CheckTexel(LPixels, 1, 255, 0, 0, 255);
  CheckTexel(LPixels, 2, 127, 0, 127, 255);
  CheckTexel(LPixels, 3, 0, 0, 0, 0);
end;

procedure TTestDdsBlockDecoder.DovrebbeDecodificareLAlfaAQuattroBitDiDxt3;
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
  LIndex: Integer;
begin
  SetLength(LBlock, 16);
  for LIndex := 0 to 7 do
    LBlock[LIndex] := Byte((LIndex * 2) or ((LIndex * 2 + 1) shl 4));
  LBlock[8] := $FF;
  LBlock[9] := $FF;
  LBlock[10] := $FF;
  LBlock[11] := $FF;
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt3, @LBlock[0], LPixels);
  for LIndex := 0 to 15 do
    CheckTexel(LPixels, LIndex, 255, 255, 255, LIndex * 17);
end;

procedure TTestDdsBlockDecoder.DovrebbeDecodificareLAlfaDiDxt5ConOttoValori;
const
  EXPECTED: array[0..7] of Integer = (255, 0, 218, 182, 145, 109, 72, 36);
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
  LIndex: Integer;
  LBits: UInt64;
begin
  SetLength(LBlock, 16);
  LBlock[0] := 255;
  LBlock[1] := 0;
  LBits := 0;
  for LIndex := 0 to 15 do
    LBits := LBits or (UInt64(LIndex and 7) shl (3 * LIndex));
  for LIndex := 0 to 5 do
    LBlock[2 + LIndex] := Byte(LBits shr (8 * LIndex));
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt5, @LBlock[0], LPixels);
  for LIndex := 0 to 15 do
    Assert.AreEqual<Integer>(EXPECTED[LIndex and 7], LPixels[LIndex * 4 + 3], 'alpha ' + IntToStr(LIndex));
end;

procedure TTestDdsBlockDecoder.DovrebbeDecodificareLAlfaDiDxt5ConSeiValoriPiuZeroEDuecentocinquantacinque;
const
  EXPECTED: array[0..7] of Integer = (0, 255, 51, 102, 153, 204, 0, 255);
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
  LIndex: Integer;
  LBits: UInt64;
begin
  SetLength(LBlock, 16);
  LBlock[0] := 0;
  LBlock[1] := 255;
  LBits := 0;
  for LIndex := 0 to 15 do
    LBits := LBits or (UInt64(LIndex and 7) shl (3 * LIndex));
  for LIndex := 0 to 5 do
    LBlock[2 + LIndex] := Byte(LBits shr (8 * LIndex));
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt5, @LBlock[0], LPixels);
  for LIndex := 0 to 15 do
    Assert.AreEqual<Integer>(EXPECTED[LIndex and 7], LPixels[LIndex * 4 + 3], 'alpha ' + IntToStr(LIndex));
end;

procedure TTestDdsBlockDecoder.DovrebbeUsareSempreQuattroColoriNeiBlocchiDxt3EDxt5;
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
  LColors: TBytes;
begin
  // c0 < c1: DXT1 would use three colours and a transparent fourth; DXT5 does not
  LColors := ColorBlock($001F, $F800, $E4);
  SetLength(LBlock, 16);
  Move(LColors[0], LBlock[8], 8);
  LBlock[0] := 255;
  LBlock[1] := 255;
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt5, @LBlock[0], LPixels);
  // c0 is blue and c1 red: c2 = (2 * c0 + c1) / 3 and c3 = (c0 + 2 * c1) / 3
  CheckTexel(LPixels, 2, 85, 0, 170, 255);
  CheckTexel(LPixels, 3, 170, 0, 85, 255);
end;

procedure TTestDdsBlockDecoder.DovrebbeEspandereIl565RipetendoIBitAlti;
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
begin
  // $8410 = 10000 100000 10000: r = 16, g = 32, b = 16 -> 132, 130, 132
  LBlock := ColorBlock($8410, $0000, $00);
  TDdsBlockDecoder.DecodeBlock(TDdsFormat.Dxt1, @LBlock[0], LPixels);
  CheckTexel(LPixels, 0, 132, 130, 132, 255);
end;

procedure TTestDdsBlockDecoder.DovrebbeTagliareLeSuperficiNonMultipleDiQuattro;
var
  LData: TBytes;
  LImage: TImagingRgbaImage;
begin
  // 5 x 3: two blocks side by side, the first red, the second blue
  SetLength(LData, 16);
  Move(ColorBlock($F800, $F800, $00)[0], LData[0], 8);
  Move(ColorBlock($001F, $001F, $00)[0], LData[8], 8);
  LImage := TDdsBlockDecoder.DecodeSurface(TDdsFormat.Dxt1, LData, 0, 5, 3);
  Assert.AreEqual(5, LImage.Width);
  Assert.AreEqual(3, LImage.Height);
  Assert.AreEqual<Integer>(255, LImage.Pixels[(2 * 5 + 3) * 4]);
  Assert.AreEqual<Integer>(0, LImage.Pixels[(2 * 5 + 3) * 4 + 2]);
  Assert.AreEqual<Integer>(0, LImage.Pixels[(0 * 5 + 4) * 4]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[(0 * 5 + 4) * 4 + 2]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[(2 * 5 + 4) * 4 + 2]);
end;

procedure TTestDdsBlockDecoder.DovrebbeRifiutareUnaSuperficieTroncata;
var
  LData: TBytes;
begin
  SetLength(LData, 15);
  Assert.WillRaise(
    procedure
    begin
      TDdsBlockDecoder.DecodeSurface(TDdsFormat.Dxt1, LData, 0, 5, 3);
    end, EDdsException);
  Assert.WillRaise(
    procedure
    begin
      TDdsBlockDecoder.DecodeSurface(TDdsFormat.Dxt1, LData, -1, 4, 4);
    end, EDdsException);
end;

procedure TTestDdsBlockDecoder.DovrebbeDareLeDimensioniDeiBlocchi;
begin
  Assert.AreEqual(8, TDdsBlockDecoder.BlockSize(TDdsFormat.Dxt1));
  Assert.AreEqual(16, TDdsBlockDecoder.BlockSize(TDdsFormat.Dxt3));
  Assert.AreEqual(16, TDdsBlockDecoder.BlockSize(TDdsFormat.Dxt5));
  Assert.AreEqual(8, TDdsBlockDecoder.SurfaceSize(TDdsFormat.Dxt1, 1, 1));
  Assert.AreEqual(32, TDdsBlockDecoder.SurfaceSize(TDdsFormat.Dxt5, 5, 3));
end;

procedure TTestDdsBlockDecoder.DovrebbeRifiutareUnFormatoNonCompresso;
var
  LBlock: TBytes;
  LPixels: TDdsBlockPixels;
begin
  SetLength(LBlock, 16);
  Assert.WillRaise(
    procedure
    begin
      TDdsBlockDecoder.DecodeBlock(TDdsFormat.Uncompressed, @LBlock[0], LPixels);
    end, EDdsException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDdsBlockDecoder);

end.
