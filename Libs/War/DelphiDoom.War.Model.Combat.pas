{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - hit points, mana and damage                       }
{                                                                              }
{  Port of war1 (acoto87/war1), we_increaseUnitHp, we_decreaseUnitHp,          }
{  we_increaseUnitMana, we_decreaseUnitMana, we_getTotalDamage and             }
{  we_takeDamage of war_entities.c, (c) 2019 Alejandro Coto Gutierrez, zlib    }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Combat;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The life of a unit: hit points and mana go up and down within their limits, and a blow takes the hit points of the
  ///   target (the damage is the minimum plus what the random part has over the armor). A unit with no hit points
  ///   starts to die (a building, to collapse): the states are asked for with the cause of the lifecycle, so they
  ///   replace whatever the unit was doing
  /// </summary>
  TWarCombat = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
    /// <summary>we_getTotalDamage: minimum + max(random - armor, 0)</summary>
    class function TotalDamage(AMinDamage, ARndDamage, AArmor: Integer): Integer; static;
    /// <summary>we_increaseUnitHp: up to the maximum</summary>
    procedure IncreaseHp(ASlot, AHp: Integer);
    /// <summary>we_decreaseUnitHp: down to 0</summary>
    procedure DecreaseHp(ASlot, AHp: Integer);
    /// <summary>we_increaseUnitMana: between 0 and the maximum</summary>
    procedure IncreaseMana(ASlot, AMana: Integer);
    /// <summary>we_decreaseUnitMana: False, with the message of the status bar, if the unit has less mana</summary>
    function DecreaseMana(ASlot, AMana: Integer): Boolean;
    /// <summary>
    ///   we_takeDamage: nothing for an invulnerable unit or a player in god mode; the hit points go down; at 0 the unit
    ///   starts to die or collapse; a building that is still standing tells the game how damaged it is
    /// </summary>
    procedure TakeDamage(ASlot, AMinDamage, ARndDamage: Integer);
  end;

implementation

uses
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.State.Types;

{ TWarCombat }

constructor TWarCombat.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
end;

class function TWarCombat.TotalDamage(AMinDamage, ARndDamage, AArmor: Integer): Integer;
var
  LRandom: Integer;
begin
  LRandom := ARndDamage - AArmor;
  if LRandom < 0 then
    LRandom := 0;
  Result := AMinDamage + LRandom;
end;

procedure TWarCombat.IncreaseHp(ASlot, AHp: Integer);
var
  LUnit: PWarUnitComponent;
begin
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LUnit^.Hp := LUnit^.Hp + AHp;
  if LUnit^.Hp > LUnit^.MaxHp then
    LUnit^.Hp := LUnit^.MaxHp;
end;

procedure TWarCombat.DecreaseHp(ASlot, AHp: Integer);
var
  LUnit: PWarUnitComponent;
begin
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LUnit^.Hp := LUnit^.Hp - AHp;
  if LUnit^.Hp < 0 then
    LUnit^.Hp := 0;
end;

procedure TWarCombat.IncreaseMana(ASlot, AMana: Integer);
var
  LUnit: PWarUnitComponent;
begin
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  LUnit^.Mana := LUnit^.Mana + AMana;
  // CLAMP(x, 0, maxMana) is MAX(MIN(x, maxMana), 0): a maximum below 0 gives 0
  if LUnit^.Mana > LUnit^.MaxMana then
    LUnit^.Mana := LUnit^.MaxMana;
  if LUnit^.Mana < 0 then
    LUnit^.Mana := 0;
end;

function TWarCombat.DecreaseMana(ASlot, AMana: Integer): Boolean;
var
  LUnit: PWarUnitComponent;
begin
  LUnit := @FContext.Pool.Slots[ASlot]^.UnitData;
  if LUnit^.Mana < AMana then
  begin
    FContext.Events.FlashStatus(wsmNotEnoughMana);
    Exit(False);
  end;
  LUnit^.Mana := LUnit^.Mana - AMana;
  if LUnit^.Mana < 0 then
    LUnit^.Mana := 0;
  Result := True;
end;

procedure TWarCombat.TakeDamage(ASlot, AMinDamage, ARndDamage: Integer);
var
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LDamage: Integer;
  LPercent: Integer;
  LCollapse: PWarStateBase;
  LDeath: PWarStateBase;
  LPosition: TWarVec2;
begin
  LEntity := FContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  if LUnit^.Invulnerable then
    Exit;
  if FContext.Players[LUnit^.Player]^.GodMode then
    Exit;
  LDamage := TotalDamage(AMinDamage, ARndDamage, LUnit^.Armor);
  DecreaseHp(ASlot, LDamage);
  if LUnit^.Hp = 0 then
  begin
    LPosition := TWarUnitGeometry.CenterPosition(LEntity);
    if TWarUnitClassifier.IsBuilding(LUnit^.UnitType) then
    begin
      LCollapse := FMachine.CreateCollapse(ASlot);
      FMachine.ResetState(ASlot, LCollapse, WAR_CAUSE_LIFECYCLE);
      FContext.Events.BuildingCollapsing(LEntity^.Id, LUnit^.UnitType, LPosition);
    end
    else
    begin
      LDeath := PWarStateBase(FMachine.CreateDeath(ASlot));
      FMachine.ResetState(ASlot, LDeath, WAR_CAUSE_LIFECYCLE);
      FContext.Events.UnitDied(LEntity^.Id, LUnit^.UnitType, LPosition);
    end;
  end
  else if TWarUnitClassifier.IsBuilding(LUnit^.UnitType) then
  begin
    LPercent := TWarModelMath.PercentOf(LUnit^.Hp, LUnit^.MaxHp);
    if LPercent <= 66 then
      FContext.Events.BuildingDamaged(LEntity^.Id, LPercent);
  end;
end;

end.
