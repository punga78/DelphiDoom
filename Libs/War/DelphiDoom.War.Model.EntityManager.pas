{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - creating and removing the units                   }
{                                                                              }
{  Port of war1 (acoto87/war1), we_createUnit, we_createDude,                  }
{  we_createBuilding, we_setInitialIdleState, we_removeEntity and              }
{  we_removeEntityById of war_entities.c, (c) 2019 Alejandro Coto Gutierrez,   }
{  zlib License (see Libs\War\LICENSE-war1.txt). This is an altered version.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.EntityManager;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The creation of the units (with the statistics of the database, a random direction and the components of the
  ///   original) and the removal of an entity (its states leave from the top, then the slot is free). The units are
  ///   found by their slot in the pool
  /// </summary>
  TWarEntityManager = class(TInterfacedObject, IWarEntityManager)
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
    /// <summary>
    ///   we_createUnit: a unit, building, gold mine or corpse at the tile (X, Y), with its hit points, mana and weapon from
    ///   the database. It has no state yet (the caller gives it the initial one). The slot, 0 if the pool is full;
    ///   EWarException if the type has no size or no statistics (the original stops on an assert). With AAddToMap
    ///   False the unit is not in the lists (a unit that is going to be trained)
    /// </summary>
    function CreateUnit(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AResourceKind: TWarResourceKind;
      AAmount: Cardinal; AAddToMap: Boolean): Integer;
    /// <summary>we_createDude: a unit that moves; it is not in the map if it is going to be trained</summary>
    function CreateDude(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AIsGoingToTrain: Boolean): Integer;
    /// <summary>
    ///   we_createBuilding: a building with the idle state, or with the build state (it is paid already) if it is going
    ///   to be built; 0 if the pool or the storage of the states is full
    /// </summary>
    function CreateBuilding(AUnitType, ATileX, ATileY: Integer; APlayer: Byte; AIsGoingToBuild: Boolean): Integer;
    /// <summary>we_setInitialIdleState: the idle state (looking around if it is a unit that moves), by a request of initialization</summary>
    procedure SetInitialIdle(ASlot: Integer);
    /// <summary>we_removeEntity: the states leave from the top (their exit hooks see the components), then the slot is free</summary>
    procedure RemoveEntity(ASlot: Integer);
    /// <summary>we_removeEntityById: nothing if there is no such entity</summary>
    procedure RemoveEntityById(AId: Word);
  end;

implementation

uses
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.ActionTable,
  DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Map.Types,
  DelphiDoom.War.Model.StateStorage;

{ TWarEntityManager }

constructor TWarEntityManager.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
end;

function TWarEntityManager.CreateUnit(AUnitType, ATileX, ATileY: Integer; APlayer: Byte;
  AResourceKind: TWarResourceKind; AAmount: Cardinal; AAddToMap: Boolean): Integer;
var
  LSizeX: Integer;
  LSizeY: Integer;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LDudeStats: TWarUnitStatsFull;
  LBuildingStats: TWarBuildingStatsFull;
begin
  if not FContext.Database.TryGetUnitSize(AUnitType, LSizeX, LSizeY) then
    raise EWarException.CreateFmt(SWarModelNoUnitData, [AUnitType]);
  // the statistics are looked for before the entity is made, so that a type without them leaves nothing behind
  if TWarUnitClassifier.IsDude(AUnitType) then
    LDudeStats := FContext.Database.GetUnitStats(AUnitType)
  else if TWarUnitClassifier.IsBuilding(AUnitType) then
    LBuildingStats := FContext.Database.GetBuildingStats(AUnitType);
  Result := FContext.Pool.CreateEntity(WAR_ENTITY_UNIT, AAddToMap);
  if Result = 0 then
    Exit;
  LEntity := FContext.Pool.Slots[Result];
  LEntity^.HasTransform := True;
  LEntity^.Position.X := ATileX * WAR_MEGA_TILE_SIZE;
  LEntity^.Position.Y := ATileY * WAR_MEGA_TILE_SIZE;
  LEntity^.HasUnit := True;
  LUnit := @LEntity^.UnitData;
  LUnit^.SizeX := 1;
  LUnit^.SizeY := 1;
  LUnit^.ActionType := WAR_ACTION_IDLE;
  LUnit^.UnitType := AUnitType;
  LUnit^.Direction := FContext.Random.Below(WAR_DIRECTION_COUNT);
  LUnit^.TileX := ATileX;
  LUnit^.TileY := ATileY;
  LUnit^.SizeX := LSizeX;
  LUnit^.SizeY := LSizeY;
  LUnit^.Player := APlayer;
  LUnit^.ResourceKind := AResourceKind;
  LUnit^.Amount := Integer(AAmount);
  TWarActionTable.InitActions(LUnit^);
  // the sprite of the unit (we_addSpriteComponentFromResource) and the scale of its transform
  LEntity^.ScaleX := 1.0;
  LEntity^.HasSprite := True;
  LEntity^.SpriteEnabled := True;
  LEntity^.SpriteFrames := FContext.ConstructionHost.UnitFrames(AUnitType);
  LEntity^.HasStateMachine := True;
  LEntity^.StateMachine.Pending.StateRef := TWarStateRefs.Invalid;
  LEntity^.StateMachine.Pending.CancellationTargetRef := TWarStateRefs.Invalid;
  if TWarUnitClassifier.IsDude(AUnitType) then
  begin
    LUnit^.MaxHp := LDudeStats.Hp;
    LUnit^.Hp := LDudeStats.Hp;
    LUnit^.MaxMana := LDudeStats.Mana;
    if TWarUnitClassifier.IsSummon(AUnitType) then
      LUnit^.Mana := LDudeStats.Mana
    else
      LUnit^.Mana := 100;
    LUnit^.Armor := LDudeStats.Armor;
    LUnit^.Range := LDudeStats.Range;
    LUnit^.MinDamage := LDudeStats.MinDamage;
    LUnit^.RndDamage := LDudeStats.RndDamage;
    LUnit^.Decay := LDudeStats.Decay;
    LUnit^.ManaTime := 1;
  end
  else if TWarUnitClassifier.IsBuilding(AUnitType) then
  begin
    LUnit^.MaxHp := LBuildingStats.Hp;
    LUnit^.Hp := LBuildingStats.Hp;
    LUnit^.Armor := LBuildingStats.Armor;
  end;
  if AAddToMap then
    FContext.Pool.AddToUnitList(Result, AUnitType);
end;

function TWarEntityManager.CreateDude(AUnitType, ATileX, ATileY: Integer; APlayer: Byte;
  AIsGoingToTrain: Boolean): Integer;
begin
  Result := CreateUnit(AUnitType, ATileX, ATileY, APlayer, wrkNone, 0, not AIsGoingToTrain);
end;

function TWarEntityManager.CreateBuilding(AUnitType, ATileX, ATileY: Integer; APlayer: Byte;
  AIsGoingToBuild: Boolean): Integer;
var
  LStats: TWarBuildingStatsFull;
  LBuild: PWarStateBase;
begin
  Result := CreateUnit(AUnitType, ATileX, ATileY, APlayer, wrkNone, 0, True);
  if Result = 0 then
    Exit;
  if AIsGoingToBuild then
  begin
    LStats := FContext.Database.GetBuildingStats(AUnitType);
    LBuild := FMachine.CreateBuild(Result, LStats.BuildTime, LStats.GoldCost, LStats.WoodCost);
    if (not Assigned(LBuild)) or (not FMachine.ResetState(Result, LBuild, WAR_CAUSE_INITIALIZATION)) then
    begin
      RemoveEntity(Result);
      Exit(0);
    end;
  end
  else
    SetInitialIdle(Result);
end;

procedure TWarEntityManager.SetInitialIdle(ASlot: Integer);
var
  LIdle: PWarStateIdle;
begin
  LIdle := FMachine.CreateIdle(ASlot, TWarUnitClassifier.IsDude(FContext.Pool.Slots[ASlot]^.UnitData.UnitType));
  FMachine.ResetState(ASlot, PWarStateBase(LIdle), WAR_CAUSE_INITIALIZATION);
end;

procedure TWarEntityManager.RemoveEntity(ASlot: Integer);
var
  LEntity: PWarEntity;
  LIsUnit: Boolean;
  LUnitType: Integer;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LIsUnit := LEntity^.EntityType = WAR_ENTITY_UNIT;
  LUnitType := WAR_UNIT_FOOTMAN;
  if LIsUnit and LEntity^.HasUnit then
    LUnitType := LEntity^.UnitData.UnitType;
  // the states leave while the components are still there
  if LEntity^.HasStateMachine then
    FMachine.TearDown(ASlot);
  FContext.Pool.FreeSlot(ASlot, LUnitType, LIsUnit);
end;

procedure TWarEntityManager.RemoveEntityById(AId: Word);
var
  LSlot: Integer;
begin
  if AId = 0 then
    Exit;
  LSlot := FContext.Pool.FindSlot(AId);
  if LSlot <> 0 then
    RemoveEntity(LSlot);
end;

end.
