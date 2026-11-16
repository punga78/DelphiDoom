{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the tables that the clustering works on           }
{                                                                              }
{  The part of aasworld that be_aas_cluster.c reads and writes. Based on the   }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Cluster.World;

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   The areas, faces and reachabilities of a file (shared with it: a change of an area setting is a change of the
  ///   file) and the tables that the clustering fills: portals, portal index and clusters, made with the sizes of the
  ///   original (65536) and counted as the original counts them (<c>NumPortals</c>, <c>PortalIndexSize</c>,
  ///   <c>NumClusters</c>). The file and the import are not owned
  /// </summary>
  TAasClusterWorld = class
  strict private
    FImport: IBotImport;
    FAreaSettings: TArray<TAasAreaSettings>;
    FAreas: TArray<TAasArea>;
    FFaces: TArray<TAasFace>;
    FFaceIndex: TArray<Integer>;
    FEdgeIndex: TArray<Integer>;
    FReachability: TArray<TAasReachability>;
    FPortals: TArray<TAasPortal>;
    FPortalIndex: TArray<Integer>;
    FClusters: TArray<TAasCluster>;
    FNumPortals: Integer;
    FPortalIndexSize: Integer;
    FNumClusters: Integer;
    FNumAreas: Integer;
    procedure Validate;
  public
    /// <summary>Takes the tables of the file; a number outside them is an EAasClusterException</summary>
    constructor Create(const AFile: IAasFile; const AImport: IBotImport);
    /// <summary>
    ///   Makes the tables for the portals, the portal index and the clusters, empty (AAS_InitClustering allocates them
    ///   for the largest sizes)
    /// </summary>
    procedure AllocateClusterTables;
    /// <summary>botimport.Print</summary>
    procedure Print(const ALevel: Integer; const AMessage: string);
    /// <summary>AAS_Error: PRT_FATAL, the message has its own line feed if the original has</summary>
    procedure Error(const AMessage: string);
    /// <summary>Log_Write</summary>
    procedure LogWrite(const AMessage: string);
    /// <summary>AAS_AreaReachability: the number of reachabilities of the area (0 is false)</summary>
    function AreaReachability(const AAreaNum: Integer): Integer;
    property NumAreas: Integer read FNumAreas;
    property AreaSettings: TArray<TAasAreaSettings> read FAreaSettings;
    property Areas: TArray<TAasArea> read FAreas;
    property Faces: TArray<TAasFace> read FFaces;
    property FaceIndex: TArray<Integer> read FFaceIndex;
    property EdgeIndex: TArray<Integer> read FEdgeIndex;
    property Reachability: TArray<TAasReachability> read FReachability;
    property Portals: TArray<TAasPortal> read FPortals;
    property PortalIndex: TArray<Integer> read FPortalIndex;
    property Clusters: TArray<TAasCluster> read FClusters;
    property NumPortals: Integer read FNumPortals write FNumPortals;
    property PortalIndexSize: Integer read FPortalIndexSize write FPortalIndexSize;
    property NumClusters: Integer read FNumClusters write FNumClusters;
  end;

implementation

uses
  DelphiDoom.Aas.Cluster.Types;

resourcestring
  SNoAreas = 'AAS clustering: the file has no area settings for its areas';
  SReachOutOfRange = 'AAS clustering: area %d has reachabilities that are not in the reachability lump';
  SReachAreaOutOfRange = 'AAS clustering: a reachability leads to area %d, which the file does not hold';
  SFaceRange = 'AAS clustering: area %d refers to faces that the file does not hold';
  SFaceAreaRange = 'AAS clustering: face %d leads to an area that the file does not hold';

{ TAasClusterWorld }

constructor TAasClusterWorld.Create(const AFile: IAasFile; const AImport: IBotImport);
begin
  inherited Create;
  FImport := AImport;
  FAreaSettings := AFile.AreaSettings;
  FAreas := AFile.Areas;
  FFaces := AFile.Faces;
  FFaceIndex := AFile.FaceIndex;
  FEdgeIndex := AFile.EdgeIndex;
  FReachability := AFile.Reachability;
  FNumAreas := Length(FAreas);
  FNumClusters := Length(AFile.Clusters);
  FNumPortals := Length(AFile.Portals);
  FPortalIndexSize := Length(AFile.PortalIndex);
  FPortals := AFile.Portals;
  FPortalIndex := AFile.PortalIndex;
  FClusters := AFile.Clusters;
  Validate;
end;

procedure TAasClusterWorld.Validate;
var
  LIndex, LPosition: Integer;
begin
  if (FNumAreas < 1) or (Length(FAreaSettings) < FNumAreas) then
    raise EAasClusterException.Create(SNoAreas);
  for LIndex := 0 to FNumAreas - 1 do
  begin
    if (FAreaSettings[LIndex].FirstReachableArea < 0) or (FAreaSettings[LIndex].NumReachableAreas < 0) or
      (Int64(FAreaSettings[LIndex].FirstReachableArea) + FAreaSettings[LIndex].NumReachableAreas >
      Length(FReachability)) then
      raise EAasClusterException.Create(Format(SReachOutOfRange, [LIndex]));
    if (FAreas[LIndex].FirstFace < 0) or (FAreas[LIndex].NumFaces < 0) or
      (Int64(FAreas[LIndex].FirstFace) + FAreas[LIndex].NumFaces > Length(FFaceIndex)) then
      raise EAasClusterException.Create(Format(SFaceRange, [LIndex]));
    for LPosition := FAreas[LIndex].FirstFace to FAreas[LIndex].FirstFace + FAreas[LIndex].NumFaces - 1 do
      if Abs(FFaceIndex[LPosition]) >= Length(FFaces) then
        raise EAasClusterException.Create(Format(SFaceRange, [LIndex]));
  end;
  for LIndex := 0 to High(FReachability) do
    if (FReachability[LIndex].AreaNum < 0) or (FReachability[LIndex].AreaNum >= FNumAreas) then
      raise EAasClusterException.Create(Format(SReachAreaOutOfRange, [FReachability[LIndex].AreaNum]));
  for LIndex := 0 to High(FFaces) do
    if (FFaces[LIndex].FirstEdge < 0) or (FFaces[LIndex].NumEdges < 0) or
      (Int64(FFaces[LIndex].FirstEdge) + FFaces[LIndex].NumEdges > Length(FEdgeIndex)) then
      raise EAasClusterException.Create(Format(SFaceAreaRange, [LIndex]))
    else if (FFaces[LIndex].FrontArea < 0) or (FFaces[LIndex].FrontArea >= FNumAreas) or
      (FFaces[LIndex].BackArea < 0) or (FFaces[LIndex].BackArea >= FNumAreas) then
      raise EAasClusterException.Create(Format(SFaceAreaRange, [LIndex]));
end;

procedure TAasClusterWorld.AllocateClusterTables;
begin
  FPortals := nil;
  FPortalIndex := nil;
  FClusters := nil;
  SetLength(FPortals, AAS_MAX_PORTALS);
  SetLength(FPortalIndex, AAS_MAX_PORTALINDEXSIZE);
  SetLength(FClusters, AAS_MAX_CLUSTERS);
end;

procedure TAasClusterWorld.Print(const ALevel: Integer; const AMessage: string);
begin
  if Assigned(FImport) then
    FImport.Print(ALevel, AnsiString(AMessage));
end;

procedure TAasClusterWorld.Error(const AMessage: string);
begin
  Print(4, AMessage);
end;

procedure TAasClusterWorld.LogWrite(const AMessage: string);
begin
  if Assigned(FImport) then
    FImport.LogWrite(AnsiString(AMessage));
end;

function TAasClusterWorld.AreaReachability(const AAreaNum: Integer): Integer;
begin
  Result := FAreaSettings[AAreaNum].NumReachableAreas;
end;

end.
