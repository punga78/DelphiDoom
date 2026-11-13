{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - contracts                                         }
{                                                                              }
{  Written for this library (the original keeps everything in the global       }
{  aasworld of be_aas_def.h). Based on the Quake III Arena GPL Source Code     }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Intf;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types;

type
  /// <summary>
  ///   An AAS file that was read: the 14 lumps as arrays of records. The arrays are shared
  ///   with the file: do not change them. Index 0 of the edges, faces, areas, nodes ... is a
  ///   dummy in the format.
  /// </summary>
  IAasFile = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D18}']
    function GetVersion: Integer;
    function GetBspChecksum: Integer;
    function GetHeader: TAasFileHeader;
    function GetBBoxes: TArray<TAasBBox>;
    function GetVertexes: TArray<TVec3>;
    function GetPlanes: TArray<TAasPlane>;
    function GetEdges: TArray<TAasEdge>;
    function GetEdgeIndex: TArray<Integer>;
    function GetFaces: TArray<TAasFace>;
    function GetFaceIndex: TArray<Integer>;
    function GetAreas: TArray<TAasArea>;
    function GetAreaSettings: TArray<TAasAreaSettings>;
    function GetReachability: TArray<TAasReachability>;
    function GetNodes: TArray<TAasNode>;
    function GetPortals: TArray<TAasPortal>;
    function GetPortalIndex: TArray<Integer>;
    function GetClusters: TArray<TAasCluster>;
    /// <summary>The bytes of lump AIndex (AASLUMP_BBOXES ... AASLUMP_CLUSTERS) as the file has them</summary>
    function LumpBytes(const AIndex: Integer): TBytes;
    /// <summary>4 or 5</summary>
    property Version: Integer read GetVersion;
    /// <summary>The checksum of the BSP the file was made for</summary>
    property BspChecksum: Integer read GetBspChecksum;
    /// <summary>The header as it is after the version 5 scrambling was undone</summary>
    property Header: TAasFileHeader read GetHeader;
    property BBoxes: TArray<TAasBBox> read GetBBoxes;
    property Vertexes: TArray<TVec3> read GetVertexes;
    property Planes: TArray<TAasPlane> read GetPlanes;
    property Edges: TArray<TAasEdge> read GetEdges;
    property EdgeIndex: TArray<Integer> read GetEdgeIndex;
    property Faces: TArray<TAasFace> read GetFaces;
    property FaceIndex: TArray<Integer> read GetFaceIndex;
    property Areas: TArray<TAasArea> read GetAreas;
    property AreaSettings: TArray<TAasAreaSettings> read GetAreaSettings;
    property Reachability: TArray<TAasReachability> read GetReachability;
    property Nodes: TArray<TAasNode> read GetNodes;
    property Portals: TArray<TAasPortal> read GetPortals;
    property PortalIndex: TArray<Integer> read GetPortalIndex;
    property Clusters: TArray<TAasCluster> read GetClusters;
  end;

  /// <summary>AAS_LoadAASFile</summary>
  IAasReader = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D19}']
    /// <summary>
    ///   Reads a file from the files the reader was given and checks it against the checksum
    ///   of the variable sv_mapChecksum, as the original. The problems are printed to the
    ///   import (the same texts, level PRT_FATAL) and returned as BLERR_ codes; 0 (BLERR_NOERROR)
    ///   and AFile set when the file was read
    /// </summary>
    function Load(const AFileName: AnsiString; out AFile: IAasFile): Integer;
    /// <summary>
    ///   Reads a file that is already in memory: the same checks without the printing. A
    ///   file that is not valid raises EAasFileException with the BLERR_ code
    /// </summary>
    function ParseBytes(const AData: TBytes; const AName: AnsiString; const ABspChecksum: Integer): IAasFile;
  end;

  /// <summary>The points of an AAS world: which area, which presence type (be_aas_sample.c)</summary>
  IAasSampler = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D1A}']
    /// <summary>AAS_PointAreaNum: the area the point is in, 0 in solid</summary>
    function PointAreaNum(const APoint: TVec3): Integer;
    /// <summary>AAS_PointPresenceType: PRESENCE_NONE in solid</summary>
    function PointPresenceType(const APoint: TVec3): Integer;
    /// <summary>
    ///   AAS_PointReachabilityAreaIndex for a point: the index of the area among the areas
    ///   with reachabilities, ordered by cluster; 0 if the point is in solid or its area has
    ///   no reachability, or the world is not initialized
    /// </summary>
    function PointReachabilityAreaIndex(const APoint: TVec3): Integer;
    /// <summary>AAS_PointReachabilityAreaIndex(NULL): the number of areas with reachabilities</summary>
    function ReachabilityAreaCount: Integer;
  end;

  /// <summary>The lines through the tree (be_aas_sample.c)</summary>
  IAasTracer = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D1B}']
    /// <summary>
    ///   AAS_TraceAreas: the areas (and the point where each is entered) a line goes through,
    ///   at most AMaxAreas; the number of areas
    /// </summary>
    function TraceAreas(const AStart, AEnd: TVec3; const AMaxAreas: Integer; out AAreas: TArray<Integer>;
      out APoints: TArray<TVec3>): Integer;
    /// <summary>
    ///   AAS_TraceClientBBox: moves the origin of a client box from AStart to AEnd through the
    ///   areas that have the presence type. APassEntity is accepted for the signature; the
    ///   entities linked into the areas are not part of the library (no entity is ever hit)
    /// </summary>
    function TraceClientBBox(const AStart, AEnd: TVec3; const APresenceType, APassEntity: Integer): TAasTrace;
  end;

  /// <summary>The faces of the areas (be_aas_sample.c)</summary>
  IAasFaceTester = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D1C}']
    /// <summary>AAS_InsideFace: the point is inside the boundary of the face seen along ANormal</summary>
    function InsideFace(const AFaceNum: Integer; const ANormal, APoint: TVec3; const AEpsilon: Single): Boolean;
    /// <summary>AAS_PointInsideFace: the same with the normal of the plane of the face</summary>
    function PointInsideFace(const AFaceNum: Integer; const APoint: TVec3; const AEpsilon: Single): Boolean;
    /// <summary>AAS_AreaGroundFace: the number of the ground face the point is above (0 if none)</summary>
    function AreaGroundFace(const AAreaNum: Integer; const APoint: TVec3): Integer;
    /// <summary>AAS_TraceEndFace: the number of the face the end of a trace is in (0 if none)</summary>
    function TraceEndFace(const ATrace: TAasTrace): Integer;
    /// <summary>AAS_FacePlane</summary>
    procedure FacePlane(const AFaceNum: Integer; out ANormal: TVec3; out ADist: Single);
  end;

  /// <summary>The areas a box touches (AAS_BBoxAreas)</summary>
  IAasBoxAreas = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D1D}']
    /// <summary>
    ///   AAS_BBoxAreas: the areas the box touches, in the order of the original (the last one
    ///   found by the descent of the tree comes first), at most AMaxAreas
    /// </summary>
    function BBoxAreas(const AAbsMins, AAbsMaxs: TVec3; const AMaxAreas: Integer): TArray<Integer>;
  end;

  /// <summary>What an area says about itself (AAS_AreaCluster, AAS_AreaInfo, AAS_AreaGrounded ...)</summary>
  IAasAreaQuery = interface
    ['{3D6A1E94-7C52-4B08-A9F3-5E21B0C47D1E}']
    /// <summary>AAS_AreaCluster: negative for a cluster portal; 0 for an area out of range</summary>
    function AreaCluster(const AAreaNum: Integer): Integer;
    /// <summary>AAS_AreaPresenceType: 0 for an area out of range</summary>
    function AreaPresenceType(const AAreaNum: Integer): Integer;
    /// <summary>AAS_AreaInfo: fills the record; the size of the record (52) or 0 for an area out of range</summary>
    function AreaInfo(const AAreaNum: Integer; out AInfo: TAasAreaInfo): Integer;
    /// <summary>AAS_AreaReachability: the number of reachabilities of the area</summary>
    function AreaReachability(const AAreaNum: Integer): Integer;
    /// <summary>The contents of the area (areasettings.contents); 0 for an area out of range</summary>
    function AreaContents(const AAreaNum: Integer): Integer;
    /// <summary>The flags of the area (areasettings.areaflags); 0 for an area out of range</summary>
    function AreaFlags(const AAreaNum: Integer): Integer;
    /// <summary>AAS_AreaGrounded, AAS_AreaLadder, AAS_AreaLiquid (= AAS_AreaSwim): the flag set in the area</summary>
    function AreaGrounded(const AAreaNum: Integer): Boolean;
    function AreaLadder(const AAreaNum: Integer): Boolean;
    function AreaLiquid(const AAreaNum: Integer): Boolean;
    /// <summary>AAS_AreaLava, AAS_AreaSlime, AAS_AreaJumpPad, AAS_AreaTeleporter, AAS_AreaClusterPortal, AAS_AreaDoNotEnter</summary>
    function AreaLava(const AAreaNum: Integer): Boolean;
    function AreaSlime(const AAreaNum: Integer): Boolean;
    function AreaJumpPad(const AAreaNum: Integer): Boolean;
    function AreaTeleporter(const AAreaNum: Integer): Boolean;
    function AreaClusterPortal(const AAreaNum: Integer): Boolean;
    function AreaDoNotEnter(const AAreaNum: Integer): Boolean;
  end;

implementation

end.
