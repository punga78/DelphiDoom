{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - tessellation of the patches of a .map        }
{                                                                              }
{  Port of ParsePatch of the dmap compiler (tools\compilers\dmap\map.cpp)      }
{  that turns an idMapPatch into the triangles of idSurface_Patch. The         }
{  subdivision itself is TGeoSurfacePatch of Framework\Geometry, which has its own }
{  parity with the idSurface_Patch of Doom 3.                                  }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Framework\IdLib\README.md); the repository }
{  as a whole is GPL v2 or later. Copyright (C) 1999-2011 id Software LLC.     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Patch.Tessellator;

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Surface.Patch, DelphiDoom.MapFile.Patch;

const
  /// <summary>DEFAULT_CURVE_MAX_ERROR (MapFile.h): the largest distance of the curve from the mesh, in units</summary>
  MAP_DEFAULT_CURVE_MAX_ERROR = 4.0;
  /// <summary>DEFAULT_CURVE_MAX_ERROR_CD: the same for the collision model</summary>
  MAP_DEFAULT_CURVE_MAX_ERROR_CD = 24.0;
  /// <summary>DEFAULT_CURVE_MAX_LENGTH: no limit to the length of a span</summary>
  MAP_DEFAULT_CURVE_MAX_LENGTH = -1.0;

type
  /// <summary>
  ///   The triangles of a patch of a map: the control grid (position and texture coordinates of each point) becomes an
  ///   <c>idSurface_Patch</c>, and it is subdivided as the map compiler does: with the subdivisions the map says
  ///   (<c>patchDef3</c>) if it is explicitly subdivided, else by the largest error of 4 units and no limit of length.
  ///   The normals are generated. The result belongs to the caller
  /// </summary>
  TMapPatchTessellator = class sealed
  public
    /// <summary>ParsePatch of dmap: the tessellated surface of the patch (nil is not allowed)</summary>
    class function Tessellate(APatch: TMapPatch): TGeoSurfacePatch; static;
    /// <summary>
    ///   The same with errors and length given (the collision model uses <c>DEFAULT_CURVE_MAX_ERROR_CD</c>); the
    ///   subdivisions of an explicitly subdivided patch are used as they are
    /// </summary>
    class function TessellateWith(APatch: TMapPatch; AMaxHorizontalError, AMaxVerticalError, AMaxLength: Single): TGeoSurfacePatch; static;
    /// <summary>The control points of the map patch as an idSurface_Patch, not yet subdivided</summary>
    class function ToSurface(APatch: TMapPatch): TGeoSurfacePatch; static;
  end;

implementation

uses
  DelphiDoom.Geometry.DrawVert, DelphiDoom.IdLib.Math.Vec2, DelphiDoom.MapFile.Types;

{ TMapPatchTessellator }

class function TMapPatchTessellator.ToSurface(APatch: TMapPatch): TGeoSurfacePatch;
var
  LIndex: Integer;
  LVertex: TGeoDrawVert;
  LSource: TMapPatchVertex;
begin
  Result := TGeoSurfacePatch.Create(APatch.Width, APatch.Height);
  try
    Result.SetSize(APatch.Width, APatch.Height);
    for LIndex := 0 to APatch.GetNumVertices - 1 do
    begin
      LSource := APatch.Vertices[LIndex];
      LVertex.Clear;
      LVertex.Xyz := LSource.Position;
      LVertex.St := TIdVec2.Create(LSource.S, LSource.T);
      Result.Vertices[LIndex] := LVertex;
    end;
  except
    Result.Free;
    raise;
  end;
end;

class function TMapPatchTessellator.TessellateWith(APatch: TMapPatch; AMaxHorizontalError, AMaxVerticalError,
  AMaxLength: Single): TGeoSurfacePatch;
begin
  Result := ToSurface(APatch);
  try
    if APatch.ExplicitlySubdivided then
      Result.SubdivideExplicit(APatch.HorzSubdivisions, APatch.VertSubdivisions, True)
    else
      Result.Subdivide(AMaxHorizontalError, AMaxVerticalError, AMaxLength, True);
  except
    Result.Free;
    raise;
  end;
end;

class function TMapPatchTessellator.Tessellate(APatch: TMapPatch): TGeoSurfacePatch;
begin
  Result := TessellateWith(APatch, MAP_DEFAULT_CURVE_MAX_ERROR, MAP_DEFAULT_CURVE_MAX_ERROR,
    MAP_DEFAULT_CURVE_MAX_LENGTH);
end;

end.
