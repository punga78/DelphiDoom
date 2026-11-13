{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - a definition of a model (idDeclModelDef)    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim_Blend.cpp }
{  (idDeclModelDef). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media  }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.ModelDef;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Geometry.Bounds,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>
  ///   The data of a MODELDEF: the md5 model and its joints with their channels, the offset, the
  ///   default skin (a name) and the animations. The parser fills it through the methods that are
  ///   not in <c>IModelDef</c>.
  /// </summary>
  TModelDef = class(TInterfacedObject, IModelDef)
  strict private
    FName: AnsiString;
    FModel: IMd5Model;
    FSkinName: AnsiString;
    FOffset: TIdVec3;
    FJoints: TArray<TAnimJointInfo>;
    FJointParents: TArray<Integer>;
    FChannelJoints: array[0..ANIM_NUM_ANIM_CHANNELS - 1] of TArray<Integer>;
    FAnims: TList<IAnim>;
    FDefaulted: Boolean;
    procedure CheckChannel(const AChannel: Integer);
    procedure Clear;
  public
    constructor Create(const AName: AnsiString);
    destructor Destroy; override;
    { ---- filling (the parser) }
    /// <summary>MakeDefault: everything cleared and the definition marked as defaulted</summary>
    procedure MakeDefault;
    /// <summary>CopyDecl: this definition becomes a copy of the other one (the anims are cloned)</summary>
    procedure CopyFrom(const AOther: IModelDef);
    /// <summary>The model of the mesh token: sets up the joint hierarchy, all the joints on the channel "all"</summary>
    procedure SetModel(const AModel: IMd5Model);
    procedure SetSkinName(const AValue: AnsiString);
    procedure SetOffset(const AValue: TIdVec3);
    function AnimCount: Integer;
    function GetAnimAt(const AIndex: Integer): IAnim;
    procedure AddAnim(const AAnim: IAnim);
    procedure ReplaceAnim(const AIndex: Integer; const AAnim: IAnim);
    procedure RemoveAnimAt(const AIndex: Integer);
    /// <summary>Puts a joint on a channel (the joint list of the channel is set by the caller)</summary>
    procedure SetJointChannel(const AJoint, AChannel: Integer);
    procedure SetChannelJoints(const AChannel: Integer; const AJoints: TArray<Integer>);
    { ---- IModelDef }
    function GetName: AnsiString;
    function GetModel: IMd5Model;
    function GetSkinName: AnsiString;
    function GetOffset: TIdVec3;
    function GetNumJoints: Integer;
    function GetJointInfo(const AHandle: Integer): TAnimJointInfo;
    function GetJointParents: TArray<Integer>;
    function GetNumAnims: Integer;
    function GetDefaulted: Boolean;
    function GetModelName: AnsiString;
    function GetAnimByIndex(const AIndex: Integer): IAnim;
    function HasAnim(const AName: AnsiString): Boolean;
    function GetSpecificAnim(const AName: AnsiString): Integer;
    function GetAnim(const AName: AnsiString; const ARandom: TAnimRandomInt): Integer;
    function FindJoint(const AName: AnsiString): Integer;
    function GetJointName(const AHandle: Integer): AnsiString;
    function GetJointList(const AJointNames: AnsiString; const ALog: IIdLibLog): TArray<Integer>;
    function NumJointsOnChannel(const AChannel: Integer): Integer;
    function GetChannelJoints(const AChannel: Integer): TArray<Integer>;
    function SetupJoints(const ARemoveOriginOffset: Boolean; out ABounds: TGeoBounds): TArray<TMd5JointMat>;
    property Model: IMd5Model read GetModel;
    property JointInfo[const AHandle: Integer]: TAnimJointInfo read GetJointInfo;
  end;

implementation

uses
  DelphiDoom.Models.Md5.Types;

const
  MAX_ANIMS = 64;

function IsSpaceChar(const AChar: AnsiChar): Boolean;
begin
  Result := AChar in [#9, #10, #11, #12, #13, ' '];
end;

{ TModelDef }

constructor TModelDef.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
  FAnims := TList<IAnim>.Create;
end;

destructor TModelDef.Destroy;
begin
  FAnims.Free;
  inherited Destroy;
end;

procedure TModelDef.Clear;
var
  LChannel: Integer;
begin
  FAnims.Clear;
  FJoints := nil;
  FJointParents := nil;
  FModel := nil;
  FSkinName := '';
  FOffset.Zero;
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    FChannelJoints[LChannel] := nil;
end;

procedure TModelDef.MakeDefault;
begin
  Clear;
  FDefaulted := True;
end;

procedure TModelDef.CopyFrom(const AOther: IModelDef);
var
  LIndex, LChannel: Integer;
begin
  Clear;
  FOffset := AOther.Offset;
  FModel := AOther.Model;
  FSkinName := AOther.SkinName;
  for LIndex := 1 to AOther.NumAnims - 1 do
    FAnims.Add(AOther.GetAnimByIndex(LIndex).Clone);
  SetLength(FJoints, AOther.NumJoints);
  for LIndex := 0 to High(FJoints) do
    FJoints[LIndex] := AOther.JointInfo[LIndex];
  FJointParents := Copy(AOther.JointParents);
  for LChannel := 0 to ANIM_NUM_ANIM_CHANNELS - 1 do
    FChannelJoints[LChannel] := Copy(AOther.GetChannelJoints(LChannel));
end;

procedure TModelDef.SetModel(const AModel: IMd5Model);
var
  LIndex, LNumJoints: Integer;
begin
  FModel := AModel;
  LNumJoints := AModel.NumJoints;
  SetLength(FJoints, LNumJoints);
  SetLength(FJointParents, LNumJoints);
  SetLength(FChannelJoints[ANIMCHANNEL_ALL], LNumJoints);
  for LIndex := 0 to LNumJoints - 1 do
  begin
    FJoints[LIndex].Channel := ANIMCHANNEL_ALL;
    FJoints[LIndex].Num := LIndex;
    FJoints[LIndex].ParentNum := AModel.Joints[LIndex].Parent;
    FJointParents[LIndex] := FJoints[LIndex].ParentNum;
    FChannelJoints[ANIMCHANNEL_ALL][LIndex] := LIndex;
  end;
end;

procedure TModelDef.SetSkinName(const AValue: AnsiString);
begin
  FSkinName := AValue;
end;

procedure TModelDef.SetOffset(const AValue: TIdVec3);
begin
  FOffset := AValue;
end;

function TModelDef.AnimCount: Integer;
begin
  Result := FAnims.Count;
end;

function TModelDef.GetAnimAt(const AIndex: Integer): IAnim;
begin
  Result := FAnims[AIndex];
end;

procedure TModelDef.AddAnim(const AAnim: IAnim);
begin
  FAnims.Add(AAnim);
end;

procedure TModelDef.ReplaceAnim(const AIndex: Integer; const AAnim: IAnim);
begin
  FAnims[AIndex] := AAnim;
end;

procedure TModelDef.RemoveAnimAt(const AIndex: Integer);
begin
  FAnims.Delete(AIndex);
end;

procedure TModelDef.SetJointChannel(const AJoint, AChannel: Integer);
begin
  FJoints[AJoint].Channel := AChannel;
end;

procedure TModelDef.SetChannelJoints(const AChannel: Integer; const AJoints: TArray<Integer>);
begin
  CheckChannel(AChannel);
  FChannelJoints[AChannel] := AJoints;
end;

procedure TModelDef.CheckChannel(const AChannel: Integer);
begin
  if (AChannel < 0) or (AChannel >= ANIM_NUM_ANIM_CHANNELS) then
    raise EAnimException.CreateFmt(SAnimChannelRange, [AChannel]);
end;

function TModelDef.GetName: AnsiString;
begin
  Result := FName;
end;

function TModelDef.GetModel: IMd5Model;
begin
  Result := FModel;
end;

function TModelDef.GetSkinName: AnsiString;
begin
  Result := FSkinName;
end;

function TModelDef.GetOffset: TIdVec3;
begin
  Result := FOffset;
end;

function TModelDef.GetNumJoints: Integer;
begin
  Result := Length(FJoints);
end;

function TModelDef.GetJointInfo(const AHandle: Integer): TAnimJointInfo;
begin
  if (AHandle < 0) or (AHandle >= Length(FJoints)) then
    raise EAnimException.CreateFmt(SAnimJointHandle, [AHandle, Length(FJoints)]);
  Result := FJoints[AHandle];
end;

function TModelDef.GetJointParents: TArray<Integer>;
begin
  Result := FJointParents;
end;

function TModelDef.GetNumAnims: Integer;
begin
  Result := FAnims.Count + 1;
end;

function TModelDef.GetDefaulted: Boolean;
begin
  Result := FDefaulted;
end;

function TModelDef.GetModelName: AnsiString;
begin
  if Assigned(FModel) then
    Result := FModel.Name
  else
    Result := '';
end;

function TModelDef.GetAnimByIndex(const AIndex: Integer): IAnim;
begin
  if (AIndex < 1) or (AIndex > FAnims.Count) then
    Result := nil
  else
    Result := FAnims[AIndex - 1];
end;

function TModelDef.HasAnim(const AName: AnsiString): Boolean;
var
  LAnim: IAnim;
begin
  for LAnim in FAnims do
    if LAnim.Name = AName then
      Exit(True);
  Result := False;
end;

function TModelDef.GetSpecificAnim(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FAnims.Count - 1 do
    if FAnims[LIndex].FullName = AName then
      Exit(LIndex + 1);
  Result := 0;
end;

function TModelDef.GetAnim(const AName: AnsiString; const ARandom: TAnimRandomInt): Integer;
var
  LIndex, LCount: Integer;
  LList: array[0..MAX_ANIMS - 1] of Integer;
begin
  if (Length(AName) > 0) and (AName[Length(AName)] in ['0'..'9']) then
    Exit(GetSpecificAnim(AName));
  LCount := 0;
  for LIndex := 0 to FAnims.Count - 1 do
    if FAnims[LIndex].Name = AName then
    begin
      LList[LCount] := LIndex;
      Inc(LCount);
      if LCount >= MAX_ANIMS then
        Break;
    end;
  if LCount = 0 then
    Exit(0);
  Result := LList[ARandom(LCount)] + 1;
end;

function TModelDef.FindJoint(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  if not Assigned(FModel) then
    Exit;
  for LIndex := 0 to Length(FJoints) - 1 do
    if SameText(string(FModel.Joints[LIndex].Name), string(AName)) then
      Exit(LIndex);
end;

function TModelDef.GetJointName(const AHandle: Integer): AnsiString;
begin
  Result := '';
  if not Assigned(FModel) then
    Exit;
  if (AHandle < 0) or (AHandle >= Length(FJoints)) then
    raise EAnimException.CreateFmt(SAnimJointHandle, [AHandle, Length(FJoints)]);
  Result := FModel.Joints[AHandle].Name;
end;

function TModelDef.GetJointList(const AJointNames: AnsiString; const ALog: IIdLibLog): TArray<Integer>;
var
  LList: TList<Integer>;
  LPos, LJoint, LChild, LIndex: Integer;
  LName: AnsiString;
  LGetChildren, LSubtract: Boolean;

  procedure Apply(const AHandle: Integer);
  begin
    if not LSubtract then
    begin
      if LList.IndexOf(AHandle) < 0 then
        LList.Add(AHandle);
    end
    else
      LList.Remove(AHandle);
  end;

begin
  Result := nil;
  if not Assigned(FModel) then
    Exit;
  LList := TList<Integer>.Create;
  try
    LPos := 1;
    while LPos <= Length(AJointNames) do
    begin
      while (LPos <= Length(AJointNames)) and IsSpaceChar(AJointNames[LPos]) do
        Inc(LPos);
      if LPos > Length(AJointNames) then
        Break;
      LName := '';
      LSubtract := AJointNames[LPos] = '-';
      if LSubtract then
        Inc(LPos);
      LGetChildren := (LPos <= Length(AJointNames)) and (AJointNames[LPos] = '*');
      if LGetChildren then
        Inc(LPos);
      while (LPos <= Length(AJointNames)) and not IsSpaceChar(AJointNames[LPos]) do
      begin
        LName := LName + AJointNames[LPos];
        Inc(LPos);
      end;
      LJoint := FindJoint(LName);
      if LJoint < 0 then
      begin
        if Assigned(ALog) then
          ALog.Warning(Format('Unknown joint ''%s'' in ''%s'' for model ''%s''',
            [string(LName), string(AJointNames), string(FName)]));
        Continue;
      end;
      Apply(LJoint);
      if LGetChildren then
        for LIndex := LJoint + 1 to FModel.NumJoints - 1 do
        begin
          LChild := LIndex;
          // all children of the joint follow it in the list: stop at the first that is not one
          if FJoints[LChild].ParentNum < LJoint then
            Break;
          Apply(FJoints[LChild].Num);
        end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function TModelDef.NumJointsOnChannel(const AChannel: Integer): Integer;
begin
  CheckChannel(AChannel);
  Result := Length(FChannelJoints[AChannel]);
end;

function TModelDef.GetChannelJoints(const AChannel: Integer): TArray<Integer>;
begin
  CheckChannel(AChannel);
  Result := FChannelJoints[AChannel];
end;

function TModelDef.SetupJoints(const ARemoveOriginOffset: Boolean; out ABounds: TGeoBounds): TArray<TMd5JointMat>;
var
  LNumJoints: Integer;
  LPose: TArray<TMd5JointQuat>;
begin
  Result := nil;
  ABounds := TGeoBounds.Cleared;
  if not Assigned(FModel) then
    Exit;
  LNumJoints := FModel.NumJoints;
  if LNumJoints = 0 then
    raise EAnimException.CreateFmt(SAnimNoJoints, [string(FModel.Name)]);
  LPose := FModel.DefaultPose;
  Result := FModel.Skeleton.ConvertToMatrices(LPose);
  // check if we offset the model by the origin joint
  if ARemoveOriginOffset then
    Result[0].SetTranslation(FOffset)
  else
    Result[0].SetTranslation(LPose[0].T + FOffset);
  FModel.Skeleton.TransformJoints(Result, 1, Length(FJoints) - 1);
  ABounds := FModel.Bounds;
end;

end.
