{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the broken light (random flashing)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightFlash;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightFlash = class(TObject)
  private
    FWorld: TFakeLightWorld;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePrendereIValoriIniziali;
    [Test]
    procedure DovrebbeUsareUnNumeroCasualeNellaPartenza;
    [Test]
    procedure DovrebbeAspettareFinoAllaFineDelConteggio;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.Thinkers.Light.Flash, DelphiDoom.Tests.Thinkers.OldLights;

{ TTestThinkersLightFlash }

procedure TTestThinkersLightFlash.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightFlash.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestThinkersLightFlash.DovrebbePrendereIValoriIniziali;
var
  LSector: TFakeLightSector;
  LMax, LMin, LMaxTime, LMinTime, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(176, [96, 128]);
  TLightFlash.Initialize(LSector, CreateTestRandom(0), LMax, LMin, LMaxTime, LMinTime, LCount);
  Assert.AreEqual(176, LMax);
  Assert.AreEqual(96, LMin);
  Assert.AreEqual(64, LMaxTime);
  Assert.AreEqual(7, LMinTime);
  Assert.IsTrue((LCount >= 1) and (LCount <= 65), 'count');
end;

procedure TTestThinkersLightFlash.DovrebbeUsareUnNumeroCasualeNellaPartenza;
var
  LSector: TFakeLightSector;
  LRandom: IGameRandom;
  LMax, LMin, LMaxTime, LMinTime, LCount: Integer;
begin
  LSector := FWorld.AddWithNeighbors(176, [96]);
  LRandom := CreateTestRandom(20);
  TLightFlash.Initialize(LSector, LRandom, LMax, LMin, LMaxTime, LMinTime, LCount);
  Assert.AreEqual(21, LRandom.PlayIndex);
end;

procedure TTestThinkersLightFlash.DovrebbeAspettareFinoAllaFineDelConteggio;
var
  LLevel: SmallInt;
  LCount: Integer;
  LRandom: IGameRandom;
begin
  LRandom := CreateTestRandom(5);
  LLevel := 100;
  LCount := 2;
  TLightFlash.Tick(LCount, LLevel, 100, 50, 64, 7, LRandom);
  Assert.AreEqual(1, LCount);
  Assert.AreEqual(100, Integer(LLevel));
  Assert.AreEqual(5, LRandom.PlayIndex);
end;

procedure TTestThinkersLightFlash.DovrebbeDareGliStessiLivelliDelVecchioCodice;
var
  LSeed, LTic: Integer;
  LOldSector, LNewSector: TFakeLightSector;
  LOld: TOldLightFlash;
  LOldRandom, LNewRandom: IGameRandom;
  LMax, LMin, LMaxTime, LMinTime, LCount: Integer;
begin
  for LSeed := 0 to 7 do
  begin
    LOldSector := FWorld.AddWithNeighbors(150 + LSeed, [90, NO_NEIGHBOR, 120]);
    LNewSector := FWorld.AddWithNeighbors(150 + LSeed, [90, NO_NEIGHBOR, 120]);
    LOldRandom := CreateTestRandom(LSeed * 33);
    LNewRandom := CreateTestRandom(LSeed * 33);
    OldSpawnLightFlash(LOld, LOldSector, LOldRandom);
    TLightFlash.Initialize(LNewSector, LNewRandom, LMax, LMin, LMaxTime, LMinTime, LCount);
    Assert.AreEqual(LOld.Count, LCount, 'first wait');
    for LTic := 1 to 4000 do
    begin
      OldTickLightFlash(LOld, LOldRandom);
      TLightFlash.Tick(LCount, LNewSector.Level, LMax, LMin, LMaxTime, LMinTime, LNewRandom);
      Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), Format('level at tic %d', [LTic]));
      Assert.AreEqual(LOld.Count, LCount, Format('count at tic %d', [LTic]));
      Assert.AreEqual(LOldRandom.PlayIndex, LNewRandom.PlayIndex, Format('random at tic %d', [LTic]));
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightFlash);

end.
