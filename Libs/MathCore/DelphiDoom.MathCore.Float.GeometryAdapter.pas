{******************************************************************************}
{                                                                              }
{  DelphiDoom: MathCore (floating point) - adapter between TIdVec3/TIdMat3     }
{  and the geometry types TGeoVec3/TGeoMat3 of Libs\Geometry                   }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). The two vector types have the same layout (three Singles) and the   }
{  two matrices the same (three rows); they were written for different         }
{  libraries (IdLib/MathCore the math, Geometry the collision model) and stay   }
{  two until Collision is moved to TIdVec3: this unit is the one place that    }
{  knows both.                                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MathCore.Float.GeometryAdapter;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3;

type
  /// <summary>Converts the vector and matrix types of MathCore to those of Geometry and back (copies)</summary>
  TIdGeometryAdapter = class sealed
  public
    class function ToGeo(const AVector: TIdVec3): TGeoVec3; overload; static;
    class function ToGeo(const AMatrix: TIdMat3): TGeoMat3; overload; static;
    class function ToId(const AVector: TGeoVec3): TIdVec3; overload; static;
    class function ToId(const AMatrix: TGeoMat3): TIdMat3; overload; static;
  end;

implementation

{ TIdGeometryAdapter }

class function TIdGeometryAdapter.ToGeo(const AVector: TIdVec3): TGeoVec3;
begin
  Result.X := AVector.X;
  Result.Y := AVector.Y;
  Result.Z := AVector.Z;
end;

class function TIdGeometryAdapter.ToGeo(const AMatrix: TIdMat3): TGeoMat3;
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    Result.Rows[LRow] := ToGeo(AMatrix.Rows[LRow]);
end;

class function TIdGeometryAdapter.ToId(const AVector: TGeoVec3): TIdVec3;
begin
  Result.X := AVector.X;
  Result.Y := AVector.Y;
  Result.Z := AVector.Z;
end;

class function TIdGeometryAdapter.ToId(const AMatrix: TGeoMat3): TIdMat3;
var
  LRow: Integer;
begin
  for LRow := 0 to 2 do
    Result.Rows[LRow] := ToId(AMatrix.Rows[LRow]);
end;

end.
