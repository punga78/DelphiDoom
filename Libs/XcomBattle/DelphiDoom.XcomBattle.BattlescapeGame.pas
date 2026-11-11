{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the game in progress: the list of     }
{  steps, the turns, the casualties (BattlescapeGame, without the screen)       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.BattlescapeGame;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomSave.BattleUnitKills,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.TileEngine, DelphiDoom.XcomBattle.Pathfinding,
  DelphiDoom.XcomBattle.Host.Intf, DelphiDoom.XcomBattle.State.Intf, DelphiDoom.XcomBattle.View.Intf,
  DelphiDoom.XcomBattle.Options, DelphiDoom.XcomBattle.Game.Intf, DelphiDoom.XcomBattle.UnitConverter;

type
  /// <summary>
  ///   What the game in progress needs besides the saved battle: the reaction fire of the units that see a move
  ///   (TileEngine::checkReactionFire, which makes the units shoot with states of their own). Without one nobody
  ///   reacts
  /// </summary>
  IXcomReactionFire = interface
    ['{7C41A8E2-5B06-4D93-A1F7-2E60C8B94D15}']
    function Check(const AUnit: TXcomBattleUnit): Boolean;
  end;

  /// <summary>
  ///   BattlescapeGame without the screen: it keeps the list of steps (a nil entry is the end of the turn), runs
  ///   the first one on every HandleState, pops it, handles the turns and the casualties. The screen is an
  ///   IXcomBattleView. It is a plain class (no reference counting): the steps hold it weakly
  /// </summary>
  TXcomBattlescapeGame = class(TObject, IXcomBattleHost, IXcomBattlescapeGame)
  strict private
    FSave: TXcomSavedBattleGame;
    FEngine: TXcomTileEngine;
    FPathfinding: TXcomPathfinding;
    FRuleset: TXcomRuleset;
    FOptions: TXcomBattleOptions;
    FView: IXcomBattleView;
    FConverter: TXcomUnitConverter;
    FReactionFire: IXcomReactionFire;
    FStates: TList<IXcomBattleState>;
    FCurrentAction: TXcomBattleAction;
    FMissionCount: Integer;
    FPlayerPanicHandled: Boolean;
    FAIActionCounter: Integer;
    FEndTurnRequested: Boolean;
    FEndTurnProcessed: Boolean;
    FDebugPlay: Boolean;
    procedure PushExplosionAndEndTurn(const ACenter: TXcomPosition; const AItem: TXcomBattleItem;
      const AUnit: TXcomBattleUnit; const ATile: TXcomTile);
    procedure FillKillStatistics(const AKill: TXcomBattleUnitKills; const AUnit: TXcomBattleUnit);
    function CopyKill(const ASource: TXcomBattleUnitKills): TXcomBattleUnitKills;
    function NoActionsPending(const AUnit: TXcomBattleUnit): Boolean;
  public
    constructor Create(const ASave: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
      const APathfinding: TXcomPathfinding; const ARuleset: TXcomRuleset; const AOptions: TXcomBattleOptions;
      const AView: IXcomBattleView; ADifficulty: Integer);
    destructor Destroy; override;
    function QueryInterface(const AGuid: TGUID; out AObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    // IXcomBattleHost
    function PanicHandled: Boolean;
    function CurrentActionType: Integer;
    function ReservedAction: Integer;
    function CheckReservedTu(const AUnit: TXcomBattleUnit; ATimeUnits: Integer; AJustChecking: Boolean = False)
      : Boolean;
    procedure StatePushNext(const AState: IXcomBattleState);
    procedure StatePushFront(const AState: IXcomBattleState);
    procedure StatePushBack(const AState: IXcomBattleState);
    procedure PopState;
    // IXcomBattlescapeGame
    function Save: TXcomSavedBattleGame;
    function TileEngine: TXcomTileEngine;
    function Pathfinding: TXcomPathfinding;
    function Ruleset: TXcomRuleset;
    function Options: TXcomBattleOptions;
    function View: IXcomBattleView;
    function Depth: Integer;
    procedure CheckForCasualties(const AMurderWeapon: TXcomBattleItem; const AMurderer: TXcomBattleUnit;
      AHiddenExplosion: Boolean = False; ATerrainExplosion: Boolean = False);
    procedure DropItem(const APosition: TXcomPosition; const AItem: TXcomBattleItem; ANewItem: Boolean = False;
      ARemoveItem: Boolean = False);
    function ConvertUnit(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
    function ConvertInfected: Boolean;
    procedure KnockOut(const AUnit: TXcomBattleUnit);
    function CheckReactionFire(const AUnit: TXcomBattleUnit): Boolean;
    function Kneel(const AUnit: TXcomBattleUnit): Boolean;
    procedure SetupCursor;
    procedure AutoEndBattle;
    function CheckForProximityGrenades(const AUnit: TXcomBattleUnit): Boolean;
    // BattlescapeGame
    /// <summary>init: after a turn the panic of the player's units is to be handled</summary>
    procedure Init;
    /// <summary>handleState: runs the first step (or ends the turn when the first entry is the end of the turn)</summary>
    procedure HandleState;
    /// <summary>think: nothing is happening, see about units that fall (the AI is not ported)</summary>
    procedure Think;
    /// <summary>endTurn</summary>
    procedure EndTurn;
    /// <summary>requestEndTurn</summary>
    procedure RequestEndTurn;
    /// <summary>
    ///   primaryAction (the left click on the map): aims the action in preparation (a shot or a throw: first the
    ///   unit turns, then the projectile flies), or selects the unit on the tile, or walks the selected unit there.
    ///   Waypoints, mind probe and psionics are not ported
    /// </summary>
    procedure PrimaryAction(const APosition: TXcomPosition);
    /// <summary>cancelCurrentAction</summary>
    function CancelCurrentAction(AForce: Boolean = False): Boolean;
    /// <summary>playableUnitSelected</summary>
    function PlayableUnitSelected: Boolean;
    procedure TallyUnits(out ALiveAliens, ALiveSoldiers: Integer);
    /// <summary>
    ///   The tile part of Map::animate (the timer of the animation of the game): the doors of the UFOs open and close
    ///   a frame at a time and the steps wait for them
    /// </summary>
    procedure AnimateTiles;
    /// <summary>isBusy: there are steps to run</summary>
    function IsBusy: Boolean;
    /// <summary>The name of the first step ('EndTurn' for the end of the turn), or ''</summary>
    function FrontStateName: string;
    /// <summary>The reaction fire (TXcomTileEngine.CheckReactionFire is not ported: an object does it)</summary>
    property ReactionFire: IXcomReactionFire read FReactionFire write FReactionFire;
    /// <summary>The number of missions in the saved game (the mission of the kill statistics)</summary>
    property MissionCount: Integer read FMissionCount write FMissionCount;
    property CurrentAction: TXcomBattleAction read FCurrentAction;
    property EndTurnRequested: Boolean read FEndTurnRequested write FEndTurnRequested;
  end;

implementation

uses
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomBattle.AIModule,
  DelphiDoom.XcomBattle.ExplosionState,
  DelphiDoom.XcomBattle.UnitDieState, DelphiDoom.XcomBattle.UnitFallState, DelphiDoom.XcomBattle.UnitTurnState,
  DelphiDoom.XcomBattle.UnitWalkState, DelphiDoom.XcomBattle.ProjectileFlyState;

const
  END_POINT = 13;
  SNotPorted = 'Not ported yet: %s';

constructor TXcomBattlescapeGame.Create(const ASave: TXcomSavedBattleGame; const AEngine: TXcomTileEngine;
  const APathfinding: TXcomPathfinding; const ARuleset: TXcomRuleset; const AOptions: TXcomBattleOptions;
  const AView: IXcomBattleView; ADifficulty: Integer);
begin
  inherited Create;
  FSave := ASave;
  FEngine := AEngine;
  FPathfinding := APathfinding;
  FRuleset := ARuleset;
  FOptions := AOptions;
  FView := AView;
  FConverter := TXcomUnitConverter.Create(ASave, AEngine, ARuleset, ADifficulty);
  FStates := TList<IXcomBattleState>.Create;
  FCurrentAction := TXcomBattleAction.Create;
  FPlayerPanicHandled := True;
  FEngine.Host := Self;
  CheckForCasualties(nil, nil, True);
end;

destructor TXcomBattlescapeGame.Destroy;
begin
  FEngine.Host := nil;
  FStates.Free;
  FCurrentAction.Free;
  FConverter.Free;
  inherited Destroy;
end;

function TXcomBattlescapeGame.QueryInterface(const AGuid: TGUID; out AObject): HResult;
begin
  if GetInterface(AGuid, AObject) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TXcomBattlescapeGame._AddRef: Integer;
begin
  Result := -1;
end;

function TXcomBattlescapeGame._Release: Integer;
begin
  Result := -1;
end;

function TXcomBattlescapeGame.PanicHandled: Boolean;
begin
  Result := FPlayerPanicHandled;
end;

function TXcomBattlescapeGame.CurrentActionType: Integer;
begin
  Result := FCurrentAction.ActionType;
end;

function TXcomBattlescapeGame.ReservedAction: Integer;
begin
  Result := FSave.TuReserved;
end;

function TXcomBattlescapeGame.Save: TXcomSavedBattleGame;
begin
  Result := FSave;
end;

function TXcomBattlescapeGame.TileEngine: TXcomTileEngine;
begin
  Result := FEngine;
end;

function TXcomBattlescapeGame.Pathfinding: TXcomPathfinding;
begin
  Result := FPathfinding;
end;

function TXcomBattlescapeGame.Ruleset: TXcomRuleset;
begin
  Result := FRuleset;
end;

function TXcomBattlescapeGame.Options: TXcomBattleOptions;
begin
  Result := FOptions;
end;

function TXcomBattlescapeGame.View: IXcomBattleView;
begin
  Result := FView;
end;

function TXcomBattlescapeGame.Depth: Integer;
begin
  Result := FSave.Depth;
end;

procedure TXcomBattlescapeGame.AnimateTiles;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FSave.MapSizeXyz - 1 do
    FSave.TileByIndex(LIndex).Animate;
end;

function TXcomBattlescapeGame.IsBusy: Boolean;
begin
  Result := FStates.Count > 0;
end;

function TXcomBattlescapeGame.FrontStateName: string;
begin
  if FStates.Count = 0 then
    Result := ''
  else if Assigned(FStates[0]) then
  begin
    Result := FStates[0].StateName;
    if FStates[0] is TXcomExplosionState then
      Result := Result + '[' + (FStates[0] as TXcomExplosionState).Description + ']';
    if FStates[0] is TXcomProjectileFlyState then
      Result := Result + '[' + (FStates[0] as TXcomProjectileFlyState).ProjectileText + ']';
  end
  else
    Result := 'EndTurn';
end;

function TXcomBattlescapeGame.CheckReactionFire(const AUnit: TXcomBattleUnit): Boolean;
begin
  if Assigned(FReactionFire) then
    Result := FReactionFire.Check(AUnit)
  else
    Result := False;
end;

function TXcomBattlescapeGame.Kneel(const AUnit: TXcomBattleUnit): Boolean;
var
  LTimeUnits: Integer;
begin
  if AUnit.IsKneeled then
    LTimeUnits := 8
  else
    LTimeUnits := 4;
  if (AUnit.UnitType = 'SOLDIER') and (not AUnit.IsFloating) and
    (((not AUnit.IsKneeled) and FSave.KneelReserved) or CheckReservedTu(AUnit, LTimeUnits)) then
  begin
    if AUnit.SpendTimeUnits(LTimeUnits) then
    begin
      AUnit.Kneel(not AUnit.IsKneeled);
      // kneeling or standing up can reveal new terrain or units. I guess.
      FEngine.CalculateFov(AUnit);
      FView.CacheUnits;
      FView.UpdateSoldierInfo;
      CheckReactionFire(AUnit);
      Exit(True);
    end
    else
      FView.Warning('STR_NOT_ENOUGH_TIME_UNITS');
  end;
  Result := False;
end;

procedure TXcomBattlescapeGame.Init;
begin
  if (FSave.Side = FACTION_PLAYER) and (FSave.Turn > 1) then
    FPlayerPanicHandled := False;
end;

procedure TXcomBattlescapeGame.Think;
begin
  // nothing is happening - see if we need some alien AI or units panicking or what have you
  if FStates.Count = 0 then
  begin
    if FSave.UnitsFalling then
    begin
      StatePushFront(TXcomUnitFallState.Create(Self));
      FSave.UnitsFalling := False;
      Exit;
    end;
    if FSave.Side <> FACTION_PLAYER then
      raise EXcomBattleException.CreateFmt(SNotPorted, ['the turn of the AI (handleAI)'])
    else if not FPlayerPanicHandled then
      raise EXcomBattleException.CreateFmt(SNotPorted, ['the panic of the player''s units']);
  end;
end;

procedure TXcomBattlescapeGame.HandleState;
var
  LFront: IXcomBattleState;
begin
  if FStates.Count > 0 then
  begin
    // end turn request?
    LFront := FStates[0];
    if not Assigned(LFront) then
    begin
      FStates.Delete(0);
      EndTurn;
      Exit;
    end
    else
      LFront.Think;
  end;
end;

procedure TXcomBattlescapeGame.StatePushFront(const AState: IXcomBattleState);
begin
  FStates.Insert(0, AState);
  AState.Init;
end;

procedure TXcomBattlescapeGame.StatePushNext(const AState: IXcomBattleState);
begin
  if FStates.Count = 0 then
  begin
    FStates.Insert(0, AState);
    AState.Init;
  end
  else
    FStates.Insert(1, AState);
end;

procedure TXcomBattlescapeGame.StatePushBack(const AState: IXcomBattleState);
begin
  if FStates.Count = 0 then
  begin
    FStates.Insert(0, AState);
    // end turn request?
    if not Assigned(AState) then
    begin
      FStates.Delete(0);
      EndTurn;
      Exit;
    end
    else
      AState.Init;
  end
  else
    FStates.Add(AState);
end;

function TXcomBattlescapeGame.NoActionsPending(const AUnit: TXcomBattleUnit): Boolean;
var
  LState: IXcomBattleState;
begin
  Result := True;
  for LState in FStates do
    if Assigned(LState) and Assigned(LState.Action) and (LState.Action.Actor = AUnit) then
      Exit(False);
end;

procedure TXcomBattlescapeGame.SetupCursor;
begin
  if FCurrentAction.Targeting then
  begin
    if FCurrentAction.ActionType = BA_THROW then
      FView.SetCursorType(1)
    else
      FView.SetCursorType(0);
  end
  else if FCurrentAction.ActionType <> BA_HIT then
  begin
    FCurrentAction.Actor := FSave.SelectedUnit;
    FView.SetCursorType(0);
  end;
end;

procedure TXcomBattlescapeGame.PopState;
var
  LActionFailed: Boolean;
  LAction: TXcomBattleAction;
  LActor: TXcomBattleUnit;
  LType: Integer;
  LTargeting: Boolean;
  LTimeUnits: Integer;
  LResult: string;
begin
  LActionFailed := False;
  if FStates.Count = 0 then
    Exit;
  LActor := nil;
  LType := BA_NONE;
  LTargeting := False;
  LTimeUnits := 0;
  LResult := '';
  if Assigned(FStates[0]) and Assigned(FStates[0].Action) then
  begin
    LAction := FStates[0].Action;
    LActor := LAction.Actor;
    LType := LAction.ActionType;
    LTargeting := LAction.Targeting;
    LTimeUnits := LAction.TimeUnits;
    LResult := LAction.ResultText;
  end;
  if Assigned(LActor) and (LResult <> '') and (LActor.Faction = FACTION_PLAYER) and FPlayerPanicHandled and
    ((FSave.Side = FACTION_PLAYER) or FDebugPlay) then
  begin
    FView.Warning(LResult);
    LActionFailed := True;
  end;
  FStates.Delete(0);
  // handle the end of this unit's actions
  if Assigned(LActor) and NoActionsPending(LActor) then
  begin
    if LActor.Faction = FACTION_PLAYER then
    begin
      // spend TUs of "target triggered actions" (shooting, throwing) only
      if LTargeting and Assigned(FSave.SelectedUnit) and (not LActionFailed) then
        LActor.SpendTimeUnits(LTimeUnits);
      if FSave.Side = FACTION_PLAYER then
        // after throwing the cursor returns to default cursor
        if ((LType = BA_THROW) or (LType = BA_LAUNCH)) and (not LActionFailed) then
        begin
          if LType = BA_LAUNCH then
            FCurrentAction.Waypoints.Clear;
          FCurrentAction.Targeting := False;
          FCurrentAction.ActionType := BA_NONE;
          SetupCursor;
        end;
    end
    else
    begin
      // spend TUs
      LActor.SpendTimeUnits(LTimeUnits);
      if (FSave.Side <> FACTION_PLAYER) and (not FDebugPlay) then
        // AI does three things per unit, before switching to the next, or it got killed before doing the second thing
        if (FAIActionCounter > 2) or (not Assigned(FSave.SelectedUnit)) or FSave.SelectedUnit.IsOut then
        begin
          if Assigned(FSave.SelectedUnit) then
          begin
            FSave.SelectedUnit.CacheInvalid := True;
            FView.CacheUnit(FSave.SelectedUnit);
          end;
          FAIActionCounter := 0;
          if (FStates.Count = 0) and (FSave.SelectNextPlayerUnit(True) = nil) then
          begin
            if not FSave.DebugMode then
            begin
              FEndTurnRequested := True;
              StatePushBack(nil); // end AI turn
            end
            else
            begin
              FSave.SelectNextPlayerUnit;
              FDebugPlay := True;
            end;
          end;
          if Assigned(FSave.SelectedUnit) then
            FView.CenterOnPosition(FSave.SelectedUnit.Position);
        end;
    end;
  end;
  if FStates.Count > 0 then
  begin
    // end turn request?
    if not Assigned(FStates[0]) then
    begin
      while FStates.Count > 0 do
      begin
        if not Assigned(FStates[0]) then
          FStates.Delete(0)
        else
          Break;
      end;
      if FStates.Count = 0 then
      begin
        EndTurn;
        Exit;
      end
      else
        FStates.Add(nil);
    end;
    // init the next state in queue
    FStates[0].Init;
  end;
  // the currently selected unit died or became unconscious or disappeared inexplicably
  if (not Assigned(FSave.SelectedUnit)) or FSave.SelectedUnit.IsOut then
  begin
    FCurrentAction.Targeting := False;
    FCurrentAction.ActionType := BA_NONE;
    FView.SetCursorType(0, 1);
    if FSave.Side = FACTION_PLAYER then
      FSave.SelectedUnit := nil
    else
      FSave.SelectNextPlayerUnit(True, True);
  end;
  FView.UpdateSoldierInfo;
end;

function TXcomBattlescapeGame.CheckReservedTu(const AUnit: TXcomBattleUnit; ATimeUnits: Integer;
  AJustChecking: Boolean): Boolean;
var
  LEffective: Integer;
  LSlowest: TXcomBattleItem;
  LKneel: Integer;
  LReserveTu: Integer;
begin
  LEffective := FSave.TuReserved; // avoid changing the reserve in this method
  if (FSave.Side <> AUnit.Faction) or (FSave.Side = FACTION_NEUTRAL) then
    Exit(ATimeUnits <= AUnit.TimeUnits);
  if (FSave.Side = FACTION_HOSTILE) and (not FDebugPlay) then
  begin
    // aliens reserve TUs as a percentage rather than just enough for a single action.
    if Assigned(AUnit.AI) then
      LEffective := (AUnit.AI as TXcomAIModule).ReserveMode;
    case LEffective of
      BA_SNAPSHOT: Exit(ATimeUnits + (AUnit.Stats.TimeUnits div 3) <= AUnit.TimeUnits);
      BA_AUTOSHOT: Exit(ATimeUnits + ((AUnit.Stats.TimeUnits div 5) * 2) <= AUnit.TimeUnits);
      BA_AIMEDSHOT: Exit(ATimeUnits + (AUnit.Stats.TimeUnits div 2) <= AUnit.TimeUnits);
    else
      Exit(ATimeUnits <= AUnit.TimeUnits);
    end;
  end;
  LReserveTu := 0;
  // check TUs against slowest weapon if we have two weapons
  LSlowest := AUnit.GetMainHandWeapon(False);
  // if the weapon has no autoshot, reserve TUs for snapshot
  if (AUnit.GetActionTus(LEffective, LSlowest) = 0) and (LEffective = BA_AUTOSHOT) then
    LEffective := BA_SNAPSHOT;
  // likewise, if we don't have a snap shot available, try aimed.
  if (AUnit.GetActionTus(LEffective, LSlowest) = 0) and (LEffective = BA_SNAPSHOT) then
    LEffective := BA_AIMEDSHOT;
  if FSave.KneelReserved and (not AUnit.IsKneeled) and (AUnit.UnitType = 'SOLDIER') then
    LKneel := 4
  else
    LKneel := 0;
  // no aimed shot available? revert to none.
  if (AUnit.GetActionTus(LEffective, LSlowest) = 0) and (LEffective = BA_AIMEDSHOT) then
  begin
    if LKneel > 0 then
      LEffective := BA_NONE
    else
      Exit(True);
  end;
  LReserveTu := AUnit.GetActionTus(LEffective, LSlowest);
  if ((LEffective <> BA_NONE) or FSave.KneelReserved) and (ATimeUnits + LKneel + LReserveTu > AUnit.TimeUnits) and
    ((LKneel + LReserveTu <= AUnit.TimeUnits) or AJustChecking) then
  begin
    if not AJustChecking then
    begin
      if LKneel > 0 then
      begin
        if LEffective = BA_NONE then
          FView.Warning('STR_TIME_UNITS_RESERVED_FOR_KNEELING')
        else
          FView.Warning('STR_TIME_UNITS_RESERVED_FOR_KNEELING_AND_FIRING');
      end
      else
        case FSave.TuReserved of
          BA_SNAPSHOT: FView.Warning('STR_TIME_UNITS_RESERVED_FOR_SNAP_SHOT');
          BA_AUTOSHOT: FView.Warning('STR_TIME_UNITS_RESERVED_FOR_AUTO_SHOT');
          BA_AIMEDSHOT: FView.Warning('STR_TIME_UNITS_RESERVED_FOR_AIMED_SHOT');
        end;
    end;
    Exit(False);
  end;
  Result := True;
end;

procedure TXcomBattlescapeGame.PushExplosionAndEndTurn(const ACenter: TXcomPosition; const AItem: TXcomBattleItem;
  const AUnit: TXcomBattleUnit; const ATile: TXcomTile);
begin
  StatePushNext(TXcomExplosionState.Create(Self, ACenter, AItem, AUnit, ATile));
  StatePushBack(nil);
end;

procedure TXcomBattlescapeGame.EndTurn;
var
  LTile: TXcomTile;
  LIndex: Integer;
  LItem: TXcomBattleItem;
  LCenter: TXcomPosition;
  LLiveAliens: Integer;
  LLiveSoldiers: Integer;
  LInExit: Integer;
  LUnit: TXcomBattleUnit;
begin
  FDebugPlay := False;
  FCurrentAction.ActionType := BA_NONE;
  FCurrentAction.Waypoints.Clear;
  FView.ShowLaunchButton(False);
  FCurrentAction.Targeting := False;
  if not FEndTurnProcessed then
  begin
    if (FEngine.CloseUfoDoors > 0) and (FRuleset.Constants.SlidingDoorClose <> -1) then
      FView.PlaySound(FRuleset.Constants.SlidingDoorClose, TXcomPosition.Make(-1, -1, -1)); // ufo door closed
    // check for hot grenades on the ground
    if FSave.Side <> FACTION_NEUTRAL then
      for LIndex := 0 to FSave.MapSizeXyz - 1 do
        for LItem in FSave.TileByIndex(LIndex).Inventory do
          if (LItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE) and (LItem.FuseTimer = 0) then
          begin
            // it's a grenade to explode now
            LTile := FSave.TileByIndex(LIndex);
            LCenter := TXcomPosition.Make(LTile.Position.X * 16 + 8, LTile.Position.Y * 16 + 8,
              LTile.Position.Z * 24 - LTile.GetTerrainLevel);
            StatePushNext(TXcomExplosionState.Create(Self, LCenter, LItem, LItem.PreviousOwner, nil));
            FSave.RemoveItem(LItem);
            StatePushBack(nil);
            Exit;
          end;
  end;
  // check for terrain explosions
  LTile := FEngine.CheckForTerrainExplosions;
  if Assigned(LTile) then
  begin
    LCenter := TXcomPosition.Make(LTile.Position.X * 16, LTile.Position.Y * 16, LTile.Position.Z * 24);
    PushExplosionAndEndTurn(LCenter, nil, nil, LTile);
    Exit;
  end;
  if not FEndTurnProcessed then
  begin
    if FSave.Side <> FACTION_NEUTRAL then
      for LItem in FSave.Items do
        if ((LItem.Rules.BattleType = TXcomRuleItem.BT_GRENADE) or
          (LItem.Rules.BattleType = TXcomRuleItem.BT_PROXIMITYGRENADE)) and (LItem.FuseTimer > 0) then
          LItem.FuseTimer := LItem.FuseTimer - 1;
    FSave.EndTurn;
    LTile := FEngine.CheckForTerrainExplosions;
    if Assigned(LTile) then
    begin
      LCenter := TXcomPosition.Make(LTile.Position.X * 16, LTile.Position.Y * 16, LTile.Position.Z * 24);
      PushExplosionAndEndTurn(LCenter, nil, nil, LTile);
      FEndTurnProcessed := True;
      Exit;
    end;
  end;
  FEndTurnProcessed := False;
  if FSave.Side = FACTION_PLAYER then
    SetupCursor
  else
    FView.SetCursorType(-1);
  CheckForCasualties(nil, nil, False, False);
  // turn off MCed alien lighting.
  FEngine.CalculateUnitLighting;
  // if all units from either faction are killed - the mission is over.
  LLiveAliens := 0;
  LLiveSoldiers := 0;
  LInExit := 0;
  for LUnit in FSave.Units do
    if not LUnit.IsOut then
    begin
      if LUnit.OriginalFaction = FACTION_HOSTILE then
      begin
        if (not FOptions.AllowPsionicCapture) or (LUnit.Faction <> FACTION_PLAYER) or (not LUnit.Capturable) then
          Inc(LLiveAliens);
      end
      else if LUnit.OriginalFaction = FACTION_PLAYER then
      begin
        if LUnit.IsInExitArea(END_POINT) then
          Inc(LInExit);
        if LUnit.Faction = FACTION_PLAYER then
          Inc(LLiveSoldiers)
        else
          Inc(LLiveAliens);
      end;
    end;
  if FSave.AllObjectivesDestroyed and (FSave.ObjectiveType = XCOM_TILE_SPECIAL_MUST_DESTROY) then
  begin
    FView.FinishBattle(False, LLiveSoldiers);
    Exit;
  end;
  if (FSave.TurnLimit > 0) and (FSave.Turn > FSave.TurnLimit) then
  begin
    case FSave.ChronoTrigger of
      FORCE_ABORT:
        begin
          FSave.Aborted := True;
          FView.FinishBattle(True, LInExit);
          Exit;
        end;
      FORCE_WIN:
        begin
          FView.FinishBattle(False, LLiveSoldiers);
          Exit;
        end;
    else
      // force mission failure
      FSave.Aborted := True;
      FView.FinishBattle(False, 0);
      Exit;
    end;
  end;
  if (LLiveAliens > 0) and (LLiveSoldiers > 0) then
  begin
    FView.UpdateSoldierInfo;
    if Assigned(FSave.SelectedUnit) and (FSave.Side = FACTION_PLAYER) then
    begin
      FView.CenterOnPosition(FSave.SelectedUnit.Position);
      SetupCursor;
    end;
  end;
  if ((FSave.Side <> FACTION_NEUTRAL) or (LLiveAliens = 0) or (LLiveSoldiers = 0)) and FEndTurnRequested then
    FView.NextTurn;
  FEndTurnRequested := False;
end;

function TXcomBattlescapeGame.PlayableUnitSelected: Boolean;
begin
  Result := Assigned(FSave.SelectedUnit) and ((FSave.Side = FACTION_PLAYER) or FSave.DebugMode);
end;

function TXcomBattlescapeGame.CancelCurrentAction(AForce: Boolean): Boolean;
begin
  Result := False;
  if (FStates.Count = 0) or AForce then
  begin
    if FCurrentAction.Targeting then
    begin
      if (FCurrentAction.ActionType = BA_LAUNCH) and (FCurrentAction.Waypoints.Count > 0) then
      begin
        FCurrentAction.Waypoints.Delete(FCurrentAction.Waypoints.Count - 1);
        if FCurrentAction.Waypoints.Count = 0 then
          FView.ShowLaunchButton(False);
        Exit(True);
      end;
      FCurrentAction.Targeting := False;
      FCurrentAction.ActionType := BA_NONE;
      SetupCursor;
      Exit(True);
    end;
  end
  else if Assigned(FStates[0]) then
  begin
    FStates[0].Cancel;
    Exit(True);
  end;
end;

procedure TXcomBattlescapeGame.PrimaryAction(const APosition: TXcomPosition);
var
  LUnit: TXcomBattleUnit;
begin
  if FCurrentAction.Targeting and Assigned(FSave.SelectedUnit) then
  begin
    if (FCurrentAction.ActionType = BA_LAUNCH) or (FCurrentAction.ActionType = BA_USE) or
      (FCurrentAction.ActionType = BA_PANIC) or (FCurrentAction.ActionType = BA_MINDCONTROL) then
      raise EXcomBattleException.CreateFmt(SNotPorted, ['the primary action of waypoints, mind probe and psionics'])
    else
    begin
      FCurrentAction.Target := APosition;
      FView.SetCursorType(-1);
      FStates.Add(TXcomProjectileFlyState.Create(Self, FCurrentAction));
      StatePushFront(TXcomUnitTurnState.Create(Self, FCurrentAction)); // first of all turn towards the target
    end;
  end
  else
  begin
    FCurrentAction.Actor := FSave.SelectedUnit;
    LUnit := FSave.SelectUnit(APosition);
    if Assigned(LUnit) and (LUnit <> FSave.SelectedUnit) and (LUnit.Visible or FDebugPlay) then
    begin
      // select unit
      if LUnit.Faction = FSave.Side then
      begin
        FSave.SelectedUnit := LUnit;
        FView.UpdateSoldierInfo;
        CancelCurrentAction;
        SetupCursor;
        FCurrentAction.Actor := LUnit;
      end;
    end
    else if PlayableUnitSelected then
    begin
      FCurrentAction.Target := APosition;
      FPathfinding.Calculate(FCurrentAction.Actor, FCurrentAction.Target);
      FCurrentAction.Run := False;
      FCurrentAction.Strafe := False;
      if FPathfinding.GetStartDirection <> -1 then
      begin
        // start walking
        FView.SetCursorType(-1);
        StatePushBack(TXcomUnitWalkState.Create(Self, FCurrentAction));
      end;
    end;
  end;
end;

procedure TXcomBattlescapeGame.RequestEndTurn;
begin
  if not FEndTurnRequested then
  begin
    FEndTurnRequested := True;
    StatePushBack(nil);
  end;
end;

procedure TXcomBattlescapeGame.TallyUnits(out ALiveAliens, ALiveSoldiers: Integer);
var
  LUnit: TXcomBattleUnit;
begin
  ALiveSoldiers := 0;
  ALiveAliens := 0;
  for LUnit in FSave.Units do
    if not LUnit.IsOut then
    begin
      if LUnit.OriginalFaction = FACTION_HOSTILE then
      begin
        if (not FOptions.AllowPsionicCapture) or (LUnit.Faction <> FACTION_PLAYER) or (not LUnit.Capturable) then
          Inc(ALiveAliens);
      end
      else if LUnit.OriginalFaction = FACTION_PLAYER then
      begin
        if LUnit.Faction = FACTION_PLAYER then
          Inc(ALiveSoldiers)
        else
          Inc(ALiveAliens);
      end;
    end;
end;

procedure TXcomBattlescapeGame.AutoEndBattle;
var
  LEnd: Boolean;
  LLiveAliens: Integer;
  LLiveSoldiers: Integer;
begin
  if FOptions.BattleAutoEnd then
  begin
    if FSave.ObjectiveType = XCOM_TILE_SPECIAL_MUST_DESTROY then
      LEnd := FSave.AllObjectivesDestroyed
    else
    begin
      TallyUnits(LLiveAliens, LLiveSoldiers);
      LEnd := (LLiveAliens = 0) or (LLiveSoldiers = 0);
    end;
    if LEnd then
    begin
      FSave.SelectedUnit := nil;
      FCurrentAction.Targeting := False;
      FCurrentAction.ActionType := BA_NONE;
      RequestEndTurn;
    end;
  end;
end;

procedure TXcomBattlescapeGame.DropItem(const APosition: TXcomPosition; const AItem: TXcomBattleItem; ANewItem,
  ARemoveItem: Boolean);
begin
  FEngine.ItemDrop(FSave.TileAt(APosition), AItem, FRuleset.Inventories.Find('STR_GROUND'), ANewItem, ARemoveItem);
end;

function TXcomBattlescapeGame.ConvertUnit(const AUnit: TXcomBattleUnit): TXcomBattleUnit;
begin
  FView.ShowPsiButton(False);
  Result := FConverter.Convert(AUnit);
  FView.CacheUnit(Result);
end;

procedure TXcomBattlescapeGame.KnockOut(const AUnit: TXcomBattleUnit);
var
  LNew: TXcomBattleUnit;
begin
  if AUnit.SpawnUnit <> '' then
  begin
    AUnit.Respawn := False;
    LNew := ConvertUnit(AUnit);
    KnockOut(LNew);
  end
  else
    AUnit.KnockOut;
end;

function TXcomBattlescapeGame.ConvertInfected: Boolean;
var
  LIndex: Integer;
  LUnit: TXcomBattleUnit;
begin
  Result := False;
  LIndex := 0;
  while LIndex < FSave.Units.Count do
  begin
    LUnit := FSave.Units[LIndex];
    if (LUnit.Health > 0) and (LUnit.Health >= LUnit.StunLevel) and LUnit.Respawn then
    begin
      Result := True;
      LUnit.Respawn := False;
      if FOptions.BattleNotifyDeath and (LUnit.Faction = FACTION_PLAYER) then
        FView.ShowUnitMessage(LUnit, 'STR_HAS_BEEN_KILLED', False);
      ConvertUnit(LUnit);
      LIndex := 0;
    end
    else
      Inc(LIndex);
  end;
end;

function TXcomBattlescapeGame.CheckForProximityGrenades(const AUnit: TXcomBattleUnit): Boolean;
var
  LSize: Integer;
  LX: Integer;
  LY: Integer;
  LTx: Integer;
  LTy: Integer;
  LTile: TXcomTile;
  LItem: TXcomBattleItem;
  LCenter: TXcomPosition;
begin
  LSize := AUnit.Armor.Size - 1;
  for LX := LSize downto 0 do
    for LY := LSize downto 0 do
      for LTx := -1 to 1 do
        for LTy := -1 to 1 do
        begin
          LTile := FSave.TileAt(AUnit.Position + TXcomPosition.Make(LX, LY, 0) + TXcomPosition.Make(LTx, LTy, 0));
          if Assigned(LTile) then
            for LItem in LTile.Inventory do
              if (LItem.Rules.BattleType = TXcomRuleItem.BT_PROXIMITYGRENADE) and (LItem.FuseTimer = 0) then
              begin
                LCenter := TXcomPosition.Make(LTile.Position.X * 16 + 8, LTile.Position.Y * 16 + 8,
                  LTile.Position.Z * 24 + LTile.GetTerrainLevel);
                StatePushNext(TXcomExplosionState.Create(Self, LCenter, LItem, LItem.PreviousOwner, nil));
                FSave.RemoveItem(LItem);
                AUnit.CacheInvalid := True;
                FView.CacheUnit(AUnit);
                Exit(True);
              end;
        end;
  Result := False;
end;

function TXcomBattlescapeGame.CopyKill(const ASource: TXcomBattleUnitKills): TXcomBattleUnitKills;
begin
  Result := TXcomBattleUnitKills.Create;
  Result.Name := ASource.Name;
  Result.UnitType := ASource.UnitType;
  Result.Rank := ASource.Rank;
  Result.Race := ASource.Race;
  Result.Weapon := ASource.Weapon;
  Result.WeaponAmmo := ASource.WeaponAmmo;
  Result.Faction := ASource.Faction;
  Result.Status := ASource.Status;
  Result.Mission := ASource.Mission;
  Result.Turn := ASource.Turn;
  Result.Id := ASource.Id;
  Result.Side := ASource.Side;
  Result.BodyPart := ASource.BodyPart;
end;

procedure TXcomBattlescapeGame.FillKillStatistics(const AKill: TXcomBattleUnitKills; const AUnit: TXcomBattleUnit);
begin
  // BattleUnitKills::setUnitStats
  AKill.Name := '';
  AKill.UnitType := '';
  if Assigned(AUnit.GeoscapeSoldier) then
    AKill.Name := AUnit.GeoscapeSoldier.Name
  else
    AKill.UnitType := AUnit.UnitType;
  if AUnit.OriginalFaction = FACTION_PLAYER then
  begin
    if Assigned(AUnit.GeoscapeSoldier) then
    begin
      if AUnit.RankString <> '' then
        AKill.Rank := AUnit.RankString
      else
        AKill.Rank := 'STR_SOLDIER';
    end
    else if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Rank <> '') then
      AKill.Rank := AUnit.UnitRules.Rank
    else
      AKill.Rank := 'STR_HWPS';
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Race <> '') then
      AKill.Race := AUnit.UnitRules.Race
    else
      AKill.Race := 'STR_FRIENDLY';
  end
  else if AUnit.OriginalFaction = FACTION_HOSTILE then
  begin
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Rank <> '') then
      AKill.Rank := AUnit.UnitRules.Rank
    else
      AKill.Rank := 'STR_LIVE_SOLDIER';
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Race <> '') then
      AKill.Race := AUnit.UnitRules.Race
    else
      AKill.Race := 'STR_HOSTILE';
  end
  else if AUnit.OriginalFaction = FACTION_NEUTRAL then
  begin
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Rank <> '') then
      AKill.Rank := AUnit.UnitRules.Rank
    else
      AKill.Rank := 'STR_CIVILIAN';
    if Assigned(AUnit.UnitRules) and (AUnit.UnitRules.Race <> '') then
      AKill.Race := AUnit.UnitRules.Race
    else
      AKill.Race := 'STR_NEUTRAL';
  end
  else
  begin
    AKill.Rank := 'STR_UNKNOWN';
    AKill.Race := 'STR_UNKNOWN';
  end;
end;

procedure TXcomBattlescapeGame.CheckForCasualties(const AMurderWeapon: TXcomBattleItem;
  const AMurderer: TXcomBattleUnit; AHiddenExplosion, ATerrainExplosion: Boolean);
var
  LOrigMurderer: TXcomBattleUnit;
  LTempWeapon: string;
  LTempAmmo: string;
  LWeapon: TXcomBattleItem;
  LAmmoName: string;
  LUnit: TXcomBattleUnit;
  LVictim: TXcomBattleUnit;
  LMurderer: TXcomBattleUnit;
  LKill: TXcomBattleUnitKills;
  LNoSound: Boolean;
  LNoCorpse: Boolean;
  LModifier: Integer;
  LLoserMod: Integer;
  LWinnerMod: Integer;
  LBravery: Integer;
  LOther: TXcomBattleUnit;
  LSlot: string;
  LSelected: TXcomBattleUnit;
begin
  LOrigMurderer := AMurderer;
  // If the victim was killed by the murderer's death explosion, fetch who killed the murderer and make HIM the murderer!
  if Assigned(LOrigMurderer) and (not Assigned(LOrigMurderer.GeoscapeSoldier)) and
    ((LOrigMurderer.SpecialAbility = SPECAB_EXPLODEONDEATH) or
    (LOrigMurderer.SpecialAbility = SPECAB_BURN_AND_EXPLODE)) and
    (LOrigMurderer.Status = STATUS_DEAD) and (LOrigMurderer.MurdererId <> 0) then
    for LUnit in FSave.Units do
      if LUnit.Id = LOrigMurderer.MurdererId then
        LOrigMurderer := LUnit;
  // Fetch the murder weapon
  LTempWeapon := 'STR_WEAPON_UNKNOWN';
  LTempAmmo := 'STR_WEAPON_UNKNOWN';
  if Assigned(LOrigMurderer) then
  begin
    if Assigned(AMurderWeapon) then
    begin
      LTempAmmo := AMurderWeapon.Rules.Name;
      LTempWeapon := LTempAmmo;
    end;
    for LSlot in ['STR_RIGHT_HAND', 'STR_LEFT_HAND'] do
    begin
      LWeapon := LOrigMurderer.GetItem(LSlot);
      if Assigned(LWeapon) then
        for LAmmoName in LWeapon.Rules.CompatibleAmmo do
          if LAmmoName = LTempAmmo then
            LTempWeapon := LWeapon.Rules.Name;
    end;
  end;
  for LUnit in FSave.Units.ToArray do
  begin
    if LUnit.Status = STATUS_IGNORE_ME then
      Continue;
    LVictim := LUnit;
    LMurderer := LOrigMurderer;
    LKill := TXcomBattleUnitKills.Create;
    try
      LKill.Mission := FMissionCount;
      LKill.SetTurn(FSave.Turn, FSave.Side);
      FillKillStatistics(LKill, LVictim);
      LKill.Faction := LVictim.Faction;
      LKill.Side := LVictim.FatalShotSide;
      LKill.BodyPart := LVictim.FatalShotBodyPart;
      LKill.Id := LVictim.Id;
      LKill.Weapon := LTempWeapon;
      LKill.WeaponAmmo := LTempAmmo;
      // Determine murder type
      if LUnit.Status <> STATUS_DEAD then
      begin
        if LUnit.Health = 0 then
          LKill.Status := STATUS_DEAD
        else if (LUnit.StunLevel >= LUnit.Health) and (LUnit.Status <> STATUS_UNCONSCIOUS) then
          LKill.Status := STATUS_UNCONSCIOUS;
      end;
      // Assume that, in absence of a murderer and an explosion, the last unit to hit the victim is the murderer.
      if (not Assigned(LMurderer)) and (not ATerrainExplosion) then
        for LOther in FSave.Units do
          if LOther.Id = LVictim.MurdererId then
          begin
            LMurderer := LOther;
            LKill.Weapon := LVictim.MurdererWeapon;
            LKill.WeaponAmmo := LVictim.MurdererWeaponAmmo;
            Break;
          end;
      if Assigned(LMurderer) and (LKill.Status <> STATUS_IGNORE_ME) then
      begin
        if (LMurderer.Faction = FACTION_PLAYER) and (LMurderer.OriginalFaction <> FACTION_PLAYER) then
        begin
          // This must be a mind controlled unit. Find out who mind controlled him and award the kill to that unit.
          for LOther in FSave.Units do
            if (LOther.Id = LMurderer.MindControllerId) and Assigned(LOther.GeoscapeSoldier) then
            begin
              LOther.Statistics.Kills.Add(CopyKill(LKill));
              if LVictim.Faction = FACTION_HOSTILE then
                LOther.Statistics.SlaveKills := LOther.Statistics.SlaveKills + 1;
              LVictim.MurdererId := LOther.Id;
              Break;
            end;
        end
        else if not LMurderer.Statistics.DuplicateEntry(LKill.Status, LVictim.Id) then
        begin
          LMurderer.Statistics.Kills.Add(CopyKill(LKill));
          LVictim.MurdererId := LMurderer.Id;
        end;
      end;
      LNoSound := False;
      LNoCorpse := False;
      if LUnit.Status <> STATUS_DEAD then
      begin
        if LUnit.Health = 0 then
        begin
          if LUnit.Status = STATUS_UNCONSCIOUS then
            LNoCorpse := True;
          if Assigned(LMurderer) then
          begin
            LMurderer.AddKillCount;
            LVictim.KilledBy := LMurderer.Faction;
            if LMurderer.Faction = FACTION_PLAYER then
              LModifier := FSave.GetMoraleModifier
            else
              LModifier := 100;
            // if there is a known murderer, he will get a morale bonus if he is of a different faction
            if ((LVictim.OriginalFaction = FACTION_PLAYER) and (LMurderer.Faction = FACTION_HOSTILE)) or
              ((LVictim.OriginalFaction = FACTION_HOSTILE) and (LMurderer.Faction = FACTION_PLAYER)) then
              LMurderer.MoraleChange(20 * LModifier div 100);
            // murderer will get a penalty with friendly fire
            if LVictim.OriginalFaction = LMurderer.OriginalFaction then
              LMurderer.MoraleChange(-(2000 div LModifier));
            if LVictim.OriginalFaction = FACTION_NEUTRAL then
            begin
              if LMurderer.OriginalFaction = FACTION_PLAYER then
                LMurderer.MoraleChange(-(1000 div LModifier))
              else
                LMurderer.MoraleChange(10);
            end;
          end;
          if LVictim.Faction <> FACTION_NEUTRAL then
          begin
            LModifier := FSave.GetMoraleModifier(LVictim);
            if LVictim.Faction = FACTION_HOSTILE then
              LLoserMod := 100
            else
              LLoserMod := FSave.GetMoraleModifier;
            if LVictim.Faction = FACTION_HOSTILE then
              LWinnerMod := FSave.GetMoraleModifier
            else
              LWinnerMod := 100;
            for LOther in FSave.Units do
              if (not LOther.IsOut) and (LOther.Armor.Size = 1) then
              begin
                // the losing squad all get a morale loss
                if LOther.OriginalFaction = LVictim.OriginalFaction then
                begin
                  LBravery := (110 - LOther.Stats.Bravery) div 10;
                  LOther.MoraleChange(-(LModifier * 200 * LBravery div LLoserMod div 100));
                  if (LVictim.Faction = FACTION_HOSTILE) and Assigned(LMurderer) then
                    LMurderer.TurnsSinceSpotted := 0;
                end
                // the winning squad all get a morale increase
                else
                  LOther.MoraleChange(10 * LWinnerMod div 100);
              end;
          end;
          if Assigned(AMurderWeapon) then
            StatePushNext(TXcomUnitDieState.Create(Self, LUnit, AMurderWeapon.Rules.DamageType, LNoSound, LNoCorpse))
          else if AHiddenExplosion then
          begin
            // this is instant death from UFO powersources, without screaming sounds
            LNoSound := True;
            StatePushNext(TXcomUnitDieState.Create(Self, LUnit, TXcomRuleItem.DT_HE, LNoSound, LNoCorpse));
          end
          else if ATerrainExplosion then
            // terrain explosion
            StatePushNext(TXcomUnitDieState.Create(Self, LUnit, TXcomRuleItem.DT_HE, LNoSound, LNoCorpse))
          else
            // no murderer, and no terrain explosion, must be fatal wounds
            StatePushNext(TXcomUnitDieState.Create(Self, LUnit, TXcomRuleItem.DT_NONE, LNoSound, LNoCorpse));
          // one of our own died, record the murderer instead of the victim
          if Assigned(LVictim.GeoscapeSoldier) then
          begin
            LVictim.Statistics.KIA := True;
            FView.SoldierKilled(LVictim);
          end;
        end
        else if (LUnit.StunLevel >= LUnit.Health) and (LUnit.Status <> STATUS_UNCONSCIOUS) then
        begin
          if Assigned(LVictim.GeoscapeSoldier) then
            LVictim.Statistics.WasUnconscious := True;
          LNoSound := True;
          StatePushNext(TXcomUnitDieState.Create(Self, LUnit, TXcomRuleItem.DT_STUN, LNoSound, LNoCorpse));
        end;
      end;
    finally
      LKill.Free;
    end;
  end;
  LSelected := FSave.SelectedUnit;
  if FSave.Side = FACTION_PLAYER then
    FView.ShowPsiButton(Assigned(LSelected) and Assigned(LSelected.GetSpecialWeapon(TXcomRuleItem.BT_PSIAMP)) and
      (not LSelected.IsOut));
end;

end.
