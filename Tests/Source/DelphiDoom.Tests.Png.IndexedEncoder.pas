{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the PNG library - TIndexedImage and TPngIndexedEncoder  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.IndexedEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf, DelphiDoom.Png.Intf, DelphiDoom.Png.Client,
  DelphiDoom.Png.IndexedImage, DelphiDoom.Png.IndexedEncoder.Intf;

type
  [TestFixture]
  [Category('png')]
  TTestPngIndexedEncoder = class(TObject)
  private
    FZlib: IZlib;
    FClient: TPngClient;
    FEncoder: IPngIndexedEncoder;
    function Palette: TBytes;
    function Picture(AWidth, AHeight: Integer): TIndexedImage;
    /// <summary>What the encoders of the Keen, Greed and OpenXcom libraries did before they were one</summary>
    function OldEncode(const AImage: TIndexedImage; const APalette: TBytes; ATransparent: Integer;
      ABlack: Boolean): TBytes;
    procedure AssertSameBytes(const AExpected, AActual: TBytes);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure UnImmagineNuovaDovrebbeEssereTuttaZero;
    [Test]
    procedure UnImmagineAvvoltaDovrebbeCondividereIPixel;
    [Test]
    procedure DovrebbeDireSeLImmagineEIntera;
    [Test]
    procedure DovrebbeScrivereIColoriDellaPalette;
    [Test]
    procedure LIndiceTrasparenteDovrebbeTenereIlColoreConAlfaZero;
    [Test]
    procedure LIndiceTrasparenteNeroDovrebbeEssereTuttoZero;
    [Test]
    procedure SenzaTrasparenzaOgniPixelDovrebbeEssereOpaco;
    [Test]
    [TestCase('Opaco', '-1,False')]
    [TestCase('ZeroColore', '0,False')]
    [TestCase('UltimoNero', '255,True')]
    [TestCase('ZeroNero', '0,True')]
    procedure DovrebbeDareGliStessiByteDeiVecchiEncoder(ATransparent: Integer; ABlack: Boolean);
    [Test]
    procedure DovrebbeSollevareSeIPixelNonSonoLarghezzaPerAltezza;
    [Test]
    procedure DovrebbeSollevareSeLaPaletteECorta;
    [Test]
    procedure DovrebbeAccettareUnaPalettePiuLunga;
    [Test]
    procedure DovrebbeSollevareSenzaLibreriaPng;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine, DelphiDoom.Png.Engine, DelphiDoom.Png.IndexedEncoder;

procedure TTestPngIndexedEncoder.Setup;
begin
  FZlib := TZlibEngine.Create;
  FClient := TPngClient.Create(TPngEngine.Create(FZlib));
  FEncoder := TPngIndexedEncoder.Create(FClient);
end;

procedure TTestPngIndexedEncoder.TearDown;
begin
  FEncoder := nil;
  FreeAndNil(FClient);
  FZlib := nil;
end;

function TTestPngIndexedEncoder.Palette: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, PNG_INDEXED_PALETTE_BYTES);
  for LIndex := 0 to 255 do
  begin
    Result[LIndex * 3] := Byte(LIndex);
    Result[LIndex * 3 + 1] := Byte(255 - LIndex);
    Result[LIndex * 3 + 2] := Byte(LIndex * 7 + 3);
  end;
end;

function TTestPngIndexedEncoder.Picture(AWidth, AHeight: Integer): TIndexedImage;
var
  LIndex: Integer;
begin
  Result := TIndexedImage.Create(AWidth, AHeight);
  for LIndex := 0 to High(Result.Pixels) do
    Result.Pixels[LIndex] := Byte(LIndex * 37 + LIndex div 5);
end;

function TTestPngIndexedEncoder.OldEncode(const AImage: TIndexedImage; const APalette: TBytes;
  ATransparent: Integer; ABlack: Boolean): TBytes;
var
  LColors: array[0..255] of Cardinal;
  LPixels: TBytes;
  LIndex: Integer;
  LColor: Cardinal;
  LPixel: Byte;
begin
  // TPaletteConverter.Convert with the identity gamma the three encoders gave it
  for LIndex := 0 to 255 do
    LColors[LIndex] := (Cardinal(APalette[LIndex * 3]) shl 16) or (Cardinal(APalette[LIndex * 3 + 1]) shl 8) or
      Cardinal(APalette[LIndex * 3 + 2]);
  SetLength(LPixels, Length(AImage.Pixels) * 4);
  for LIndex := 0 to High(AImage.Pixels) do
  begin
    LPixel := AImage.Pixels[LIndex];
    if ABlack and (LPixel = ATransparent) then
    begin
      // TKeenPngEncoder
      LPixels[LIndex * 4] := 0;
      LPixels[LIndex * 4 + 1] := 0;
      LPixels[LIndex * 4 + 2] := 0;
      LPixels[LIndex * 4 + 3] := 0;
    end
    else
    begin
      // TGreedPngEncoder and TXcomPngEncoder
      LColor := LColors[LPixel];
      LPixels[LIndex * 4] := Byte(LColor);
      LPixels[LIndex * 4 + 1] := Byte(LColor shr 8);
      LPixels[LIndex * 4 + 2] := Byte(LColor shr 16);
      if LPixel = ATransparent then
        LPixels[LIndex * 4 + 3] := 0
      else
        LPixels[LIndex * 4 + 3] := $FF;
    end;
  end;
  Result := FClient.Encode(LPixels, AImage.Width, AImage.Height, DDPNG_FORMAT_BGRA);
end;

procedure TTestPngIndexedEncoder.AssertSameBytes(const AExpected, AActual: TBytes);
begin
  Assert.AreEqual(Integer(Length(AExpected)), Integer(Length(AActual)));
  Assert.IsTrue(CompareMem(@AExpected[0], @AActual[0], Length(AExpected)), 'i byte del file sono diversi');
end;

procedure TTestPngIndexedEncoder.UnImmagineNuovaDovrebbeEssereTuttaZero;
var
  LImage: TIndexedImage;
  LIndex: Integer;
begin
  LImage := TIndexedImage.Create(7, 5);
  Assert.AreEqual(7, LImage.Width);
  Assert.AreEqual(5, LImage.Height);
  Assert.AreEqual(35, Integer(Length(LImage.Pixels)));
  for LIndex := 0 to High(LImage.Pixels) do
    Assert.AreEqual(0, Integer(LImage.Pixels[LIndex]));
  Assert.AreEqual(0, Integer(Length(TIndexedImage.Create(0, 5).Pixels)));
  Assert.AreEqual(0, Integer(Length(TIndexedImage.Create(4, -1).Pixels)));
end;

procedure TTestPngIndexedEncoder.UnImmagineAvvoltaDovrebbeCondividereIPixel;
var
  LPixels: TBytes;
  LImage: TIndexedImage;
begin
  LPixels := [1, 2, 3, 4, 5, 6];
  LImage := TIndexedImage.Wrap(3, 2, LPixels);
  Assert.IsTrue(LImage.IsValid);
  Assert.AreEqual(NativeUInt(Pointer(LPixels)), NativeUInt(Pointer(LImage.Pixels)), 'nessuna copia');
end;

procedure TTestPngIndexedEncoder.DovrebbeDireSeLImmagineEIntera;
begin
  Assert.IsTrue(TIndexedImage.Create(1, 1).IsValid);
  Assert.IsFalse(TIndexedImage.Create(0, 1).IsValid);
  Assert.IsFalse(TIndexedImage.Wrap(2, 2, [1, 2, 3]).IsValid);
  Assert.IsFalse(TIndexedImage.Wrap(2, 2, [1, 2, 3, 4, 5]).IsValid);
  Assert.IsFalse(TIndexedImage.Wrap(-2, -2, [1, 2, 3, 4]).IsValid);
  Assert.IsFalse(Default(TIndexedImage).IsValid);
end;

procedure TTestPngIndexedEncoder.DovrebbeScrivereIColoriDellaPalette;
var
  LImage: TIndexedImage;
  LPalette: TBytes;
  LDecoded: TPngImage;
  LIndex: Integer;
  LPixel: Byte;
begin
  LImage := Picture(16, 9);
  LPalette := Palette;
  LDecoded := FClient.Decode(FEncoder.Encode(LImage, LPalette));
  Assert.AreEqual(16, LDecoded.Info.Width);
  Assert.AreEqual(9, LDecoded.Info.Height);
  Assert.AreEqual(16 * 9 * 4, Integer(Length(LDecoded.Pixels)));
  for LIndex := 0 to High(LImage.Pixels) do
  begin
    LPixel := LImage.Pixels[LIndex];
    Assert.AreEqual(Integer(LPalette[LPixel * 3 + 2]), Integer(LDecoded.Pixels[LIndex * 4]), 'blu');
    Assert.AreEqual(Integer(LPalette[LPixel * 3 + 1]), Integer(LDecoded.Pixels[LIndex * 4 + 1]), 'verde');
    Assert.AreEqual(Integer(LPalette[LPixel * 3]), Integer(LDecoded.Pixels[LIndex * 4 + 2]), 'rosso');
    Assert.AreEqual(255, Integer(LDecoded.Pixels[LIndex * 4 + 3]), 'alfa');
  end;
end;

procedure TTestPngIndexedEncoder.LIndiceTrasparenteDovrebbeTenereIlColoreConAlfaZero;
var
  LImage: TIndexedImage;
  LPalette: TBytes;
  LDecoded: TPngImage;
begin
  LImage := TIndexedImage.Wrap(2, 1, [9, 200]);
  LPalette := Palette;
  LDecoded := FClient.Decode(FEncoder.Encode(LImage, LPalette, 9, ptcPalette));
  Assert.AreEqual(Integer(LPalette[9 * 3 + 2]), Integer(LDecoded.Pixels[0]));
  Assert.AreEqual(Integer(LPalette[9 * 3 + 1]), Integer(LDecoded.Pixels[1]));
  Assert.AreEqual(Integer(LPalette[9 * 3]), Integer(LDecoded.Pixels[2]));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[3]));
  Assert.AreEqual(255, Integer(LDecoded.Pixels[7]));
end;

procedure TTestPngIndexedEncoder.LIndiceTrasparenteNeroDovrebbeEssereTuttoZero;
var
  LDecoded: TPngImage;
begin
  LDecoded := FClient.Decode(FEncoder.Encode(TIndexedImage.Wrap(2, 1, [255, 3]), Palette, 255, ptcBlack));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[0]));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[1]));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[2]));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[3]));
  Assert.AreEqual(255, Integer(LDecoded.Pixels[7]));
end;

procedure TTestPngIndexedEncoder.SenzaTrasparenzaOgniPixelDovrebbeEssereOpaco;
var
  LDecoded: TPngImage;
  LIndex: Integer;
begin
  LDecoded := FClient.Decode(FEncoder.Encode(TIndexedImage.Wrap(4, 1, [0, 1, 254, 255]), Palette));
  for LIndex := 0 to 3 do
    Assert.AreEqual(255, Integer(LDecoded.Pixels[LIndex * 4 + 3]));
end;

procedure TTestPngIndexedEncoder.DovrebbeDareGliStessiByteDeiVecchiEncoder(ATransparent: Integer;
  ABlack: Boolean);
var
  LImage: TIndexedImage;
  LPalette: TBytes;
  LColor: TPngTransparentColor;
begin
  LPalette := Palette;
  if ABlack then
    LColor := ptcBlack
  else
    LColor := ptcPalette;
  LImage := Picture(320, 200);
  AssertSameBytes(OldEncode(LImage, LPalette, ATransparent, ABlack),
    FEncoder.Encode(LImage, LPalette, ATransparent, LColor));
  LImage := Picture(1, 1);
  AssertSameBytes(OldEncode(LImage, LPalette, ATransparent, ABlack),
    FEncoder.Encode(LImage, LPalette, ATransparent, LColor));
  LImage := Picture(33, 77);
  AssertSameBytes(OldEncode(LImage, LPalette, ATransparent, ABlack),
    FEncoder.Encode(LImage, LPalette, ATransparent, LColor));
end;

procedure TTestPngIndexedEncoder.DovrebbeSollevareSeIPixelNonSonoLarghezzaPerAltezza;
begin
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(TIndexedImage.Wrap(2, 2, [1, 2, 3]), Palette);
    end, EPngIndexedImageException);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(Default(TIndexedImage), Palette);
    end, EPngIndexedImageException);
end;

procedure TTestPngIndexedEncoder.DovrebbeSollevareSeLaPaletteECorta;
var
  LShort: TBytes;
begin
  LShort := Copy(Palette, 0, PNG_INDEXED_PALETTE_BYTES - 1);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(TIndexedImage.Create(2, 2), LShort);
    end, EPngIndexedImageException);
end;

procedure TTestPngIndexedEncoder.DovrebbeAccettareUnaPalettePiuLunga;
var
  LLong: TBytes;
begin
  LLong := Palette;
  SetLength(LLong, PNG_INDEXED_PALETTE_BYTES + 10);
  AssertSameBytes(FEncoder.Encode(Picture(8, 8), Palette), FEncoder.Encode(Picture(8, 8), LLong));
end;

procedure TTestPngIndexedEncoder.DovrebbeSollevareSenzaLibreriaPng;
begin
  Assert.WillRaise(
    procedure
    begin
      TPngIndexedEncoder.Create(nil);
    end, EArgumentNilException);
end;

end.
