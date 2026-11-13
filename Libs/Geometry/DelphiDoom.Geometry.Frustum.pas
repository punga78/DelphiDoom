{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the orthogonal frustum (idFrustum)           }
{                                                                              }
{  Port of idFrustum (idlib\bv\Frustum.h and Frustum.cpp) of the Doom 3 GPL    }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Frustum;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Sphere, DelphiDoom.Geometry.Box,
  DelphiDoom.Geometry.Winding;

type
  /// <summary>The eight corners of a frustum (or of a box)</summary>
  TGeoFrustumPoints = array[0..7] of TGeoVec3;

  /// <summary>The four vectors from the origin to the corners of the far plane</summary>
  TGeoFrustumCorners = array[0..3] of TGeoVec3;

  /// <summary>The six planes of a frustum, pointing outwards</summary>
  TGeoFrustumPlanes = array[0..5] of TGeoPlane;

  /// <summary>
  ///   An orthogonal frustum (idFrustum): origin, axis (forward, left, up as rows), near and far
  ///   distance, half width and half height at the far plane and the cached 1 / far (68 bytes).
  ///   The fields are public: the getters of the original (GetOrigin, GetAxis, GetNearDistance,
  ///   GetFarDistance, GetLeft, GetUp) are the fields themselves. A default constructed frustum
  ///   has near = far = 0 (not valid). Defects of the original kept: <c>Expand</c> (the const one)
  ///   computes the new 1 / far from the old far distance; <c>IntersectsSphere</c> tests the
  ///   z coordinate in the left plane region (0, 2, 0); <c>FromProjection</c> leaves the
  ///   frustum half changed when it fails.
  /// </summary>
  TGeoFrustum = record
    Origin: TGeoVec3;
    Axis: TGeoMat3;
    DNear: Single;
    DFar: Single;
    DLeft: Single;
    DUp: Single;
    InvFar: Single;
  strict private
    procedure ToClippedPoints(const AFractions: array of Single; out APoints: TGeoFrustumPoints);
    procedure ToIndexPoints(out AIndexPoints: TGeoFrustumPoints);
    procedure ToIndexPointsAndCornerVecs(out AIndexPoints: TGeoFrustumPoints; out ACornerVecs: TGeoFrustumCorners);
    procedure AxisProjection(const AIndexPoints: TGeoFrustumPoints; const ACornerVecs: TGeoFrustumCorners;
      const ADir: TGeoVec3; out AMin, AMax: Single); overload;
    function CullLocalBox(const ALocalOrigin, AExtents: TGeoVec3; const ALocalAxis: TGeoMat3): Boolean;
    function CullLocalFrustum(const ALocalFrustum: TGeoFrustum; const AIndexPoints: TGeoFrustumPoints;
      const ACornerVecs: TGeoFrustumCorners): Boolean;
    function CullLocalWinding(const APoints: TArray<TGeoVec3>; var APointCull: TArray<Integer>): Boolean;
    function BoundsCullLocalFrustum(const ABounds: TGeoBounds; const ALocalFrustum: TGeoFrustum;
      const AIndexPoints: TGeoFrustumPoints; const ACornerVecs: TGeoFrustumCorners): Boolean;
    function LocalLineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
    function LocalRayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
    function LocalFrustumIntersectsFrustum(const APoints: TGeoFrustumPoints; ATestFirstSide: Boolean): Boolean;
    function LocalFrustumIntersectsBounds(const APoints: TGeoFrustumPoints; const ABounds: TGeoBounds): Boolean;
    procedure AddLocalLineToProjectionBoundsSetCull(const AStart, AEnd: TGeoVec3;
      out AStartCull, AEndCull: Integer; var ABounds: TGeoBounds);
    procedure AddLocalLineToProjectionBoundsUseCull(const AStart, AEnd: TGeoVec3;
      AStartCull, AEndCull: Integer; var ABounds: TGeoBounds);
    function AddLocalCapsToProjectionBounds(const AEndPoints: array of TGeoVec3;
      const AEndPointCull: array of Integer; const APoint: TGeoVec3; APointCull, APointClip: Integer;
      var AProjectionBounds: TGeoBounds): Boolean;
    function BoundsRayIntersection(const ABounds: TGeoBounds; const AStart, ADir: TGeoVec3;
      out AScale1, AScale2: Single): Boolean;
    procedure ClipFrustumToBox(const ABox: TGeoBox; var AClipFractions: array of Single;
      var AClipPlanes: array of Integer);
    function ClipLine(const ALocalPoints, APoints: TGeoFrustumPoints; AStartIndex, AEndIndex: Integer;
      var AStart, AEnd: TGeoVec3; var AStartClip, AEndClip: Integer): Boolean;
  public
    /// <summary>Origin zero, axis the identity, every distance 0 (not valid)</summary>
    class function Make: TGeoFrustum; static;
    procedure SetOrigin(const AOrigin: TGeoVec3);
    procedure SetAxis(const AAxis: TGeoMat3);
    procedure SetSize(ANear, AFar, ALeft, AUp: Single);
    /// <summary>A frustum whose far plane is a square as large as the far distance</summary>
    procedure SetPyramid(ANear, AFar: Single);
    procedure MoveNearDistance(ANear: Single);
    /// <summary>Moves the far plane and scales the left and up sizes with it</summary>
    procedure MoveFarDistance(AFar: Single);
    /// <summary>The centre of the frustum along the forward axis</summary>
    function GetCenter: TGeoVec3;
    function IsValid: Boolean;
    function Expand(ADelta: Single): TGeoFrustum;
    procedure ExpandSelf(ADelta: Single);
    function Translate(const ATranslation: TGeoVec3): TGeoFrustum;
    procedure TranslateSelf(const ATranslation: TGeoVec3);
    function Rotate(const ARotation: TGeoMat3): TGeoFrustum;
    procedure RotateSelf(const ARotation: TGeoMat3);
    function PlaneDistance(const APlane: TGeoPlane): Single;
    /// <summary>PLANESIDE_FRONT, _BACK or _CROSS</summary>
    function PlaneSide(const APlane: TGeoPlane; AEpsilon: Single = 0.1): Integer;
    // fast culling: may fail to cull everything that is outside
    function CullPoint(const APoint: TGeoVec3): Boolean;
    function CullBounds(const ABounds: TGeoBounds): Boolean;
    function CullBox(const ABox: TGeoBox): Boolean;
    function CullSphere(const ASphere: TGeoSphere): Boolean;
    function CullFrustum(const AFrustum: TGeoFrustum): Boolean;
    function CullWinding(const AWinding: TGeoWinding): Boolean;
    // exact intersection tests
    function ContainsPoint(const APoint: TGeoVec3): Boolean;
    function IntersectsBounds(const ABounds: TGeoBounds): Boolean;
    function IntersectsBox(const ABox: TGeoBox): Boolean;
    function IntersectsSphere(const ASphere: TGeoSphere): Boolean;
    function IntersectsFrustum(const AFrustum: TGeoFrustum): Boolean;
    function IntersectsWinding(const AWinding: TGeoWinding): Boolean;
    /// <summary>True when the segment between start and end meets the frustum</summary>
    function LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
    /// <summary>
    ///   The ray meets the frustum at start + dir * scale1 and start + dir * scale2 in both
    ///   directions; scale1 &lt; 0 when the start is inside
    /// </summary>
    function RayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
    /// <summary>
    ///   Builds the frustum that contains the projection of the volume from the origin; false when
    ///   the origin is too close to the volume
    /// </summary>
    function FromProjection(const ABounds: TGeoBounds; const AProjectionOrigin: TGeoVec3;
      AFar: Single): Boolean; overload;
    function FromProjection(const ABox: TGeoBox; const AProjectionOrigin: TGeoVec3;
      AFar: Single): Boolean; overload;
    function FromProjection(const ASphere: TGeoSphere; const AProjectionOrigin: TGeoVec3;
      AFar: Single): Boolean; overload;
    // moves the far plane so that it extends just beyond the volume
    function ConstrainToBounds(const ABounds: TGeoBounds): Boolean;
    function ConstrainToBox(const ABox: TGeoBox): Boolean;
    function ConstrainToSphere(const ASphere: TGeoSphere): Boolean;
    function ConstrainToFrustum(const AFrustum: TGeoFrustum): Boolean;
    procedure ToPlanes(out APlanes: TGeoFrustumPlanes);
    /// <summary>The eight corners: near plane first, then far plane</summary>
    procedure ToPoints(out APoints: TGeoFrustumPoints);
    procedure AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single); overload;
    procedure AxisProjection(const AAxis: TGeoMat3; out ABounds: TGeoBounds); overload;
    // the bounds of the projection of a volume in this frustum
    function ProjectionBounds(const ABounds: TGeoBounds; out AProjectionBounds: TGeoBounds): Boolean; overload;
    function ProjectionBounds(const ABox: TGeoBox; out AProjectionBounds: TGeoBounds): Boolean; overload;
    function ProjectionBounds(const ASphere: TGeoSphere; out AProjectionBounds: TGeoBounds): Boolean; overload;
    function ProjectionBounds(const AFrustum: TGeoFrustum; out AProjectionBounds: TGeoBounds): Boolean; overload;
    function ProjectionBounds(const AWinding: TGeoWinding; out AProjectionBounds: TGeoBounds): Boolean; overload;
    /// <summary>The projection of the given frustum clipped to the box</summary>
    function ClippedProjectionBounds(const AFrustum: TGeoFrustum; const AClipBox: TGeoBox;
      out AProjectionBounds: TGeoBounds): Boolean;
  end;

  PGeoFrustum = ^TGeoFrustum;

implementation

uses
  System.Math, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath, DelphiDoom.IdLib.Math.Math;

const
  // bit 0 = min x, 1 = max x, 2 = min y, 3 = max y, 4 = min z, 5 = max z
  BOX_VERT_PLANES: array[0..7] of Integer = (
    (1 shl 0) or (1 shl 2) or (1 shl 4),
    (1 shl 1) or (1 shl 2) or (1 shl 4),
    (1 shl 1) or (1 shl 3) or (1 shl 4),
    (1 shl 0) or (1 shl 3) or (1 shl 4),
    (1 shl 0) or (1 shl 2) or (1 shl 5),
    (1 shl 1) or (1 shl 2) or (1 shl 5),
    (1 shl 1) or (1 shl 3) or (1 shl 5),
    (1 shl 0) or (1 shl 3) or (1 shl 5));

  CAP_POINT_INDEX: array[0..3, 0..1] of Integer = ((0, 3), (1, 2), (0, 1), (2, 3));

function SignBitSet(AValue: Single): Integer; inline;
begin
  Result := Integer(TGeoMath.FloatSignBitSet(AValue));
end;

function SignBitNotSet(AValue: Single): Integer; inline;
begin
  Result := Integer(TGeoMath.FloatSignBitNotSet(AValue));
end;

// FLOATNOTZERO: the bits without the sign are not zero (so -0.0 is zero)
function NotZero(AValue: Single): Boolean; inline;
begin
  Result := (PCardinal(@AValue)^ and $7FFFFFFF) <> 0;
end;

procedure SwapPoints(var A, B: TGeoVec3); inline;
var
  LTemp: TGeoVec3;
begin
  LTemp := A;
  A := B;
  B := LTemp;
end;

// idVec3::ToMat3: the vector as forward axis, a perpendicular left and an up axis
function VectorToMat3(const AVector: TGeoVec3): TGeoMat3;
var
  LDist: Single;
begin
  Result.Rows[0] := AVector;
  LDist := AVector.X * AVector.X + AVector.Y * AVector.Y;
  if LDist = 0 then
  begin
    Result.Rows[1].X := 1;
    Result.Rows[1].Y := 0;
    Result.Rows[1].Z := 0;
  end
  else
  begin
    LDist := TGeoMath.InvSqrt(LDist);
    Result.Rows[1].X := -AVector.Y * LDist;
    Result.Rows[1].Y := AVector.X * LDist;
    Result.Rows[1].Z := 0;
  end;
  Result.Rows[2] := AVector.Cross(Result.Rows[1]);
end;

// BoxToPoints of Frustum.cpp: the eight corners of a box
procedure BoxToPoints(const ACenter, AExtents: TGeoVec3; const AAxis: TGeoMat3; out APoints: TGeoFrustumPoints);
var
  LAxisX, LAxisY, LAxisZ: TGeoVec3;
  LTemp: array[0..3] of TGeoVec3;
begin
  LAxisX := AAxis.Rows[0] * AExtents.X;
  LAxisY := AAxis.Rows[1] * AExtents.Y;
  LAxisZ := AAxis.Rows[2] * AExtents.Z;
  LTemp[0] := ACenter - LAxisX;
  LTemp[1] := ACenter + LAxisX;
  LTemp[2] := LAxisY - LAxisZ;
  LTemp[3] := LAxisY + LAxisZ;
  APoints[0] := LTemp[0] - LTemp[3];
  APoints[1] := LTemp[1] - LTemp[3];
  APoints[2] := LTemp[1] + LTemp[2];
  APoints[3] := LTemp[0] + LTemp[2];
  APoints[4] := LTemp[0] - LTemp[2];
  APoints[5] := LTemp[1] - LTemp[2];
  APoints[6] := LTemp[1] + LTemp[3];
  APoints[7] := LTemp[0] + LTemp[3];
end;

{ TGeoFrustum }

class function TGeoFrustum.Make: TGeoFrustum;
begin
  Result.Origin.Zero;
  Result.Axis := TGeoMat3.Identity;
  Result.DNear := 0;
  Result.DFar := 0;
  Result.DLeft := 0;
  Result.DUp := 0;
  Result.InvFar := 0;
end;

procedure TGeoFrustum.SetOrigin(const AOrigin: TGeoVec3);
begin
  Origin := AOrigin;
end;

procedure TGeoFrustum.SetAxis(const AAxis: TGeoMat3);
begin
  Axis := AAxis;
end;

procedure TGeoFrustum.SetSize(ANear, AFar, ALeft, AUp: Single);
begin
  DNear := ANear;
  DFar := AFar;
  DLeft := ALeft;
  DUp := AUp;
  InvFar := 1.0 / AFar;
end;

procedure TGeoFrustum.SetPyramid(ANear, AFar: Single);
begin
  DNear := ANear;
  DFar := AFar;
  DLeft := AFar;
  DUp := AFar;
  InvFar := 1.0 / AFar;
end;

procedure TGeoFrustum.MoveNearDistance(ANear: Single);
begin
  DNear := ANear;
end;

procedure TGeoFrustum.MoveFarDistance(AFar: Single);
var
  LScale: Single;
begin
  LScale := AFar / DFar;
  DFar := AFar;
  DLeft := DLeft * LScale;
  DUp := DUp * LScale;
  InvFar := 1.0 / AFar;
end;

function TGeoFrustum.GetCenter: TGeoVec3;
begin
  Result := Origin + Axis.Rows[0] * ((DFar - DNear) * 0.5);
end;

function TGeoFrustum.IsValid: Boolean;
begin
  Result := DFar > DNear;
end;

function TGeoFrustum.Expand(ADelta: Single): TGeoFrustum;
begin
  Result := Self;
  Result.Origin := Result.Origin - Result.Axis.Rows[0] * ADelta;
  Result.DFar := Result.DFar + 2.0 * ADelta;
  Result.DLeft := Result.DFar * DLeft * InvFar;
  Result.DUp := Result.DFar * DUp * InvFar;
  // the original uses the far distance of the source here, not the expanded one
  Result.InvFar := 1.0 / DFar;
end;

procedure TGeoFrustum.ExpandSelf(ADelta: Single);
begin
  Origin := Origin - Axis.Rows[0] * ADelta;
  DFar := DFar + 2.0 * ADelta;
  DLeft := DFar * DLeft * InvFar;
  DUp := DFar * DUp * InvFar;
  InvFar := 1.0 / DFar;
end;

function TGeoFrustum.Translate(const ATranslation: TGeoVec3): TGeoFrustum;
begin
  Result := Self;
  Result.Origin := Result.Origin + ATranslation;
end;

procedure TGeoFrustum.TranslateSelf(const ATranslation: TGeoVec3);
begin
  Origin := Origin + ATranslation;
end;

function TGeoFrustum.Rotate(const ARotation: TGeoMat3): TGeoFrustum;
begin
  Result := Self;
  Result.Axis := Result.Axis * ARotation;
end;

procedure TGeoFrustum.RotateSelf(const ARotation: TGeoMat3);
begin
  Axis := Axis * ARotation;
end;

function TGeoFrustum.PlaneDistance(const APlane: TGeoPlane): Single;
var
  LMin, LMax: Single;
begin
  AxisProjection(APlane.Normal, LMin, LMax);
  if LMin + APlane.D > 0 then
    Exit(LMin + APlane.D);
  if LMax + APlane.D < 0 then
    Exit(LMax + APlane.D);
  Result := 0;
end;

function TGeoFrustum.PlaneSide(const APlane: TGeoPlane; AEpsilon: Single): Integer;
var
  LMin, LMax: Single;
begin
  AxisProjection(APlane.Normal, LMin, LMax);
  if LMin + APlane.D > AEpsilon then
    Exit(PLANESIDE_FRONT);
  if LMax + APlane.D < AEpsilon then
    Exit(PLANESIDE_BACK);
  Result := PLANESIDE_CROSS;
end;

function TGeoFrustum.CullPoint(const APoint: TGeoVec3): Boolean;
var
  LPoint: TGeoVec3;
  LScale: Single;
begin
  // transform the point to frustum space
  LPoint := (APoint - Origin) * Axis.Transpose;
  // test whether or not the point is within the frustum
  if (LPoint.X < DNear) or (LPoint.X > DFar) then
    Exit(True);
  LScale := LPoint.X * InvFar;
  if TGeoMath.Fabs(LPoint.Y) > DLeft * LScale then
    Exit(True);
  if TGeoMath.Fabs(LPoint.Z) > DUp * LScale then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.CullLocalBox(const ALocalOrigin, AExtents: TGeoVec3; const ALocalAxis: TGeoMat3): Boolean;
var
  LD1, LD2: Single;
  LTestOrigin: TGeoVec3;
  LTestAxis: TGeoMat3;
begin
  // near plane
  LD1 := DNear - ALocalOrigin.X;
  LD2 := TGeoMath.Fabs(AExtents.X * ALocalAxis.Rows[0].X) +
    TGeoMath.Fabs(AExtents.Y * ALocalAxis.Rows[1].X) +
    TGeoMath.Fabs(AExtents.Z * ALocalAxis.Rows[2].X);
  if LD1 - LD2 > 0 then
    Exit(True);
  // far plane
  LD1 := ALocalOrigin.X - DFar;
  if LD1 - LD2 > 0 then
    Exit(True);

  LTestOrigin := ALocalOrigin;
  LTestAxis := ALocalAxis;
  if LTestOrigin.Y < 0 then
  begin
    LTestOrigin.Y := -LTestOrigin.Y;
    LTestAxis.Rows[0].Y := -LTestAxis.Rows[0].Y;
    LTestAxis.Rows[1].Y := -LTestAxis.Rows[1].Y;
    LTestAxis.Rows[2].Y := -LTestAxis.Rows[2].Y;
  end;
  // left and right planes
  LD1 := DFar * LTestOrigin.Y - DLeft * LTestOrigin.X;
  LD2 := TGeoMath.Fabs(AExtents.X * (DFar * LTestAxis.Rows[0].Y - DLeft * LTestAxis.Rows[0].X)) +
    TGeoMath.Fabs(AExtents.Y * (DFar * LTestAxis.Rows[1].Y - DLeft * LTestAxis.Rows[1].X)) +
    TGeoMath.Fabs(AExtents.Z * (DFar * LTestAxis.Rows[2].Y - DLeft * LTestAxis.Rows[2].X));
  if LD1 - LD2 > 0 then
    Exit(True);

  if LTestOrigin.Z < 0 then
  begin
    LTestOrigin.Z := -LTestOrigin.Z;
    LTestAxis.Rows[0].Z := -LTestAxis.Rows[0].Z;
    LTestAxis.Rows[1].Z := -LTestAxis.Rows[1].Z;
    LTestAxis.Rows[2].Z := -LTestAxis.Rows[2].Z;
  end;
  // up and down planes
  LD1 := DFar * LTestOrigin.Z - DUp * LTestOrigin.X;
  LD2 := TGeoMath.Fabs(AExtents.X * (DFar * LTestAxis.Rows[0].Z - DUp * LTestAxis.Rows[0].X)) +
    TGeoMath.Fabs(AExtents.Y * (DFar * LTestAxis.Rows[1].Z - DUp * LTestAxis.Rows[1].X)) +
    TGeoMath.Fabs(AExtents.Z * (DFar * LTestAxis.Rows[2].Z - DUp * LTestAxis.Rows[2].X));
  if LD1 - LD2 > 0 then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.CullBounds(const ABounds: TGeoBounds): Boolean;
var
  LCenter, LExtents, LLocalOrigin: TGeoVec3;
  LLocalAxis: TGeoMat3;
begin
  LCenter := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LExtents := ABounds.Maxs - LCenter;
  // transform the bounds into the space of this frustum
  LLocalOrigin := (LCenter - Origin) * Axis.Transpose;
  LLocalAxis := Axis.Transpose;
  Result := CullLocalBox(LLocalOrigin, LExtents, LLocalAxis);
end;

function TGeoFrustum.CullBox(const ABox: TGeoBox): Boolean;
var
  LLocalOrigin: TGeoVec3;
  LLocalAxis: TGeoMat3;
begin
  LLocalOrigin := (ABox.Center - Origin) * Axis.Transpose;
  LLocalAxis := ABox.Axis * Axis.Transpose;
  Result := CullLocalBox(LLocalOrigin, ABox.Extents, LLocalAxis);
end;

function TGeoFrustum.CullSphere(const ASphere: TGeoSphere): Boolean;
var
  LD, LR, LRadiusSqr, LFarSqr: Single;
  LCenter: TGeoVec3;
begin
  LCenter := (ASphere.Origin - Origin) * Axis.Transpose;
  LR := ASphere.Radius;
  // near plane
  if DNear - LCenter.X > LR then
    Exit(True);
  // far plane
  if LCenter.X - DFar > LR then
    Exit(True);
  LRadiusSqr := LR * LR;
  LFarSqr := DFar * DFar;
  // left and right planes
  LD := DFar * TGeoMath.Fabs(LCenter.Y) - DLeft * LCenter.X;
  if (LD * LD) > LRadiusSqr * (LFarSqr + DLeft * DLeft) then
    Exit(True);
  // up and down planes
  LD := DFar * TGeoMath.Fabs(LCenter.Z) - DUp * LCenter.X;
  if (LD * LD) > LRadiusSqr * (LFarSqr + DUp * DUp) then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.CullLocalFrustum(const ALocalFrustum: TGeoFrustum; const AIndexPoints: TGeoFrustumPoints;
  const ACornerVecs: TGeoFrustumCorners): Boolean;
var
  LIndex: Integer;
  LDx, LDy, LDz, LLeftScale, LUpScale: Single;
begin
  // near plane
  LDy := -ALocalFrustum.Axis.Rows[1].X;
  LDz := -ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := -ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].X < DNear then
    Exit(True);
  // far plane
  LDy := ALocalFrustum.Axis.Rows[1].X;
  LDz := ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].X > DFar then
    Exit(True);

  LLeftScale := DLeft * InvFar;
  // left plane
  LDy := DFar * ALocalFrustum.Axis.Rows[1].Y - DLeft * ALocalFrustum.Axis.Rows[1].X;
  LDz := DFar * ALocalFrustum.Axis.Rows[2].Y - DLeft * ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := DFar * ACornerVecs[LIndex].Y - DLeft * ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Y > AIndexPoints[LIndex].X * LLeftScale then
    Exit(True);
  // right plane
  LDy := -DFar * ALocalFrustum.Axis.Rows[1].Y - DLeft * ALocalFrustum.Axis.Rows[1].X;
  LDz := -DFar * ALocalFrustum.Axis.Rows[2].Y - DLeft * ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := -DFar * ACornerVecs[LIndex].Y - DLeft * ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Y < -AIndexPoints[LIndex].X * LLeftScale then
    Exit(True);

  LUpScale := DUp * InvFar;
  // up plane
  LDy := DFar * ALocalFrustum.Axis.Rows[1].Z - DUp * ALocalFrustum.Axis.Rows[1].X;
  LDz := DFar * ALocalFrustum.Axis.Rows[2].Z - DUp * ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := DFar * ACornerVecs[LIndex].Z - DUp * ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Z > AIndexPoints[LIndex].X * LUpScale then
    Exit(True);
  // down plane
  LDy := -DFar * ALocalFrustum.Axis.Rows[1].Z - DUp * ALocalFrustum.Axis.Rows[1].X;
  LDz := -DFar * ALocalFrustum.Axis.Rows[2].Z - DUp * ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := -DFar * ACornerVecs[LIndex].Z - DUp * ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Z < -AIndexPoints[LIndex].X * LUpScale then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.CullFrustum(const AFrustum: TGeoFrustum): Boolean;
var
  LLocalFrustum: TGeoFrustum;
  LIndexPoints: TGeoFrustumPoints;
  LCornerVecs: TGeoFrustumCorners;
begin
  // transform the given frustum into the space of this frustum
  LLocalFrustum := AFrustum;
  LLocalFrustum.Origin := (AFrustum.Origin - Origin) * Axis.Transpose;
  LLocalFrustum.Axis := AFrustum.Axis * Axis.Transpose;
  LLocalFrustum.ToIndexPointsAndCornerVecs(LIndexPoints, LCornerVecs);
  Result := CullLocalFrustum(LLocalFrustum, LIndexPoints, LCornerVecs);
end;

function TGeoFrustum.CullLocalWinding(const APoints: TArray<TGeoVec3>; var APointCull: TArray<Integer>): Boolean;
var
  LIndex, LPointCull, LCulled: Integer;
  LLeftScale, LUpScale: Single;
begin
  LLeftScale := DLeft * InvFar;
  LUpScale := DUp * InvFar;
  LCulled := -1;
  for LIndex := 0 to Length(APoints) - 1 do
  begin
    LPointCull := 0;
    if APoints[LIndex].X < DNear then
      LPointCull := 1
    else if APoints[LIndex].X > DFar then
      LPointCull := 2;
    if TGeoMath.Fabs(APoints[LIndex].Y) > APoints[LIndex].X * LLeftScale then
      LPointCull := LPointCull or (4 shl SignBitSet(APoints[LIndex].Y));
    if TGeoMath.Fabs(APoints[LIndex].Z) > APoints[LIndex].X * LUpScale then
      LPointCull := LPointCull or (16 shl SignBitSet(APoints[LIndex].Z));
    LCulled := LCulled and LPointCull;
    APointCull[LIndex] := LPointCull;
  end;
  Result := LCulled <> 0;
end;

function TGeoFrustum.CullWinding(const AWinding: TGeoWinding): Boolean;
var
  LIndex: Integer;
  LLocalPoints: TArray<TGeoVec3>;
  LPointCull: TArray<Integer>;
  LTranspose: TGeoMat3;
begin
  SetLength(LLocalPoints, AWinding.NumPoints);
  SetLength(LPointCull, AWinding.NumPoints);
  LTranspose := Axis.Transpose;
  for LIndex := 0 to AWinding.NumPoints - 1 do
    LLocalPoints[LIndex] := (AWinding[LIndex] - Origin) * LTranspose;
  Result := CullLocalWinding(LLocalPoints, LPointCull);
end;

function TGeoFrustum.BoundsCullLocalFrustum(const ABounds: TGeoBounds; const ALocalFrustum: TGeoFrustum;
  const AIndexPoints: TGeoFrustumPoints; const ACornerVecs: TGeoFrustumCorners): Boolean;
var
  LIndex: Integer;
  LDx, LDy, LDz: Single;
begin
  LDy := -ALocalFrustum.Axis.Rows[1].X;
  LDz := -ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := -ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].X < ABounds.Mins.X then
    Exit(True);

  LDy := ALocalFrustum.Axis.Rows[1].X;
  LDz := ALocalFrustum.Axis.Rows[2].X;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := ACornerVecs[LIndex].X;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].X > ABounds.Maxs.X then
    Exit(True);

  LDy := -ALocalFrustum.Axis.Rows[1].Y;
  LDz := -ALocalFrustum.Axis.Rows[2].Y;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := -ACornerVecs[LIndex].Y;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Y < ABounds.Mins.Y then
    Exit(True);

  LDy := ALocalFrustum.Axis.Rows[1].Y;
  LDz := ALocalFrustum.Axis.Rows[2].Y;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := ACornerVecs[LIndex].Y;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Y > ABounds.Maxs.Y then
    Exit(True);

  LDy := -ALocalFrustum.Axis.Rows[1].Z;
  LDz := -ALocalFrustum.Axis.Rows[2].Z;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := -ACornerVecs[LIndex].Z;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Z < ABounds.Mins.Z then
    Exit(True);

  LDy := ALocalFrustum.Axis.Rows[1].Z;
  LDz := ALocalFrustum.Axis.Rows[2].Z;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := ACornerVecs[LIndex].Z;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  if AIndexPoints[LIndex].Z > ABounds.Maxs.Z then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.LocalLineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
var
  LDir: TGeoVec3;
  LD1, LD2, LFStart, LFEnd, LLStart, LLEnd, LF, LX: Single;
  LLeftScale, LUpScale: Single;
  LStartInside: Integer;
begin
  LStartInside := 1;
  LLeftScale := DLeft * InvFar;
  LUpScale := DUp * InvFar;
  LDir := AEnd - AStart;

  // near plane
  if DNear > 0 then
  begin
    LD1 := DNear - AStart.X;
    LStartInside := LStartInside and SignBitSet(LD1);
    if NotZero(LD1) then
    begin
      LD2 := DNear - AEnd.X;
      if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
      begin
        LF := LD1 / (LD1 - LD2);
        if TGeoMath.Fabs(AStart.Y + LF * LDir.Y) <= DNear * LLeftScale then
          if TGeoMath.Fabs(AStart.Z + LF * LDir.Z) <= DNear * LUpScale then
            Exit(True);
      end;
    end;
  end;

  // far plane
  LD1 := AStart.X - DFar;
  LStartInside := LStartInside and SignBitSet(LD1);
  if NotZero(LD1) then
  begin
    LD2 := AEnd.X - DFar;
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      if TGeoMath.Fabs(AStart.Y + LF * LDir.Y) <= DFar * LLeftScale then
        if TGeoMath.Fabs(AStart.Z + LF * LDir.Z) <= DFar * LUpScale then
          Exit(True);
    end;
  end;

  LFStart := DFar * AStart.Y;
  LFEnd := DFar * AEnd.Y;
  LLStart := DLeft * AStart.X;
  LLEnd := DLeft * AEnd.X;

  // left plane
  LD1 := LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  if NotZero(LD1) then
  begin
    LD2 := LFEnd - LLEnd;
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := AStart.X + LF * LDir.X;
      if (LX >= DNear) and (LX <= DFar) then
        if TGeoMath.Fabs(AStart.Z + LF * LDir.Z) <= LX * LUpScale then
          Exit(True);
    end;
  end;

  // right plane
  LD1 := -LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  if NotZero(LD1) then
  begin
    LD2 := -LFEnd - LLEnd;
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := AStart.X + LF * LDir.X;
      if (LX >= DNear) and (LX <= DFar) then
        if TGeoMath.Fabs(AStart.Z + LF * LDir.Z) <= LX * LUpScale then
          Exit(True);
    end;
  end;

  LFStart := DFar * AStart.Z;
  LFEnd := DFar * AEnd.Z;
  LLStart := DUp * AStart.X;
  LLEnd := DUp * AEnd.X;

  // up plane
  LD1 := LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  if NotZero(LD1) then
  begin
    LD2 := LFEnd - LLEnd;
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := AStart.X + LF * LDir.X;
      if (LX >= DNear) and (LX <= DFar) then
        if TGeoMath.Fabs(AStart.Y + LF * LDir.Y) <= LX * LLeftScale then
          Exit(True);
    end;
  end;

  // down plane
  LD1 := -LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  if NotZero(LD1) then
  begin
    LD2 := -LFEnd - LLEnd;
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := AStart.X + LF * LDir.X;
      if (LX >= DNear) and (LX <= DFar) then
        if TGeoMath.Fabs(AStart.Y + LF * LDir.Y) <= LX * LLeftScale then
          Exit(True);
    end;
  end;
  Result := LStartInside <> 0;
end;

function TGeoFrustum.LocalRayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
var
  LEnd: TGeoVec3;
  LD1, LD2, LFStart, LFEnd, LLStart, LLEnd, LF, LX: Single;
  LLeftScale, LUpScale: Single;
  LStartInside: Integer;
begin
  LStartInside := 1;
  LLeftScale := DLeft * InvFar;
  LUpScale := DUp * InvFar;
  LEnd := AStart + ADir;
  AScale1 := GEO_INFINITY;
  AScale2 := -GEO_INFINITY;

  // near plane
  if DNear > 0 then
  begin
    LD1 := DNear - AStart.X;
    LStartInside := LStartInside and SignBitSet(LD1);
    LD2 := DNear - LEnd.X;
    if LD1 <> LD2 then
    begin
      LF := LD1 / (LD1 - LD2);
      if TGeoMath.Fabs(AStart.Y + LF * ADir.Y) <= DNear * LLeftScale then
        if TGeoMath.Fabs(AStart.Z + LF * ADir.Z) <= DNear * LUpScale then
        begin
          if LF < AScale1 then
            AScale1 := LF;
          if LF > AScale2 then
            AScale2 := LF;
        end;
    end;
  end;

  // far plane
  LD1 := AStart.X - DFar;
  LStartInside := LStartInside and SignBitSet(LD1);
  LD2 := LEnd.X - DFar;
  if LD1 <> LD2 then
  begin
    LF := LD1 / (LD1 - LD2);
    if TGeoMath.Fabs(AStart.Y + LF * ADir.Y) <= DFar * LLeftScale then
      if TGeoMath.Fabs(AStart.Z + LF * ADir.Z) <= DFar * LUpScale then
      begin
        if LF < AScale1 then
          AScale1 := LF;
        if LF > AScale2 then
          AScale2 := LF;
      end;
  end;

  LFStart := DFar * AStart.Y;
  LFEnd := DFar * LEnd.Y;
  LLStart := DLeft * AStart.X;
  LLEnd := DLeft * LEnd.X;

  // left plane
  LD1 := LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  LD2 := LFEnd - LLEnd;
  if LD1 <> LD2 then
  begin
    LF := LD1 / (LD1 - LD2);
    LX := AStart.X + LF * ADir.X;
    if (LX >= DNear) and (LX <= DFar) then
      if TGeoMath.Fabs(AStart.Z + LF * ADir.Z) <= LX * LUpScale then
      begin
        if LF < AScale1 then
          AScale1 := LF;
        if LF > AScale2 then
          AScale2 := LF;
      end;
  end;

  // right plane
  LD1 := -LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  LD2 := -LFEnd - LLEnd;
  if LD1 <> LD2 then
  begin
    LF := LD1 / (LD1 - LD2);
    LX := AStart.X + LF * ADir.X;
    if (LX >= DNear) and (LX <= DFar) then
      if TGeoMath.Fabs(AStart.Z + LF * ADir.Z) <= LX * LUpScale then
      begin
        if LF < AScale1 then
          AScale1 := LF;
        if LF > AScale2 then
          AScale2 := LF;
      end;
  end;

  LFStart := DFar * AStart.Z;
  LFEnd := DFar * LEnd.Z;
  LLStart := DUp * AStart.X;
  LLEnd := DUp * LEnd.X;

  // up plane
  LD1 := LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  LD2 := LFEnd - LLEnd;
  if LD1 <> LD2 then
  begin
    LF := LD1 / (LD1 - LD2);
    LX := AStart.X + LF * ADir.X;
    if (LX >= DNear) and (LX <= DFar) then
      if TGeoMath.Fabs(AStart.Y + LF * ADir.Y) <= LX * LLeftScale then
      begin
        if LF < AScale1 then
          AScale1 := LF;
        if LF > AScale2 then
          AScale2 := LF;
      end;
  end;

  // down plane
  LD1 := -LFStart - LLStart;
  LStartInside := LStartInside and SignBitSet(LD1);
  LD2 := -LFEnd - LLEnd;
  if LD1 <> LD2 then
  begin
    LF := LD1 / (LD1 - LD2);
    LX := AStart.X + LF * ADir.X;
    if (LX >= DNear) and (LX <= DFar) then
      if TGeoMath.Fabs(AStart.Y + LF * ADir.Y) <= LX * LLeftScale then
      begin
        if LF < AScale1 then
          AScale1 := LF;
        if LF > AScale2 then
          AScale2 := LF;
      end;
  end;
  Result := LStartInside <> 0;
end;

function TGeoFrustum.ContainsPoint(const APoint: TGeoVec3): Boolean;
begin
  Result := not CullPoint(APoint);
end;

function TGeoFrustum.LocalFrustumIntersectsFrustum(const APoints: TGeoFrustumPoints;
  ATestFirstSide: Boolean): Boolean;
var
  LIndex: Integer;
begin
  // test if any edges of the other frustum intersect this frustum
  for LIndex := 0 to 3 do
    if LocalLineIntersection(APoints[LIndex], APoints[4 + LIndex]) then
      Exit(True);
  if ATestFirstSide then
    for LIndex := 0 to 3 do
      if LocalLineIntersection(APoints[LIndex], APoints[(LIndex + 1) and 3]) then
        Exit(True);
  for LIndex := 0 to 3 do
    if LocalLineIntersection(APoints[4 + LIndex], APoints[4 + ((LIndex + 1) and 3)]) then
      Exit(True);
  Result := False;
end;

function TGeoFrustum.LocalFrustumIntersectsBounds(const APoints: TGeoFrustumPoints;
  const ABounds: TGeoBounds): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 3 do
    if ABounds.LineIntersection(APoints[LIndex], APoints[4 + LIndex]) then
      Exit(True);
  if DNear > 0 then
    for LIndex := 0 to 3 do
      if ABounds.LineIntersection(APoints[LIndex], APoints[(LIndex + 1) and 3]) then
        Exit(True);
  for LIndex := 0 to 3 do
    if ABounds.LineIntersection(APoints[4 + LIndex], APoints[4 + ((LIndex + 1) and 3)]) then
      Exit(True);
  Result := False;
end;

function TGeoFrustum.IntersectsBounds(const ABounds: TGeoBounds): Boolean;
var
  LCenter, LExtents, LLocalOrigin: TGeoVec3;
  LLocalAxis: TGeoMat3;
  LIndexPoints: TGeoFrustumPoints;
  LCornerVecs: TGeoFrustumCorners;
begin
  LCenter := (ABounds.Mins + ABounds.Maxs) * 0.5;
  LExtents := ABounds.Maxs - LCenter;
  LLocalOrigin := (LCenter - Origin) * Axis.Transpose;
  LLocalAxis := Axis.Transpose;
  if CullLocalBox(LLocalOrigin, LExtents, LLocalAxis) then
    Exit(False);

  ToIndexPointsAndCornerVecs(LIndexPoints, LCornerVecs);
  if BoundsCullLocalFrustum(ABounds, Self, LIndexPoints, LCornerVecs) then
    Exit(False);

  SwapPoints(LIndexPoints[2], LIndexPoints[3]);
  SwapPoints(LIndexPoints[6], LIndexPoints[7]);
  if LocalFrustumIntersectsBounds(LIndexPoints, ABounds) then
    Exit(True);

  BoxToPoints(LLocalOrigin, LExtents, LLocalAxis, LIndexPoints);
  if LocalFrustumIntersectsFrustum(LIndexPoints, True) then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.IntersectsBox(const ABox: TGeoBox): Boolean;
var
  LLocalOrigin: TGeoVec3;
  LLocalAxis: TGeoMat3;
  LIndexPoints: TGeoFrustumPoints;
  LCornerVecs: TGeoFrustumCorners;
  LLocalFrustum: TGeoFrustum;
  LBoxBounds: TGeoBounds;
begin
  LLocalOrigin := (ABox.Center - Origin) * Axis.Transpose;
  LLocalAxis := ABox.Axis * Axis.Transpose;
  if CullLocalBox(LLocalOrigin, ABox.Extents, LLocalAxis) then
    Exit(False);

  LLocalFrustum := Self;
  LLocalFrustum.Origin := (Origin - ABox.Center) * ABox.Axis.Transpose;
  LLocalFrustum.Axis := Axis * ABox.Axis.Transpose;
  LLocalFrustum.ToIndexPointsAndCornerVecs(LIndexPoints, LCornerVecs);
  LBoxBounds := TGeoBounds.Make(-ABox.Extents, ABox.Extents);
  if BoundsCullLocalFrustum(LBoxBounds, LLocalFrustum, LIndexPoints, LCornerVecs) then
    Exit(False);

  SwapPoints(LIndexPoints[2], LIndexPoints[3]);
  SwapPoints(LIndexPoints[6], LIndexPoints[7]);
  if LocalFrustumIntersectsBounds(LIndexPoints, LBoxBounds) then
    Exit(True);

  BoxToPoints(LLocalOrigin, ABox.Extents, LLocalAxis, LIndexPoints);
  if LocalFrustumIntersectsFrustum(LIndexPoints, True) then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.IntersectsSphere(const ASphere: TGeoSphere): Boolean;
var
  LIndex, LX, LY, LZ: Integer;
  LScale, LR, LD: Single;
  LP, LDir: TGeoVec3;
  LPoints: TGeoFrustumPoints;
begin
  if CullSphere(ASphere) then
    Exit(False);

  LX := 0;
  LY := 0;
  LZ := 0;
  LDir.Zero;
  LP := (ASphere.Origin - Origin) * Axis.Transpose;

  if LP.X <= DNear then
  begin
    LScale := DNear * InvFar;
    LDir.Y := TGeoMath.Fabs(LP.Y) - DLeft * LScale;
    LDir.Z := TGeoMath.Fabs(LP.Z) - DUp * LScale;
  end
  else if LP.X >= DFar then
  begin
    LDir.Y := TGeoMath.Fabs(LP.Y) - DLeft;
    LDir.Z := TGeoMath.Fabs(LP.Z) - DUp;
  end
  else
  begin
    LScale := LP.X * InvFar;
    LDir.Y := TGeoMath.Fabs(LP.Y) - DLeft * LScale;
    LDir.Z := TGeoMath.Fabs(LP.Z) - DUp * LScale;
  end;

  if LDir.Y > 0 then
    LY := 1 + SignBitNotSet(LP.Y);
  if LDir.Z > 0 then
    LZ := 1 + SignBitNotSet(LP.Z);

  if LP.X < DNear then
  begin
    LScale := DLeft * DNear * InvFar;
    if LP.X < DNear + (LScale - LP.Y) * LScale * InvFar then
    begin
      LScale := DUp * DNear * InvFar;
      if LP.X < DNear + (LScale - LP.Z) * LScale * InvFar then
        LX := 1;
    end;
  end
  else
  begin
    if LP.X > DFar then
      LX := 2
    else if LP.X > DFar + (DLeft - LP.Y) * DLeft * InvFar then
      LX := 2
    else if LP.X > DFar + (DUp - LP.Z) * DUp * InvFar then
      LX := 2;
  end;

  LR := ASphere.Radius;
  // the Voronoi region: x + y * 3 + z * 9
  LIndex := LX + LY * 3 + LZ * 9;
  case LIndex of
    0: Exit(True);
    1: Exit(DNear - LP.X < LR);
    2: Exit(LP.X - DFar < LR);
    3:
      begin
        LD := DFar * LP.Y - DLeft * LP.X;
        Exit(LD * LD < LR * LR * (DFar * DFar + DLeft * DLeft));
      end;
    6:
      begin
        // the original uses z where the left plane needs y: kept
        LD := -DFar * LP.Z - DLeft * LP.X;
        Exit(LD * LD < LR * LR * (DFar * DFar + DLeft * DLeft));
      end;
    9:
      begin
        LD := DFar * LP.Z - DUp * LP.X;
        Exit(LD * LD < LR * LR * (DFar * DFar + DUp * DUp));
      end;
    18:
      begin
        LD := -DFar * LP.Z - DUp * LP.X;
        Exit(LD * LD < LR * LR * (DFar * DFar + DUp * DUp));
      end;
  else
    ToIndexPoints(LPoints);
    case LIndex of
      13: Exit(ASphere.ContainsPoint(LPoints[0]));
      14: Exit(ASphere.ContainsPoint(LPoints[4]));
      16: Exit(ASphere.ContainsPoint(LPoints[1]));
      17: Exit(ASphere.ContainsPoint(LPoints[5]));
      22: Exit(ASphere.ContainsPoint(LPoints[2]));
      23: Exit(ASphere.ContainsPoint(LPoints[6]));
      25: Exit(ASphere.ContainsPoint(LPoints[3]));
      26: Exit(ASphere.ContainsPoint(LPoints[7]));
      4: Exit(ASphere.LineIntersection(LPoints[0], LPoints[2]));
      5: Exit(ASphere.LineIntersection(LPoints[4], LPoints[6]));
      7: Exit(ASphere.LineIntersection(LPoints[1], LPoints[3]));
      8: Exit(ASphere.LineIntersection(LPoints[5], LPoints[7]));
      10: Exit(ASphere.LineIntersection(LPoints[0], LPoints[1]));
      11: Exit(ASphere.LineIntersection(LPoints[4], LPoints[5]));
      12: Exit(ASphere.LineIntersection(LPoints[0], LPoints[4]));
      15: Exit(ASphere.LineIntersection(LPoints[1], LPoints[5]));
      19: Exit(ASphere.LineIntersection(LPoints[2], LPoints[3]));
      20: Exit(ASphere.LineIntersection(LPoints[6], LPoints[7]));
      21: Exit(ASphere.LineIntersection(LPoints[2], LPoints[6]));
      24: Exit(ASphere.LineIntersection(LPoints[3], LPoints[7]));
    end;
  end;
  Result := False;
end;

function TGeoFrustum.IntersectsFrustum(const AFrustum: TGeoFrustum): Boolean;
var
  LIndexPoints1, LIndexPoints2: TGeoFrustumPoints;
  LCornerVecs1, LCornerVecs2: TGeoFrustumCorners;
  LLocalFrustum1, LLocalFrustum2: TGeoFrustum;
begin
  LLocalFrustum2 := AFrustum;
  LLocalFrustum2.Origin := (AFrustum.Origin - Origin) * Axis.Transpose;
  LLocalFrustum2.Axis := AFrustum.Axis * Axis.Transpose;
  LLocalFrustum2.ToIndexPointsAndCornerVecs(LIndexPoints2, LCornerVecs2);
  if CullLocalFrustum(LLocalFrustum2, LIndexPoints2, LCornerVecs2) then
    Exit(False);

  LLocalFrustum1 := Self;
  LLocalFrustum1.Origin := (Origin - AFrustum.Origin) * AFrustum.Axis.Transpose;
  LLocalFrustum1.Axis := Axis * AFrustum.Axis.Transpose;
  LLocalFrustum1.ToIndexPointsAndCornerVecs(LIndexPoints1, LCornerVecs1);
  if AFrustum.CullLocalFrustum(LLocalFrustum1, LIndexPoints1, LCornerVecs1) then
    Exit(False);

  SwapPoints(LIndexPoints2[2], LIndexPoints2[3]);
  SwapPoints(LIndexPoints2[6], LIndexPoints2[7]);
  if LocalFrustumIntersectsFrustum(LIndexPoints2, LLocalFrustum2.DNear > 0) then
    Exit(True);

  SwapPoints(LIndexPoints1[2], LIndexPoints1[3]);
  SwapPoints(LIndexPoints1[6], LIndexPoints1[7]);
  if AFrustum.LocalFrustumIntersectsFrustum(LIndexPoints1, LLocalFrustum1.DNear > 0) then
    Exit(True);
  Result := False;
end;

function TGeoFrustum.IntersectsWinding(const AWinding: TGeoWinding): Boolean;
var
  LIndex, LNext: Integer;
  LMin, LMax: Single;
  LLocalPoints: TArray<TGeoVec3>;
  LPointCull: TArray<Integer>;
  LIndexPoints: TGeoFrustumPoints;
  LCornerVecs: TGeoFrustumCorners;
  LTranspose: TGeoMat3;
  LPlane: TGeoPlane;
begin
  SetLength(LLocalPoints, AWinding.NumPoints);
  SetLength(LPointCull, AWinding.NumPoints);
  LTranspose := Axis.Transpose;
  for LIndex := 0 to AWinding.NumPoints - 1 do
    LLocalPoints[LIndex] := (AWinding[LIndex] - Origin) * LTranspose;

  // if the winding is culled
  if CullLocalWinding(LLocalPoints, LPointCull) then
    Exit(False);

  AWinding.GetPlane(LPlane);
  ToIndexPointsAndCornerVecs(LIndexPoints, LCornerVecs);
  AxisProjection(LIndexPoints, LCornerVecs, LPlane.Normal, LMin, LMax);

  // if the frustum does not cross the winding plane
  if (LMin + LPlane.D > 0) or (LMax + LPlane.D < 0) then
    Exit(False);

  // test if any of the winding edges goes through the frustum
  for LIndex := 0 to AWinding.NumPoints - 1 do
  begin
    LNext := (LIndex + 1) mod AWinding.NumPoints;
    if (LPointCull[LIndex] and LPointCull[LNext]) = 0 then
      if LocalLineIntersection(LLocalPoints[LIndex], LLocalPoints[LNext]) then
        Exit(True);
  end;

  SwapPoints(LIndexPoints[2], LIndexPoints[3]);
  SwapPoints(LIndexPoints[6], LIndexPoints[7]);

  // test if any edges of the frustum intersect the winding
  for LIndex := 0 to 3 do
    if AWinding.LineIntersection(LPlane, LIndexPoints[LIndex], LIndexPoints[4 + LIndex]) then
      Exit(True);
  if DNear > 0 then
    for LIndex := 0 to 3 do
      if AWinding.LineIntersection(LPlane, LIndexPoints[LIndex], LIndexPoints[(LIndex + 1) and 3]) then
        Exit(True);
  for LIndex := 0 to 3 do
    if AWinding.LineIntersection(LPlane, LIndexPoints[4 + LIndex], LIndexPoints[4 + ((LIndex + 1) and 3)]) then
      Exit(True);
  Result := False;
end;

function TGeoFrustum.LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
begin
  Result := LocalLineIntersection((AStart - Origin) * Axis.Transpose, (AEnd - Origin) * Axis.Transpose);
end;

function TGeoFrustum.RayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
begin
  if LocalRayIntersection((AStart - Origin) * Axis.Transpose, ADir * Axis.Transpose, AScale1, AScale2) then
    Exit(True);
  Result := AScale1 <= AScale2;
end;

function TGeoFrustum.FromProjection(const ABounds: TGeoBounds; const AProjectionOrigin: TGeoVec3;
  AFar: Single): Boolean;
begin
  Result := FromProjection(TGeoBox.Make(ABounds, TGeoVec3.Origin, TGeoMat3.Identity), AProjectionOrigin, AFar);
end;

function TGeoFrustum.FromProjection(const ABox: TGeoBox; const AProjectionOrigin: TGeoVec3;
  AFar: Single): Boolean;
var
  LIndex, LBestAxis, LPass, LMinX, LMinY, LMaxY, LMinZ, LMaxZ: Integer;
  LValue, LBestValue: Single;
  LDir: TGeoVec3;
  LPoints: TGeoFrustumPoints;
begin
  DNear := 0;
  DFar := 0;
  InvFar := 0;

  LDir := ABox.Center - AProjectionOrigin;
  if LDir.NormalizeSelf = 0 then
    Exit(False);

  LBestAxis := 0;
  LBestValue := TGeoMath.Fabs(ABox.Axis.Rows[0].Dot(LDir));
  for LIndex := 1 to 2 do
  begin
    LValue := TGeoMath.Fabs(ABox.Axis.Rows[LIndex].Dot(LDir));
    if LValue * ABox.Extents[LBestAxis] * ABox.Extents[LBestAxis] <
      LBestValue * ABox.Extents[LIndex] * ABox.Extents[LIndex] then
    begin
      LBestValue := LValue;
      LBestAxis := LIndex;
    end;
  end;

  for LPass := 0 to 1 do
  begin
    Axis.Rows[0] := LDir;
    Axis.Rows[1] := ABox.Axis.Rows[LBestAxis] - Axis.Rows[0] * ABox.Axis.Rows[LBestAxis].Dot(Axis.Rows[0]);
    Axis.Rows[1].NormalizeSelf;
    Axis.Rows[2] := Axis.Rows[0].Cross(Axis.Rows[1]);
    BoxToPoints((ABox.Center - AProjectionOrigin) * Axis.Transpose, ABox.Extents,
      ABox.Axis * Axis.Transpose, LPoints);
    if LPoints[0].X <= 1.0 then
      Exit(False);
    LMinX := 0;
    LMinY := 0;
    LMaxY := 0;
    LMinZ := 0;
    LMaxZ := 0;
    for LIndex := 1 to 7 do
    begin
      if LPoints[LIndex].X <= 1.0 then
        Exit(False);
      if LPoints[LIndex].X < LPoints[LMinX].X then
        LMinX := LIndex;
      if LPoints[LMinY].X * LPoints[LIndex].Y < LPoints[LIndex].X * LPoints[LMinY].Y then
        LMinY := LIndex
      else if LPoints[LMaxY].X * LPoints[LIndex].Y > LPoints[LIndex].X * LPoints[LMaxY].Y then
        LMaxY := LIndex;
      if LPoints[LMinZ].X * LPoints[LIndex].Z < LPoints[LIndex].X * LPoints[LMinZ].Z then
        LMinZ := LIndex
      else if LPoints[LMaxZ].X * LPoints[LIndex].Z > LPoints[LIndex].X * LPoints[LMaxZ].Z then
        LMaxZ := LIndex;
    end;
    if LPass = 0 then
    begin
      LDir := LDir + Axis.Rows[1] * TIdMath.Tan16(0.5 *
        (TIdMath.ATan16(LPoints[LMinY].Y, LPoints[LMinY].X) + TIdMath.ATan16(LPoints[LMaxY].Y, LPoints[LMaxY].X)));
      LDir := LDir + Axis.Rows[2] * TIdMath.Tan16(0.5 *
        (TIdMath.ATan16(LPoints[LMinZ].Z, LPoints[LMinZ].X) + TIdMath.ATan16(LPoints[LMaxZ].Z, LPoints[LMaxZ].X)));
      LDir.NormalizeSelf;
    end;
  end;

  Origin := AProjectionOrigin;
  DNear := LPoints[LMinX].X;
  DFar := AFar;
  DLeft := Max(TGeoMath.Fabs(LPoints[LMinY].Y / LPoints[LMinY].X),
    TGeoMath.Fabs(LPoints[LMaxY].Y / LPoints[LMaxY].X)) * AFar;
  DUp := Max(TGeoMath.Fabs(LPoints[LMinZ].Z / LPoints[LMinZ].X),
    TGeoMath.Fabs(LPoints[LMaxZ].Z / LPoints[LMaxZ].X)) * AFar;
  InvFar := 1.0 / AFar;
  Result := True;
end;

function TGeoFrustum.FromProjection(const ASphere: TGeoSphere; const AProjectionOrigin: TGeoVec3;
  AFar: Single): Boolean;
var
  LDir: TGeoVec3;
  LD, LR, LS, LX, LY: Single;
begin
  LDir := ASphere.Origin - AProjectionOrigin;
  LD := LDir.NormalizeSelf;
  LR := ASphere.Radius;
  if LD <= LR + 1.0 then
  begin
    DNear := 0;
    DFar := 0;
    InvFar := 0;
    Exit(False);
  end;

  Origin := AProjectionOrigin;
  Axis := VectorToMat3(LDir);
  LS := TIdMath.Sqrt(LD * LD - LR * LR);
  LX := LR / LD * LS;
  LY := TIdMath.Sqrt(LS * LS - LX * LX);

  DNear := LD - LR;
  DFar := AFar;
  DLeft := LX / LY * AFar;
  DUp := DLeft;
  InvFar := 1.0 / AFar;
  Result := True;
end;

function TGeoFrustum.ConstrainToBounds(const ABounds: TGeoBounds): Boolean;
var
  LMin, LMax, LNewFar: Single;
begin
  ABounds.AxisProjection(Axis.Rows[0], LMin, LMax);
  LNewFar := LMax - Axis.Rows[0].Dot(Origin);
  if LNewFar <= DNear then
  begin
    MoveFarDistance(DNear + 1.0);
    Exit(False);
  end;
  MoveFarDistance(LNewFar);
  Result := True;
end;

function TGeoFrustum.ConstrainToBox(const ABox: TGeoBox): Boolean;
var
  LMin, LMax, LNewFar: Single;
begin
  ABox.AxisProjection(Axis.Rows[0], LMin, LMax);
  LNewFar := LMax - Axis.Rows[0].Dot(Origin);
  if LNewFar <= DNear then
  begin
    MoveFarDistance(DNear + 1.0);
    Exit(False);
  end;
  MoveFarDistance(LNewFar);
  Result := True;
end;

function TGeoFrustum.ConstrainToSphere(const ASphere: TGeoSphere): Boolean;
var
  LMin, LMax, LNewFar: Single;
begin
  ASphere.AxisProjection(Axis.Rows[0], LMin, LMax);
  LNewFar := LMax - Axis.Rows[0].Dot(Origin);
  if LNewFar <= DNear then
  begin
    MoveFarDistance(DNear + 1.0);
    Exit(False);
  end;
  MoveFarDistance(LNewFar);
  Result := True;
end;

function TGeoFrustum.ConstrainToFrustum(const AFrustum: TGeoFrustum): Boolean;
var
  LMin, LMax, LNewFar: Single;
begin
  AFrustum.AxisProjection(Axis.Rows[0], LMin, LMax);
  LNewFar := LMax - Axis.Rows[0].Dot(Origin);
  if LNewFar <= DNear then
  begin
    MoveFarDistance(DNear + 1.0);
    Exit(False);
  end;
  MoveFarDistance(LNewFar);
  Result := True;
end;

procedure TGeoFrustum.ToPlanes(out APlanes: TGeoFrustumPlanes);
var
  LIndex: Integer;
  LScaled: array[0..1] of TGeoVec3;
  LPoints: array[0..3] of TGeoVec3;
begin
  APlanes[0].Zero;
  APlanes[0].SetNormal(-Axis.Rows[0]);
  APlanes[0].SetDist(-DNear);
  APlanes[1].Zero;
  APlanes[1].SetNormal(Axis.Rows[0]);
  APlanes[1].SetDist(DFar);

  LScaled[0] := Axis.Rows[1] * DLeft;
  LScaled[1] := Axis.Rows[2] * DUp;
  LPoints[0] := LScaled[0] + LScaled[1];
  LPoints[1] := -LScaled[0] + LScaled[1];
  LPoints[2] := -LScaled[0] - LScaled[1];
  LPoints[3] := LScaled[0] - LScaled[1];

  for LIndex := 0 to 3 do
  begin
    APlanes[LIndex + 2].Zero;
    APlanes[LIndex + 2].SetNormal(LPoints[LIndex].Cross(LPoints[(LIndex + 1) and 3] - LPoints[LIndex]));
    APlanes[LIndex + 2].NormalizeSelf;
    APlanes[LIndex + 2].FitThroughPoint(LPoints[LIndex]);
  end;
end;

procedure TGeoFrustum.ToPoints(out APoints: TGeoFrustumPoints);
var
  LScaled: array[0..2] of TGeoVec3;
begin
  LScaled[0] := Origin + Axis.Rows[0] * DNear;
  LScaled[1] := Axis.Rows[1] * (DLeft * DNear * InvFar);
  LScaled[2] := Axis.Rows[2] * (DUp * DNear * InvFar);
  APoints[0] := LScaled[0] + LScaled[1];
  APoints[1] := LScaled[0] - LScaled[1];
  APoints[2] := APoints[1] - LScaled[2];
  APoints[3] := APoints[0] - LScaled[2];
  APoints[0] := APoints[0] + LScaled[2];
  APoints[1] := APoints[1] + LScaled[2];

  LScaled[0] := Origin + Axis.Rows[0] * DFar;
  LScaled[1] := Axis.Rows[1] * DLeft;
  LScaled[2] := Axis.Rows[2] * DUp;
  APoints[4] := LScaled[0] + LScaled[1];
  APoints[5] := LScaled[0] - LScaled[1];
  APoints[6] := APoints[5] - LScaled[2];
  APoints[7] := APoints[4] - LScaled[2];
  APoints[4] := APoints[4] + LScaled[2];
  APoints[5] := APoints[5] + LScaled[2];
end;

procedure TGeoFrustum.ToClippedPoints(const AFractions: array of Single; out APoints: TGeoFrustumPoints);
var
  LScaled: array[0..2] of TGeoVec3;
begin
  LScaled[0] := Origin + Axis.Rows[0] * DNear;
  LScaled[1] := Axis.Rows[1] * (DLeft * DNear * InvFar);
  LScaled[2] := Axis.Rows[2] * (DUp * DNear * InvFar);
  APoints[0] := LScaled[0] + LScaled[1];
  APoints[1] := LScaled[0] - LScaled[1];
  APoints[2] := APoints[1] - LScaled[2];
  APoints[3] := APoints[0] - LScaled[2];
  APoints[0] := APoints[0] + LScaled[2];
  APoints[1] := APoints[1] + LScaled[2];

  LScaled[0] := Axis.Rows[0] * DFar;
  LScaled[1] := Axis.Rows[1] * DLeft;
  LScaled[2] := Axis.Rows[2] * DUp;
  APoints[4] := LScaled[0] + LScaled[1];
  APoints[5] := LScaled[0] - LScaled[1];
  APoints[6] := APoints[5] - LScaled[2];
  APoints[7] := APoints[4] - LScaled[2];
  APoints[4] := APoints[4] + LScaled[2];
  APoints[5] := APoints[5] + LScaled[2];

  APoints[4] := Origin + APoints[4] * AFractions[0];
  APoints[5] := Origin + APoints[5] * AFractions[1];
  APoints[6] := Origin + APoints[6] * AFractions[2];
  APoints[7] := Origin + APoints[7] * AFractions[3];
end;

procedure TGeoFrustum.ToIndexPoints(out AIndexPoints: TGeoFrustumPoints);
var
  LScaled: array[0..2] of TGeoVec3;
begin
  LScaled[0] := Origin + Axis.Rows[0] * DNear;
  LScaled[1] := Axis.Rows[1] * (DLeft * DNear * InvFar);
  LScaled[2] := Axis.Rows[2] * (DUp * DNear * InvFar);
  AIndexPoints[0] := LScaled[0] - LScaled[1];
  AIndexPoints[2] := LScaled[0] + LScaled[1];
  AIndexPoints[1] := AIndexPoints[0] + LScaled[2];
  AIndexPoints[3] := AIndexPoints[2] + LScaled[2];
  AIndexPoints[0] := AIndexPoints[0] - LScaled[2];
  AIndexPoints[2] := AIndexPoints[2] - LScaled[2];

  LScaled[0] := Origin + Axis.Rows[0] * DFar;
  LScaled[1] := Axis.Rows[1] * DLeft;
  LScaled[2] := Axis.Rows[2] * DUp;
  AIndexPoints[4] := LScaled[0] - LScaled[1];
  AIndexPoints[6] := LScaled[0] + LScaled[1];
  AIndexPoints[5] := AIndexPoints[4] + LScaled[2];
  AIndexPoints[7] := AIndexPoints[6] + LScaled[2];
  AIndexPoints[4] := AIndexPoints[4] - LScaled[2];
  AIndexPoints[6] := AIndexPoints[6] - LScaled[2];
end;

procedure TGeoFrustum.ToIndexPointsAndCornerVecs(out AIndexPoints: TGeoFrustumPoints;
  out ACornerVecs: TGeoFrustumCorners);
var
  LScaled: array[0..2] of TGeoVec3;
begin
  LScaled[0] := Origin + Axis.Rows[0] * DNear;
  LScaled[1] := Axis.Rows[1] * (DLeft * DNear * InvFar);
  LScaled[2] := Axis.Rows[2] * (DUp * DNear * InvFar);
  AIndexPoints[0] := LScaled[0] - LScaled[1];
  AIndexPoints[2] := LScaled[0] + LScaled[1];
  AIndexPoints[1] := AIndexPoints[0] + LScaled[2];
  AIndexPoints[3] := AIndexPoints[2] + LScaled[2];
  AIndexPoints[0] := AIndexPoints[0] - LScaled[2];
  AIndexPoints[2] := AIndexPoints[2] - LScaled[2];

  LScaled[0] := Axis.Rows[0] * DFar;
  LScaled[1] := Axis.Rows[1] * DLeft;
  LScaled[2] := Axis.Rows[2] * DUp;
  ACornerVecs[0] := LScaled[0] - LScaled[1];
  ACornerVecs[2] := LScaled[0] + LScaled[1];
  ACornerVecs[1] := ACornerVecs[0] + LScaled[2];
  ACornerVecs[3] := ACornerVecs[2] + LScaled[2];
  ACornerVecs[0] := ACornerVecs[0] - LScaled[2];
  ACornerVecs[2] := ACornerVecs[2] - LScaled[2];

  AIndexPoints[4] := ACornerVecs[0] + Origin;
  AIndexPoints[5] := ACornerVecs[1] + Origin;
  AIndexPoints[6] := ACornerVecs[2] + Origin;
  AIndexPoints[7] := ACornerVecs[3] + Origin;
end;

procedure TGeoFrustum.AxisProjection(const AIndexPoints: TGeoFrustumPoints; const ACornerVecs: TGeoFrustumCorners;
  const ADir: TGeoVec3; out AMin, AMax: Single);
var
  LDx, LDy, LDz: Single;
  LIndex: Integer;
begin
  LDy := ADir.X * Axis.Rows[1].X + ADir.Y * Axis.Rows[1].Y + ADir.Z * Axis.Rows[1].Z;
  LDz := ADir.X * Axis.Rows[2].X + ADir.Y * Axis.Rows[2].Y + ADir.Z * Axis.Rows[2].Z;
  LIndex := (SignBitSet(LDy) shl 1) or SignBitSet(LDz);
  LDx := ADir.X * ACornerVecs[LIndex].X + ADir.Y * ACornerVecs[LIndex].Y + ADir.Z * ACornerVecs[LIndex].Z;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  AMin := AIndexPoints[LIndex].Dot(ADir);

  LIndex := (not LIndex) and 3;
  LDx := -ADir.X * ACornerVecs[LIndex].X - ADir.Y * ACornerVecs[LIndex].Y - ADir.Z * ACornerVecs[LIndex].Z;
  LIndex := LIndex or (SignBitSet(LDx) shl 2);
  AMax := AIndexPoints[LIndex].Dot(ADir);
end;

procedure TGeoFrustum.AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single);
var
  LIndexPoints: TGeoFrustumPoints;
  LCornerVecs: TGeoFrustumCorners;
begin
  ToIndexPointsAndCornerVecs(LIndexPoints, LCornerVecs);
  AxisProjection(LIndexPoints, LCornerVecs, ADir, AMin, AMax);
end;

procedure TGeoFrustum.AxisProjection(const AAxis: TGeoMat3; out ABounds: TGeoBounds);
var
  LIndexPoints: TGeoFrustumPoints;
  LCornerVecs: TGeoFrustumCorners;
begin
  ToIndexPointsAndCornerVecs(LIndexPoints, LCornerVecs);
  AxisProjection(LIndexPoints, LCornerVecs, AAxis.Rows[0], ABounds.Mins.X, ABounds.Maxs.X);
  AxisProjection(LIndexPoints, LCornerVecs, AAxis.Rows[1], ABounds.Mins.Y, ABounds.Maxs.Y);
  AxisProjection(LIndexPoints, LCornerVecs, AAxis.Rows[2], ABounds.Mins.Z, ABounds.Maxs.Z);
end;

procedure TGeoFrustum.AddLocalLineToProjectionBoundsSetCull(const AStart, AEnd: TGeoVec3;
  out AStartCull, AEndCull: Integer; var ABounds: TGeoBounds);
var
  LDir, LP: TGeoVec3;
  LD1, LD2, LFStart, LFEnd, LLStart, LLEnd, LF: Single;
  LLeftScale, LUpScale: Single;
  LCull1, LCull2: Integer;
begin
  LLeftScale := DLeft * InvFar;
  LUpScale := DUp * InvFar;
  LDir := AEnd - AStart;
  LP.Zero;

  LFStart := DFar * AStart.Y;
  LFEnd := DFar * AEnd.Y;
  LLStart := DLeft * AStart.X;
  LLEnd := DLeft * AEnd.X;

  // left plane
  LD1 := -LFStart + LLStart;
  LD2 := -LFEnd + LLEnd;
  LCull1 := SignBitSet(LD1);
  LCull2 := SignBitSet(LD2);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.X := AStart.X + LF * LDir.X;
      if LP.X > 0 then
      begin
        LP.Z := AStart.Z + LF * LDir.Z;
        if TGeoMath.Fabs(LP.Z) <= LP.X * LUpScale then
        begin
          LP.Y := 1.0;
          LP.Z := LP.Z * DFar / (LP.X * DUp);
          ABounds.AddPoint(LP);
        end;
      end;
    end;

  // right plane
  LD1 := LFStart + LLStart;
  LD2 := LFEnd + LLEnd;
  LCull1 := LCull1 or (SignBitSet(LD1) shl 1);
  LCull2 := LCull2 or (SignBitSet(LD2) shl 1);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.X := AStart.X + LF * LDir.X;
      if LP.X > 0 then
      begin
        LP.Z := AStart.Z + LF * LDir.Z;
        if TGeoMath.Fabs(LP.Z) <= LP.X * LUpScale then
        begin
          LP.Y := -1.0;
          LP.Z := LP.Z * DFar / (LP.X * DUp);
          ABounds.AddPoint(LP);
        end;
      end;
    end;

  LFStart := DFar * AStart.Z;
  LFEnd := DFar * AEnd.Z;
  LLStart := DUp * AStart.X;
  LLEnd := DUp * AEnd.X;

  // up plane
  LD1 := -LFStart + LLStart;
  LD2 := -LFEnd + LLEnd;
  LCull1 := LCull1 or (SignBitSet(LD1) shl 2);
  LCull2 := LCull2 or (SignBitSet(LD2) shl 2);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.X := AStart.X + LF * LDir.X;
      if LP.X > 0 then
      begin
        LP.Y := AStart.Y + LF * LDir.Y;
        if TGeoMath.Fabs(LP.Y) <= LP.X * LLeftScale then
        begin
          LP.Y := LP.Y * DFar / (LP.X * DLeft);
          LP.Z := 1.0;
          ABounds.AddPoint(LP);
        end;
      end;
    end;

  // down plane
  LD1 := LFStart + LLStart;
  LD2 := LFEnd + LLEnd;
  LCull1 := LCull1 or (SignBitSet(LD1) shl 3);
  LCull2 := LCull2 or (SignBitSet(LD2) shl 3);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.X := AStart.X + LF * LDir.X;
      if LP.X > 0 then
      begin
        LP.Y := AStart.Y + LF * LDir.Y;
        if TGeoMath.Fabs(LP.Y) <= LP.X * LLeftScale then
        begin
          LP.Y := LP.Y * DFar / (LP.X * DLeft);
          LP.Z := -1.0;
          ABounds.AddPoint(LP);
        end;
      end;
    end;

  if (LCull1 = 0) and (AStart.X > 0) then
  begin
    // add start point to projection bounds
    LP.X := AStart.X;
    LP.Y := AStart.Y * DFar / (AStart.X * DLeft);
    LP.Z := AStart.Z * DFar / (AStart.X * DUp);
    ABounds.AddPoint(LP);
  end;
  if (LCull2 = 0) and (AEnd.X > 0) then
  begin
    // add end point to projection bounds
    LP.X := AEnd.X;
    LP.Y := AEnd.Y * DFar / (AEnd.X * DLeft);
    LP.Z := AEnd.Z * DFar / (AEnd.X * DUp);
    ABounds.AddPoint(LP);
  end;

  if AStart.X < ABounds.Mins.X then
  begin
    if AStart.X < 0 then
      ABounds.Mins.X := 0
    else
      ABounds.Mins.X := AStart.X;
  end;
  if AEnd.X < ABounds.Mins.X then
  begin
    if AEnd.X < 0 then
      ABounds.Mins.X := 0
    else
      ABounds.Mins.X := AEnd.X;
  end;

  AStartCull := LCull1;
  AEndCull := LCull2;
end;

procedure TGeoFrustum.AddLocalLineToProjectionBoundsUseCull(const AStart, AEnd: TGeoVec3;
  AStartCull, AEndCull: Integer; var ABounds: TGeoBounds);
var
  LDir, LP: TGeoVec3;
  LD1, LD2, LFStart, LFEnd, LLStart, LLEnd, LF: Single;
  LLeftScale, LUpScale: Single;
  LClip: Integer;
begin
  LClip := AStartCull xor AEndCull;
  if LClip = 0 then
    Exit;

  LLeftScale := DLeft * InvFar;
  LUpScale := DUp * InvFar;
  LDir := AEnd - AStart;
  LP.Zero;

  if (LClip and (1 or 2)) <> 0 then
  begin
    LFStart := DFar * AStart.Y;
    LFEnd := DFar * AEnd.Y;
    LLStart := DLeft * AStart.X;
    LLEnd := DLeft * AEnd.X;

    if (LClip and 1) <> 0 then
    begin
      // left plane
      LD1 := -LFStart + LLStart;
      LD2 := -LFEnd + LLEnd;
      if NotZero(LD1) then
        if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
        begin
          LF := LD1 / (LD1 - LD2);
          LP.X := AStart.X + LF * LDir.X;
          if LP.X > 0 then
          begin
            LP.Z := AStart.Z + LF * LDir.Z;
            if TGeoMath.Fabs(LP.Z) <= LP.X * LUpScale then
            begin
              LP.Y := 1.0;
              LP.Z := LP.Z * DFar / (LP.X * DUp);
              ABounds.AddPoint(LP);
            end;
          end;
        end;
    end;
    if (LClip and 2) <> 0 then
    begin
      // right plane
      LD1 := LFStart + LLStart;
      LD2 := LFEnd + LLEnd;
      if NotZero(LD1) then
        if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
        begin
          LF := LD1 / (LD1 - LD2);
          LP.X := AStart.X + LF * LDir.X;
          if LP.X > 0 then
          begin
            LP.Z := AStart.Z + LF * LDir.Z;
            if TGeoMath.Fabs(LP.Z) <= LP.X * LUpScale then
            begin
              LP.Y := -1.0;
              LP.Z := LP.Z * DFar / (LP.X * DUp);
              ABounds.AddPoint(LP);
            end;
          end;
        end;
    end;
  end;

  if (LClip and (4 or 8)) <> 0 then
  begin
    LFStart := DFar * AStart.Z;
    LFEnd := DFar * AEnd.Z;
    LLStart := DUp * AStart.X;
    LLEnd := DUp * AEnd.X;

    if (LClip and 4) <> 0 then
    begin
      // up plane
      LD1 := -LFStart + LLStart;
      LD2 := -LFEnd + LLEnd;
      if NotZero(LD1) then
        if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
        begin
          LF := LD1 / (LD1 - LD2);
          LP.X := AStart.X + LF * LDir.X;
          if LP.X > 0 then
          begin
            LP.Y := AStart.Y + LF * LDir.Y;
            if TGeoMath.Fabs(LP.Y) <= LP.X * LLeftScale then
            begin
              LP.Y := LP.Y * DFar / (LP.X * DLeft);
              LP.Z := 1.0;
              ABounds.AddPoint(LP);
            end;
          end;
        end;
    end;
    if (LClip and 8) <> 0 then
    begin
      // down plane
      LD1 := LFStart + LLStart;
      LD2 := LFEnd + LLEnd;
      if NotZero(LD1) then
        if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
        begin
          LF := LD1 / (LD1 - LD2);
          LP.X := AStart.X + LF * LDir.X;
          if LP.X > 0 then
          begin
            LP.Y := AStart.Y + LF * LDir.Y;
            if TGeoMath.Fabs(LP.Y) <= LP.X * LLeftScale then
            begin
              LP.Y := LP.Y * DFar / (LP.X * DLeft);
              LP.Z := -1.0;
              ABounds.AddPoint(LP);
            end;
          end;
        end;
    end;
  end;
end;

function TGeoFrustum.BoundsRayIntersection(const ABounds: TGeoBounds; const AStart, ADir: TGeoVec3;
  out AScale1, AScale2: Single): Boolean;
var
  LEnd, LP: TGeoVec3;
  LD1, LD2, LF: Single;
  LIndex, LStartInside: Integer;
  LBounds: array[0..1] of TGeoVec3;
begin
  LBounds[0] := ABounds.Mins;
  LBounds[1] := ABounds.Maxs;
  LStartInside := 1;
  AScale1 := GEO_INFINITY;
  AScale2 := -GEO_INFINITY;
  LEnd := AStart + ADir;
  LP.Zero;

  for LIndex := 0 to 1 do
  begin
    LD1 := AStart.X - LBounds[LIndex].X;
    LStartInside := LStartInside and (SignBitSet(LD1) xor LIndex);
    LD2 := LEnd.X - LBounds[LIndex].X;
    if LD1 <> LD2 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.Y := AStart.Y + LF * ADir.Y;
      if (LBounds[0].Y <= LP.Y) and (LP.Y <= LBounds[1].Y) then
      begin
        LP.Z := AStart.Z + LF * ADir.Z;
        if (LBounds[0].Z <= LP.Z) and (LP.Z <= LBounds[1].Z) then
        begin
          if LF < AScale1 then
            AScale1 := LF;
          if LF > AScale2 then
            AScale2 := LF;
        end;
      end;
    end;

    LD1 := AStart.Y - LBounds[LIndex].Y;
    LStartInside := LStartInside and (SignBitSet(LD1) xor LIndex);
    LD2 := LEnd.Y - LBounds[LIndex].Y;
    if LD1 <> LD2 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.X := AStart.X + LF * ADir.X;
      if (LBounds[0].X <= LP.X) and (LP.X <= LBounds[1].X) then
      begin
        LP.Z := AStart.Z + LF * ADir.Z;
        if (LBounds[0].Z <= LP.Z) and (LP.Z <= LBounds[1].Z) then
        begin
          if LF < AScale1 then
            AScale1 := LF;
          if LF > AScale2 then
            AScale2 := LF;
        end;
      end;
    end;

    LD1 := AStart.Z - LBounds[LIndex].Z;
    LStartInside := LStartInside and (SignBitSet(LD1) xor LIndex);
    LD2 := LEnd.Z - LBounds[LIndex].Z;
    if LD1 <> LD2 then
    begin
      LF := LD1 / (LD1 - LD2);
      LP.X := AStart.X + LF * ADir.X;
      if (LBounds[0].X <= LP.X) and (LP.X <= LBounds[1].X) then
      begin
        LP.Y := AStart.Y + LF * ADir.Y;
        if (LBounds[0].Y <= LP.Y) and (LP.Y <= LBounds[1].Y) then
        begin
          if LF < AScale1 then
            AScale1 := LF;
          if LF > AScale2 then
            AScale2 := LF;
        end;
      end;
    end;
  end;
  Result := LStartInside <> 0;
end;

function TGeoFrustum.ProjectionBounds(const ABounds: TGeoBounds; out AProjectionBounds: TGeoBounds): Boolean;
begin
  Result := ProjectionBounds(TGeoBox.Make(ABounds, TGeoVec3.Origin, TGeoMat3.Identity), AProjectionBounds);
end;

function TGeoFrustum.ProjectionBounds(const ABox: TGeoBox; out AProjectionBounds: TGeoBounds): Boolean;
var
  LIndex, LP1, LP2, LCulled, LOutside: Integer;
  LPointCull: array[0..7] of Integer;
  LScale1, LScale2, LBoxMin, LBoxMax, LBase: Single;
  LPoints: TGeoFrustumPoints;
  LLocalOrigin: TGeoVec3;
  LLocalAxis, LLocalScaled: TGeoMat3;
  LBounds: TGeoBounds;
begin
  FillChar(LPointCull, SizeOf(LPointCull), 0);
  LBounds := TGeoBounds.Make(-ABox.Extents, ABox.Extents);

  // if the frustum origin is inside the bounds
  if LBounds.ContainsPoint((Origin - ABox.Center) * ABox.Axis.Transpose) then
  begin
    // bounds that cover the whole frustum
    LBase := Origin.Dot(Axis.Rows[0]);
    ABox.AxisProjection(Axis.Rows[0], LBoxMin, LBoxMax);
    AProjectionBounds.Mins.X := LBoxMin - LBase;
    AProjectionBounds.Maxs.X := LBoxMax - LBase;
    AProjectionBounds.Mins.Y := -1.0;
    AProjectionBounds.Mins.Z := -1.0;
    AProjectionBounds.Maxs.Y := 1.0;
    AProjectionBounds.Maxs.Z := 1.0;
    Exit(True);
  end;

  AProjectionBounds.Clear;

  // transform the bounds into the space of this frustum
  LLocalOrigin := (ABox.Center - Origin) * Axis.Transpose;
  LLocalAxis := ABox.Axis * Axis.Transpose;
  BoxToPoints(LLocalOrigin, ABox.Extents, LLocalAxis, LPoints);

  // test outer four edges of the bounds
  LCulled := -1;
  LOutside := 0;
  for LIndex := 0 to 3 do
  begin
    LP1 := LIndex;
    LP2 := 4 + LIndex;
    AddLocalLineToProjectionBoundsSetCull(LPoints[LP1], LPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
    LCulled := LCulled and LPointCull[LP1] and LPointCull[LP2];
    LOutside := LOutside or LPointCull[LP1] or LPointCull[LP2];
  end;

  // if the bounds are completely outside this frustum
  if LCulled <> 0 then
    Exit(False);
  // if the bounds are completely inside this frustum
  if LOutside = 0 then
    Exit(True);

  // test the remaining edges of the bounds
  for LIndex := 0 to 3 do
  begin
    LP1 := LIndex;
    LP2 := (LIndex + 1) and 3;
    AddLocalLineToProjectionBoundsUseCull(LPoints[LP1], LPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
  end;
  for LIndex := 0 to 3 do
  begin
    LP1 := 4 + LIndex;
    LP2 := 4 + ((LIndex + 1) and 3);
    AddLocalLineToProjectionBoundsUseCull(LPoints[LP1], LPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
  end;

  // if the bounds extend beyond two or more boundaries of this frustum
  if (LOutside <> 1) and (LOutside <> 2) and (LOutside <> 4) and (LOutside <> 8) then
  begin
    LLocalOrigin := (Origin - ABox.Center) * ABox.Axis.Transpose;
    LLocalScaled := Axis * ABox.Axis.Transpose;
    LLocalScaled.Rows[0] := LLocalScaled.Rows[0] * DFar;
    LLocalScaled.Rows[1] := LLocalScaled.Rows[1] * DLeft;
    LLocalScaled.Rows[2] := LLocalScaled.Rows[2] * DUp;

    // test the outer edges of this frustum for intersection with the bounds
    if ((LOutside and 2) <> 0) and ((LOutside and 8) <> 0) then
    begin
      BoundsRayIntersection(LBounds, LLocalOrigin,
        LLocalScaled.Rows[0] - LLocalScaled.Rows[1] - LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, -1.0, -1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, -1.0, -1.0));
      end;
    end;
    if ((LOutside and 2) <> 0) and ((LOutside and 4) <> 0) then
    begin
      BoundsRayIntersection(LBounds, LLocalOrigin,
        LLocalScaled.Rows[0] - LLocalScaled.Rows[1] + LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, -1.0, 1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, -1.0, 1.0));
      end;
    end;
    if ((LOutside and 1) <> 0) and ((LOutside and 8) <> 0) then
    begin
      BoundsRayIntersection(LBounds, LLocalOrigin,
        LLocalScaled.Rows[0] + LLocalScaled.Rows[1] - LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, 1.0, -1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, 1.0, -1.0));
      end;
    end;
    if ((LOutside and 1) <> 0) and ((LOutside and 2) <> 0) then
    begin
      BoundsRayIntersection(LBounds, LLocalOrigin,
        LLocalScaled.Rows[0] + LLocalScaled.Rows[1] + LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, 1.0, 1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, 1.0, 1.0));
      end;
    end;
  end;
  Result := True;
end;

function TGeoFrustum.ProjectionBounds(const ASphere: TGeoSphere; out AProjectionBounds: TGeoBounds): Boolean;
var
  LD, LR, LRadiusSqr, LFarSqr: Single;
  LCenter: TGeoVec3;
begin
  AProjectionBounds.Clear;
  LCenter := (ASphere.Origin - Origin) * Axis.Transpose;
  LR := ASphere.Radius;
  LRadiusSqr := LR * LR;
  LFarSqr := DFar * DFar;

  // left and right planes
  LD := DFar * TGeoMath.Fabs(LCenter.Y) - DLeft * LCenter.X;
  if (LD * LD) > LRadiusSqr * (LFarSqr + DLeft * DLeft) then
    Exit(False);
  // up and down planes
  LD := DFar * TGeoMath.Fabs(LCenter.Z) - DUp * LCenter.X;
  if (LD * LD) > LRadiusSqr * (LFarSqr + DUp * DUp) then
    Exit(False);

  // bounds that cover the whole frustum
  AProjectionBounds.Mins.X := 0;
  AProjectionBounds.Maxs.X := DFar;
  AProjectionBounds.Mins.Y := -1.0;
  AProjectionBounds.Mins.Z := -1.0;
  AProjectionBounds.Maxs.Y := 1.0;
  AProjectionBounds.Maxs.Z := 1.0;
  Result := True;
end;

function TGeoFrustum.ProjectionBounds(const AFrustum: TGeoFrustum; out AProjectionBounds: TGeoBounds): Boolean;
var
  LIndex, LP1, LP2, LCulled, LOutside: Integer;
  LPointCull: array[0..7] of Integer;
  LScale1, LScale2, LFrustumMin, LFrustumMax, LBase: Single;
  LLocalFrustum: TGeoFrustum;
  LPoints: TGeoFrustumPoints;
  LLocalOrigin: TGeoVec3;
  LLocalScaled: TGeoMat3;
begin
  FillChar(LPointCull, SizeOf(LPointCull), 0);

  // if the frustum origin is inside the other frustum
  if AFrustum.ContainsPoint(Origin) then
  begin
    // bounds that cover the whole frustum
    LBase := Origin.Dot(Axis.Rows[0]);
    AFrustum.AxisProjection(Axis.Rows[0], LFrustumMin, LFrustumMax);
    AProjectionBounds.Mins.X := LFrustumMin - LBase;
    AProjectionBounds.Maxs.X := LFrustumMax - LBase;
    AProjectionBounds.Mins.Y := -1.0;
    AProjectionBounds.Mins.Z := -1.0;
    AProjectionBounds.Maxs.Y := 1.0;
    AProjectionBounds.Maxs.Z := 1.0;
    Exit(True);
  end;

  AProjectionBounds.Clear;

  // transform the given frustum into the space of this frustum
  LLocalFrustum := AFrustum;
  LLocalFrustum.Origin := (AFrustum.Origin - Origin) * Axis.Transpose;
  LLocalFrustum.Axis := AFrustum.Axis * Axis.Transpose;
  LLocalFrustum.ToPoints(LPoints);

  // test outer four edges of the other frustum
  LCulled := -1;
  LOutside := 0;
  for LIndex := 0 to 3 do
  begin
    LP1 := LIndex;
    LP2 := 4 + LIndex;
    AddLocalLineToProjectionBoundsSetCull(LPoints[LP1], LPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
    LCulled := LCulled and LPointCull[LP1] and LPointCull[LP2];
    LOutside := LOutside or LPointCull[LP1] or LPointCull[LP2];
  end;

  // if the other frustum is completely outside this frustum
  if LCulled <> 0 then
    Exit(False);
  // if the other frustum is completely inside this frustum
  if LOutside = 0 then
    Exit(True);

  // test the remaining edges of the other frustum
  if LLocalFrustum.DNear > 0 then
    for LIndex := 0 to 3 do
    begin
      LP1 := LIndex;
      LP2 := (LIndex + 1) and 3;
      AddLocalLineToProjectionBoundsUseCull(LPoints[LP1], LPoints[LP2], LPointCull[LP1], LPointCull[LP2],
        AProjectionBounds);
    end;
  for LIndex := 0 to 3 do
  begin
    LP1 := 4 + LIndex;
    LP2 := 4 + ((LIndex + 1) and 3);
    AddLocalLineToProjectionBoundsUseCull(LPoints[LP1], LPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
  end;

  // if the other frustum extends beyond two or more boundaries of this frustum
  if (LOutside <> 1) and (LOutside <> 2) and (LOutside <> 4) and (LOutside <> 8) then
  begin
    LLocalOrigin := (Origin - AFrustum.Origin) * AFrustum.Axis.Transpose;
    LLocalScaled := Axis * AFrustum.Axis.Transpose;
    LLocalScaled.Rows[0] := LLocalScaled.Rows[0] * DFar;
    LLocalScaled.Rows[1] := LLocalScaled.Rows[1] * DLeft;
    LLocalScaled.Rows[2] := LLocalScaled.Rows[2] * DUp;

    // test the outer edges of this frustum for intersection with the other frustum
    if ((LOutside and 2) <> 0) and ((LOutside and 8) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin,
        LLocalScaled.Rows[0] - LLocalScaled.Rows[1] - LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, -1.0, -1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, -1.0, -1.0));
      end;
    end;
    if ((LOutside and 2) <> 0) and ((LOutside and 4) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin,
        LLocalScaled.Rows[0] - LLocalScaled.Rows[1] + LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, -1.0, 1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, -1.0, 1.0));
      end;
    end;
    if ((LOutside and 1) <> 0) and ((LOutside and 8) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin,
        LLocalScaled.Rows[0] + LLocalScaled.Rows[1] - LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, 1.0, -1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, 1.0, -1.0));
      end;
    end;
    if ((LOutside and 1) <> 0) and ((LOutside and 2) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin,
        LLocalScaled.Rows[0] + LLocalScaled.Rows[1] + LLocalScaled.Rows[2], LScale1, LScale2);
      if (LScale1 <= LScale2) and (LScale1 >= 0) then
      begin
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale1 * DFar, 1.0, 1.0));
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale2 * DFar, 1.0, 1.0));
      end;
    end;
  end;
  Result := True;
end;

function TGeoFrustum.ProjectionBounds(const AWinding: TGeoWinding; out AProjectionBounds: TGeoBounds): Boolean;
var
  LIndex, LP1, LP2, LCulled, LOutside: Integer;
  LScale: Single;
  LLocalPoints: TArray<TGeoVec3>;
  LPointCull: TArray<Integer>;
  LTranspose, LScaled: TGeoMat3;
  LPlane: TGeoPlane;
  LCount: Integer;
begin
  AProjectionBounds.Clear;
  LCount := AWinding.NumPoints;

  // transform the winding points into the space of this frustum
  SetLength(LLocalPoints, LCount);
  SetLength(LPointCull, LCount);
  LTranspose := Axis.Transpose;
  for LIndex := 0 to LCount - 1 do
    LLocalPoints[LIndex] := (AWinding[LIndex] - Origin) * LTranspose;

  // test the winding edges
  LCulled := -1;
  LOutside := 0;
  LIndex := 0;
  while LIndex < LCount do
  begin
    LP1 := LIndex;
    LP2 := (LIndex + 1) mod LCount;
    AddLocalLineToProjectionBoundsSetCull(LLocalPoints[LP1], LLocalPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
    LCulled := LCulled and LPointCull[LP1] and LPointCull[LP2];
    LOutside := LOutside or LPointCull[LP1] or LPointCull[LP2];
    Inc(LIndex, 2);
  end;

  // if completely culled
  if LCulled <> 0 then
    Exit(False);
  // if completely inside
  if LOutside = 0 then
    Exit(True);

  // test remaining winding edges
  LIndex := 1;
  while LIndex < LCount do
  begin
    LP1 := LIndex;
    LP2 := (LIndex + 1) mod LCount;
    AddLocalLineToProjectionBoundsUseCull(LLocalPoints[LP1], LLocalPoints[LP2], LPointCull[LP1], LPointCull[LP2],
      AProjectionBounds);
    Inc(LIndex, 2);
  end;

  // if the winding extends beyond two or more boundaries of this frustum
  if (LOutside <> 1) and (LOutside <> 2) and (LOutside <> 4) and (LOutside <> 8) then
  begin
    AWinding.GetPlane(LPlane);
    LScaled.Rows[0] := Axis.Rows[0] * DFar;
    LScaled.Rows[1] := Axis.Rows[1] * DLeft;
    LScaled.Rows[2] := Axis.Rows[2] * DUp;

    // test the outer edges of this frustum for intersection with the winding
    if ((LOutside and 2) <> 0) and ((LOutside and 8) <> 0) then
      if AWinding.RayIntersection(LPlane, Origin, LScaled.Rows[0] - LScaled.Rows[1] - LScaled.Rows[2], LScale) then
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale * DFar, -1.0, -1.0));
    if ((LOutside and 2) <> 0) and ((LOutside and 4) <> 0) then
      if AWinding.RayIntersection(LPlane, Origin, LScaled.Rows[0] - LScaled.Rows[1] + LScaled.Rows[2], LScale) then
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale * DFar, -1.0, 1.0));
    if ((LOutside and 1) <> 0) and ((LOutside and 8) <> 0) then
      if AWinding.RayIntersection(LPlane, Origin, LScaled.Rows[0] + LScaled.Rows[1] - LScaled.Rows[2], LScale) then
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale * DFar, 1.0, -1.0));
    if ((LOutside and 1) <> 0) and ((LOutside and 2) <> 0) then
      if AWinding.RayIntersection(LPlane, Origin, LScaled.Rows[0] + LScaled.Rows[1] + LScaled.Rows[2], LScale) then
        AProjectionBounds.AddPoint(TGeoVec3.Make(LScale * DFar, 1.0, 1.0));
  end;
  Result := True;
end;

procedure TGeoFrustum.ClipFrustumToBox(const ABox: TGeoBox; var AClipFractions: array of Single;
  var AClipPlanes: array of Integer);
var
  LIndex, LSide: Integer;
  LF, LMinF: Single;
  LScaled, LLocalAxis, LTranspose: TGeoMat3;
  LLocalOrigin: TGeoVec3;
  LCornerVecs: TGeoFrustumCorners;
  LBounds: array[0..1] of TGeoVec3;
begin
  LTranspose := ABox.Axis.Transpose;
  LLocalOrigin := (Origin - ABox.Center) * LTranspose;
  LLocalAxis := Axis * LTranspose;
  LScaled.Rows[0] := LLocalAxis.Rows[0] * DFar;
  LScaled.Rows[1] := LLocalAxis.Rows[1] * DLeft;
  LScaled.Rows[2] := LLocalAxis.Rows[2] * DUp;
  LCornerVecs[0] := LScaled.Rows[0] + LScaled.Rows[1];
  LCornerVecs[1] := LScaled.Rows[0] - LScaled.Rows[1];
  LCornerVecs[2] := LCornerVecs[1] - LScaled.Rows[2];
  LCornerVecs[3] := LCornerVecs[0] - LScaled.Rows[2];
  LCornerVecs[0] := LCornerVecs[0] + LScaled.Rows[2];
  LCornerVecs[1] := LCornerVecs[1] + LScaled.Rows[2];

  LBounds[0] := -ABox.Extents;
  LBounds[1] := ABox.Extents;

  LMinF := (DNear + 1.0) * InvFar;
  for LIndex := 0 to 3 do
  begin
    LSide := SignBitNotSet(LCornerVecs[LIndex].X);
    LF := (LBounds[LSide].X - LLocalOrigin.X) / LCornerVecs[LIndex].X;
    AClipFractions[LIndex] := LF;
    AClipPlanes[LIndex] := 1 shl LSide;

    LSide := SignBitNotSet(LCornerVecs[LIndex].Y);
    LF := (LBounds[LSide].Y - LLocalOrigin.Y) / LCornerVecs[LIndex].Y;
    if LF < AClipFractions[LIndex] then
    begin
      AClipFractions[LIndex] := LF;
      AClipPlanes[LIndex] := 4 shl LSide;
    end;

    LSide := SignBitNotSet(LCornerVecs[LIndex].Z);
    LF := (LBounds[LSide].Z - LLocalOrigin.Z) / LCornerVecs[LIndex].Z;
    if LF < AClipFractions[LIndex] then
    begin
      AClipFractions[LIndex] := LF;
      AClipPlanes[LIndex] := 16 shl LSide;
    end;

    // make sure the frustum is not clipped between the frustum origin and the near plane
    if AClipFractions[LIndex] < LMinF then
      AClipFractions[LIndex] := LMinF;
  end;
end;

function TGeoFrustum.ClipLine(const ALocalPoints, APoints: TGeoFrustumPoints; AStartIndex, AEndIndex: Integer;
  var AStart, AEnd: TGeoVec3; var AStartClip, AEndClip: Integer): Boolean;
var
  LD1, LD2, LFStart, LFEnd, LLStart, LLEnd, LF, LX: Single;
  LLeftScale, LUpScale, LScale1, LScale2: Single;
  LStartCull, LEndCull: Integer;
  LLocalStart, LLocalEnd, LLocalDir: TGeoVec3;
begin
  LLeftScale := DLeft * InvFar;
  LUpScale := DUp * InvFar;
  LLocalStart := ALocalPoints[AStartIndex];
  LLocalEnd := ALocalPoints[AEndIndex];
  LLocalDir := LLocalEnd - LLocalStart;
  AStartClip := -1;
  AEndClip := -1;
  LScale1 := GEO_INFINITY;
  LScale2 := -GEO_INFINITY;

  LFStart := DFar * LLocalStart.Y;
  LFEnd := DFar * LLocalEnd.Y;
  LLStart := DLeft * LLocalStart.X;
  LLEnd := DLeft * LLocalEnd.X;

  // left plane
  LD1 := -LFStart + LLStart;
  LD2 := -LFEnd + LLEnd;
  LStartCull := SignBitSet(LD1);
  LEndCull := SignBitSet(LD2);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := LLocalStart.X + LF * LLocalDir.X;
      if LX >= 0 then
        if TGeoMath.Fabs(LLocalStart.Z + LF * LLocalDir.Z) <= LX * LUpScale then
        begin
          if LF < LScale1 then
          begin
            LScale1 := LF;
            AStartClip := 0;
          end;
          if LF > LScale2 then
          begin
            LScale2 := LF;
            AEndClip := 0;
          end;
        end;
    end;

  // right plane
  LD1 := LFStart + LLStart;
  LD2 := LFEnd + LLEnd;
  LStartCull := LStartCull or (SignBitSet(LD1) shl 1);
  LEndCull := LEndCull or (SignBitSet(LD2) shl 1);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := LLocalStart.X + LF * LLocalDir.X;
      if LX >= 0 then
        if TGeoMath.Fabs(LLocalStart.Z + LF * LLocalDir.Z) <= LX * LUpScale then
        begin
          if LF < LScale1 then
          begin
            LScale1 := LF;
            AStartClip := 1;
          end;
          if LF > LScale2 then
          begin
            LScale2 := LF;
            AEndClip := 1;
          end;
        end;
    end;

  LFStart := DFar * LLocalStart.Z;
  LFEnd := DFar * LLocalEnd.Z;
  LLStart := DUp * LLocalStart.X;
  LLEnd := DUp * LLocalEnd.X;

  // up plane
  LD1 := -LFStart + LLStart;
  LD2 := -LFEnd + LLEnd;
  LStartCull := LStartCull or (SignBitSet(LD1) shl 2);
  LEndCull := LEndCull or (SignBitSet(LD2) shl 2);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := LLocalStart.X + LF * LLocalDir.X;
      if LX >= 0 then
        if TGeoMath.Fabs(LLocalStart.Y + LF * LLocalDir.Y) <= LX * LLeftScale then
        begin
          if LF < LScale1 then
          begin
            LScale1 := LF;
            AStartClip := 2;
          end;
          if LF > LScale2 then
          begin
            LScale2 := LF;
            AEndClip := 2;
          end;
        end;
    end;

  // down plane
  LD1 := LFStart + LLStart;
  LD2 := LFEnd + LLEnd;
  LStartCull := LStartCull or (SignBitSet(LD1) shl 3);
  LEndCull := LEndCull or (SignBitSet(LD2) shl 3);
  if NotZero(LD1) then
    if (SignBitSet(LD1) xor SignBitSet(LD2)) <> 0 then
    begin
      LF := LD1 / (LD1 - LD2);
      LX := LLocalStart.X + LF * LLocalDir.X;
      if LX >= 0 then
        if TGeoMath.Fabs(LLocalStart.Y + LF * LLocalDir.Y) <= LX * LLeftScale then
        begin
          if LF < LScale1 then
          begin
            LScale1 := LF;
            AStartClip := 3;
          end;
          if LF > LScale2 then
          begin
            LScale2 := LF;
            AEndClip := 3;
          end;
        end;
    end;

  // if completely inside
  if (LStartCull or LEndCull) = 0 then
  begin
    AStart := APoints[AStartIndex];
    AEnd := APoints[AEndIndex];
    Exit(True);
  end
  else if LScale1 <= LScale2 then
  begin
    if LStartCull = 0 then
    begin
      AStart := APoints[AStartIndex];
      AStartClip := -1;
    end
    else
      AStart := APoints[AStartIndex] + (APoints[AEndIndex] - APoints[AStartIndex]) * LScale1;
    if LEndCull = 0 then
    begin
      AEnd := APoints[AEndIndex];
      AEndClip := -1;
    end
    else
      AEnd := APoints[AStartIndex] + (APoints[AEndIndex] - APoints[AStartIndex]) * LScale2;
    Exit(True);
  end;
  Result := False;
end;

function TGeoFrustum.AddLocalCapsToProjectionBounds(const AEndPoints: array of TGeoVec3;
  const AEndPointCull: array of Integer; const APoint: TGeoVec3; APointCull, APointClip: Integer;
  var AProjectionBounds: TGeoBounds): Boolean;
var
  LFirst, LSecond: Integer;
begin
  if APointClip < 0 then
    Exit(False);
  LFirst := CAP_POINT_INDEX[APointClip, 0];
  LSecond := CAP_POINT_INDEX[APointClip, 1];
  AddLocalLineToProjectionBoundsUseCull(AEndPoints[LFirst], APoint, AEndPointCull[LFirst], APointCull,
    AProjectionBounds);
  AddLocalLineToProjectionBoundsUseCull(AEndPoints[LSecond], APoint, AEndPointCull[LSecond], APointCull,
    AProjectionBounds);
  Result := True;
end;

function TGeoFrustum.ClippedProjectionBounds(const AFrustum: TGeoFrustum; const AClipBox: TGeoBox;
  out AProjectionBounds: TGeoBounds): Boolean;
var
  LIndex, LP1, LP2, LUsedClipPlanes, LNearCull, LFarCull, LOutside: Integer;
  LStartClip, LEndClip: Integer;
  LClipPointCull: array[0..7] of Integer;
  LBoxPointCull: array[0..7] of Integer;
  LClipPlanes: array[0..3] of Integer;
  LPointCull: array[0..1] of Integer;
  LClipFractions: array[0..3] of Single;
  LS1, LS2, LT1, LT2, LLeftScale, LUpScale: Single;
  LLocalFrustum: TGeoFrustum;
  LClipPoints, LLocalPoints1, LLocalPoints2: TGeoFrustumPoints;
  LEndPoints: array[0..3] of TGeoVec3;
  LEndPointCull: array[0..3] of Integer;
  LLocalOrigin1, LLocalOrigin2, LStart, LEnd: TGeoVec3;
  LLocalAxis1, LLocalAxis2, LTranspose: TGeoMat3;
  LClipBounds: TGeoBounds;
  LClipBoxMin, LClipBoxMax, LFrustumMin, LFrustumMax, LBase: Single;

  procedure ClipEdge(AFirst, ASecond: Integer);
  begin
    if (LBoxPointCull[AFirst] and LBoxPointCull[ASecond]) = 0 then
      if AFrustum.ClipLine(LLocalPoints1, LLocalPoints2, AFirst, ASecond, LStart, LEnd, LStartClip, LEndClip) then
      begin
        AddLocalLineToProjectionBoundsSetCull(LStart, LEnd, LPointCull[0], LPointCull[1], AProjectionBounds);
        AddLocalCapsToProjectionBounds(LEndPoints, LEndPointCull, LStart, LPointCull[0], LStartClip,
          AProjectionBounds);
        AddLocalCapsToProjectionBounds(LEndPoints, LEndPointCull, LEnd, LPointCull[1], LEndClip,
          AProjectionBounds);
        LOutside := LOutside or LPointCull[0] or LPointCull[1];
      end;
  end;

begin
  FillChar(LClipPointCull, SizeOf(LClipPointCull), 0);
  FillChar(LBoxPointCull, SizeOf(LBoxPointCull), 0);
  LPointCull[0] := 0;
  LPointCull[1] := 0;
  LStart.Zero;
  LEnd.Zero;

  // if the frustum origin is inside the other frustum
  if AFrustum.ContainsPoint(Origin) then
  begin
    // bounds that cover the whole frustum
    LBase := Origin.Dot(Axis.Rows[0]);
    AClipBox.AxisProjection(Axis.Rows[0], LClipBoxMin, LClipBoxMax);
    AFrustum.AxisProjection(Axis.Rows[0], LFrustumMin, LFrustumMax);
    AProjectionBounds.Mins.X := Max(LClipBoxMin, LFrustumMin) - LBase;
    AProjectionBounds.Maxs.X := Min(LClipBoxMax, LFrustumMax) - LBase;
    AProjectionBounds.Mins.Y := -1.0;
    AProjectionBounds.Mins.Z := -1.0;
    AProjectionBounds.Maxs.Y := 1.0;
    AProjectionBounds.Maxs.Z := 1.0;
    Exit(True);
  end;

  AProjectionBounds.Clear;

  // clip the outer edges of the given frustum to the clip bounds
  AFrustum.ClipFrustumToBox(AClipBox, LClipFractions, LClipPlanes);
  LUsedClipPlanes := LClipPlanes[0] or LClipPlanes[1] or LClipPlanes[2] or LClipPlanes[3];

  // transform the clipped frustum to the space of this frustum
  LTranspose := Axis.Transpose;
  LLocalFrustum := AFrustum;
  LLocalFrustum.Origin := (AFrustum.Origin - Origin) * LTranspose;
  LLocalFrustum.Axis := AFrustum.Axis * LTranspose;
  LLocalFrustum.ToClippedPoints(LClipFractions, LClipPoints);

  // test outer four edges of the clipped frustum
  for LIndex := 0 to 3 do
  begin
    LP1 := LIndex;
    LP2 := 4 + LIndex;
    AddLocalLineToProjectionBoundsSetCull(LClipPoints[LP1], LClipPoints[LP2], LClipPointCull[LP1],
      LClipPointCull[LP2], AProjectionBounds);
  end;

  // get cull bits for the clipped frustum
  LOutside := LClipPointCull[0] or LClipPointCull[1] or LClipPointCull[2] or LClipPointCull[3] or
    LClipPointCull[4] or LClipPointCull[5] or LClipPointCull[6] or LClipPointCull[7];
  LNearCull := LClipPointCull[0] and LClipPointCull[1] and LClipPointCull[2] and LClipPointCull[3];
  LFarCull := LClipPointCull[4] and LClipPointCull[5] and LClipPointCull[6] and LClipPointCull[7];

  // if the clipped frustum is not completely inside this frustum
  if LOutside <> 0 then
  begin
    // test the remaining edges of the clipped frustum
    if (LNearCull = 0) and (LLocalFrustum.DNear > 0) then
      for LIndex := 0 to 3 do
      begin
        LP1 := LIndex;
        LP2 := (LIndex + 1) and 3;
        AddLocalLineToProjectionBoundsUseCull(LClipPoints[LP1], LClipPoints[LP2], LClipPointCull[LP1],
          LClipPointCull[LP2], AProjectionBounds);
      end;
    if LFarCull = 0 then
      for LIndex := 0 to 3 do
      begin
        LP1 := 4 + LIndex;
        LP2 := 4 + ((LIndex + 1) and 3);
        AddLocalLineToProjectionBoundsUseCull(LClipPoints[LP1], LClipPoints[LP2], LClipPointCull[LP1],
          LClipPointCull[LP2], AProjectionBounds);
      end;
  end;

  // if the clipped frustum far end points are inside this frustum
  if not ((LFarCull <> 0) and ((LNearCull and LFarCull) = 0)) and
    // if the clipped frustum is not clipped to a single plane of the clip bounds
    ((LClipPlanes[0] <> LClipPlanes[1]) or (LClipPlanes[1] <> LClipPlanes[2]) or
      (LClipPlanes[2] <> LClipPlanes[3])) then
  begin
    // transform the clip box into the space of the other frustum
    LTranspose := AFrustum.Axis.Transpose;
    LLocalOrigin1 := (AClipBox.Center - AFrustum.Origin) * LTranspose;
    LLocalAxis1 := AClipBox.Axis * LTranspose;
    BoxToPoints(LLocalOrigin1, AClipBox.Extents, LLocalAxis1, LLocalPoints1);

    // cull the box corners with the other frustum
    LLeftScale := AFrustum.DLeft * AFrustum.InvFar;
    LUpScale := AFrustum.DUp * AFrustum.InvFar;
    for LIndex := 0 to 7 do
    begin
      if ((BOX_VERT_PLANES[LIndex] and LUsedClipPlanes) = 0) or (LLocalPoints1[LIndex].X <= 0) then
        LBoxPointCull[LIndex] := 1 or 2 or 4 or 8
      else
      begin
        LBoxPointCull[LIndex] := 0;
        if TGeoMath.Fabs(LLocalPoints1[LIndex].Y) > LLocalPoints1[LIndex].X * LLeftScale then
          LBoxPointCull[LIndex] := LBoxPointCull[LIndex] or (1 shl SignBitSet(LLocalPoints1[LIndex].Y));
        if TGeoMath.Fabs(LLocalPoints1[LIndex].Z) > LLocalPoints1[LIndex].X * LUpScale then
          LBoxPointCull[LIndex] := LBoxPointCull[LIndex] or (4 shl SignBitSet(LLocalPoints1[LIndex].Z));
      end;
    end;

    // transform the clip box into the space of this frustum
    LTranspose := Axis.Transpose;
    LLocalOrigin2 := (AClipBox.Center - Origin) * LTranspose;
    LLocalAxis2 := AClipBox.Axis * LTranspose;
    BoxToPoints(LLocalOrigin2, AClipBox.Extents, LLocalAxis2, LLocalPoints2);

    // the cap points of the clipped far end (AddLocalCapsToProjectionBounds reads clipPoints + 4)
    for LIndex := 0 to 3 do
    begin
      LEndPoints[LIndex] := LClipPoints[4 + LIndex];
      LEndPointCull[LIndex] := LClipPointCull[4 + LIndex];
    end;

    // clip the edges of the clip bounds to the other frustum and add the clipped edges to the projection bounds
    for LIndex := 0 to 3 do
      ClipEdge(LIndex, 4 + LIndex);
    for LIndex := 0 to 3 do
      ClipEdge(LIndex, (LIndex + 1) and 3);
    for LIndex := 0 to 3 do
      ClipEdge(4 + LIndex, 4 + ((LIndex + 1) and 3));
  end;

  // if the clipped frustum extends beyond two or more boundaries of this frustum
  if (LOutside <> 1) and (LOutside <> 2) and (LOutside <> 4) and (LOutside <> 8) then
  begin
    // transform this frustum into the space of the other frustum
    LTranspose := AFrustum.Axis.Transpose;
    LLocalOrigin1 := (Origin - AFrustum.Origin) * LTranspose;
    LLocalAxis1 := Axis * LTranspose;
    LLocalAxis1.Rows[0] := LLocalAxis1.Rows[0] * DFar;
    LLocalAxis1.Rows[1] := LLocalAxis1.Rows[1] * DLeft;
    LLocalAxis1.Rows[2] := LLocalAxis1.Rows[2] * DUp;

    // transform this frustum into the space of the clip bounds
    LTranspose := AClipBox.Axis.Transpose;
    LLocalOrigin2 := (Origin - AClipBox.Center) * LTranspose;
    LLocalAxis2 := Axis * LTranspose;
    LLocalAxis2.Rows[0] := LLocalAxis2.Rows[0] * DFar;
    LLocalAxis2.Rows[1] := LLocalAxis2.Rows[1] * DLeft;
    LLocalAxis2.Rows[2] := LLocalAxis2.Rows[2] * DUp;

    LClipBounds.Mins := -AClipBox.Extents;
    LClipBounds.Maxs := AClipBox.Extents;

    // test the outer edges of this frustum for intersection with both the other frustum and the clip bounds
    if ((LOutside and 2) <> 0) and ((LOutside and 8) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin1,
        LLocalAxis1.Rows[0] - LLocalAxis1.Rows[1] - LLocalAxis1.Rows[2], LS1, LS2);
      if (LS1 <= LS2) and (LS1 >= 0) then
      begin
        BoundsRayIntersection(LClipBounds, LLocalOrigin2,
          LLocalAxis2.Rows[0] - LLocalAxis2.Rows[1] - LLocalAxis2.Rows[2], LT1, LT2);
        if (LT1 <= LT2) and (LT2 > LS1) and (LT1 < LS2) then
        begin
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS1 * DFar, -1.0, -1.0));
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS2 * DFar, -1.0, -1.0));
        end;
      end;
    end;
    if ((LOutside and 2) <> 0) and ((LOutside and 4) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin1,
        LLocalAxis1.Rows[0] - LLocalAxis1.Rows[1] + LLocalAxis1.Rows[2], LS1, LS2);
      if (LS1 <= LS2) and (LS1 >= 0) then
      begin
        BoundsRayIntersection(LClipBounds, LLocalOrigin2,
          LLocalAxis2.Rows[0] - LLocalAxis2.Rows[1] + LLocalAxis2.Rows[2], LT1, LT2);
        if (LT1 <= LT2) and (LT2 > LS1) and (LT1 < LS2) then
        begin
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS1 * DFar, -1.0, 1.0));
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS2 * DFar, -1.0, 1.0));
        end;
      end;
    end;
    if ((LOutside and 1) <> 0) and ((LOutside and 8) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin1,
        LLocalAxis1.Rows[0] + LLocalAxis1.Rows[1] - LLocalAxis1.Rows[2], LS1, LS2);
      if (LS1 <= LS2) and (LS1 >= 0) then
      begin
        BoundsRayIntersection(LClipBounds, LLocalOrigin2,
          LLocalAxis2.Rows[0] + LLocalAxis2.Rows[1] - LLocalAxis2.Rows[2], LT1, LT2);
        if (LT1 <= LT2) and (LT2 > LS1) and (LT1 < LS2) then
        begin
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS1 * DFar, 1.0, -1.0));
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS2 * DFar, 1.0, -1.0));
        end;
      end;
    end;
    if ((LOutside and 1) <> 0) and ((LOutside and 2) <> 0) then
    begin
      AFrustum.LocalRayIntersection(LLocalOrigin1,
        LLocalAxis1.Rows[0] + LLocalAxis1.Rows[1] + LLocalAxis1.Rows[2], LS1, LS2);
      if (LS1 <= LS2) and (LS1 >= 0) then
      begin
        BoundsRayIntersection(LClipBounds, LLocalOrigin2,
          LLocalAxis2.Rows[0] + LLocalAxis2.Rows[1] + LLocalAxis2.Rows[2], LT1, LT2);
        if (LT1 <= LT2) and (LT2 > LS1) and (LT1 < LS2) then
        begin
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS1 * DFar, 1.0, 1.0));
          AProjectionBounds.AddPoint(TGeoVec3.Make(LS2 * DFar, 1.0, 1.0));
        end;
      end;
    end;
  end;
  Result := True;
end;

end.
