{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTexturePngTextureDecoder                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.PngTextureDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.PngBase, DelphiDoom.Texture.Decoder.PngTexture,
  DelphiDoom.Tests.Texture.Samples, DelphiDoom.Tests.Texture.Fakes, DelphiDoom.Tests.Texture.Golden;

type
  [TestFixture]
  [Category('texture')]
  TTestTexturePngTextureDecoder = class(TObject)
  private
    FLog: TFakeLog;
    FLogInterface: IInterface;
    FSettings: TFakePngSettings;
    FSettingsInterface: IInterface;
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
    function Decode(AIndex: Integer): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodice;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceSenzaIColoriComuni;
    [Test]
    procedure DovrebbeTenereGliIndiciEMettereZeroLeVociTrasparentiDellaPalette;
    [Test]
    procedure DovrebbeMettereZeroIPixelDelColoreDelFile;
    [Test]
    procedure DovrebbeMettereZeroIPixelDeiDueColoriDelleImpostazioni;
    [Test]
    procedure DovrebbeMettereZeroIColoriComuniSoloSeLeImpostazioniLoDicono;
    [Test]
    procedure DovrebbeTenereGliOffsetDelFile;
    [Test]
    procedure DovrebbeDareUnAvvisoEFalseSeIlFileNonSiLegge;
    [Test]
    procedure DovrebbeRiconoscereICaloriComuniDiUnaTrasparenza;
    [Test]
    procedure DovrebbeScambiareRossoEBlu;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzaNil;
  end;

implementation

procedure TTestTexturePngTextureDecoder.Setup;
begin
  FLog := TFakeLog.Create;
  FLogInterface := FLog;
  FSettings := TFakePngSettings.Create;
  FSettingsInterface := FSettings;
  FDecoder := TTexturePngTextureDecoder.Create('.PNG', TFakePngReader.Create, FSettings, FLog);
  FImage := TTextureImage.Create;
end;

procedure TTestTexturePngTextureDecoder.TearDown;
begin
  FImage.Free;
  FDecoder := nil;
  FSettingsInterface := nil;
  FLogInterface := nil;
end;

function TTestTexturePngTextureDecoder.Decode(AIndex: Integer): Boolean;
begin
  Result := FDecoder.Decode(TTextureSamples.PngToken(AIndex), FImage);
end;

procedure TTestTexturePngTextureDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.PNG', FDecoder.Extension, 'dovrebbe dire .PNG');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeDareGliStessiRisultatiDelVecchioCodice;
var
  LCases: TTextureSamplePngs;
  LCase: TTextureSamplePng;
  LImage: TTextureImage;
  LOk: Boolean;
begin
  FSettings.Color := $FF00FF;
  FSettings.Color2 := $FFFF;
  FSettings.AssumeCommon := True;
  LCases := TTextureSamples.PngCases;
  for LCase in LCases do
  begin
    LImage := TTextureImage.Create;
    try
      LOk := FDecoder.Decode(LCase.Token, LImage);
      TTextureGolden.Check('png.golden.txt', 'png-texture-' + LCase.Name + '|default',
        TTextureSamples.Describe(LOk, LImage, False, 256));
    finally
      LImage.Free;
    end;
  end;
end;

procedure TTestTexturePngTextureDecoder.DovrebbeDareGliStessiRisultatiDelVecchioCodiceSenzaIColoriComuni;
var
  LCases: TTextureSamplePngs;
  LCase: TTextureSamplePng;
  LImage: TTextureImage;
  LOk: Boolean;
begin
  FSettings.Color := $0A0B0C;
  FSettings.Color2 := $FF0000;
  FSettings.AssumeCommon := False;
  LCases := TTextureSamples.PngCases;
  for LCase in LCases do
  begin
    LImage := TTextureImage.Create;
    try
      LOk := FDecoder.Decode(LCase.Token, LImage);
      TTextureGolden.Check('png.golden.txt', 'png-texture-' + LCase.Name + '|plain',
        TTextureSamples.Describe(LOk, LImage, False, 256));
    finally
      LImage.Free;
    end;
  end;
end;

procedure TTestTexturePngTextureDecoder.DovrebbeTenereGliIndiciEMettereZeroLeVociTrasparentiDellaPalette;
begin
  // the case 0 has a palette: the entries of black, magenta, cyan and the near black go to 0
  Assert.IsTrue(Decode(0), 'dovrebbe riuscire');
  Assert.AreEqual(1, FImage.BytesPerPixel, 'dovrebbe tenere gli indici');
  Assert.AreEqual(Cardinal(0), FImage.Palette[1], 'dovrebbe mettere a zero il magenta del file');
  Assert.AreEqual(Cardinal(0), FImage.Palette[2], 'dovrebbe mettere a zero il ciano');
  Assert.IsTrue(FImage.Palette[6] <> 0, 'dovrebbe tenere gli altri colori');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeMettereZeroIPixelDelColoreDelFile;
var
  LPixels: PTextureColorArray;
begin
  // the case 9: RGB with the color $FF00FF in the tRNS chunk; no common colors. The pixel 1 is
  // magenta, the pixel 2 is another color with two bytes at $FF
  FSettings.AssumeCommon := False;
  FSettings.Color := $123456;
  FSettings.Color2 := $654321;
  Assert.IsTrue(Decode(9), 'dovrebbe riuscire');
  LPixels := PTextureColorArray(FImage.PixelsPointer);
  Assert.AreEqual(Cardinal(0), LPixels^[1], 'dovrebbe mettere a zero il pixel del colore del file');
  Assert.AreNotEqual(Cardinal(0), LPixels^[2], 'non dovrebbe toccare gli altri colori');
  Assert.AreEqual(Cardinal(0), FImage.TransparentColor, 'dovrebbe azzerare i colori trasparenti dopo averli usati');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeMettereZeroIPixelDeiDueColoriDelleImpostazioni;
var
  LIndex: Integer;
  LPixels: PTextureColorArray;
  LColored, LPlain: Integer;
begin
  // the case 8: RGB without a tRNS color; the first color of the settings is magenta (as COLORREF
  // $FF00FF: the same in both byte orders), the second one $FFFF is yellow
  FSettings.AssumeCommon := False;
  Assert.IsTrue(Decode(8), 'dovrebbe riuscire');
  LPixels := PTextureColorArray(FImage.PixelsPointer);
  LColored := 0;
  for LIndex := 0 to FImage.Width * FImage.Height - 1 do
    if LPixels^[LIndex] = 0 then
      Inc(LColored);
  FImage.Free;
  FImage := TTextureImage.Create;
  FSettings.Color := $123456;
  FSettings.Color2 := $654321;
  Assert.IsTrue(Decode(8), 'dovrebbe riuscire anche con altri colori');
  LPixels := PTextureColorArray(FImage.PixelsPointer);
  LPlain := 0;
  for LIndex := 0 to FImage.Width * FImage.Height - 1 do
    if LPixels^[LIndex] = 0 then
      Inc(LPlain);
  Assert.IsTrue(LColored > LPlain, 'dovrebbe azzerare piu'' pixel con i colori delle impostazioni che stanno nell''immagine');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeMettereZeroIColoriComuniSoloSeLeImpostazioniLoDicono;
var
  LIndex: Integer;
  LPixels: PTextureColorArray;
  LWith, LWithout: Integer;
begin
  FSettings.Color := $123456;
  FSettings.Color2 := $654321;
  FSettings.AssumeCommon := True;
  Assert.IsTrue(Decode(8), 'dovrebbe riuscire');
  LPixels := PTextureColorArray(FImage.PixelsPointer);
  LWith := 0;
  for LIndex := 0 to FImage.Width * FImage.Height - 1 do
    if LPixels^[LIndex] = 0 then
      Inc(LWith);
  FImage.Free;
  FImage := TTextureImage.Create;
  FSettings.AssumeCommon := False;
  Assert.IsTrue(Decode(8), 'dovrebbe riuscire anche senza i colori comuni');
  LPixels := PTextureColorArray(FImage.PixelsPointer);
  LWithout := 0;
  for LIndex := 0 to FImage.Width * FImage.Height - 1 do
    if LPixels^[LIndex] = 0 then
      Inc(LWithout);
  Assert.IsTrue(LWith > LWithout, 'dovrebbe azzerare piu'' pixel con i colori comuni');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeTenereGliOffsetDelFile;
begin
  // the case 1 has the offsets (1, 2)
  Assert.IsTrue(Decode(1), 'dovrebbe riuscire');
  Assert.AreEqual(1, FImage.LeftOffset, 'dovrebbe tenere l''offset a sinistra');
  Assert.AreEqual(2, FImage.TopOffset, 'dovrebbe tenere l''offset in alto');
  Assert.IsTrue(FImage.HasOffsets, 'dovrebbe avere gli offset');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeDareUnAvvisoEFalseSeIlFileNonSiLegge;
begin
  Assert.IsFalse(FDecoder.Decode(TBytes.Create(250, 0, 0, 0), FImage), 'dovrebbe dare false');
  Assert.AreEqual(1, FLog.Warnings.Count, 'dovrebbe dare un avviso');
  Assert.IsTrue(FLog.Warnings[0].StartsWith('TPNGTextureManager(): '), 'dovrebbe dire chi lo da');
  Assert.IsTrue(FLog.Warnings[0].Contains('not a PNG'), 'dovrebbe dire il motivo del lettore');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeRiconoscereICaloriComuniDiUnaTrasparenza;
begin
  Assert.IsTrue(TTexturePngDecoderBase.IsCommonTransparentColor($FF00FF), 'dovrebbe riconoscere il magenta');
  Assert.IsTrue(TTexturePngDecoderBase.IsCommonTransparentColor($00FFFF), 'dovrebbe riconoscere il ciano');
  Assert.IsTrue(TTexturePngDecoderBase.IsCommonTransparentColor($FFFF00), 'dovrebbe riconoscere il giallo');
  Assert.IsTrue(TTexturePngDecoderBase.IsCommonTransparentColor($FFFFFF), 'dovrebbe riconoscere il bianco');
  Assert.IsFalse(TTexturePngDecoderBase.IsCommonTransparentColor($000000), 'non dovrebbe riconoscere il nero');
  Assert.IsFalse(TTexturePngDecoderBase.IsCommonTransparentColor($FF0000), 'non dovrebbe riconoscere un colore primario');
  Assert.IsFalse(TTexturePngDecoderBase.IsCommonTransparentColor($FF0001), 'non dovrebbe riconoscere un colore quasi comune');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeScambiareRossoEBlu;
begin
  Assert.AreEqual(Cardinal($00332211), TTexturePngDecoderBase.SwapRedBlue($00112233), 'dovrebbe scambiare il primo e il terzo byte');
  Assert.AreEqual(Cardinal($00FF00FF), TTexturePngDecoderBase.SwapRedBlue($00FF00FF), 'dovrebbe lasciare il magenta');
end;

procedure TTestTexturePngTextureDecoder.DovrebbeRifiutareLeDipendenzaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTexturePngTextureDecoder.Create('.PNG', nil, TFakePngSettings.Create, TFakeLog.Create);
    end, EArgumentNilException, 'dovrebbe rifiutare un lettore nil');
  Assert.WillRaise(
    procedure
    begin
      TTexturePngTextureDecoder.Create('.PNG', TFakePngReader.Create, nil, TFakeLog.Create);
    end, EArgumentNilException, 'dovrebbe rifiutare le impostazioni nil');
  Assert.WillRaise(
    procedure
    begin
      TTexturePngTextureDecoder.Create('.PNG', TFakePngReader.Create, TFakePngSettings.Create, nil);
    end, EArgumentNilException, 'dovrebbe rifiutare un log nil');
end;

end.
