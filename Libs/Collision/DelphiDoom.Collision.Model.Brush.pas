{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the brush of a model                        }
{                                                                              }
{  Port of cm_brush_t of CollisionModel_local.h, Doom 3 GPL Source Code.       }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms. This unit is a derived work (GPL v3).                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Model.Brush;

interface

uses
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Collision.Types;

type
  /// <summary>A convex brush of a collision model, used for position tests. Owned by the model</summary>
  TCmBrush = class
  public
    /// <summary>for multi-check avoidance</summary>
    CheckCount: Integer;
    /// <summary>brush bounds</summary>
    Bounds: TGeoBounds;
    /// <summary>contents of brush</summary>
    Contents: Integer;
    /// <summary>material, not owned</summary>
    Material: TCollisionMaterial;
    /// <summary>number of brush primitive</summary>
    PrimitiveNum: Integer;
    /// <summary>bounding planes: the normals point out of the brush</summary>
    Planes: TArray<TGeoPlane>;
    function NumPlanes: Integer;
  end;

implementation

{ TCmBrush }

function TCmBrush.NumPlanes: Integer;
begin
  Result := Length(Planes);
end;

end.
