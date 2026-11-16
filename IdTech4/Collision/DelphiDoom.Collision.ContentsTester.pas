{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - position tests of the trace model           }
{                                                                              }
{  Port of TestTrmVertsInBrush and TestTrmInPolygon of CollisionModel_         }
{  contents.cpp, Doom 3 GPL Source Code. Copyright (C) 1999-2011 id Software   }
{  LLC, a ZeniMax Media company. Doom 3 Source Code: GNU General Public        }
{  License version 3 with additional terms. This unit is a derived work (GPL   }
{  v3).                                                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.ContentsTester;

interface

uses
  DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.TraceWork, DelphiDoom.Collision.Model.Brush,
  DelphiDoom.Collision.Model.Polygon;

type
  /// <summary>Tests whether the trace model, standing still, is inside a brush or touches a polygon</summary>
  TCollisionContentsTester = class
  private
    FCounter: TCollisionCheckCounter;
  public
    constructor Create(ACounter: TCollisionCheckCounter);
    /// <summary>True if any of the trm vertices is inside the brush (TestTrmVertsInBrush)</summary>
    function TestTrmVertsInBrush(ATraceWork: TCmTraceWork; ABrush: TCmBrush): Boolean;
    /// <summary>True if the trm intersects the polygon (TestTrmInPolygon)</summary>
    function TestTrmInPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon): Boolean;
  end;

implementation

uses
  System.Math, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Pluecker, DelphiDoom.Geometry.TraceModel, DelphiDoom.Geometry.FloatMath,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Model, DelphiDoom.Collision.Model.Types,
  DelphiDoom.Collision.Sidedness;

{ TCollisionContentsTester }

constructor TCollisionContentsTester.Create(ACounter: TCollisionCheckCounter);
begin
  inherited Create;
  FCounter := ACounter;
end;

function TCollisionContentsTester.TestTrmVertsInBrush(ATraceWork: TCmTraceWork; ABrush: TCmBrush): Boolean;
var
  LIndex: Integer;
  LVertexIndex: Integer;
  LNumVerts: Integer;
  LBestPlane: Integer;
  LBestD: Single;
  LD: Single;
  LPoint: TGeoVec3;
begin
  if ABrush.CheckCount = FCounter.Value then
    Exit(False);
  ABrush.CheckCount := FCounter.Value;

  if (ABrush.Contents and ATraceWork.Contents) = 0 then
    Exit(False);

  // if the brush bounds don't intersect the trace bounds
  if not ABrush.Bounds.IntersectsBounds(ATraceWork.Bounds) then
    Exit(False);

  if ATraceWork.PointTrace then
    LNumVerts := 1
  else
    LNumVerts := ATraceWork.NumVerts;

  for LVertexIndex := 0 to LNumVerts - 1 do
  begin
    LPoint := ATraceWork.Vertices[LVertexIndex].P;

    // see if the point is inside the brush
    LBestPlane := 0;
    LBestD := -GEO_INFINITY;
    LIndex := 0;
    while LIndex < ABrush.NumPlanes do
    begin
      LD := ABrush.Planes[LIndex].Distance(LPoint);
      if LD >= 0 then
        Break;
      if LD > LBestD then
      begin
        LBestD := LD;
        LBestPlane := LIndex;
      end;
      Inc(LIndex);
    end;
    if LIndex >= ABrush.NumPlanes then
    begin
      ATraceWork.Trace.Fraction := 0;
      ATraceWork.Trace.C.ContactType := ctTrmVertex;
      ATraceWork.Trace.C.Normal := ABrush.Planes[LBestPlane].Normal;
      ATraceWork.Trace.C.Dist := ABrush.Planes[LBestPlane].Dist;
      ATraceWork.Trace.C.Contents := ABrush.Contents;
      ATraceWork.Trace.C.Material := ABrush.Material;
      ATraceWork.Trace.C.Point := LPoint;
      ATraceWork.Trace.C.ModelFeature := 0;
      ATraceWork.Trace.C.TrmFeature := LVertexIndex;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TCollisionContentsTester.TestTrmInPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon): Boolean;
var
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LEdgeNum: Integer;
  LTrmEdgeNum: Integer;
  LBitNum: Integer;
  LFlip: Integer;
  LBestPlane: Integer;
  LBestD: Single;
  LD: Single;
  LSides: array[0..MAX_TRACEMODEL_VERTS - 1] of Integer;
  LEdge: PCmEdge;
  LV: PCmVertex;
  LV1: PCmVertex;
  LV2: PCmVertex;
  LModel: TCollisionModel;
  LCount: Integer;
  LPoint: TGeoVec3;

  /// <summary>(Side >> n) &amp; 1 with the shift count wrapped like x86</summary>
  function BitOf(AValue: Cardinal; ABit: Integer): Cardinal;
  begin
    Result := (AValue shr (ABit and 31)) and 1;
  end;

begin
  LModel := ATraceWork.Model;
  // if already checked this polygon
  if APolygon.CheckCount = FCounter.Value then
    Exit(False);
  APolygon.CheckCount := FCounter.Value;

  // if this polygon does not have the right contents behind it
  if (APolygon.Contents and ATraceWork.Contents) = 0 then
    Exit(False);

  // if the polygon bounds don't intersect the trace bounds
  if not APolygon.Bounds.IntersectsBounds(ATraceWork.Bounds) then
    Exit(False);

  // bounds should cross polygon plane
  case ATraceWork.Bounds.PlaneSide(APolygon.Plane) of
    PLANESIDE_CROSS:
      ;
    PLANESIDE_FRONT:
      begin
        if LModel.IsConvex then
        begin
          ATraceWork.QuickExit := True;
          Exit(True);
        end;
        Exit(False);
      end;
  else
    Exit(False);
  end;

  // if the trace model is convex
  if ATraceWork.IsConvex then
  begin
    // test if any polygon vertices are inside the trm
    for LI := 0 to APolygon.NumEdges - 1 do
    begin
      LEdgeNum := APolygon.Edges[LI];
      LEdge := @LModel.Edges[Abs(LEdgeNum)];
      // if this edge is already tested
      if LEdge.CheckCount = FCounter.Value then
        Continue;

      for LJ := 0 to 1 do
      begin
        LV := @LModel.Vertices[LEdge.VertexNum[LJ]];
        // if this vertex is already tested
        if LV.CheckCount = FCounter.Value then
          Continue;

        LBestPlane := 0;
        LBestD := -GEO_INFINITY;
        LK := 0;
        while LK < ATraceWork.NumPolys do
        begin
          LD := ATraceWork.Polys[LK].Plane.Distance(LV.P);
          if LD >= 0 then
            Break;
          if LD > LBestD then
          begin
            LBestD := LD;
            LBestPlane := LK;
          end;
          Inc(LK);
        end;
        if LK >= ATraceWork.NumPolys then
        begin
          ATraceWork.Trace.Fraction := 0;
          ATraceWork.Trace.C.ContactType := ctModelVertex;
          ATraceWork.Trace.C.Normal := -ATraceWork.Polys[LBestPlane].Plane.Normal;
          ATraceWork.Trace.C.Dist := -ATraceWork.Polys[LBestPlane].Plane.Dist;
          ATraceWork.Trace.C.Contents := APolygon.Contents;
          ATraceWork.Trace.C.Material := APolygon.Material;
          ATraceWork.Trace.C.Point := LV.P;
          ATraceWork.Trace.C.ModelFeature := LEdge.VertexNum[LJ];
          ATraceWork.Trace.C.TrmFeature := 0;
          Exit(True);
        end;
      end;
    end;
  end;

  for LI := 0 to APolygon.NumEdges - 1 do
  begin
    LEdgeNum := APolygon.Edges[LI];
    LEdge := @LModel.Edges[Abs(LEdgeNum)];
    // reset sidedness cache if this is the first time we encounter this edge
    if LEdge.CheckCount <> FCounter.Value then
      LEdge.SideSet := 0;
    // pluecker coordinate for edge
    ATraceWork.PolygonEdgePlueckerCache[LI].FromLine(LModel.Vertices[LEdge.VertexNum[0]].P,
      LModel.Vertices[LEdge.VertexNum[1]].P);
    LV := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]];
    // reset sidedness cache if this is the first time we encounter this vertex
    if LV.CheckCount <> FCounter.Value then
      LV.SideSet := 0;
    LV.CheckCount := FCounter.Value;
  end;

  // get side of polygon for each trm vertex
  for LI := 0 to ATraceWork.NumVerts - 1 do
  begin
    LD := APolygon.Plane.Distance(ATraceWork.Vertices[LI].P);
    if LD < 0 then
      LSides[LI] := -1
    else
      LSides[LI] := 1;
  end;

  // test if any trm edges go through the polygon
  for LI := 1 to ATraceWork.NumEdges do
  begin
    // if the trm edge does not cross the polygon plane
    if LSides[ATraceWork.Edges[LI].VertexNum[0]] = LSides[ATraceWork.Edges[LI].VertexNum[1]] then
      Continue;
    // check from which side to which side the trm edge goes
    LFlip := TGeoMath.IntSignBitSet(LSides[ATraceWork.Edges[LI].VertexNum[0]]);
    // test if trm edge goes through the polygon between the polygon edges
    LJ := 0;
    while LJ < APolygon.NumEdges do
    begin
      LEdgeNum := APolygon.Edges[LJ];
      LEdge := @LModel.Edges[Abs(LEdgeNum)];
      TCollisionSidedness.SetEdge(LEdge, ATraceWork.Edges[LI].Pl, ATraceWork.PolygonEdgePlueckerCache[LJ], LI);
      if ((TGeoMath.IntSignBitSet(LEdgeNum) xor BitOf(LEdge.Side, LI)) xor Cardinal(LFlip)) <> 0 then
        Break;
      Inc(LJ);
    end;
    if LJ >= APolygon.NumEdges then
    begin
      ATraceWork.Trace.Fraction := 0;
      ATraceWork.Trace.C.ContactType := ctEdge;
      ATraceWork.Trace.C.Normal := APolygon.Plane.Normal;
      ATraceWork.Trace.C.Dist := APolygon.Plane.Dist;
      ATraceWork.Trace.C.Contents := APolygon.Contents;
      ATraceWork.Trace.C.Material := APolygon.Material;
      if LFlip = 0 then
        LCount := 1
      else
        LCount := 0;
      ATraceWork.Trace.C.Point := ATraceWork.Vertices[ATraceWork.Edges[LI].VertexNum[LCount]].P;
      ATraceWork.Trace.C.ModelFeature := APolygon.Id;
      ATraceWork.Trace.C.TrmFeature := LI;
      Exit(True);
    end;
  end;

  // test if any polygon edges go through the trm polygons
  for LI := 0 to APolygon.NumEdges - 1 do
  begin
    LEdgeNum := APolygon.Edges[LI];
    LEdge := @LModel.Edges[Abs(LEdgeNum)];
    if LEdge.CheckCount = FCounter.Value then
      Continue;
    LEdge.CheckCount := FCounter.Value;

    for LJ := 0 to ATraceWork.NumPolys - 1 do
    begin
      LV1 := @LModel.Vertices[LEdge.VertexNum[0]];
      TCollisionSidedness.SetVertexPolygon(LV1, ATraceWork.Polys[LJ].Plane, LJ);
      LV2 := @LModel.Vertices[LEdge.VertexNum[1]];
      TCollisionSidedness.SetVertexPolygon(LV2, ATraceWork.Polys[LJ].Plane, LJ);
      // if the polygon edge does not cross the trm polygon plane
      if (((LV1.Side xor LV2.Side) shr (LJ and 31)) and 1) = 0 then
        Continue;
      LFlip := Integer((LV1.Side shr (LJ and 31)) and 1);
      // test if polygon edge goes through the trm polygon between the trm polygon edges
      LK := 0;
      while LK < ATraceWork.Polys[LJ].NumEdges do
      begin
        LTrmEdgeNum := ATraceWork.Polys[LJ].Edges[LK];
        LBitNum := Abs(LTrmEdgeNum);
        TCollisionSidedness.SetEdge(LEdge, ATraceWork.Edges[Abs(LTrmEdgeNum)].Pl,
          ATraceWork.PolygonEdgePlueckerCache[LI], LBitNum);
        if ((TGeoMath.IntSignBitSet(LTrmEdgeNum) xor BitOf(LEdge.Side, LBitNum)) xor Cardinal(LFlip)) <> 0 then
          Break;
        Inc(LK);
      end;
      if LK >= ATraceWork.Polys[LJ].NumEdges then
      begin
        ATraceWork.Trace.Fraction := 0;
        ATraceWork.Trace.C.ContactType := ctEdge;
        ATraceWork.Trace.C.Normal := -ATraceWork.Polys[LJ].Plane.Normal;
        ATraceWork.Trace.C.Dist := -ATraceWork.Polys[LJ].Plane.Dist;
        ATraceWork.Trace.C.Contents := APolygon.Contents;
        ATraceWork.Trace.C.Material := APolygon.Material;
        if LFlip = 0 then
          LCount := 1
        else
          LCount := 0;
        LPoint := LModel.Vertices[LEdge.VertexNum[LCount]].P;
        ATraceWork.Trace.C.Point := LPoint;
        ATraceWork.Trace.C.ModelFeature := LEdgeNum;
        ATraceWork.Trace.C.TrmFeature := LJ;
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

end.
