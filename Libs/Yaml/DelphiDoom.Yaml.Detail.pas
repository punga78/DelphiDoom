{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the node storage (YAML::detail)                  }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{  node_data, node_ref, node and memory are one unit here because they are     }
{  four views of the same thing and use each other's private fields            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Detail;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Convert;

type
  TYamlDetailNode = class;
  TYamlNodeRef = class;
  TYamlNodeData = class;
  TYamlMemory = class;

  /// <summary>
  ///   Reference counted base for the objects that yaml-cpp shares with std::shared_ptr (node_data, node_ref,
  ///   node, memory): an explicit count, because the references between them are plain pointers
  /// </summary>
  TYamlShared = class
  strict private
    FRefCount: Integer;
  public
    constructor Create;
    procedure AddRef;
    /// <summary>One reference less; the object is freed when the last one goes</summary>
    procedure Release;
  end;

  /// <summary>The key of a lookup: a text, an integer (a sequence index) or a node (found by identity)</summary>
  TYamlKeyKind = (kkText, kkInt, kkNode);

  TYamlKey = record
    Kind: TYamlKeyKind;
    Text: TYamlText;
    IntValue: Integer;
    Node: TYamlDetailNode;
    class function FromText(const AText: TYamlText): TYamlKey; static;
    class function FromInt(AValue: Integer): TYamlKey; static;
    class function FromNode(ANode: TYamlDetailNode): TYamlKey; static;
    /// <summary>The text of BAD_SUBSCRIPT_WITH_KEY</summary>
    function SubscriptMessage: TYamlText;
  end;

  TYamlNodePair = record
    Key: TYamlDetailNode;
    Value: TYamlDetailNode;
  end;

  /// <summary>memory: the set of nodes that live together</summary>
  TYamlMemory = class(TYamlShared)
  strict private
    FNodes: TList<TYamlDetailNode>;
    FKnown: TDictionary<TYamlDetailNode, Boolean>;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateNode: TYamlDetailNode;
    procedure Merge(AOther: TYamlMemory);
  end;

  /// <summary>memory_holder: what the handles share; Merge makes the other holder use this memory</summary>
  IYamlMemoryHolder = interface
    ['{6F4B4E0C-3A52-4C4D-8E0B-2B6A5D1B9C10}']
    function CreateNode: TYamlDetailNode;
    procedure Merge(const AOther: IYamlMemoryHolder);
    function GetMemory: TYamlMemory;
    procedure SetMemory(AMemory: TYamlMemory);
  end;

  TYamlMemoryHolder = class(TInterfacedObject, IYamlMemoryHolder)
  strict private
    FMemory: TYamlMemory;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateNode: TYamlDetailNode;
    procedure Merge(const AOther: IYamlMemoryHolder);
    function GetMemory: TYamlMemory;
    procedure SetMemory(AMemory: TYamlMemory);
  end;

  /// <summary>node_data: the type, the scalar and the children of a node</summary>
  TYamlNodeData = class(TYamlShared)
  strict private
    FIsDefined: Boolean;
    FMark: TYamlMark;
    FType: TYamlNodeType;
    FTag: TYamlText;
    FStyle: TYamlEmitterStyle;
    FScalar: TYamlText;
    FSequence: TList<TYamlDetailNode>;
    FSeqSize: Integer;
    FMap: TList<TYamlNodePair>;
    FUndefinedPairs: TList<TYamlNodePair>;
    procedure ComputeSeqSize;
    procedure ComputeMapSize;
    procedure ResetSequence;
    procedure ResetMap;
    procedure InsertMapPair(AKey, AValue: TYamlDetailNode);
    procedure ConvertToMap(const AMemory: IYamlMemoryHolder);
    procedure ConvertSequenceToMap(const AMemory: IYamlMemoryHolder);
    function KeyMatches(AMapKey: TYamlDetailNode; const AKey: TYamlKey): Boolean;
    function GetSequenceElement(const AKey: TYamlKey; AMemory: IYamlMemoryHolder; ACreate: Boolean): TYamlDetailNode;
    function ConvertToNode(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
  public
    constructor Create;
    destructor Destroy; override;
    procedure MarkDefined;
    procedure SetMark(const AMark: TYamlMark);
    procedure SetType(AType: TYamlNodeType);
    procedure SetTag(const ATag: TYamlText);
    procedure SetNull;
    procedure SetScalar(const AScalar: TYamlText);
    procedure SetStyle(AStyle: TYamlEmitterStyle);
    function IsDefined: Boolean;
    function Mark: TYamlMark;
    function NodeType: TYamlNodeType;
    function Scalar: TYamlText;
    function Tag: TYamlText;
    function Style: TYamlEmitterStyle;
    function Size: Integer;
    // iteration (what begin()/end() give)
    function SequenceCount: Integer;
    function SequenceAt(AIndex: Integer): TYamlDetailNode;
    function MapCount: Integer;
    function MapPairAt(AIndex: Integer): TYamlNodePair;
    procedure PushBack(ANode: TYamlDetailNode);
    procedure Insert(AKey, AValue: TYamlDetailNode; const AMemory: IYamlMemoryHolder);
    /// <summary>The const get: nil when the key is not there</summary>
    function Find(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
    /// <summary>The get that creates the entry</summary>
    function Get(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
    function Remove(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): Boolean;
    procedure ForceInsert(const AKey, AValue: TYamlKey; const AMemory: IYamlMemoryHolder);
  end;

  /// <summary>node_ref: the shared pointer to the data (set_ref makes two nodes the same one)</summary>
  TYamlNodeRef = class(TYamlShared)
  strict private
    FData: TYamlNodeData;
  public
    constructor Create;
    destructor Destroy; override;
    property Data: TYamlNodeData read FData;
    procedure SetData(ARhs: TYamlNodeRef);
  end;

  /// <summary>detail::node</summary>
  TYamlDetailNode = class(TYamlShared)
  strict private
    class var FAmount: UInt64;
  strict private
    FRef: TYamlNodeRef;
    FDependencies: TList<TYamlDetailNode>;
    FIndex: UInt64;
    procedure SetRefInternal(ARef: TYamlNodeRef);
    function InsertDependency(ANode: TYamlDetailNode): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function Is_(ARhs: TYamlDetailNode): Boolean;
    function Ref: TYamlNodeRef;
    function IsDefined: Boolean;
    function Mark: TYamlMark;
    function NodeType: TYamlNodeType;
    function Scalar: TYamlText;
    function Tag: TYamlText;
    function Style: TYamlEmitterStyle;
    procedure MarkDefined;
    procedure AddDependency(ARhs: TYamlDetailNode);
    procedure SetRef(ARhs: TYamlDetailNode);
    procedure SetData(ARhs: TYamlDetailNode);
    procedure SetMark(const AMark: TYamlMark);
    procedure SetType(AType: TYamlNodeType);
    procedure SetNull;
    procedure SetScalar(const AScalar: TYamlText);
    procedure SetTag(const ATag: TYamlText);
    procedure SetStyle(AStyle: TYamlEmitterStyle);
    function Size: Integer;
    function SequenceCount: Integer;
    function SequenceAt(AIndex: Integer): TYamlDetailNode;
    function MapCount: Integer;
    function MapPairAt(AIndex: Integer): TYamlNodePair;
    procedure PushBack(AInput: TYamlDetailNode);
    procedure Insert(AKey, AValue: TYamlDetailNode; const AMemory: IYamlMemoryHolder);
    function Find(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
    function Get(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
    function Remove(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): Boolean;
    procedure ForceInsert(const AKey, AValue: TYamlKey; const AMemory: IYamlMemoryHolder);
  end;

implementation

{ TYamlShared }

constructor TYamlShared.Create;
begin
  inherited Create;
  FRefCount := 1;
end;

procedure TYamlShared.AddRef;
begin
  Inc(FRefCount);
end;

procedure TYamlShared.Release;
begin
  Dec(FRefCount);
  if FRefCount = 0 then
    Free;
end;

{ TYamlKey }

class function TYamlKey.FromText(const AText: TYamlText): TYamlKey;
begin
  Result.Kind := kkText;
  Result.Text := AText;
  Result.IntValue := 0;
  Result.Node := nil;
end;

class function TYamlKey.FromInt(AValue: Integer): TYamlKey;
begin
  Result.Kind := kkInt;
  Result.Text := '';
  Result.IntValue := AValue;
  Result.Node := nil;
end;

class function TYamlKey.FromNode(ANode: TYamlDetailNode): TYamlKey;
begin
  Result.Kind := kkNode;
  Result.Text := '';
  Result.IntValue := 0;
  Result.Node := ANode;
end;

function TYamlKey.SubscriptMessage: TYamlText;
begin
  case Kind of
    kkText: Result := YamlBadSubscriptMessage(Text);
    kkInt: Result := YamlBadSubscriptMessage(TYamlText(IntToStr(IntValue)));
  else
    Result := SYamlBadSubscript;
  end;
end;

{ TYamlMemory }

constructor TYamlMemory.Create;
begin
  inherited Create;
  FNodes := TList<TYamlDetailNode>.Create;
  FKnown := TDictionary<TYamlDetailNode, Boolean>.Create;
end;

destructor TYamlMemory.Destroy;
var
  LNode: TYamlDetailNode;
begin
  for LNode in FNodes do
    LNode.Release;
  FNodes.Free;
  FKnown.Free;
  inherited Destroy;
end;

function TYamlMemory.CreateNode: TYamlDetailNode;
begin
  Result := TYamlDetailNode.Create;
  FNodes.Add(Result);
  FKnown.Add(Result, True);
end;

procedure TYamlMemory.Merge(AOther: TYamlMemory);
var
  LNode: TYamlDetailNode;
begin
  for LNode in AOther.FNodes do
    if not FKnown.ContainsKey(LNode) then
    begin
      LNode.AddRef;
      FNodes.Add(LNode);
      FKnown.Add(LNode, True);
    end;
end;

{ TYamlMemoryHolder }

constructor TYamlMemoryHolder.Create;
begin
  inherited Create;
  FMemory := TYamlMemory.Create;
end;

destructor TYamlMemoryHolder.Destroy;
begin
  FMemory.Release;
  inherited Destroy;
end;

function TYamlMemoryHolder.CreateNode: TYamlDetailNode;
begin
  Result := FMemory.CreateNode;
end;

function TYamlMemoryHolder.GetMemory: TYamlMemory;
begin
  Result := FMemory;
end;

procedure TYamlMemoryHolder.SetMemory(AMemory: TYamlMemory);
begin
  AMemory.AddRef;
  FMemory.Release;
  FMemory := AMemory;
end;

procedure TYamlMemoryHolder.Merge(const AOther: IYamlMemoryHolder);
begin
  if FMemory = AOther.GetMemory then
    Exit;
  FMemory.Merge(AOther.GetMemory);
  AOther.SetMemory(FMemory);
end;

{ TYamlNodeData }

constructor TYamlNodeData.Create;
begin
  inherited Create;
  FIsDefined := False;
  FMark := TYamlMark.NullMark;
  FType := ntNull;
  FStyle := esDefault;
  FSequence := TList<TYamlDetailNode>.Create;
  FMap := TList<TYamlNodePair>.Create;
  FUndefinedPairs := TList<TYamlNodePair>.Create;
end;

destructor TYamlNodeData.Destroy;
begin
  FUndefinedPairs.Free;
  FMap.Free;
  FSequence.Free;
  inherited Destroy;
end;

procedure TYamlNodeData.MarkDefined;
begin
  if FType = ntUndefined then
    FType := ntNull;
  FIsDefined := True;
end;

procedure TYamlNodeData.SetMark(const AMark: TYamlMark);
begin
  FMark := AMark;
end;

procedure TYamlNodeData.SetType(AType: TYamlNodeType);
begin
  if AType = ntUndefined then
  begin
    FType := AType;
    FIsDefined := False;
    Exit;
  end;
  FIsDefined := True;
  if AType = FType then
    Exit;
  FType := AType;
  case FType of
    ntNull: ;
    ntScalar: FScalar := '';
    ntSequence: ResetSequence;
    ntMap: ResetMap;
  end;
end;

procedure TYamlNodeData.SetTag(const ATag: TYamlText);
begin
  FTag := ATag;
end;

procedure TYamlNodeData.SetStyle(AStyle: TYamlEmitterStyle);
begin
  FStyle := AStyle;
end;

procedure TYamlNodeData.SetNull;
begin
  FIsDefined := True;
  FType := ntNull;
end;

procedure TYamlNodeData.SetScalar(const AScalar: TYamlText);
begin
  FIsDefined := True;
  FType := ntScalar;
  FScalar := AScalar;
end;

function TYamlNodeData.IsDefined: Boolean;
begin
  Result := FIsDefined;
end;

function TYamlNodeData.Mark: TYamlMark;
begin
  Result := FMark;
end;

function TYamlNodeData.NodeType: TYamlNodeType;
begin
  if FIsDefined then
    Result := FType
  else
    Result := ntUndefined;
end;

function TYamlNodeData.Scalar: TYamlText;
begin
  Result := FScalar;
end;

function TYamlNodeData.Tag: TYamlText;
begin
  Result := FTag;
end;

function TYamlNodeData.Style: TYamlEmitterStyle;
begin
  Result := FStyle;
end;

function TYamlNodeData.Size: Integer;
begin
  Result := 0;
  if not FIsDefined then
    Exit;
  case FType of
    ntSequence:
      begin
        ComputeSeqSize;
        Result := FSeqSize;
      end;
    ntMap:
      begin
        ComputeMapSize;
        Result := FMap.Count - FUndefinedPairs.Count;
      end;
  end;
end;

procedure TYamlNodeData.ComputeSeqSize;
begin
  while (FSeqSize < FSequence.Count) and FSequence[FSeqSize].IsDefined do
    Inc(FSeqSize);
end;

procedure TYamlNodeData.ComputeMapSize;
var
  I: Integer;
begin
  I := 0;
  while I < FUndefinedPairs.Count do
  begin
    if FUndefinedPairs[I].Key.IsDefined and FUndefinedPairs[I].Value.IsDefined then
      FUndefinedPairs.Delete(I)
    else
      Inc(I);
  end;
end;

function TYamlNodeData.SequenceCount: Integer;
begin
  if FIsDefined and (FType = ntSequence) then
    Result := FSequence.Count
  else
    Result := 0;
end;

function TYamlNodeData.SequenceAt(AIndex: Integer): TYamlDetailNode;
begin
  Result := FSequence[AIndex];
end;

function TYamlNodeData.MapCount: Integer;
begin
  if FIsDefined and (FType = ntMap) then
    Result := FMap.Count
  else
    Result := 0;
end;

function TYamlNodeData.MapPairAt(AIndex: Integer): TYamlNodePair;
begin
  Result := FMap[AIndex];
end;

procedure TYamlNodeData.PushBack(ANode: TYamlDetailNode);
begin
  if (FType = ntUndefined) or (FType = ntNull) then
  begin
    FType := ntSequence;
    ResetSequence;
  end;
  if FType <> ntSequence then
    raise EYamlBadPushback.Create(TYamlMark.NullMark, SYamlBadPushback);
  FSequence.Add(ANode);
end;

procedure TYamlNodeData.Insert(AKey, AValue: TYamlDetailNode; const AMemory: IYamlMemoryHolder);
begin
  case FType of
    ntMap: ;
    ntUndefined, ntNull, ntSequence: ConvertToMap(AMemory);
    ntScalar: raise EYamlBadSubscript.Create(FMark, SYamlBadSubscript);
  end;
  InsertMapPair(AKey, AValue);
end;

function TYamlNodeData.KeyMatches(AMapKey: TYamlDetailNode; const AKey: TYamlKey): Boolean;
var
  LValue: Integer;
begin
  case AKey.Kind of
    kkNode:
      Result := AMapKey.Is_(AKey.Node);
    kkText:
      Result := (AMapKey.NodeType = ntScalar) and (AMapKey.Scalar = AKey.Text);
  else
    Result := (AMapKey.NodeType = ntScalar) and TYamlConvert.TryInt32(AMapKey.Scalar, LValue) and
      (LValue = AKey.IntValue);
  end;
end;

function TYamlNodeData.GetSequenceElement(const AKey: TYamlKey; AMemory: IYamlMemoryHolder;
  ACreate: Boolean): TYamlDetailNode;
var
  LIndex: Integer;
begin
  Result := nil;
  if AKey.Kind <> kkInt then
    Exit;
  if AKey.IntValue < 0 then
    Exit;
  LIndex := AKey.IntValue;
  if not ACreate then
  begin
    if LIndex < FSequence.Count then
      Result := FSequence[LIndex];
    Exit;
  end;
  if (LIndex > FSequence.Count) or ((LIndex > 0) and (not FSequence[LIndex - 1].IsDefined)) then
    Exit;
  if LIndex = FSequence.Count then
    FSequence.Add(AMemory.CreateNode);
  Result := FSequence[LIndex];
end;

function TYamlNodeData.ConvertToNode(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
begin
  Result := AMemory.CreateNode;
  case AKey.Kind of
    kkText: Result.SetScalar(AKey.Text);
    kkInt: Result.SetScalar(TYamlText(IntToStr(AKey.IntValue)));
  end;
end;

function TYamlNodeData.Find(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
var
  LPair: TYamlNodePair;
begin
  Result := nil;
  if AKey.Kind = kkNode then
  begin
    if FType <> ntMap then
      Exit;
    for LPair in FMap do
      if LPair.Key.Is_(AKey.Node) then
        Exit(LPair.Value);
    Exit;
  end;
  case FType of
    ntMap: ;
    ntUndefined, ntNull: Exit;
    ntSequence: Exit(GetSequenceElement(AKey, AMemory, False));
    ntScalar: raise EYamlBadSubscript.Create(FMark, AKey.SubscriptMessage);
  end;
  for LPair in FMap do
    if KeyMatches(LPair.Key, AKey) then
      Exit(LPair.Value);
end;

function TYamlNodeData.Get(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
var
  LPair: TYamlNodePair;
  LKey, LValue: TYamlDetailNode;
begin
  if AKey.Kind = kkNode then
  begin
    case FType of
      ntMap: ;
      ntUndefined, ntNull, ntSequence: ConvertToMap(AMemory);
      ntScalar: raise EYamlBadSubscript.Create(FMark, SYamlBadSubscript);
    end;
    for LPair in FMap do
      if LPair.Key.Is_(AKey.Node) then
        Exit(LPair.Value);
    LValue := AMemory.CreateNode;
    InsertMapPair(AKey.Node, LValue);
    Exit(LValue);
  end;
  case FType of
    ntMap: ;
    ntUndefined, ntNull, ntSequence:
      begin
        LValue := GetSequenceElement(AKey, AMemory, True);
        if Assigned(LValue) then
        begin
          FType := ntSequence;
          Exit(LValue);
        end;
        ConvertToMap(AMemory);
      end;
    ntScalar: raise EYamlBadSubscript.Create(FMark, AKey.SubscriptMessage);
  end;
  for LPair in FMap do
    if KeyMatches(LPair.Key, AKey) then
      Exit(LPair.Value);
  LKey := ConvertToNode(AKey, AMemory);
  LValue := AMemory.CreateNode;
  InsertMapPair(LKey, LValue);
  Result := LValue;
end;

function TYamlNodeData.Remove(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): Boolean;
var
  I: Integer;
begin
  Result := False;
  if AKey.Kind = kkNode then
  begin
    if FType <> ntMap then
      Exit;
    I := 0;
    while I < FUndefinedPairs.Count do
      if FUndefinedPairs[I].Key.Is_(AKey.Node) then
        FUndefinedPairs.Delete(I)
      else
        Inc(I);
    for I := 0 to FMap.Count - 1 do
      if FMap[I].Key.Is_(AKey.Node) then
      begin
        FMap.Delete(I);
        Exit(True);
      end;
    Exit;
  end;
  if FType = ntSequence then
  begin
    if (AKey.Kind <> kkInt) or (AKey.IntValue < 0) then
      Exit(False);
    if AKey.IntValue >= FSequence.Count then
      Exit(False);
    FSequence.Delete(AKey.IntValue);
    if FSeqSize > AKey.IntValue then
      Dec(FSeqSize);
    Exit(True);
  end;
  if FType = ntMap then
  begin
    I := 0;
    while I < FUndefinedPairs.Count do
      if KeyMatches(FUndefinedPairs[I].Key, AKey) then
        FUndefinedPairs.Delete(I)
      else
        Inc(I);
    for I := 0 to FMap.Count - 1 do
      if KeyMatches(FMap[I].Key, AKey) then
      begin
        FMap.Delete(I);
        Exit(True);
      end;
  end;
end;

procedure TYamlNodeData.ForceInsert(const AKey, AValue: TYamlKey; const AMemory: IYamlMemoryHolder);
var
  LKey, LValue: TYamlDetailNode;
begin
  case FType of
    ntMap: ;
    ntUndefined, ntNull, ntSequence: ConvertToMap(AMemory);
    ntScalar: raise EYamlBadInsert.Create(TYamlMark.NullMark, SYamlBadInsert);
  end;
  LKey := ConvertToNode(AKey, AMemory);
  LValue := ConvertToNode(AValue, AMemory);
  InsertMapPair(LKey, LValue);
end;

procedure TYamlNodeData.ResetSequence;
begin
  FSequence.Clear;
  FSeqSize := 0;
end;

procedure TYamlNodeData.ResetMap;
begin
  FMap.Clear;
  FUndefinedPairs.Clear;
end;

procedure TYamlNodeData.InsertMapPair(AKey, AValue: TYamlDetailNode);
var
  LPair: TYamlNodePair;
begin
  LPair.Key := AKey;
  LPair.Value := AValue;
  FMap.Add(LPair);
  if (not AKey.IsDefined) or (not AValue.IsDefined) then
    FUndefinedPairs.Add(LPair);
end;

procedure TYamlNodeData.ConvertToMap(const AMemory: IYamlMemoryHolder);
begin
  case FType of
    ntUndefined, ntNull:
      begin
        ResetMap;
        FType := ntMap;
      end;
    ntSequence: ConvertSequenceToMap(AMemory);
  end;
end;

procedure TYamlNodeData.ConvertSequenceToMap(const AMemory: IYamlMemoryHolder);
var
  I: Integer;
  LKey: TYamlDetailNode;
begin
  ResetMap;
  for I := 0 to FSequence.Count - 1 do
  begin
    LKey := AMemory.CreateNode;
    LKey.SetScalar(TYamlText(IntToStr(I)));
    InsertMapPair(LKey, FSequence[I]);
  end;
  ResetSequence;
  FType := ntMap;
end;

{ TYamlNodeRef }

constructor TYamlNodeRef.Create;
begin
  inherited Create;
  FData := TYamlNodeData.Create;
end;

destructor TYamlNodeRef.Destroy;
begin
  FData.Release;
  inherited Destroy;
end;

procedure TYamlNodeRef.SetData(ARhs: TYamlNodeRef);
begin
  ARhs.FData.AddRef;
  FData.Release;
  FData := ARhs.FData;
end;

{ TYamlDetailNode }

constructor TYamlDetailNode.Create;
begin
  inherited Create;
  FRef := TYamlNodeRef.Create;
  FDependencies := TList<TYamlDetailNode>.Create;
end;

destructor TYamlDetailNode.Destroy;
begin
  FDependencies.Free;
  FRef.Release;
  inherited Destroy;
end;

procedure TYamlDetailNode.SetRefInternal(ARef: TYamlNodeRef);
begin
  ARef.AddRef;
  FRef.Release;
  FRef := ARef;
end;

function TYamlDetailNode.Is_(ARhs: TYamlDetailNode): Boolean;
begin
  Result := FRef = ARhs.FRef;
end;

function TYamlDetailNode.Ref: TYamlNodeRef;
begin
  Result := FRef;
end;

function TYamlDetailNode.IsDefined: Boolean;
begin
  Result := FRef.Data.IsDefined;
end;

function TYamlDetailNode.Mark: TYamlMark;
begin
  Result := FRef.Data.Mark;
end;

function TYamlDetailNode.NodeType: TYamlNodeType;
begin
  Result := FRef.Data.NodeType;
end;

function TYamlDetailNode.Scalar: TYamlText;
begin
  Result := FRef.Data.Scalar;
end;

function TYamlDetailNode.Tag: TYamlText;
begin
  Result := FRef.Data.Tag;
end;

function TYamlDetailNode.Style: TYamlEmitterStyle;
begin
  Result := FRef.Data.Style;
end;

procedure TYamlDetailNode.MarkDefined;
var
  LDependencies: TArray<TYamlDetailNode>;
  LNode: TYamlDetailNode;
begin
  if IsDefined then
    Exit;
  FRef.Data.MarkDefined;
  LDependencies := FDependencies.ToArray;
  FDependencies.Clear;
  for LNode in LDependencies do
    LNode.MarkDefined;
end;

// std::set<node*, less>::insert: ordered by m_index, an element with the same index is not added again
function TYamlDetailNode.InsertDependency(ANode: TYamlDetailNode): Boolean;
var
  I: Integer;
begin
  for I := 0 to FDependencies.Count - 1 do
  begin
    if FDependencies[I].FIndex = ANode.FIndex then
      Exit(False);
    if FDependencies[I].FIndex > ANode.FIndex then
    begin
      FDependencies.Insert(I, ANode);
      Exit(True);
    end;
  end;
  FDependencies.Add(ANode);
  Result := True;
end;

procedure TYamlDetailNode.AddDependency(ARhs: TYamlDetailNode);
begin
  if IsDefined then
    ARhs.MarkDefined
  else
    InsertDependency(ARhs);
end;

procedure TYamlDetailNode.SetRef(ARhs: TYamlDetailNode);
begin
  if ARhs.IsDefined then
    MarkDefined;
  SetRefInternal(ARhs.FRef);
end;

procedure TYamlDetailNode.SetData(ARhs: TYamlDetailNode);
begin
  if ARhs.IsDefined then
    MarkDefined;
  FRef.SetData(ARhs.FRef);
end;

procedure TYamlDetailNode.SetMark(const AMark: TYamlMark);
begin
  FRef.Data.SetMark(AMark);
end;

procedure TYamlDetailNode.SetType(AType: TYamlNodeType);
begin
  if AType <> ntUndefined then
    MarkDefined;
  FRef.Data.SetType(AType);
end;

procedure TYamlDetailNode.SetNull;
begin
  MarkDefined;
  FRef.Data.SetNull;
end;

procedure TYamlDetailNode.SetScalar(const AScalar: TYamlText);
begin
  MarkDefined;
  FRef.Data.SetScalar(AScalar);
end;

procedure TYamlDetailNode.SetTag(const ATag: TYamlText);
begin
  MarkDefined;
  FRef.Data.SetTag(ATag);
end;

procedure TYamlDetailNode.SetStyle(AStyle: TYamlEmitterStyle);
begin
  MarkDefined;
  FRef.Data.SetStyle(AStyle);
end;

function TYamlDetailNode.Size: Integer;
begin
  Result := FRef.Data.Size;
end;

function TYamlDetailNode.SequenceCount: Integer;
begin
  Result := FRef.Data.SequenceCount;
end;

function TYamlDetailNode.SequenceAt(AIndex: Integer): TYamlDetailNode;
begin
  Result := FRef.Data.SequenceAt(AIndex);
end;

function TYamlDetailNode.MapCount: Integer;
begin
  Result := FRef.Data.MapCount;
end;

function TYamlDetailNode.MapPairAt(AIndex: Integer): TYamlNodePair;
begin
  Result := FRef.Data.MapPairAt(AIndex);
end;

procedure TYamlDetailNode.PushBack(AInput: TYamlDetailNode);
begin
  FRef.Data.PushBack(AInput);
  AInput.AddDependency(Self);
  FIndex := FAmount;
  Inc(FAmount);
end;

procedure TYamlDetailNode.Insert(AKey, AValue: TYamlDetailNode; const AMemory: IYamlMemoryHolder);
begin
  FRef.Data.Insert(AKey, AValue, AMemory);
  AKey.AddDependency(Self);
  AValue.AddDependency(Self);
end;

function TYamlDetailNode.Find(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
begin
  Result := FRef.Data.Find(AKey, AMemory);
end;

function TYamlDetailNode.Get(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): TYamlDetailNode;
begin
  Result := FRef.Data.Get(AKey, AMemory);
  if AKey.Kind = kkNode then
    AKey.Node.AddDependency(Self);
  Result.AddDependency(Self);
end;

function TYamlDetailNode.Remove(const AKey: TYamlKey; const AMemory: IYamlMemoryHolder): Boolean;
begin
  Result := FRef.Data.Remove(AKey, AMemory);
end;

procedure TYamlDetailNode.ForceInsert(const AKey, AValue: TYamlKey; const AMemory: IYamlMemoryHolder);
begin
  FRef.Data.ForceInsert(AKey, AValue, AMemory);
end;

end.
