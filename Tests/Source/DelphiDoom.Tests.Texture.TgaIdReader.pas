{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TTgaIdReader                                           }
{  Tests\Data\IdImages\tga\*.tga were made by a harness and read by the real   }
{  LoadTGA of Doom 3 (golden file); the others are worked out by hand.         }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.TgaIdReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Texture.Types, DelphiDoom.Texture.Tga.IdReader,
  DelphiDoom.Imaging.Rgba.Image, DelphiDoom.Tests.IdImages.Golden;

type
  [TestFixture]
  [Category('IdImages')]
  TTestTgaIdReader = class
  strict private
    class function Header(const AType, ABits, AAttributes: Byte; const AWidth, AHeight: Word;
      const AIdLength: Byte = 0): TBytes; static;
    class function Join(const AFirst, ASecond: TBytes): TBytes; static;
    class procedure CheckFile(const AName: string); static;
    class procedure ExpectError(const AFile: TBytes); static;
  public
    [Test]
    procedure DovrebbeCoincidereConIlVeroLoadTgaSuITipo2;
    [Test]
    procedure DovrebbeCoincidereConIlVeroLoadTgaSuITipo3;
    [Test]
    procedure DovrebbeCoincidereConIlVeroLoadTgaSuITipo10;
    [Test]
    procedure DovrebbeCoincidereConIlVeroLoadTgaConLoSbordoDiUnaRun;
    [Test]
    procedure DovrebbeCoincidereConIlVeroLoadTgaConLIdentificativo;
    [Test]
    procedure DovrebbeDareErroreDoveIlVeroLoadTgaDaErrore;
    [Test]
    procedure DovrebbeLeggereLeRigheDalBassoVersoLAlto;
    [Test]
    procedure DovrebbeCapovolgereConLOrigineInAlto;
    [Test]
    procedure DovrebbeUsare255ComeAlfaDiUn24Bit;
    [Test]
    procedure DovrebbeRipeterePixelDiUnaRunChePassaALaRigaDopo;
    [Test]
    procedure DovrebbeDareErroreSuUnRleTroncato;
    [Test]
    procedure DovrebbeRifiutareLeDimensioniNonValide;
    [Test]
    procedure DovrebbeRifiutareUnFileCortoDellaIntestazione;
  end;

implementation

{ TTestTgaIdReader }

class function TTestTgaIdReader.Header(const AType, ABits, AAttributes: Byte; const AWidth,
  AHeight: Word; const AIdLength: Byte): TBytes;
begin
  SetLength(Result, 18);
  Result[0] := AIdLength;
  Result[2] := AType;
  Result[12] := Byte(AWidth);
  Result[13] := Byte(AWidth shr 8);
  Result[14] := Byte(AHeight);
  Result[15] := Byte(AHeight shr 8);
  Result[16] := ABits;
  Result[17] := AAttributes;
end;

class function TTestTgaIdReader.Join(const AFirst, ASecond: TBytes): TBytes;
begin
  SetLength(Result, Length(AFirst) + Length(ASecond));
  Move(AFirst[0], Result[0], Length(AFirst));
  if Length(ASecond) > 0 then
    Move(ASecond[0], Result[Length(AFirst)], Length(ASecond));
end;

class procedure TTestTgaIdReader.CheckFile(const AName: string);
begin
  TIdImagesGolden.Check('tga_' + AName,
    TTgaIdReader.Read(TIdImagesGolden.ReadFile('tga\' + AName + '.tga')));
end;

class procedure TTestTgaIdReader.ExpectError(const AFile: TBytes);
begin
  Assert.WillRaise(
    procedure
    begin
      TTgaIdReader.Read(AFile);
    end, ETextureException);
end;

procedure TTestTgaIdReader.DovrebbeCoincidereConIlVeroLoadTgaSuITipo2;
begin
  CheckFile('t2_24');
  CheckFile('t2_32_top');
end;

procedure TTestTgaIdReader.DovrebbeCoincidereConIlVeroLoadTgaSuITipo3;
begin
  CheckFile('t3_gray');
end;

procedure TTestTgaIdReader.DovrebbeCoincidereConIlVeroLoadTgaSuITipo10;
begin
  CheckFile('t10_24');
  CheckFile('t10_32_top');
end;

procedure TTestTgaIdReader.DovrebbeCoincidereConIlVeroLoadTgaConLoSbordoDiUnaRun;
begin
  // the packets have 3 pixels more than the image: the C++ stops at the last pixel
  CheckFile('t10_overrun');
end;

procedure TTestTgaIdReader.DovrebbeCoincidereConIlVeroLoadTgaConLIdentificativo;
begin
  CheckFile('t2_idlen');
end;

procedure TTestTgaIdReader.DovrebbeDareErroreDoveIlVeroLoadTgaDaErrore;
begin
  // type 1 (colour map), a file with too few pixels, 16 bits
  Assert.AreEqual('ERROR', TIdImagesGolden.Value('tga_t1_cmap'));
  ExpectError(TIdImagesGolden.ReadFile('tga\t1_cmap.tga'));
  Assert.AreEqual('ERROR', TIdImagesGolden.Value('tga_t2_trunc'));
  ExpectError(TIdImagesGolden.ReadFile('tga\t2_trunc.tga'));
  Assert.AreEqual('ERROR', TIdImagesGolden.Value('tga_t2_16'));
  ExpectError(TIdImagesGolden.ReadFile('tga\t2_16.tga'));
end;

procedure TTestTgaIdReader.DovrebbeLeggereLeRigheDalBassoVersoLAlto;
var
  LFile: TBytes;
  LImage: TImagingRgbaImage;
begin
  // 1 x 2, 24 bit: the first row in the file is the bottom one (B, G, R)
  LFile := Join(Header(2, 24, 0, 1, 2), TBytes.Create(1, 2, 3, 4, 5, 6));
  LImage := TTgaIdReader.Read(LFile);
  Assert.AreEqual<Integer>(6, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(5, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(4, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(3, LImage.Pixels[4]);
  Assert.AreEqual<Integer>(1, LImage.Pixels[6]);
end;

procedure TTestTgaIdReader.DovrebbeCapovolgereConLOrigineInAlto;
var
  LFile: TBytes;
  LImage: TImagingRgbaImage;
begin
  LFile := Join(Header(2, 24, $20, 1, 2), TBytes.Create(1, 2, 3, 4, 5, 6));
  LImage := TTgaIdReader.Read(LFile);
  Assert.AreEqual<Integer>(3, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(6, LImage.Pixels[4]);
end;

procedure TTestTgaIdReader.DovrebbeUsare255ComeAlfaDiUn24Bit;
var
  LImage: TImagingRgbaImage;
begin
  LImage := TTgaIdReader.Read(Join(Header(2, 24, 0, 1, 1), TBytes.Create(1, 2, 3)));
  Assert.AreEqual<Integer>(255, LImage.Pixels[3]);
  LImage := TTgaIdReader.Read(Join(Header(3, 8, 0, 1, 1), TBytes.Create(9)));
  Assert.AreEqual<Integer>(9, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(9, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[3]);
end;

procedure TTestTgaIdReader.DovrebbeRipeterePixelDiUnaRunChePassaALaRigaDopo;
var
  LImage: TImagingRgbaImage;
begin
  // 2 x 2 RLE 24 bit: one run packet of 3 pixels (B, G, R = 1, 2, 3) and a raw pixel
  LImage := TTgaIdReader.Read(Join(Header(10, 24, 0, 2, 2),
    TBytes.Create($82, 1, 2, 3, $00, 7, 8, 9)));
  // the file starts at the bottom row: its pixels 0 and 1, then the top row pixel 0 and 1
  Assert.AreEqual<Integer>(3, LImage.Pixels[(1 * 2 + 0) * 4]);
  Assert.AreEqual<Integer>(3, LImage.Pixels[(1 * 2 + 1) * 4]);
  Assert.AreEqual<Integer>(3, LImage.Pixels[(0 * 2 + 0) * 4]);
  Assert.AreEqual<Integer>(9, LImage.Pixels[(0 * 2 + 1) * 4]);
  Assert.AreEqual<Integer>(7, LImage.Pixels[(0 * 2 + 1) * 4 + 2]);
end;

procedure TTestTgaIdReader.DovrebbeDareErroreSuUnRleTroncato;
begin
  ExpectError(Join(Header(10, 24, 0, 2, 2), TBytes.Create($82, 1, 2, 3)));
end;

procedure TTestTgaIdReader.DovrebbeRifiutareLeDimensioniNonValide;
begin
  ExpectError(Join(Header(2, 24, 0, 0, 2), nil));
  ExpectError(Join(Header(10, 24, 0, 20000, 2), nil));
end;

procedure TTestTgaIdReader.DovrebbeRifiutareUnFileCortoDellaIntestazione;
begin
  ExpectError(TBytes.Create(0, 0, 2));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTgaIdReader);

end.
