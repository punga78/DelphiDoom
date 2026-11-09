{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the emitter (YAML::Emitter)                      }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Emitter;

interface

uses
  System.SysUtils,
  System.Math,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Convert,
  DelphiDoom.Yaml.OutputWriter,
  DelphiDoom.Yaml.EmitterState,
  DelphiDoom.Yaml.EmitterUtils,
  DelphiDoom.Yaml.NodeEvents,
  DelphiDoom.Yaml.EmitFromEvents;

type
  /// <summary>
  ///   YAML::Emitter: writes YAML into a memory buffer. Every operation of the C++ class has the same effect
  ///   here; after an error (Good is false) nothing more is written
  /// </summary>
  TYamlEmitter = class(TInterfacedObject, IYamlEmitter)
  strict private
    FState: TYamlEmitterState;
    FStream: TYamlOutputWriter;
    procedure EmitBeginDoc;
    procedure EmitEndDoc;
    procedure EmitBeginSeq;
    procedure EmitEndSeq;
    procedure EmitBeginMap;
    procedure EmitEndMap;
    procedure EmitNewline;
    procedure EmitKindTag;
    procedure PrepareNode(AChild: TYamlEmitterNodeType);
    procedure PrepareTopNode(AChild: TYamlEmitterNodeType);
    procedure FlowSeqPrepareNode(AChild: TYamlEmitterNodeType);
    procedure BlockSeqPrepareNode(AChild: TYamlEmitterNodeType);
    procedure FlowMapPrepareNode(AChild: TYamlEmitterNodeType);
    procedure FlowMapPrepareLongKey(AChild: TYamlEmitterNodeType);
    procedure FlowMapPrepareLongKeyValue(AChild: TYamlEmitterNodeType);
    procedure FlowMapPrepareSimpleKey(AChild: TYamlEmitterNodeType);
    procedure FlowMapPrepareSimpleKeyValue(AChild: TYamlEmitterNodeType);
    procedure BlockMapPrepareNode(AChild: TYamlEmitterNodeType);
    procedure BlockMapPrepareLongKey(AChild: TYamlEmitterNodeType);
    procedure BlockMapPrepareLongKeyValue(AChild: TYamlEmitterNodeType);
    procedure BlockMapPrepareSimpleKey(AChild: TYamlEmitterNodeType);
    procedure BlockMapPrepareSimpleKeyValue(AChild: TYamlEmitterNodeType);
    procedure SpaceOrIndentTo(ARequireSpace: Boolean; AIndent: Integer);
    procedure StartedScalar;
    function ComputeFullBoolName(AValue: Boolean): TYamlText;
    function ComputeNullName: TYamlText;
    function EscapingStyle: TYamlStringEscaping;
    procedure WriteIntegral(AValue: UInt64; ANegative: Boolean; ABits: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function Text: TYamlText;
    function Size: Integer;
    function Good: Boolean;
    function LastError: TYamlText;
    function SetOutputCharset(AValue: TYamlManip): Boolean;
    function SetStringFormat(AValue: TYamlManip): Boolean;
    function SetBoolFormat(AValue: TYamlManip): Boolean;
    function SetNullFormat(AValue: TYamlManip): Boolean;
    function SetIntBase(AValue: TYamlManip): Boolean;
    function SetSeqFormat(AValue: TYamlManip): Boolean;
    function SetMapFormat(AValue: TYamlManip): Boolean;
    function SetIndent(AValue: NativeUInt): Boolean;
    function SetPreCommentIndent(AValue: NativeUInt): Boolean;
    function SetPostCommentIndent(AValue: NativeUInt): Boolean;
    function SetFloatPrecision(AValue: NativeUInt): Boolean;
    function SetDoublePrecision(AValue: NativeUInt): Boolean;
    procedure RestoreGlobalModifiedSettings;
    procedure Manip(AValue: TYamlManip);
    procedure LocalIndent(AValue: Integer);
    procedure LocalPrecision(AFloatPrecision, ADoublePrecision: Integer);
    procedure WriteString(const AValue: TYamlText);
    procedure WriteBool(AValue: Boolean);
    procedure WriteChar(AValue: Byte);
    procedure WriteAlias(const AContent: TYamlText);
    procedure WriteAnchor(const AContent: TYamlText);
    procedure WriteTag(AKind: TYamlEmitterTagKind; const APrefix, AContent: TYamlText);
    procedure WriteComment(const AContent: TYamlText);
    procedure WriteNull;
    procedure WriteBinary(const AData: TBytes);
    procedure WriteInteger(AValue: Integer);
    procedure WriteCardinal(AValue: Cardinal);
    procedure WriteSmallInt(AValue: SmallInt);
    procedure WriteWord(AValue: Word);
    procedure WriteInt64(AValue: Int64);
    procedure WriteUInt64(AValue: UInt64);
    procedure WriteDouble(AValue: Double);
    procedure WriteSingle(AValue: Single);
    procedure WriteNode(const ANode: IYamlNode);
  end;

implementation

constructor TYamlEmitter.Create;
begin
  inherited Create;
  FState := TYamlEmitterState.Create;
  FStream := TYamlOutputWriter.Create;
end;

destructor TYamlEmitter.Destroy;
begin
  FStream.Free;
  FState.Free;
  inherited Destroy;
end;

function TYamlEmitter.Text: TYamlText;
begin
  Result := FStream.Text;
end;

function TYamlEmitter.Size: Integer;
begin
  Result := FStream.Pos;
end;

function TYamlEmitter.Good: Boolean;
begin
  Result := FState.Good;
end;

function TYamlEmitter.LastError: TYamlText;
begin
  Result := FState.GetLastError;
end;

function TYamlEmitter.SetOutputCharset(AValue: TYamlManip): Boolean;
begin
  Result := FState.SetOutputCharset(AValue, fsGlobal);
end;

function TYamlEmitter.SetStringFormat(AValue: TYamlManip): Boolean;
begin
  Result := FState.SetStringFormat(AValue, fsGlobal);
end;

function TYamlEmitter.SetBoolFormat(AValue: TYamlManip): Boolean;
begin
  Result := False;
  if FState.SetBoolFormat(AValue, fsGlobal) then
    Result := True;
  if FState.SetBoolCaseFormat(AValue, fsGlobal) then
    Result := True;
  if FState.SetBoolLengthFormat(AValue, fsGlobal) then
    Result := True;
end;

function TYamlEmitter.SetNullFormat(AValue: TYamlManip): Boolean;
begin
  Result := FState.SetNullFormat(AValue, fsGlobal);
end;

function TYamlEmitter.SetIntBase(AValue: TYamlManip): Boolean;
begin
  Result := FState.SetIntFormat(AValue, fsGlobal);
end;

function TYamlEmitter.SetSeqFormat(AValue: TYamlManip): Boolean;
begin
  Result := FState.SetFlowType(gtSeq, AValue, fsGlobal);
end;

function TYamlEmitter.SetMapFormat(AValue: TYamlManip): Boolean;
begin
  Result := False;
  if FState.SetFlowType(gtMap, AValue, fsGlobal) then
    Result := True;
  if FState.SetMapKeyFormat(AValue, fsGlobal) then
    Result := True;
end;

function TYamlEmitter.SetIndent(AValue: NativeUInt): Boolean;
begin
  Result := FState.SetIndent(AValue, fsGlobal);
end;

function TYamlEmitter.SetPreCommentIndent(AValue: NativeUInt): Boolean;
begin
  Result := FState.SetPreCommentIndent(AValue, fsGlobal);
end;

function TYamlEmitter.SetPostCommentIndent(AValue: NativeUInt): Boolean;
begin
  Result := FState.SetPostCommentIndent(AValue, fsGlobal);
end;

function TYamlEmitter.SetFloatPrecision(AValue: NativeUInt): Boolean;
begin
  Result := FState.SetFloatPrecision(AValue, fsGlobal);
end;

function TYamlEmitter.SetDoublePrecision(AValue: NativeUInt): Boolean;
begin
  Result := FState.SetDoublePrecision(AValue, fsGlobal);
end;

procedure TYamlEmitter.RestoreGlobalModifiedSettings;
begin
  FState.RestoreGlobalModifiedSettings;
end;

procedure TYamlEmitter.Manip(AValue: TYamlManip);
begin
  if not Good then
    Exit;
  case AValue of
    ymBeginDoc: EmitBeginDoc;
    ymEndDoc: EmitEndDoc;
    ymBeginSeq: EmitBeginSeq;
    ymEndSeq: EmitEndSeq;
    ymBeginMap: EmitBeginMap;
    ymEndMap: EmitEndMap;
    ymKey, ymValue: ;
    ymTagByKind: EmitKindTag;
    ymNewline: EmitNewline;
  else
    FState.SetLocalValue(AValue);
  end;
end;

procedure TYamlEmitter.LocalIndent(AValue: Integer);
begin
  // the value is a std::size_t in C++: a negative number is a huge one (and accepted)
  FState.SetIndent(NativeUInt(AValue), fsLocal);
end;

procedure TYamlEmitter.LocalPrecision(AFloatPrecision, ADoublePrecision: Integer);
begin
  if AFloatPrecision >= 0 then
    FState.SetFloatPrecision(NativeUInt(AFloatPrecision), fsLocal);
  if ADoublePrecision >= 0 then
    FState.SetDoublePrecision(NativeUInt(ADoublePrecision), fsLocal);
end;

procedure TYamlEmitter.EmitBeginDoc;
begin
  if not Good then
    Exit;
  if FState.CurGroupType <> gtNoType then
  begin
    FState.SetError('Unexpected begin document');
    Exit;
  end;
  if FState.HasAnchor or FState.HasTag then
  begin
    FState.SetError('Unexpected begin document');
    Exit;
  end;
  if FStream.Col > 0 then
    FStream.Write(#10);
  FStream.Write('---'#10);
  FState.StartedDoc;
end;

procedure TYamlEmitter.EmitEndDoc;
begin
  if not Good then
    Exit;
  if FState.CurGroupType <> gtNoType then
  begin
    FState.SetError('Unexpected begin document');
    Exit;
  end;
  if FState.HasAnchor or FState.HasTag then
  begin
    FState.SetError('Unexpected begin document');
    Exit;
  end;
  if FStream.Col > 0 then
    FStream.Write(#10);
  FStream.Write('...'#10);
end;

procedure TYamlEmitter.EmitBeginSeq;
begin
  if not Good then
    Exit;
  PrepareNode(FState.NextGroupType(gtSeq));
  FState.StartedGroup(gtSeq);
end;

procedure TYamlEmitter.EmitEndSeq;
var
  LOriginalType: TYamlFlowType;
begin
  if not Good then
    Exit;
  LOriginalType := FState.CurGroupFlowType;
  if FState.CurGroupChildCount = 0 then
    FState.ForceFlow;
  if FState.CurGroupFlowType = ftFlow then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(FState.CurIndent);
    if LOriginalType = ftBlock then
      FStream.Write('[')
    else if (FState.CurGroupChildCount = 0) and (not FState.HasBegunNode) then
      FStream.Write('[');
    FStream.Write(']');
  end;
  FState.EndedGroup(gtSeq);
end;

procedure TYamlEmitter.EmitBeginMap;
begin
  if not Good then
    Exit;
  PrepareNode(FState.NextGroupType(gtMap));
  FState.StartedGroup(gtMap);
end;

procedure TYamlEmitter.EmitEndMap;
var
  LOriginalType: TYamlFlowType;
begin
  if not Good then
    Exit;
  LOriginalType := FState.CurGroupFlowType;
  if FState.CurGroupChildCount = 0 then
    FState.ForceFlow;
  if FState.CurGroupFlowType = ftFlow then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(FState.CurIndent);
    if LOriginalType = ftBlock then
      FStream.Write('{')
    else if (FState.CurGroupChildCount = 0) and (not FState.HasBegunNode) then
      FStream.Write('{');
    FStream.Write('}');
  end;
  FState.EndedGroup(gtMap);
end;

procedure TYamlEmitter.EmitNewline;
begin
  if not Good then
    Exit;
  PrepareNode(entNoType);
  FStream.Write(#10);
  FState.SetNonContent;
end;

procedure TYamlEmitter.PrepareNode(AChild: TYamlEmitterNodeType);
begin
  case FState.CurGroupNodeType of
    entNoType: PrepareTopNode(AChild);
    entFlowSeq: FlowSeqPrepareNode(AChild);
    entBlockSeq: BlockSeqPrepareNode(AChild);
    entFlowMap: FlowMapPrepareNode(AChild);
    entBlockMap: BlockMapPrepareNode(AChild);
    entProperty, entScalar: ;
  end;
end;

procedure TYamlEmitter.PrepareTopNode(AChild: TYamlEmitterNodeType);
begin
  if AChild = entNoType then
    Exit;
  if (FState.CurGroupChildCount > 0) and (FStream.Col > 0) then
    EmitBeginDoc;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent, 0);
    entBlockSeq, entBlockMap:
      if FState.HasBegunNode then
        FStream.Write(#10);
  end;
end;

procedure TYamlEmitter.FlowSeqPrepareNode(AChild: TYamlEmitterNodeType);
var
  LLastIndent: Integer;
begin
  LLastIndent := FState.LastIndent;
  if not FState.HasBegunNode then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LLastIndent);
    if FState.CurGroupChildCount = 0 then
      FStream.Write('[')
    else
      FStream.Write(',');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent or (FState.CurGroupChildCount > 0), LLastIndent);
    entBlockSeq, entBlockMap: ;
  end;
end;

procedure TYamlEmitter.BlockSeqPrepareNode(AChild: TYamlEmitterNodeType);
var
  LCurIndent, LNextIndent: Integer;
begin
  LCurIndent := FState.CurIndent;
  LNextIndent := LCurIndent + FState.CurGroupIndent;
  if AChild = entNoType then
    Exit;
  if not FState.HasBegunContent then
  begin
    if (FState.CurGroupChildCount > 0) or FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LCurIndent);
    FStream.Write('-');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent, LNextIndent);
    entBlockSeq:
      FStream.Write(#10);
    entBlockMap:
      if FState.HasBegunContent or FStream.Comment then
        FStream.Write(#10);
  end;
end;

procedure TYamlEmitter.FlowMapPrepareNode(AChild: TYamlEmitterNodeType);
begin
  if FState.CurGroupChildCount mod 2 = 0 then
  begin
    if FState.GetMapKeyFormat = ymLongKey then
      FState.SetLongKey;
    if FState.CurGroupLongKey then
      FlowMapPrepareLongKey(AChild)
    else
      FlowMapPrepareSimpleKey(AChild);
  end
  else
  begin
    if FState.CurGroupLongKey then
      FlowMapPrepareLongKeyValue(AChild)
    else
      FlowMapPrepareSimpleKeyValue(AChild);
  end;
end;

procedure TYamlEmitter.FlowMapPrepareLongKey(AChild: TYamlEmitterNodeType);
var
  LLastIndent: Integer;
begin
  LLastIndent := FState.LastIndent;
  if not FState.HasBegunNode then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LLastIndent);
    if FState.CurGroupChildCount = 0 then
      FStream.Write('{ ?')
    else
      FStream.Write(', ?');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent or (FState.CurGroupChildCount > 0), LLastIndent);
    entBlockSeq, entBlockMap: ;
  end;
end;

procedure TYamlEmitter.FlowMapPrepareLongKeyValue(AChild: TYamlEmitterNodeType);
var
  LLastIndent: Integer;
begin
  LLastIndent := FState.LastIndent;
  if not FState.HasBegunNode then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LLastIndent);
    FStream.Write(':');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent or (FState.CurGroupChildCount > 0), LLastIndent);
    entBlockSeq, entBlockMap: ;
  end;
end;

procedure TYamlEmitter.FlowMapPrepareSimpleKey(AChild: TYamlEmitterNodeType);
var
  LLastIndent: Integer;
begin
  LLastIndent := FState.LastIndent;
  if not FState.HasBegunNode then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LLastIndent);
    if FState.CurGroupChildCount = 0 then
      FStream.Write('{')
    else
      FStream.Write(',');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent or (FState.CurGroupChildCount > 0), LLastIndent);
    entBlockSeq, entBlockMap: ;
  end;
end;

procedure TYamlEmitter.FlowMapPrepareSimpleKeyValue(AChild: TYamlEmitterNodeType);
var
  LLastIndent: Integer;
begin
  LLastIndent := FState.LastIndent;
  if not FState.HasBegunNode then
  begin
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LLastIndent);
    if FState.HasAlias then
      FStream.Write(' ');
    FStream.Write(':');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent or (FState.CurGroupChildCount > 0), LLastIndent);
    entBlockSeq, entBlockMap: ;
  end;
end;

procedure TYamlEmitter.BlockMapPrepareNode(AChild: TYamlEmitterNodeType);
begin
  if FState.CurGroupChildCount mod 2 = 0 then
  begin
    if FState.GetMapKeyFormat = ymLongKey then
      FState.SetLongKey;
    if (AChild = entBlockSeq) or (AChild = entBlockMap) then
      FState.SetLongKey;
    if FState.CurGroupLongKey then
      BlockMapPrepareLongKey(AChild)
    else
      BlockMapPrepareSimpleKey(AChild);
  end
  else
  begin
    if FState.CurGroupLongKey then
      BlockMapPrepareLongKeyValue(AChild)
    else
      BlockMapPrepareSimpleKeyValue(AChild);
  end;
end;

procedure TYamlEmitter.BlockMapPrepareLongKey(AChild: TYamlEmitterNodeType);
var
  LCurIndent, LChildCount: Integer;
begin
  LCurIndent := FState.CurIndent;
  LChildCount := FState.CurGroupChildCount;
  if AChild = entNoType then
    Exit;
  if not FState.HasBegunContent then
  begin
    if LChildCount > 0 then
      FStream.Write(#10);
    if FStream.Comment then
      FStream.Write(#10);
    FStream.IndentTo(LCurIndent);
    FStream.Write('?');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(True, LCurIndent + 1);
    entBlockSeq, entBlockMap:
      if FState.HasBegunContent then
        FStream.Write(#10);
  end;
end;

procedure TYamlEmitter.BlockMapPrepareLongKeyValue(AChild: TYamlEmitterNodeType);
var
  LCurIndent: Integer;
begin
  LCurIndent := FState.CurIndent;
  if AChild = entNoType then
    Exit;
  if not FState.HasBegunContent then
  begin
    FStream.Write(#10);
    FStream.IndentTo(LCurIndent);
    FStream.Write(':');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(True, LCurIndent + 1);
    entBlockSeq, entBlockMap:
      begin
        if FState.HasBegunContent then
          FStream.Write(#10);
        SpaceOrIndentTo(True, LCurIndent + 1);
      end;
  end;
end;

procedure TYamlEmitter.BlockMapPrepareSimpleKey(AChild: TYamlEmitterNodeType);
var
  LCurIndent, LChildCount: Integer;
begin
  LCurIndent := FState.CurIndent;
  LChildCount := FState.CurGroupChildCount;
  if AChild = entNoType then
    Exit;
  if not FState.HasBegunNode then
  begin
    if LChildCount > 0 then
      FStream.Write(#10);
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(FState.HasBegunContent, LCurIndent);
    entBlockSeq, entBlockMap: ;
  end;
end;

procedure TYamlEmitter.BlockMapPrepareSimpleKeyValue(AChild: TYamlEmitterNodeType);
var
  LCurIndent, LNextIndent: Integer;
begin
  LCurIndent := FState.CurIndent;
  LNextIndent := LCurIndent + FState.CurGroupIndent;
  if not FState.HasBegunNode then
  begin
    if FState.HasAlias then
      FStream.Write(' ');
    FStream.Write(':');
  end;
  case AChild of
    entNoType: ;
    entProperty, entScalar, entFlowSeq, entFlowMap:
      SpaceOrIndentTo(True, LNextIndent);
    entBlockSeq, entBlockMap:
      FStream.Write(#10);
  end;
end;

procedure TYamlEmitter.SpaceOrIndentTo(ARequireSpace: Boolean; AIndent: Integer);
begin
  if FStream.Comment then
    FStream.Write(#10);
  if (FStream.Col > 0) and ARequireSpace then
    FStream.Write(' ');
  FStream.IndentTo(AIndent);
end;

procedure TYamlEmitter.StartedScalar;
begin
  FState.StartedScalar;
end;

function TYamlEmitter.EscapingStyle: TYamlStringEscaping;
begin
  case FState.GetOutputCharset of
    ymEscapeNonAscii: Result := seNonAscii;
    ymEscapeAsJson: Result := seJSON;
  else
    Result := seNone;
  end;
end;

procedure TYamlEmitter.WriteString(const AValue: TYamlText);
var
  LEscaping: TYamlStringEscaping;
  LFormat: TYamlStringFormat;
begin
  if not Good then
    Exit;
  LEscaping := EscapingStyle;
  LFormat := TYamlEmitterUtils.ComputeStringFormat(AValue, FState.GetStringFormat, FState.CurGroupFlowType,
    LEscaping = seNonAscii);
  if (LFormat = sfLiteral) or (Length(AValue) > 1024) then
    FState.SetMapKeyFormat(ymLongKey, fsLocal);
  PrepareNode(entScalar);
  case LFormat of
    sfPlain: FStream.Write(AValue);
    sfSingleQuoted: TYamlEmitterUtils.WriteSingleQuotedString(FStream, AValue);
    sfDoubleQuoted: TYamlEmitterUtils.WriteDoubleQuotedString(FStream, AValue, LEscaping);
    sfLiteral: TYamlEmitterUtils.WriteLiteralString(FStream, AValue, FState.CurIndent + FState.GetIndent);
  end;
  StartedScalar;
end;

function TYamlEmitter.ComputeFullBoolName(AValue: Boolean): TYamlText;
var
  LMainFormat, LCaseFormat: TYamlManip;
begin
  if FState.GetBoolLengthFormat = ymShortBool then
    LMainFormat := ymYesNoBool
  else
    LMainFormat := FState.GetBoolFormat;
  LCaseFormat := FState.GetBoolCaseFormat;
  case LMainFormat of
    ymYesNoBool:
      case LCaseFormat of
        ymUpperCase: if AValue then Exit('YES') else Exit('NO');
        ymCamelCase: if AValue then Exit('Yes') else Exit('No');
        ymLowerCase: if AValue then Exit('yes') else Exit('no');
      end;
    ymOnOffBool:
      case LCaseFormat of
        ymUpperCase: if AValue then Exit('ON') else Exit('OFF');
        ymCamelCase: if AValue then Exit('On') else Exit('Off');
        ymLowerCase: if AValue then Exit('on') else Exit('off');
      end;
    ymTrueFalseBool:
      case LCaseFormat of
        ymUpperCase: if AValue then Exit('TRUE') else Exit('FALSE');
        ymCamelCase: if AValue then Exit('True') else Exit('False');
        ymLowerCase: if AValue then Exit('true') else Exit('false');
      end;
  end;
  if AValue then
    Result := 'y'
  else
    Result := 'n';
end;

function TYamlEmitter.ComputeNullName: TYamlText;
begin
  case FState.GetNullFormat of
    ymLowerNull: Result := 'null';
    ymUpperNull: Result := 'NULL';
    ymCamelNull: Result := 'Null';
  else
    Result := '~';
  end;
end;

procedure TYamlEmitter.WriteBool(AValue: Boolean);
var
  LName: TYamlText;
begin
  if not Good then
    Exit;
  PrepareNode(entScalar);
  LName := ComputeFullBoolName(AValue);
  if FState.GetBoolLengthFormat = ymShortBool then
    FStream.Write(Byte(LName[1]))
  else
    FStream.Write(LName);
  StartedScalar;
end;

procedure TYamlEmitter.WriteChar(AValue: Byte);
begin
  if not Good then
    Exit;
  PrepareNode(entScalar);
  TYamlEmitterUtils.WriteChar(FStream, AValue, EscapingStyle);
  StartedScalar;
end;

procedure TYamlEmitter.WriteAlias(const AContent: TYamlText);
begin
  if not Good then
    Exit;
  if FState.HasAnchor or FState.HasTag then
  begin
    FState.SetError(SYamlInvalidAlias);
    Exit;
  end;
  PrepareNode(entScalar);
  if not TYamlEmitterUtils.WriteAlias(FStream, AContent) then
  begin
    FState.SetError(SYamlInvalidAlias);
    Exit;
  end;
  StartedScalar;
  FState.SetAlias;
end;

procedure TYamlEmitter.WriteAnchor(const AContent: TYamlText);
begin
  if not Good then
    Exit;
  if FState.HasAnchor then
  begin
    FState.SetError(SYamlInvalidAnchor);
    Exit;
  end;
  PrepareNode(entProperty);
  if not TYamlEmitterUtils.WriteAnchor(FStream, AContent) then
  begin
    FState.SetError(SYamlInvalidAnchor);
    Exit;
  end;
  FState.SetAnchor;
end;

procedure TYamlEmitter.WriteTag(AKind: TYamlEmitterTagKind; const APrefix, AContent: TYamlText);
var
  LSuccess: Boolean;
begin
  if not Good then
    Exit;
  if FState.HasTag then
  begin
    FState.SetError(SYamlInvalidTag);
    Exit;
  end;
  PrepareNode(entProperty);
  case AKind of
    etVerbatim: LSuccess := TYamlEmitterUtils.WriteTag(FStream, AContent, True);
    etPrimaryHandle: LSuccess := TYamlEmitterUtils.WriteTag(FStream, AContent, False);
  else
    LSuccess := TYamlEmitterUtils.WriteTagWithPrefix(FStream, APrefix, AContent);
  end;
  if not LSuccess then
  begin
    FState.SetError(SYamlInvalidTag);
    Exit;
  end;
  FState.SetTag;
end;

procedure TYamlEmitter.EmitKindTag;
begin
  WriteTag(etPrimaryHandle, '', '');
end;

procedure TYamlEmitter.WriteComment(const AContent: TYamlText);
begin
  if not Good then
    Exit;
  PrepareNode(entNoType);
  if FStream.Col > 0 then
    FStream.WriteSpaces(FState.GetPreCommentIndent);
  TYamlEmitterUtils.WriteComment(FStream, AContent, FState.GetPostCommentIndent);
  FState.SetNonContent;
end;

procedure TYamlEmitter.WriteNull;
begin
  if not Good then
    Exit;
  PrepareNode(entScalar);
  FStream.Write(ComputeNullName);
  StartedScalar;
end;

procedure TYamlEmitter.WriteBinary(const AData: TBytes);
begin
  WriteTag(etNamedHandle, '', 'binary');
  if not Good then
    Exit;
  PrepareNode(entScalar);
  TYamlEmitterUtils.WriteBinary(FStream, AData);
  StartedScalar;
end;

procedure TYamlEmitter.WriteIntegral(AValue: UInt64; ANegative: Boolean; ABits: Integer);
var
  LBase: Integer;
begin
  if not Good then
    Exit;
  PrepareNode(entScalar);
  case FState.GetIntFormat of
    ymHex: LBase := 16;
    ymOct: LBase := 8;
  else
    LBase := 10;
  end;
  FStream.Write(TYamlConvert.FormatInteger(AValue, ANegative, ABits, LBase));
  StartedScalar;
end;

procedure TYamlEmitter.WriteInteger(AValue: Integer);
begin
  WriteIntegral(UInt64(Int64(AValue)), AValue < 0, 32);
end;

procedure TYamlEmitter.WriteCardinal(AValue: Cardinal);
begin
  WriteIntegral(AValue, False, 32);
end;

procedure TYamlEmitter.WriteSmallInt(AValue: SmallInt);
begin
  WriteIntegral(UInt64(Int64(AValue)), AValue < 0, 16);
end;

procedure TYamlEmitter.WriteWord(AValue: Word);
begin
  WriteIntegral(AValue, False, 16);
end;

procedure TYamlEmitter.WriteInt64(AValue: Int64);
begin
  WriteIntegral(UInt64(AValue), AValue < 0, 64);
end;

procedure TYamlEmitter.WriteUInt64(AValue: UInt64);
begin
  WriteIntegral(AValue, False, 64);
end;

procedure TYamlEmitter.WriteDouble(AValue: Double);
begin
  if not Good then
    Exit;
  PrepareNode(entScalar);
  if IsNan(AValue) then
    FStream.Write('.nan')
  else if IsInfinite(AValue) then
  begin
    if AValue < 0 then
      FStream.Write('-.inf')
    else
      FStream.Write('.inf');
  end
  else
    FStream.Write(TYamlConvert.FormatGeneral(AValue, FState.GetDoublePrecision));
  StartedScalar;
end;

procedure TYamlEmitter.WriteSingle(AValue: Single);
var
  LValue: Double;
begin
  if not Good then
    Exit;
  PrepareNode(entScalar);
  LValue := AValue;
  if IsNan(LValue) then
    FStream.Write('.nan')
  else if IsInfinite(LValue) then
  begin
    if LValue < 0 then
      FStream.Write('-.inf')
    else
      FStream.Write('.inf');
  end
  else
    FStream.Write(TYamlConvert.FormatGeneral(LValue, FState.GetFloatPrecision));
  StartedScalar;
end;

procedure TYamlEmitter.WriteNode(const ANode: IYamlNode);
var
  LEvents: TYamlNodeEvents;
  LHandler: IYamlEventHandler;
begin
  LHandler := TYamlEmitFromEvents.Create(Self);
  LEvents := TYamlNodeEvents.Create(ANode);
  try
    LEvents.Emit(LHandler);
  finally
    LEvents.Free;
  end;
end;

end.
