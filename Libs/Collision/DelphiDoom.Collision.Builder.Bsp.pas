{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the axial BSP tree of a model               }
{                                                                              }
{  Port of CM_FindSplitter, CM_R_InsideAllChildren, R_FilterPolygonIntoTree,   }
{  R_FilterBrushIntoTree, R_CreateAxialBSPTree and CreateAxialBSPTree of       }
{  CollisionModel_load.cpp, Doom 3 GPL Source Code.                            }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.Bsp;

interface

uses
  DelphiDoom.Geometry.Bounds, DelphiDoom.Collision.Model, DelphiDoom.Collision.Model.Node,
  DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush;

type
  /// <summary>
  ///   Arranges the polygons and brushes of a model in a spatial subdivision made of axial
  ///   planes: a brush or polygon is linked in the node closest to the root where it is
  ///   inside all the children. Works on the model it is given and does not own it
  /// </summary>
  TCollisionBspBuilder = class
  private
    FModel: TCollisionModel;
    function FindSplitter(ANode: TCmNode; const ABounds: TGeoBounds; var APlaneType: Integer;
      var APlaneDist: Single): Boolean;
    function InsideAllChildren(ANode: TCmNode; const ABounds: TGeoBounds): Boolean;
    function CreateTree(ANode: TCmNode; const ABounds: TGeoBounds): TCmNode;
  public
    constructor Create(AModel: TCollisionModel);
    /// <summary>
    ///   Links the polygon in the tree below ANode (R_FilterPolygonIntoTree). AMoved is true
    ///   when the polygon is only being moved down from a node that already holds it
    ///   (a pointer to an existing reference in the C++ code): then the reference counter
    ///   of the model does not grow
    /// </summary>
    procedure FilterPolygonIntoTree(ANode: TCmNode; APolygon: TCmPolygon; AMoved: Boolean = False);
    procedure FilterBrushIntoTree(ANode: TCmNode; ABrush: TCmBrush; AMoved: Boolean = False);
    /// <summary>Splits the head node of the model until the leaves are small (CreateAxialBSPTree)</summary>
    function CreateAxialBSPTree(ANode: TCmNode): TCmNode;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Geometry.FloatMath, DelphiDoom.Collision.Types;

{ TCollisionBspBuilder }

constructor TCollisionBspBuilder.Create(AModel: TCollisionModel);
begin
  inherited Create;
  FModel := AModel;
end;

function TCollisionBspBuilder.FindSplitter(ANode: TCmNode; const ABounds: TGeoBounds;
  var APlaneType: Integer; var APlaneDist: Single): Boolean;
var
  LIndex: Integer;
  LAxisIndex: Integer;
  LSide: Integer;
  LAxis: array[0..2] of Integer;
  LSize: array[0..2] of Single;
  LType: Integer;
  LDist: Single;
  LT: Single;
  LBestT: Single;
  LSwap: Single;
  LSwapAxis: Integer;
  LForceSplit: Boolean;
  LNode: TCmNode;
  LBrush: TCmBrush;
  LPolygon: TCmPolygon;
begin
  LForceSplit := False;
  for LIndex := 0 to 2 do
  begin
    LSize[LIndex] := ABounds.Maxs[LIndex] - ABounds.Mins[LIndex];
    LAxis[LIndex] := LIndex;
  end;
  // sort on largest axis
  LIndex := 0;
  while LIndex < 2 do
  begin
    if LSize[LIndex] < LSize[LIndex + 1] then
    begin
      LSwap := LSize[LIndex];
      LSize[LIndex] := LSize[LIndex + 1];
      LSize[LIndex + 1] := LSwap;
      LSwapAxis := LAxis[LIndex];
      LAxis[LIndex] := LAxis[LIndex + 1];
      LAxis[LIndex + 1] := LSwapAxis;
      LIndex := -1;
    end;
    Inc(LIndex);
  end;
  // if the node is too small for further splits
  if LSize[0] < MIN_NODE_SIZE then
    if ANode.Polygons.Count > MAX_NODE_POLYGONS then
      LForceSplit := True;
  // find an axial aligned splitter
  for LAxisIndex := 0 to 2 do
  begin
    // start with the largest axis first
    LType := LAxis[LAxisIndex];
    LBestT := LSize[LAxisIndex];
    // if the node is small anough in this axis direction
    if (not LForceSplit) and (LBestT < MIN_NODE_SIZE) then
      Break;
    // find an axial splitter from the brush bounding boxes, also try brushes from parent nodes
    LNode := ANode;
    while Assigned(LNode) do
    begin
      for LBrush in LNode.Brushes do
        for LSide := 0 to 1 do
        begin
          if LSide = 0 then
            LDist := LBrush.Bounds.Mins[LType]
          else
            LDist := LBrush.Bounds.Maxs[LType];
          // if the splitter is already used or outside node bounds
          if (LDist >= ABounds.Maxs[LType]) or (LDist <= ABounds.Mins[LType]) then
            Continue;
          // find the most centered splitter
          LT := TGeoMath.Fabs((ABounds.Maxs[LType] - LDist) - (LDist - ABounds.Mins[LType]));
          if LT < LBestT then
          begin
            LBestT := LT;
            APlaneType := LType;
            APlaneDist := LDist;
          end;
        end;
      LNode := LNode.Parent;
    end;
    // find an axial splitter from the polygon bounding boxes, also try polygons from parent nodes
    LNode := ANode;
    while Assigned(LNode) do
    begin
      for LPolygon in LNode.Polygons do
        for LSide := 0 to 1 do
        begin
          if LSide = 0 then
            LDist := LPolygon.Bounds.Mins[LType]
          else
            LDist := LPolygon.Bounds.Maxs[LType];
          // if the splitter is already used or outside node bounds
          if (LDist >= ABounds.Maxs[LType]) or (LDist <= ABounds.Mins[LType]) then
            Continue;
          // find the most centered splitter
          LT := TGeoMath.Fabs((ABounds.Maxs[LType] - LDist) - (LDist - ABounds.Mins[LType]));
          if LT < LBestT then
          begin
            LBestT := LT;
            APlaneType := LType;
            APlaneDist := LDist;
          end;
        end;
      LNode := LNode.Parent;
    end;
    // if we found a splitter on the largest axis
    if LBestT < LSize[LAxisIndex] then
    begin
      // if forced split due to lots of polygons
      if LForceSplit then
        Exit(True);
      // don't create splitters real close to the bounds
      if (ABounds.Maxs[APlaneType] - APlaneDist > (MIN_NODE_SIZE * 0.5)) and
        (APlaneDist - ABounds.Mins[APlaneType] > (MIN_NODE_SIZE * 0.5)) then
        Exit(True);
    end;
  end;
  Result := False;
end;

function TCollisionBspBuilder.InsideAllChildren(ANode: TCmNode; const ABounds: TGeoBounds): Boolean;
begin
  if not ANode.IsLeaf then
  begin
    if ABounds.Mins[ANode.PlaneType] >= ANode.PlaneDist then
      Exit(False);
    if ABounds.Maxs[ANode.PlaneType] <= ANode.PlaneDist then
      Exit(False);
    if not InsideAllChildren(ANode.Children[0], ABounds) then
      Exit(False);
    if not InsideAllChildren(ANode.Children[1], ABounds) then
      Exit(False);
  end;
  Result := True;
end;

procedure TCollisionBspBuilder.FilterPolygonIntoTree(ANode: TCmNode; APolygon: TCmPolygon; AMoved: Boolean);
begin
  while not ANode.IsLeaf do
  begin
    if InsideAllChildren(ANode, APolygon.Bounds) then
      Break;
    if APolygon.Bounds.Mins[ANode.PlaneType] >= ANode.PlaneDist then
      ANode := ANode.Children[0]
    else if APolygon.Bounds.Maxs[ANode.PlaneType] <= ANode.PlaneDist then
      ANode := ANode.Children[1]
    else
    begin
      FilterPolygonIntoTree(ANode.Children[1], APolygon, False);
      ANode := ANode.Children[0];
    end;
  end;
  if AMoved then
    ANode.Polygons.Insert(0, APolygon)
  else
    FModel.AddPolygonToNode(ANode, APolygon);
end;

procedure TCollisionBspBuilder.FilterBrushIntoTree(ANode: TCmNode; ABrush: TCmBrush; AMoved: Boolean);
begin
  while not ANode.IsLeaf do
  begin
    if InsideAllChildren(ANode, ABrush.Bounds) then
      Break;
    if ABrush.Bounds.Mins[ANode.PlaneType] >= ANode.PlaneDist then
      ANode := ANode.Children[0]
    else if ABrush.Bounds.Maxs[ANode.PlaneType] <= ANode.PlaneDist then
      ANode := ANode.Children[1]
    else
    begin
      FilterBrushIntoTree(ANode.Children[1], ABrush, False);
      ANode := ANode.Children[0];
    end;
  end;
  if AMoved then
    ANode.Brushes.Insert(0, ABrush)
  else
    FModel.AddBrushToNode(ANode, ABrush);
end;

function TCollisionBspBuilder.CreateTree(ANode: TCmNode; const ABounds: TGeoBounds): TCmNode;
var
  LPlaneType: Integer;
  LPlaneDist: Single;
  LFrontNode: TCmNode;
  LBackNode: TCmNode;
  LFrontBounds: TGeoBounds;
  LBackBounds: TGeoBounds;
  LN: TCmNode;
  LKeptPolygons: TList<TCmPolygon>;
  LKeptBrushes: TList<TCmBrush>;
  LPolygon: TCmPolygon;
  LBrush: TCmBrush;
  LSnapshotPolygons: TArray<TCmPolygon>;
  LSnapshotBrushes: TArray<TCmBrush>;
begin
  LPlaneType := 0;
  LPlaneDist := 0;
  if not FindSplitter(ANode, ABounds, LPlaneType, LPlaneDist) then
  begin
    ANode.PlaneType := -1;
    Exit(ANode);
  end;
  // create two child nodes
  LFrontNode := FModel.CreateNode(ANode);
  LFrontNode.PlaneType := -1;
  LBackNode := FModel.CreateNode(ANode);
  LBackNode.PlaneType := -1;
  Inc(FModel.NumNodes, 2);
  // set front node bounds
  LFrontBounds := ABounds;
  LFrontBounds.Mins[LPlaneType] := LPlaneDist;
  // set back node bounds
  LBackBounds := ABounds;
  LBackBounds.Maxs[LPlaneType] := LPlaneDist;

  ANode.PlaneType := LPlaneType;
  ANode.PlaneDist := LPlaneDist;
  ANode.Children[0] := LFrontNode;
  ANode.Children[1] := LBackNode;
  // filter polygons and brushes down the tree if necessary
  LN := ANode;
  while Assigned(LN) do
  begin
    LSnapshotPolygons := LN.Polygons.ToArray;
    LKeptPolygons := TList<TCmPolygon>.Create;
    LKeptBrushes := TList<TCmBrush>.Create;
    try
      for LPolygon in LSnapshotPolygons do
        // if polygon is not inside all children
        if not InsideAllChildren(LN, LPolygon.Bounds) then
          // filter polygon down the tree
          FilterPolygonIntoTree(LN, LPolygon, True)
        else
          LKeptPolygons.Add(LPolygon);
      LN.Polygons.Clear;
      LN.Polygons.AddRange(LKeptPolygons);

      LSnapshotBrushes := LN.Brushes.ToArray;
      for LBrush in LSnapshotBrushes do
        // if brush is not inside all children
        if not InsideAllChildren(LN, LBrush.Bounds) then
          // filter brush down the tree
          FilterBrushIntoTree(LN, LBrush, True)
        else
          LKeptBrushes.Add(LBrush);
      LN.Brushes.Clear;
      LN.Brushes.AddRange(LKeptBrushes);
    finally
      LKeptBrushes.Free;
      LKeptPolygons.Free;
    end;
    LN := LN.Parent;
  end;
  CreateTree(LFrontNode, LFrontBounds);
  CreateTree(LBackNode, LBackBounds);
  Result := ANode;
end;

function TCollisionBspBuilder.CreateAxialBSPTree(ANode: TCmNode): TCmNode;
var
  LBounds: TGeoBounds;
  LPolygon: TCmPolygon;
  LBrush: TCmBrush;
begin
  // get head node bounds
  LBounds.Clear;
  for LPolygon in ANode.Polygons do
    LBounds.AddBounds(LPolygon.Bounds);
  for LBrush in ANode.Brushes do
    LBounds.AddBounds(LBrush.Bounds);
  // create axial BSP tree from head node
  Result := CreateTree(ANode, LBounds);
end;

end.
