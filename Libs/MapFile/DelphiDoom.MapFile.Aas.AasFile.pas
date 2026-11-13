{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the model of an .aas file                    }
{                                                                              }
{  Model of the data of idAASFile / idAASFileLocal (AASFile.h, AASFile_local.h)}
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.AasFile;

interface

uses
  System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Plane,
  DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Area, DelphiDoom.MapFile.Aas.Settings;

type
  /// <summary>
  ///   The navigation file of the AI: planes, vertices, edges, faces and areas (the polygons that
  ///   bound the areas, through the edge index and the face index), the BSP tree of the areas,
  ///   the portals and clusters, and the settings it was built with. Index 0 of the lists is a
  ///   dummy in a file written by the compiler (edge 0, face 0, ...): the model keeps the lists
  ///   as the file has them. The areas and the settings belong to the file
  /// </summary>
  TAasFile = class
  strict private
    FName: AnsiString;
    FCrc: Cardinal;
    FPlanes: TArray<TGeoPlane>;
    FVertices: TArray<TGeoVec3>;
    FEdges: TArray<TAasEdge>;
    FEdgeIndex: TArray<Integer>;
    FFaces: TArray<TAasFace>;
    FFaceIndex: TArray<Integer>;
    FAreas: TObjectList<TAasArea>;
    FNodes: TArray<TAasNode>;
    FPortals: TArray<TAasPortal>;
    FPortalIndex: TArray<Integer>;
    FClusters: TArray<TAasCluster>;
    FSettings: TAasSettings;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: AnsiString read FName write FName;
    /// <summary>The CRC of the map file the AAS was built from (GetCRC)</summary>
    property Crc: Cardinal read FCrc write FCrc;
    property Planes: TArray<TGeoPlane> read FPlanes write FPlanes;
    property Vertices: TArray<TGeoVec3> read FVertices write FVertices;
    property Edges: TArray<TAasEdge> read FEdges write FEdges;
    property EdgeIndex: TArray<Integer> read FEdgeIndex write FEdgeIndex;
    property Faces: TArray<TAasFace> read FFaces write FFaces;
    property FaceIndex: TArray<Integer> read FFaceIndex write FFaceIndex;
    property Areas: TObjectList<TAasArea> read FAreas;
    property Nodes: TArray<TAasNode> read FNodes write FNodes;
    property Portals: TArray<TAasPortal> read FPortals write FPortals;
    property PortalIndex: TArray<Integer> read FPortalIndex write FPortalIndex;
    property Clusters: TArray<TAasCluster> read FClusters write FClusters;
    property Settings: TAasSettings read FSettings;
    function NumPlanes: Integer;
    function NumVertices: Integer;
    function NumEdges: Integer;
    function NumFaces: Integer;
    function NumAreas: Integer;
    function NumNodes: Integer;
    function NumPortals: Integer;
    function NumClusters: Integer;
    /// <summary>The reachabilities of all the areas (NumReachabilities)</summary>
    function NumReachabilities: Integer;
  end;

implementation

{ TAasFile }

constructor TAasFile.Create;
begin
  inherited Create;
  FAreas := TObjectList<TAasArea>.Create(True);
  FSettings := TAasSettings.Create;
end;

destructor TAasFile.Destroy;
begin
  FSettings.Free;
  FAreas.Free;
  inherited Destroy;
end;

function TAasFile.NumPlanes: Integer;
begin
  Result := Length(FPlanes);
end;

function TAasFile.NumVertices: Integer;
begin
  Result := Length(FVertices);
end;

function TAasFile.NumEdges: Integer;
begin
  Result := Length(FEdges);
end;

function TAasFile.NumFaces: Integer;
begin
  Result := Length(FFaces);
end;

function TAasFile.NumAreas: Integer;
begin
  Result := FAreas.Count;
end;

function TAasFile.NumNodes: Integer;
begin
  Result := Length(FNodes);
end;

function TAasFile.NumPortals: Integer;
begin
  Result := Length(FPortals);
end;

function TAasFile.NumClusters: Integer;
begin
  Result := Length(FClusters);
end;

function TAasFile.NumReachabilities: Integer;
var
  LArea: TAasArea;
begin
  Result := 0;
  for LArea in FAreas do
    Inc(Result, LArea.Reach.Count);
end;

end.
