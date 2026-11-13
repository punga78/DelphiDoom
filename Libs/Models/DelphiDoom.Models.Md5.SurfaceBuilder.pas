{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the deformed surface of a mesh         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp   }
{  (idMD5Mesh::ParseMesh deform info, idMD5Mesh::UpdateSurface). Copyright (C) }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.SurfaceBuilder;

interface

uses
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Triangles,
  DelphiDoom.Models.Static.Deform.Types;

type
  /// <summary>
  ///   Gives the triangles of a mesh of an MD5 model for a pose, with normals and tangents:
  ///   the deform info is built once (as ParseMesh does) and every call is UpdateSurface. The
  ///   material is only the name that the mesh has. The mesh is not owned: it is a reference.
  /// </summary>
  TMd5SurfaceBuilder = class
  strict private
    FMesh: IMd5Mesh;
    FDeformInfo: TStaticDeformInfo;
  public
    /// <summary>
    ///   Builds the deform info of the mesh (R_BuildDeformInfo). AUseUnsmoothedTangents is
    ///   shader->UseUnsmoothedTangents(): the material is not looked up here.
    /// </summary>
    constructor Create(const AMesh: IMd5Mesh; const AReferenceJoints: TArray<TMd5JointMat>;
      const AUseUnsmoothedTangents: Boolean);
    /// <summary>
    ///   idMD5Mesh::UpdateSurface for the absolute matrices of the joints: positions from the
    ///   weights (scaled when ASkinScale is not zero: SHADERPARM_MD5_SKINSCALE), the mirror seam
    ///   vertexes replicated and, when ADeriveTangents, R_DeriveTangents (the engine with
    ///   r_useDeferredTangents off). GenerateNormals is False: the normals are derived.
    /// </summary>
    function Build(const AJoints: TArray<TMd5JointMat>; const ASkinScale: Single;
      const ADeriveTangents: Boolean = True): TStaticTriangles;
    /// <summary>The name of the material of the mesh (the shader of the md5mesh)</summary>
    function MaterialName: AnsiString;
    property DeformInfo: TStaticDeformInfo read FDeformInfo;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Models.Static.DeformBuilder,
  DelphiDoom.Models.Static.TangentDeriver;

{ TMd5SurfaceBuilder }

constructor TMd5SurfaceBuilder.Create(const AMesh: IMd5Mesh; const AReferenceJoints: TArray<TMd5JointMat>;
  const AUseUnsmoothedTangents: Boolean);
var
  LVerts: TArray<TStaticDrawVert>;
  LPositions: TArray<TIdVec3>;
  LIndex: Integer;
begin
  inherited Create;
  FMesh := AMesh;
  // ParseMesh: the vertexes of the deform info are in the pose of the file
  LPositions := AMesh.TransformVerts(AReferenceJoints);
  SetLength(LVerts, AMesh.NumVerts);
  for LIndex := 0 to High(LVerts) do
  begin
    LVerts[LIndex].Clear;
    LVerts[LIndex].St := AMesh.TexCoords[LIndex];
    LVerts[LIndex].Xyz := LPositions[LIndex];
  end;
  FDeformInfo := TStaticDeformBuilder.Build(LVerts, AMesh.Triangles, AUseUnsmoothedTangents);
end;

function TMd5SurfaceBuilder.MaterialName: AnsiString;
begin
  Result := FMesh.ShaderName;
end;

function TMd5SurfaceBuilder.Build(const AJoints: TArray<TMd5JointMat>; const ASkinScale: Single;
  const ADeriveTangents: Boolean): TStaticTriangles;
var
  LPositions: TArray<TIdVec3>;
  LVerts: TArray<TStaticDrawVert>;
  LIndex, LBase: Integer;
begin
  SetLength(LVerts, FDeformInfo.NumOutputVerts);
  for LIndex := 0 to FDeformInfo.NumSourceVerts - 1 do
  begin
    LVerts[LIndex].Clear;
    LVerts[LIndex].St := FMesh.TexCoords[LIndex];
  end;
  if ASkinScale <> 0 then
    LPositions := FMesh.TransformScaledVerts(AJoints, ASkinScale)
  else
    LPositions := FMesh.TransformVerts(AJoints);
  for LIndex := 0 to FDeformInfo.NumSourceVerts - 1 do
    LVerts[LIndex].Xyz := LPositions[LIndex];
  // replicate the mirror seam vertexes
  LBase := FDeformInfo.NumOutputVerts - FDeformInfo.NumMirroredVerts;
  for LIndex := 0 to FDeformInfo.NumMirroredVerts - 1 do
    LVerts[LBase + LIndex] := LVerts[FDeformInfo.MirroredVerts[LIndex]];
  if ADeriveTangents then
    TStaticTangentDeriver.DeriveTangents(LVerts, FDeformInfo.Indexes, FDeformInfo.DupVerts,
      FDeformInfo.DominantTris);
  Result.Verts := LVerts;
  Result.Indexes := Copy(FDeformInfo.Indexes);
  Result.GenerateNormals := False;
end;

end.
