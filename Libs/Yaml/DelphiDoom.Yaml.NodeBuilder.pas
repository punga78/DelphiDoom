{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - building a node tree from the parser events      }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.NodeBuilder;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf,
  DelphiDoom.Yaml.Detail,
  DelphiDoom.Yaml.Node;

type
  /// <summary>NodeBuilder: an event handler that builds the nodes of one document</summary>
  TYamlNodeBuilder = class(TInterfacedObject, IYamlEventHandler)
  strict private
    type
      TPushedKey = record
        Node: TYamlDetailNode;
        Seen: Boolean;
      end;
  strict private
    FMemory: IYamlMemoryHolder;
    FRoot: TYamlDetailNode;
    FStack: TList<TYamlDetailNode>;
    FAnchors: TList<TYamlDetailNode>;
    FKeys: TList<TPushedKey>;
    FMapDepth: Integer;
    function PushNew(const AMark: TYamlMark; AAnchor: TYamlAnchor): TYamlDetailNode;
    procedure PushNode(ANode: TYamlDetailNode);
    procedure Pop;
    procedure RegisterAnchor(AAnchor: TYamlAnchor; ANode: TYamlDetailNode);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>The root of the document (a null node that is not stored if there was none)</summary>
    function Root: IYamlNode;
    procedure OnDocumentStart(const AMark: TYamlMark);
    procedure OnDocumentEnd;
    procedure OnNull(const AMark: TYamlMark; AAnchor: TYamlAnchor);
    procedure OnAlias(const AMark: TYamlMark; AAnchor: TYamlAnchor);
    procedure OnScalar(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      const AValue: TYamlText);
    procedure OnSequenceStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      AStyle: TYamlEmitterStyle);
    procedure OnSequenceEnd;
    procedure OnMapStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
      AStyle: TYamlEmitterStyle);
    procedure OnMapEnd;
    procedure OnAnchor(const AMark: TYamlMark; const AAnchorName: TYamlText);
  end;

implementation

constructor TYamlNodeBuilder.Create;
begin
  inherited Create;
  FMemory := TYamlMemoryHolder.Create;
  FStack := TList<TYamlDetailNode>.Create;
  FAnchors := TList<TYamlDetailNode>.Create;
  FKeys := TList<TPushedKey>.Create;
  FAnchors.Add(nil); // since the anchors start at 1
end;

destructor TYamlNodeBuilder.Destroy;
begin
  FKeys.Free;
  FAnchors.Free;
  FStack.Free;
  inherited Destroy;
end;

function TYamlNodeBuilder.Root: IYamlNode;
begin
  if not Assigned(FRoot) then
    Exit(TYamlNode.Create);
  Result := TYamlNode.CreateHandle(FRoot, FMemory);
end;

procedure TYamlNodeBuilder.OnDocumentStart(const AMark: TYamlMark);
begin
end;

procedure TYamlNodeBuilder.OnDocumentEnd;
begin
end;

procedure TYamlNodeBuilder.OnAnchor(const AMark: TYamlMark; const AAnchorName: TYamlText);
begin
end;

procedure TYamlNodeBuilder.OnNull(const AMark: TYamlMark; AAnchor: TYamlAnchor);
var
  LNode: TYamlDetailNode;
begin
  LNode := PushNew(AMark, AAnchor);
  LNode.SetNull;
  Pop;
end;

procedure TYamlNodeBuilder.OnAlias(const AMark: TYamlMark; AAnchor: TYamlAnchor);
begin
  PushNode(FAnchors[AAnchor]);
  Pop;
end;

procedure TYamlNodeBuilder.OnScalar(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
  const AValue: TYamlText);
var
  LNode: TYamlDetailNode;
begin
  LNode := PushNew(AMark, AAnchor);
  LNode.SetScalar(AValue);
  LNode.SetTag(ATag);
  Pop;
end;

procedure TYamlNodeBuilder.OnSequenceStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
  AStyle: TYamlEmitterStyle);
var
  LNode: TYamlDetailNode;
begin
  LNode := PushNew(AMark, AAnchor);
  LNode.SetTag(ATag);
  LNode.SetType(ntSequence);
  LNode.SetStyle(AStyle);
end;

procedure TYamlNodeBuilder.OnSequenceEnd;
begin
  Pop;
end;

procedure TYamlNodeBuilder.OnMapStart(const AMark: TYamlMark; const ATag: TYamlText; AAnchor: TYamlAnchor;
  AStyle: TYamlEmitterStyle);
var
  LNode: TYamlDetailNode;
begin
  LNode := PushNew(AMark, AAnchor);
  LNode.SetType(ntMap);
  LNode.SetTag(ATag);
  LNode.SetStyle(AStyle);
  Inc(FMapDepth);
end;

procedure TYamlNodeBuilder.OnMapEnd;
begin
  Dec(FMapDepth);
  Pop;
end;

function TYamlNodeBuilder.PushNew(const AMark: TYamlMark; AAnchor: TYamlAnchor): TYamlDetailNode;
begin
  Result := FMemory.CreateNode;
  Result.SetMark(AMark);
  RegisterAnchor(AAnchor, Result);
  PushNode(Result);
end;

procedure TYamlNodeBuilder.PushNode(ANode: TYamlDetailNode);
var
  LNeedsKey: Boolean;
  LKey: TPushedKey;
begin
  LNeedsKey := (FStack.Count > 0) and (FStack[FStack.Count - 1].NodeType = ntMap) and (FKeys.Count < FMapDepth);
  FStack.Add(ANode);
  if LNeedsKey then
  begin
    LKey.Node := ANode;
    LKey.Seen := False;
    FKeys.Add(LKey);
  end;
end;

procedure TYamlNodeBuilder.Pop;
var
  LNode, LCollection: TYamlDetailNode;
  LKey: TPushedKey;
begin
  if FStack.Count = 1 then
  begin
    FRoot := FStack[0];
    FStack.Delete(0);
    Exit;
  end;
  LNode := FStack[FStack.Count - 1];
  FStack.Delete(FStack.Count - 1);
  LCollection := FStack[FStack.Count - 1];
  if LCollection.NodeType = ntSequence then
    LCollection.PushBack(LNode)
  else if LCollection.NodeType = ntMap then
  begin
    LKey := FKeys[FKeys.Count - 1];
    if LKey.Seen then
    begin
      LCollection.Insert(LKey.Node, LNode, FMemory);
      FKeys.Delete(FKeys.Count - 1);
    end
    else
    begin
      LKey.Seen := True;
      FKeys[FKeys.Count - 1] := LKey;
    end;
  end
  else
    FStack.Clear;
end;

procedure TYamlNodeBuilder.RegisterAnchor(AAnchor: TYamlAnchor; ANode: TYamlDetailNode);
begin
  if AAnchor <> 0 then
    FAnchors.Add(ANode);
end;

end.
