{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the world of the bots before any map   }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): be_aas_bspq3.c, }
{  be_interface.c. Copyright (C) 1999-2005 Id Software, Inc. This unit is      }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.Bot.World;

interface

uses
  DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Move.Intf, DelphiDoom.Aas.Bsp.Intf,
  DelphiDoom.Aas.Reach.Intf, DelphiDoom.BotAi.World.Intf, DelphiDoom.BotAi.World.AasWorld;

type
  /// <summary>
  ///   IBotAasWorld over a <c>TBotAasWorld</c> that answers the BSP entities of a world with no map as the C does:
  ///   none. <c>BotSetupMoveAI</c> walks them (BotSetBrushModelTypes) at the setup of the library, before any map
  ///   is loaded, and the original finds an empty list; <c>TBotAasWorld</c> raises for every part of a missing map.
  ///   Every other part is the inner world's, and the inner world is not owned
  /// </summary>
  TQ3BotWorld = class(TInterfacedObject, IBotAasWorld)
  strict private
    FInnerRef: IBotAasWorld;
    FNoEntities: IAasBspEntities;
  public
    /// <summary>The inner world must be held as an interface by the caller too (it counts references)</summary>
    constructor Create(const AInner: TBotAasWorld; const ANoEntities: IAasBspEntities);
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

constructor TQ3BotWorld.Create(const AInner: TBotAasWorld; const ANoEntities: IAasBspEntities);
begin
  inherited Create;
  FInnerRef := AInner;
  FNoEntities := ANoEntities;
end;

function TQ3BotWorld.Loaded: Boolean;
begin
  Result := FInnerRef.Loaded;
end;

function TQ3BotWorld.Time: Single;
begin
  Result := FInnerRef.Time;
end;

function TQ3BotWorld.Areas: IAasAreaQuery;
begin
  Result := FInnerRef.Areas;
end;

function TQ3BotWorld.Sampler: IAasSampler;
begin
  Result := FInnerRef.Sampler;
end;

function TQ3BotWorld.Tracer: IAasTracer;
begin
  Result := FInnerRef.Tracer;
end;

function TQ3BotWorld.Router: IAasRouter;
begin
  Result := FInnerRef.Router;
end;

function TQ3BotWorld.Movement: IAasMovement;
begin
  Result := FInnerRef.Movement;
end;

function TQ3BotWorld.BestReachable: IAasBestReachable;
begin
  Result := FInnerRef.BestReachable;
end;

function TQ3BotWorld.Bsp: IAasBspWorld;
begin
  Result := FInnerRef.Bsp;
end;

function TQ3BotWorld.BspModels: IAasBspModels;
begin
  Result := FInnerRef.BspModels;
end;

function TQ3BotWorld.BspEntities: IAasBspEntities;
begin
  // no map: the BSP entities of a world that has none
  if FInnerRef.Loaded then
    Result := FInnerRef.BspEntities
  else
    Result := FNoEntities;
end;

function TQ3BotWorld.Entities: IBotEntitySource;
begin
  Result := FInnerRef.Entities;
end;

end.
