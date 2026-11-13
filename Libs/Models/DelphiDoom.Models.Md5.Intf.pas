{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5 (idTech 4): contracts                   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp, }
{  renderer\Model_local.h, game\anim\Anim.h. Copyright (C) 1999-2011 id        }
{  Software LLC, a ZeniMax Media company. This unit is derived from the Doom 3 }
{  GPL source code and is therefore available under the GNU General Public     }
{  License, version 3, with the additional terms of the Doom 3 Source Code     }
{  License (see README.md of Libs\IdLib); the repository as a whole is GPL v2  }
{  or later.                                                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec2,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat;

type
  /// <summary>
  ///   The hierarchy of the joints of a model and the operations on the poses (idSIMD joints
  ///   functions of the generic processor). It has no pose: the callers own the arrays.
  /// </summary>
  IMd5Skeleton = interface
    ['{6A2E5C41-91B7-4F0D-8D3B-2C5E7A90B6D1}']
    function GetNumJoints: Integer;
    /// <summary>The parent of a joint, -1 for the root</summary>
    function GetParent(const AJoint: Integer): Integer;
    /// <summary>ConvertJointQuatsToJointMats: the matrices of the poses, still relative to the parents</summary>
    function ConvertToMatrices(const AJoints: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
    /// <summary>ConvertJointMatsToJointQuats</summary>
    function ConvertToQuats(const AMatrices: TArray<TMd5JointMat>): TArray<TMd5JointQuat>;
    /// <summary>
    ///   TransformJoints (first..last): from relative to absolute, parents first. The root is not
    ///   transformed when the first joint is 1, as the engine does.
    /// </summary>
    procedure TransformJoints(var AMatrices: TArray<TMd5JointMat>; const AFirst, ALast: Integer);
    /// <summary>UntransformJoints (last down to first): from absolute to relative</summary>
    procedure UntransformJoints(var AMatrices: TArray<TMd5JointMat>; const AFirst, ALast: Integer);
    /// <summary>The absolute matrices of a relative pose: ConvertToMatrices then TransformJoints(1, n-1)</summary>
    function ToAbsolute(const AJoints: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
    /// <summary>BlendJoints: joints[j] becomes the slerp/lerp to blend[j] for the indexes given</summary>
    procedure BlendJoints(var AJoints: TArray<TMd5JointQuat>; const ABlend: TArray<TMd5JointQuat>;
      const ALerp: Single; const AIndexes: TArray<Integer>);
    property NumJoints: Integer read GetNumJoints;
    property Parent[const AJoint: Integer]: Integer read GetParent;
  end;

  /// <summary>One surface of an MD5 model (idMD5Mesh): texture points, triangles and weights</summary>
  IMd5Mesh = interface
    ['{D41C8E27-5B63-4A9E-B0F2-7E3A19C5D8A4}']
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
    /// <summary>The positions of the vertexes for the absolute matrices of the joints (TransformVerts)</summary>
    function TransformVerts(const AJoints: TArray<TMd5JointMat>): TArray<TIdVec3>;
    /// <summary>The positions with the weights scaled (TransformScaledVerts: fat or skinny)</summary>
    function TransformScaledVerts(const AJoints: TArray<TMd5JointMat>; const AScale: Single): TArray<TIdVec3>;
    /// <summary>The bounds of the transformed vertexes (CalcBounds)</summary>
    function CalcBounds(const AJoints: TArray<TMd5JointMat>): TGeoBounds;
    /// <summary>The joint of the largest weight of a vertex of a triangle (NearestJoint)</summary>
    function NearestJoint(const A, B, C: Integer): Integer;
    property Name: AnsiString read GetName;
    property ShaderName: AnsiString read GetShaderName;
    property NumVerts: Integer read GetNumVerts;
    property NumTris: Integer read GetNumTris;
    property NumWeights: Integer read GetNumWeights;
    property TexCoords[const AVertex: Integer]: TIdVec2 read GetTexCoord;
    /// <summary>Three vertex indexes for each triangle</summary>
    property Triangles: TArray<Integer> read GetTriangles;
    /// <summary>The joint of every weight, in the order of the vertexes (weightIndex)</summary>
    property WeightJoints[const AWeight: Integer]: Integer read GetWeightJoint;
    /// <summary>The offset already multiplied by the weight in XYZ and the weight in W (scaledWeights)</summary>
    property ScaledWeights[const AWeight: Integer]: TIdVec4 read GetScaledWeight;
    /// <summary>True on the last weight of every vertex</summary>
    property WeightEndsVertex[const AWeight: Integer]: Boolean read GetWeightEndsVertex;
  end;

  /// <summary>An MD5 model: the skeleton, the reference pose and the meshes (idRenderModelMD5)</summary>
  IMd5Model = interface
    ['{B7F30A52-3E18-4C6D-9A41-0D8E5B27C3F9}']
    function GetName: AnsiString;
    function GetNumJoints: Integer;
    function GetJoint(const AIndex: Integer): TMd5Joint;
    function GetDefaultPose: TArray<TMd5JointQuat>;
    function GetReferenceMatrices: TArray<TMd5JointMat>;
    function GetNumMeshes: Integer;
    function GetMesh(const AIndex: Integer): IMd5Mesh;
    function GetBounds: TGeoBounds;
    function GetSkeleton: IMd5Skeleton;
    /// <summary>The index of the joint with that name (ASCII, case insensitive) or MD5_INVALID_JOINT</summary>
    function GetJointHandle(const AName: AnsiString): Integer;
    /// <summary>The name of the joint, '&lt;invalid joint&gt;' out of range</summary>
    function GetJointName(const AHandle: Integer): AnsiString;
    /// <summary>The joint index of the mesh's nearest joint (idRenderModelMD5::NearestJoint)</summary>
    function NearestJoint(const AMesh, A, B, C: Integer): Integer;
    property Name: AnsiString read GetName;
    property NumJoints: Integer read GetNumJoints;
    property Joints[const AIndex: Integer]: TMd5Joint read GetJoint;
    /// <summary>The pose of the joints relative to their parents (defaultPose)</summary>
    property DefaultPose: TArray<TMd5JointQuat> read GetDefaultPose;
    /// <summary>The absolute matrices of the pose of the file (the poseMat3 of LoadModel)</summary>
    property ReferenceMatrices: TArray<TMd5JointMat> read GetReferenceMatrices;
    property NumMeshes: Integer read GetNumMeshes;
    property Meshes[const AIndex: Integer]: IMd5Mesh read GetMesh;
    /// <summary>The bounds of all the meshes in the reference pose (CalculateBounds)</summary>
    property Bounds: TGeoBounds read GetBounds;
    property Skeleton: IMd5Skeleton read GetSkeleton;
  end;

  /// <summary>An MD5 animation (idMD5Anim)</summary>
  IMd5Anim = interface
    ['{4E9A1D63-C8B5-42F7-A036-9B1F7D5E2C80}']
    function GetName: AnsiString;
    function GetNumFrames: Integer;
    function GetNumJoints: Integer;
    function GetFrameRate: Integer;
    function GetLength: Integer;
    function GetTotalMovementDelta: TIdVec3;
    function GetJointInfo(const AIndex: Integer): TMd5AnimJointInfo;
    function GetBaseFrame: TArray<TMd5JointQuat>;
    function GetFrameBounds(const AFrame: Integer): TGeoBounds;
    /// <summary>GetFrameBlend: a frame number (1 is the first) clamped, no interpolation</summary>
    function GetFrameBlend(const AFrameNumber: Integer): TMd5FrameBlend;
    /// <summary>ConvertTimeToFrame: AMilliseconds from the start; ACycleCount 0 loops forever</summary>
    function ConvertTimeToFrame(const AMilliseconds, ACycleCount: Integer): TMd5FrameBlend;
    /// <summary>GetOrigin: the translation of the root joint at a time</summary>
    function GetOrigin(const AMilliseconds, ACycleCount: Integer): TIdVec3;
    /// <summary>GetOriginRotation: the rotation of the root joint at a time</summary>
    function GetOriginRotation(const AMilliseconds, ACycleCount: Integer): TIdQuat;
    /// <summary>GetBounds: the bounds of the two frames, relative to the origin of the root</summary>
    function GetBounds(const AMilliseconds, ACycleCount: Integer): TGeoBounds;
    /// <summary>
    ///   GetInterpolatedFrame: the pose of the joints (relative to the parents) for a blend of
    ///   two frames. The indexes list the joints to compute; nil computes all of them.
    /// </summary>
    function GetInterpolatedFrame(const ABlend: TMd5FrameBlend;
      const AIndexes: TArray<Integer>): TArray<TMd5JointQuat>;
    /// <summary>GetSingleFrame: the pose of one frame (0 is the base frame); nil indexes compute all the joints</summary>
    function GetSingleFrame(const AFrame: Integer; const AIndexes: TArray<Integer>): TArray<TMd5JointQuat>;
    property Name: AnsiString read GetName;
    property NumFrames: Integer read GetNumFrames;
    property NumJoints: Integer read GetNumJoints;
    property FrameRate: Integer read GetFrameRate;
    /// <summary>The length in milliseconds (the last frame is not counted)</summary>
    property Length: Integer read GetLength;
    property TotalMovementDelta: TIdVec3 read GetTotalMovementDelta;
    property JointInfo[const AIndex: Integer]: TMd5AnimJointInfo read GetJointInfo;
    property BaseFrame: TArray<TMd5JointQuat> read GetBaseFrame;
    property FrameBounds[const AFrame: Integer]: TGeoBounds read GetFrameBounds;
  end;

  /// <summary>The reader of md5mesh files</summary>
  IMd5ModelParser = interface
    ['{9C3D7B18-0A52-4E96-B8F4-1E6A2D93C705}']
    /// <summary>
    ///   Reads the text of an md5mesh. A format error is an EIdLexerException with the file name
    ///   (AName) and the line.
    /// </summary>
    function Parse(const AText, AName: AnsiString): IMd5Model;
  end;

  /// <summary>The reader of md5anim files</summary>
  IMd5AnimParser = interface
    ['{2F6B0E94-D7A3-4185-9C5E-83B1A4F60D27}']
    function Parse(const AText, AName: AnsiString): IMd5Anim;
  end;

implementation

end.
