{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - TAasFile, an AAS file that was read               }
{                                                                              }
{  Replaces the arrays of aasworld (be_aas_def.h). Based on the Quake III      }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,   }
{  Inc. This unit is derived from the Quake III Arena source code and is       }
{  therefore available under the GNU General Public License, version 2 or (at  }
{  your option) any later version.                                             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.AasFile;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf;

type
  /// <summary>The lumps of an AAS file; made by TAasReader, or by a test that builds a world</summary>
  TAasFile = class(TInterfacedObject, IAasFile)
  strict private
    FData: TAasFileData;
    class function Raw(const ASource: Pointer; const ASize: Integer): TBytes; static;
  public
    constructor Create(const AData: TAasFileData);
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
    function LumpBytes(const AIndex: Integer): TBytes;
  end;

implementation

{ TAasFile }

constructor TAasFile.Create(const AData: TAasFileData);
begin
  inherited Create;
  FData := AData;
end;

class function TAasFile.Raw(const ASource: Pointer; const ASize: Integer): TBytes;
begin
  SetLength(Result, ASize);
  if ASize > 0 then
    Move(ASource^, Result[0], ASize);
end;

function TAasFile.GetVersion: Integer;
begin
  Result := FData.Header.Version;
end;

function TAasFile.GetBspChecksum: Integer;
begin
  Result := FData.Header.BspChecksum;
end;

function TAasFile.GetHeader: TAasFileHeader;
begin
  Result := FData.Header;
end;

function TAasFile.GetBBoxes: TArray<TAasBBox>;
begin
  Result := FData.BBoxes;
end;

function TAasFile.GetVertexes: TArray<TVec3>;
begin
  Result := FData.Vertexes;
end;

function TAasFile.GetPlanes: TArray<TAasPlane>;
begin
  Result := FData.Planes;
end;

function TAasFile.GetEdges: TArray<TAasEdge>;
begin
  Result := FData.Edges;
end;

function TAasFile.GetEdgeIndex: TArray<Integer>;
begin
  Result := FData.EdgeIndex;
end;

function TAasFile.GetFaces: TArray<TAasFace>;
begin
  Result := FData.Faces;
end;

function TAasFile.GetFaceIndex: TArray<Integer>;
begin
  Result := FData.FaceIndex;
end;

function TAasFile.GetAreas: TArray<TAasArea>;
begin
  Result := FData.Areas;
end;

function TAasFile.GetAreaSettings: TArray<TAasAreaSettings>;
begin
  Result := FData.AreaSettings;
end;

function TAasFile.GetReachability: TArray<TAasReachability>;
begin
  Result := FData.Reachability;
end;

function TAasFile.GetNodes: TArray<TAasNode>;
begin
  Result := FData.Nodes;
end;

function TAasFile.GetPortals: TArray<TAasPortal>;
begin
  Result := FData.Portals;
end;

function TAasFile.GetPortalIndex: TArray<Integer>;
begin
  Result := FData.PortalIndex;
end;

function TAasFile.GetClusters: TArray<TAasCluster>;
begin
  Result := FData.Clusters;
end;

function TAasFile.LumpBytes(const AIndex: Integer): TBytes;
begin
  case AIndex of
    AASLUMP_BBOXES: Result := Raw(Pointer(FData.BBoxes), Length(FData.BBoxes) * SizeOf(TAasBBox));
    AASLUMP_VERTEXES: Result := Raw(Pointer(FData.Vertexes), Length(FData.Vertexes) * SizeOf(TVec3));
    AASLUMP_PLANES: Result := Raw(Pointer(FData.Planes), Length(FData.Planes) * SizeOf(TAasPlane));
    AASLUMP_EDGES: Result := Raw(Pointer(FData.Edges), Length(FData.Edges) * SizeOf(TAasEdge));
    AASLUMP_EDGEINDEX: Result := Raw(Pointer(FData.EdgeIndex), Length(FData.EdgeIndex) * SizeOf(Integer));
    AASLUMP_FACES: Result := Raw(Pointer(FData.Faces), Length(FData.Faces) * SizeOf(TAasFace));
    AASLUMP_FACEINDEX: Result := Raw(Pointer(FData.FaceIndex), Length(FData.FaceIndex) * SizeOf(Integer));
    AASLUMP_AREAS: Result := Raw(Pointer(FData.Areas), Length(FData.Areas) * SizeOf(TAasArea));
    AASLUMP_AREASETTINGS: Result := Raw(Pointer(FData.AreaSettings), Length(FData.AreaSettings) * SizeOf(TAasAreaSettings));
    AASLUMP_REACHABILITY: Result := Raw(Pointer(FData.Reachability), Length(FData.Reachability) * SizeOf(TAasReachability));
    AASLUMP_NODES: Result := Raw(Pointer(FData.Nodes), Length(FData.Nodes) * SizeOf(TAasNode));
    AASLUMP_PORTALS: Result := Raw(Pointer(FData.Portals), Length(FData.Portals) * SizeOf(TAasPortal));
    AASLUMP_PORTALINDEX: Result := Raw(Pointer(FData.PortalIndex), Length(FData.PortalIndex) * SizeOf(Integer));
    AASLUMP_CLUSTERS: Result := Raw(Pointer(FData.Clusters), Length(FData.Clusters) * SizeOf(TAasCluster));
  else
    Result := nil;
  end;
end;

end.
