{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the node of the axial BSP tree              }
{                                                                              }
{  Port of cm_node_t of CollisionModel_local.h, Doom 3 GPL Source Code.        }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Model.Node;

interface

uses
  System.Generics.Collections, DelphiDoom.Collision.Model.Polygon, DelphiDoom.Collision.Model.Brush;

type
  /// <summary>
  ///   A node of the spatial subdivision. The chains of polygon and brush references of the
  ///   C++ code are lists: index 0 is the head of the chain, and a new reference goes to the
  ///   head, so the visiting order is the one of the C++ code. Nodes, polygons and brushes
  ///   are owned by the model
  /// </summary>
  TCmNode = class
  private
    FPolygons: TList<TCmPolygon>;
    FBrushes: TList<TCmBrush>;
  public
    /// <summary>node axial plane type: 0, 1 or 2, or -1 for a leaf</summary>
    PlaneType: Integer;
    /// <summary>node plane distance</summary>
    PlaneDist: Single;
    Parent: TCmNode;
    /// <summary>child 0 is in front of the plane, child 1 behind it</summary>
    Children: array[0..1] of TCmNode;
    constructor Create;
    destructor Destroy; override;
    /// <summary>Polygons in the node, head of the chain first</summary>
    property Polygons: TList<TCmPolygon> read FPolygons;
    /// <summary>Brushes in the node, head of the chain first</summary>
    property Brushes: TList<TCmBrush> read FBrushes;
    function IsLeaf: Boolean;
  end;

implementation

{ TCmNode }

constructor TCmNode.Create;
begin
  inherited Create;
  FPolygons := TList<TCmPolygon>.Create;
  FBrushes := TList<TCmBrush>.Create;
  PlaneType := -1;
end;

destructor TCmNode.Destroy;
begin
  FBrushes.Free;
  FPolygons.Free;
  inherited Destroy;
end;

function TCmNode.IsLeaf: Boolean;
begin
  Result := PlaneType = -1;
end;

end.
