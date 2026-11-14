{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the scenario of the clustering and   }
{  optimizer golden                                                            }
{                                                                              }
{  The twin of Tools\Verifica\122\cluster\clustergen.c: every line that the    }
{  real be_aas_cluster.c and be_aas_optimize.c print is printed here with the  }
{  same text.                                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Cluster.Scenario;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf;

type
  /// <summary>Runs the five cases on one .aas file (its bytes) and writes the lines of the C tool</summary>
  TAasClusterScenario = class
  strict private
    FOutput: TStrings;
    FImport: IBotImport;
    FHash: Cardinal;
    procedure H(const AValue: Cardinal);
    function Load(const ABytes: TBytes): IAasFile;
    procedure DumpClusters(const ATag: string; const AFile: IAasFile);
    procedure DumpGeometry(const AFile: IAasFile);
    procedure WipeClusters(const AFile: IAasFile);
  public
    constructor Create(const AOutput: TStrings);
    procedure Run(const AName: string; const ABytes: TBytes);
  end;

implementation

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.HeaderCipher, DelphiDoom.Aas.Factory,
  DelphiDoom.Aas.Editor.Intf, DelphiDoom.Aas.Cluster.Intf, DelphiDoom.Aas.Cluster.Initializer,
  DelphiDoom.Tests.Aas.Support;

type
  TScenarioImport = class(TInterfacedObject, IBotImport)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
  end;

  /// <summary>forceclustering is the only variable that the clustering asks for</summary>
  TScenarioLibVars = class(TInterfacedObject, IBotLibVars)
  strict private
    FForce: Boolean;
  public
    constructor Create(const AForce: Boolean);
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

{ TScenarioImport }

constructor TScenarioImport.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TScenarioImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FOutput.Add(Format('P%d|%s', [ALevel, Escaped(string(AMessage))]));
end;

procedure TScenarioImport.LogWrite(const AMessage: AnsiString);
begin
  FOutput.Add('L|' + Escaped(string(AMessage)));
end;

function TScenarioImport.Time: Single;
begin
  Result := 0;
end;

procedure TScenarioImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

{ TScenarioLibVars }

constructor TScenarioLibVars.Create(const AForce: Boolean);
begin
  inherited Create;
  FForce := AForce;
end;

function TScenarioLibVars.GetValue(const AName: AnsiString): Single;
begin
  if FForce and (AName = 'forceclustering') then
    Result := 1
  else
    Result := 0;
end;

function TScenarioLibVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  Result := 0;
end;

function TScenarioLibVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  Result := '';
end;

{ TAasClusterScenario }

constructor TAasClusterScenario.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
  FImport := TScenarioImport.Create(AOutput);
end;

procedure TAasClusterScenario.H(const AValue: Cardinal);
begin
  FHash := FHash xor AValue;
  FHash := FHash * 16777619;
end;

function TAasClusterScenario.Load(const ABytes: TBytes): IAasFile;
var
  LHeader: TAasFileHeader;
begin
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  Result := TAasFactory.CreateReader(FImport, nil, nil).ParseBytes(ABytes, 'maps/cluster.aas', LHeader.BspChecksum);
end;

procedure TAasClusterScenario.WipeClusters(const AFile: IAasFile);
var
  LIndex: Integer;
  LSettings: TArray<TAasAreaSettings>;
  LEditor: IAasFileEditor;
begin
  Supports(AFile, IAasFileEditor, LEditor);
  LEditor.ReplaceClusterData(nil, nil, nil);
  LSettings := AFile.AreaSettings;
  for LIndex := 0 to High(LSettings) do
  begin
    LSettings[LIndex].Cluster := 0;
    LSettings[LIndex].ClusterAreaNum := 0;
  end;
end;

procedure TAasClusterScenario.DumpClusters(const ATag: string; const AFile: IAasFile);
var
  LIndex, LCount: Integer;
  LPortals: TArray<TAasPortal>;
  LClusters: TArray<TAasCluster>;
  LPortalIndex: TArray<Integer>;
  LSettings: TArray<TAasAreaSettings>;
begin
  LPortals := AFile.Portals;
  LClusters := AFile.Clusters;
  LPortalIndex := AFile.PortalIndex;
  LSettings := AFile.AreaSettings;
  FOutput.Add(Format('%s %d %d %d', [ATag, Length(LPortals), Length(LPortalIndex), Length(LClusters)]));
  for LIndex := 1 to High(LPortals) do
    FOutput.Add(Format('PO %d %d %d %d %d %d', [LIndex, LPortals[LIndex].AreaNum, LPortals[LIndex].FrontCluster,
      LPortals[LIndex].BackCluster, LPortals[LIndex].ClusterAreaNum[0], LPortals[LIndex].ClusterAreaNum[1]]));
  for LIndex := 1 to High(LClusters) do
    FOutput.Add(Format('CL %d %d %d %d %d', [LIndex, LClusters[LIndex].NumAreas, LClusters[LIndex].NumReachabilityAreas,
      LClusters[LIndex].NumPortals, LClusters[LIndex].FirstPortal]));
  FHash := 2166136261;
  for LIndex := 0 to High(LPortalIndex) do
    H(Cardinal(LPortalIndex[LIndex]));
  FOutput.Add(Format('PI %u', [FHash]));
  FHash := 2166136261;
  LCount := Length(AFile.Areas);
  for LIndex := 0 to LCount - 1 do
  begin
    H(Cardinal(LSettings[LIndex].Contents));
    H(Cardinal(LSettings[LIndex].Cluster));
    H(Cardinal(LSettings[LIndex].ClusterAreaNum));
    H(Cardinal(LSettings[LIndex].AreaFlags));
  end;
  FOutput.Add(Format('SH %u', [FHash]));
  for LIndex := 0 to LCount - 1 do
  begin
    if LIndex >= 40 then
      Break;
    FOutput.Add(Format('SA %d %d %d %d', [LIndex, LSettings[LIndex].Contents, LSettings[LIndex].Cluster,
      LSettings[LIndex].ClusterAreaNum]));
  end;
end;

procedure TAasClusterScenario.DumpGeometry(const AFile: IAasFile);
var
  LIndex, LJ: Integer;
  LVertexes: TArray<TVec3>;
  LEdges: TArray<TAasEdge>;
  LEdgeIndex, LFaceIndex: TArray<Integer>;
  LFaces: TArray<TAasFace>;
  LAreas: TArray<TAasArea>;
  LReach: TArray<TAasReachability>;
  function Bits(const AValue: Single): Cardinal;
  begin
    Move(AValue, Result, SizeOf(Result));
  end;
begin
  LVertexes := AFile.Vertexes;
  LEdges := AFile.Edges;
  LEdgeIndex := AFile.EdgeIndex;
  LFaces := AFile.Faces;
  LFaceIndex := AFile.FaceIndex;
  LAreas := AFile.Areas;
  LReach := AFile.Reachability;
  FOutput.Add(Format('GEO %d %d %d %d %d %d', [Length(LVertexes), Length(LEdges), Length(LEdgeIndex), Length(LFaces),
    Length(LFaceIndex), Length(LAreas)]));
  FHash := 2166136261;
  for LIndex := 0 to High(LVertexes) do
    for LJ := 0 to 2 do
      H(Bits(LVertexes[LIndex][LJ]));
  FOutput.Add(Format('GV %u', [FHash]));
  FHash := 2166136261;
  for LIndex := 0 to High(LEdges) do
  begin
    H(Cardinal(LEdges[LIndex].Vertexes[0]));
    H(Cardinal(LEdges[LIndex].Vertexes[1]));
  end;
  FOutput.Add(Format('GD %u', [FHash]));
  FHash := 2166136261;
  for LIndex := 0 to High(LEdgeIndex) do
    H(Cardinal(LEdgeIndex[LIndex]));
  FOutput.Add(Format('GI %u', [FHash]));
  FHash := 2166136261;
  for LIndex := 0 to High(LFaces) do
  begin
    H(Cardinal(LFaces[LIndex].PlaneNum));
    H(Cardinal(LFaces[LIndex].FaceFlags));
    H(Cardinal(LFaces[LIndex].NumEdges));
    H(Cardinal(LFaces[LIndex].FirstEdge));
    H(Cardinal(LFaces[LIndex].FrontArea));
    H(Cardinal(LFaces[LIndex].BackArea));
  end;
  FOutput.Add(Format('GC %u', [FHash]));
  FHash := 2166136261;
  for LIndex := 0 to High(LFaceIndex) do
    H(Cardinal(LFaceIndex[LIndex]));
  FOutput.Add(Format('GJ %u', [FHash]));
  FHash := 2166136261;
  for LIndex := 0 to High(LAreas) do
  begin
    H(Cardinal(LAreas[LIndex].AreaNum));
    H(Cardinal(LAreas[LIndex].NumFaces));
    H(Cardinal(LAreas[LIndex].FirstFace));
    for LJ := 0 to 2 do
    begin
      H(Bits(LAreas[LIndex].Mins[LJ]));
      H(Bits(LAreas[LIndex].Maxs[LJ]));
      H(Bits(LAreas[LIndex].Center[LJ]));
    end;
  end;
  FOutput.Add(Format('GR %u', [FHash]));
  FHash := 2166136261;
  for LIndex := 0 to High(LReach) do
  begin
    H(Cardinal(LReach[LIndex].FaceNum));
    H(Cardinal(LReach[LIndex].EdgeNum));
  end;
  FOutput.Add(Format('GK %u', [FHash]));
  for LIndex := 0 to High(LEdges) do
  begin
    if LIndex >= 12 then
      Break;
    FOutput.Add(Format('GE %d %d %d', [LIndex, LEdges[LIndex].Vertexes[0], LEdges[LIndex].Vertexes[1]]));
  end;
  for LIndex := 0 to High(LFaces) do
  begin
    if LIndex >= 12 then
      Break;
    FOutput.Add(Format('GF %d %d %d %d %d %d %d', [LIndex, LFaces[LIndex].PlaneNum, LFaces[LIndex].FaceFlags,
      LFaces[LIndex].NumEdges, LFaces[LIndex].FirstEdge, LFaces[LIndex].FrontArea, LFaces[LIndex].BackArea]));
  end;
  for LIndex := 0 to High(LAreas) do
  begin
    if LIndex >= 12 then
      Break;
    FOutput.Add(Format('GA %d %d %d', [LIndex, LAreas[LIndex].NumFaces, LAreas[LIndex].FirstFace]));
  end;
end;

procedure TAasClusterScenario.Run(const AName: string; const ABytes: TBytes);
var
  LFile: IAasFile;
  LInit: TAasClusterInitializer;
  LInitIntf: IAasClusterInitializer;
  LFaces: TArray<TAasFace>;
  LIndex: Integer;
begin
  FOutput.Add('FILE ' + AName);
  LFile := Load(ABytes);
  FOutput.Add('LOAD 0');
  // A: nothing is forced
  TAasFactory.CreateClusterInitializer(LFile, FImport, TScenarioLibVars.Create(False)).InitClustering;
  DumpClusters('A', LFile);
  // B: forced
  TAasFactory.CreateClusterInitializer(LFile, FImport, TScenarioLibVars.Create(True)).InitClustering;
  DumpClusters('B', LFile);
  // C: the clusters are wiped
  LFile := Load(ABytes);
  WipeClusters(LFile);
  TAasFactory.CreateClusterInitializer(LFile, FImport, TScenarioLibVars.Create(False)).InitClustering;
  DumpClusters('C', LFile);
  // D: the optimizer
  LFile := Load(ABytes);
  TAasFactory.CreateOptimizer(LFile, FImport).Optimize;
  DumpGeometry(LFile);
  // E: the optimizer on a file where every seventh face is a ladder face
  LFile := Load(ABytes);
  LFaces := LFile.Faces;
  for LIndex := 0 to High(LFaces) do
    if LIndex mod 7 = 3 then
      LFaces[LIndex].FaceFlags := LFaces[LIndex].FaceFlags or FACE_LADDER;
  TAasFactory.CreateOptimizer(LFile, FImport).Optimize;
  DumpGeometry(LFile);
  // F: the clusters wiped and flooded through the faces too
  LFile := Load(ABytes);
  WipeClusters(LFile);
  LInit := TAasClusterInitializer.Create(LFile, FImport, TScenarioLibVars.Create(False));
  LInitIntf := LInit;
  LInit.NoFaceFlood := False;
  LInitIntf.InitClustering;
  DumpClusters('F', LFile);
end;

end.
