{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 obstacle avoidance                          }
{                                                                              }
{  What the golden of the real C++ cannot reach: the input that the original   }
{  does not survive (loops forever or reads outside its arrays) and the        }
{  small cases of every class.                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.Avoid;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Aas.D3.Avoid.ObstacleSet,
  DelphiDoom.Aas.D3.Avoid.PathNode;

type
  [TestFixture]
  [Category('AasD3')]
  TTestAasD3Avoid = class
  strict private
    FSet: TAvoidObstacleSet;
    procedure AddSquare(const ACenterX, ACenterY, AHalf: Single);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrovareLObstacleCheContieneIlPunto;
    [Test]
    procedure DovrebbeDare1SeIlPuntoNonStaInNessunObstacle;
    [Test]
    procedure DovrebbeLasciareIlPuntoDoveEraSeFuoriDagliOstacoli;
    [Test]
    procedure DovrebbeSpingereIlPuntoFuoriDallObstacleCheLoContiene;
    [Test]
    procedure DovrebbeTrovareIlPrimoObstacleCheBloccaIlMovimento;
    [Test]
    procedure DovrebbeNonTrovareObstacleSeIlMovimentoELibero;
    [Test]
    procedure DovrebbeSaltareLObstacleDaSaltare;
    [Test]
    procedure DovrebbeSvuotareLInsiemeConClear;
    [Test]
    procedure DovrebbeSollevareEccezioneOltreIlMassimoDiOstacoli;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIlNodoNominaUnObstacleChePiuNonCe;
    [Test]
    procedure DovrebbeSollevareEccezioneSeLObstacleNonHaPunti;
    [Test]
    procedure DovrebbeSollevareEccezioneSeTuttiIPuntiSonoUguali;
    [Test]
    procedure DovrebbeAbbandonareLAlberoConFreeTree;
    [Test]
    procedure DovrebbeSollevareEccezioneSeIlPercorsoHaPiuPuntiDelMassimo;
    [Test]
    procedure DovrebbeSollevareEccezioneSeNonCePercorsoNeUnPrimoPasso;
    [Test]
    procedure DovrebbeDareIlPrimoPassoDellAlberoSeNonRaggiungeLaMeta;
    [Test]
    procedure DovrebbeDareLaLunghezzaDelPercorsoConLaPenalitaDiSvolta;
    [Test]
    procedure DovrebbeNonCambiareIlPercorsoSenzaNavigatore;
    [Test]
    procedure DovrebbeDare0SeLaMetaNonSiRaggiunge;
    [Test]
    procedure DovrebbeDareLAltezzaDelLancio;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Aas.D3.Avoid.Types,
  DelphiDoom.Aas.D3.Avoid.Intf, DelphiDoom.Aas.D3.Avoid.Obstacle, DelphiDoom.Aas.D3.Avoid.PathTree, DelphiDoom.Aas.D3.Avoid.PathOptimizer,
  DelphiDoom.Aas.D3.Avoid.PathFinder, DelphiDoom.Aas.D3.Avoid.Ballistics, DelphiDoom.Tests.Aas.D3.AvoidScenario;

{ TTestAasD3Avoid }

procedure TTestAasD3Avoid.AddSquare(const ACenterX, ACenterY, AHalf: Single);
var
  LObstacle: TAvoidObstacle;
begin
  LObstacle := FSet.Add;
  LObstacle.Winding.AddPoint(TIdVec2.Create(ACenterX - AHalf, ACenterY - AHalf));
  LObstacle.Winding.AddPoint(TIdVec2.Create(ACenterX - AHalf, ACenterY + AHalf));
  LObstacle.Winding.AddPoint(TIdVec2.Create(ACenterX + AHalf, ACenterY + AHalf));
  LObstacle.Winding.AddPoint(TIdVec2.Create(ACenterX + AHalf, ACenterY - AHalf));
  LObstacle.UpdateBounds;
end;

procedure TTestAasD3Avoid.Setup;
begin
  FSet := TAvoidObstacleSet.Create;
end;

procedure TTestAasD3Avoid.TearDown;
begin
  FSet.Free;
end;

procedure TTestAasD3Avoid.DovrebbeTrovareLObstacleCheContieneIlPunto;
begin
  AddSquare(0, 0, 10);
  AddSquare(100, 0, 10);
  Assert.AreEqual(1, FSet.PointInsideObstacle(TIdVec2.Create(101, 2)));
end;

procedure TTestAasD3Avoid.DovrebbeDare1SeIlPuntoNonStaInNessunObstacle;
begin
  AddSquare(0, 0, 10);
  Assert.AreEqual(-1, FSet.PointInsideObstacle(TIdVec2.Create(50, 50)));
end;

procedure TTestAasD3Avoid.DovrebbeLasciareIlPuntoDoveEraSeFuoriDagliOstacoli;
var
  LPoint: TIdVec2;
  LObstacle, LEdge: Integer;
begin
  AddSquare(0, 0, 10);
  LPoint := TIdVec2.Create(50, 50);
  FSet.GetPointOutsideObstacles(LPoint, LObstacle, LEdge);
  Assert.AreEqual(-1, LObstacle);
  Assert.AreEqual(-1, LEdge);
  Assert.AreEqual(Double(50), Double(LPoint.X));
  Assert.AreEqual(Double(50), Double(LPoint.Y));
end;

procedure TTestAasD3Avoid.DovrebbeSpingereIlPuntoFuoriDallObstacleCheLoContiene;
var
  LPoint: TIdVec2;
  LObstacle, LEdge: Integer;
begin
  AddSquare(0, 0, 10);
  LPoint := TIdVec2.Create(9, 0);
  FSet.GetPointOutsideObstacles(LPoint, LObstacle, LEdge);
  Assert.AreEqual(0, LObstacle);
  Assert.IsTrue(LEdge >= 0);
  Assert.AreEqual(-1, FSet.PointInsideObstacle(LPoint));
end;

procedure TTestAasD3Avoid.DovrebbeTrovareIlPrimoObstacleCheBloccaIlMovimento;
var
  LScale: Single;
  LObstacle, LEdge: Integer;
begin
  AddSquare(50, 0, 10);
  AddSquare(100, 0, 10);
  LObstacle := -1;
  LEdge := -1;
  Assert.IsTrue(FSet.GetFirstBlockingObstacle(-1, TIdVec2.Create(0, 0), TIdVec2.Create(200, 0), LScale, LObstacle,
    LEdge));
  Assert.AreEqual(0, LObstacle);
  Assert.IsTrue((LScale > 0) and (LScale < 1));
end;

procedure TTestAasD3Avoid.DovrebbeNonTrovareObstacleSeIlMovimentoELibero;
var
  LScale: Single;
  LObstacle, LEdge: Integer;
begin
  AddSquare(50, 100, 10);
  LObstacle := -1;
  LEdge := -1;
  Assert.IsFalse(FSet.GetFirstBlockingObstacle(-1, TIdVec2.Create(0, 0), TIdVec2.Create(200, 0), LScale, LObstacle,
    LEdge));
  Assert.AreEqual(-1, LObstacle);
end;

procedure TTestAasD3Avoid.DovrebbeSaltareLObstacleDaSaltare;
var
  LScale: Single;
  LObstacle, LEdge: Integer;
begin
  AddSquare(50, 0, 10);
  AddSquare(100, 0, 10);
  LObstacle := -1;
  LEdge := -1;
  Assert.IsTrue(FSet.GetFirstBlockingObstacle(0, TIdVec2.Create(0, 0), TIdVec2.Create(200, 0), LScale, LObstacle,
    LEdge));
  Assert.AreEqual(1, LObstacle);
end;

procedure TTestAasD3Avoid.DovrebbeSvuotareLInsiemeConClear;
begin
  AddSquare(0, 0, 10);
  Assert.AreEqual(1, FSet.Count);
  FSet.Clear;
  Assert.AreEqual(0, FSet.Count);
end;

procedure TTestAasD3Avoid.DovrebbeSollevareEccezioneOltreIlMassimoDiOstacoli;
var
  LIndex: Integer;
begin
  for LIndex := 1 to AVOID_MAX_OBSTACLES do
    FSet.Add;
  Assert.AreEqual(AVOID_MAX_OBSTACLES, FSet.Count);
  Assert.WillRaise(
    procedure
    begin
      FSet.Add;
    end, EAasAvoidException);
end;

procedure TTestAasD3Avoid.DovrebbeSollevareEccezioneSeIlNodoNominaUnObstacleChePiuNonCe;
var
  LTree: TAvoidPathTree;
  LNode: TAvoidPathNode;
begin
  LTree := TAvoidPathTree.Create(FSet);
  LNode := TAvoidPathNode.Create;
  try
    LNode.Obstacle := 3;
    Assert.WillRaise(
      procedure
      begin
        LTree.GetPathNodeDelta(LNode, TIdVec2.Create(0, 0), False);
      end, EAasAvoidException);
    LNode.Obstacle := -1;
    Assert.WillRaise(
      procedure
      begin
        LTree.GetPathNodeDelta(LNode, TIdVec2.Create(0, 0), False);
      end, EAasAvoidException);
  finally
    LNode.Free;
    LTree.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeSollevareEccezioneSeLObstacleNonHaPunti;
var
  LTree: TAvoidPathTree;
  LNode: TAvoidPathNode;
begin
  FSet.Add;
  LTree := TAvoidPathTree.Create(FSet);
  LNode := TAvoidPathNode.Create;
  try
    LNode.Obstacle := 0;
    Assert.WillRaise(
      procedure
      begin
        LTree.GetPathNodeDelta(LNode, TIdVec2.Create(0, 0), False);
      end, EAasAvoidException);
  finally
    LNode.Free;
    LTree.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeSollevareEccezioneSeTuttiIPuntiSonoUguali;
var
  LTree: TAvoidPathTree;
  LNode: TAvoidPathNode;
  LObstacle: TAvoidObstacle;
  LIndex: Integer;
begin
  // the original goes round the winding for ever
  LObstacle := FSet.Add;
  for LIndex := 0 to 3 do
    LObstacle.Winding.AddPoint(TIdVec2.Create(5, 5));
  LObstacle.UpdateBounds;
  LTree := TAvoidPathTree.Create(FSet);
  LNode := TAvoidPathNode.Create;
  try
    LNode.Obstacle := 0;
    LNode.Pos := TIdVec2.Create(5, 5);
    LNode.EdgeNum := 0;
    LNode.Dir := 1;
    Assert.WillRaise(
      procedure
      begin
        LTree.GetPathNodeDelta(LNode, TIdVec2.Create(50, 50), False);
      end, EAasAvoidException);
  finally
    LNode.Free;
    LTree.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeAbbandonareLAlberoConFreeTree;
var
  LTree: TAvoidPathTree;
  LPath: TAvoidPath;
begin
  AddSquare(50, 0, 10);
  LTree := TAvoidPathTree.Create(FSet);
  try
    LPath.FirstObstacle := AVOID_NO_ENTITY;
    LTree.Build(TGeoBounds.Make(TGeoVec3.Make(-100, -100, -10), TGeoVec3.Make(300, 100, 10)),
      TIdVec2.Create(0, 0), TIdVec2.Create(100, 0), LPath);
    Assert.IsTrue(LTree.AllocCount > 0);
    Assert.IsNotNull(LTree.Root);
    LTree.FreeTree;
    Assert.AreEqual(0, LTree.AllocCount);
    Assert.IsNull(LTree.Root);
    // twice is harmless
    LTree.FreeTree;
  finally
    LTree.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeSollevareEccezioneSeIlPercorsoHaPiuPuntiDelMassimo;
var
  LOptimizer: TAvoidPathOptimizer;
  LNodes: array[0..AVOID_MAX_OBSTACLE_PATH + 4] of TAvoidPathNode;
  LPath: TAvoidOptimizedPath;
  LIndex: Integer;
begin
  AddSquare(0, 0, 1);
  LOptimizer := TAvoidPathOptimizer.Create(FSet);
  try
    // a chain of nodes along the same obstacle: no shortcut is allowed, so every node is a point of the path
    for LIndex := 0 to High(LNodes) do
    begin
      LNodes[LIndex] := TAvoidPathNode.Create;
      LNodes[LIndex].Obstacle := 0;
      LNodes[LIndex].Pos := TIdVec2.Create(LIndex, 0);
      if LIndex > 0 then
        LNodes[LIndex].Parent := LNodes[LIndex - 1];
    end;
    FillChar(LPath, SizeOf(LPath), 0);
    Assert.WillRaise(
      procedure
      begin
        LOptimizer.OptimizePath(LNodes[0], LNodes[High(LNodes)], LPath);
      end, EAasAvoidException);
    // fewer points than the maximum are fine
    Assert.AreEqual(4, LOptimizer.OptimizePath(LNodes[0], LNodes[3], LPath));
  finally
    for LIndex := 0 to High(LNodes) do
      LNodes[LIndex].Free;
    LOptimizer.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeSollevareEccezioneSeNonCePercorsoNeUnPrimoPasso;
var
  LOptimizer: TAvoidPathOptimizer;
  LRoot: TAvoidPathNode;
  LSeekPos: TGeoVec3;
begin
  LOptimizer := TAvoidPathOptimizer.Create(FSet);
  LRoot := TAvoidPathNode.Create;
  try
    LRoot.Dist := 1000;
    Assert.WillRaise(
      procedure
      begin
        LOptimizer.FindOptimalPath(LRoot, 5, TGeoVec3.Make(0, 0, 0), LSeekPos);
      end, EAasAvoidException);
  finally
    LRoot.Free;
    LOptimizer.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeDareIlPrimoPassoDellAlberoSeNonRaggiungeLaMeta;
var
  LOptimizer: TAvoidPathOptimizer;
  LRoot, LChild: TAvoidPathNode;
  LSeekPos: TGeoVec3;
begin
  LOptimizer := TAvoidPathOptimizer.Create(FSet);
  LRoot := TAvoidPathNode.Create;
  LChild := TAvoidPathNode.Create;
  try
    LRoot.Dist := 1000;
    LChild.Dist := 500;
    LChild.Pos := TIdVec2.Create(12, 34);
    LChild.Parent := LRoot;
    LRoot.Children[0] := LChild;
    Assert.IsFalse(LOptimizer.FindOptimalPath(LRoot, 5, TGeoVec3.Make(0, 0, 0), LSeekPos));
    Assert.AreEqual(Double(12), Double(LSeekPos.X));
    Assert.AreEqual(Double(34), Double(LSeekPos.Y));
    Assert.AreEqual(Double(5), Double(LSeekPos.Z));
  finally
    LChild.Free;
    LRoot.Free;
    LOptimizer.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeDareLaLunghezzaDelPercorsoConLaPenalitaDiSvolta;
var
  LOptimizer: TAvoidPathOptimizer;
  LPath: TAvoidOptimizedPath;
begin
  LOptimizer := TAvoidPathOptimizer.Create(FSet);
  try
    FillChar(LPath, SizeOf(LPath), 0);
    LPath[1] := TIdVec2.Create(30, 0);
    LPath[2] := TIdVec2.Create(30, 40);
    // 30 + 40 (the lengths are the fast, approximate ones of idlib) going the way the body goes
    Assert.AreEqual(Double(70), Double(LOptimizer.PathLength(LPath, 3, TIdVec2.Create(1, 0))), 0.2);
    // 100 more for a path that starts against the current direction
    Assert.AreEqual(Double(170), Double(LOptimizer.PathLength(LPath, 3, TIdVec2.Create(-1, 0))), 0.2);
  finally
    LOptimizer.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeNonCambiareIlPercorsoSenzaNavigatore;
var
  LFinder: TAvoidPathFinder;
  LBody: IAvoidBody;
  LPath: TAvoidPath;
begin
  LFinder := TAvoidPathFinder.Create(nil);
  try
    LBody := TScenarioBody.Create(TGeoVec3.Make(1, 2, 3), TGeoVec3.Make(0, 0, 0));
    Assert.IsTrue(LFinder.FindPathAroundObstacles(LBody, TGeoVec3.Make(1, 2, 3), TGeoVec3.Make(40, 50, 3), LPath));
    Assert.AreEqual(Double(40), Double(LPath.SeekPos.X));
    Assert.AreEqual(Double(50), Double(LPath.SeekPos.Y));
    Assert.AreEqual(AVOID_NO_ENTITY, LPath.FirstObstacle);
    Assert.AreEqual(Double(1), Double(LPath.StartPosOutsideObstacles.X));
    Assert.AreEqual(AVOID_NO_ENTITY, LPath.StartPosObstacle);
    Assert.AreEqual(AVOID_NO_ENTITY, LPath.SeekPosObstacle);
  finally
    LFinder.Free;
  end;
end;

procedure TTestAasD3Avoid.DovrebbeDare0SeLaMetaNonSiRaggiunge;
var
  LBallistics: array[0..1] of TAvoidBallistic;
begin
  // the target is far away and the projectile slow
  Assert.AreEqual(0, TAvoidBallistics.Solve(TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10000, 0, 0), 10, 800, LBallistics));
  // nothing to cover: the target is where the shot starts
  Assert.AreEqual(0, TAvoidBallistics.Solve(TGeoVec3.Make(1, 1, 1), TGeoVec3.Make(1, 1, 1), 400, 0, LBallistics));
end;

procedure TTestAasD3Avoid.DovrebbeDareLAltezzaDelLancio;
begin
  // the original subtracts: t = 100 / 100 = 1, 10 - 0.5 * 100 * 1
  Assert.AreEqual(Double(-40), Double(TAvoidBallistics.HeightForTrajectory(TGeoVec3.Make(0, 0, 10), 100, 100)), 0.0001);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasD3Avoid);

end.
