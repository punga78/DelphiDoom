{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the collision model                         }
{                                                                              }
{  Port of cm_model_t of CollisionModel_local.h and of the allocation and      }
{  bounds helpers of CollisionModel_load.cpp, Doom 3 GPL Source Code.          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Model;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Bounds, DelphiDoom.Collision.Model.Types,
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush, DelphiDoom.Collision.Model.Node;

type
  /// <summary>
  ///   A collision model: vertices, edges, polygons and brushes, plus the axial BSP tree
  ///   that arranges them. The model owns every node, polygon and brush it creates (the
  ///   block allocators of the C++ code are lists of owned objects), so freeing the model
  ///   frees everything.
  /// </summary>
  TCollisionModel = class
  private
    FNodes: TObjectList<TCmNode>;
    FPolygons: TObjectList<TCmPolygon>;
    FBrushes: TObjectList<TCmBrush>;
    FNextPolygonId: Integer;
    procedure CollectPolygons(ANode: TCmNode; AList: TList<TCmPolygon>; ASeen: TDictionary<TCmPolygon, Boolean>);
    procedure CollectBrushes(ANode: TCmNode; AList: TList<TCmBrush>; ASeen: TDictionary<TCmBrush, Boolean>);
    procedure AddNodeBounds(ANode: TCmNode; var ABounds: TGeoBounds);
    function NodeContents(ANode: TCmNode): Integer;
  public
    /// <summary>model name</summary>
    Name: string;
    /// <summary>model bounds</summary>
    Bounds: TGeoBounds;
    /// <summary>all contents of the model ored together</summary>
    Contents: Integer;
    /// <summary>set if model is convex</summary>
    IsConvex: Boolean;
    /// <summary>Array with all vertices; only the first NumVertices are used (the array is the capacity)</summary>
    Vertices: TArray<TCmVertex>;
    NumVertices: Integer;
    /// <summary>Array with all edges; edge 0 is a dummy; only the first NumEdges are used</summary>
    Edges: TArray<TCmEdge>;
    NumEdges: Integer;
    /// <summary>first node of the spatial subdivision</summary>
    Node: TCmNode;
    // statistics
    NumPolygons: Integer;
    NumBrushes: Integer;
    NumNodes: Integer;
    NumBrushRefs: Integer;
    NumPolygonRefs: Integer;
    NumInternalEdges: Integer;
    NumSharpEdges: Integer;
    NumRemovedPolys: Integer;
    NumMergedPolys: Integer;

    constructor Create;
    destructor Destroy; override;

    /// <summary>A new node owned by the model; it is a leaf until a plane is set</summary>
    function CreateNode(AParent: TCmNode): TCmNode;
    /// <summary>A new polygon owned by the model, with ANumEdges edge slots and a unique Id</summary>
    function CreatePolygon(ANumEdges: Integer): TCmPolygon;
    function CreateBrush(ANumPlanes: Integer): TCmBrush;
    /// <summary>Links the polygon at the head of the node chain (AddPolygonToNode)</summary>
    procedure AddPolygonToNode(ANode: TCmNode; APolygon: TCmPolygon);
    procedure AddBrushToNode(ANode: TCmNode; ABrush: TCmBrush);

    /// <summary>The polygon with that Id (the contact "modelFeature" of a polygon hit), or nil</summary>
    function PolygonById(AId: Integer): TCmPolygon;
    /// <summary>Every polygon once, in the order the C++ tree walks visit them</summary>
    function TreePolygons: TArray<TCmPolygon>;
    function TreeBrushes: TArray<TCmBrush>;
    /// <summary>Bounds from the bounds of brushes and polygons (CM_GetNodeBounds)</summary>
    procedure CalculateBounds;
    /// <summary>Contents of all brushes and polygons ored (CM_GetNodeContents)</summary>
    procedure CalculateContents;
    /// <summary>Sets the checkcount of every polygon, brush, vertex and edge to 0</summary>
    procedure ResetCheckCounts;
    /// <summary>Makes room for at least ACount vertices (the array grows by 1.5 plus 1 like the C++ code)</summary>
    procedure EnsureVertexCapacity(ACount: Integer);
    procedure EnsureEdgeCapacity(ACount: Integer);
  end;

implementation

{ TCollisionModel }

constructor TCollisionModel.Create;
begin
  inherited Create;
  FNodes := TObjectList<TCmNode>.Create(True);
  FPolygons := TObjectList<TCmPolygon>.Create(True);
  FBrushes := TObjectList<TCmBrush>.Create(True);
  Bounds.Clear;
end;

destructor TCollisionModel.Destroy;
begin
  FBrushes.Free;
  FPolygons.Free;
  FNodes.Free;
  inherited Destroy;
end;

function TCollisionModel.CreateNode(AParent: TCmNode): TCmNode;
begin
  Result := TCmNode.Create;
  Result.Parent := AParent;
  FNodes.Add(Result);
end;

function TCollisionModel.CreatePolygon(ANumEdges: Integer): TCmPolygon;
begin
  Result := TCmPolygon.Create;
  SetLength(Result.Edges, ANumEdges);
  Inc(FNextPolygonId);
  Result.Id := FNextPolygonId;
  FPolygons.Add(Result);
  Inc(NumPolygons);
end;

function TCollisionModel.CreateBrush(ANumPlanes: Integer): TCmBrush;
begin
  Result := TCmBrush.Create;
  SetLength(Result.Planes, ANumPlanes);
  FBrushes.Add(Result);
  Inc(NumBrushes);
end;

procedure TCollisionModel.AddPolygonToNode(ANode: TCmNode; APolygon: TCmPolygon);
begin
  ANode.Polygons.Insert(0, APolygon);
  Inc(NumPolygonRefs);
end;

procedure TCollisionModel.AddBrushToNode(ANode: TCmNode; ABrush: TCmBrush);
begin
  ANode.Brushes.Insert(0, ABrush);
  Inc(NumBrushRefs);
end;

procedure TCollisionModel.CollectPolygons(ANode: TCmNode; AList: TList<TCmPolygon>; ASeen: TDictionary<TCmPolygon, Boolean>);
var
  LPolygon: TCmPolygon;
begin
  for LPolygon in ANode.Polygons do
    if ASeen.TryAdd(LPolygon, True) then
      AList.Add(LPolygon);
  if not ANode.IsLeaf then
  begin
    CollectPolygons(ANode.Children[1], AList, ASeen);
    CollectPolygons(ANode.Children[0], AList, ASeen);
  end;
end;

procedure TCollisionModel.CollectBrushes(ANode: TCmNode; AList: TList<TCmBrush>; ASeen: TDictionary<TCmBrush, Boolean>);
var
  LBrush: TCmBrush;
begin
  for LBrush in ANode.Brushes do
    if ASeen.TryAdd(LBrush, True) then
      AList.Add(LBrush);
  if not ANode.IsLeaf then
  begin
    CollectBrushes(ANode.Children[1], AList, ASeen);
    CollectBrushes(ANode.Children[0], AList, ASeen);
  end;
end;

function TCollisionModel.PolygonById(AId: Integer): TCmPolygon;
var
  LPolygon: TCmPolygon;
begin
  for LPolygon in FPolygons do
    if LPolygon.Id = AId then
      Exit(LPolygon);
  Result := nil;
end;

function TCollisionModel.TreePolygons: TArray<TCmPolygon>;
var
  LList: TList<TCmPolygon>;
  LSeen: TDictionary<TCmPolygon, Boolean>;
begin
  LList := TList<TCmPolygon>.Create;
  LSeen := TDictionary<TCmPolygon, Boolean>.Create;
  try
    if Assigned(Node) then
      CollectPolygons(Node, LList, LSeen);
    Result := LList.ToArray;
  finally
    LSeen.Free;
    LList.Free;
  end;
end;

function TCollisionModel.TreeBrushes: TArray<TCmBrush>;
var
  LList: TList<TCmBrush>;
  LSeen: TDictionary<TCmBrush, Boolean>;
begin
  LList := TList<TCmBrush>.Create;
  LSeen := TDictionary<TCmBrush, Boolean>.Create;
  try
    if Assigned(Node) then
      CollectBrushes(Node, LList, LSeen);
    Result := LList.ToArray;
  finally
    LSeen.Free;
    LList.Free;
  end;
end;

procedure TCollisionModel.AddNodeBounds(ANode: TCmNode; var ABounds: TGeoBounds);
var
  LPolygon: TCmPolygon;
  LBrush: TCmBrush;
begin
  for LPolygon in ANode.Polygons do
  begin
    ABounds.AddPoint(LPolygon.Bounds.Mins);
    ABounds.AddPoint(LPolygon.Bounds.Maxs);
  end;
  for LBrush in ANode.Brushes do
  begin
    ABounds.AddPoint(LBrush.Bounds.Mins);
    ABounds.AddPoint(LBrush.Bounds.Maxs);
  end;
  if not ANode.IsLeaf then
  begin
    AddNodeBounds(ANode.Children[1], ABounds);
    AddNodeBounds(ANode.Children[0], ABounds);
  end;
end;

procedure TCollisionModel.CalculateBounds;
begin
  Bounds.Clear;
  if Assigned(Node) then
    AddNodeBounds(Node, Bounds);
  if Bounds.IsCleared then
    Bounds.Zero;
end;

function TCollisionModel.NodeContents(ANode: TCmNode): Integer;
var
  LPolygon: TCmPolygon;
  LBrush: TCmBrush;
begin
  Result := 0;
  for LPolygon in ANode.Polygons do
    Result := Result or LPolygon.Contents;
  for LBrush in ANode.Brushes do
    Result := Result or LBrush.Contents;
  if not ANode.IsLeaf then
  begin
    Result := Result or NodeContents(ANode.Children[1]);
    Result := Result or NodeContents(ANode.Children[0]);
  end;
end;

procedure TCollisionModel.CalculateContents;
begin
  if Assigned(Node) then
    Contents := NodeContents(Node)
  else
    Contents := 0;
end;

procedure TCollisionModel.ResetCheckCounts;
var
  LIndex: Integer;
  LPolygon: TCmPolygon;
  LBrush: TCmBrush;
begin
  for LPolygon in FPolygons do
    LPolygon.CheckCount := 0;
  for LBrush in FBrushes do
    LBrush.CheckCount := 0;
  for LIndex := 0 to NumVertices - 1 do
    Vertices[LIndex].CheckCount := 0;
  for LIndex := 0 to NumEdges - 1 do
    Edges[LIndex].CheckCount := 0;
end;

procedure TCollisionModel.EnsureVertexCapacity(ACount: Integer);
var
  LNewCapacity: Integer;
begin
  if ACount <= Length(Vertices) then
    Exit;
  LNewCapacity := Trunc(Length(Vertices) * 1.5 + 1);
  if LNewCapacity < ACount then
    LNewCapacity := ACount;
  SetLength(Vertices, LNewCapacity);
end;

procedure TCollisionModel.EnsureEdgeCapacity(ACount: Integer);
var
  LNewCapacity: Integer;
begin
  if ACount <= Length(Edges) then
    Exit;
  LNewCapacity := Trunc(Length(Edges) * 1.5 + 1);
  if LNewCapacity < ACount then
    LNewCapacity := ACount;
  SetLength(Edges, LNewCapacity);
end;

end.
