{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: the skeleton and the pose operations   }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): idlib\math\              }
{  Simd_Generic.cpp (BlendJoints, ConvertJointQuatsToJointMats,                }
{  ConvertJointMatsToJointQuats, TransformJoints, UntransformJoints).          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This unit }
{  is derived from the Doom 3 GPL source code and is therefore available under }
{  the GNU General Public License, version 3, with the additional terms of the }
{  Doom 3 Source Code License (see README.md of Libs\IdLib); the repository as }
{  a whole is GPL v2 or later.                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Skeleton;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>
  ///   The hierarchy of a model: the parent of every joint, always before the joint. The pose
  ///   operations are the ones of the generic SIMD processor of Doom 3 in plain Pascal.
  /// </summary>
  TMd5Skeleton = class(TInterfacedObject, IMd5Skeleton)
  strict private
    FParents: TArray<Integer>;
    function GetNumJoints: Integer;
    function GetParent(const AJoint: Integer): Integer;
    procedure CheckLength(const ACount: Integer);
    procedure CheckRange(const AFirst, ALast: Integer);
  public
    /// <summary>The parents (-1 for the root); each one must be less than its joint</summary>
    constructor Create(const AParents: TArray<Integer>);
    function ConvertToMatrices(const AJoints: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
    function ConvertToQuats(const AMatrices: TArray<TMd5JointMat>): TArray<TMd5JointQuat>;
    procedure TransformJoints(var AMatrices: TArray<TMd5JointMat>; const AFirst, ALast: Integer);
    procedure UntransformJoints(var AMatrices: TArray<TMd5JointMat>; const AFirst, ALast: Integer);
    function ToAbsolute(const AJoints: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
    procedure BlendJoints(var AJoints: TArray<TMd5JointQuat>; const ABlend: TArray<TMd5JointQuat>;
      const ALerp: Single; const AIndexes: TArray<Integer>);
  end;

implementation

uses
  DelphiDoom.MathCore.Float.Conversions;

{ TMd5Skeleton }

constructor TMd5Skeleton.Create(const AParents: TArray<Integer>);
var
  LIndex: Integer;
begin
  inherited Create;
  for LIndex := 0 to High(AParents) do
    if (AParents[LIndex] >= LIndex) or (AParents[LIndex] < -1) then
      raise EModelsException.CreateFmt(SMd5InvalidParent, [AParents[LIndex], LIndex]);
  FParents := Copy(AParents);
end;

function TMd5Skeleton.GetNumJoints: Integer;
begin
  Result := Length(FParents);
end;

function TMd5Skeleton.GetParent(const AJoint: Integer): Integer;
begin
  if (AJoint < 0) or (AJoint >= Length(FParents)) then
    raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [AJoint, Length(FParents)]);
  Result := FParents[AJoint];
end;

procedure TMd5Skeleton.CheckLength(const ACount: Integer);
begin
  if ACount <> Length(FParents) then
    raise EModelsException.CreateFmt(SMd5ArrayLength, [Length(FParents), ACount]);
end;

procedure TMd5Skeleton.CheckRange(const AFirst, ALast: Integer);
begin
  if AFirst < 0 then
    raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [AFirst, Length(FParents)]);
  if ALast >= Length(FParents) then
    raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [ALast, Length(FParents)]);
end;

function TMd5Skeleton.ConvertToMatrices(const AJoints: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
var
  LIndex: Integer;
begin
  CheckLength(Length(AJoints));
  SetLength(Result, Length(AJoints));
  for LIndex := 0 to High(AJoints) do
  begin
    Result[LIndex].SetRotation(TIdRotationConversions.QuatToMat(AJoints[LIndex].Q));
    Result[LIndex].SetTranslation(AJoints[LIndex].T);
  end;
end;

function TMd5Skeleton.ConvertToQuats(const AMatrices: TArray<TMd5JointMat>): TArray<TMd5JointQuat>;
var
  LIndex: Integer;
begin
  CheckLength(Length(AMatrices));
  SetLength(Result, Length(AMatrices));
  for LIndex := 0 to High(AMatrices) do
    Result[LIndex] := AMatrices[LIndex].ToJointQuat;
end;

procedure TMd5Skeleton.TransformJoints(var AMatrices: TArray<TMd5JointMat>; const AFirst, ALast: Integer);
var
  LIndex: Integer;
begin
  CheckLength(Length(AMatrices));
  CheckRange(AFirst, ALast);
  for LIndex := AFirst to ALast do
    AMatrices[LIndex].TransformBy(AMatrices[FParents[LIndex]]);
end;

procedure TMd5Skeleton.UntransformJoints(var AMatrices: TArray<TMd5JointMat>; const AFirst, ALast: Integer);
var
  LIndex: Integer;
begin
  CheckLength(Length(AMatrices));
  CheckRange(AFirst, ALast);
  for LIndex := ALast downto AFirst do
    AMatrices[LIndex].UntransformBy(AMatrices[FParents[LIndex]]);
end;

function TMd5Skeleton.ToAbsolute(const AJoints: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
begin
  Result := ConvertToMatrices(AJoints);
  if Length(Result) > 1 then
    TransformJoints(Result, 1, High(Result));
end;

procedure TMd5Skeleton.BlendJoints(var AJoints: TArray<TMd5JointQuat>; const ABlend: TArray<TMd5JointQuat>;
  const ALerp: Single; const AIndexes: TArray<Integer>);
var
  LIndex, LJoint: Integer;
  LFrom: TMd5JointQuat;
begin
  CheckLength(Length(AJoints));
  CheckLength(Length(ABlend));
  for LIndex := 0 to High(AIndexes) do
  begin
    LJoint := AIndexes[LIndex];
    if (LJoint < 0) or (LJoint >= Length(FParents)) then
      raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [LJoint, Length(FParents)]);
    LFrom := AJoints[LJoint];
    AJoints[LJoint].Q.Slerp(LFrom.Q, ABlend[LJoint].Q, ALerp);
    AJoints[LJoint].T.Lerp(LFrom.T, ABlend[LJoint].T, ALerp);
  end;
end;

end.
