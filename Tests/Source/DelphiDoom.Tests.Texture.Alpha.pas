{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTextureAlpha                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Alpha;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Alpha;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureAlpha = class(TObject)
  private
    FImage: TTextureImage;
    function Pixel(AIndex: Integer): Cardinal;
    procedure Fill(const AColors: array of Cardinal);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeImpostareLoStessoAlfaPerOgniPixel;
    [Test]
    procedure DovrebbeConvertireA32BitPrimaDiImpostareLAlfa;
    [Test]
    procedure DovrebbeMettereZeroIPixelDeiColoriTrasparentiEDarePienoAlfaAgliAltri;
    [Test]
    procedure DovrebbeUsareLeTreSogliePerIlCanaleAlfaPredefinito;
    [Test]
    procedure DovrebbeTogliereLaTrasparenzaDalNero;
    [Test]
    procedure DovrebbeAzzerareSoloIPixelDeiColoriTrasparentiSenzaDareAlfa;
    [Test]
    procedure DovrebbeNonFareNullaSeNonCiSonoColoriTrasparenti;
    [Test]
    procedure DovrebbeCalcolareLAlfaDallaScalaDiGrigiDiUnAltraImmagine;
  end;

implementation

function TTestTextureAlpha.Pixel(AIndex: Integer): Cardinal;
begin
  Result := PTextureColorArray(FImage.PixelsPointer)^[AIndex];
end;

procedure TTestTextureAlpha.Fill(const AColors: array of Cardinal);
var
  LIndex: Integer;
begin
  FImage.SetBytesPerPixel(4);
  FImage.SetWidth(Length(AColors));
  FImage.SetHeight(1);
  for LIndex := 0 to High(AColors) do
    PTextureColorArray(FImage.PixelsPointer)^[LIndex] := AColors[LIndex];
end;

procedure TTestTextureAlpha.Setup;
begin
  FImage := TTextureImage.Create;
end;

procedure TTestTextureAlpha.TearDown;
begin
  FImage.Free;
end;

procedure TTestTextureAlpha.DovrebbeImpostareLoStessoAlfaPerOgniPixel;
begin
  Fill([$00112233, $FF445566]);
  TTextureAlpha.SetChannel(FImage, $80);
  Assert.AreEqual(Cardinal($80112233), Pixel(0), 'dovrebbe cambiare l''alfa del primo pixel');
  Assert.AreEqual(Cardinal($80445566), Pixel(1), 'dovrebbe cambiare l''alfa del secondo');
end;

procedure TTestTextureAlpha.DovrebbeConvertireA32BitPrimaDiImpostareLAlfa;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(1);
  FImage.SetHeight(1);
  FImage.SetPalette(TTexturePixels.Create($0A0B0C));
  TTextureAlpha.SetChannel(FImage, $FF);
  Assert.AreEqual(4, FImage.BytesPerPixel, 'dovrebbe passare a 32 bit');
  Assert.AreEqual(Cardinal($FF0A0B0C), Pixel(0), 'dovrebbe avere il colore della palette e l''alfa');
end;

procedure TTestTextureAlpha.DovrebbeMettereZeroIPixelDeiColoriTrasparentiEDarePienoAlfaAgliAltri;
begin
  Fill([$00112233, $00445566]);
  FImage.TransparentColor := $00112233;
  FImage.TransparentColor2 := $00112233;
  FImage.TransparentColor3 := $00112233;
  TTextureAlpha.SetDefaultChannel(FImage);
  Assert.AreEqual(Cardinal(0), Pixel(0), 'dovrebbe azzerare il pixel trasparente');
  Assert.AreEqual(Cardinal($FF445566), Pixel(1), 'dovrebbe dare pieno alfa agli altri');
end;

procedure TTestTextureAlpha.DovrebbeUsareLeTreSogliePerIlCanaleAlfaPredefinito;
begin
  Fill([$00000001, $00000002, $00000003, $00000004]);
  FImage.TransparentColor := 1;
  FImage.TransparentColor2 := 2;
  FImage.TransparentColor3 := 3;
  TTextureAlpha.SetDefaultChannel(FImage);
  Assert.AreEqual(Cardinal(0), Pixel(0), 'dovrebbe azzerare il primo colore');
  Assert.AreEqual(Cardinal(0), Pixel(1), 'dovrebbe azzerare il secondo colore');
  Assert.AreEqual(Cardinal(0), Pixel(2), 'dovrebbe azzerare il terzo colore');
  Assert.AreEqual(Cardinal($FF000004), Pixel(3), 'dovrebbe dare pieno alfa agli altri');
end;

procedure TTestTextureAlpha.DovrebbeTogliereLaTrasparenzaDalNero;
begin
  Fill([$00000000, $00FFFFFF, $AA000000]);
  TTextureAlpha.RemoveTransparency(FImage);
  Assert.AreEqual(Cardinal($FF010101), Pixel(0), 'dovrebbe dare un quasi nero al nero');
  Assert.AreEqual(Cardinal($FFFFFFFF), Pixel(1), 'dovrebbe dare pieno alfa agli altri');
  Assert.AreEqual(Cardinal($FF010101), Pixel(2), 'dovrebbe dare un quasi nero anche al nero con alfa');
end;

procedure TTestTextureAlpha.DovrebbeAzzerareSoloIPixelDeiColoriTrasparentiSenzaDareAlfa;
begin
  Fill([$00112233, $00445566]);
  FImage.TransparentColor := $00445566;
  TTextureAlpha.AdjustTransparency(FImage);
  Assert.AreEqual(Cardinal($00112233), Pixel(0), 'non dovrebbe toccare gli altri');
  Assert.AreEqual(Cardinal(0), Pixel(1), 'dovrebbe azzerare il pixel trasparente');
end;

procedure TTestTextureAlpha.DovrebbeNonFareNullaSeNonCiSonoColoriTrasparenti;
begin
  FImage.SetBytesPerPixel(1);
  FImage.SetWidth(1);
  FImage.SetHeight(1);
  TTextureAlpha.AdjustTransparency(FImage);
  Assert.AreEqual(1, FImage.BytesPerPixel, 'non dovrebbe nemmeno convertire a 32 bit');
end;

procedure TTestTextureAlpha.DovrebbeCalcolareLAlfaDallaScalaDiGrigiDiUnAltraImmagine;
var
  LMask: TTextureImage;
begin
  Fill([$00112233, $00445566]);
  LMask := TTextureImage.Create;
  try
    LMask.SetBytesPerPixel(4);
    LMask.SetWidth(1);
    LMask.SetHeight(1);
    PCardinal(LMask.PixelsPointer)^ := $00303030;
    TTextureAlpha.SetChannelFromImage(FImage, LMask);
    Assert.AreEqual(Cardinal($30112233), Pixel(0), 'dovrebbe usare il grigio come alfa');
    Assert.AreEqual(Cardinal($30445566), Pixel(1), 'dovrebbe adattare la maschera alla dimensione');
    Assert.IsTrue(FImage.ExternalAlphaPresent, 'dovrebbe ricordare l''alfa esterno');
    Assert.AreEqual(2, LMask.Width, 'dovrebbe aver scalato la maschera');
    Assert.AreEqual(1, LMask.BytesPerPixel, 'dovrebbe aver portato la maschera in grigi');
  finally
    LMask.Free;
  end;
end;

end.
