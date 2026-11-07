{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureMaterialDecoder                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.MaterialDecoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Decoder.Material, DelphiDoom.Tests.Texture.Samples,
  DelphiDoom.Tests.Texture.Fakes;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureMaterialDecoder = class(TObject)
  private
    FResolver: TFakeResolver;
    FResolverInterface: ITextureResolver;
    FDecoder: ITextureDecoder;
    FImage: TTextureImage;
    function Text(const ALines: string): TBytes;
    procedure AddTexture(const AName: string; AWidth, AHeight, ABytesPerPixel: Integer; ASeed: Cardinal);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDireLaPropriaEstensione;
    [Test]
    procedure DovrebbeCopiareLaTexturaCheIlMaterialNomina;
    [Test]
    procedure DovrebbeConvertireA32BitUnaTexturaConLaPalette;
    [Test]
    procedure DovrebbeUsareLaScalaDiGrigiDelleAlfaComeCanaleAlfa;
    [Test]
    procedure DovrebbeRifiutareUnMaterialSenzaTextura;
    [Test]
    procedure DovrebbeRifiutareUnaTexturaCheNonSiTrova;
    [Test]
    procedure DovrebbeRifiutareUnAlfaCheNonSiTrova;
    [Test]
    procedure DovrebbeLeggereLeRigheSeparateDaRitornoACapoEDaLineFeed;
    [Test]
    procedure DovrebbeDistinguereLeMaiuscoleNelNomeDellaChiave;
    [Test]
    procedure DovrebbeRifiutareUnResolverNil;
  end;

implementation

function TTestTextureMaterialDecoder.Text(const ALines: string): TBytes;
begin
  Result := TEncoding.ANSI.GetBytes(ALines);
end;

procedure TTestTextureMaterialDecoder.AddTexture(const AName: string; AWidth, AHeight,
  ABytesPerPixel: Integer; ASeed: Cardinal);
var
  LImage: TTextureImage;
begin
  LImage := TTextureImage.Create;
  TTextureSamples.FillImage(LImage, AWidth, AHeight, ABytesPerPixel, ASeed);
  FResolver.Add(AName, LImage);
end;

procedure TTestTextureMaterialDecoder.Setup;
begin
  FResolver := TFakeResolver.Create;
  FResolverInterface := FResolver;
  FDecoder := TTextureMaterialDecoder.Create(FResolver);
  FImage := TTextureImage.Create;
end;

procedure TTestTextureMaterialDecoder.TearDown;
begin
  FImage.Free;
  FDecoder := nil;
  FResolverInterface := nil;
end;

procedure TTestTextureMaterialDecoder.DovrebbeDireLaPropriaEstensione;
begin
  Assert.AreEqual('.MATERIAL', FDecoder.Extension, 'dovrebbe dire .MATERIAL');
end;

procedure TTestTextureMaterialDecoder.DovrebbeCopiareLaTexturaCheIlMaterialNomina;
var
  LBytes: TBytes;
begin
  LBytes := TTextureSamples.RandomBytes(1, 48);
  AddTexture('WALL', 4, 3, 4, 1);
  Assert.IsTrue(FDecoder.Decode(Text('texture=WALL'#13#10), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.Width, 'dovrebbe avere la larghezza della textura');
  Assert.AreEqual(3, FImage.Height, 'dovrebbe avere l''altezza della textura');
  Assert.AreEqual(PCardinal(@LBytes[20])^, PTextureColorArray(FImage.PixelsPointer)^[5],
    'dovrebbe avere i pixel della textura');
  Assert.IsFalse(FImage.ExternalAlphaPresent, 'dovrebbe non avere l''alfa esterno');
end;

procedure TTestTextureMaterialDecoder.DovrebbeConvertireA32BitUnaTexturaConLaPalette;
var
  LIndices: TBytes;
  LPalette: TTexturePixels;
begin
  // regression: the old code copied 4 bytes for each pixel out of an image of 1
  LIndices := TTextureSamples.RandomBytes(2, 8);
  LPalette := TTextureSamples.Palette(3);
  AddTexture('PAL', 4, 2, 1, 2);
  Assert.IsTrue(FDecoder.Decode(Text('texture=PAL'), FImage), 'dovrebbe riuscire');
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe dare 32 bit');
  Assert.AreEqual(8 * 4, Length(FImage.Pixels), 'dovrebbe avere 4 byte per pixel');
  Assert.AreEqual(LPalette[LIndices[0]], PCardinal(FImage.PixelsPointer)^, 'dovrebbe dare il colore della palette');
end;

procedure TTestTextureMaterialDecoder.DovrebbeUsareLaScalaDiGrigiDelleAlfaComeCanaleAlfa;
begin
  AddTexture('WALL', 2, 2, 4, 4);
  AddTexture('MASK', 2, 2, 4, 5);
  Assert.IsTrue(FDecoder.Decode(Text('texture=WALL'#13#10'alpha=MASK'#13#10), FImage), 'dovrebbe riuscire');
  Assert.IsTrue(FImage.ExternalAlphaPresent, 'dovrebbe ricordare l''alfa esterno');
  Assert.AreEqual(2, FResolver.Requests.Count, 'dovrebbe chiedere la textura e la maschera');
  Assert.AreEqual('WALL', FResolver.Requests[0], 'dovrebbe chiedere prima la textura');
  Assert.AreEqual('MASK', FResolver.Requests[1], 'dovrebbe chiedere poi la maschera');
end;

procedure TTestTextureMaterialDecoder.DovrebbeRifiutareUnMaterialSenzaTextura;
begin
  Assert.IsFalse(FDecoder.Decode(Text('alpha=MASK'), FImage), 'dovrebbe dare false senza "texture"');
  Assert.IsFalse(FDecoder.Decode(Text('texture='), FImage), 'dovrebbe dare false con un nome vuoto');
  Assert.IsFalse(FDecoder.Decode(nil, FImage), 'dovrebbe dare false per un file vuoto');
  Assert.AreEqual(0, FResolver.Requests.Count, 'non dovrebbe cercare nulla');
end;

procedure TTestTextureMaterialDecoder.DovrebbeRifiutareUnaTexturaCheNonSiTrova;
begin
  Assert.IsFalse(FDecoder.Decode(Text('texture=NOTHING'), FImage), 'dovrebbe dare false');
  Assert.AreEqual(1, FResolver.Requests.Count, 'dovrebbe aver cercato la textura');
end;

procedure TTestTextureMaterialDecoder.DovrebbeRifiutareUnAlfaCheNonSiTrova;
begin
  AddTexture('WALL', 2, 2, 4, 6);
  Assert.IsFalse(FDecoder.Decode(Text('texture=WALL'#10'alpha=NOTHING'), FImage), 'dovrebbe dare false');
end;

procedure TTestTextureMaterialDecoder.DovrebbeLeggereLeRigheSeparateDaRitornoACapoEDaLineFeed;
begin
  AddTexture('A', 2, 2, 4, 7);
  Assert.IsTrue(FDecoder.Decode(Text('other=1'#13'texture=A'#10), FImage), 'dovrebbe riuscire con #13 come separatore');
  Assert.IsTrue(FDecoder.Decode(Text('other=1'#10'texture=A'), FImage), 'dovrebbe riuscire con #10 come separatore');
end;

procedure TTestTextureMaterialDecoder.DovrebbeDistinguereLeMaiuscoleNelNomeDellaChiave;
begin
  AddTexture('A', 2, 2, 4, 8);
  Assert.IsFalse(FDecoder.Decode(Text('Texture=A'), FImage), 'dovrebbe distinguere "Texture" da "texture"');
end;

procedure TTestTextureMaterialDecoder.DovrebbeRifiutareUnResolverNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TTextureMaterialDecoder.Create(nil);
    end, EArgumentNilException, 'dovrebbe rifiutare un resolver nil');
end;

end.
