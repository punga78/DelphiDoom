{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the routing of Quake III on a world  }
{  of three areas in a row, built here                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Route.Units;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf,
  DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Intf, DelphiDoom.Tests.Aas.Support;

type
  [TestFixture]
  [Category('Aas')]
  TTestAasRoute = class
  strict private
    FFile: IAasFile;
    FImport: TFakeImport;
    FImportIntf: IBotImport;
    FRouter: IAasRouter;
    function BuildData: TAasFileData;
    procedure Use(const AData: TAasFileData; const ADeveloper: Boolean = True);
    procedure ExpectRejected(const AData: TAasFileData);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareIlTempoEDLaPrimaRaggiungibilita;
    [Test]
    procedure DovrebbeDareTempoUnoPerLaStessaArea;
    [Test]
    procedure DovrebbeDareIlTempoPerAttraversareUnArea;
    [Test]
    procedure DovrebbeScegliereUnAreaCasualeDoveSiNuota;
    [Test]
    procedure DovrebbeNonTrovareUnAreaCasualeSenzaTerrenoNeRaggiungibilita;
    [Test]
    procedure DovrebbeNonContareIlTempoDentroLAreaSenzaOrigine;
    [Test]
    procedure DovrebbeRifiutareAreeFuoriDalFileSoloInModoSviluppatore;
    [Test]
    procedure DovrebbeNonEntrareInUnAreaDisabilitata;
    [Test]
    procedure DovrebbeLeggereELeggereLoStatoDiUnAreaDiRouting;
    [Test]
    procedure DovrebbeEvitareUnTipoDiMovimentoNonPermesso;
    [Test]
    procedure DovrebbePredireLaStradaFinoAlLaMeta;
    [Test]
    procedure DovrebbeFermareLaPrevisioneSuUnEvento;
    [Test]
    procedure DovrebbeFermareLaPrevisioneSenzaStrada;
    [Test]
    procedure DovrebbeDareLeBandiereDeiTipiDiMovimento;
    [Test]
    procedure DovrebbeDareLeBandiereDelContenutoDelleAree;
    [Test]
    procedure DovrebbeCopiareUnaRaggiungibilita;
    [Test]
    procedure DovrebbePassareAllaRaggiungibilitaSuccessiva;
    [Test]
    procedure DovrebbeTrovareLeRaggiungibilitaDiUnModello;
    [Test]
    procedure DovrebbeTrovareLAreaPiuVicinaDoveNascondersi;
    [Test]
    procedure DovrebbeDareMenoDiZeroObiettiviSenzaSpazio;
    [Test]
    procedure DovrebbeRifiutareUnaRaggiungibilitaVersoUnAreaCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnClusterCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnPortaleFuoriDalFile;
    [Test]
    procedure DovrebbeContareLeCacheEGliAggiornamenti;
    [Test]
    procedure DovrebbeFalliSeLaMemoriaEFinita;
  end;

implementation

uses
  DelphiDoom.Aas.Route.RandomGoal, DelphiDoom.Aas.Reach.Factory, DelphiDoom.BotAi.Types, DelphiDoom.Aas.AasFile, DelphiDoom.Aas.Factory, DelphiDoom.Aas.Route.Types, DelphiDoom.Aas.Route.Router;

type
  TNoMemory = class(TInterfacedObject, IAasRoutingMemory)
  public
    FCalls: Integer;
    function AvailableMemory: Integer;
  end;

function TNoMemory.AvailableMemory: Integer;
begin
  Inc(FCalls);
  Result := 0;
end;

function ReachPoint(const AX: Single): TVec3;
begin
  Result[0] := AX;
  Result[1] := 32;
  Result[2] := 0;
end;

procedure SetReach(var AReach: TAasReachability; const AArea, AType: Integer; const AStart, AEnd: Single;
  const ATime: Integer);
begin
  AReach.AreaNum := AArea;
  AReach.TravelType := AType;
  AReach.StartPoint := ReachPoint(AStart);
  AReach.EndPoint := ReachPoint(AEnd);
  AReach.TravelTime := ATime;
end;

{ TTestAasRoute }

function TTestAasRoute.BuildData: TAasFileData;
var
  LIndex: Integer;
begin
  // three areas in a row, 64 units each, one cluster; reachabilities: 1 -> 2, 2 -> 1, 2 -> 3, 3 -> 2 (number 0 is the dummy)
  FillChar(Result, SizeOf(Result), 0);
  SetLength(Result.Areas, 4);
  SetLength(Result.AreaSettings, 4);
  SetLength(Result.Reachability, 5);
  SetLength(Result.Clusters, 2);
  SetLength(Result.Portals, 1);
  SetLength(Result.PortalIndex, 1);
  SetLength(Result.Faces, 3);
  SetLength(Result.FaceIndex, 5);
  for LIndex := 1 to 3 do
  begin
    Result.Areas[LIndex].AreaNum := LIndex;
    Result.Areas[LIndex].Center := ReachPoint(LIndex * 64 - 32);
    Result.AreaSettings[LIndex].PresenceType := PRESENCE_NORMAL or PRESENCE_CROUCH;
    Result.AreaSettings[LIndex].Cluster := 1;
    Result.AreaSettings[LIndex].ClusterAreaNum := LIndex - 1;
  end;
  SetReach(Result.Reachability[1], 2, TRAVEL_WALK, 60, 68, 20);
  SetReach(Result.Reachability[2], 1, TRAVEL_WALK, 68, 60, 20);
  SetReach(Result.Reachability[3], 3, TRAVEL_WALK, 124, 132, 20);
  SetReach(Result.Reachability[4], 2, TRAVEL_WALK, 132, 124, 20);
  Result.AreaSettings[1].FirstReachableArea := 1;
  Result.AreaSettings[1].NumReachableAreas := 1;
  Result.AreaSettings[2].FirstReachableArea := 2;
  Result.AreaSettings[2].NumReachableAreas := 2;
  Result.AreaSettings[3].FirstReachableArea := 4;
  Result.AreaSettings[3].NumReachableAreas := 1;
  Result.Clusters[1].NumAreas := 3;
  Result.Clusters[1].NumReachabilityAreas := 3;
  // the faces between the areas, for the alternative routes
  Result.Faces[1].FrontArea := 1;
  Result.Faces[1].BackArea := 2;
  Result.Faces[2].FrontArea := 2;
  Result.Faces[2].BackArea := 3;
  Result.Areas[1].FirstFace := 0;
  Result.Areas[1].NumFaces := 1;
  Result.Areas[2].FirstFace := 1;
  Result.Areas[2].NumFaces := 2;
  Result.Areas[3].FirstFace := 3;
  Result.Areas[3].NumFaces := 1;
  Result.FaceIndex[0] := 1;
  Result.FaceIndex[1] := 1;
  Result.FaceIndex[2] := 2;
  Result.FaceIndex[3] := 2;
end;

procedure TTestAasRoute.Use(const AData: TAasFileData; const ADeveloper: Boolean);
begin
  FRouter := nil;
  FFile := TAasFile.Create(AData) as IAasFile;
  FRouter := TAasFactory.CreateRouter(FFile, FImportIntf, TAasFactory.CreateTracer(FFile, FImportIntf), nil,
    ADeveloper);
end;

procedure TTestAasRoute.ExpectRejected(const AData: TAasFileData);
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    Use(AData);
  except
    on EAasRouteException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised, 'EAasRouteException expected');
end;

procedure TTestAasRoute.Setup;
begin
  FImport := TFakeImport.Create;
  FImportIntf := FImport;
  Use(BuildData);
end;

procedure TTestAasRoute.TearDown;
begin
  FRouter := nil;
  FFile := nil;
  FImportIntf := nil;
  FImport := nil;
end;

procedure TTestAasRoute.DovrebbeDareIlTempoEDLaPrimaRaggiungibilita;
var
  LTime, LReach: Integer;
  LOrigin: TVec3;
begin
  LOrigin := ReachPoint(32);
  LTime := 0;
  LReach := -1;
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(1, @LOrigin, 3, TFL_DEFAULT, LTime, LReach));
  // 1 (the start of the cache) + 20 + 18 (crossing area 2: 56 units * 0.33) + 20, plus 9 (28 units in area 1)
  Assert.AreEqual(68, LTime);
  Assert.AreEqual(1, LReach);
  Assert.AreEqual(68, FRouter.AreaTravelTimeToGoalArea(1, @LOrigin, 3, TFL_DEFAULT));
  Assert.AreEqual(1, FRouter.AreaReachabilityToGoalArea(1, @LOrigin, 3, TFL_DEFAULT));
end;

procedure TTestAasRoute.DovrebbeDareTempoUnoPerLaStessaArea;
var
  LTime, LReach: Integer;
begin
  LTime := 0;
  LReach := 5;
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(2, nil, 2, TFL_DEFAULT, LTime, LReach));
  Assert.AreEqual(1, LTime);
  Assert.AreEqual(0, LReach);
end;

type
  TFixedRandom = class(TInterfacedObject, IBotRandom)
  strict private
    FValue: Single;
  public
    constructor Create(const AValue: Single);
    function NextFloat: Single;
  end;

constructor TFixedRandom.Create(const AValue: Single);
begin
  inherited Create;
  FValue := AValue;
end;

function TFixedRandom.NextFloat: Single;
begin
  Result := FValue;
end;

procedure TTestAasRoute.DovrebbeScegliereUnAreaCasualeDoveSiNuota;
var
  LData: TAasFileData;
  LGoal: TAasRandomGoal;
  LArea: Integer;
  LOrigin: TVec3;
begin
  LData := BuildData;
  LData.AreaSettings[3].AreaFlags := AREA_LIQUID;
  Use(LData);
  LGoal := TAasRandomGoal.Create(FFile, TAasFactory.CreateSampler(FFile, FImportIntf, True), TAasFactory.CreateTracer(FFile, FImportIntf), FRouter, TAasFactory.CreateAreaQuery(FFile, FImportIntf), TAasReachFactory.CreateGeometry(FFile), TFixedRandom.Create(0.75));
  try
    // 4 areas * 0.75 = 3: the area in the water
    Assert.IsTrue(LGoal.RandomGoalArea(1, TFL_DEFAULT, LArea, LOrigin));
    Assert.AreEqual(3, LArea);
    Assert.AreEqual(Double(FFile.Areas[3].Center[0]), Double(LOrigin[0]), 0.0);
  finally
    LGoal.Free;
  end;
end;

procedure TTestAasRoute.DovrebbeNonTrovareUnAreaCasualeSenzaTerrenoNeRaggiungibilita;
var
  LGoal: TAasRandomGoal;
  LArea: Integer;
  LOrigin: TVec3;
begin
  LGoal := TAasRandomGoal.Create(FFile, TAasFactory.CreateSampler(FFile, FImportIntf, True), TAasFactory.CreateTracer(FFile, FImportIntf), FRouter, TAasFactory.CreateAreaQuery(FFile, FImportIntf), TAasReachFactory.CreateGeometry(FFile), TFixedRandom.Create(0));
  try
    // no reachabilities in the area 0
    Assert.IsFalse(LGoal.RandomGoalArea(0, TFL_DEFAULT, LArea, LOrigin));
    // no ground below the centers: nothing is found after every area was tried
    Assert.IsFalse(LGoal.RandomGoalArea(1, TFL_DEFAULT, LArea, LOrigin));
    Assert.AreEqual(0, LArea);
  finally
    LGoal.Free;
  end;
end;

procedure TTestAasRoute.DovrebbeDareIlTempoPerAttraversareUnArea;
begin
  // the same point: at least one hundredth of a second; farther points take longer
  Assert.AreEqual(1, FRouter.AreaTravelTime(2, Vec(0, 0, 0), Vec(0, 0, 0)));
  Assert.IsTrue(FRouter.AreaTravelTime(2, Vec(0, 0, 0), Vec(300, 0, 0)) > 1);
end;

procedure TTestAasRoute.DovrebbeNonContareIlTempoDentroLAreaSenzaOrigine;
var
  LTime, LReach: Integer;
begin
  LTime := 0;
  LReach := -1;
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT, LTime, LReach));
  Assert.AreEqual(59, LTime);
  Assert.AreEqual(1, LReach);
end;

procedure TTestAasRoute.DovrebbeRifiutareAreeFuoriDalFileSoloInModoSviluppatore;
var
  LTime, LReach: Integer;
begin
  Assert.IsFalse(FRouter.AreaRouteToGoalArea(0, nil, 3, TFL_DEFAULT, LTime, LReach));
  Assert.IsFalse(FRouter.AreaRouteToGoalArea(1, nil, 9, TFL_DEFAULT, LTime, LReach));
  Assert.AreEqual(2, FImport.Count);
  Assert.AreEqual(PRT_ERROR, FImport.Level(0));
  Assert.IsTrue(Pos('areanum 0', FImport.Message(0)) > 0);
  Assert.IsTrue(Pos('goalareanum 9', FImport.Message(1)) > 0);
  // without bot_developer nothing is said
  Use(BuildData, False);
  Assert.IsFalse(FRouter.AreaRouteToGoalArea(0, nil, 3, TFL_DEFAULT, LTime, LReach));
  Assert.AreEqual(2, FImport.Count);
  Assert.AreEqual(0, FRouter.EnableRoutingArea(0, 1));
  Assert.AreEqual(2, FImport.Count);
end;

procedure TTestAasRoute.DovrebbeNonEntrareInUnAreaDisabilitata;
var
  LTime, LReach: Integer;
begin
  Assert.AreEqual(1, FRouter.EnableRoutingArea(2, 0));
  Assert.IsFalse(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT, LTime, LReach));
  Assert.AreEqual(0, FRouter.EnableRoutingArea(2, 1));
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT, LTime, LReach));
end;

procedure TTestAasRoute.DovrebbeLeggereELeggereLoStatoDiUnAreaDiRouting;
begin
  Assert.AreEqual(1, FRouter.EnableRoutingArea(3, -1));
  FRouter.EnableRoutingArea(3, 0);
  Assert.AreEqual(0, FRouter.EnableRoutingArea(3, -1));
  Assert.AreEqual(AREA_DISABLED, FFile.AreaSettings[3].AreaFlags and AREA_DISABLED);
  // asking for the state it already has leaves the caches alone
  FRouter.EnableRoutingArea(3, 0);
  Assert.AreEqual(0, FRouter.EnableRoutingArea(0, -1));
  Assert.AreEqual(0, FRouter.EnableRoutingArea(9, 1));
end;

procedure TTestAasRoute.DovrebbeEvitareUnTipoDiMovimentoNonPermesso;
var
  LTime, LReach: Integer;
begin
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT, LTime, LReach));
  // walking is not allowed: no route
  Assert.IsFalse(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT and not TFL_WALK, LTime, LReach));
  // the areas are air: air not allowed
  Assert.IsFalse(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT and not TFL_AIR, LTime, LReach));
end;

procedure TTestAasRoute.DovrebbePredireLaStradaFinoAlLaMeta;
var
  LRoute: TAasPredictRoute;
begin
  Assert.IsTrue(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT, 0, 0, RSE_NONE, 0, 0, 0));
  Assert.AreEqual(3, LRoute.EndArea);
  Assert.AreEqual<Integer>(RSE_NONE, LRoute.StopEvent);
  Assert.AreEqual<Single>(132, LRoute.EndPos[0]);
  // the time of the first area is counted with the origin of the whole prediction, as the original does
  Assert.IsTrue(LRoute.Time > 40);
end;

procedure TTestAasRoute.DovrebbeFermareLaPrevisioneSuUnEvento;
var
  LRoute: TAasPredictRoute;
begin
  Assert.IsTrue(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT, 0, 0, RSE_ENTERAREA, 0, 0, 2));
  Assert.AreEqual(RSE_ENTERAREA, LRoute.StopEvent);
  Assert.AreEqual(2, LRoute.EndArea);
  Assert.IsTrue(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT, 0, 0, RSE_USETRAVELTYPE, 0, TFL_WALK, 0));
  Assert.AreEqual(RSE_USETRAVELTYPE, LRoute.StopEvent);
  Assert.AreEqual(1, LRoute.EndArea);
  // the contents of the area that comes next
  FFile.AreaSettings[2].Contents := AREACONTENTS_WATER;
  Use(BuildData);
  FFile.AreaSettings[2].Contents := AREACONTENTS_WATER;
  Assert.IsTrue(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT, 0, 0, RSE_ENTERCONTENTS,
    AREACONTENTS_WATER, 0, 0));
  Assert.AreEqual(RSE_ENTERCONTENTS, LRoute.StopEvent);
  Assert.AreEqual(2, LRoute.EndArea);
  // a limit of one area
  Assert.IsFalse(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT, 1, 0, RSE_NONE, 0, 0, 0));
  Assert.AreEqual(2, LRoute.EndArea);
  // a limit of time
  Assert.IsFalse(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT, 0, 5, RSE_NONE, 0, 0, 0));
end;

procedure TTestAasRoute.DovrebbeFermareLaPrevisioneSenzaStrada;
var
  LRoute: TAasPredictRoute;
begin
  Assert.IsFalse(FRouter.PredictRoute(LRoute, 1, ReachPoint(32), 3, TFL_DEFAULT and not TFL_WALK, 0, 0, RSE_NONE, 0, 0, 0));
  Assert.AreEqual(RSE_NOROUTE, LRoute.StopEvent);
end;

procedure TTestAasRoute.DovrebbeDareLeBandiereDeiTipiDiMovimento;
begin
  Assert.AreEqual(TFL_WALK, FRouter.TravelFlagForType(TRAVEL_WALK));
  Assert.AreEqual(TFL_JUMPPAD, FRouter.TravelFlagForType(TRAVEL_JUMPPAD));
  Assert.AreEqual(TFL_FUNCBOB, FRouter.TravelFlagForType(TRAVEL_FUNCBOB));
  Assert.AreEqual(TFL_INVALID, FRouter.TravelFlagForType(TRAVEL_INVALID));
  Assert.AreEqual(TFL_INVALID, FRouter.TravelFlagForType(0));
  Assert.AreEqual(TFL_INVALID, FRouter.TravelFlagForType(99));
  Assert.AreEqual(TFL_INVALID, FRouter.TravelFlagForType(-5));
  // the team flags of the type are outside the mask
  Assert.AreEqual(TFL_WALK, FRouter.TravelFlagForType(TRAVEL_WALK or (1 shl 24)));
end;

procedure TTestAasRoute.DovrebbeDareLeBandiereDelContenutoDelleAree;
var
  LData: TAasFileData;
begin
  LData := BuildData;
  LData.AreaSettings[1].Contents := AREACONTENTS_WATER or AREACONTENTS_DONOTENTER;
  LData.AreaSettings[2].Contents := AREACONTENTS_SLIME or AREACONTENTS_NOTTEAM1;
  LData.AreaSettings[3].Contents := AREACONTENTS_LAVA or AREACONTENTS_NOTTEAM2;
  LData.AreaSettings[3].AreaFlags := AREA_BRIDGE;
  Use(LData);
  Assert.AreEqual(TFL_WATER or TFL_DONOTENTER, FRouter.AreaContentsTravelFlags(1));
  Assert.AreEqual(TFL_SLIME or TFL_NOTTEAM1, FRouter.AreaContentsTravelFlags(2));
  Assert.AreEqual(TFL_LAVA or TFL_NOTTEAM2 or TFL_BRIDGE, FRouter.AreaContentsTravelFlags(3));
  Assert.AreEqual(TFL_AIR, FRouter.AreaContentsTravelFlags(0));
end;

procedure TTestAasRoute.DovrebbeCopiareUnaRaggiungibilita;
var
  LReach: TAasReachability;
begin
  FRouter.ReachabilityFromNum(3, LReach);
  Assert.AreEqual(3, LReach.AreaNum);
  Assert.AreEqual<Single>(124, LReach.StartPoint[0]);
  FRouter.ReachabilityFromNum(-1, LReach);
  Assert.AreEqual(0, LReach.AreaNum);
  FRouter.ReachabilityFromNum(5, LReach);
  Assert.AreEqual(0, LReach.TravelType);
end;

procedure TTestAasRoute.DovrebbePassareAllaRaggiungibilitaSuccessiva;
begin
  Assert.AreEqual(2, FRouter.NextAreaReachability(2, 0));
  Assert.AreEqual(3, FRouter.NextAreaReachability(2, 2));
  Assert.AreEqual(0, FRouter.NextAreaReachability(2, 3));
  Assert.AreEqual(0, FRouter.NextAreaReachability(0, 0));
  Assert.AreEqual(PRT_ERROR, FImport.Level(0));
  Assert.AreEqual(0, FRouter.NextAreaReachability(2, 1));
  Assert.AreEqual(PRT_FATAL, FImport.Level(1));
end;

procedure TTestAasRoute.DovrebbeTrovareLeRaggiungibilitaDiUnModello;
var
  LData: TAasFileData;
begin
  LData := BuildData;
  LData.Reachability[2].TravelType := TRAVEL_ELEVATOR;
  LData.Reachability[2].FaceNum := 7;
  LData.Reachability[4].TravelType := TRAVEL_FUNCBOB;
  LData.Reachability[4].FaceNum := $00050007;
  Use(LData);
  Assert.AreEqual(2, FRouter.NextModelReachability(0, 7));
  Assert.AreEqual(4, FRouter.NextModelReachability(2, 7));
  Assert.AreEqual(0, FRouter.NextModelReachability(4, 7));
  Assert.AreEqual(0, FRouter.NextModelReachability(0, 8));
  Assert.AreEqual(0, FRouter.NextModelReachability(9, 7));
  Assert.AreEqual(2, FRouter.NextModelReachability(-3, 7));
end;

procedure TTestAasRoute.DovrebbeTrovareLAreaPiuVicinaDoveNascondersi;
begin
  // AAS_AreaVisible says no: the nearest area is the first that the bot can go to, apart from the area of the enemy
  Assert.AreEqual(2, FRouter.NearestHideArea(0, ReachPoint(32), 1, 1, ReachPoint(160), 3, TFL_DEFAULT));
  // the enemy stands on the way: never go through him
  Assert.AreEqual(0, FRouter.NearestHideArea(0, ReachPoint(32), 1, 1, ReachPoint(64), 2, TFL_DEFAULT));
  // near the enemy the travel time grows
  Assert.AreEqual(0, FRouter.NearestHideArea(0, ReachPoint(32), 1, 1, ReachPoint(64), 3, TFL_DEFAULT and not TFL_WALK));
end;

procedure TTestAasRoute.DovrebbeDareMenoDiZeroObiettiviSenzaSpazio;
var
  LGoals: TArray<TAasAltRouteGoal>;
begin
  Assert.AreEqual(0, FRouter.AlternativeRouteGoals(ReachPoint(32), 1, ReachPoint(160), 3, TFL_DEFAULT, LGoals, 0,
    ALTROUTEGOAL_ALL));
  Assert.AreEqual(0, FRouter.AlternativeRouteGoals(ReachPoint(32), 0, ReachPoint(160), 3, TFL_DEFAULT, LGoals, 4,
    ALTROUTEGOAL_ALL));
  Assert.AreEqual(0, FRouter.AlternativeRouteGoals(ReachPoint(32), 1, ReachPoint(160), 0, TFL_DEFAULT, LGoals, 4,
    ALTROUTEGOAL_ALL));
  // the middle area is not so far from the line (a goal that needs a shorter way than the straight one)
  Assert.AreEqual(0, FRouter.AlternativeRouteGoals(ReachPoint(32), 1, ReachPoint(160), 3, TFL_DEFAULT, LGoals, 4,
    ALTROUTEGOAL_CLUSTERPORTALS));
end;

procedure TTestAasRoute.DovrebbeRifiutareUnaRaggiungibilitaVersoUnAreaCheNonEsiste;
var
  LData: TAasFileData;
begin
  LData := BuildData;
  LData.Reachability[1].AreaNum := 12;
  ExpectRejected(LData);
end;

procedure TTestAasRoute.DovrebbeRifiutareUnClusterCheNonEsiste;
var
  LData: TAasFileData;
begin
  LData := BuildData;
  LData.AreaSettings[2].Cluster := 4;
  ExpectRejected(LData);
  LData := BuildData;
  LData.AreaSettings[2].ClusterAreaNum := -1;
  ExpectRejected(LData);
  LData := BuildData;
  LData.AreaSettings[2].FirstReachableArea := 90;
  ExpectRejected(LData);
  LData := BuildData;
  LData.Clusters[1].NumPortals := 3;
  ExpectRejected(LData);
end;

procedure TTestAasRoute.DovrebbeRifiutareUnPortaleFuoriDalFile;
var
  LData: TAasFileData;
begin
  LData := BuildData;
  SetLength(LData.Portals, 2);
  LData.Portals[1].AreaNum := 30;
  ExpectRejected(LData);
  LData := BuildData;
  LData.AreaSettings[2].Cluster := -1;
  ExpectRejected(LData);
  // the number of areas and the number of settings must agree
  LData := BuildData;
  SetLength(LData.AreaSettings, 2);
  ExpectRejected(LData);
  LData := BuildData;
  SetLength(LData.Areas, 0);
  ExpectRejected(LData);
end;

procedure TTestAasRoute.DovrebbeContareLeCacheEGliAggiornamenti;
var
  LAreas, LPortals, LMemory, LAreaUpdates, LPortalUpdates, LTime, LReach: Integer;
begin
  FRouter.CacheStatistics(LAreas, LPortals, LMemory);
  Assert.AreEqual(0, LAreas + LPortals + LMemory);
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT, LTime, LReach));
  FRouter.CacheStatistics(LAreas, LPortals, LMemory);
  // inside a cluster the portal caches are not needed: one cache of the area, 64 bytes of structure and a table of
  // three areas
  Assert.AreEqual(1, LAreas);
  Assert.AreEqual(0, LPortals);
  Assert.AreEqual(64 + 3 * 3, LMemory);
  FRouter.UpdateCounts(LAreaUpdates, LPortalUpdates);
  Assert.AreEqual(1, LAreaUpdates);
  Assert.AreEqual(0, LPortalUpdates);
end;

procedure TTestAasRoute.DovrebbeFalliSeLaMemoriaEFinita;
var
  LMemory: TNoMemory;
  LMemoryIntf: IAasRoutingMemory;
  LTime, LReach, LAreas, LPortals, LSize: Integer;
begin
  LMemory := TNoMemory.Create;
  LMemoryIntf := LMemory;
  FRouter := TAasFactory.CreateRouter(FFile, FImportIntf, TAasFactory.CreateTracer(FFile, FImportIntf), LMemoryIntf, True);
  // the memory is always short: the caches of the earlier routes are dropped before the next one, never the last
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(1, nil, 3, TFL_DEFAULT, LTime, LReach));
  Assert.IsTrue(FRouter.AreaRouteToGoalArea(3, nil, 1, TFL_DEFAULT, LTime, LReach));
  Assert.IsTrue(LMemory.FCalls >= 2);
  FRouter.CacheStatistics(LAreas, LPortals, LSize);
  Assert.AreEqual(1, LAreas);
  Assert.AreEqual(0, LPortals);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasRoute);

end.
