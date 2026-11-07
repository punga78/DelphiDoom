{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Texture library - parity with the old code of      }
{  TEXLIB, on the golden files that the old code wrote                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.Parity;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.Factory, DelphiDoom.Tests.Texture.Samples,
  DelphiDoom.Tests.Texture.Golden, DelphiDoom.Tests.Texture.Operations,
  DelphiDoom.Tests.Texture.Fakes;

type
  [TestFixture]
  [Category('texture')]
  TTestTextureParity = class(TObject)
  private
    FFormats: ITextureFormats;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelVecchioCodiceInOgniOperazione;
    [Test]
    procedure DovrebbeLeggereLePaletteDiUnFileComeIlVecchioCodice;
    [Test]
    procedure DovrebbeScrivereIPixelNegliStessiFormatiDelVecchioCodice;
    [Test]
    procedure DovrebbeLeggereIFileBmpComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereIFileTgaComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereIFilePcxComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereIFlatComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereLePatchComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLeggereIFileDiDimensioneCasualeComeIlVecchioCodice;
    [Test]
    procedure DovrebbeTrovareIDecoderComeLaVecchiaListaDiFormati;
  end;

implementation

procedure TTestTextureParity.Setup;
begin
  FFormats := TTextureFactory.CreateFormats(TFakes.Services(TFakeLog.Create));
end;

procedure TTestTextureParity.DovrebbeDareGliStessiRisultatiDelVecchioCodiceInOgniOperazione;
var
  LCases: TArray<TTextureOperationCase>;
  LCase, LOperation: Integer;
  LImage: TTextureImage;
  LExtra: string;
begin
  LCases := TTextureOperations.Cases;
  for LCase := 0 to High(LCases) do
    for LOperation := 0 to TTextureOperations.COUNT - 1 do
    begin
      // the old conversion of the 16 bit pixels gave 0 (see TestTextureColors): not the same
      if LCases[LCase].BytesPerPixel = 2 then
        Continue;
      LImage := TTextureOperations.CreateImage(LCases[LCase], TTextureOperations.Seed(LCase));
      try
        LExtra := TTextureOperations.Apply(LOperation, LImage, LCases[LCase].Width, LCases[LCase].Height,
          TTextureOperations.Seed(LCase));
        TTextureGolden.Check('image.golden.txt', TTextureOperations.CaseName(LOperation, LCases[LCase]),
          TTextureOperations.Describe(LOperation, LImage, LExtra));
      finally
        LImage.Free;
      end;
    end;
end;

procedure TTestTextureParity.DovrebbeLeggereLePaletteDiUnFileComeIlVecchioCodice;
var
  LLayout, LSize, LCount, LCompare: Integer;
  LImage: TTextureImage;
  LBytes: TBytes;
  LCounts: TArray<Integer>;
begin
  LBytes := TTextureSamples.RandomBytes(900, 256 * 4 + 16);
  LCounts := TArray<Integer>.Create(1, 17, 200);
  for LLayout := 0 to 1 do
    for LSize := 2 to 4 do
      for LCount in LCounts do
      begin
        if (LLayout = 0) and (LSize = 2) then
          Continue;
        LCompare := LCount;
        // the last entry of a 15 or 16 bit map came from memory that the old code did not write
        if LLayout = 1 then
          LCompare := LCount - 1;
        LImage := TTextureImage.Create;
        try
          LImage.SetBytesPerPixel(1);
          LImage.SetWidth(2);
          LImage.SetHeight(2);
          if LLayout = 0 then
            LImage.SetPaletteFromRecords(LBytes, 0, LCount, LSize, TTexturePaletteLayout.Bgr8)
          else
            LImage.SetPaletteFromRecords(LBytes, 0, LCount, LSize, TTexturePaletteLayout.Bgr5);
          TTextureGolden.Check('image-colors.golden.txt',
            Format('palette-layout%d-record%d-count%d', [LLayout, LSize, LCount]),
            TTextureSamples.Describe(True, LImage, False, LCompare));
        finally
          LImage.Free;
        end;
      end;
end;

procedure TTestTextureParity.DovrebbeScrivereIPixelNegliStessiFormatiDelVecchioCodice;
var
  LFormat, LX, LY: Integer;
  LImage: TTextureImage;
  LFormats, LXs, LYs: TArray<Integer>;
begin
  LFormats := TArray<Integer>.Create(1, 4, 8, 24, 32);
  LXs := TArray<Integer>.Create(0, 3);
  LYs := TArray<Integer>.Create(0, 2);
  for LFormat in LFormats do
    for LX in LXs do
      for LY in LYs do
      begin
        LImage := TTextureImage.Create;
        try
          LImage.SetBytesPerPixel(4);
          LImage.SetWidth(12);
          LImage.SetHeight(5);
          LImage.SetPalette(TTextureSamples.Palette(960));
          LImage.PutPixels(LX, LY, 7, TTextureSamples.RandomBytes(950 + Cardinal(LFormat), 64), 0, LFormat);
          TTextureGolden.Check('image-colors.golden.txt',
            Format('putpixels-%dbit-x%d-y%d', [LFormat, LX, LY]),
            TTextureSamples.Describe(True, LImage, False, 256));
        finally
          LImage.Free;
        end;
      end;
end;

procedure TTestTextureParity.DovrebbeLeggereIFileBmpComeIlVecchioCodice;
begin
  TTextureGolden.CheckFiles(FFormats, 'bmp.golden.txt', TTextureSamples.BmpFiles);
end;

procedure TTestTextureParity.DovrebbeLeggereIFileTgaComeIlVecchioCodice;
begin
  TTextureGolden.CheckFiles(FFormats, 'tga.golden.txt', TTextureSamples.TgaFiles);
end;

procedure TTestTextureParity.DovrebbeLeggereIFilePcxComeIlVecchioCodice;
begin
  TTextureGolden.CheckFiles(FFormats, 'pcx.golden.txt', TTextureSamples.PcxFiles);
end;

procedure TTestTextureParity.DovrebbeLeggereIFlatComeIlVecchioCodice;
begin
  TTextureGolden.CheckFiles(FFormats, 'flat.golden.txt', TTextureSamples.FlatFiles);
end;

procedure TTestTextureParity.DovrebbeLeggereLePatchComeIlVecchioCodice;
begin
  TTextureGolden.CheckFiles(FFormats, 'patch.golden.txt', TTextureSamples.PatchFiles);
end;

procedure TTestTextureParity.DovrebbeLeggereIFileDiDimensioneCasualeComeIlVecchioCodice;
begin
  TTextureGolden.CheckFiles(FFormats, 'fuzz.golden.txt', TTextureSamples.FuzzFiles(150));
end;

procedure TTestTextureParity.DovrebbeTrovareIDecoderComeLaVecchiaListaDiFormati;
var
  LExtension: string;
  LDecoder: ITextureDecoder;
  LActual: string;
begin
  for LExtension in TArray<string>.Create('.PNG', '.PNGSPRITE', '.JPG', '.JPEG', '.PCX', '.TGA', '.BMP',
    '.MATERIAL', '.PATCH', '.FLAT', '.png', '.Bmp', '.JP', '.G', '.P', '.A', '.TX', '.XYZ', '.PNGS') do
  begin
    LDecoder := FFormats.FindDecoder(LExtension);
    if LDecoder = nil then
      LActual := '-'
    else
      LActual := LDecoder.Extension;
    TTextureGolden.Check('lookup.golden.txt', 'lookup-' + LExtension, LActual);
  end;
end;

end.
