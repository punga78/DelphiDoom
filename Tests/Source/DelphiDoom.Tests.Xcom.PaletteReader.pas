{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - PALETTES.DAT                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.PaletteReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.Xcom.Intf;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomPaletteReader = class(TObject)
  private
    FReader: IXcomPaletteReader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeMoltiplicareIValoriPerQuattro;
    [Test]
    procedure DovrebbeRendereTrasparenteIlColoreZero;
    [Test]
    procedure DovrebbeLeggereDallOffset;
    [Test]
    procedure DovrebbeLasciareNeriIColoriCheIlFileNonHa;
    [Test]
    procedure DovrebbeIgnorareUnColoreTroncato;
    [Test]
    procedure DovrebbeTroncareUnValoreSopraSessantatre;
    [Test]
    procedure DovrebbeDareTuttiNeriSeLOffsetEOltreLaFine;
    [Test]
    procedure DovrebbeRifiutareUnOffsetNegativo;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiColoriNonValido;
    [Test]
    procedure DovrebbeDareLOffsetDiUnaPalette;
  end;

implementation

uses
  DelphiDoom.Xcom.Factory, DelphiDoom.Tests.Xcom.Builders;

{ TTestXcomPaletteReader }

procedure TTestXcomPaletteReader.Setup;
begin
  FReader := TXcomFactory.CreatePaletteReader;
end;

procedure TTestXcomPaletteReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestXcomPaletteReader.DovrebbeMoltiplicareIValoriPerQuattro;
var
  LPalette: TXcomPalette;
begin
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([0, 0, 0, 63, 32, 1]), 2, 0);
  Assert.AreEqual(2, LPalette.Count);
  Assert.AreEqual(252, Integer(LPalette.Colors[1].Red));
  Assert.AreEqual(128, Integer(LPalette.Colors[1].Green));
  Assert.AreEqual(4, Integer(LPalette.Colors[1].Blue));
end;

procedure TTestXcomPaletteReader.DovrebbeRendereTrasparenteIlColoreZero;
var
  LPalette: TXcomPalette;
begin
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([9, 9, 9, 9, 9, 9]), 2, 0);
  Assert.AreEqual(0, Integer(LPalette.Colors[0].Alpha));
  Assert.AreEqual(36, Integer(LPalette.Colors[0].Red), 'il colore 0 ha i suoi valori, solo l''alfa e'' 0');
  Assert.AreEqual(255, Integer(LPalette.Colors[1].Alpha));
end;

procedure TTestXcomPaletteReader.DovrebbeLeggereDallOffset;
var
  LPalette: TXcomPalette;
begin
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([1, 1, 1, 2, 2, 2, 3, 3, 3]), 1, 6);
  Assert.AreEqual(12, Integer(LPalette.Colors[0].Red));
end;

procedure TTestXcomPaletteReader.DovrebbeLasciareNeriIColoriCheIlFileNonHa;
var
  LPalette: TXcomPalette;
begin
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([1, 2, 3, 4, 5, 6]), 4, 0);
  Assert.AreEqual(4, LPalette.Count);
  Assert.AreEqual(0, Integer(LPalette.Colors[2].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[2].Alpha));
end;

procedure TTestXcomPaletteReader.DovrebbeIgnorareUnColoreTroncato;
var
  LPalette: TXcomPalette;
begin
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([1, 2, 3, 4, 5]), 2, 0);
  Assert.AreEqual(0, Integer(LPalette.Colors[1].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[1].Alpha));
end;

procedure TTestXcomPaletteReader.DovrebbeTroncareUnValoreSopraSessantatre;
var
  LPalette: TXcomPalette;
begin
  // 100 * 4 = 400 does not fit in a byte: 400 - 256 = 144 (the C++ keeps the low byte)
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([0, 0, 0, 100, 64, 255]), 2, 0);
  Assert.AreEqual(144, Integer(LPalette.Colors[1].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[1].Green));
  Assert.AreEqual(252, Integer(LPalette.Colors[1].Blue));
end;

procedure TTestXcomPaletteReader.DovrebbeDareTuttiNeriSeLOffsetEOltreLaFine;
var
  LPalette: TXcomPalette;
begin
  LPalette := FReader.Read(TXcomTestBuilders.Bytes([1, 2, 3]), 2, 100);
  Assert.AreEqual(0, Integer(LPalette.Colors[0].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[1].Alpha));
end;

procedure TTestXcomPaletteReader.DovrebbeRifiutareUnOffsetNegativo;
begin
  Assert.WillRaise(procedure begin FReader.Read(nil, 2, -1); end, EXcomException);
end;

procedure TTestXcomPaletteReader.DovrebbeRifiutareUnNumeroDiColoriNonValido;
begin
  Assert.WillRaise(procedure begin FReader.Read(nil, 300, 0); end, EXcomException);
end;

procedure TTestXcomPaletteReader.DovrebbeDareLOffsetDiUnaPalette;
begin
  Assert.AreEqual(0, FReader.OffsetOf(0));
  Assert.AreEqual(774, FReader.OffsetOf(1));
  Assert.AreEqual(3096, FReader.OffsetOf(4));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomPaletteReader);

end.
