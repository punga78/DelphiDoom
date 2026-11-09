{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - a node tree as events (for emitting and cloning) }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.NodeEvents;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Detail,
  DelphiDoom.Yaml.Node;

type
  /// <summary>
  ///   NodeEvents: walks a node tree and gives the events of it; a node that is reached more than once (the same
  ///   node_ref) gets an anchor the first time and an alias after that, so a tree with cycles is finite
  /// </summary>
  TYamlNodeEvents = class
  strict private
    FMemory: IYamlMemoryHolder;
    FRoot: TYamlDetailNode;
    FRefCount: TDictionary<TYamlNodeRef, Integer>;
    FAnchorByIdentity: TDictionary<TYamlNodeRef, TYamlAnchor>;
    FCurAnchor: TYamlAnchor;
    procedure Setup(ANode: TYamlDetailNode);
    procedure EmitNode(ANode: TYamlDetailNode; const AHandler: IYamlEventHandler);
    function IsAliased(ANode: TYamlDetailNode): Boolean;
  public
    constructor Create(const ANode: IYamlNode);
    destructor Destroy; override;
    procedure Emit(const AHandler: IYamlEventHandler);
  end;

implementation

constructor TYamlNodeEvents.Create(const ANode: IYamlNode);
var
  LHandle: TYamlNode;
begin
  inherited Create;
  FRefCount := TDictionary<TYamlNodeRef, Integer>.Create;
  FAnchorByIdentity := TDictionary<TYamlNodeRef, TYamlAnchor>.Create;
  LHandle := ANode as TYamlNode;
  FMemory := LHandle.MemoryHolder;
  FRoot := LHandle.DetailNode;
  if Assigned(FRoot) then
    Setup(FRoot);
end;

destructor TYamlNodeEvents.Destroy;
begin
  FAnchorByIdentity.Free;
  FRefCount.Free;
  inherited Destroy;
end;

procedure TYamlNodeEvents.Setup(ANode: TYamlDetailNode);
var
  LCount, I: Integer;
  LPair: TYamlNodePair;
begin
  if not FRefCount.TryGetValue(ANode.Ref, LCount) then
    LCount := 0;
  Inc(LCount);
  FRefCount.AddOrSetValue(ANode.Ref, LCount);
  if LCount > 1 then
    Exit;
  if ANode.NodeType = ntSequence then
  begin
    for I := 0 to ANode.SequenceCount - 1 do
      Setup(ANode.SequenceAt(I));
  end
  else if ANode.NodeType = ntMap then
  begin
    for I := 0 to ANode.MapCount - 1 do
    begin
      LPair := ANode.MapPairAt(I);
      if LPair.Key.IsDefined and LPair.Value.IsDefined then
      begin
        Setup(LPair.Key);
        Setup(LPair.Value);
      end;
    end;
  end;
end;

function TYamlNodeEvents.IsAliased(ANode: TYamlDetailNode): Boolean;
var
  LCount: Integer;
begin
  Result := FRefCount.TryGetValue(ANode.Ref, LCount) and (LCount > 1);
end;

procedure TYamlNodeEvents.Emit(const AHandler: IYamlEventHandler);
begin
  FAnchorByIdentity.Clear;
  FCurAnchor := 0;
  AHandler.OnDocumentStart(TYamlMark.Zero);
  if Assigned(FRoot) then
    EmitNode(FRoot, AHandler);
  AHandler.OnDocumentEnd;
end;

procedure TYamlNodeEvents.EmitNode(ANode: TYamlDetailNode; const AHandler: IYamlEventHandler);
var
  LAnchor: TYamlAnchor;
  I: Integer;
  LPair: TYamlNodePair;
begin
  LAnchor := YAML_NULL_ANCHOR;
  if IsAliased(ANode) then
  begin
    if FAnchorByIdentity.TryGetValue(ANode.Ref, LAnchor) then
    begin
      AHandler.OnAlias(TYamlMark.Zero, LAnchor);
      Exit;
    end;
    Inc(FCurAnchor);
    FAnchorByIdentity.Add(ANode.Ref, FCurAnchor);
    LAnchor := FCurAnchor;
  end;
  case ANode.NodeType of
    ntUndefined: ;
    ntNull:
      AHandler.OnNull(TYamlMark.Zero, LAnchor);
    ntScalar:
      AHandler.OnScalar(TYamlMark.Zero, ANode.Tag, LAnchor, ANode.Scalar);
    ntSequence:
      begin
        AHandler.OnSequenceStart(TYamlMark.Zero, ANode.Tag, LAnchor, ANode.Style);
        for I := 0 to ANode.SequenceCount - 1 do
          EmitNode(ANode.SequenceAt(I), AHandler);
        AHandler.OnSequenceEnd;
      end;
    ntMap:
      begin
        AHandler.OnMapStart(TYamlMark.Zero, ANode.Tag, LAnchor, ANode.Style);
        for I := 0 to ANode.MapCount - 1 do
        begin
          LPair := ANode.MapPairAt(I);
          if LPair.Key.IsDefined and LPair.Value.IsDefined then
          begin
            EmitNode(LPair.Key, AHandler);
            EmitNode(LPair.Value, AHandler);
          end;
        end;
        AHandler.OnMapEnd;
      end;
  end;
end;

end.
