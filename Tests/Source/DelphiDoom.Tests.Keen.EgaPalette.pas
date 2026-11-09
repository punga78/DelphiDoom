{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the colors of the EGA                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.EgaPalette;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenEgaPalette = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIColoriDelloSchermoEga;
    [Test]
    procedure DovrebbeDarePrimaiEIntensiDiversi;
    [Test]
    procedure DovrebbeRifiutareUnColoreCheNonCe;
    [Test]
    procedure DovrebbeDareUnaPaletteDi256ColoriPerLaLibreriaDelleTavolozze;
    [Test]
    procedure DovrebbeConvertireLaPaletteConIlConvertitoreDelVideo;
  end;

implementation

uses
  DelphiDoom.Keen.EgaPalette, DelphiDoom.Video.Intf, DelphiDoom.Video.Factory;

{ TTestKeenEgaPalette }

procedure TTestKeenEgaPalette.DovrebbeDareIColoriDelloSchermoEga;
begin
  Assert.AreEqual($000000, Integer(TKeenEgaPalette.Color(0)), 'nero');
  Assert.AreEqual($0000AA, Integer(TKeenEgaPalette.Color(1)), 'blu');
  Assert.AreEqual($AA5500, Integer(TKeenEgaPalette.Color(6)), 'marrone');
  Assert.AreEqual($AAAAAA, Integer(TKeenEgaPalette.Color(7)), 'grigio chiaro');
  Assert.AreEqual($555555, Integer(TKeenEgaPalette.Color(8)), 'grigio scuro');
  Assert.AreEqual($FFFF55, Integer(TKeenEgaPalette.Color(14)), 'giallo');
  Assert.AreEqual($FFFFFF, Integer(TKeenEgaPalette.Color(15)), 'bianco');
end;

procedure TTestKeenEgaPalette.DovrebbeDarePrimaiEIntensiDiversi;
var
  LIndex: Integer;
  LOther: Integer;
begin
  for LIndex := 0 to KEEN_EGA_COLORS - 1 do
    for LOther := LIndex + 1 to KEEN_EGA_COLORS - 1 do
      Assert.AreNotEqual(Integer(TKeenEgaPalette.Color(LIndex)), Integer(TKeenEgaPalette.Color(LOther)));
end;

procedure TTestKeenEgaPalette.DovrebbeRifiutareUnColoreCheNonCe;
begin
  Assert.WillRaise(procedure begin TKeenEgaPalette.Color(16); end, EKeenException);
  Assert.WillRaise(procedure begin TKeenEgaPalette.Color(-1); end, EKeenException);
end;

procedure TTestKeenEgaPalette.DovrebbeDareUnaPaletteDi256ColoriPerLaLibreriaDelleTavolozze;
var
  LPalette: TBytes;
begin
  LPalette := TKeenEgaPalette.GamePalette;
  Assert.AreEqual(768, Length(LPalette));
  Assert.AreEqual($AA, Integer(LPalette[6 * 3]), 'rosso del marrone');
  Assert.AreEqual($55, Integer(LPalette[6 * 3 + 1]), 'verde del marrone');
  Assert.AreEqual($00, Integer(LPalette[6 * 3 + 2]), 'blu del marrone');
  Assert.AreEqual($FF, Integer(LPalette[15 * 3 + 2]), 'blu del bianco');
  Assert.AreEqual(0, Integer(LPalette[16 * 3]), 'il resto e'' nero');
  Assert.AreEqual(0, Integer(LPalette[255 * 3 + 2]));
end;

procedure TTestKeenEgaPalette.DovrebbeConvertireLaPaletteConIlConvertitoreDelVideo;
var
  LConverter: IPaletteConverter;
  LPalette: TBytes;
  LGamma: array[0..255] of Byte;
  LColors: array[0..255] of Cardinal;
  LIndex: Integer;
begin
  LConverter := TVideoFactory.CreatePaletteConverter;
  LPalette := TKeenEgaPalette.GamePalette;
  for LIndex := 0 to 255 do
    LGamma[LIndex] := Byte(LIndex);
  LConverter.Convert(@LPalette[0], @LGamma[0], @LColors[0]);
  for LIndex := 0 to KEEN_EGA_COLORS - 1 do
    Assert.AreEqual(Integer(TKeenEgaPalette.Color(LIndex)), Integer(LColors[LIndex]), 'colore ' + IntToStr(LIndex));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenEgaPalette);

end.
