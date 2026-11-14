{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 AAS navigation - the navigator of a map (idAASLocal)     }
{                                                                              }
{  Port of idAASLocal (AAS.cpp, AAS_local.h), Doom 3 GPL Source Code.          }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.D3.Navigator;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Plane, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.MapFile.Aas.AasFile, DelphiDoom.MapFile.Aas.Intf, DelphiDoom.MapFile.Aas.Reachability,
  DelphiDoom.MapFile.Aas.Settings, DelphiDoom.MapFile.Aas.Trace, DelphiDoom.Aas.D3.Types, DelphiDoom.Aas.D3.Intf,
  DelphiDoom.Aas.D3.Topology, DelphiDoom.Aas.D3.CacheStore, DelphiDoom.Aas.D3.Router,
  DelphiDoom.Aas.D3.Obstacles, DelphiDoom.Aas.D3.PathFinder, DelphiDoom.Aas.D3.WallEdges;

type
  /// <summary>
  ///   The navigation of the AI on the AAS of a map. It has no file until <c>Init</c> (which reads
  ///   it through the reader given) or <c>Attach</c> (a file that is already loaded); without a file
  ///   it answers like idAASLocal does. The parts that make it up are made when a file comes and
  ///   freed when it goes, in the reverse order. No global: one navigator per map
  /// </summary>
  TAasNavigator = class(TInterfacedObject, IAasMapNavigator)
  strict private
    FReader: IAasFileReader;
    FLog: IIdLibLog;
    FMaxCacheMemory: Integer;
    FFile: TAasFile;
    FOwnsFile: Boolean;
    FSampler: IAasSampler;
    FTopology: TAasTopology;
    FStore: TAasCacheStore;
    FRouter: TAasRouter;
    FObstacles: TAasObstacleManager;
    FPaths: TAasPathFinder;
    FWallEdges: TAasWallEdges;
    procedure SetupRouting;
    procedure CheckArea(const AAreaNum: Integer);
  public
    /// <summary>
    ///   The reader loads the files for <c>Init</c> (it may be nil if only <c>Attach</c> is used) and
    ///   the log gets the messages (nil is silent). <c>AMaxCacheMemory</c> is the memory of the routing
    ///   caches that is allowed, AAS_MAX_ROUTING_CACHE_MEMORY in the original
    /// </summary>
    constructor Create(const AReader: IAasFileReader; const ALog: IIdLibLog = nil;
      const AMaxCacheMemory: Integer = AAS_MAX_ROUTING_CACHE_MEMORY);
    destructor Destroy; override;
    /// <summary>
    ///   Loads the AAS of the map (idAASLocal::Init): if the file loaded is the one asked for (same name,
    ///   same CRC) it is kept and the obstacles are removed. False, with a warning, if the file
    ///   cannot be read or is not fit for routing (EAasFileException is not raised)
    /// </summary>
    function Init(const AMapName: AnsiString; const AMapFileCrc: Cardinal): Boolean;
    /// <summary>Uses a file that is loaded; <c>AOwnsFile</c> says if the navigator frees it</summary>
    procedure Attach(const AFile: TAasFile; const AOwnsFile: Boolean);
    procedure Shutdown;
    /// <summary>The file in use, or nil</summary>
    function AasFile: TAasFile;
    /// <summary>The memory counted for the routing caches</summary>
    function CacheMemory: Integer;
    /// <summary>How many caches there are of each kind</summary>
    procedure CacheCounts(out ANumAreaCache, ANumPortalCache: Integer);

    // IAasNavigator
    function GetSettings: TAasSettings;
    function PointAreaNum(const AOrigin: TGeoVec3): Integer;
    function PointReachableAreaNum(const AOrigin: TGeoVec3; const ASearchBounds: TGeoBounds;
      const AAreaFlags: Integer): Integer;
    function BoundsReachableAreaNum(const ABounds: TGeoBounds; const AAreaFlags: Integer): Integer;
    procedure PushPointIntoAreaNum(const AAreaNum: Integer; var AOrigin: TGeoVec3);
    function AreaCenter(const AAreaNum: Integer): TGeoVec3;
    function AreaFlags(const AAreaNum: Integer): Integer;
    function AreaTravelFlags(const AAreaNum: Integer): Integer;
    function Trace(var ATrace: TAasTrace; const AStart, AEnd: TGeoVec3): Boolean;
    function GetPlane(const APlaneNum: Integer): TGeoPlane;
    function GetWallEdges(const AAreaNum: Integer; const ABounds: TGeoBounds; const ATravelFlags: Integer;
      var AEdges: TArray<Integer>; const AMaxEdges: Integer): Integer;
    procedure SortWallEdges(var AEdges: TArray<Integer>; const ANumEdges: Integer);
    procedure GetEdgeVertexNumbers(const AEdgeNum: Integer; out AVertex0, AVertex1: Integer);
    procedure GetEdge(const AEdgeNum: Integer; out AStart, AEnd: TGeoVec3);
    function SetAreaState(const ABounds: TGeoBounds; const AAreaContents: Integer; const ADisabled: Boolean): Boolean;
    function AddObstacle(const ABounds: TGeoBounds): Integer;
    procedure RemoveObstacle(const AHandle: Integer);
    procedure RemoveAllObstacles;
    function TravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
      ATravelFlags: Integer): Integer;
    function RouteToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
      ATravelFlags: Integer; out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
    function WalkPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
      const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
    function WalkPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
      const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
      out AEndAreaNum: Integer): Boolean;
    function FlyPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
      const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
    function FlyPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
      const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
      out AEndAreaNum: Integer): Boolean;
    function FindNearestGoal(out AGoal: TAasGoal; const AAreaNum: Integer; const AOrigin, ATarget: TGeoVec3;
      const ATravelFlags: Integer; var AObstacles: array of TAasObstacle;
      const ACallback: IAasAreaCallback): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Aas.Types, DelphiDoom.MapFile.Aas.Factory;

resourcestring
  SKeeping = 'Keeping %s';
  SCouldNotLoad = 'Couldn''t load AAS file: ''%s''';
  SAreaNotInFile = 'AAS area %d is not in the file';
  SPlaneNotInFile = 'AAS plane %d is not in the file';

{ TAasNavigator }

constructor TAasNavigator.Create(const AReader: IAasFileReader; const ALog: IIdLibLog; const AMaxCacheMemory: Integer);
begin
  inherited Create;
  FReader := AReader;
  FLog := ALog;
  FMaxCacheMemory := AMaxCacheMemory;
end;

destructor TAasNavigator.Destroy;
begin
  Shutdown;
  inherited Destroy;
end;

procedure TAasNavigator.SetupRouting;
begin
  FSampler := TAasFileFactory.CreateSampler(FFile);
  FTopology := TAasTopology.Create(FFile, FSampler);
  FStore := TAasCacheStore.Create(FTopology, FMaxCacheMemory);
  FRouter := TAasRouter.Create(FTopology, FStore, FLog);
  FObstacles := TAasObstacleManager.Create(FTopology, FStore);
  FPaths := TAasPathFinder.Create(FTopology, FRouter, FSampler, FLog);
  FWallEdges := TAasWallEdges.Create(FTopology);
end;

procedure TAasNavigator.Shutdown;
begin
  if Assigned(FFile) then
  begin
    FreeAndNil(FWallEdges);
    FreeAndNil(FPaths);
    if Assigned(FObstacles) then
      FObstacles.RemoveAllObstacles;
    FreeAndNil(FObstacles);
    FreeAndNil(FRouter);
    FreeAndNil(FStore);
    FreeAndNil(FTopology);
    FSampler := nil;
    if FOwnsFile then
      FFile.Free;
    FFile := nil;
  end;
end;

procedure TAasNavigator.Attach(const AFile: TAasFile; const AOwnsFile: Boolean);
begin
  Shutdown;
  if not Assigned(AFile) then
    Exit;
  FFile := AFile;
  FOwnsFile := AOwnsFile;
  try
    SetupRouting;
  except
    // a file that is not fit for routing is not kept
    Shutdown;
    raise;
  end;
end;

function TAasNavigator.Init(const AMapName: AnsiString; const AMapFileCrc: Cardinal): Boolean;
var
  LFile: TAasFile;
begin
  if Assigned(FFile) and SameText(string(AMapName), string(FFile.Name)) and (AMapFileCrc = FFile.Crc) then
  begin
    if Assigned(FLog) then
      FLog.Printf(Format(SKeeping, [string(FFile.Name)]));
    RemoveAllObstacles;
    Exit(True);
  end;

  Shutdown;
  LFile := nil;
  if Assigned(FReader) then
    try
      LFile := FReader.Parse(AMapName, AMapFileCrc);
    except
      on E: EAasFileException do
      begin
        if Assigned(FLog) then
          FLog.Warning(E.Message);
        LFile := nil;
      end;
    end;
  if not Assigned(LFile) then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format(SCouldNotLoad, [string(AMapName)]));
    Exit(False);
  end;
  try
    Attach(LFile, True);
  except
    on E: EAasFileException do
    begin
      if Assigned(FLog) then
        FLog.Warning(E.Message);
      Exit(False);
    end;
  end;
  Result := True;
end;

function TAasNavigator.AasFile: TAasFile;
begin
  Result := FFile;
end;

function TAasNavigator.CacheMemory: Integer;
begin
  if Assigned(FStore) then
    Result := FStore.TotalCacheMemory
  else
    Result := 0;
end;

procedure TAasNavigator.CacheCounts(out ANumAreaCache, ANumPortalCache: Integer);
var
  LAreaMemory, LPortalMemory: Integer;
begin
  ANumAreaCache := 0;
  ANumPortalCache := 0;
  if Assigned(FStore) then
    FStore.Statistics(ANumAreaCache, ANumPortalCache, LAreaMemory, LPortalMemory);
end;

procedure TAasNavigator.CheckArea(const AAreaNum: Integer);
begin
  if (AAreaNum < 0) or (AAreaNum >= FTopology.NumAreas) then
    raise EAasRoutingException.Create(Format(SAreaNotInFile, [AAreaNum]));
end;

function TAasNavigator.GetSettings: TAasSettings;
begin
  if Assigned(FFile) then
    Result := FFile.Settings
  else
    Result := nil;
end;

function TAasNavigator.PointAreaNum(const AOrigin: TGeoVec3): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  Result := FSampler.PointAreaNum(AOrigin);
end;

function TAasNavigator.PointReachableAreaNum(const AOrigin: TGeoVec3; const ASearchBounds: TGeoBounds;
  const AAreaFlags: Integer): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  Result := FSampler.PointReachableAreaNum(AOrigin, ASearchBounds, AAreaFlags, TFL_INVALID);
end;

function TAasNavigator.BoundsReachableAreaNum(const ABounds: TGeoBounds; const AAreaFlags: Integer): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  Result := FSampler.BoundsReachableAreaNum(ABounds, AAreaFlags, TFL_INVALID);
end;

procedure TAasNavigator.PushPointIntoAreaNum(const AAreaNum: Integer; var AOrigin: TGeoVec3);
begin
  if Assigned(FFile) then
    FSampler.PushPointIntoAreaNum(AAreaNum, AOrigin);
end;

function TAasNavigator.AreaCenter(const AAreaNum: Integer): TGeoVec3;
begin
  if not Assigned(FFile) then
    Exit(TGeoVec3.Origin);
  CheckArea(AAreaNum);
  Result := FTopology.Centers[AAreaNum];
end;

function TAasNavigator.AreaFlags(const AAreaNum: Integer): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  CheckArea(AAreaNum);
  Result := FTopology.Areas[AAreaNum].Flags;
end;

function TAasNavigator.AreaTravelFlags(const AAreaNum: Integer): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  CheckArea(AAreaNum);
  Result := FTopology.Areas[AAreaNum].TravelFlags;
end;

function TAasNavigator.Trace(var ATrace: TAasTrace; const AStart, AEnd: TGeoVec3): Boolean;
begin
  if not Assigned(FFile) then
  begin
    ATrace.Fraction := 0;
    ATrace.LastAreaNum := 0;
    ATrace.NumAreas := 0;
    Exit(True);
  end;
  Result := FSampler.Trace(ATrace, AStart, AEnd);
end;

function TAasNavigator.GetPlane(const APlaneNum: Integer): TGeoPlane;
begin
  if not Assigned(FFile) then
  begin
    Result.Zero;
    Exit;
  end;
  if (APlaneNum < 0) or (APlaneNum >= FFile.NumPlanes) then
    raise EAasRoutingException.Create(Format(SPlaneNotInFile, [APlaneNum]));
  Result := FFile.Planes[APlaneNum];
end;

function TAasNavigator.GetWallEdges(const AAreaNum: Integer; const ABounds: TGeoBounds; const ATravelFlags: Integer;
  var AEdges: TArray<Integer>; const AMaxEdges: Integer): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  CheckArea(AAreaNum);
  if Length(AEdges) < AMaxEdges then
    SetLength(AEdges, AMaxEdges);
  Result := FWallEdges.GetWallEdges(AAreaNum, ABounds, ATravelFlags, AEdges, AMaxEdges);
end;

procedure TAasNavigator.SortWallEdges(var AEdges: TArray<Integer>; const ANumEdges: Integer);
begin
  if Assigned(FFile) then
    FWallEdges.SortWallEdges(AEdges, ANumEdges);
end;

procedure TAasNavigator.GetEdgeVertexNumbers(const AEdgeNum: Integer; out AVertex0, AVertex1: Integer);
begin
  if not Assigned(FFile) then
  begin
    AVertex0 := 0;
    AVertex1 := 0;
    Exit;
  end;
  FWallEdges.GetEdgeVertexNumbers(AEdgeNum, AVertex0, AVertex1);
end;

procedure TAasNavigator.GetEdge(const AEdgeNum: Integer; out AStart, AEnd: TGeoVec3);
begin
  if not Assigned(FFile) then
  begin
    AStart.Zero;
    AEnd.Zero;
    Exit;
  end;
  FWallEdges.GetEdge(AEdgeNum, AStart, AEnd);
end;

function TAasNavigator.SetAreaState(const ABounds: TGeoBounds; const AAreaContents: Integer;
  const ADisabled: Boolean): Boolean;
begin
  if not Assigned(FFile) then
    Exit(False);
  Result := FObstacles.SetAreaState(ABounds, AAreaContents, ADisabled);
end;

function TAasNavigator.AddObstacle(const ABounds: TGeoBounds): Integer;
begin
  if not Assigned(FFile) then
    Exit(-1);
  Result := FObstacles.AddObstacle(ABounds);
end;

procedure TAasNavigator.RemoveObstacle(const AHandle: Integer);
begin
  if Assigned(FFile) then
    FObstacles.RemoveObstacle(AHandle);
end;

procedure TAasNavigator.RemoveAllObstacles;
begin
  if Assigned(FFile) then
    FObstacles.RemoveAllObstacles;
end;

function TAasNavigator.TravelTimeToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
  ATravelFlags: Integer): Integer;
begin
  if not Assigned(FFile) then
    Exit(0);
  Result := FRouter.TravelTimeToGoalArea(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags);
end;

function TAasNavigator.RouteToGoalArea(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum,
  ATravelFlags: Integer; out ATravelTime: Integer; out AReach: TAasReachability): Boolean;
begin
  if not Assigned(FFile) then
  begin
    ATravelTime := 0;
    AReach := nil;
    Exit(False);
  end;
  Result := FRouter.RouteToGoalArea(AAreaNum, AOrigin, AGoalAreaNum, ATravelFlags, ATravelTime, AReach);
end;

function TAasNavigator.WalkPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
  const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
begin
  if not Assigned(FFile) then
  begin
    APath.Kind := PATHTYPE_WALK;
    APath.MoveGoal := AGoalOrigin;
    APath.MoveAreaNum := AAreaNum;
    APath.SecondaryGoal := AOrigin;
    APath.Reachability := nil;
    Exit(True);
  end;
  Result := FPaths.WalkPathToGoal(APath, AAreaNum, AOrigin, AGoalAreaNum, AGoalOrigin, ATravelFlags);
end;

function TAasNavigator.WalkPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
  const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
  out AEndAreaNum: Integer): Boolean;
begin
  if not Assigned(FFile) then
  begin
    AEndPos := AGoalOrigin;
    AEndAreaNum := 0;
    Exit(True);
  end;
  Result := FPaths.WalkPathValid(AAreaNum, AOrigin, AGoalAreaNum, AGoalOrigin, ATravelFlags, AEndPos, AEndAreaNum);
end;

function TAasNavigator.FlyPathToGoal(out APath: TAasPath; const AAreaNum: Integer; const AOrigin: TGeoVec3;
  const AGoalAreaNum: Integer; const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer): Boolean;
begin
  if not Assigned(FFile) then
  begin
    APath.Kind := PATHTYPE_WALK;
    APath.MoveGoal := AGoalOrigin;
    APath.MoveAreaNum := AAreaNum;
    APath.SecondaryGoal := AOrigin;
    APath.Reachability := nil;
    Exit(True);
  end;
  Result := FPaths.FlyPathToGoal(APath, AAreaNum, AOrigin, AGoalAreaNum, AGoalOrigin, ATravelFlags);
end;

function TAasNavigator.FlyPathValid(const AAreaNum: Integer; const AOrigin: TGeoVec3; const AGoalAreaNum: Integer;
  const AGoalOrigin: TGeoVec3; const ATravelFlags: Integer; out AEndPos: TGeoVec3;
  out AEndAreaNum: Integer): Boolean;
begin
  if not Assigned(FFile) then
  begin
    AEndPos := AGoalOrigin;
    AEndAreaNum := 0;
    Exit(True);
  end;
  Result := FPaths.FlyPathValid(AAreaNum, AOrigin, AGoalAreaNum, AGoalOrigin, ATravelFlags, AEndPos, AEndAreaNum);
end;

function TAasNavigator.FindNearestGoal(out AGoal: TAasGoal; const AAreaNum: Integer; const AOrigin, ATarget: TGeoVec3;
  const ATravelFlags: Integer; var AObstacles: array of TAasObstacle; const ACallback: IAasAreaCallback): Boolean;
begin
  if (not Assigned(FFile)) or (AAreaNum <= 0) then
  begin
    AGoal.AreaNum := AAreaNum;
    AGoal.Origin := AOrigin;
    Exit(False);
  end;
  Result := FRouter.FindNearestGoal(AGoal, AAreaNum, AOrigin, ATarget, ATravelFlags, AObstacles, Self as IAasNavigator, ACallback);
end;

end.
