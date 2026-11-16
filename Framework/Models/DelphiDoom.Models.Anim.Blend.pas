{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - one animation of a channel (idAnimBlend)    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim_Blend.cpp }
{  and Anim.h (idAnimBlend). Copyright (C) 1999-2011 id Software LLC, a        }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Framework\IdLib); the repository as a whole is GPL v2 or  }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Blend;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.MathCore.Float.Quat,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.Blend.Types;

type
  PAnimBlend = ^TAnimBlend;

  /// <summary>
  ///   One animation of a channel and how it fades in and out (idAnimBlend). It is a value, as in
  ///   the original: <c>idAnimator</c> copies it when it pushes the animations of a channel. The
  ///   time is always an argument, in milliseconds. The fields are public because the animator
  ///   (<c>friend class idAnimator</c>) reads and writes them; nobody else should.
  /// </summary>
  TAnimBlend = record
  strict private
    FLog: IIdLibLog;
    FRandom: TAnimRandomFloat;
    /// <summary>
    ///   The start of SetFrame, CycleAnim and PlayAnim: Reset, then the anim, which must exist and
    ///   fit the model (the original warns and leaves the blend reset)
    /// </summary>
    function Prepare(const AModelDef: IModelDef; const AAnimNum: Integer; out AAnim: IAnim): Boolean;
  public
    ModelDef: IModelDef;
    StartTime: Integer;
    EndTime: Integer;
    TimeOffset: Integer;
    Rate: Single;
    BlendStartTime: Integer;
    BlendDuration: Integer;
    BlendStartValue: Single;
    BlendEndValue: Single;
    AnimWeights: array[0..ANIM_MAX_SYNCED_ANIMS - 1] of Single;
    /// <summary>cycle, a short in the original: -1 loops forever</summary>
    Cycle: SmallInt;
    /// <summary>frame, a short: 0 is not a single frame blend, otherwise the frame number (1 is the first)</summary>
    Frame: SmallInt;
    AnimNum: SmallInt;
    AllowMove: Boolean;
    AllowFrameCommands: Boolean;
    /// <summary>
    ///   A blend with no animation (idAnimBlend::idAnimBlend); ALog gets the warnings, ARandom
    ///   (nil: always 0) the starts at a random time
    /// </summary>
    class function Create(const ALog: IIdLibLog; const ARandom: TAnimRandomFloat): TAnimBlend; static;
    procedure Reset(const AModelDef: IModelDef);
    function Anim: IAnim;
    function AnimName: AnsiString;
    function AnimFullName: AnsiString;
    function GetWeight(const ACurrentTime: Integer): Single;
    function GetFinalWeight: Single;
    procedure SetWeight(const ANewWeight: Single; const ACurrentTime, ABlendTime: Integer);
    function NumSyncedAnims: Integer;
    function SetSyncedAnimWeight(const ANumber: Integer; const AWeight: Single): Boolean;
    procedure SetFrame(const AModelDef: IModelDef; const AAnimNum, AFrame, ACurrentTime, ABlendTime: Integer);
    procedure CycleAnim(const AModelDef: IModelDef; const AAnimNum, ACurrentTime, ABlendTime: Integer);
    procedure PlayAnim(const AModelDef: IModelDef; const AAnimNum, ACurrentTime, ABlendTime: Integer);
    procedure Clear(const ACurrentTime, AClearTime: Integer);
    function IsDone(const ACurrentTime: Integer): Boolean;
    function FrameHasChanged(const ACurrentTime: Integer): Boolean;
    function GetCycleCount: Integer;
    procedure SetCycleCount(const ACount: Integer);
    procedure SetPlaybackRate(const ACurrentTime: Integer; const ANewRate: Single);
    function GetPlaybackRate: Single;
    procedure SetStartTime(const AStartTime: Integer);
    function GetStartTime: Integer;
    function GetEndTime: Integer;
    function PlayLength: Integer;
    function NumFrames: Integer;
    function Length: Integer;
    procedure SetAllowMovement(const AAllow: Boolean);
    procedure SetAllowFrameCommands(const AAllow: Boolean);
    function GetAnimNum: Integer;
    /// <summary>The time inside the anim: the frame of a single frame blend, the time scaled by the rate and wrapped for a cycle</summary>
    function AnimTime(const ACurrentTime: Integer): Integer;
    function GetFrameNumber(const ACurrentTime: Integer): Integer;
    /// <summary>
    ///   idAnimBlend::CallFrameCommands: the commands of the frames between two times go to the
    ///   sink. Nothing happens without a sink, with the commands disabled, on a single frame
    ///   blend or on an anim that is over.
    /// </summary>
    procedure CallFrameCommands(const ASink: IAnimFrameCommandSink; const AFromTime, AToTime: Integer);
    /// <summary>
    ///   BlendAnim: mixes the pose of this anim into ABlendFrame (one pose for the whole model).
    ///   ABlendWeight is what the channels before have already put (0 when nothing): the result is
    ///   true when the anim contributed. With ABlendWeight 0 on the channel "all" the frame is
    ///   replaced by the pose of the anim (the original writes into it directly).
    /// </summary>
    function BlendAnim(const ACurrentTime, AChannel: Integer; var ABlendFrame: TArray<TMd5JointQuat>;
      var ABlendWeight: Single; const ARemoveOriginOffset, AOverrideBlend, APrintInfo: Boolean): Boolean;
    procedure BlendOrigin(const ACurrentTime: Integer; var ABlendPos: TIdVec3; var ABlendWeight: Single;
      const ARemoveOriginOffset: Boolean);
    procedure BlendDelta(const AFromTime, AToTime: Integer; var ABlendDelta: TIdVec3; var ABlendWeight: Single);
    /// <summary>BlendDeltaRotation, with the original's slerp of the second quaternion from the first one</summary>
    procedure BlendDeltaRotation(const AFromTime, AToTime: Integer; var ABlendDelta: TIdQuat;
      var ABlendWeight: Single);
    function AddBounds(const ACurrentTime: Integer; var ABounds: TGeoBounds;
      const ARemoveOriginOffset: Boolean): Boolean;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3,
  DelphiDoom.Models.Md5.Types,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Anim.FrameCommandCaller;

{ TAnimBlend }

class function TAnimBlend.Create(const ALog: IIdLibLog; const ARandom: TAnimRandomFloat): TAnimBlend;
begin
  Result.FLog := ALog;
  Result.FRandom := ARandom;
  Result.Reset(nil);
end;

procedure TAnimBlend.Reset(const AModelDef: IModelDef);
var
  LIndex: Integer;
begin
  ModelDef := AModelDef;
  Cycle := 1;
  StartTime := 0;
  EndTime := 0;
  TimeOffset := 0;
  Rate := 1.0;
  Frame := 0;
  AllowMove := True;
  AllowFrameCommands := True;
  AnimNum := 0;
  for LIndex := 0 to ANIM_MAX_SYNCED_ANIMS - 1 do
    AnimWeights[LIndex] := 0;
  BlendStartValue := 0;
  BlendEndValue := 0;
  BlendStartTime := 0;
  BlendDuration := 0;
end;

function TAnimBlend.Prepare(const AModelDef: IModelDef; const AAnimNum: Integer; out AAnim: IAnim): Boolean;
var
  LMd5Anim: IMd5Anim;
begin
  Reset(AModelDef);
  Result := False;
  AAnim := nil;
  if AModelDef = nil then
    Exit;
  AAnim := AModelDef.GetAnimByIndex(AAnimNum);
  if AAnim = nil then
    Exit;
  LMd5Anim := AAnim.GetMd5Anim(0);
  if LMd5Anim = nil then
    Exit;
  if AModelDef.NumJoints <> LMd5Anim.NumJoints then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SAnimModelJointCount, [string(AModelDef.GetModelName), string(LMd5Anim.Name)]));
    Exit;
  end;
  Result := True;
end;

function TAnimBlend.Anim: IAnim;
begin
  if ModelDef = nil then
    Result := nil
  else
    Result := ModelDef.GetAnimByIndex(AnimNum);
end;

function TAnimBlend.AnimFullName: AnsiString;
var
  LAnim: IAnim;
begin
  LAnim := Anim;
  if LAnim = nil then
    Result := ''
  else
    Result := LAnim.FullName;
end;

function TAnimBlend.AnimName: AnsiString;
var
  LAnim: IAnim;
begin
  LAnim := Anim;
  if LAnim = nil then
    Result := ''
  else
    Result := LAnim.Name;
end;

function TAnimBlend.NumFrames: Integer;
var
  LAnim: IAnim;
begin
  LAnim := Anim;
  if LAnim = nil then
    Result := 0
  else
    Result := LAnim.NumFrames;
end;

function TAnimBlend.Length: Integer;
var
  LAnim: IAnim;
begin
  LAnim := Anim;
  if LAnim = nil then
    Result := 0
  else
    Result := LAnim.Length;
end;

function TAnimBlend.GetWeight(const ACurrentTime: Integer): Single;
var
  LTimeDelta: Integer;
  LFraction, LSpan: Single;
begin
  LTimeDelta := ACurrentTime - BlendStartTime;
  if LTimeDelta <= 0 then
    Result := BlendStartValue
  else if LTimeDelta >= BlendDuration then
    Result := BlendEndValue
  else
  begin
    LFraction := Single(LTimeDelta) / Single(BlendDuration);
    LSpan := BlendEndValue - BlendStartValue;
    LSpan := LSpan * LFraction;
    Result := BlendStartValue + LSpan;
  end;
end;

function TAnimBlend.GetFinalWeight: Single;
begin
  Result := BlendEndValue;
end;

procedure TAnimBlend.SetWeight(const ANewWeight: Single; const ACurrentTime, ABlendTime: Integer);
begin
  BlendStartValue := GetWeight(ACurrentTime);
  BlendEndValue := ANewWeight;
  BlendStartTime := ACurrentTime - 1;
  BlendDuration := ABlendTime;
  if ANewWeight = 0 then
    EndTime := ACurrentTime + ABlendTime;
end;

function TAnimBlend.NumSyncedAnims: Integer;
var
  LAnim: IAnim;
begin
  LAnim := Anim;
  if LAnim = nil then
    Result := 0
  else
    Result := LAnim.NumAnims;
end;

function TAnimBlend.SetSyncedAnimWeight(const ANumber: Integer; const AWeight: Single): Boolean;
var
  LAnim: IAnim;
begin
  LAnim := Anim;
  // the original lets the number be NumAnims itself (it writes one past the anims it plays)
  Result := (LAnim <> nil) and (ANumber >= 0) and (ANumber <= LAnim.NumAnims) and
    (ANumber < ANIM_MAX_SYNCED_ANIMS);
  if Result then
    AnimWeights[ANumber] := AWeight;
end;

procedure TAnimBlend.SetFrame(const AModelDef: IModelDef; const AAnimNum, AFrame, ACurrentTime,
  ABlendTime: Integer);
var
  LAnim: IAnim;
  LFrame: Integer;
begin
  if not Prepare(AModelDef, AAnimNum, LAnim) then
    Exit;
  AnimNum := SmallInt(AAnimNum);
  StartTime := ACurrentTime;
  EndTime := -1;
  Cycle := -1;
  AnimWeights[0] := 1.0;
  LFrame := AFrame;
  // a frame of 0 means it is not a single frame blend, so it becomes frame + 1
  if LFrame <= 0 then
    LFrame := 1
  else if LFrame > LAnim.NumFrames then
    LFrame := LAnim.NumFrames;
  Frame := SmallInt(LFrame);
  BlendEndValue := 1.0;
  BlendStartTime := ACurrentTime - 1;
  BlendDuration := ABlendTime;
  BlendStartValue := 0.0;
end;

procedure TAnimBlend.CycleAnim(const AModelDef: IModelDef; const AAnimNum, ACurrentTime, ABlendTime: Integer);
var
  LAnim: IAnim;
  LRandom, LOffset: Single;
begin
  if not Prepare(AModelDef, AAnimNum, LAnim) then
    Exit;
  AnimNum := SmallInt(AAnimNum);
  AnimWeights[0] := 1.0;
  EndTime := -1;
  Cycle := -1;
  if LAnim.Flags.RandomCycleStart then
  begin
    // start the animation at a random time so that characters do not walk in sync
    LRandom := 0;
    if Assigned(FRandom) then
      LRandom := FRandom();
    LOffset := LRandom * LAnim.Length;
    LOffset := Single(ACurrentTime) - LOffset;
    StartTime := Trunc(LOffset);
  end
  else
    StartTime := ACurrentTime;
  BlendEndValue := 1.0;
  BlendStartTime := ACurrentTime - 1;
  BlendDuration := ABlendTime;
  BlendStartValue := 0.0;
end;

procedure TAnimBlend.PlayAnim(const AModelDef: IModelDef; const AAnimNum, ACurrentTime, ABlendTime: Integer);
var
  LAnim: IAnim;
begin
  if not Prepare(AModelDef, AAnimNum, LAnim) then
    Exit;
  AnimNum := SmallInt(AAnimNum);
  StartTime := ACurrentTime;
  EndTime := StartTime + LAnim.Length;
  Cycle := 1;
  AnimWeights[0] := 1.0;
  BlendEndValue := 1.0;
  BlendStartTime := ACurrentTime - 1;
  BlendDuration := ABlendTime;
  BlendStartValue := 0.0;
end;

procedure TAnimBlend.Clear(const ACurrentTime, AClearTime: Integer);
begin
  if AClearTime = 0 then
    Reset(ModelDef)
  else
    SetWeight(0.0, ACurrentTime, AClearTime);
end;

function TAnimBlend.IsDone(const ACurrentTime: Integer): Boolean;
begin
  if (Frame = 0) and (EndTime > 0) and (ACurrentTime >= EndTime) then
    Exit(True);
  Result := (BlendEndValue <= 0.0) and (ACurrentTime >= (BlendStartTime + BlendDuration));
end;

function TAnimBlend.FrameHasChanged(const ACurrentTime: Integer): Boolean;
begin
  // without an anim, or when it is over, nothing changes
  if AnimNum = 0 then
    Exit(False);
  if (EndTime > 0) and (ACurrentTime > EndTime) then
    Exit(False);
  // a changing blend weight needs an update
  if (ACurrentTime < (BlendStartTime + BlendDuration)) and (BlendStartValue <> BlendEndValue) then
    Exit(True);
  // a single frame anim that is not on the frame it started on does not need one
  if ((Frame <> 0) or (NumFrames = 1)) and (ACurrentTime <> StartTime) then
    Exit(False);
  Result := True;
end;

function TAnimBlend.GetCycleCount: Integer;
begin
  Result := Cycle;
end;

procedure TAnimBlend.SetCycleCount(const ACount: Integer);
var
  LAnim: IAnim;
  LCycle: Integer;
  LBase, LScaled: Single;
begin
  LAnim := Anim;
  if LAnim = nil then
  begin
    Cycle := -1;
    EndTime := 0;
    Exit;
  end;
  Cycle := SmallInt(ACount);
  if Cycle < 0 then
  begin
    Cycle := -1;
    EndTime := -1;
  end
  else
  begin
    if Cycle = 0 then
    begin
      Cycle := 1;
      LCycle := 1;
    end
    else
      LCycle := Cycle;
    // most of the time the rate is 1: the original avoids the conversion to float and back
    if Rate = 1.0 then
      EndTime := StartTime - TimeOffset + LAnim.Length * LCycle
    else if Rate <> 0.0 then
    begin
      LBase := Single(StartTime - TimeOffset);
      LScaled := Single(LAnim.Length * LCycle) / Rate;
      LBase := LBase + LScaled;
      EndTime := Trunc(LBase);
    end
    else
      EndTime := -1;
  end;
end;

procedure TAnimBlend.SetPlaybackRate(const ACurrentTime: Integer; const ANewRate: Single);
var
  LAnimTime: Integer;
  LScaled: Single;
begin
  if Rate = ANewRate then
    Exit;
  LAnimTime := AnimTime(ACurrentTime);
  if ANewRate = 1.0 then
    TimeOffset := LAnimTime - (ACurrentTime - StartTime)
  else
  begin
    LScaled := Single(ACurrentTime - StartTime) * ANewRate;
    LScaled := Single(LAnimTime) - LScaled;
    TimeOffset := Trunc(LScaled);
  end;
  Rate := ANewRate;
  // update the anim end time
  SetCycleCount(Cycle);
end;

function TAnimBlend.GetPlaybackRate: Single;
begin
  Result := Rate;
end;

procedure TAnimBlend.SetStartTime(const AStartTime: Integer);
begin
  StartTime := AStartTime;
  SetCycleCount(Cycle);
end;

function TAnimBlend.GetStartTime: Integer;
begin
  if AnimNum = 0 then
    Result := 0
  else
    Result := StartTime;
end;

function TAnimBlend.GetEndTime: Integer;
begin
  if AnimNum = 0 then
    Result := 0
  else
    Result := EndTime;
end;

function TAnimBlend.PlayLength: Integer;
begin
  if AnimNum = 0 then
    Result := 0
  else if EndTime < 0 then
    Result := -1
  else
    Result := EndTime - StartTime + TimeOffset;
end;

procedure TAnimBlend.SetAllowMovement(const AAllow: Boolean);
begin
  AllowMove := AAllow;
end;

procedure TAnimBlend.SetAllowFrameCommands(const AAllow: Boolean);
begin
  AllowFrameCommands := AAllow;
end;

function TAnimBlend.GetAnimNum: Integer;
begin
  Result := AnimNum;
end;

function TAnimBlend.AnimTime(const ACurrentTime: Integer): Integer;
var
  LAnim: IAnim;
  LTime, LLength: Integer;
  LScaled: Single;
begin
  LAnim := Anim;
  if LAnim = nil then
    Exit(0);
  if Frame <> 0 then
    Exit(AnimFrameToMilliseconds(Frame - 1));
  // most of the time the rate is 1: the original avoids the conversion to float and back
  if Rate = 1.0 then
    LTime := ACurrentTime - StartTime + TimeOffset
  else
  begin
    LScaled := Single(ACurrentTime - StartTime) * Rate;
    LTime := Trunc(LScaled) + TimeOffset;
  end;
  // a cycling animation keeps its time inside the length of the anim
  LLength := LAnim.Length;
  if (Cycle < 0) and (LLength > 0) then
  begin
    LTime := LTime mod LLength;
    // the time wraps after 24 days: the remainder is negative then
    if LTime < 0 then
      Inc(LTime, LLength);
  end;
  Result := LTime;
end;

function TAnimBlend.GetFrameNumber(const ACurrentTime: Integer): Integer;
var
  LAnim: IAnim;
  LBlend: TMd5FrameBlend;
begin
  LAnim := Anim;
  if LAnim = nil then
    Exit(1);
  if Frame <> 0 then
    Exit(Frame);
  LBlend := LAnim.GetMd5Anim(0).ConvertTimeToFrame(AnimTime(ACurrentTime), Cycle);
  Result := LBlend.Frame1 + 1;
end;

procedure TAnimBlend.CallFrameCommands(const ASink: IAnimFrameCommandSink; const AFromTime, AToTime: Integer);
var
  LAnim: IAnim;
  LFromFrameTime, LToFrameTime: Integer;
  LFrom, LTo: TMd5FrameBlend;
  LMd5Anim: IMd5Anim;
begin
  if (not AllowFrameCommands) or (ASink = nil) or (Frame <> 0) or ((EndTime > 0) and (AFromTime > EndTime)) then
    Exit;
  LAnim := Anim;
  if (LAnim = nil) or (not LAnim.HasFrameCommands) then
    Exit;
  // do not play until the next frame or the commands would play twice
  if AToTime <= StartTime then
    Exit;
  LFromFrameTime := AnimTime(AFromTime);
  LToFrameTime := AnimTime(AToTime);
  if LToFrameTime < LFromFrameTime then
    Inc(LToFrameTime, LAnim.Length);
  LMd5Anim := LAnim.GetMd5Anim(0);
  LFrom := LMd5Anim.ConvertTimeToFrame(LFromFrameTime, Cycle);
  LTo := LMd5Anim.ConvertTimeToFrame(LToFrameTime, Cycle);
  if LFromFrameTime <= 0 then
    // make sure the first frame is called
    TAnimFrameCommandCaller.Call(LAnim, ASink, -1, LTo.Frame1)
  else
    TAnimFrameCommandCaller.Call(LAnim, ASink, LFrom.Frame1, LTo.Frame1);
end;

function TAnimBlend.BlendAnim(const ACurrentTime, AChannel: Integer; var ABlendFrame: TArray<TMd5JointQuat>;
  var ABlendWeight: Single; const ARemoveOriginOffset, AOverrideBlend, APrintInfo: Boolean): Boolean;
var
  LAnim: IAnim;
  LWeight, LMixWeight, LLerp: Single;
  LDirect: Boolean;
  LJointFrame, LFrame: TArray<TMd5JointQuat>;
  LIndexes: TArray<Integer>;
  LFrameBlend: TMd5FrameBlend;
  LMd5Anim: IMd5Anim;
  LSkeleton: IMd5Skeleton;
  LTime, LIndex, LCount: Integer;
  LFirst: Boolean;
  LText: string;
begin
  Result := False;
  LAnim := Anim;
  if LAnim = nil then
    Exit;
  LWeight := GetWeight(ACurrentTime);
  if ABlendWeight > 0.0 then
  begin
    if (EndTime >= 0) and (ACurrentTime >= EndTime) then
      Exit;
    if LWeight = 0 then
      Exit;
    if AOverrideBlend then
      ABlendWeight := 1.0 - LWeight;
  end;
  // with nothing blended yet on the channel "all" the original stores the pose in the blend frame itself
  LDirect := (AChannel = ANIMCHANNEL_ALL) and (ABlendWeight = 0);
  LIndexes := ModelDef.GetChannelJoints(AChannel);
  LSkeleton := ModelDef.Model.Skeleton;
  LTime := AnimTime(ACurrentTime);
  if LAnim.NumAnims = 1 then
  begin
    LMd5Anim := LAnim.GetMd5Anim(0);
    if Frame <> 0 then
      LJointFrame := LMd5Anim.GetSingleFrame(Frame - 1, LIndexes)
    else
    begin
      LFrameBlend := LMd5Anim.ConvertTimeToFrame(LTime, Cycle);
      LJointFrame := LMd5Anim.GetInterpolatedFrame(LFrameBlend, LIndexes);
    end;
  end
  else
  begin
    // the anims that play together are mixed first
    if Frame = 0 then
      LFrameBlend := LAnim.GetMd5Anim(0).ConvertTimeToFrame(LTime, Cycle);
    LMixWeight := 0.0;
    LFirst := True;
    for LCount := 0 to LAnim.NumAnims - 1 do
      if AnimWeights[LCount] > 0.0 then
      begin
        LMixWeight := LMixWeight + AnimWeights[LCount];
        LLerp := AnimWeights[LCount] / LMixWeight;
        LMd5Anim := LAnim.GetMd5Anim(LCount);
        if Frame <> 0 then
          LFrame := LMd5Anim.GetSingleFrame(Frame - 1, LIndexes)
        else
          LFrame := LMd5Anim.GetInterpolatedFrame(LFrameBlend, LIndexes);
        // only blend after the first anim is mixed in
        if LFirst then
        begin
          LJointFrame := LFrame;
          LFirst := False;
        end
        else
          LSkeleton.BlendJoints(LJointFrame, LFrame, LLerp, LIndexes);
      end;
    if LMixWeight = 0 then
      Exit;
  end;
  if LDirect then
    ABlendFrame := LJointFrame;
  if ARemoveOriginOffset then
  begin
    if AllowMove then
      LJointFrame[0].T.Zero;
    if LAnim.Flags.AnimTurn then
      LJointFrame[0].Q.SetValues(-0.70710677, 0.0, 0.0, 0.70710677);
  end;
  if ABlendWeight = 0 then
  begin
    ABlendWeight := LWeight;
    if AChannel <> ANIMCHANNEL_ALL then
      for LIndex := 0 to System.Length(LIndexes) - 1 do
      begin
        ABlendFrame[LIndexes[LIndex]].T := LJointFrame[LIndexes[LIndex]].T;
        ABlendFrame[LIndexes[LIndex]].Q := LJointFrame[LIndexes[LIndex]].Q;
      end;
  end
  else
  begin
    ABlendWeight := ABlendWeight + LWeight;
    LLerp := LWeight / ABlendWeight;
    LSkeleton.BlendJoints(ABlendFrame, LJointFrame, LLerp, LIndexes);
  end;
  if APrintInfo and Assigned(FLog) then
  begin
    if Frame <> 0 then
      LText := Format('  %s: ''%s'', %d, %.2f%%'#10,
        [ANIM_CHANNEL_NAMES[AChannel], string(LAnim.FullName), Integer(Frame), LWeight * 100.0])
    else
      LText := Format('  %s: ''%s'', %.3f, %.2f%%'#10,
        [ANIM_CHANNEL_NAMES[AChannel], string(LAnim.FullName),
         Single(LFrameBlend.Frame1) + LFrameBlend.BackLerp, LWeight * 100.0]);
    FLog.Printf(LText);
  end;
  Result := True;
end;

procedure TAnimBlend.BlendOrigin(const ACurrentTime: Integer; var ABlendPos: TIdVec3; var ABlendWeight: Single;
  const ARemoveOriginOffset: Boolean);
var
  LAnim: IAnim;
  LWeight, LLerp: Single;
  LTime, LIndex: Integer;
  LAnimPos, LPos: TIdVec3;
begin
  if (Frame <> 0) or ((EndTime > 0) and (ACurrentTime > EndTime)) then
    Exit;
  LAnim := Anim;
  if LAnim = nil then
    Exit;
  if AllowMove and ARemoveOriginOffset then
    Exit;
  LWeight := GetWeight(ACurrentTime);
  if LWeight = 0 then
    Exit;
  LTime := AnimTime(ACurrentTime);
  LPos.Zero;
  for LIndex := 0 to LAnim.NumAnims - 1 do
  begin
    LAnim.GetOrigin(LIndex, LTime, Cycle, LAnimPos);
    LPos := LPos + LAnimPos * AnimWeights[LIndex];
  end;
  if ABlendWeight = 0 then
  begin
    ABlendPos := LPos;
    ABlendWeight := LWeight;
  end
  else
  begin
    LLerp := LWeight / (ABlendWeight + LWeight);
    ABlendPos := ABlendPos + LLerp * (LPos - ABlendPos);
    ABlendWeight := ABlendWeight + LWeight;
  end;
end;

procedure TAnimBlend.BlendDelta(const AFromTime, AToTime: Integer; var ABlendDelta: TIdVec3;
  var ABlendWeight: Single);
var
  LAnim: IAnim;
  LWeight, LLerp: Single;
  LTime1, LTime2, LIndex: Integer;
  LPos1, LPos2, LAnimPos, LDelta: TIdVec3;
begin
  if (Frame <> 0) or (not AllowMove) or ((EndTime > 0) and (AFromTime > EndTime)) then
    Exit;
  LAnim := Anim;
  if LAnim = nil then
    Exit;
  LWeight := GetWeight(AToTime);
  if LWeight = 0 then
    Exit;
  LTime1 := AnimTime(AFromTime);
  LTime2 := AnimTime(AToTime);
  if LTime2 < LTime1 then
    Inc(LTime2, LAnim.Length);
  LPos1.Zero;
  LPos2.Zero;
  for LIndex := 0 to LAnim.NumAnims - 1 do
  begin
    LAnim.GetOrigin(LIndex, LTime1, Cycle, LAnimPos);
    LPos1 := LPos1 + LAnimPos * AnimWeights[LIndex];
    LAnim.GetOrigin(LIndex, LTime2, Cycle, LAnimPos);
    LPos2 := LPos2 + LAnimPos * AnimWeights[LIndex];
  end;
  LDelta := LPos2 - LPos1;
  if ABlendWeight = 0 then
  begin
    ABlendDelta := LDelta;
    ABlendWeight := LWeight;
  end
  else
  begin
    LLerp := LWeight / (ABlendWeight + LWeight);
    ABlendDelta := ABlendDelta + LLerp * (LDelta - ABlendDelta);
    ABlendWeight := ABlendWeight + LWeight;
  end;
end;

procedure TAnimBlend.BlendDeltaRotation(const AFromTime, AToTime: Integer; var ABlendDelta: TIdQuat;
  var ABlendWeight: Single);
var
  LAnim: IAnim;
  LWeight, LLerp, LMixWeight: Single;
  LTime1, LTime2, LIndex: Integer;
  LQ1, LQ2, LQ3: TIdQuat;
begin
  if (Frame <> 0) or (not AllowMove) or ((EndTime > 0) and (AFromTime > EndTime)) then
    Exit;
  LAnim := Anim;
  if (LAnim = nil) or (not LAnim.Flags.AnimTurn) then
    Exit;
  LWeight := GetWeight(AToTime);
  if LWeight = 0 then
    Exit;
  LTime1 := AnimTime(AFromTime);
  LTime2 := AnimTime(AToTime);
  if LTime2 < LTime1 then
    Inc(LTime2, LAnim.Length);
  LQ1.SetValues(0.0, 0.0, 0.0, 1.0);
  LQ2.SetValues(0.0, 0.0, 0.0, 1.0);
  LMixWeight := 0.0;
  for LIndex := 0 to LAnim.NumAnims - 1 do
    if AnimWeights[LIndex] > 0.0 then
    begin
      LMixWeight := LMixWeight + AnimWeights[LIndex];
      if AnimWeights[LIndex] = LMixWeight then
      begin
        LAnim.GetOriginRotation(LIndex, LTime1, Cycle, LQ1);
        LAnim.GetOriginRotation(LIndex, LTime2, Cycle, LQ2);
      end
      else
      begin
        LLerp := AnimWeights[LIndex] / LMixWeight;
        LAnim.GetOriginRotation(LIndex, LTime1, Cycle, LQ3);
        LQ1.Slerp(LQ1, LQ3, LLerp);
        LAnim.GetOriginRotation(LIndex, LTime2, Cycle, LQ3);
        // the original slerps from the first quaternion here, not from the second one
        LQ2.Slerp(LQ1, LQ3, LLerp);
      end;
    end;
  LQ3 := LQ1.Inverse * LQ2;
  if ABlendWeight = 0 then
  begin
    ABlendDelta := LQ3;
    ABlendWeight := LWeight;
  end
  else
  begin
    LLerp := LWeight / (ABlendWeight + LWeight);
    ABlendDelta.Slerp(ABlendDelta, LQ3, LLerp);
    ABlendWeight := ABlendWeight + LWeight;
  end;
end;

function TAnimBlend.AddBounds(const ACurrentTime: Integer; var ABounds: TGeoBounds;
  const ARemoveOriginOffset: Boolean): Boolean;
var
  LAnim: IAnim;
  LTime, LIndex: Integer;
  LBounds: TGeoBounds;
  LPos: TIdVec3;
  LAddOrigin: Boolean;
begin
  Result := False;
  if (EndTime > 0) and (ACurrentTime > EndTime) then
    Exit;
  LAnim := Anim;
  if LAnim = nil then
    Exit;
  if GetWeight(ACurrentTime) = 0 then
    Exit;
  LTime := AnimTime(ACurrentTime);
  LAddOrigin := (not AllowMove) or (not ARemoveOriginOffset);
  for LIndex := 0 to LAnim.NumAnims - 1 do
    if LAnim.GetBounds(LIndex, LTime, Cycle, LBounds) then
    begin
      if LAddOrigin then
      begin
        LAnim.GetOrigin(LIndex, LTime, Cycle, LPos);
        LBounds.TranslateSelf(TGeoVec3.Make(LPos.X, LPos.Y, LPos.Z));
      end;
      ABounds.AddBounds(LBounds);
    end;
  Result := True;
end;

end.
