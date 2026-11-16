{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - AAS_InitClustering (be_aas_cluster.c)             }
{                                                                              }
{  Port of AAS_InitClustering, AAS_CountForcedClusterPortals,                  }
{  AAS_CreateViewPortals and AAS_SetViewPortalsAsClusterPortals. Based on the  }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Cluster.Initializer;

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Cluster.Intf;

type
  /// <summary>
  ///   Makes the portals and the clusters of a file that is loaded, writes them into the file and the numbers of the
  ///   areas inside their clusters into its area settings. The file, the import and the variables are not owned
  /// </summary>
  TAasClusterInitializer = class(TInterfacedObject, IAasClusterInitializer)
  strict private
    FFile: IAasFile;
    FImport: IBotImport;
    FLibVars: IBotLibVars;
    FNoFaceFlood: Boolean;
  public
    /// <summary>
    ///   The file must be changeable (<c>IAasFileEditor</c>: TAasFile is). The variables give forceclustering and
    ///   forcereachability and may be nil (nothing is forced)
    /// </summary>
    constructor Create(const AFile: IAasFile; const AImport: IBotImport; const ALibVars: IBotLibVars);
    function InitClustering: Boolean;
    /// <summary>nofaceflood of the original (True): the flood goes through reachabilities only</summary>
    property NoFaceFlood: Boolean read FNoFaceFlood write FNoFaceFlood;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Editor.Intf, DelphiDoom.Aas.Cluster.Types,
  DelphiDoom.Aas.Cluster.World, DelphiDoom.Aas.Cluster.Builder, DelphiDoom.Aas.Cluster.PortalFinder;

resourcestring
  SNotEditable = 'AAS clustering: the file cannot be changed (it does not implement IAasFileEditor)';
  SNoProgress = 'AAS clustering: the search for clusters made no progress after %d tries';

{ TAasClusterInitializer }

constructor TAasClusterInitializer.Create(const AFile: IAasFile; const AImport: IBotImport;
  const ALibVars: IBotLibVars);
begin
  inherited Create;
  FFile := AFile;
  FImport := AImport;
  FLibVars := ALibVars;
  FNoFaceFlood := True;
end;

function TAasClusterInitializer.InitClustering: Boolean;
var
  LEditor: IAasFileEditor;
  LWorld: TAasClusterWorld;
  LBuilder: TAasClusterBuilder;
  LFinder: TAasPortalFinder;
  LIndex, LRemoved, LNum, LTotal, LReachabilityAreas, LPortalAreas, LLastPortalAreas: Integer;
  LFailed: Boolean;
  LClusters: TArray<TAasCluster>;
  LPortals: TArray<TAasPortal>;
  LPortalIndex: TArray<Integer>;
begin
  if not Supports(FFile, IAasFileEditor, LEditor) then
    raise EAasClusterException.Create(SNotEditable);
  LWorld := TAasClusterWorld.Create(FFile, FImport);
  try
    // if there are clusters
    if LWorld.NumClusters >= 1 then
      // if clustering isn't forced
      if not Assigned(FLibVars) or ((Trunc(FLibVars.GetValue('forceclustering')) = 0) and
        (Trunc(FLibVars.GetValue('forcereachability')) = 0)) then
        Exit(False);
    LBuilder := TAasClusterBuilder.Create(LWorld);
    LBuilder.NoFaceFlood := FNoFaceFlood;
    LFinder := TAasPortalFinder.Create(LWorld);
    try
      // set all view portals as cluster portals in case we re-calculate the reachabilities and clusters
      for LIndex := 1 to LWorld.NumAreas - 1 do
        if (LWorld.AreaSettings[LIndex].Contents and AREACONTENTS_VIEWPORTAL) <> 0 then
          LWorld.AreaSettings[LIndex].Contents := LWorld.AreaSettings[LIndex].Contents or AREACONTENTS_CLUSTERPORTAL;
      // count the number of forced cluster portals
      LNum := 0;
      for LIndex := 1 to LWorld.NumAreas - 1 do
        if (LWorld.AreaSettings[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
        begin
          LWorld.LogWrite(Format('area %d is a forced portal area'#13#10, [LIndex]));
          Inc(LNum);
        end;
      LWorld.Print(PRT_MESSAGE, Format('%6d forced portal areas'#10, [LNum]));
      // remove all area cluster marks
      LBuilder.RemoveClusterAreas;
      // find possible cluster portals
      LFinder.FindPossiblePortals;
      // create portals to for the bot view
      for LIndex := 1 to LWorld.NumAreas - 1 do
        if (LWorld.AreaSettings[LIndex].Contents and AREACONTENTS_CLUSTERPORTAL) <> 0 then
          LWorld.AreaSettings[LIndex].Contents := LWorld.AreaSettings[LIndex].Contents or AREACONTENTS_VIEWPORTAL;
      // initialize portal, portal index and cluster memory
      LWorld.AllocateClusterTables;
      LRemoved := 0;
      LLastPortalAreas := -1;
      LWorld.Print(PRT_MESSAGE, Format(#13'%6d removed portal areas', [LRemoved]));
      while True do
      begin
        LWorld.Print(PRT_MESSAGE, Format(#13'%6d', [LRemoved]));
        // initialize the number of portals and clusters
        LWorld.NumPortals := 1; // portal 0 is a dummy
        LWorld.PortalIndexSize := 0;
        LWorld.NumClusters := 1; // cluster 0 is a dummy
        // create the portals from the portal areas
        LBuilder.CreatePortals;
        // the C loops for ever when a search fails and no portal flag was removed
        LPortalAreas := LWorld.NumPortals;
        if (LLastPortalAreas = LPortalAreas) then
          raise EAasClusterException.Create(Format(SNoProgress, [LRemoved]));
        LFailed := False;
        Inc(LRemoved);
        // find the clusters
        if not LBuilder.FindClusters then
          LFailed := True
        // test the portals
        else if not LBuilder.TestPortals then
          LFailed := True;
        if not LFailed then
          Break;
        LLastPortalAreas := LPortalAreas;
      end;
      LWorld.Print(PRT_MESSAGE, #10);
      // write the portal areas to the log file
      for LIndex := 1 to LWorld.NumPortals - 1 do
        LWorld.LogWrite(Format('portal %d: area %d'#13#10, [LIndex, LWorld.Portals[LIndex].AreaNum]));
      // report cluster info
      LWorld.Print(PRT_MESSAGE, Format('%6d portals created'#10, [LWorld.NumPortals]));
      LWorld.Print(PRT_MESSAGE, Format('%6d clusters created'#10, [LWorld.NumClusters]));
      for LIndex := 1 to LWorld.NumClusters - 1 do
        LWorld.Print(PRT_MESSAGE, Format('cluster %d has %d reachability areas'#10,
          [LIndex, LWorld.Clusters[LIndex].NumReachabilityAreas]));
      // report AAS file efficiency
      LReachabilityAreas := 0;
      LTotal := 0;
      for LIndex := 0 to LWorld.NumClusters - 1 do
      begin
        LNum := LWorld.Clusters[LIndex].NumReachabilityAreas;
        Inc(LReachabilityAreas, LNum);
        Inc(LTotal, LNum * LNum);
      end;
      Inc(LTotal, LReachabilityAreas * LWorld.NumPortals);
      LWorld.Print(PRT_MESSAGE, Format('%6d total reachability areas'#10, [LReachabilityAreas]));
      LWorld.Print(PRT_MESSAGE, Format('%6d AAS memory/CPU usage (the lower the better)'#10, [LTotal * 3]));
      // the tables of the file have the number of entries that were counted
      LClusters := Copy(LWorld.Clusters, 0, LWorld.NumClusters);
      LPortals := Copy(LWorld.Portals, 0, LWorld.NumPortals);
      LPortalIndex := Copy(LWorld.PortalIndex, 0, LWorld.PortalIndexSize);
      LEditor.ReplaceClusterData(LClusters, LPortals, LPortalIndex);
    finally
      LFinder.Free;
      LBuilder.Free;
    end;
    Result := True;
  finally
    LWorld.Free;
  end;
end;

end.
