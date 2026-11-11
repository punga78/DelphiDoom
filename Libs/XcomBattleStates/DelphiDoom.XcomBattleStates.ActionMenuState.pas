{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the menu of the actions of     }
{  the item of a hand (ActionMenuState)                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.ActionMenuState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.Screens.Intf,
  DelphiDoom.XcomBattleStates.ActionMenuItem, DelphiDoom.XcomBattleStates.BattlescapeState;

const
  /// <summary>The lines of the menu (ActionMenuState::_actionMenu[6])</summary>
  XCOM_ACTION_MENU_ITEMS = 6;

type
  /// <summary>
  ///   The popup over the battle with what the soldier can do with the weapon of the action: throw, prime, the
  ///   shots, hit, use. The choice is written in the action (type, time units, targeting, or the text of what is
  ///   wrong in ResultText) and the menu goes away: the battlescape then carries the action out. The action, the
  ///   session and the parent state are not owned
  /// </summary>
  TXcomActionMenuState = class(TXcomState)
  strict private
    FParent: TXcomState;
    FSession: IXcomBattleSession;
    FScreens: IXcomBattleScreens;
    FAction: TXcomBattleAction;
    FActionMenu: array[0..XCOM_ACTION_MENU_ITEMS - 1] of TXcomActionMenuItem;
    procedure Build(AX, AY: Integer);
    procedure AddItem(AActionType: Integer; const AName: string; var AId: Integer);
    function FindMedikitTarget: TXcomBattleUnit;
    procedure UseMedikit;
    procedure UseScanner;
    procedure BtnActionMenuItemClick(AAction: TXcomAction);
  public
    /// <param name="AParent">The battlescape that opens the menu: gives the battle and the other screens</param>
    /// <param name="AAction">The action to fill, with its actor and its weapon</param>
    /// <param name="AX">Left of the panel of the icons</param>
    /// <param name="AY">Top of the first line of the menu</param>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState; AAction: TXcomBattleAction;
      AX, AY: Integer); overload;
    /// <summary>The same menu on a session and on screens given one by one (AParent is passed on to the screens)</summary>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomState; const ASession: IXcomBattleSession;
      const AScreens: IXcomBattleScreens; AAction: TXcomBattleAction; AX, AY: Integer); overload;
    /// <summary>handle: the right button and the keys of cancel and of the two hands close the menu</summary>
    procedure Handle(AAction: TXcomAction); override;
    procedure Resize(var ADX, ADY: Integer); override;
    /// <summary>How many lines the menu shows</summary>
    function ItemCount: Integer;
    /// <summary>A line of the menu, 0 the lowest</summary>
    function Item(AIndex: Integer): TXcomActionMenuItem;
  end;

implementation

uses
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomBattle.Types;

const
  SNoActionMenuElement = 'The interface of the battlescape has no element "actionMenu"';

constructor TXcomActionMenuState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState;
  AAction: TXcomBattleAction; AX, AY: Integer);
begin
  Create(AHost, AParent, AParent.Session, AParent.Screens, AAction, AX, AY);
end;

constructor TXcomActionMenuState.Create(AHost: TXcomStateHost; AParent: TXcomState;
  const ASession: IXcomBattleSession; const AScreens: IXcomBattleScreens; AAction: TXcomBattleAction; AX, AY: Integer);
begin
  inherited Create(AHost);
  FParent := AParent;
  FSession := ASession;
  FScreens := AScreens;
  FAction := AAction;
  ToggleScreen;
  // SavedBattleGame::setPaletteByDepth
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(ASession.Graphics.Palette(ASession.Battle.Depth), 0, 256);
  Build(AX, AY);
end;

procedure TXcomActionMenuState.Build(AX, AY: Integer);
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
  LIndex, LId: Integer;
  LWeapon: TXcomRuleItem;
begin
  LInterface := Host.Resources.GetInterface('battlescape');
  if (not Assigned(LInterface)) or (not LInterface.TryGetElement('actionMenu', LElement)) then
    raise EXcomEngineException.Create(SNoActionMenuElement);
  for LIndex := 0 to High(FActionMenu) do
  begin
    FActionMenu[LIndex] := TXcomActionMenuItem.Create(LIndex, LElement, Host.Resources.GetFont('FONT_BIG'),
      Host.Resources.GetFont('FONT_SMALL'), Host.Language, AX, AY);
    Add(FActionMenu[LIndex]);
    FActionMenu[LIndex].Visible := False;
    FActionMenu[LIndex].OnMouseClick(BtnActionMenuItemClick);
  end;

  // build up the popup menu
  LId := 0;
  LWeapon := FAction.Weapon.Rules;
  // throwing (if not a fixed weapon)
  if not LWeapon.FixedWeapon then
    AddItem(BA_THROW, 'STR_THROW', LId);
  // priming
  if ((LWeapon.BattleType = TXcomRuleItem.BT_GRENADE) or (LWeapon.BattleType = TXcomRuleItem.BT_PROXIMITYGRENADE)) and
    (FAction.Weapon.FuseTimer = -1) then
    AddItem(BA_PRIME, 'STR_PRIME_GRENADE', LId);
  if LWeapon.BattleType = TXcomRuleItem.BT_FIREARM then
  begin
    if (LWeapon.Waypoints <> 0) or (Assigned(FAction.Weapon.AmmoItem) and
      (FAction.Weapon.AmmoItem.Rules.Waypoints <> 0)) then
      AddItem(BA_LAUNCH, 'STR_LAUNCH_MISSILE', LId)
    else
    begin
      if LWeapon.AccuracyAuto <> 0 then
        AddItem(BA_AUTOSHOT, 'STR_AUTO_SHOT', LId);
      if LWeapon.AccuracySnap <> 0 then
        AddItem(BA_SNAPSHOT, 'STR_SNAP_SHOT', LId);
      if LWeapon.AccuracyAimed <> 0 then
        AddItem(BA_AIMEDSHOT, 'STR_AIMED_SHOT', LId);
    end;
  end;
  if LWeapon.TimeUnitsMelee <> 0 then
  begin
    // stun rod
    if (LWeapon.BattleType = TXcomRuleItem.BT_MELEE) and (LWeapon.DamageType = TXcomRuleItem.DT_STUN) then
      AddItem(BA_HIT, 'STR_STUN', LId)
    else
      // melee weapon
      AddItem(BA_HIT, 'STR_HIT_MELEE', LId);
  end
  // special items
  else if LWeapon.BattleType = TXcomRuleItem.BT_MEDIKIT then
    AddItem(BA_USE, 'STR_USE_MEDI_KIT', LId)
  else if LWeapon.BattleType = TXcomRuleItem.BT_SCANNER then
    AddItem(BA_USE, 'STR_USE_SCANNER', LId)
  else if (LWeapon.BattleType = TXcomRuleItem.BT_PSIAMP) and (FAction.Actor.Stats.PsiSkill > 0) then
  begin
    AddItem(BA_MINDCONTROL, 'STR_MIND_CONTROL', LId);
    AddItem(BA_PANIC, 'STR_PANIC_UNIT', LId);
  end
  else if LWeapon.BattleType = TXcomRuleItem.BT_MINDPROBE then
    AddItem(BA_USE, 'STR_USE_MIND_PROBE', LId);
end;

procedure TXcomActionMenuState.AddItem(AActionType: Integer; const AName: string; var AId: Integer);
var
  LAccuracyText, LTimeUnitsText: string;
  LAccuracy, LTimeUnits: Integer;
begin
  LAccuracyText := '';
  LAccuracy := FAction.Actor.GetFiringAccuracy(AActionType, FAction.Weapon);
  if AActionType = BA_THROW then
    LAccuracy := Trunc(FAction.Actor.GetThrowingAccuracy);
  LTimeUnits := FAction.Actor.GetActionTus(AActionType, FAction.Weapon);
  if (AActionType = BA_THROW) or (AActionType = BA_AIMEDSHOT) or (AActionType = BA_SNAPSHOT) or
    (AActionType = BA_AUTOSHOT) or (AActionType = BA_LAUNCH) or (AActionType = BA_HIT) then
    // Unicode::formatPercentage
    LAccuracyText := Tr('STR_ACCURACY_SHORT').Arg(IntToStr(LAccuracy) + '%').Text;
  LTimeUnitsText := Tr('STR_TIME_UNITS_SHORT').Arg(LTimeUnits).Text;
  FActionMenu[AId].SetAction(AActionType, Tr(AName).Text, LAccuracyText, LTimeUnitsText, LTimeUnits);
  FActionMenu[AId].Visible := True;
  Inc(AId);
end;

procedure TXcomActionMenuState.Handle(AAction: TXcomAction);
var
  LKey: Integer;
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekMouseDown) and (AAction.Details.Button = XCOM_BUTTON_RIGHT) then
    Host.PopState
  else if AAction.Details.Kind = ekKeyDown then
  begin
    LKey := AAction.Details.Key;
    if (LKey = Host.Options.GetValue('keyCancel')) or (LKey = Host.Options.GetValue('keyBattleUseLeftHand')) or
      (LKey = Host.Options.GetValue('keyBattleUseRightHand')) then
      Host.PopState;
  end;
end;

function TXcomActionMenuState.FindMedikitTarget: TXcomBattleUnit;
var
  LUnit: TXcomBattleUnit;
  LTile: TXcomTile;
begin
  Result := nil;
  // we can heal a unit that is at the same position, unconscious and healable(=woundable)
  for LUnit in FSession.Battle.Units do
    if (LUnit.Position = FAction.Actor.Position) and (LUnit <> FAction.Actor) and
      (LUnit.Status = STATUS_UNCONSCIOUS) and LUnit.IsWoundable then
      Exit(LUnit);
  if FSession.TileEngine.ValidMeleeRange(FAction.Actor.Position, FAction.Actor.Direction, FAction.Actor, nil,
    FAction.Target, False) then
  begin
    LTile := FSession.Battle.TileAt(FAction.Target);
    if Assigned(LTile) and Assigned(LTile.CurrentUnit) and LTile.CurrentUnit.IsWoundable then
      Result := LTile.CurrentUnit;
  end;
end;

procedure TXcomActionMenuState.UseMedikit;
var
  LTarget: TXcomBattleUnit;
  LScreen: TXcomState;
begin
  LTarget := FindMedikitTarget;
  if not Assigned(LTarget) then
  begin
    FAction.ResultText := 'STR_THERE_IS_NO_ONE_THERE';
    Host.PopState;
    Exit;
  end;
  LScreen := nil;
  if Assigned(FScreens) then
    LScreen := FScreens.Medikit(FParent, LTarget, FAction);
  // no medi-kit screen: the line does nothing and the action is not left half chosen
  if not Assigned(LScreen) then
  begin
    FAction.ActionType := BA_NONE;
    Exit;
  end;
  Host.PopState;
  Host.PushState(LScreen);
end;

procedure TXcomActionMenuState.UseScanner;
var
  LScreen: TXcomState;
begin
  if FAction.TimeUnits > FAction.Actor.TimeUnits then
  begin
    FAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS';
    Host.PopState;
    Exit;
  end;
  LScreen := nil;
  if Assigned(FScreens) then
    LScreen := FScreens.Scanner(FParent, FAction);
  // no scanner screen: the line does nothing and no time unit is spent
  if not Assigned(LScreen) then
  begin
    FAction.ActionType := BA_NONE;
    Exit;
  end;
  // spend TUs first, then show the scanner
  FAction.Actor.SpendTimeUnits(FAction.TimeUnits);
  Host.PopState;
  Host.PushState(LScreen);
end;

procedure TXcomActionMenuState.BtnActionMenuItemClick(AAction: TXcomAction);
var
  LButton, LIndex: Integer;
  LWeapon: TXcomRuleItem;
  LWeaponUsable: string;
  LScreen: TXcomState;
begin
  FSession.Pathfinding.RemovePreview;
  LButton := -1;
  LWeapon := FAction.Weapon.Rules;
  LWeaponUsable := FSession.Battle.GetItemUsable(FAction.Weapon);
  // got to find out which button was pressed
  for LIndex := 0 to High(FActionMenu) do
    if AAction.Sender = FActionMenu[LIndex] then
    begin
      LButton := LIndex;
      Break;
    end;
  if LButton = -1 then
    Exit;

  FAction.ActionType := FActionMenu[LButton].ActionType;
  FAction.TimeUnits := FActionMenu[LButton].TimeUnits;
  if (FAction.ActionType <> BA_THROW) and (FAction.Actor.OriginalFaction = FACTION_PLAYER) and
    (not FSession.SavedGame.IsResearched(LWeapon.Requirements)) then
  begin
    FAction.ResultText := 'STR_UNABLE_TO_USE_ALIEN_ARTIFACT_UNTIL_RESEARCHED';
    Host.PopState;
  end
  else if (FAction.ActionType <> BA_THROW) and (LWeaponUsable <> '') then
  begin
    FAction.ResultText := LWeaponUsable;
    Host.PopState;
  end
  else if FAction.ActionType = BA_PRIME then
  begin
    if LWeapon.BattleType = TXcomRuleItem.BT_PROXIMITYGRENADE then
    begin
      FAction.Value := 0;
      Host.PopState;
    end
    else
    begin
      LScreen := nil;
      if Assigned(FScreens) then
        LScreen := FScreens.PrimeGrenade(FParent, FAction, False, nil);
      if Assigned(LScreen) then
        Host.PushState(LScreen)
      else
        FAction.ActionType := BA_NONE;
    end;
  end
  else if (FAction.ActionType = BA_USE) and (LWeapon.BattleType = TXcomRuleItem.BT_MEDIKIT) then
    UseMedikit
  else if (FAction.ActionType = BA_USE) and (LWeapon.BattleType = TXcomRuleItem.BT_SCANNER) then
    UseScanner
  else if FAction.ActionType = BA_LAUNCH then
  begin
    // check beforehand if we have enough time units
    if FAction.TimeUnits > FAction.Actor.TimeUnits then
      FAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS'
    else if (not Assigned(FAction.Weapon.AmmoItem)) or (FAction.Weapon.AmmoItem.AmmoQuantity = 0) then
      FAction.ResultText := 'STR_NO_AMMUNITION_LOADED'
    else
      FAction.Targeting := True;
    Host.PopState;
  end
  else if FAction.ActionType = BA_HIT then
  begin
    // check beforehand if we have enough time units
    if FAction.TimeUnits > FAction.Actor.TimeUnits then
      FAction.ResultText := 'STR_NOT_ENOUGH_TIME_UNITS'
    else if not FSession.TileEngine.ValidMeleeRange(FAction.Actor.Position, FAction.Actor.Direction, FAction.Actor,
      nil, FAction.Target) then
      FAction.ResultText := 'STR_THERE_IS_NO_ONE_THERE';
    Host.PopState;
  end
  else
  begin
    FAction.Targeting := True;
    Host.PopState;
  end;
  // meleeAttackBState won't be available to clear the action type, do it here instead.
  if (FAction.ActionType = BA_HIT) and (FAction.ResultText <> '') then
    FAction.ActionType := BA_NONE;
end;

procedure TXcomActionMenuState.Resize(var ADX, ADY: Integer);
begin
  Recenter(ADX, ADY * 2);
end;

function TXcomActionMenuState.ItemCount: Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to High(FActionMenu) do
    if FActionMenu[LIndex].Visible then
      Inc(Result);
end;

function TXcomActionMenuState.Item(AIndex: Integer): TXcomActionMenuItem;
begin
  Result := FActionMenu[AIndex];
end;

end.
