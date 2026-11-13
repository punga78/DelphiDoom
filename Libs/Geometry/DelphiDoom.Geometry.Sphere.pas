{******************************************************************************}
{                                                                              }
{  DelphiDoom: geometry library - the sphere (idSphere)                        }
{                                                                              }
{  Port of idSphere (idlib\bv\Sphere.h and Sphere.cpp) of the Doom 3 GPL       }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Based on the Doom 3 GPL Source Code (id Software).                 }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Geometry.Sphere;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane;

type
  /// <summary>
  ///   A sphere (idSphere), 16 bytes: origin and radius. A negative radius is the cleared
  ///   (inside out) sphere. The rotation members of the original (FromPointRotation,
  ///   FromSphereRotation) take an idRotation, a type of MathCore: they are in
  ///   <c>TIdBoundsRotation</c> (<c>DelphiDoom.MathCore.Float.BoundsRotation</c>).
  /// </summary>
  TGeoSphere = record
    Origin: TGeoVec3;
    Radius: Single;
  public
    class function Make(const AOrigin: TGeoVec3; ARadius: Single): TGeoSphere; overload; static;
    /// <summary>A sphere with radius 0 at the point</summary>
    class function Make(const APoint: TGeoVec3): TGeoSphere; overload; static;
    /// <summary>Inside out sphere: origin zero, radius -1</summary>
    procedure Clear;
    procedure Zero;
    function IsCleared: Boolean;
    function Compare(const ASphere: TGeoSphere): Boolean; overload;
    function Compare(const ASphere: TGeoSphere; AEpsilon: Single): Boolean; overload;
    /// <summary>Grows the sphere to contain the point; true when it grew</summary>
    function AddPoint(const APoint: TGeoVec3): Boolean;
    /// <summary>Grows the sphere to contain the other sphere; true when it grew</summary>
    function AddSphere(const ASphere: TGeoSphere): Boolean;
    function Expand(ADelta: Single): TGeoSphere;
    procedure ExpandSelf(ADelta: Single);
    function Translate(const ATranslation: TGeoVec3): TGeoSphere;
    procedure TranslateSelf(const ATranslation: TGeoVec3);
    /// <summary>Signed distance of the sphere from the plane, 0 when the plane crosses it</summary>
    function PlaneDistance(const APlane: TGeoPlane): Single;
    /// <summary>PLANESIDE_FRONT, _BACK or _CROSS</summary>
    function PlaneSide(const APlane: TGeoPlane; AEpsilon: Single = 0.1): Integer;
    /// <summary>Includes touching</summary>
    function ContainsPoint(const APoint: TGeoVec3): Boolean;
    /// <summary>Includes touching</summary>
    function IntersectsSphere(const ASphere: TGeoSphere): Boolean;
    /// <summary>True when the segment between start and end meets the sphere</summary>
    function LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
    /// <summary>
    ///   The ray meets the sphere at start + dir * scale1 and start + dir * scale2, in both
    ///   directions from the start. The original computes in double with float inputs
    /// </summary>
    function RayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
    /// <summary>Tight sphere for a point set: centre of the bounds, radius to the farthest point</summary>
    procedure FromPoints(const APoints: array of TGeoVec3);
    procedure FromPointTranslation(const APoint, ATranslation: TGeoVec3);
    procedure FromSphereTranslation(const ASphere: TGeoSphere; const AStart, ATranslation: TGeoVec3);
    procedure AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single);
  end;

implementation

uses
  DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath;

{ TGeoSphere }

class function TGeoSphere.Make(const AOrigin: TGeoVec3; ARadius: Single): TGeoSphere;
begin
  Result.Origin := AOrigin;
  Result.Radius := ARadius;
end;

class function TGeoSphere.Make(const APoint: TGeoVec3): TGeoSphere;
begin
  Result.Origin := APoint;
  Result.Radius := 0;
end;

procedure TGeoSphere.Clear;
begin
  Origin.Zero;
  Radius := -1;
end;

procedure TGeoSphere.Zero;
begin
  Origin.Zero;
  Radius := 0;
end;

function TGeoSphere.IsCleared: Boolean;
begin
  Result := Radius < 0;
end;

function TGeoSphere.Compare(const ASphere: TGeoSphere): Boolean;
begin
  Result := Origin.Compare(ASphere.Origin) and (Radius = ASphere.Radius);
end;

function TGeoSphere.Compare(const ASphere: TGeoSphere; AEpsilon: Single): Boolean;
begin
  Result := Origin.Compare(ASphere.Origin, AEpsilon) and (TGeoMath.Fabs(Radius - ASphere.Radius) <= AEpsilon);
end;

function TGeoSphere.AddPoint(const APoint: TGeoVec3): Boolean;
var
  LRadiusSqr: Single;
  LDistance: Single;
  LOffset: TGeoVec3;
begin
  if Radius < 0 then
  begin
    Origin := APoint;
    Radius := 0;
    Exit(True);
  end;
  LOffset := APoint - Origin;
  LRadiusSqr := LOffset.LengthSqr;
  if LRadiusSqr > Radius * Radius then
  begin
    LDistance := TGeoMath.Sqrt(LRadiusSqr);
    Origin := Origin + LOffset * 0.5 * (1.0 - Radius / LDistance);
    Radius := Radius + 0.5 * (LDistance - Radius);
    Exit(True);
  end;
  Result := False;
end;

function TGeoSphere.AddSphere(const ASphere: TGeoSphere): Boolean;
var
  LRadiusSqr: Single;
  LDistance: Single;
  LOffset: TGeoVec3;
begin
  if Radius < 0 then
  begin
    Origin := ASphere.Origin;
    Radius := ASphere.Radius;
    Exit(True);
  end;
  LOffset := ASphere.Origin - Origin;
  LRadiusSqr := LOffset.LengthSqr;
  if LRadiusSqr > (Radius + ASphere.Radius) * (Radius + ASphere.Radius) then
  begin
    LDistance := TGeoMath.Sqrt(LRadiusSqr);
    Origin := Origin + LOffset * 0.5 * (1.0 - Radius / (LDistance + ASphere.Radius));
    Radius := Radius + 0.5 * ((LDistance + ASphere.Radius) - Radius);
    Exit(True);
  end;
  Result := False;
end;

function TGeoSphere.Expand(ADelta: Single): TGeoSphere;
begin
  Result := Make(Origin, Radius + ADelta);
end;

procedure TGeoSphere.ExpandSelf(ADelta: Single);
begin
  Radius := Radius + ADelta;
end;

function TGeoSphere.Translate(const ATranslation: TGeoVec3): TGeoSphere;
begin
  Result := Make(Origin + ATranslation, Radius);
end;

procedure TGeoSphere.TranslateSelf(const ATranslation: TGeoVec3);
begin
  Origin := Origin + ATranslation;
end;

function TGeoSphere.PlaneDistance(const APlane: TGeoPlane): Single;
var
  LDistance: Single;
begin
  LDistance := APlane.Distance(Origin);
  if LDistance > Radius then
    Exit(LDistance - Radius);
  if LDistance < -Radius then
    Exit(LDistance + Radius);
  Result := 0;
end;

function TGeoSphere.PlaneSide(const APlane: TGeoPlane; AEpsilon: Single): Integer;
var
  LDistance: Single;
begin
  LDistance := APlane.Distance(Origin);
  if LDistance > Radius + AEpsilon then
    Exit(PLANESIDE_FRONT);
  if LDistance < -Radius - AEpsilon then
    Exit(PLANESIDE_BACK);
  Result := PLANESIDE_CROSS;
end;

function TGeoSphere.ContainsPoint(const APoint: TGeoVec3): Boolean;
begin
  Result := not ((APoint - Origin).LengthSqr > Radius * Radius);
end;

function TGeoSphere.IntersectsSphere(const ASphere: TGeoSphere): Boolean;
var
  LSum: Single;
begin
  LSum := ASphere.Radius + Radius;
  Result := not ((ASphere.Origin - Origin).LengthSqr > LSum * LSum);
end;

function TGeoSphere.LineIntersection(const AStart, AEnd: TGeoVec3): Boolean;
var
  LS: TGeoVec3;
  LE: TGeoVec3;
  LR: TGeoVec3;
  LA: Single;
  LRSqr: Single;
begin
  LS := AStart - Origin;
  LE := AEnd - Origin;
  LR := LE - LS;
  LA := -LS.Dot(LR);
  if LA <= 0 then
    Exit(LS.Dot(LS) < Radius * Radius);
  LRSqr := LR.Dot(LR);
  if LA >= LRSqr then
    Exit(LE.Dot(LE) < Radius * Radius);
  LR := LS + (LA / LRSqr) * LR;
  Result := LR.Dot(LR) < Radius * Radius;
end;

function TGeoSphere.RayIntersection(const AStart, ADir: TGeoVec3; out AScale1, AScale2: Single): Boolean;
var
  LA: Double;
  LB: Double;
  LC: Double;
  LD: Double;
  LSqrtD: Double;
  LP: TGeoVec3;
  LRoot: Single;
  LDiscriminant: Single;
begin
  AScale1 := 0;
  AScale2 := 0;
  LP := AStart - Origin;
  LA := ADir.Dot(ADir);
  LB := ADir.Dot(LP);
  LC := LP.Dot(LP) - Radius * Radius;
  LD := LB * LB - LC * LA;
  if LD < 0 then
    Exit(False);
  // idMath::Sqrt takes a float: the discriminant is rounded to float, the root is a float
  LDiscriminant := LD;
  LRoot := TGeoMath.Sqrt(LDiscriminant);
  LSqrtD := LRoot;
  LA := 1.0 / LA;
  AScale1 := (-LB + LSqrtD) * LA;
  AScale2 := (-LB - LSqrtD) * LA;
  Result := True;
end;

procedure TGeoSphere.FromPoints(const APoints: array of TGeoVec3);
var
  LIndex: Integer;
  LAxis: Integer;
  LMins: TGeoVec3;
  LMaxs: TGeoVec3;
  LRadiusSqr: Single;
  LDistance: Single;
begin
  // SIMDProcessor->MinMax: with no points the result is the cleared bounds
  LMins.SetValues(GEO_INFINITY, GEO_INFINITY, GEO_INFINITY);
  LMaxs.SetValues(-GEO_INFINITY, -GEO_INFINITY, -GEO_INFINITY);
  for LIndex := 0 to High(APoints) do
    for LAxis := 0 to 2 do
    begin
      if APoints[LIndex][LAxis] < LMins[LAxis] then
        LMins[LAxis] := APoints[LIndex][LAxis];
      if APoints[LIndex][LAxis] > LMaxs[LAxis] then
        LMaxs[LAxis] := APoints[LIndex][LAxis];
    end;
  Origin := (LMins + LMaxs) * 0.5;
  LRadiusSqr := 0;
  for LIndex := 0 to High(APoints) do
  begin
    LDistance := (APoints[LIndex] - Origin).LengthSqr;
    if LDistance > LRadiusSqr then
      LRadiusSqr := LDistance;
  end;
  Radius := TGeoMath.Sqrt(LRadiusSqr);
end;

procedure TGeoSphere.FromPointTranslation(const APoint, ATranslation: TGeoVec3);
begin
  Origin := APoint + 0.5 * ATranslation;
  Radius := TGeoMath.Sqrt(0.5 * ATranslation.LengthSqr);
end;

procedure TGeoSphere.FromSphereTranslation(const ASphere: TGeoSphere; const AStart, ATranslation: TGeoVec3);
begin
  Origin := AStart + ASphere.Origin + 0.5 * ATranslation;
  Radius := TGeoMath.Sqrt(0.5 * ATranslation.LengthSqr) + ASphere.Radius;
end;

procedure TGeoSphere.AxisProjection(const ADir: TGeoVec3; out AMin, AMax: Single);
var
  LDistance: Single;
begin
  LDistance := ADir.Dot(Origin);
  AMin := LDistance - Radius;
  AMax := LDistance + Radius;
end;

end.
