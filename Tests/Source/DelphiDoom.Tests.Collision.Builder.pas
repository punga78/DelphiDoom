{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - building the model             }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Builder;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Builder,
  DelphiDoom.Tests.Collision.Support;

type
  [TestFixture]
  [Category('collision')]
  TTestCollisionBuilder = class(TObject)
  private
    FCatalog: ICollisionMaterialCatalog;
    FBuilder: TCollisionModelBuilder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestSourceWithoutPrimitivesGivesNoModel;
    [Test]
    procedure TestBoxBrushHasEightVerticesAndTwelveEdges;
    [Test]
    procedure TestBoxEdgesAreSharedByTwoPolygons;
    [Test]
    procedure TestBoxModelBoundsAndContents;
    [Test]
    procedure TestBoxEdgeNormalsPointOutOfTheBox;
    [Test]
    procedure TestBrushPlanesFaceOutward;
    [Test]
    procedure TestBrushWithoutCollisionContentsIsIgnored;
    [Test]
    procedure TestVerticesCloseToAnIntegerAreSnapped;
    [Test]
    procedure TestPolygonEdgesInOppositeDirectionAreShared;
    [Test]
    procedure TestTwoSidedPolygonMakesTwoPolygons;
    [Test]
    procedure TestDegeneratePolygonIsDropped;
    [Test]
    procedure TestHugePolygonIsRejectedWithAWarning;
    [Test]
    procedure TestManyBrushesGetAnAxialBspTree;
    [Test]
    procedure TestFewBrushesStayInOneLeaf;
    [Test]
    procedure TestEveryPolygonIsInTheTreeOnce;
    [Test]
    procedure TestTriangleModelNumbering;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding,
  DelphiDoom.Logging.Intf, DelphiDoom.Logging.Types, DelphiDoom.Logging.Recorder,
  DelphiDoom.Logging.Factory, DelphiDoom.Collision.Types, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon,
  DelphiDoom.Collision.Model.Brush, DelphiDoom.Collision.Model.Node;

{ TTestCollisionBuilder }

procedure TTestCollisionBuilder.Setup;
begin
  FCatalog := TFakeMaterialCatalog.Create;
  FBuilder := TCollisionModelBuilder.Create(nil);
end;

procedure TTestCollisionBuilder.TearDown;
begin
  FBuilder.Free;
  FCatalog := nil;
end;

procedure TTestCollisionBuilder.TestSourceWithoutPrimitivesGivesNoModel;
var
  LSource: ICollisionGeometrySource;
begin
  LSource := TFakeGeometrySource.Create('empty');
  Assert.IsNull(FBuilder.Build(LSource));
end;

procedure TTestCollisionBuilder.TestBoxBrushHasEightVerticesAndTwelveEdges;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
begin
  LSource := TFakeGeometrySource.Create('box');
  LRef := LSource;
  LSource.AddBox(Bounds3(-64, -64, -64, 64, 64, 64), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual('box', LModel.Name);
    Assert.AreEqual(8, LModel.NumVertices);
    // the first edge is a dummy
    Assert.AreEqual(13, LModel.NumEdges);
    Assert.AreEqual(8, Integer(Length(LModel.Vertices)));
    Assert.AreEqual(13, Integer(Length(LModel.Edges)));
    Assert.AreEqual(6, LModel.NumPolygons);
    Assert.AreEqual(1, LModel.NumBrushes);
    Assert.AreEqual(6, Integer(Length(LModel.TreePolygons)));
    Assert.AreEqual(1, Integer(Length(LModel.TreeBrushes)));
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestBoxEdgesAreSharedByTwoPolygons;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LIndex: Integer;
  LPolygon: TCmPolygon;
  LUsers: TArray<Integer>;
  LForward: TArray<Integer>;
  LEdgeNum: Integer;
begin
  LSource := TFakeGeometrySource.Create('box');
  LRef := LSource;
  LSource.AddBox(Bounds3(0, 0, 0, 32, 32, 32), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    SetLength(LUsers, LModel.NumEdges);
    SetLength(LForward, LModel.NumEdges);
    for LPolygon in LModel.TreePolygons do
    begin
      Assert.AreEqual(4, LPolygon.NumEdges);
      for LIndex := 0 to LPolygon.NumEdges - 1 do
      begin
        LEdgeNum := LPolygon.Edges[LIndex];
        Inc(LUsers[Abs(LEdgeNum)]);
        if LEdgeNum > 0 then
          Inc(LForward[LEdgeNum]);
      end;
    end;
    for LIndex := 1 to LModel.NumEdges - 1 do
    begin
      Assert.AreEqual(2, LUsers[LIndex], 'users of edge ' + IntToStr(LIndex));
      Assert.AreEqual(1, LForward[LIndex], 'forward walks of edge ' + IntToStr(LIndex));
      Assert.AreEqual(2, Integer(LModel.Edges[LIndex].NumUsers));
    end;
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestBoxModelBoundsAndContents;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
begin
  LSource := TFakeGeometrySource.Create('box');
  LRef := LSource;
  LSource.AddBox(Bounds3(-10, -20, -30, 40, 50, 60), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(-10.0, LModel.Bounds.Mins.X, 1e-4);
    Assert.AreEqual(-20.0, LModel.Bounds.Mins.Y, 1e-4);
    Assert.AreEqual(-30.0, LModel.Bounds.Mins.Z, 1e-4);
    Assert.AreEqual(40.0, LModel.Bounds.Maxs.X, 1e-4);
    Assert.AreEqual(50.0, LModel.Bounds.Maxs.Y, 1e-4);
    Assert.AreEqual(60.0, LModel.Bounds.Maxs.Z, 1e-4);
    Assert.AreEqual(CONTENTS_SOLID, LModel.Contents);
    Assert.IsFalse(LModel.IsConvex);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestBoxEdgeNormalsPointOutOfTheBox;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LIndex: Integer;
  LMiddle: TGeoVec3;
  LCenter: TGeoVec3;
  LOut: TGeoVec3;
begin
  LSource := TFakeGeometrySource.Create('box');
  LRef := LSource;
  LSource.AddBox(Bounds3(-16, -16, -16, 16, 16, 16), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    LCenter := TGeoVec3.Origin;
    for LIndex := 1 to LModel.NumEdges - 1 do
    begin
      LMiddle := (LModel.Vertices[LModel.Edges[LIndex].VertexNum[0]].P +
        LModel.Vertices[LModel.Edges[LIndex].VertexNum[1]].P) * 0.5;
      LOut := LMiddle - LCenter;
      // perpendicular polygons: the normal is the sum of the two polygon normals, length sqrt(2)
      Assert.AreEqual(1.41421356, LModel.Edges[LIndex].Normal.Length, 1e-4);
      Assert.IsTrue(LModel.Edges[LIndex].Normal.Dot(LOut) > 0, 'edge ' + IntToStr(LIndex));
    end;
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestBrushPlanesFaceOutward;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LBrush: TCmBrush;
  LPolygon: TCmPolygon;
  LCenter: TGeoVec3;
  LIndex: Integer;
begin
  LSource := TFakeGeometrySource.Create('box');
  LRef := LSource;
  LSource.AddBox(Bounds3(10, 10, 10, 50, 50, 50), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    LCenter := TGeoVec3.Make(30, 30, 30);
    LBrush := LModel.TreeBrushes[0];
    Assert.AreEqual(6, LBrush.NumPlanes);
    for LIndex := 0 to 5 do
      Assert.IsTrue(LBrush.Planes[LIndex].Distance(LCenter) < 0);
    for LPolygon in LModel.TreePolygons do
      Assert.IsTrue(LPolygon.Plane.Distance(LCenter) < 0);
    Assert.AreEqual(CONTENTS_SOLID, LBrush.Contents);
    Assert.AreEqual('solid', LBrush.Material.Name);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestBrushWithoutCollisionContentsIsIgnored;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LCatalog: TFakeMaterialCatalog;
begin
  LCatalog := TFakeMaterialCatalog.Create;
  FCatalog := LCatalog;
  LSource := TFakeGeometrySource.Create('portal');
  LRef := LSource;
  // area portals and nocsg do not collide: they have no contents that count
  LSource.AddBox(Bounds3(0, 0, 0, 8, 8, 8), LCatalog.Define('portal', CONTENTS_AREAPORTAL));
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(0, LModel.NumBrushes);
    Assert.AreEqual(0, LModel.NumPolygons);
    Assert.AreEqual(0, LModel.Contents);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestVerticesCloseToAnIntegerAreSnapped;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
begin
  LSource := TFakeGeometrySource.Create('snap');
  LRef := LSource;
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0.004, 0, 0), TGeoVec3.Make(8.006, 0, 0.003),
    TGeoVec3.Make(0, 8, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('solid'));
  finally
    LWinding.Free;
  end;
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(3, LModel.NumVertices);
    Assert.AreEqual(0.0, LModel.Vertices[0].P.X, 0.0);
    Assert.AreEqual(8.0, LModel.Vertices[1].P.X, 0.0);
    Assert.AreEqual(0.0, LModel.Vertices[1].P.Z, 0.0);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestPolygonEdgesInOppositeDirectionAreShared;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
  LPolygons: TArray<TCmPolygon>;
  LIndex: Integer;
  LShared: Integer;
  LOther: Integer;
begin
  LSource := TFakeGeometrySource.Create('fold');
  LRef := LSource;
  // two quads that meet along the edge x = 10: the first runs (10,0)->(10,10), the second back
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 0, 0), TGeoVec3.Make(10, 10, 0),
    TGeoVec3.Make(0, 10, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('solid'));
  finally
    LWinding.Free;
  end;
  LWinding := TGeoWinding.Create([TGeoVec3.Make(10, 10, 0), TGeoVec3.Make(10, 0, 0), TGeoVec3.Make(10, 0, -10),
    TGeoVec3.Make(10, 10, -10)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(1, 0, 0), 10), FCatalog.FindMaterial('solid'));
  finally
    LWinding.Free;
  end;
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(2, Integer(Length(LModel.TreePolygons)));
    // 8 corners minus the 2 that are shared
    Assert.AreEqual(6, LModel.NumVertices);
    // 4 + 4 edges minus the shared one, plus the dummy
    Assert.AreEqual(8, LModel.NumEdges);
    LPolygons := LModel.TreePolygons;
    LShared := 0;
    for LIndex := 0 to LPolygons[0].NumEdges - 1 do
      for LOther := 0 to LPolygons[1].NumEdges - 1 do
        if LPolygons[0].Edges[LIndex] = -LPolygons[1].Edges[LOther] then
          Inc(LShared);
    Assert.AreEqual(1, LShared);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestTwoSidedPolygonMakesTwoPolygons;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
  LCatalog: TFakeMaterialCatalog;
  LPolygon: TCmPolygon;
  LUp: Integer;
begin
  LCatalog := TFakeMaterialCatalog.Create;
  FCatalog := LCatalog;
  LSource := TFakeGeometrySource.Create('two sided');
  LRef := LSource;
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(10, 0, 0), TGeoVec3.Make(10, 10, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), LCatalog.Define('glass', CONTENTS_SOLID, True));
  finally
    LWinding.Free;
  end;
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(2, Integer(Length(LModel.TreePolygons)));
    // the back side has the opposite plane and its three edges are the first ones walked backwards
    LUp := 0;
    for LPolygon in LModel.TreePolygons do
      if LPolygon.Plane.C > 0 then
        Inc(LUp);
    Assert.AreEqual(1, LUp);
    // 3 edges, each used by the front and the back polygon
    Assert.AreEqual(4, LModel.NumEdges);
    Assert.AreEqual(2, Integer(LModel.Edges[1].NumUsers));
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestDegeneratePolygonIsDropped;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
begin
  LSource := TFakeGeometrySource.Create('degenerate');
  LRef := LSource;
  // two of three points are the same vertex: only one valid edge is left, fewer than 3
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(0.01, 0.01, 0), TGeoVec3.Make(10, 0, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('solid'));
  finally
    LWinding.Free;
  end;
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(0, Integer(Length(LModel.TreePolygons)));
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestHugePolygonIsRejectedWithAWarning;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
  LRecorder: TLogRecorder;
  LLog: ILog;
  LBuilder: TCollisionModelBuilder;
begin
  LRecorder := TLogRecorder.Create;
  LLog := TLogFactory.CreateLog([LRecorder], nil);
  LBuilder := TCollisionModelBuilder.Create(LLog);
  try
    LSource := TFakeGeometrySource.Create('huge');
    LRef := LSource;
    LWinding := TGeoWinding.CreateForPlane(TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0));
    try
      LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('solid'));
    finally
      LWinding.Free;
    end;
    LModel := LBuilder.Build(LRef);
    try
      Assert.AreEqual(0, Integer(Length(LModel.TreePolygons)));
      Assert.IsTrue(LRecorder.Count > 0, 'a warning is logged');
    finally
      LModel.Free;
    end;
  finally
    LBuilder.Free;
  end;
end;

procedure TTestCollisionBuilder.TestManyBrushesGetAnAxialBspTree;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LX: Integer;
  LY: Integer;
begin
  LSource := TFakeGeometrySource.Create('grid');
  LRef := LSource;
  for LX := 0 to 5 do
    for LY := 0 to 5 do
      LSource.AddBox(Bounds3(LX * 200, LY * 200, 0, LX * 200 + 100, LY * 200 + 100, 100), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    Assert.IsTrue(LModel.Node.PlaneType in [0, 1, 2], 'the root is split');
    Assert.IsTrue(LModel.NumNodes >= 3);
    Assert.AreEqual(36, Integer(Length(LModel.TreeBrushes)));
    Assert.AreEqual(36 * 6, Integer(Length(LModel.TreePolygons)));
    Assert.AreEqual(36 * 8, LModel.NumVertices);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestFewBrushesStayInOneLeaf;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LIndex: Integer;
begin
  LSource := TFakeGeometrySource.Create('few');
  LRef := LSource;
  for LIndex := 0 to 3 do
    LSource.AddBox(Bounds3(LIndex * 500, 0, 0, LIndex * 500 + 100, 100, 100), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  try
    // four brushes or less: no tree (CollisionModelForMapEntity)
    Assert.AreEqual(-1, LModel.Node.PlaneType);
    Assert.AreEqual(4, LModel.Node.Brushes.Count);
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestEveryPolygonIsInTheTreeOnce;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LX: Integer;
  LSeen: TDictionary<TCmPolygon, Integer>;
  LPolygon: TCmPolygon;
  LCount: Integer;

  procedure Walk(ANode: TCmNode);
  var
    LP: TCmPolygon;
  begin
    for LP in ANode.Polygons do
      if LSeen.TryGetValue(LP, LCount) then
        LSeen[LP] := LCount + 1
      else
        LSeen.Add(LP, 1);
    if not ANode.IsLeaf then
    begin
      Walk(ANode.Children[0]);
      Walk(ANode.Children[1]);
    end;
  end;

begin
  LSource := TFakeGeometrySource.Create('long');
  LRef := LSource;
  // boxes that span many nodes: a polygon in a node is referenced in the leaves it touches
  for LX := 0 to 11 do
    LSource.AddBox(Bounds3(LX * 150, 0, 0, LX * 150 + 140, 600, 20), FCatalog.FindMaterial('solid'));
  LModel := FBuilder.Build(LRef);
  LSeen := TDictionary<TCmPolygon, Integer>.Create;
  try
    Walk(LModel.Node);
    Assert.AreEqual(12 * 6, LSeen.Count);
    for LPolygon in LModel.TreePolygons do
      Assert.IsTrue(LSeen.ContainsKey(LPolygon));
  finally
    LSeen.Free;
    LModel.Free;
  end;
end;

procedure TTestCollisionBuilder.TestTriangleModelNumbering;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
  LPolygon: TCmPolygon;
begin
  // hand derived from CreatePolygon/GetEdge: vertices 0,1,2 in order, edges 1 (0-1), 2 (1-2), 3 (2-0)
  LSource := TFakeGeometrySource.Create('tri');
  LRef := LSource;
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(8, 0, 0), TGeoVec3.Make(0, 8, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('m'));
  finally
    LWinding.Free;
  end;
  LModel := FBuilder.Build(LRef);
  try
    Assert.AreEqual(3, LModel.NumVertices);
    Assert.AreEqual(4, LModel.NumEdges);
    LPolygon := LModel.TreePolygons[0];
    Assert.AreEqual(3, LPolygon.NumEdges);
    Assert.AreEqual(1, LPolygon.Edges[0]);
    Assert.AreEqual(2, LPolygon.Edges[1]);
    Assert.AreEqual(3, LPolygon.Edges[2]);
    Assert.AreEqual(0, LModel.Edges[1].VertexNum[0]);
    Assert.AreEqual(1, LModel.Edges[1].VertexNum[1]);
    Assert.AreEqual(2, LModel.Edges[3].VertexNum[0]);
    Assert.AreEqual(0, LModel.Edges[3].VertexNum[1]);
    // edge normals of a single polygon point out of it in its plane
    Assert.AreEqual(-1.0, LModel.Edges[1].Normal.Y, 1e-5);
    Assert.AreEqual(0.7071068, LModel.Edges[2].Normal.X, 1e-5);
    Assert.AreEqual(0.7071068, LModel.Edges[2].Normal.Y, 1e-5);
    Assert.AreEqual(-1.0, LModel.Edges[3].Normal.X, 1e-5);
  finally
    LModel.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCollisionBuilder);

end.
