{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotAasWorld, the AAS the bots work in                 }
{                                                                              }
{  Assembles the parts of Libs\Aas (the areas, routing, movement prediction,   }
{  entities and BSP of the loaded map) as the world the goals and the          }
{  movement ask. Based on the Quake III Arena GPL Source Code (id Software).   }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is available under the  }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.World.AasWorld;

interface

uses
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Bsp.Intf,
  DelphiDoom.Aas.Reach.Intf, DelphiDoom.BotAi.World.Intf;

type
  /// <summary>
  ///   One object for the game: it exists before the first map, has no map (<c>Loaded</c> is False and the time is
  ///   the one that was set) and gets the parts of the map with <c>SetMap</c> each time the AAS loads one. The
  ///   parts that are not there are an error for the caller that asks (EBotAiException), as the original would
  ///   dereference nothing.
  /// </summary>
  TBotAasWorld = class(TInterfacedObject, IBotAasWorld)
  strict private
    FLoaded: Boolean;
    FTime: Single;
    FAreas: IAasAreaQuery;
    FSampler: IAasSampler;
    FTracer: IAasTracer;
    FRouter: IAasRouter;
    FMovement: IAasMovement;
    FBestReachable: IAasBestReachable;
    FBsp: IAasBspWorld;
    FBspModels: IAasBspModels;
    FBspEntities: IAasBspEntities;
    FEntities: IBotEntitySource;
    procedure Require(const APart: IInterface; const AName: string);
  public
    /// <summary>The parts of the game that do not change from map to map</summary>
    constructor Create(const ABsp: IAasBspWorld; const ABspModels: IAasBspModels; const AEntities: IBotEntitySource);
    /// <summary>The parts of the loaded map (AAS_LoadMap): the world is loaded from now on</summary>
    procedure SetMap(const AAreas: IAasAreaQuery; const ASampler: IAasSampler; const ATracer: IAasTracer;
      const ARouter: IAasRouter; const AMovement: IAasMovement; const ABestReachable: IAasBestReachable;
      const ABspEntities: IAasBspEntities);
    /// <summary>No map is loaded (AAS_Shutdown)</summary>
    procedure ClearMap;
    /// <summary>AAS_StartFrame sets the time of the world</summary>
    procedure SetTime(const ATime: Single);
    function Loaded: Boolean;
    function Time: Single;
    function Areas: IAasAreaQuery;
    function Sampler: IAasSampler;
    function Tracer: IAasTracer;
    function Router: IAasRouter;
    function Movement: IAasMovement;
    function BestReachable: IAasBestReachable;
    function Bsp: IAasBspWorld;
    function BspModels: IAasBspModels;
    function BspEntities: IAasBspEntities;
    function Entities: IBotEntitySource;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Exceptions;

resourcestring
  SPartMissing = 'The bot world has no %s: no AAS map is loaded';

{ TBotAasWorld }

constructor TBotAasWorld.Create(const ABsp: IAasBspWorld; const ABspModels: IAasBspModels;
  const AEntities: IBotEntitySource);
begin
  inherited Create;
  FBsp := ABsp;
  FBspModels := ABspModels;
  FEntities := AEntities;
end;

procedure TBotAasWorld.SetMap(const AAreas: IAasAreaQuery; const ASampler: IAasSampler; const ATracer: IAasTracer;
  const ARouter: IAasRouter; const AMovement: IAasMovement; const ABestReachable: IAasBestReachable;
  const ABspEntities: IAasBspEntities);
begin
  FAreas := AAreas;
  FSampler := ASampler;
  FTracer := ATracer;
  FRouter := ARouter;
  FMovement := AMovement;
  FBestReachable := ABestReachable;
  FBspEntities := ABspEntities;
  FLoaded := True;
end;

procedure TBotAasWorld.ClearMap;
begin
  FAreas := nil;
  FSampler := nil;
  FTracer := nil;
  FRouter := nil;
  FMovement := nil;
  FBestReachable := nil;
  FBspEntities := nil;
  FLoaded := False;
end;

procedure TBotAasWorld.SetTime(const ATime: Single);
begin
  FTime := ATime;
end;

procedure TBotAasWorld.Require(const APart: IInterface; const AName: string);
begin
  if not Assigned(APart) then
    raise EBotAiException.CreateFmt(SPartMissing, [AName]);
end;

function TBotAasWorld.Loaded: Boolean;
begin
  Result := FLoaded;
end;

function TBotAasWorld.Time: Single;
begin
  Result := FTime;
end;

function TBotAasWorld.Areas: IAasAreaQuery;
begin
  Require(FAreas, 'area query');
  Result := FAreas;
end;

function TBotAasWorld.Sampler: IAasSampler;
begin
  Require(FSampler, 'sampler');
  Result := FSampler;
end;

function TBotAasWorld.Tracer: IAasTracer;
begin
  Require(FTracer, 'tracer');
  Result := FTracer;
end;

function TBotAasWorld.Router: IAasRouter;
begin
  Require(FRouter, 'router');
  Result := FRouter;
end;

function TBotAasWorld.Movement: IAasMovement;
begin
  Require(FMovement, 'movement');
  Result := FMovement;
end;

function TBotAasWorld.BestReachable: IAasBestReachable;
begin
  Require(FBestReachable, 'best reachable area');
  Result := FBestReachable;
end;

function TBotAasWorld.Bsp: IAasBspWorld;
begin
  Require(FBsp, 'BSP world');
  Result := FBsp;
end;

function TBotAasWorld.BspModels: IAasBspModels;
begin
  Require(FBspModels, 'BSP models');
  Result := FBspModels;
end;

function TBotAasWorld.BspEntities: IAasBspEntities;
begin
  Require(FBspEntities, 'BSP entities');
  Result := FBspEntities;
end;

function TBotAasWorld.Entities: IBotEntitySource;
begin
  Require(FEntities, 'entities');
  Result := FEntities;
end;

end.
