{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - removal of unused vertices and edges        }
{                                                                              }
{  Port of RemapEdges and OptimizeArrays of CollisionModel_load.cpp, Doom 3    }
{  GPL Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media   }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.Optimizer;

interface

uses
  DelphiDoom.Collision.Model;

type
  /// <summary>Compacts the vertex and edge arrays of a model</summary>
  TCollisionArrayOptimizer = class sealed
  public
    /// <summary>
    ///   Removes the vertices that no edge uses and the edges with no user, and renumbers the
    ///   edges of the polygons (OptimizeArrays). The arrays end with exactly NumVertices
    ///   and NumEdges items, as the C++ code reallocates them.
    /// </summary>
    class procedure Optimize(AModel: TCollisionModel); static;
  end;

implementation

uses
  DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon;

{ TCollisionArrayOptimizer }

class procedure TCollisionArrayOptimizer.Optimize(AModel: TCollisionModel);
var
  LRemap: TArray<Integer>;
  LIndex: Integer;
  LNewNumVertices: Integer;
  LNewNumEdges: Integer;
  LPolygon: TCmPolygon;
  LEdgeIndex: Integer;
  LEdgeNum: Integer;
begin
  if AModel.NumVertices > AModel.NumEdges then
    SetLength(LRemap, AModel.NumVertices)
  else
    SetLength(LRemap, AModel.NumEdges);
  // get all used vertices
  for LIndex := 0 to AModel.NumEdges - 1 do
  begin
    LRemap[AModel.Edges[LIndex].VertexNum[0]] := 1;
    LRemap[AModel.Edges[LIndex].VertexNum[1]] := 1;
  end;
  // create remap index and move vertices
  LNewNumVertices := 0;
  for LIndex := 0 to AModel.NumVertices - 1 do
    if LRemap[LIndex] <> 0 then
    begin
      LRemap[LIndex] := LNewNumVertices;
      AModel.Vertices[LNewNumVertices] := AModel.Vertices[LIndex];
      Inc(LNewNumVertices);
    end;
  AModel.NumVertices := LNewNumVertices;
  // change edge vertex indexes
  for LIndex := 1 to AModel.NumEdges - 1 do
  begin
    AModel.Edges[LIndex].VertexNum[0] := LRemap[AModel.Edges[LIndex].VertexNum[0]];
    AModel.Edges[LIndex].VertexNum[1] := LRemap[AModel.Edges[LIndex].VertexNum[1]];
  end;

  // create remap index and move edges
  LNewNumEdges := 1;
  for LIndex := 1 to AModel.NumEdges - 1 do
    // if the edge is used
    if AModel.Edges[LIndex].NumUsers <> 0 then
    begin
      LRemap[LIndex] := LNewNumEdges;
      AModel.Edges[LNewNumEdges] := AModel.Edges[LIndex];
      Inc(LNewNumEdges);
    end;
  // change polygon edge indexes
  for LPolygon in AModel.TreePolygons do
    for LEdgeIndex := 0 to LPolygon.NumEdges - 1 do
    begin
      LEdgeNum := LPolygon.Edges[LEdgeIndex];
      if LEdgeNum < 0 then
        LPolygon.Edges[LEdgeIndex] := -LRemap[Abs(LEdgeNum)]
      else
        LPolygon.Edges[LEdgeIndex] := LRemap[LEdgeNum];
    end;
  AModel.NumEdges := LNewNumEdges;

  // realloc vertices and edges
  SetLength(AModel.Vertices, AModel.NumVertices);
  SetLength(AModel.Edges, AModel.NumEdges);
end;

end.
