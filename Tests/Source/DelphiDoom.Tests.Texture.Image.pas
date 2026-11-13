{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureImage                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Image;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Colors;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureImage = class(TObject)
  private
    FImage: TTextureImage;
    function Palette: TTexturePixels;
    procedure FillPalettedImage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeIniziareVuota;
    [Test]
    procedure DovrebbeAzzerareIPixelCambiandoIByteDiUnPixel;
    [Test]
    procedure DovrebbeIgnorareUnNumeroDiByteDiUnPixelNonValido;
    [Test]
    procedure DovrebbeConservareLeRigheAllargandoLImmagine;
    [Test]
    procedure DovrebbeConservareIPixelAllungandoLImmagine;
    [Test]
    procedure DovrebbeCopiareIPixelDiUnaRigaDelloStessoFormato;
    [Test]
    procedure DovrebbeConvertireUnaRigaDa24BitA32Bit;
    [Test]
    procedure DovrebbeConvertireUnaRigaDa8BitConLaPalette;
    [Test]
    procedure DovrebbeConvertireUnaRigaDa4BitEDa1Bit;
    [Test]
    procedure DovrebbeScartareIPixelFuoriDallImmagine;
    [Test]
    procedure DovrebbeRipetereLaColonnaOltreLAltezza;
    [Test]
    procedure DovrebbeLeggereUnaColonnaDiUnImmagineConPalette;
    [Test]
    procedure DovrebbeConvertireUnImmagineA16BitInColoriVeri;
    [Test]
    procedure DovrebbeConvertireA32BitTenendoLaPalette;
    [Test]
    procedure DovrebbeFareLaScalaDiGrigi;
    [Test]
    procedure DovrebbeRispecchiareLImmagine;
    [Test]
    procedure DovrebbeScambiareRossoEBluUnaVolta;
    [Test]
    procedure DovrebbeScambiareLaPaletteDiUnImmagineA8Bit;
    [Test]
    procedure DovrebbeScalareConIlPixelPiuVicino;
    [Test]
    procedure DovrebbeCopiarsiConPaletteEFormato;
    [Test]
    procedure DovrebbeDareOffsetPredefinitiFinoAQuandoNonSonoImpostati;
    [Test]
    procedure DovrebbeLeggereUnaPaletteInBgr8ADaRecordDi3Byte;
    [Test]
    procedure DovrebbeDareLaPaletteWebSafeSenzaPalette;
    [Test]
    procedure DovrebbeIniziareLaPaletteTrasformataComeCopiaDellaPalette;
    [Test]
    procedure DovrebbeSommareIlColoreAllaPaletteTrasformata;
    [Test]
    procedure DovrebbeRicostruireTutte256LeVociDellaPaletteTrasformata;
    [Test]
    procedure DovrebbeLeggereLaRigaSenzaIlColoreAggiunto;
    [Test]
    procedure DovrebbeRifiutareLeLetturePalettateSenzaPalette;
    [Test]
    procedure DovrebbeSvuotarsiTenendoIlFormato;
  end;

implementation

function TTestTextureImage.Palette: TTexturePixels;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := $010000 * Cardinal(LIndex mod 7) + $000100 * Cardinal(LIndex mod 11) +
      Cardinal(LIndex);
end;

procedure TTestTextureImage.FillPalettedImage;
var
  LIndex: Integer;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(3);
  FImage.SetHeight(2);
  for LIndex := 0 to 5 do
    FImage.Pixels[LIndex] := Byte(LIndex + 10);
  FImage.SetPalette(Palette);
end;

procedure TTestTextureImage.Setup;
begin
  FImage := TTextureImage.Create;
end;

procedure TTestTextureImage.TearDown;
begin
  FImage.Free;
end;

procedure TTestTextureImage.DovrebbeIniziareVuota;
begin
  Assert.AreEqual(0, FImage.Width, 'dovrebbe avere larghezza 0');
  Assert.AreEqual(0, FImage.Height, 'dovrebbe avere altezza 0');
  Assert.AreEqual(0, FImage.BytesPerPixel, 'dovrebbe non avere un formato');
  Assert.IsFalse(FImage.HasPixels, 'dovrebbe non avere pixel');
  Assert.IsFalse(FImage.HasPalette, 'dovrebbe non avere palette');
  Assert.IsTrue(FImage.NeedsSwapRGB, 'dovrebbe aspettare lo scambio di rosso e blu');
end;

procedure TTestTextureImage.DovrebbeAzzerareIPixelCambiandoIByteDiUnPixel;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(2);
  FImage.SetHeight(2);
  FImage.Pixels[0] := 9;
  FImage.SetBytesPerPixel(4);
  Assert.AreEqual<Integer>(16, Length(FImage.Pixels), 'dovrebbe avere 4 byte per pixel');
  Assert.AreEqual(Byte(0), FImage.Pixels[0], 'dovrebbe dare un buffer azzerato');
end;

procedure TTestTextureImage.DovrebbeIgnorareUnNumeroDiByteDiUnPixelNonValido;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetBytesPerPixel(3);
  FImage.SetBytesPerPixel(0);
  FImage.SetBytesPerPixel(5);
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe tenere il formato di prima');
end;

procedure TTestTextureImage.DovrebbeConservareLeRigheAllargandoLImmagine;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(2);
  FImage.SetHeight(2);
  FImage.Pixels[0] := 1;
  FImage.Pixels[1] := 2;
  FImage.Pixels[2] := 3;
  FImage.Pixels[3] := 4;
  FImage.SetWidth(4);
  Assert.AreEqual<Integer>(8, Length(FImage.Pixels), 'dovrebbe avere 4x2 pixel');
  Assert.AreEqual(Byte(2), FImage.Pixels[1], 'dovrebbe tenere la prima riga');
  Assert.AreEqual(Byte(0), FImage.Pixels[2], 'dovrebbe azzerare i pixel nuovi');
  Assert.AreEqual(Byte(3), FImage.Pixels[4], 'dovrebbe spostare la seconda riga');
end;

procedure TTestTextureImage.DovrebbeConservareIPixelAllungandoLImmagine;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(2);
  FImage.SetHeight(2);
  FImage.Pixels[3] := 7;
  FImage.SetHeight(3);
  Assert.AreEqual<Integer>(6, Length(FImage.Pixels), 'dovrebbe avere 2x3 pixel');
  Assert.AreEqual(Byte(7), FImage.Pixels[3], 'dovrebbe tenere i pixel di prima');
  Assert.AreEqual(Byte(0), FImage.Pixels[5], 'dovrebbe azzerare la riga nuova');
end;

procedure TTestTextureImage.DovrebbeCopiareIPixelDiUnaRigaDelloStessoFormato;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(4);
  FImage.SetHeight(2);
  FImage.PutPixels(1, 1, 2, TBytes.Create(5, 6), 0, TEXTURE_FORMAT_8BIT);
  Assert.AreEqual(Byte(5), FImage.Pixels[5], 'dovrebbe scrivere il primo pixel');
  Assert.AreEqual(Byte(6), FImage.Pixels[6], 'dovrebbe scrivere il secondo pixel');
  Assert.AreEqual(Byte(0), FImage.Pixels[4], 'dovrebbe lasciare gli altri');
end;

procedure TTestTextureImage.DovrebbeConvertireUnaRigaDa24BitA32Bit;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(2);
  FImage.SetHeight(1);
  // B, G, R, B, G, R
  FImage.PutPixels(0, 0, 2, TBytes.Create($11, $22, $33, $44, $55, $66, 0), 0, TEXTURE_FORMAT_24BIT);
  Assert.AreEqual(Cardinal($00332211), PCardinal(@FImage.Pixels[0])^, 'dovrebbe dare $00RRGGBB senza alfa');
  Assert.AreEqual(Cardinal($00665544), PCardinal(@FImage.Pixels[4])^, 'dovrebbe convertire il secondo pixel');
end;

procedure TTestTextureImage.DovrebbeConvertireUnaRigaDa8BitConLaPalette;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(2);
  FImage.SetHeight(1);
  FImage.SetPalette(Palette);
  FImage.PutPixels(0, 0, 2, TBytes.Create(3, 200), 0, TEXTURE_FORMAT_8BIT);
  Assert.AreEqual(Palette[3], PCardinal(@FImage.Pixels[0])^, 'dovrebbe passare dalla palette');
  Assert.AreEqual(Palette[200], PCardinal(@FImage.Pixels[4])^, 'dovrebbe passare dalla palette anche il secondo');
end;

procedure TTestTextureImage.DovrebbeConvertireUnaRigaDa4BitEDa1Bit;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(5);
  FImage.SetHeight(2);
  FImage.SetPalette(Palette);
  // 4 bit: the high nibble first, an odd count uses only the high nibble of the last byte
  FImage.PutPixels(0, 0, 5, TBytes.Create($12, $34, $50), 0, TEXTURE_FORMAT_4BIT);
  Assert.AreEqual(Palette[1], PCardinal(@FImage.Pixels[0])^, 'dovrebbe prendere il nibble alto');
  Assert.AreEqual(Palette[2], PCardinal(@FImage.Pixels[4])^, 'dovrebbe prendere il nibble basso');
  Assert.AreEqual(Palette[5], PCardinal(@FImage.Pixels[16])^, 'dovrebbe prendere solo il nibble alto dell''ultimo');
  // 1 bit: the high bit first
  FImage.PutPixels(0, 1, 5, TBytes.Create($A8), 0, TEXTURE_FORMAT_1BIT);
  Assert.AreEqual(Palette[1], PCardinal(@FImage.Pixels[20])^, 'dovrebbe dare 1 per il bit alto');
  Assert.AreEqual(Palette[0], PCardinal(@FImage.Pixels[24])^, 'dovrebbe dare 0 per il secondo bit');
  Assert.AreEqual(Palette[1], PCardinal(@FImage.Pixels[28])^, 'dovrebbe dare 1 per il terzo bit');
end;

procedure TTestTextureImage.DovrebbeScartareIPixelFuoriDallImmagine;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(2);
  FImage.SetHeight(2);
  FImage.PutPixels(1, 1, 5, TBytes.Create(1, 2, 3, 4, 5), 0, TEXTURE_FORMAT_8BIT);
  FImage.PutPixels(0, -1, 2, TBytes.Create(9, 9), 0, TEXTURE_FORMAT_8BIT);
  Assert.AreEqual<Integer>(4, Length(FImage.Pixels), 'dovrebbe tenere la stessa dimensione');
  Assert.AreEqual(Byte(1), FImage.Pixels[3], 'dovrebbe scrivere il pixel dentro');
  Assert.AreEqual(Byte(0), FImage.Pixels[0], 'dovrebbe scartare i pixel sopra l''immagine');
end;

procedure TTestTextureImage.DovrebbeRipetereLaColonnaOltreLAltezza;
var
  LColors: array[0..4] of Cardinal;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(2);
  FImage.SetHeight(2);
  PTextureColorArray(FImage.PixelsPointer)^[0] := $A1;
  PTextureColorArray(FImage.PixelsPointer)^[1] := $B1;
  PTextureColorArray(FImage.PixelsPointer)^[2] := $A2;
  PTextureColorArray(FImage.PixelsPointer)^[3] := $B2;
  FImage.GetColumn32(0, 5, @LColors[0]);
  Assert.AreEqual(Cardinal($A1), LColors[0], 'dovrebbe dare il primo pixel della colonna');
  Assert.AreEqual(Cardinal($A2), LColors[1], 'dovrebbe dare il secondo');
  Assert.AreEqual(Cardinal($A1), LColors[2], 'dovrebbe ricominciare dalla cima');
  FImage.GetColumn32(3, 2, @LColors[0]);
  Assert.AreEqual(Cardinal($B1), LColors[0], 'dovrebbe ripetere anche le colonne oltre la larghezza');
end;

procedure TTestTextureImage.DovrebbeLeggereUnaColonnaDiUnImmagineConPalette;
var
  LColors: array[0..2] of Cardinal;
begin
  FillPalettedImage;
  FImage.GetColumn32(1, 3, @LColors[0]);
  Assert.AreEqual(Palette[11], LColors[0], 'dovrebbe passare dalla palette');
  Assert.AreEqual(Palette[14], LColors[1], 'dovrebbe leggere la riga sotto');
  Assert.AreEqual(Palette[11], LColors[2], 'dovrebbe ricominciare');
end;

procedure TTestTextureImage.DovrebbeConvertireUnImmagineA16BitInColoriVeri;
var
  LColors: array[0..1] of Cardinal;
begin
  // regression: the old conversion of the 16 bit pixels always gave 0
  FImage.SetBytesPerPixel(2);
  FImage.SetWidth(2);
  FImage.SetHeight(1);
  PWord(@FImage.Pixels[0])^ := $7FFF;
  PWord(@FImage.Pixels[2])^ := $001F;
  FImage.GetRow32(0, 2, @LColors[0]);
  Assert.AreEqual(Cardinal($F8F8F8), LColors[0], 'dovrebbe dare il bianco');
  Assert.AreEqual(Cardinal($0000F8), LColors[1], 'dovrebbe dare il campo basso');
end;

procedure TTestTextureImage.DovrebbeConvertireA32BitTenendoLaPalette;
begin
  FillPalettedImage;
  FImage.ConvertTo32bit;
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe avere 4 byte per pixel');
  Assert.AreEqual(Palette[12], PTextureColorArray(FImage.PixelsPointer)^[2], 'dovrebbe avere il colore della palette');
  Assert.IsTrue(FImage.HasPalette, 'dovrebbe tenere la palette, come prima');
end;

procedure TTestTextureImage.DovrebbeFareLaScalaDiGrigi;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(2);
  FImage.SetHeight(1);
  PTextureColorArray(FImage.PixelsPointer)^[0] := $0A141E;
  PTextureColorArray(FImage.PixelsPointer)^[1] := $FFFFFF;
  FImage.ConvertToGrayScale;
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe avere un byte per pixel');
  Assert.AreEqual(Byte(20), FImage.Pixels[0], 'dovrebbe fare la media dei canali');
  Assert.AreEqual(Byte(255), FImage.Pixels[1], 'dovrebbe dare 255 per il bianco');
  Assert.AreEqual(Cardinal($141414), FImage.Palette[20], 'dovrebbe avere una palette di grigi');
end;

procedure TTestTextureImage.DovrebbeRispecchiareLImmagine;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(3);
  FImage.SetHeight(2);
  PTextureColorArray(FImage.PixelsPointer)^[0] := 1;
  PTextureColorArray(FImage.PixelsPointer)^[1] := 2;
  PTextureColorArray(FImage.PixelsPointer)^[2] := 3;
  PTextureColorArray(FImage.PixelsPointer)^[3] := 4;
  PTextureColorArray(FImage.PixelsPointer)^[4] := 5;
  PTextureColorArray(FImage.PixelsPointer)^[5] := 6;
  FImage.Mirror;
  Assert.AreEqual(Cardinal(3), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe scambiare i pixel dei lati');
  Assert.AreEqual(Cardinal(2), PTextureColorArray(FImage.PixelsPointer)^[1], 'dovrebbe lasciare quello di mezzo');
  Assert.AreEqual(Cardinal(4), PTextureColorArray(FImage.PixelsPointer)^[5], 'dovrebbe girare anche la seconda riga');
end;

procedure TTestTextureImage.DovrebbeScambiareRossoEBluUnaVolta;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(1);
  FImage.SetHeight(1);
  PTextureColorArray(FImage.PixelsPointer)^[0] := $FF112233;
  FImage.SwapRGB;
  Assert.AreEqual(Cardinal($FF332211), PTextureColorArray(FImage.PixelsPointer)^[0], 'dovrebbe scambiare');
  Assert.IsFalse(FImage.NeedsSwapRGB, 'dovrebbe ricordare che l''ha fatto');
  FImage.SwapRGB;
  Assert.AreEqual(Cardinal($FF332211), PTextureColorArray(FImage.PixelsPointer)^[0], 'non dovrebbe scambiare la seconda volta');
end;

procedure TTestTextureImage.DovrebbeScambiareLaPaletteDiUnImmagineA8Bit;
begin
  FillPalettedImage;
  FImage.SwapRGB;
  Assert.AreEqual(TTextureColors.SwapRedBlue(Palette[1]), FImage.Palette[1],
    'dovrebbe scambiare i canali della palette');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe restare a un byte per pixel');
end;

procedure TTestTextureImage.DovrebbeScalareConIlPixelPiuVicino;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(2);
  FImage.SetHeight(1);
  FImage.Pixels[0] := 10;
  FImage.Pixels[1] := 20;
  FImage.ScaleTo(4, 2);
  Assert.AreEqual<Integer>(8, Length(FImage.Pixels), 'dovrebbe avere 4x2 pixel');
  Assert.AreEqual(Byte(10), FImage.Pixels[1], 'dovrebbe ripetere il primo pixel');
  Assert.AreEqual(Byte(20), FImage.Pixels[2], 'dovrebbe passare al secondo');
  Assert.AreEqual(Byte(20), FImage.Pixels[7], 'dovrebbe ripetere la riga');
end;

procedure TTestTextureImage.DovrebbeCopiarsiConPaletteEFormato;
var
  LCopy: TTextureImage;
begin
  FillPalettedImage;
  FImage.ExternalAlphaPresent := True;
  LCopy := FImage.Clone;
  try
    Assert.AreEqual(3, LCopy.Width, 'dovrebbe avere la stessa larghezza');
    Assert.AreEqual(1, LCopy.BytesPerPixel, 'dovrebbe avere lo stesso formato');
    Assert.AreEqual(Byte(13), LCopy.Pixels[3], 'dovrebbe avere gli stessi pixel');
    Assert.AreEqual(Palette[200], LCopy.Palette[200], 'dovrebbe avere la stessa palette');
    Assert.IsTrue(LCopy.ExternalAlphaPresent, 'dovrebbe ricordare l''alfa esterno');
    LCopy.Pixels[0] := 99;
    Assert.AreEqual(Byte(10), FImage.Pixels[0], 'non dovrebbe condividere i pixel con l''originale');
  finally
    LCopy.Free;
  end;
end;

procedure TTestTextureImage.DovrebbeDareOffsetPredefinitiFinoAQuandoNonSonoImpostati;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(10);
  FImage.SetHeight(6);
  Assert.AreEqual(5, FImage.LeftOffset, 'dovrebbe dare mezza larghezza');
  Assert.AreEqual(6, FImage.TopOffset, 'dovrebbe dare l''altezza');
  Assert.IsFalse(FImage.HasOffsets, 'dovrebbe non avere offset');
  FImage.LeftOffset := 2;
  Assert.IsFalse(FImage.HasOffsets, 'dovrebbe non averli finche'' manca il secondo');
  FImage.TopOffset := 3;
  Assert.IsTrue(FImage.HasOffsets, 'dovrebbe averli');
  Assert.AreEqual(2, FImage.LeftOffset, 'dovrebbe dare quello impostato');
end;

procedure TTestTextureImage.DovrebbeLeggereUnaPaletteInBgr8ADaRecordDi3Byte;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetPaletteFromRecords(TBytes.Create(1, 2, 3, 4, 5, 6), 0, 2, 3, TTexturePaletteLayout.Bgr8);
  Assert.AreEqual(Cardinal($030201), FImage.Palette[0], 'dovrebbe leggere B, G, R');
  Assert.AreEqual(Cardinal($060504), FImage.Palette[1], 'dovrebbe leggere la seconda voce');
  Assert.AreEqual(Cardinal(0), FImage.Palette[2], 'dovrebbe lasciare 0 le voci che il file non ha');
end;

procedure TTestTextureImage.DovrebbeDareLaPaletteWebSafeSenzaPalette;
begin
  Assert.AreEqual(Cardinal($0000FC), PCardinal(NativeUInt(FImage.PalettePointer) + 9 * 4)^, 'dovrebbe dare la palette web safe');
  Assert.AreEqual(Cardinal($FFFFFF), PCardinal(NativeUInt(FImage.TransformedPalettePointer) + 255 * 4)^,
    'dovrebbe dare la palette web safe anche per quella trasformata');
end;

procedure TTestTextureImage.DovrebbeIniziareLaPaletteTrasformataComeCopiaDellaPalette;
begin
  // regression: the old transformed palette was not filled until a color was added
  FillPalettedImage;
  Assert.AreEqual(Palette[77], PCardinal(NativeUInt(FImage.TransformedPalettePointer) + 77 * 4)^,
    'dovrebbe essere uguale alla palette');
end;

procedure TTestTextureImage.DovrebbeSommareIlColoreAllaPaletteTrasformata;
var
  LColors: array[0..0] of Cardinal;
begin
  FillPalettedImage;
  Assert.IsTrue(FImage.GetPalettedColumn32(0, 1, @LColors[0], $010203), 'dovrebbe riuscire con una palette');
  // the entry 10 is $030A0A, the color $010203: the channels add up to $0D, $0C and $04
  Assert.AreEqual(Cardinal($040C0D), LColors[0], 'dovrebbe sommare il colore al primo pixel');
  Assert.AreEqual(Palette[10], FImage.Palette[10], 'non dovrebbe cambiare la palette');
end;

procedure TTestTextureImage.DovrebbeRicostruireTutte256LeVociDellaPaletteTrasformata;
var
  LColors: array[0..0] of Cardinal;
begin
  // regression: the old copy to the transformed palette stopped at the entry 254
  FillPalettedImage;
  FImage.GetPalettedColumn32(0, 1, @LColors[0], $010203);
  FImage.GetPalettedColumn32(0, 1, @LColors[0], 0);
  Assert.AreEqual(Palette[255], PCardinal(NativeUInt(FImage.TransformedPalettePointer) + 255 * 4)^,
    'dovrebbe tornare uguale alla palette anche per l''ultima voce');
end;

procedure TTestTextureImage.DovrebbeLeggereLaRigaSenzaIlColoreAggiunto;
var
  LColors: array[0..0] of Cardinal;
begin
  // the old GetPalettedRow32 asked for the added color and read the plain palette: kept
  FillPalettedImage;
  Assert.IsTrue(FImage.GetPalettedRow32(0, 1, @LColors[0], $010203), 'dovrebbe riuscire con una palette');
  Assert.AreEqual(Palette[10], LColors[0], 'dovrebbe dare il colore della palette senza somma');
end;

procedure TTestTextureImage.DovrebbeRifiutareLeLetturePalettateSenzaPalette;
var
  LColors: array[0..3] of Cardinal;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(2);
  FImage.SetHeight(2);
  Assert.IsFalse(FImage.GetPalettedColumn32(0, 2, @LColors[0], 5), 'dovrebbe dare false per una colonna a 32 bit');
  Assert.IsFalse(FImage.GetPalettedRow32(0, 2, @LColors[0], 5), 'dovrebbe dare false per una riga a 32 bit');
end;

procedure TTestTextureImage.DovrebbeSvuotarsiTenendoIlFormato;
begin
  FillPalettedImage;
  FImage.Clear;
  Assert.AreEqual(0, FImage.Width, 'dovrebbe azzerare la larghezza');
  Assert.AreEqual<Integer>(0, Length(FImage.Pixels), 'dovrebbe liberare i pixel');
  Assert.IsFalse(FImage.HasPalette, 'dovrebbe liberare la palette');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe tenere il formato, come prima');
end;

end.
