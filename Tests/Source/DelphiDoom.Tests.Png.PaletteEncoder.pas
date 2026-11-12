{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the PNG library - TPngPaletteEncoder (indexed PNG)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Png.PaletteEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zlib.Intf, DelphiDoom.Zlib.Client, DelphiDoom.Png.Intf,
  DelphiDoom.Png.Client, DelphiDoom.Png.IndexedImage, DelphiDoom.Png.PaletteEncoder.Intf;

type
  [TestFixture]
  [Category('png')]
  TTestPngPaletteEncoder = class(TObject)
  strict private
    FZlib: IZlib;
    FZlibClient: TZlibClient;
    FClient: TPngClient;
    FEncoder: IPngPaletteEncoder;
    function Grays: TBytes;
    function Picture(AWidth, AHeight, AColors: Integer): TIndexedImage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereUnPngIndicizzatoAOttoBit;
    [Test]
    procedure DovrebbeRidareGliStessiIndiciELaStessaPalette;
    [Test]
    procedure DovrebbeRendereTrasparenteSoloLIndiceChiesto;
    [Test]
    procedure DovrebbeNonScrivereLaTrasparenzaSeNessunIndiceLoE;
    [Test]
    procedure DovrebbeRifiutareUnPixelSenzaColore;
    [Test]
    procedure DovrebbeRifiutareUnImmagineNonIntera;
    [Test]
    [TestCase('vuota', '0')]
    [TestCase('non multipla di tre', '7')]
    [TestCase('troppo lunga', '771')]
    procedure DovrebbeRifiutareUnaPalettaSbagliata(ABytes: Integer);
    [Test]
    procedure DovrebbeRifiutareUnCompressoreNil;
  end;

implementation

uses
  DelphiDoom.Zlib.Engine, DelphiDoom.Png.Engine, DelphiDoom.Png.PaletteEncoder;

procedure TTestPngPaletteEncoder.Setup;
begin
  FZlib := TZlibEngine.Create;
  FZlibClient := TZlibClient.Create(FZlib);
  FClient := TPngClient.Create(TPngEngine.Create(FZlib));
  FEncoder := TPngPaletteEncoder.Create(FZlibClient);
end;

procedure TTestPngPaletteEncoder.TearDown;
begin
  FEncoder := nil;
  FreeAndNil(FClient);
  FreeAndNil(FZlibClient);
  FZlib := nil;
end;

function TTestPngPaletteEncoder.Grays: TBytes;
begin
  // the palette of the pictures of the fonts of OpenXcom
  Result := TBytes.Create(0, 0, 0, 255, 255, 255, 207, 207, 207, 159, 159, 159, 111, 111, 111, 63, 63, 63);
end;

function TTestPngPaletteEncoder.Picture(AWidth, AHeight, AColors: Integer): TIndexedImage;
var
  LIndex: Integer;
begin
  Result := TIndexedImage.Create(AWidth, AHeight);
  for LIndex := 0 to High(Result.Pixels) do
    Result.Pixels[LIndex] := Byte(LIndex * 7 mod AColors);
end;

procedure TTestPngPaletteEncoder.DovrebbeScrivereUnPngIndicizzatoAOttoBit;
var
  LFile: TBytes;
begin
  LFile := FEncoder.Encode(Picture(5, 3, 6), Grays, 0);
  // the signature, then IHDR: width, height, depth 8, color type 3
  Assert.AreEqual($89, Integer(LFile[0]));
  Assert.AreEqual(Ord('P'), Integer(LFile[1]));
  Assert.AreEqual(Ord('I'), Integer(LFile[12]));
  Assert.AreEqual(5, Integer(LFile[19]));
  Assert.AreEqual(3, Integer(LFile[23]));
  Assert.AreEqual(8, Integer(LFile[24]));
  Assert.AreEqual(3, Integer(LFile[25]));
end;

procedure TTestPngPaletteEncoder.DovrebbeRidareGliStessiIndiciELaStessaPalette;
var
  LPicture: TIndexedImage;
  LRead: TPngIndexedImage;
  LIndex: Integer;
begin
  LPicture := Picture(17, 9, 6);
  LRead := FClient.DecodeIndexed(FEncoder.Encode(LPicture, Grays, 0));
  Assert.AreEqual(17, Integer(LRead.Info.Width));
  Assert.AreEqual(9, Integer(LRead.Info.Height));
  Assert.AreEqual(Integer(Length(LPicture.Pixels)), Integer(Length(LRead.Pixels)));
  for LIndex := 0 to High(LPicture.Pixels) do
    Assert.AreEqual(Integer(LPicture.Pixels[LIndex]), Integer(LRead.Pixels[LIndex]), Format('pixel %d', [LIndex]));
  // the palette of the client is B, G, R, A
  Assert.AreEqual(207, Integer(LRead.Palette[2 * 4]));
  Assert.AreEqual(63, Integer(LRead.Palette[5 * 4 + 2]));
end;

procedure TTestPngPaletteEncoder.DovrebbeRendereTrasparenteSoloLIndiceChiesto;
var
  LRead: TPngIndexedImage;
begin
  LRead := FClient.DecodeIndexed(FEncoder.Encode(Picture(4, 4, 6), Grays, 2));
  Assert.AreEqual(255, Integer(LRead.Palette[0 * 4 + 3]));
  Assert.AreEqual(255, Integer(LRead.Palette[1 * 4 + 3]));
  Assert.AreEqual(0, Integer(LRead.Palette[2 * 4 + 3]));
  Assert.AreEqual(255, Integer(LRead.Palette[3 * 4 + 3]));
end;

procedure TTestPngPaletteEncoder.DovrebbeNonScrivereLaTrasparenzaSeNessunIndiceLoE;
var
  LFile: TBytes;
  LText: AnsiString;
begin
  LFile := FEncoder.Encode(Picture(4, 4, 6), Grays);
  SetString(LText, PAnsiChar(@LFile[0]), Length(LFile));
  Assert.AreEqual(0, Pos(AnsiString('tRNS'), LText));
  Assert.IsTrue(Pos(AnsiString('PLTE'), LText) > 0);
  // an index that the palette does not have is no transparency either
  LFile := FEncoder.Encode(Picture(4, 4, 6), Grays, 6);
  SetString(LText, PAnsiChar(@LFile[0]), Length(LFile));
  Assert.AreEqual(0, Pos(AnsiString('tRNS'), LText));
end;

procedure TTestPngPaletteEncoder.DovrebbeRifiutareUnPixelSenzaColore;
var
  LPicture: TIndexedImage;
begin
  LPicture := Picture(4, 4, 6);
  // the palette has the colors 0 to 5
  LPicture.Pixels[9] := 6;
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(LPicture, Grays, 0);
    end, EPngPaletteEncoderException);
end;

procedure TTestPngPaletteEncoder.DovrebbeRifiutareUnImmagineNonIntera;
var
  LPicture: TIndexedImage;
begin
  LPicture := Picture(4, 4, 6);
  LPicture.Width := 5;
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(LPicture, Grays, 0);
    end, EPngPaletteEncoderException);
end;

procedure TTestPngPaletteEncoder.DovrebbeRifiutareUnaPalettaSbagliata(ABytes: Integer);
var
  LPalette: TBytes;
begin
  SetLength(LPalette, ABytes);
  Assert.WillRaise(
    procedure
    begin
      FEncoder.Encode(TIndexedImage.Create(2, 2), LPalette, 0);
    end, EPngPaletteEncoderException);
end;

procedure TTestPngPaletteEncoder.DovrebbeRifiutareUnCompressoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TPngPaletteEncoder.Create(nil);
    end, EArgumentNilException);
end;

end.
