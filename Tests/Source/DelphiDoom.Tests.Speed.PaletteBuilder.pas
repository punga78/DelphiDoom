{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedPaletteBuilder                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.PaletteBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Speed.Intf;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedPaletteBuilder = class(TObject)
  strict private
    FBuilder: ISpeedPaletteBuilder;
    /// <summary>256 different colors, none above 63 (the palette of a file)</summary>
    function SixBitPalette: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMoltiplicareAQuattroUnaPalettaDiSeiBit;
    [Test]
    procedure DovrebbeLasciareUnaPalettaCheHaUnValoreDaSessantaquattroInSu;
    [Test]
    procedure DovrebbeDareQuattordiciPaletteEDiciottoMappe;
    [Test]
    procedure DovrebbeCominciareLePalettePerLaPalettaDiBase;
    [Test]
    procedure DovrebbeSpingereVersoIlRossoLaPalettaDelDolore;
    [Test]
    procedure DovrebbeSpingereVersoIlVerdeLaPalettaDellaTuta;
    [Test]
    procedure DovrebbeDareNellaMappaZeroGliStessiColori;
    [Test]
    procedure DovrebbeFareNeraLUltimaMappa;
    [Test]
    procedure DovrebbeSchiarireLeMappeVersoLaFine;
    [Test]
    procedure DovrebbeDareIColoriComeRossoVerdeBlu;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCorta;
    [Test]
    procedure DovrebbeRifiutareUnMatcherNil;
    [Test]
    procedure DovrebbeNonCambiareLaPalettaDelChiamante;
  end;

implementation

uses
  DelphiDoom.GameData.Types, DelphiDoom.Palette.Factory, DelphiDoom.Speed.Factory,
  DelphiDoom.Speed.PaletteBuilder;

{ TTestSpeedPaletteBuilder }

procedure TTestSpeedPaletteBuilder.Setup;
begin
  FBuilder := TSpeedFactory.CreatePaletteBuilder;
end;

procedure TTestSpeedPaletteBuilder.TearDown;
begin
  FBuilder := nil;
end;

function TTestSpeedPaletteBuilder.SixBitPalette: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 768);
  for LIndex := 0 to 255 do
  begin
    Result[LIndex * 3] := Byte(LIndex mod 64);
    Result[LIndex * 3 + 1] := Byte((LIndex div 4) mod 64);
    Result[LIndex * 3 + 2] := Byte(255 - LIndex) mod 64;
  end;
  // every color has to be different (the maps are tested by it)
  for LIndex := 0 to 255 do
    Result[LIndex * 3 + 1] := Byte(LIndex div 4);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeMoltiplicareAQuattroUnaPalettaDiSeiBit;
var
  LPalette: TBytes;
  LResult: TSpeedPalette;
begin
  LPalette := SixBitPalette;
  LResult := FBuilder.Build(LPalette);
  Assert.AreEqual<Byte>(Byte(4 * LPalette[30]), LResult.Source[30]);
  Assert.AreEqual<Byte>(Byte(4 * LPalette[767]), LResult.Source[767]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeLasciareUnaPalettaCheHaUnValoreDaSessantaquattroInSu;
var
  LPalette: TBytes;
  LResult: TSpeedPalette;
begin
  LPalette := SixBitPalette;
  LPalette[5] := 64;
  LResult := FBuilder.Build(LPalette);
  Assert.AreEqual<Byte>(64, LResult.Source[5]);
  Assert.AreEqual<Byte>(LPalette[30], LResult.Source[30], 'not multiplied');
end;

procedure TTestSpeedPaletteBuilder.DovrebbeDareQuattordiciPaletteEDiciottoMappe;
var
  LResult: TSpeedPalette;
begin
  LResult := FBuilder.Build(SixBitPalette);
  Assert.AreEqual<Integer>(14 * 768, Length(LResult.PlayPal));
  Assert.AreEqual<Integer>(34 * 256, Length(LResult.ColorMap));
  Assert.AreEqual<Integer>(256, Length(LResult.Colors));
  Assert.AreEqual<Integer>(768, Length(LResult.Source));
end;

procedure TTestSpeedPaletteBuilder.DovrebbeCominciareLePalettePerLaPalettaDiBase;
var
  LResult: TSpeedPalette;
  LIndex: Integer;
begin
  LResult := FBuilder.Build(SixBitPalette);
  for LIndex := 0 to 767 do
    Assert.AreEqual<Byte>(LResult.Source[LIndex], LResult.PlayPal[LIndex]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeSpingereVersoIlRossoLaPalettaDelDolore;
var
  LResult: TSpeedPalette;
begin
  LResult := FBuilder.Build(SixBitPalette);
  // the color 0 has R = 0: the palette 1 gives (255 - 0) * 1 div 9 = 28; the green is 0 + (0 - 0) = 0
  Assert.AreEqual<Byte>(28, LResult.PlayPal[768 + 0]);
  Assert.AreEqual<Byte>(LResult.Source[1], LResult.PlayPal[768 + 1]);
  // the palette 8: (255 - 0) * 8 div 9 = 226
  Assert.AreEqual<Byte>(226, LResult.PlayPal[8 * 768 + 0]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeSpingereVersoIlVerdeLaPalettaDellaTuta;
var
  LResult: TSpeedPalette;
begin
  LResult := FBuilder.Build(SixBitPalette);
  // the color 0 has G = 0: the palette 13 gives (256 - 0) * 1 div 8 = 32
  Assert.AreEqual<Byte>(32, LResult.PlayPal[13 * 768 + 1]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeDareNellaMappaZeroGliStessiColori;
var
  LResult: TSpeedPalette;
  LIndex: Integer;
begin
  LResult := FBuilder.Build(SixBitPalette);
  // the light 0 is the color itself: an exact match is found at once
  for LIndex := 0 to 255 do
    Assert.AreEqual<Cardinal>(LResult.Colors[LIndex], LResult.Colors[LResult.ColorMap[LIndex]]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeFareNeraLUltimaMappa;
var
  LResult: TSpeedPalette;
  LIndex: Integer;
begin
  LResult := FBuilder.Build(SixBitPalette);
  for LIndex := 0 to 255 do
    Assert.AreEqual<Byte>(0, LResult.ColorMap[33 * 256 + LIndex]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeSchiarireLeMappeVersoLaFine;
var
  LResult: TSpeedPalette;
  LIndex: Integer;
  LFirst: Integer;
  LLast: Integer;

  function Brightness(AColor: Cardinal): Integer;
  begin
    Result := Integer((AColor shr 16) and $FF) + Integer((AColor shr 8) and $FF) + Integer(AColor and $FF);
  end;

begin
  LResult := FBuilder.Build(SixBitPalette);
  LFirst := 0;
  LLast := 0;
  for LIndex := 0 to 255 do
  begin
    Inc(LFirst, Brightness(LResult.Colors[LResult.ColorMap[LIndex]]));
    Inc(LLast, Brightness(LResult.Colors[LResult.ColorMap[31 * 256 + LIndex]]));
  end;
  Assert.IsTrue(LLast < LFirst, 'the last light map is darker than the first');
end;

procedure TTestSpeedPaletteBuilder.DovrebbeDareIColoriComeRossoVerdeBlu;
var
  LResult: TSpeedPalette;
begin
  LResult := FBuilder.Build(SixBitPalette);
  Assert.AreEqual<Cardinal>((Cardinal(LResult.Source[300]) shl 16) + (Cardinal(LResult.Source[301]) shl 8) +
    LResult.Source[302], LResult.Colors[100]);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeRifiutareUnaPalettaCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(TBytes.Create(1, 2, 3));
    end, EGameDataException);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeRifiutareUnMatcherNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedPaletteBuilder.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestSpeedPaletteBuilder.DovrebbeNonCambiareLaPalettaDelChiamante;
var
  LPalette: TBytes;
  LCopy: TBytes;
begin
  LPalette := SixBitPalette;
  LCopy := Copy(LPalette);
  FBuilder.Build(LPalette);
  Assert.AreEqual<TBytes>(LCopy, LPalette);
end;

end.
