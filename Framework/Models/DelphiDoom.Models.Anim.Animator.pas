{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the animator of a model (idAnimator)        }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software):                          }
{  game\anim\Anim_Blend.cpp and Anim.h (idAnimator). Copyright (C) 1999-2011   }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3 or (at your option) any later version, with the   }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Animator;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Mat3,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.Blend.Types,
  DelphiDoom.Models.Anim.Blend;

type
  /// <summary>
  ///   The animations that play on a model and the pose they give (idAnimator): five channels
  ///   (all, torso, legs, head, eyelids) with up to three animations each that fade in and out, the
  ///   joint modifications of the game, the pose of an articulated figure and the matrices of the
  ///   joints that <c>CreateFrame</c> computes. The time is always an argument (milliseconds), the
  ///   random numbers, the log and the entity are injected. The frame commands are not run: the
  ///   entity receives them. Not ported: <c>Save</c> and <c>Restore</c> (the save game), the
  ///   declaration manager (the definition arrives resolved in <c>SetModelDef</c>), the render
  ///   model reset.
  /// </summary>
  TAnimator = class
  strict private
    FLog: IIdLibLog;
    FModelDef: IModelDef;
    [weak] FEntity: IAnimatorEntity;
    FChannels: array[0..ANIM_NUM_ANIM_CHANNELS - 1, 0..ANIM_MAX_ANIMS_PER_CHANNEL - 1] of TAnimBlend;
    FJointMods: TList<TAnimJointMod>;
    FJoints: TArray<TMd5JointMat>;
    FLastTransformTime: Integer;
    FStoppedAnimatingUpdate: Boolean;
    FRemoveOriginOffset: Boolean;
    FForceUpdate: Boolean;
    FFrameBounds: TGeoBounds;
    FAfPoseBlendWeight: Single;
    FAfPoseJoints: TList<Integer>;
    FAfPoseJointMods: TArray<TAnimAfPoseJointMod>;
    FAfPoseJointFrame: TArray<TMd5JointQuat>;
    FAfPoseBounds: TGeoBounds;
    FAfPoseTime: Integer;
    FSkipCinematic: Boolean;
    FShowSkeleton: Integer;
    FDebugInfo: Boolean;
    FDebugBounds: Boolean;
    function HasModel: Boolean;
    function GetNumJoints: Integer;
    procedure CheckChannel(const AChannel: Integer; const AOperation: string);
    procedure FreeData;
    procedure PushAnims(const AChannel, ACurrentTime, ABlendTime: Integer);
    procedure BecomeActive(const AFlags: Integer);
    function FindJointMod(const AJointNum: Integer; out AIndex: Integer): Boolean;
    function InsertJointMod(const AJointNum, AIndex: Integer): TAnimJointMod;
    function BlendAfPose(var ABlendFrame: TArray<TMd5JointQuat>): Boolean;
    function AfPoseIndex(const AJointNum: Integer): Integer;
    function BlendedPose(const ACurrentTime: Integer; out AHasAnim: Boolean): TArray<TMd5JointQuat>;
    procedure ApplyRootJointMod(const AJointMod: TAnimJointMod);
    procedure ApplyJointMod(const AJointMod: TAnimJointMod; const AParent: Integer);
  public
    /// <summary>ALog gets the warnings and the debug text, ARandom the random cycle starts</summary>
    constructor Create(const ALog: IIdLibLog; const ARandom: TAnimRandomFloat);
    destructor Destroy; override;
    { ---- the model }
    /// <summary>
    ///   SetModel for a definition that was already found: nil, or a definition without a model,
    ///   clears the animator. The joints are set up in the default pose.
    /// </summary>
    function SetModelDef(const AModelDef: IModelDef): Boolean;
    function ModelDef: IModelDef;
    procedure SetEntity(const AEntity: IAnimatorEntity);
    function GetEntity: IAnimatorEntity;
    procedure SetRemoveOriginOffset(const ARemove: Boolean);
    function RemoveOrigin: Boolean;
    function NumAnims: Integer;
    function GetAnim(const AIndex: Integer): IAnim; overload;
    function GetAnim(const AName: AnsiString; const ARandom: TAnimRandomInt): Integer; overload;
    function HasAnim(const AName: AnsiString): Boolean;
    function GetJointList(const AJointNames: AnsiString): TArray<Integer>;
    { ---- running }
    /// <summary>ServiceAnims: the frame commands between two times go to the entity; the animator stops when nothing is left to play</summary>
    procedure ServiceAnims(const AFromTime, AToTime: Integer);
    function IsAnimating(const ACurrentTime: Integer): Boolean;
    function FrameHasChanged(const ACurrentTime: Integer): Boolean;
    procedure ForceUpdate;
    procedure ClearForceUpdate;
    /// <summary>
    ///   CreateFrame: blends the channels, applies the joint modifications and the articulated
    ///   figure and computes the matrices of the joints. False when nothing had to change.
    /// </summary>
    function CreateFrame(const ACurrentTime: Integer; const AForce: Boolean): Boolean;
    { ---- channels }
    /// <summary>CurrentAnim: the animation of a channel (EAnimException when the channel does not exist)</summary>
    function CurrentAnim(const AChannel: Integer): PAnimBlend;
    /// <summary>
    ///   One of the animations of a channel (0 is the current one, the next ones are fading out);
    ///   EAnimException when the channel or the index do not exist
    /// </summary>
    function ChannelAnim(const AChannel, AIndex: Integer): PAnimBlend;
    procedure Clear(const AChannel, ACurrentTime, AClearTime: Integer);
    procedure ClearAllAnims(const ACurrentTime, AClearTime: Integer);
    procedure SetFrame(const AChannel, AAnimNum, AFrame, ACurrentTime, ABlendTime: Integer);
    procedure CycleAnim(const AChannel, AAnimNum, ACurrentTime, ABlendTime: Integer);
    procedure PlayAnim(const AChannel, AAnimNum, ACurrentTime, ABlendTime: Integer);
    /// <summary>SyncAnimChannels: copies the current anim of a channel on another one, with the frame commands disabled</summary>
    procedure SyncAnimChannels(const AChannel, AFromChannel, ACurrentTime, ABlendTime: Integer);
    { ---- the pose }
    procedure SetJointPos(const AJointNum: Integer; const ATransform: TAnimJointModTransform; const APos: TIdVec3);
    procedure SetJointAxis(const AJointNum: Integer; const ATransform: TAnimJointModTransform; const AMat: TIdMat3);
    procedure ClearJoint(const AJointNum: Integer);
    procedure ClearAllJoints;
    procedure GetDelta(const AFromTime, AToTime: Integer; out ADelta: TIdVec3);
    function GetDeltaRotation(const AFromTime, AToTime: Integer; out ADelta: TIdMat3): Boolean;
    procedure GetOrigin(const ACurrentTime: Integer; out APos: TIdVec3);
    function GetBounds(const ACurrentTime: Integer; out ABounds: TGeoBounds): Boolean;
    function GetJointTransform(const AJointHandle, ACurrentTime: Integer; out AOffset: TIdVec3;
      out AAxis: TIdMat3): Boolean;
    function GetJointLocalTransform(const AJointHandle, ACurrentTime: Integer; out AOffset: TIdVec3;
      out AAxis: TIdMat3): Boolean;
    function GetJointHandle(const AName: AnsiString): Integer;
    function GetJointName(const AHandle: Integer): AnsiString;
    function GetChannelForJoint(const AJoint: Integer): Integer;
    function GetFirstChild(const AJointNum: Integer): Integer; overload;
    function GetFirstChild(const AName: AnsiString): Integer; overload;
    { ---- articulated figure }
    procedure InitAfPose;
    procedure SetAfPoseJointMod(const AJointNum: Integer; const AKind: TAnimAfJointModType; const AAxis: TIdMat3;
      const AOrigin: TIdVec3);
    procedure FinishAfPose(const AAnimNum: Integer; const ABounds: TGeoBounds; const ATime: Integer);
    procedure SetAfPoseBlendWeight(const ABlendWeight: Single);
    procedure ClearAfPose;
    { ---- the anims by number }
    function GetAnimFlags(const AAnimNum: Integer): TAnimFlags;
    function NumFrames(const AAnimNum: Integer): Integer;
    function NumSyncedAnims(const AAnimNum: Integer): Integer;
    function AnimName(const AAnimNum: Integer): AnsiString;
    function AnimFullName(const AAnimNum: Integer): AnsiString;
    function AnimLength(const AAnimNum: Integer): Integer;
    function TotalMovementDelta(const AAnimNum: Integer): TIdVec3;
    { ---- state }
    /// <summary>The matrices of the joints (absolute) that the last <c>CreateFrame</c> computed</summary>
    property Joints: TArray<TMd5JointMat> read FJoints;
    property NumJoints: Integer read GetNumJoints;
    /// <summary>gameLocal.inCinematic and gameLocal.skipCinematic: no frame is created</summary>
    property SkipCinematic: Boolean read FSkipCinematic write FSkipCinematic;
    /// <summary>The cvar r_showSkel: a frame is always created when it is not 0</summary>
    property ShowSkeleton: Integer read FShowSkeleton write FShowSkeleton;
    /// <summary>g_debugAnim names this entity: the blends are written to the log</summary>
    property DebugInfo: Boolean read FDebugInfo write FDebugInfo;
    /// <summary>The cvar g_debugBounds: a warning for the bounds that are too big</summary>
    property DebugBounds: Boolean read FDebugBounds write FDebugBounds;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.MathCore.Float.Conversions,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.Intf;

{ TAnimator }

constructor TAnimator.Create(const ALog: IIdLibLog; const ARandom: TAnimRandomFloat);
var
  LChannel, LIndex: Integer;
begin
  inherited Create;
  FLog := ALog;
  FJointMods := TList<TAnimJointMod>.Create;
  FAfPoseJoints := TList<Integer>.Create;
  FLastTransformTime := -1;
  FFrameBounds.Clear;
  ClearAfPose;
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      FChannels[LChannel, LIndex] := TAnimBlend.Create(ALog, ARandom);
end;

destructor TAnimator.Destroy;
begin
  FreeData;
  FAfPoseJoints.Free;
  FJointMods.Free;
  inherited Destroy;
end;

function TAnimator.HasModel: Boolean;
begin
  Result := (FModelDef <> nil) and (FModelDef.Model <> nil);
end;

function TAnimator.GetNumJoints: Integer;
begin
  Result := Length(FJoints);
end;

procedure TAnimator.CheckChannel(const AChannel: Integer; const AOperation: string);
begin
  if (AChannel < 0) or (AChannel >= ANIM_NUM_ANIM_CHANNELS) then
    raise EAnimException.CreateFmt('idAnimator::%s : %s', [AOperation, Format(SAnimChannelRange, [AChannel])]);
end;

procedure TAnimator.BecomeActive(const AFlags: Integer);
begin
  if FEntity <> nil then
    FEntity.BecomeActive(AFlags);
end;

procedure TAnimator.FreeData;
var
  LChannel, LIndex: Integer;
begin
  if FEntity <> nil then
    FEntity.BecomeInactive(ANIM_THINK_ANIMATE);
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      FChannels[LChannel, LIndex].Reset(nil);
  FJointMods.Clear;
  FJoints := nil;
  FModelDef := nil;
  ForceUpdate;
end;

procedure TAnimator.PushAnims(const AChannel, ACurrentTime, ABlendTime: Integer);
var
  LIndex: Integer;
begin
  if (FChannels[AChannel, 0].GetWeight(ACurrentTime) = 0) or (FChannels[AChannel, 0].StartTime = ACurrentTime) then
    Exit;
  for LIndex := ANIM_MAX_ANIMS_PER_CHANNEL - 1 downto 1 do
    FChannels[AChannel, LIndex] := FChannels[AChannel, LIndex - 1];
  FChannels[AChannel, 0].Reset(FModelDef);
  FChannels[AChannel, 1].Clear(ACurrentTime, ABlendTime);
  ForceUpdate;
end;

function TAnimator.SetModelDef(const AModelDef: IModelDef): Boolean;
var
  LChannel, LIndex: Integer;
begin
  FreeData;
  Result := False;
  if (AModelDef = nil) or (AModelDef.Model = nil) then
    Exit;
  FModelDef := AModelDef;
  FJoints := FModelDef.SetupJoints(FRemoveOriginOffset, FFrameBounds);
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      FChannels[LChannel, LIndex].Reset(FModelDef);
  Result := True;
end;

function TAnimator.ModelDef: IModelDef;
begin
  Result := FModelDef;
end;

procedure TAnimator.SetEntity(const AEntity: IAnimatorEntity);
begin
  FEntity := AEntity;
end;

function TAnimator.GetEntity: IAnimatorEntity;
begin
  Result := FEntity;
end;

procedure TAnimator.SetRemoveOriginOffset(const ARemove: Boolean);
begin
  FRemoveOriginOffset := ARemove;
end;

function TAnimator.RemoveOrigin: Boolean;
begin
  Result := FRemoveOriginOffset;
end;

function TAnimator.NumAnims: Integer;
begin
  if FModelDef = nil then
    Result := 0
  else
    Result := FModelDef.NumAnims;
end;

function TAnimator.GetAnim(const AIndex: Integer): IAnim;
begin
  if FModelDef = nil then
    Result := nil
  else
    Result := FModelDef.GetAnimByIndex(AIndex);
end;

function TAnimator.GetAnim(const AName: AnsiString; const ARandom: TAnimRandomInt): Integer;
begin
  if FModelDef = nil then
    Result := 0
  else
    Result := FModelDef.GetAnim(AName, ARandom);
end;

function TAnimator.HasAnim(const AName: AnsiString): Boolean;
begin
  Result := (FModelDef <> nil) and FModelDef.HasAnim(AName);
end;

function TAnimator.GetJointList(const AJointNames: AnsiString): TArray<Integer>;
begin
  if FModelDef = nil then
    Result := nil
  else
    Result := FModelDef.GetJointList(AJointNames, FLog);
end;

procedure TAnimator.ServiceAnims(const AFromTime, AToTime: Integer);
var
  LChannel, LIndex: Integer;
begin
  if FModelDef = nil then
    Exit;
  if FModelDef.Model <> nil then
    for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
      for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
        FChannels[LChannel, LIndex].CallFrameCommands(FEntity, AFromTime, AToTime);
  if not IsAnimating(AToTime) then
  begin
    FStoppedAnimatingUpdate := True;
    if FEntity <> nil then
    begin
      FEntity.BecomeInactive(ANIM_THINK_ANIMATE);
      // present one more time with stopped animations so the renderer can recreate the interactions
      FEntity.BecomeActive(ANIM_THINK_UPDATE_VISUALS);
    end;
  end;
end;

function TAnimator.IsAnimating(const ACurrentTime: Integer): Boolean;
var
  LChannel, LIndex: Integer;
begin
  Result := False;
  if not HasModel then
    Exit;
  // animating with an articulated figure
  if (FAfPoseJoints.Count > 0) and (ACurrentTime <= FAfPoseTime) then
    Exit(True);
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      if not FChannels[LChannel, LIndex].IsDone(ACurrentTime) then
        Exit(True);
end;

function TAnimator.FrameHasChanged(const ACurrentTime: Integer): Boolean;
var
  LChannel, LIndex: Integer;
begin
  Result := False;
  if not HasModel then
    Exit;
  if (FAfPoseJoints.Count > 0) and (ACurrentTime <= FAfPoseTime) then
    Exit(True);
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      if FChannels[LChannel, LIndex].FrameHasChanged(ACurrentTime) then
        Exit(True);
  Result := FForceUpdate and IsAnimating(ACurrentTime);
end;

procedure TAnimator.ForceUpdate;
begin
  FLastTransformTime := -1;
  FForceUpdate := True;
end;

procedure TAnimator.ClearForceUpdate;
begin
  FForceUpdate := False;
end;

function TAnimator.BlendAfPose(var ABlendFrame: TArray<TMd5JointQuat>): Boolean;
begin
  Result := FAfPoseJoints.Count > 0;
  if Result then
    FModelDef.Model.Skeleton.BlendJoints(ABlendFrame, FAfPoseJointFrame, FAfPoseBlendWeight,
      FAfPoseJoints.ToArray);
end;

function TAnimator.BlendedPose(const ACurrentTime: Integer; out AHasAnim: Boolean): TArray<TMd5JointQuat>;
var
  LDefaultPose: TArray<TMd5JointQuat>;
  LBaseBlend, LBlendWeight: Single;
  LChannel, LIndex: Integer;
begin
  AHasAnim := False;
  // init the joint buffer
  if FAfPoseJoints.Count > 0 then
    // initialize with the pose of the articulated figure for the case where there are no other
    // animations and no modifications of its joints
    LDefaultPose := FAfPoseJointFrame
  else
    LDefaultPose := FModelDef.Model.DefaultPose;
  if Length(LDefaultPose) = 0 then
  begin
    Result := nil;
    Exit;
  end;
  Result := Copy(LDefaultPose);
  // blend the all channel
  LBaseBlend := 0.0;
  for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
    if FChannels[ANIMCHANNEL_ALL, LIndex].BlendAnim(ACurrentTime, ANIMCHANNEL_ALL, Result, LBaseBlend,
      FRemoveOriginOffset, False, FDebugInfo) then
    begin
      AHasAnim := True;
      if LBaseBlend >= 1.0 then
        Break;
    end;
  // the other channels are blended only if there is space to blend into
  if LBaseBlend < 1.0 then
    for LChannel := ANIMCHANNEL_ALL + 1 to ANIM_NUM_ANIM_CHANNELS - 1 do
    begin
      if FModelDef.NumJointsOnChannel(LChannel) = 0 then
        Continue;
      // the eyelids blend over any previous anims: they come later
      if LChannel = ANIMCHANNEL_EYELIDS then
        Continue;
      LBlendWeight := LBaseBlend;
      for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
        if FChannels[LChannel, LIndex].BlendAnim(ACurrentTime, LChannel, Result, LBlendWeight,
          FRemoveOriginOffset, False, FDebugInfo) then
        begin
          AHasAnim := True;
          // fully blended
          if LBlendWeight >= 1.0 then
            Break;
        end;
      if FDebugInfo and (FAfPoseJoints.Count = 0) and (LBlendWeight = 0) and Assigned(FLog) then
        FLog.Printf(Format('%s using default pose in model ''%s''', [ANIM_CHANNEL_NAMES[LChannel],
          string(FModelDef.GetModelName)]));
    end;
  // blend in the eyelids
  if FModelDef.NumJointsOnChannel(ANIMCHANNEL_EYELIDS) <> 0 then
  begin
    LBlendWeight := LBaseBlend;
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      if FChannels[ANIMCHANNEL_EYELIDS, LIndex].BlendAnim(ACurrentTime, ANIMCHANNEL_EYELIDS, Result,
        LBlendWeight, FRemoveOriginOffset, True, FDebugInfo) then
      begin
        AHasAnim := True;
        if LBlendWeight >= 1.0 then
          Break;
      end;
  end;
  // blend the articulated figure pose
  if BlendAfPose(Result) then
    AHasAnim := True;
end;

procedure TAnimator.ApplyRootJointMod(const AJointMod: TAnimJointMod);
begin
  case AJointMod.TransformAxis of
    jmNone:
      ;
    jmLocal:
      FJoints[0].SetRotation(AJointMod.Mat * FJoints[0].ToMat3);
    jmWorld:
      FJoints[0].SetRotation(FJoints[0].ToMat3 * AJointMod.Mat);
    jmLocalOverride, jmWorldOverride:
      FJoints[0].SetRotation(AJointMod.Mat);
  end;
  case AJointMod.TransformPos of
    jmNone:
      ;
    jmLocal:
      FJoints[0].SetTranslation(FJoints[0].ToVec3 + AJointMod.Pos);
    jmLocalOverride, jmWorld, jmWorldOverride:
      FJoints[0].SetTranslation(AJointMod.Pos);
  end;
end;

procedure TAnimator.ApplyJointMod(const AJointMod: TAnimJointMod; const AParent: Integer);
var
  LJoint: Integer;
begin
  LJoint := AJointMod.JointNum;
  case AJointMod.TransformAxis of
    jmNone:
      FJoints[LJoint].SetRotation(FJoints[LJoint].ToMat3 * FJoints[AParent].ToMat3);
    jmLocal:
      FJoints[LJoint].SetRotation(AJointMod.Mat * (FJoints[LJoint].ToMat3 * FJoints[AParent].ToMat3));
    jmLocalOverride:
      FJoints[LJoint].SetRotation(AJointMod.Mat * FJoints[AParent].ToMat3);
    jmWorld:
      FJoints[LJoint].SetRotation((FJoints[LJoint].ToMat3 * FJoints[AParent].ToMat3) * AJointMod.Mat);
    jmWorldOverride:
      FJoints[LJoint].SetRotation(AJointMod.Mat);
  end;
  case AJointMod.TransformPos of
    jmNone:
      FJoints[LJoint].SetTranslation(FJoints[AParent].ToVec3 + FJoints[LJoint].ToVec3 * FJoints[AParent].ToMat3);
    jmLocal:
      FJoints[LJoint].SetTranslation(FJoints[AParent].ToVec3 +
        (FJoints[LJoint].ToVec3 + AJointMod.Pos) * FJoints[AParent].ToMat3);
    jmLocalOverride:
      FJoints[LJoint].SetTranslation(FJoints[AParent].ToVec3 + AJointMod.Pos * FJoints[AParent].ToMat3);
    jmWorld:
      FJoints[LJoint].SetTranslation(FJoints[AParent].ToVec3 +
        FJoints[LJoint].ToVec3 * FJoints[AParent].ToMat3 + AJointMod.Pos);
    jmWorldOverride:
      FJoints[LJoint].SetTranslation(AJointMod.Pos);
  end;
end;

function TAnimator.CreateFrame(const ACurrentTime: Integer; const AForce: Boolean): Boolean;
var
  LJointFrame: TArray<TMd5JointQuat>;
  LParents: TArray<Integer>;
  LSkeleton: IMd5Skeleton;
  LHasAnim: Boolean;
  LIndex, LModIndex, LNumJoints: Integer;
  LOffset: TIdVec3;
begin
  Result := False;
  if FSkipCinematic then
    Exit;
  if not HasModel then
    Exit;
  if (not AForce) and (FShowSkeleton = 0) then
  begin
    if FLastTransformTime = ACurrentTime then
      Exit;
    if (FLastTransformTime <> -1) and (not FStoppedAnimatingUpdate) and (not IsAnimating(ACurrentTime)) then
      Exit;
  end;
  FLastTransformTime := ACurrentTime;
  FStoppedAnimatingUpdate := False;
  if FDebugInfo and Assigned(FLog) then
    FLog.Printf(Format('---------------'#10'%d: model ''%s'':'#10, [ACurrentTime, string(FModelDef.GetModelName)]));
  LJointFrame := BlendedPose(ACurrentTime, LHasAnim);
  if LJointFrame = nil then
    Exit;
  if (not LHasAnim) and (FJointMods.Count = 0) then
    // no animations were updated
    Exit;
  LNumJoints := FModelDef.NumJoints;
  LSkeleton := FModelDef.Model.Skeleton;
  LParents := FModelDef.JointParents;
  // convert the joint quaternions to rotation matrices
  FJoints := LSkeleton.ConvertToMatrices(LJointFrame);
  // check if the origin has to be modified
  if (FJointMods.Count > 0) and (FJointMods[0].JointNum = 0) then
  begin
    ApplyRootJointMod(FJointMods[0]);
    LModIndex := 1;
  end
  else
    LModIndex := 0;
  // add in the model offset
  LOffset := FModelDef.Offset;
  FJoints[0].SetTranslation(FJoints[0].ToVec3 + LOffset);
  // add in any joint modifications
  LIndex := 1;
  while LModIndex < FJointMods.Count do
  begin
    // transform any joints preceding the joint modifier
    LSkeleton.TransformJoints(FJoints, LIndex, FJointMods[LModIndex].JointNum - 1);
    LIndex := FJointMods[LModIndex].JointNum;
    ApplyJointMod(FJointMods[LModIndex], LParents[LIndex]);
    Inc(LModIndex);
    Inc(LIndex);
  end;
  // transform the rest of the hierarchy
  LSkeleton.TransformJoints(FJoints, LIndex, LNumJoints - 1);
  Result := True;
end;

function TAnimator.CurrentAnim(const AChannel: Integer): PAnimBlend;
begin
  CheckChannel(AChannel, 'CurrentAnim');
  Result := @FChannels[AChannel, 0];
end;

function TAnimator.ChannelAnim(const AChannel, AIndex: Integer): PAnimBlend;
begin
  CheckChannel(AChannel, 'ChannelAnim');
  if (AIndex < 0) or (AIndex >= ANIM_MAX_ANIMS_PER_CHANNEL) then
    raise EAnimException.CreateFmt('idAnimator::ChannelAnim : anim %d out of range', [AIndex]);
  Result := @FChannels[AChannel, AIndex];
end;

procedure TAnimator.Clear(const AChannel, ACurrentTime, AClearTime: Integer);
var
  LIndex: Integer;
begin
  CheckChannel(AChannel, 'Clear');
  for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
    FChannels[AChannel, LIndex].Clear(ACurrentTime, AClearTime);
  ForceUpdate;
end;

procedure TAnimator.ClearAllAnims(const ACurrentTime, AClearTime: Integer);
var
  LChannel: Integer;
begin
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    Clear(LChannel, ACurrentTime, AClearTime);
  ClearAfPose;
  ForceUpdate;
end;

procedure TAnimator.SetFrame(const AChannel, AAnimNum, AFrame, ACurrentTime, ABlendTime: Integer);
begin
  CheckChannel(AChannel, 'SetFrame');
  if (FModelDef = nil) or (FModelDef.GetAnimByIndex(AAnimNum) = nil) then
    Exit;
  PushAnims(AChannel, ACurrentTime, ABlendTime);
  FChannels[AChannel, 0].SetFrame(FModelDef, AAnimNum, AFrame, ACurrentTime, ABlendTime);
  BecomeActive(ANIM_THINK_ANIMATE);
end;

procedure TAnimator.CycleAnim(const AChannel, AAnimNum, ACurrentTime, ABlendTime: Integer);
begin
  CheckChannel(AChannel, 'CycleAnim');
  if (FModelDef = nil) or (FModelDef.GetAnimByIndex(AAnimNum) = nil) then
    Exit;
  PushAnims(AChannel, ACurrentTime, ABlendTime);
  FChannels[AChannel, 0].CycleAnim(FModelDef, AAnimNum, ACurrentTime, ABlendTime);
  BecomeActive(ANIM_THINK_ANIMATE);
end;

procedure TAnimator.PlayAnim(const AChannel, AAnimNum, ACurrentTime, ABlendTime: Integer);
begin
  CheckChannel(AChannel, 'PlayAnim');
  if (FModelDef = nil) or (FModelDef.GetAnimByIndex(AAnimNum) = nil) then
    Exit;
  PushAnims(AChannel, ACurrentTime, ABlendTime);
  FChannels[AChannel, 0].PlayAnim(FModelDef, AAnimNum, ACurrentTime, ABlendTime);
  BecomeActive(ANIM_THINK_ANIMATE);
end;

procedure TAnimator.SyncAnimChannels(const AChannel, AFromChannel, ACurrentTime, ABlendTime: Integer);
var
  LFromBlend, LToBlend: PAnimBlend;
  LWeight: Single;
begin
  CheckChannel(AChannel, 'SyncToChannel');
  CheckChannel(AFromChannel, 'SyncToChannel');
  LFromBlend := @FChannels[AFromChannel, 0];
  LToBlend := @FChannels[AChannel, 0];
  LWeight := LFromBlend^.BlendEndValue;
  if (LFromBlend^.Anim <> LToBlend^.Anim) or (LFromBlend^.GetStartTime <> LToBlend^.GetStartTime) or
    (LFromBlend^.GetEndTime <> LToBlend^.GetEndTime) then
  begin
    PushAnims(AChannel, ACurrentTime, ABlendTime);
    LToBlend^ := LFromBlend^;
    LToBlend^.BlendStartValue := 0.0;
    LToBlend^.BlendEndValue := 0.0;
  end;
  LToBlend^.SetWeight(LWeight, ACurrentTime - 1, ABlendTime);
  // disable the frame commands on the current channel so that they are not called twice
  LToBlend^.SetAllowFrameCommands(False);
  BecomeActive(ANIM_THINK_ANIMATE);
end;

function TAnimator.FindJointMod(const AJointNum: Integer; out AIndex: Integer): Boolean;
begin
  Result := False;
  AIndex := 0;
  while AIndex < FJointMods.Count do
  begin
    if FJointMods[AIndex].JointNum = AJointNum then
      Exit(True)
    else if FJointMods[AIndex].JointNum > AJointNum then
      Exit(False);
    Inc(AIndex);
  end;
end;

function TAnimator.InsertJointMod(const AJointNum, AIndex: Integer): TAnimJointMod;
begin
  Result.JointNum := AJointNum;
  Result.Mat := TIdMat3.Identity;
  Result.Pos.Zero;
  Result.TransformPos := jmNone;
  Result.TransformAxis := jmNone;
  FJointMods.Insert(AIndex, Result);
end;

procedure TAnimator.SetJointPos(const AJointNum: Integer; const ATransform: TAnimJointModTransform;
  const APos: TIdVec3);
var
  LIndex: Integer;
  LMod: TAnimJointMod;
begin
  if (not HasModel) or (AJointNum < 0) or (AJointNum >= NumJoints) then
    Exit;
  if FindJointMod(AJointNum, LIndex) then
    LMod := FJointMods[LIndex]
  else
    LMod := InsertJointMod(AJointNum, LIndex);
  LMod.Pos := APos;
  LMod.TransformPos := ATransform;
  FJointMods[LIndex] := LMod;
  BecomeActive(ANIM_THINK_ANIMATE);
  ForceUpdate;
end;

procedure TAnimator.SetJointAxis(const AJointNum: Integer; const ATransform: TAnimJointModTransform;
  const AMat: TIdMat3);
var
  LIndex: Integer;
  LMod: TAnimJointMod;
begin
  if (not HasModel) or (AJointNum < 0) or (AJointNum >= NumJoints) then
    Exit;
  if FindJointMod(AJointNum, LIndex) then
    LMod := FJointMods[LIndex]
  else
    LMod := InsertJointMod(AJointNum, LIndex);
  LMod.Mat := AMat;
  LMod.TransformAxis := ATransform;
  FJointMods[LIndex] := LMod;
  BecomeActive(ANIM_THINK_ANIMATE);
  ForceUpdate;
end;

procedure TAnimator.ClearJoint(const AJointNum: Integer);
var
  LIndex: Integer;
begin
  if (not HasModel) or (AJointNum < 0) or (AJointNum >= NumJoints) then
    Exit;
  if FindJointMod(AJointNum, LIndex) then
  begin
    FJointMods.Delete(LIndex);
    ForceUpdate;
  end;
end;

procedure TAnimator.ClearAllJoints;
begin
  if FJointMods.Count > 0 then
    ForceUpdate;
  FJointMods.Clear;
end;

procedure TAnimator.GetDelta(const AFromTime, AToTime: Integer; out ADelta: TIdVec3);
var
  LBlendWeight: Single;
  LIndex: Integer;
begin
  ADelta.Zero;
  if (not HasModel) or (AFromTime = AToTime) then
    Exit;
  LBlendWeight := 0.0;
  for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
    FChannels[ANIMCHANNEL_ALL, LIndex].BlendDelta(AFromTime, AToTime, ADelta, LBlendWeight);
  if (FModelDef.NumJoints > 0) and (FModelDef.JointInfo[0].Channel <> 0) then
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      FChannels[FModelDef.JointInfo[0].Channel, LIndex].BlendDelta(AFromTime, AToTime, ADelta, LBlendWeight);
end;

function TAnimator.GetDeltaRotation(const AFromTime, AToTime: Integer; out ADelta: TIdMat3): Boolean;
var
  LBlendWeight: Single;
  LIndex: Integer;
  LQuat: TIdQuat;
begin
  ADelta := TIdMat3.Identity;
  Result := False;
  if (not HasModel) or (AFromTime = AToTime) then
    Exit;
  LQuat.SetValues(0.0, 0.0, 0.0, 1.0);
  LBlendWeight := 0.0;
  for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
    FChannels[ANIMCHANNEL_ALL, LIndex].BlendDeltaRotation(AFromTime, AToTime, LQuat, LBlendWeight);
  if (FModelDef.NumJoints > 0) and (FModelDef.JointInfo[0].Channel <> 0) then
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      FChannels[FModelDef.JointInfo[0].Channel, LIndex].BlendDeltaRotation(AFromTime, AToTime, LQuat,
        LBlendWeight);
  if LBlendWeight > 0.0 then
  begin
    ADelta := TIdRotationConversions.QuatToMat(LQuat);
    Result := True;
  end;
end;

procedure TAnimator.GetOrigin(const ACurrentTime: Integer; out APos: TIdVec3);
var
  LBlendWeight: Single;
  LIndex: Integer;
begin
  APos.Zero;
  if not HasModel then
    Exit;
  LBlendWeight := 0.0;
  for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
    FChannels[ANIMCHANNEL_ALL, LIndex].BlendOrigin(ACurrentTime, APos, LBlendWeight, FRemoveOriginOffset);
  if (FModelDef.NumJoints > 0) and (FModelDef.JointInfo[0].Channel <> 0) then
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      FChannels[FModelDef.JointInfo[0].Channel, LIndex].BlendOrigin(ACurrentTime, APos, LBlendWeight,
        FRemoveOriginOffset);
  APos := APos + FModelDef.Offset;
end;

function TAnimator.GetBounds(const ACurrentTime: Integer; out ABounds: TGeoBounds): Boolean;
var
  LChannel, LIndex, LCount: Integer;
  LOffset: TIdVec3;
begin
  Result := False;
  ABounds.Zero;
  if not HasModel then
    Exit;
  if FAfPoseJoints.Count > 0 then
  begin
    ABounds := FAfPoseBounds;
    LCount := 1;
  end
  else
  begin
    ABounds.Clear;
    LCount := 0;
  end;
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    for LIndex := 0 to ANIM_MAX_ANIMS_PER_CHANNEL - 1 do
      if FChannels[LChannel, LIndex].AddBounds(ACurrentTime, ABounds, FRemoveOriginOffset) then
        Inc(LCount);
  if LCount = 0 then
  begin
    if not FFrameBounds.IsCleared then
    begin
      ABounds := FFrameBounds;
      Exit(True);
    end;
    ABounds.Zero;
    Exit(False);
  end;
  LOffset := FModelDef.Offset;
  ABounds.TranslateSelf(TGeoVec3.Make(LOffset.X, LOffset.Y, LOffset.Z));
  if FDebugBounds and Assigned(FLog) and
    ((ABounds.Maxs.X - ABounds.Mins.X > 2048) or (ABounds.Maxs.Y - ABounds.Mins.Y > 2048)) then
    FLog.Warning(Format('big frameBounds on model ''%s'': %f,%f',
      [string(FModelDef.Model.Name), ABounds.Maxs.X - ABounds.Mins.X, ABounds.Maxs.Y - ABounds.Mins.Y]));
  FFrameBounds := ABounds;
  Result := True;
end;

function TAnimator.GetJointTransform(const AJointHandle, ACurrentTime: Integer; out AOffset: TIdVec3;
  out AAxis: TIdMat3): Boolean;
begin
  Result := False;
  if (FModelDef = nil) or (AJointHandle < 0) or (AJointHandle >= FModelDef.NumJoints) then
    Exit;
  CreateFrame(ACurrentTime, False);
  AOffset := FJoints[AJointHandle].ToVec3;
  AAxis := FJoints[AJointHandle].ToMat3;
  Result := True;
end;

function TAnimator.GetJointLocalTransform(const AJointHandle, ACurrentTime: Integer; out AOffset: TIdVec3;
  out AAxis: TIdMat3): Boolean;
var
  LMatrix: TMd5JointMat;
begin
  Result := False;
  if (FModelDef = nil) or (AJointHandle < 0) or (AJointHandle >= FModelDef.NumJoints) then
    Exit;
  CreateFrame(ACurrentTime, False);
  if AJointHandle > 0 then
  begin
    LMatrix := FJoints[AJointHandle];
    LMatrix.UntransformBy(FJoints[FModelDef.JointInfo[AJointHandle].ParentNum]);
    AOffset := LMatrix.ToVec3;
    AAxis := LMatrix.ToMat3;
  end
  else
  begin
    AOffset := FJoints[AJointHandle].ToVec3;
    AAxis := FJoints[AJointHandle].ToMat3;
  end;
  Result := True;
end;

function TAnimator.GetJointHandle(const AName: AnsiString): Integer;
begin
  if not HasModel then
    Result := MD5_INVALID_JOINT
  else
    Result := FModelDef.Model.GetJointHandle(AName);
end;

function TAnimator.GetJointName(const AHandle: Integer): AnsiString;
begin
  if not HasModel then
    Result := ''
  else
    Result := FModelDef.Model.GetJointName(AHandle);
end;

function TAnimator.GetChannelForJoint(const AJoint: Integer): Integer;
begin
  if FModelDef = nil then
    raise EAnimException.Create('idAnimator::GetChannelForJoint: NULL model');
  if (AJoint < 0) or (AJoint >= NumJoints) then
    raise EAnimException.CreateFmt('idAnimator::GetChannelForJoint: invalid joint num (%d)', [AJoint]);
  Result := FModelDef.JointInfo[AJoint].Channel;
end;

function TAnimator.GetFirstChild(const AJointNum: Integer): Integer;
var
  LIndex: Integer;
begin
  if FModelDef = nil then
    Exit(MD5_INVALID_JOINT);
  if FModelDef.NumJoints = 0 then
    Exit(AJointNum);
  for LIndex := 0 to FModelDef.NumJoints - 1 do
    if FModelDef.JointInfo[LIndex].ParentNum = AJointNum then
      Exit(FModelDef.JointInfo[LIndex].Num);
  Result := AJointNum;
end;

function TAnimator.GetFirstChild(const AName: AnsiString): Integer;
begin
  Result := GetFirstChild(GetJointHandle(AName));
end;

procedure TAnimator.InitAfPose;
var
  LCount: Integer;
begin
  if FModelDef = nil then
    Exit;
  LCount := FModelDef.NumJoints;
  FAfPoseJoints.Clear;
  SetLength(FAfPoseJointMods, LCount);
  SetLength(FAfPoseJointFrame, LCount);
end;

function TAnimator.AfPoseIndex(const AJointNum: Integer): Integer;
var
  LLow, LHigh, LMiddle: Integer;
begin
  // idBinSearch_GreaterEqual: the first index whose joint is not less than the one given
  LLow := 0;
  LHigh := FAfPoseJoints.Count;
  while LLow < LHigh do
  begin
    LMiddle := (LLow + LHigh) div 2;
    if FAfPoseJoints[LMiddle] < AJointNum then
      LLow := LMiddle + 1
    else
      LHigh := LMiddle;
  end;
  Result := LLow;
end;

procedure TAnimator.SetAfPoseJointMod(const AJointNum: Integer; const AKind: TAnimAfJointModType;
  const AAxis: TIdMat3; const AOrigin: TIdVec3);
var
  LIndex: Integer;
begin
  FAfPoseJointMods[AJointNum].Kind := AKind;
  FAfPoseJointMods[AJointNum].Axis := AAxis;
  FAfPoseJointMods[AJointNum].Origin := AOrigin;
  LIndex := AfPoseIndex(AJointNum);
  if (LIndex >= FAfPoseJoints.Count) or (AJointNum <> FAfPoseJoints[LIndex]) then
    FAfPoseJoints.Insert(LIndex, AJointNum);
end;

procedure TAnimator.FinishAfPose(const AAnimNum: Integer; const ABounds: TGeoBounds; const ATime: Integer);
var
  LAnim: IAnim;
  LMd5Anim: IMd5Anim;
  LSkeleton: IMd5Skeleton;
  LParents: TArray<Integer>;
  LJointFrame: TArray<TMd5JointQuat>;
  LJoints: TArray<TMd5JointMat>;
  LBlendJoints: TArray<Boolean>;
  LNumJoints, LIndex, LModIndex, LJointMod, LParentNum, LJointNum: Integer;
begin
  if FModelDef = nil then
    Exit;
  LAnim := FModelDef.GetAnimByIndex(AAnimNum);
  if LAnim = nil then
    Exit;
  LNumJoints := FModelDef.NumJoints;
  if LNumJoints = 0 then
    Exit;
  LMd5Anim := LAnim.GetMd5Anim(0);
  if LNumJoints <> LMd5Anim.NumJoints then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SAnimModelJointCount, [string(FModelDef.Model.Name), string(LMd5Anim.Name)]));
    Exit;
  end;
  LSkeleton := FModelDef.Model.Skeleton;
  LParents := FModelDef.JointParents;
  LJointFrame := LMd5Anim.GetSingleFrame(0, FModelDef.GetChannelJoints(ANIMCHANNEL_ALL));
  if FRemoveOriginOffset then
    LJointFrame[0].T.Zero;
  // convert the joint quaternions to joint matrices
  LJoints := LSkeleton.ConvertToMatrices(LJointFrame);
  // the first joint is always the root of the hierarchy
  if (FAfPoseJoints.Count > 0) and (FAfPoseJoints[0] = 0) then
  begin
    case FAfPoseJointMods[0].Kind of
      afAxis:
        LJoints[0].SetRotation(FAfPoseJointMods[0].Axis);
      afOrigin:
        LJoints[0].SetTranslation(FAfPoseJointMods[0].Origin);
      afBoth:
        begin
          LJoints[0].SetRotation(FAfPoseJointMods[0].Axis);
          LJoints[0].SetTranslation(FAfPoseJointMods[0].Origin);
        end;
    end;
    LModIndex := 1;
  end
  else
    LModIndex := 0;
  // transform the child joints
  LIndex := 1;
  while LModIndex < FAfPoseJoints.Count do
  begin
    LJointMod := FAfPoseJoints[LModIndex];
    // transform any joints preceding the joint modifier
    LSkeleton.TransformJoints(LJoints, LIndex, LJointMod - 1);
    LIndex := LJointMod;
    LParentNum := LParents[LIndex];
    case FAfPoseJointMods[LJointMod].Kind of
      afAxis:
        begin
          LJoints[LIndex].SetRotation(FAfPoseJointMods[LJointMod].Axis);
          LJoints[LIndex].SetTranslation(LJoints[LParentNum].ToVec3 +
            LJoints[LIndex].ToVec3 * LJoints[LParentNum].ToMat3);
        end;
      afOrigin:
        begin
          LJoints[LIndex].SetRotation(LJoints[LIndex].ToMat3 * LJoints[LParentNum].ToMat3);
          LJoints[LIndex].SetTranslation(FAfPoseJointMods[LJointMod].Origin);
        end;
      afBoth:
        begin
          LJoints[LIndex].SetRotation(FAfPoseJointMods[LJointMod].Axis);
          LJoints[LIndex].SetTranslation(FAfPoseJointMods[LJointMod].Origin);
        end;
    end;
    Inc(LModIndex);
    Inc(LIndex);
  end;
  // transform the rest of the hierarchy
  LSkeleton.TransformJoints(LJoints, LIndex, LNumJoints - 1);
  // untransform the hierarchy
  LSkeleton.UntransformJoints(LJoints, 1, LNumJoints - 1);
  // convert the joint matrices back to joint quaternions
  FAfPoseJointFrame := LSkeleton.ConvertToQuats(LJoints);
  // mark all the modified joints and their parents
  SetLength(LBlendJoints, LNumJoints);
  for LIndex := 0 to FAfPoseJoints.Count - 1 do
  begin
    LJointNum := FAfPoseJoints[LIndex];
    while LJointNum <> MD5_INVALID_JOINT do
    begin
      LBlendJoints[LJointNum] := True;
      LJointNum := LParents[LJointNum];
    end;
  end;
  // lock all the parents of the modified joints
  FAfPoseJoints.Clear;
  for LIndex := 0 to LNumJoints - 1 do
    if LBlendJoints[LIndex] then
      FAfPoseJoints.Add(LIndex);
  FAfPoseBounds := ABounds;
  FAfPoseTime := ATime;
  ForceUpdate;
end;

procedure TAnimator.SetAfPoseBlendWeight(const ABlendWeight: Single);
begin
  FAfPoseBlendWeight := ABlendWeight;
end;

procedure TAnimator.ClearAfPose;
begin
  if FAfPoseJoints.Count > 0 then
    ForceUpdate;
  FAfPoseBlendWeight := 1.0;
  FAfPoseJoints.Clear;
  FAfPoseBounds.Clear;
  FAfPoseTime := 0;
end;

function TAnimator.GetAnimFlags(const AAnimNum: Integer): TAnimFlags;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.Flags
  else
    FillChar(Result, SizeOf(Result), 0);
end;

function TAnimator.NumFrames(const AAnimNum: Integer): Integer;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.NumFrames
  else
    Result := 0;
end;

function TAnimator.NumSyncedAnims(const AAnimNum: Integer): Integer;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.NumAnims
  else
    Result := 0;
end;

function TAnimator.AnimName(const AAnimNum: Integer): AnsiString;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.Name
  else
    Result := '';
end;

function TAnimator.AnimFullName(const AAnimNum: Integer): AnsiString;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.FullName
  else
    Result := '';
end;

function TAnimator.AnimLength(const AAnimNum: Integer): Integer;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.Length
  else
    Result := 0;
end;

function TAnimator.TotalMovementDelta(const AAnimNum: Integer): TIdVec3;
var
  LAnim: IAnim;
begin
  LAnim := GetAnim(AAnimNum);
  if LAnim <> nil then
    Result := LAnim.TotalMovementDelta
  else
    Result.Zero;
end;

end.
