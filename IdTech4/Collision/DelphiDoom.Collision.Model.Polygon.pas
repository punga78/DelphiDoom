{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the polygon of a model                      }
{                                                                              }
{  Port of cm_polygon_t of CollisionModel_local.h, Doom 3 GPL Source Code.     }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Model.Polygon;

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Collision.Types;

type
  /// <summary>
  ///   A polygon of a collision model. Owned by the model; the nodes of the BSP only refer to it.
  ///   The variable sized array of the C++ struct is a dynamic array
  /// </summary>
  TCmPolygon = class
  public
    /// <summary>polygon bounds</summary>
    Bounds: TGeoBounds;
    /// <summary>for multi-check avoidance</summary>
    CheckCount: Integer;
    /// <summary>contents behind polygon</summary>
    Contents: Integer;
    /// <summary>material, not owned</summary>
    Material: TCollisionMaterial;
    /// <summary>polygon plane</summary>
    Plane: TGeoPlane;
    /// <summary>signed indexes into the edge list of the model (negative: reversed)</summary>
    Edges: TArray<Integer>;
    /// <summary>
    ///   Number given by the model: it stands in for the address that the C++ code stores in
    ///   the contact "modelFeature" of a polygon hit
    /// </summary>
    Id: Integer;
    function NumEdges: Integer;
  end;

implementation

{ TCmPolygon }

function TCmPolygon.NumEdges: Integer;
begin
  Result := Length(Edges);
end;

end.
