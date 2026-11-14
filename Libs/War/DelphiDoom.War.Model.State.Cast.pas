{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the cast state (the spells)                       }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_cast.c, (c) 2019 Alejandro   }
{  Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an    }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.State.Cast;

{$R-}
{$Q-}

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   A unit that casts a spell on a target (a unit or a point). Out of the range of the spell it follows the target;
  ///   in range it turns to it, plays its attack action and, when the action reaches its blow, the spell happens:
  ///   healing (one hit point for every 6 of mana, as many as the caster can pay), far sight and dark vision (an entity
  ///   that sees a tile for some seconds), invisibility, unholy armor (half of the hit points for some seconds without
  ///   damage), rain of fire (five fires that fall around the point, again at every blow until the mana ends or an
  ///   order comes), poison cloud (an entity that hurts who stands near), raise dead (a skeleton for every corpse within
  ///   4 tiles that the mana pays). The summons are not cast from here: they are the summon command. Defects of the
  ///   original kept: the range is measured to the point of the order, not to where the target unit is now; the rain of
  ///   fire starts above the top of the view of the player (Context.ViewportTop); a spell on a target that is gone or
  ///   not a dude costs nothing and does nothing; raise dead shows "not enough mana" once for every corpse it can not pay
  /// </summary>
  TWarCastState = class
  public
    /// <summary>wst_createCastState; nil if the storage is full</summary>
    class function CreateState(AMachine: TWarStateMachine; ASlot, ASpellType: Integer; ATargetId: Word;
      const ATargetPosition: TWarVec2): PWarStateCast; static;
    /// <summary>wst_updateCastState</summary>
    class procedure UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateCast); static;
    /// <summary>wst_updateCastStates</summary>
    class procedure UpdateAll(AMachine: TWarStateMachine); static;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Math,
  DelphiDoom.War.Model.ActionTable, DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Model.UnitGeometry,
  DelphiDoom.War.Model.Stats.Types, DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.Animations,
  DelphiDoom.War.Model.Spells;

procedure GoIdle(AMachine: TWarStateMachine; ASlot: Integer);
var
  LIdle: PWarStateIdle;
begin
  LIdle := AMachine.CreateIdle(ASlot, True);
  AMachine.ReplaceState(ASlot, PWarStateBase(LIdle), WAR_CAUSE_COMPLETION);
end;

// the flash and the sound that every spell with a place has
procedure Effect(AContext: TWarModelContext; const APosition: TWarVec2);
begin
  TWarAnimations.SpawnSpellEffect(AContext, APosition);
  if Assigned(AContext.SpellEvents) then
    AContext.SpellEvents.SpellCast(APosition);
end;

function DudeTarget(AContext: TWarModelContext; ATargetId: Word): Integer;
begin
  Result := AContext.Pool.FindSlot(ATargetId);
  if (Result <> 0) and not (AContext.Pool.Slots[Result]^.HasUnit and
    TWarUnitClassifier.IsDude(AContext.Pool.Slots[Result]^.UnitData.UnitType)) then
    Result := 0;
end;

procedure CastHealing(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateCast; const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
  LUnit: PWarUnitComponent;
  LTargetSlot: Integer;
  LTarget: PWarEntity;
  LHp: Integer;
  LMissing: Integer;
begin
  LContext := AMachine.Context;
  LUnit := @LContext.Pool.Slots[ASlot]^.UnitData;
  LTargetSlot := DudeTarget(LContext, AState^.TargetEntityId);
  if LTargetSlot <> 0 then
  begin
    LTarget := LContext.Pool.Slots[LTargetSlot];
    // all the hit points that the mana of the caster pays, then only those that the target misses
    LHp := LUnit^.Mana div AStats.ManaCost;
    LMissing := LTarget^.UnitData.MaxHp - LTarget^.UnitData.Hp;
    if LMissing < LHp then
      LHp := LMissing;
    LContext.Combat.IncreaseHp(LTargetSlot, LHp);
    LContext.Combat.DecreaseMana(ASlot, LHp * AStats.ManaCost);
    Effect(LContext, TWarUnitGeometry.CenterPosition(LTarget));
  end;
  GoIdle(AMachine, ASlot);
end;

procedure CastSight(AMachine: TWarStateMachine; ASlot: Integer; const ATargetTile: TWarVec2;
  const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
begin
  LContext := AMachine.Context;
  if LContext.Combat.DecreaseMana(ASlot, AStats.ManaCost) then
  begin
    TWarSpells.SpawnSight(LContext, ATargetTile, AStats.Time);
    if Assigned(LContext.SpellEvents) then
      LContext.SpellEvents.SpellCast(TWarModelMath.TileToMap(ATargetTile, True));
  end;
  GoIdle(AMachine, ASlot);
end;

procedure CastInvisibility(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateCast;
  const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
  LTargetSlot: Integer;
  LTarget: PWarEntity;
begin
  LContext := AMachine.Context;
  LTargetSlot := DudeTarget(LContext, AState^.TargetEntityId);
  if (LTargetSlot <> 0) and LContext.Combat.DecreaseMana(ASlot, AStats.ManaCost) then
  begin
    LTarget := LContext.Pool.Slots[LTargetSlot];
    LTarget^.UnitData.Invisible := True;
    LTarget^.UnitData.InvisibilityTime := AStats.Time;
    Effect(LContext, TWarUnitGeometry.CenterPosition(LTarget));
  end;
  GoIdle(AMachine, ASlot);
end;

procedure CastUnholyArmor(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateCast;
  const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
  LTargetSlot: Integer;
  LTarget: PWarEntity;
begin
  LContext := AMachine.Context;
  LTargetSlot := DudeTarget(LContext, AState^.TargetEntityId);
  if (LTargetSlot <> 0) and LContext.Combat.DecreaseMana(ASlot, AStats.ManaCost) then
  begin
    LTarget := LContext.Pool.Slots[LTargetSlot];
    LContext.Combat.DecreaseHp(LTargetSlot, LTarget^.UnitData.Hp div 2);
    LTarget^.UnitData.Invulnerable := True;
    LTarget^.UnitData.InvulnerabilityTime := AStats.Time;
    Effect(LContext, TWarUnitGeometry.CenterPosition(LTarget));
  end;
  GoIdle(AMachine, ASlot);
end;

procedure CastRainOfFire(AMachine: TWarStateMachine; ASlot: Integer; const ATargetTile: TWarVec2;
  const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
begin
  LContext := AMachine.Context;
  if LContext.Combat.DecreaseMana(ASlot, AStats.ManaCost) then
    TWarSpells.RainOfFire(LContext, TWarModelMath.TileToMap(ATargetTile, True))
  else
    GoIdle(AMachine, ASlot);
end;

procedure CastRaiseDead(AMachine: TWarStateMachine; ASlot: Integer; const ATargetTile: TWarVec2;
  const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
  LNear: TList<Integer>;
  LIndex: Integer;
  LCorpseSlot: Integer;
  LCorpse: PWarEntity;
  LTile: TWarVec2;
  LPosition: TWarVec2;
  LSkeleton: Integer;
  LPlayer: Byte;
begin
  LContext := AMachine.Context;
  LPlayer := LContext.Pool.Slots[ASlot]^.UnitData.Player;
  LNear := TList<Integer>.Create;
  try
    LContext.Combat.CollectNearUnits(ATargetTile, 4, LNear);
    for LIndex := 0 to LNear.Count - 1 do
    begin
      LCorpseSlot := LNear[LIndex];
      LCorpse := LContext.Pool.Slots[LCorpseSlot];
      if not TWarUnitClassifier.IsCorpse(LCorpse^.UnitData.UnitType) then
        Continue;
      if not LContext.Combat.DecreaseMana(ASlot, AStats.ManaCost) then
        Continue;
      LTile := TWarUnitGeometry.CenterTile(LCorpse);
      LPosition := TWarUnitGeometry.CenterPosition(LCorpse);
      LSkeleton := LContext.Entities.CreateUnit(WAR_UNIT_SKELETON, Trunc(LTile.X), Trunc(LTile.Y), LPlayer, wrkNone, 0,
        True);
      // a full pool: the original has no check and would crash; the corpse stays and the mana is spent
      if LSkeleton = 0 then
        Continue;
      LContext.Entities.SetInitialIdle(LSkeleton);
      Effect(LContext, LPosition);
      LContext.Entities.RemoveEntityById(LCorpse^.Id);
    end;
  finally
    LNear.Free;
  end;
  GoIdle(AMachine, ASlot);
end;

procedure CastPoisonCloud(AMachine: TWarStateMachine; ASlot: Integer; const ATargetTile: TWarVec2;
  const AStats: TWarSpellStats);
var
  LContext: TWarModelContext;
begin
  LContext := AMachine.Context;
  if LContext.Combat.DecreaseMana(ASlot, AStats.ManaCost) then
  begin
    TWarSpells.SpawnPoisonCloud(LContext, ATargetTile, AStats.Time);
    if Assigned(LContext.SpellEvents) then
      LContext.SpellEvents.SpellCast(TWarModelMath.TileToMap(ATargetTile, True));
  end;
  GoIdle(AMachine, ASlot);
end;

{ TWarCastState }

class function TWarCastState.CreateState(AMachine: TWarStateMachine; ASlot, ASpellType: Integer; ATargetId: Word;
  const ATargetPosition: TWarVec2): PWarStateCast;
begin
  Result := PWarStateCast(AMachine.AllocState(ASlot, WAR_STATE_CAST));
  if Assigned(Result) then
  begin
    Result^.SpellType := ASpellType;
    Result^.TargetEntityId := ATargetId;
    Result^.TargetPosition := ATargetPosition;
  end;
end;

class procedure TWarCastState.UpdateOne(AMachine: TWarStateMachine; ASlot: Integer; AState: PWarStateCast);
var
  LContext: TWarModelContext;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LUnitTile: TWarVec2;
  LTargetTile: TWarVec2;
  LStats: TWarSpellStats;
  LFollow: PWarStateFollow;
  LDx: Single;
  LDy: Single;
  LAction: ^TWarUnitAction;
begin
  LContext := AMachine.Context;
  LEntity := LContext.Pool.Slots[ASlot];
  LUnit := @LEntity^.UnitData;
  LUnitTile := TWarUnitGeometry.CenterTile(LEntity);
  LTargetTile := TWarModelMath.MapToTile(AState^.TargetPosition);
  LStats := LContext.Database.GetSpellStats(AState^.SpellType);
  if (LStats.Range <> 0) and not TWarUnitGeometry.TileInRange(LEntity, LTargetTile, LStats.Range) then
  begin
    LFollow := AMachine.CreateFollow(ASlot, AState^.TargetEntityId, AState^.TargetPosition,
      LStats.Range * WAR_MODEL_MEGA_TILE);
    AMachine.PushState(ASlot, PWarStateBase(LFollow), WAR_CAUSE_COMPLETION);
    Exit;
  end;
  LContext.Occupancy.SetStaticEntity(Trunc(LUnitTile.X), Trunc(LUnitTile.Y), LUnit^.SizeX, LUnit^.SizeY, LEntity^.Id);
  LDx := LTargetTile.X - LUnitTile.X;
  LDy := LTargetTile.Y - LUnitTile.Y;
  LUnit^.Direction := TWarModelMath.DirectionFromDiff(LDx, LDy);
  TWarActionTable.SetAction(LUnit^, WAR_ACTION_ATTACK, False, 1.0);
  if LUnit^.ActionType < 0 then
    Exit;
  LAction := @LUnit^.Actions[LUnit^.ActionType];
  if LAction^.LastActionStep <> WAR_ACTION_STEP_ATTACK then
    Exit;
  // when the unit casts a spell it is not invisible any more
  LUnit^.Invisible := False;
  LUnit^.InvisibilityTime := 0;
  case AState^.SpellType of
    WAR_SPELL_HEALING:
      CastHealing(AMachine, ASlot, AState, LStats);
    WAR_SPELL_FAR_SIGHT, WAR_SPELL_DARK_VISION:
      CastSight(AMachine, ASlot, LTargetTile, LStats);
    WAR_SPELL_INVISIBILITY:
      CastInvisibility(AMachine, ASlot, AState, LStats);
    WAR_SPELL_RAIN_OF_FIRE:
      CastRainOfFire(AMachine, ASlot, LTargetTile, LStats);
    WAR_SPELL_RAISE_DEAD:
      CastRaiseDead(AMachine, ASlot, LTargetTile, LStats);
    WAR_SPELL_UNHOLY_ARMOR:
      CastUnholyArmor(AMachine, ASlot, AState, LStats);
    WAR_SPELL_POISON_CLOUD:
      CastPoisonCloud(AMachine, ASlot, LTargetTile, LStats);
    // a summon in a cast state: the original logs a warning and the unit swings forever
  end;
  // the actions and the state machine have to talk somehow
  LAction^.LastActionStep := WAR_ACTION_STEP_NONE;
  LAction^.LastSoundStep := WAR_ACTION_STEP_NONE;
end;

class procedure TWarCastState.UpdateAll(AMachine: TWarStateMachine);
var
  LContext: TWarModelContext;
  LIndex: Integer;
  LState: PWarStateBase;
  LSlot: Integer;
begin
  LContext := AMachine.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
  begin
    if not LContext.Storage.Occupied[WAR_STATE_CAST, LIndex] then
      Continue;
    LState := LContext.Storage.StateAt(WAR_STATE_CAST, LIndex);
    LSlot := LContext.Pool.FindSlot(LState^.EntityId);
    if LSlot = 0 then
      Continue;
    if AMachine.ActiveState(LSlot) <> LState then
      Continue;
    if not AMachine.IsNextUpdateTime(LState) then
      Continue;
    UpdateOne(AMachine, LSlot, PWarStateCast(LState));
  end;
end;

end.
