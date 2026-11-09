{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the node handle (YAML::Node)                     }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Node;

interface

uses
  System.SysUtils,
  System.Math,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Convert,
  DelphiDoom.Yaml.Detail;

type
  /// <summary>
  ///   YAML::Node: a pointer to a node of a shared memory. Created by the factory and by the parser; it is
  ///   not thread safe (neither is yaml-cpp)
  /// </summary>
  TYamlNode = class(TInterfacedObject, IYamlNode)
  strict private
    FIsValid: Boolean;
    FInvalidKey: TYamlText;
    FMemory: IYamlMemoryHolder;
    FNode: TYamlDetailNode;
    procedure EnsureNodeExists;
    procedure RequireValid;
    procedure AssignNodeInternal(ARhs: TYamlNode);
    function ScalarForConversion(out AText: TYamlText): Boolean;
    function ConversionFailure: EYamlBadConversion;
    function ChildByKey(const AKey: TYamlKey): IYamlNode;
    function FindByKey(const AKey: TYamlKey): IYamlNode;
    function RemoveByKey(const AKey: TYamlKey): Boolean;
    function HandleOf(const ANode: IYamlNode): TYamlNode;
    function NewHandle(ANode: TYamlDetailNode): IYamlNode;
  public
    /// <summary>Node(): a null node that is not stored anywhere yet</summary>
    constructor Create; overload;
    /// <summary>Node(NodeType::value)</summary>
    constructor Create(AType: TYamlNodeType); overload;
    /// <summary>Node(string): a scalar</summary>
    constructor CreateScalar(const AText: TYamlText);
    /// <summary>A handle to an existing node</summary>
    constructor CreateHandle(ANode: TYamlDetailNode; const AMemory: IYamlMemoryHolder);
    /// <summary>The handle of a missing key (ZombieNode)</summary>
    class function NewZombie(const AKey: TYamlText): IYamlNode; static;
    function IsDefined: Boolean;
    function NodeType: TYamlNodeType;
    function IsNull: Boolean;
    function IsScalar: Boolean;
    function IsSequence: Boolean;
    function IsMap: Boolean;
    function Mark: TYamlMark;
    function Scalar: TYamlText;
    function ScalarString: string;
    function Tag: TYamlText;
    procedure SetTag(const ATag: TYamlText);
    function Style: TYamlEmitterStyle;
    procedure SetStyle(AStyle: TYamlEmitterStyle);
    function Size: Integer;
    function SameNode(const AOther: IYamlNode): Boolean;
    function Items: TArray<IYamlNode>;
    function Pairs: TArray<TYamlPair>;
    function Child(const AKey: TYamlText): IYamlNode; overload;
    function Child(AIndex: Integer): IYamlNode; overload;
    function Child(const AKey: IYamlNode): IYamlNode; overload;
    function Find(const AKey: TYamlText): IYamlNode; overload;
    function Find(AIndex: Integer): IYamlNode; overload;
    function Find(const AKey: IYamlNode): IYamlNode; overload;
    procedure Add(const AValue: IYamlNode); overload;
    procedure Add(const AValue: TYamlText); overload;
    function Remove(const AKey: TYamlText): Boolean; overload;
    function Remove(AIndex: Integer): Boolean; overload;
    function Remove(const AKey: IYamlNode): Boolean; overload;
    procedure Assign(const AValue: IYamlNode);
    procedure AssignScalar(const AValue: TYamlText);
    procedure AssignInteger(AValue: Integer);
    procedure AssignInt64(AValue: Int64);
    procedure AssignUInt64(AValue: UInt64);
    procedure AssignDouble(AValue: Double);
    procedure AssignSingle(AValue: Single);
    procedure AssignBoolean(AValue: Boolean);
    procedure AssignNull;
    procedure AssignData(const AValue: IYamlNode);
    procedure Reset(const AValue: IYamlNode);
    procedure ForceInsert(const AKey, AValue: TYamlText);
    function AsString: TYamlText; overload;
    function AsString(const ADefault: TYamlText): TYamlText; overload;
    function AsInteger: Integer; overload;
    function AsInteger(ADefault: Integer): Integer; overload;
    function AsCardinal: Cardinal; overload;
    function AsCardinal(ADefault: Cardinal): Cardinal; overload;
    function AsInt64: Int64; overload;
    function AsInt64(ADefault: Int64): Int64; overload;
    function AsUInt64: UInt64; overload;
    function AsUInt64(ADefault: UInt64): UInt64; overload;
    function AsSmallInt: SmallInt; overload;
    function AsSmallInt(ADefault: SmallInt): SmallInt; overload;
    function AsWord: Word; overload;
    function AsWord(ADefault: Word): Word; overload;
    function AsShortInt: ShortInt; overload;
    function AsShortInt(ADefault: ShortInt): ShortInt; overload;
    function AsByte: Byte; overload;
    function AsByte(ADefault: Byte): Byte; overload;
    function AsChar: AnsiChar; overload;
    function AsChar(ADefault: AnsiChar): AnsiChar; overload;
    function AsDouble: Double; overload;
    function AsDouble(ADefault: Double): Double; overload;
    function AsSingle: Single; overload;
    function AsSingle(ADefault: Single): Single; overload;
    function AsBoolean: Boolean; overload;
    function AsBoolean(ADefault: Boolean): Boolean; overload;
    function TryAsInteger(out AValue: Integer): Boolean;
    function TryAsCardinal(out AValue: Cardinal): Boolean;
    function TryAsInt64(out AValue: Int64): Boolean;
    function TryAsUInt64(out AValue: UInt64): Boolean;
    function TryAsSmallInt(out AValue: SmallInt): Boolean;
    function TryAsWord(out AValue: Word): Boolean;
    function TryAsChar(out AValue: AnsiChar): Boolean;
    function TryAsDouble(out AValue: Double): Boolean;
    function TryAsSingle(out AValue: Single): Boolean;
    function TryAsBoolean(out AValue: Boolean): Boolean;
    /// <summary>The node of the storage layer (nil for a node that is not stored yet)</summary>
    function DetailNode: TYamlDetailNode;
    function MemoryHolder: IYamlMemoryHolder;
    /// <summary>EnsureNodeExists made public: the node is stored (and a missing one is created null)</summary>
    function Stored: TYamlDetailNode;
  end;

implementation

{ TYamlNode }

constructor TYamlNode.Create;
begin
  inherited Create;
  FIsValid := True;
end;

constructor TYamlNode.Create(AType: TYamlNodeType);
begin
  inherited Create;
  FIsValid := True;
  FMemory := TYamlMemoryHolder.Create;
  FNode := FMemory.CreateNode;
  FNode.SetType(AType);
end;

constructor TYamlNode.CreateScalar(const AText: TYamlText);
begin
  inherited Create;
  FIsValid := True;
  FMemory := TYamlMemoryHolder.Create;
  FNode := FMemory.CreateNode;
  FNode.SetScalar(AText);
end;

constructor TYamlNode.CreateHandle(ANode: TYamlDetailNode; const AMemory: IYamlMemoryHolder);
begin
  inherited Create;
  FIsValid := True;
  FMemory := AMemory;
  FNode := ANode;
end;

class function TYamlNode.NewZombie(const AKey: TYamlText): IYamlNode;
var
  LNode: TYamlNode;
begin
  LNode := TYamlNode.Create;
  LNode.FIsValid := False;
  LNode.FInvalidKey := AKey;
  Result := LNode;
end;

function TYamlNode.DetailNode: TYamlDetailNode;
begin
  Result := FNode;
end;

function TYamlNode.MemoryHolder: IYamlMemoryHolder;
begin
  Result := FMemory;
end;

function TYamlNode.Stored: TYamlDetailNode;
begin
  EnsureNodeExists;
  Result := FNode;
end;

procedure TYamlNode.RequireValid;
begin
  if not FIsValid then
    raise EYamlInvalidNode.Create(TYamlMark.NullMark, YamlInvalidNodeMessage(FInvalidKey));
end;

procedure TYamlNode.EnsureNodeExists;
begin
  RequireValid;
  if not Assigned(FNode) then
  begin
    FMemory := TYamlMemoryHolder.Create;
    FNode := FMemory.CreateNode;
    FNode.SetNull;
  end;
end;

function TYamlNode.HandleOf(const ANode: IYamlNode): TYamlNode;
begin
  Result := ANode as TYamlNode;
end;

function TYamlNode.NewHandle(ANode: TYamlDetailNode): IYamlNode;
begin
  Result := TYamlNode.CreateHandle(ANode, FMemory);
end;

function TYamlNode.IsDefined: Boolean;
begin
  if not FIsValid then
    Exit(False);
  if Assigned(FNode) then
    Result := FNode.IsDefined
  else
    Result := True;
end;

function TYamlNode.Mark: TYamlMark;
begin
  RequireValid;
  if Assigned(FNode) then
    Result := FNode.Mark
  else
    Result := TYamlMark.NullMark;
end;

function TYamlNode.NodeType: TYamlNodeType;
begin
  RequireValid;
  if Assigned(FNode) then
    Result := FNode.NodeType
  else
    Result := ntNull;
end;

function TYamlNode.IsNull: Boolean;
begin
  Result := NodeType = ntNull;
end;

function TYamlNode.IsScalar: Boolean;
begin
  Result := NodeType = ntScalar;
end;

function TYamlNode.IsSequence: Boolean;
begin
  Result := NodeType = ntSequence;
end;

function TYamlNode.IsMap: Boolean;
begin
  Result := NodeType = ntMap;
end;

function TYamlNode.Scalar: TYamlText;
begin
  RequireValid;
  if Assigned(FNode) then
    Result := FNode.Scalar
  else
    Result := '';
end;

function TYamlNode.ScalarString: string;
begin
  Result := YamlTextToString(Scalar);
end;

function TYamlNode.Tag: TYamlText;
begin
  RequireValid;
  if Assigned(FNode) then
    Result := FNode.Tag
  else
    Result := '';
end;

procedure TYamlNode.SetTag(const ATag: TYamlText);
begin
  EnsureNodeExists;
  FNode.SetTag(ATag);
end;

function TYamlNode.Style: TYamlEmitterStyle;
begin
  RequireValid;
  if Assigned(FNode) then
    Result := FNode.Style
  else
    Result := esDefault;
end;

procedure TYamlNode.SetStyle(AStyle: TYamlEmitterStyle);
begin
  EnsureNodeExists;
  FNode.SetStyle(AStyle);
end;

function TYamlNode.Size: Integer;
begin
  RequireValid;
  if Assigned(FNode) then
    Result := FNode.Size
  else
    Result := 0;
end;

function TYamlNode.SameNode(const AOther: IYamlNode): Boolean;
var
  LOther: TYamlNode;
begin
  LOther := HandleOf(AOther);
  if (not FIsValid) or (not LOther.FIsValid) then
    RequireValid;
  if (not Assigned(FNode)) or (not Assigned(LOther.FNode)) then
    Exit(False);
  Result := FNode.Is_(LOther.FNode);
end;

function TYamlNode.Items: TArray<IYamlNode>;
var
  I: Integer;
begin
  Result := nil;
  if (not FIsValid) or (not Assigned(FNode)) then
    Exit;
  SetLength(Result, FNode.SequenceCount);
  for I := 0 to High(Result) do
    Result[I] := NewHandle(FNode.SequenceAt(I));
end;

function TYamlNode.Pairs: TArray<TYamlPair>;
var
  I, N: Integer;
  LPair: TYamlNodePair;
begin
  Result := nil;
  if (not FIsValid) or (not Assigned(FNode)) then
    Exit;
  N := 0;
  SetLength(Result, FNode.MapCount);
  for I := 0 to FNode.MapCount - 1 do
  begin
    LPair := FNode.MapPairAt(I);
    // the iterator skips the pairs that are not defined yet
    if LPair.Key.IsDefined and LPair.Value.IsDefined then
    begin
      Result[N].Key := NewHandle(LPair.Key);
      Result[N].Value := NewHandle(LPair.Value);
      Inc(N);
    end;
  end;
  SetLength(Result, N);
end;

function TYamlNode.ChildByKey(const AKey: TYamlKey): IYamlNode;
var
  LValue: TYamlDetailNode;
begin
  EnsureNodeExists;
  LValue := FNode.Get(AKey, FMemory);
  Result := NewHandle(LValue);
end;

function TYamlNode.FindByKey(const AKey: TYamlKey): IYamlNode;
var
  LValue: TYamlDetailNode;
  LText: TYamlText;
begin
  EnsureNodeExists;
  LValue := FNode.Find(AKey, FMemory);
  if not Assigned(LValue) then
  begin
    case AKey.Kind of
      kkText: LText := AKey.Text;
      kkInt: LText := TYamlText(IntToStr(AKey.IntValue));
    else
      LText := AKey.Node.Scalar;
    end;
    Exit(TYamlNode.NewZombie(LText));
  end;
  Result := NewHandle(LValue);
end;

function TYamlNode.RemoveByKey(const AKey: TYamlKey): Boolean;
begin
  EnsureNodeExists;
  Result := FNode.Remove(AKey, FMemory);
end;

function TYamlNode.Child(const AKey: TYamlText): IYamlNode;
begin
  Result := ChildByKey(TYamlKey.FromText(AKey));
end;

function TYamlNode.Child(AIndex: Integer): IYamlNode;
begin
  Result := ChildByKey(TYamlKey.FromInt(AIndex));
end;

function TYamlNode.Child(const AKey: IYamlNode): IYamlNode;
var
  LKey: TYamlNode;
begin
  EnsureNodeExists;
  LKey := HandleOf(AKey);
  LKey.EnsureNodeExists;
  FMemory.Merge(LKey.FMemory);
  Result := ChildByKey(TYamlKey.FromNode(LKey.FNode));
end;

function TYamlNode.Find(const AKey: TYamlText): IYamlNode;
begin
  Result := FindByKey(TYamlKey.FromText(AKey));
end;

function TYamlNode.Find(AIndex: Integer): IYamlNode;
begin
  Result := FindByKey(TYamlKey.FromInt(AIndex));
end;

function TYamlNode.Find(const AKey: IYamlNode): IYamlNode;
var
  LKey: TYamlNode;
begin
  EnsureNodeExists;
  LKey := HandleOf(AKey);
  LKey.EnsureNodeExists;
  FMemory.Merge(LKey.FMemory);
  Result := FindByKey(TYamlKey.FromNode(LKey.FNode));
end;

procedure TYamlNode.Add(const AValue: IYamlNode);
var
  LRhs: TYamlNode;
begin
  EnsureNodeExists;
  LRhs := HandleOf(AValue);
  LRhs.EnsureNodeExists;
  FNode.PushBack(LRhs.FNode);
  FMemory.Merge(LRhs.FMemory);
end;

procedure TYamlNode.Add(const AValue: TYamlText);
begin
  RequireValid;
  Add(TYamlNode.CreateScalar(AValue) as IYamlNode);
end;

function TYamlNode.Remove(const AKey: TYamlText): Boolean;
begin
  Result := RemoveByKey(TYamlKey.FromText(AKey));
end;

function TYamlNode.Remove(AIndex: Integer): Boolean;
begin
  Result := RemoveByKey(TYamlKey.FromInt(AIndex));
end;

function TYamlNode.Remove(const AKey: IYamlNode): Boolean;
var
  LKey: TYamlNode;
begin
  EnsureNodeExists;
  LKey := HandleOf(AKey);
  LKey.EnsureNodeExists;
  Result := FNode.Remove(TYamlKey.FromNode(LKey.FNode), FMemory);
end;

procedure TYamlNode.AssignNodeInternal(ARhs: TYamlNode);
begin
  RequireValid;
  ARhs.EnsureNodeExists;
  if not Assigned(FNode) then
  begin
    FNode := ARhs.FNode;
    FMemory := ARhs.FMemory;
    Exit;
  end;
  FNode.SetRef(ARhs.FNode);
  FMemory.Merge(ARhs.FMemory);
  FNode := ARhs.FNode;
end;

procedure TYamlNode.Assign(const AValue: IYamlNode);
var
  LRhs: TYamlNode;
begin
  LRhs := HandleOf(AValue);
  if SameNode(AValue) then
    Exit;
  AssignNodeInternal(LRhs);
end;

procedure TYamlNode.AssignScalar(const AValue: TYamlText);
begin
  EnsureNodeExists;
  FNode.SetScalar(AValue);
end;

procedure TYamlNode.AssignInteger(AValue: Integer);
begin
  AssignScalar(TYamlText(IntToStr(AValue)));
end;

procedure TYamlNode.AssignInt64(AValue: Int64);
begin
  AssignScalar(TYamlText(IntToStr(AValue)));
end;

procedure TYamlNode.AssignUInt64(AValue: UInt64);
begin
  AssignScalar(TYamlText(UIntToStr(AValue)));
end;

procedure TYamlNode.AssignDouble(AValue: Double);
begin
  if IsNan(AValue) then
    AssignScalar('.nan')
  else if IsInfinite(AValue) then
  begin
    if AValue < 0 then
      AssignScalar('-.inf')
    else
      AssignScalar('.inf');
  end
  else
    AssignScalar(TYamlConvert.FormatGeneral(AValue, 17));
end;

procedure TYamlNode.AssignSingle(AValue: Single);
var
  LValue: Double;
begin
  LValue := AValue;
  if IsNan(LValue) then
    AssignScalar('.nan')
  else if IsInfinite(LValue) then
  begin
    if LValue < 0 then
      AssignScalar('-.inf')
    else
      AssignScalar('.inf');
  end
  else
    AssignScalar(TYamlConvert.FormatGeneral(LValue, 9));
end;

procedure TYamlNode.AssignBoolean(AValue: Boolean);
begin
  if AValue then
    AssignScalar('true')
  else
    AssignScalar('false');
end;

procedure TYamlNode.AssignNull;
begin
  AssignData(TYamlNode.Create as IYamlNode);
end;

procedure TYamlNode.AssignData(const AValue: IYamlNode);
var
  LRhs: TYamlNode;
begin
  EnsureNodeExists;
  LRhs := HandleOf(AValue);
  LRhs.EnsureNodeExists;
  FNode.SetData(LRhs.FNode);
  FMemory.Merge(LRhs.FMemory);
end;

procedure TYamlNode.Reset(const AValue: IYamlNode);
var
  LRhs: TYamlNode;
begin
  LRhs := HandleOf(AValue);
  if (not FIsValid) or (not LRhs.FIsValid) then
    RequireValid;
  FMemory := LRhs.FMemory;
  FNode := LRhs.FNode;
end;

procedure TYamlNode.ForceInsert(const AKey, AValue: TYamlText);
begin
  EnsureNodeExists;
  FNode.ForceInsert(TYamlKey.FromText(AKey), TYamlKey.FromText(AValue), FMemory);
end;

{ conversions }

function TYamlNode.ScalarForConversion(out AText: TYamlText): Boolean;
begin
  AText := '';
  if not Assigned(FNode) then
    Exit(False);
  if FNode.NodeType <> ntScalar then
    Exit(False);
  AText := FNode.Scalar;
  Result := True;
end;

function TYamlNode.ConversionFailure: EYamlBadConversion;
begin
  Result := EYamlBadConversion.Create(Mark, SYamlBadConversion);
end;

function TYamlNode.TryAsInteger(out AValue: Integer): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryInt32(LText, AValue);
end;

function TYamlNode.TryAsCardinal(out AValue: Cardinal): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryUInt32(LText, AValue);
end;

function TYamlNode.TryAsInt64(out AValue: Int64): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryInt64(LText, AValue);
end;

function TYamlNode.TryAsUInt64(out AValue: UInt64): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryUInt64(LText, AValue);
end;

function TYamlNode.TryAsSmallInt(out AValue: SmallInt): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryInt16(LText, AValue);
end;

function TYamlNode.TryAsWord(out AValue: Word): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryUInt16(LText, AValue);
end;

function TYamlNode.TryAsChar(out AValue: AnsiChar): Boolean;
var
  LText: TYamlText;
begin
  AValue := #0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryChar(LText, AValue);
end;

function TYamlNode.TryAsDouble(out AValue: Double): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryDouble(LText, AValue);
end;

function TYamlNode.TryAsSingle(out AValue: Single): Boolean;
var
  LText: TYamlText;
begin
  AValue := 0;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TrySingle(LText, AValue);
end;

function TYamlNode.TryAsBoolean(out AValue: Boolean): Boolean;
var
  LText: TYamlText;
begin
  AValue := False;
  Result := FIsValid and ScalarForConversion(LText) and TYamlConvert.TryBool(LText, AValue);
end;

function TYamlNode.AsString: TYamlText;
begin
  RequireValid;
  if NodeType = ntNull then
    Exit('null');
  if NodeType <> ntScalar then
    raise ConversionFailure;
  Result := Scalar;
end;

function TYamlNode.AsString(const ADefault: TYamlText): TYamlText;
begin
  if not FIsValid then
    Exit(ADefault);
  if NodeType = ntNull then
    Exit('null');
  if NodeType <> ntScalar then
    Exit(ADefault);
  Result := Scalar;
end;

function TYamlNode.AsInteger: Integer;
begin
  RequireValid;
  if not TryAsInteger(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsInteger(ADefault: Integer): Integer;
begin
  if not TryAsInteger(Result) then
    Result := ADefault;
end;

function TYamlNode.AsCardinal: Cardinal;
begin
  RequireValid;
  if not TryAsCardinal(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsCardinal(ADefault: Cardinal): Cardinal;
begin
  if not TryAsCardinal(Result) then
    Result := ADefault;
end;

function TYamlNode.AsInt64: Int64;
begin
  RequireValid;
  if not TryAsInt64(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsInt64(ADefault: Int64): Int64;
begin
  if not TryAsInt64(Result) then
    Result := ADefault;
end;

function TYamlNode.AsUInt64: UInt64;
begin
  RequireValid;
  if not TryAsUInt64(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsUInt64(ADefault: UInt64): UInt64;
begin
  if not TryAsUInt64(Result) then
    Result := ADefault;
end;

function TYamlNode.AsSmallInt: SmallInt;
begin
  RequireValid;
  if not TryAsSmallInt(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsSmallInt(ADefault: SmallInt): SmallInt;
begin
  if not TryAsSmallInt(Result) then
    Result := ADefault;
end;

function TYamlNode.AsWord: Word;
begin
  RequireValid;
  if not TryAsWord(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsWord(ADefault: Word): Word;
begin
  if not TryAsWord(Result) then
    Result := ADefault;
end;

function TYamlNode.AsShortInt: ShortInt;
var
  LText: TYamlText;
begin
  RequireValid;
  if not (ScalarForConversion(LText) and TYamlConvert.TryInt8(LText, Result)) then
    raise ConversionFailure;
end;

function TYamlNode.AsShortInt(ADefault: ShortInt): ShortInt;
var
  LText: TYamlText;
begin
  if not (FIsValid and ScalarForConversion(LText) and TYamlConvert.TryInt8(LText, Result)) then
    Result := ADefault;
end;

function TYamlNode.AsByte: Byte;
var
  LText: TYamlText;
begin
  RequireValid;
  if not (ScalarForConversion(LText) and TYamlConvert.TryUInt8(LText, Result)) then
    raise ConversionFailure;
end;

function TYamlNode.AsByte(ADefault: Byte): Byte;
var
  LText: TYamlText;
begin
  if not (FIsValid and ScalarForConversion(LText) and TYamlConvert.TryUInt8(LText, Result)) then
    Result := ADefault;
end;

function TYamlNode.AsChar: AnsiChar;
begin
  RequireValid;
  if not TryAsChar(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsChar(ADefault: AnsiChar): AnsiChar;
begin
  if not TryAsChar(Result) then
    Result := ADefault;
end;

function TYamlNode.AsDouble: Double;
begin
  RequireValid;
  if not TryAsDouble(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsDouble(ADefault: Double): Double;
begin
  if not TryAsDouble(Result) then
    Result := ADefault;
end;

function TYamlNode.AsSingle: Single;
begin
  RequireValid;
  if not TryAsSingle(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsSingle(ADefault: Single): Single;
begin
  if not TryAsSingle(Result) then
    Result := ADefault;
end;

function TYamlNode.AsBoolean: Boolean;
begin
  RequireValid;
  if not TryAsBoolean(Result) then
    raise ConversionFailure;
end;

function TYamlNode.AsBoolean(ADefault: Boolean): Boolean;
begin
  if not TryAsBoolean(Result) then
    Result := ADefault;
end;

end.
