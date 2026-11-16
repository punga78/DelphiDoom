{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - TIdSurfaceSweptSpline               }
{                                                                              }
{  Port of idSurface_SweptSpline (idlib\geometry\Surface_SweptSpline.h and     }
{  Surface_SweptSpline.cpp) of the Doom 3 GPL Source Code. Copyright (C)       }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3     }
{  GPL Source Code (id Software).                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.Surface.SweptSpline;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Surface, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.MathCore.Float.Curve.Spline, DelphiDoom.MathCore.Float.Mat3;

type
  /// <summary>
  ///   A surface made by sweeping a spline (the swept spline, for example a circle) along another
  ///   spline (idSurface_SweptSpline). The splines are curves of 4D vectors: xyz is the position
  ///   and w the texture coordinate. The surface owns the two splines. It lives in MathCore and
  ///   not in Geometry because it needs the curves. <c>Tessellate</c> needs at least two
  ///   subdivisions per spline.
  /// </summary>
  TIdSurfaceSweptSpline = class(TGeoSurface)
  strict private
    FSpline: TIdCurveSpline<TIdVec4>;
    FSweptSpline: TIdCurveSpline<TIdVec4>;
  public
    destructor Destroy; override;
    /// <summary>Takes the spline along which the swept spline moves; the surface owns it</summary>
    procedure SetSpline(const ASpline: TIdCurveSpline<TIdVec4>);
    /// <summary>Takes the spline that is swept; the surface owns it</summary>
    procedure SetSweptSpline(const ASweptSpline: TIdCurveSpline<TIdVec4>);
    /// <summary>Sets the swept spline to a closed NURBS circle of the radius</summary>
    procedure SetSweptCircle(const ARadius: Single);
    /// <summary>
    ///   The frame that follows the direction: the previous frame turned by the shortest rotation
    ///   that takes its z axis to the direction (GetFrame)
    /// </summary>
    class function GetFrame(const APreviousFrame: TIdMat3; const ADirection: TIdVec3): TIdMat3;
      static;
    /// <summary>Makes the triangles; clears the surface when a spline is missing</summary>
    procedure Tessellate(const ASplineSubdivisions, ASweptSplineSubdivisions: Integer);
    /// <summary>Clears the surface and frees the two splines (idSurface_SweptSpline::Clear)</summary>
    procedure Clear; reintroduce;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.DrawVert, DelphiDoom.Geometry.Types,
  DelphiDoom.IdLib.Math.Math, DelphiDoom.MathCore.Float.Curve.NURBS,
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4, DelphiDoom.MathCore.Float.Curve.Types,
  DelphiDoom.MathCore.Float.GeometryAdapter;

const
  SSubdivisions = 'A swept spline surface needs at least two subdivisions per spline';
  SNoKnots = 'A spline of a swept spline surface needs at least one knot';

{ TIdSurfaceSweptSpline }

destructor TIdSurfaceSweptSpline.Destroy;
begin
  FSweptSpline.Free;
  FSpline.Free;
  inherited Destroy;
end;

procedure TIdSurfaceSweptSpline.SetSpline(const ASpline: TIdCurveSpline<TIdVec4>);
begin
  if FSpline <> ASpline then
    FSpline.Free;
  FSpline := ASpline;
end;

procedure TIdSurfaceSweptSpline.SetSweptSpline(const ASweptSpline: TIdCurveSpline<TIdVec4>);
begin
  if FSweptSpline <> ASweptSpline then
    FSweptSpline.Free;
  FSweptSpline := ASweptSpline;
end;

procedure TIdSurfaceSweptSpline.SetSweptCircle(const ARadius: Single);
var
  LNurbs: TIdCurveNURBS<TIdVec4>;
begin
  LNurbs := TIdCurveNURBS<TIdVec4>.Create(TIdCurveVec4Arithmetic.Create);
  LNurbs.Clear;
  LNurbs.AddValue(0.0, TIdVec4.Create(ARadius, ARadius, 0.0, 0.0));
  LNurbs.AddValue(100.0, TIdVec4.Create(-ARadius, ARadius, 0.0, 0.25));
  LNurbs.AddValue(200.0, TIdVec4.Create(-ARadius, -ARadius, 0.0, 0.5));
  LNurbs.AddValue(300.0, TIdVec4.Create(ARadius, -ARadius, 0.0, 0.75));
  LNurbs.BoundaryType := TIdCurveBoundary.Closed;
  LNurbs.CloseTime := 100.0;
  SetSweptSpline(LNurbs);
end;

class function TIdSurfaceSweptSpline.GetFrame(const APreviousFrame: TIdMat3;
  const ADirection: TIdVec3): TIdMat3;
var
  LWx, LWy, LWz, LXx, LYy, LYz, LXy, LXz, LZz, LX2, LY2, LZ2: Single;
  LA, LC, LS, LX, LY, LZ: Single;
  LD, LV: TIdVec3;
  LAxis: TIdMat3;
begin
  LD := ADirection;
  LD.Normalize;
  LV := LD.Cross(APreviousFrame.Rows[2]);
  LV.Normalize;
  LA := TIdMath.ACos(APreviousFrame.Rows[2] * LD) * 0.5;
  LC := TIdMath.Cos(LA);
  LS := TIdMath.Sqrt(1.0 - LC * LC);
  LX := LV.X * LS;
  LY := LV.Y * LS;
  LZ := LV.Z * LS;
  LX2 := LX + LX;
  LY2 := LY + LY;
  LZ2 := LZ + LZ;
  LXx := LX * LX2;
  LXy := LX * LY2;
  LXz := LX * LZ2;
  LYy := LY * LY2;
  LYz := LY * LZ2;
  LZz := LZ * LZ2;
  LWx := LC * LX2;
  LWy := LC * LY2;
  LWz := LC * LZ2;
  LAxis.Rows[0].X := 1.0 - (LYy + LZz);
  LAxis.Rows[0].Y := LXy - LWz;
  LAxis.Rows[0].Z := LXz + LWy;
  LAxis.Rows[1].X := LXy + LWz;
  LAxis.Rows[1].Y := 1.0 - (LXx + LZz);
  LAxis.Rows[1].Z := LYz - LWx;
  LAxis.Rows[2].X := LXz - LWy;
  LAxis.Rows[2].Y := LYz + LWx;
  LAxis.Rows[2].Z := 1.0 - (LXx + LYy);
  Result := APreviousFrame * LAxis;
  Result.Rows[2] := ADirection;
  Result.Rows[2].Normalize;
  Result.Rows[1].Cross(Result.Rows[2], Result.Rows[0]);
  Result.Rows[1].Normalize;
  Result.Rows[0].Cross(Result.Rows[1], Result.Rows[2]);
  Result.Rows[0].Normalize;
end;

procedure TIdSurfaceSweptSpline.Tessellate(const ASplineSubdivisions,
  ASweptSplineSubdivisions: Integer);
var
  LI, LJ, LOffset, LBaseOffset, LSplineDiv, LSweptSplineDiv, LI0, LI1, LJ0, LJ1: Integer;
  LTotalTime, LT: Single;
  LSplinePos, LSplineD1: TIdVec4;
  LSplineMat: TIdMat3;
  LBase: TGeoDrawVert;
  LPosition, LTangent0, LTangent1, LNormal: TIdVec3;
begin
  if (FSpline = nil) or (FSweptSpline = nil) then
  begin
    inherited Clear;
    Exit;
  end;
  if (ASplineSubdivisions < 2) or (ASweptSplineSubdivisions < 2) then
    raise EGeometryException.Create(SSubdivisions);
  if (FSpline.GetNumValues < 1) or (FSweptSpline.GetNumValues < 1) then
    raise EGeometryException.Create(SNoKnots);
  SetLength(FVerts, ASplineSubdivisions * ASweptSplineSubdivisions);
  // the points and first derivatives of the swept spline, in the last row of the vertices
  LTotalTime := FSweptSpline.GetTime(FSweptSpline.GetNumValues - 1) - FSweptSpline.GetTime(0) +
    FSweptSpline.CloseTime;
  if FSweptSpline.BoundaryType = TIdCurveBoundary.Closed then
    LSweptSplineDiv := ASweptSplineSubdivisions
  else
    LSweptSplineDiv := ASweptSplineSubdivisions - 1;
  LBaseOffset := (ASplineSubdivisions - 1) * ASweptSplineSubdivisions;
  for LI := 0 to ASweptSplineSubdivisions - 1 do
  begin
    LT := LTotalTime * LI / LSweptSplineDiv;
    LSplinePos := FSweptSpline.GetCurrentValue(LT);
    LSplineD1 := FSweptSpline.GetCurrentFirstDerivative(LT);
    FVerts[LBaseOffset + LI].Xyz := TIdGeometryAdapter.ToGeo(LSplinePos.ToVec3);
    FVerts[LBaseOffset + LI].St.X := LSplinePos.W;
    FVerts[LBaseOffset + LI].Tangents[0] := TIdGeometryAdapter.ToGeo(LSplineD1.ToVec3);
  end;
  // sweep the spline
  LTotalTime := FSpline.GetTime(FSpline.GetNumValues - 1) - FSpline.GetTime(0) +
    FSpline.CloseTime;
  if FSpline.BoundaryType = TIdCurveBoundary.Closed then
    LSplineDiv := ASplineSubdivisions
  else
    LSplineDiv := ASplineSubdivisions - 1;
  LSplineMat := TIdMat3.Identity;
  for LI := 0 to ASplineSubdivisions - 1 do
  begin
    LT := LTotalTime * LI / LSplineDiv;
    LSplinePos := FSpline.GetCurrentValue(LT);
    LSplineD1 := FSpline.GetCurrentFirstDerivative(LT);
    LSplineMat := GetFrame(LSplineMat, LSplineD1.ToVec3);
    LOffset := LI * ASweptSplineSubdivisions;
    for LJ := 0 to ASweptSplineSubdivisions - 1 do
    begin
      // the last row is the base row itself: it is read before it is written
      LBase := FVerts[LBaseOffset + LJ];
      LPosition := LSplinePos.ToVec3 + TIdGeometryAdapter.ToId(LBase.Xyz) * LSplineMat;
      LTangent0 := TIdGeometryAdapter.ToId(LBase.Tangents[0]) * LSplineMat;
      LTangent1 := LSplineD1.ToVec3;
      LNormal := LTangent1.Cross(LTangent0);
      LNormal.Normalize;
      FVerts[LOffset + LJ].Xyz := TIdGeometryAdapter.ToGeo(LPosition);
      FVerts[LOffset + LJ].St.X := LBase.St.X;
      FVerts[LOffset + LJ].St.Y := LSplinePos.W;
      FVerts[LOffset + LJ].Tangents[0] := TIdGeometryAdapter.ToGeo(LTangent0);
      FVerts[LOffset + LJ].Tangents[1] := TIdGeometryAdapter.ToGeo(LTangent1);
      FVerts[LOffset + LJ].Normal := TIdGeometryAdapter.ToGeo(LNormal);
      FVerts[LOffset + LJ].Color[0] := 0;
      FVerts[LOffset + LJ].Color[1] := 0;
      FVerts[LOffset + LJ].Color[2] := 0;
      FVerts[LOffset + LJ].Color[3] := 0;
    end;
  end;
  SetLength(FIndexes, LSplineDiv * LSweptSplineDiv * 2 * 3);
  // the indexes of the triangles
  LOffset := 0;
  for LI := 0 to LSplineDiv - 1 do
  begin
    LI0 := LI * ASweptSplineSubdivisions;
    LI1 := (LI + 1) mod ASplineSubdivisions * ASweptSplineSubdivisions;
    for LJ := 0 to LSweptSplineDiv - 1 do
    begin
      LJ0 := LJ;
      LJ1 := (LJ + 1) mod ASweptSplineSubdivisions;
      FIndexes[LOffset] := LI0 + LJ0;
      FIndexes[LOffset + 1] := LI0 + LJ1;
      FIndexes[LOffset + 2] := LI1 + LJ1;
      FIndexes[LOffset + 3] := LI1 + LJ1;
      FIndexes[LOffset + 4] := LI1 + LJ0;
      FIndexes[LOffset + 5] := LI0 + LJ0;
      Inc(LOffset, 6);
    end;
  end;
  GenerateEdgeIndexes;
end;

procedure TIdSurfaceSweptSpline.Clear;
begin
  inherited Clear;
  FreeAndNil(FSpline);
  FreeAndNil(FSweptSpline);
end;

end.
