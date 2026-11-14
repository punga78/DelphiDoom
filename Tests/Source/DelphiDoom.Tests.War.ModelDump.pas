{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the text of the state of the model   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelDump;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Map.PathGrid, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.World, DelphiDoom.Tests.War.ModelObserver;

type
  /// <summary>
  ///   The state of the model as text, line by line as dumpWorld of war_model_ref.c writes it (Tools\Verifica\194): the
  ///   time and the counters, the players, the storage of the states, the list of the units, the occupation grid and every
  ///   entity with its components and its stack of states. Floats are written as their bits. The impronta of a tic is
  ///   the FNV-1a of this text
  /// </summary>
  TModelDump = class
  strict private
    class function H8(AValue: Cardinal): string; static;
    class function FBits(AValue: Single): Cardinal; static;
    class procedure DBits(AValue: Double; out ALow, AHigh: Cardinal); static;
    class function Ref(const ARef: TWarStateRef): string; static;
    class procedure AddState(var AText: string; AWorld: TWarModelWorld; AState: PWarStateBase;
      const ARef: TWarStateRef); static;
  public
    class function Dump(AWorld: TWarModelWorld; AGrid: TWarPathGrid; AObserver: TModelObserver; ATic: Integer;
      AResults: Cardinal; AExtended: Boolean = False): string; static;
    /// <summary>FNV-1a 32 bit of the bytes of the text</summary>
    class function Fnv1a(const AText: string): Cardinal; static;
  end;

implementation

uses
  System.StrUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.EntityPool,
  DelphiDoom.War.Model.StateStorage;

{$Q-}
{$R-}

{ TModelDump }

class function TModelDump.H8(AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

class function TModelDump.FBits(AValue: Single): Cardinal;
begin
  Result := PCardinal(@AValue)^;
end;

class procedure TModelDump.DBits(AValue: Double; out ALow, AHigh: Cardinal);
var
  LBits: UInt64;
begin
  LBits := PUInt64(@AValue)^;
  ALow := Cardinal(LBits and $FFFFFFFF);
  AHigh := Cardinal(LBits shr 32);
end;

class function TModelDump.Ref(const ARef: TWarStateRef): string;
begin
  Result := Format('%d.%d.%u', [ARef.StateType, ARef.Index, ARef.Generation]);
end;

class function TModelDump.Fnv1a(const AText: string): Cardinal;
var
  LIndex: Integer;
begin
  Result := 2166136261;
  for LIndex := 1 to Length(AText) do
  begin
    Result := Result xor Cardinal(Ord(AText[LIndex]));
    Result := Result * 16777619;
  end;
end;

class procedure TModelDump.AddState(var AText: string; AWorld: TWarModelWorld; AState: PWarStateBase;
  const ARef: TWarStateRef);
var
  LLow: Cardinal;
  LHigh: Cardinal;
  LMove: PWarStateMove;
  LTrain: PWarStateTrain;
  LUpgrade: PWarStateUpgrade;
  LBuild: PWarStateBuild;
  LIndex: Integer;
begin
  DBits(AState^.NextUpdateGameTime, LLow, LHigh);
  AText := AText + Format(' S%s e=%d nx=%s%s dl=%s', [Ref(ARef), AState^.EntityId, H8(LHigh), H8(LLow),
    H8(FBits(AState^.Delay))]);
  case AState^.StateType of
    WAR_STATE_IDLE:
      AText := AText + Format(' look=%d', [Ord(PWarStateIdle(AState)^.LookAround)]);
    WAR_STATE_MOVE:
      begin
        LMove := PWarStateMove(AState);
        AText := AText + Format(' wi=%d wc=%d chk=%d', [LMove^.WaypointsIndex, LMove^.WaypointsCount,
          Ord(LMove^.CheckForAttacks)]);
        for LIndex := 0 to LMove^.WaypointsCount - 1 do
          AText := AText + Format(' w%d=%s,%s', [LIndex, H8(FBits(LMove^.Waypoints[LIndex].X)),
            H8(FBits(LMove^.Waypoints[LIndex].Y))]);
        AText := AText + Format(' rv=%s,%s pb=%s np=%s lv=%s ra=%d', [H8(FBits(LMove^.RvoVelocity.X)),
          H8(FBits(LMove^.RvoVelocity.Y)), H8(FBits(LMove^.Progress.BestDistanceSq)),
          H8(FBits(LMove^.Progress.NoProgressTime)), H8(FBits(LMove^.Progress.LowVelocityTime)),
          LMove^.Progress.RecoveryAttempt]);
        AText := AText + Format(' pg=%s,%s pw=%d pv=%s,%s av=%s,%s', [H8(FBits(LMove^.ProgressGoalPosition.X)),
          H8(FBits(LMove^.ProgressGoalPosition.Y)), LMove^.ProgressWaypointIndex,
          H8(FBits(LMove^.RvoPreferredVelocity.X)), H8(FBits(LMove^.RvoPreferredVelocity.Y)),
          H8(FBits(LMove^.RvoAdjustedVelocity.X)), H8(FBits(LMove^.RvoAdjustedVelocity.Y))]);
      end;
    WAR_STATE_FOLLOW:
      AText := AText + Format(' tg=%d tp=%s,%s td=%d', [PWarStateFollow(AState)^.TargetEntityId,
        H8(FBits(PWarStateFollow(AState)^.TargetPosition.X)), H8(FBits(PWarStateFollow(AState)^.TargetPosition.Y)),
        PWarStateFollow(AState)^.TargetDistance]);
    WAR_STATE_GOLD:
      AText := AText + Format(' gm=%d', [PWarStateGold(AState)^.GoldmineId]);
    WAR_STATE_MINING:
      AText := AText + Format(' gm=%d mt=%s', [PWarStateMining(AState)^.GoldmineId,
        H8(FBits(PWarStateMining(AState)^.MiningTime))]);
    WAR_STATE_WOOD:
      AText := AText + Format(' fo=%d fp=%s,%s', [PWarStateWood(AState)^.ForestId,
        H8(FBits(PWarStateWood(AState)^.Position.X)), H8(FBits(PWarStateWood(AState)^.Position.Y))]);
    WAR_STATE_CHOPPING:
      AText := AText + Format(' fo=%d fp=%s,%s', [PWarStateChopping(AState)^.ForestId,
        H8(FBits(PWarStateChopping(AState)^.Position.X)), H8(FBits(PWarStateChopping(AState)^.Position.Y))]);
    WAR_STATE_DELIVER:
      AText := AText + Format(' th=%d in=%d cy=%d sk=%d si=%d sp=%s,%s', [PWarStateDeliver(AState)^.TownHallId,
        Ord(PWarStateDeliver(AState)^.InsideBuilding), Ord(PWarStateDeliver(AState)^.Cycle),
        Ord(PWarStateDeliver(AState)^.SourceKind), PWarStateDeliver(AState)^.SourceId,
        H8(FBits(PWarStateDeliver(AState)^.SourcePosition.X)), H8(FBits(PWarStateDeliver(AState)^.SourcePosition.Y))]);
    WAR_STATE_ATTACK:
      AText := AText + Format(' tg=%d tp=%s,%s', [PWarStateAttack(AState)^.TargetEntityId,
        H8(FBits(PWarStateAttack(AState)^.TargetPosition.X)), H8(FBits(PWarStateAttack(AState)^.TargetPosition.Y))]);
    WAR_STATE_PATROL:
      begin
        AText := AText + Format(' wi=%d wc=%d dir=%d', [PWarStatePatrol(AState)^.WaypointsIndex,
          PWarStatePatrol(AState)^.WaypointsCount, PWarStatePatrol(AState)^.Dir]);
        for LIndex := 0 to PWarStatePatrol(AState)^.WaypointsCount - 1 do
          AText := AText + Format(' w%d=%s,%s', [LIndex, H8(FBits(PWarStatePatrol(AState)^.Waypoints[LIndex].X)),
            H8(FBits(PWarStatePatrol(AState)^.Waypoints[LIndex].Y))]);
      end;
    WAR_STATE_WAIT:
      begin
        DBits(PWarStateWait(AState)^.WaitEndGameTime, LLow, LHigh);
        AText := AText + Format(' we=%s%s', [H8(LHigh), H8(LLow)]);
      end;
    // building, repairing, collapsing, training and upgrading (second slice of the issue 194)
    WAR_STATE_TRAIN:
      begin
        LTrain := PWarStateTrain(AState);
        AText := AText + Format(' ut=%d bt=%s tt=%s gc=%d wc=%d fl=%d%d%d%d', [LTrain^.UnitToBuild,
          H8(FBits(LTrain^.BuildTime)), H8(FBits(LTrain^.TotalBuildTime)), LTrain^.GoldCost, LTrain^.WoodCost,
          Ord(LTrain^.TransactionApplied), Ord(LTrain^.OutputCommitted), Ord(LTrain^.Cancelled),
          Ord(LTrain^.AlreadyRefunded)]);
      end;
    WAR_STATE_UPGRADE:
      begin
        LUpgrade := PWarStateUpgrade(AState);
        AText := AText + Format(' ug=%d bt=%s tt=%s gc=%d wc=%d fl=%d%d%d%d', [LUpgrade^.UpgradeToBuild,
          H8(FBits(LUpgrade^.BuildTime)), H8(FBits(LUpgrade^.TotalBuildTime)), LUpgrade^.GoldCost, LUpgrade^.WoodCost,
          Ord(LUpgrade^.TransactionApplied), Ord(LUpgrade^.OutputCommitted), Ord(LUpgrade^.Cancelled),
          Ord(LUpgrade^.AlreadyRefunded)]);
      end;
    WAR_STATE_BUILD:
      begin
        LBuild := PWarStateBuild(AState);
        AText := AText + Format(' wk=%d bt=%s tt=%s gc=%d wc=%d fl=%d%d%d%d', [LBuild^.WorkerId,
          H8(FBits(LBuild^.BuildTime)), H8(FBits(LBuild^.TotalBuildTime)), LBuild^.GoldCost, LBuild^.WoodCost,
          Ord(LBuild^.TransactionApplied), Ord(LBuild^.OutputCommitted), Ord(LBuild^.Cancelled),
          Ord(LBuild^.AlreadyRefunded)]);
      end;
    WAR_STATE_REPAIR:
      AText := AText + Format(' bd=%d', [PWarStateRepair(AState)^.BuildingId]);
    WAR_STATE_REPAIRING:
      AText := AText + Format(' bd=%d in=%d', [PWarStateRepairing(AState)^.BuildingId,
        Ord(PWarStateRepairing(AState)^.InsideBuilding)]);
    WAR_STATE_CAST:
      AText := AText + Format(' sp=%d tg=%d tp=%s,%s', [PWarStateCast(AState)^.SpellType,
        PWarStateCast(AState)^.TargetEntityId, H8(FBits(PWarStateCast(AState)^.TargetPosition.X)),
        H8(FBits(PWarStateCast(AState)^.TargetPosition.Y))]);
  end;
end;

class function TModelDump.Dump(AWorld: TWarModelWorld; AGrid: TWarPathGrid; AObserver: TModelObserver; ATic: Integer;
  AResults: Cardinal; AExtended: Boolean): string;
var
  LContext: TWarModelContext;
  LText: string;
  LLow: Cardinal;
  LHigh: Cardinal;
  LPlayer: Integer;
  LUpgrade: Integer;
  LType: Integer;
  LUnits: TList<Integer>;
  LIndex: Integer;
  LGridHash: Cardinal;
  LGrid: TArray<Word>;
  LSlot: Integer;
  LEntity: PWarEntity;
  LUnit: PWarUnitComponent;
  LAction: Integer;
  LMachine: PWarStateMachineComponent;
  LState: PWarStateBase;
  LPending: PWarTransitionRequest;
  LPlayerInfo: PWarPlayerInfo;
begin
  LContext := AWorld.Context;
  LText := '';
  DBits(LContext.Clock^.GameTime, LLow, LHigh);
  LText := LText + Format('W tic=%d time=%s%s ents=%d next=%d draws=%u sum=%s flash=%u audio=%u res=%s'#10,
    [ATic, H8(LHigh), H8(LLow), LContext.Pool.EntityCount, LContext.Pool.LastId, AObserver.Draws, H8(AObserver.Sum),
    AObserver.FlashCount, AObserver.AudioCount, H8(AResults)]);
  for LPlayer := 0 to WAR_MAX_PLAYERS_COUNT - 1 do
  begin
    LPlayerInfo := LContext.Players[LPlayer];
    LText := LText + Format('P%d gold=%d wood=%d up=', [LPlayer, LPlayerInfo^.Gold, LPlayerInfo^.Wood]);
    for LUpgrade := 0 to WAR_MAX_UPGRADES_COUNT - 1 do
      LText := LText + Format('%d,', [LPlayerInfo^.Upgrades[LUpgrade].Level]);
    LText := LText + #10;
  end;
  LText := LText + 'Z act=';
  for LType := 0 to WAR_STATE_COUNT - 1 do
    LText := LText + Format('%d,', [LContext.Storage.ActiveCount[LType]]);
  LText := LText + ' free=';
  for LType := 0 to WAR_STATE_COUNT - 1 do
    LText := LText + Format('%d,', [LContext.Storage.FreeCount[LType]]);
  LText := LText + #10;
  LUnits := LContext.Pool.OfType[WAR_ENTITY_UNIT];
  LText := LText + 'L';
  for LIndex := 0 to LUnits.Count - 1 do
    LText := LText + Format(' %d', [LContext.Pool.Slots[LUnits[LIndex]]^.Id]);
  LText := LText + #10;
  LGridHash := 2166136261;
  LGrid := AGrid.ToArray;
  for LIndex := 0 to High(LGrid) do
  begin
    LGridHash := LGridHash xor LGrid[LIndex];
    LGridHash := LGridHash * 16777619;
  end;
  LText := LText + Format('G %s'#10, [H8(LGridHash)]);
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := LContext.Pool.Slots[LSlot];
    if LEntity^.Id = 0 then
      Continue;
    LText := LText + Format('E slot=%d id=%d type=%d', [LSlot, LEntity^.Id, LEntity^.EntityType]);
    if LEntity^.HasTransform then
      LText := LText + Format(' pos=%s,%s', [H8(FBits(LEntity^.Position.X)), H8(FBits(LEntity^.Position.Y))]);
    if LEntity^.HasUnit then
    begin
      LUnit := @LEntity^.UnitData;
      LText := LText + Format(' u=%d dir=%d tile=%d,%d size=%d,%d pl=%d rk=%d am=%d bd=%d bp=%s hp=%d/%d mn=%d/%d ar=%d rg=%d dm=%d+%d dc=%d inv=%d%d seen=%d sp=%d act=%d mt=%s it=%s vt=%s',
        [LUnit^.UnitType, LUnit^.Direction, LUnit^.TileX, LUnit^.TileY, LUnit^.SizeX, LUnit^.SizeY, LUnit^.Player,
        Ord(LUnit^.ResourceKind), LUnit^.Amount, Ord(LUnit^.Building), H8(FBits(LUnit^.BuildPercent)), LUnit^.Hp,
        LUnit^.MaxHp, LUnit^.Mana, LUnit^.MaxMana, LUnit^.Armor, LUnit^.Range, LUnit^.MinDamage, LUnit^.RndDamage,
        LUnit^.Decay, Ord(LUnit^.Invisible), Ord(LUnit^.Invulnerable), Ord(LUnit^.HasBeenSeen), LUnit^.Speed,
        LUnit^.ActionType, H8(FBits(LUnit^.ManaTime)), H8(FBits(LUnit^.InvisibilityTime)),
        H8(FBits(LUnit^.InvulnerabilityTime))]);
      for LAction := 0 to WAR_ACTION_TYPE_COUNT - 1 do
        LText := LText + Format(' a%d=%d,%s,%d', [LAction, LUnit^.Actions[LAction].Status,
          H8(FBits(LUnit^.Actions[LAction].Scale)), LUnit^.Actions[LAction].StepIndex]);
      if AExtended then
      begin
        DBits(LUnit^.LastAttackSoundGameTime, LLow, LHigh);
        LText := LText + Format(' ls=%s%s', [H8(LHigh), H8(LLow)]);
        for LAction := 0 to WAR_ACTION_TYPE_COUNT - 1 do
        begin
          DBits(LUnit^.Actions[LAction].WaitEndGameTime, LLow, LHigh);
          LText := LText + Format(' x%d=%d,%d,%s%s', [LAction, LUnit^.Actions[LAction].LastActionStep,
            LUnit^.Actions[LAction].LastSoundStep, H8(LHigh), H8(LLow)]);
        end;
      end;
    end;
    if AExtended and LEntity^.HasProjectile and LEntity^.HasTransform then
      LText := LText + Format(' pj=%d,%d,%d,%s,%s,%s,%s,%d fi=%d sx=%s', [LEntity^.Projectile.ProjectileType,
        LEntity^.Projectile.SourceEntityId, LEntity^.Projectile.TargetEntityId,
        H8(FBits(LEntity^.Projectile.Origin.X)), H8(FBits(LEntity^.Projectile.Origin.Y)),
        H8(FBits(LEntity^.Projectile.Target.X)), H8(FBits(LEntity^.Projectile.Target.Y)), LEntity^.Projectile.Speed,
        LEntity^.Projectile.FrameIndex, IfThen(LEntity^.Projectile.FlipX, 'bf800000', '3f800000')]);
    if LEntity^.HasStateMachine then
    begin
      LMachine := @LEntity^.StateMachine;
      LText := LText + Format(' sm=%d seq=%u', [LMachine^.Depth, Cardinal(LMachine^.NextTransitionSequence)]);
      for LIndex := 0 to LMachine^.Depth - 1 do
      begin
        LState := LContext.Storage.Deref(LMachine^.Stack[LIndex]);
        if Assigned(LState) then
          AddState(LText, AWorld, LState, LMachine^.Stack[LIndex])
        else
          LText := LText + ' S?';
      end;
      LPending := @LMachine^.Pending;
      LText := LText + Format(' pend=%d,%d,%d,%u,%d ref=%s can=%s', [LPending^.Operation, LPending^.Cause,
        LPending^.Result, Cardinal(LPending^.Sequence), Ord(LPending^.Cancellation), Ref(LPending^.StateRef),
        Ref(LPending^.CancellationTargetRef)]);
      if LPending^.Operation <> WAR_OP_NONE then
      begin
        LState := LContext.Storage.Deref(LPending^.StateRef);
        if Assigned(LState) then
          AddState(LText, AWorld, LState, LPending^.StateRef);
      end;
    end;
    LText := LText + #10;
  end;
  Result := LText;
end;

end.
