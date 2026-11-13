{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the particles and of the transparency tables of    }
{  the xcom battlescape library                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomBattlescape.Particle;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Palette, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomBattlescape.Particle, DelphiDoom.XcomBattlescape.TransparencyTable;

type
  [TestFixture]
  [Category('xcom-battlescape')]
  TTestXcomParticle = class(TObject)
  public
    [TestCase('Piccola', '149,1')]
    [TestCase('Soglia 150', '150,0')]
    [TestCase('Soglia 125', '125,1')]
    [TestCase('Sotto 125', '124,2')]
    [TestCase('Soglia 100', '100,2')]
    [TestCase('Sotto 100', '99,3')]
    procedure DovrebbeScegliereLaDimensioneDallaDensita(ADensity, ASize: Integer);
    [TestCase('Tutta', '44,3')]
    [TestCase('Meta', '13,2')]
    [TestCase('Poca', '3,1')]
    [TestCase('Finita', '0,0')]
    procedure DovrebbeCalcolareIlLivelloDiOpacita(AOpacity, ALevel: Integer);
    [Test]
    procedure DovrebbeSalireEPerdereOpacitaAdOgniPasso;
    [Test]
    procedure DovrebbeFinireQuandoL_OpacitaArrivaAZero;
  end;

  [TestFixture]
  [Category('xcom-battlescape')]
  TTestXcomTransparencyTable = class(TObject)
  strict private
    function MakePalette: TXcomPalette;
    function MakeTints: TArray<TXcomTransparencyColor>;
  public
    [Test]
    procedure DovrebbeDareMilleVentiquattroByteAPerTinta;
    [Test]
    procedure DovrebbeLasciareTrasparenteIlColoreZero;
    [Test]
    procedure DovrebbeAvvicinareIlColoreAllaTintaConLOpacitaMassima;
    [Test]
    procedure DovrebbeTenereIlBiancoAlLivelloPiuBasso;
  end;

implementation

{ TTestXcomParticle }

procedure TTestXcomParticle.DovrebbeScegliereLaDimensioneDallaDensita(ADensity, ASize: Integer);
var
  LParticle: TXcomParticle;
begin
  LParticle := TXcomParticle.Create(0, 0, ADensity, 1, 40);
  try
    Assert.AreEqual(ASize, LParticle.Size);
  finally
    LParticle.Free;
  end;
end;

procedure TTestXcomParticle.DovrebbeCalcolareIlLivelloDiOpacita(AOpacity, ALevel: Integer);
var
  LParticle: TXcomParticle;
begin
  LParticle := TXcomParticle.Create(0, 0, 100, 1, AOpacity);
  try
    Assert.AreEqual(ALevel, LParticle.OpacityLevel);
  finally
    LParticle.Free;
  end;
end;

procedure TTestXcomParticle.DovrebbeSalireEPerdereOpacitaAdOgniPasso;
var
  LParticle: TXcomParticle;
  LRandom: IXcomRandom;
begin
  LRandom := TXcomRandom.Create(5);
  LParticle := TXcomParticle.Create(10, 20, 64, 1, 40);
  try
    Assert.IsTrue(LParticle.Animate(LRandom));
    // (320 - 64) / 256 = 1
    Assert.AreEqual(19.0, Double(LParticle.YOffset), 0.0001);
    Assert.AreEqual(39, Integer(LParticle.Opacity));
    // the jitter is a step of 0.25 to 0.55 to the left or to the right
    Assert.IsTrue(Abs(LParticle.XOffset - 10) >= 0.2499);
    Assert.IsTrue(Abs(LParticle.XOffset - 10) <= 0.5501);
  finally
    LParticle.Free;
  end;
end;

procedure TTestXcomParticle.DovrebbeFinireQuandoL_OpacitaArrivaAZero;
var
  LParticle: TXcomParticle;
  LRandom: IXcomRandom;
  LSteps: Integer;
begin
  LRandom := TXcomRandom.Create(9);
  LParticle := TXcomParticle.Create(0, 0, 100, 1, 3);
  try
    LSteps := 1;
    while LParticle.Animate(LRandom) do
      Inc(LSteps);
    Assert.AreEqual(3, LSteps);
  finally
    LParticle.Free;
  end;
end;

{ TTestXcomTransparencyTable }

function TTestXcomTransparencyTable.MakePalette: TXcomPalette;
begin
  Result := TXcomPalette.Create(256);
  // 0 transparent, 1 black, 2 white, 3 red
  Result.Colors[1].Red := 0;
  Result.Colors[1].Green := 0;
  Result.Colors[1].Blue := 0;
  Result.Colors[2].Red := 255;
  Result.Colors[2].Green := 255;
  Result.Colors[2].Blue := 255;
  Result.Colors[3].Red := 255;
  Result.Colors[3].Green := 0;
  Result.Colors[3].Blue := 0;
end;

function TTestXcomTransparencyTable.MakeTints: TArray<TXcomTransparencyColor>;
begin
  SetLength(Result, 1);
  Result[0].R := 255;
  Result[0].G := 0;
  Result[0].B := 0;
  Result[0].Unused := 16;
end;

procedure TTestXcomTransparencyTable.DovrebbeDareMilleVentiquattroByteAPerTinta;
var
  LTints: TArray<TXcomTransparencyColor>;
begin
  LTints := MakeTints;
  SetLength(LTints, 2);
  Assert.AreEqual<Integer>(2048, Length(TXcomTransparencyTable.Build(MakePalette, LTints)));
end;

procedure TTestXcomTransparencyTable.DovrebbeLasciareTrasparenteIlColoreZero;
var
  LTable: TBytes;
  LLevel: Integer;
begin
  LTable := TXcomTransparencyTable.Build(MakePalette, MakeTints);
  for LLevel := 0 to 3 do
    Assert.AreEqual(0, Integer(LTable[LLevel * 256]));
end;

procedure TTestXcomTransparencyTable.DovrebbeAvvicinareIlColoreAllaTintaConLOpacitaMassima;
var
  LTable: TBytes;
begin
  LTable := TXcomTransparencyTable.Build(MakePalette, MakeTints);
  // the level 3 has opacity 4 * 16 = 64: all tint, the closest color of the palette to red is 3
  Assert.AreEqual(3, Integer(LTable[3 * 256 + 2]));
  Assert.AreEqual(3, Integer(LTable[3 * 256 + 1]));
end;

procedure TTestXcomTransparencyTable.DovrebbeTenereIlBiancoAlLivelloPiuBasso;
var
  LTable: TBytes;
begin
  LTable := TXcomTransparencyTable.Build(MakePalette, MakeTints);
  // opacity 16 of 64: the mix of white and red is still closer to white (255,255,255) than to red
  Assert.AreEqual(2, Integer(LTable[2]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomParticle);
  TDUnitX.RegisterTestFixture(TTestXcomTransparencyTable);

end.
