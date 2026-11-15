{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the units move around obstacles and each other    }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_move.c (updatePreferred-     }
{  Velocity, updateAdjustedVelocity), war_rvo.c (wrvo_gatherNeighbours) and    }
{  the use of the flow fields of war_pathfinder.c, (c) 2019 Alejandro Coto     }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.FlowSteering;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.Intf,
  DelphiDoom.War.Model.Rvo, DelphiDoom.War.Path.FlowFields, DelphiDoom.War.Path.FlowField, DelphiDoom.War.Path.Intf;

type
  /// <summary>
  ///   IWarMovementSteering as the original does it: a unit that moves asks the flow field of the tile of its next waypoint
  ///   (made the first time it is asked and then kept) which way to go, and chooses its velocity among the 34 of
  ///   TWarRvo with the units that are within 5 tiles as obstacles. The static units (a unit that stands still, a
  ///   building, a tree) are in the grid of the flow field; the moving ones are the neighbors of the avoidance, taken
  ///   from the grid of the units of the tic before (Context.UnitGrid) with their position of now and the velocity that
  ///   their move state kept. The two passes loop over the moving units themselves (TWarMoveState.ForEachActive)
  /// </summary>
  TWarFlowSteering = class(TInterfacedObject, IWarMovementSteering, IWarFlowFieldSource)
  strict private
    FMachine: TWarStateMachine;
    FContext: TWarModelContext;
    FFields: TWarFlowFields;
    FNeighbours: TWarRvoNeighbours;
    procedure PreferredPass(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
    procedure AdjustedPass(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
    procedure GatherNeighbours(ASelfId: Word; const ACentre: TWarVec2; ARadius: Single);
  public
    /// <summary>
    ///   The machine gives the context and the states; the grid of what is occupied is the one of the flow fields (not
    ///   owned). The steering owns the flow fields
    /// </summary>
    constructor Create(const AMachine: TWarStateMachine; const AGrid: TWarPathGrid);
    destructor Destroy; override;
    procedure UpdatePreferredVelocities;
    procedure UpdateAdjustedVelocities;
    procedure RefreshFlowField(const AGoalPosition: TWarVec2);
    procedure PlanMove(const ATargetPosition: TWarVec2);
    /// <summary>IWarFlowFieldSource: wpath_computeFlowField, for the debug drawing of the flow field</summary>
    function ComputeFlowField(ATileX, ATileY: Integer): TWarFlowField;
    /// <summary>
    ///   wrvo_gatherNeighbours for a unit at ACentre within ARadius pixels, in the order of the original (cells by row,
    ///   the last unit put in a cell first, at most 16); the result is the list that the avoidance gets
    /// </summary>
    procedure Neighbours(ASelfId: Word; const ACentre: TWarVec2; ARadius: Single; out AResult: TWarRvoNeighbours);
    /// <summary>The flow fields of the map (what the tests look at)</summary>
    property Fields: TWarFlowFields read FFields;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Types, DelphiDoom.War.Map.Grid, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.State.Move;

const
  // MOVE_BASE_RVO_RADIUS_PX, MOVE_RECOVERY_RVO_RADIUS_PX (MEGA_TILE_WIDTH * 0.45f and * 0.60f), SEARCH_RADIUS_PX (* 5.0f)
  BASE_RADIUS: Single = 7.2;
  RECOVERY_RADIUS: Single = 9.6;
  SEARCH_RADIUS: Single = 80.0;
  // MEGA_TILE_WIDTH as a float
  TILE_WIDTH: Single = 16.0;
  // the flow field is zero where the unit has arrived: a vector shorter than this is no direction (0.0001f)
  NO_DIRECTION_LENGTH_SQR: Single = 0.0001;

{ TWarFlowSteering }

constructor TWarFlowSteering.Create(const AMachine: TWarStateMachine; const AGrid: TWarPathGrid);
begin
  inherited Create;
  FMachine := AMachine;
  FContext := AMachine.Context;
  FFields := TWarFlowFields.Create(AGrid);
end;

destructor TWarFlowSteering.Destroy;
begin
  FFields.Free;
  inherited;
end;

procedure TWarFlowSteering.UpdatePreferredVelocities;
begin
  TWarMoveState.ForEachActive(FMachine, PreferredPass);
end;

procedure TWarFlowSteering.UpdateAdjustedVelocities;
begin
  TWarMoveState.ForEachActive(FMachine, AdjustedPass);
end;

procedure TWarFlowSteering.PlanMove(const ATargetPosition: TWarVec2);
var
  LTile: TWarVec2;
begin
  LTile := TWarModelMath.MapToTile(ATargetPosition);
  FFields.Compute(Trunc(LTile.X), Trunc(LTile.Y));
end;

function TWarFlowSteering.ComputeFlowField(ATileX, ATileY: Integer): TWarFlowField;
begin
  Result := FFields.Compute(ATileX, ATileY);
end;

procedure TWarFlowSteering.RefreshFlowField(const AGoalPosition: TWarVec2);
var
  LTile: TWarVec2;
begin
  LTile := TWarModelMath.MapToTile(AGoalPosition);
  FFields.Compute(Trunc(LTile.X), Trunc(LTile.Y));
end;

// updatePreferredVelocity
procedure TWarFlowSteering.PreferredPass(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LTile: TWarVec2;
  LNext: TWarVec2;
  LNextTile: TWarVec2;
  LField: TWarFlowField;
  LDirection: TWarVec2;
begin
  if AState^.WaypointsIndex >= AState^.WaypointsCount - 1 then
    Exit;
  LEntity := FContext.Pool.Slots[ASlot];
  LPosition := TWarUnitGeometry.CenterPosition(LEntity);
  LTile := TWarModelMath.MapToTile(LPosition);
  LNext := AState^.Waypoints[AState^.WaypointsIndex + 1];
  LNextTile := TWarModelMath.MapToTile(LNext);
  // the field of the tile of the next waypoint (made now if nobody asked for it before)
  LField := FFields.Ensure(Trunc(LNextTile.X), Trunc(LNextTile.Y));
  LDirection := LField.Sample(Trunc(LTile.X), Trunc(LTile.Y));
  // a zero direction (the goal tile, or a tile that is not in the field): straight to the next waypoint
  if TWarModelMath.LengthSqr(LDirection) < NO_DIRECTION_LENGTH_SQR then
  begin
    LDirection := TWarModelMath.Sub(LNext, LPosition);
    LDirection := TWarModelMath.Normalize(LDirection);
  end;
  TWarMoveState.SetPreferredVelocity(FContext, LEntity, AState, LPosition, LDirection);
end;

// updateAdjustedVelocity
procedure TWarFlowSteering.AdjustedPass(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateMove);
var
  LEntity: PWarEntity;
  LPosition: TWarVec2;
  LSpeed: Single;
  LRadius: Single;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LPosition := TWarUnitGeometry.CenterPosition(LEntity);
  LSpeed := FContext.UnitSpeed(LEntity^.UnitData.UnitType, LEntity^.UnitData.Speed);
  if AState^.Progress.RecoveryAttempt >= 2 then
    LRadius := RECOVERY_RADIUS
  else
    LRadius := BASE_RADIUS;
  GatherNeighbours(LEntity^.Id, LPosition, SEARCH_RADIUS);
  AState^.RvoAdjustedVelocity := TWarRvo.ComputeNewVelocity(AState^.RvoPreferredVelocity, LPosition,
    AState^.RvoVelocity, LRadius, LSpeed, FContext.Clock^.DeltaTime, FNeighbours);
end;

procedure TWarFlowSteering.Neighbours(ASelfId: Word; const ACentre: TWarVec2; ARadius: Single;
  out AResult: TWarRvoNeighbours);
begin
  GatherNeighbours(ASelfId, ACentre, ARadius);
  AResult := FNeighbours;
end;

// wrvo_gatherNeighbours
procedure TWarFlowSteering.GatherNeighbours(ASelfId: Word; const ACentre: TWarVec2; ARadius: Single);
var
  LGrid: TWarMapGrid;
  LTile: TWarVec2;
  LReach: Single;
  LValue: Single;
  LXMin: Integer;
  LXMax: Integer;
  LYMin: Integer;
  LYMax: Integer;
  LGy: Integer;
  LGx: Integer;
  LSlot: Integer;
  LOther: PWarEntity;
  LPosition: TWarVec2;
  LDx: Single;
  LDy: Single;
  LDistanceSqr: Single;
  LRadiusSqr: Single;
  LState: PWarStateMove;
begin
  FNeighbours.Count := 0;
  LGrid := FContext.UnitGrid;
  if not Assigned(LGrid) then
    Exit;
  LTile := TWarModelMath.MapToTile(ACentre);
  LReach := ARadius / TILE_WIDTH;
  LValue := LTile.X - LReach;
  LValue := LValue / WAR_MAP_GRID_TILE_SIZE;
  LXMin := Max(0, Floor(LValue));
  LValue := LTile.X + LReach;
  LValue := LValue / WAR_MAP_GRID_TILE_SIZE;
  LXMax := Min(WAR_MAP_GRID_TILES_WIDTH - 1, Floor(LValue));
  LValue := LTile.Y - LReach;
  LValue := LValue / WAR_MAP_GRID_TILE_SIZE;
  LYMin := Max(0, Floor(LValue));
  LValue := LTile.Y + LReach;
  LValue := LValue / WAR_MAP_GRID_TILE_SIZE;
  LYMax := Min(WAR_MAP_GRID_TILES_HEIGHT - 1, Floor(LValue));
  LRadiusSqr := ARadius * ARadius;
  LGy := LYMin;
  while (LGy <= LYMax) and (FNeighbours.Count < WAR_RVO_MAX_NEIGHBOURS) do
  begin
    LGx := LXMin;
    while (LGx <= LXMax) and (FNeighbours.Count < WAR_RVO_MAX_NEIGHBOURS) do
    begin
      LSlot := LGrid.Head(LGy * WAR_MAP_GRID_TILES_WIDTH + LGx);
      while (LSlot >= 0) and (FNeighbours.Count < WAR_RVO_MAX_NEIGHBOURS) do
      begin
        // what is in the slot now, not what was when the grid was built
        LOther := FContext.Pool.Slots[LSlot];
        if (LOther^.Id <> ASelfId) and LOther^.HasUnit then
        begin
          LPosition := TWarUnitGeometry.CenterPosition(LOther);
          LDx := LPosition.X - ACentre.X;
          LDy := LPosition.Y - ACentre.Y;
          LDx := LDx * LDx;
          LDy := LDy * LDy;
          LDistanceSqr := LDx + LDy;
          if not (LDistanceSqr > LRadiusSqr) then
          begin
            // the last velocity of its move state (zero if it is not moving)
            FNeighbours.Items[FNeighbours.Count].Position := LPosition;
            FNeighbours.Items[FNeighbours.Count].Velocity.X := 0;
            FNeighbours.Items[FNeighbours.Count].Velocity.Y := 0;
            if LOther^.HasStateMachine then
            begin
              LState := PWarStateMove(FMachine.FindState(LSlot, WAR_STATE_MOVE));
              if Assigned(LState) then
                FNeighbours.Items[FNeighbours.Count].Velocity := LState^.RvoVelocity;
            end;
            FNeighbours.Items[FNeighbours.Count].Radius := BASE_RADIUS;
            Inc(FNeighbours.Count);
          end;
        end;
        LSlot := LGrid.Next(LSlot);
      end;
      Inc(LGx);
    end;
    Inc(LGy);
  end;
end;

end.
