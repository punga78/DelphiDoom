{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 AAS navigation - the parts, the files that  }
{  cannot be routed on and the navigator without a file                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.Units;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.Aas.D3.Intf;

type
  [TestFixture]
  [Category('AasD3')]
  TTestAasD3TravelTime = class
  public
    [Test]
    procedure DovrebbeScalareLaDistanzaSecondoLArea;
    [Test]
    procedure DovrebbeDareAlmenoUno;
    [Test]
    procedure DovrebbeTroncareAiSedicibit;
  end;

  [TestFixture]
  [Category('AasD3')]
  TTestAasD3Files = class
  strict private
    FFile: TAasFile;
    FLog: IInterface;
    procedure Load;
    procedure ExpectRejected(const AMessagePart: string);
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaRaggiungibilitaVersoUnAreaCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnClusterCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnaRaggiungibilitaDaUnAreaSenzaBandiere;
    [Test]
    procedure DovrebbeRifiutareUnPortaleFuoriDalFile;
    [Test]
    procedure DovrebbeRifiutareUnaFacciaCheRimandaAdUnoSpigoloCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnClusterConPortaliFuoriDallIndice;
    [Test]
    procedure DovrebbeRifiutareTroppeRaggiungibilitaInUnArea;
  end;

  [TestFixture]
  [Category('AasD3')]
  TTestAasD3Navigator = class
  strict private
    FNavigator: IAasMapNavigator;
    FLog: TObject;
    FLogIntf: IInterface;
    procedure UseEmpty;
    procedure UseRing;
  public
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRispondereComeIdAasLocalSenzaFile;
    [Test]
    procedure DovrebbeDareUnPercorsoDirittoSenzaFile;
    [Test]
    procedure DovrebbeNonCaricareUnaMappaSenzaLettore;
    [Test]
    procedure DovrebbeTenereIlFileSeLaMappaELoStessoCrc;
    [Test]
    procedure DovrebbeSostituireIlFileSeIlCrcCambia;
    [Test]
    procedure DovrebbeLeggereIlCentroELeBandiereDelleAree;
    [Test]
    procedure DovrebbeRifiutareUnAreaCheNonEsiste;
    [Test]
    procedure DovrebbeDareIPianiEGliSpigoli;
    [Test]
    procedure DovrebbeTrovareLAreaDiUnPunto;
    [Test]
    procedure DovrebbeSpingereUnPuntoNellArea;
    [Test]
    procedure DovrebbeRifiutareUnPianoCheNonEsiste;
    [Test]
    procedure DovrebbeFermareLaTracciaFuoriDalMondo;
    [Test]
    procedure DovrebbeDareLeImpostazioniDelFile;
    [Test]
    procedure DovrebbeNonTrovareUnObiettivoSeLAreaEZero;
    [Test]
    procedure DovrebbeTrovareLAreaCheLaProvaAccetta;
    [Test]
    procedure DovrebbeContareLeCache;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area,
  DelphiDoom.MapFile.Aas.Intf, DelphiDoom.MapFile.Aas.Trace, DelphiDoom.MapFile.Aas.Reachability,
  DelphiDoom.Geometry.Plane, DelphiDoom.Aas.D3.Types,
  DelphiDoom.Aas.D3.TravelTime, DelphiDoom.Aas.D3.Factory, DelphiDoom.Aas.D3.Navigator,
  DelphiDoom.Tests.Aas.D3.Support;

const
  EVERYTHING = TFL_WALK or TFL_CROUCH or TFL_WALKOFFLEDGE or TFL_BARRIERJUMP or TFL_JUMP or TFL_LADDER or
    TFL_SWIM or TFL_WATERJUMP or TFL_TELEPORT or TFL_ELEVATOR or TFL_FLY or TFL_WATER or TFL_AIR;

{ TTestAasD3TravelTime }

procedure TTestAasD3TravelTime.DovrebbeScalareLaDistanzaSecondoLArea;
var
  LStart, LEnd: TGeoVec3;
begin
  LStart := TGeoVec3.Make(0, 0, 0);
  LEnd := TGeoVec3.Make(300, 0, 0);
  // 100 / 300 per unit when walking, 100 / 150 in water and 100 / 100 when crouching
  Assert.AreEqual<Integer>(100, TAasTravelTime.Calculate(TFL_AIR, LStart, LEnd));
  Assert.AreEqual<Integer>(200, TAasTravelTime.Calculate(TFL_WATER, LStart, LEnd));
  Assert.AreEqual<Integer>(300, TAasTravelTime.Calculate(TFL_CROUCH, LStart, LEnd));
  // crouching comes first when both are set
  Assert.AreEqual<Integer>(300, TAasTravelTime.Calculate(TFL_CROUCH or TFL_WATER, LStart, LEnd));
end;

procedure TTestAasD3TravelTime.DovrebbeDareAlmenoUno;
begin
  Assert.AreEqual<Integer>(1, TAasTravelTime.Calculate(TFL_AIR, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(0, 0, 0)));
  Assert.AreEqual<Integer>(1, TAasTravelTime.Calculate(TFL_AIR, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(2, 0, 0)));
end;

procedure TTestAasD3TravelTime.DovrebbeTroncareAiSedicibit;
begin
  // 100 000 units walking: 33 333; 100 000 000 units: 33 333 334 (the factor is the float 0.33333334) which wraps
  // as the unsigned short of the original
  Assert.AreEqual<Integer>(33333, TAasTravelTime.Calculate(TFL_AIR, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(100000, 0, 0)));
  Assert.AreEqual<Integer>(33333334 and $FFFF,
    TAasTravelTime.Calculate(TFL_AIR, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(100000000, 0, 0)));
end;

{ TTestAasD3Files }

procedure TTestAasD3Files.Load;
begin
  FreeAndNil(FFile);
  FFile := D3LoadFile('aas_ring.aas', 2882400109);
end;

procedure TTestAasD3Files.TearDown;
begin
  FreeAndNil(FFile);
  FLog := nil;
end;

procedure TTestAasD3Files.ExpectRejected(const AMessagePart: string);
var
  LRaised: Boolean;
  LMessage: string;
begin
  LRaised := False;
  LMessage := '';
  try
    // the navigator takes the file: it is not freed here when it is rejected (AOwnsFile False)
    TAasNavigationFactory.CreateNavigatorForFile(FFile, False);
  except
    on E: EAasRoutingException do
    begin
      LRaised := True;
      LMessage := E.Message;
    end;
  end;
  Assert.IsTrue(LRaised, 'EAasRoutingException expected');
  Assert.IsTrue(Pos(AMessagePart, LMessage) > 0, LMessage);
end;

procedure TTestAasD3Files.DovrebbeRifiutareUnaRaggiungibilitaVersoUnAreaCheNonEsiste;
begin
  Load;
  FFile.Areas[2].Reach[0].ToAreaNum := 99;
  ExpectRejected('does not hold');
end;

procedure TTestAasD3Files.DovrebbeRifiutareUnClusterCheNonEsiste;
begin
  Load;
  FFile.Areas[2].Cluster := 7;
  ExpectRejected('cluster 7');
end;

procedure TTestAasD3Files.DovrebbeRifiutareUnaRaggiungibilitaDaUnAreaSenzaBandiere;
begin
  Load;
  FFile.Areas[2].Flags := AREA_FLOOR;
  ExpectRejected('neither');
end;

procedure TTestAasD3Files.DovrebbeRifiutareUnPortaleFuoriDalFile;
var
  LPortals: TArray<TAasPortal>;
begin
  Load;
  LPortals := FFile.Portals;
  LPortals[1].AreaNum := 99;
  ExpectRejected('portal 1');
end;

procedure TTestAasD3Files.DovrebbeRifiutareUnaFacciaCheRimandaAdUnoSpigoloCheNonEsiste;
var
  LEdgeIndex: TArray<Integer>;
begin
  Load;
  LEdgeIndex := FFile.EdgeIndex;
  LEdgeIndex[1] := 500;
  ExpectRejected('edge');
end;

procedure TTestAasD3Files.DovrebbeRifiutareUnClusterConPortaliFuoriDallIndice;
var
  LClusters: TArray<TAasCluster>;
begin
  Load;
  LClusters := FFile.Clusters;
  LClusters[1].NumPortals := 99;
  ExpectRejected('cluster 1');
end;

procedure TTestAasD3Files.DovrebbeRifiutareTroppeRaggiungibilitaInUnArea;
var
  LIndex: Integer;
  LReach: TAasReachability;
begin
  Load;
  for LIndex := 1 to MAX_REACH_PER_AREA do
  begin
    LReach := TAasReachability.Create;
    LReach.TravelType := TFL_WALK;
    LReach.ToAreaNum := 3;
    LReach.FromAreaNum := 2;
    FFile.Areas[2].Reach.Add(LReach);
  end;
  ExpectRejected('more than');
end;

{ TTestAasD3Navigator }

procedure TTestAasD3Navigator.UseEmpty;
var
  LLog: TD3FakeLog;
begin
  LLog := TD3FakeLog.Create;
  FLogIntf := LLog;
  FLog := LLog;
  FNavigator := TAasNavigationFactory.CreateNavigator(nil, LLog);
end;

procedure TTestAasD3Navigator.UseRing;
var
  LLog: TD3FakeLog;
begin
  LLog := TD3FakeLog.Create;
  FLogIntf := LLog;
  FLog := LLog;
  FNavigator := TAasNavigationFactory.CreateNavigatorForFile(D3LoadFile('aas_ring.aas', 2882400109), True, LLog);
end;

procedure TTestAasD3Navigator.TearDown;
begin
  FNavigator := nil;
  FLogIntf := nil;
  FLog := nil;
end;

procedure TTestAasD3Navigator.DovrebbeRispondereComeIdAasLocalSenzaFile;
var
  LTrace: TAasTrace;
  LStart, LEnd: TGeoVec3;
  LPlane: TGeoPlane;
  LEdges: TArray<Integer>;
  LTime, LVertex0, LVertex1, LCount: Integer;
  LReach: TAasReachability;
  LPoint: TGeoVec3;
begin
  UseEmpty;
  LPoint := TGeoVec3.Make(1, 2, 3);
  Assert.IsNull(FNavigator.GetSettings);
  Assert.AreEqual<Integer>(0, FNavigator.PointAreaNum(LPoint));
  Assert.AreEqual<Integer>(0, FNavigator.PointReachableAreaNum(LPoint, TGeoBounds.Make(LPoint, LPoint), 0));
  Assert.AreEqual<Integer>(0, FNavigator.BoundsReachableAreaNum(TGeoBounds.Make(LPoint, LPoint), 0));
  FNavigator.PushPointIntoAreaNum(1, LPoint);
  Assert.AreEqual<Single>(1, LPoint.X);
  Assert.IsTrue(FNavigator.AreaCenter(1).Compare(TGeoVec3.Origin));
  Assert.AreEqual<Integer>(0, FNavigator.AreaFlags(1));
  Assert.AreEqual<Integer>(0, FNavigator.AreaTravelFlags(1));
  LTrace := TAasTrace.Init;
  LTrace.Fraction := 5;
  Assert.IsTrue(FNavigator.Trace(LTrace, LPoint, LPoint));
  Assert.AreEqual<Single>(0, LTrace.Fraction);
  LPlane := FNavigator.GetPlane(3);
  Assert.AreEqual<Single>(0, LPlane.A);
  Assert.AreEqual<Integer>(0, FNavigator.GetWallEdges(1, TGeoBounds.Make(LPoint, LPoint), EVERYTHING, LEdges, 4));
  FNavigator.SortWallEdges(LEdges, 0);
  FNavigator.GetEdgeVertexNumbers(1, LVertex0, LVertex1);
  Assert.AreEqual<Integer>(0, LVertex0 + LVertex1);
  FNavigator.GetEdge(1, LStart, LEnd);
  Assert.IsTrue(LStart.Compare(TGeoVec3.Origin) and LEnd.Compare(TGeoVec3.Origin));
  Assert.IsFalse(FNavigator.SetAreaState(TGeoBounds.Make(LPoint, LPoint), 4, True));
  Assert.AreEqual<Integer>(-1, FNavigator.AddObstacle(TGeoBounds.Make(LPoint, LPoint)));
  FNavigator.RemoveObstacle(0);
  FNavigator.RemoveAllObstacles;
  Assert.AreEqual<Integer>(0, FNavigator.TravelTimeToGoalArea(1, LPoint, 2, EVERYTHING));
  Assert.IsFalse(FNavigator.RouteToGoalArea(1, LPoint, 2, EVERYTHING, LTime, LReach));
  LCount := 0;
  Assert.AreEqual<Integer>(0, LCount);
end;

procedure TTestAasD3Navigator.DovrebbeDareUnPercorsoDirittoSenzaFile;
var
  LPath: TAasPath;
  LEndPos, LOrigin, LGoal: TGeoVec3;
  LEndArea: Integer;
  LObstacles: TArray<TAasObstacle>;
  LGoalFound: TAasGoal;
begin
  UseEmpty;
  LOrigin := TGeoVec3.Make(1, 2, 3);
  LGoal := TGeoVec3.Make(10, 20, 30);
  Assert.IsTrue(FNavigator.WalkPathToGoal(LPath, 4, LOrigin, 9, LGoal, EVERYTHING));
  Assert.IsTrue(LPath.MoveGoal.Compare(LGoal));
  Assert.AreEqual<Integer>(4, LPath.MoveAreaNum);
  Assert.IsTrue(FNavigator.FlyPathToGoal(LPath, 4, LOrigin, 9, LGoal, EVERYTHING));
  Assert.IsTrue(LPath.MoveGoal.Compare(LGoal));
  Assert.IsTrue(FNavigator.WalkPathValid(4, LOrigin, 9, LGoal, EVERYTHING, LEndPos, LEndArea));
  Assert.IsTrue(LEndPos.Compare(LGoal));
  Assert.AreEqual<Integer>(0, LEndArea);
  Assert.IsTrue(FNavigator.FlyPathValid(4, LOrigin, 9, LGoal, EVERYTHING, LEndPos, LEndArea));
  SetLength(LObstacles, 0);
  Assert.IsFalse(FNavigator.FindNearestGoal(LGoalFound, 4, LOrigin, LGoal, EVERYTHING, LObstacles,
    TD3ModuloCallback.Create(2, 0)));
  Assert.AreEqual<Integer>(4, LGoalFound.AreaNum);
end;

procedure TTestAasD3Navigator.DovrebbeNonCaricareUnaMappaSenzaLettore;
begin
  UseEmpty;
  Assert.IsFalse(FNavigator.Init('aas_ring.aas', 1));
  Assert.IsTrue(TD3FakeLog(FLog).Messages.Count >= 1);
end;

procedure TTestAasD3Navigator.DovrebbeTenereIlFileSeLaMappaELoStessoCrc;
var
  LHandle: Integer;
begin
  UseRing;
  // the file was read with the CRC 2882400109 and the name aas_ring.aas
  Assert.IsTrue(FNavigator.Init('AAS_RING.AAS', 2882400109));
  Assert.AreEqual<Integer>(1, TD3FakeLog(FLog).Messages.Count);
  Assert.IsTrue(Pos('Keeping', TD3FakeLog(FLog).Messages[0]) > 0);
  Assert.IsTrue(FNavigator.PointAreaNum(TGeoVec3.Make(32, 32, 32)) > 0);
  LHandle := FNavigator.AddObstacle(TGeoBounds.Make(TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 10, 10)));
  Assert.AreEqual<Integer>(0, LHandle);
end;

procedure TTestAasD3Navigator.DovrebbeSostituireIlFileSeIlCrcCambia;
begin
  UseRing;
  // no reader: the map cannot be loaded, and the file that was there is gone
  Assert.IsFalse(FNavigator.Init('aas_ring.aas', 5));
  Assert.IsNull(FNavigator.GetSettings);
  Assert.AreEqual<Integer>(0, FNavigator.PointAreaNum(TGeoVec3.Make(32, 32, 32)));
end;

procedure TTestAasD3Navigator.DovrebbeLeggereIlCentroELeBandiereDelleAree;
begin
  UseRing;
  Assert.IsTrue(FNavigator.AreaFlags(1) and AREA_FLOOR <> 0);
  Assert.IsTrue(FNavigator.AreaTravelFlags(1) <> 0);
  Assert.AreEqual<Single>(32, FNavigator.AreaCenter(1).X);
  Assert.AreEqual<Single>(32, FNavigator.AreaCenter(1).Y);
end;

procedure TTestAasD3Navigator.DovrebbeRifiutareUnAreaCheNonEsiste;
begin
  UseRing;
  Assert.WillRaise(
    procedure
    begin
      FNavigator.AreaCenter(99);
    end, EAasRoutingException);
  Assert.WillRaise(
    procedure
    begin
      FNavigator.AreaFlags(-1);
    end, EAasRoutingException);
  Assert.WillRaise(
    procedure
    begin
      FNavigator.AreaTravelFlags(13);
    end, EAasRoutingException);
end;

procedure TTestAasD3Navigator.DovrebbeDareIPianiEGliSpigoli;
var
  LStart, LEnd: TGeoVec3;
  LVertex0, LVertex1: Integer;
begin
  UseRing;
  Assert.AreEqual<Single>(1, Abs(FNavigator.GetPlane(2).A));
  FNavigator.GetEdgeVertexNumbers(2, LVertex0, LVertex1);
  FNavigator.GetEdge(2, LStart, LEnd);
  // a negative number is the edge the other way round
  FNavigator.GetEdgeVertexNumbers(-2, LVertex0, LVertex1);
  Assert.AreNotEqual<Integer>(0, LVertex0 + LVertex1);
end;

procedure TTestAasD3Navigator.DovrebbeTrovareLAreaDiUnPunto;
begin
  UseRing;
  Assert.AreEqual<Integer>(1, FNavigator.PointAreaNum(TGeoVec3.Make(32, 32, 32)));
  Assert.AreEqual<Integer>(2, FNavigator.PointAreaNum(TGeoVec3.Make(96, 32, 32)));
  Assert.AreEqual<Integer>(0, FNavigator.PointAreaNum(TGeoVec3.Make(1000, 32, 32)));
  Assert.AreEqual<Integer>(1, FNavigator.PointReachableAreaNum(TGeoVec3.Make(32, 32, 32),
    TGeoBounds.Make(TGeoVec3.Make(-8, -8, -8), TGeoVec3.Make(8, 8, 8)), AREA_REACHABLE_WALK));
  Assert.AreEqual<Integer>(1, FNavigator.BoundsReachableAreaNum(TGeoBounds.Make(TGeoVec3.Make(20, 20, 20),
    TGeoVec3.Make(40, 40, 40)), AREA_REACHABLE_WALK));
end;

procedure TTestAasD3Navigator.DovrebbeSpingereUnPuntoNellArea;
var
  LPoint: TGeoVec3;
begin
  UseRing;
  LPoint := TGeoVec3.Make(-20, 32, 32);
  FNavigator.PushPointIntoAreaNum(1, LPoint);
  Assert.IsTrue(LPoint.X >= 0);
end;

procedure TTestAasD3Navigator.DovrebbeRifiutareUnPianoCheNonEsiste;
begin
  UseRing;
  Assert.WillRaise(
    procedure
    begin
      FNavigator.GetPlane(9999);
    end, EAasRoutingException);
end;

procedure TTestAasD3Navigator.DovrebbeFermareLaTracciaFuoriDalMondo;
var
  LTrace: TAasTrace;
begin
  UseRing;
  LTrace := TAasTrace.Init;
  Assert.IsTrue(FNavigator.Trace(LTrace, TGeoVec3.Make(32, 32, 32), TGeoVec3.Make(32, 32, -500)));
  Assert.IsTrue(LTrace.Fraction < 1);
end;

procedure TTestAasD3Navigator.DovrebbeDareLeImpostazioniDelFile;
begin
  UseRing;
  Assert.IsNotNull(FNavigator.GetSettings);
  Assert.AreEqual<Integer>(2, FNavigator.GetSettings.NumBoundingBoxes);
end;

procedure TTestAasD3Navigator.DovrebbeNonTrovareUnObiettivoSeLAreaEZero;
var
  LObstacles: TArray<TAasObstacle>;
  LGoal: TAasGoal;
begin
  UseRing;
  SetLength(LObstacles, 0);
  LGoal.AreaNum := -3;
  Assert.IsFalse(FNavigator.FindNearestGoal(LGoal, 0, TGeoVec3.Make(1, 1, 1), TGeoVec3.Make(2, 2, 2), EVERYTHING,
    LObstacles, TD3ModuloCallback.Create(2, 0)));
  Assert.AreEqual<Integer>(0, LGoal.AreaNum);
end;

procedure TTestAasD3Navigator.DovrebbeTrovareLAreaCheLaProvaAccetta;
var
  LObstacles: TArray<TAasObstacle>;
  LGoal: TAasGoal;
  LCallback: TD3ModuloCallback;
  LCallbackIntf: IAasAreaCallback;
begin
  UseRing;
  SetLength(LObstacles, 0);
  // 7 * 2 mod 7 = 0: only the areas whose number is a multiple of 7 are accepted
  LCallback := TD3ModuloCallback.Create(7, 0);
  LCallbackIntf := LCallback;
  Assert.IsTrue(FNavigator.FindNearestGoal(LGoal, 1, FNavigator.AreaCenter(1), FNavigator.AreaCenter(12), EVERYTHING,
    LObstacles, LCallbackIntf));
  Assert.IsTrue(LGoal.AreaNum > 0);
  Assert.IsTrue(LCallback.Asked >= 1);
end;

procedure TTestAasD3Navigator.DovrebbeContareLeCache;
var
  LAreas, LPortals, LTime: Integer;
  LReach: TAasReachability;
begin
  UseRing;
  TAasNavigator(FNavigator as TObject).CacheCounts(LAreas, LPortals);
  Assert.AreEqual<Integer>(0, LAreas + LPortals);
  Assert.AreEqual<Integer>(0, TAasNavigator(FNavigator as TObject).CacheMemory);
  FNavigator.RouteToGoalArea(1, FNavigator.AreaCenter(1), 5, EVERYTHING, LTime, LReach);
  TAasNavigator(FNavigator as TObject).CacheCounts(LAreas, LPortals);
  Assert.IsTrue(LAreas > 0);
  Assert.IsTrue(LPortals > 0);
  Assert.IsTrue(TAasNavigator(FNavigator as TObject).CacheMemory > 0);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasD3TravelTime);
  TDUnitX.RegisterTestFixture(TTestAasD3Files);
  TDUnitX.RegisterTestFixture(TTestAasD3Navigator);

end.
