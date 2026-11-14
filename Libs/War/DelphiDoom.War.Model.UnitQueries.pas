{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - questions about the units                         }
{                                                                              }
{  Port of war1 (acoto87/war1), we_getNearEnemy, we_getAttacker,               }
{  we_isBeingAttackedBy, wu_areEnemies, wu_canAttack and the wu_getNumber*     }
{  functions of war_units.c and war_entities.c, (c) 2019 Alejandro Coto        }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.UnitQueries;

interface

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   Who is an enemy of whom, who can attack, who is near: the entities are slots of the pool. The functions look at
  ///   the units in the order of the list of the original, so the first enemy found is the same
  /// </summary>
  TWarUnitQueries = class(TInterfacedObject, IWarUnitQueries)
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
    /// <summary>wu_areEnemies: two different units of different players, the second not neutral</summary>
    function AreEnemies(ASlot, AOtherSlot: Integer): Boolean;
    /// <summary>wu_canAttack: a warrior that is not dying can attack a wall or a unit that is not dying, not a corpse</summary>
    function CanAttack(ASlot, ATargetSlot: Integer): Boolean;
    /// <summary>we_getNearEnemy: the first unit that the entity could attack within 5 tiles of it (0 if none)</summary>
    function NearEnemy(ASlot: Integer): Integer;
    /// <summary>we_isBeingAttackedBy: the other has an attack state on its stack whose target is the entity</summary>
    function IsBeingAttackedBy(ASlot, AOtherSlot: Integer): Boolean;
    /// <summary>we_getAttacker: the first unit that attacks the entity (0 if none)</summary>
    function Attacker(ASlot: Integer): Integer;
    /// <summary>wu_getTotalNumberOfDudes: the units that move of the player, without the summoned ones and the skeletons</summary>
    function CountDudes(APlayer: Integer): Integer;
    /// <summary>wu_getNumberOfBuildingsOfType; with AAlreadyBuilt the ones that are still being built do not count</summary>
    function CountBuildingsOfType(APlayer, AUnitType: Integer; AAlreadyBuilt: Boolean): Integer;
    /// <summary>wu_getNumberOfUnitsOfType</summary>
    function CountUnitsOfType(APlayer, AUnitType: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.State.Types;

{ TWarUnitQueries }

constructor TWarUnitQueries.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
end;

function TWarUnitQueries.AreEnemies(ASlot, AOtherSlot: Integer): Boolean;
var
  LFirst: PWarEntity;
  LSecond: PWarEntity;
begin
  LFirst := FContext.Pool.Slots[ASlot];
  LSecond := FContext.Pool.Slots[AOtherSlot];
  if not (LFirst^.HasUnit and LSecond^.HasUnit) then
    Exit(False);
  if LFirst^.Id = LSecond^.Id then
    Exit(False);
  if LFirst^.UnitData.Player = LSecond^.UnitData.Player then
    Exit(False);
  Result := FContext.Players[LSecond^.UnitData.Player]^.Race <> wraNeutral;
end;

function TWarUnitQueries.CanAttack(ASlot, ATargetSlot: Integer): Boolean;
var
  LEntity: PWarEntity;
  LTarget: PWarEntity;
begin
  Result := False;
  LEntity := FContext.Pool.Slots[ASlot];
  LTarget := FContext.Pool.Slots[ATargetSlot];
  if LEntity^.HasUnit and TWarUnitClassifier.IsWarrior(LEntity^.UnitData.UnitType) and
    not FMachine.IsDead(ASlot) and not FMachine.IsGoingToDie(ASlot) then
  begin
    if LTarget^.EntityType = WAR_ENTITY_WALL then
      Exit(True);
    if (LTarget^.EntityType = WAR_ENTITY_UNIT) and not FMachine.IsDead(ATargetSlot) and
      not FMachine.IsGoingToDie(ATargetSlot) and not TWarUnitClassifier.IsCorpse(LTarget^.UnitData.UnitType) and
      not FMachine.IsCollapsing(ASlot) and not FMachine.IsGoingToCollapse(ASlot) then
      Exit(True);
  end;
end;

function TWarUnitQueries.NearEnemy(ASlot: Integer): Integer;
var
  LTile: TWarVec2;
  LUnits: TList<Integer>;
  LIndex: Integer;
  LOther: Integer;
begin
  LTile := TWarUnitGeometry.CenterTile(FContext.Pool.Slots[ASlot]);
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LOther := LUnits[LIndex];
    if AreEnemies(ASlot, LOther) and CanAttack(ASlot, LOther) then
    begin
      if FContext.Pool.Slots[LOther]^.UnitData.Invisible then
        Continue;
      if TWarUnitGeometry.TileInRange(FContext.Pool.Slots[LOther], LTile, WAR_MODEL_NEAR_ENEMY_RADIUS) then
        Exit(LOther);
    end;
  end;
  Result := 0;
end;

function TWarUnitQueries.IsBeingAttackedBy(ASlot, AOtherSlot: Integer): Boolean;
var
  LAttack: PWarStateBase;
begin
  LAttack := FMachine.FindState(AOtherSlot, WAR_STATE_ATTACK);
  Result := Assigned(LAttack) and (PWarStateAttack(LAttack)^.TargetEntityId = FContext.Pool.Slots[ASlot]^.Id);
end;

function TWarUnitQueries.Attacker(ASlot: Integer): Integer;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
begin
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
    if IsBeingAttackedBy(ASlot, LUnits[LIndex]) then
      Exit(LUnits[LIndex]);
  Result := 0;
end;

function TWarUnitQueries.CountDudes(APlayer: Integer): Integer;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
begin
  Result := 0;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LEntity := FContext.Pool.Slots[LUnits[LIndex]];
    if LEntity^.HasUnit and TWarUnitClassifier.IsDude(LEntity^.UnitData.UnitType) and
      not TWarUnitClassifier.IsSummon(LEntity^.UnitData.UnitType) and
      not TWarUnitClassifier.IsSkeleton(LEntity^.UnitData.UnitType) and (LEntity^.UnitData.Player = APlayer) then
      Inc(Result);
  end;
end;

function TWarUnitQueries.CountBuildingsOfType(APlayer, AUnitType: Integer; AAlreadyBuilt: Boolean): Integer;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
begin
  Result := 0;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LEntity := FContext.Pool.Slots[LUnits[LIndex]];
    if LEntity^.HasUnit and (LEntity^.UnitData.Player = APlayer) and (LEntity^.UnitData.UnitType = AUnitType) then
    begin
      if AAlreadyBuilt and (FMachine.IsBuilding(LUnits[LIndex]) or FMachine.IsGoingToBuild(LUnits[LIndex])) then
        Continue;
      Inc(Result);
    end;
  end;
end;

function TWarUnitQueries.CountUnitsOfType(APlayer, AUnitType: Integer): Integer;
var
  LUnits: TList<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
begin
  Result := 0;
  LUnits := FContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LEntity := FContext.Pool.Slots[LUnits[LIndex]];
    if LEntity^.HasUnit and (LEntity^.UnitData.Player = APlayer) and (LEntity^.UnitData.UnitType = AUnitType) then
      Inc(Result);
  end;
end;

end.
