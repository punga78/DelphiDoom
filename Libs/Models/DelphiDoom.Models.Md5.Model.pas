{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: a model (joints, pose and meshes)      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp   }
{  (idRenderModelMD5). Copyright (C) 1999-2011 id Software LLC, a ZeniMax      }
{  Media company. This unit is derived from the Doom 3 GPL source code and is  }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Model;

interface

uses
  System.SysUtils,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>An MD5 model read from an md5mesh. Immutable after the creation.</summary>
  TMd5Model = class(TInterfacedObject, IMd5Model)
  strict private
    FName: AnsiString;
    FJoints: TArray<TMd5Joint>;
    FDefaultPose: TArray<TMd5JointQuat>;
    FReference: TArray<TMd5JointMat>;
    FMeshes: TArray<IMd5Mesh>;
    FBounds: TGeoBounds;
    FSkeleton: IMd5Skeleton;
    function GetName: AnsiString;
    function GetNumJoints: Integer;
    function GetJoint(const AIndex: Integer): TMd5Joint;
    function GetDefaultPose: TArray<TMd5JointQuat>;
    function GetReferenceMatrices: TArray<TMd5JointMat>;
    function GetNumMeshes: Integer;
    function GetMesh(const AIndex: Integer): IMd5Mesh;
    function GetBounds: TGeoBounds;
    function GetSkeleton: IMd5Skeleton;
  public
    /// <summary>
    ///   The bounds are the union of the bounds of the meshes in the reference pose
    ///   (CalculateBounds), computed here from the reference matrices.
    /// </summary>
    constructor Create(const AName: AnsiString; const AJoints: TArray<TMd5Joint>;
      const ADefaultPose: TArray<TMd5JointQuat>; const AReference: TArray<TMd5JointMat>;
      const AMeshes: TArray<IMd5Mesh>; const ASkeleton: IMd5Skeleton);
    function GetJointHandle(const AName: AnsiString): Integer;
    function GetJointName(const AHandle: Integer): AnsiString;
    function NearestJoint(const AMesh, A, B, C: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Models.Types;

{ TMd5Model }

constructor TMd5Model.Create(const AName: AnsiString; const AJoints: TArray<TMd5Joint>;
  const ADefaultPose: TArray<TMd5JointQuat>; const AReference: TArray<TMd5JointMat>;
  const AMeshes: TArray<IMd5Mesh>; const ASkeleton: IMd5Skeleton);
var
  LIndex: Integer;
begin
  inherited Create;
  FName := AName;
  FJoints := AJoints;
  FDefaultPose := ADefaultPose;
  FReference := AReference;
  FMeshes := AMeshes;
  FSkeleton := ASkeleton;
  FBounds := TGeoBounds.Cleared;
  for LIndex := 0 to High(FMeshes) do
    FBounds.AddBounds(FMeshes[LIndex].CalcBounds(FReference));
end;

function TMd5Model.GetName: AnsiString;
begin
  Result := FName;
end;

function TMd5Model.GetNumJoints: Integer;
begin
  Result := Length(FJoints);
end;

function TMd5Model.GetJoint(const AIndex: Integer): TMd5Joint;
begin
  Result := FJoints[AIndex];
end;

function TMd5Model.GetDefaultPose: TArray<TMd5JointQuat>;
begin
  Result := FDefaultPose;
end;

function TMd5Model.GetReferenceMatrices: TArray<TMd5JointMat>;
begin
  Result := FReference;
end;

function TMd5Model.GetNumMeshes: Integer;
begin
  Result := Length(FMeshes);
end;

function TMd5Model.GetMesh(const AIndex: Integer): IMd5Mesh;
begin
  Result := FMeshes[AIndex];
end;

function TMd5Model.GetBounds: TGeoBounds;
begin
  Result := FBounds;
end;

function TMd5Model.GetSkeleton: IMd5Skeleton;
begin
  Result := FSkeleton;
end;

function TMd5Model.GetJointHandle(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FJoints) do
    if CompareText(string(FJoints[LIndex].Name), string(AName)) = 0 then
      Exit(LIndex);
  Result := MD5_INVALID_JOINT;
end;

function TMd5Model.GetJointName(const AHandle: Integer): AnsiString;
begin
  if (AHandle < 0) or (AHandle >= Length(FJoints)) then
    Result := MD5_INVALID_JOINT_NAME
  else
    Result := FJoints[AHandle].Name;
end;

function TMd5Model.NearestJoint(const AMesh, A, B, C: Integer): Integer;
begin
  if (AMesh < 0) or (AMesh >= Length(FMeshes)) then
    raise EModelsException.CreateFmt(SMd5InvalidMesh, [AMesh, Length(FMeshes)]);
  Result := FMeshes[AMesh].NearestJoint(A, B, C);
end;

end.
