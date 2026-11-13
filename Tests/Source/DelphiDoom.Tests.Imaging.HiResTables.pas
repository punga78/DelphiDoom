{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingHiResTableBuilder                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.HiResTables;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.HiResTables, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingHiResTables = class(TObject)
  private
    FBuilder: IImagingHiResTableBuilder;
    function Index(ALevel, AFirst, ASecond: Integer): Integer;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestBuildMatchesOldCode;
    [Test]
    procedure TestBuildGivesEightLevelsOf256x256;
    [Test]
    procedure TestLevelZeroIsTheFirstColor;
    [Test]
    procedure TestLevelFourOfBlackAndWhiteIsTheHalf;
    [Test]
    procedure TestBlendOfAColorWithItselfLosesOneStepAtMost;
    [Test]
    procedure TestBuildWithAShortPaletteRaises;
  end;

implementation

function TTestImagingHiResTables.Index(ALevel, AFirst, ASecond: Integer): Integer;
begin
  Result := (ALevel * 256 + AFirst) * 256 + ASecond;
end;

procedure TTestImagingHiResTables.Setup;
begin
  FBuilder := TImagingHiResTableBuilder.Create;
end;

procedure TTestImagingHiResTables.TestBuildMatchesOldCode;
var
  LSeed: Integer;
begin
  for LSeed := 1 to 2 do
    TImagingGolden.Check('hires.golden.txt', 'palette_' + IntToStr(LSeed),
      TImagingSamples.Hex(TImagingSamples.Hash(FBuilder.Build(TImagingSamples.Palette(Cardinal(LSeed) * 1000)))));
end;

procedure TTestImagingHiResTables.TestBuildGivesEightLevelsOf256x256;
begin
  Assert.AreEqual<Integer>(8 * 256 * 256, Length(FBuilder.Build(TImagingSamples.Palette(3))), 'dovrebbe dare 8 livelli di 256x256 colori');
end;

procedure TTestImagingHiResTables.TestLevelZeroIsTheFirstColor;
var
  LPalette, LTable: TImagingPixels;
begin
  LPalette := TImagingSamples.Palette(4);
  LTable := FBuilder.Build(LPalette);
  Assert.AreEqual(LPalette[17], LTable[Index(0, 17, 0)], 'dovrebbe dare il primo colore al livello 0');
  Assert.AreEqual(LPalette[17], LTable[Index(0, 17, 255)], 'dovrebbe dare il primo colore con qualsiasi secondo');
end;

procedure TTestImagingHiResTables.TestLevelFourOfBlackAndWhiteIsTheHalf;
var
  LPalette, LTable: TImagingPixels;
begin
  LPalette := TImagingSamples.ZeroPixels(256);
  LPalette[1] := $00FFFFFF;
  LTable := FBuilder.Build(LPalette);
  Assert.AreEqual(Cardinal($007F7F7F), LTable[Index(4, 0, 1)], 'dovrebbe dare la meta'' tra nero e bianco');
end;

procedure TTestImagingHiResTables.TestBlendOfAColorWithItselfLosesOneStepAtMost;
var
  LPalette, LTable: TImagingPixels;
begin
  LPalette := TImagingSamples.ZeroPixels(256);
  LPalette[5] := $00808080;
  LTable := FBuilder.Build(LPalette);
  Assert.AreEqual(Cardinal($00808080), LTable[Index(0, 5, 5)], 'dovrebbe lasciare il colore al livello 0');
  Assert.IsTrue(Byte(LTable[Index(7, 5, 5)]) >= $7F, 'dovrebbe restare a un passo dal colore');
end;

procedure TTestImagingHiResTables.TestBuildWithAShortPaletteRaises;
var
  LPalette: TImagingPixels;
begin
  SetLength(LPalette, 255);
  Assert.WillRaise(
    procedure
    begin
      FBuilder.Build(LPalette);
    end, EImagingException, 'dovrebbe rifiutare una palette di meno di 256 colori');
end;

end.
