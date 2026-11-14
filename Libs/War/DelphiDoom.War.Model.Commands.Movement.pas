{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the commands that move the units                  }
{                                                                              }
{  Port of war1 (acoto87/war1), wcmd_executeMoveCommand,                       }
{  wcmd_executeFollowCommand and wcmd_executeStopCommand of war_commands.c,    }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see                        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Movement;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Commands.Family;

type
  /// <summary>
  ///   Move, follow and stop for the selected units. Every unit gets the same point: the original has no formation (the
  ///   units crowd on the target and the avoidance of #195 spreads them). Defects of the original kept: a move added
  ///   with SHIFT to a unit that patrols adds the point to its patrol too; a stop is given to buildings as well (it
  ///   resets a building that trains: the money is given back by the state it leaves)
  /// </summary>
  TWarMovementCommands = class(TWarCommandFamily)
  public
    /// <summary>
    ///   wcmd_executeMoveCommand: the dudes of the commander go to the point (pixels of the map); with AQueue (SHIFT) the
    ///   point is added to the way of who is already moving or patrolling. True if someone obeyed
    /// </summary>
    function Move(const ATarget: TWarVec2; AQueue: Boolean = False): Boolean;
    /// <summary>
    ///   wcmd_executeFollowCommand: the dudes of the commander follow the entity at one tile. Wanted difference: the
    ///   original gives the order to the buildings too, and stops on an assert at their first step
    /// </summary>
    function Follow(ATargetSlot: Integer): Boolean;
    /// <summary>wcmd_executeStopCommand: idle, looking around</summary>
    function Stop: Boolean;
  end;

implementation

uses
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry;

{ TWarMovementCommands }

function TWarMovementCommands.Move(const ATarget: TWarVec2; AQueue: Boolean): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LMove: PWarStateMove;
  LPatrol: PWarStatePatrol;
  LAcknowledge: Integer;

  procedure AddToMove;
  begin
    LMove := PWarStateMove(Machine.FindState(LSlot, WAR_STATE_MOVE));
    if LMove^.WaypointsCount < WAR_MODEL_MAX_WAYPOINTS then
    begin
      LMove^.Waypoints[LMove^.WaypointsCount] := ATarget;
      Inc(LMove^.WaypointsCount);
    end;
  end;

  procedure NewMove;
  begin
    Order(LSlot, Machine.CreateMove(LSlot, [TWarUnitGeometry.CenterPosition(LEntity), ATarget], False));
  end;

begin
  Result := False;
  LAcknowledge := 0;
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    LEntity := Context.Pool.Slots[LSlot];
    if not (LEntity^.HasUnit and TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) and IsOwn(LSlot)) then
      Continue;
    if not CanOrder(LSlot) then
      Continue;
    if not AQueue then
      NewMove
    else if Machine.Contains(LSlot, WAR_STATE_PATROL) then
    begin
      if Machine.Contains(LSlot, WAR_STATE_MOVE) then
        AddToMove;
      LPatrol := PWarStatePatrol(Machine.FindState(LSlot, WAR_STATE_PATROL));
      if LPatrol^.WaypointsCount < WAR_MODEL_MAX_WAYPOINTS then
      begin
        LPatrol^.Waypoints[LPatrol^.WaypointsCount] := ATarget;
        Inc(LPatrol^.WaypointsCount);
      end;
    end
    else if Machine.Contains(LSlot, WAR_STATE_MOVE) and not Machine.IsAttacking(LSlot) then
      AddToMove
    else
      NewMove;
    if LAcknowledge = 0 then
      LAcknowledge := LSlot;
    Result := True;
  end;
  if Result then
    Acknowledge(LAcknowledge);
end;

function TWarMovementCommands.Follow(ATargetSlot: Integer): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LAcknowledge: Integer;
  LTargetId: Word;
begin
  Result := False;
  LAcknowledge := 0;
  LTargetId := Context.Pool.Slots[ATargetSlot]^.Id;
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    if not (IsOwn(LSlot) and CanOrder(LSlot)) then
      Continue;
    // a building can not follow (the original gives it the order and stops on an assert when it tries to move)
    if not TWarUnitClassifier.IsDude(Context.Pool.Slots[LSlot]^.UnitData.UnitType) then
      Continue;
    Order(LSlot, Machine.CreateFollow(LSlot, LTargetId, Default(TWarVec2), WAR_MODEL_MEGA_TILE));
    if LAcknowledge = 0 then
      LAcknowledge := LSlot;
    Result := True;
  end;
  if Result then
    Acknowledge(LAcknowledge);
end;

function TWarMovementCommands.Stop: Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
begin
  Result := False;
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    if IsOwn(LSlot) and CanOrder(LSlot) then
    begin
      Order(LSlot, Machine.CreateIdle(LSlot, True));
      Result := True;
    end;
  end;
end;

end.
