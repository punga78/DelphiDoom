{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - shared vertices and edges while building    }
{                                                                              }
{  Port of SetupHash, ClearHash, HashVec, GetVertex and GetEdge of             }
{  CollisionModel_load.cpp, Doom 3 GPL Source Code.                            }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.Table;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Collision.HashIndex,
  DelphiDoom.Collision.Model;

type
  /// <summary>
  ///   Keeps the vertices and the edges of a model unique while polygons are added: two
  ///   points closer than VERTEX_EPSILON are one vertex, an edge used in the opposite direction
  ///   by a second polygon is shared (negative edge number). The hash tables of the C++ code
  ///   (cm_vertexHash, cm_edgeHash, cm_modelBounds) are fields here, not globals.
  /// </summary>
  TCollisionGeometryTable = class
  private
    FModel: TCollisionModel;
    FVertexHash: TCmHashIndex;
    FEdgeHash: TCmHashIndex;
    FModelBounds: TGeoBounds;
    function HashVec(const AVector: TGeoVec3): Integer;
  public
    /// <summary>The model is not owned</summary>
    constructor Create(AModel: TCollisionModel);
    destructor Destroy; override;
    /// <summary>Forgets every vertex and edge, to start another model (idCollisionModelManagerLocal::ClearHash)</summary>
    procedure Clear(const ABounds: TGeoBounds);
    /// <summary>The number of the vertex at that point; true when it already existed (GetVertex)</summary>
    function GetVertex(const AVertex: TGeoVec3; out AVertexNum: Integer): Boolean;
    /// <summary>
    ///   The signed number of the edge from AV1 to AV2, 0 when both points are the same vertex;
    ///   true when the edge or the vertices already existed (GetEdge). AV1Num is the vertex
    ///   number of AV1 when known, else -1
    /// </summary>
    function GetEdge(const AV1, AV2: TGeoVec3; out AEdgeNum: Integer; AV1Num: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.Geometry.FloatMath, DelphiDoom.Collision.Types;

/// <summary>C++ "n >> 2" on a signed int: an arithmetic shift (Delphi's shr is logical)</summary>
function ShiftRightTwo(AValue: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr 2
  else
    Result := not ((not AValue) shr 2);
end;

{ TCollisionGeometryTable }

constructor TCollisionGeometryTable.Create(AModel: TCollisionModel);
begin
  inherited Create;
  FModel := AModel;
  FVertexHash := TCmHashIndex.Create(VERTEX_HASH_SIZE, 1024);
  FEdgeHash := TCmHashIndex.Create(EDGE_HASH_SIZE, 1024);
end;

destructor TCollisionGeometryTable.Destroy;
begin
  FEdgeHash.Free;
  FVertexHash.Free;
  inherited Destroy;
end;

procedure TCollisionGeometryTable.Clear(const ABounds: TGeoBounds);
begin
  FVertexHash.Clear;
  FEdgeHash.Clear;
  FModelBounds := ABounds;
end;

function TCollisionGeometryTable.HashVec(const AVector: TGeoVec3): Integer;
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
begin
  // the C++ code works in double here: "vec[0] - bounds.x + 0.5" with a double constant
  LX := ShiftRightTwo(Trunc(Double(AVector.X) - FModelBounds.Mins.X + 0.5) + 2);
  LY := ShiftRightTwo(Trunc(Double(AVector.Y) - FModelBounds.Mins.Y + 0.5) + 2);
  LZ := ShiftRightTwo(Trunc(Double(AVector.Z) - FModelBounds.Mins.Z + 0.5) + 2);
  Result := (LX + LY * VERTEX_HASH_BOXSIZE + LZ) and (VERTEX_HASH_SIZE - 1);
end;

function TCollisionGeometryTable.GetVertex(const AVertex: TGeoVec3; out AVertexNum: Integer): Boolean;
var
  LAxis: Integer;
  LVert: TGeoVec3;
  LHashKey: Integer;
  LVn: Integer;
  LPoint: PGeoVec3;
begin
  for LAxis := 0 to 2 do
    if TGeoMath.Fabs(AVertex[LAxis] - TGeoMath.Rint(AVertex[LAxis])) < INTEGRAL_EPSILON then
      LVert[LAxis] := TGeoMath.Rint(AVertex[LAxis])
    else
      LVert[LAxis] := AVertex[LAxis];

  LHashKey := HashVec(LVert);

  LVn := FVertexHash.First(LHashKey);
  while LVn >= 0 do
  begin
    LPoint := @FModel.Vertices[LVn].P;
    // first compare z-axis because hash is based on x-y plane
    if (TGeoMath.Fabs(LVert.Z - LPoint.Z) < VERTEX_EPSILON) and
      (TGeoMath.Fabs(LVert.X - LPoint.X) < VERTEX_EPSILON) and
      (TGeoMath.Fabs(LVert.Y - LPoint.Y) < VERTEX_EPSILON) then
    begin
      AVertexNum := LVn;
      Exit(True);
    end;
    LVn := FVertexHash.Next(LVn);
  end;

  FModel.EnsureVertexCapacity(FModel.NumVertices + 1);
  FModel.Vertices[FModel.NumVertices].P := LVert;
  FModel.Vertices[FModel.NumVertices].CheckCount := 0;
  AVertexNum := FModel.NumVertices;
  // add vertex to hash
  FVertexHash.Add(LHashKey, FModel.NumVertices);
  Inc(FModel.NumVertices);
  Result := False;
end;

function TCollisionGeometryTable.GetEdge(const AV1, AV2: TGeoVec3; out AEdgeNum: Integer;
  AV1Num: Integer): Boolean;
var
  LV2Num: Integer;
  LHashKey: Integer;
  LEdge: Integer;
  LFound: Boolean;
  LV2Found: Boolean;
begin
  AEdgeNum := 0;
  // the first edge is a dummy
  if FModel.NumEdges = 0 then
    FModel.NumEdges := 1;

  if AV1Num <> -1 then
    LFound := True
  else
    LFound := GetVertex(AV1, AV1Num);
  LV2Found := GetVertex(AV2, LV2Num);
  LFound := LFound and LV2Found;
  // if both vertices are the same or snapped onto each other
  if AV1Num = LV2Num then
  begin
    AEdgeNum := 0;
    Exit(True);
  end;
  LHashKey := FEdgeHash.GenerateKey(AV1Num, LV2Num);
  // if both vertices where already stored
  if LFound then
  begin
    LEdge := FEdgeHash.First(LHashKey);
    while LEdge >= 0 do
    begin
      // NOTE: only allow at most two users that use the edge in opposite direction
      if FModel.Edges[LEdge].NumUsers = 1 then
        if (FModel.Edges[LEdge].VertexNum[0] = LV2Num) and (FModel.Edges[LEdge].VertexNum[1] = AV1Num) then
        begin
          // negative for a reversed edge
          AEdgeNum := -LEdge;
          Break;
        end;
      LEdge := FEdgeHash.Next(LEdge);
    end;
    // if edge found in hash
    if LEdge >= 0 then
    begin
      Inc(FModel.Edges[LEdge].NumUsers);
      Exit(True);
    end;
  end;
  FModel.EnsureEdgeCapacity(FModel.NumEdges + 1);
  // setup edge
  FModel.Edges[FModel.NumEdges].VertexNum[0] := AV1Num;
  FModel.Edges[FModel.NumEdges].VertexNum[1] := LV2Num;
  FModel.Edges[FModel.NumEdges].Internal := 0;
  FModel.Edges[FModel.NumEdges].CheckCount := 0;
  FModel.Edges[FModel.NumEdges].NumUsers := 1; // used by one polygon atm
  FModel.Edges[FModel.NumEdges].Normal.Zero;
  AEdgeNum := FModel.NumEdges;
  // add edge to hash
  FEdgeHash.Add(LHashKey, FModel.NumEdges);
  Inc(FModel.NumEdges);
  Result := False;
end;

end.
