{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texture library - R_LoadImage of Doom 3 (TGA, BMP, }
{  PCX, JPG, power of two)                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Texture.IdImageLoader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Imaging.Rgba.Image,
  DelphiDoom.Texture.Intf, DelphiDoom.Texture.IdImage.Intf;

type
  /// <summary>A source that holds the files of a test (names as given, lower case)</summary>
  TFakeImageSource = class(TInterfacedObject, IIdImageSource)
  public
    Files: TDictionary<string, TBytes>;
    Reads: TList<string>;
    constructor Create;
    destructor Destroy; override;
    function ReadFile(const AName: string; out ABytes: TBytes; out ATimestamp: Int64): Boolean;
  end;

  TFakeJpegDecoder = class(TInterfacedObject, IIdImageJpegDecoder)
  public
    function Decode(const ABytes: TBytes; out AImage: TImagingRgbaImage): Boolean;
  end;

  TFakeJpegConverter = class(TInterfacedObject, ITextureJpegConverter)
  public
    function ToBitmap(const ASource: TBytes): TBytes;
  end;

  /// <summary>
  ///   R_LoadImage of Doom 3 on files built by hand (the C++ reads files through idFileSystem and Doom 3 data is
  ///   not in the repository: the expected pixels follow from the loops of Image_files.cpp)
  /// </summary>
  [TestFixture]
  [Category('IdImage')]
  TTestIdImageLoader = class
  strict private
    FSource: TFakeImageSource;
    FSourceIntf: IIdImageSource;
    FLoader: IIdImageLoader;
    function Load(const AName: string; AMakePowerOf2: Boolean; out AImage: TImagingRgbaImage): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLeggereUnTga32CapovoltoCome;
    [Test]
    procedure DovrebbeAggiungereLEstensioneTgaEMinuscolo;
    [Test]
    procedure DovrebbeProvareIlJpgSeIlTgaManca;
    [Test]
    procedure NonDovrebbeProvareIlJpgSeIlTgaCe;
    [Test]
    procedure DovrebbeDareFalsoPerUnFileMancanteEUnNomeCorto;
    [Test]
    procedure DovrebbeLeggereUnBmp24SenzaRiempimentoDiRiga;
    [Test]
    procedure DovrebbeLeggereUnBmp8ConLaPalette;
    [Test]
    procedure DovrebbeLeggereUnBmp32ConLAlfa;
    [Test]
    procedure DovrebbeRifiutareIBmpNonSupportati;
    [Test]
    procedure DovrebbeRifiutareUnBmpTroncato;
    [Test]
    procedure DovrebbeLeggereUnPcxAChiaviEPalette;
    [Test]
    procedure DovrebbeDareFalsoPerUnPcxSbagliato;
    [Test]
    procedure DovrebbeRidimensionareAUnaPotenzaDiDue;
    [Test]
    procedure DovrebbeArrotondareInBassoSeRichiesto;
    [Test]
    procedure NonDovrebbeRidimensionareSeNonServe;
    [Test]
    procedure DovrebbeDareSoloLOrarioDelFile;
    [Test]
    procedure DovrebbeIgnorareLeEstensioniSconosciute;
    [Test]
    procedure DovrebbeLeggereUnJpgConIlDecodificatoreIniettato;
    [Test]
    procedure SenzaDecodificatoreJpgDovrebbeDareFalso;
    [Test]
    procedure DovrebbeRifiutareUnaSorgenteNulla;
    [Test]
    procedure JpegViaBitmapDovrebbeLeggereLeRigheRiempiteDelBmp;
    [Test]
    procedure JpegViaBitmapDovrebbeDareFalsoSeIlConvertitoreRifiuta;
    [Test]
    procedure JpegViaBitmapDovrebbeRifiutareUnConvertitoreNullo;
  end;

implementation

uses
  DelphiDoom.Texture.Types, DelphiDoom.Texture.IdImage.Loader, DelphiDoom.Texture.IdImage.JpegViaBitmap;

procedure Put32(var ABuffer: TBytes; const AOffset: Integer; const AValue: Integer);
begin
  ABuffer[AOffset] := Byte(AValue);
  ABuffer[AOffset + 1] := Byte(AValue shr 8);
  ABuffer[AOffset + 2] := Byte(AValue shr 16);
  ABuffer[AOffset + 3] := Byte(AValue shr 24);
end;

/// <summary>A BMP: the header of 54 bytes, the palette of an 8 bit file and the pixel bytes</summary>
function MakeBmp(const AWidth, AHeight, ABits: Integer; const APalette, APixels: TBytes): TBytes;
var
  LPalette: Integer;
begin
  LPalette := 0;
  if ABits = 8 then
    LPalette := 1024;
  SetLength(Result, 54 + LPalette + Length(APixels));
  Result[0] := Ord('B');
  Result[1] := Ord('M');
  Put32(Result, 2, Length(Result));
  Put32(Result, 10, 54 + LPalette);
  Put32(Result, 14, 40);
  Put32(Result, 18, AWidth);
  Put32(Result, 22, AHeight);
  Result[26] := 1;
  Result[28] := Byte(ABits);
  if Length(APalette) > 0 then
    Move(APalette[0], Result[54], Length(APalette));
  if Length(APixels) > 0 then
    Move(APixels[0], Result[54 + LPalette], Length(APixels));
end;

/// <summary>An uncompressed TGA of 32 bit: the pixels in the order of the file, B G R A</summary>
function MakeTga(const AWidth, AHeight: Integer; const APixels: TBytes): TBytes;
begin
  SetLength(Result, 18 + Length(APixels));
  Result[2] := 2;
  Result[12] := Byte(AWidth);
  Result[13] := Byte(AWidth shr 8);
  Result[14] := Byte(AHeight);
  Result[15] := Byte(AHeight shr 8);
  Result[16] := 32;
  Move(APixels[0], Result[18], Length(APixels));
end;

function Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
  begin
    Result[LIndex] := AValues[LIndex];
  end;
end;

{ TFakeImageSource }

constructor TFakeImageSource.Create;
begin
  inherited Create;
  Files := TDictionary<string, TBytes>.Create;
  Reads := TList<string>.Create;
end;

destructor TFakeImageSource.Destroy;
begin
  Reads.Free;
  Files.Free;
  inherited Destroy;
end;

function TFakeImageSource.ReadFile(const AName: string; out ABytes: TBytes; out ATimestamp: Int64): Boolean;
begin
  Reads.Add(AName);
  Result := Files.TryGetValue(AName, ABytes);
  if Result then
    ATimestamp := 1000 + Length(ABytes)
  else
    ATimestamp := ID_IMAGE_NO_TIMESTAMP;
end;

{ TFakeJpegDecoder }

function TFakeJpegDecoder.Decode(const ABytes: TBytes; out AImage: TImagingRgbaImage): Boolean;
begin
  AImage := TImagingRgbaImage.Create(1, 1);
  AImage.Pixels[0] := ABytes[0];
  AImage.Pixels[3] := 255;
  Result := True;
end;

{ TFakeJpegConverter }

function TFakeJpegConverter.ToBitmap(const ASource: TBytes): TBytes;
begin
  if Length(ASource) = 0 then
    raise ETextureException.Create('bad jpeg');
  // 1 x 2 pixels of 24 bit, the rows padded to four bytes: bottom row first (R=1 G=2 B=3), then the top row (4 5 6)
  Result := MakeBmp(1, 2, 24, nil, Bytes([3, 2, 1, 0, 6, 5, 4, 0]));
end;

{ TTestIdImageLoader }

procedure TTestIdImageLoader.Setup;
begin
  FSource := TFakeImageSource.Create;
  FSourceIntf := FSource;
  FLoader := TIdImageLoader.Create(FSourceIntf, TFakeJpegDecoder.Create);
end;

procedure TTestIdImageLoader.TearDown;
begin
  FLoader := nil;
  FSourceIntf := nil;
  FSource := nil;
end;

function TTestIdImageLoader.Load(const AName: string; AMakePowerOf2: Boolean; out AImage: TImagingRgbaImage): Boolean;
var
  LTimestamp: Int64;
begin
  Result := FLoader.Load(AName, AMakePowerOf2, AImage, LTimestamp);
end;

procedure TTestIdImageLoader.DovrebbeLeggereUnTga32CapovoltoCome;
var
  LImage: TImagingRgbaImage;
begin
  // two rows in the file: the bottom one first (blue, then red), the top one (green)
  FSource.Files.Add('textures/a.tga', MakeTga(1, 2, Bytes([255, 0, 0, 255, 0, 255, 0, 128])));
  Assert.IsTrue(Load('textures/a.tga', False, LImage));
  Assert.AreEqual(1, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  // the top row is the last of the file: green with alpha 128; the bottom row is blue
  Assert.AreEqual<Integer>(0, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(128, LImage.Pixels[3]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[6]);
end;

procedure TTestIdImageLoader.DovrebbeAggiungereLEstensioneTgaEMinuscolo;
var
  LImage: TImagingRgbaImage;
begin
  FSource.Files.Add('textures/b.tga', MakeTga(1, 1, Bytes([1, 2, 3, 4])));
  Assert.IsTrue(Load('Textures/B', False, LImage));
  Assert.AreEqual('textures/b.tga', FSource.Reads[0]);
  // B G R A in the file, R G B A in the image
  Assert.AreEqual<Integer>(3, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(1, LImage.Pixels[2]);
end;

procedure TTestIdImageLoader.DovrebbeProvareIlJpgSeIlTgaManca;
var
  LImage: TImagingRgbaImage;
begin
  FSource.Files.Add('textures/c.jpg', Bytes([77]));
  Assert.IsTrue(Load('textures/c.tga', False, LImage));
  Assert.AreEqual<Integer>(2, FSource.Reads.Count);
  Assert.AreEqual('textures/c.tga', FSource.Reads[0]);
  Assert.AreEqual('textures/c.jpg', FSource.Reads[1]);
  Assert.AreEqual<Integer>(77, LImage.Pixels[0]);
end;

procedure TTestIdImageLoader.NonDovrebbeProvareIlJpgSeIlTgaCe;
var
  LImage: TImagingRgbaImage;
begin
  FSource.Files.Add('textures/d.tga', MakeTga(1, 1, Bytes([1, 2, 3, 4])));
  FSource.Files.Add('textures/d.jpg', Bytes([77]));
  Assert.IsTrue(Load('textures/d.tga', False, LImage));
  Assert.AreEqual<Integer>(1, FSource.Reads.Count);
end;

procedure TTestIdImageLoader.DovrebbeDareFalsoPerUnFileMancanteEUnNomeCorto;
var
  LImage: TImagingRgbaImage;
  LTimestamp: Int64;
begin
  Assert.IsFalse(FLoader.Load('textures/none', False, LImage, LTimestamp));
  Assert.IsTrue(LImage.IsEmpty);
  Assert.AreEqual<Int64>(ID_IMAGE_NO_TIMESTAMP, LTimestamp);
  FSource.Reads.Clear;
  // ".tga" alone is under five characters: nothing is read
  Assert.IsFalse(FLoader.Load('', False, LImage, LTimestamp));
  Assert.AreEqual<Integer>(0, FSource.Reads.Count);
end;

procedure TTestIdImageLoader.DovrebbeLeggereUnBmp24SenzaRiempimentoDiRiga;
var
  LImage: TImagingRgbaImage;
begin
  // 2 x 2, 24 bit, 6 bytes per row with no padding (the original does not pad): the first row of the file is the
  // bottom one. Pixels B G R: row 0 = (1,2,3) (4,5,6); row 1 = (7,8,9) (10,11,12)
  FSource.Files.Add('gfx/e.bmp', MakeBmp(2, 2, 24, nil, Bytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])));
  Assert.IsTrue(Load('gfx/e.bmp', False, LImage));
  Assert.AreEqual(2, LImage.Width);
  // image row 1 (bottom) is file row 0: R = 3, G = 2, B = 1
  Assert.AreEqual<Integer>(3, LImage.Pixels[2 * 4]);
  Assert.AreEqual<Integer>(2, LImage.Pixels[2 * 4 + 1]);
  Assert.AreEqual<Integer>(1, LImage.Pixels[2 * 4 + 2]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[2 * 4 + 3]);
  // image row 0 is file row 1: first pixel R = 9
  Assert.AreEqual<Integer>(9, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(12, LImage.Pixels[4]);
end;

procedure TTestIdImageLoader.DovrebbeLeggereUnBmp8ConLaPalette;
var
  LImage: TImagingRgbaImage;
  LPalette: TBytes;
begin
  SetLength(LPalette, 1024);
  // colour 3: B 10, G 20, R 30
  LPalette[3 * 4] := 10;
  LPalette[3 * 4 + 1] := 20;
  LPalette[3 * 4 + 2] := 30;
  FSource.Files.Add('gfx/f.bmp', MakeBmp(1, 1, 8, LPalette, Bytes([3])));
  Assert.IsTrue(Load('gfx/f.bmp', False, LImage));
  Assert.AreEqual<Integer>(30, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(20, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(10, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[3]);
end;

procedure TTestIdImageLoader.DovrebbeLeggereUnBmp32ConLAlfa;
var
  LImage: TImagingRgbaImage;
begin
  FSource.Files.Add('gfx/g.bmp', MakeBmp(1, 1, 32, nil, Bytes([1, 2, 3, 99])));
  Assert.IsTrue(Load('gfx/g.bmp', False, LImage));
  Assert.AreEqual<Integer>(3, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(99, LImage.Pixels[3]);
end;

procedure TTestIdImageLoader.DovrebbeRifiutareIBmpNonSupportati;
var
  LImage: TImagingRgbaImage;
  LFile: TBytes;
begin
  LFile := MakeBmp(1, 1, 24, nil, Bytes([1, 2, 3]));
  // neither letter right
  LFile[0] := 0;
  LFile[1] := 0;
  FSource.Files.Add('gfx/h1.bmp', LFile);
  Assert.WillRaise(procedure begin Load('gfx/h1.bmp', False, LImage); end, ETextureException);
  // the check of the original is && : one right letter passes
  LFile := MakeBmp(1, 1, 24, nil, Bytes([1, 2, 3]));
  LFile[0] := 0;
  FSource.Files.Add('gfx/h2.bmp', LFile);
  Assert.IsTrue(Load('gfx/h2.bmp', False, LImage));
  // size of the header and of the file differ
  LFile := MakeBmp(1, 1, 24, nil, Bytes([1, 2, 3]));
  Put32(LFile, 2, 999);
  FSource.Files.Add('gfx/h3.bmp', LFile);
  Assert.WillRaise(procedure begin Load('gfx/h3.bmp', False, LImage); end, ETextureException);
  // compression
  LFile := MakeBmp(1, 1, 24, nil, Bytes([1, 2, 3]));
  Put32(LFile, 30, 1);
  FSource.Files.Add('gfx/h4.bmp', LFile);
  Assert.WillRaise(procedure begin Load('gfx/h4.bmp', False, LImage); end, ETextureException);
  // 4 bit and 16 bit
  FSource.Files.Add('gfx/h5.bmp', MakeBmp(1, 1, 4, nil, Bytes([1, 2, 3])));
  Assert.WillRaise(procedure begin Load('gfx/h5.bmp', False, LImage); end, ETextureException);
  FSource.Files.Add('gfx/h6.bmp', MakeBmp(1, 1, 16, nil, Bytes([1, 2])));
  Assert.WillRaise(procedure begin Load('gfx/h6.bmp', False, LImage); end, ETextureException);
  // 12 bit pixels: an illegal size
  FSource.Files.Add('gfx/h7.bmp', MakeBmp(1, 1, 12, nil, Bytes([1, 2])));
  Assert.WillRaise(procedure begin Load('gfx/h7.bmp', False, LImage); end, ETextureException);
end;

procedure TTestIdImageLoader.DovrebbeRifiutareUnBmpTroncato;
var
  LImage: TImagingRgbaImage;
  LFile: TBytes;
begin
  FSource.Files.Add('gfx/i1.bmp', Bytes([66, 77, 1, 2]));
  Assert.WillRaise(procedure begin Load('gfx/i1.bmp', False, LImage); end, ETextureException);
  // the header says 10 x 10 and the pixels are not there
  LFile := MakeBmp(10, 10, 24, nil, Bytes([1, 2, 3]));
  FSource.Files.Add('gfx/i2.bmp', LFile);
  Assert.WillRaise(procedure begin Load('gfx/i2.bmp', False, LImage); end, ETextureException);
  LFile := MakeBmp(0, 5, 24, nil, Bytes([1, 2, 3]));
  FSource.Files.Add('gfx/i3.bmp', LFile);
  Assert.WillRaise(procedure begin Load('gfx/i3.bmp', False, LImage); end, ETextureException);
end;

function MakePcx(const AXMax, AYMax: Integer; const AData: TBytes; const APalette: TBytes): TBytes;
begin
  SetLength(Result, 128 + Length(AData) + 768);
  Result[0] := $0A;
  Result[1] := 5;
  Result[2] := 1;
  Result[3] := 8;
  Result[8] := Byte(AXMax);
  Result[9] := Byte(AXMax shr 8);
  Result[10] := Byte(AYMax);
  Result[11] := Byte(AYMax shr 8);
  Move(AData[0], Result[128], Length(AData));
  Move(APalette[0], Result[128 + Length(AData)], Length(APalette));
end;

procedure TTestIdImageLoader.DovrebbeLeggereUnPcxAChiaviEPalette;
var
  LImage: TImagingRgbaImage;
  LPalette: TBytes;
begin
  SetLength(LPalette, 768);
  LPalette[5 * 3] := 50;
  LPalette[5 * 3 + 1] := 51;
  LPalette[5 * 3 + 2] := 52;
  LPalette[8 * 3] := 80;
  // 2 x 2: a run of two pixels of colour 5, then 7 and 8 as plain bytes
  FSource.Files.Add('pics/p.pcx', MakePcx(1, 1, Bytes([$C2, 5, 7, 8]), LPalette));
  Assert.IsTrue(Load('pics/p.pcx', False, LImage));
  Assert.AreEqual(2, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  Assert.AreEqual<Integer>(50, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(52, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(255, LImage.Pixels[3]);
  Assert.AreEqual<Integer>(50, LImage.Pixels[4]);
  Assert.AreEqual<Integer>(80, LImage.Pixels[12], 'colour 8');
end;

procedure TTestIdImageLoader.DovrebbeDareFalsoPerUnPcxSbagliato;
var
  LImage: TImagingRgbaImage;
  LFile: TBytes;
  LPalette: TBytes;
begin
  SetLength(LPalette, 768);
  // version 4
  LFile := MakePcx(1, 1, Bytes([1, 2, 3, 4]), LPalette);
  LFile[1] := 4;
  FSource.Files.Add('pics/q1.pcx', LFile);
  Assert.IsFalse(Load('pics/q1.pcx', False, LImage));
  // more than 1024 pixels wide
  FSource.Files.Add('pics/q2.pcx', MakePcx(1024, 1, Bytes([1, 2, 3, 4]), LPalette));
  Assert.IsFalse(Load('pics/q2.pcx', False, LImage));
  // the data ends before the pixels (the original would also read the palette as pixels: only a read past the file is malformed)
  FSource.Files.Add('pics/q3.pcx', MakePcx(900, 900, Bytes([1, 2]), LPalette));
  Assert.IsFalse(Load('pics/q3.pcx', False, LImage));
  // a short file
  FSource.Files.Add('pics/q4.pcx', Bytes([10, 5, 1, 8]));
  Assert.IsFalse(Load('pics/q4.pcx', False, LImage));
  // no room for the palette
  FSource.Files.Add('pics/q5.pcx', Copy(MakePcx(0, 0, Bytes([1]), LPalette), 0, 130));
  Assert.IsFalse(Load('pics/q5.pcx', False, LImage));
end;

procedure TTestIdImageLoader.DovrebbeRidimensionareAUnaPotenzaDiDue;
var
  LImage: TImagingRgbaImage;
  LPixels: TBytes;
  LIndex: Integer;
begin
  SetLength(LPixels, 3 * 3 * 4);
  for LIndex := 0 to High(LPixels) do
  begin
    LPixels[LIndex] := 100;
  end;
  FSource.Files.Add('gfx/r.tga', MakeTga(3, 3, LPixels));
  Assert.IsTrue(Load('gfx/r.tga', True, LImage));
  Assert.AreEqual(4, LImage.Width);
  Assert.AreEqual(4, LImage.Height);
  // a flat image stays flat
  Assert.AreEqual<Integer>(100, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(100, LImage.Pixels[LImage.Width * LImage.Height * 4 - 1]);
end;

procedure TTestIdImageLoader.DovrebbeArrotondareInBassoSeRichiesto;
var
  LImage: TImagingRgbaImage;
  LPixels: TBytes;
  LLoader: IIdImageLoader;
  LTimestamp: Int64;
begin
  SetLength(LPixels, 5 * 3 * 4);
  FSource.Files.Add('gfx/s.tga', MakeTga(5, 3, LPixels));
  LLoader := TIdImageLoader.Create(FSourceIntf, nil, True);
  Assert.IsTrue(LLoader.Load('gfx/s.tga', True, LImage, LTimestamp));
  Assert.AreEqual(4, LImage.Width, '5 goes down to 4');
  Assert.AreEqual(2, LImage.Height, '3 goes down to 2');
end;

procedure TTestIdImageLoader.NonDovrebbeRidimensionareSeNonServe;
var
  LImage: TImagingRgbaImage;
  LPixels: TBytes;
begin
  SetLength(LPixels, 4 * 2 * 4);
  FSource.Files.Add('gfx/t.tga', MakeTga(4, 2, LPixels));
  Assert.IsTrue(Load('gfx/t.tga', True, LImage));
  Assert.AreEqual(4, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
end;

procedure TTestIdImageLoader.DovrebbeDareSoloLOrarioDelFile;
begin
  FSource.Files.Add('gfx/u.tga', MakeTga(1, 1, Bytes([1, 2, 3, 4])));
  FSource.Files.Add('gfx/v.jpg', Bytes([1, 2, 3]));
  Assert.AreEqual<Int64>(1000 + 22, FLoader.Timestamp('gfx/u.tga'));
  Assert.AreEqual<Int64>(ID_IMAGE_NO_TIMESTAMP, FLoader.Timestamp('gfx/none.bmp'));
  // a missing tga: the time of the jpg
  Assert.AreEqual<Int64>(1000 + 3, FLoader.Timestamp('gfx/v.tga'));
  Assert.AreEqual<Int64>(ID_IMAGE_NO_TIMESTAMP, FLoader.Timestamp('gfx/w'));
  Assert.AreEqual<Int64>(ID_IMAGE_NO_TIMESTAMP, FLoader.Timestamp(''));
  Assert.AreEqual<Int64>(ID_IMAGE_NO_TIMESTAMP, FLoader.Timestamp('gfx/x.png'));
end;

procedure TTestIdImageLoader.DovrebbeIgnorareLeEstensioniSconosciute;
var
  LImage: TImagingRgbaImage;
begin
  FSource.Files.Add('gfx/y.png', Bytes([1, 2, 3, 4]));
  Assert.IsFalse(Load('gfx/y.png', False, LImage));
  Assert.AreEqual<Integer>(0, FSource.Reads.Count, 'the original does not even read it');
end;

procedure TTestIdImageLoader.DovrebbeLeggereUnJpgConIlDecodificatoreIniettato;
var
  LImage: TImagingRgbaImage;
begin
  FSource.Files.Add('gfx/z.jpg', Bytes([42]));
  Assert.IsTrue(Load('gfx/z.jpg', False, LImage));
  Assert.AreEqual<Integer>(42, LImage.Pixels[0]);
end;

procedure TTestIdImageLoader.SenzaDecodificatoreJpgDovrebbeDareFalso;
var
  LImage: TImagingRgbaImage;
  LLoader: IIdImageLoader;
  LTimestamp: Int64;
begin
  FSource.Files.Add('gfx/z.jpg', Bytes([42]));
  LLoader := TIdImageLoader.Create(FSourceIntf);
  Assert.IsFalse(LLoader.Load('gfx/z.jpg', False, LImage, LTimestamp));
end;

procedure TTestIdImageLoader.DovrebbeRifiutareUnaSorgenteNulla;
begin
  Assert.WillRaise(procedure begin TIdImageLoader.Create(nil); end, EArgumentNilException);
end;

procedure TTestIdImageLoader.JpegViaBitmapDovrebbeLeggereLeRigheRiempiteDelBmp;
var
  LDecoder: IIdImageJpegDecoder;
  LImage: TImagingRgbaImage;
begin
  LDecoder := TIdImageJpegViaBitmap.Create(TFakeJpegConverter.Create);
  Assert.IsTrue(LDecoder.Decode(Bytes([1]), LImage));
  Assert.AreEqual(1, LImage.Width);
  Assert.AreEqual(2, LImage.Height);
  // the top row of the image is the last row of the file: R=4 G=5 B=6
  Assert.AreEqual<Integer>(4, LImage.Pixels[0]);
  Assert.AreEqual<Integer>(5, LImage.Pixels[1]);
  Assert.AreEqual<Integer>(6, LImage.Pixels[2]);
  Assert.AreEqual<Integer>(1, LImage.Pixels[4]);
end;

procedure TTestIdImageLoader.JpegViaBitmapDovrebbeDareFalsoSeIlConvertitoreRifiuta;
var
  LDecoder: IIdImageJpegDecoder;
  LImage: TImagingRgbaImage;
begin
  LDecoder := TIdImageJpegViaBitmap.Create(TFakeJpegConverter.Create);
  Assert.IsFalse(LDecoder.Decode(nil, LImage));
  Assert.IsTrue(LImage.IsEmpty);
end;

procedure TTestIdImageLoader.JpegViaBitmapDovrebbeRifiutareUnConvertitoreNullo;
begin
  Assert.WillRaise(procedure begin TIdImageJpegViaBitmap.Create(nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestIdImageLoader);

end.