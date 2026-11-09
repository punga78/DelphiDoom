{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixPaletteBuilder                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.PaletteBuilder;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixPaletteBuilder = class(TObject)
  strict private
    FBuilder: IRadixPaletteBuilder;
    /// <summary>A palette of 256 different colors; with AScale 5 the largest value is 75 (8 bit), with 3 it is 45 (VGA)</summary>
    function DistinctPalette(AScale: Integer): TBytes;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeMoltiplicareP4UnaPalettaVga;
    [Test]
    procedure DovrebbeLasciareUnaPalettaGiaA8Bit;
    [Test]
    procedure DovrebbeFare22PaletteInPlayPal;
    [Test]
    procedure DovrebbeCopiareLaPalettaBaseNellaPrima;
    [Test]
    procedure DovrebbeSpostareVersoIlVerdeLaPalettaTredici;
    [Test]
    procedure DovrebbeFare34TabelleInColorMap;
    [Test]
    procedure DovrebbeTenereIColoriNellaTabellaDiLuceZero;
    [Test]
    procedure DovrebbeFareNeraLUltimaTabella;
    [Test]
    procedure DovrebbeFareUnaTraduzioneIdentitaTraDuePaletteUguali;
    [Test]
    procedure DovrebbeRifiutareUnaPalettaCorta;
  end;

implementation

{ TTestRadixPaletteBuilder }

procedure TTestRadixPaletteBuilder.Setup;
begin
  FBuilder := TRadixFactory.CreatePaletteBuilder;
end;

function TTestRadixPaletteBuilder.DistinctPalette(AScale: Integer): TBytes;
var
  LColor: Integer;
begin
  SetLength(Result, 768);
  for LColor := 0 to 255 do
  begin
    // the pairs of (r, g) are all different, so every color is
    Result[LColor * 3] := Byte((LColor mod 16) * AScale);
    Result[LColor * 3 + 1] := Byte((LColor div 16) * AScale);
    Result[LColor * 3 + 2] := Byte(((LColor * 5) mod 16) * AScale);
  end;
end;

procedure TTestRadixPaletteBuilder.DovrebbeMoltiplicareP4UnaPalettaVga;
var
  LPalette: TBytes;
begin
  LPalette := DistinctPalette(3);
  Assert.IsTrue(FBuilder.Scale(LPalette));
  Assert.AreEqual(Integer(48), Integer(LPalette[3 * 4]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeLasciareUnaPalettaGiaA8Bit;
var
  LPalette: TBytes;
begin
  LPalette := DistinctPalette(5);
  Assert.IsFalse(FBuilder.Scale(LPalette));
  Assert.AreEqual(Integer(20), Integer(LPalette[3 * 4]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeFare22PaletteInPlayPal;
begin
  Assert.AreEqual(22 * 768, Length(FBuilder.BuildPlayPal(DistinctPalette(5))));
end;

procedure TTestRadixPaletteBuilder.DovrebbeCopiareLaPalettaBaseNellaPrima;
var
  LBase: TBytes;
  LPlayPal: TBytes;
  LIndex: Integer;
begin
  LBase := DistinctPalette(5);
  LPlayPal := FBuilder.BuildPlayPal(LBase);
  for LIndex := 0 to 767 do
    Assert.AreEqual(Integer(LBase[LIndex]), Integer(LPlayPal[LIndex]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeSpostareVersoIlVerdeLaPalettaTredici;
var
  LBase: TBytes;
  LPlayPal: TBytes;
begin
  LBase := DistinctPalette(5);
  LPlayPal := FBuilder.BuildPlayPal(LBase);
  // the palette 13 is the base one moved by 1/8 to a green of 256
  Assert.AreEqual(Integer(Byte(LBase[3 * 20 + 1] + (256 - LBase[3 * 20 + 1]) div 8)),
    Integer(LPlayPal[768 * 13 + 3 * 20 + 1]));
  Assert.AreEqual(Integer(Byte(LBase[3 * 20] + (0 - LBase[3 * 20]) div 8)),
    Integer(LPlayPal[768 * 13 + 3 * 20]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeFare34TabelleInColorMap;
begin
  Assert.AreEqual(34 * 256, Length(FBuilder.BuildColorMap(DistinctPalette(5))));
end;

procedure TTestRadixPaletteBuilder.DovrebbeTenereIColoriNellaTabellaDiLuceZero;
var
  LColorMap: TBytes;
  LColor: Integer;
begin
  LColorMap := FBuilder.BuildColorMap(DistinctPalette(5));
  for LColor := 0 to 255 do
    Assert.AreEqual(LColor, Integer(LColorMap[LColor]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeFareNeraLUltimaTabella;
var
  LColorMap: TBytes;
  LColor: Integer;
begin
  LColorMap := FBuilder.BuildColorMap(DistinctPalette(5));
  for LColor := 0 to 255 do
    Assert.AreEqual(0, Integer(LColorMap[33 * 256 + LColor]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeFareUnaTraduzioneIdentitaTraDuePaletteUguali;
var
  LPalette: TBytes;
  LTranslation: TBytes;
  LColor: Integer;
begin
  LPalette := DistinctPalette(5);
  LTranslation := FBuilder.BuildTranslation(LPalette, LPalette);
  for LColor := 0 to 255 do
    Assert.AreEqual(LColor, Integer(LTranslation[LColor]));
end;

procedure TTestRadixPaletteBuilder.DovrebbeRifiutareUnaPalettaCorta;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuilder.BuildPlayPal([1, 2, 3]);
    end, ERadixException);
end;

end.
