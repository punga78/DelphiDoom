{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - a trace model from a collision model        }
{                                                                              }
{  Port of TrmFromModel_r and TrmFromModel of CollisionModel_load.cpp, Doom 3  }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.TrmExtractor;

interface

uses
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Logging.Intf, DelphiDoom.Collision.Model;

type
  /// <summary>Turns a small closed collision model into a trace model</summary>
  TCollisionTrmExtractor = class sealed
  public
    /// <summary>
    ///   Fills ATrm from the model; false (with a message in ALog, which may be nil) when
    ///   the model has too many vertices, edges or polygons or is not an enclosed hull.
    ///   Polygon merging could leave dangling edges: the hull test catches them
    /// </summary>
    class function Extract(AModel: TCollisionModel; ATrm: TTraceModel; const ALog: ILog): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.Model.Polygon;

resourcestring
  STooManyVertices = 'TCollisionTrmExtractor: model %s has too many vertices.';
  STooManyEdges = 'TCollisionTrmExtractor: model %s has too many edges.';
  STooManyPolygons = 'TCollisionTrmExtractor: model %s has too many polygons.';
  SDanglingEdges =
    'TCollisionTrmExtractor: model %s has dangling edges, the model has to be an enclosed hull.';

{ TCollisionTrmExtractor }

class function TCollisionTrmExtractor.Extract(AModel: TCollisionModel; ATrm: TTraceModel;
  const ALog: ILog): Boolean;
var
  LIndex: Integer;
  LJ: Integer;
  LPolygon: TCmPolygon;
  LNumEdgeUsers: array[0..MAX_TRACEMODEL_EDGES] of Integer;

  procedure Say(const AText: string);
  begin
    if Assigned(ALog) then
      ALog.Info(AText + #10);
  end;

begin
  Result := False;
  // if the model has too many vertices to fit in a trace model
  if AModel.NumVertices > MAX_TRACEMODEL_VERTS then
  begin
    Say(Format(STooManyVertices, [AModel.Name]));
    Exit;
  end;

  // plus one because the collision model accounts for the first unused edge
  if AModel.NumEdges > MAX_TRACEMODEL_EDGES + 1 then
  begin
    Say(Format(STooManyEdges, [AModel.Name]));
    Exit;
  end;

  ATrm.Kind := tmkCustom;
  ATrm.NumVerts := 0;
  ATrm.NumEdges := 1;
  ATrm.NumPolys := 0;
  ATrm.Bounds.Clear;

  // copy polygons
  for LPolygon in AModel.TreePolygons do
  begin
    if ATrm.NumPolys >= MAX_TRACEMODEL_POLYS then
    begin
      Say(Format(STooManyPolygons, [AModel.Name]));
      Exit;
    end;
    // copy polygon properties
    ATrm.Polys[ATrm.NumPolys].Bounds := LPolygon.Bounds;
    ATrm.Polys[ATrm.NumPolys].Normal := LPolygon.Plane.Normal;
    ATrm.Polys[ATrm.NumPolys].Dist := LPolygon.Plane.Dist;
    ATrm.Polys[ATrm.NumPolys].NumEdges := LPolygon.NumEdges;
    // copy edge index
    for LIndex := 0 to LPolygon.NumEdges - 1 do
      ATrm.Polys[ATrm.NumPolys].Edges[LIndex] := LPolygon.Edges[LIndex];
    Inc(ATrm.NumPolys);
  end;

  // copy vertices
  for LIndex := 0 to AModel.NumVertices - 1 do
  begin
    ATrm.Verts[LIndex] := AModel.Vertices[LIndex].P;
    ATrm.Bounds.AddPoint(ATrm.Verts[LIndex]);
  end;
  ATrm.NumVerts := AModel.NumVertices;

  // copy edges
  for LIndex := 0 to AModel.NumEdges - 1 do
  begin
    ATrm.Edges[LIndex].V[0] := AModel.Edges[LIndex].VertexNum[0];
    ATrm.Edges[LIndex].V[1] := AModel.Edges[LIndex].VertexNum[1];
  end;
  // minus one because the collision model accounts for the first unused edge
  ATrm.NumEdges := AModel.NumEdges - 1;

  // each edge should be used exactly twice
  FillChar(LNumEdgeUsers, SizeOf(LNumEdgeUsers), 0);
  for LIndex := 0 to ATrm.NumPolys - 1 do
    for LJ := 0 to ATrm.Polys[LIndex].NumEdges - 1 do
      Inc(LNumEdgeUsers[Abs(ATrm.Polys[LIndex].Edges[LJ])]);
  for LIndex := 1 to ATrm.NumEdges do
    if LNumEdgeUsers[LIndex] <> 2 then
    begin
      Say(Format(SDanglingEdges, [AModel.Name]));
      Exit;
    end;

  // assume convex
  ATrm.IsConvex := True;
  // check if really convex
  for LIndex := 0 to ATrm.NumPolys - 1 do
  begin
    // to be convex no vertices should be in front of any polygon plane
    for LJ := 0 to ATrm.NumVerts - 1 do
      if ATrm.Polys[LIndex].Normal.Dot(ATrm.Verts[LJ]) - ATrm.Polys[LIndex].Dist > 0.01 then
      begin
        ATrm.IsConvex := False;
        Break;
      end;
    if not ATrm.IsConvex then
      Break;
  end;

  // offset to center of model
  ATrm.Offset := ATrm.Bounds.GetCenter;

  ATrm.GenerateEdgeNormals;
  Result := True;
end;

end.
