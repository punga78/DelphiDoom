{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - contracts                                   }
{                                                                              }
{  Derived from CollisionModel.h and CollisionModel_local.h of Doom 3 GPL      }
{  Source Code (Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company). Doom 3 Source Code: GNU General Public License version 3 with     }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Intf;

interface

uses
  System.Classes, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.Plane, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding,
  DelphiDoom.Geometry.TraceModel, DelphiDoom.Collision.Types, DelphiDoom.Collision.Model;

type
  /// <summary>
  ///   Where the surface materials come from (replaces declManager->FindMaterial). The
  ///   materials stay owned by the catalog and live at least as long as the models
  /// </summary>
  ICollisionMaterialCatalog = interface
    ['{5B1D7E42-9C36-4A8F-B0D5-3E7A12C94F60}']
    /// <summary>The material with that name; never nil (an unknown name is a catalog decision)</summary>
    function FindMaterial(const AName: string): TCollisionMaterial;
  end;

  /// <summary>One side of a brush: its plane and its material (idMapBrushSide)</summary>
  TCollisionBrushSide = record
    Plane: TGeoPlane;
    Material: TCollisionMaterial;
  end;

  /// <summary>
  ///   The geometry a collision model is built from (replaces idMapEntity: its brushes and
  ///   its polygons). Brushes come first, then polygons; the primitive number of a primitive
  ///   is its position counted over both
  /// </summary>
  ICollisionGeometrySource = interface
    ['{C3A84F19-52E7-4D60-8B1A-6F9D0E27B351}']
    function ModelName: string;
    function BrushCount: Integer;
    function BrushSides(ABrushIndex: Integer): TArray<TCollisionBrushSide>;
    function PolygonCount: Integer;
    /// <summary>The caller owns nothing: the returned winding is a copy the builder frees</summary>
    function PolygonWinding(APolygonIndex: Integer): TGeoWinding;
    function PolygonPlane(APolygonIndex: Integer): TGeoPlane;
    function PolygonMaterial(APolygonIndex: Integer): TCollisionMaterial;
  end;

  /// <summary>
  ///   What the game asks of the collision system (idCollisionModelManager of CollisionModel.h):
  ///   a registry of models and the queries on them. Models are referred to by handle.
  ///   Rotation, debug drawing and model listing are not part of the contract.
  /// </summary>
  ICollisionModelManager = interface
    ['{8E2F6A71-0B4D-4C95-A3E8-D17C5B906F24}']
    /// <summary>Frees all the models (FreeMap)</summary>
    procedure FreeMap;
    /// <summary>Takes a model and gives its handle; the manager owns it from now on</summary>
    function AddModel(AModel: TCollisionModel): Integer;
    /// <summary>The handle of the model with that name (without case) or -1 (FindModel)</summary>
    function FindModel(const AName: string): Integer;
    /// <summary>Reads the models of a .cm file and adds them; returns how many, 0 when the file is rejected</summary>
    function LoadModelFile(AStream: TStream; AMapFileCrc: Cardinal = 0): Integer;
    /// <summary>Sets up a trace model for collision with other trace models; AMaterial may be nil (SetupTrmModel)</summary>
    function SetupTrmModel(ATrm: TTraceModel; AMaterial: TCollisionMaterial): Integer;
    /// <summary>Creates a trace model from a collision model, true if successful (TrmFromModel)</summary>
    function TrmFromModel(AHandle: Integer; ATrm: TTraceModel): Boolean;

    function GetModelName(AHandle: Integer): string;
    function GetModelBounds(AHandle: Integer; out ABounds: TGeoBounds): Boolean;
    function GetModelContents(AHandle: Integer; out AContents: Integer): Boolean;
    function GetModelVertex(AHandle, AVertexNum: Integer; out AVertex: TGeoVec3): Boolean;
    function GetModelEdge(AHandle, AEdgeNum: Integer; out AStart, AEnd: TGeoVec3): Boolean;
    /// <summary>
    ///   The points of a polygon of a model; APolygonNum is the Id of the polygon (the
    ///   modelFeature of a contact with a polygon). The caller frees the winding; nil if invalid
    /// </summary>
    function GetModelPolygon(AHandle, APolygonNum: Integer): TGeoWinding;

    /// <summary>
    ///   Translates a trm (nil for a point) and reports the first collision if any. With
    ///   AStart = AEnd it does a position test
    /// </summary>
    procedure Translation(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; ATrm: TTraceModel;
      const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3;
      const AModelAxis: TGeoMat3);
    /// <summary>Returns the contents the trm is stuck in or 0 if the trm is in free space</summary>
    function Contents(const AStart: TGeoVec3; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
      AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
    /// <summary>
    ///   Stores all contact points of the trm with the model along the translation ADir * ADepth;
    ///   returns the number of contacts. The rotational part of the idVec6 direction is not supported
    ///   (a FIXME in the original too)
    /// </summary>
    function Contacts(AContacts: TList<TContactInfo>; AMaxContacts: Integer; const AStart, ADir: TGeoVec3;
      ADepth: Single; ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: Integer;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
  end;

implementation

end.
