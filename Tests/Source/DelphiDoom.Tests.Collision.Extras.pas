{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests with values worked out by hand of the pieces added by the  }
{  issues #108 and #118: the rotation of a trace model, the bone trace model,   }
{  the split of a winding, the grid and the facets of a Quake III patch, the    }
{  chopping of polygons by the proc BSP tree                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Extras;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('collision')]
  TTestCollisionExtras = class(TObject)
  public
    [Test]
    procedure DovrebbeFermareUnPuntoCheRuotaControUnMuro;
    [Test]
    procedure DovrebbeNonUrtareSeLaRotazioneNonRaggiungeIlMuro;
    [Test]
    procedure DovrebbeFareUnMovimentoDiSolaTraslazioneORotazione;
    [Test]
    procedure DovrebbeComporreTraslazioneERotazioneNelMovimento;
    [Test]
    procedure DovrebbeFareUnaProvaDiPosizioneConAngoloZero;
    [Test]
    procedure DovrebbeDareLeMisureDellOsso;
    [Test]
    procedure DovrebbeDividereUnWindingSulPiano;
    [Test]
    procedure DovrebbeDireSeUnWindingStaInSolidoNelProc;
    [Test]
    procedure DovrebbeRiconoscereLaColonnaChiusaDiUnaGriglia;
    [Test]
    procedure DovrebbeLevareLeColonneUguali;
    [Test]
    procedure DovrebbeSuddividereUnaCurvaTroppoCurva;
    [Test]
    procedure DovrebbeRifiutareLeSuperficiNonValide;
    [Test]
    procedure DovrebbeFermareUnaScatolaSuUnaPatchPiana;
    [Test]
    procedure DovrebbeFarUrtareUnaCapsulaControUnaPatch;
    [Test]
    procedure DovrebbeIgnorareLaPatchPerUnPuntoSeIlTagliaCurveENonCeSpento;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Winding, DelphiDoom.Geometry.TraceModel, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Rotation, DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf,
  DelphiDoom.Collision.Factory, DelphiDoom.Collision.Builder, DelphiDoom.Collision.Builder.Chopper,
  DelphiDoom.Collision.Motion,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Intf, DelphiDoom.Collision.Q3.PatchGrid,
  DelphiDoom.Collision.Q3.PatchCollideBuilder, DelphiDoom.Tests.Collision.Support;

function Handle(const AManager: ICollisionModelManager; const ACatalog: ICollisionMaterialCatalog;
  const ABounds: TGeoBounds): Integer;
var
  LSource: ICollisionGeometrySource;
  LBuilder: TCollisionModelBuilder;
  LFake: TFakeGeometrySource;
begin
  LFake := TFakeGeometrySource.Create('wall');
  LSource := LFake;
  LFake.AddBox(ABounds, ACatalog.FindMaterial('textures/solid'));
  LBuilder := TCollisionFactory.CreateBuilder(nil);
  try
    Result := AManager.AddModel(LBuilder.Build(LSource));
  finally
    LBuilder.Free;
  end;
end;

procedure TTestCollisionExtras.DovrebbeFermareUnPuntoCheRuotaControUnMuro;
var
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LModel: Integer;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
  LExpectedAngle: Double;
begin
  LCatalog := CreateDoom3Catalog;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  // a wall 10 thick whose outer face is the plane x = 110, long in y and z
  LModel := Handle(LManager, LCatalog, Bounds3(100, -300, -100, 110, 300, 100));
  // a point at (150, 0, 0) turning about the z axis through the origin: its circle of radius 150 reaches the
  // plane x = 110 + 0.25 (the clip epsilon) at acos( 110.25 / 150 ) degrees
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 90);
  LManager.Rotation(LTrace, TGeoVec3.Make(150, 0, 0), LRotation, nil, TGeoMat3.Identity, -1, LModel,
    TGeoVec3.Origin, TGeoMat3.Identity);
  LExpectedAngle := ArcCos(110.25 / 150) * 180 / Pi;
  Assert.IsTrue(LTrace.Fraction < 1, 'the point passes through the wall');
  Assert.AreEqual(LExpectedAngle / 90, Double(LTrace.Fraction), 0.002);
  // the contact is on the face x = 110: a normal along +x, in the contents of the wall
  Assert.AreEqual(1.0, Double(LTrace.C.Normal.X), 0.01);
  Assert.AreEqual(CONTENTS_SOLID, LTrace.C.Contents);
  // the end position is on the circle, at the angle of the hit
  Assert.AreEqual(150.0, Double(Sqrt(Sqr(LTrace.EndPos.X) + Sqr(LTrace.EndPos.Y))), 0.05);
end;

procedure TTestCollisionExtras.DovrebbeNonUrtareSeLaRotazioneNonRaggiungeIlMuro;
var
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LModel: Integer;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
begin
  LCatalog := CreateDoom3Catalog;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  LModel := Handle(LManager, LCatalog, Bounds3(100, -300, -100, 110, 300, 100));
  // radius 50: the circle stays inside the wall's plane x = 100 (a point at 50 never gets to x = 100)
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 300);
  LManager.Rotation(LTrace, TGeoVec3.Make(50, 0, 0), LRotation, nil, TGeoMat3.Identity, -1, LModel,
    TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(1.0, Double(LTrace.Fraction), 1E-6);
  // 300 degrees is turned in two steps of 150: it ends at 300 degrees
  Assert.AreEqual(50 * Cos(300 * Pi / 180), Double(LTrace.EndPos.X), 0.01);
  // (the rotation of idlib turns a positive angle about z towards -y)
  Assert.AreEqual(-50 * Sin(300 * Pi / 180), Double(LTrace.EndPos.Y), 0.01);
  // more than 360 is turned 360 (the original does so): back at the start
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 400);
  LManager.Rotation(LTrace, TGeoVec3.Make(50, 0, 0), LRotation, nil, TGeoMat3.Identity, -1, LModel,
    TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(1.0, Double(LTrace.Fraction), 1E-6);
  Assert.AreEqual(50.0, Double(LTrace.EndPos.X), 0.01);
  Assert.AreEqual(0.0, Double(LTrace.EndPos.Y), 0.01);
end;

procedure TTestCollisionExtras.DovrebbeFareUnMovimentoDiSolaTraslazioneORotazione;
var
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LModel: Integer;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
  LNoRotation: TIdRotation;
begin
  LCatalog := CreateDoom3Catalog;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  LModel := Handle(LManager, LCatalog, Bounds3(100, -300, -100, 110, 300, 100));
  LNoRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 0), 0);
  // pure translation: the same as Translation (the point stops 0.25 before x = 100)
  Assert.IsTrue(TCollisionMotion.Motion(LManager, LTrace, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(200, 0, 0),
    LNoRotation, nil, TGeoMat3.Identity, -1, LModel, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.AreEqual(99.75 / 200, Double(LTrace.Fraction), 1E-5);
  // no motion at all
  Assert.IsFalse(TCollisionMotion.Motion(LManager, LTrace, TGeoVec3.Make(5, 0, 0), TGeoVec3.Make(5, 0, 0),
    LNoRotation, nil, TGeoMat3.Identity, -1, LModel, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.AreEqual(1.0, Double(LTrace.Fraction), 1E-6);
  Assert.AreEqual(5.0, Double(LTrace.EndPos.X), 1E-6);
  // pure rotation: a point at (150, 0, 0) turning about the origin hits the wall as in the rotation test
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 90);
  Assert.IsTrue(TCollisionMotion.Motion(LManager, LTrace, TGeoVec3.Make(150, 0, 0), TGeoVec3.Make(150, 0, 0),
    LRotation, nil, TGeoMat3.Identity, -1, LModel, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.IsTrue(LTrace.Fraction < 1);
  // a translation over a huge distance is a hit at fraction 0
  Assert.IsTrue(TCollisionMotion.Motion(LManager, LTrace, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(9000, 0, 0),
    LNoRotation, nil, TGeoMat3.Identity, -1, LModel, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.AreEqual(0.0, Double(LTrace.Fraction), 1E-6);
end;

procedure TTestCollisionExtras.DovrebbeComporreTraslazioneERotazioneNelMovimento;
var
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LModel: Integer;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
begin
  LCatalog := CreateDoom3Catalog;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  LModel := Handle(LManager, LCatalog, Bounds3(100, -300, -100, 110, 300, 100));
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 30);
  // the translation hits the wall, the rotation of a point about itself does not move: it hits, and the
  // fraction is the larger of the two (1) as in idClip::Motion
  Assert.IsTrue(TCollisionMotion.Motion(LManager, LTrace, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(200, 0, 0),
    LRotation, nil, TGeoMat3.Identity, -1, LModel, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.AreEqual(1.0, Double(LTrace.Fraction), 1E-6);
  Assert.AreEqual(99.75, Double(LTrace.EndPos.X), 1E-3);
  // free of the wall: no hit
  Assert.IsFalse(TCollisionMotion.Motion(LManager, LTrace, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(50, 0, 0),
    LRotation, nil, TGeoMat3.Identity, -1, LModel, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.AreEqual(1.0, Double(LTrace.Fraction), 1E-6);
end;

procedure TTestCollisionExtras.DovrebbeFareUnaProvaDiPosizioneConAngoloZero;
var
  LCatalog: ICollisionMaterialCatalog;
  LManager: ICollisionModelManager;
  LModel: Integer;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
begin
  LCatalog := CreateDoom3Catalog;
  LManager := TCollisionFactory.CreateManager(LCatalog, nil);
  LModel := Handle(LManager, LCatalog, Bounds3(100, -300, -100, 110, 300, 100));
  LRotation := TIdRotation.Create(TIdVec3.Create(0, 0, 0), TIdVec3.Create(0, 0, 1), 0);
  // inside the wall: the position test finds the contents
  LManager.Rotation(LTrace, TGeoVec3.Make(105, 0, 0), LRotation, nil, TGeoMat3.Identity, -1, LModel,
    TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(0.0, Double(LTrace.Fraction), 1E-6);
  Assert.AreEqual(CONTENTS_SOLID, LTrace.C.Contents);
  // outside it: nothing
  LManager.Rotation(LTrace, TGeoVec3.Make(50, 0, 0), LRotation, nil, TGeoMat3.Identity, -1, LModel,
    TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(1.0, Double(LTrace.Fraction), 1E-6);
end;

procedure TTestCollisionExtras.DovrebbeDareLeMisureDellOsso;
var
  LBone: TTraceModel;
begin
  LBone := TTraceModel.Create;
  try
    LBone.SetupBone(40, 10);
    Assert.AreEqual(5, LBone.NumVerts);
    Assert.AreEqual(9, LBone.NumEdges);
    Assert.AreEqual(6, LBone.NumPolys);
    Assert.IsTrue(LBone.IsConvex);
    // the bounds: half the width on x and y (a quarter forward), half the length on z
    Assert.AreEqual(-5.0, Double(LBone.Bounds.Mins.X), 1E-6);
    Assert.AreEqual(-5.0, Double(LBone.Bounds.Mins.Y), 1E-6);
    Assert.AreEqual(-20.0, Double(LBone.Bounds.Mins.Z), 1E-6);
    Assert.AreEqual(5.0, Double(LBone.Bounds.Maxs.X), 1E-6);
    Assert.AreEqual(2.5, Double(LBone.Bounds.Maxs.Y), 1E-6);
    Assert.AreEqual(20.0, Double(LBone.Bounds.Maxs.Z), 1E-6);
    // the tips are on the axis
    Assert.AreEqual(-20.0, Double(LBone.Verts[0].Z), 1E-6);
    Assert.AreEqual(20.0, Double(LBone.Verts[4].Z), 1E-6);
    // the faces have unit normals and every vertex is behind or on the plane of every face (convex)
    Assert.AreEqual(1.0, Double(LBone.Polys[0].Normal.Length), 1E-5);
    Assert.IsTrue(LBone.Polys[0].Normal.Dot(LBone.Verts[3]) - LBone.Polys[0].Dist <= 1E-4);
    // setting it up again with other measures keeps the structure
    LBone.SetupBone(80, 20);
    Assert.AreEqual(40.0, Double(LBone.Bounds.Maxs.Z), 1E-6);
  finally
    LBone.Free;
  end;
end;

procedure TTestCollisionExtras.DovrebbeDividereUnWindingSulPiano;
var
  LWinding: TGeoWinding;
  LBack: TGeoWinding;
  LPlane: TGeoPlane;
begin
  LWinding := TGeoWinding.Create([TGeoVec3.Make(-10, -10, 0), TGeoVec3.Make(10, -10, 0), TGeoVec3.Make(10, 10, 0),
    TGeoVec3.Make(-10, 10, 0)]);
  LBack := TGeoWinding.Create;
  try
    // the plane x = 0 cuts the square in two rectangles; the axial plane takes the exact value for the new points
    LPlane := TGeoPlane.Make(1, 0, 0, 0);
    Assert.AreEqual(3, LWinding.Split(LBack, LPlane, 0.1));
    Assert.AreEqual(4, LWinding.NumPoints);
    Assert.AreEqual(4, LBack.NumPoints);
    Assert.AreEqual(0.0, Double(LWinding.GetBounds.Mins.X), 1E-6);
    Assert.AreEqual(10.0, Double(LWinding.GetBounds.Maxs.X), 1E-6);
    Assert.AreEqual(-10.0, Double(LBack.GetBounds.Mins.X), 1E-6);
    Assert.AreEqual(0.0, Double(LBack.GetBounds.Maxs.X), 1E-6);
    // a plane that does not cut leaves both alone
    LPlane := TGeoPlane.Make(1, 0, 0, -50);
    Assert.AreEqual(1, LWinding.Split(LBack, LPlane, 0.1)); // behind
    LPlane := TGeoPlane.Make(1, 0, 0, 50);
    Assert.AreEqual(0, LWinding.Split(LBack, LPlane, 0.1)); // in front
    LPlane := TGeoPlane.Make(0, 0, 1, 0);
    Assert.AreEqual(2, LWinding.Split(LBack, LPlane, 0.1)); // on the plane
  finally
    LBack.Free;
    LWinding.Free;
  end;
end;

procedure TTestCollisionExtras.DovrebbeDireSeUnWindingStaInSolidoNelProc;
var
  LNodes: TArray<TCollisionProcNode>;
  LChopper: TCollisionChopper;
  LWinding: TGeoWinding;
  LPlane: TGeoPlane;

  function Square(AX0, AX1, AY0, AY1: Single): TGeoWinding;
  begin
    Result := TGeoWinding.Create([TGeoVec3.Make(AX0, AY0, 0), TGeoVec3.Make(AX1, AY0, 0), TGeoVec3.Make(AX1, AY1, 0),
      TGeoVec3.Make(AX0, AY1, 0)]);
  end;

begin
  SetLength(LNodes, 2);
  // node 0: the plane x = 0, in front the node 1, behind solid
  LNodes[0].Plane := TGeoPlane.Make(1, 0, 0, 0);
  LNodes[0].Children[0] := 1;
  LNodes[0].Children[1] := 0;
  // node 1: the plane y = 0, in front the area 0 (-1), behind solid
  LNodes[1].Plane := TGeoPlane.Make(0, 1, 0, 0);
  LNodes[1].Children[0] := -1;
  LNodes[1].Children[1] := 0;
  LPlane := TGeoPlane.Make(0, 0, 1, 0);

  LChopper := TCollisionChopper.Create(nil, nil, LNodes, True, nil);
  try
    // behind the first plane: solid
    LWinding := Square(-50, -20, 10, 40);
    try
      Assert.IsTrue(LChopper.ChoppedAwayByProcBSP(LWinding, LPlane, CONTENTS_SOLID));
      // not solid contents are never chopped
      Assert.IsFalse(LChopper.ChoppedAwayByProcBSP(LWinding, LPlane, CONTENTS_WATER));
    finally
      LWinding.Free;
    end;
    // in front of both: the area
    LWinding := Square(20, 50, 10, 40);
    try
      Assert.IsFalse(LChopper.ChoppedAwayByProcBSP(LWinding, LPlane, CONTENTS_SOLID));
    finally
      LWinding.Free;
    end;
    // across the first plane, in front of the second: the front part is in the area
    LWinding := Square(-20, 20, 10, 40);
    try
      Assert.IsFalse(LChopper.ChoppedAwayByProcBSP(LWinding, LPlane, CONTENTS_SOLID));
    finally
      LWinding.Free;
    end;
    // across both planes: one side is solid, the other not
    LWinding := Square(-20, 20, -20, 20);
    try
      Assert.IsFalse(LChopper.ChoppedAwayByProcBSP(LWinding, LPlane, CONTENTS_SOLID));
    finally
      LWinding.Free;
    end;
    // lying on the plane x = 0 and facing it: follows the side the polygon looks at
    LWinding := TGeoWinding.Create([TGeoVec3.Make(0, 10, 0), TGeoVec3.Make(0, 40, 0), TGeoVec3.Make(0, 40, 30),
      TGeoVec3.Make(0, 10, 30)]);
    try
      Assert.IsFalse(LChopper.ChoppedAwayByProcBSP(LWinding, TGeoPlane.Make(1, 0, 0, 0), CONTENTS_SOLID));
      Assert.IsTrue(LChopper.ChoppedAwayByProcBSP(LWinding, TGeoPlane.Make(-1, 0, 0, 0), CONTENTS_SOLID));
    finally
      LWinding.Free;
    end;
  finally
    LChopper.Free;
  end;
  // without nodes nothing is chopped
  LChopper := TCollisionChopper.Create(nil, nil, nil, True, nil);
  try
    LWinding := Square(-50, -20, 10, 40);
    try
      Assert.IsFalse(LChopper.ChoppedAwayByProcBSP(LWinding, LPlane, CONTENTS_SOLID));
    finally
      LWinding.Free;
    end;
  finally
    LChopper.Free;
  end;
end;

function Point3(AX, AY, AZ: Single): TQ3Vec3;
begin
  Result[0] := AX;
  Result[1] := AY;
  Result[2] := AZ;
end;

function Row(const ACount: Integer; const AZ: array of Single): TArray<TQ3Vec3>;
var
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Point3(LIndex * 64 - 64, 0, AZ[LIndex]);
end;

/// <summary>The control points of a width x 3 patch, three rows of the same shape one 64 units behind the other</summary>
function ThreeRows(const AWidth: Integer; const AZ: array of Single): TArray<TQ3Vec3>;
var
  LRow, LColumn: Integer;
begin
  SetLength(Result, AWidth * 3);
  for LRow := 0 to 2 do
    for LColumn := 0 to AWidth - 1 do
      Result[LRow * AWidth + LColumn] := Point3(LColumn * 64 - 64 * (AWidth div 2), LRow * 64 - 64, AZ[LColumn]);
end;

procedure TTestCollisionExtras.DovrebbeRiconoscereLaColonnaChiusaDiUnaGriglia;
var
  LGrid: TQ3PatchGrid;
begin
  LGrid := TQ3PatchGrid.Create;
  try
    // the first and the last column are the same points: a closed patch
    LGrid.Load(5, 3, ThreeRows(5, [0, 10, 20, 10, 0]));
    LGrid.SetWrapWidth;
    Assert.IsFalse(LGrid.WrapWidth);
    LGrid.Load(5, 3, [Point3(0, 0, 0), Point3(10, 0, 0), Point3(0, 10, 0), Point3(-10, 0, 0), Point3(0, 0, 0),
      Point3(0, 0, 5), Point3(10, 0, 5), Point3(0, 10, 5), Point3(-10, 0, 5), Point3(0, 0, 5),
      Point3(0, 0, 10), Point3(10, 0, 10), Point3(0, 10, 10), Point3(-10, 0, 10), Point3(0, 0, 10)]);
    LGrid.SetWrapWidth;
    Assert.IsTrue(LGrid.WrapWidth);
    // the transposed grid has the flags swapped
    LGrid.Transpose;
    Assert.AreEqual(3, LGrid.Width);
    Assert.AreEqual(5, LGrid.Height);
    Assert.IsTrue(LGrid.WrapHeight);
    Assert.IsFalse(LGrid.WrapWidth);
    // and the points are where they were turned to: the old (column 2, row 1) is the new (column 1, row 2)
    Assert.AreEqual(5.0, Double(LGrid[1, 2][2]), 1E-6);
    Assert.AreEqual(10.0, Double(LGrid[1, 2][1]), 1E-6);
  finally
    LGrid.Free;
  end;
end;

procedure TTestCollisionExtras.DovrebbeLevareLeColonneUguali;
var
  LGrid: TQ3PatchGrid;
  LPoints: TArray<TQ3Vec3>;
  LRow, LColumn: Integer;
begin
  LGrid := TQ3PatchGrid.Create;
  try
    // 5 columns, the second and the third are the same (a flat strip)
    SetLength(LPoints, 15);
    for LRow := 0 to 2 do
      for LColumn := 0 to 4 do
        LPoints[LRow * 5 + LColumn] := Point3(Max(LColumn - 1, 0) * 32 * 1.0 - 32 * Ord(LColumn = 2), LRow * 64, 0);
    LGrid.Load(5, 3, LPoints);
    LGrid.RemoveDegenerateColumns;
    Assert.IsTrue(LGrid.Width < 5, 'a column was not removed');
    // a flat curve has all the middle points on the chord: the approximating column collapses
    LGrid.Load(3, 3, ThreeRows(3, [0, 0, 0]));
    LGrid.SubdivideColumns;
    Assert.AreEqual(2, LGrid.Width);
  finally
    LGrid.Free;
  end;
end;

procedure TTestCollisionExtras.DovrebbeSuddividereUnaCurvaTroppoCurva;
var
  LGrid: TQ3PatchGrid;
begin
  LGrid := TQ3PatchGrid.Create;
  try
    // the middle control point 100 units off the chord: the curve passes 50 away from the chord, more than 16, so
    // the approximating point is replaced by the point on the curve, z(t) = 200 t (1 - t) = 50 at t = 1/2
    LGrid.Load(3, 3, ThreeRows(3, [0, 100, 0]));
    LGrid.SubdivideColumns;
    Assert.AreEqual(3, LGrid.Width);
    Assert.AreEqual(50.0, Double(LGrid[1, 0][2]), 1E-4);
    // a much deeper curve needs more columns
    LGrid.Load(3, 3, ThreeRows(3, [0, 800, 0]));
    LGrid.SubdivideColumns;
    Assert.IsTrue(LGrid.Width > 3, 'the curve was not subdivided');
    Assert.IsTrue(Odd(LGrid.Width));
  finally
    LGrid.Free;
  end;
end;

procedure TTestCollisionExtras.DovrebbeRifiutareLeSuperficiNonValide;
var
  LBuilder: IQ3PatchCollideBuilder;

  procedure Fails(AWidth, AHeight: Integer; const APoints: TArray<TQ3Vec3>);
  begin
    try
      LBuilder.Generate(AWidth, AHeight, APoints);
      Assert.Fail(Format('%d x %d is accepted', [AWidth, AHeight]));
    except
      on EQ3CollisionException do
        ;
    end;
  end;

begin
  LBuilder := TQ3PatchCollideBuilder.Create;
  Fails(2, 3, ThreeRows(3, [0, 0, 0]));
  Fails(3, 2, ThreeRows(3, [0, 0, 0]));
  Fails(4, 3, ThreeRows(4, [0, 0, 0, 0]));
  Fails(3, 3, nil);
  Fails(131, 3, nil);
  // too few points for the size
  Fails(3, 3, [Point3(0, 0, 0)]);
  // a 3 x 129 patch is too large for the grid
  Fails(3, 131, ThreeRows(3, [0, 0, 0]));
end;

/// <summary>The trace work of a box (or a point) at rest with the offsets that CM_BoxTrace makes</summary>
function BoxWork(const AStart, AEnd, AMins, AMaxs: TQ3Vec3; APoint: Boolean): TQ3TraceWork;
var
  LIndex, LBits, LAxis: Integer;
begin
  Result := Default(TQ3TraceWork);
  Result.Start := AStart;
  Result.EndPoint := AEnd;
  Result.Size[0] := AMins;
  Result.Size[1] := AMaxs;
  for LBits := 0 to 7 do
    for LAxis := 0 to 2 do
      // tw.offsets[signbits] is the corner of the box that is the first to meet a plane with these sign bits
      if (LBits and (1 shl LAxis)) <> 0 then
        Result.Offsets[LBits][LAxis] := AMaxs[LAxis]
      else
        Result.Offsets[LBits][LAxis] := AMins[LAxis];
  Result.IsPoint := APoint;
  Result.PlayerCurveClip := True;
  Result.Trace.Fraction := 1;
  for LIndex := 0 to 2 do
    Result.Extents[LIndex] := Max(Abs(AMins[LIndex]), Abs(AMaxs[LIndex]));
end;

procedure TTestCollisionExtras.DovrebbeFermareUnaScatolaSuUnaPatchPiana;
var
  LBuilder: IQ3PatchCollideBuilder;
  LCollide: IQ3PatchCollide;
  LWork: TQ3TraceWork;
begin
  LBuilder := TQ3PatchCollideBuilder.Create;
  // a flat 3 x 3 patch: the square [-64, 64] x [-64, 64] at z = 0
  LCollide := LBuilder.Generate(3, 3, ThreeRows(3, [0, 0, 0]));
  Assert.IsNotNull(LCollide);
  // a box 32 wide and 56 high (z from -24 to 32) falling from z = 100 to z = -100: its lowest point meets the plane
  // z = 0 + 0.125 when the centre is at 24.125; the centre moves 200 units: fraction (100 - 24.125) / 200
  LWork := BoxWork(Point3(0, 0, 100), Point3(0, 0, -100), Point3(-16, -16, -24), Point3(16, 16, 32), False);
  LCollide.TraceThrough(LWork);
  Assert.AreEqual((100 - 24.125) / 200, Double(LWork.Trace.Fraction), 1E-4);
  Assert.AreEqual(1.0, Double(LWork.Trace.Plane.Normal[2]), 1E-4);
  // the position test: a box whose bottom is under the patch and whose top is above it is inside
  LWork := BoxWork(Point3(0, 0, 0), Point3(0, 0, 0), Point3(-16, -16, -24), Point3(16, 16, 32), False);
  Assert.IsTrue(LCollide.PositionTest(LWork));
  // 200 units above it is not; beside it neither
  LWork := BoxWork(Point3(0, 0, 200), Point3(0, 0, 200), Point3(-16, -16, -24), Point3(16, 16, 32), False);
  Assert.IsFalse(LCollide.PositionTest(LWork));
  LWork := BoxWork(Point3(300, 0, 0), Point3(300, 0, 0), Point3(-16, -16, -24), Point3(16, 16, 32), False);
  Assert.IsFalse(LCollide.PositionTest(LWork));
  // a point has no volume: no position test, and it only hits the patch when cm_playerCurveClip is on
  LWork := BoxWork(Point3(0, 0, 100), Point3(0, 0, -100), Point3(0, 0, 0), Point3(0, 0, 0), True);
  LCollide.TraceThrough(LWork);
  Assert.AreEqual((100 - 0.125) / 200, Double(LWork.Trace.Fraction), 1E-4);
  Assert.IsFalse(LCollide.PositionTest(LWork));
end;

procedure TTestCollisionExtras.DovrebbeFarUrtareUnaCapsulaControUnaPatch;
var
  LBuilder: IQ3PatchCollideBuilder;
  LCollide: IQ3PatchCollide;
  LWork: TQ3TraceWork;
begin
  LBuilder := TQ3PatchCollideBuilder.Create;
  LCollide := LBuilder.Generate(3, 3, ThreeRows(3, [0, 0, 0]));
  // a capsule of radius 16 falling: the plane is pushed out by the radius, the bottom of the sphere meets z = 0.125
  LWork := BoxWork(Point3(0, 0, 100), Point3(0, 0, -100), Point3(-16, -16, -16), Point3(16, 16, 16), False);
  LWork.Sphere.Use := True;
  LWork.Sphere.Radius := 16;
  LCollide.TraceThrough(LWork);
  Assert.AreEqual((100 - 16 - 0.125) / 200, Double(LWork.Trace.Fraction), 1E-4);
  // the position test with a capsule: the centre 10 above the patch is inside (the radius is 16)
  LWork := BoxWork(Point3(0, 0, 10), Point3(0, 0, 10), Point3(-16, -16, -16), Point3(16, 16, 16), False);
  LWork.Sphere.Use := True;
  LWork.Sphere.Radius := 16;
  Assert.IsTrue(LCollide.PositionTest(LWork));
  // the offset of a capsule that has a body: the top and the bottom spheres
  LWork := BoxWork(Point3(0, 0, 100), Point3(0, 0, -100), Point3(-16, -16, -40), Point3(16, 16, 40), False);
  LWork.Sphere.Use := True;
  LWork.Sphere.Radius := 16;
  LWork.Sphere.HalfHeight := 40;
  LWork.Sphere.Offset := Point3(0, 0, 24);
  LCollide.TraceThrough(LWork);
  Assert.IsTrue(LWork.Trace.Fraction < 1);
  LWork.Sphere.Offset := Point3(0, 0, -24);
  LWork.Trace.Fraction := 1;
  LCollide.TraceThrough(LWork);
  Assert.IsTrue(LWork.Trace.Fraction < 1);
end;

procedure TTestCollisionExtras.DovrebbeIgnorareLaPatchPerUnPuntoSeIlTagliaCurveENonCeSpento;
var
  LBuilder: IQ3PatchCollideBuilder;
  LCollide: IQ3PatchCollide;
  LWork: TQ3TraceWork;
begin
  LBuilder := TQ3PatchCollideBuilder.Create;
  LCollide := LBuilder.Generate(3, 3, ThreeRows(3, [0, 0, 0]));
  LWork := BoxWork(Point3(0, 0, 100), Point3(0, 0, -100), Point3(0, 0, 0), Point3(0, 0, 0), True);
  LWork.PlayerCurveClip := False;
  LCollide.TraceThrough(LWork);
  Assert.AreEqual(1.0, Double(LWork.Trace.Fraction), 1E-6, 'cm_playerCurveClip 0: a point passes through');
  // from below: the plane is behind the start
  LWork := BoxWork(Point3(0, 0, -100), Point3(0, 0, 100), Point3(0, 0, 0), Point3(0, 0, 0), True);
  LCollide.TraceThrough(LWork);
  Assert.AreEqual(1.0, Double(LWork.Trace.Fraction), 1E-6, 'a point that comes from behind passes');
  // a trace that does not move relative to the plane
  LWork := BoxWork(Point3(0, 0, 100), Point3(10, 0, 100), Point3(0, 0, 0), Point3(0, 0, 0), True);
  LCollide.TraceThrough(LWork);
  Assert.AreEqual(1.0, Double(LWork.Trace.Fraction), 1E-6);
end;

end.
