{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the text of the debug of the state machine         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_state_machine_debug.c (wstdbg_updateDebugText,}
{  appendStateDetail), (c) 2019 Alejandro Coto Gutierrez, zlib License (see    }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.DebugStateText;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine;

type
  /// <summary>
  ///   The text that the cheat line shows with the flag "state-machine" on and one unit selected: its name, its id and the
  ///   depth of its stack, one line for each state of the stack from the active one down (name padded to 10 characters
  ///   and the fields of the state) and the request that waits. The buffer of the original is 1024 bytes: the text stops at 1023
  /// </summary>
  TWarDebugStateText = class
  strict private
    class function StateName(AType: Integer): AnsiString; static;
    class function UnitName(AEntity: PWarEntity): AnsiString; static;
    class function Progress(ABuild, ATotal: Single): Integer; static;
    class function Detail(const AContext: TWarModelContext; AState: PWarStateBase): AnsiString; static;
  public
    /// <summary>
    ///   wstdbg_updateDebugText for the entity of the slot (the caller has checked the flag and that one unit is selected):
    ///   empty when the entity has no state machine
    /// </summary>
    class function Build(const AContext: TWarModelContext; const AMachine: TWarStateMachine; ASlot: Integer): AnsiString; static;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Text.CFormat, DelphiDoom.War.Level.Types, DelphiDoom.War.MapUi.UnitNames.Data,
  DelphiDoom.War.Model.StateStorage, DelphiDoom.War.Model.EntityPool;

const
  STATE_NAMES: array[0..WAR_STATE_COUNT - 1] of AnsiString = ('IDLE', 'MOVE', 'PATROL', 'FOLLOW', 'ATTACK', 'GOLD',
    'MINING', 'WOOD', 'CHOPPING', 'DELIVER', 'DEATH', 'COLLAPSE', 'TRAIN', 'UPGRADE', 'BUILD', 'REPAIR', 'REPAIRING',
    'CAST', 'WAIT');
  OPERATION_NAMES: array[0..4] of AnsiString = ('NONE', 'PUSH', 'POP', 'REPLACE', 'RESET');
  SPELL_NAMES: array[0..11] of AnsiString = ('HEALING', 'FAR_SIGHT', 'INVISIBILITY', 'RAIN_OF_FIRE', 'POISON_CLOUD',
    'RAISE_DEAD', 'DARK_VISION', 'UNHOLY_ARMOR', 'SUMMON_SPIDER', 'SUMMON_SCORPION', 'SUMMON_DAEMON',
    'SUMMON_WATER_ELEMENTAL');
  /// <summary>upgradeNames of war_units.c, indexed by the upgrade type as the original does</summary>
  UPGRADE_NAMES: array[0..19] of AnsiString = ('upgrade-spear', 'upgrade-arrow', 'upgrade-axe', 'upgrade-sword',
    'upgrade-wolves', 'upgrade-horse', 'upgrade-spider', 'upgrade-scorpion', 'upgrade-poison-cloud',
    'upgrade-rain-of-fire', 'upgrade-daemon', 'upgrade-water-elemental', 'upgrade-raise-dead', 'upgrade-healing',
    'upgrade-dark-vision', 'upgrade-far-seeing', 'upgrade-unholy-armor', 'upgrade-invisibility', 'upgrade-orc-shield',
    'upgrade-human-shield');
  MAX_TEXT = 1023;

{ TWarDebugStateText }

class function TWarDebugStateText.StateName(AType: Integer): AnsiString;
begin
  if (AType >= WAR_STATE_IDLE) and (AType < WAR_STATE_COUNT) then
    Result := STATE_NAMES[AType]
  else
    Result := 'UNKNOWN';
end;

class function TWarDebugStateText.UnitName(AEntity: PWarEntity): AnsiString;
var
  LIndex: Integer;
begin
  Result := 'ENTITY';
  if not AEntity^.HasUnit then
    Exit;
  for LIndex := 0 to High(WAR_UNIT_NAMES) do
    if WAR_UNIT_NAMES[LIndex].UnitType = AEntity^.UnitData.UnitType then
      Exit(WAR_UNIT_NAMES[LIndex].Name);
end;

class function TWarDebugStateText.Progress(ABuild, ATotal: Single): Integer;
var
  LPercent: Single;
begin
  Result := 0;
  if ATotal > 0 then
  begin
    LPercent := ABuild / ATotal;
    LPercent := LPercent * 100.0;
    if LPercent < 0 then
      LPercent := 0;
    if LPercent > 100 then
      LPercent := 100;
    Result := Trunc(LPercent);
  end;
end;

class function TWarDebugStateText.Detail(const AContext: TWarModelContext; AState: PWarStateBase): AnsiString;
var
  LName: AnsiString;
  LIndex: Integer;
  LRemaining: Double;
begin
  Result := '';
  case AState^.StateType of
    WAR_STATE_IDLE:
      Result := 'look=' + AnsiString(IntToStr(Ord(PWarStateIdle(AState)^.LookAround)));
    WAR_STATE_MOVE:
      with PWarStateMove(AState)^ do
        Result := AnsiString(Format('wp=%d/%d vel=(', [WaypointsIndex, WaypointsCount])) +
          TWarCFormat.Fixed1(RvoVelocity.X) + ',' + TWarCFormat.Fixed1(RvoVelocity.Y) + ') stuck=' +
          TWarCFormat.Fixed1(Progress.NoProgressTime) + 's recovery=' + AnsiString(IntToStr(Progress.RecoveryAttempt));
    WAR_STATE_PATROL:
      with PWarStatePatrol(AState)^ do
        Result := AnsiString(Format('wp=%d/%d dir=%d', [WaypointsIndex, WaypointsCount, Dir]));
    WAR_STATE_FOLLOW:
      with PWarStateFollow(AState)^ do
        Result := AnsiString(Format('target=#%d dist=%d pos=(', [TargetEntityId, TargetDistance])) +
          TWarCFormat.Fixed1(TargetPosition.X) + ',' + TWarCFormat.Fixed1(TargetPosition.Y) + ')';
    WAR_STATE_ATTACK:
      with PWarStateAttack(AState)^ do
        Result := AnsiString(Format('target=#%d pos=(', [TargetEntityId])) + TWarCFormat.Fixed1(TargetPosition.X) + ',' +
          TWarCFormat.Fixed1(TargetPosition.Y) + ')';
    WAR_STATE_GOLD:
      Result := AnsiString(Format('mine=#%d', [PWarStateGold(AState)^.GoldmineId]));
    WAR_STATE_MINING:
      with PWarStateMining(AState)^ do
        Result := AnsiString(Format('mine=#%d time=', [GoldmineId])) + TWarCFormat.Fixed1(MiningTime) + 's';
    WAR_STATE_WOOD:
      with PWarStateWood(AState)^ do
        Result := AnsiString(Format('forest=#%d pos=(', [ForestId])) + TWarCFormat.Fixed1(Position.X) + ',' +
          TWarCFormat.Fixed1(Position.Y) + ')';
    WAR_STATE_CHOPPING:
      with PWarStateChopping(AState)^ do
        Result := AnsiString(Format('forest=#%d pos=(', [ForestId])) + TWarCFormat.Fixed1(Position.X) + ',' +
          TWarCFormat.Fixed1(Position.Y) + ')';
    WAR_STATE_DELIVER:
      with PWarStateDeliver(AState)^ do
        Result := AnsiString(Format('th=#%d cycle=%d src=%d srcId=#%d pos=(', [TownHallId, Ord(Cycle), Ord(SourceKind),
          SourceId])) + TWarCFormat.Fixed1(SourcePosition.X) + ',' + TWarCFormat.Fixed1(SourcePosition.Y) + ')';
    WAR_STATE_TRAIN:
      with PWarStateTrain(AState)^ do
      begin
        LName := 'UNKNOWN';
        for LIndex := 0 to High(WAR_UNIT_NAMES) do
          if WAR_UNIT_NAMES[LIndex].UnitType = UnitToBuild then
          begin
            LName := WAR_UNIT_NAMES[LIndex].Name;
            Break;
          end;
        Result := AnsiString(Format('unit=%s progress=%d%% cancelled=%d', [string(LName), Progress(BuildTime,
          TotalBuildTime), Ord(Cancelled)]));
      end;
    WAR_STATE_UPGRADE:
      with PWarStateUpgrade(AState)^ do
      begin
        LName := 'UNKNOWN_UPGRADE';
        if (UpgradeToBuild >= WAR_UPGRADE_ARROWS) and (UpgradeToBuild <= WAR_UPGRADE_SHIELD) then
          LName := UPGRADE_NAMES[UpgradeToBuild];
        Result := AnsiString(Format('upg=%s progress=%d%% cancelled=%d', [string(LName), Progress(BuildTime,
          TotalBuildTime), Ord(Cancelled)]));
      end;
    WAR_STATE_BUILD:
      with PWarStateBuild(AState)^ do
        Result := AnsiString(Format('worker=#%d progress=%d%% cancelled=%d', [WorkerId, Progress(BuildTime,
          TotalBuildTime), Ord(Cancelled)]));
    WAR_STATE_REPAIR:
      Result := AnsiString(Format('building=#%d', [PWarStateRepair(AState)^.BuildingId]));
    WAR_STATE_REPAIRING:
      with PWarStateRepairing(AState)^ do
        Result := AnsiString(Format('building=#%d inside=%d', [BuildingId, Ord(InsideBuilding)]));
    WAR_STATE_CAST:
      with PWarStateCast(AState)^ do
      begin
        if (SpellType >= WAR_SPELL_HEALING) and (SpellType <= High(SPELL_NAMES)) then
          LName := SPELL_NAMES[SpellType]
        else
          LName := 'UNKNOWN_SPELL';
        Result := AnsiString(Format('spell=%s target=#%d pos=(%d,%d)', [string(LName), TargetEntityId,
          Trunc(TargetPosition.X), Trunc(TargetPosition.Y)]));
      end;
    WAR_STATE_WAIT:
      begin
        LRemaining := Max(PWarStateWait(AState)^.WaitEndGameTime - AContext.Clock^.GameTime, 0.0);
        Result := 'remaining=' + TWarCFormat.Fixed1(LRemaining) + 's';
      end;
  end;
end;

class function TWarDebugStateText.Build(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  ASlot: Integer): AnsiString;
var
  LEntity: PWarEntity;
  LIndex: Integer;
  LState: PWarStateBase;
  LPending: PWarTransitionRequest;
begin
  LEntity := AContext.Pool.Slots[ASlot];
  if not LEntity^.HasStateMachine then
    Exit('');
  Result := '=== ' + UnitName(LEntity) + ' #' + AnsiString(IntToStr(LEntity^.Id)) + ' (depth=' +
    AnsiString(IntToStr(LEntity^.StateMachine.Depth)) + ') ===' + #10;
  if LEntity^.StateMachine.Depth = 0 then
    Result := Result + 'NO_STATE' + #10
  else
    for LIndex := LEntity^.StateMachine.Depth - 1 downto 0 do
    begin
      LState := AContext.Storage.Deref(LEntity^.StateMachine.Stack[LIndex]);
      if not Assigned(LState) then
      begin
        Result := Result + '<INVALID_STATE>' + #10;
        Continue;
      end;
      Result := Result + TWarCFormat.PadRight(StateName(LState^.StateType), 10) + ' ' + Detail(AContext, LState) + #10;
    end;
  LPending := @LEntity^.StateMachine.Pending;
  case LPending^.Operation of
    WAR_OP_POP:
      Result := Result + 'pending: >>POP' + #10;
    WAR_OP_PUSH, WAR_OP_REPLACE, WAR_OP_RESET:
      // WAR_STATE_REF_IS_VALID: a type of the table, an index of the storage and a generation that is not 0
      if (LPending^.StateRef.StateType >= WAR_STATE_IDLE) and (LPending^.StateRef.StateType < WAR_STATE_COUNT) and
        (LPending^.StateRef.Index >= 0) and (LPending^.StateRef.Generation <> 0) then
        Result := Result + 'pending: >>' + OPERATION_NAMES[LPending^.Operation] + ' -> ' +
          StateName(LPending^.StateRef.StateType) + #10
      else
        Result := Result + 'pending: >>' + OPERATION_NAMES[LPending^.Operation] + #10;
  end;
  if Length(Result) > MAX_TEXT then
    SetLength(Result, MAX_TEXT);
end;

end.
