{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the mana and the effects of the spells            }
{                                                                              }
{  Port of war1 (acoto87/war1), updateMagic, updatePoisonCloud, updateSight    }
{  and updateSpells of war_map.c and the effects of                            }
{  war_state_machine_cast.c, (c) 2019 Alejandro Coto Gutierrez, zlib License   }
{  (see Libs\War\LICENSE-war1.txt). This is an altered version, not the        }
{  original.                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Spells;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   What the spells leave in the world and what happens to them at every tic: the mana of the magic units (one point
  ///   a second up to their maximum; a summoned unit loses one a second and dies at zero), the poison clouds (10 of damage
  ///   a second to every unit within 2 tiles, friends too, for their time), the sights (a tile seen for some seconds: who
  ///   lifts the fog reads the entities of type sight), the time left of invisibility and unholy armor. Called once per
  ///   tic by TWarModelWorld.UpdateEffects, in the order of wmap_updateMap
  /// </summary>
  TWarSpells = class
  public
    /// <summary>SDL_randf of the original from the generator of the model: 24 random bits over 2^24, in [0, 1)</summary>
    class function RandomUnit(AContext: TWarModelContext): Single; static;
    /// <summary>The entity of a far sight or a dark vision (with the flash of the spell); 0 if the pool is full</summary>
    class function SpawnSight(AContext: TWarModelContext; const ATile: TWarVec2; ATime: Single): Integer; static;
    /// <summary>The entity of a poison cloud (with its animation); 0 if the pool is full</summary>
    class function SpawnPoisonCloud(AContext: TWarModelContext; const ATile: TWarVec2; ATime: Single): Integer; static;
    /// <summary>
    ///   The five fires of one blow of a rain of fire around the position (within 2 tiles), each from 1 to 4 tiles above
    ///   the top of the view
    /// </summary>
    class procedure RainOfFire(AContext: TWarModelContext; const APosition: TWarVec2); static;
    /// <summary>updateMagic</summary>
    class procedure UpdateMagic(AMachine: TWarStateMachine); static;
    /// <summary>updateSpells (with updatePoisonCloud and updateSight)</summary>
    class procedure UpdateSpells(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.Math, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.Animations;

const
  RANDOM_BITS = 16777216;
  RAIN_FIRES = 5;

{ TWarSpells }

class function TWarSpells.RandomUnit(AContext: TWarModelContext): Single;
var
  LBits: Integer;
begin
  LBits := AContext.Random.Below(RANDOM_BITS);
  Result := LBits;
  Result := Result / RANDOM_BITS;
end;

class function TWarSpells.SpawnSight(AContext: TWarModelContext; const ATile: TWarVec2; ATime: Single): Integer;
var
  LEntity: PWarEntity;
begin
  Result := AContext.Pool.CreateEntity(WAR_ENTITY_SIGHT, True);
  if Result = 0 then
    Exit;
  LEntity := AContext.Pool.Slots[Result];
  LEntity^.HasSight := True;
  LEntity^.SpellTile := ATile;
  LEntity^.SpellTime := ATime;
  TWarAnimations.CreateSpell(LEntity, TWarModelMath.TileToMap(ATile, True));
end;

class function TWarSpells.SpawnPoisonCloud(AContext: TWarModelContext; const ATile: TWarVec2; ATime: Single): Integer;
var
  LEntity: PWarEntity;
begin
  Result := AContext.Pool.CreateEntity(WAR_ENTITY_POISON_CLOUD, True);
  if Result = 0 then
    Exit;
  LEntity := AContext.Pool.Slots[Result];
  LEntity^.HasPoisonCloud := True;
  LEntity^.SpellTile := ATile;
  LEntity^.SpellTime := ATime;
  LEntity^.SpellDamageTime := 0;
  TWarAnimations.CreatePoisonCloud(LEntity, TWarModelMath.TileToMap(ATile, True));
end;

class procedure TWarSpells.RainOfFire(AContext: TWarModelContext; const APosition: TWarVec2);
var
  LCount: Integer;
  LOffsetX: Single;
  LOffsetY: Single;
  LTarget: TWarVec2;
  LOrigin: TWarVec2;
  LRadius: Integer;
begin
  if not Assigned(AContext.Combat) then
    Exit;
  LRadius := 2 * WAR_MODEL_MEGA_TILE;
  for LCount := 1 to RAIN_FIRES do
  begin
    // randomf(-radius, radius), twice, then randomf(MEGA_TILE_WIDTH, MEGA_TILE_WIDTH * 4): three draws, in this order
    LOffsetX := RandomUnit(AContext);
    LOffsetX := LOffsetX * (2 * LRadius);
    LOffsetX := -LRadius + LOffsetX;
    LOffsetY := RandomUnit(AContext);
    LOffsetY := LOffsetY * (2 * LRadius);
    LOffsetY := -LRadius + LOffsetY;
    LTarget.X := APosition.X + LOffsetX;
    LTarget.Y := APosition.Y + LOffsetY;
    LOffsetY := RandomUnit(AContext);
    LOffsetY := LOffsetY * (3 * WAR_MODEL_MEGA_TILE);
    LOffsetY := WAR_MODEL_MEGA_TILE + LOffsetY;
    LOrigin.X := LTarget.X;
    LOrigin.Y := AContext.ViewportTop - LOffsetY;
    AContext.Combat.CreateProjectile(WAR_PROJECTILE_RAIN_OF_FIRE, 0, 0, LOrigin, LTarget);
  end;
end;

class procedure TWarSpells.UpdateMagic(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LUnits: TList<Integer>;
  LIndex: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LDeath: PWarStateDeath;
  LPosition: TWarVec2;
begin
  LContext := AMachine.Context;
  LUnits := LContext.Pool.OfType[WAR_ENTITY_UNIT];
  for LIndex := 0 to LUnits.Count - 1 do
  begin
    LSlot := LUnits[LIndex];
    LEntity := LContext.Pool.Slots[LSlot];
    LUnit := @LEntity^.UnitData;
    if not TWarUnitClassifier.IsMagic(LUnit^.UnitType) then
      Continue;
    if AMachine.IsDead(LSlot) or AMachine.IsGoingToDie(LSlot) then
      Continue;
    if LUnit^.ManaTime > 0 then
    begin
      LUnit^.ManaTime := LUnit^.ManaTime - LContext.Clock^.DeltaTime;
      Continue;
    end;
    if TWarUnitClassifier.IsSummon(LUnit^.UnitType) then
    begin
      if LUnit^.Mana > 0 then
        Dec(LUnit^.Mana)
      else
        LUnit^.Mana := 0;
      // when the mana runs out the summoned unit dies
      if LUnit^.Mana = 0 then
      begin
        LPosition := TWarUnitGeometry.CenterPosition(LEntity);
        LDeath := AMachine.CreateDeath(LSlot);
        AMachine.ResetState(LSlot, PWarStateBase(LDeath), WAR_CAUSE_LIFECYCLE);
        if ((LUnit^.UnitType = WAR_UNIT_SCORPION) or (LUnit^.UnitType = WAR_UNIT_SPIDER)) and
          Assigned(LContext.SpellEvents) then
          LContext.SpellEvents.SummonExpired(LPosition, LUnit^.UnitType);
      end;
    end
    // a magic unit gets about one point of mana a second: almost 4 minutes to fill it from nothing
    else if LUnit^.Mana < LUnit^.MaxMana then
      Inc(LUnit^.Mana)
    else
      LUnit^.Mana := LUnit^.MaxMana;
    LUnit^.ManaTime := 1.0;
  end;
end;

class procedure TWarSpells.UpdateSpells(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LDelta: Single;
  LClouds: TList<Integer>;
  LSights: TList<Integer>;
  LUnits: TList<Integer>;
  LGone: TList<Word>;
  LNear: TList<Integer>;
  LIndex: Integer;
  LVictim: Integer;
  LSlot: Integer;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
begin
  LContext := AMachine.Context;
  LDelta := LContext.Clock^.DeltaTime;
  LClouds := LContext.Pool.OfType[WAR_ENTITY_POISON_CLOUD];
  LSights := LContext.Pool.OfType[WAR_ENTITY_SIGHT];
  LGone := TList<Word>.Create;
  LNear := TList<Integer>.Create;
  try
    for LIndex := 0 to LClouds.Count - 1 do
    begin
      LEntity := LContext.Pool.Slots[LClouds[LIndex]];
      LEntity^.SpellTime := LEntity^.SpellTime - LDelta;
      LEntity^.SpellDamageTime := LEntity^.SpellDamageTime - LDelta;
      if LEntity^.SpellDamageTime <= 0 then
      begin
        if Assigned(LContext.Combat) then
        begin
          LContext.Combat.CollectNearUnits(LEntity^.SpellTile, 2, LNear);
          for LVictim := 0 to LNear.Count - 1 do
          begin
            LSlot := LNear[LVictim];
            if not AMachine.IsDead(LSlot) and not AMachine.IsGoingToDie(LSlot) and not AMachine.IsCollapsing(LSlot) and
              not AMachine.IsGoingToCollapse(LSlot) then
              LContext.Combat.TakeDamage(LSlot, 0, WAR_MODEL_POISON_CLOUD_DAMAGE);
          end;
        end;
        LEntity^.SpellDamageTime := 1.0;
      end;
      if LEntity^.SpellTime <= 0 then
        LGone.Add(LEntity^.Id);
    end;
    for LIndex := 0 to LSights.Count - 1 do
    begin
      LEntity := LContext.Pool.Slots[LSights[LIndex]];
      LEntity^.SpellTime := LEntity^.SpellTime - LDelta;
      if LEntity^.SpellTime <= 0 then
        LGone.Add(LEntity^.Id);
    end;
    LUnits := LContext.Pool.OfType[WAR_ENTITY_UNIT];
    for LIndex := 0 to LUnits.Count - 1 do
    begin
      LUnit := @LContext.Pool.Slots[LUnits[LIndex]]^.UnitData;
      if LUnit^.Invisible then
      begin
        LUnit^.InvisibilityTime := LUnit^.InvisibilityTime - LDelta;
        if LUnit^.InvisibilityTime <= 0 then
        begin
          LUnit^.Invisible := False;
          LUnit^.InvisibilityTime := 0;
        end;
      end;
      if LUnit^.Invulnerable then
      begin
        LUnit^.InvulnerabilityTime := LUnit^.InvulnerabilityTime - LDelta;
        if LUnit^.InvulnerabilityTime <= 0 then
        begin
          LUnit^.Invulnerable := False;
          LUnit^.InvulnerabilityTime := 0;
        end;
      end;
    end;
    for LIndex := 0 to LGone.Count - 1 do
      LContext.Entities.RemoveEntityById(LGone[LIndex]);
  finally
    LNear.Free;
    LGone.Free;
  end;
end;

end.
