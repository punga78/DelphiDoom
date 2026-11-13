{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - bounds and spheres of a rotating    }
{  point, box or sphere                                                        }
{                                                                              }
{  Port of BoundsForPointRotation, idBounds::FromPointRotation,                }
{  idBounds::FromBoundsRotation (idlib\bv\Bounds.cpp) and of                   }
{  idSphere::FromPointRotation, idSphere::FromSphereRotation                   }
{  (idlib\bv\Sphere.h) of the Doom 3 GPL Source Code. Copyright (C)            }
{  1999-2011 id Software LLC, a ZeniMax Media company. Based on the Doom 3     }
{  GPL Source Code (id Software).                                              }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.BoundsRotation;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Sphere, DelphiDoom.MathCore.Float.Rotation;

type
  /// <summary>
  ///   The members of idBounds and idSphere that take an idRotation. They live here because the
  ///   rotation is a MathCore type (TIdRotation, on TIdVec3) and the volumes are Geometry types
  ///   (TGeoBounds, TGeoSphere): Geometry does not know MathCore. The rotation is a variable
  ///   parameter because it caches its matrix.
  /// </summary>
  TIdBoundsRotation = class sealed
  public
    /// <summary>BoundsForPointRotation: the bounds of the arc of a point, for rotations below 180 degrees</summary>
    class function ForPointRotation(const AStart: TGeoVec3; var ARotation: TIdRotation): TGeoBounds; static;
    /// <summary>
    ///   idBounds::FromPointRotation: the arc bounds below 180 degrees, otherwise the cube of
    ///   the distance to the rotation origin ("these bounds are usually way larger")
    /// </summary>
    class function FromPointRotation(const APoint: TGeoVec3; var ARotation: TIdRotation): TGeoBounds; static;
    /// <summary>
    ///   idBounds::FromBoundsRotation. At 180 degrees or more the original takes half the size
    ///   (not the centre) of the box as the point: kept
    /// </summary>
    class function FromBoundsRotation(const ABounds: TGeoBounds; const AOrigin: TGeoVec3;
      const AAxis: TGeoMat3; var ARotation: TIdRotation): TGeoBounds; static;
    /// <summary>idSphere::FromPointRotation</summary>
    class function SphereFromPointRotation(const APoint: TGeoVec3; var ARotation: TIdRotation): TGeoSphere; static;
    /// <summary>idSphere::FromSphereRotation</summary>
    class function SphereFromSphereRotation(const ASphere: TGeoSphere; const AStart: TGeoVec3;
      var ARotation: TIdRotation): TGeoSphere; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Geometry.FloatMath, DelphiDoom.MathCore.Float.GeometryAdapter;

function MinSingle(const AX, AY: Single): Single;
begin
  if AX < AY then
    Result := AX
  else
    Result := AY;
end;

function MaxSingle(const AX, AY: Single): Single;
begin
  if AX > AY then
    Result := AX
  else
    Result := AY;
end;

function RotatePoint(const APoint: TGeoVec3; var ARotation: TIdRotation): TGeoVec3;
begin
  Result := TIdGeometryAdapter.ToGeo(ARotation.Rotate(TIdGeometryAdapter.ToId(APoint)));
end;

{ TIdBoundsRotation }

class function TIdBoundsRotation.ForPointRotation(const AStart: TGeoVec3;
  var ARotation: TIdRotation): TGeoBounds;
var
  LIndex: Integer;
  LRadiusSqr: Single;
  LV1: TGeoVec3;
  LV2: TGeoVec3;
  LOrigin: TGeoVec3;
  LAxis: TGeoVec3;
  LEnd: TGeoVec3;
  LRotationOrigin: TGeoVec3;
  LRoot: Single;
begin
  LEnd := RotatePoint(AStart, ARotation);
  LAxis := TIdGeometryAdapter.ToGeo(ARotation.Vector);
  LRotationOrigin := TIdGeometryAdapter.ToGeo(ARotation.Origin);
  LOrigin := LRotationOrigin + LAxis * LAxis.Dot(AStart - LRotationOrigin);
  LRadiusSqr := (AStart - LOrigin).LengthSqr;
  LV1 := (AStart - LOrigin).Cross(LAxis);
  LV2 := (LEnd - LOrigin).Cross(LAxis);
  Result.Mins.Zero;
  Result.Maxs.Zero;
  for LIndex := 0 to 2 do
  begin
    // if the derivative changes sign along this axis during the rotation from start to end
    if ((LV1[LIndex] > 0) and (LV2[LIndex] < 0)) or ((LV1[LIndex] < 0) and (LV2[LIndex] > 0)) then
    begin
      LRoot := TGeoMath.Sqrt(LRadiusSqr * (1.0 - LAxis[LIndex] * LAxis[LIndex]));
      if (0.5 * (AStart[LIndex] + LEnd[LIndex]) - LOrigin[LIndex]) > 0 then
      begin
        Result.Mins[LIndex] := MinSingle(AStart[LIndex], LEnd[LIndex]);
        Result.Maxs[LIndex] := LOrigin[LIndex] + LRoot;
      end
      else
      begin
        Result.Mins[LIndex] := LOrigin[LIndex] - LRoot;
        Result.Maxs[LIndex] := MaxSingle(AStart[LIndex], LEnd[LIndex]);
      end;
    end
    else if AStart[LIndex] > LEnd[LIndex] then
    begin
      Result.Mins[LIndex] := LEnd[LIndex];
      Result.Maxs[LIndex] := AStart[LIndex];
    end
    else
    begin
      Result.Mins[LIndex] := AStart[LIndex];
      Result.Maxs[LIndex] := LEnd[LIndex];
    end;
  end;
end;

class function TIdBoundsRotation.FromPointRotation(const APoint: TGeoVec3;
  var ARotation: TIdRotation): TGeoBounds;
var
  LRadius: Single;
begin
  if Abs(ARotation.Angle) < 180.0 then
    Exit(ForPointRotation(APoint, ARotation));
  LRadius := (APoint - TIdGeometryAdapter.ToGeo(ARotation.Origin)).Length;
  Result.Mins.SetValues(-LRadius, -LRadius, -LRadius);
  Result.Maxs.SetValues(LRadius, LRadius, LRadius);
end;

class function TIdBoundsRotation.FromBoundsRotation(const ABounds: TGeoBounds; const AOrigin: TGeoVec3;
  const AAxis: TGeoMat3; var ARotation: TIdRotation): TGeoBounds;
var
  LIndex: Integer;
  LRadius: Single;
  LPoint: TGeoVec3;
begin
  if Abs(ARotation.Angle) < 180.0 then
  begin
    Result := ForPointRotation(ABounds.Mins * AAxis + AOrigin, ARotation);
    for LIndex := 1 to 7 do
    begin
      if ((LIndex xor (LIndex shr 1)) and 1) = 0 then
        LPoint.X := ABounds.Mins.X
      else
        LPoint.X := ABounds.Maxs.X;
      if ((LIndex shr 1) and 1) = 0 then
        LPoint.Y := ABounds.Mins.Y
      else
        LPoint.Y := ABounds.Maxs.Y;
      if ((LIndex shr 2) and 1) = 0 then
        LPoint.Z := ABounds.Mins.Z
      else
        LPoint.Z := ABounds.Maxs.Z;
      Result.AddBounds(ForPointRotation(LPoint * AAxis + AOrigin, ARotation));
    end;
    Exit;
  end;
  LPoint := (ABounds.Maxs - ABounds.Mins) * 0.5;
  LRadius := (ABounds.Maxs - LPoint).Length + (LPoint - TIdGeometryAdapter.ToGeo(ARotation.Origin)).Length;
  Result.Mins.SetValues(-LRadius, -LRadius, -LRadius);
  Result.Maxs.SetValues(LRadius, LRadius, LRadius);
end;

class function TIdBoundsRotation.SphereFromPointRotation(const APoint: TGeoVec3;
  var ARotation: TIdRotation): TGeoSphere;
var
  LEnd: TGeoVec3;
begin
  LEnd := RotatePoint(APoint, ARotation);
  Result.Origin := (APoint + LEnd) * 0.5;
  Result.Radius := TGeoMath.Sqrt(0.5 * (LEnd - APoint).LengthSqr);
end;

class function TIdBoundsRotation.SphereFromSphereRotation(const ASphere: TGeoSphere; const AStart: TGeoVec3;
  var ARotation: TIdRotation): TGeoSphere;
var
  LEnd: TGeoVec3;
begin
  LEnd := RotatePoint(ASphere.Origin, ARotation);
  Result.Origin := AStart + (ASphere.Origin + LEnd) * 0.5;
  Result.Radius := TGeoMath.Sqrt(0.5 * (LEnd - ASphere.Origin).LengthSqr) + ASphere.Radius;
end;

end.
