{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - what the goals and the movement ask of the AAS         }
{                                                                              }
{  The functions of the AAS (be_aas_*.h) that be_ai_goal.c and be_ai_move.c    }
{  call, behind small interfaces of Libs\Aas. Based on the Quake III Arena GPL }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.World.Intf;

interface

uses
  DelphiDoom.MathCore.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Reach.Intf, DelphiDoom.Aas.Entity.Types;

type
  /// <summary>
  ///   The entities of the game as the AAS sees them (be_aas_entity.c): the bots look at items that were dropped,
  ///   at missiles of the grapple and at movers. <c>TAasEntityTable</c> is the real one (<c>TBotAasEntitySource</c>
  ///   adapts it); a test gives a table of its own.
  /// </summary>
  IBotEntitySource = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F92}']
    /// <summary>AAS_EntityType</summary>
    function EntityType(const AEntity: Integer): Integer;
    /// <summary>AAS_EntityModelindex</summary>
    function EntityModelIndex(const AEntity: Integer): Integer;
    /// <summary>AAS_EntityModelNum</summary>
    function EntityModelNum(const AEntity: Integer): Integer;
    /// <summary>AAS_EntityInfo</summary>
    function EntityInfo(const AEntity: Integer): TAasEntityInfo;
    /// <summary>AAS_NextEntity: the next valid entity, 0 at the end</summary>
    function NextEntity(const AEntity: Integer): Integer;
    /// <summary>AAS_OriginOfMoverWithModelNum</summary>
    function OriginOfMoverWithModelNum(const AModelNum: Integer; out AOrigin: TVec3): Boolean;
  end;

  /// <summary>
  ///   The world of the bots: the loaded AAS (its areas, routing, movement prediction and entities) and the BSP of
  ///   the game. One object for each loaded map; <c>TBotAasWorld</c> assembles one from the parts of Libs\Aas.
  /// </summary>
  IBotAasWorld = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F93}']
    /// <summary>AAS_Loaded</summary>
    function Loaded: Boolean;
    /// <summary>AAS_Time</summary>
    function Time: Single;
    /// <summary>AAS_AreaReachability, AAS_AreaPresenceType, AAS_AreaJumpPad, AAS_AreaLava, AAS_AreaDoNotEnter ...</summary>
    function Areas: IAasAreaQuery;
    /// <summary>AAS_PointAreaNum</summary>
    function Sampler: IAasSampler;
    /// <summary>AAS_TraceAreas, AAS_TraceClientBBox</summary>
    function Tracer: IAasTracer;
    /// <summary>AAS_AreaTravelTimeToGoalArea, AAS_NextAreaReachability, AAS_ReachabilityFromNum ...</summary>
    function Router: IAasRouter;
    /// <summary>AAS_PredictClientMovement, AAS_OnGround, AAS_Swimming ...</summary>
    function Movement: IAasMovement;
    /// <summary>AAS_BestReachableArea, AAS_BestReachableFromJumpPadArea</summary>
    function BestReachable: IAasBestReachable;
    /// <summary>AAS_Trace, AAS_PointContents</summary>
    function Bsp: IAasBspWorld;
    /// <summary>AAS_BSPModelMinsMaxsOrigin</summary>
    function BspModels: IAasBspModels;
    /// <summary>AAS_NextBSPEntity, AAS_ValueForBSPEpairKey ...</summary>
    function BspEntities: IAasBspEntities;
    function Entities: IBotEntitySource;
  end;

implementation

end.
