{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - shared types and constants                  }
{                                                                              }
{  Port of CollisionModel.h and CollisionModel_local.h of Doom 3 GPL Source    }
{  Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.     }
{  Doom 3 Source Code: GNU General Public License version 3 with additional    }
{  terms (see Reference\doom3\COPYING.txt). This unit is a derived work.       }
{  Delphi port: GNU General Public License, version 3 (the combined work       }
{  falls under the GPL v3 of the Doom 3 code).                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Types;

interface

uses
  System.SysUtils, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3;

const
  /// <summary>Always stay this distance away from any model (CM_CLIP_EPSILON)</summary>
  CM_CLIP_EPSILON: Single = 0.25;
  /// <summary>Should always be larger than the clip epsilon (CM_BOX_EPSILON)</summary>
  CM_BOX_EPSILON: Single = 1.0;
  /// <summary>Maximum distance a trace model may be traced, point traces are unlimited</summary>
  CM_MAX_TRACE_DIST: Single = 4096.0;

  MIN_NODE_SIZE: Single = 64.0;
  MAX_NODE_POLYGONS = 128;
  CM_MAX_POLYGON_EDGES = 64;
  CIRCLE_APPROXIMATION_LENGTH: Single = 64.0;
  /// <summary>Handle of the reusable trace model slot (MAX_SUBMODELS / TRACE_MODEL_HANDLE)</summary>
  MAX_SUBMODELS = 2048;
  TRACE_MODEL_HANDLE = MAX_SUBMODELS;

  VERTEX_HASH_BOXSIZE = 1 shl 6;
  VERTEX_HASH_SIZE = VERTEX_HASH_BOXSIZE * VERTEX_HASH_BOXSIZE;
  EDGE_HASH_SIZE = 1 shl 14;
  INTEGRAL_EPSILON: Single = 0.01;
  VERTEX_EPSILON: Single = 0.1;
  SHARP_EDGE_DOT: Single = -0.7;

  /// <summary>Content flags of idMaterial (renderer\Material.h)</summary>
  CONTENTS_SOLID = 1 shl 0;
  CONTENTS_OPAQUE = 1 shl 1;
  CONTENTS_WATER = 1 shl 2;
  CONTENTS_PLAYERCLIP = 1 shl 3;
  CONTENTS_MONSTERCLIP = 1 shl 4;
  CONTENTS_MOVEABLECLIP = 1 shl 5;
  CONTENTS_IKCLIP = 1 shl 6;
  CONTENTS_BLOOD = 1 shl 7;
  CONTENTS_BODY = 1 shl 8;
  CONTENTS_PROJECTILE = 1 shl 9;
  CONTENTS_CORPSE = 1 shl 10;
  CONTENTS_RENDERMODEL = 1 shl 11;
  CONTENTS_TRIGGER = 1 shl 12;
  CONTENTS_AAS_SOLID = 1 shl 13;
  CONTENTS_AAS_OBSTACLE = 1 shl 14;
  CONTENTS_FLASHLIGHT_TRIGGER = 1 shl 15;
  CONTENTS_AREAPORTAL = 1 shl 20;
  CONTENTS_NOCSG = 1 shl 21;
  /// <summary>Contents that take part in collision: everything but area portals and nocsg</summary>
  CONTENTS_REMOVE_UTIL = not (CONTENTS_AREAPORTAL or CONTENTS_NOCSG);

type
  /// <summary>Contact type (contactType_t)</summary>
  TContactType = (
    /// <summary>no contact</summary>
    ctNone,
    /// <summary>trace model edge hits model edge</summary>
    ctEdge,
    /// <summary>model vertex hits trace model polygon</summary>
    ctModelVertex,
    /// <summary>trace model vertex hits model polygon</summary>
    ctTrmVertex);

  /// <summary>
  ///   A surface material as the collision code needs it: the name, the content flags and
  ///   whether the polygons built from it are two sided. It replaces idMaterial and is
  ///   owned by an ICollisionMaterialCatalog
  /// </summary>
  TCollisionMaterial = class
  private
    FName: string;
    FContents: Integer;
    FTwoSided: Boolean;
  public
    constructor Create(const AName: string; AContents: Integer; ATwoSided: Boolean = False);
    property Name: string read FName;
    /// <summary>idMaterial::GetContentFlags</summary>
    property Contents: Integer read FContents;
    /// <summary>cull type two sided or a material that creates back sides</summary>
    property TwoSided: Boolean read FTwoSided;
  end;

  /// <summary>Contact information (contactInfo_t)</summary>
  TContactInfo = record
    ContactType: TContactType;
    /// <summary>point of contact</summary>
    Point: TGeoVec3;
    /// <summary>contact plane normal</summary>
    Normal: TGeoVec3;
    /// <summary>contact plane distance</summary>
    Dist: Single;
    /// <summary>contents at other side of surface</summary>
    Contents: Integer;
    /// <summary>surface material (not owned, may be nil)</summary>
    Material: TCollisionMaterial;
    /// <summary>contact feature on model: a vertex or signed edge number, or the polygon address</summary>
    ModelFeature: Integer;
    /// <summary>contact feature on trace model</summary>
    TrmFeature: Integer;
    EntityNum: Integer;
    Id: Integer;
  end;

  PContactInfo = ^TContactInfo;

  /// <summary>Trace result (trace_t)</summary>
  TCollisionTrace = record
    /// <summary>fraction of movement completed, 1.0 = didn't hit anything</summary>
    Fraction: Single;
    /// <summary>final position of trace model</summary>
    EndPos: TGeoVec3;
    /// <summary>final axis of trace model</summary>
    EndAxis: TGeoMat3;
    /// <summary>contact information, only valid if Fraction &lt; 1.0</summary>
    C: TContactInfo;
  end;

  PCollisionTrace = ^TCollisionTrace;

  /// <summary>Base of the errors of the collision library (replaces common->Error)</summary>
  ECollisionException = class(Exception);
  /// <summary>A collision model file is not valid</summary>
  ECollisionFormatException = class(ECollisionException);

implementation

{ TCollisionMaterial }

constructor TCollisionMaterial.Create(const AName: string; AContents: Integer; ATwoSided: Boolean);
begin
  inherited Create;
  FName := AName;
  FContents := AContents;
  FTwoSided := ATwoSided;
end;

end.
