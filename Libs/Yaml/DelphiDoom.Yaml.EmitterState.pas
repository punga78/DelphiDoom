{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the state of the emitter                         }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{  (emitterstate.cpp and setting.h, with their quirks: see the README)         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.EmitterState;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types;

type
  TYamlFormatScope = (fsLocal, fsGlobal);
  TYamlGroupType = (gtNoType, gtSeq, gtMap);
  TYamlFlowType = (ftNoType, ftFlow, ftBlock);
  TYamlEmitterNodeType = (entNoType, entProperty, entScalar, entFlowSeq, entBlockSeq, entFlowMap, entBlockMap);

  TYamlSettingId = (
    siCharset, siStringFormat, siBoolFormat, siBoolLengthFormat, siBoolCaseFormat, siNullFormat, siIntFormat,
    siIndent, siPreCommentIndent, siPostCommentIndent, siSeqFormat, siMapFormat, siMapKeyFormat,
    siFloatPrecision, siDoublePrecision);

  /// <summary>
  ///   SettingChanges: the old values of settings changed for a while. Restore puts them back in the order they
  ///   were pushed (like yaml-cpp: with two changes of the same setting the first old value comes back last
  ///   only if it was pushed last, i.e. the result is the second old value); Clear restores and forgets
  /// </summary>
  TYamlSettingChanges = class
  strict private
    type
      TChange = record
        Id: TYamlSettingId;
        OldValue: Int64;
      end;
  strict private
    FChanges: TList<TChange>;
    FValues: ^TArray<Int64>;
  public
    constructor Create(AValues: Pointer);
    destructor Destroy; override;
    procedure Push(AId: TYamlSettingId; AOldValue: Int64);
    procedure Restore;
    procedure Clear;
    /// <summary>operator=(SettingChanges&amp;&amp;): clear this one, take the changes of AOther</summary>
    procedure MoveFrom(AOther: TYamlSettingChanges);
  end;

  /// <summary>EmitterState</summary>
  TYamlEmitterState = class
  strict private
    type
      TGroup = class
      public
        GroupType: TYamlGroupType;
        FlowType: TYamlFlowType;
        Indent: Integer;
        ChildCount: Integer;
        LongKey: Boolean;
        Settings: TYamlSettingChanges;
        constructor Create(AType: TYamlGroupType; AValues: Pointer);
        destructor Destroy; override;
        function NodeType: TYamlEmitterNodeType;
      end;
  strict private
    FIsGood: Boolean;
    FLastError: TYamlText;
    FValues: TArray<Int64>;
    FModifiedSettings: TYamlSettingChanges;
    FGlobalModifiedSettings: TYamlSettingChanges;
    FGroups: TObjectList<TGroup>;
    FCurIndent: Integer;
    FHasAnchor: Boolean;
    FHasAlias: Boolean;
    FHasTag: Boolean;
    FHasNonContent: Boolean;
    FDocCount: Integer;
    procedure SetValue(AId: TYamlSettingId; AValue: Int64; AScope: TYamlFormatScope);
    function GetManip(AId: TYamlSettingId): TYamlManip;
    procedure StartedNode;
  public
    constructor Create;
    destructor Destroy; override;
    function Good: Boolean;
    function GetLastError: TYamlText;
    procedure SetError(const AError: TYamlText);
    procedure SetAnchor;
    procedure SetAlias;
    procedure SetTag;
    procedure SetNonContent;
    procedure SetLongKey;
    procedure ForceFlow;
    procedure StartedDoc;
    procedure EndedDoc;
    procedure StartedScalar;
    procedure StartedGroup(AType: TYamlGroupType);
    procedure EndedGroup(AType: TYamlGroupType);
    function NextGroupType(AType: TYamlGroupType): TYamlEmitterNodeType;
    function CurGroupNodeType: TYamlEmitterNodeType;
    function CurGroupType: TYamlGroupType;
    function CurGroupFlowType: TYamlFlowType;
    function CurGroupIndent: Integer;
    function CurGroupChildCount: Integer;
    function CurGroupLongKey: Boolean;
    function LastIndent: Integer;
    function CurIndent: Integer;
    function HasAnchor: Boolean;
    function HasAlias: Boolean;
    function HasTag: Boolean;
    function HasBegunNode: Boolean;
    function HasBegunContent: Boolean;
    procedure ClearModifiedSettings;
    procedure RestoreGlobalModifiedSettings;
    procedure SetLocalValue(AValue: TYamlManip);
    function SetOutputCharset(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetOutputCharset: TYamlManip;
    function SetStringFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetStringFormat: TYamlManip;
    function SetBoolFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetBoolFormat: TYamlManip;
    function SetBoolLengthFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetBoolLengthFormat: TYamlManip;
    function SetBoolCaseFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetBoolCaseFormat: TYamlManip;
    function SetNullFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetNullFormat: TYamlManip;
    function SetIntFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetIntFormat: TYamlManip;
    function SetIndent(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
    function GetIndent: Integer;
    function SetPreCommentIndent(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
    function GetPreCommentIndent: Integer;
    function SetPostCommentIndent(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
    function GetPostCommentIndent: Integer;
    function SetFlowType(AGroupType: TYamlGroupType; AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetFlowType(AGroupType: TYamlGroupType): TYamlManip;
    function SetMapKeyFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
    function GetMapKeyFormat: TYamlManip;
    function SetFloatPrecision(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
    function GetFloatPrecision: Integer;
    function SetDoublePrecision(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
    function GetDoublePrecision: Integer;
  end;

implementation

{ TYamlSettingChanges }

constructor TYamlSettingChanges.Create(AValues: Pointer);
begin
  inherited Create;
  FValues := AValues;
  FChanges := TList<TChange>.Create;
end;

destructor TYamlSettingChanges.Destroy;
begin
  Clear;
  FChanges.Free;
  inherited Destroy;
end;

procedure TYamlSettingChanges.Push(AId: TYamlSettingId; AOldValue: Int64);
var
  LChange: TChange;
begin
  LChange.Id := AId;
  LChange.OldValue := AOldValue;
  FChanges.Add(LChange);
end;

procedure TYamlSettingChanges.Restore;
var
  LChange: TChange;
begin
  for LChange in FChanges do
    FValues^[Ord(LChange.Id)] := LChange.OldValue;
end;

procedure TYamlSettingChanges.Clear;
begin
  Restore;
  FChanges.Clear;
end;

procedure TYamlSettingChanges.MoveFrom(AOther: TYamlSettingChanges);
var
  LTemp: TList<TChange>;
begin
  if AOther = Self then
    Exit;
  Clear;
  LTemp := FChanges;
  FChanges := AOther.FChanges;
  AOther.FChanges := LTemp;
end;

{ TYamlEmitterState.TGroup }

constructor TYamlEmitterState.TGroup.Create(AType: TYamlGroupType; AValues: Pointer);
begin
  inherited Create;
  GroupType := AType;
  FlowType := ftNoType;
  Settings := TYamlSettingChanges.Create(AValues);
end;

destructor TYamlEmitterState.TGroup.Destroy;
begin
  Settings.Free;
  inherited Destroy;
end;

function TYamlEmitterState.TGroup.NodeType: TYamlEmitterNodeType;
begin
  if GroupType = gtSeq then
  begin
    if FlowType = ftFlow then
      Result := entFlowSeq
    else
      Result := entBlockSeq;
  end
  else
  begin
    if FlowType = ftFlow then
      Result := entFlowMap
    else
      Result := entBlockMap;
  end;
end;

{ TYamlEmitterState }

constructor TYamlEmitterState.Create;
begin
  inherited Create;
  FIsGood := True;
  SetLength(FValues, Ord(High(TYamlSettingId)) + 1);
  FValues[Ord(siCharset)] := Ord(ymEmitNonAscii);
  FValues[Ord(siStringFormat)] := Ord(ymAuto);
  FValues[Ord(siBoolFormat)] := Ord(ymTrueFalseBool);
  FValues[Ord(siBoolLengthFormat)] := Ord(ymLongBool);
  FValues[Ord(siBoolCaseFormat)] := Ord(ymLowerCase);
  FValues[Ord(siNullFormat)] := Ord(ymTildeNull);
  FValues[Ord(siIntFormat)] := Ord(ymDec);
  FValues[Ord(siIndent)] := 2;
  FValues[Ord(siPreCommentIndent)] := 2;
  FValues[Ord(siPostCommentIndent)] := 1;
  FValues[Ord(siSeqFormat)] := Ord(ymBlock);
  FValues[Ord(siMapFormat)] := Ord(ymBlock);
  FValues[Ord(siMapKeyFormat)] := Ord(ymAuto);
  FValues[Ord(siFloatPrecision)] := 9;   // numeric_limits<float>::max_digits10
  FValues[Ord(siDoublePrecision)] := 17; // numeric_limits<double>::max_digits10
  FModifiedSettings := TYamlSettingChanges.Create(@FValues);
  FGlobalModifiedSettings := TYamlSettingChanges.Create(@FValues);
  FGroups := TObjectList<TGroup>.Create(True);
end;

destructor TYamlEmitterState.Destroy;
begin
  FGroups.Free;
  FGlobalModifiedSettings.Free;
  FModifiedSettings.Free;
  inherited Destroy;
end;

function TYamlEmitterState.Good: Boolean;
begin
  Result := FIsGood;
end;

function TYamlEmitterState.GetLastError: TYamlText;
begin
  Result := FLastError;
end;

procedure TYamlEmitterState.SetError(const AError: TYamlText);
begin
  FIsGood := False;
  FLastError := AError;
end;

procedure TYamlEmitterState.SetAnchor;
begin
  FHasAnchor := True;
end;

procedure TYamlEmitterState.SetAlias;
begin
  FHasAlias := True;
end;

procedure TYamlEmitterState.SetTag;
begin
  FHasTag := True;
end;

procedure TYamlEmitterState.SetNonContent;
begin
  FHasNonContent := True;
end;

procedure TYamlEmitterState.SetLongKey;
begin
  if FGroups.Count = 0 then
    Exit;
  FGroups.Last.LongKey := True;
end;

procedure TYamlEmitterState.ForceFlow;
begin
  if FGroups.Count = 0 then
    Exit;
  FGroups.Last.FlowType := ftFlow;
end;

procedure TYamlEmitterState.StartedNode;
begin
  if FGroups.Count = 0 then
    Inc(FDocCount)
  else
  begin
    Inc(FGroups.Last.ChildCount);
    if FGroups.Last.ChildCount mod 2 = 0 then
      FGroups.Last.LongKey := False;
  end;
  FHasAnchor := False;
  FHasAlias := False;
  FHasTag := False;
  FHasNonContent := False;
end;

function TYamlEmitterState.NextGroupType(AType: TYamlGroupType): TYamlEmitterNodeType;
begin
  if AType = gtSeq then
  begin
    if GetFlowType(AType) = ymBlock then
      Exit(entBlockSeq);
    Exit(entFlowSeq);
  end;
  if GetFlowType(AType) = ymBlock then
    Exit(entBlockMap);
  Result := entFlowMap;
end;

procedure TYamlEmitterState.StartedDoc;
begin
  FHasAnchor := False;
  FHasTag := False;
  FHasNonContent := False;
end;

procedure TYamlEmitterState.EndedDoc;
begin
  FHasAnchor := False;
  FHasTag := False;
  FHasNonContent := False;
end;

procedure TYamlEmitterState.StartedScalar;
begin
  StartedNode;
  ClearModifiedSettings;
end;

procedure TYamlEmitterState.StartedGroup(AType: TYamlGroupType);
var
  LLastGroupIndent: Integer;
  LGroup: TGroup;
begin
  StartedNode;
  if FGroups.Count = 0 then
    LLastGroupIndent := 0
  else
    LLastGroupIndent := FGroups.Last.Indent;
  Inc(FCurIndent, LLastGroupIndent);
  LGroup := TGroup.Create(AType, @FValues);
  LGroup.Settings.MoveFrom(FModifiedSettings);
  if GetFlowType(AType) = ymBlock then
    LGroup.FlowType := ftBlock
  else
    LGroup.FlowType := ftFlow;
  LGroup.Indent := GetIndent;
  FGroups.Add(LGroup);
end;

procedure TYamlEmitterState.EndedGroup(AType: TYamlGroupType);
var
  LFinished: TGroup;
  LLastIndent: Integer;
begin
  if FGroups.Count = 0 then
  begin
    if AType = gtSeq then
      SetError(SYamlUnexpectedEndSeq)
    else
      SetError(SYamlUnexpectedEndMap);
    Exit;
  end;
  if FHasTag then
    SetError(SYamlInvalidTag);
  if FHasAnchor then
    SetError(SYamlInvalidAnchor);
  // get rid of the current group
  LFinished := FGroups.Extract(FGroups.Last);
  try
    if LFinished.GroupType <> AType then
    begin
      SetError(SYamlUnmatchedGroupTag);
      Exit;
    end;
  finally
    // the group goes away here and puts back the settings changed for it
    LFinished.Free;
  end;
  // reset old settings
  if FGroups.Count = 0 then
    LLastIndent := 0
  else
    LLastIndent := FGroups.Last.Indent;
  Dec(FCurIndent, LLastIndent);
  // some global settings that we changed may have been overridden by a local setting we just popped, so we need to
  // restore them
  FGlobalModifiedSettings.Restore;
  ClearModifiedSettings;
  FHasAnchor := False;
  FHasTag := False;
  FHasNonContent := False;
end;

function TYamlEmitterState.CurGroupNodeType: TYamlEmitterNodeType;
begin
  if FGroups.Count = 0 then
    Exit(entNoType);
  Result := FGroups.Last.NodeType;
end;

function TYamlEmitterState.CurGroupType: TYamlGroupType;
begin
  if FGroups.Count = 0 then
    Result := gtNoType
  else
    Result := FGroups.Last.GroupType;
end;

function TYamlEmitterState.CurGroupFlowType: TYamlFlowType;
begin
  if FGroups.Count = 0 then
    Result := ftNoType
  else
    Result := FGroups.Last.FlowType;
end;

function TYamlEmitterState.CurGroupIndent: Integer;
begin
  if FGroups.Count = 0 then
    Result := 0
  else
    Result := FGroups.Last.Indent;
end;

function TYamlEmitterState.CurGroupChildCount: Integer;
begin
  if FGroups.Count = 0 then
    Result := FDocCount
  else
    Result := FGroups.Last.ChildCount;
end;

function TYamlEmitterState.CurGroupLongKey: Boolean;
begin
  if FGroups.Count = 0 then
    Result := False
  else
    Result := FGroups.Last.LongKey;
end;

function TYamlEmitterState.LastIndent: Integer;
begin
  if FGroups.Count <= 1 then
    Exit(0);
  Result := FCurIndent - FGroups[FGroups.Count - 2].Indent;
end;

function TYamlEmitterState.CurIndent: Integer;
begin
  Result := FCurIndent;
end;

function TYamlEmitterState.HasAnchor: Boolean;
begin
  Result := FHasAnchor;
end;

function TYamlEmitterState.HasAlias: Boolean;
begin
  Result := FHasAlias;
end;

function TYamlEmitterState.HasTag: Boolean;
begin
  Result := FHasTag;
end;

function TYamlEmitterState.HasBegunNode: Boolean;
begin
  Result := FHasAnchor or FHasTag or FHasNonContent;
end;

function TYamlEmitterState.HasBegunContent: Boolean;
begin
  Result := FHasAnchor or FHasTag;
end;

procedure TYamlEmitterState.ClearModifiedSettings;
begin
  FModifiedSettings.Clear;
end;

procedure TYamlEmitterState.RestoreGlobalModifiedSettings;
begin
  FGlobalModifiedSettings.Restore;
end;

procedure TYamlEmitterState.SetValue(AId: TYamlSettingId; AValue: Int64; AScope: TYamlFormatScope);
begin
  case AScope of
    fsLocal:
      begin
        FModifiedSettings.Push(AId, FValues[Ord(AId)]);
        FValues[Ord(AId)] := AValue;
      end;
    fsGlobal:
      begin
        FValues[Ord(AId)] := AValue;
        // this pushes an identity set: restoring does not bring back the old value (as in yaml-cpp)
        FGlobalModifiedSettings.Push(AId, FValues[Ord(AId)]);
        FValues[Ord(AId)] := AValue;
      end;
  end;
end;

function TYamlEmitterState.GetManip(AId: TYamlSettingId): TYamlManip;
begin
  Result := TYamlManip(FValues[Ord(AId)]);
end;

procedure TYamlEmitterState.SetLocalValue(AValue: TYamlManip);
begin
  SetOutputCharset(AValue, fsLocal);
  SetStringFormat(AValue, fsLocal);
  SetBoolFormat(AValue, fsLocal);
  SetBoolCaseFormat(AValue, fsLocal);
  SetBoolLengthFormat(AValue, fsLocal);
  SetNullFormat(AValue, fsLocal);
  SetIntFormat(AValue, fsLocal);
  SetFlowType(gtSeq, AValue, fsLocal);
  SetFlowType(gtMap, AValue, fsLocal);
  SetMapKeyFormat(AValue, fsLocal);
end;

function TYamlEmitterState.SetOutputCharset(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymEmitNonAscii, ymEscapeNonAscii, ymEscapeAsJson];
  if Result then
    SetValue(siCharset, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetOutputCharset: TYamlManip;
begin
  Result := GetManip(siCharset);
end;

function TYamlEmitterState.SetStringFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymAuto, ymSingleQuoted, ymDoubleQuoted, ymLiteral];
  if Result then
    SetValue(siStringFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetStringFormat: TYamlManip;
begin
  Result := GetManip(siStringFormat);
end;

function TYamlEmitterState.SetBoolFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymOnOffBool, ymTrueFalseBool, ymYesNoBool];
  if Result then
    SetValue(siBoolFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetBoolFormat: TYamlManip;
begin
  Result := GetManip(siBoolFormat);
end;

function TYamlEmitterState.SetBoolLengthFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymLongBool, ymShortBool];
  if Result then
    SetValue(siBoolLengthFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetBoolLengthFormat: TYamlManip;
begin
  Result := GetManip(siBoolLengthFormat);
end;

function TYamlEmitterState.SetBoolCaseFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymUpperCase, ymLowerCase, ymCamelCase];
  if Result then
    SetValue(siBoolCaseFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetBoolCaseFormat: TYamlManip;
begin
  Result := GetManip(siBoolCaseFormat);
end;

function TYamlEmitterState.SetNullFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymLowerNull, ymUpperNull, ymCamelNull, ymTildeNull];
  if Result then
    SetValue(siNullFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetNullFormat: TYamlManip;
begin
  Result := GetManip(siNullFormat);
end;

function TYamlEmitterState.SetIntFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymDec, ymHex, ymOct];
  if Result then
    SetValue(siIntFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetIntFormat: TYamlManip;
begin
  Result := GetManip(siIntFormat);
end;

function TYamlEmitterState.SetIndent(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
begin
  if AValue <= 1 then
    Exit(False);
  SetValue(siIndent, Int64(AValue), AScope);
  Result := True;
end;

function TYamlEmitterState.GetIndent: Integer;
begin
  Result := Integer(FValues[Ord(siIndent)]);
end;

function TYamlEmitterState.SetPreCommentIndent(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
begin
  if AValue = 0 then
    Exit(False);
  SetValue(siPreCommentIndent, Int64(AValue), AScope);
  Result := True;
end;

function TYamlEmitterState.GetPreCommentIndent: Integer;
begin
  Result := Integer(FValues[Ord(siPreCommentIndent)]);
end;

function TYamlEmitterState.SetPostCommentIndent(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
begin
  if AValue = 0 then
    Exit(False);
  SetValue(siPostCommentIndent, Int64(AValue), AScope);
  Result := True;
end;

function TYamlEmitterState.GetPostCommentIndent: Integer;
begin
  Result := Integer(FValues[Ord(siPostCommentIndent)]);
end;

function TYamlEmitterState.SetFlowType(AGroupType: TYamlGroupType; AValue: TYamlManip;
  AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymBlock, ymFlow];
  if not Result then
    Exit;
  if AGroupType = gtSeq then
    SetValue(siSeqFormat, Ord(AValue), AScope)
  else
    SetValue(siMapFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetFlowType(AGroupType: TYamlGroupType): TYamlManip;
begin
  if CurGroupFlowType = ftFlow then
    Exit(ymFlow);
  if AGroupType = gtSeq then
    Result := GetManip(siSeqFormat)
  else
    Result := GetManip(siMapFormat);
end;

function TYamlEmitterState.SetMapKeyFormat(AValue: TYamlManip; AScope: TYamlFormatScope): Boolean;
begin
  Result := AValue in [ymAuto, ymLongKey];
  if Result then
    SetValue(siMapKeyFormat, Ord(AValue), AScope);
end;

function TYamlEmitterState.GetMapKeyFormat: TYamlManip;
begin
  Result := GetManip(siMapKeyFormat);
end;

function TYamlEmitterState.SetFloatPrecision(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
begin
  if AValue > 9 then
    Exit(False);
  SetValue(siFloatPrecision, Int64(AValue), AScope);
  Result := True;
end;

function TYamlEmitterState.GetFloatPrecision: Integer;
begin
  Result := Integer(FValues[Ord(siFloatPrecision)]);
end;

function TYamlEmitterState.SetDoublePrecision(AValue: NativeUInt; AScope: TYamlFormatScope): Boolean;
begin
  if AValue > 17 then
    Exit(False);
  SetValue(siDoublePrecision, Int64(AValue), AScope);
  Result := True;
end;

function TYamlEmitterState.GetDoublePrecision: Integer;
begin
  Result := Integer(FValues[Ord(siDoublePrecision)]);
end;

end.
