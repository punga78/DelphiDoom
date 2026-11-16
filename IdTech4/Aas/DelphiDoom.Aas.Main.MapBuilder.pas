{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the maker of the map that is loaded                }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.MapBuilder;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Intf, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Main.Intf;

type
  /// <summary>
  ///   The only class of the system that knows the classes of the file: it makes the sampler, the tracer, the
  ///   movement, the reachability calculation, the clustering, the optimizer and (when the initialization asks for it)
  ///   the router of a loaded file. The import, the variables, the world and the models are not owned. The file must be
  ///   a TAasFile (the clustering and the reachabilities change its tables)
  /// </summary>
  TAasMapBuilder = class(TInterfacedObject, IAasMapBuilder)
  strict private
    FImport: IBotImport;
    FLibVars: IBotLibVars;
    FWorld: IAasBspWorld;
    FModels: IAasBspModels;
    FMemory: IAasRoutingMemory;
    FClock: TAasMilliseconds;
    FDeveloper: Boolean;
    FBest: IAasBestReachable;
  public
    /// <summary>The memory and the clock may be nil (the routing never drops caches, the reachability has no time limit)</summary>
    constructor Create(const AImport: IBotImport; const ALibVars: IBotLibVars; const AWorld: IAasBspWorld;
      const AModels: IAasBspModels; const AMemory: IAasRoutingMemory; const AClock: TAasMilliseconds;
      const ADeveloper: Boolean);
    function Build(const AFile: IAasFile; const AMaxLinks: Integer; const AEntities: IAasBspEntities): IAasMap;
    /// <summary>AAS_BestReachableLinkArea on the map that was made last; 0 before any map</summary>
    function BestReachableLinkArea(const ALinkHead: Integer): Integer;
    /// <summary>The functions of be_aas_reach.c that the bots call (AAS_BestReachableArea ...) on the last map</summary>
    property BestReachable: IAasBestReachable read FBest;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Aas.Links, DelphiDoom.Aas.Factory, DelphiDoom.Aas.Move.Settings,
  DelphiDoom.Aas.Move.Movement, DelphiDoom.Aas.Reach.Factory, DelphiDoom.Aas.Cluster.Intf,
  DelphiDoom.Aas.Main.Map, DelphiDoom.Aas.Main.InitSteps;

constructor TAasMapBuilder.Create(const AImport: IBotImport; const ALibVars: IBotLibVars;
  const AWorld: IAasBspWorld; const AModels: IAasBspModels; const AMemory: IAasRoutingMemory;
  const AClock: TAasMilliseconds; const ADeveloper: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FLibVars := ALibVars;
  FWorld := AWorld;
  FModels := AModels;
  FMemory := AMemory;
  FClock := AClock;
  FDeveloper := ADeveloper;
end;

function TAasMapBuilder.Build(const AFile: IAasFile; const AMaxLinks: Integer;
  const AEntities: IAasBspEntities): IAasMap;
var
  LLinks: TAasEntityLinks;
  LSampler: IAasSampler;
  LTracer: IAasTracer;
  LFaces: IAasFaceTester;
  LMovement: IAasMovement;
  LReach: IAasReachInitializer;
  LImport: IBotImport;
  LMemory: IAasRoutingMemory;
  LDeveloper: Boolean;
begin
  LImport := FImport;
  LMemory := FMemory;
  LDeveloper := FDeveloper;
  LLinks := TAasEntityLinks.Create(AFile, FImport, AMaxLinks, FDeveloper);
  try
    LSampler := TAasFactory.CreateSampler(AFile, FImport, True);
    LTracer := TAasFactory.CreateTracer(AFile, FImport);
    LFaces := TAasFactory.CreateFaceTester(AFile, FImport);
    LMovement := TAasMovement.Create(AFile, LSampler, LTracer, LFaces, FWorld, FImport,
      TAasMoveSettingsReader.Read(FLibVars));
    LReach := TAasReachFactory.CreateInitializer(AFile, LSampler, LTracer, LFaces, LMovement, FWorld, FModels,
      AEntities, LLinks, FImport, FLibVars, FClock);
    Supports(LReach, IAasBestReachable, FBest);
    Result := TAasMap.Create(AFile, LLinks, TAasInitSteps.Create(AFile, FLibVars, LReach,
      TAasFactory.CreateClusterInitializer(AFile, FImport, FLibVars), TAasFactory.CreateOptimizer(AFile, FImport),
      function: IAasRouter
      begin
        Result := TAasFactory.CreateRouter(AFile, LImport, LTracer, LMemory, LDeveloper);
      end));
  except
    LLinks.Free;
    raise;
  end;
end;

function TAasMapBuilder.BestReachableLinkArea(const ALinkHead: Integer): Integer;
begin
  if Assigned(FBest) then
    Result := FBest.BestReachableLinkArea(ALinkHead)
  else
    Result := 0;
end;

end.
