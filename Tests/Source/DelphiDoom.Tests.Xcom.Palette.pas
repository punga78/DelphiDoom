{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the palette                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.Palette;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette;

type
  [TestFixture]
  [Category('xcom')]
  TTestXcomPalette = class(TObject)
  public
    [Test]
    procedure DovrebbeCreareUnaPaletteNeraTrasparente;
    [Test]
    procedure DovrebbeRifiutareUnNumeroDiColoriNonValido;
    [Test]
    procedure DovrebbeDareUnColore;
    [Test]
    procedure DovrebbeRifiutareUnColoreCheNonCe;
    [Test]
    procedure DovrebbeDareIByteRgbDellaPalette;
    [Test]
    procedure DovrebbeMetterelIlGradienteDelCampoDiBattaglia;
    [Test]
    procedure DovrebbeVolereDuecentocinquantasseiColoriPerIlGradiente;
  end;

implementation

{ TTestXcomPalette }

procedure TTestXcomPalette.DovrebbeCreareUnaPaletteNeraTrasparente;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomPalette.Create(16);
  Assert.AreEqual(16, LPalette.Count);
  Assert.AreEqual(0, Integer(LPalette.Colors[15].Red));
  Assert.AreEqual(0, Integer(LPalette.Colors[15].Alpha));
end;

procedure TTestXcomPalette.DovrebbeRifiutareUnNumeroDiColoriNonValido;
begin
  Assert.WillRaise(procedure begin TXcomPalette.Create(-1); end, EXcomException);
  Assert.WillRaise(procedure begin TXcomPalette.Create(257); end, EXcomException);
end;

procedure TTestXcomPalette.DovrebbeDareUnColore;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomPalette.Create(4);
  LPalette.Colors[2].Green := 99;
  Assert.AreEqual(99, Integer(LPalette.ColorAt(2).Green));
end;

procedure TTestXcomPalette.DovrebbeRifiutareUnColoreCheNonCe;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomPalette.Create(4);
  Assert.WillRaise(procedure begin LPalette.ColorAt(4); end, EXcomException);
  Assert.WillRaise(procedure begin LPalette.ColorAt(-1); end, EXcomException);
end;

procedure TTestXcomPalette.DovrebbeDareIByteRgbDellaPalette;
var
  LPalette: TXcomPalette;
  LBytes: TBytes;
begin
  LPalette := TXcomPalette.Create(2);
  LPalette.Colors[0].Red := 1;
  LPalette.Colors[1].Green := 2;
  LPalette.Colors[1].Blue := 3;
  LBytes := LPalette.ToRgbBytes;
  Assert.AreEqual(768, Integer(Length(LBytes)));
  Assert.AreEqual(1, Integer(LBytes[0]));
  Assert.AreEqual(2, Integer(LBytes[4]));
  Assert.AreEqual(3, Integer(LBytes[5]));
  Assert.AreEqual(0, Integer(LBytes[6]), 'i colori che la palette non ha sono neri');
end;

procedure TTestXcomPalette.DovrebbeMetterelIlGradienteDelCampoDiBattaglia;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomPalette.Create(256);
  LPalette.ApplyBattlescapeGradient;
  Assert.AreEqual(140, Integer(LPalette.Colors[240].Red));
  Assert.AreEqual(152, Integer(LPalette.Colors[240].Green));
  Assert.AreEqual(148, Integer(LPalette.Colors[240].Blue));
  Assert.AreEqual(255, Integer(LPalette.Colors[240].Alpha));
  Assert.AreEqual(3, Integer(LPalette.Colors[255].Red));
  Assert.AreEqual(6, Integer(LPalette.Colors[255].Blue));
  Assert.AreEqual(0, Integer(LPalette.Colors[239].Red), 'i colori prima del gradiente non cambiano');
end;

procedure TTestXcomPalette.DovrebbeVolereDuecentocinquantasseiColoriPerIlGradiente;
var
  LPalette: TXcomPalette;
begin
  LPalette := TXcomPalette.Create(128);
  Assert.WillRaise(procedure begin LPalette.ApplyBattlescapeGradient; end, EXcomException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomPalette);

end.
