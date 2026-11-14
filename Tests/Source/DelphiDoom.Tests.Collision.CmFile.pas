{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - the .cm file format, the       }
{  hash index and the content names                                            }
{                                                                              }
{  The golden text is derived by hand from the C++ writer (CollisionModel_     }
{  files.cpp and FS_WriteFloatString), not produced by a run of it.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.CmFile;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Model;

type
  [TestFixture]
  [Category('collision')]
  TTestCollisionFile = class(TObject)
  private
    FCatalog: ICollisionMaterialCatalog;
    function BuildGrid(AColumns: Integer): TCollisionModel;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestTriangleModelWritesTheExpectedText;
    [Test]
    procedure TestGoldenFileOfTheDataFolderIsTheExpectedText;
    [Test]
    procedure TestExpectedTextReadsBackAndWritesTheSameText;
    [Test]
    procedure TestFloatsAreWrittenWithoutTrailingZeros;
    [Test]
    procedure TestRoundTripOfAModelWithATree;
    [Test]
    procedure TestRoundTripKeepsTheQueryResults;
    [Test]
    procedure TestSeveralModelsInOneFile;
    [Test]
    procedure TestStreamRoundTrip;
    [Test]
    procedure TestFileThatIsNotACmFileIsRejected;
    [Test]
    procedure TestOtherVersionIsRejected;
    [Test]
    procedure TestOutOfDateCrcIsRejected;
    [Test]
    procedure TestMapCrcZeroAcceptsAnyFile;
    [Test]
    procedure TestBadTokenInTheBodyRaises;
    [Test]
    procedure TestOldFilesWithNumericContentsAreAccepted;
    [Test]
    procedure TestCommentsAndOptionalMemoryNumbersAreSkipped;
    [Test]
    procedure TestContentsNames;
    [Test]
    procedure TestHashIndexReturnsTheLastAddedFirst;
    [Test]
    procedure TestHashIndexKeysAreMasked;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, DelphiDoom.Geometry.Types,
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Collision.Types,
  DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush,
  DelphiDoom.Collision.Model.Node, DelphiDoom.Collision.Builder, DelphiDoom.Collision.Factory,
  DelphiDoom.Collision.CmFile.Writer, DelphiDoom.Collision.CmFile.Reader, DelphiDoom.Collision.ContentsNames,
  DelphiDoom.Collision.HashIndex, DelphiDoom.Tests.Collision.Support;

const
  TRIANGLE_TEXT =
    'CM "1.00"'#10#10 +
    '0'#10#10 +
    'collisionModel "tri" {'#10 +
    #9'vertices { /* numVertices = */ 3'#10 +
    #9'/* 0 */ ( 0 0 0 )'#10 +
    #9'/* 1 */ ( 8 0 0 )'#10 +
    #9'/* 2 */ ( 0 8 0 )'#10 +
    #9'}'#10 +
    #9'edges { /* numEdges = */ 4'#10 +
    #9'/* 0 */ ( 0 0 ) 0 0'#10 +
    #9'/* 1 */ ( 0 1 ) 0 1'#10 +
    #9'/* 2 */ ( 1 2 ) 0 1'#10 +
    #9'/* 3 */ ( 2 0 ) 0 1'#10 +
    #9'}'#10 +
    #9'nodes {'#10 +
    #9'( -1 0 )'#10 +
    #9'}'#10 +
    #9'polygons /* polygonMemory = */ 68 {'#10 +
    #9'3 ( 1 2 3 ) ( 0 0 1 ) 0 ( 0 0 0 ) ( 8 8 0 ) "m"'#10 +
    #9'}'#10 +
    #9'brushes /* brushMemory = */ 0 {'#10 +
    #9'}'#10 +
    '}'#10;

{ TTestCollisionFile }

procedure TTestCollisionFile.Setup;
begin
  FCatalog := TFakeMaterialCatalog.Create;
end;

procedure TTestCollisionFile.TearDown;
begin
  FCatalog := nil;
end;

function TTestCollisionFile.BuildGrid(AColumns: Integer): TCollisionModel;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LBuilder: TCollisionModelBuilder;
  LX: Integer;
  LY: Integer;
  LWinding: TGeoWinding;
begin
  LSource := TFakeGeometrySource.Create('grid');
  LRef := LSource;
  for LX := 0 to AColumns - 1 do
    for LY := 0 to AColumns - 1 do
      LSource.AddBox(Bounds3(LX * 200 + 0.5, LY * 200, 0, LX * 200 + 100, LY * 200 + 100.25, 100),
        FCatalog.FindMaterial('solid'));
  // and a loose polygon, to have polygons that are not part of a brush
  LWinding := TGeoWinding.Create([TGeoVec3.Make(-50, -50, 0), TGeoVec3.Make(-10, -50, 0), TGeoVec3.Make(-10, -10, 0),
    TGeoVec3.Make(-50, -10, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('floor'));
  finally
    LWinding.Free;
  end;
  LBuilder := TCollisionFactory.CreateBuilder(nil);
  try
    Result := LBuilder.Build(LRef);
  finally
    LBuilder.Free;
  end;
end;

procedure TTestCollisionFile.TestTriangleModelWritesTheExpectedText;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LBuilder: TCollisionModelBuilder;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
begin
  LSource := TFakeGeometrySource.Create('tri');
  LRef := LSource;
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(8, 0, 0), TGeoVec3.Make(0, 8, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), 0), FCatalog.FindMaterial('m'));
  finally
    LWinding.Free;
  end;
  LBuilder := TCollisionFactory.CreateBuilder(nil);
  try
    LModel := LBuilder.Build(LRef);
  finally
    LBuilder.Free;
  end;
  try
    Assert.AreEqual(TRIANGLE_TEXT, TCollisionFileWriter.ToText([LModel], 0));
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionFile.TestGoldenFileOfTheDataFolderIsTheExpectedText;
var
  LPath: string;
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
  LStream: TFileStream;
begin
  LPath := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Collision\triangle.cm');
  if not TFile.Exists(LPath) then
  begin
    Assert.Pass('triangle.cm not found: ' + LPath);
    Exit;
  end;
  Assert.AreEqual(TRIANGLE_TEXT, TFile.ReadAllText(LPath, TEncoding.UTF8));
  // and the library reads the file from a stream
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  LStream := TFileStream.Create(LPath, fmOpenRead or fmShareDenyWrite);
  try
    LModels := LReader.LoadFromStream(LStream);
    try
      Assert.AreEqual(1, LModels.Count);
      Assert.AreEqual('tri', LModels[0].Name);
    finally
      LModels.Free;
    end;
  finally
    LStream.Free;
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestExpectedTextReadsBackAndWritesTheSameText;
var
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
begin
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    LModels := LReader.Parse(TRIANGLE_TEXT);
  finally
    LReader.Free;
  end;
  try
    Assert.IsNotNull(LModels);
    Assert.AreEqual(1, LModels.Count);
    Assert.AreEqual('tri', LModels[0].Name);
    Assert.AreEqual(3, LModels[0].NumVertices);
    Assert.AreEqual(4, LModels[0].NumEdges);
    Assert.AreEqual(CONTENTS_SOLID, LModels[0].Contents);
    Assert.AreEqual(8.0, LModels[0].Bounds.Maxs.Y, 0.0);
    // the edge normals are calculated on loading
    Assert.AreEqual(-1.0, LModels[0].Edges[1].Normal.Y, 1e-5);
    Assert.AreEqual(TRIANGLE_TEXT, TCollisionFileWriter.ToText([LModels[0]], 0));
  finally
    LModels.Free;
  end;
end;

procedure TTestCollisionFile.TestFloatsAreWrittenWithoutTrailingZeros;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LBuilder: TCollisionModelBuilder;
  LModel: TCollisionModel;
  LWinding: TGeoWinding;
  LText: string;
begin
  LSource := TFakeGeometrySource.Create('floats');
  LRef := LSource;
  LWinding := TGeoWinding.Create([TGeoVec3.Make(0.5, 0, 0), TGeoVec3.Make(8.25, 0, 0), TGeoVec3.Make(0, 8.5, 0)]);
  try
    LSource.AddPolygon(LWinding, TGeoPlane.Make(TGeoVec3.Make(0, 0, 1), -12.5), FCatalog.FindMaterial('m'));
  finally
    LWinding.Free;
  end;
  LBuilder := TCollisionFactory.CreateBuilder(nil);
  try
    LModel := LBuilder.Build(LRef);
  finally
    LBuilder.Free;
  end;
  try
    LText := TCollisionFileWriter.ToText([LModel], 0);
    // the plane distance and the coordinates are as short as possible, never with a trailing point
    Assert.IsTrue(Pos(' ( 0 0 1 ) -12.5 ( 0 0 0 ) ( 8.25 8.5 0 ) "m"', LText) > 0, LText);
    Assert.IsTrue(Pos('/* 0 */ ( 0.5 0 0 )', LText) > 0, LText);
    Assert.IsTrue(Pos('/* 2 */ ( 0 8.5 0 )', LText) > 0, LText);
    Assert.IsTrue(Pos('. ', LText) = 0, 'no trailing point');
  finally
    LModel.Free;
  end;
end;

procedure TTestCollisionFile.TestRoundTripOfAModelWithATree;
var
  LOriginal: TCollisionModel;
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
  LCopy: TCollisionModel;
  LIndex: Integer;
  LOriginalPolygons: TArray<TCmPolygon>;
  LCopyPolygons: TArray<TCmPolygon>;
  LOriginalBrushes: TArray<TCmBrush>;
  LCopyBrushes: TArray<TCmBrush>;
  LText: string;
  LModelsAgain: TObjectList<TCollisionModel>;

  function DescribePolygons(const APolygons: TArray<TCmPolygon>): TArray<string>;
  var
    LI: Integer;
    LJ: Integer;
    LEdges: string;
  begin
    SetLength(Result, Length(APolygons));
    for LI := 0 to High(APolygons) do
    begin
      LEdges := '';
      for LJ := 0 to APolygons[LI].NumEdges - 1 do
        LEdges := LEdges + IntToStr(APolygons[LI].Edges[LJ]) + ',';
      Result[LI] := Format('%s|%d|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%.3f|%s', [LEdges, APolygons[LI].Contents,
        APolygons[LI].Plane.A, APolygons[LI].Plane.B, APolygons[LI].Plane.C, APolygons[LI].Plane.Dist,
        APolygons[LI].Bounds.Mins.X, APolygons[LI].Bounds.Mins.Y, APolygons[LI].Bounds.Mins.Z,
        APolygons[LI].Bounds.Maxs.X, APolygons[LI].Bounds.Maxs.Y, APolygons[LI].Material.Name]);
    end;
  end;

  function DescribeBrushes(const ABrushes: TArray<TCmBrush>): TArray<string>;
  var
    LI: Integer;
    LJ: Integer;
    LPlanes: string;
  begin
    SetLength(Result, Length(ABrushes));
    for LI := 0 to High(ABrushes) do
    begin
      LPlanes := '';
      for LJ := 0 to ABrushes[LI].NumPlanes - 1 do
        LPlanes := LPlanes + Format('%.3f %.3f %.3f %.3f;', [ABrushes[LI].Planes[LJ].A, ABrushes[LI].Planes[LJ].B,
          ABrushes[LI].Planes[LJ].C, ABrushes[LI].Planes[LJ].Dist]);
      Result[LI] := Format('%d|%.3f|%.3f|%.3f|%s', [ABrushes[LI].Contents, ABrushes[LI].Bounds.Mins.X,
        ABrushes[LI].Bounds.Maxs.Y, ABrushes[LI].Bounds.Maxs.Z, LPlanes]);
    end;
  end;

  function SameStrings(AFirst, ASecond: TArray<string>): Boolean;
  var
    LI: Integer;
  begin
    TArray.Sort<string>(AFirst);
    TArray.Sort<string>(ASecond);
    Result := Length(AFirst) = Length(ASecond);
    if Result then
      for LI := 0 to High(AFirst) do
        if AFirst[LI] <> ASecond[LI] then
          Exit(False);
  end;

  procedure CompareNodes(ANode, AOther: TCmNode);
  begin
    Assert.AreEqual(ANode.PlaneType, AOther.PlaneType);
    Assert.AreEqual(ANode.PlaneDist, AOther.PlaneDist, 1e-4);
    Assert.AreEqual(ANode.Polygons.Count, AOther.Polygons.Count);
    Assert.AreEqual(ANode.Brushes.Count, AOther.Brushes.Count);
    if not ANode.IsLeaf then
    begin
      CompareNodes(ANode.Children[0], AOther.Children[0]);
      CompareNodes(ANode.Children[1], AOther.Children[1]);
    end;
  end;

begin
  LOriginal := TCollisionModel(BuildGrid(5));
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    LText := TCollisionFileWriter.ToText([LOriginal], 123456);
    LModels := LReader.Parse(LText, 123456);
    try
      Assert.IsNotNull(LModels);
      LCopy := LModels[0];
      Assert.AreEqual(LOriginal.Name, LCopy.Name);
      Assert.AreEqual(LOriginal.NumVertices, LCopy.NumVertices);
      Assert.AreEqual(LOriginal.NumEdges, LCopy.NumEdges);
      Assert.AreEqual(LOriginal.Contents, LCopy.Contents);
      Assert.AreEqual(LOriginal.Bounds.Mins.X, LCopy.Bounds.Mins.X, 1e-4);
      Assert.AreEqual(LOriginal.Bounds.Maxs.Y, LCopy.Bounds.Maxs.Y, 1e-4);
      for LIndex := 0 to LOriginal.NumVertices - 1 do
      begin
        Assert.AreEqual(LOriginal.Vertices[LIndex].P.X, LCopy.Vertices[LIndex].P.X, 1e-4);
        Assert.AreEqual(LOriginal.Vertices[LIndex].P.Y, LCopy.Vertices[LIndex].P.Y, 1e-4);
        Assert.AreEqual(LOriginal.Vertices[LIndex].P.Z, LCopy.Vertices[LIndex].P.Z, 1e-4);
      end;
      for LIndex := 0 to LOriginal.NumEdges - 1 do
      begin
        Assert.AreEqual(LOriginal.Edges[LIndex].VertexNum[0], LCopy.Edges[LIndex].VertexNum[0]);
        Assert.AreEqual(LOriginal.Edges[LIndex].VertexNum[1], LCopy.Edges[LIndex].VertexNum[1]);
        Assert.AreEqual(Integer(LOriginal.Edges[LIndex].NumUsers), Integer(LCopy.Edges[LIndex].NumUsers));
        Assert.AreEqual(LOriginal.Edges[LIndex].Normal.X, LCopy.Edges[LIndex].Normal.X, 1e-4);
        Assert.AreEqual(LOriginal.Edges[LIndex].Normal.Z, LCopy.Edges[LIndex].Normal.Z, 1e-4);
      end;
      CompareNodes(LOriginal.Node, LCopy.Node);
      // the order of the polygons in a node is reversed by reading (each one goes to the head
      // of the chain, as in the C++ code), so they are compared as sets of descriptions
      LOriginalPolygons := LOriginal.TreePolygons;
      LCopyPolygons := LCopy.TreePolygons;
      Assert.AreEqual(Integer(Length(LOriginalPolygons)), Integer(Length(LCopyPolygons)));
      Assert.IsTrue(Integer(Length(LOriginalPolygons)) > 100);
      Assert.AreEqual(Integer(Length(LOriginalPolygons)), Integer(Length(LCopy.TreePolygons)));
      Assert.IsTrue(SameStrings(DescribePolygons(LOriginalPolygons), DescribePolygons(LCopyPolygons)));
      LOriginalBrushes := LOriginal.TreeBrushes;
      LCopyBrushes := LCopy.TreeBrushes;
      Assert.AreEqual(25, Integer(Length(LCopyBrushes)));
      Assert.IsTrue(SameStrings(DescribeBrushes(LOriginalBrushes), DescribeBrushes(LCopyBrushes)));
      // writing what was read and reading it again restores the first order: the text is the same
      LModelsAgain := LReader.Parse(TCollisionFileWriter.ToText([LCopy], 123456), 123456);
      try
        Assert.AreEqual(LText, TCollisionFileWriter.ToText([LModelsAgain[0]], 123456));
      finally
        LModelsAgain.Free;
      end;
    finally
      LModels.Free;
    end;
  finally
    LReader.Free;
    LOriginal.Free;
  end;
end;

procedure TTestCollisionFile.TestRoundTripKeepsTheQueryResults;
var
  LOriginal: TCollisionModel;
  LManager: ICollisionModelManager;
  LStream: TMemoryStream;
  LBytes: TBytes;
  LText: string;
  LHandleA: Integer;
  LHandleB: Integer;
  LResultA: TCollisionTrace;
  LResultB: TCollisionTrace;
  LTrm: TTraceModel;
  LIndex: Integer;
  LStart: TGeoVec3;
  LEnd: TGeoVec3;
begin
  LOriginal := TCollisionModel(BuildGrid(5));
  LManager := TCollisionFactory.CreateManager(FCatalog, nil);
  LStream := TMemoryStream.Create;
  LTrm := TTraceModel.CreateBox(Bounds3(-6, -6, -6, 6, 6, 6));
  try
    LText := TCollisionFileWriter.ToText([LOriginal], 0);
    LBytes := TEncoding.UTF8.GetBytes(LText);
    LStream.WriteBuffer(LBytes[0], Length(LBytes));
    LStream.Position := 0;
    LHandleA := LManager.AddModel(LOriginal);
    Assert.AreEqual(1, LManager.LoadModelFile(LStream));
    // the model read from the file is the next one
    LHandleB := LHandleA + 1;
    for LIndex := 0 to 59 do
    begin
      LStart := TGeoVec3.Make(-150 + LIndex * 17, -100 + (LIndex mod 7) * 160, 50);
      LEnd := TGeoVec3.Make(1100 - LIndex * 11, 900 - (LIndex mod 5) * 250, 30 + LIndex);
      LManager.Translation(LResultA, LStart, LEnd, LTrm, TGeoMat3.Identity, CONTENTS_SOLID, LHandleA,
        TGeoVec3.Origin, TGeoMat3.Identity);
      LManager.Translation(LResultB, LStart, LEnd, LTrm, TGeoMat3.Identity, CONTENTS_SOLID, LHandleB,
        TGeoVec3.Origin, TGeoMat3.Identity);
      Assert.AreEqual(LResultA.Fraction, LResultB.Fraction, 1e-4, 'trace ' + IntToStr(LIndex));
      Assert.AreEqual(LResultA.C.Normal.X, LResultB.C.Normal.X, 1e-4);
    end;
  finally
    LTrm.Free;
    LStream.Free;
    LManager := nil;
  end;
end;

procedure TTestCollisionFile.TestSeveralModelsInOneFile;
var
  LFirst: TCollisionModel;
  LSecond: TCollisionModel;
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
begin
  LFirst := TCollisionModel(BuildGrid(2));
  LSecond := TCollisionModel(BuildGrid(3));
  LSecond.Name := 'bigger grid';
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    LModels := LReader.Parse(TCollisionFileWriter.ToText([LFirst, LSecond], 99), 99);
    try
      Assert.AreEqual(2, LModels.Count);
      Assert.AreEqual('grid', LModels[0].Name);
      Assert.AreEqual('bigger grid', LModels[1].Name);
      Assert.AreEqual(LSecond.NumVertices, LModels[1].NumVertices);
    finally
      LModels.Free;
    end;
  finally
    LReader.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestCollisionFile.TestStreamRoundTrip;
var
  LModel: TCollisionModel;
  LStream: TMemoryStream;
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
begin
  LModel := TCollisionModel(BuildGrid(2));
  LStream := TMemoryStream.Create;
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    TCollisionFileWriter.ToStream(LStream, [LModel], 7);
    LStream.Position := 0;
    LModels := LReader.LoadFromStream(LStream, 7);
    try
      Assert.IsNotNull(LModels);
      Assert.AreEqual(1, LModels.Count);
      Assert.AreEqual(LModel.NumEdges, LModels[0].NumEdges);
    finally
      LModels.Free;
    end;
  finally
    LReader.Free;
    LStream.Free;
    LModel.Free;
  end;
end;

procedure TTestCollisionFile.TestFileThatIsNotACmFileIsRejected;
var
  LReader: TCollisionFileReader;
begin
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    Assert.IsNull(LReader.Parse('hello "1.00"'#10'0'#10));
    Assert.IsNull(LReader.Parse(''));
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestOtherVersionIsRejected;
var
  LReader: TCollisionFileReader;
begin
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    Assert.IsNull(LReader.Parse('CM "2.00"'#10'0'#10));
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestOutOfDateCrcIsRejected;
var
  LReader: TCollisionFileReader;
begin
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    Assert.IsNull(LReader.Parse('CM "1.00"'#10'12345'#10, 99));
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestMapCrcZeroAcceptsAnyFile;
var
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
begin
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    LModels := LReader.Parse('CM "1.00"'#10'4000000000'#10, 0);
    try
      Assert.IsNotNull(LModels);
      Assert.AreEqual(0, LModels.Count);
    finally
      LModels.Free;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestBadTokenInTheBodyRaises;
var
  LReader: TCollisionFileReader;
begin
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.Parse('CM "1.00"'#10'0'#10'collisionModel "x" { wibble }'#10);
      end, ECollisionFormatException);
    Assert.WillRaise(
      procedure
      begin
        LReader.Parse('CM "1.00"'#10'0'#10'something'#10);
      end, ECollisionFormatException);
    // a number that is not one
    Assert.WillRaise(
      procedure
      begin
        LReader.Parse('CM "1.00"'#10'0'#10'collisionModel "x" { vertices { 1 ( a 0 0 ) } }'#10);
      end, ECollisionFormatException);
    // the end of the text in the middle of a model
    Assert.WillRaise(
      procedure
      begin
        LReader.Parse('CM "1.00"'#10'0'#10'collisionModel "x" { vertices { 2 ( 0 0 0 )'#10);
      end, ECollisionFormatException);
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestOldFilesWithNumericContentsAreAccepted;
var
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
  LText: string;
begin
  // a brush written the old way: the contents are one integer
  LText := 'CM "1.00"'#10'0'#10 +
    'collisionModel "old" {'#10 +
    #9'vertices { 0 }'#10 +
    #9'edges { 0 }'#10 +
    #9'nodes {'#10 + #9'( -1 0 )'#10 + #9'}'#10 +
    #9'polygons {'#10 + #9'}'#10 +
    #9'brushes {'#10 +
    #9'6 {'#10 +
    #9#9'( 1 0 0 ) 8'#10 + #9#9'( -1 0 0 ) 8'#10 + #9#9'( 0 1 0 ) 8'#10 +
    #9#9'( 0 -1 0 ) 8'#10 + #9#9'( 0 0 1 ) 8'#10 + #9#9'( 0 0 -1 ) 8'#10 +
    #9'} ( -8 -8 -8 ) ( 8 8 8 ) 9'#10 +
    #9'}'#10 +
    '}'#10;
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    LModels := LReader.Parse(LText);
    try
      Assert.AreEqual(1, LModels.Count);
      Assert.AreEqual(9, LModels[0].Contents);
      Assert.AreEqual(1, Integer(Length(LModels[0].TreeBrushes)));
      Assert.AreEqual(6, LModels[0].TreeBrushes[0].NumPlanes);
      Assert.AreEqual(8.0, LModels[0].TreeBrushes[0].Planes[0].Dist, 1e-6);
    finally
      LModels.Free;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestCommentsAndOptionalMemoryNumbersAreSkipped;
var
  LReader: TCollisionFileReader;
  LModels: TObjectList<TCollisionModel>;
  LText: string;
begin
  // the numbers after "polygons" and "brushes" are optional, and comments are skipped
  LText := '// a comment'#10'CM "1.00" /* inline */'#10'0'#10 +
    'collisionModel "c" {'#10 +
    #9'vertices { /* numVertices = */ 0 }'#10 +
    #9'edges { 1'#10 + #9'/* 0 */ ( 0 0 ) 0 0'#10 + #9'}'#10 +
    #9'nodes { ( -1 0 ) }'#10 +
    #9'polygons { }'#10 +
    #9'brushes /* brushMemory = */ 0 { }'#10 +
    '}'#10;
  LReader := TCollisionFileReader.Create(FCatalog, nil);
  try
    LModels := LReader.Parse(LText);
    try
      Assert.AreEqual(1, LModels.Count);
      Assert.AreEqual(0, LModels[0].NumVertices);
      Assert.AreEqual(1, LModels[0].NumEdges);
      Assert.AreEqual(0, LModels[0].Contents);
    finally
      LModels.Free;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TTestCollisionFile.TestContentsNames;
begin
  Assert.AreEqual('solid', TCollisionContentsNames.StringFromContents(CONTENTS_SOLID));
  Assert.AreEqual('solid,playerclip', TCollisionContentsNames.StringFromContents(CONTENTS_SOLID or CONTENTS_PLAYERCLIP));
  Assert.AreEqual('', TCollisionContentsNames.StringFromContents(0));
  Assert.AreEqual(CONTENTS_SOLID or CONTENTS_WATER, TCollisionContentsNames.ContentsFromString('Solid, water'));
  Assert.AreEqual(0, TCollisionContentsNames.ContentsFromString('nothing'));
  Assert.AreEqual(CONTENTS_FLASHLIGHT_TRIGGER, TCollisionContentsNames.ContentsFromString('flashlight_trigger'));
  // areaportal and nocsg have no name: they are not written
  Assert.AreEqual('', TCollisionContentsNames.StringFromContents(CONTENTS_AREAPORTAL or CONTENTS_NOCSG));
end;

procedure TTestCollisionFile.TestHashIndexReturnsTheLastAddedFirst;
var
  LHash: TCmHashIndex;
  LKey: Integer;
begin
  LHash := TCmHashIndex.Create(16, 4);
  try
    Assert.AreEqual(-1, LHash.First(5));
    LHash.Add(5, 0);
    LHash.Add(5, 1);
    LHash.Add(21, 2); // 21 and 5 are the same key modulo 16
    LHash.Add(6, 3);
    LKey := LHash.First(5);
    Assert.AreEqual(2, LKey);
    LKey := LHash.Next(LKey);
    Assert.AreEqual(1, LKey);
    LKey := LHash.Next(LKey);
    Assert.AreEqual(0, LKey);
    Assert.AreEqual(-1, LHash.Next(LKey));
    Assert.AreEqual(3, LHash.First(6));
    // the index array grows by itself
    LHash.Add(7, 100);
    Assert.AreEqual(100, LHash.First(7));
    LHash.Clear;
    Assert.AreEqual(-1, LHash.First(5));
  finally
    LHash.Free;
  end;
end;

procedure TTestCollisionFile.TestHashIndexKeysAreMasked;
var
  LHash: TCmHashIndex;
begin
  LHash := TCmHashIndex.Create(1 shl 14, 8);
  try
    Assert.AreEqual(12, LHash.GenerateKey(12));
    Assert.AreEqual((7 + 9) and 16383, LHash.GenerateKey(7, 9));
    Assert.AreEqual(3, LHash.GenerateKey(16384 + 2, 1));
  finally
    LHash.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCollisionFile);

end.
