{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the steps of the initialization of a map          }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.InitSteps;

interface

uses
  System.SysUtils, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Cluster.Intf,
  DelphiDoom.Aas.Reach.Intf, DelphiDoom.Aas.Main.Intf;

type
  /// <summary>
  ///   AAS_InitSettings, AAS_InitReachability, AAS_ContinueInitReachability, AAS_InitClustering, AAS_Optimize and
  ///   AAS_InitRouting on a file. The settings were read when the map was made (the movement has them), so
  ///   InitSettings has nothing left to do; the alternative routes are made together with the router, after the
  ///   clustering (they only need the number of areas). The router is made by the function that is given
  /// </summary>
  TAasInitSteps = class(TInterfacedObject, IAasInitSteps)
  strict private
    FFile: IAasFile;
    FLibVars: IBotLibVars;
    FReach: IAasReachInitializer;
    FCluster: IAasClusterInitializer;
    FOptimizer: IAasOptimizer;
    FRouterFactory: TFunc<IAasRouter>;
    FRouter: IAasRouter;
    FCalculating: Boolean;
  public
    constructor Create(const AFile: IAasFile; const ALibVars: IBotLibVars; const AReach: IAasReachInitializer;
      const ACluster: IAasClusterInitializer; const AOptimizer: IAasOptimizer; const ARouterFactory: TFunc<IAasRouter>);
    procedure InitSettings;
    procedure InitReachability;
    function ContinueInitReachability(const ATime: Single): Boolean;
    procedure InitClustering;
    procedure Optimize;
    procedure InitRouting;
    procedure InitAlternativeRouting;
    function SaveFile: Boolean;
    procedure FreeRouting;
    /// <summary>The router of the map, nil until InitRouting</summary>
    property Router: IAasRouter read FRouter;
  end;

implementation

constructor TAasInitSteps.Create(const AFile: IAasFile; const ALibVars: IBotLibVars;
  const AReach: IAasReachInitializer; const ACluster: IAasClusterInitializer; const AOptimizer: IAasOptimizer;
  const ARouterFactory: TFunc<IAasRouter>);
begin
  inherited Create;
  FFile := AFile;
  FLibVars := ALibVars;
  FReach := AReach;
  FCluster := ACluster;
  FOptimizer := AOptimizer;
  FRouterFactory := ARouterFactory;
end;

procedure TAasInitSteps.InitSettings;
begin
  // read when the map was made
end;

procedure TAasInitSteps.InitReachability;
begin
  FReach.InitReachability;
  // the file has all its reachabilities (numreachabilityareas = numareas + 2) unless they are to be calculated
  FCalculating := FReach.NumReachabilityAreas <> Length(FFile.AreaSettings) + 2;
end;

function TAasInitSteps.ContinueInitReachability(const ATime: Single): Boolean;
begin
  Result := FReach.ContinueInitReachability(ATime);
end;

procedure TAasInitSteps.InitClustering;
begin
  FCluster.InitClustering;
end;

procedure TAasInitSteps.Optimize;
begin
  FOptimizer.Optimize;
end;

procedure TAasInitSteps.InitRouting;
begin
  FRouter := FRouterFactory();
end;

procedure TAasInitSteps.InitAlternativeRouting;
begin
  // made with the router
end;

function TAasInitSteps.SaveFile: Boolean;
begin
  Result := FCalculating;
end;

procedure TAasInitSteps.FreeRouting;
begin
  FRouter := nil;
end;

end.