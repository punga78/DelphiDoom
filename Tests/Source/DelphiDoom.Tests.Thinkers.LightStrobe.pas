{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the strobe light                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightStrobe;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightStrobe = class(TObject)
  private
    FWorld: TFakeLightWorld;
    procedure CheckSameAsOldCode(AFastOrSlow, AInSync: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePrendereIValoriIniziali;
    [Test]
    procedure DovrebbeUsareIlMinimoZeroSeIVicinaSonoUgualiAlSettore;
    [Test]
    procedure DovrebbePartireSubitoSeInSincronia;
    [Test]
    procedure DovrebbeUsareUnNumeroCasualeSeNonInSincronia;
    [Test]
    procedure DovrebbeAspettareFinoAllaFineDelConteggio;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Types, DelphiDoom.Thinkers.Light.Strobe,
  DelphiDoom.Tests.Thinkers.OldLights;

{ TTestThinkersLightStrobe }

procedure TTestThinkersLightStrobe.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightStrobe.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestThinkersLightStrobe.DovrebbePrendereIValoriIniziali;
var
  LSector: TFakeLightSector;
  LMax, LMin, LDark, LBright, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(200, [80, 120]);
  TLightStrobe.Initialize(LSector, 35, True, CreateTestRandom(0), LMax, LMin, LDark, LBright, LCount);
  Assert.AreEqual(200, LMax);
  Assert.AreEqual(80, LMin);
  Assert.AreEqual(35, LDark);
  Assert.AreEqual(LIGHT_STROBE_BRIGHT_TICS, LBright);
end;

procedure TTestThinkersLightStrobe.DovrebbeUsareIlMinimoZeroSeIVicinaSonoUgualiAlSettore;
var
  LSector: TFakeLightSector;
  LMax, LMin, LDark, LBright, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(200, [200, 220]);
  TLightStrobe.Initialize(LSector, 15, True, CreateTestRandom(0), LMax, LMin, LDark, LBright, LCount);
  Assert.AreEqual(0, LMin);
end;

procedure TTestThinkersLightStrobe.DovrebbePartireSubitoSeInSincronia;
var
  LSector: TFakeLightSector;
  LRandom: IGameRandom;
  LMax, LMin, LDark, LBright, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(200, [80]);
  LRandom := CreateTestRandom(9);
  TLightStrobe.Initialize(LSector, 15, True, LRandom, LMax, LMin, LDark, LBright, LCount);
  Assert.AreEqual(1, LCount);
  Assert.AreEqual(9, LRandom.PlayIndex, 'no random number');
end;

procedure TTestThinkersLightStrobe.DovrebbeUsareUnNumeroCasualeSeNonInSincronia;
var
  LSector: TFakeLightSector;
  LRandom: IGameRandom;
  LMax, LMin, LDark, LBright, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(200, [80]);
  LRandom := CreateTestRandom(9);
  TLightStrobe.Initialize(LSector, 15, False, LRandom, LMax, LMin, LDark, LBright, LCount);
  Assert.AreEqual(10, LRandom.PlayIndex);
  Assert.IsTrue((LCount >= 1) and (LCount <= 8));
end;

procedure TTestThinkersLightStrobe.DovrebbeAspettareFinoAllaFineDelConteggio;
var
  LLevel: SmallInt;
  LCount: Integer;
begin
  LLevel := 200;
  LCount := 3;
  TLightStrobe.Tick(LCount, LLevel, 80, 200, 35, 5);
  Assert.AreEqual(2, LCount);
  Assert.AreEqual(200, Integer(LLevel));
end;

procedure TTestThinkersLightStrobe.CheckSameAsOldCode(AFastOrSlow, AInSync: Integer);
var
  LSeed, LTic: Integer;
  LOldSector, LNewSector: TFakeLightSector;
  LOld: TOldStrobe;
  LOldRandom, LNewRandom: IGameRandom;
  LMax, LMin, LDark, LBright, LCount: Integer;
begin
  for LSeed := 0 to 5 do
  begin
    LOldSector := FWorld.AddWithNeighbors(180, [60 + LSeed * 10, NO_NEIGHBOR, 150]);
    LNewSector := FWorld.AddWithNeighbors(180, [60 + LSeed * 10, NO_NEIGHBOR, 150]);
    LOldRandom := CreateTestRandom(LSeed * 41);
    LNewRandom := CreateTestRandom(LSeed * 41);
    OldSpawnStrobe(LOld, LOldSector, AFastOrSlow, AInSync, LOldRandom);
    TLightStrobe.Initialize(LNewSector, AFastOrSlow, AInSync <> 0, LNewRandom, LMax, LMin, LDark,
      LBright, LCount);
    Assert.AreEqual(LOld.Count, LCount, 'first wait');
    for LTic := 1 to 3000 do
    begin
      OldTickStrobe(LOld);
      TLightStrobe.Tick(LCount, LNewSector.Level, LMin, LMax, LDark, LBright);
      Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), Format('level at tic %d', [LTic]));
      Assert.AreEqual(LOld.Count, LCount, Format('count at tic %d', [LTic]));
    end;
    Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, 'random');
  end;
end;

procedure TTestThinkersLightStrobe.DovrebbeDareGliStessiLivelliDelVecchioCodice;
begin
  CheckSameAsOldCode(35, 0);
  CheckSameAsOldCode(15, 0);
  CheckSameAsOldCode(15, 1);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightStrobe);

end.
