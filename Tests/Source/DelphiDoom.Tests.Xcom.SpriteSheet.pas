{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the sheet of sprites         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.SpriteSheet;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Image;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomSpriteSheet = class(TObject)
  private
    function Frame(AWidth, AHeight: Integer; AFill: Byte): TXcomImage;
  public
    [Test]
    procedure DovrebbeMetterleImmaginiInUnaGriglia;
    [Test]
    procedure DovrebbeUsareUnaCellaPerIlFotogrammaPiuGrande;
    [Test]
    procedure DovrebbeRidurreLeColonneAlNumeroDiFotogrammi;
    [Test]
    procedure DovrebbeTenereLaPaletteDelPrimoFotogramma;
    [Test]
    procedure DovrebbeRifiutareUnInsiemeVuotoONessunaColonna;
  end;

implementation

uses
  DelphiDoom.Xcom.SpriteSheet, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomSpriteSheet }

function TTestXcomSpriteSheet.Frame(AWidth, AHeight: Integer; AFill: Byte): TXcomImage;
begin
  Result := TXcomImage.Create(AWidth, AHeight);
  FillChar(Result.Pixels[0], Length(Result.Pixels), AFill);
end;

procedure TTestXcomSpriteSheet.DovrebbeMetterleImmaginiInUnaGriglia;
var
  LSheet: TXcomImage;
begin
  LSheet := TXcomSpriteSheet.Compose([Frame(2, 2, 1), Frame(2, 2, 2), Frame(2, 2, 3)], 2);
  Assert.AreEqual(4, LSheet.Width);
  Assert.AreEqual(4, LSheet.Height);
  Assert.AreEqual('01 01 02 02 01 01 02 02 03 03 00 00 03 03 00 00', TXcomTestBuilders.Pixels(LSheet));
end;

procedure TTestXcomSpriteSheet.DovrebbeUsareUnaCellaPerIlFotogrammaPiuGrande;
var
  LSheet: TXcomImage;
begin
  LSheet := TXcomSpriteSheet.Compose([Frame(1, 3, 5), Frame(3, 1, 6)], 2);
  Assert.AreEqual(6, LSheet.Width);
  Assert.AreEqual(3, LSheet.Height);
  Assert.AreEqual(5, Integer(LSheet.GetPixel(0, 2)));
  Assert.AreEqual(6, Integer(LSheet.GetPixel(5, 0)));
  Assert.AreEqual(0, Integer(LSheet.GetPixel(5, 1)));
end;

procedure TTestXcomSpriteSheet.DovrebbeRidurreLeColonneAlNumeroDiFotogrammi;
var
  LSheet: TXcomImage;
begin
  LSheet := TXcomSpriteSheet.Compose([Frame(2, 2, 1), Frame(2, 2, 2)], 16);
  Assert.AreEqual(4, LSheet.Width);
  Assert.AreEqual(2, LSheet.Height);
end;

procedure TTestXcomSpriteSheet.DovrebbeTenereLaPaletteDelPrimoFotogramma;
var
  LFrame: TXcomImage;
  LSheet: TXcomImage;
begin
  LFrame := Frame(1, 1, 1);
  LFrame.HasPalette := True;
  LFrame.Palette := TXcomPalette.Create(256);
  LFrame.Palette.Colors[1].Blue := 77;
  LSheet := TXcomSpriteSheet.Compose([LFrame], 1);
  Assert.IsTrue(LSheet.HasPalette);
  Assert.AreEqual(77, Integer(LSheet.Palette.Colors[1].Blue));
end;

procedure TTestXcomSpriteSheet.DovrebbeRifiutareUnInsiemeVuotoONessunaColonna;
begin
  Assert.WillRaise(procedure begin TXcomSpriteSheet.Compose(nil, 2); end, EXcomException);
  Assert.WillRaise(procedure begin TXcomSpriteSheet.Compose([TXcomImage.Create(1, 1)], 0); end, EXcomException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomSpriteSheet);

end.
