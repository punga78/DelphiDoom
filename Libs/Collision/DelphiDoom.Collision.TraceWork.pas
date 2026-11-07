{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the data of one trace                       }
{                                                                              }
{  Port of cm_traceWork_t (CollisionModel_local.h) and of SetupTrm and         }
{  SetupTranslationHeartPlanes (CollisionModel_translate.cpp), Doom 3 GPL      }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3). The fields of the   }
{  rotational collision (rotation origin, axis, angle, rotation bounds) are    }
{  not ported.                                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.TraceWork;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Pluecker, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Model;

type
  /// <summary>A vertex of the moving trace model (cm_trmVertex_t)</summary>
  TCmTrmVertex = record
    /// <summary>true if this vertex is used for collision detection</summary>
    Used: Boolean;
    /// <summary>vertex position</summary>
    P: TGeoVec3;
    /// <summary>end point of vertex after movement</summary>
    EndP: TGeoVec3;
    /// <summary>pluecker coordinate for vertex movement</summary>
    Pl: TGeoPluecker;
  end;

  /// <summary>An edge of the moving trace model (cm_trmEdge_t)</summary>
  TCmTrmEdge = record
    Used: Boolean;
    Start: TGeoVec3;
    EndPoint: TGeoVec3;
    /// <summary>indexes into the vertices of the trace work</summary>
    VertexNum: array[0..1] of Integer;
    /// <summary>pluecker coordinate for edge</summary>
    Pl: TGeoPluecker;
    /// <summary>(z,-y,x) of cross product between edge dir and movement dir</summary>
    Cross: TGeoVec3;
    /// <summary>vertex bit number</summary>
    BitNum: Word;
  end;

  /// <summary>A polygon of the moving trace model (cm_trmPolygon_t)</summary>
  TCmTrmPolygon = record
    Used: Boolean;
    Plane: TGeoPlane;
    NumEdges: Integer;
    /// <summary>signed index into the edges of the trace work</summary>
    Edges: array[0..MAX_TRACEMODEL_POLYEDGES - 1] of Integer;
  end;

  /// <summary>
  ///   Data used during collision detection calculations (cm_traceWork_t). One instance is
  ///   made for each trace (the C++ code keeps a static one). Everything the calculation
  ///   needs besides the model is here, so nothing is global
  /// </summary>
  TCmTraceWork = class
  public
    NumVerts: Integer;
    Vertices: array[0..MAX_TRACEMODEL_VERTS - 1] of TCmTrmVertex;
    NumEdges: Integer;
    Edges: array[0..MAX_TRACEMODEL_EDGES] of TCmTrmEdge;
    NumPolys: Integer;
    Polys: array[0..MAX_TRACEMODEL_POLYS - 1] of TCmTrmPolygon;
    /// <summary>model colliding with, not owned</summary>
    Model: TCollisionModel;
    /// <summary>start of trace</summary>
    Start: TGeoVec3;
    /// <summary>end of trace</summary>
    EndPoint: TGeoVec3;
    /// <summary>trace direction</summary>
    Dir: TGeoVec3;
    /// <summary>bounds of full trace</summary>
    Bounds: TGeoBounds;
    /// <summary>bounds of transformed trm relative to start</summary>
    Size: TGeoBounds;
    /// <summary>largest of abs(size[0]) and abs(size[1]) for BSP trace</summary>
    Extents: TGeoVec3;
    /// <summary>ignore polygons that do not have any of these contents flags</summary>
    Contents: Integer;
    /// <summary>collision detection result</summary>
    Trace: TCollisionTrace;
    /// <summary>true if only tracing a point</summary>
    PointTrace: Boolean;
    /// <summary>true if not tracing but doing a position test</summary>
    PositionTest: Boolean;
    /// <summary>true if the trace model is convex</summary>
    IsConvex: Boolean;
    /// <summary>true if retrieving contacts</summary>
    GetContacts: Boolean;
    /// <summary>set to quickly stop the collision detection calculations</summary>
    QuickExit: Boolean;
    /// <summary>contacts found (replaces the caller's array and the maximum)</summary>
    Contacts: TList<TContactInfo>;
    MaxContacts: Integer;
    /// <summary>polygons should be near enough the trace heart planes</summary>
    HeartPlane1: TGeoPlane;
    MaxDistFromHeartPlane1: Single;
    HeartPlane2: TGeoPlane;
    MaxDistFromHeartPlane2: Single;
    PolygonEdgePlueckerCache: array[0..CM_MAX_POLYGON_EDGES - 1] of TGeoPluecker;
    PolygonVertexPlueckerCache: array[0..CM_MAX_POLYGON_EDGES] of TGeoPluecker;

    constructor Create;
    /// <summary>Copies the vertices, edges and polygons of the trace model (SetupTrm)</summary>
    procedure SetupTrm(ATrm: TTraceModel);
    /// <summary>Planes through the start, orthogonal to each other and to the movement (SetupTranslationHeartPlanes)</summary>
    procedure SetupTranslationHeartPlanes;
  end;

implementation

{ TCmTraceWork }

constructor TCmTraceWork.Create;
begin
  inherited Create;
  Bounds.Clear;
  Size.Clear;
end;

procedure TCmTraceWork.SetupTrm(ATrm: TTraceModel);
var
  LIndex: Integer;
  LEdge: Integer;
begin
  // vertices
  NumVerts := ATrm.NumVerts;
  for LIndex := 0 to ATrm.NumVerts - 1 do
  begin
    Vertices[LIndex].P := ATrm.Verts[LIndex];
    Vertices[LIndex].Used := False;
  end;
  // edges
  NumEdges := ATrm.NumEdges;
  for LIndex := 1 to ATrm.NumEdges do
  begin
    Edges[LIndex].VertexNum[0] := ATrm.Edges[LIndex].V[0];
    Edges[LIndex].VertexNum[1] := ATrm.Edges[LIndex].V[1];
    Edges[LIndex].Used := False;
  end;
  // polygons
  NumPolys := ATrm.NumPolys;
  for LIndex := 0 to ATrm.NumPolys - 1 do
  begin
    Polys[LIndex].NumEdges := ATrm.Polys[LIndex].NumEdges;
    for LEdge := 0 to ATrm.Polys[LIndex].NumEdges - 1 do
      Polys[LIndex].Edges[LEdge] := ATrm.Polys[LIndex].Edges[LEdge];
    Polys[LIndex].Plane.SetNormal(ATrm.Polys[LIndex].Normal);
    Polys[LIndex].Used := False;
  end;
  // is the trace model convex or not
  IsConvex := ATrm.IsConvex;
end;

procedure TCmTraceWork.SetupTranslationHeartPlanes;
var
  LDir: TGeoVec3;
  LNormal1: TGeoVec3;
  LNormal2: TGeoVec3;
begin
  // calculate trace heart planes
  LDir := Dir;
  LDir.NormalizeSelf;
  LDir.NormalVectors(LNormal1, LNormal2);
  HeartPlane1.SetNormal(LNormal1);
  HeartPlane1.FitThroughPoint(Start);
  HeartPlane2.SetNormal(LNormal2);
  HeartPlane2.FitThroughPoint(Start);
end;

end.
