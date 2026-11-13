{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - MD5: an animation                           }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim.cpp       }
{  (idMD5Anim) and game\anim\Anim.h. Copyright (C) 1999-2011 id Software LLC,  }
{  a ZeniMax Media company. This unit is derived from the Doom 3 GPL source    }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License (see }
{  README.md of Libs\IdLib); the repository as a whole is GPL v2 or later.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Md5.Anim;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  System.Math,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.Intf;

type
  /// <summary>
  ///   An MD5 animation: per frame the animated components of the joints and the bounds, over a
  ///   base frame. The data is final (the parser has already moved the translation of the root
  ///   into the total movement delta). Immutable.
  /// </summary>
  TMd5Anim = class(TInterfacedObject, IMd5Anim)
  strict private
    FName: AnsiString;
    FNumFrames: Integer;
    FFrameRate: Integer;
    FNumAnimatedComponents: Integer;
    FJointInfo: TArray<TMd5AnimJointInfo>;
    FBounds: TArray<TGeoBounds>;
    FBaseFrame: TArray<TMd5JointQuat>;
    FComponentFrames: TArray<Single>;
    FTotalDelta: TIdVec3;
    FLength: Integer;
    FSkeleton: IMd5Skeleton;
    function GetName: AnsiString;
    function GetNumFrames: Integer;
    function GetNumJoints: Integer;
    function GetFrameRate: Integer;
    function GetLength: Integer;
    function GetTotalMovementDelta: TIdVec3;
    function GetJointInfo(const AIndex: Integer): TMd5AnimJointInfo;
    function GetBaseFrame: TArray<TMd5JointQuat>;
    function GetFrameBounds(const AFrame: Integer): TGeoBounds;
    procedure CheckFrame(const AFrame: Integer);
    function AllJoints(const AIndexes: TArray<Integer>): TArray<Integer>;
    /// <summary>Reads the translation components of a joint from a frame at APosition, advancing it</summary>
    procedure ReadTranslation(const AFrame, ABits: Integer; var APosition: Integer; var AValue: TIdVec3);
    /// <summary>Reads the rotation components and rebuilds W</summary>
    procedure ReadRotation(const AFrame, ABits: Integer; var APosition: Integer; var AValue: TIdQuat);
  public
    /// <summary>
    ///   AComponentFrames holds NumAnimatedComponents floats for every frame. The hierarchy must
    ///   have the parent before the joint. AFrameRate must be greater than zero: the length of the
    ///   animation divides by it.
    /// </summary>
    constructor Create(const AName: AnsiString; const AFrameRate, ANumAnimatedComponents: Integer;
      const AJointInfo: TArray<TMd5AnimJointInfo>; const ABounds: TArray<TGeoBounds>;
      const ABaseFrame: TArray<TMd5JointQuat>; const AComponentFrames: TArray<Single>;
      const ATotalDelta: TIdVec3);
    function GetFrameBlend(const AFrameNumber: Integer): TMd5FrameBlend;
    function ConvertTimeToFrame(const AMilliseconds, ACycleCount: Integer): TMd5FrameBlend;
    function GetOrigin(const AMilliseconds, ACycleCount: Integer): TIdVec3;
    function GetOriginRotation(const AMilliseconds, ACycleCount: Integer): TIdQuat;
    function GetBounds(const AMilliseconds, ACycleCount: Integer): TGeoBounds;
    function GetInterpolatedFrame(const ABlend: TMd5FrameBlend;
      const AIndexes: TArray<Integer>): TArray<TMd5JointQuat>;
    function GetSingleFrame(const AFrame: Integer; const AIndexes: TArray<Integer>): TArray<TMd5JointQuat>;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Md5.Skeleton;

{ TMd5Anim }

constructor TMd5Anim.Create(const AName: AnsiString; const AFrameRate, ANumAnimatedComponents: Integer;
  const AJointInfo: TArray<TMd5AnimJointInfo>; const ABounds: TArray<TGeoBounds>;
  const ABaseFrame: TArray<TMd5JointQuat>; const AComponentFrames: TArray<Single>;
  const ATotalDelta: TIdVec3);
var
  LParents: TArray<Integer>;
  LIndex: Integer;
begin
  inherited Create;
  if (Length(AJointInfo) = 0) or (Length(ABounds) = 0) or (AFrameRate <= 0) or
    (Length(ABaseFrame) <> Length(AJointInfo)) or (ANumAnimatedComponents < 0) or
    (Length(AComponentFrames) <> ANumAnimatedComponents * Length(ABounds)) then
    raise EModelsException.Create(SMd5InvalidAnimData);
  FName := AName;
  FNumFrames := Length(ABounds);
  FFrameRate := AFrameRate;
  FNumAnimatedComponents := ANumAnimatedComponents;
  FJointInfo := AJointInfo;
  FBounds := ABounds;
  FBaseFrame := ABaseFrame;
  FComponentFrames := AComponentFrames;
  FTotalDelta := ATotalDelta;
  SetLength(LParents, Length(AJointInfo));
  for LIndex := 0 to High(LParents) do
    LParents[LIndex] := Max(-1, AJointInfo[LIndex].ParentNum);
  FSkeleton := TMd5Skeleton.Create(LParents);
  // we don't count the last frame because it would cause a 1 frame pause at the end
  FLength := ((FNumFrames - 1) * 1000 + FFrameRate - 1) div FFrameRate;
end;

function TMd5Anim.GetName: AnsiString;
begin
  Result := FName;
end;

function TMd5Anim.GetNumFrames: Integer;
begin
  Result := FNumFrames;
end;

function TMd5Anim.GetNumJoints: Integer;
begin
  Result := Length(FJointInfo);
end;

function TMd5Anim.GetFrameRate: Integer;
begin
  Result := FFrameRate;
end;

function TMd5Anim.GetLength: Integer;
begin
  Result := FLength;
end;

function TMd5Anim.GetTotalMovementDelta: TIdVec3;
begin
  Result := FTotalDelta;
end;

function TMd5Anim.GetJointInfo(const AIndex: Integer): TMd5AnimJointInfo;
begin
  Result := FJointInfo[AIndex];
end;

function TMd5Anim.GetBaseFrame: TArray<TMd5JointQuat>;
begin
  Result := Copy(FBaseFrame);
end;

function TMd5Anim.GetFrameBounds(const AFrame: Integer): TGeoBounds;
begin
  CheckFrame(AFrame);
  Result := FBounds[AFrame];
end;

procedure TMd5Anim.CheckFrame(const AFrame: Integer);
begin
  if (AFrame < 0) or (AFrame >= FNumFrames) then
    raise EModelsException.CreateFmt(SMd5InvalidFrame, [AFrame, FNumFrames]);
end;

function TMd5Anim.AllJoints(const AIndexes: TArray<Integer>): TArray<Integer>;
var
  LIndex: Integer;
begin
  if Length(AIndexes) > 0 then
    Exit(AIndexes);
  SetLength(Result, Length(FJointInfo));
  for LIndex := 0 to High(Result) do
    Result[LIndex] := LIndex;
end;

function TMd5Anim.GetFrameBlend(const AFrameNumber: Integer): TMd5FrameBlend;
var
  LFrame: Integer;
begin
  Result.CycleCount := 0;
  Result.BackLerp := 0.0;
  Result.FrontLerp := 1.0;
  // frame 1 is the first frame
  LFrame := AFrameNumber - 1;
  if LFrame < 0 then
    LFrame := 0
  else if LFrame >= FNumFrames then
    LFrame := FNumFrames - 1;
  Result.Frame1 := LFrame;
  Result.Frame2 := LFrame;
end;

function TMd5Anim.ConvertTimeToFrame(const AMilliseconds, ACycleCount: Integer): TMd5FrameBlend;
var
  LFrameTime, LFrameNumber: Int64;
begin
  Result.CycleCount := 0;
  Result.Frame1 := 0;
  Result.Frame2 := 0;
  Result.BackLerp := 0.0;
  Result.FrontLerp := 1.0;
  if FNumFrames <= 1 then
    Exit;
  if AMilliseconds <= 0 then
  begin
    Result.Frame2 := 1;
    Exit;
  end;

  // Int64: the original multiplies in an int and wraps after about a day of animation
  LFrameTime := Int64(AMilliseconds) * FFrameRate;
  LFrameNumber := LFrameTime div 1000;
  Result.CycleCount := Integer(LFrameNumber div (FNumFrames - 1));

  if (ACycleCount > 0) and (Result.CycleCount >= ACycleCount) then
  begin
    Result.CycleCount := ACycleCount - 1;
    Result.Frame1 := FNumFrames - 1;
    Result.Frame2 := Result.Frame1;
    Exit;
  end;

  Result.Frame1 := Integer(LFrameNumber mod (FNumFrames - 1));
  Result.Frame2 := Result.Frame1 + 1;
  if Result.Frame2 >= FNumFrames then
    Result.Frame2 := 0;

  Result.BackLerp := Single(Integer(LFrameTime mod 1000)) * Single(0.001);
  Result.FrontLerp := 1.0 - Result.BackLerp;
end;

procedure TMd5Anim.ReadTranslation(const AFrame, ABits: Integer; var APosition: Integer;
  var AValue: TIdVec3);
begin
  if (ABits and ANIM_TX) <> 0 then
  begin
    AValue.X := FComponentFrames[AFrame * FNumAnimatedComponents + APosition];
    Inc(APosition);
  end;
  if (ABits and ANIM_TY) <> 0 then
  begin
    AValue.Y := FComponentFrames[AFrame * FNumAnimatedComponents + APosition];
    Inc(APosition);
  end;
  if (ABits and ANIM_TZ) <> 0 then
  begin
    AValue.Z := FComponentFrames[AFrame * FNumAnimatedComponents + APosition];
    Inc(APosition);
  end;
end;

procedure TMd5Anim.ReadRotation(const AFrame, ABits: Integer; var APosition: Integer;
  var AValue: TIdQuat);
begin
  if (ABits and ANIM_QX) <> 0 then
  begin
    AValue.X := FComponentFrames[AFrame * FNumAnimatedComponents + APosition];
    Inc(APosition);
  end;
  if (ABits and ANIM_QY) <> 0 then
  begin
    AValue.Y := FComponentFrames[AFrame * FNumAnimatedComponents + APosition];
    Inc(APosition);
  end;
  if (ABits and ANIM_QZ) <> 0 then
  begin
    AValue.Z := FComponentFrames[AFrame * FNumAnimatedComponents + APosition];
    Inc(APosition);
  end;
  if (ABits and ANIM_ROTATION) <> 0 then
    AValue.W := AValue.CalcW;
end;

function TMd5Anim.GetOrigin(const AMilliseconds, ACycleCount: Integer): TIdVec3;
var
  LBlend: TMd5FrameBlend;
  LFirst, LSecond: TIdVec3;
  LPosition: Integer;
begin
  Result := FBaseFrame[0].T;
  if (FJointInfo[0].AnimBits and ANIM_TRANSLATION) = 0 then
    // just use the baseframe
    Exit;

  LBlend := ConvertTimeToFrame(AMilliseconds, ACycleCount);
  LFirst := Result;
  LSecond := Result;
  LPosition := FJointInfo[0].FirstComponent;
  ReadTranslation(LBlend.Frame1, FJointInfo[0].AnimBits, LPosition, LFirst);
  LPosition := FJointInfo[0].FirstComponent;
  ReadTranslation(LBlend.Frame2, FJointInfo[0].AnimBits, LPosition, LSecond);

  if (FJointInfo[0].AnimBits and ANIM_TX) <> 0 then
    Result.X := LFirst.X * LBlend.FrontLerp + LSecond.X * LBlend.BackLerp;
  if (FJointInfo[0].AnimBits and ANIM_TY) <> 0 then
    Result.Y := LFirst.Y * LBlend.FrontLerp + LSecond.Y * LBlend.BackLerp;
  if (FJointInfo[0].AnimBits and ANIM_TZ) <> 0 then
    Result.Z := LFirst.Z * LBlend.FrontLerp + LSecond.Z * LBlend.BackLerp;

  if LBlend.CycleCount <> 0 then
    Result := Result + FTotalDelta * Single(LBlend.CycleCount);
end;

function TMd5Anim.GetOriginRotation(const AMilliseconds, ACycleCount: Integer): TIdQuat;
var
  LBlend: TMd5FrameBlend;
  LBits, LPosition: Integer;
  LFirst, LSecond: TIdQuat;
  LDummy: TIdVec3;
begin
  LBits := FJointInfo[0].AnimBits;
  if (LBits and ANIM_ROTATION) = 0 then
    // just use the baseframe
    Exit(FBaseFrame[0].Q);

  LBlend := ConvertTimeToFrame(AMilliseconds, ACycleCount);
  LFirst := FBaseFrame[0].Q;
  LSecond := FBaseFrame[0].Q;
  LDummy := FBaseFrame[0].T;

  // the translation components come first in the frame
  LPosition := FJointInfo[0].FirstComponent;
  ReadTranslation(LBlend.Frame1, LBits, LPosition, LDummy);
  ReadRotation(LBlend.Frame1, LBits, LPosition, LFirst);
  LPosition := FJointInfo[0].FirstComponent;
  ReadTranslation(LBlend.Frame2, LBits, LPosition, LDummy);
  ReadRotation(LBlend.Frame2, LBits, LPosition, LSecond);

  Result.Slerp(LFirst, LSecond, LBlend.BackLerp);
end;

function TMd5Anim.GetBounds(const AMilliseconds, ACycleCount: Integer): TGeoBounds;
var
  LOffset: TIdVec3;
  LOffsetGeo: TGeoVec3;
  LBlend: TMd5FrameBlend;
  LFirst, LSecond: TIdVec3;
  LPosition: Integer;
begin
  LBlend := ConvertTimeToFrame(AMilliseconds, ACycleCount);
  Result := FBounds[LBlend.Frame1];
  Result.AddBounds(FBounds[LBlend.Frame2]);

  // origin position
  LOffset := FBaseFrame[0].T;
  if (FJointInfo[0].AnimBits and ANIM_TRANSLATION) <> 0 then
  begin
    LFirst := LOffset;
    LSecond := LOffset;
    LPosition := FJointInfo[0].FirstComponent;
    ReadTranslation(LBlend.Frame1, FJointInfo[0].AnimBits, LPosition, LFirst);
    LPosition := FJointInfo[0].FirstComponent;
    ReadTranslation(LBlend.Frame2, FJointInfo[0].AnimBits, LPosition, LSecond);
    if (FJointInfo[0].AnimBits and ANIM_TX) <> 0 then
      LOffset.X := LFirst.X * LBlend.FrontLerp + LSecond.X * LBlend.BackLerp;
    if (FJointInfo[0].AnimBits and ANIM_TY) <> 0 then
      LOffset.Y := LFirst.Y * LBlend.FrontLerp + LSecond.Y * LBlend.BackLerp;
    if (FJointInfo[0].AnimBits and ANIM_TZ) <> 0 then
      LOffset.Z := LFirst.Z * LBlend.FrontLerp + LSecond.Z * LBlend.BackLerp;
  end;

  LOffsetGeo := TGeoVec3.Make(LOffset.X, LOffset.Y, LOffset.Z);
  Result.Mins := Result.Mins - LOffsetGeo;
  Result.Maxs := Result.Maxs - LOffsetGeo;
end;

function TMd5Anim.GetInterpolatedFrame(const ABlend: TMd5FrameBlend;
  const AIndexes: TArray<Integer>): TArray<TMd5JointQuat>;
var
  LBlendJoints: TArray<TMd5JointQuat>;
  LLerpIndexes, LIndexes: TArray<Integer>;
  LCount, LIndex, LJoint, LBits, LPosition: Integer;
begin
  CheckFrame(ABlend.Frame1);
  CheckFrame(ABlend.Frame2);
  // copy the baseframe
  Result := Copy(FBaseFrame);
  if FNumAnimatedComponents = 0 then
    // just use the base frame
    Exit;

  LIndexes := AllJoints(AIndexes);
  SetLength(LBlendJoints, Length(FBaseFrame));
  SetLength(LLerpIndexes, Length(LIndexes));
  LCount := 0;
  for LIndex := 0 to High(LIndexes) do
  begin
    LJoint := LIndexes[LIndex];
    if (LJoint < 0) or (LJoint >= Length(FJointInfo)) then
      raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [LJoint, Length(FJointInfo)]);
    LBits := FJointInfo[LJoint].AnimBits;
    if LBits = 0 then
      Continue;
    LLerpIndexes[LCount] := LJoint;
    Inc(LCount);
    LBlendJoints[LJoint] := Result[LJoint];
    LPosition := FJointInfo[LJoint].FirstComponent;
    ReadTranslation(ABlend.Frame1, LBits, LPosition, Result[LJoint].T);
    ReadRotation(ABlend.Frame1, LBits, LPosition, Result[LJoint].Q);
    LPosition := FJointInfo[LJoint].FirstComponent;
    ReadTranslation(ABlend.Frame2, LBits, LPosition, LBlendJoints[LJoint].T);
    ReadRotation(ABlend.Frame2, LBits, LPosition, LBlendJoints[LJoint].Q);
  end;
  SetLength(LLerpIndexes, LCount);

  FSkeleton.BlendJoints(Result, LBlendJoints, ABlend.BackLerp, LLerpIndexes);

  if ABlend.CycleCount <> 0 then
    Result[0].T := Result[0].T + FTotalDelta * Single(ABlend.CycleCount);
end;

function TMd5Anim.GetSingleFrame(const AFrame: Integer;
  const AIndexes: TArray<Integer>): TArray<TMd5JointQuat>;
var
  LIndexes: TArray<Integer>;
  LIndex, LJoint, LPosition: Integer;
begin
  CheckFrame(AFrame);
  // copy the baseframe
  Result := Copy(FBaseFrame);
  if (AFrame = 0) or (FNumAnimatedComponents = 0) then
    // just use the base frame
    Exit;

  LIndexes := AllJoints(AIndexes);
  for LIndex := 0 to High(LIndexes) do
  begin
    LJoint := LIndexes[LIndex];
    if (LJoint < 0) or (LJoint >= Length(FJointInfo)) then
      raise EModelsException.CreateFmt(SMd5InvalidJointIndex, [LJoint, Length(FJointInfo)]);
    if FJointInfo[LJoint].AnimBits = 0 then
      Continue;
    LPosition := FJointInfo[LJoint].FirstComponent;
    ReadTranslation(AFrame, FJointInfo[LJoint].AnimBits, LPosition, Result[LJoint].T);
    ReadRotation(AFrame, FJointInfo[LJoint].AnimBits, LPosition, Result[LJoint].Q);
  end;
end;

end.
