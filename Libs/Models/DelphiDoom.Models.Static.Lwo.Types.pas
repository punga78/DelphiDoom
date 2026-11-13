{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: LightWave objects (LWO2)     }
{  the data read from the file                                                 }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_lwo.h     }
{  (from the LightWave 6.5 SDK). Copyright (C) 1999-2011 id Software LLC, a    }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Lwo.Types;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Math.Vec3;

const
  /// <summary>LWID_('T','X','U','V'): the type of a vertex map of texture coordinates</summary>
  LWO_VMAP_TXUV = $54585556;
  /// <summary>LWID_('R','G','B','A'): the type of a vertex map of colours</summary>
  LWO_VMAP_RGBA = $52474241;

type
  /// <summary>A reference of a point or of a polygon vertex to a record of a vertex map (lwVMapPt)</summary>
  TLwoVMapRef = record
    /// <summary>The index in the vertex maps of the layer</summary>
    VMap: Integer;
    /// <summary>The record in the map</summary>
    Index: Integer;
  end;

  /// <summary>A vertex map of a layer (lwVMap): VMAP (per point) or VMAD (per polygon vertex)</summary>
  TLwoVMap = record
    Name: AnsiString;
    /// <summary>The four letters as a number, LWID_ style</summary>
    Kind: Cardinal;
    Dim: Integer;
    PerPoly: Boolean;
    VertexIndex: TArray<Integer>;
    PolygonIndex: TArray<Integer>;
    /// <summary>Dim values for each record, one after the other</summary>
    Values: TArray<Single>;
    function Count: Integer;
    function Value(const ARecord, AComponent: Integer): Single;
  end;

  /// <summary>A point (lwPoint): position and the polygons and vertex map records that use it</summary>
  TLwoPoint = record
    Pos: TIdVec3;
    Polygons: TArray<Integer>;
    VMaps: TArray<TLwoVMapRef>;
  end;

  /// <summary>A vertex of a polygon (lwPolVert): point, normal and vertex map records</summary>
  TLwoPolVert = record
    Index: Integer;
    Norm: TIdVec3;
    VMaps: TArray<TLwoVMapRef>;
  end;

  /// <summary>A polygon (lwPolygon)</summary>
  TLwoPolygon = record
    Kind: Cardinal;
    Flags: Integer;
    /// <summary>The surface of the object: before the resolve the index of the tag</summary>
    Surf: Integer;
    Part: Integer;
    SmoothGroup: Integer;
    Norm: TIdVec3;
    Verts: TArray<TLwoPolVert>;
  end;

  /// <summary>A layer (lwLayer); BBox is computed from the points</summary>
  TLwoLayer = record
    Name: AnsiString;
    Index: Integer;
    Flags: Integer;
    Parent: Integer;
    Pivot: TIdVec3;
    Points: TArray<TLwoPoint>;
    Polygons: TArray<TLwoPolygon>;
    VMaps: TArray<TLwoVMap>;
    BBoxMin: TIdVec3;
    BBoxMax: TIdVec3;
  end;

  /// <summary>
  ///   A surface (lwSurface): only what the engine reads of it, the name, the base colour (COLR)
  ///   and the maximum smoothing angle (SMAN). The textures, shaders and other channels of the
  ///   surface are skipped.
  /// </summary>
  TLwoSurface = record
    Name: AnsiString;
    Red: Single;
    Green: Single;
    Blue: Single;
    Smooth: Single;
  end;

  /// <summary>An object (lwObject): the layers, the surfaces and the tags that name them</summary>
  TLwoObject = record
    Layers: TArray<TLwoLayer>;
    Surfaces: TArray<TLwoSurface>;
    Tags: TArray<AnsiString>;
    /// <summary>The layers declared by LAYR chunks (nlayers)</summary>
    LayerCount: Integer;
  end;

implementation

{ TLwoVMap }

function TLwoVMap.Count: Integer;
begin
  Result := Length(VertexIndex);
end;

function TLwoVMap.Value(const ARecord, AComponent: Integer): Single;
begin
  Result := Values[ARecord * Dim + AComponent];
end;

end.
