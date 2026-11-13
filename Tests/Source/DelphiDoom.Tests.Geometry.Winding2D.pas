{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGeoWinding2D (idWinding2D)                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Geometry.Winding2D;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   The 2D winding: hand worked values and parity with the real idWinding2D of Doom 3
  ///   (Tests\Data\Geometry\surface.golden.txt, lines w2_*)
  /// </summary>
  [TestFixture]
  [Category('geometry')]
  TTestGeometryWinding2D = class(TObject)
  public
    [Test]
    procedure AreaECentroDiUnQuadratoDovrebberoEssereGiusti;
    [Test]
    procedure IlRaggioDovrebbeEssereLaDistanzaDelPuntoPiuLontano;
    [Test]
    procedure IBoundsDiUnWindingVuotoDovrebberoEssereRovesciati;
    [Test]
    procedure IlCentroDiUnWindingVuotoDovrebbeEssereNaN;
    [Test]
    procedure ReverseDovrebbeInvertireLOrdineEIlSegnoDellArea;
    [Test]
    procedure SplitDovrebbeDividereUnQuadratoAMeta;
    [Test]
    procedure SplitConUnPianoAssialeDovrebbeUsareIlSegnoDelloOriginale;
    [Test]
    procedure SplitDiUnWindingATuttiIPuntiNeiRamiDovrebbeDareUnaCopia;
    [Test]
    procedure SplitDiUnWindingDa16PuntiNonDovrebbeSforareLaCapacita;
    [Test]
    procedure ClipInPlaceDovrebbeTagliareIlRetro;
    [Test]
    procedure ClipInPlaceFuoriDalPianoDovrebbeSvuotareIlWinding;
    [Test]
    procedure ExpandDovrebbeAllargareUnQuadratoDellaDistanza;
    [Test]
    procedure ExpandForAxialBoxDovrebbeAllargareUnQuadratoDellaMetaDelBox;
    [Test]
    procedure ExpandForAxialBoxDiUnWindingDegenereNonDovrebbeLeggereFuoriDalVettore;
    [Test]
    procedure IlRaggioDovrebbeColpireIDueLatiOpposti;
    [Test]
    procedure IlPianoDa2DDovrebbeEssereQuelloDellaRetta;
    [Test]
    procedure AddPointOltreLaCapacitaDovrebbeDareEccezione;
    [Test]
    procedure LeMisureDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure LeOperazioniSulPianoDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure SplitEClipDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure ExpandDovrebbeDareLeStesseRispostePerIlCpp;
    [Test]
    procedure PuntoLineaERaggioDovrebberoDareLeStesseRispostePerIlCpp;
    [Test]
    procedure IPianiDa2DDovrebberoDareLeStesseRispostePerIlCpp;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Math, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.Geometry.Vec3,
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Winding2D, DelphiDoom.Tests.Geometry.Golden;

/// <summary>The square as a clockwise winding: the convention of the 2D planes of idlib has them point outwards</summary>
function MakeSquare(AX, AY, ASize: Single): TGeoWinding2D;
begin
  Result := TGeoWinding2D.Create;
  Result.AddPoint(TIdVec2.Create(AX, AY));
  Result.AddPoint(TIdVec2.Create(AX, AY + ASize));
  Result.AddPoint(TIdVec2.Create(AX + ASize, AY + ASize));
  Result.AddPoint(TIdVec2.Create(AX + ASize, AY));
end;

function ReadWinding(var AReader: TGeoGoldenReader): TGeoWinding2D;
var
  LCount, LIndex: Integer;
begin
  Result := TGeoWinding2D.Create;
  LCount := AReader.Int;
  for LIndex := 0 to LCount - 1 do
    Result.AddPoint(AReader.Vec2);
end;

procedure PutWinding(AWriter: TGeoGoldenWriter; const AWinding: TGeoWinding2D);
var
  LIndex: Integer;
begin
  if not Assigned(AWinding) then
  begin
    AWriter.Int(-1);
    Exit;
  end;
  AWriter.Int(AWinding.NumPoints);
  for LIndex := 0 to AWinding.NumPoints - 1 do
    AWriter.Vec2(AWinding[LIndex]);
end;

procedure TTestGeometryWinding2D.AreaECentroDiUnQuadratoDovrebberoEssereGiusti;
var
  LWinding: TGeoWinding2D;
begin
  LWinding := MakeSquare(1, 1, 2);
  try
    Assert.AreEqual<Single>(-4, LWinding.GetArea);
    Assert.AreEqual<Single>(2, LWinding.GetCenter.X);
    Assert.AreEqual<Single>(2, LWinding.GetCenter.Y);
    Assert.IsFalse(LWinding.IsTiny);
    Assert.IsFalse(LWinding.IsHuge);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.IlRaggioDovrebbeEssereLaDistanzaDelPuntoPiuLontano;
var
  LWinding: TGeoWinding2D;
begin
  LWinding := MakeSquare(-1, -1, 2);
  try
    AssertNear(Sqrt(2), LWinding.GetRadius(TIdVec2.Create(0, 0)), 1E-4);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.IBoundsDiUnWindingVuotoDovrebberoEssereRovesciati;
var
  LWinding: TGeoWinding2D;
  LMins, LMaxs: TIdVec2;
begin
  LWinding := TGeoWinding2D.Create;
  try
    LWinding.GetBounds(LMins, LMaxs);
    Assert.IsTrue(LMins.X > LMaxs.X);
    Assert.AreEqual<Single>(GEO_INFINITY, LMins.Y);
    Assert.IsTrue(LWinding.IsTiny);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.IlCentroDiUnWindingVuotoDovrebbeEssereNaN;
var
  LWinding: TGeoWinding2D;
begin
  LWinding := TGeoWinding2D.Create;
  try
    Assert.IsTrue(IsNan(LWinding.GetCenter.X));
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.ReverseDovrebbeInvertireLOrdineEIlSegnoDellArea;
var
  LWinding, LReversed: TGeoWinding2D;
begin
  LWinding := MakeSquare(0, 0, 3);
  LReversed := LWinding.Reverse;
  try
    Assert.AreEqual<Single>(9, LReversed.GetArea);
    Assert.AreEqual<Single>(0, LReversed[0].Y);
    Assert.AreEqual<Single>(3, LReversed[0].X);
  finally
    LReversed.Free;
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.SplitDovrebbeDividereUnQuadratoAMeta;
var
  LWinding, LFront, LBack: TGeoWinding2D;
  LSide: Integer;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    // a line through the centre: both halves have half of the area
    LSide := LWinding.Split(TGeoVec3.Make(0.6, 0.8, -1.4), 0.1, LFront, LBack);
    Assert.AreEqual(PLANESIDE_CROSS, LSide);
    try
      AssertNear(-2, LFront.GetArea, 1E-4);
      AssertNear(-2, LBack.GetArea, 1E-4);
      Assert.AreEqual(4, LFront.NumPoints);
    finally
      LFront.Free;
      LBack.Free;
    end;
    Assert.AreEqual(4, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.SplitConUnPianoAssialeDovrebbeUsareIlSegnoDelloOriginale;
var
  LWinding, LFront, LBack: TGeoWinding2D;
  LIndex: Integer;
  LFound: Boolean;
begin
  // to avoid round-off the original sets the coordinate of the cut point to plane.z, but the plane
  // x + z = 0 is at x = -z: the point lands on the wrong side (defect kept for the parity)
  LWinding := MakeSquare(0, 0, 2);
  try
    Assert.AreEqual(PLANESIDE_CROSS, LWinding.Split(TGeoVec3.Make(1, 0, -1), 0.1, LFront, LBack));
    LFound := False;
    for LIndex := 0 to LFront.NumPoints - 1 do
      if LFront[LIndex].X = -1 then
        LFound := True;
    Assert.IsTrue(LFound);
    LFront.Free;
    LBack.Free;
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.SplitDiUnWindingATuttiIPuntiNeiRamiDovrebbeDareUnaCopia;
var
  LWinding, LFront, LBack: TGeoWinding2D;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    Assert.AreEqual(PLANESIDE_FRONT, LWinding.Split(TGeoVec3.Make(1, 0, 5), 0.1, LFront, LBack));
    Assert.IsNull(LBack);
    Assert.AreEqual(4, LFront.NumPoints);
    LFront.Free;
    Assert.AreEqual(PLANESIDE_BACK, LWinding.Split(TGeoVec3.Make(1, 0, -5), 0.1, LFront, LBack));
    Assert.IsNull(LFront);
    LBack.Free;
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.SplitDiUnWindingDa16PuntiNonDovrebbeSforareLaCapacita;
var
  LWinding, LFront, LBack: TGeoWinding2D;
  LIndex: Integer;
  LAngle: Single;
begin
  // the original writes sides[16] and dists[16] past its arrays: here the 17th element exists
  LWinding := TGeoWinding2D.Create;
  try
    for LIndex := 0 to MAX_POINTS_ON_WINDING_2D - 1 do
    begin
      LAngle := 2 * Pi * LIndex / MAX_POINTS_ON_WINDING_2D;
      LWinding.AddPoint(TIdVec2.Create(Cos(LAngle), Sin(LAngle)));
    end;
    Assert.AreEqual(PLANESIDE_CROSS, LWinding.Split(TGeoVec3.Make(1, 0, 0.1), 0.01, LFront, LBack));
    Assert.IsTrue(LFront.NumPoints >= 3);
    Assert.IsTrue(LBack.NumPoints >= 3);
    LFront.Free;
    LBack.Free;
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.ClipInPlaceDovrebbeTagliareIlRetro;
var
  LWinding: TGeoWinding2D;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    Assert.IsTrue(LWinding.ClipInPlace(TGeoVec3.Make(0.6, 0.8, -1.4), 0.1));
    AssertNear(-2, LWinding.GetArea, 1E-4);
    Assert.AreEqual(4, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.ClipInPlaceFuoriDalPianoDovrebbeSvuotareIlWinding;
var
  LWinding: TGeoWinding2D;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    Assert.IsFalse(LWinding.ClipInPlace(TGeoVec3.Make(1, 0, -5), 0.1));
    Assert.AreEqual(0, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
  // a winding on the plane is kept only on request
  LWinding := TGeoWinding2D.Create;
  try
    LWinding.AddPoint(TIdVec2.Create(0, 0));
    LWinding.AddPoint(TIdVec2.Create(1, 0));
    LWinding.AddPoint(TIdVec2.Create(2, 0));
    Assert.IsTrue(LWinding.ClipInPlace(TGeoVec3.Make(0, 1, 0), 0.1, True));
    Assert.AreEqual(3, LWinding.NumPoints);
    Assert.IsFalse(LWinding.ClipInPlace(TGeoVec3.Make(0, 1, 0), 0.1, False));
    Assert.AreEqual(0, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.ExpandDovrebbeAllargareUnQuadratoDellaDistanza;
var
  LWinding: TGeoWinding2D;
  LMins, LMaxs: TIdVec2;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    LWinding.Expand(0.5);
    LWinding.GetBounds(LMins, LMaxs);
    // every corner moves by the sum of the two edge normals scaled by the distance
    AssertNear(3, LMaxs.X - LMins.X, 1E-5);
    AssertNear(3, LMaxs.Y - LMins.Y, 1E-5);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.ExpandForAxialBoxDovrebbeAllargareUnQuadratoDellaMetaDelBox;
var
  LWinding: TGeoWinding2D;
  LMins, LMaxs: TIdVec2;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    LWinding.ExpandForAxialBox(TIdVec2.Create(-0.5, -0.5), TIdVec2.Create(0.5, 0.5));
    LWinding.GetBounds(LMins, LMaxs);
    AssertNear(3, LMaxs.X - LMins.X, 1E-4);
    AssertNear(3, LMaxs.Y - LMins.Y, 1E-4);
    Assert.AreEqual(4, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.ExpandForAxialBoxDiUnWindingDegenereNonDovrebbeLeggereFuoriDalVettore;
var
  LWinding: TGeoWinding2D;
begin
  // every edge is shorter than 0.1: the original reads planes[-1]
  LWinding := TGeoWinding2D.Create;
  try
    LWinding.AddPoint(TIdVec2.Create(0, 0));
    LWinding.AddPoint(TIdVec2.Create(0.01, 0));
    LWinding.AddPoint(TIdVec2.Create(0.01, 0.01));
    LWinding.ExpandForAxialBox(TIdVec2.Create(-1, -1), TIdVec2.Create(1, 1));
    Assert.AreEqual(0, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.IlRaggioDovrebbeColpireIDueLatiOpposti;
var
  LWinding: TGeoWinding2D;
  LScale1, LScale2: Single;
  LEdge1, LEdge2: Integer;
begin
  LWinding := MakeSquare(0, 0, 2);
  try
    Assert.IsTrue(LWinding.RayIntersection(TIdVec2.Create(-1, 1), TIdVec2.Create(1, 0), LScale1, LScale2, LEdge1,
      LEdge2));
    AssertNear(1, LScale1, 1E-5);
    AssertNear(3, LScale2, 1E-5);
    Assert.AreNotEqual(LEdge1, LEdge2);
    Assert.IsFalse(LWinding.RayIntersection(TIdVec2.Create(-1, 5), TIdVec2.Create(1, 0), LScale1, LScale2, LEdge1,
      LEdge2));
    Assert.AreEqual(-1, LEdge1);
    Assert.IsTrue(LWinding.LineIntersection(TIdVec2.Create(-1, 1), TIdVec2.Create(3, 1)));
    Assert.IsFalse(LWinding.LineIntersection(TIdVec2.Create(-1, 5), TIdVec2.Create(3, 5)));
    Assert.IsTrue(LWinding.PointInside(TIdVec2.Create(1, 1), 0));
    Assert.IsFalse(LWinding.PointInside(TIdVec2.Create(3, 1), 0));
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.IlPianoDa2DDovrebbeEssereQuelloDellaRetta;
var
  LPlane: TGeoVec3;
  LPoint: TIdVec2;
begin
  LPlane := TGeoWinding2D.Plane2DFromPoints(TIdVec2.Create(0, 0), TIdVec2.Create(2, 0));
  Assert.AreEqual<Single>(0, LPlane.X);
  Assert.AreEqual<Single>(2, LPlane.Y);
  Assert.AreEqual<Single>(0, LPlane.Z);
  LPlane := TGeoWinding2D.Plane2DFromVecs(TIdVec2.Create(0, 3), TIdVec2.Create(4, 0), True);
  AssertNear(1, LPlane.Y, 1E-6);
  AssertNear(-3, LPlane.Z, 1E-5);
  Assert.IsTrue(TGeoWinding2D.Plane2DIntersection(TGeoVec3.Make(1, 0, -2), TGeoVec3.Make(0, 1, -3), LPoint));
  AssertNear(2, LPoint.X, 1E-6);
  AssertNear(3, LPoint.Y, 1E-6);
  Assert.IsFalse(TGeoWinding2D.Plane2DIntersection(TGeoVec3.Make(1, 0, -2), TGeoVec3.Make(1, 0, -3), LPoint));
end;

procedure TTestGeometryWinding2D.AddPointOltreLaCapacitaDovrebbeDareEccezione;
var
  LWinding: TGeoWinding2D;
  LIndex: Integer;
begin
  LWinding := TGeoWinding2D.Create;
  try
    Assert.WillRaise(
      procedure
      var
        LPoint: Integer;
      begin
        for LPoint := 0 to 40 do
          LWinding.AddPoint(TIdVec2.Create(LPoint, 0));
      end, EGeometryException);
    LIndex := LWinding.NumPoints;
    Assert.IsTrue(LIndex > MAX_POINTS_ON_WINDING_2D);
    LWinding.Clear;
    Assert.AreEqual(0, LWinding.NumPoints);
  finally
    LWinding.Free;
  end;
end;

procedure TTestGeometryWinding2D.LeMisureDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LWinding: TGeoWinding2D;
  LCenter, LMins, LMaxs: TIdVec2;
  LReversed: TGeoWinding2D;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['w2_basic', 'w2_reverse']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LWinding := ReadWinding(LReader);
      LWriter := TGeoGoldenWriter.Create;
      try
        if LLine.StartsWith('w2_basic') then
        begin
          LCenter := LWinding.GetCenter;
          LWinding.GetBounds(LMins, LMaxs);
          LWriter.Float(LWinding.GetArea);
          LWriter.Vec2(LCenter);
          LWriter.Float(LWinding.GetRadius(LCenter));
          LWriter.Vec2(LMins);
          LWriter.Vec2(LMaxs);
          LWriter.Flag(LWinding.IsTiny);
          LWriter.Flag(LWinding.IsHuge);
        end
        else
        begin
          LReversed := LWinding.Reverse;
          try
            PutWinding(LWriter, LReversed);
          finally
            LReversed.Free;
          end;
        end;
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
        LWinding.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryWinding2D.LeOperazioniSulPianoDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LWinding: TGeoWinding2D;
  LPlane: TGeoVec3;
  LEpsilon: Single;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['w2_plane']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LWinding := ReadWinding(LReader);
      LPlane := LReader.Vec3;
      LEpsilon := LReader.Float;
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.Float(LWinding.PlaneDistance(LPlane));
        LWriter.Int(LWinding.PlaneSide(LPlane, LEpsilon));
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
        LWinding.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryWinding2D.SplitEClipDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LWinding, LFront, LBack: TGeoWinding2D;
  LPlane: TGeoVec3;
  LEpsilon: Single;
  LKeep, LResult: Boolean;
  LSide: Integer;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['w2_split', 'w2_clip']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LWinding := ReadWinding(LReader);
      LPlane := LReader.Vec3;
      LEpsilon := LReader.Float;
      LWriter := TGeoGoldenWriter.Create;
      try
        if LLine.StartsWith('w2_split') then
        begin
          LSide := LWinding.Split(LPlane, LEpsilon, LFront, LBack);
          LWriter.Int(LSide);
          PutWinding(LWriter, LFront);
          PutWinding(LWriter, LBack);
          LFront.Free;
          LBack.Free;
        end
        else
        begin
          LKeep := LReader.Flag;
          LResult := LWinding.ClipInPlace(LPlane, LEpsilon, LKeep);
          LWriter.Flag(LResult);
          PutWinding(LWriter, LWinding);
        end;
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
        LWinding.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryWinding2D.ExpandDovrebbeDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LWinding: TGeoWinding2D;
  LDistance: Single;
  LMins, LMaxs: TIdVec2;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['w2_expand', 'w2_expandbox']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LWinding := ReadWinding(LReader);
      LWriter := TGeoGoldenWriter.Create;
      try
        if LLine.StartsWith('w2_expandbox') then
        begin
          LMins := LReader.Vec2;
          LMaxs := LReader.Vec2;
          LWinding.ExpandForAxialBox(LMins, LMaxs);
        end
        else
        begin
          LDistance := LReader.Float;
          LWinding.Expand(LDistance);
        end;
        PutWinding(LWriter, LWinding);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
        LWinding.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryWinding2D.PuntoLineaERaggioDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LWinding: TGeoWinding2D;
  LFirst, LSecond: TIdVec2;
  LEpsilon, LScale1, LScale2: Single;
  LEdges: array[0..1] of Integer;
  LHit: Boolean;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['w2_inside', 'w2_line', 'w2_ray']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LWinding := ReadWinding(LReader);
      LFirst := LReader.Vec2;
      LWriter := TGeoGoldenWriter.Create;
      try
        if LLine.StartsWith('w2_inside') then
        begin
          LEpsilon := LReader.Float;
          LWriter.Flag(LWinding.PointInside(LFirst, LEpsilon));
          TGeoGolden.CompareOutput(LLine, LWriter.Text);
        end
        else if LLine.StartsWith('w2_line') then
        begin
          LSecond := LReader.Vec2;
          LWriter.Flag(LWinding.LineIntersection(LFirst, LSecond));
          TGeoGolden.CompareOutput(LLine, LWriter.Text);
        end
        else
        begin
          LSecond := LReader.Vec2;
          LHit := LWinding.RayIntersection(LFirst, LSecond, LScale1, LScale2, LEdges[0], LEdges[1]);
          LWriter.Flag(LHit);
          LWriter.Float(LScale1);
          LWriter.Float(LScale2);
          LWriter.Int(LEdges[0]);
          LWriter.Int(LEdges[1]);
          TGeoGolden.CompareOutput(LLine, LWriter.Text);
        end;
      finally
        LWriter.Free;
        LWinding.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestGeometryWinding2D.IPianiDa2DDovrebberoDareLeStesseRispostePerIlCpp;
var
  LLines: TStringList;
  LLine: string;
  LReader: TGeoGoldenReader;
  LWriter: TGeoGoldenWriter;
  LStart, LEnd, LDirection, LPoint: TIdVec2;
  LPlane2, LPlane4: TGeoVec3;
begin
  LLines := TGeoGolden.Load('surface.golden.txt', ['w2_plane2d']);
  try
    Assert.IsTrue(LLines.Count > 0);
    for LLine in LLines do
    begin
      LReader := TGeoGoldenReader.Open(LLine);
      LStart := LReader.Vec2;
      LEnd := LReader.Vec2;
      LDirection := LReader.Vec2;
      LWriter := TGeoGoldenWriter.Create;
      try
        LWriter.Vec3(TGeoWinding2D.Plane2DFromPoints(LStart, LEnd, False));
        LPlane2 := TGeoWinding2D.Plane2DFromPoints(LStart, LEnd, True);
        LWriter.Vec3(LPlane2);
        LWriter.Vec3(TGeoWinding2D.Plane2DFromVecs(LStart, LDirection, False));
        LPlane4 := TGeoWinding2D.Plane2DFromVecs(LStart, LDirection, True);
        LWriter.Vec3(LPlane4);
        LWriter.Flag(TGeoWinding2D.Plane2DIntersection(LPlane2, LPlane4, LPoint));
        LWriter.Vec2(LPoint);
        TGeoGolden.CompareOutput(LLine, LWriter.Text);
      finally
        LWriter.Free;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

end.
