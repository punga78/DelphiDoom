{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the collision library - translation, contents,         }
{  contacts and the manager                                                    }
{                                                                              }
{  The values are worked out by hand from the algorithm or by an independent   }
{  analytic oracle (sweep of a box against boxes). There is no run of the C++  }
{  code behind them: see README.md of the library.                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 (the library       }
{  derives from Doom 3 GPL Source Code)                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Collision.Translation;

interface

uses
  System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.TraceModel, DelphiDoom.Collision.Types,
  DelphiDoom.Collision.Intf;

type
  TBoxArray = TArray<TGeoBounds>;

  [TestFixture]
  [Category('collision')]
  TTestCollisionTranslation = class(TObject)
  private
    FCatalog: ICollisionMaterialCatalog;
    FManager: ICollisionModelManager;
    FSeed: Cardinal;
    function NextRandom: Single;
    function Between(AMin, AMax: Single): Single;
    function AddBoxes(const ABoxes: TBoxArray; const AName: string): Integer;
    function RandomBoxes(ACount: Integer; ASpread, AMinSize, AMaxSize: Integer): TBoxArray;
    procedure RunSweepOracle(const ABoxes: TBoxArray; AIterations: Integer; ASpread, AMaxLength: Single;
      ATrm: TTraceModel; out ATested, AHits: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestPointHitsAFaceOfTheBox;
    [Test]
    procedure TestBoxTraceModelHitsAFaceOfTheBox;
    [Test]
    procedure TestTraceNextToTheBoxDoesNotHit;
    [Test]
    procedure TestMovingAwayFromTheFaceDoesNotHit;
    [Test]
    procedure TestContentMaskThatDoesNotMatchIsIgnored;
    [Test]
    procedure TestModelOriginMovesTheModel;
    [Test]
    procedure TestRotatedModelIsHitThroughItsRotatedFace;
    [Test]
    procedure TestRotatedTraceModelUsesItsRotatedExtent;
    [Test]
    procedure TestStartEqualsEndDoesAPositionTest;
    [Test]
    procedure TestHugeTranslationIsRefused;
    [Test]
    procedure TestInvalidModelHandleGivesAnEmptyResult;
    [Test]
    procedure TestModelVertexHitsTheFaceOfALargeTraceModel;
    [Test]
    procedure TestTraceModelVertexHitsAFaceNearTheCorner;
    [Test]
    procedure TestSweepAgainstFewBoxesMatchesTheOracle;
    [Test]
    procedure TestSweepOfAPointAgainstFewBoxesMatchesTheOracle;
    [Test]
    procedure TestSweepAgainstManyBoxesWithTheBspMatchesTheOracle;
    [Test]
    procedure TestContentsOfABoxAgainstBoxesMatchesTheOracle;
    [Test]
    procedure TestContentsOfAPointInABrush;
    [Test]
    procedure TestContactsOfABoxLandingOnAFloor;
    [Test]
    procedure TestTraceModelAgainstATraceModel;
    [Test]
    procedure TestTrmFromModelOfABox;
    [Test]
    procedure TestModelQueries;
    [Test]
    procedure TestAddingAModelResetsItsCheckCounts;
  end;

implementation

uses
  System.SysUtils, System.Math, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Winding,
  DelphiDoom.Collision.Model, DelphiDoom.Collision.Builder, DelphiDoom.Collision.Factory,
  DelphiDoom.Tests.Collision.Support;

const
  EPS = 1e-4;


/// <summary>Entry fraction of the ray start-end into the box (slab method); false when it does not enter</summary>
function RayEntersBox(const AStart, AEnd: TGeoVec3; const ABox: TGeoBounds; out AEntry: Double): Boolean;
var
  LAxis: Integer;
  LTMin: Double;
  LTMax: Double;
  LD: Double;
  LT1: Double;
  LT2: Double;
begin
  LTMin := -1e30;
  LTMax := 1e30;
  for LAxis := 0 to 2 do
  begin
    LD := Double(AEnd[LAxis]) - AStart[LAxis];
    if Abs(LD) < 1e-12 then
    begin
      if (AStart[LAxis] <= ABox.Mins[LAxis]) or (AStart[LAxis] >= ABox.Maxs[LAxis]) then
        Exit(False);
    end
    else
    begin
      LT1 := (ABox.Mins[LAxis] - Double(AStart[LAxis])) / LD;
      LT2 := (ABox.Maxs[LAxis] - Double(AStart[LAxis])) / LD;
      if LT1 > LT2 then
      begin
        LD := LT1;
        LT1 := LT2;
        LT2 := LD;
      end;
      if LT1 > LTMin then
        LTMin := LT1;
      if LT2 < LTMax then
        LTMax := LT2;
    end;
  end;
  Result := (LTMin < LTMax) and (LTMax > 0) and (LTMin < 1);
  if Result then
    AEntry := Max(LTMin, 0.0)
  else
    AEntry := 2;
end;

/// <summary>The box grown by the extent of a trm box and by a margin: the swept trm origin enters it</summary>
function MinkowskiBox(const ABox: TGeoBounds; const ATrmBounds: TGeoBounds; AMargin: Single): TGeoBounds;
begin
  Result.Mins := ABox.Mins - ATrmBounds.Maxs - TGeoVec3.Make(AMargin, AMargin, AMargin);
  Result.Maxs := ABox.Maxs - ATrmBounds.Mins + TGeoVec3.Make(AMargin, AMargin, AMargin);
end;

function PointInBox(const APoint: TGeoVec3; const ABox: TGeoBounds): Boolean;
begin
  Result := (APoint.X > ABox.Mins.X) and (APoint.X < ABox.Maxs.X) and (APoint.Y > ABox.Mins.Y) and
    (APoint.Y < ABox.Maxs.Y) and (APoint.Z > ABox.Mins.Z) and (APoint.Z < ABox.Maxs.Z);
end;

{ TTestCollisionTranslation }

procedure TTestCollisionTranslation.Setup;
begin
  FCatalog := TFakeMaterialCatalog.Create;
  FManager := TCollisionFactory.CreateManager(FCatalog, nil);
  FSeed := 2463534242;
end;

procedure TTestCollisionTranslation.TearDown;
begin
  FManager := nil;
  FCatalog := nil;
end;

function TTestCollisionTranslation.NextRandom: Single;
begin
  // xorshift32: the same sequence on every run and on every platform
  FSeed := FSeed xor (FSeed shl 13);
  FSeed := FSeed xor (FSeed shr 17);
  FSeed := FSeed xor (FSeed shl 5);
  Result := (FSeed and $FFFFFF) / 16777216.0;
end;

function TTestCollisionTranslation.Between(AMin, AMax: Single): Single;
begin
  Result := AMin + NextRandom * (AMax - AMin);
end;

function TTestCollisionTranslation.AddBoxes(const ABoxes: TBoxArray; const AName: string): Integer;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LBuilder: TCollisionModelBuilder;
  LIndex: Integer;
  LModel: TCollisionModel;
begin
  LSource := TFakeGeometrySource.Create(AName);
  LRef := LSource;
  for LIndex := 0 to High(ABoxes) do
    LSource.AddBox(ABoxes[LIndex], FCatalog.FindMaterial('solid'));
  LBuilder := TCollisionFactory.CreateBuilder(nil);
  try
    LModel := LBuilder.Build(LRef);
  finally
    LBuilder.Free;
  end;
  Result := FManager.AddModel(LModel);
end;

function TTestCollisionTranslation.RandomBoxes(ACount: Integer; ASpread, AMinSize, AMaxSize: Integer): TBoxArray;
var
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LZ: Integer;
begin
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
  begin
    LX := Round(Between(-ASpread, ASpread));
    LY := Round(Between(-ASpread, ASpread));
    LZ := Round(Between(-ASpread, ASpread));
    Result[LIndex] := Bounds3(LX, LY, LZ, LX + Round(Between(AMinSize, AMaxSize)),
      LY + Round(Between(AMinSize, AMaxSize)), LZ + Round(Between(AMinSize, AMaxSize)));
  end;
end;

procedure TTestCollisionTranslation.RunSweepOracle(const ABoxes: TBoxArray; AIterations: Integer; ASpread,
  AMaxLength: Single; ATrm: TTraceModel; out ATested, AHits: Integer);
var
  LHandle: Integer;
  LIteration: Integer;
  LIndex: Integer;
  LStart: TGeoVec3;
  LEnd: TGeoVec3;
  LDir: TGeoVec3;
  LResult: TCollisionTrace;
  LTrmBounds: TGeoBounds;
  LEntry: Double;
  LHit: Double;
  LNear: Double;
  LStartBlocked: Boolean;
  LCenterStart: TGeoVec3;
  LContents: Integer;
begin
  ATested := 0;
  AHits := 0;
  LHandle := AddBoxes(ABoxes, 'sweep');
  if Assigned(ATrm) then
    LTrmBounds := ATrm.Bounds
  else
    LTrmBounds := Bounds3(0, 0, 0, 0, 0, 0);
  for LIteration := 1 to AIterations do
  begin
    LStart := TGeoVec3.Make(Between(-ASpread, ASpread), Between(-ASpread, ASpread), Between(-ASpread, ASpread));
    LDir := TGeoVec3.Make(Between(-1, 1), Between(-1, 1), Between(-1, 1));
    if LDir.LengthSqr < 0.01 then
      Continue;
    LDir.NormalizeSelf;
    LEnd := LStart + LDir * Between(10, AMaxLength);
    // the start must be well outside every box
    LStartBlocked := False;
    for LIndex := 0 to High(ABoxes) do
      if PointInBox(LStart, MinkowskiBox(ABoxes[LIndex], LTrmBounds, 1.0)) then
        LStartBlocked := True;
    if LStartBlocked then
      Continue;
    Inc(ATested);

    FManager.Translation(LResult, LStart, LEnd, ATrm, TGeoMat3.Identity, CONTENTS_SOLID, LHandle,
      TGeoVec3.Origin, TGeoMat3.Identity);

    LHit := 2;
    LNear := 2;
    for LIndex := 0 to High(ABoxes) do
    begin
      if RayEntersBox(LStart, LEnd, MinkowskiBox(ABoxes[LIndex], LTrmBounds, 0), LEntry) and (LEntry < LHit) then
        LHit := LEntry;
      if RayEntersBox(LStart, LEnd, MinkowskiBox(ABoxes[LIndex], LTrmBounds, 0.6), LEntry) and (LEntry < LNear) then
        LNear := LEntry;
    end;

    // no tunnelling: the trace stops no later than the first real contact
    if LHit <= 1 then
    begin
      Inc(AHits);
      Assert.IsTrue(LResult.Fraction <= LHit + 1e-3,
        Format('iteration %d: fraction %g is past the contact at %g', [LIteration, LResult.Fraction, LHit]));
    end;
    // no false hits: when the path stays clear of the boxes grown by more than the clip epsilon, it is free
    if LNear > 1 then
      Assert.AreEqual(1.0, LResult.Fraction, 0.0,
        Format('iteration %d: false hit at %g', [LIteration, LResult.Fraction]));
    // the end position of a hit is out of the solid
    if LResult.Fraction < 1 then
    begin
      LCenterStart := LResult.EndPos;
      LContents := FManager.Contents(LCenterStart, ATrm, TGeoMat3.Identity, CONTENTS_SOLID, LHandle,
        TGeoVec3.Origin, TGeoMat3.Identity);
      Assert.AreEqual(0, LContents, Format('iteration %d: the end of the trace is in solid', [LIteration]));
      // and the contact plane faces the start of the trace
      Assert.IsTrue(LResult.C.Normal.Dot(LDir) <= 1e-3, Format('iteration %d: normal faces away', [LIteration]));
    end;
  end;
end;

procedure TTestCollisionTranslation.TestPointHitsAFaceOfTheBox;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  FManager.Translation(LResult, TGeoVec3.Make(-200, 0, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
  // the point stops CM_CLIP_EPSILON (0.25) before the face x = -64: (136 - 0.25) / 200
  Assert.AreEqual(0.67875, LResult.Fraction, 1e-5);
  Assert.AreEqual(-64.25, LResult.EndPos.X, 1e-3);
  Assert.AreEqual(0.0, LResult.EndPos.Y, 1e-6);
  Assert.AreEqual(-1.0, LResult.C.Normal.X, 1e-6);
  Assert.AreEqual(64.0, LResult.C.Dist, 1e-4);
  Assert.AreEqual(CONTENTS_SOLID, LResult.C.Contents);
  Assert.IsTrue(LResult.C.ContactType = ctTrmVertex);
  Assert.AreEqual('solid', LResult.C.Material.Name);
  Assert.AreEqual(-64.25, LResult.C.Point.X, 1e-3);
  Assert.IsFalse(LResult.EndAxis.IsRotated);
end;

procedure TTestCollisionTranslation.TestBoxTraceModelHitsAFaceOfTheBox;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    FManager.Translation(LResult, TGeoVec3.Make(-200, 0, 0), TGeoVec3.Make(0, 0, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    // the leading face of the trm (x = start + 8) stops 0.25 before the face x = -64:
    // start.x = -72.25, fraction = 127.75 / 200
    Assert.AreEqual(0.63875, LResult.Fraction, 1e-5);
    Assert.AreEqual(-72.25, LResult.EndPos.X, 1e-3);
    Assert.AreEqual(-1.0, LResult.C.Normal.X, 1e-6);
    Assert.AreEqual(64.0, LResult.C.Dist, 1e-4);
    Assert.IsTrue(LResult.C.ContactType = ctTrmVertex);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestTraceNextToTheBoxDoesNotHit;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    // 20 units clear of the face y = 64 (the trm is 8 wide)
    FManager.Translation(LResult, TGeoVec3.Make(-200, 92, 0), TGeoVec3.Make(200, 92, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(1.0, LResult.Fraction, 0.0);
    Assert.AreEqual(200.0, LResult.EndPos.X, 1e-4);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestMovingAwayFromTheFaceDoesNotHit;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  FManager.Translation(LResult, TGeoVec3.Make(-100, 0, 0), TGeoVec3.Make(-300, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(1.0, LResult.Fraction, 0.0);
end;

procedure TTestCollisionTranslation.TestContentMaskThatDoesNotMatchIsIgnored;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  FManager.Translation(LResult, TGeoVec3.Make(-200, 0, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_PLAYERCLIP, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(1.0, LResult.Fraction, 0.0);
end;

procedure TTestCollisionTranslation.TestModelOriginMovesTheModel;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  // the model is placed at x = 500: its face is at x = 436
  FManager.Translation(LResult, TGeoVec3.Make(300, 0, 0), TGeoVec3.Make(500, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Make(500, 0, 0), TGeoMat3.Identity);
  // (136 - 0.25) / 200
  Assert.AreEqual(0.67875, LResult.Fraction, 1e-5);
  Assert.AreEqual(435.75, LResult.EndPos.X, 1e-3);
  Assert.AreEqual(435.75, LResult.C.Point.X, 1e-3);
  // the plane of the contact is in world space: n = (-1,0,0) through x = 436
  Assert.AreEqual(-436.0, LResult.C.Dist, 1e-3);
end;

procedure TTestCollisionTranslation.TestRotatedModelIsHitThroughItsRotatedFace;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
begin
  // a box 128 long in X and 32 in Y, turned a quarter about Z: in the world it is 32 in X and 128 in Y
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -16, -16, 64, 16, 16)), 'long');
  FManager.Translation(LResult, TGeoVec3.Make(-100, 0, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.RotationAboutZ(90));
  // the face is at x = -16 in the world: (84 - 0.25) / 100
  Assert.AreEqual(0.8375, LResult.Fraction, 1e-4);
  Assert.AreEqual(-1.0, LResult.C.Normal.X, 1e-4);
  Assert.AreEqual(16.0, LResult.C.Dist, 1e-3);
  // the same trace along Y passes the long side only at its far end
  FManager.Translation(LResult, TGeoVec3.Make(0, -200, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.RotationAboutZ(90));
  Assert.AreEqual((200 - 64 - 0.25) / 200, LResult.Fraction, 1e-4);
end;

procedure TTestCollisionTranslation.TestRotatedTraceModelUsesItsRotatedExtent;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  // a trm 40 long in X and 8 in Y, turned a quarter: it is 8 long in X and 40 in Y in the world
  LTrm := TTraceModel.CreateBox(Bounds3(-20, -4, -4, 20, 4, 4));
  try
    FManager.Translation(LResult, TGeoVec3.Make(-200, 0, 0), TGeoVec3.Make(0, 0, 0), LTrm,
      TGeoMat3.RotationAboutZ(90), CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    // the leading face is at start.x + 4: it stops 0.25 before x = -64: start.x = -68.25
    Assert.AreEqual((200 - 68.25) / 200, LResult.Fraction, 1e-4);
    Assert.IsTrue(LResult.EndAxis.IsRotated);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestStartEqualsEndDoesAPositionTest;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    // inside
    FManager.Translation(LResult, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(0, 0, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(0.0, LResult.Fraction, 0.0);
    Assert.AreEqual(CONTENTS_SOLID, LResult.C.Contents);
    // outside
    FManager.Translation(LResult, TGeoVec3.Make(200, 0, 0), TGeoVec3.Make(200, 0, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(1.0, LResult.Fraction, 0.0);
    Assert.AreEqual(0, LResult.C.Contents);
    // a point
    FManager.Translation(LResult, TGeoVec3.Make(0, 0, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(0.0, LResult.Fraction, 0.0);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestHugeTranslationIsRefused;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    // longer than CM_MAX_TRACE_DIST: the trace fraction is too inaccurate, the result is 0
    FManager.Translation(LResult, TGeoVec3.Make(-5000, 500, 0), TGeoVec3.Make(5000, 500, 0), LTrm,
      TGeoMat3.Identity, CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(0.0, LResult.Fraction, 0.0);
    Assert.AreEqual(-5000.0, LResult.EndPos.X, 0.0);
    // but a point trace has no limit
    FManager.Translation(LResult, TGeoVec3.Make(-5000, 500, 0), TGeoVec3.Make(5000, 500, 0), nil, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(1.0, LResult.Fraction, 0.0);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestInvalidModelHandleGivesAnEmptyResult;
var
  LResult: TCollisionTrace;
begin
  FManager.Translation(LResult, TGeoVec3.Make(-5, 0, 0), TGeoVec3.Make(5, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, 7, TGeoVec3.Origin, TGeoMat3.Identity);
  // the C++ code zeroes the result and returns
  Assert.AreEqual(0.0, LResult.Fraction, 0.0);
  Assert.AreEqual(0, FManager.Contents(TGeoVec3.Origin, nil, TGeoMat3.Identity, CONTENTS_SOLID, -1, TGeoVec3.Origin,
    TGeoMat3.Identity));
end;

procedure TTestCollisionTranslation.TestModelVertexHitsTheFaceOfALargeTraceModel;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  // a small model in front of a large trm: no trm vertex lies on the model face, so the first
  // contact is a model vertex against the leading polygon of the trm
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(100, -5, -5, 110, 5, 5)), 'small');
  LTrm := TTraceModel.CreateBox(Bounds3(-50, -50, -50, 50, 50, 50));
  try
    FManager.Translation(LResult, TGeoVec3.Origin, TGeoVec3.Make(300, 0, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    // the model vertex at x = 100 meets the trm face x = 50 + t: (50 - 0.25) / 300
    Assert.AreEqual(49.75 / 300, LResult.Fraction, 1e-5);
    Assert.IsTrue(LResult.C.ContactType = ctModelVertex);
    Assert.AreEqual(-1.0, LResult.C.Normal.X, 1e-6);
    Assert.AreEqual(CONTENTS_SOLID, LResult.C.Contents);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestTraceModelVertexHitsAFaceNearTheCorner;
var
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    // a corner of the trm comes down on the top face at its corner (z = 64): the trm bottom vertex
    // (x+8, y+8) is over the face and leads
    FManager.Translation(LResult, TGeoVec3.Make(50, 50, 200), TGeoVec3.Make(50, 50, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    // the bottom face (z = start.z - 8) stops 0.25 above z = 64: start.z = 72.25
    Assert.AreEqual((200 - 72.25) / 200, LResult.Fraction, 1e-4);
    Assert.AreEqual(1.0, LResult.C.Normal.Z, 1e-6);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestSweepAgainstFewBoxesMatchesTheOracle;
var
  LTrm: TTraceModel;
  LTested: Integer;
  LHits: Integer;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-12, -10, -16, 12, 10, 16));
  try
    RunSweepOracle(RandomBoxes(8, 100, 20, 90), 600, 200, 500, LTrm, LTested, LHits);
    Assert.IsTrue(LTested > 300, 'tested ' + IntToStr(LTested));
    Assert.IsTrue(LHits > 40, 'hits ' + IntToStr(LHits));
    Assert.IsTrue(LTested - LHits > 20, 'misses ' + IntToStr(LTested - LHits));
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestSweepOfAPointAgainstFewBoxesMatchesTheOracle;
var
  LTested: Integer;
  LHits: Integer;
begin
  RunSweepOracle(RandomBoxes(10, 100, 20, 90), 600, 200, 600, nil, LTested, LHits);
  Assert.IsTrue(LTested > 300, 'tested ' + IntToStr(LTested));
  Assert.IsTrue(LHits > 40, 'hits ' + IntToStr(LHits));
end;

procedure TTestCollisionTranslation.TestSweepAgainstManyBoxesWithTheBspMatchesTheOracle;
var
  LTrm: TTraceModel;
  LTested: Integer;
  LHits: Integer;
begin
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  try
    // more than four brushes: the model gets an axial BSP tree
    RunSweepOracle(RandomBoxes(100, 1500, 60, 300), 800, 1600, 3000, LTrm, LTested, LHits);
    Assert.IsTrue(LTested > 300, 'tested ' + IntToStr(LTested));
    Assert.IsTrue(LHits > 100, 'hits ' + IntToStr(LHits));
    Assert.IsTrue(LTested - LHits > 20, 'misses ' + IntToStr(LTested - LHits));
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestContentsOfABoxAgainstBoxesMatchesTheOracle;
var
  LBoxes: TBoxArray;
  LHandle: Integer;
  LTrm: TTraceModel;
  LIteration: Integer;
  LIndex: Integer;
  LCenter: TGeoVec3;
  LDepth: Single;
  LSolid: Boolean;
  LFree: Boolean;
  LMargin: Single;
  LContents: Integer;
  LSolidCount: Integer;
  LFreeCount: Integer;
  LAxis: Integer;
  LTrmBounds: TGeoBounds;
  LAxisDepth: Single;
begin
  LBoxes := RandomBoxes(14, 150, 20, 100);
  LHandle := AddBoxes(LBoxes, 'contents');
  // a long thin trm: it crosses boxes without having a vertex in them
  LTrm := TTraceModel.CreateBox(Bounds3(-60, -4, -6, 60, 4, 6));
  try
    LTrmBounds := LTrm.Bounds;
    LSolidCount := 0;
    LFreeCount := 0;
    for LIteration := 1 to 2500 do
    begin
      LCenter := TGeoVec3.Make(Between(-200, 200), Between(-200, 200), Between(-200, 200));
      LSolid := False;
      LFree := True;
      for LIndex := 0 to High(LBoxes) do
      begin
        // depth of the overlap on the axis where it is smallest; negative when separated on an axis
        LDepth := 1e30;
        for LAxis := 0 to 2 do
        begin
          LAxisDepth := Min(LCenter[LAxis] + LTrmBounds.Maxs[LAxis] - LBoxes[LIndex].Mins[LAxis],
            LBoxes[LIndex].Maxs[LAxis] - (LCenter[LAxis] + LTrmBounds.Mins[LAxis]));
          if LAxisDepth < LDepth then
            LDepth := LAxisDepth;
        end;
        LMargin := 0.05;
        if LDepth > LMargin then
          LSolid := True;
        if LDepth > -LMargin then
          LFree := False;
      end;
      // skip the cases at the border of a box
      if (not LSolid) and (not LFree) then
        Continue;
      LContents := FManager.Contents(LCenter, LTrm, TGeoMat3.Identity, CONTENTS_SOLID, LHandle, TGeoVec3.Origin,
        TGeoMat3.Identity);
      if LSolid then
      begin
        Inc(LSolidCount);
        Assert.AreEqual(CONTENTS_SOLID, LContents, Format('iteration %d should be solid', [LIteration]));
      end
      else
      begin
        Inc(LFreeCount);
        Assert.AreEqual(0, LContents, Format('iteration %d should be free', [LIteration]));
      end;
    end;
    Assert.IsTrue(LSolidCount > 50, 'solid cases ' + IntToStr(LSolidCount));
    Assert.IsTrue(LFreeCount > 300, 'free cases ' + IntToStr(LFreeCount));
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestContentsOfAPointInABrush;
var
  LHandle: Integer;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-64, -64, -64, 64, 64, 64)), 'box');
  Assert.AreEqual(CONTENTS_SOLID, FManager.Contents(TGeoVec3.Make(10, 10, 10), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity));
  Assert.AreEqual(0, FManager.Contents(TGeoVec3.Make(70, 0, 0), nil, TGeoMat3.Identity, CONTENTS_SOLID, LHandle,
    TGeoVec3.Origin, TGeoMat3.Identity));
  // the model moved: the origin is now outside and a point at the new place inside
  Assert.AreEqual(0, FManager.Contents(TGeoVec3.Make(10, 10, 10), nil, TGeoMat3.Identity, CONTENTS_SOLID, LHandle,
    TGeoVec3.Make(500, 0, 0), TGeoMat3.Identity));
  Assert.AreEqual(CONTENTS_SOLID, FManager.Contents(TGeoVec3.Make(510, 10, 10), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Make(500, 0, 0), TGeoMat3.Identity));
end;

procedure TTestCollisionTranslation.TestContactsOfABoxLandingOnAFloor;
var
  LHandle: Integer;
  LTrm: TTraceModel;
  LContacts: TList<TContactInfo>;
  LCount: Integer;
  LIndex: Integer;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-100, -100, -10, 100, 100, 0)), 'floor');
  LTrm := TTraceModel.CreateBox(Bounds3(-8, -8, 0, 8, 8, 16));
  LContacts := TList<TContactInfo>.Create;
  try
    // the box stands 4.9 above the floor and is pushed 10 units down: its four bottom corners touch
    LCount := FManager.Contacts(LContacts, 32, TGeoVec3.Make(0, 0, 4.9), TGeoVec3.Make(0, 0, -1), 10, LTrm,
      TGeoMat3.Identity, CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(4, LCount);
    Assert.AreEqual(4, LContacts.Count);
    for LIndex := 0 to LContacts.Count - 1 do
    begin
      Assert.AreEqual(1.0, LContacts[LIndex].Normal.Z, 1e-5);
      Assert.AreEqual(0.0, LContacts[LIndex].Dist, 1e-5);
      Assert.IsTrue(LContacts[LIndex].ContactType = ctTrmVertex);
      Assert.AreEqual(CONTENTS_SOLID, LContacts[LIndex].Contents);
    end;
    // a limit on the number of contacts
    LCount := FManager.Contacts(LContacts, 2, TGeoVec3.Make(0, 0, 4.9), TGeoVec3.Make(0, 0, -1), 10, LTrm,
      TGeoMat3.Identity, CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual(2, LCount);
  finally
    LContacts.Free;
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestTraceModelAgainstATraceModel;
var
  LBox: TTraceModel;
  LHandle: Integer;
  LResult: TCollisionTrace;
  LTrm: TTraceModel;
begin
  LBox := TTraceModel.CreateBox(Bounds3(-8, -8, -8, 8, 8, 8));
  LTrm := TTraceModel.CreateBox(Bounds3(-4, -4, -4, 4, 4, 4));
  try
    LHandle := FManager.SetupTrmModel(LBox, nil);
    Assert.AreEqual(TRACE_MODEL_HANDLE, LHandle);
    // a point into the box model: stops 0.25 before the face x = -8
    FManager.Translation(LResult, TGeoVec3.Make(-100, 0, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual((100 - 8.25) / 100, LResult.Fraction, 1e-5);
    // a smaller box into it: its leading face at start.x + 4 stops 0.25 before x = -8
    FManager.Translation(LResult, TGeoVec3.Make(-100, 0, 0), TGeoVec3.Make(0, 0, 0), LTrm, TGeoMat3.Identity,
      CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
    Assert.AreEqual((100 - 12.25) / 100, LResult.Fraction, 1e-5);
    // position tests: inside and outside
    Assert.AreEqual(-1, FManager.Contents(TGeoVec3.Make(1, 1, 1), LTrm, TGeoMat3.Identity, -1, LHandle,
      TGeoVec3.Origin, TGeoMat3.Identity));
    Assert.AreEqual(0, FManager.Contents(TGeoVec3.Make(50, 0, 0), LTrm, TGeoMat3.Identity, -1, LHandle,
      TGeoVec3.Origin, TGeoMat3.Identity));
  finally
    LTrm.Free;
    LBox.Free;
  end;
end;

procedure TTestCollisionTranslation.TestTrmFromModelOfABox;
var
  LHandle: Integer;
  LTrm: TTraceModel;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(-8, -8, -8, 8, 8, 8)), 'hull');
  LTrm := TTraceModel.Create;
  try
    Assert.IsTrue(FManager.TrmFromModel(LHandle, LTrm));
    Assert.AreEqual(8, LTrm.NumVerts);
    Assert.AreEqual(12, LTrm.NumEdges);
    Assert.AreEqual(6, LTrm.NumPolys);
    Assert.IsTrue(LTrm.IsConvex);
    Assert.AreEqual(-8.0, LTrm.Bounds.Mins.X, 1e-4);
    Assert.AreEqual(0.0, LTrm.Offset.X, 1e-4);
    // a trace with the extracted trace model behaves like a box
    Assert.IsTrue(LTrm.Kind = tmkCustom);
  finally
    LTrm.Free;
  end;
end;

procedure TTestCollisionTranslation.TestModelQueries;
var
  LHandle: Integer;
  LBounds: TGeoBounds;
  LContents: Integer;
  LVertex: TGeoVec3;
  LStart: TGeoVec3;
  LEnd: TGeoVec3;
  LWinding: TGeoWinding;
  LResult: TCollisionTrace;
begin
  LHandle := AddBoxes(TBoxArray.Create(Bounds3(0, 0, 0, 16, 16, 16)), 'queried');
  Assert.AreEqual('queried', FManager.GetModelName(LHandle));
  Assert.AreEqual(LHandle, FManager.FindModel('QUERIED'));
  Assert.AreEqual(-1, FManager.FindModel('other'));
  Assert.IsTrue(FManager.GetModelBounds(LHandle, LBounds));
  Assert.AreEqual(16.0, LBounds.Maxs.Z, 1e-4);
  Assert.IsTrue(FManager.GetModelContents(LHandle, LContents));
  Assert.AreEqual(CONTENTS_SOLID, LContents);
  Assert.IsTrue(FManager.GetModelVertex(LHandle, 0, LVertex));
  Assert.IsFalse(FManager.GetModelVertex(LHandle, 8, LVertex));
  Assert.IsFalse(FManager.GetModelVertex(LHandle + 1, 0, LVertex));
  Assert.IsTrue(FManager.GetModelEdge(LHandle, -1, LStart, LEnd));
  Assert.IsFalse(FManager.GetModelEdge(LHandle, 13, LStart, LEnd));
  Assert.AreEqual('', FManager.GetModelName(99));
  // the polygon of a contact: a point hits the face x = 0 and the winding is that face
  FManager.Translation(LResult, TGeoVec3.Make(-50, 8, 8), TGeoVec3.Make(8, 8, 8), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.IsTrue(LResult.Fraction < 1);
  LWinding := FManager.GetModelPolygon(LHandle, LResult.C.ModelFeature);
  try
    Assert.IsNotNull(LWinding);
    Assert.AreEqual(4, LWinding.NumPoints);
    Assert.AreEqual(0.0, LWinding[0].X, 1e-4);
    Assert.AreEqual(0.0, LWinding[2].X, 1e-4);
  finally
    LWinding.Free;
  end;
end;

procedure TTestCollisionTranslation.TestAddingAModelResetsItsCheckCounts;
var
  LSource: TFakeGeometrySource;
  LRef: ICollisionGeometrySource;
  LBuilder: TCollisionModelBuilder;
  LModel: TCollisionModel;
  LResult: TCollisionTrace;
  LHandle: Integer;
  LPolygonIndex: Integer;
begin
  LSource := TFakeGeometrySource.Create('stamped');
  LRef := LSource;
  LSource.AddBox(Bounds3(-64, -64, -64, 64, 64, 64), FCatalog.FindMaterial('solid'));
  LBuilder := TCollisionFactory.CreateBuilder(nil);
  try
    LModel := LBuilder.Build(LRef);
  finally
    LBuilder.Free;
  end;
  // stamp every polygon with the value the first query of a manager uses
  for LPolygonIndex := 0 to High(LModel.TreePolygons) do
    LModel.TreePolygons[LPolygonIndex].CheckCount := 1;
  LHandle := FManager.AddModel(LModel);
  FManager.Translation(LResult, TGeoVec3.Make(-200, 0, 0), TGeoVec3.Make(0, 0, 0), nil, TGeoMat3.Identity,
    CONTENTS_SOLID, LHandle, TGeoVec3.Origin, TGeoMat3.Identity);
  Assert.AreEqual(0.67875, LResult.Fraction, 1e-5);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCollisionTranslation);

end.
