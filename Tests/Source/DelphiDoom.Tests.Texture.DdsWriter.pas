{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TDdsWriter and TTextureDdsDecoder                      }
{  The headers and the file names are the ones of the real Doom 3 code.        }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.DdsWriter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Dds.Types, DelphiDoom.Texture.Dds.Writer,
  DelphiDoom.Imaging.Rgba.Image, DelphiDoom.Tests.IdImages.Golden;

type
  [TestFixture]
  [Category('IdImages')]
  TTestDdsWriter = class
  strict private
    class function Chain(const AWidth, AHeight, ALevels: Integer): TArray<TImagingRgbaImage>; static;
    class procedure CheckHeader(const AName: string; const AWidth, AHeight, ALevels: Integer;
      const AMonochrome: Boolean); static;
  public
    [Test]
    procedure DovrebbeScrivereLIntestazioneDiUnLivelloComeDoom3;
    [Test]
    procedure DovrebbeScrivereLIntestazioneConMipmapComeDoom3;
    [Test]
    procedure DovrebbeScrivereLaBandieraMonocromaticaComeDoom3;
    [Test]
    procedure DovrebbeScrivereUnaCatenaDiSetteLivelli;
    [Test]
    procedure DovrebbeScrivereIPixelInBgr;
    [Test]
    procedure DovrebbeRileggereCioCheScrive;
    [Test]
    procedure DovrebbeRifiutareUnaCatenaSbagliata;
    [Test]
    procedure DovrebbeRifiutareTroppiLivelli;
    [Test]
    procedure DovrebbeDareILNomeDiFileComprimatoComeDoom3;
    [Test]
    procedure DovrebbeUsareSpaziDopoIlQuartoLivelloDiCartelle;
  end;

  [TestFixture]
  [Category('IdImages')]
  TTestTextureDdsDecoder = class
  public
    [Test]
    procedure DovrebbeDareLEstensioneDds;
    [Test]
    procedure DovrebbeDecodificareIlPrimoLivelloIn32Bit;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileCheNonEUnDds;
  end;

implementation

uses
  DelphiDoom.Imaging.Rgba.Sampler, DelphiDoom.Texture.Dds.Reader, DelphiDoom.Texture.Decoder.Dds,
  DelphiDoom.Texture.Image, DelphiDoom.Texture.Intf;

{ TTestDdsWriter }

class function TTestDdsWriter.Chain(const AWidth, AHeight,
  ALevels: Integer): TArray<TImagingRgbaImage>;
var
  LIndex: Integer;
begin
  SetLength(Result, ALevels);
  Result[0] := TIdImagesGolden.Generate(AWidth, AHeight, 31, False);
  for LIndex := 1 to ALevels - 1 do
    if Result[LIndex - 1].Width + Result[LIndex - 1].Height > 2 then
      Result[LIndex] := TImagingRgbaSampler.MipMap(Result[LIndex - 1], False)
    else
      Result[LIndex] := TImagingRgbaImage.Create(1, 1);
end;

class procedure TTestDdsWriter.CheckHeader(const AName: string; const AWidth, AHeight,
  ALevels: Integer; const AMonochrome: Boolean);
var
  LFile, LExpected: TBytes;
begin
  LFile := TDdsWriter.WriteUncompressed(Chain(AWidth, AHeight, ALevels), AMonochrome);
  LExpected := TIdImagesGolden.HeaderBytes(AName);
  Assert.IsTrue(Length(LFile) >= Length(LExpected));
  Assert.IsTrue(CompareMem(@LFile[0], @LExpected[0], Length(LExpected)), AName);
end;

procedure TTestDdsWriter.DovrebbeScrivereLIntestazioneDiUnLivelloComeDoom3;
begin
  CheckHeader('ddshead0', 16, 16, 1, False);
end;

procedure TTestDdsWriter.DovrebbeScrivereLIntestazioneConMipmapComeDoom3;
begin
  CheckHeader('ddshead1', 16, 8, 5, False);
end;

procedure TTestDdsWriter.DovrebbeScrivereLaBandieraMonocromaticaComeDoom3;
begin
  CheckHeader('ddshead2', 1, 1, 1, True);
end;

procedure TTestDdsWriter.DovrebbeScrivereUnaCatenaDiSetteLivelli;
begin
  CheckHeader('ddshead3', 64, 64, 7, True);
end;

procedure TTestDdsWriter.DovrebbeScrivereIPixelInBgr;
var
  LImage: TImagingRgbaImage;
  LFile: TBytes;
begin
  LImage := TImagingRgbaImage.Create(1, 1);
  LImage.Pixels[0] := 10;
  LImage.Pixels[1] := 20;
  LImage.Pixels[2] := 30;
  LImage.Pixels[3] := 40;
  LFile := TDdsWriter.WriteUncompressed([LImage]);
  Assert.AreEqual(DDS_FILE_PREFIX_SIZE + 4, Length(LFile));
  Assert.AreEqual<Integer>(30, LFile[DDS_FILE_PREFIX_SIZE]);
  Assert.AreEqual<Integer>(20, LFile[DDS_FILE_PREFIX_SIZE + 1]);
  Assert.AreEqual<Integer>(10, LFile[DDS_FILE_PREFIX_SIZE + 2]);
  Assert.AreEqual<Integer>(40, LFile[DDS_FILE_PREFIX_SIZE + 3]);
end;

procedure TTestDdsWriter.DovrebbeRileggereCioCheScrive;
var
  LLevels: TArray<TImagingRgbaImage>;
  LImage: TDdsImage;
  LIndex: Integer;
begin
  LLevels := Chain(8, 4, 4);
  LImage := TDdsReader.Read(TDdsWriter.WriteUncompressed(LLevels, True));
  Assert.AreEqual(4, Length(LImage.Levels));
  Assert.IsTrue(LImage.IsMonochrome);
  Assert.IsTrue(LImage.HasAlpha);
  for LIndex := 0 to 3 do
    Assert.IsTrue(LImage.Levels[LIndex].SameAs(LLevels[LIndex]), 'level ' + IntToStr(LIndex));
end;

procedure TTestDdsWriter.DovrebbeRifiutareUnaCatenaSbagliata;
begin
  Assert.WillRaise(
    procedure
    begin
      TDdsWriter.WriteUncompressed(nil);
    end, EDdsException);
  Assert.WillRaise(
    procedure
    begin
      // the second level is not half the size
      TDdsWriter.WriteUncompressed([TImagingRgbaImage.Create(8, 8), TImagingRgbaImage.Create(2, 2)]);
    end, EDdsException);
end;

procedure TTestDdsWriter.DovrebbeRifiutareTroppiLivelli;
var
  LLevels: TArray<TImagingRgbaImage>;
  LIndex: Integer;
begin
  SetLength(LLevels, DDS_MAX_LEVELS + 1);
  for LIndex := 0 to High(LLevels) do
    LLevels[LIndex] := TImagingRgbaImage.Create(1, 1);
  Assert.WillRaise(
    procedure
    begin
      TDdsWriter.WriteUncompressed(LLevels);
    end, EDdsException);
end;

procedure TTestDdsWriter.DovrebbeDareILNomeDiFileComprimatoComeDoom3;
const
  PROGRAMS: array[0..4] of string = ('textures/base_wall/lfwall13f3',
    'addnormals( models/monsters/zombie/zombie_local, heightmap( models/monsters/zombie/zombie_h, 4 ) )',
    'a\b\c\d\e\f(g)<h>:i|j".k  l', 'x/ y', 'scale( a, 1, 2, 3, 4 )');
var
  LIndex: Integer;
begin
  for LIndex := 0 to 4 do
    Assert.AreEqual(TIdImagesGolden.Value('file' + IntToStr(LIndex)),
      TDdsWriter.CompressedFileName(PROGRAMS[LIndex]), PROGRAMS[LIndex]);
end;

procedure TTestDdsWriter.DovrebbeUsareSpaziDopoIlQuartoLivelloDiCartelle;
begin
  Assert.AreEqual('dds/a/b/c/d/e f.dds', TDdsWriter.CompressedFileName('a/b/c/d/e/f'));
end;

{ TTestTextureDdsDecoder }

procedure TTestTextureDdsDecoder.DovrebbeDareLEstensioneDds;
var
  LDecoder: ITextureDecoder;
begin
  LDecoder := TTextureDdsDecoder.Create;
  Assert.AreEqual('.DDS', LDecoder.Extension);
end;

procedure TTestTextureDdsDecoder.DovrebbeDecodificareIlPrimoLivelloIn32Bit;
var
  LImage: TTextureImage;
  LLevel: TImagingRgbaImage;
  LFile: TBytes;
  LBytes: PByte;
  LDecoder: ITextureDecoder;
begin
  LDecoder := TTextureDdsDecoder.Create;
  LLevel := TImagingRgbaImage.Create(2, 1);
  LLevel.Pixels[0] := 10;
  LLevel.Pixels[1] := 20;
  LLevel.Pixels[2] := 30;
  LLevel.Pixels[3] := 40;
  LLevel.Pixels[4] := 50;
  LLevel.Pixels[5] := 60;
  LLevel.Pixels[6] := 70;
  LLevel.Pixels[7] := 80;
  LFile := TDdsWriter.WriteUncompressed([LLevel]);
  LImage := TTextureImage.Create;
  try
    Assert.IsTrue(LDecoder.Decode(LFile, LImage));
    Assert.AreEqual(2, LImage.Width);
    Assert.AreEqual(1, LImage.Height);
    Assert.AreEqual(4, LImage.BytesPerPixel);
    LBytes := LImage.PixelsPointer;
    // B, G, R, A in memory
    Assert.AreEqual<Integer>(30, LBytes[0]);
    Assert.AreEqual<Integer>(20, LBytes[1]);
    Assert.AreEqual<Integer>(10, LBytes[2]);
    Assert.AreEqual<Integer>(40, LBytes[3]);
    Assert.AreEqual<Integer>(70, LBytes[4]);
  finally
    LImage.Free;
  end;
end;

procedure TTestTextureDdsDecoder.DovrebbeDareFalsoPerUnFileCheNonEUnDds;
var
  LImage: TTextureImage;
  LDecoder: ITextureDecoder;
begin
  LDecoder := TTextureDdsDecoder.Create;
  LImage := TTextureImage.Create;
  try
    Assert.IsFalse(LDecoder.Decode(TBytes.Create(1, 2, 3), LImage));
  finally
    LImage.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDdsWriter);
  TDUnitX.RegisterTestFixture(TTestTextureDdsDecoder);

end.
