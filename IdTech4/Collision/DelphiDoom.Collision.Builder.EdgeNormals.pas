{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - edge normals                                }
{                                                                              }
{  Port of CalculateEdgeNormals of CollisionModel_load.cpp, Doom 3 GPL Source  }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Builder.EdgeNormals;

interface

uses
  DelphiDoom.Collision.Model;

type
  /// <summary>Computes the normal of every edge of a model from the polygons that use it</summary>
  TCollisionEdgeNormals = class sealed
  public
    /// <summary>
    ///   Polygons are visited in the order of the tree walk (as the C++ code does): an edge used
    ///   by one polygon points out of it, an edge shared by two gets the average of the two
    ///   normals, or a long normal pointing out of both when they make a very sharp edge.
    ///   Increments the model's sharp edge counter. The checkcount of the C++ code is not
    ///   needed: every polygon is visited once.
    /// </summary>
    class procedure Calculate(AModel: TCollisionModel); static;
  end;

implementation

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Collision.Types, DelphiDoom.Collision.Model.Types,
  DelphiDoom.Collision.Model.Polygon;

{ TCollisionEdgeNormals }

class procedure TCollisionEdgeNormals.Calculate(AModel: TCollisionModel);
var
  LPolygon: TCmPolygon;
  LIndex: Integer;
  LEdgeNum: Integer;
  LEdge: PCmEdge;
  LDot: Single;
  LScale: Single;
  LDir: TGeoVec3;
  LPolyNormal: TGeoVec3;
  LFrom: Integer;
  LTo: Integer;
begin
  for LPolygon in AModel.TreePolygons do
  begin
    LPolyNormal := LPolygon.Plane.Normal;
    for LIndex := 0 to LPolygon.NumEdges - 1 do
    begin
      LEdgeNum := LPolygon.Edges[LIndex];
      LEdge := @AModel.Edges[Abs(LEdgeNum)];
      if (LEdge.Normal.X = 0) and (LEdge.Normal.Y = 0) and (LEdge.Normal.Z = 0) then
      begin
        // if the edge is only used by this polygon
        if LEdge.NumUsers = 1 then
        begin
          if LEdgeNum < 0 then
            LFrom := 1
          else
            LFrom := 0;
          if LEdgeNum > 0 then
            LTo := 1
          else
            LTo := 0;
          LDir := AModel.Vertices[LEdge.VertexNum[LFrom]].P - AModel.Vertices[LEdge.VertexNum[LTo]].P;
          LEdge.Normal := LPolyNormal.Cross(LDir);
          LEdge.Normal.NormalizeSelf;
        end
        else
          // the edge is used by more than one polygon
          LEdge.Normal := LPolyNormal;
      end
      else
      begin
        LDot := LEdge.Normal.Dot(LPolyNormal);
        // if the two planes make a very sharp edge
        if LDot < SHARP_EDGE_DOT then
        begin
          // max length normal pointing outside both polygons
          if LEdgeNum > 0 then
            LFrom := 1
          else
            LFrom := 0;
          if LEdgeNum < 0 then
            LTo := 1
          else
            LTo := 0;
          LDir := AModel.Vertices[LEdge.VertexNum[LFrom]].P - AModel.Vertices[LEdge.VertexNum[LTo]].P;
          LEdge.Normal := LEdge.Normal.Cross(LDir) + LPolyNormal.Cross(-LDir);
          LEdge.Normal := LEdge.Normal * ((0.5 / (0.5 + 0.5 * SHARP_EDGE_DOT)) / LEdge.Normal.Length);
          Inc(AModel.NumSharpEdges);
        end
        else
        begin
          LScale := 0.5 / (0.5 + 0.5 * LDot);
          LEdge.Normal := (LEdge.Normal + LPolyNormal) * LScale;
        end;
      end;
    end;
  end;
end;

end.
