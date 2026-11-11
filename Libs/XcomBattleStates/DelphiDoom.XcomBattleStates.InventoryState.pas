{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screen of the inventory    }
{  of a soldier during a battle (InventoryState)                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.InventoryState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.BattlescapeButton, DelphiDoom.XcomMod.RuleInventory,
  DelphiDoom.XcomSave.EquipmentLayoutItem,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattleStates.Session.Intf,
  DelphiDoom.XcomBattleStates.BattlescapeState, DelphiDoom.XcomBattleStates.Inventory;

type
  /// <summary>
  ///   Screen which displays the inventory of the selected soldier of a battle, opened by the battlescape (the
  ///   parent, never nil). With ATimeUnits the moves cost time units; without (the debug mode) they are free, a
  ///   right click primes the grenades and OK prepares the units as before the first turn. Leaving the screen lets
  ///   the dropped items fall and computes the light and the field of view again.
  ///   Without time units the two buttons of the equipment template are shown: the first copies the equipment
  ///   of the soldier, the second gives it to the soldier on screen from the items on the ground (with no
  ///   template it empties the inventory); the keys of Options clear the inventory and equip automatically.
  ///   Not ported: the inventory from the base (no parent), Options::maximizeInfoScreens, the mouse refresh after
  ///   a change (SDL_WarpMouse) and the psi strength shown by Options::psiStrengthEval
  /// </summary>
  TXcomInventoryState = class(TXcomState)
  strict private
    FParent: TXcomBattlescapeState;
    FSession: IXcomBattleSession;
    FBattle: TXcomSavedBattleGame;
    FTimeUnits: Boolean;
    FLeft: Boolean;
    FBg: TXcomWidget;
    FSoldier: TXcomWidget;
    FTxtName, FTxtItem, FTxtAmmo, FTxtWeight, FTxtTus, FTxtFAcc, FTxtReact, FTxtPSkill, FTxtPStr: TXcomText;
    FBtnOk, FBtnPrev, FBtnNext, FBtnUnload, FBtnGround, FBtnRank, FBtnCreateTemplate,
      FBtnApplyTemplate: TXcomBattlescapeButton;
    FTemplate: TObjectList<TXcomEquipmentLayoutItem>;
    FSelAmmo: TXcomWidget;
    FInv: TXcomInventory;
    FCurrentTooltip: string;
    FWeightColor: Byte;
    FOverweightColor: Byte;
    FGridColor: Byte;
    function SortedInventories: TArray<TXcomRuleInventory>;
    function ReadStyle: TXcomInventoryStyle;
    function Translate(AId: string): string;
    procedure AddButton(AButton: TXcomBattlescapeButton; const AId: string);
    procedure SetupButton(AButton: TXcomBattlescapeButton; const AHandler: TXcomActionHandler;
      const ATooltip: string);
    procedure DrawSoldier(const AUnit: TXcomBattleUnit);
    procedure PlayInventorySound(ASound: TXcomInventorySound);
    procedure PrimeGrenade(AItem: TXcomBattleItem);
    procedure CloseFromInventory;
    procedure Leave;
    procedure SaveEquipmentLayout;
    /// <summary>_updateTemplateButtons: the pictures of the two buttons (empty or active template), or nothing</summary>
    procedure UpdateTemplateButtons(AVisible: Boolean);
    /// <summary>_clearInventory: everything but the fixed weapons goes to the ground</summary>
    procedure ClearInventory(const AUnit: TXcomBattleUnit; const AGroundTile: TXcomTile);
    /// <summary>Inventory::overlapItems</summary>
    function OverlapItems(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem;
      const ASlot: TXcomRuleInventory; AX, AY: Integer): Boolean;
    procedure RefreshAfterChange;
    // handlers
    procedure BtnOkClick(AAction: TXcomAction);
    procedure BtnPrevClick(AAction: TXcomAction);
    procedure BtnNextClick(AAction: TXcomAction);
    procedure BtnUnloadClick(AAction: TXcomAction);
    procedure BtnGroundClick(AAction: TXcomAction);
    procedure BtnRankClick(AAction: TXcomAction);
    procedure BtnCreateTemplateClick(AAction: TXcomAction);
    procedure BtnApplyTemplateClick(AAction: TXcomAction);
    procedure ClearInventoryPress(AAction: TXcomAction);
    procedure AutoEquipPress(AAction: TXcomAction);
    procedure InvClick(AAction: TXcomAction);
    procedure InvMouseOver(AAction: TXcomAction);
    procedure InvMouseOut(AAction: TXcomAction);
    procedure TxtTooltipIn(AAction: TXcomAction);
    procedure TxtTooltipOut(AAction: TXcomAction);
  public
    /// <param name="AParent">The battlescape that opens the screen: its session, its screens and its sounds are used</param>
    /// <param name="ATimeUnits">Does the inventory use up time units?</param>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState; ATimeUnits: Boolean);
    destructor Destroy; override;
    /// <summary>init: the soldier selected in the battle is shown (the first with an inventory); none closes the screen</summary>
    procedure Init; override;
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>updateStats: time units, weight and statistics of the selected soldier</summary>
    procedure UpdateStats;
    /// <summary>The view of the inventory (for the tests)</summary>
    property Inventory: TXcomInventory read FInv;
    /// <summary>The button that copies the equipment of the soldier into the template</summary>
    property CreateTemplateButton: TXcomBattlescapeButton read FBtnCreateTemplate;
    /// <summary>The button that applies the template (or, with no template, clears the inventory)</summary>
    property ApplyTemplateButton: TXcomBattlescapeButton read FBtnApplyTemplate;
    /// <summary>How many items the current template has</summary>
    function TemplateCount: Integer;
    /// <summary>The text under the soldier: the item under the mouse or a tooltip (for the tests)</summary>
    function ItemText: string;
    /// <summary>The text of the ammunition of the item under the mouse (for the tests)</summary>
    function AmmoText: string;
    /// <summary>The text of the time units (for the tests)</summary>
    function TimeUnitsText: string;
    /// <summary>The name shown (for the tests)</summary>
    function NameText: string;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.XcomSurface.SurfaceSet,
  DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.ItemEquipper;

const
  HAND_PIXELS_W = INV_HAND_WIDTH * INV_SLOT_WIDTH;
  HAND_PIXELS_H = INV_HAND_HEIGHT * INV_SLOT_HEIGHT;
  // SDL_BUTTON_X1 and SDL_BUTTON_X2: the side buttons of the mouse
  BUTTON_X1 = 6;
  BUTTON_X2 = 7;
  RANK_SPRITE = 20;
  AMMO_BACKGROUND = 15;
  LOOK_SUFFIX: array[0..3] of string = ('0', '1', '2', '3');
  TEMPLATE_BUTTON_X = 288;
  CREATE_TEMPLATE_BUTTON_Y = 90;
  APPLY_TEMPLATE_BUTTON_Y = 113;
  GROUND_SECTION = 'STR_GROUND';
  NO_AMMO = 'NONE';

constructor TXcomInventoryState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState; ATimeUnits: Boolean);
var
  LBackground: TXcomSurface;
  LMoreStats: Boolean;
begin
  inherited Create(AHost);
  FParent := AParent;
  FSession := AParent.Session;
  FBattle := FSession.Battle;
  FTimeUnits := ATimeUnits;
  FBg := TXcomWidget.Create(320, 200, 0, 0);
  FSoldier := TXcomWidget.Create(320, 200, 0, 0);
  FTxtName := TXcomText.Create(210, 17, 28, 6);
  FTxtTus := TXcomText.Create(40, 9, 245, 24);
  FTxtWeight := TXcomText.Create(70, 9, 245, 24);
  FTxtFAcc := TXcomText.Create(50, 9, 245, 32);
  FTxtReact := TXcomText.Create(50, 9, 245, 40);
  FTxtPSkill := TXcomText.Create(50, 9, 245, 48);
  FTxtPStr := TXcomText.Create(50, 9, 245, 56);
  FTxtItem := TXcomText.Create(160, 9, 128, 140);
  FTxtAmmo := TXcomText.Create(66, 24, 254, 64);
  FBtnOk := TXcomBattlescapeButton.Create(35, 22, 237, 1);
  FBtnPrev := TXcomBattlescapeButton.Create(23, 22, 273, 1);
  FBtnNext := TXcomBattlescapeButton.Create(23, 22, 297, 1);
  FBtnUnload := TXcomBattlescapeButton.Create(32, 25, 288, 32);
  FBtnGround := TXcomBattlescapeButton.Create(32, 15, 289, 137);
  FBtnRank := TXcomBattlescapeButton.Create(26, 23, 0, 0);
  FBtnCreateTemplate := TXcomBattlescapeButton.Create(32, 22, TEMPLATE_BUTTON_X, CREATE_TEMPLATE_BUTTON_Y);
  FBtnApplyTemplate := TXcomBattlescapeButton.Create(32, 22, TEMPLATE_BUTTON_X, APPLY_TEMPLATE_BUTTON_Y);
  FTemplate := TObjectList<TXcomEquipmentLayoutItem>.Create(True);
  FSelAmmo := TXcomWidget.Create(HAND_PIXELS_W, HAND_PIXELS_H, 272, 88);
  FInv := TXcomInventory.Create(Host.Clock, SortedInventories, FSession.Graphics, Translate, ReadStyle, 320, 200, 0,
    0, False);
  // the cursor color of the battlescape, then the colors of the surface (the depth 0: the inventory is never tinted)
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(FSession.Graphics.Palette(0), 0, 256);
  FSession.Graphics.SetPalette(@Palette^[0]);
  Add(FBg);
  LBackground := FSession.Graphics.Surface('TAC01.SCR');
  if Assigned(LBackground) then
  begin
    LBackground.X := 0;
    LBackground.Y := 0;
    LBackground.Blit(FBg);
  end;
  Add(FSoldier);
  Add(FTxtName, 'textName', 'inventory', FBg);
  Add(FTxtTus, 'textTUs', 'inventory', FBg);
  Add(FTxtWeight, 'textWeight', 'inventory', FBg);
  Add(FTxtFAcc, 'textFiring', 'inventory', FBg);
  Add(FTxtReact, 'textReaction', 'inventory', FBg);
  Add(FTxtPSkill, 'textPsiSkill', 'inventory', FBg);
  Add(FTxtPStr, 'textPsiStrength', 'inventory', FBg);
  Add(FTxtItem, 'textItem', 'inventory', FBg);
  Add(FTxtAmmo, 'textAmmo', 'inventory', FBg);
  AddButton(FBtnOk, 'buttonOK');
  AddButton(FBtnPrev, 'buttonPrev');
  AddButton(FBtnNext, 'buttonNext');
  AddButton(FBtnUnload, 'buttonUnload');
  AddButton(FBtnGround, 'buttonGround');
  AddButton(FBtnRank, 'rank');
  AddButton(FBtnCreateTemplate, 'buttonCreate');
  AddButton(FBtnApplyTemplate, 'buttonApply');
  Add(FSelAmmo);
  Add(FInv);
  LMoreStats := Host.Options.GetBool('showMoreStatsInInventoryView');
  // move the TU display down to make room for the weight display
  if LMoreStats then
    FTxtTus.Y := FTxtTus.Y + 8;
  CenterAllSurfaces;
  FTxtName.SetBig;
  FTxtName.SetHighContrast(True);
  FTxtTus.SetHighContrast(True);
  FTxtWeight.SetHighContrast(True);
  FTxtFAcc.SetHighContrast(True);
  FTxtReact.SetHighContrast(True);
  FTxtPSkill.SetHighContrast(True);
  FTxtPStr.SetHighContrast(True);
  FTxtItem.SetHighContrast(True);
  FTxtAmmo.SetAlign(haCenter);
  FTxtAmmo.SetHighContrast(True);
  SetupButton(FBtnOk, BtnOkClick, 'STR_OK');
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.GetValue('keyCancel'));
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.GetValue('keyBattleInventory'));
  SetupButton(FBtnPrev, BtnPrevClick, 'STR_PREVIOUS_UNIT');
  FBtnPrev.OnKeyboardPress(BtnPrevClick, Host.Options.GetValue('keyBattlePrevUnit'));
  SetupButton(FBtnNext, BtnNextClick, 'STR_NEXT_UNIT');
  FBtnNext.OnKeyboardPress(BtnNextClick, Host.Options.GetValue('keyBattleNextUnit'));
  SetupButton(FBtnUnload, BtnUnloadClick, 'STR_UNLOAD_WEAPON');
  SetupButton(FBtnGround, BtnGroundClick, 'STR_SCROLL_RIGHT');
  SetupButton(FBtnRank, BtnRankClick, 'STR_UNIT_STATS');
  SetupButton(FBtnCreateTemplate, BtnCreateTemplateClick, 'STR_CREATE_INVENTORY_TEMPLATE');
  FBtnCreateTemplate.OnKeyboardPress(BtnCreateTemplateClick, Host.Options.GetValue('keyInvCreateTemplate'));
  SetupButton(FBtnApplyTemplate, BtnApplyTemplateClick, 'STR_APPLY_INVENTORY_TEMPLATE');
  FBtnApplyTemplate.OnKeyboardPress(BtnApplyTemplateClick, Host.Options.GetValue('keyInvApplyTemplate'));
  FBtnApplyTemplate.OnKeyboardPress(ClearInventoryPress, Host.Options.GetValue('keyInvClear'));
  FBtnApplyTemplate.OnKeyboardPress(AutoEquipPress, Host.Options.GetValue('keyInvAutoEquip'));
  // only use copy/paste buttons in setup (i.e. non-tu) mode
  if FTimeUnits then
  begin
    FBtnCreateTemplate.Visible := False;
    FBtnApplyTemplate.Visible := False;
  end
  else
    UpdateTemplateButtons(True);
  FInv.OnSound := PlayInventorySound;
  FInv.OnClose := CloseFromInventory;
  FInv.OnPrimeGrenade := PrimeGrenade;
  FInv.Draw;
  FInv.SetTuMode(FTimeUnits);
  FInv.SetSelectedUnit(FBattle.SelectedUnit);
  FInv.OnMouseClick(InvClick, 0);
  FInv.OnMouseOver(InvMouseOver);
  FInv.OnMouseOut(InvMouseOut);
  FTxtTus.Visible := FTimeUnits;
  FTxtWeight.Visible := LMoreStats;
  FTxtFAcc.Visible := LMoreStats and (not FTimeUnits);
  FTxtReact.Visible := LMoreStats and (not FTimeUnits);
  FTxtPSkill.Visible := LMoreStats and (not FTimeUnits);
  FTxtPStr.Visible := LMoreStats and (not FTimeUnits);
end;

destructor TXcomInventoryState.Destroy;
begin
  inherited Destroy;
  FTemplate.Free;
end;

function TXcomInventoryState.TemplateCount: Integer;
begin
  Result := FTemplate.Count;
end;

procedure TXcomInventoryState.UpdateTemplateButtons(AVisible: Boolean);

  procedure Paint(AButton: TXcomBattlescapeButton; const AName: string);
  var
    LPicture: TXcomSurface;
  begin
    LPicture := FSession.Graphics.Surface(AName);
    if Assigned(LPicture) then
      LPicture.Blit(AButton);
    AButton.InitSurfaces;
  end;

begin
  if not AVisible then
  begin
    FBtnCreateTemplate.Clear;
    FBtnApplyTemplate.Clear;
    Exit;
  end;
  if FTemplate.Count = 0 then
  begin
    // use "empty template" icons
    Paint(FBtnCreateTemplate, 'InvCopy');
    Paint(FBtnApplyTemplate, 'InvPasteEmpty');
    FBtnApplyTemplate.Tooltip := 'STR_CLEAR_INVENTORY';
  end
  else
  begin
    // use "active template" icons
    Paint(FBtnCreateTemplate, 'InvCopyActive');
    Paint(FBtnApplyTemplate, 'InvPaste');
    FBtnApplyTemplate.Tooltip := 'STR_APPLY_INVENTORY_TEMPLATE';
  end;
end;

procedure TXcomInventoryState.ClearInventory(const AUnit: TXcomBattleUnit; const AGroundTile: TXcomTile);
var
  LGround: TXcomRuleInventory;
  LIndex: Integer;
  LItem: TXcomBattleItem;
begin
  LGround := FSession.Ruleset.Inventories.Find(GROUND_SECTION);
  LIndex := 0;
  while LIndex < AUnit.Inventory.Count do
  begin
    LItem := AUnit.Inventory[LIndex];
    // don't drop fixed weapons
    if LItem.Rules.FixedWeapon then
    begin
      Inc(LIndex);
      Continue;
    end;
    LItem.SetOwner(nil);
    AGroundTile.AddItem(LItem, LGround);
    AUnit.Inventory.Delete(LIndex);
  end;
end;

function TXcomInventoryState.OverlapItems(const AUnit: TXcomBattleUnit; const AItem: TXcomBattleItem;
  const ASlot: TXcomRuleInventory; AX, AY: Integer): Boolean;
var
  LItem: TXcomBattleItem;
begin
  Result := False;
  if ASlot.InventoryType <> INV_GROUND then
  begin
    for LItem in AUnit.Inventory do
      if (LItem.Slot = ASlot) and LItem.OccupiesSlot(AX, AY, AItem) then
        Exit(True);
  end
  else if Assigned(AUnit.Tile) then
    for LItem in AUnit.Tile.Inventory do
      if LItem.OccupiesSlot(AX, AY, AItem) then
        Exit(True);
end;

procedure TXcomInventoryState.RefreshAfterChange;
begin
  // refresh ui
  FInv.ArrangeGround(False);
  UpdateStats;
  // give audio feedback
  PlayInventorySound(isDrop);
end;

procedure TXcomInventoryState.BtnCreateTemplateClick(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
  LAmmo: string;
begin
  // don't accept clicks when moving items
  if Assigned(FInv.SelectedItem) then
    Exit;
  LUnit := FBattle.SelectedUnit;
  if not Assigned(LUnit) then
    Exit;
  // clear current template
  FTemplate.Clear;
  // copy inventory instead of just keeping a pointer to it. that way create/apply can be used as an undo button
  // for a single unit and will also work as expected if inventory is modified after 'create' is clicked
  for LItem in LUnit.Inventory do
  begin
    // don't copy fixed weapons into the template
    if LItem.Rules.FixedWeapon or (not Assigned(LItem.Slot)) then
      Continue;
    if LItem.NeedsAmmo and Assigned(LItem.AmmoItem) then
      LAmmo := LItem.AmmoItem.Rules.ItemType
    else
      LAmmo := NO_AMMO;
    FTemplate.Add(TXcomEquipmentLayoutItem.Create(LItem.Rules.ItemType, LItem.Slot.Id, LItem.SlotX, LItem.SlotY,
      LAmmo, LItem.FuseTimer));
  end;
  // give audio feedback
  PlayInventorySound(isDrop);
  // the mouse refresh of the C++ shows the new pictures: here they are drawn at once
  UpdateTemplateButtons(True);
end;

procedure TXcomInventoryState.BtnApplyTemplateClick(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
  LGroundTile: TXcomTile;
  LGroundInventory: TList<TXcomBattleItem>;
  LGround: TXcomRuleInventory;
  LTemplateItem: TXcomEquipmentLayoutItem;
  LRule: TXcomRuleItem;
  LSlot: TXcomRuleInventory;
  LGroundItem, LMatchedWeapon, LMatchedAmmo, LLoadedAmmo: TXcomBattleItem;
  LNeedsAmmo, LFound, LRescan, LItemMissing: Boolean;
  LIndex: Integer;
  LGroundItemName: string;
begin
  // don't accept clicks when moving items; it's ok if the template is empty: it will just result in clearing
  // the unit's inventory
  if Assigned(FInv.SelectedItem) then
    Exit;
  LUnit := FBattle.SelectedUnit;
  if (not Assigned(LUnit)) or (not Assigned(LUnit.Tile)) then
    Exit;
  LGroundTile := LUnit.Tile;
  LGroundInventory := LGroundTile.Inventory;
  LGround := FSession.Ruleset.Inventories.Find(GROUND_SECTION);
  ClearInventory(LUnit, LGroundTile);
  // attempt to replicate inventory template by grabbing corresponding items from the ground. if any item is not
  // found on the ground, display warning message, but continue attempting to fulfill the template as best we can
  LItemMissing := False;
  for LTemplateItem in FTemplate do
  begin
    // search for template item in ground inventory
    LRule := FSession.Ruleset.Items.Find(LTemplateItem.ItemType);
    LSlot := FSession.Ruleset.Inventories.Find(LTemplateItem.Slot);
    if (not Assigned(LRule)) or (not Assigned(LSlot)) then
    begin
      LItemMissing := True;
      Continue;
    end;
    LNeedsAmmo := Length(LRule.CompatibleAmmo) > 0;
    LFound := False;
    LRescan := True;
    while LRescan do
    begin
      LRescan := False;
      LMatchedWeapon := nil;
      LMatchedAmmo := nil;
      LIndex := 0;
      while LIndex < LGroundInventory.Count do
      begin
        LGroundItem := LGroundInventory[LIndex];
        Inc(LIndex);
        // if we find the appropriate ammo, remember it for later for if we find the right weapon but with the
        // wrong ammo
        LGroundItemName := LGroundItem.Rules.ItemType;
        if LNeedsAmmo and (LTemplateItem.AmmoItem = LGroundItemName) then
          LMatchedAmmo := LGroundItem;
        if LTemplateItem.ItemType <> LGroundItemName then
          Continue;
        // if the template item would overlap with an existing item (i.e. a fixed weapon that didn't get cleared
        // in ClearInventory above), skip it; don't display 'item not found' warning message
        if OverlapItems(LUnit, LGroundItem, LSlot, LTemplateItem.SlotX, LTemplateItem.SlotY) then
        begin
          LFound := True;
          Break;
        end;
        // if the loaded ammo doesn't match the template item's, remember the weapon for later and continue
        // scanning
        LLoadedAmmo := LGroundItem.AmmoItem;
        if (LNeedsAmmo and Assigned(LLoadedAmmo) and (LTemplateItem.AmmoItem <> LLoadedAmmo.Rules.ItemType)) or
          (LNeedsAmmo and (not Assigned(LLoadedAmmo))) then
        begin
          // remember the last matched weapon for simplicity (but prefer empty weapons if any are found)
          if (not Assigned(LMatchedWeapon)) or Assigned(LMatchedWeapon.AmmoItem) then
            LMatchedWeapon := LGroundItem;
          Continue;
        end;
        // move matched item from ground to the appropriate inv slot
        LGroundItem.SetOwner(LUnit);
        LGroundItem.Tile := nil;
        LGroundItem.Slot := LSlot;
        LGroundItem.SlotX := LTemplateItem.SlotX;
        LGroundItem.SlotY := LTemplateItem.SlotY;
        LGroundItem.FuseTimer := LTemplateItem.FuseTimer;
        LUnit.Inventory.Add(LGroundItem);
        LGroundInventory.Remove(LGroundItem);
        LFound := True;
        Break;
      end;
      // if we failed to find an exact match, but found unloaded ammo and the right weapon, unload the target
      // weapon, load the right ammo, and use it
      if (not LFound) and Assigned(LMatchedWeapon) and ((not LNeedsAmmo) or Assigned(LMatchedAmmo)) then
      begin
        // unload the existing ammo (if any) from the weapon
        LLoadedAmmo := LMatchedWeapon.AmmoItem;
        if Assigned(LLoadedAmmo) then
        begin
          LGroundTile.AddItem(LLoadedAmmo, LGround);
          LMatchedWeapon.SetAmmoItem(nil);
        end;
        // load the correct ammo into the weapon
        if Assigned(LMatchedAmmo) then
        begin
          LMatchedWeapon.SetAmmoItem(LMatchedAmmo);
          LGroundTile.RemoveItem(LMatchedAmmo);
        end;
        // rescan and pick up the newly-loaded/unloaded weapon
        LRescan := True;
      end;
    end;
    if not LFound then
      LItemMissing := True;
  end;
  if LItemMissing then
    FInv.ShowWarning(Tr('STR_NOT_ENOUGH_ITEMS_FOR_TEMPLATE').Text);
  RefreshAfterChange;
end;

procedure TXcomInventoryState.ClearInventoryPress(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
begin
  // don't act when moving items
  if Assigned(FInv.SelectedItem) then
    Exit;
  LUnit := FBattle.SelectedUnit;
  if (not Assigned(LUnit)) or (not Assigned(LUnit.Tile)) then
    Exit;
  ClearInventory(LUnit, LUnit.Tile);
  RefreshAfterChange;
end;

procedure TXcomInventoryState.AutoEquipPress(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
  LEquipper: TXcomItemEquipper;
begin
  // don't act when moving items
  if Assigned(FInv.SelectedItem) then
    Exit;
  LUnit := FBattle.SelectedUnit;
  if (not Assigned(LUnit)) or (not Assigned(LUnit.Tile)) then
    Exit;
  // BattlescapeGenerator::autoEquip of the items of the ground, nothing is added to the saved battle
  LEquipper := TXcomItemEquipper.Create(FSession.Ruleset, nil, True);
  try
    LEquipper.AutoEquip([LUnit], LUnit.Tile.Inventory, FSession.Ruleset.Inventories.Find(GROUND_SECTION),
      FBattle.GlobalShade, True);
  finally
    LEquipper.Free;
  end;
  RefreshAfterChange;
end;

function TXcomInventoryState.SortedInventories: TArray<TXcomRuleInventory>;
var
  LNames: TArray<string>;
  LIndex: Integer;
begin
  // Mod::getInventories is a std::map: the sections come in the order of their ids
  LNames := FSession.Ruleset.Inventories.Index;
  TArray.Sort<string>(LNames, TComparer<string>.Construct(
    function(const ALeft, ARight: string): Integer
    begin
      Result := CompareStr(ALeft, ARight);
    end));
  SetLength(Result, Length(LNames));
  for LIndex := 0 to High(LNames) do
    Result[LIndex] := FSession.Ruleset.Inventories.Find(LNames[LIndex]);
end;

function TXcomInventoryState.ReadStyle: TXcomInventoryStyle;
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  FillChar(Result, SizeOf(Result), 0);
  LInterface := Host.Resources.GetInterface('inventory');
  if Assigned(LInterface) then
  begin
    if LInterface.TryGetElement('grid', LElement) then
      Result.GridColor := Byte(LElement.Color);
    if LInterface.TryGetElement('textSlots', LElement) then
      Result.SlotTextColor := Byte(LElement.Color);
    if LInterface.TryGetElement('numStack', LElement) then
      Result.StackColor := Byte(LElement.Color);
    if LInterface.TryGetElement('weight', LElement) then
    begin
      FWeightColor := Byte(LElement.Color);
      FOverweightColor := Byte(LElement.Color2);
    end;
  end;
  FGridColor := Result.GridColor;
  LInterface := Host.Resources.GetInterface('battlescape');
  if Assigned(LInterface) and LInterface.TryGetElement('warning', LElement) then
  begin
    Result.WarningColor := Byte(LElement.Color2);
    Result.WarningTextColor := Byte(LElement.Color);
  end;
end;

function TXcomInventoryState.Translate(AId: string): string;
begin
  Result := Tr(AId).Text;
end;

procedure TXcomInventoryState.AddButton(AButton: TXcomBattlescapeButton; const AId: string);
begin
  Add(AButton, AId, 'inventory', FBg);
  // State::add: a battlescape button takes its picture from the background under it
  AButton.Copy(FBg);
  AButton.InitSurfaces;
end;

procedure TXcomInventoryState.SetupButton(AButton: TXcomBattlescapeButton; const AHandler: TXcomActionHandler;
  const ATooltip: string);
begin
  AButton.OnMouseClick(AHandler);
  AButton.Tooltip := ATooltip;
  AButton.OnMouseIn(TxtTooltipIn);
  AButton.OnMouseOut(TxtTooltipOut);
end;

procedure TXcomInventoryState.PlayInventorySound(ASound: TXcomInventorySound);
begin
  // a sound without a place: it is not panned
  if ASound = isReload then
    FParent.PlaySound(FSession.Ruleset.Constants.ItemReload, TXcomPosition.Make(-1, -1, -1))
  else
    FParent.PlaySound(FSession.Ruleset.Constants.ItemDrop, TXcomPosition.Make(-1, -1, -1));
end;

procedure TXcomInventoryState.PrimeGrenade(AItem: TXcomBattleItem);
var
  LState: TXcomState;
begin
  if not Assigned(FParent.Screens) then
    Exit;
  LState := FParent.Screens.PrimeGrenade(FParent, nil, True, AItem);
  if Assigned(LState) then
    Host.PushState(LState);
end;

procedure TXcomInventoryState.Leave;
var
  LUnit: TXcomBattleUnit;
begin
  // what the destructor of the C++ does: here the state is freed later, when the battle may be gone
  if FLeft then
    Exit;
  FLeft := True;
  LUnit := FBattle.SelectedUnit;
  if Assigned(LUnit) and Assigned(LUnit.Tile) then
    FSession.TileEngine.ApplyGravity(LUnit.Tile);
  // dropping or picking up flares
  FSession.TileEngine.CalculateTerrainLighting;
  FSession.TileEngine.RecalculateFov;
end;

procedure TXcomInventoryState.CloseFromInventory;
begin
  Host.PopState;
  Leave;
end;

procedure TXcomInventoryState.DrawSoldier(const AUnit: TXcomBattleUnit);
var
  LSoldier: TXcomSoldier;
  LSet: TXcomSurfaceSet;
  LFrame, LPicture: TXcomSurface;
  LBase, LLook: string;
begin
  FSoldier.Clear;
  FBtnRank.Clear;
  LSoldier := AUnit.GeoscapeSoldier;
  LBase := AUnit.Armor.SpriteInventory;
  if Assigned(LSoldier) then
  begin
    LSet := FSession.Graphics.SurfaceSet('SMOKE.PCK');
    if Assigned(LSet) then
    begin
      LFrame := LSet.GetFrame(RANK_SPRITE + LSoldier.Rank);
      if Assigned(LFrame) then
        TXcomSurfaceShader.Blit(LFrame, FBtnRank, FBtnRank.X, FBtnRank.Y, 0);
    end;
    LBase := LSoldier.Armor.SpriteInventory;
    if LSoldier.Gender = TXcomSoldier.GENDER_MALE then
      LLook := LBase + 'M'
    else
      LLook := LBase + 'F';
    if (LSoldier.Look >= Low(LOOK_SUFFIX)) and (LSoldier.Look <= High(LOOK_SUFFIX)) then
      LLook := LLook + LOOK_SUFFIX[LSoldier.Look];
    LPicture := FSession.Graphics.Surface(LLook + '.SPK');
    if not Assigned(LPicture) then
      LPicture := FSession.Graphics.Surface(LBase + '.SPK');
    if not Assigned(LPicture) then
      LPicture := FSession.Graphics.Surface(LBase);
  end
  else
  begin
    LPicture := FSession.Graphics.Surface(LBase);
    if not Assigned(LPicture) then
      LPicture := FSession.Graphics.Surface(LBase + '.SPK');
    if not Assigned(LPicture) then
      LPicture := FSession.Graphics.Surface(LBase + 'M0.SPK');
  end;
  if Assigned(LPicture) then
    TXcomSurfaceShader.Blit(LPicture, FSoldier, FSoldier.X, FSoldier.Y, 0);
end;

procedure TXcomInventoryState.Init;
var
  LUnit: TXcomBattleUnit;
begin
  inherited Init;
  FSession.Graphics.SetPalette(@Palette^[0]);
  LUnit := FBattle.SelectedUnit;
  // no selected unit, close inventory
  if not Assigned(LUnit) then
  begin
    BtnOkClick(nil);
    Exit;
  end;
  // skip to the first unit with inventory
  if not LUnit.HasInventory then
  begin
    FParent.SelectNextPlayerUnit(False, False, True, FTimeUnits);
    LUnit := FBattle.SelectedUnit;
    // no available unit (a mission with just vehicles), close inventory
    if (not Assigned(LUnit)) or (not LUnit.HasInventory) then
    begin
      BtnOkClick(nil);
      Exit;
    end;
  end;
  FTxtName.SetBig;
  FTxtName.SetText(LUnit.DisplayName(
    function(AId: string): string
    begin
      Result := Tr(AId).Text;
    end, False));
  FInv.SetSelectedUnit(LUnit);
  DrawSoldier(LUnit);
  UpdateStats;
end;

procedure TXcomInventoryState.UpdateStats;
var
  LUnit: TXcomBattleUnit;
  LWeight: Integer;
begin
  LUnit := FBattle.SelectedUnit;
  if not Assigned(LUnit) then
    Exit;
  FTxtTus.SetText(Tr('STR_TIME_UNITS_SHORT').Arg(LUnit.TimeUnits).Text);
  LWeight := LUnit.GetCarriedWeight(FInv.SelectedItem);
  FTxtWeight.SetText(Tr('STR_WEIGHT').Arg(LWeight).Arg(LUnit.Stats.Strength).Text);
  if LWeight > LUnit.Stats.Strength then
    FTxtWeight.SetSecondaryColor(FOverweightColor)
  else
    FTxtWeight.SetSecondaryColor(FWeightColor);
  if LUnit.Stats.Health <> 0 then
    FTxtFAcc.SetText(Tr('STR_ACCURACY_SHORT').Arg(LUnit.Stats.Firing * LUnit.Health div LUnit.Stats.Health).Text);
  FTxtReact.SetText(Tr('STR_REACTIONS_SHORT').Arg(LUnit.Stats.Reactions).Text);
  if LUnit.Stats.PsiSkill > 0 then
  begin
    FTxtPSkill.SetText(Tr('STR_PSIONIC_SKILL_SHORT').Arg(LUnit.Stats.PsiSkill).Text);
    FTxtPStr.SetText(Tr('STR_PSIONIC_STRENGTH_SHORT').Arg(LUnit.Stats.PsiStrength).Text);
  end
  else
  begin
    FTxtPSkill.SetText('');
    FTxtPStr.SetText('');
  end;
end;

procedure TXcomInventoryState.SaveEquipmentLayout;
var
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
  LLayout: TObjectList<TXcomEquipmentLayoutItem>;
  LAmmo: string;
begin
  for LUnit in FBattle.Units do
  begin
    // X-Com soldiers only
    if not Assigned(LUnit.GeoscapeSoldier) then
      Continue;
    LLayout := LUnit.GeoscapeSoldier.EquipmentLayout;
    LLayout.Clear;
    // the loaded clips are not in the inventory: they are saved with their weapon
    for LItem in LUnit.Inventory do
    begin
      if not Assigned(LItem.Slot) then
        Continue;
      if LItem.NeedsAmmo and Assigned(LItem.AmmoItem) then
        LAmmo := LItem.AmmoItem.Rules.ItemType
      else
        LAmmo := 'NONE';
      LLayout.Add(TXcomEquipmentLayoutItem.Create(LItem.Rules.ItemType, LItem.Slot.Id, LItem.SlotX, LItem.SlotY,
        LAmmo, LItem.FuseTimer));
    end;
  end;
end;

procedure TXcomInventoryState.BtnOkClick(AAction: TXcomAction);
var
  LSelected, LUnit: TXcomBattleUnit;
  LTile: TXcomTile;
begin
  if Assigned(FInv.SelectedItem) then
    Exit;
  Host.PopState;
  LSelected := FBattle.SelectedUnit;
  if (not FTimeUnits) and Assigned(LSelected) then
  begin
    LTile := LSelected.Tile;
    SaveEquipmentLayout;
    FBattle.ResetUnitTiles;
    if (FBattle.Turn = 1) and Assigned(LTile) then
    begin
      FBattle.RandomizeItemLocations(LTile);
      // make sure we select the unit closest to the ramp
      if Assigned(LTile.CurrentUnit) then
        FBattle.SelectedUnit := LTile.CurrentUnit;
    end;
    // initialize xcom units for battle
    for LUnit in FBattle.Units do
      if (LUnit.OriginalFaction = FACTION_PLAYER) and (not LUnit.IsOut) then
        LUnit.PrepareNewTurn(False);
  end;
  Leave;
end;

procedure TXcomInventoryState.BtnPrevClick(AAction: TXcomAction);
begin
  if Assigned(FInv.SelectedItem) then
    Exit;
  FParent.SelectPreviousPlayerUnit(False, False, True);
  Init;
end;

procedure TXcomInventoryState.BtnNextClick(AAction: TXcomAction);
begin
  if Assigned(FInv.SelectedItem) then
    Exit;
  FParent.SelectNextPlayerUnit(False, False, True);
  Init;
end;

procedure TXcomInventoryState.BtnUnloadClick(AAction: TXcomAction);
begin
  if FInv.Unload then
  begin
    FTxtItem.SetText('');
    FTxtAmmo.SetText('');
    FSelAmmo.Clear;
    UpdateStats;
    PlayInventorySound(isDrop);
  end;
end;

procedure TXcomInventoryState.BtnGroundClick(AAction: TXcomAction);
begin
  FInv.ArrangeGround;
end;

procedure TXcomInventoryState.BtnRankClick(AAction: TXcomAction);
var
  LState: TXcomState;
begin
  if (not Assigned(FParent.Screens)) or (not Assigned(FBattle.SelectedUnit)) then
    Exit;
  LState := FParent.Screens.UnitInfo(FParent, FBattle.SelectedUnit, True, False);
  if Assigned(LState) then
    Host.PushState(LState);
end;

procedure TXcomInventoryState.InvClick(AAction: TXcomAction);
begin
  UpdateStats;
end;

procedure TXcomInventoryState.InvMouseOver(AAction: TXcomAction);
var
  LItem: TXcomBattleItem;
  LText: string;
  LFrame: TXcomSurface;
  LSet: TXcomSurfaceSet;
begin
  if Assigned(FInv.SelectedItem) then
    Exit;
  LItem := FInv.MouseOverItem;
  if not Assigned(LItem) then
  begin
    if FCurrentTooltip = '' then
      FTxtItem.SetText('');
    FTxtAmmo.SetText('');
    FSelAmmo.Clear;
    UpdateTemplateButtons(not FTimeUnits);
    Exit;
  end;
  if Assigned(LItem.CorpseUnit) and (LItem.CorpseUnit.Status = STATUS_UNCONSCIOUS) then
    FTxtItem.SetText(LItem.CorpseUnit.DisplayName(
      function(AId: string): string
      begin
        Result := Tr(AId).Text;
      end, False))
  else if (not Assigned(FSession.SavedGame)) or FSession.SavedGame.IsResearched(LItem.Rules.Requirements) then
    FTxtItem.SetText(Tr(LItem.Rules.Name).Text)
  else
    FTxtItem.SetText(Tr('STR_ALIEN_ARTIFACT').Text);
  LText := '';
  if Assigned(LItem.AmmoItem) and LItem.NeedsAmmo then
  begin
    LText := Tr('STR_AMMO_ROUNDS_LEFT').Arg(LItem.AmmoItem.AmmoQuantity).Text;
    FSelAmmo.DrawRect(0, 0, HAND_PIXELS_W, HAND_PIXELS_H, FGridColor);
    FSelAmmo.DrawRect(1, 1, HAND_PIXELS_W - 2, HAND_PIXELS_H - 2, AMMO_BACKGROUND);
    // RuleItem::drawHandSprite of the clip
    LSet := FSession.Graphics.SurfaceSet('BIGOBS.PCK');
    LFrame := nil;
    if Assigned(LSet) then
      LFrame := LSet.GetFrame(LItem.AmmoItem.Rules.BigSprite);
    if Assigned(LFrame) then
      TXcomSurfaceShader.Blit(LFrame, FSelAmmo,
        FSelAmmo.X + (INV_HAND_WIDTH - LItem.AmmoItem.Rules.InventoryWidth) * INV_SLOT_WIDTH div 2,
        FSelAmmo.Y + (INV_HAND_HEIGHT - LItem.AmmoItem.Rules.InventoryHeight) * INV_SLOT_HEIGHT div 2, 0);
    // the picture of the clip takes the place of the buttons of the template
    UpdateTemplateButtons(False);
  end
  else
  begin
    FSelAmmo.Clear;
    UpdateTemplateButtons(not FTimeUnits);
  end;
  if (LItem.AmmoQuantity <> 0) and LItem.NeedsAmmo then
    LText := Tr('STR_AMMO_ROUNDS_LEFT').Arg(LItem.AmmoQuantity).Text
  else if LItem.Rules.BattleType = TXcomRuleItem.BT_MEDIKIT then
    LText := Tr('STR_MEDI_KIT_QUANTITIES_LEFT').Arg(LItem.PainKillerQuantity).Arg(LItem.StimulantQuantity)
      .Arg(LItem.HealQuantity).Text;
  FTxtAmmo.SetText(LText);
end;

procedure TXcomInventoryState.InvMouseOut(AAction: TXcomAction);
begin
  FTxtItem.SetText('');
  FTxtAmmo.SetText('');
  FSelAmmo.Clear;
  UpdateTemplateButtons(not FTimeUnits);
end;

procedure TXcomInventoryState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if AAction.Details^.Kind = ekMouseDown then
  begin
    if AAction.Details^.Button = BUTTON_X1 then
      BtnNextClick(AAction)
    else if AAction.Details^.Button = BUTTON_X2 then
      BtnPrevClick(AAction);
  end;
end;

procedure TXcomInventoryState.TxtTooltipIn(AAction: TXcomAction);
begin
  if (not Assigned(FInv.SelectedItem)) and Host.Options.GetBool('battleTooltips') and
    (AAction.Sender is TXcomWidget) then
  begin
    FCurrentTooltip := TXcomWidget(AAction.Sender).Tooltip;
    FTxtItem.SetText(Tr(FCurrentTooltip).Text);
  end;
end;

procedure TXcomInventoryState.TxtTooltipOut(AAction: TXcomAction);
begin
  if (not Assigned(FInv.SelectedItem)) and Host.Options.GetBool('battleTooltips') and
    (AAction.Sender is TXcomWidget) and (FCurrentTooltip = TXcomWidget(AAction.Sender).Tooltip) then
  begin
    FCurrentTooltip := '';
    FTxtItem.SetText('');
  end;
end;

function TXcomInventoryState.ItemText: string;
begin
  Result := FTxtItem.GetText;
end;

function TXcomInventoryState.AmmoText: string;
begin
  Result := FTxtAmmo.GetText;
end;

function TXcomInventoryState.TimeUnitsText: string;
begin
  Result := FTxtTus.GetText;
end;

function TXcomInventoryState.NameText: string;
begin
  Result := FTxtName.GetText;
end;

end.
