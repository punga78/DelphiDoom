{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the glowing light                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LightGlow;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Tests.Thinkers.Fakes;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLightGlow = class(TObject)
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
    procedure DovrebbeScendereEPoiSalireTraIDueLimiti;
    [Test]
    procedure DovrebbeDareGliStessiLivelliDelVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Thinkers.Light.Glow, DelphiDoom.Tests.Thinkers.OldLights;

{ TTestThinkersLightGlow }

procedure TTestThinkersLightGlow.Setup;
begin
  FWorld := TFakeLightWorld.Create;
end;

procedure TTestThinkersLightGlow.TearDown;
begin
  FreeAndNil(FWorld);
end;

procedure TTestThinkersLightGlow.DovrebbePrendereIValoriIniziali;
var
  LSector: TFakeLightSector;
  LMin, LMax, LDirection: Integer;
begin
  LSector := FWorld.AddWithNeighbors(200, [90, 140]);
  TLightGlow.Initialize(LSector, LMin, LMax, LDirection);
  Assert.AreEqual(90, LMin);
  Assert.AreEqual(200, LMax);
  Assert.AreEqual(-1, LDirection);
end;

procedure TTestThinkersLightGlow.DovrebbeScendereEPoiSalireTraIDueLimiti;
var
  LLevel: SmallInt;
  LDirection, LTic, LDown, LUp: Integer;
begin
  LLevel := 100;
  LDirection := -1;
  LDown := 0;
  LUp := 0;
  for LTic := 1 to 200 do
  begin
    TLightGlow.Tick(LLevel, 60, 100, LDirection);
    Assert.IsTrue((LLevel > 52) and (LLevel <= 100), 'level ' + IntToStr(LLevel));
    if LDirection = -1 then
      Inc(LDown)
    else
      Inc(LUp);
  end;
  Assert.IsTrue((LDown > 0) and (LUp > 0), 'it went in both directions');
end;

procedure TTestThinkersLightGlow.DovrebbeDareGliStessiLivelliDelVecchioCodice;
var
  LStart, LTic: Integer;
  LOldSector, LNewSector: TFakeLightSector;
  LOld: TOldGlow;
  LMin, LMax, LDirection: Integer;
begin
  for LStart := 0 to 5 do
  begin
    LOldSector := FWorld.AddWithNeighbors(100 + LStart * 20, [40, NO_NEIGHBOR, 70]);
    LNewSector := FWorld.AddWithNeighbors(100 + LStart * 20, [40, NO_NEIGHBOR, 70]);
    OldSpawnGlow(LOld, LOldSector);
    TLightGlow.Initialize(LNewSector, LMin, LMax, LDirection);
    for LTic := 1 to 3000 do
    begin
      OldTickGlow(LOld);
      TLightGlow.Tick(LNewSector.Level, LMin, LMax, LDirection);
      Assert.AreEqual(Integer(LOldSector.Level), Integer(LNewSector.Level), Format('level at tic %d', [LTic]));
      Assert.AreEqual(LOld.Direction, LDirection, Format('direction at tic %d', [LTic]));
    end;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLightGlow);

end.
