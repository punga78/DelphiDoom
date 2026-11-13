{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TDdsReader                                             }
{  The headers are the ones that the real Doom 3 code builds (golden file).    }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.DdsReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Dds.Types, DelphiDoom.Texture.Dds.Reader,
  DelphiDoom.Imaging.Rgba.Image, DelphiDoom.Tests.IdImages.Golden;

type
  [TestFixture]
  [Category('IdImages')]
  TTestDdsReader = class
  strict private
    class function Combine(const AHeader, AData: TBytes): TBytes; static;
    class function FileWith(const AHeader: TDdsHeader; const AData: TBytes): TBytes; static;
    class function BaseHeader(const AWidth, AHeight: Cardinal): TDdsHeader; static;
    class procedure ExpectError(const AFile: TBytes); static;
  public
    [Test]
    procedure DovrebbeLeggereUnBgraConLIntestazioneDiDoom3;
    [Test]
    procedure DovrebbeLeggereLaCatenaDiUnDxt5DiDoom3;
    [Test]
    procedure DovrebbeLeggereUnDxt1SenzaAlfaConAlfa255;
    [Test]
    procedure DovrebbeLeggereUn24BitDiDoom3;
    [Test]
    procedure DovrebbeLeggereLaLuminanzaDiDoom3;
    [Test]
    procedure DovrebbeLeggereLaBandieraMonocromatica;
    [Test]
    procedure DovrebbeLeggereIMaschereDi16Bit;
    [Test]
    procedure DovrebbeLeggereUnSoloAlfaDi8Bit;
    [Test]
    procedure DovrebbeLimitareIlNumeroDiLivelliAllaCatena;
    [Test]
    procedure DovrebbeLeggereUnSoloLivelloSenzaLaBandieraDeiMipmap;
    [Test]
    procedure DovrebbeContareILivelli;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareLaFirmaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaIntestazioneConDimensioneSbagliata;
    [Test]
    procedure DovrebbeRifiutareLeDimensioniNonValide;
    [Test]
    procedure DovrebbeRifiutareIFormatiNonSupportati;
    [Test]
    procedure DovrebbeRifiutareUnLivelloTroncato;
  end;

implementation

uses
  DelphiDoom.Texture.Dds.BlockDecoder, DelphiDoom.Texture.Types;

{ TTestDdsReader }

class function TTestDdsReader.Combine(const AHeader, AData: TBytes): TBytes;
begin
  SetLength(Result, Length(AHeader) + Length(AData));
  Move(AHeader[0], Result[0], Length(AHeader));
  if Length(AData) > 0 then
    Move(AData[0], Result[Length(AHeader)], Length(AData));
end;

class function TTestDdsReader.BaseHeader(const AWidth, AHeight: Cardinal): TDdsHeader;
begin
  Result := Default(TDdsHeader);
  Result.Size := DDS_HEADER_SIZE;
  Result.Flags := DDSF_CAPS or DDSF_PIXELFORMAT or DDSF_WIDTH or DDSF_HEIGHT;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.PixelFormat.Size := DDS_PIXEL_FORMAT_SIZE;
  Result.Caps1 := DDSF_TEXTURE;
end;

class function TTestDdsReader.FileWith(const AHeader: TDdsHeader; const AData: TBytes): TBytes;
var
  LPrefix: TBytes;
  LMagic: Cardinal;
begin
  SetLength(LPrefix, DDS_FILE_PREFIX_SIZE);
  LMagic := DDS_MAGIC;
  Move(LMagic, LPrefix[0], 4);
  Move(AHeader, LPrefix[4], SizeOf(AHeader));
  Result := Combine(LPrefix, AData);
end;

class procedure TTestDdsReader.ExpectError(const AFile: TBytes);
begin
  Assert.WillRaise(
    procedure
    begin
      TDdsReader.Read(AFile);
    end, EDdsException);
end;

procedure TTestDdsReader.DovrebbeLeggereUnBgraConLIntestazioneDiDoom3;
var
  LData: TBytes;
  LImage: TDdsImage;
  LIndex: Integer;
begin
  SetLength(LData, 16 * 16 * 4);
  for LIndex := 0 to 255 do
  begin
    LData[LIndex * 4] := 1; // B
    LData[LIndex * 4 + 1] := 2; // G
    LData[LIndex * 4 + 2] := 3; // R
    LData[LIndex * 4 + 3] := 4; // A
  end;
  LImage := TDdsReader.Read(Combine(TIdImagesGolden.HeaderBytes('ddshead0'), LData));
  Assert.AreEqual<Integer>(Ord(TDdsFormat.Uncompressed), Ord(LImage.Format));
  Assert.IsTrue(LImage.HasAlpha);
  Assert.IsFalse(LImage.IsMonochrome);
  Assert.AreEqual(1, Length(LImage.Levels));
  Assert.AreEqual(16, LImage.Levels[0].Width);
  Assert.AreEqual<Integer>(3, LImage.Levels[0].Pixels[0]);
  Assert.AreEqual<Integer>(2, LImage.Levels[0].Pixels[1]);
  Assert.AreEqual<Integer>(1, LImage.Levels[0].Pixels[2]);
  Assert.AreEqual<Integer>(4, LImage.Levels[0].Pixels[3]);
end;

procedure TTestDdsReader.DovrebbeLeggereLaCatenaDiUnDxt5DiDoom3;
var
  LData: TBytes;
  LImage: TDdsImage;
  LWidth, LLevel, LTotal: Integer;
begin
  LTotal := 0;
  LWidth := 32;
  for LLevel := 0 to 5 do
  begin
    Inc(LTotal, TDdsBlockDecoder.SurfaceSize(TDdsFormat.Dxt5, LWidth, LWidth));
    LWidth := LWidth shr 1;
  end;
  SetLength(LData, LTotal);
  LImage := TDdsReader.Read(Combine(TIdImagesGolden.HeaderBytes('ddshead4'), LData));
  Assert.AreEqual<Integer>(Ord(TDdsFormat.Dxt5), Ord(LImage.Format));
  Assert.IsTrue(LImage.HasAlpha);
  Assert.AreEqual(6, Length(LImage.Levels));
  Assert.AreEqual(32, LImage.Levels[0].Width);
  Assert.AreEqual(1, LImage.Levels[5].Width);
  Assert.AreEqual(2, LImage.Levels[4].Height);
end;

procedure TTestDdsReader.DovrebbeLeggereUnDxt1SenzaAlfaConAlfa255;
var
  LData: TBytes;
  LImage: TDdsImage;
  LWidth, LHeight, LLevel, LTotal: Integer;
begin
  LTotal := 0;
  LWidth := 32;
  LHeight := 16;
  for LLevel := 0 to 5 do
  begin
    Inc(LTotal, TDdsBlockDecoder.SurfaceSize(TDdsFormat.Dxt1, LWidth, LHeight));
    LWidth := LWidth shr 1;
    LHeight := LHeight shr 1;
    if LHeight = 0 then
      LHeight := 1;
  end;
  SetLength(LData, LTotal);
  // the first block: c0 = c1 = 0 and every code 3 (a transparent texel for a DXT1 with alpha)
  LData[4] := $FF;
  LData[5] := $FF;
  LData[6] := $FF;
  LData[7] := $FF;
  LImage := TDdsReader.Read(Combine(TIdImagesGolden.HeaderBytes('ddshead5'), LData));
  Assert.AreEqual<Integer>(Ord(TDdsFormat.Dxt1), Ord(LImage.Format));
  Assert.IsFalse(LImage.HasAlpha);
  Assert.AreEqual(6, Length(LImage.Levels));
  Assert.AreEqual<Integer>(255, LImage.Levels[0].Pixels[3]);
end;

procedure TTestDdsReader.DovrebbeLeggereUn24BitDiDoom3;
var
  LData: TBytes;
  LImage: TDdsImage;
begin
  SetLength(LData, 8 * 8 * 3 + 4 * 4 * 3 + 2 * 2 * 3 + 3);
  LData[0] := 10; // B
  LData[1] := 20; // G
  LData[2] := 30; // R
  LImage := TDdsReader.Read(Combine(TIdImagesGolden.HeaderBytes('ddshead6'), LData));
  Assert.AreEqual(4, Length(LImage.Levels));
  Assert.IsFalse(LImage.HasAlpha);
  Assert.AreEqual<Integer>(30, LImage.Levels[0].Pixels[0]);
  Assert.AreEqual<Integer>(20, LImage.Levels[0].Pixels[1]);
  Assert.AreEqual<Integer>(10, LImage.Levels[0].Pixels[2]);
  Assert.AreEqual<Integer>(255, LImage.Levels[0].Pixels[3]);
end;

procedure TTestDdsReader.DovrebbeLeggereLaLuminanzaDiDoom3;
var
  LData: TBytes;
  LImage: TDdsImage;
begin
  SetLength(LData, 64);
  LData[0] := 77;
  LData[63] := 200;
  LImage := TDdsReader.Read(Combine(TIdImagesGolden.HeaderBytes('ddshead7'), LData));
  Assert.AreEqual<Integer>(77, LImage.Levels[0].Pixels[0]);
  Assert.AreEqual<Integer>(77, LImage.Levels[0].Pixels[1]);
  Assert.AreEqual<Integer>(77, LImage.Levels[0].Pixels[2]);
  Assert.AreEqual<Integer>(255, LImage.Levels[0].Pixels[3]);
  Assert.AreEqual<Integer>(200, LImage.Levels[0].Pixels[63 * 4]);
end;

procedure TTestDdsReader.DovrebbeLeggereLaBandieraMonocromatica;
var
  LImage: TDdsImage;
begin
  LImage := TDdsReader.Read(Combine(TIdImagesGolden.HeaderBytes('ddshead2'), TBytes.Create(1, 2, 3, 4)));
  Assert.IsTrue(LImage.IsMonochrome);
  Assert.AreEqual(1, Length(LImage.Levels));
end;

procedure TTestDdsReader.DovrebbeLeggereIMaschereDi16Bit;
var
  LHeader: TDdsHeader;
  LImage: TDdsImage;
begin
  LHeader := BaseHeader(2, 1);
  LHeader.PixelFormat.Flags := DDSF_RGB;
  LHeader.PixelFormat.RGBBitCount := 16;
  LHeader.PixelFormat.RBitMask := $F800;
  LHeader.PixelFormat.GBitMask := $07E0;
  LHeader.PixelFormat.BBitMask := $001F;
  // $F800 is red, $07E0 green
  LImage := TDdsReader.Read(FileWith(LHeader, TBytes.Create($00, $F8, $E0, $07)));
  Assert.AreEqual<Integer>(255, LImage.Levels[0].Pixels[0]);
  Assert.AreEqual<Integer>(0, LImage.Levels[0].Pixels[1]);
  Assert.AreEqual<Integer>(0, LImage.Levels[0].Pixels[4]);
  Assert.AreEqual<Integer>(255, LImage.Levels[0].Pixels[5]);
  Assert.AreEqual<Integer>(255, LImage.Levels[0].Pixels[7]);
  Assert.IsFalse(LImage.HasAlpha);
end;

procedure TTestDdsReader.DovrebbeLeggereUnSoloAlfaDi8Bit;
var
  LHeader: TDdsHeader;
  LImage: TDdsImage;
begin
  LHeader := BaseHeader(2, 1);
  LHeader.PixelFormat.Flags := DDSF_ALPHAPIXELS;
  LHeader.PixelFormat.RGBBitCount := 8;
  LHeader.PixelFormat.ABitMask := $FF000000;
  LImage := TDdsReader.Read(FileWith(LHeader, TBytes.Create(33, 200)));
  Assert.IsTrue(LImage.HasAlpha);
  Assert.AreEqual<Integer>(0, LImage.Levels[0].Pixels[0]);
  Assert.AreEqual<Integer>(33, LImage.Levels[0].Pixels[3]);
  Assert.AreEqual<Integer>(200, LImage.Levels[0].Pixels[7]);
end;

procedure TTestDdsReader.DovrebbeLimitareIlNumeroDiLivelliAllaCatena;
var
  LHeader: TDdsHeader;
  LImage: TDdsImage;
begin
  LHeader := BaseHeader(2, 2);
  LHeader.Flags := LHeader.Flags or DDSF_MIPMAPCOUNT;
  LHeader.MipMapCount := 12;
  LHeader.PixelFormat.Flags := DDSF_RGB or DDSF_ALPHAPIXELS;
  LHeader.PixelFormat.RGBBitCount := 32;
  LHeader.PixelFormat.RBitMask := $00FF0000;
  LHeader.PixelFormat.GBitMask := $0000FF00;
  LHeader.PixelFormat.BBitMask := $000000FF;
  LHeader.PixelFormat.ABitMask := $FF000000;
  LImage := TDdsReader.Read(FileWith(LHeader, TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0)));
  Assert.AreEqual(2, Length(LImage.Levels));
end;

procedure TTestDdsReader.DovrebbeLeggereUnSoloLivelloSenzaLaBandieraDeiMipmap;
var
  LHeader: TDdsHeader;
  LImage: TDdsImage;
begin
  LHeader := BaseHeader(2, 2);
  LHeader.MipMapCount := 5;
  LHeader.PixelFormat.Flags := DDSF_RGB;
  LHeader.PixelFormat.RGBBitCount := 32;
  LHeader.PixelFormat.RBitMask := $00FF0000;
  LHeader.PixelFormat.GBitMask := $0000FF00;
  LHeader.PixelFormat.BBitMask := $000000FF;
  LImage := TDdsReader.Read(FileWith(LHeader, TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0)));
  Assert.AreEqual(1, Length(LImage.Levels));
end;

procedure TTestDdsReader.DovrebbeContareILivelli;
begin
  Assert.AreEqual(1, TDdsReader.LevelCount(1, 1));
  Assert.AreEqual(3, TDdsReader.LevelCount(4, 4));
  Assert.AreEqual(6, TDdsReader.LevelCount(32, 16));
  Assert.AreEqual(5, TDdsReader.LevelCount(1, 16));
end;

procedure TTestDdsReader.DovrebbeRifiutareUnFileTroppoCorto;
begin
  ExpectError(nil);
  ExpectError(TBytes.Create(Ord('D'), Ord('D'), Ord('S'), Ord(' ')));
end;

procedure TTestDdsReader.DovrebbeRifiutareLaFirmaSbagliata;
var
  LFile: TBytes;
begin
  LFile := Combine(TIdImagesGolden.HeaderBytes('ddshead0'), TBytes.Create(1, 2, 3, 4));
  LFile[0] := Ord('X');
  ExpectError(LFile);
end;

procedure TTestDdsReader.DovrebbeRifiutareUnaIntestazioneConDimensioneSbagliata;
var
  LHeader: TDdsHeader;
begin
  LHeader := BaseHeader(1, 1);
  LHeader.Size := 100;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0)));
  LHeader := BaseHeader(1, 1);
  LHeader.PixelFormat.Size := 24;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0)));
end;

procedure TTestDdsReader.DovrebbeRifiutareLeDimensioniNonValide;
var
  LHeader: TDdsHeader;
begin
  LHeader := BaseHeader(0, 4);
  ExpectError(FileWith(LHeader, nil));
  LHeader := BaseHeader(4, TEXTURE_MAX_DIMENSION + 1);
  ExpectError(FileWith(LHeader, nil));
end;

procedure TTestDdsReader.DovrebbeRifiutareIFormatiNonSupportati;
var
  LHeader: TDdsHeader;
begin
  // DXT2 (premultiplied alpha)
  LHeader := BaseHeader(4, 4);
  LHeader.PixelFormat.Flags := DDSF_FOURCC;
  LHeader.PixelFormat.FourCC := $32545844;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)));
  // DX10 extended header
  LHeader.PixelFormat.FourCC := $30315844;
  ExpectError(FileWith(LHeader, nil));
  // a palettised image of Doom 3 (the file has no palette)
  LHeader := BaseHeader(1, 1);
  LHeader.PixelFormat.Flags := DDSF_RGB or DDSF_ID_INDEXCOLOR;
  LHeader.PixelFormat.RGBBitCount := 8;
  ExpectError(FileWith(LHeader, TBytes.Create(0)));
  // 12 bits per pixel
  LHeader := BaseHeader(1, 1);
  LHeader.PixelFormat.Flags := DDSF_RGB;
  LHeader.PixelFormat.RGBBitCount := 12;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0)));
  // no colour flags at all
  LHeader := BaseHeader(1, 1);
  LHeader.PixelFormat.RGBBitCount := 32;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0)));
  // cube map and volume
  LHeader := BaseHeader(1, 1);
  LHeader.PixelFormat.Flags := DDSF_RGB;
  LHeader.PixelFormat.RGBBitCount := 32;
  LHeader.Caps2 := $200;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0)));
  LHeader.Caps2 := 0;
  LHeader.Flags := LHeader.Flags or DDSF_DEPTH;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0)));
end;

procedure TTestDdsReader.DovrebbeRifiutareUnLivelloTroncato;
var
  LHeader: TDdsHeader;
begin
  LHeader := BaseHeader(4, 4);
  LHeader.PixelFormat.Flags := DDSF_RGB or DDSF_ALPHAPIXELS;
  LHeader.PixelFormat.RGBBitCount := 32;
  LHeader.PixelFormat.RBitMask := $00FF0000;
  ExpectError(FileWith(LHeader, TBytes.Create(1, 2, 3, 4)));
  // DXT1 with half a block missing
  LHeader := BaseHeader(4, 4);
  LHeader.PixelFormat.Flags := DDSF_FOURCC;
  LHeader.PixelFormat.FourCC := DDS_FOURCC_DXT1;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0)));
  // the second level is not there
  LHeader := BaseHeader(2, 2);
  LHeader.Flags := LHeader.Flags or DDSF_MIPMAPCOUNT;
  LHeader.MipMapCount := 2;
  LHeader.PixelFormat.Flags := DDSF_RGB;
  LHeader.PixelFormat.RGBBitCount := 32;
  ExpectError(FileWith(LHeader, TBytes.Create(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDdsReader);

end.
