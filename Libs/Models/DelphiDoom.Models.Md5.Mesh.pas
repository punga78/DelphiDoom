{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: a mesh (surface) of a model            }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp   }
{  (idMD5Mesh) and idlib\math\Simd_Generic.cpp (TransformVerts). Copyright (C) }
{  1999-2011 id Software LLC, a ZeniMax Media company. This unit is derived    }
{  from the Doom 3 GPL source code and is therefore available under the GNU    }
{  General Public License, version 3, with the additional terms of the Doom 3  }
{  Source Code License (see README.md of Libs\IdLib); the repository as a      }
{  whole is GPL v2 or later.                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Mesh;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>
  ///   A mesh of an MD5 model. The weights are kept as the original does after the parse: the
  ///   offset of the weight already multiplied by its value, the value in W, the joint of the
  ///   weight, and a flag on the last weight of every vertex (the second integer of weightIndex).
  ///   The deform info of the renderer (silhouette edges, mirrored vertexes, normals and tangents)
  ///   is not computed: see the README.
  /// </summary>
  TMd5Mesh = class(TInterfacedObject, IMd5Mesh)
  strict private
    FName: AnsiString;
    FShaderName: AnsiString;
    FTexCoords: TArray<TIdVec2>;
    FTriangles: TArray<Integer>;
    FScaledWeights: TArray<TIdVec4>;
    FWeightJoints: TArray<Integer>;
    FEndsVertex: TArray<Boolean>;
    function GetName: AnsiString;
    function GetShaderName: AnsiString;
    function GetNumVerts: Integer;
    function GetNumTris: Integer;
    function GetNumWeights: Integer;
    function GetTexCoord(const AVertex: Integer): TIdVec2;
    function GetTriangles: TArray<Integer>;
    function GetWeightJoint(const AWeight: Integer): Integer;
    function GetScaledWeight(const AWeight: Integer): TIdVec4;
    function GetWeightEndsVertex(const AWeight: Integer): Boolean;
    function Transform(const AJoints: TArray<TMd5JointMat>;
      const AWeights: TArray<TIdVec4>): TArray<TIdVec3>;
  public
    /// <summary>
    ///   The arrays belong to the mesh from now on. The weights arrays have the same length; the
    ///   last weight of every vertex has AEndsVertex true; a joint index is not checked here
    ///   (the parser does it, a transform with fewer joints raises an exception).
    /// </summary>
    constructor Create(const AName, AShaderName: AnsiString; const ATexCoords: TArray<TIdVec2>;
      const ATriangles: TArray<Integer>; const AScaledWeights: TArray<TIdVec4>;
      const AWeightJoints: TArray<Integer>; const AEndsVertex: TArray<Boolean>);
    function TransformVerts(const AJoints: TArray<TMd5JointMat>): TArray<TIdVec3>;
    function TransformScaledVerts(const AJoints: TArray<TMd5JointMat>; const AScale: Single): TArray<TIdVec3>;
    function CalcBounds(const AJoints: TArray<TMd5JointMat>): TGeoBounds;
    function NearestJoint(const A, B, C: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Types;

{ TMd5Mesh }

constructor TMd5Mesh.Create(const AName, AShaderName: AnsiString; const ATexCoords: TArray<TIdVec2>;
  const ATriangles: TArray<Integer>; const AScaledWeights: TArray<TIdVec4>;
  const AWeightJoints: TArray<Integer>; const AEndsVertex: TArray<Boolean>);
begin
  inherited Create;
  FName := AName;
  FShaderName := AShaderName;
  FTexCoords := ATexCoords;
  FTriangles := ATriangles;
  FScaledWeights := AScaledWeights;
  FWeightJoints := AWeightJoints;
  FEndsVertex := AEndsVertex;
end;

function TMd5Mesh.GetName: AnsiString;
begin
  Result := FName;
end;

function TMd5Mesh.GetShaderName: AnsiString;
begin
  Result := FShaderName;
end;

function TMd5Mesh.GetNumVerts: Integer;
begin
  Result := Length(FTexCoords);
end;

function TMd5Mesh.GetNumTris: Integer;
begin
  Result := Length(FTriangles) div 3;
end;

function TMd5Mesh.GetNumWeights: Integer;
begin
  Result := Length(FScaledWeights);
end;

function TMd5Mesh.GetTexCoord(const AVertex: Integer): TIdVec2;
begin
  Result := FTexCoords[AVertex];
end;

function TMd5Mesh.GetTriangles: TArray<Integer>;
begin
  Result := FTriangles;
end;

function TMd5Mesh.GetWeightJoint(const AWeight: Integer): Integer;
begin
  Result := FWeightJoints[AWeight];
end;

function TMd5Mesh.GetScaledWeight(const AWeight: Integer): TIdVec4;
begin
  Result := FScaledWeights[AWeight];
end;

function TMd5Mesh.GetWeightEndsVertex(const AWeight: Integer): Boolean;
begin
  Result := FEndsVertex[AWeight];
end;

function TMd5Mesh.Transform(const AJoints: TArray<TMd5JointMat>;
  const AWeights: TArray<TIdVec4>): TArray<TIdVec3>;
var
  LVertex, LWeight: Integer;
  LSum: TIdVec3;
begin
  SetLength(Result, Length(FTexCoords));
  LWeight := 0;
  for LVertex := 0 to High(FTexCoords) do
  begin
    if FWeightJoints[LWeight] >= Length(AJoints) then
      raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [FWeightJoints[LWeight], Length(AJoints)]);
    LSum := AJoints[FWeightJoints[LWeight]].Apply(AWeights[LWeight]);
    while not FEndsVertex[LWeight] do
    begin
      Inc(LWeight);
      if FWeightJoints[LWeight] >= Length(AJoints) then
        raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [FWeightJoints[LWeight], Length(AJoints)]);
      LSum := LSum + AJoints[FWeightJoints[LWeight]].Apply(AWeights[LWeight]);
    end;
    Inc(LWeight);
    Result[LVertex] := LSum;
  end;
end;

function TMd5Mesh.TransformVerts(const AJoints: TArray<TMd5JointMat>): TArray<TIdVec3>;
begin
  Result := Transform(AJoints, FScaledWeights);
end;

function TMd5Mesh.TransformScaledVerts(const AJoints: TArray<TMd5JointMat>;
  const AScale: Single): TArray<TIdVec3>;
var
  LScaled: TArray<TIdVec4>;
  LIndex: Integer;
begin
  // the original multiplies an uninitialised copy here (see README); this is the intended result
  SetLength(LScaled, Length(FScaledWeights));
  for LIndex := 0 to High(FScaledWeights) do
    LScaled[LIndex] := FScaledWeights[LIndex] * AScale;
  Result := Transform(AJoints, LScaled);
end;

function TMd5Mesh.CalcBounds(const AJoints: TArray<TMd5JointMat>): TGeoBounds;
var
  LVertices: TArray<TIdVec3>;
  LIndex: Integer;
begin
  LVertices := TransformVerts(AJoints);
  Result := TGeoBounds.Cleared;
  for LIndex := 0 to High(LVertices) do
    Result.AddPoint(TGeoVec3.Make(LVertices[LIndex].X, LVertices[LIndex].Y, LVertices[LIndex].Z));
end;

function TMd5Mesh.NearestJoint(const A, B, C: Integer): Integer;
var
  LVertex, LWeightVertex, LIndex: Integer;
  LBestWeight: Single;
begin
  // duplicated vertices might not have weights
  if (A >= 0) and (A < Length(FTexCoords)) then
    LVertex := A
  else if (B >= 0) and (B < Length(FTexCoords)) then
    LVertex := B
  else if (C >= 0) and (C < Length(FTexCoords)) then
    LVertex := C
  else
    Exit(0);

  // find the first weight of this vertex
  LWeightVertex := 0;
  LIndex := 0;
  while LWeightVertex < LVertex do
  begin
    Inc(LWeightVertex, Ord(FEndsVertex[LIndex]));
    Inc(LIndex);
  end;

  // the joint of the largest weight. As in the original the loop stops on the weight that ends
  // the vertex without looking at it: the last weight of a vertex never wins
  LBestWeight := FScaledWeights[LIndex].W;
  Result := FWeightJoints[LIndex];
  while not FEndsVertex[LIndex] do
  begin
    if FScaledWeights[LIndex].W > LBestWeight then
    begin
      LBestWeight := FScaledWeights[LIndex].W;
      Result := FWeightJoints[LIndex];
    end;
    Inc(LIndex);
  end;
end;

end.
