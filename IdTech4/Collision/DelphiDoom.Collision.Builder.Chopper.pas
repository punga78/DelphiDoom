{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - removal of polygons that are contained in   }
{  brushes or in solid space                                                   }
{                                                                              }
{  Port of R_ChoppedAwayByProcBSP, ChoppedAwayByProcBSP,                       }
{  ChopWindingListWithBrush, R_ChopWindingListWithTreeBrushes and              }
{  WindingOutsideBrushes (CollisionModel_load.cpp), Doom 3 GPL Source Code.    }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. Based on  }
{  the Doom 3 GPL Source Code (id Software). Doom 3 Source Code: GNU General   }
{  Public License version 3 with additional terms. This unit is a derived      }
{  work (GPL v3).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.Chopper;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Geometry.Winding, DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Model,
  DelphiDoom.Collision.Model.Node, DelphiDoom.Collision.Model.Brush, DelphiDoom.Logging.Intf,
  DelphiDoom.MapFile.Proc.ProcFile;

type
  /// <summary>
  ///   A node of the BSP tree of the .proc file (cm_procNode_t): the plane with a raw d (a point is in
  ///   front when a*x+b*y+c*z+d is positive), and the children: negative numbers are
  ///   (-1 - area number), 0 is solid, a positive number is the index of another node
  /// </summary>
  TCollisionProcNode = record
    Plane: TGeoPlane;
    Children: array[0..1] of Integer;
  end;

  /// <summary>
  ///   Windings of one primitive, to be chopped by brushes (cm_windingList_t). The windings are
  ///   owned by the list
  /// </summary>
  TCollisionWindingList = class
  public
    Windings: TObjectList<TGeoWinding>;
    /// <summary>normal for all windings</summary>
    Normal: TGeoVec3;
    /// <summary>bounds of all windings in list</summary>
    Bounds: TGeoBounds;
    /// <summary>origin for radius</summary>
    Origin: TGeoVec3;
    /// <summary>radius relative to origin for all windings</summary>
    Radius: Single;
    /// <summary>winding surface contents</summary>
    Contents: Integer;
    /// <summary>number of primitive the windings came from</summary>
    PrimitiveNum: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  /// <summary>
  ///   Decides if a polygon is not needed: it lies in solid space of the proc BSP tree (only for the
  ///   world model) or inside brushes of the model (WindingOutsideBrushes)
  /// </summary>
  TCollisionChopper = class
  private
    FModel: TCollisionModel;
    FCounter: TCollisionCheckCounter;
    FProcNodes: TArray<TCollisionProcNode>;
    FWorldModel: Boolean;
    FLog: ILog;
    function ChoppedAwayByProcNode(ANodeNum: Integer; AWinding: TGeoWinding; const ANormal, AOrigin: TGeoVec3;
      ARadius: Single): Boolean;
    procedure ChopWindingListWithBrush(AList: TCollisionWindingList; ABrush: TCmBrush);
    procedure ChopWindingListWithTreeBrushes(AList: TCollisionWindingList; ANode: TCmNode);
    procedure Warn(const AText: string);
  public
    /// <summary>
    ///   AProcNodes may be empty (no proc tree: nothing is chopped away by it); AWorldModel is true for the
    ///   first model of the map (numModels = 0 in the original). The log may be nil
    /// </summary>
    constructor Create(AModel: TCollisionModel; ACounter: TCollisionCheckCounter;
      const AProcNodes: TArray<TCollisionProcNode>; AWorldModel: Boolean; const ALog: ILog);
    /// <summary>The nodes of the "nodes" section of a .proc file (ParseProcNodes) as the chopper wants them</summary>
    class function NodesFromProcFile(AFile: TProcFile): TArray<TCollisionProcNode>; static;
    /// <summary>ChoppedAwayByProcBSP: true if the winding lies completely in solid space of the proc tree</summary>
    function ChoppedAwayByProcBSP(AWinding: TGeoWinding; const APlane: TGeoPlane; AContents: Integer): Boolean;
    /// <summary>
    ///   WindingOutsideBrushes: one winding that is not or only partly contained in brushes, nil if the
    ///   winding is fully contained. The result is AWinding itself or a new winding that the caller frees
    /// </summary>
    function WindingOutsideBrushes(AWinding: TGeoWinding; const APlane: TGeoPlane; AContents,
      APrimitiveNum: Integer; AHeadNode: TCmNode): TGeoWinding;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Mat3, DelphiDoom.Collision.Types;

const
  CHOP_EPSILON: Single = 0.1;
  MAX_WINDING_LIST = 128;
  /// <summary>MAX_POINTS_ON_WINDING of Winding.h</summary>
  MAX_POINTS_ON_WINDING = 96;

resourcestring
  SChopMoreWindings = 'TCollisionChopper.ChopWindingWithBrush: primitive %d more than %d windings';

{ TCollisionWindingList }

constructor TCollisionWindingList.Create;
begin
  inherited Create;
  Windings := TObjectList<TGeoWinding>.Create(True);
end;

destructor TCollisionWindingList.Destroy;
begin
  Windings.Free;
  inherited Destroy;
end;

{ TCollisionChopper }

constructor TCollisionChopper.Create(AModel: TCollisionModel; ACounter: TCollisionCheckCounter;
  const AProcNodes: TArray<TCollisionProcNode>; AWorldModel: Boolean; const ALog: ILog);
begin
  inherited Create;
  FModel := AModel;
  FCounter := ACounter;
  FProcNodes := AProcNodes;
  FWorldModel := AWorldModel;
  FLog := ALog;
end;

class function TCollisionChopper.NodesFromProcFile(AFile: TProcFile): TArray<TCollisionProcNode>;
var
  LIndex: Integer;
begin
  SetLength(Result, AFile.Nodes.Count);
  for LIndex := 0 to AFile.Nodes.Count - 1 do
  begin
    Result[LIndex].Plane := AFile.Nodes[LIndex].Plane;
    Result[LIndex].Children[0] := AFile.Nodes[LIndex].PositiveChild;
    Result[LIndex].Children[1] := AFile.Nodes[LIndex].NegativeChild;
  end;
end;

procedure TCollisionChopper.Warn(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TCollisionChopper.ChoppedAwayByProcNode(ANodeNum: Integer; AWinding: TGeoWinding; const ANormal,
  AOrigin: TGeoVec3; ARadius: Single): Boolean;
var
  LRes: Integer;
  LBack: TGeoWinding;
  LDist: Single;
  LNode: TCollisionProcNode;
begin
  repeat
    LNode := FProcNodes[ANodeNum];
    LDist := LNode.Plane.Normal.Dot(AOrigin) + LNode.Plane.D;
    LBack := nil;
    try
      if LDist > ARadius then
        LRes := PLANESIDE_FRONT
      else if LDist < -ARadius then
        LRes := PLANESIDE_BACK
      else
      begin
        LBack := TGeoWinding.Create;
        // the part in front stays in AWinding
        LRes := AWinding.Split(LBack, LNode.Plane, CHOP_EPSILON);
      end;
      if LRes = PLANESIDE_FRONT then
        ANodeNum := LNode.Children[0]
      else if LRes = PLANESIDE_BACK then
        ANodeNum := LNode.Children[1]
      else if LRes = PLANESIDE_ON then
      begin
        // continue with the side the winding faces
        if LNode.Plane.Normal.Dot(ANormal) > 0 then
          ANodeNum := LNode.Children[0]
        else
          ANodeNum := LNode.Children[1];
      end
      else
      begin
        // if either node is not solid
        if (LNode.Children[0] < 0) or (LNode.Children[1] < 0) then
          Exit(False);
        // only recurse if the node is not solid
        if LNode.Children[1] > 0 then
          if not ChoppedAwayByProcNode(LNode.Children[1], LBack, ANormal, AOrigin, ARadius) then
            Exit(False);
        ANodeNum := LNode.Children[0];
      end;
    finally
      LBack.Free;
    end;
  until ANodeNum <= 0;
  if ANodeNum < 0 then
    Exit(False);
  Result := True;
end;

function TCollisionChopper.ChoppedAwayByProcBSP(AWinding: TGeoWinding; const APlane: TGeoPlane;
  AContents: Integer): Boolean;
var
  LCopy: TGeoWinding;
  LBounds: TGeoBounds;
  LOrigin: TGeoVec3;
  LRadius: Single;
begin
  // if the .proc file has no BSP tree
  if Length(FProcNodes) = 0 then
    Exit(False);
  // don't chop if the polygon is not solid
  if (AContents and CONTENTS_SOLID) = 0 then
    Exit(False);
  // make a local copy of the winding
  LCopy := AWinding.Copy;
  try
    LBounds := LCopy.GetBounds;
    LOrigin := (LBounds.Maxs - LBounds.Mins) * 0.5;
    LRadius := LOrigin.Length + CHOP_EPSILON;
    LOrigin := LBounds.Mins + LOrigin;
    Result := ChoppedAwayByProcNode(0, LCopy, APlane.Normal, LOrigin, LRadius);
  finally
    LCopy.Free;
  end;
end;

procedure TCollisionChopper.ChopWindingListWithBrush(AList: TCollisionWindingList; ABrush: TCmBrush);
var
  LIndex: Integer;
  LK: Integer;
  LRes: Integer;
  LStartPlane: Integer;
  LPlaneNum: Integer;
  LBestNumWindings: Integer;
  LChopped: Boolean;
  LSidedness: array[0..MAX_POINTS_ON_WINDING - 1] of Integer;
  LDist: Single;
  LPlane: TGeoPlane;
  LFront: TGeoWinding;
  LBack: TGeoWinding;
  LOut: TObjectList<TGeoWinding>;
  LOutNum: Integer;
  LTmp: TObjectList<TGeoWinding>;
  LNormal: TGeoVec3;

  procedure SetOut(APosition: Integer; AWinding: TGeoWinding);
  begin
    // the original overwrites windings in an array: the objects of the list are replaced
    while LOut.Count <= APosition do
      LOut.Add(TGeoWinding.Create);
    LOut[APosition] := AWinding;
  end;

begin
  if ABrush.NumPlanes > MAX_POINTS_ON_WINDING then
    Exit;

  // get sidedness for the list of windings
  for LIndex := 0 to ABrush.NumPlanes - 1 do
  begin
    LPlane := -ABrush.Planes[LIndex];
    LDist := LPlane.Distance(AList.Origin);
    if LDist > AList.Radius then
      LSidedness[LIndex] := PLANESIDE_FRONT
    else if LDist < -AList.Radius then
      LSidedness[LIndex] := PLANESIDE_BACK
    else
    begin
      LSidedness[LIndex] := AList.Bounds.PlaneSide(LPlane);
      if LSidedness[LIndex] = PLANESIDE_FRONT then
        LSidedness[LIndex] := PLANESIDE_FRONT
      else if LSidedness[LIndex] = PLANESIDE_BACK then
        LSidedness[LIndex] := PLANESIDE_BACK
      else
        LSidedness[LIndex] := PLANESIDE_CROSS;
    end;
  end;

  LOut := TObjectList<TGeoWinding>.Create(True);
  LTmp := TObjectList<TGeoWinding>.Create(True);
  try
    LOutNum := 0;
    for LK := 0 to AList.Windings.Count - 1 do
    begin
      LStartPlane := 0;
      LBestNumWindings := 1 + ABrush.NumPlanes;
      LChopped := False;
      repeat
        LFront := AList.Windings[LK].Copy;
        try
          LTmp.Clear;
          LPlaneNum := LStartPlane;
          for LIndex := 0 to ABrush.NumPlanes - 1 do
          begin
            if LPlaneNum >= ABrush.NumPlanes then
              LPlaneNum := 0;

            LRes := LSidedness[LPlaneNum];
            LBack := nil;

            if LRes = PLANESIDE_CROSS then
            begin
              LPlane := -ABrush.Planes[LPlaneNum];
              LBack := TGeoWinding.Create;
              LRes := LFront.Split(LBack, LPlane, CHOP_EPSILON);
            end;

            // NOTE: disabling this can create gaps at places where Z-fighting occurs
            // only leave windings on a brush if the winding plane and brush side plane face the same direction
            LNormal := ABrush.Planes[LPlaneNum].Normal;
            if (LRes = PLANESIDE_ON) and (AList.PrimitiveNum >= 0) and (AList.Normal.Dot(LNormal) > 0) then
            begin
              // return because all windings in the list will be on this brush side plane
              LBack.Free;
              Exit;
            end;

            if LRes = PLANESIDE_BACK then
            begin
              LBack.Free;
              if LOutNum >= MAX_WINDING_LIST then
              begin
                Warn(Format(SChopMoreWindings, [AList.PrimitiveNum, MAX_WINDING_LIST]));
                Exit;
              end;
              // winding and brush didn't intersect, store the original winding
              SetOut(LOutNum, AList.Windings[LK].Copy);
              Inc(LOutNum);
              LChopped := False;
              Break;
            end;

            if LRes = PLANESIDE_CROSS then
            begin
              if LTmp.Count >= MAX_WINDING_LIST then
              begin
                LBack.Free;
                Warn(Format(SChopMoreWindings, [AList.PrimitiveNum, MAX_WINDING_LIST]));
                Exit;
              end;
              // store the front winding in the temporary list
              LTmp.Add(LBack);
              LBack := nil;
              LChopped := True;
            end;
            LBack.Free;

            // if already found a start plane which generates less fragments
            if LTmp.Count >= LBestNumWindings then
              Break;
            Inc(LPlaneNum);
          end;
        finally
          LFront.Free;
        end;

        // find the best start plane to get the least number of fragments outside the brush
        if LTmp.Count < LBestNumWindings then
        begin
          LBestNumWindings := LTmp.Count;
          // store windings from temporary list in the out list
          for LIndex := 0 to LTmp.Count - 1 do
          begin
            if LOutNum + LIndex >= MAX_WINDING_LIST then
            begin
              Warn(Format(SChopMoreWindings, [AList.PrimitiveNum, MAX_WINDING_LIST]));
              Exit;
            end;
            SetOut(LOutNum + LIndex, LTmp[LIndex].Copy);
          end;
          // if only one winding left then we can't do any better
          if LBestNumWindings = 1 then
            Break;
        end;

        // try the next start plane
        Inc(LStartPlane);
      until not (LChopped and (LStartPlane < ABrush.NumPlanes));

      if LChopped then
        Inc(LOutNum, LBestNumWindings);
    end;

    AList.Windings.Clear;
    for LIndex := 0 to LOutNum - 1 do
      AList.Windings.Add(LOut[LIndex].Copy);
  finally
    LTmp.Free;
    LOut.Free;
  end;
end;

procedure TCollisionChopper.ChopWindingListWithTreeBrushes(AList: TCollisionWindingList; ANode: TCmNode);
var
  LIndex: Integer;
  LAxis: Integer;
  LBrush: TCmBrush;
begin
  while True do
  begin
    for LIndex := 0 to ANode.Brushes.Count - 1 do
    begin
      LBrush := ANode.Brushes[LIndex];
      // if we checked this brush already
      if LBrush.CheckCount = FCounter.Value then
        Continue;
      LBrush.CheckCount := FCounter.Value;
      // if the windings in the list originate from this brush
      if LBrush.PrimitiveNum = AList.PrimitiveNum then
        Continue;
      // if brush has a different contents
      if LBrush.Contents <> AList.Contents then
        Continue;
      // brush bounds and winding list bounds should overlap
      LAxis := 0;
      while LAxis < 3 do
      begin
        if AList.Bounds.Mins[LAxis] > LBrush.Bounds.Maxs[LAxis] then
          Break;
        if AList.Bounds.Maxs[LAxis] < LBrush.Bounds.Mins[LAxis] then
          Break;
        Inc(LAxis);
      end;
      if LAxis < 3 then
        Continue;
      // chop windings in the list with brush
      ChopWindingListWithBrush(AList, LBrush);
      // if all windings are chopped away we're done
      if AList.Windings.Count = 0 then
        Exit;
    end;
    // if leaf node
    if ANode.PlaneType = -1 then
      Break;
    if AList.Bounds.Mins[ANode.PlaneType] > ANode.PlaneDist then
      ANode := ANode.Children[0]
    else if AList.Bounds.Maxs[ANode.PlaneType] < ANode.PlaneDist then
      ANode := ANode.Children[1]
    else
    begin
      ChopWindingListWithTreeBrushes(AList, ANode.Children[1]);
      if AList.Windings.Count = 0 then
        Exit;
      ANode := ANode.Children[0];
    end;
  end;
end;

function TCollisionChopper.WindingOutsideBrushes(AWinding: TGeoWinding; const APlane: TGeoPlane; AContents,
  APrimitiveNum: Integer; AHeadNode: TCmNode): TGeoWinding;
var
  LList: TCollisionWindingList;
  LIndex: Integer;
  LWindingLeft: Integer;
  LAxis: Integer;
begin
  LList := TCollisionWindingList.Create;
  try
    LList.Bounds.Clear;
    for LIndex := 0 to AWinding.NumPoints - 1 do
      LList.Bounds.AddPoint(AWinding[LIndex]);

    LList.Origin := (LList.Bounds.Maxs - LList.Bounds.Mins) * 0.5;
    LList.Radius := LList.Origin.Length + CHOP_EPSILON;
    LList.Origin := LList.Bounds.Mins + LList.Origin;
    for LAxis := 0 to 2 do
    begin
      LList.Bounds.Mins[LAxis] := LList.Bounds.Mins[LAxis] - CHOP_EPSILON;
      LList.Bounds.Maxs[LAxis] := LList.Bounds.Maxs[LAxis] + CHOP_EPSILON;
    end;

    LList.Windings.Add(AWinding.Copy);
    LList.Normal := APlane.Normal;
    LList.Contents := AContents;
    LList.PrimitiveNum := APrimitiveNum;

    FCounter.Next;
    ChopWindingListWithTreeBrushes(LList, AHeadNode);

    if LList.Windings.Count = 0 then
      Exit(nil);
    if LList.Windings.Count = 1 then
      Exit(LList.Windings.Extract(LList.Windings[0]));
    // if not the world model
    if not FWorldModel then
      Exit(AWinding);
    // check if winding fragments would be chopped away by the proc BSP tree
    LWindingLeft := -1;
    for LIndex := 0 to LList.Windings.Count - 1 do
      if not ChoppedAwayByProcBSP(LList.Windings[LIndex], APlane, AContents) then
      begin
        if LWindingLeft >= 0 then
          Exit(AWinding);
        LWindingLeft := LIndex;
      end;
    if LWindingLeft >= 0 then
      Exit(LList.Windings.Extract(LList.Windings[LWindingLeft]));
    Result := nil;
  finally
    LList.Free;
  end;
end;

end.
