{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureFactory                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Factory, DelphiDoom.Tests.Texture.Samples,
  DelphiDoom.Tests.Texture.Fakes;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureFactory = class(TObject)
  private
    FFormats: ITextureFormats;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeCreareIDecoderNellOrdineDelVecchioT_Init;
    [Test]
    procedure DovrebbeDecodificareUnaBitmapConLEstensioneBmp;
    [Test]
    procedure DovrebbeDecodificareUnFlatConLEstensioneFlat;
    [Test]
    procedure DovrebbeRifiutareLeDipendenzeNil;
  end;

implementation

procedure TTestTextureFactory.Setup;
begin
  FFormats := TTextureFactory.CreateFormats(TFakes.Services(TFakeLog.Create));
end;

procedure TTestTextureFactory.DovrebbeCreareIDecoderNellOrdineDelVecchioT_Init;
var
  LExtensions: TArray<string>;
  LExpected: TArray<string>;
  LIndex: Integer;
begin
  LExpected := TArray<string>.Create('.PNG', '.PNGSPRITE', '.JPG', '.JPEG', '.PCX', '.TGA', '.BMP',
    '.MATERIAL', '.PATCH', '.FLAT');
  LExtensions := FFormats.Extensions;
  Assert.AreEqual(Length(LExpected), Length(LExtensions), 'dovrebbe avere 10 decoder');
  for LIndex := 0 to High(LExpected) do
    Assert.AreEqual(LExpected[LIndex], LExtensions[LIndex], 'dovrebbe avere ' + LExpected[LIndex] + ' al suo posto');
end;

procedure TTestTextureFactory.DovrebbeDecodificareUnaBitmapConLEstensioneBmp;
var
  LImage: TTextureImage;
begin
  LImage := TTextureImage.Create;
  try
    Assert.IsTrue(FFormats.Decode('.BMP', TTextureSamples.Bmp(1, 1, 24, 0, nil, TBytes.Create(1, 2, 3, 0)), LImage),
      'dovrebbe riuscire');
    Assert.AreEqual(Cardinal($00030201), PCardinal(LImage.PixelsPointer)^, 'dovrebbe dare il pixel');
  finally
    LImage.Free;
  end;
end;

procedure TTestTextureFactory.DovrebbeDecodificareUnFlatConLEstensioneFlat;
var
  LImage: TTextureImage;
begin
  LImage := TTextureImage.Create;
  try
    Assert.IsTrue(FFormats.Decode('.FLAT', TTextureSamples.RandomBytes(1, 4096), LImage), 'dovrebbe riuscire');
    Assert.AreEqual(64, LImage.Width, 'dovrebbe avere 64 di larghezza');
  finally
    LImage.Free;
  end;
end;

procedure TTestTextureFactory.DovrebbeRifiutareLeDipendenzeNil;
var
  LServices: TTextureServices;
begin
  LServices := TFakes.Services(TFakeLog.Create);
  LServices.Log := nil;
  Assert.WillRaise(
    procedure
    begin
      TTextureFactory.CreateFormats(LServices);
    end, EArgumentNilException, 'dovrebbe rifiutare un log nil');
  LServices := TFakes.Services(TFakeLog.Create);
  LServices.Palette := nil;
  Assert.WillRaise(
    procedure
    begin
      TTextureFactory.CreateFormats(LServices);
    end, EArgumentNilException, 'dovrebbe rifiutare una palette nil');
  LServices := TFakes.Services(TFakeLog.Create);
  LServices.Resolver := nil;
  Assert.WillRaise(
    procedure
    begin
      TTextureFactory.CreateFormats(LServices);
    end, EArgumentNilException, 'dovrebbe rifiutare un resolver nil');
end;

end.
