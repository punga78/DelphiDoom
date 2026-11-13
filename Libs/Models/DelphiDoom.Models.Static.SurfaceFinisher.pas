{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the cleanup of the triangles of a surface   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\tr_trisurf.cpp  }
{  (R_CleanupTriangles, R_RemoveDegenerateTriangles, R_ReverseTriangles).      }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This unit }
{  is derived from the Doom 3 GPL source code and is therefore available       }
{  under the GNU General Public License, version 3, with the additional terms  }
{  of the Doom 3 Source Code License (see README.md of Libs\IdLib); the        }
{  repository as a whole is GPL v2 or later.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.SurfaceFinisher;

interface

uses
  DelphiDoom.Models.Static.Triangles;

type
  /// <summary>
  ///   What a static surface goes through when the model is finished: the degenerate triangles
  ///   go away, the vertexes used by both texture polarities are split, then the normals and
  ///   tangents are derived. It has no state. Not ported: the silhouette edges.
  /// </summary>
  TStaticSurfaceFinisher = class
  public
    /// <summary>
    ///   R_CleanupTriangles: ACreateNormals derives normals and tangents (R_DeriveTangents),
    ///   otherwise the normals are kept and the tangents are derived without them;
    ///   AUseUnsmoothedTangents uses the dominant triangle of each vertex. The indexes must be
    ///   in range (EStaticModelException). GenerateNormals is kept as it is.
    /// </summary>
    class function Cleanup(const ATriangles: TStaticTriangles; const ACreateNormals,
      AUseUnsmoothedTangents: Boolean): TStaticTriangles; static;
    /// <summary>R_ReverseTriangles: the normals flip and the first two indexes of each triangle swap</summary>
    class function Reverse(const ATriangles: TStaticTriangles): TStaticTriangles; static;
  end;

implementation

uses
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Deform.Types,
  DelphiDoom.Models.Static.DeformBuilder,
  DelphiDoom.Models.Static.TangentDeriver;

{ TStaticSurfaceFinisher }

class function TStaticSurfaceFinisher.Cleanup(const ATriangles: TStaticTriangles; const ACreateNormals,
  AUseUnsmoothedTangents: Boolean): TStaticTriangles;
var
  LVerts: TArray<TStaticDrawVert>;
  LIndexes, LSilIndexes, LMirrored, LDupVerts: TArray<Integer>;
  LDominant: TArray<TStaticDominantTri>;
  LIndex, LKept: Integer;
  LA, LB, LC: Integer;
begin
  TStaticDeformBuilder.RangeCheckIndexes(Length(ATriangles.Verts), ATriangles.Indexes);
  LVerts := Copy(ATriangles.Verts);
  LIndexes := Copy(ATriangles.Indexes);
  LSilIndexes := TStaticDeformBuilder.CreateSilIndexes(LVerts, LIndexes);

  // R_RemoveDegenerateTriangles: a triangle with two vertexes at the same position goes away
  LKept := 0;
  LIndex := 0;
  while LIndex + 2 < Length(LIndexes) do
  begin
    LA := LSilIndexes[LIndex];
    LB := LSilIndexes[LIndex + 1];
    LC := LSilIndexes[LIndex + 2];
    if not ((LA = LB) or (LA = LC) or (LB = LC)) then
    begin
      LIndexes[LKept] := LIndexes[LIndex];
      LIndexes[LKept + 1] := LIndexes[LIndex + 1];
      LIndexes[LKept + 2] := LIndexes[LIndex + 2];
      LSilIndexes[LKept] := LA;
      LSilIndexes[LKept + 1] := LB;
      LSilIndexes[LKept + 2] := LC;
      Inc(LKept, 3);
    end;
    Inc(LIndex, 3);
  end;
  SetLength(LIndexes, LKept);
  SetLength(LSilIndexes, LKept);

  // bust vertexes that share a mirrored edge into separate vertexes
  TStaticDeformBuilder.SplitMirroredVertexes(LVerts, LIndexes, LMirrored);
  LDupVerts := TStaticDeformBuilder.FindDupVerts(Length(LVerts), LIndexes, LSilIndexes);

  if AUseUnsmoothedTangents then
  begin
    LDominant := TStaticDeformBuilder.FindDominantTris(LVerts, LIndexes);
    TStaticTangentDeriver.DeriveTangents(LVerts, LIndexes, LDupVerts, LDominant);
  end
  else if not ACreateNormals then
  begin
    TStaticTangentDeriver.DeriveFacePlanes(LVerts, LIndexes);
    TStaticTangentDeriver.DeriveTangentsWithoutNormals(LVerts, LIndexes);
  end
  else
    TStaticTangentDeriver.DeriveTangents(LVerts, LIndexes, LDupVerts, nil);

  Result.Verts := LVerts;
  Result.Indexes := LIndexes;
  Result.GenerateNormals := ATriangles.GenerateNormals;
end;

class function TStaticSurfaceFinisher.Reverse(const ATriangles: TStaticTriangles): TStaticTriangles;
var
  LIndex, LTemp: Integer;
  LOrigin: TIdVec3;
begin
  LOrigin.Zero;
  Result.Verts := Copy(ATriangles.Verts);
  Result.Indexes := Copy(ATriangles.Indexes);
  Result.GenerateNormals := ATriangles.GenerateNormals;
  // flip the normal on each vertex
  for LIndex := 0 to High(Result.Verts) do
    Result.Verts[LIndex].Normal := LOrigin - Result.Verts[LIndex].Normal;
  // flip the index order to make them back sided
  LIndex := 0;
  while LIndex + 2 < Length(Result.Indexes) do
  begin
    LTemp := Result.Indexes[LIndex];
    Result.Indexes[LIndex] := Result.Indexes[LIndex + 1];
    Result.Indexes[LIndex + 1] := LTemp;
    Inc(LIndex, 3);
  end;
end;

end.
