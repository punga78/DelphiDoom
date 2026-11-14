{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the blows of the units                            }
{                                                                              }
{  Port of war1 (acoto87/war1), we_meleeAttack and we_rangeAttack of           }
{  war_entities.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Attacks;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Projectiles;

type
  /// <summary>
  ///   A blow: in melee it takes the damage of the unit from the target, with a chance of 4 in 5 to hit (a catapult never
  ///   misses; a player in god mode hits for 255); at range it throws a projectile, which hurts when it arrives. A
  ///   magic unit pays 2 mana for a shot and, with no mana, goes idle. The walls are not in the model yet
  /// </summary>
  TWarAttacks = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FCombat: TWarCombat;
    FProjectiles: TWarProjectiles;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine; const ACombat: TWarCombat);
    /// <summary>What a shot throws; the projectiles need the blows of this class for their impact, so it is given after</summary>
    property Projectiles: TWarProjectiles read FProjectiles write FProjectiles;
    /// <summary>we_meleeAttack</summary>
    procedure Melee(AAttackerSlot, ATargetSlot: Integer);
    /// <summary>we_rangeAttack</summary>
    procedure Range(AAttackerSlot, ATargetSlot: Integer);
  end;

implementation

uses
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry, DelphiDoom.War.Model.State.Types;

{ TWarAttacks }

constructor TWarAttacks.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const ACombat: TWarCombat);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FCombat := ACombat;
end;

procedure TWarAttacks.Melee(AAttackerSlot, ATargetSlot: Integer);
var
  LUnit: PWarUnitComponent;
  LMinDamage: Integer;
  LHit: Boolean;
begin
  LUnit := @FContext.Pool.Slots[AAttackerSlot]^.UnitData;
  // every unit has a 20 percent chance to miss (except catapults)
  LHit := TWarUnitClassifier.IsCatapult(LUnit^.UnitType);
  if not LHit then
    LHit := FContext.Random.Below(100) < 80;
  if not LHit then
    Exit;
  LMinDamage := LUnit^.MinDamage;
  if FContext.Players[LUnit^.Player]^.GodMode then
    LMinDamage := WAR_MODEL_GOD_MODE_MIN_DAMAGE;
  FCombat.TakeDamage(ATargetSlot, LMinDamage, LUnit^.RndDamage);
end;

procedure TWarAttacks.Range(AAttackerSlot, ATargetSlot: Integer);
var
  LAttacker: PWarEntity;
  LTarget: PWarEntity;
  LIdle: PWarStateIdle;
begin
  LAttacker := FContext.Pool.Slots[AAttackerSlot];
  LTarget := FContext.Pool.Slots[ATargetSlot];
  if TWarUnitClassifier.IsMagic(LAttacker^.UnitData.UnitType) and
    not FCombat.DecreaseMana(AAttackerSlot, 2) then
  begin
    // stop attacking if the magic unit runs out of mana
    LIdle := FMachine.CreateIdle(AAttackerSlot, True);
    FMachine.ResetState(AAttackerSlot, PWarStateBase(LIdle), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  FProjectiles.Launch(TWarProjectiles.TypeOfUnit(LAttacker^.UnitData.UnitType), LAttacker^.Id, LTarget^.Id,
    TWarUnitGeometry.CenterPosition(LAttacker), TWarUnitGeometry.CenterPosition(LTarget));
end;

end.
