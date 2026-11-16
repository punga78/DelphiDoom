{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - vertices and edges of a model               }
{                                                                              }
{  Port of cm_vertex_t and cm_edge_t of CollisionModel_local.h, Doom 3 GPL     }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Model.Types;

interface

uses
  DelphiDoom.Geometry.Vec3;

type
  /// <summary>A vertex of a collision model (cm_vertex_t)</summary>
  TCmVertex = record
    /// <summary>vertex point</summary>
    P: TGeoVec3;
    /// <summary>for multi-check avoidance</summary>
    CheckCount: Integer;
    /// <summary>each bit tells at which side this vertex passes one of the trace model edges</summary>
    Side: Cardinal;
    /// <summary>each bit tells if sidedness for the trace model edge has been calculated yet</summary>
    SideSet: Cardinal;
  end;

  PCmVertex = ^TCmVertex;

  /// <summary>An edge of a collision model (cm_edge_t). Edge 0 of a model is a dummy</summary>
  TCmEdge = record
    /// <summary>for multi-check avoidance</summary>
    CheckCount: Integer;
    /// <summary>a trace model can never collide with internal edges</summary>
    Internal: Word;
    /// <summary>number of polygons using this edge</summary>
    NumUsers: Word;
    /// <summary>each bit tells at which side of this edge one of the trace model vertices passes</summary>
    Side: Cardinal;
    /// <summary>each bit tells if sidedness for the trace model vertex has been calculated yet</summary>
    SideSet: Cardinal;
    /// <summary>start and end point of edge</summary>
    VertexNum: array[0..1] of Integer;
    /// <summary>edge normal</summary>
    Normal: TGeoVec3;
  end;

  PCmEdge = ^TCmEdge;

implementation

end.
