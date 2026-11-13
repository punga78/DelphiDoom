{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: triangles and surfaces       }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\tr_trisurf.cpp  }
{  (R_BoundTriSurf, R_MergeTriangles) and renderer\Model_local.h               }
{  (modelSurface_t). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Triangles;

interface

uses
  System.SysUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Static.Types;

type
  /// <summary>
  ///   The geometry of a surface (the part of srfTriangles_t that the loaders fill): vertexes and
  ///   indexes of triangles. A value: the arrays are shared until written. Not ported: the derived
  ///   data of the renderer (silhouette edges, planes, shadow vertexes, caches).
  /// </summary>
  TStaticTriangles = record
    Verts: TArray<TStaticDrawVert>;
    Indexes: TArray<Integer>;
    /// <summary>The normals have to be derived (srfTriangles_t::generateNormals)</summary>
    GenerateNormals: Boolean;
    function NumVerts: Integer;
    function NumIndexes: Integer;
    /// <summary>R_BoundTriSurf: the box of the positions (cleared if there are no vertexes)</summary>
    function CalcBounds: TGeoBounds;
    /// <summary>
    ///   R_MergeTriangles: the vertexes of the first, then those of the second; the indexes of the
    ///   second move by the vertexes of the first. No cleanup: duplicated vertexes stay. As in the
    ///   original the result has GenerateNormals False (a defect of the C++, kept).
    /// </summary>
    class function Merge(const AFirst, ASecond: TStaticTriangles): TStaticTriangles; static;
  end;

  /// <summary>A surface of a model (modelSurface_t): the id, the name of the material and the triangles</summary>
  TStaticSurface = record
    Id: Integer;
    /// <summary>The name of the material: the model does not look the material up</summary>
    MaterialName: AnsiString;
    Triangles: TStaticTriangles;
    /// <summary>False until a loader gives the surface its geometry (geometry != NULL)</summary>
    HasGeometry: Boolean;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3;

{ TStaticTriangles }

function TStaticTriangles.NumVerts: Integer;
begin
  Result := Length(Verts);
end;

function TStaticTriangles.NumIndexes: Integer;
begin
  Result := Length(Indexes);
end;

function TStaticTriangles.CalcBounds: TGeoBounds;
var
  LIndex: Integer;
begin
  Result := TGeoBounds.Cleared;
  for LIndex := 0 to High(Verts) do
    Result.AddPoint(TGeoVec3.Make(Verts[LIndex].Xyz.X, Verts[LIndex].Xyz.Y, Verts[LIndex].Xyz.Z));
end;

class function TStaticTriangles.Merge(const AFirst, ASecond: TStaticTriangles): TStaticTriangles;
var
  LIndex, LBase: Integer;
begin
  LBase := Length(AFirst.Verts);
  SetLength(Result.Verts, LBase + Length(ASecond.Verts));
  for LIndex := 0 to High(AFirst.Verts) do
    Result.Verts[LIndex] := AFirst.Verts[LIndex];
  for LIndex := 0 to High(ASecond.Verts) do
    Result.Verts[LBase + LIndex] := ASecond.Verts[LIndex];
  SetLength(Result.Indexes, Length(AFirst.Indexes) + Length(ASecond.Indexes));
  for LIndex := 0 to High(AFirst.Indexes) do
    Result.Indexes[LIndex] := AFirst.Indexes[LIndex];
  for LIndex := 0 to High(ASecond.Indexes) do
    Result.Indexes[Length(AFirst.Indexes) + LIndex] := LBase + ASecond.Indexes[LIndex];
  // R_MergeSurfaceList allocates a cleared surface and never copies generateNormals
  Result.GenerateNormals := False;
end;

end.
