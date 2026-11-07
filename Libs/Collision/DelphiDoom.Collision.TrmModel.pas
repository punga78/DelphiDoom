{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - a trace model as a collision model          }
{                                                                              }
{  Port of SetupTrmModelStructure and SetupTrmModel of CollisionModel_load.    }
{  cpp, Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a     }
{  ZeniMax Media company. Doom 3 Source Code: GNU General Public License       }
{  version 3 with additional terms. This unit is a derived work (GPL v3).      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.TrmModel;

interface

uses
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Collision.Types, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush;

type
  /// <summary>
  ///   The reusable collision model that stands for a trace model when it collides with
  ///   another trace model: the C++ manager keeps it in the last model slot (TRACE_MODEL_HANDLE).
  ///   It is rebuilt by every Setup, so it is valid until the next call
  /// </summary>
  TCollisionTrmModelSlot = class
  private
    FModel: TCollisionModel;
    FDefaultMaterial: TCollisionMaterial;
    FPolygons: array[0..MAX_TRACEMODEL_POLYS - 1] of TCmPolygon;
    FBrush: TCmBrush;
  public
    /// <summary>ADefaultMaterial is the "_tracemodel" material; it is not owned</summary>
    constructor Create(ADefaultMaterial: TCollisionMaterial);
    destructor Destroy; override;
    /// <summary>The model, owned by the slot</summary>
    property Model: TCollisionModel read FModel;
    /// <summary>Fills the model with the trace model (SetupTrmModel); AMaterial may be nil</summary>
    procedure Setup(ATrm: TTraceModel; AMaterial: TCollisionMaterial);
  end;

implementation

{ TCollisionTrmModelSlot }

constructor TCollisionTrmModelSlot.Create(ADefaultMaterial: TCollisionMaterial);
var
  LIndex: Integer;
begin
  inherited Create;
  FDefaultMaterial := ADefaultMaterial;
  // setup model
  FModel := TCollisionModel.Create;
  // create node to hold the collision data
  FModel.Node := FModel.CreateNode(nil);
  FModel.Node.PlaneType := -1;
  // allocate vertex and edge arrays
  FModel.NumVertices := 0;
  SetLength(FModel.Vertices, MAX_TRACEMODEL_VERTS);
  FModel.NumEdges := 0;
  SetLength(FModel.Edges, MAX_TRACEMODEL_EDGES + 1);
  // allocate polygons
  for LIndex := 0 to MAX_TRACEMODEL_POLYS - 1 do
  begin
    FPolygons[LIndex] := FModel.CreatePolygon(0);
    FPolygons[LIndex].Bounds.Clear;
    FPolygons[LIndex].Plane.Zero;
    FPolygons[LIndex].CheckCount := 0;
    FPolygons[LIndex].Contents := -1; // all contents
    FPolygons[LIndex].Material := FDefaultMaterial;
  end;
  // allocate brush for position test
  FBrush := FModel.CreateBrush(0);
  FBrush.PrimitiveNum := 0;
  FBrush.Bounds.Clear;
  FBrush.CheckCount := 0;
  FBrush.Contents := -1; // all contents
end;

destructor TCollisionTrmModelSlot.Destroy;
begin
  FModel.Free;
  inherited Destroy;
end;

procedure TCollisionTrmModelSlot.Setup(ATrm: TTraceModel; AMaterial: TCollisionMaterial);
var
  LIndex: Integer;
  LEdge: Integer;
begin
  if not Assigned(AMaterial) then
    AMaterial := FDefaultMaterial;

  FModel.Node.Brushes.Clear;
  FModel.Node.Polygons.Clear;
  // if not a valid trace model
  if (ATrm.Kind = tmkInvalid) or (ATrm.NumPolys = 0) then
    Exit;
  // vertices
  FModel.NumVertices := ATrm.NumVerts;
  for LIndex := 0 to ATrm.NumVerts - 1 do
  begin
    FModel.Vertices[LIndex].P := ATrm.Verts[LIndex];
    FModel.Vertices[LIndex].SideSet := 0;
  end;
  // edges
  FModel.NumEdges := ATrm.NumEdges;
  for LIndex := 1 to ATrm.NumEdges do
  begin
    FModel.Edges[LIndex].VertexNum[0] := ATrm.Edges[LIndex].V[0];
    FModel.Edges[LIndex].VertexNum[1] := ATrm.Edges[LIndex].V[1];
    FModel.Edges[LIndex].Normal := ATrm.Edges[LIndex].Normal;
    FModel.Edges[LIndex].Internal := 0;
    FModel.Edges[LIndex].SideSet := 0;
  end;
  // polygons
  FModel.NumPolygons := ATrm.NumPolys;
  for LIndex := 0 to ATrm.NumPolys - 1 do
  begin
    SetLength(FPolygons[LIndex].Edges, ATrm.Polys[LIndex].NumEdges);
    for LEdge := 0 to ATrm.Polys[LIndex].NumEdges - 1 do
      FPolygons[LIndex].Edges[LEdge] := ATrm.Polys[LIndex].Edges[LEdge];
    FPolygons[LIndex].Plane.SetNormal(ATrm.Polys[LIndex].Normal);
    FPolygons[LIndex].Plane.SetDist(ATrm.Polys[LIndex].Dist);
    FPolygons[LIndex].Bounds := ATrm.Polys[LIndex].Bounds;
    FPolygons[LIndex].Material := AMaterial;
    // link polygon at node
    FModel.Node.Polygons.Insert(0, FPolygons[LIndex]);
  end;
  // if the trace model is convex
  if ATrm.IsConvex then
  begin
    // setup brush for position test
    SetLength(FBrush.Planes, ATrm.NumPolys);
    for LIndex := 0 to ATrm.NumPolys - 1 do
      FBrush.Planes[LIndex] := FPolygons[LIndex].Plane;
    FBrush.Bounds := ATrm.Bounds;
    // link brush at node
    FModel.Node.Brushes.Insert(0, FBrush);
  end;
  // model bounds
  FModel.Bounds := ATrm.Bounds;
  // convex
  FModel.IsConvex := ATrm.IsConvex;
end;

end.
