{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the entities of the wall and of the ruins          }
{                                                                              }
{  Port of war1 (acoto87/war1), we_createWall of war_walls.c, we_createRuins   }
{  of war_ruins.c and createStartingWalls / createRuinEntity of war_map.c,     }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.TerrainEntities;

interface

uses
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The two entities that a map has for what is built on the ground and is not a unit: the wall (one entity for all the
  ///   pieces, which are in the walls of the context; it has the idle state, which fills or frees the tiles by the hit
  ///   points of the pieces) and the ruins (an entity for all the pieces, kept in the ruins of the context). The map makes
  ///   them before its units, so they take the first ids
  /// </summary>
  TWarTerrainEntities = class
  public
    /// <summary>we_createWall with the state machine and the idle state that createStartingWalls gives it; the slot of the pool, 0 if it is full</summary>
    class function CreateWall(AContext: TWarModelContext; AMachine: TWarStateMachine): Integer; static;
    /// <summary>we_createRuins; the slot of the pool, 0 if it is full</summary>
    class function CreateRuins(AContext: TWarModelContext): Integer; static;
  end;

implementation

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateStorage;

{ TWarTerrainEntities }

class function TWarTerrainEntities.CreateWall(AContext: TWarModelContext; AMachine: TWarStateMachine): Integer;
var
  LEntity: PWarEntity;
  LIdle: PWarStateIdle;
begin
  Result := AContext.Pool.CreateEntity(WAR_ENTITY_WALL, True);
  if Result = 0 then
    Exit;
  LEntity := AContext.Pool.Slots[Result];
  LEntity^.HasStateMachine := True;
  LEntity^.StateMachine.Pending.StateRef := TWarStateRefs.Invalid;
  LEntity^.StateMachine.Pending.CancellationTargetRef := TWarStateRefs.Invalid;
  LIdle := AMachine.CreateIdle(Result, False);
  AMachine.ResetState(Result, PWarStateBase(LIdle), WAR_CAUSE_INITIALIZATION);
end;

class function TWarTerrainEntities.CreateRuins(AContext: TWarModelContext): Integer;
begin
  Result := AContext.Pool.CreateEntity(WAR_ENTITY_RUIN, True);
end;

end.
