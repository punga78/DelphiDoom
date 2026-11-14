{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - what the reachability calculators share           }
{                                                                              }
{  The original keeps all of this in globals (aasworld, aassettings, the heap  }
{  and the reach_* counters of be_aas_reach.c). Based on the Quake III Arena   }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Context;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Links,
  DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Intf, DelphiDoom.Aas.Reach.Heap;

type
  /// <summary>
  ///   The objects, the tables of the file and the counters that every kind of reachability uses. Nothing is owned except
  ///   the heap, which the calculator makes and drops. The tables are the arrays of the file (not copies): the calculation
  ///   changes the area flags in place and does not change anything else until it stores the table of the reachabilities
  /// </summary>
  TAasReachContext = class
  strict private
    FFile: IAasFile;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FFaces: IAasFaceTester;
    FMovement: IAasMovement;
    FWorld: IAasBspWorld;
    FModels: IAasBspModels;
    FEntities: IAasBspEntities;
    FLinks: TAasEntityLinks;
    FImport: IBotImport;
    FGeometry: IAasReachGeometry;
    FPhysics: IAasReachPhysics;
    FSettings: TAasMoveSettings;
    FHeap: TAasReachHeap;
    FCounters: TAasReachCounters;
    FCalculateGrapple: Boolean;
    FAreas: TArray<TAasArea>;
    FAreaSettings: TArray<TAasAreaSettings>;
    FPlanes: TArray<TAasPlane>;
    FEdges: TArray<TAasEdge>;
    FEdgeIndex: TArray<Integer>;
    FFaceTable: TArray<TAasFace>;
    FFaceIndex: TArray<Integer>;
    FVertexes: TArray<TVec3>;
    function GetNumAreas: Integer;
    function GetCounters: PAasReachCounters;
  public
    constructor Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
      const AFaces: IAasFaceTester; const AMovement: IAasMovement; const AWorld: IAasBspWorld;
      const AModels: IAasBspModels; const AEntities: IAasBspEntities; const ALinks: TAasEntityLinks;
      const AImport: IBotImport; const AGeometry: IAasReachGeometry; const APhysics: IAasReachPhysics);
    /// <summary>aassettings</summary>
    property Settings: TAasMoveSettings read FSettings;
    property AasFile: IAasFile read FFile;
    property Sampler: IAasSampler read FSampler;
    property Tracer: IAasTracer read FTracer;
    property FaceTester: IAasFaceTester read FFaces;
    property Movement: IAasMovement read FMovement;
    property World: IAasBspWorld read FWorld;
    property Models: IAasBspModels read FModels;
    property Entities: IAasBspEntities read FEntities;
    /// <summary>The entities linked to the areas (not owned)</summary>
    property Links: TAasEntityLinks read FLinks;
    property Import: IBotImport read FImport;
    property Geometry: IAasReachGeometry read FGeometry;
    property Physics: IAasReachPhysics read FPhysics;
    /// <summary>The heap of the temporary links; nil until the calculation starts and after it stores the table</summary>
    property Heap: TAasReachHeap read FHeap write FHeap;
    property Areas: TArray<TAasArea> read FAreas;
    property AreaSettings: TArray<TAasAreaSettings> read FAreaSettings;
    property Planes: TArray<TAasPlane> read FPlanes;
    property Edges: TArray<TAasEdge> read FEdges;
    property EdgeIndex: TArray<Integer> read FEdgeIndex;
    property FaceTable: TArray<TAasFace> read FFaceTable;
    property FaceIndex: TArray<Integer> read FFaceIndex;
    property Vertexes: TArray<TVec3> read FVertexes;
    /// <summary>aasworld.numareas</summary>
    property NumAreas: Integer read GetNumAreas;
    /// <summary>calcgrapplereach: if False the grapple reachabilities are skipped</summary>
    property CalculateGrapple: Boolean read FCalculateGrapple write FCalculateGrapple;
    /// <summary>The numbers of reachabilities of each type (reach_swim ...): the calculators count into it</summary>
    property Counters: PAasReachCounters read GetCounters;
    /// <summary>AAS_AreaGrounded .. AAS_AreaClusterPortal: the flag of the area, with no check of the number (as the original)</summary>
    function AreaGrounded(const AAreaNum: Integer): Boolean; inline;
    function AreaSwim(const AAreaNum: Integer): Boolean; inline;
    function AreaCrouch(const AAreaNum: Integer): Boolean; inline;
    function AreaLadder(const AAreaNum: Integer): Boolean; inline;
    function AreaJumpPad(const AAreaNum: Integer): Boolean; inline;
    function AreaTeleporter(const AAreaNum: Integer): Boolean; inline;
    function AreaClusterPortal(const AAreaNum: Integer): Boolean; inline;
    /// <summary>AAS_TravelFlagsForTeam: TRAVELFLAG_NOTTEAM1 or 2 from the key bot_notteam of the entity</summary>
    function TravelFlagsForTeam(const AEntity: Integer): Integer;
    /// <summary>AAS_AreaReachability on the temporary lists: True if there is a link from the area to the other</summary>
    function ReachabilityExists(const AFromArea, AToArea: Integer): Boolean;
    /// <summary>AAS_TraceAreas: the number of areas the line goes through (at most AMaxAreas)</summary>
    function TraceAreas(const AStart, AEnd: TVec3; const AMaxAreas: Integer; out AAreas: TArray<Integer>;
      out APoints: TArray<TVec3>): Integer;
    /// <summary>A link that must exist: the original does not look at a NULL (EAasReachException)</summary>
    function AllocateLink: PAasLinkedReach;
  end;

implementation

resourcestring
  SNoLink = 'AAS reachability: no link left in the heap';

{ TAasReachContext }

constructor TAasReachContext.Create(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
  const AFaces: IAasFaceTester; const AMovement: IAasMovement; const AWorld: IAasBspWorld;
  const AModels: IAasBspModels; const AEntities: IAasBspEntities; const ALinks: TAasEntityLinks;
  const AImport: IBotImport; const AGeometry: IAasReachGeometry; const APhysics: IAasReachPhysics);
begin
  inherited Create;
  FFile := AFile;
  FSampler := ASampler;
  FTracer := ATracer;
  FFaces := AFaces;
  FMovement := AMovement;
  FWorld := AWorld;
  FModels := AModels;
  FEntities := AEntities;
  FLinks := ALinks;
  FImport := AImport;
  FGeometry := AGeometry;
  FPhysics := APhysics;
  FSettings := AMovement.Settings;
  FAreas := AFile.Areas;
  FAreaSettings := AFile.AreaSettings;
  FPlanes := AFile.Planes;
  FEdges := AFile.Edges;
  FEdgeIndex := AFile.EdgeIndex;
  FFaceTable := AFile.Faces;
  FFaceIndex := AFile.FaceIndex;
  FVertexes := AFile.Vertexes;
  FillChar(FCounters, SizeOf(FCounters), 0);
end;

function TAasReachContext.GetNumAreas: Integer;
begin
  Result := Length(FAreaSettings);
end;

function TAasReachContext.GetCounters: PAasReachCounters;
begin
  Result := @FCounters;
end;

function TAasReachContext.AreaGrounded(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].AreaFlags and AREA_GROUNDED) <> 0;
end;

function TAasReachContext.AreaSwim(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].AreaFlags and AREA_LIQUID) <> 0;
end;

function TAasReachContext.AreaCrouch(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].PresenceType and PRESENCE_NORMAL) = 0;
end;

function TAasReachContext.AreaLadder(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].AreaFlags and AREA_LADDER) <> 0;
end;

function TAasReachContext.AreaJumpPad(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].Contents and AREACONTENTS_JUMPPAD) <> 0;
end;

function TAasReachContext.AreaTeleporter(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].Contents and AREACONTENTS_TELEPORTER) <> 0;
end;

function TAasReachContext.AreaClusterPortal(const AAreaNum: Integer): Boolean;
begin
  Result := (FAreaSettings[AAreaNum].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0;
end;

function TAasReachContext.TravelFlagsForTeam(const AEntity: Integer): Integer;
var
  LNotTeam: Integer;
begin
  Result := 0;
  if not FEntities.IntForKey(AEntity, 'bot_notteam', LNotTeam) then
    Exit;
  if LNotTeam = 1 then
    Result := TRAVELFLAG_NOTTEAM1
  else if LNotTeam = 2 then
    Result := TRAVELFLAG_NOTTEAM2;
end;

function TAasReachContext.ReachabilityExists(const AFromArea, AToArea: Integer): Boolean;
begin
  Result := FHeap.Exists(AFromArea, AToArea);
end;

function TAasReachContext.TraceAreas(const AStart, AEnd: TVec3; const AMaxAreas: Integer;
  out AAreas: TArray<Integer>; out APoints: TArray<TVec3>): Integer;
begin
  Result := FTracer.TraceAreas(AStart, AEnd, AMaxAreas, AAreas, APoints);
end;

function TAasReachContext.AllocateLink: PAasLinkedReach;
begin
  Result := FHeap.Allocate;
  if Result = nil then
    raise EAasReachException.Create(SNoLink);
end;

end.
