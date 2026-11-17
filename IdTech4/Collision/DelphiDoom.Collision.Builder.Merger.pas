{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - merging of coplanar polygons                }
{                                                                              }
{  Port of ReplacePolygons, TryMergePolygons, MergePolygonWithTreePolygons     }
{  and MergeTreePolygons (CollisionModel_load.cpp), Doom 3 GPL Source Code.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software). This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3 or (at your option) any later version, with the   }
{  additional terms of the Doom 3 Source Code License                          }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.Merger;

interface

uses
  DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Model, DelphiDoom.Collision.Model.Node,
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Builder.Table;

type
  /// <summary>
  ///   Merges two polygons of the tree that lie on the same plane, have the same material
  ///   and share an edge into one convex polygon (the spurious hits of a trace model with an
  ///   edge inside a flat floor made of triangles are avoided this way)
  /// </summary>
  TCollisionPolygonMerger = class
  private
    FModel: TCollisionModel;
    FTable: TCollisionGeometryTable;
    FCounter: TCollisionCheckCounter;
    procedure ReplacePolygons(ANode: TCmNode; AP1, AP2, ANewPolygon: TCmPolygon);
    function TryMergePolygons(AP1, AP2: TCmPolygon): TCmPolygon;
    function MergePolygonWithTreePolygons(ANode: TCmNode; APolygon: TCmPolygon): Boolean;
  public
    /// <summary>Nothing is owned; the counter is the one of the build (checkCount)</summary>
    constructor Create(AModel: TCollisionModel; ATable: TCollisionGeometryTable; ACounter: TCollisionCheckCounter);
    /// <summary>Tries to merge any two polygons of the subtree (MergeTreePolygons); call Counter.Next before</summary>
    procedure MergeTreePolygons(ANode: TCmNode);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.FloatMath, DelphiDoom.Collision.Types,
  DelphiDoom.Collision.Model.Types;

const
  CONTINUOUS_EPSILON: Single = 0.005;
  NORMAL_EPSILON: Single = 0.01;

{ TCollisionPolygonMerger }

constructor TCollisionPolygonMerger.Create(AModel: TCollisionModel; ATable: TCollisionGeometryTable;
  ACounter: TCollisionCheckCounter);
begin
  inherited Create;
  FModel := AModel;
  FTable := ATable;
  FCounter := ACounter;
end;

procedure TCollisionPolygonMerger.ReplacePolygons(ANode: TCmNode; AP1, AP2, ANewPolygon: TCmPolygon);
var
  LIndex: Integer;
  LLinked: Boolean;
  LPolygon: TCmPolygon;
begin
  // does not allow for a node to have multiple references to the same polygon
  while True do
  begin
    LLinked := False;
    LIndex := 0;
    while LIndex < ANode.Polygons.Count do
    begin
      LPolygon := ANode.Polygons[LIndex];
      // if this polygon reference should change
      if (LPolygon = AP1) or (LPolygon = AP2) then
      begin
        // if the new polygon is already linked at this node
        if LLinked then
        begin
          ANode.Polygons.Delete(LIndex);
          Dec(FModel.NumPolygonRefs);
        end
        else
        begin
          ANode.Polygons[LIndex] := ANewPolygon;
          LLinked := True;
          Inc(LIndex);
        end;
      end
      else
        Inc(LIndex);
    end;
    // if leaf node
    if ANode.PlaneType = -1 then
      Break;
    if (AP1.Bounds.Mins[ANode.PlaneType] > ANode.PlaneDist) and (AP2.Bounds.Mins[ANode.PlaneType] > ANode.PlaneDist) then
      ANode := ANode.Children[0]
    else if (AP1.Bounds.Maxs[ANode.PlaneType] < ANode.PlaneDist) and
      (AP2.Bounds.Maxs[ANode.PlaneType] < ANode.PlaneDist) then
      ANode := ANode.Children[1]
    else
    begin
      ReplacePolygons(ANode.Children[1], AP1, AP2, ANewPolygon);
      ANode := ANode.Children[0];
    end;
  end;
end;

function TCollisionPolygonMerger.TryMergePolygons(AP1, AP2: TCmPolygon): TCmPolygon;
var
  LI: Integer;
  LJ: Integer;
  LNextI: Integer;
  LPrevJ: Integer;
  LP1BeforeShare: Integer;
  LP1AfterShare: Integer;
  LP2BeforeShare: Integer;
  LP2AfterShare: Integer;
  LNewEdges: array[0..CM_MAX_POLYGON_EDGES - 1] of Integer;
  LNewNumEdges: Integer;
  LEdgeNum: Integer;
  LEdgeNum1: Integer;
  LEdgeNum2: Integer;
  LNewEdgeNum1: Integer;
  LNewEdgeNum2: Integer;
  LDelta: TGeoVec3;
  LNormal: TGeoVec3;
  LNormal1: TGeoVec3;
  LNormal2: TGeoVec3;
  LDot: Single;
  LKeep1: Boolean;
  LKeep2: Boolean;
  LNotKeep1: Integer;
  LNotKeep2: Integer;
  LNew: TCmPolygon;

  function VertexAt(AEdgeNum: Integer; AEnd: Boolean): TGeoVec3;
  var
    LSlot: Integer;
  begin
    if AEnd then
      LSlot := TGeoMath.IntSignBitNotSet(AEdgeNum)
    else
      LSlot := TGeoMath.IntSignBitSet(AEdgeNum);
    Result := FModel.Vertices[FModel.Edges[Abs(AEdgeNum)].VertexNum[LSlot]].P;
  end;

  function Direction(AEdgeNum: Integer): TGeoVec3;
  begin
    Result := VertexAt(AEdgeNum, True) - VertexAt(AEdgeNum, False);
  end;

begin
  Result := nil;
  if AP1.Material <> AP2.Material then
    Exit;
  if TGeoMath.Fabs(AP1.Plane.Dist - AP2.Plane.Dist) > NORMAL_EPSILON then
    Exit;
  LNormal1 := AP1.Plane.Normal;
  LNormal2 := AP2.Plane.Normal;
  for LI := 0 to 2 do
  begin
    if TGeoMath.Fabs(LNormal1[LI] - LNormal2[LI]) > NORMAL_EPSILON then
      Exit;
    if AP1.Bounds.Mins[LI] > AP2.Bounds.Maxs[LI] then
      Exit;
    if AP1.Bounds.Maxs[LI] < AP2.Bounds.Mins[LI] then
      Exit;
  end;
  // this allows for merging polygons with multiple shared edges
  // polygons with multiple shared edges probably never occur tho ;)
  LP1BeforeShare := -1;
  LP1AfterShare := -1;
  LP2BeforeShare := -1;
  LP2AfterShare := -1;
  for LI := 0 to AP1.NumEdges - 1 do
  begin
    LNextI := (LI + 1) mod AP1.NumEdges;
    for LJ := 0 to AP2.NumEdges - 1 do
    begin
      LPrevJ := (LJ + AP2.NumEdges - 1) mod AP2.NumEdges;
      if Abs(AP1.Edges[LI]) <> Abs(AP2.Edges[LJ]) then
      begin
        // if the next edge of p1 and the previous edge of p2 are the same
        if Abs(AP1.Edges[LNextI]) = Abs(AP2.Edges[LPrevJ]) then
        begin
          // if both polygons don't use the edge in the same direction
          if AP1.Edges[LNextI] <> AP2.Edges[LPrevJ] then
          begin
            LP1BeforeShare := LI;
            LP2AfterShare := LJ;
          end;
          Break;
        end;
      end
      // if both polygons don't use the edge in the same direction
      else if AP1.Edges[LI] <> AP2.Edges[LJ] then
      begin
        // if the next edge of p1 and the previous edge of p2 are not the same
        if Abs(AP1.Edges[LNextI]) <> Abs(AP2.Edges[LPrevJ]) then
        begin
          LP1AfterShare := LNextI;
          LP2BeforeShare := LPrevJ;
          Break;
        end;
      end;
    end;
  end;
  if (LP1BeforeShare < 0) or (LP1AfterShare < 0) or (LP2BeforeShare < 0) or (LP2AfterShare < 0) then
    Exit;

  // check if the new polygon would still be convex
  LEdgeNum := AP1.Edges[LP1BeforeShare];
  LDelta := Direction(LEdgeNum);
  LNormal := AP1.Plane.Normal.Cross(LDelta);
  LNormal.NormalizeSelf;

  LEdgeNum := AP2.Edges[LP2AfterShare];
  LDelta := Direction(LEdgeNum);

  LDot := LDelta.Dot(LNormal);
  if LDot < -CONTINUOUS_EPSILON then
    Exit; // not a convex polygon
  LKeep1 := LDot > CONTINUOUS_EPSILON;

  LEdgeNum := AP2.Edges[LP2BeforeShare];
  LDelta := Direction(LEdgeNum);
  LNormal := AP1.Plane.Normal.Cross(LDelta);
  LNormal.NormalizeSelf;

  LEdgeNum := AP1.Edges[LP1AfterShare];
  LDelta := Direction(LEdgeNum);

  LDot := LDelta.Dot(LNormal);
  if LDot < -CONTINUOUS_EPSILON then
    Exit; // not a convex polygon
  LKeep2 := LDot > CONTINUOUS_EPSILON;

  LNewEdgeNum1 := 0;
  LNewEdgeNum2 := 0;
  // get new edges if we need to replace colinear ones
  if not LKeep1 then
  begin
    LEdgeNum1 := AP1.Edges[LP1BeforeShare];
    LEdgeNum2 := AP2.Edges[LP2AfterShare];
    FTable.GetEdge(VertexAt(LEdgeNum1, False), VertexAt(LEdgeNum2, True), LNewEdgeNum1, -1);
    if LNewEdgeNum1 = 0 then
      LKeep1 := True;
  end;
  if not LKeep2 then
  begin
    LEdgeNum1 := AP2.Edges[LP2BeforeShare];
    LEdgeNum2 := AP1.Edges[LP1AfterShare];
    FTable.GetEdge(VertexAt(LEdgeNum1, False), VertexAt(LEdgeNum2, True), LNewEdgeNum2, -1);
    if LNewEdgeNum2 = 0 then
      LKeep2 := True;
  end;
  LNotKeep1 := Ord(not LKeep1);
  LNotKeep2 := Ord(not LKeep2);
  // set edges for new polygon
  LNewNumEdges := 0;
  if not LKeep2 then
  begin
    LNewEdges[LNewNumEdges] := LNewEdgeNum2;
    Inc(LNewNumEdges);
  end;
  if LP1AfterShare < LP1BeforeShare then
  begin
    for LI := LP1AfterShare + LNotKeep2 to LP1BeforeShare - LNotKeep1 do
    begin
      LNewEdges[LNewNumEdges] := AP1.Edges[LI];
      Inc(LNewNumEdges);
    end;
  end
  else
  begin
    for LI := LP1AfterShare + LNotKeep2 to AP1.NumEdges - 1 do
    begin
      LNewEdges[LNewNumEdges] := AP1.Edges[LI];
      Inc(LNewNumEdges);
    end;
    for LI := 0 to LP1BeforeShare - LNotKeep1 do
    begin
      LNewEdges[LNewNumEdges] := AP1.Edges[LI];
      Inc(LNewNumEdges);
    end;
  end;
  if not LKeep1 then
  begin
    LNewEdges[LNewNumEdges] := LNewEdgeNum1;
    Inc(LNewNumEdges);
  end;
  if LP2AfterShare < LP2BeforeShare then
  begin
    for LI := LP2AfterShare + LNotKeep1 to LP2BeforeShare - LNotKeep2 do
    begin
      LNewEdges[LNewNumEdges] := AP2.Edges[LI];
      Inc(LNewNumEdges);
    end;
  end
  else
  begin
    for LI := LP2AfterShare + LNotKeep1 to AP2.NumEdges - 1 do
    begin
      LNewEdges[LNewNumEdges] := AP2.Edges[LI];
      Inc(LNewNumEdges);
    end;
    for LI := 0 to LP2BeforeShare - LNotKeep2 do
    begin
      LNewEdges[LNewNumEdges] := AP2.Edges[LI];
      Inc(LNewNumEdges);
    end;
  end;

  LNew := FModel.CreatePolygon(LNewNumEdges);
  LNew.Bounds := AP1.Bounds;
  LNew.Contents := AP1.Contents;
  LNew.Material := AP1.Material;
  LNew.Plane := AP1.Plane;
  for LI := 0 to LNewNumEdges - 1 do
    LNew.Edges[LI] := LNewEdges[LI];
  LNew.CheckCount := 0;
  // increase usage count for the edges of this polygon
  for LI := 0 to LNew.NumEdges - 1 do
  begin
    if (not LKeep1) and (LNew.Edges[LI] = LNewEdgeNum1) then
      Continue;
    if (not LKeep2) and (LNew.Edges[LI] = LNewEdgeNum2) then
      Continue;
    Inc(FModel.Edges[Abs(LNew.Edges[LI])].NumUsers);
  end;
  // create new bounds from the merged polygons
  LNew.Bounds.AddBounds(AP2.Bounds);
  Result := LNew;
end;

function TCollisionPolygonMerger.MergePolygonWithTreePolygons(ANode: TCmNode; APolygon: TCmPolygon): Boolean;
var
  LIndex: Integer;
  LEdge: Integer;
  LPolygon: TCmPolygon;
  LNew: TCmPolygon;
begin
  while True do
  begin
    for LIndex := 0 to ANode.Polygons.Count - 1 do
    begin
      LPolygon := ANode.Polygons[LIndex];
      if LPolygon = APolygon then
        Continue;
      LNew := TryMergePolygons(APolygon, LPolygon);
      // if polygons were merged
      if Assigned(LNew) then
      begin
        Inc(FModel.NumMergedPolys);
        // replace links to the merged polygons with links to the new polygon
        ReplacePolygons(FModel.Node, APolygon, LPolygon, LNew);
        // decrease usage count for edges of both merged polygons
        for LEdge := 0 to APolygon.NumEdges - 1 do
          Dec(FModel.Edges[Abs(APolygon.Edges[LEdge])].NumUsers);
        for LEdge := 0 to LPolygon.NumEdges - 1 do
          Dec(FModel.Edges[Abs(LPolygon.Edges[LEdge])].NumUsers);
        // free merged polygons
        FModel.ReleasePolygon(APolygon);
        FModel.ReleasePolygon(LPolygon);
        Exit(True);
      end;
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
      if MergePolygonWithTreePolygons(ANode.Children[1], APolygon) then
        Exit(True);
      ANode := ANode.Children[0];
    end;
  end;
  Result := False;
end;

procedure TCollisionPolygonMerger.MergeTreePolygons(ANode: TCmNode);
var
  LIndex: Integer;
  LMerge: Boolean;
  LPolygon: TCmPolygon;
begin
  while True do
  begin
    repeat
      LMerge := False;
      for LIndex := 0 to ANode.Polygons.Count - 1 do
      begin
        LPolygon := ANode.Polygons[LIndex];
        // if we checked this polygon already
        if LPolygon.CheckCount = FCounter.Value then
          Continue;
        LPolygon.CheckCount := FCounter.Value;
        // try to merge this polygon with other polygons in the tree
        if MergePolygonWithTreePolygons(FModel.Node, LPolygon) then
        begin
          LMerge := True;
          Break;
        end;
      end;
    until not LMerge;
    // if leaf node
    if ANode.PlaneType = -1 then
      Break;
    MergeTreePolygons(ANode.Children[1]);
    ANode := ANode.Children[0];
  end;
end;

end.
