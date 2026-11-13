{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - deformable surfaces: shared types           }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\tr_local.h      }
{  (deformInfo_t) and idlib\geometry\DrawVert.h (dominantTri_s). Copyright     }
{  (C) 1999-2011 id Software LLC, a ZeniMax Media company. This unit is        }
{  derived from the Doom 3 GPL source code and is therefore available under    }
{  the GNU General Public License, version 3, with the additional terms of     }
{  the Doom 3 Source Code License (see README.md of Libs\IdLib); the           }
{  repository as a whole is GPL v2 or later.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Deform.Types;

interface

type
  /// <summary>
  ///   The largest triangle that uses a vertex, with the scales that normalise its normal and
  ///   tangents (dominantTri_s)
  /// </summary>
  TStaticDominantTri = record
    V2: Integer;
    V3: Integer;
    /// <summary>Tangent, bitangent and normal scales (normalizationScale[0..2])</summary>
    NormalizationScale: array[0..2] of Single;
  end;

  /// <summary>
  ///   What a surface that deforms every frame keeps from its construction (deformInfo_t): the
  ///   indexes, the silhouette remap, the vertexes that are shared by mirrored texture polarities,
  ///   the vertexes with the same position and the dominant triangles. Not ported: the silhouette
  ///   edges (<c>R_IdentifySilEdges</c>, they only serve the shadow volumes).
  /// </summary>
  TStaticDeformInfo = record
    /// <summary>The vertexes the mesh gives (before the mirror seam is duplicated)</summary>
    NumSourceVerts: Integer;
    /// <summary>The vertexes the surface has after the duplication of the mirrored ones</summary>
    NumOutputVerts: Integer;
    Indexes: TArray<Integer>;
    /// <summary>The index of the first vertex with the same position, for every index</summary>
    SilIndexes: TArray<Integer>;
    /// <summary>The source vertex of every duplicated one, in order (the last NumMirroredVerts vertexes)</summary>
    MirroredVerts: TArray<Integer>;
    /// <summary>Pairs: a vertex and the first one with the same position (dupVerts)</summary>
    DupVerts: TArray<Integer>;
    /// <summary>One for each vertex when the tangents are not smoothed, else empty</summary>
    DominantTris: TArray<TStaticDominantTri>;
    function NumIndexes: Integer;
    function NumMirroredVerts: Integer;
    function NumDupVerts: Integer;
  end;

resourcestring
  SStaticDeformIndexCount = 'The surface has a number of indexes that is not a multiple of 3';
  SStaticDeformIndexRange = 'The surface has an index out of range';

implementation

{ TStaticDeformInfo }

function TStaticDeformInfo.NumIndexes: Integer;
begin
  Result := Length(Indexes);
end;

function TStaticDeformInfo.NumMirroredVerts: Integer;
begin
  Result := Length(MirroredVerts);
end;

function TStaticDeformInfo.NumDupVerts: Integer;
begin
  Result := Length(DupVerts) div 2;
end;

end.
