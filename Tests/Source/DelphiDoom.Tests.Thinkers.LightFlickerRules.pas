{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the rules of the fire flicker of each game             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightFlickerRules;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Intf;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightFlickerRules = class(TObject)
  private
    FRandom: IGameRandom;
    FStandard: ILightFlickerRules;
    FStrife: ILightFlickerRules;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareQuantitaMultipleDiSedici;
    [Test]
    procedure DovrebbeUsareUnNumeroCasualeSoloPerLaQuantitaDelFuocoStandard;
    [Test]
    procedure DovrebbeAspettareSempreQuattroTicNelFuocoStandard;
    [Test]
    procedure DovrebbePartireDaQuattroTicNelFuocoStandard;
    [Test]
    procedure DovrebbeSommareSedicialPiuBassoDeiViciniNelFuocoStandard;
    [Test]
    procedure DovrebbeDareQuantitaMultipleDiOttoInStrife;
    [Test]
    procedure DovrebbeAspettareDaUnoAQuattroTicInStrife;
    [Test]
    procedure DovrebbeUsareDueNumeriCasualiPerCambioInStrife;
    [Test]
    procedure DovrebbePartireDaDueTicInStrife;
    [Test]
    procedure DovrebbeScendereDiTrentaduePartendoDalLivelloDelSettoreInStrife;
    [Test]
    procedure DovrebbeNonScendereSottoZeroInStrife;
    [Test]
    procedure DovrebbeCrearePerOgniGiocoLeRegoleGiuste;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Factory,
  DelphiDoom.Thinkers.Light.FlickerRules.Standard, DelphiDoom.Thinkers.Light.FlickerRules.Strife,
  DelphiDoom.Tests.Thinkers.Fakes;

{ TTestThinkersLightFlickerRules }

procedure TTestThinkersLightFlickerRules.Setup;
begin
  FRandom := CreateTestRandom(0);
  FStandard := TLightStandardFlickerRules.Create;
  FStrife := TLightStrifeFlickerRules.Create;
end;

procedure TTestThinkersLightFlickerRules.TearDown;
begin
  FStandard := nil;
  FStrife := nil;
  FRandom := nil;
end;

procedure TTestThinkersLightFlickerRules.DovrebbeDareQuantitaMultipleDiSedici;
var
  LIndex: Integer;
  LAmount: Integer;
begin
  for LIndex := 1 to 600 do
  begin
    LAmount := FStandard.NextAmount(FRandom);
    Assert.IsTrue(LAmount in [0, 16, 32, 48], 'amount ' + IntToStr(LAmount));
  end;
end;

procedure TTestThinkersLightFlickerRules.DovrebbeUsareUnNumeroCasualeSoloPerLaQuantitaDelFuocoStandard;
var
  LStart: Integer;
begin
  LStart := FRandom.PlayIndex;
  FStandard.NextAmount(FRandom);
  Assert.AreEqual((LStart + 1) and 255, FRandom.PlayIndex, 'the amount takes one number');
  FStandard.NextCount(FRandom);
  Assert.AreEqual((LStart + 1) and 255, FRandom.PlayIndex, 'the wait takes none');
end;

procedure TTestThinkersLightFlickerRules.DovrebbeAspettareSempreQuattroTicNelFuocoStandard;
begin
  Assert.AreEqual(4, FStandard.NextCount(FRandom));
end;

procedure TTestThinkersLightFlickerRules.DovrebbePartireDaQuattroTicNelFuocoStandard;
begin
  Assert.AreEqual(4, FStandard.InitialCount);
end;

procedure TTestThinkersLightFlickerRules.DovrebbeSommareSedicialPiuBassoDeiViciniNelFuocoStandard;
begin
  Assert.AreEqual(96 + 16, FStandard.InitialMinLight(200, 96));
end;

procedure TTestThinkersLightFlickerRules.DovrebbeDareQuantitaMultipleDiOttoInStrife;
var
  LIndex: Integer;
  LAmount: Integer;
begin
  for LIndex := 1 to 600 do
  begin
    LAmount := FStrife.NextAmount(FRandom);
    Assert.IsTrue(LAmount in [0, 8, 16, 24], 'amount ' + IntToStr(LAmount));
  end;
end;

procedure TTestThinkersLightFlickerRules.DovrebbeAspettareDaUnoAQuattroTicInStrife;
var
  LIndex: Integer;
  LCount: Integer;
begin
  for LIndex := 1 to 600 do
  begin
    LCount := FStrife.NextCount(FRandom);
    Assert.IsTrue((LCount >= 1) and (LCount <= 4), 'wait ' + IntToStr(LCount));
  end;
end;

procedure TTestThinkersLightFlickerRules.DovrebbeUsareDueNumeriCasualiPerCambioInStrife;
var
  LStart: Integer;
begin
  LStart := FRandom.PlayIndex;
  FStrife.NextAmount(FRandom);
  FStrife.NextCount(FRandom);
  Assert.AreEqual((LStart + 2) and 255, FRandom.PlayIndex);
end;

procedure TTestThinkersLightFlickerRules.DovrebbePartireDaDueTicInStrife;
begin
  Assert.AreEqual(2, FStrife.InitialCount);
end;

procedure TTestThinkersLightFlickerRules.DovrebbeScendereDiTrentaduePartendoDalLivelloDelSettoreInStrife;
begin
  // the lowest neighbor does not count in Strife
  Assert.AreEqual(160 - 32, FStrife.InitialMinLight(160, 10));
end;

procedure TTestThinkersLightFlickerRules.DovrebbeNonScendereSottoZeroInStrife;
begin
  Assert.AreEqual(0, FStrife.InitialMinLight(20, 0));
end;

procedure TTestThinkersLightFlickerRules.DovrebbeCrearePerOgniGiocoLeRegoleGiuste;
var
  LRules: ILightFlickerRules;
begin
  LRules := TLightFactory.CreateFlickerRules(TLightGame.Strife);
  Assert.AreEqual(2, LRules.InitialCount, 'Strife');
  LRules := TLightFactory.CreateFlickerRules(TLightGame.Doom);
  Assert.AreEqual(4, LRules.InitialCount, 'Doom');
  LRules := TLightFactory.CreateFlickerRules(TLightGame.Heretic);
  Assert.AreEqual(4, LRules.InitialCount, 'Heretic');
  LRules := TLightFactory.CreateFlickerRules(TLightGame.Hexen);
  Assert.AreEqual(4, LRules.InitialCount, 'Hexen');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightFlickerRules);

end.
