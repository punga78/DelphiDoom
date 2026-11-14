{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Texture library - the images of the test PK3       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Pk3;

interface

uses
  System.SysUtils, System.IOUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf,
  DelphiDoom.Texture.Types, DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf,
  DelphiDoom.Tests.Texture.Fakes;

type
  /// <summary>
  ///   Decodes the image files of Tests\Data\Pk3\src (the same bytes that are in zpktest.pk3 and
  ///   in zpkhires.wad, see the README of the folder) with the decoders of the library, with no
  ///   engine: every file is 64x64 and the pixel (x, y) of the lossless ones is known, because the
  ///   generator (Make-Pk3.ps1) writes (32 + 3x, 32 + 3y, 32 + 3 (x xor y)) or an index of the palette
  /// </summary>
  [TestFixture]
  [Category('texture')]
  [Category('pk3')]
  TTestTexturePk3 = class(TObject)
  private
    FDataDir: string;
    FLog: TFakeLog;
    FLogInterface: ILog;
    FImage: TTextureImage;
    FFormats: ITextureFormats;
    function Load(const ARelative: string): TBytes;
    function PixelAt(AX, AY: Integer): Cardinal;
    function ExpectedRgb(AX, AY: Integer): Cardinal;
    function PatchIndex(AX, AY: Integer): Integer;
    function FlatIndex(AX, AY: Integer): Integer;
    function PcxIndex(AX, AY: Integer): Integer;
    function SwapRedBlue(AColor: Cardinal): Cardinal;
    procedure CheckLosslessImage(const AExtension, ARelative: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaBmpDelPk3;
    [Test]
    procedure DovrebbeLeggereLaTgaDelPk3;
    [Test]
    procedure DovrebbeLeggereLaPcxDelPk3ConLaPalette;
    [Test]
    procedure DovrebbeLeggereLaPatchDelPk3ConGliOffsetEIlBuco;
    [Test]
    procedure DovrebbeLeggereIlFlatDelPk3;
    [Test]
    procedure DovrebbeRiconoscereLeEstensioniDelleImmaginiDelPk3;
    [Test]
    procedure DovrebbeTrovareLeDimensioniDelPngNellIntestazione;
    [Test]
    procedure DovrebbeTrovareLeDimensioniDelJpegNelMarcatoreSof;
    [Test]
    procedure DovrebbeRiconoscereLIntestazioneDellaPcxEscludereLeAltre;
    [Test]
    procedure DovrebbeRiconoscereLaPatchELaLunghezzaDelFlat;
  end;

implementation

uses
  DelphiDoom.Texture.Decoder.Pcx, DelphiDoom.Texture.Decoder.Flat,
  DelphiDoom.Texture.PatchInspector, DelphiDoom.Texture.Factory, DelphiDoom.Tests.Texture.Samples;

const
  SIDE = 64;

{ TTestTexturePk3 }

procedure TTestTexturePk3.Setup;
begin
  FDataDir := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..\Tests\Data\Pk3\src'));
  FLog := TFakeLog.Create;
  FLogInterface := FLog;
  FImage := TTextureImage.Create;
  FFormats := TTextureFactory.CreateFormats(TFakes.Services(FLogInterface));
end;

procedure TTestTexturePk3.TearDown;
begin
  FFormats := nil;
  FImage.Free;
  FLogInterface := nil;
end;

function TTestTexturePk3.Load(const ARelative: string): TBytes;
begin
  Result := TFile.ReadAllBytes(TPath.Combine(FDataDir, ARelative));
end;

function TTestTexturePk3.PixelAt(AX, AY: Integer): Cardinal;
begin
  Result := PTextureColorArray(FImage.PixelsPointer)^[AY * SIDE + AX];
end;

function TTestTexturePk3.ExpectedRgb(AX, AY: Integer): Cardinal;
begin
  Result := (Cardinal(32 + 3 * AX) shl 16) or (Cardinal(32 + 3 * AY) shl 8) or Cardinal(32 + 3 * (AX xor AY));
end;

function TTestTexturePk3.PatchIndex(AX, AY: Integer): Integer;
begin
  Result := 1 + ((AX * 3 + AY * 5) mod 250);
end;

function TTestTexturePk3.FlatIndex(AX, AY: Integer): Integer;
begin
  Result := 1 + ((AX * 7 + AY * 11) mod 250);
end;

function TTestTexturePk3.PcxIndex(AX, AY: Integer): Integer;
begin
  Result := 1 + ((AX + AY * 4) mod 250);
end;

function TTestTexturePk3.SwapRedBlue(AColor: Cardinal): Cardinal;
begin
  Result := (AColor and $FF00FF00) or ((AColor and $FF) shl 16) or ((AColor shr 16) and $FF);
end;

procedure TTestTexturePk3.CheckLosslessImage(const AExtension, ARelative: string);
var
  LX, LY: Integer;
begin
  Assert.IsTrue(FFormats.Decode(AExtension, Load(ARelative), FImage), 'dovrebbe riuscire: ' + ARelative);
  Assert.AreEqual(SIDE, FImage.Width, 'larghezza di ' + ARelative);
  Assert.AreEqual(SIDE, FImage.Height, 'altezza di ' + ARelative);
  Assert.AreEqual(4, FImage.BytesPerPixel, '32 bit per pixel: ' + ARelative);
  for LY := 0 to SIDE - 1 do
    for LX := 0 to SIDE - 1 do
      if PixelAt(LX, LY) <> ExpectedRgb(LX, LY) then
        Assert.AreEqual(IntToHex(ExpectedRgb(LX, LY), 8), IntToHex(PixelAt(LX, LY), 8),
          Format('pixel (%d, %d) di %s', [LX, LY, ARelative]));
end;

procedure TTestTexturePk3.DovrebbeLeggereLaBmpDelPk3;
begin
  CheckLosslessImage('.BMP', 'textures\ZPKBMP.bmp');
  Assert.IsTrue(FImage.NeedsSwapRGB, 'la BMP lascia lo scambio di rosso e blu a chi usa l''immagine');
end;

procedure TTestTexturePk3.DovrebbeLeggereLaTgaDelPk3;
begin
  CheckLosslessImage('.TGA', 'textures\ZPKTGA.tga');
end;

procedure TTestTexturePk3.DovrebbeLeggereLaPcxDelPk3ConLaPalette;
var
  LX, LY, LIndex: Integer;
  LExpected: Cardinal;
begin
  Assert.IsTrue(FFormats.Decode('.PCX', Load('textures\ZPKPCX.pcx'), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(SIDE, FImage.Width, 'larghezza');
  Assert.AreEqual(SIDE, FImage.Height, 'altezza');
  // the palette of the generator: entry i is (i, 255 - i, i * 37 mod 256), as R, G, B
  for LY := 0 to SIDE - 1 do
    for LX := 0 to SIDE - 1 do
    begin
      LIndex := PcxIndex(LX, LY);
      LExpected := (Cardinal(LIndex) shl 16) or (Cardinal(255 - LIndex) shl 8) or Cardinal((LIndex * 37) mod 256);
      if PixelAt(LX, LY) <> LExpected then
        Assert.AreEqual(IntToHex(LExpected, 8), IntToHex(PixelAt(LX, LY), 8),
          Format('pixel (%d, %d)', [LX, LY]));
    end;
  Assert.AreEqual(0, FLog.Warnings.Count, 'non dovrebbe avvisare');
end;

procedure TTestTexturePk3.DovrebbeLeggereLaPatchDelPk3ConGliOffsetEIlBuco;
var
  LPalette: TTexturePixels;
  LX, LY: Integer;
  LExpected: Cardinal;
begin
  LPalette := TTextureSamples.GamePalette;
  Assert.IsTrue(FFormats.Decode('.PATCH', Load('textures\ZPKPAT.patch'), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(SIDE, FImage.Width, 'larghezza');
  Assert.AreEqual(SIDE, FImage.Height, 'altezza');
  Assert.AreEqual(32, FImage.LeftOffset, 'offset sinistro');
  Assert.AreEqual(60, FImage.TopOffset, 'offset in alto');
  for LY := 0 to SIDE - 1 do
    for LX := 0 to SIDE - 1 do
    begin
      if (LX < 8) and (LY < 8) then
        LExpected := 0
      else
        // like the flat, the patch decoder ends with SwapRGB (the engine order of the channels)
        LExpected := SwapRedBlue(LPalette[PatchIndex(LX, LY)] or $FF000000);
      if PixelAt(LX, LY) <> LExpected then
        Assert.AreEqual(IntToHex(LExpected, 8), IntToHex(PixelAt(LX, LY), 8),
          Format('pixel (%d, %d)', [LX, LY]));
    end;
end;

procedure TTestTexturePk3.DovrebbeLeggereIlFlatDelPk3;
var
  LPalette: TTexturePixels;
  LX, LY: Integer;
  LExpected: Cardinal;
begin
  LPalette := TTextureSamples.GamePalette;
  Assert.IsTrue(FFormats.Decode('.FLAT', Load('textures\ZPKFLT.flat'), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(SIDE, FImage.Width, 'larghezza');
  Assert.AreEqual(SIDE, FImage.Height, 'altezza');
  // the decoder gives the colors with red and blue exchanged
  for LY := 0 to SIDE - 1 do
    for LX := 0 to SIDE - 1 do
    begin
      LExpected := SwapRedBlue(LPalette[FlatIndex(LX, LY)] or $FF000000);
      if PixelAt(LX, LY) <> LExpected then
        Assert.AreEqual(IntToHex(LExpected, 8), IntToHex(PixelAt(LX, LY), 8),
          Format('pixel (%d, %d)', [LX, LY]));
    end;
end;

procedure TTestTexturePk3.DovrebbeRiconoscereLeEstensioniDelleImmaginiDelPk3;
var
  LExtension: string;
begin
  for LExtension in ['.PNG', '.JPG', '.JPEG', '.TGA', '.BMP', '.PCX', '.PATCH', '.FLAT'] do
    Assert.IsTrue(FFormats.IsKnownExtension(LExtension), 'dovrebbe conoscere ' + LExtension);
  // R_AddTextureFileName takes the extension with fext, which has the dot: .WAV is not an image
  Assert.IsFalse(FFormats.IsKnownExtension('PNG'), 'senza il punto non e'' un''estensione');
  Assert.IsFalse(FFormats.IsKnownExtension('.WAV'), '.WAV non e'' un''immagine');
  Assert.IsFalse(FFormats.IsKnownExtension('.KVX'), '.KVX non e'' un''immagine');
end;

procedure TTestTexturePk3.DovrebbeTrovareLeDimensioniDelPngNellIntestazione;
var
  LBytes: TBytes;
  LRelative: string;
begin
  // the PNG is decoded by Libs\Png (with its own tests): here only the header, which is what
  // the decoders of the engine start from
  for LRelative in ['textures\ZPKPNG.png', 'flats\ZPKFLAT.png'] do
  begin
    LBytes := Load(LRelative);
    Assert.IsTrue(Length(LBytes) > 33, 'file troppo corto: ' + LRelative);
    Assert.AreEqual(Integer($89), Integer(LBytes[0]), 'firma PNG di ' + LRelative);
    Assert.AreEqual('PNG', string(Chr(LBytes[1]) + Chr(LBytes[2]) + Chr(LBytes[3])), 'firma PNG di ' + LRelative);
    Assert.AreEqual('IHDR', string(Chr(LBytes[12]) + Chr(LBytes[13]) + Chr(LBytes[14]) + Chr(LBytes[15])), 'primo chunk');
    Assert.AreEqual(SIDE, (Integer(LBytes[18]) shl 8) or LBytes[19], 'larghezza di ' + LRelative);
    Assert.AreEqual(SIDE, (Integer(LBytes[22]) shl 8) or LBytes[23], 'altezza di ' + LRelative);
    Assert.AreEqual(8, Integer(LBytes[24]), 'profondita'' di ' + LRelative);
  end;
end;

procedure TTestTexturePk3.DovrebbeTrovareLeDimensioniDelJpegNelMarcatoreSof;
var
  LBytes: TBytes;
  LPosition: Integer;
begin
  // the JPEG is decoded by Libs\Jpeg (with its own tests): here SOI, JFIF and the baseline frame
  LBytes := Load('textures\ZPKJPG.jpg');
  Assert.AreEqual(Integer($FF), Integer(LBytes[0]), 'SOI');
  Assert.AreEqual(Integer($D8), Integer(LBytes[1]), 'SOI');
  Assert.AreEqual('JFIF', string(Chr(LBytes[6]) + Chr(LBytes[7]) + Chr(LBytes[8]) + Chr(LBytes[9])), 'JFIF come cerca w_pak');
  LPosition := 2;
  while (LPosition + 9 < Length(LBytes)) and not ((LBytes[LPosition] = $FF) and (LBytes[LPosition + 1] = $C0)) do
  begin
    Assert.AreEqual(Integer($FF), Integer(LBytes[LPosition]), 'dovrebbe essere un marcatore');
    Inc(LPosition, 2 + ((Integer(LBytes[LPosition + 2]) shl 8) or LBytes[LPosition + 3]));
  end;
  Assert.IsTrue(LPosition + 9 < Length(LBytes), 'dovrebbe avere un frame baseline (SOF0)');
  Assert.AreEqual(8, Integer(LBytes[LPosition + 4]), 'precisione');
  Assert.AreEqual(SIDE, (Integer(LBytes[LPosition + 5]) shl 8) or LBytes[LPosition + 6], 'altezza');
  Assert.AreEqual(SIDE, (Integer(LBytes[LPosition + 7]) shl 8) or LBytes[LPosition + 8], 'larghezza');
end;

procedure TTestTexturePk3.DovrebbeRiconoscereLIntestazioneDellaPcxEscludereLeAltre;
var
  LHeader: TBytes;
  LRelative: string;
begin
  LHeader := Load('textures\ZPKPCX.pcx');
  SetLength(LHeader, 128);
  Assert.IsTrue(TTexturePcxDecoder.IsValidHeader(LHeader), 'la PCX dovrebbe essere valida');
  for LRelative in ['textures\ZPKTGA.tga', 'textures\ZPKBMP.bmp', 'textures\ZPKPNG.png',
    'textures\ZPKJPG.jpg', 'textures\ZPKPAT.patch'] do
  begin
    LHeader := Load(LRelative);
    SetLength(LHeader, 128);
    Assert.IsFalse(TTexturePcxDecoder.IsValidHeader(LHeader), 'non dovrebbe prendere per PCX ' + LRelative);
  end;
end;

procedure TTestTexturePk3.DovrebbeRiconoscereLaPatchELaLunghezzaDelFlat;
var
  LPatch: TBytes;
begin
  LPatch := Load('textures\ZPKPAT.patch');
  Assert.IsTrue(TTexturePatchInspector.IsValid(LPatch, Length(LPatch)), 'la patch dovrebbe essere valida');
  Assert.IsTrue(TTextureFlatDecoder.IsFlatLength(Length(Load('textures\ZPKFLT.flat'))),
    'il flat ha una lunghezza da flat');
  // the patch is 4616 bytes long: not one of a flat, so w_pak does not take it for one
  Assert.IsFalse(TTextureFlatDecoder.IsFlatLength(Length(LPatch)), 'la patch non ha una lunghezza da flat');
end;

end.
