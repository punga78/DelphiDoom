{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - translation of a trace model through        }
{  the polygons of a model                                                     }
{                                                                              }
{  Port of CollisionModel_translate.cpp (without the Translation entry point,  }
{  which is in the manager), Doom 3 GPL Source Code.                           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Translator;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Pluecker,
  DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.TraceWork, DelphiDoom.Collision.Model.Types,
  DelphiDoom.Collision.Model.Polygon;

type
  /// <summary>
  ///   The collision tests of a translating trace model against one polygon: it moves
  ///   the vertices, the edges and the polygons of the trace model along the direction and
  ///   keeps in the trace work the first collision. Pluecker coordinates tell on which side
  ///   of an edge a moving point passes, so there is no sampling.
  /// </summary>
  TCollisionTranslator = class
  private
    FCounter: TCollisionCheckCounter;
    class function TranslateEdgeThroughEdge(const ACross: TGeoVec3; const AL1, AL2: TGeoPluecker;
      out AFraction: Single): Boolean; static;
    class function TranslationPlaneFraction(const APlane: TGeoPlane; const AStart, AEnd: TGeoVec3): Single; static;
    class procedure AddContact(ATraceWork: TCmTraceWork); static;
    procedure TranslateTrmEdgeThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon; ATrmEdgeIndex: Integer);
    procedure TranslateTrmVertexThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon;
      AVertexIndex: Integer; ABitNum: Integer);
    procedure TranslatePointThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon; AVertexIndex: Integer);
    procedure TranslateVertexThroughTrmPolygon(ATraceWork: TCmTraceWork; ATrmPolyIndex: Integer;
      APolygon: TCmPolygon; AVertex: PCmVertex; const AEndPoint: TGeoVec3; const APluecker: TGeoPluecker);
  public
    constructor Create(ACounter: TCollisionCheckCounter);
    /// <summary>
    ///   Returns true if the polygon blocks the complete translation
    ///   (TranslateTrmThroughPolygon). Updates ATraceWork.Trace
    /// </summary>
    function TranslateTrmThroughPolygon(ATraceWork: TCmTraceWork; APolygon: TCmPolygon): Boolean;
  end;

implementation

uses
  System.Math, DelphiDoom.Geometry.Types, DelphiDoom.Geometry.FloatMath, DelphiDoom.Geometry.Bounds,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Model, DelphiDoom.Collision.Sidedness;

/// <summary>(value >> bit) &amp; 1 with the shift count wrapped to 32 bits as on x86</summary>
function BitOf(AValue: Cardinal; ABit: Integer): Cardinal; inline;
begin
  Result := (AValue shr (ABit and 31)) and 1;
end;

{ TCollisionTranslator }

constructor TCollisionTranslator.Create(ACounter: TCollisionCheckCounter);
begin
  inherited Create;
  FCounter := ACounter;
end;

class function TCollisionTranslator.TranslateEdgeThroughEdge(const ACross: TGeoVec3; const AL1,
  AL2: TGeoPluecker; out AFraction: Single): Boolean;
var
  LD: Single;
  LT: Single;
begin
  LD := AL2.P[4] * ACross.X + AL2.P[5] * ACross.Y + AL2.P[2] * ACross.Z;
  if LD = 0 then
  begin
    AFraction := 1;
    // no collision ever
    Exit(False);
  end;
  LT := -AL1.PermutedInnerProduct(AL2);
  // if the lines cross each other to begin with
  if LT = 0 then
  begin
    AFraction := 0;
    Exit(True);
  end;
  // fraction of movement at the time the lines cross each other
  AFraction := LT / LD;
  Result := True;
end;

class function TCollisionTranslator.TranslationPlaneFraction(const APlane: TGeoPlane; const AStart,
  AEnd: TGeoVec3): Single;
var
  LD1: Single;
  LD2: Single;
  LD2Eps: Single;
begin
  LD2 := APlane.Distance(AEnd);
  // if the end point is closer to the plane than an epsilon we still take it for a collision
  LD2Eps := LD2 - CM_CLIP_EPSILON;
  if TGeoMath.FloatSignBitNotSet(LD2Eps) <> 0 then
    Exit(1);
  LD1 := APlane.Distance(AStart);
  // if completely behind the polygon
  if TGeoMath.FloatSignBitSet(LD1) <> 0 then
    Exit(1);
  // if going towards the front of the plane and the start and end point are not at
  // equal distance from the plane
  LD2 := LD1 - LD2;
  if LD2 <= 0 then
    Exit(1);
  Result := (LD1 - CM_CLIP_EPSILON) / LD2;
end;

class procedure TCollisionTranslator.AddContact(ATraceWork: TCmTraceWork);
begin
  if ATraceWork.Contacts.Count >= ATraceWork.MaxContacts then
    Exit;
  // copy contact information from the trace
  ATraceWork.Contacts.Add(ATraceWork.Trace.C);
  // set fraction back to 1 to find all other contacts
  ATraceWork.Trace.Fraction := 1;
end;

procedure TCollisionTranslator.TranslateTrmEdgeThroughPolygon(ATraceWork: TCmTraceWork;
  APolygon: TCmPolygon; ATrmEdgeIndex: Integer);
var
  LIndex: Integer;
  LEdgeNum: Integer;
  LF1: Single;
  LF2: Single;
  LDist: Single;
  LD1: Single;
  LD2: Single;
  LStart: TGeoVec3;
  LEnd: TGeoVec3;
  LNormal: TGeoVec3;
  LEdge: PCmEdge;
  LV1: PCmVertex;
  LV2: PCmVertex;
  LPl: PGeoPluecker;
  LEpsPl: TGeoPluecker;
  LTrmEdge: ^TCmTrmEdge;
  LModel: TCollisionModel;
begin
  LModel := ATraceWork.Model;
  LTrmEdge := @ATraceWork.Edges[ATrmEdgeIndex];
  // check edges for a collision
  for LIndex := 0 to APolygon.NumEdges - 1 do
  begin
    LEdgeNum := APolygon.Edges[LIndex];
    LEdge := @LModel.Edges[Abs(LEdgeNum)];
    // if this edge is already checked
    if LEdge.CheckCount = FCounter.Value then
      Continue;
    // can never collide with internal edges
    if LEdge.Internal <> 0 then
      Continue;
    LPl := @ATraceWork.PolygonEdgePlueckerCache[LIndex];
    // get the sides at which the trm edge vertices pass the polygon edge
    TCollisionSidedness.SetEdge(LEdge, LPl^, ATraceWork.Vertices[LTrmEdge.VertexNum[0]].Pl, LTrmEdge.VertexNum[0]);
    TCollisionSidedness.SetEdge(LEdge, LPl^, ATraceWork.Vertices[LTrmEdge.VertexNum[1]].Pl, LTrmEdge.VertexNum[1]);
    // if the trm edge start and end vertex do not pass the polygon edge at different sides
    if ((BitOf(LEdge.Side, LTrmEdge.VertexNum[0]) xor BitOf(LEdge.Side, LTrmEdge.VertexNum[1])) and 1) = 0 then
      Continue;
    // get the sides at which the polygon edge vertices pass the trm edge
    LV1 := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]];
    TCollisionSidedness.SetVertex(LV1, ATraceWork.PolygonVertexPlueckerCache[LIndex], LTrmEdge.Pl, LTrmEdge.BitNum);
    LV2 := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitNotSet(LEdgeNum)]];
    TCollisionSidedness.SetVertex(LV2, ATraceWork.PolygonVertexPlueckerCache[LIndex + 1], LTrmEdge.Pl,
      LTrmEdge.BitNum);
    // if the polygon edge start and end vertex do not pass the trm edge at different sides
    if ((LV1.Side xor LV2.Side) and TGeoMath.BitMask(LTrmEdge.BitNum)) = 0 then
      Continue;
    // if there is no possible collision between the trm edge and the polygon edge
    if not TranslateEdgeThroughEdge(LTrmEdge.Cross, LTrmEdge.Pl, LPl^, LF1) then
      Continue;
    // if moving away from edge
    if LF1 < 0 then
      Continue;

    // pluecker coordinate for epsilon expanded edge
    LEpsPl.FromLine(LModel.Vertices[LEdge.VertexNum[0]].P + LEdge.Normal * CM_CLIP_EPSILON,
      LModel.Vertices[LEdge.VertexNum[1]].P + LEdge.Normal * CM_CLIP_EPSILON);
    // calculate collision fraction with epsilon expanded edge
    if not TranslateEdgeThroughEdge(LTrmEdge.Cross, LTrmEdge.Pl, LEpsPl, LF2) then
      Continue;
    // if no collision with epsilon edge or moving away from edge
    if (LF2 > 1) or (LF1 < LF2) then
      Continue;

    if LF2 < 0 then
      LF2 := 0;

    if LF2 < ATraceWork.Trace.Fraction then
    begin
      ATraceWork.Trace.Fraction := LF2;
      // create plane with normal vector orthogonal to both the polygon edge and the trm edge
      LStart := LModel.Vertices[LEdge.VertexNum[0]].P;
      LEnd := LModel.Vertices[LEdge.VertexNum[1]].P;
      ATraceWork.Trace.C.Normal := (LEnd - LStart).Cross(LTrmEdge.EndPoint - LTrmEdge.Start);
      ATraceWork.Trace.C.Normal.NormalizeSelf;
      ATraceWork.Trace.C.Dist := ATraceWork.Trace.C.Normal.Dot(LStart);
      // make sure the collision plane faces the trace model
      if ATraceWork.Trace.C.Normal.Dot(LTrmEdge.Start) - ATraceWork.Trace.C.Dist < 0 then
      begin
        ATraceWork.Trace.C.Normal := -ATraceWork.Trace.C.Normal;
        ATraceWork.Trace.C.Dist := -ATraceWork.Trace.C.Dist;
      end;
      ATraceWork.Trace.C.Contents := APolygon.Contents;
      ATraceWork.Trace.C.Material := APolygon.Material;
      ATraceWork.Trace.C.ContactType := ctEdge;
      ATraceWork.Trace.C.ModelFeature := LEdgeNum;
      ATraceWork.Trace.C.TrmFeature := ATrmEdgeIndex;
      // calculate collision point
      LNormal.X := LTrmEdge.Cross.Z;
      LNormal.Y := -LTrmEdge.Cross.Y;
      LNormal.Z := LTrmEdge.Cross.X;
      LDist := LNormal.Dot(LTrmEdge.Start);
      LD1 := LNormal.Dot(LStart) - LDist;
      LD2 := LNormal.Dot(LEnd) - LDist;
      LF1 := LD1 / (LD1 - LD2);
      ATraceWork.Trace.C.Point := LStart + (LEnd - LStart) * LF1;
      // if retrieving contacts
      if ATraceWork.GetContacts then
        AddContact(ATraceWork);
    end;
  end;
end;

procedure TCollisionTranslator.TranslateTrmVertexThroughPolygon(ATraceWork: TCmTraceWork;
  APolygon: TCmPolygon; AVertexIndex: Integer; ABitNum: Integer);
var
  LIndex: Integer;
  LEdgeNum: Integer;
  LF: Single;
  LEdge: PCmEdge;
  LVertex: ^TCmTrmVertex;
begin
  LVertex := @ATraceWork.Vertices[AVertexIndex];
  LF := TranslationPlaneFraction(APolygon.Plane, LVertex.P, LVertex.EndP);
  if LF < ATraceWork.Trace.Fraction then
  begin
    for LIndex := 0 to APolygon.NumEdges - 1 do
    begin
      LEdgeNum := APolygon.Edges[LIndex];
      LEdge := @ATraceWork.Model.Edges[Abs(LEdgeNum)];
      TCollisionSidedness.SetEdge(LEdge, ATraceWork.PolygonEdgePlueckerCache[LIndex], LVertex.Pl, ABitNum);
      if (TGeoMath.IntSignBitSet(LEdgeNum) xor BitOf(LEdge.Side, ABitNum)) <> 0 then
        Exit;
    end;
    if LF < 0 then
      LF := 0;
    ATraceWork.Trace.Fraction := LF;
    // collision plane is the polygon plane
    ATraceWork.Trace.C.Normal := APolygon.Plane.Normal;
    ATraceWork.Trace.C.Dist := APolygon.Plane.Dist;
    ATraceWork.Trace.C.Contents := APolygon.Contents;
    ATraceWork.Trace.C.Material := APolygon.Material;
    ATraceWork.Trace.C.ContactType := ctTrmVertex;
    ATraceWork.Trace.C.ModelFeature := APolygon.Id;
    ATraceWork.Trace.C.TrmFeature := AVertexIndex;
    ATraceWork.Trace.C.Point := LVertex.P + (LVertex.EndP - LVertex.P) * ATraceWork.Trace.Fraction;
    // if retrieving contacts
    if ATraceWork.GetContacts then
    begin
      AddContact(ATraceWork);
      // no need to store the trm vertex more than once as a contact
      LVertex.Used := False;
    end;
  end;
end;

procedure TCollisionTranslator.TranslatePointThroughPolygon(ATraceWork: TCmTraceWork;
  APolygon: TCmPolygon; AVertexIndex: Integer);
var
  LIndex: Integer;
  LEdgeNum: Integer;
  LF: Single;
  LFl: Single;
  LEdge: PCmEdge;
  LPl: TGeoPluecker;
  LVertex: ^TCmTrmVertex;
begin
  LVertex := @ATraceWork.Vertices[AVertexIndex];
  LF := TranslationPlaneFraction(APolygon.Plane, LVertex.P, LVertex.EndP);
  if LF < ATraceWork.Trace.Fraction then
  begin
    for LIndex := 0 to APolygon.NumEdges - 1 do
    begin
      LEdgeNum := APolygon.Edges[LIndex];
      LEdge := @ATraceWork.Model.Edges[Abs(LEdgeNum)];
      // if we didn't yet calculate the sidedness for this edge
      if LEdge.CheckCount <> FCounter.Value then
      begin
        LEdge.CheckCount := FCounter.Value;
        LPl.FromLine(ATraceWork.Model.Vertices[LEdge.VertexNum[0]].P,
          ATraceWork.Model.Vertices[LEdge.VertexNum[1]].P);
        LFl := LVertex.Pl.PermutedInnerProduct(LPl);
        LEdge.Side := TGeoMath.FloatSignBitSet(LFl);
      end;
      // if the point passes the edge at the wrong side
      if (TGeoMath.IntSignBitSet(LEdgeNum) xor LEdge.Side) <> 0 then
        Exit;
    end;
    if LF < 0 then
      LF := 0;
    ATraceWork.Trace.Fraction := LF;
    // collision plane is the polygon plane
    ATraceWork.Trace.C.Normal := APolygon.Plane.Normal;
    ATraceWork.Trace.C.Dist := APolygon.Plane.Dist;
    ATraceWork.Trace.C.Contents := APolygon.Contents;
    ATraceWork.Trace.C.Material := APolygon.Material;
    ATraceWork.Trace.C.ContactType := ctTrmVertex;
    ATraceWork.Trace.C.ModelFeature := APolygon.Id;
    ATraceWork.Trace.C.TrmFeature := AVertexIndex;
    ATraceWork.Trace.C.Point := LVertex.P + (LVertex.EndP - LVertex.P) * ATraceWork.Trace.Fraction;
    // if retrieving contacts
    if ATraceWork.GetContacts then
    begin
      AddContact(ATraceWork);
      // no need to store the trm vertex more than once as a contact
      LVertex.Used := False;
    end;
  end;
end;

procedure TCollisionTranslator.TranslateVertexThroughTrmPolygon(ATraceWork: TCmTraceWork;
  ATrmPolyIndex: Integer; APolygon: TCmPolygon; AVertex: PCmVertex; const AEndPoint: TGeoVec3;
  const APluecker: TGeoPluecker);
var
  LIndex: Integer;
  LEdgeNum: Integer;
  LF: Single;
  LEdge: ^TCmTrmEdge;
  LTrmPoly: ^TCmTrmPolygon;
begin
  LTrmPoly := @ATraceWork.Polys[ATrmPolyIndex];
  LF := TranslationPlaneFraction(LTrmPoly.Plane, AVertex.P, AEndPoint);
  if LF < ATraceWork.Trace.Fraction then
  begin
    for LIndex := 0 to LTrmPoly.NumEdges - 1 do
    begin
      LEdgeNum := LTrmPoly.Edges[LIndex];
      LEdge := @ATraceWork.Edges[Abs(LEdgeNum)];

      TCollisionSidedness.SetVertex(AVertex, APluecker, LEdge.Pl, LEdge.BitNum);
      if (TGeoMath.IntSignBitSet(LEdgeNum) xor BitOf(AVertex.Side, LEdge.BitNum)) <> 0 then
        Exit;
    end;
    if LF < 0 then
      LF := 0;
    ATraceWork.Trace.Fraction := LF;
    // collision plane is the inverse trm polygon plane
    ATraceWork.Trace.C.Normal := -LTrmPoly.Plane.Normal;
    ATraceWork.Trace.C.Dist := -LTrmPoly.Plane.Dist;
    ATraceWork.Trace.C.Contents := APolygon.Contents;
    ATraceWork.Trace.C.Material := APolygon.Material;
    ATraceWork.Trace.C.ContactType := ctModelVertex;
    ATraceWork.Trace.C.ModelFeature := Integer((NativeInt(AVertex) - NativeInt(@ATraceWork.Model.Vertices[0])) div
      SizeOf(TCmVertex));
    ATraceWork.Trace.C.TrmFeature := ATrmPolyIndex;
    ATraceWork.Trace.C.Point := AVertex.P + (AEndPoint - AVertex.P) * ATraceWork.Trace.Fraction;
    // if retrieving contacts
    if ATraceWork.GetContacts then
      AddContact(ATraceWork);
  end;
end;

function TCollisionTranslator.TranslateTrmThroughPolygon(ATraceWork: TCmTraceWork;
  APolygon: TCmPolygon): Boolean;
var
  LI: Integer;
  LJ: Integer;
  LK: Integer;
  LEdgeNum: Integer;
  LFraction: Single;
  LD: Single;
  LEndPoint: TGeoVec3;
  LPl: PGeoPluecker;
  LEdge: PCmEdge;
  LVertex: PCmVertex;
  LModel: TCollisionModel;
begin
  LModel := ATraceWork.Model;
  // if already checked this polygon
  if APolygon.CheckCount = FCounter.Value then
    Exit(False);
  APolygon.CheckCount := FCounter.Value;

  // if this polygon does not have the right contents behind it
  if (APolygon.Contents and ATraceWork.Contents) = 0 then
    Exit(False);

  // if the the trace bounds do not intersect the polygon bounds
  if not ATraceWork.Bounds.IntersectsBounds(APolygon.Bounds) then
    Exit(False);

  // only collide with the polygon if approaching at the front
  if APolygon.Plane.Normal.Dot(ATraceWork.Dir) > 0 then
    Exit(False);

  // if the polygon is too far from the first heart plane
  LD := APolygon.Bounds.PlaneDistance(ATraceWork.HeartPlane1);
  if TGeoMath.Fabs(LD) > ATraceWork.MaxDistFromHeartPlane1 then
    Exit(False);

  // if the polygon is too far from the second heart plane
  LD := APolygon.Bounds.PlaneDistance(ATraceWork.HeartPlane2);
  if TGeoMath.Fabs(LD) > ATraceWork.MaxDistFromHeartPlane2 then
    Exit(False);
  LFraction := ATraceWork.Trace.Fraction;

  // fast point trace
  if ATraceWork.PointTrace then
    TranslatePointThroughPolygon(ATraceWork, APolygon, 0)
  else
  begin
    // trace bounds should cross polygon plane
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

    // calculate pluecker coordinates for the polygon edges and polygon vertices
    for LI := 0 to APolygon.NumEdges - 1 do
    begin
      LEdgeNum := APolygon.Edges[LI];
      LEdge := @LModel.Edges[Abs(LEdgeNum)];
      // reset sidedness cache if this is the first time we encounter this edge during this trace
      if LEdge.CheckCount <> FCounter.Value then
        LEdge.SideSet := 0;
      // pluecker coordinate for edge
      ATraceWork.PolygonEdgePlueckerCache[LI].FromLine(LModel.Vertices[LEdge.VertexNum[0]].P,
        LModel.Vertices[LEdge.VertexNum[1]].P);

      LVertex := @LModel.Vertices[LEdge.VertexNum[TGeoMath.IntSignBitSet(LEdgeNum)]];
      // reset sidedness cache if this is the first time we encounter this vertex during this trace
      if LVertex.CheckCount <> FCounter.Value then
        LVertex.SideSet := 0;
      // pluecker coordinate for vertex movement vector
      ATraceWork.PolygonVertexPlueckerCache[LI].FromRay(LVertex.P, -ATraceWork.Dir);
    end;
    // copy first to last so we can easily cycle through for the edges
    ATraceWork.PolygonVertexPlueckerCache[APolygon.NumEdges] := ATraceWork.PolygonVertexPlueckerCache[0];

    // trace trm vertices through polygon
    for LI := 0 to ATraceWork.NumVerts - 1 do
      if ATraceWork.Vertices[LI].Used then
        TranslateTrmVertexThroughPolygon(ATraceWork, APolygon, LI, LI);

    // trace trm edges through polygon
    for LI := 1 to ATraceWork.NumEdges do
      if ATraceWork.Edges[LI].Used then
        TranslateTrmEdgeThroughPolygon(ATraceWork, APolygon, LI);

    // trace all polygon vertices through the trm
    for LI := 0 to APolygon.NumEdges - 1 do
    begin
      LEdgeNum := APolygon.Edges[LI];
      LEdge := @LModel.Edges[Abs(LEdgeNum)];

      if LEdge.CheckCount = FCounter.Value then
        Continue;
      // set edge check count
      LEdge.CheckCount := FCounter.Value;
      // can never collide with internal edges
      if LEdge.Internal <> 0 then
        Continue;
      // got to check both vertices because we skip internal edges
      for LK := 0 to 1 do
      begin
        LVertex := @LModel.Vertices[LEdge.VertexNum[LK xor Integer(TGeoMath.IntSignBitSet(LEdgeNum))]];
        // if this vertex is already checked
        if LVertex.CheckCount = FCounter.Value then
          Continue;
        // set vertex check count
        LVertex.CheckCount := FCounter.Value;

        // if the vertex is outside the trace bounds
        if not ATraceWork.Bounds.ContainsPoint(LVertex.P) then
          Continue;

        // vertex end point after movement
        LEndPoint := LVertex.P - ATraceWork.Dir;
        // pluecker coordinate for vertex movement vector
        LPl := @ATraceWork.PolygonVertexPlueckerCache[LI + LK];

        for LJ := 0 to ATraceWork.NumPolys - 1 do
          if ATraceWork.Polys[LJ].Used then
            TranslateVertexThroughTrmPolygon(ATraceWork, LJ, APolygon, LVertex, LEndPoint, LPl^);
      end;
    end;
  end;

  // if there was a collision with this polygon and we are not retrieving contacts
  if (ATraceWork.Trace.Fraction < LFraction) and (not ATraceWork.GetContacts) then
  begin
    LFraction := ATraceWork.Trace.Fraction;
    LEndPoint := ATraceWork.Start + ATraceWork.Dir * LFraction;
    // decrease bounds
    for LI := 0 to 2 do
      if ATraceWork.Start[LI] < LEndPoint[LI] then
      begin
        ATraceWork.Bounds.Mins[LI] := ATraceWork.Start[LI] + ATraceWork.Size.Mins[LI] - CM_BOX_EPSILON;
        ATraceWork.Bounds.Maxs[LI] := LEndPoint[LI] + ATraceWork.Size.Maxs[LI] + CM_BOX_EPSILON;
      end
      else
      begin
        ATraceWork.Bounds.Mins[LI] := LEndPoint[LI] + ATraceWork.Size.Mins[LI] - CM_BOX_EPSILON;
        ATraceWork.Bounds.Maxs[LI] := ATraceWork.Start[LI] + ATraceWork.Size.Maxs[LI] + CM_BOX_EPSILON;
      end;
  end;

  Result := ATraceWork.Trace.Fraction = 0;
end;

end.
