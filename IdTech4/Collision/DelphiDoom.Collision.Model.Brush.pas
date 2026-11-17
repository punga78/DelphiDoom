{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the brush of a model                        }
{                                                                              }
{  Port of cm_brush_t of CollisionModel_local.h, Doom 3 GPL Source Code.       }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This      }
{  unit is derived from the Doom 3 GPL source code and is therefore available  }
{  under the GNU General Public License, version 3 or (at your option) any     }
{  later version, with the additional terms of the Doom 3 Source Code License  }
{  (Reference\doom3\COPYING.txt: preservation of legal notices and             }
{  trademarks, no use of the licensors' names for publicity, warranty          }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
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
