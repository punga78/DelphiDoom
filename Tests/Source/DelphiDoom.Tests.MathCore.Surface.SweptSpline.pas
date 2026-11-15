{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of MathCore - idSurface_SweptSpline: parity with the C++  }
{  idLib and invariants                                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Surface.SweptSpline;

{$Q-}
{$R-}

interface

uses
  System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Parity with the real <c>idSurface_SweptSpline</c> of Doom 3 (Tests\Data\Geometry\swept.golden.txt,
  ///   27 tessellations written by the C++ class compiled with bcc32c, harness
  ///   Tools\Verifica\96\swept-main.cpp): the vertices (position, texture coordinates, normal, two
  ///   tangents, colour) and the indexes. Every line is rebuilt from its inputs: the knots of the
  ///   two splines and the subdivisions.
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestSweptSpline = class(TObject)
  private
    FLines: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeDareLeStesseTassellazioniDelCpp;
    [Test]
    procedure SenzaSplineDovrebbeSvuotareLaSuperficie;
    [Test]
    procedure ConTroppoPocheSuddivisioniDovrebbeSollevareUnEccezione;
    [Test]
    procedure ConUnaSplineSenzaNodiDovrebbeSollevareUnEccezione;
    [Test]
    procedure ClearDovrebbeLiberareLeSpline;
    [Test]
    procedure IlCerchioDovrebbeAvereQuattroNodiEUnaCurvaChiusa;
    [Test]
    procedure GetFrameDovrebbeDareUnaBaseOrtonormaleOrientataSullaDirezione;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4, DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4,
  DelphiDoom.MathCore.Float.Curve.CatmullRomSpline, DelphiDoom.MathCore.Float.Curve.NURBS,
  DelphiDoom.MathCore.Float.Curve.Spline, DelphiDoom.MathCore.Float.Curve.Types,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.MathCore.Float.Surface.SweptSpline,
  DelphiDoom.Tests.MathCore.Matrix.Lines;

function BitsOrInt(const AToken: string): Single;
begin
  Result := TMatrixLines.Bits(AToken);
end;

function MakeCurve(const AKind, ACount: Integer; const AKnots: TArray<Single>;
  const AStart: Integer): TIdCurveSpline<TIdVec4>;
var
  LIndex: Integer;
begin
  if (AKind = 0) or (AKind = 1) or (AKind = 5) then
    Result := TIdCurveCatmullRomSpline<TIdVec4>.Create(TIdCurveVec4Arithmetic.Create)
  else
    Result := TIdCurveNURBS<TIdVec4>.Create(TIdCurveVec4Arithmetic.Create);
  for LIndex := 0 to ACount - 1 do
  begin
    Result.AddValue(AKnots[AStart + LIndex * 5], TIdVec4.Create(AKnots[AStart + LIndex * 5 + 1],
      AKnots[AStart + LIndex * 5 + 2], AKnots[AStart + LIndex * 5 + 3],
      AKnots[AStart + LIndex * 5 + 4]));
  end;
  if (AKind = 1) or (AKind = 3) then
  begin
    Result.BoundaryType := TIdCurveBoundary.Closed;
    Result.CloseTime := 100.0;
  end;
  if AKind = 5 then
    Result.BoundaryType := TIdCurveBoundary.Clamped;
end;

procedure PutVec(var ALine: string; const AX, AY, AZ: Single);
begin
  TMatrixLines.Put(ALine, AX);
  TMatrixLines.Put(ALine, AY);
  TMatrixLines.Put(ALine, AZ);
end;

procedure TTestSweptSpline.Setup;
begin
  FLines := TStringList.Create;
  FLines.LoadFromFile(TMatrixLines.DataPath('..\Geometry\swept.golden.txt'));
end;

procedure TTestSweptSpline.TearDown;
begin
  FLines.Free;
end;

procedure TTestSweptSpline.DovrebbeDareLeStesseTassellazioniDelCpp;
var
  LRow, LIndex, LTokenCount: Integer;
  LParts: TArray<string>;
  LKnots: TArray<Single>;
  LMainKind, LMainCount, LSweptKind, LSweptCount, LSplineSub, LSweptSub: Integer;
  LRadius: Single;
  LSurface: TIdSurfaceSweptSpline;
  LLine: string;
  LActual, LExpected: TStringList;
  LVertex: Integer;
begin
  LActual := TStringList.Create;
  LExpected := TStringList.Create;
  try
    for LRow := 0 to FLines.Count - 1 do
    begin
      LParts := FLines[LRow].Split([' ']);
      LMainKind := StrToInt(LParts[1]);
      LMainCount := StrToInt(LParts[2]);
      LSweptKind := StrToInt(LParts[3]);
      LSweptCount := StrToInt(LParts[4]);
      LRadius := BitsOrInt(LParts[5]);
      LSplineSub := StrToInt(LParts[6]);
      LSweptSub := StrToInt(LParts[7]);
      LTokenCount := LMainCount * 5 + LSweptCount * 5;
      SetLength(LKnots, LTokenCount);
      for LIndex := 0 to LTokenCount - 1 do
      begin
        LKnots[LIndex] := BitsOrInt(LParts[8 + LIndex]);
      end;
      LSurface := TIdSurfaceSweptSpline.Create;
      try
        LSurface.SetSpline(MakeCurve(LMainKind, LMainCount, LKnots, 0));
        if LSweptKind < 0 then
          LSurface.SetSweptCircle(LRadius)
        else
          LSurface.SetSweptSpline(MakeCurve(LSweptKind, LSweptCount, LKnots, LMainCount * 5));
        LSurface.Tessellate(LSplineSub, LSweptSub);
        LLine := TMatrixLines.HeadOf(FLines[LRow]);
        TMatrixLines.PutInt(LLine, LSurface.NumVertices);
        for LVertex := 0 to LSurface.NumVertices - 1 do
        begin
          with LSurface[LVertex] do
          begin
            PutVec(LLine, Xyz.X, Xyz.Y, Xyz.Z);
            TMatrixLines.Put(LLine, St.X);
            TMatrixLines.Put(LLine, St.Y);
            PutVec(LLine, Normal.X, Normal.Y, Normal.Z);
            PutVec(LLine, Tangents[0].X, Tangents[0].Y, Tangents[0].Z);
            PutVec(LLine, Tangents[1].X, Tangents[1].Y, Tangents[1].Z);
            TMatrixLines.PutInt(LLine, Color[0]);
            TMatrixLines.PutInt(LLine, Color[1]);
            TMatrixLines.PutInt(LLine, Color[2]);
            TMatrixLines.PutInt(LLine, Color[3]);
          end;
        end;
        TMatrixLines.PutInt(LLine, LSurface.NumIndexes);
        for LIndex := 0 to LSurface.NumIndexes - 1 do
        begin
          TMatrixLines.PutInt(LLine, LSurface.Indexes[LIndex]);
        end;
      finally
        LSurface.Free;
      end;
      LActual.Add(LLine);
      LExpected.Add(FLines[LRow]);
    end;
    Assert.AreEqual(27, LExpected.Count);
    // the input tokens are in the head, copied as they are; the outputs are floats chained through
    // the matrices of the frames and the derivatives of the splines: a few ULPs and the absolute
    // error of 1e-3 on the values of the order of 100
    TMatrixLines.CompareLines(LExpected, LActual, 8, 2E-5, 1E-3);
  finally
    LExpected.Free;
    LActual.Free;
  end;
end;

procedure TTestSweptSpline.SenzaSplineDovrebbeSvuotareLaSuperficie;
var
  LSurface: TIdSurfaceSweptSpline;
begin
  LSurface := TIdSurfaceSweptSpline.Create;
  try
    LSurface.SetSweptCircle(1.0);
    LSurface.Tessellate(4, 4);
    Assert.AreEqual(0, LSurface.NumVertices);
    Assert.AreEqual(0, LSurface.NumIndexes);
  finally
    LSurface.Free;
  end;
end;

procedure TTestSweptSpline.ConTroppoPocheSuddivisioniDovrebbeSollevareUnEccezione;
var
  LSurface: TIdSurfaceSweptSpline;
  LKnots: TArray<Single>;
begin
  LSurface := TIdSurfaceSweptSpline.Create;
  try
    LKnots := [0.0, 0.0, 0.0, 0.0, 0.0, 100.0, 10.0, 0.0, 0.0, 1.0];
    LSurface.SetSpline(MakeCurve(0, 2, LKnots, 0));
    LSurface.SetSweptCircle(1.0);
    Assert.WillRaise(
      procedure
      begin
        LSurface.Tessellate(1, 4);
      end, EGeometryException);
    Assert.WillRaise(
      procedure
      begin
        LSurface.Tessellate(4, 1);
      end, EGeometryException);
  finally
    LSurface.Free;
  end;
end;

procedure TTestSweptSpline.ConUnaSplineSenzaNodiDovrebbeSollevareUnEccezione;
var
  LSurface: TIdSurfaceSweptSpline;
begin
  LSurface := TIdSurfaceSweptSpline.Create;
  try
    LSurface.SetSpline(TIdCurveCatmullRomSpline<TIdVec4>.Create(TIdCurveVec4Arithmetic.Create));
    LSurface.SetSweptCircle(1.0);
    Assert.WillRaise(
      procedure
      begin
        LSurface.Tessellate(4, 4);
      end, EGeometryException);
  finally
    LSurface.Free;
  end;
end;

procedure TTestSweptSpline.ClearDovrebbeLiberareLeSpline;
var
  LSurface: TIdSurfaceSweptSpline;
  LKnots: TArray<Single>;
begin
  LSurface := TIdSurfaceSweptSpline.Create;
  try
    LKnots := [0.0, 0.0, 0.0, 0.0, 0.0, 100.0, 10.0, 0.0, 0.0, 1.0];
    LSurface.SetSpline(MakeCurve(0, 2, LKnots, 0));
    LSurface.SetSweptCircle(1.0);
    LSurface.Tessellate(3, 4);
    Assert.AreEqual(12, LSurface.NumVertices);
    // replacing a spline with itself must not free it
    LSurface.SetSweptCircle(2.0);
    LSurface.Tessellate(3, 4);
    LSurface.Clear;
    Assert.AreEqual(0, LSurface.NumVertices);
    // the splines are gone: a new tessellation is empty
    LSurface.Tessellate(3, 4);
    Assert.AreEqual(0, LSurface.NumVertices);
  finally
    LSurface.Free;
  end;
end;

procedure TTestSweptSpline.IlCerchioDovrebbeAvereQuattroNodiEUnaCurvaChiusa;
var
  LSurface: TIdSurfaceSweptSpline;
  LKnots: TArray<Single>;
  LIndex: Integer;
  LRadius: Double;
begin
  LSurface := TIdSurfaceSweptSpline.Create;
  try
    LKnots := [0.0, 0.0, 0.0, 0.0, 0.0, 100.0, 10.0, 0.0, 0.0, 1.0];
    LSurface.SetSpline(MakeCurve(0, 2, LKnots, 0));
    LSurface.SetSweptCircle(3.0);
    LSurface.Tessellate(2, 8);
    // a closed swept spline of 8 steps makes 8 quads per row: 1 ring step * 8 * 2 triangles
    Assert.AreEqual(1 * 8 * 6, LSurface.NumIndexes);
    for LIndex := 0 to 7 do
    begin
      LRadius := Sqrt(Sqr(LSurface[LIndex].Xyz.Y) + Sqr(LSurface[LIndex].Xyz.Z));
      Assert.IsTrue((LRadius > 2.0) and (LRadius < 5.0), 'i punti stanno attorno all''asse');
    end;
  finally
    LSurface.Free;
  end;
end;

procedure TTestSweptSpline.GetFrameDovrebbeDareUnaBaseOrtonormaleOrientataSullaDirezione;
var
  LFrame: TIdMat3;
  LDirection: TIdVec3;
begin
  LDirection := TIdVec3.Create(1.0, 2.0, 3.0);
  LDirection.Normalize;
  LFrame := TIdSurfaceSweptSpline.GetFrame(TIdMat3.Identity, TIdVec3.Create(1.0, 2.0, 3.0));
  Assert.AreEqual(Double(LDirection.X), Double(LFrame.Rows[2].X), 1E-5);
  Assert.AreEqual(Double(LDirection.Y), Double(LFrame.Rows[2].Y), 1E-5);
  Assert.AreEqual(Double(LDirection.Z), Double(LFrame.Rows[2].Z), 1E-5);
  Assert.AreEqual(0.0, Double(LFrame.Rows[0] * LFrame.Rows[1]), 1E-5);
  Assert.AreEqual(0.0, Double(LFrame.Rows[0] * LFrame.Rows[2]), 1E-5);
  Assert.AreEqual(1.0, Double(LFrame.Rows[0] * LFrame.Rows[0]), 1E-5);
  Assert.AreEqual(1.0, Double(LFrame.Rows[1] * LFrame.Rows[1]), 1E-5);
end;

end.
