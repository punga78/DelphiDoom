{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the PNG of an image                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.PngEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedPngEncoder = class(TObject)
  private
    FEncoder: IGreedImageEncoder;
    FPalette: TBytes;
    function Image(AWidth, AHeight: Integer; const APixels: array of Byte): TGreedImage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereUnFilePng;
    [Test]
    procedure DovrebbeDareIColoriDellaPalette;
    [Test]
    procedure DovrebbeTenereLeDimensioni;
    [Test]
    procedure DovrebbeDareAlfaZeroAlloZeroSeVuoleLaTrasparenza;
    [Test]
    procedure DovrebbeTenereOpachoLoZeroSenzaTrasparenza;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineConLaDimensioneSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnaPaletteCorta;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Greed.PngEncoder, DelphiDoom.Greed.Palette, DelphiDoom.Png.Intf, DelphiDoom.Png.Client,
  DelphiDoom.Png.Provider, DelphiDoom.Video.Factory, DelphiDoom.Tests.Greed.Builders;

{ TTestGreedPngEncoder }

procedure TTestGreedPngEncoder.Setup;
begin
  FEncoder := TGreedPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client);
  FPalette := TGreedPalette.FromLump(TGreedLumps.Palette);
end;

procedure TTestGreedPngEncoder.TearDown;
begin
  FEncoder := nil;
end;

function TTestGreedPngEncoder.Image(AWidth, AHeight: Integer; const APixels: array of Byte): TGreedImage;
var
  LIndex: Integer;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.OriginX := 0;
  Result.OriginY := 0;
  SetLength(Result.Pixels, Length(APixels));
  for LIndex := 0 to High(APixels) do
    Result.Pixels[LIndex] := APixels[LIndex];
end;

procedure TTestGreedPngEncoder.DovrebbeScrivereUnFilePng;
var
  LBytes: TBytes;
begin
  LBytes := FEncoder.Encode(Image(2, 1, [1, 2]), FPalette, False);
  Assert.IsTrue(Length(LBytes) > 8);
  Assert.AreEqual($89, Integer(LBytes[0]));
  Assert.AreEqual(Ord('P'), Integer(LBytes[1]));
  Assert.AreEqual(Ord('N'), Integer(LBytes[2]));
  Assert.AreEqual(Ord('G'), Integer(LBytes[3]));
end;

procedure TTestGreedPngEncoder.DovrebbeDareIColoriDellaPalette;
var
  LDecoded: TPngImage;
begin
  // the color 5 of the palette of the tests has the 6 bit values 5, 6, 7: 20, 24, 28 in 8 bits
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image(2, 1, [5, 6]), FPalette, False));
  Assert.AreEqual(28, Integer(LDecoded.Pixels[0])); // B
  Assert.AreEqual(24, Integer(LDecoded.Pixels[1])); // G
  Assert.AreEqual(20, Integer(LDecoded.Pixels[2])); // R
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[3]));
  Assert.AreEqual(32, Integer(LDecoded.Pixels[4])); // B of the color 6
end;

procedure TTestGreedPngEncoder.DovrebbeTenereLeDimensioni;
var
  LInfo: TPngInfo;
begin
  LInfo := TPngProvider.Client.GetInfo(FEncoder.Encode(Image(3, 2, [0, 1, 2, 3, 4, 5]), FPalette, False));
  Assert.AreEqual(3, LInfo.Width);
  Assert.AreEqual(2, LInfo.Height);
end;

procedure TTestGreedPngEncoder.DovrebbeDareAlfaZeroAlloZeroSeVuoleLaTrasparenza;
var
  LDecoded: TPngImage;
begin
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image(2, 1, [0, 1]), FPalette, True));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[3]));
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[7]));
end;

procedure TTestGreedPngEncoder.DovrebbeTenereOpachoLoZeroSenzaTrasparenza;
var
  LDecoded: TPngImage;
begin
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image(2, 1, [0, 1]), FPalette, False));
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[3]));
end;

procedure TTestGreedPngEncoder.DovrebbeRifiutareUnaImmagineConLaDimensioneSbagliata;
begin
  Assert.WillRaise(procedure begin FEncoder.Encode(Image(2, 2, [1, 2, 3]), FPalette, False); end, EGreedDataException);
  Assert.WillRaise(procedure begin FEncoder.Encode(Image(0, 0, []), FPalette, False); end, EGreedDataException);
end;

procedure TTestGreedPngEncoder.DovrebbeRifiutareUnaPaletteCorta;
begin
  Assert.WillRaise(procedure begin FEncoder.Encode(Image(1, 1, [1]), TBytes.Create(1, 2, 3), False); end, EGreedDataException);
end;

procedure TTestGreedPngEncoder.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(procedure begin TGreedPngEncoder.Create(nil, TPngProvider.Client); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TGreedPngEncoder.Create(TVideoFactory.CreatePaletteConverter, nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedPngEncoder);

end.
