{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - internal edges                              }
{                                                                              }
{  Port of PointInsidePolygon, FindInternalEdgesOnPolygon,                     }
{  FindInternalPolygonEdges and FindInternalEdges (CollisionModel_load.cpp),   }
{  Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax  }
{  Media company. Based on the Doom 3 GPL Source Code (id Software). Doom 3    }
{  Source Code: GNU General Public License version 3 with additional terms.    }
{  This unit is a derived work (GPL v3).                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.InternalEdges;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Model.Node, DelphiDoom.Collision.Model.Polygon;

type
  /// <summary>
  ///   Marks the edges that no trace model can collide with: an edge between two polygons with the
  ///   same contents whose normals face each other and whose edge is shared the other way round, or
  ///   lies on the plane of the other polygon and inside it. Such an edge is only a seam
  /// </summary>
  TCollisionInternalEdges = class
  private
    FModel: TCollisionModel;
    FCounter: TCollisionCheckCounter;
    function PointInsidePolygon(APolygon: TCmPolygon; const APoint: TGeoVec3): Boolean;
    procedure FindInternalEdgesOnPolygon(AP1, AP2: TCmPolygon);
    procedure FindInternalPolygonEdges(ANode: TCmNode; APolygon: TCmPolygon);
  public
    /// <summary>Nothing is owned</summary>
    constructor Create(AModel: TCollisionModel; ACounter: TCollisionCheckCounter);
    /// <summary>FindInternalEdges: the whole subtree; call Counter.Next before</summary>
    procedure FindInternalEdges(ANode: TCmNode);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.FloatMath, DelphiDoom.Collision.Types, DelphiDoom.Collision.Model.Types;

{ TCollisionInternalEdges }

constructor TCollisionInternalEdges.Create(AModel: TCollisionModel; ACounter: TCollisionCheckCounter);
begin
  inherited Create;
  FModel := AModel;
  FCounter := ACounter;
end;

function TCollisionInternalEdges.PointInsidePolygon(APolygon: TCmPolygon; const APoint: TGeoVec3): Boolean;
var
  LIndex: Integer;
  LEdgeNum: Integer;
  LV1: TGeoVec3;
  LV2: TGeoVec3;
  LDir1: TGeoVec3;
  LDir2: TGeoVec3;
  LVec: TGeoVec3;
begin
  for LIndex := 0 to APolygon.NumEdges - 1 do
  begin
    LEdgeNum := APolygon.Edges[LIndex];
    LV1 := FModel.Vertices[FModel.Edges[Abs(LEdgeNum)].VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]].P;
    LV2 := FModel.Vertices[FModel.Edges[Abs(LEdgeNum)].VertexNum[TGeoMath.IntSignBitNotSet(LEdgeNum)]].P;
    LDir1 := LV2 - LV1;
    LVec := APoint - LV1;
    LDir2 := LDir1.Cross(APolygon.Plane.Normal);
    if LVec.Dot(LDir2) > VERTEX_EPSILON then
      Exit(False);
  end;
  Result := True;
end;

procedure TCollisionInternalEdges.FindInternalEdgesOnPolygon(AP1, AP2: TCmPolygon);
var
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LEdgeNum: Integer;
  LEdge: Integer;
  LD: Single;
  LV1: TGeoVec3;
  LV2: TGeoVec3;
  LDir1: TGeoVec3;
  LDir2: TGeoVec3;
begin
  // bounds of polygons should overlap or touch
  for LI := 0 to 2 do
  begin
    if AP1.Bounds.Mins[LI] > AP2.Bounds.Maxs[LI] then
      Exit;
    if AP1.Bounds.Maxs[LI] < AP2.Bounds.Mins[LI] then
      Exit;
  end;
  // FIXME: doubled geometry causes problems
  for LI := 0 to AP1.NumEdges - 1 do
  begin
    LEdgeNum := AP1.Edges[LI];
    LEdge := Abs(LEdgeNum);
    // if already an internal edge
    if FModel.Edges[LEdge].Internal <> 0 then
      Continue;
    LV1 := FModel.Vertices[FModel.Edges[LEdge].VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]].P;
    LV2 := FModel.Vertices[FModel.Edges[LEdge].VertexNum[TGeoMath.IntSignBitNotSet(LEdgeNum)]].P;
    // if either of the two vertices is outside the bounds of the other polygon
    LK := 0;
    while LK < 3 do
    begin
      LD := AP2.Bounds.Maxs[LK] + VERTEX_EPSILON;
      if (LV1[LK] > LD) or (LV2[LK] > LD) then
        Break;
      LD := AP2.Bounds.Mins[LK] - VERTEX_EPSILON;
      if (LV1[LK] < LD) or (LV2[LK] < LD) then
        Break;
      Inc(LK);
    end;
    if LK < 3 then
      Continue;

    LK := LEdge;
    LJ := 0;
    while LJ < AP2.NumEdges do
    begin
      if LK = Abs(AP2.Edges[LJ]) then
        Break;
      Inc(LJ);
    end;
    // if the edge is shared between the two polygons
    if LJ < AP2.NumEdges then
    begin
      // if the edge is used by more than 2 polygons
      if FModel.Edges[LEdge].NumUsers > 2 then
        // could still be internal but we'd have to test all polygons using the edge
        Continue;
      // if the edge goes in the same direction for both polygons
      if LEdgeNum = AP2.Edges[LJ] then
        // the polygons can lay ontop of each other or one can obscure the other
        Continue;
    end
    // the edge was not shared
    else
    begin
      // both vertices should be on the plane of the other polygon
      LD := AP2.Plane.Distance(LV1);
      if TGeoMath.Fabs(LD) > VERTEX_EPSILON then
        Continue;
      LD := AP2.Plane.Distance(LV2);
      if TGeoMath.Fabs(LD) > VERTEX_EPSILON then
        Continue;
    end;
    // the two polygon plane normals should face towards each other
    LDir1 := LV2 - LV1;
    LDir2 := AP1.Plane.Normal.Cross(LDir1);
    if AP2.Plane.Normal.Dot(LDir2) < 0 then
      // the original has a commented out "continue" here: it stops looking at the edges of this polygon
      Break;
    // if the edge was not shared
    if LJ >= AP2.NumEdges then
    begin
      // both vertices of the edge should be inside the winding of the other polygon
      if not PointInsidePolygon(AP2, LV1) then
        Continue;
      if not PointInsidePolygon(AP2, LV2) then
        Continue;
    end;
    // we got another internal edge
    FModel.Edges[LEdge].Internal := 1;
    Inc(FModel.NumInternalEdges);
  end;
end;

procedure TCollisionInternalEdges.FindInternalPolygonEdges(ANode: TCmNode; APolygon: TCmPolygon);
var
  LIndex: Integer;
  LPolygon: TCmPolygon;
begin
  if APolygon.Material.TwoSided then
    Exit;

  while True do
  begin
    for LIndex := 0 to ANode.Polygons.Count - 1 do
    begin
      LPolygon := ANode.Polygons[LIndex];
      // if the polygons don't have the same contents
      if LPolygon.Contents <> APolygon.Contents then
        Continue;
      if LPolygon = APolygon then
        Continue;
      FindInternalEdgesOnPolygon(APolygon, LPolygon);
    end;
    // if leaf node
    if ANode.PlaneType = -1 then
      Break;
    if APolygon.Bounds.Mins[ANode.PlaneType] > ANode.PlaneDist then
      ANode := ANode.Children[0]
    else if APolygon.Bounds.Maxs[ANode.PlaneType] < ANode.PlaneDist then
      ANode := ANode.Children[1]
    else
    begin
      FindInternalPolygonEdges(ANode.Children[1], APolygon);
      ANode := ANode.Children[0];
    end;
  end;
end;

procedure TCollisionInternalEdges.FindInternalEdges(ANode: TCmNode);
var
  LIndex: Integer;
  LPolygon: TCmPolygon;
begin
  while True do
  begin
    for LIndex := 0 to ANode.Polygons.Count - 1 do
    begin
      LPolygon := ANode.Polygons[LIndex];
      // if we checked this polygon already
      if LPolygon.CheckCount = FCounter.Value then
        Continue;
      LPolygon.CheckCount := FCounter.Value;
      FindInternalPolygonEdges(FModel.Node, LPolygon);
    end;
    // if leaf node
    if ANode.PlaneType = -1 then
      Break;
    FindInternalEdges(ANode.Children[1]);
    ANode := ANode.Children[0];
  end;
end;

end.
