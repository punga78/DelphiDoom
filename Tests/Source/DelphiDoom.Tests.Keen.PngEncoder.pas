{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the PNG of an EGA image              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.PngEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenPngEncoder = class(TObject)
  private
    FEncoder: IKeenImageEncoder;
    function Image(AWidth, AHeight: Integer; const APixels: array of Byte): TKeenChunkyImage;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereUnFilePng;
    [Test]
    procedure DovrebbeDareIColoriDellaPaletteEga;
    [Test]
    procedure DovrebbeDareAlfaZeroAiPixelTrasparenti;
    [Test]
    procedure DovrebbeTenereLeDimensioni;
    [Test]
    procedure DovrebbeRifiutareUnColoreCheNonCe;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineConLaDimensioneSbagliata;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Keen.PngEncoder, DelphiDoom.Keen.EgaPalette, DelphiDoom.Png.Intf, DelphiDoom.Png.Client,
  DelphiDoom.Png.Provider,
  DelphiDoom.Video.Factory;

{ TTestKeenPngEncoder }

procedure TTestKeenPngEncoder.Setup;
begin
  FEncoder := TKeenPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client);
end;

procedure TTestKeenPngEncoder.TearDown;
begin
  FEncoder := nil;
end;

function TTestKeenPngEncoder.Image(AWidth, AHeight: Integer; const APixels: array of Byte): TKeenChunkyImage;
var
  LIndex: Integer;
begin
  Result.Width := AWidth;
  Result.Height := AHeight;
  SetLength(Result.Pixels, Length(APixels));
  for LIndex := 0 to High(APixels) do
    Result.Pixels[LIndex] := APixels[LIndex];
end;

procedure TTestKeenPngEncoder.DovrebbeScrivereUnFilePng;
var
  LBytes: TBytes;
begin
  LBytes := FEncoder.Encode(Image(2, 1, [1, 2]));
  Assert.IsTrue(Length(LBytes) > 8);
  Assert.AreEqual($89, Integer(LBytes[0]));
  Assert.AreEqual(Ord('P'), Integer(LBytes[1]));
  Assert.AreEqual(Ord('N'), Integer(LBytes[2]));
  Assert.AreEqual(Ord('G'), Integer(LBytes[3]));
end;

procedure TTestKeenPngEncoder.DovrebbeDareIColoriDellaPaletteEga;
var
  LDecoded: TPngImage;
  LIndex: Integer;
  LColor: Cardinal;
begin
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image(16, 1, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])));
  Assert.AreEqual(16, LDecoded.Info.Width);
  for LIndex := 0 to KEEN_EGA_COLORS - 1 do
  begin
    // B, G, R, A
    LColor := (Cardinal(LDecoded.Pixels[LIndex * 4 + 2]) shl 16) or (Cardinal(LDecoded.Pixels[LIndex * 4 + 1]) shl 8) or
      LDecoded.Pixels[LIndex * 4];
    Assert.AreEqual(Integer(TKeenEgaPalette.Color(LIndex)), Integer(LColor), 'colore ' + IntToStr(LIndex));
    Assert.AreEqual($FF, Integer(LDecoded.Pixels[LIndex * 4 + 3]));
  end;
end;

procedure TTestKeenPngEncoder.DovrebbeDareAlfaZeroAiPixelTrasparenti;
var
  LDecoded: TPngImage;
begin
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image(2, 1, [KEEN_PIXEL_TRANSPARENT, 15])));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[3]));
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[7]));
end;

procedure TTestKeenPngEncoder.DovrebbeTenereLeDimensioni;
var
  LInfo: TPngInfo;
begin
  LInfo := TPngProvider.Client.GetInfo(FEncoder.Encode(Image(3, 2, [0, 1, 2, 3, 4, 5])));
  Assert.AreEqual(3, LInfo.Width);
  Assert.AreEqual(2, LInfo.Height);
end;

procedure TTestKeenPngEncoder.DovrebbeRifiutareUnColoreCheNonCe;
begin
  Assert.WillRaise(procedure begin FEncoder.Encode(Image(1, 1, [16])); end, EKeenException);
end;

procedure TTestKeenPngEncoder.DovrebbeRifiutareUnaImmagineConLaDimensioneSbagliata;
begin
  Assert.WillRaise(procedure begin FEncoder.Encode(Image(2, 2, [1, 2, 3])); end, EKeenException);
  Assert.WillRaise(procedure begin FEncoder.Encode(Image(0, 0, [])); end, EKeenException);
end;

procedure TTestKeenPngEncoder.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenPngEncoder.Create(nil, TPngProvider.Client);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenPngEncoder.Create(TVideoFactory.CreatePaletteConverter, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenPngEncoder);

end.
