{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the PNG encoder              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.PngEncoder;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image,
  DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomPngEncoder = class(TObject)
  private
    FEncoder: IXcomImageEncoder;
    function Image: TXcomImage;
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
    procedure DovrebbeDareAlfaZeroAiPixelDiIndiceZeroSeLoSiChiede;
    [Test]
    procedure DovrebbeTenereLeDimensioni;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineSenzaPalette;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineConLaDimensioneSbagliata;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Xcom.PngEncoder, DelphiDoom.Png.Intf, DelphiDoom.Png.Client, DelphiDoom.Png.Provider,
  DelphiDoom.Video.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomPngEncoder }

function TTestXcomPngEncoder.Image: TXcomImage;
begin
  Result := TXcomImage.Create(2, 1);
  Result.Pixels[0] := 0;
  Result.Pixels[1] := 1;
  Result.HasPalette := True;
  Result.Palette := TXcomPalette.Create(256);
  Result.Palette.Colors[0].Red := 10;
  Result.Palette.Colors[1].Red := 20;
  Result.Palette.Colors[1].Green := 30;
  Result.Palette.Colors[1].Blue := 40;
end;

procedure TTestXcomPngEncoder.Setup;
begin
  FEncoder := TXcomPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client);
end;

procedure TTestXcomPngEncoder.TearDown;
begin
  FEncoder := nil;
end;

procedure TTestXcomPngEncoder.DovrebbeScrivereUnFilePng;
var
  LBytes: TBytes;
begin
  LBytes := FEncoder.Encode(Image, False);
  Assert.IsTrue(Length(LBytes) > 8);
  Assert.AreEqual($89, Integer(LBytes[0]));
  Assert.AreEqual(Ord('P'), Integer(LBytes[1]));
  Assert.AreEqual(Ord('N'), Integer(LBytes[2]));
  Assert.AreEqual(Ord('G'), Integer(LBytes[3]));
end;

procedure TTestXcomPngEncoder.DovrebbeDareIColoriDellaPalette;
var
  LDecoded: TPngImage;
begin
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image, False));
  // B, G, R, A
  Assert.AreEqual(40, Integer(LDecoded.Pixels[4]));
  Assert.AreEqual(30, Integer(LDecoded.Pixels[5]));
  Assert.AreEqual(20, Integer(LDecoded.Pixels[6]));
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[7]));
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[3]), 'senza trasparenza anche il colore 0 e'' opaco');
end;

procedure TTestXcomPngEncoder.DovrebbeDareAlfaZeroAiPixelDiIndiceZeroSeLoSiChiede;
var
  LDecoded: TPngImage;
begin
  LDecoded := TPngProvider.Client.Decode(FEncoder.Encode(Image, True));
  Assert.AreEqual(0, Integer(LDecoded.Pixels[3]));
  Assert.AreEqual($FF, Integer(LDecoded.Pixels[7]));
end;

procedure TTestXcomPngEncoder.DovrebbeTenereLeDimensioni;
var
  LInfo: TPngInfo;
begin
  LInfo := TPngProvider.Client.GetInfo(FEncoder.Encode(Image, False));
  Assert.AreEqual(2, LInfo.Width);
  Assert.AreEqual(1, LInfo.Height);
end;

procedure TTestXcomPngEncoder.DovrebbeRifiutareUnaImmagineSenzaPalette;
begin
  Assert.WillRaise(procedure begin FEncoder.Encode(TXcomImage.Create(2, 1), False); end, EXcomException);
end;

procedure TTestXcomPngEncoder.DovrebbeRifiutareUnaImmagineConLaDimensioneSbagliata;
var
  LImage: TXcomImage;
begin
  LImage := Image;
  SetLength(LImage.Pixels, 3);
  Assert.WillRaise(procedure begin FEncoder.Encode(LImage, False); end, EXcomException);
  LImage := Default(TXcomImage);
  Assert.WillRaise(procedure begin FEncoder.Encode(LImage, False); end, EXcomException);
end;

procedure TTestXcomPngEncoder.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomPngEncoder.Create(nil, TPngProvider.Client);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TXcomPngEncoder.Create(TVideoFactory.CreatePaletteConverter, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomPngEncoder);

end.
