{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the commands of the gatherers                     }
{                                                                              }
{  Port of war1 (acoto87/war1), wcmd_executeHarvestCommand and                 }
{  wcmd_executeDeliverCommand of war_commands.c, (c) 2019 Alejandro Coto       }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Commands.Gather;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Commands.Family;

type
  /// <summary>
  ///   Harvest (gold from a mine, wood from a tree of a forest) and deliver. A worker that already carries a full load
  ///   delivers it first and then comes back to what it was told to harvest; the other dudes of the selection walk to
  ///   the place. Defects of the original kept: a worker with a full load and no town hall of its race does nothing but
  ///   the order is acknowledged; a worker with a load that is not full (the load is full only at exactly 100) leaves
  ///   for the new harvest with what it has; deliver without a town hall anywhere is EWarException (an assert there)
  /// </summary>
  TWarGatherCommands = class(TWarCommandFamily)
  public
    /// <summary>
    ///   wcmd_executeHarvestCommand: ATargetSlot is a gold mine or a forest (anything else is EWarException, the
    ///   original has an assert), the tile is the one of the tree
    /// </summary>
    function Harvest(ATargetSlot, ATileX, ATileY: Integer): Boolean;
    /// <summary>wcmd_executeDeliverCommand: to the town hall of the slot, or (0) to the closest of the race of each unit</summary>
    function Deliver(ATownHallSlot: Integer): Boolean;
  end;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.UnitSearch,
  DelphiDoom.War.Model.State.GatherFactory;

resourcestring
  SWarModelNotHarvestable = 'The entity %d is not a gold mine nor a forest';
  SWarModelNoTownHall = 'The unit %d has no town hall to deliver to';

// wu_isCarryingResources: a full load
function IsCarrying(const AUnit: TWarUnitComponent): Boolean;
begin
  Result := (AUnit.ResourceKind in [wrkGold, wrkWood]) and (AUnit.Amount = WAR_MODEL_MAX_CARRY);
end;

{ TWarGatherCommands }

function TWarGatherCommands.Harvest(ATargetSlot, ATileX, ATileY: Integer): Boolean;
var
  LTarget: PWarEntity;
  LIsForest: Boolean;
  LPosition: TWarVec2;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LTownHall: Integer;
  LDeliver: PWarStateDeliver;
  LAcknowledge: Integer;
begin
  LTarget := Context.Pool.Slots[ATargetSlot];
  LIsForest := LTarget^.EntityType = WAR_ENTITY_FOREST;
  if not LIsForest and not (LTarget^.HasUnit and (LTarget^.UnitData.UnitType = WAR_UNIT_GOLDMINE)) then
    raise EWarException.CreateFmt(SWarModelNotHarvestable, [LTarget^.Id]);
  Result := False;
  LAcknowledge := 0;
  LPosition := TWarModelMath.TileToMap(TWarModelMath.Vec(ATileX, ATileY), True);
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    if not (IsOwn(LSlot) and CanOrder(LSlot)) then
      Continue;
    LEntity := Context.Pool.Slots[LSlot];
    LUnit := @LEntity^.UnitData;
    if TWarUnitClassifier.IsWorker(LUnit^.UnitType) then
    begin
      if IsCarrying(LUnit^) then
      begin
        // the closest town hall to deliver the load, then back to this mine or tree
        LTownHall := TWarUnitSearch.FindClosestOfType(Context, LSlot,
          TWarUnitSearch.TownHallOfRace(TWarUnitClassifier.RaceOf(LUnit^.UnitType)));
        if LTownHall <> 0 then
        begin
          LDeliver := TWarGatherStateFactory.NewDeliver(Machine, LSlot, Context.Pool.Slots[LTownHall]^.Id);
          if Assigned(LDeliver) then
          begin
            LDeliver^.Cycle := True;
            if LIsForest then
            begin
              LDeliver^.SourceKind := wrkWood;
              LDeliver^.SourcePosition := LPosition;
            end
            else
              LDeliver^.SourceKind := wrkGold;
            LDeliver^.SourceId := LTarget^.Id;
          end;
          Order(LSlot, LDeliver);
        end;
      end
      else if LIsForest then
        Order(LSlot, TWarGatherStateFactory.NewWood(Machine, LSlot, LTarget^.Id, LPosition))
      else
        Order(LSlot, TWarGatherStateFactory.NewGold(Machine, LSlot, LTarget^.Id));
    end
    else if TWarUnitClassifier.IsDude(LUnit^.UnitType) then
      Order(LSlot, Machine.CreateMove(LSlot, [TWarUnitGeometry.CenterPosition(LEntity), LPosition], False))
    else
      Continue;
    if LAcknowledge = 0 then
      LAcknowledge := LSlot;
    Result := True;
  end;
  if Result then
    Acknowledge(LAcknowledge);
end;

function TWarGatherCommands.Deliver(ATownHallSlot: Integer): Boolean;
var
  LIndex: Integer;
  LSlot: Integer;
  LUnit: PWarUnitComponent;
  LTownHall: Integer;
  LTownHallId: Word;
  LAcknowledge: Integer;
begin
  Result := False;
  LAcknowledge := 0;
  for LIndex := 0 to Commander.Selection.Count - 1 do
  begin
    LSlot := SelectedSlot(LIndex);
    if not (IsOwn(LSlot) and CanOrder(LSlot)) then
      Continue;
    LUnit := @Context.Pool.Slots[LSlot]^.UnitData;
    LTownHall := ATownHallSlot;
    if LTownHall = 0 then
    begin
      LTownHall := TWarUnitSearch.FindClosestOfType(Context, LSlot,
        TWarUnitSearch.TownHallOfRace(TWarUnitClassifier.RaceOf(LUnit^.UnitType)));
      if LTownHall = 0 then
        raise EWarException.CreateFmt(SWarModelNoTownHall, [Context.Pool.Slots[LSlot]^.Id]);
    end;
    LTownHallId := Context.Pool.Slots[LTownHall]^.Id;
    if TWarUnitClassifier.IsWorker(LUnit^.UnitType) and IsCarrying(LUnit^) then
      Order(LSlot, TWarGatherStateFactory.NewDeliver(Machine, LSlot, LTownHallId))
    else if TWarUnitClassifier.IsDude(LUnit^.UnitType) then
      Order(LSlot, Machine.CreateFollow(LSlot, LTownHallId, Default(TWarVec2), WAR_MODEL_MEGA_TILE))
    else
      Continue;
    if LAcknowledge = 0 then
      LAcknowledge := LSlot;
    Result := True;
  end;
  if Result then
    Acknowledge(LAcknowledge);
end;

end.
