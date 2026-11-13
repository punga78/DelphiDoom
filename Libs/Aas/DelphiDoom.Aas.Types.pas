{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - constants, records and errors of Quake III AAS    }
{                                                                              }
{  Port of the constants and the records of aasfile.h and be_aas.h             }
{  (code\botlib, code\game) of Quake III Arena. Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Types;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

const
  /// <summary>AASID: "EASS" read as a little endian integer</summary>
  AAS_ID = (Ord('S') shl 24) + (Ord('A') shl 16) + (Ord('A') shl 8) + Ord('E');
  /// <summary>AASVERSION_OLD: the only version that is not scrambled</summary>
  AAS_VERSION_OLD = 4;
  /// <summary>AASVERSION</summary>
  AAS_VERSION = 5;

  // presence types
  PRESENCE_NONE = 1;
  PRESENCE_NORMAL = 2;
  PRESENCE_CROUCH = 4;

  // travel types
  MAX_TRAVELTYPES = 32;
  TRAVEL_INVALID = 1;
  TRAVEL_WALK = 2;
  TRAVEL_CROUCH = 3;
  TRAVEL_BARRIERJUMP = 4;
  TRAVEL_JUMP = 5;
  TRAVEL_LADDER = 6;
  TRAVEL_WALKOFFLEDGE = 7;
  TRAVEL_SWIM = 8;
  TRAVEL_WATERJUMP = 9;
  TRAVEL_TELEPORT = 10;
  TRAVEL_ELEVATOR = 11;
  TRAVEL_ROCKETJUMP = 12;
  TRAVEL_BFGJUMP = 13;
  TRAVEL_GRAPPLEHOOK = 14;
  TRAVEL_DOUBLEJUMP = 15;
  TRAVEL_RAMPJUMP = 16;
  TRAVEL_STRAFEJUMP = 17;
  TRAVEL_JUMPPAD = 18;
  TRAVEL_FUNCBOB = 19;

  // additional travel flags
  TRAVELTYPE_MASK = $FFFFFF;
  TRAVELFLAG_NOTTEAM1 = 1 shl 24;
  TRAVELFLAG_NOTTEAM2 = 2 shl 24;

  // face flags
  FACE_SOLID = 1;
  FACE_LADDER = 2;
  FACE_GROUND = 4;
  FACE_GAP = 8;
  FACE_LIQUID = 16;
  FACE_LIQUIDSURFACE = 32;
  FACE_BRIDGE = 64;

  // area contents
  AREACONTENTS_WATER = 1;
  AREACONTENTS_LAVA = 2;
  AREACONTENTS_SLIME = 4;
  AREACONTENTS_CLUSTERPORTAL = 8;
  AREACONTENTS_TELEPORTAL = 16;
  AREACONTENTS_ROUTEPORTAL = 32;
  AREACONTENTS_TELEPORTER = 64;
  AREACONTENTS_JUMPPAD = 128;
  AREACONTENTS_DONOTENTER = 256;
  AREACONTENTS_VIEWPORTAL = 512;
  AREACONTENTS_MOVER = 1024;
  AREACONTENTS_NOTTEAM1 = 2048;
  AREACONTENTS_NOTTEAM2 = 4096;
  AREACONTENTS_MODELNUMSHIFT = 24;
  AREACONTENTS_MAXMODELNUM = $FF;

  // area flags
  AREA_GROUNDED = 1;
  AREA_LADDER = 2;
  AREA_LIQUID = 4;
  AREA_DISABLED = 8;
  AREA_BRIDGE = 16;

  // header lumps
  AAS_LUMPS = 14;
  AASLUMP_BBOXES = 0;
  AASLUMP_VERTEXES = 1;
  AASLUMP_PLANES = 2;
  AASLUMP_EDGES = 3;
  AASLUMP_EDGEINDEX = 4;
  AASLUMP_FACES = 5;
  AASLUMP_FACEINDEX = 6;
  AASLUMP_AREAS = 7;
  AASLUMP_AREASETTINGS = 8;
  AASLUMP_REACHABILITY = 9;
  AASLUMP_NODES = 10;
  AASLUMP_PORTALS = 11;
  AASLUMP_PORTALINDEX = 12;
  AASLUMP_CLUSTERS = 13;

  /// <summary>The bytes of the header that AAS_DData scrambles start after the identifier and the version</summary>
  AAS_SCRAMBLE_START = 8;

  /// <summary>BLERR_CANNOTOPENAASFILE and the other error codes of botlib.h that loading an AAS file returns</summary>
  BLERR_CANNOTOPENAASFILE = 4;
  BLERR_WRONGAASFILEID = 5;
  BLERR_WRONGAASFILEVERSION = 6;
  BLERR_CANNOTREADAASLUMP = 7;

  /// <summary>The size of the stack of the traces (aas_tracestack_t tracestack[127])</summary>
  AAS_TRACE_STACK_SIZE = 127;

type
  /// <summary>aas_lump_t: where a lump is in the file</summary>
  TAasLump = packed record
    FileOffset: Integer;
    FileLength: Integer;
  end;

  /// <summary>aas_header_t (124 bytes); the bytes after the version are scrambled in a version 5 file</summary>
  TAasFileHeader = packed record
    Ident: Integer;
    Version: Integer;
    BspChecksum: Integer;
    Lumps: array[0..AAS_LUMPS - 1] of TAasLump;
  end;

  /// <summary>aas_bbox_t</summary>
  TAasBBox = packed record
    PresenceType: Integer;
    Flags: Integer;
    Mins: TVec3;
    Maxs: TVec3;
  end;

  /// <summary>aas_plane_t; the planes come in pairs: plane N xor 1 is the same plane facing the other way</summary>
  TAasPlane = packed record
    Normal: TVec3;
    Dist: Single;
    PlaneType: Integer;
  end;

  /// <summary>aas_edge_t</summary>
  TAasEdge = packed record
    Vertexes: array[0..1] of Integer;
  end;

  /// <summary>aas_face_t</summary>
  TAasFace = packed record
    PlaneNum: Integer;
    FaceFlags: Integer;
    NumEdges: Integer;
    FirstEdge: Integer;
    FrontArea: Integer;
    BackArea: Integer;
  end;

  /// <summary>aas_area_t</summary>
  TAasArea = packed record
    AreaNum: Integer;
    NumFaces: Integer;
    FirstFace: Integer;
    Mins: TVec3;
    Maxs: TVec3;
    Center: TVec3;
  end;

  /// <summary>aas_areasettings_t</summary>
  TAasAreaSettings = packed record
    Contents: Integer;
    AreaFlags: Integer;
    PresenceType: Integer;
    Cluster: Integer;
    ClusterAreaNum: Integer;
    NumReachableAreas: Integer;
    FirstReachableArea: Integer;
  end;

  /// <summary>
  ///   aas_reachability_t: 44 bytes in the file, as the C struct with its padding (the short
  ///   is followed by two bytes that nobody reads)
  /// </summary>
  TAasReachability = packed record
    AreaNum: Integer;
    FaceNum: Integer;
    EdgeNum: Integer;
    StartPoint: TVec3;
    EndPoint: TVec3;
    TravelType: Integer;
    TravelTime: Word;
    Padding: Word;
  end;

  /// <summary>aas_node_t: a child is a node, an area when negative, or a solid leaf when zero</summary>
  TAasNode = packed record
    PlaneNum: Integer;
    Children: array[0..1] of Integer;
  end;

  /// <summary>aas_portal_t</summary>
  TAasPortal = packed record
    AreaNum: Integer;
    FrontCluster: Integer;
    BackCluster: Integer;
    ClusterAreaNum: array[0..1] of Integer;
  end;

  /// <summary>aas_cluster_t</summary>
  TAasCluster = packed record
    NumAreas: Integer;
    NumReachabilityAreas: Integer;
    NumPortals: Integer;
    FirstPortal: Integer;
  end;

  /// <summary>
  ///   The lumps of an AAS file as arrays of records (aasworld.bboxes ... aasworld.clusters):
  ///   what the reader fills in and the byte swapper changes in place
  /// </summary>
  TAasFileData = record
    Header: TAasFileHeader;
    BBoxes: TArray<TAasBBox>;
    Vertexes: TArray<TVec3>;
    Planes: TArray<TAasPlane>;
    Edges: TArray<TAasEdge>;
    EdgeIndex: TArray<Integer>;
    Faces: TArray<TAasFace>;
    FaceIndex: TArray<Integer>;
    Areas: TArray<TAasArea>;
    AreaSettings: TArray<TAasAreaSettings>;
    Reachability: TArray<TAasReachability>;
    Nodes: TArray<TAasNode>;
    Portals: TArray<TAasPortal>;
    PortalIndex: TArray<Integer>;
    Clusters: TArray<TAasCluster>;
  end;

  /// <summary>aas_trace_t, the result of a trace of a bounding box through the areas</summary>
  TAasTrace = record
    StartSolid: Boolean;
    Fraction: Single;
    EndPos: TVec3;
    Ent: Integer;
    LastArea: Integer;
    Area: Integer;
    PlaneNum: Integer;
  end;

  /// <summary>aas_areainfo_t (52 bytes)</summary>
  TAasAreaInfo = packed record
    Contents: Integer;
    Flags: Integer;
    PresenceType: Integer;
    Cluster: Integer;
    Mins: TVec3;
    Maxs: TVec3;
    Center: TVec3;
  end;

  /// <summary>
  ///   An AAS file that is not valid, with the BLERR_ code the original returns for the same
  ///   mistake (the message is the one the original prints, without the line feed)
  /// </summary>
  EAasFileException = class(Exception)
  strict private
    FErrorCode: Integer;
  public
    constructor Create(const AErrorCode: Integer; const AMessage: string);
    /// <summary>BLERR_WRONGAASFILEID, BLERR_WRONGAASFILEVERSION, BLERR_CANNOTREADAASLUMP</summary>
    property ErrorCode: Integer read FErrorCode;
  end;

implementation

{ EAasFileException }

constructor EAasFileException.Create(const AErrorCode: Integer; const AMessage: string);
begin
  inherited Create(AMessage);
  FErrorCode := AErrorCode;
end;

end.
