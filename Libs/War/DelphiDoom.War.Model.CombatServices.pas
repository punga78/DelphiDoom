{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the blows and the projectiles of the model        }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.CombatServices;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine,
  DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.Combat.Intf, DelphiDoom.War.Model.NearUnits,
  DelphiDoom.War.Model.Projectiles, DelphiDoom.War.Model.Attacks;

type
  /// <summary>
  ///   IWarCombatServices: puts the blows, the projectiles and the grid of the units together, and does what comes after
  ///   the states in a tic (the grid, the steps of the actions, the projectiles). It owns its own TWarCombat
  /// </summary>
  TWarCombatServices = class(TInterfacedObject, IWarCombatServices)
  strict private
    FContext: TWarModelContext;
    FCombat: TWarCombat;
    FNear: TWarNearUnits;
    FProjectiles: TWarProjectiles;
    FAttacks: TWarAttacks;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
    destructor Destroy; override;
    procedure MeleeAttack(AAttackerSlot, ATargetSlot: Integer);
    procedure RangeAttack(AAttackerSlot, ATargetSlot: Integer);
    function CreateProjectile(AProjectileType: Integer; ASourceId, ATargetId: Word; const AOrigin,
      ATarget: TWarVec2): Integer;
    procedure BuildNearUnits;
    procedure UpdateProjectiles;
  end;

implementation

{ TWarCombatServices }

constructor TWarCombatServices.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine);
begin
  inherited Create;
  FContext := AContext;
  FCombat := TWarCombat.Create(AContext, AMachine);
  FNear := TWarNearUnits.Create(AContext, AMachine);
  FAttacks := TWarAttacks.Create(AContext, AMachine, FCombat);
  FProjectiles := TWarProjectiles.Create(AContext, AMachine, FCombat, FNear, FAttacks.Melee);
  FAttacks.Projectiles := FProjectiles;
end;

destructor TWarCombatServices.Destroy;
begin
  FAttacks.Free;
  FProjectiles.Free;
  FNear.Free;
  FCombat.Free;
  inherited;
end;

procedure TWarCombatServices.MeleeAttack(AAttackerSlot, ATargetSlot: Integer);
begin
  FAttacks.Melee(AAttackerSlot, ATargetSlot);
end;

procedure TWarCombatServices.RangeAttack(AAttackerSlot, ATargetSlot: Integer);
begin
  FAttacks.Range(AAttackerSlot, ATargetSlot);
end;

function TWarCombatServices.CreateProjectile(AProjectileType: Integer; ASourceId, ATargetId: Word; const AOrigin,
  ATarget: TWarVec2): Integer;
begin
  Result := FProjectiles.Launch(AProjectileType, ASourceId, ATargetId, AOrigin, ATarget);
end;

procedure TWarCombatServices.BuildNearUnits;
begin
  FNear.Build;
end;

procedure TWarCombatServices.UpdateProjectiles;
begin
  FProjectiles.UpdateAll;
end;

end.
