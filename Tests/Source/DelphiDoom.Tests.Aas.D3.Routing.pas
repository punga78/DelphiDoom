{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 AAS navigation - travel times and routes    }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.Routing;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3, DelphiDoom.MapFile.Aas.AasFile,
  DelphiDoom.Aas.D3.Intf;

type
  [TestFixture]
  [Category('AasD3')]
  TTestAasD3Routing = class
  strict private
    FNavigator: IAasMapNavigator;
    FLog: IInterface;
    procedure Use(const AName: string; const AMaxCacheMemory: Integer = 2 * 1024 * 1024);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareTempoZeroTraLaStessaArea;
    [Test]
    procedure DovrebbeTrovareUnPercorsoNelloStessoCluster;
    [Test]
    procedure DovrebbeTrovareUnPercorsoTraDueClusterAttraversandoUnPortale;
    [Test]
    procedure DovrebbeRifiutareAreeFuoriDalFile;
    [Test]
    procedure DovrebbeDareLeStesseRispostePocaMemoriaDiCache;
    [Test]
    procedure DovrebbeNonSuperareLaMemoriaDiCacheConsentita;
  end;

implementation

uses
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Reachability, DelphiDoom.Aas.D3.Types,
  DelphiDoom.Aas.D3.Factory, DelphiDoom.Aas.D3.Navigator, DelphiDoom.Tests.Aas.D3.Support;

const
  EVERYTHING = TFL_WALK or TFL_CROUCH or TFL_WALKOFFLEDGE or TFL_BARRIERJUMP or TFL_JUMP or TFL_LADDER or
    TFL_SWIM or TFL_WATERJUMP or TFL_TELEPORT or TFL_ELEVATOR or TFL_FLY or TFL_WATER or TFL_AIR;

{ TTestAasD3Routing }

procedure TTestAasD3Routing.Use(const AName: string; const AMaxCacheMemory: Integer);
var
  LLog: TD3FakeLog;
begin
  FNavigator := nil;
  LLog := TD3FakeLog.Create;
  FLog := LLog;
  FNavigator := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile(AName), True, LLog, AMaxCacheMemory);
end;

procedure TTestAasD3Routing.TearDown;
begin
  FNavigator := nil;
  FLog := nil;
end;

procedure TTestAasD3Routing.DovrebbeDareTempoZeroTraLaStessaArea;
var
  LTime: Integer;
  LReach: TAasReachability;
begin
  Use('aas_ring.aas');
  Assert.IsTrue(FNavigator.RouteToGoalArea(2, FNavigator.AreaCenter(2), 2, EVERYTHING, LTime, LReach));
  Assert.AreEqual(0, LTime);
  Assert.IsNull(LReach);
end;

procedure TTestAasD3Routing.DovrebbeTrovareUnPercorsoNelloStessoCluster;
var
  LTime: Integer;
  LReach: TAasReachability;
begin
  Use('aas_ring.aas');
  Assert.IsTrue(FNavigator.RouteToGoalArea(1, FNavigator.AreaCenter(1), 2, EVERYTHING, LTime, LReach));
  Assert.IsNotNull(LReach);
  Assert.AreEqual(2, Integer(LReach.ToAreaNum));
  Assert.IsTrue(LTime > 0);
end;

procedure TTestAasD3Routing.DovrebbeTrovareUnPercorsoTraDueClusterAttraversandoUnPortale;
var
  LTime: Integer;
  LReach: TAasReachability;
begin
  Use('aas_ring.aas');
  // area 1 is in the first cluster, area 5 in the second one, area 3 is the portal between them
  Assert.IsTrue(FNavigator.RouteToGoalArea(1, FNavigator.AreaCenter(1), 5, EVERYTHING, LTime, LReach));
  Assert.IsNotNull(LReach);
  Assert.IsTrue(LTime > 0);
end;

procedure TTestAasD3Routing.DovrebbeRifiutareAreeFuoriDalFile;
var
  LTime: Integer;
  LReach: TAasReachability;
  LLog: TD3FakeLog;
begin
  Use('aas_ring.aas');
  LLog := TD3FakeLog(FLog as TObject);
  Assert.IsFalse(FNavigator.RouteToGoalArea(0, FNavigator.AreaCenter(1), 2, EVERYTHING, LTime, LReach));
  Assert.IsFalse(FNavigator.RouteToGoalArea(1, FNavigator.AreaCenter(1), 99, EVERYTHING, LTime, LReach));
  Assert.AreEqual(2, LLog.Messages.Count);
end;

procedure TTestAasD3Routing.DovrebbeDareLeStesseRispostePocaMemoriaDiCache;
var
  LSmall: IAasMapNavigator;
  LFrom, LTo, LTimeBig, LTimeSmall: Integer;
  LReach: TAasReachability;
begin
  Use('aas_ring.aas');
  LSmall := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile('aas_ring.aas'), True, nil, 600);
  for LFrom := 1 to 12 do
    for LTo := 1 to 12 do
    begin
      Assert.AreEqual(
        FNavigator.RouteToGoalArea(LFrom, FNavigator.AreaCenter(LFrom), LTo, EVERYTHING, LTimeBig, LReach),
        LSmall.RouteToGoalArea(LFrom, LSmall.AreaCenter(LFrom), LTo, EVERYTHING, LTimeSmall, LReach),
        Format('%d -> %d', [LFrom, LTo]));
      Assert.AreEqual(LTimeBig, LTimeSmall, Format('%d -> %d', [LFrom, LTo]));
    end;
end;

procedure TTestAasD3Routing.DovrebbeNonSuperareLaMemoriaDiCacheConsentita;
var
  LSmall, LBig: IAasMapNavigator;
  LFrom, LTo, LTime, LSmallAreas, LSmallPortals, LBigAreas, LBigPortals: Integer;
  LReach: TAasReachability;
begin
  LSmall := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile('aas_grid.aas'), True, nil, 3000);
  LBig := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile('aas_grid.aas'), True, nil);
  for LFrom := 1 to 24 do
    for LTo := 1 to 24 do
    begin
      try
        LSmall.RouteToGoalArea(LFrom, LSmall.AreaCenter(LFrom), LTo, EVERYTHING, LTime, LReach);
      except
        on E: Exception do
          raise Exception.CreateFmt('small %d -> %d: %s', [LFrom, LTo, E.Message]);
      end;
      try
        LBig.RouteToGoalArea(LFrom, LBig.AreaCenter(LFrom), LTo, EVERYTHING, LTime, LReach);
      except
        on E: Exception do
          raise Exception.CreateFmt('big %d -> %d: %s', [LFrom, LTo, E.Message]);
      end;
    end;
  TAasNavigator(LSmall as TObject).CacheCounts(LSmallAreas, LSmallPortals);
  TAasNavigator(LBig as TObject).CacheCounts(LBigAreas, LBigPortals);
  // the oldest caches were dropped to stay near the limit, with the limit of 2 MB none was
  Assert.IsTrue(LSmallAreas + LSmallPortals < LBigAreas + LBigPortals);
  Assert.IsTrue(TAasNavigator(LSmall as TObject).CacheMemory < TAasNavigator(LBig as TObject).CacheMemory);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasD3Routing);

end.
