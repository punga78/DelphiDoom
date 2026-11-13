{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the palette                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Palette;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Types, DelphiDoom.Greed.Palette;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedPalette = class(TObject)
  public
    [Test]
    procedure DovrebbeMoltiplicarePerQuattroIValoriDiSeiBit;
    [Test]
    procedure DovrebbeDare768Byte;
    [Test]
    procedure DovrebbeTroncareAUnByteUnValoreOltreSessantatre;
    [Test]
    procedure DovrebbeIgnorareICoseDopoI768Byte;
    [Test]
    procedure DovrebbeRifiutareUnLumpTroppoCorto;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.Builders;

{ TTestGreedPalette }

procedure TTestGreedPalette.DovrebbeMoltiplicarePerQuattroIValoriDiSeiBit;
var
  LPalette: TBytes;
begin
  LPalette := TGreedPalette.FromLump(TGreedLumps.Palette);
  Assert.AreEqual(0, Integer(LPalette[0]));
  Assert.AreEqual(4, Integer(LPalette[1]));
  Assert.AreEqual(8, Integer(LPalette[2]));
  Assert.AreEqual(63 * 4, Integer(LPalette[63 * 3]));
  Assert.AreEqual(0, Integer(LPalette[64 * 3]));
end;

procedure TTestGreedPalette.DovrebbeDare768Byte;
begin
  Assert.AreEqual<Integer>(GREED_PALETTE_BYTES, Length(TGreedPalette.FromLump(TGreedLumps.Palette)));
end;

procedure TTestGreedPalette.DovrebbeTroncareAUnByteUnValoreOltreSessantatre;
var
  LLump: TBytes;
begin
  // DISKPAL[i] := p[i] * 4 in a byte: 65 * 4 = 260 -> 4, 255 * 4 = 1020 -> 252
  LLump := TGreedLumps.Palette;
  LLump[0] := 65;
  LLump[1] := 255;
  Assert.AreEqual(4, Integer(TGreedPalette.FromLump(LLump)[0]));
  Assert.AreEqual(252, Integer(TGreedPalette.FromLump(LLump)[1]));
end;

procedure TTestGreedPalette.DovrebbeIgnorareICoseDopoI768Byte;
var
  LLump: TBytes;
begin
  LLump := TGreedLumps.Palette;
  SetLength(LLump, 800);
  Assert.AreEqual<Integer>(GREED_PALETTE_BYTES, Length(TGreedPalette.FromLump(LLump)));
end;

procedure TTestGreedPalette.DovrebbeRifiutareUnLumpTroppoCorto;
var
  LLump: TBytes;
begin
  SetLength(LLump, 767);
  Assert.WillRaise(procedure begin TGreedPalette.FromLump(LLump); end, EGreedDataException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedPalette);

end.
