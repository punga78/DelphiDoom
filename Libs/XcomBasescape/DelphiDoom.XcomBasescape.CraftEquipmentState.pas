{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - CraftEquipmentState of OpenXcom (the   }
{  items and vehicles of a craft)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.CraftEquipmentState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomBasescape.ListArrowTimers;

type
  /// <summary>
  ///   The equipment of a craft: for each item the stores and the craft, with the arrows (the left one moves an
  ///   item to the base, the right one to the craft; the right button moves all, held down they repeat). A fixed
  ///   weapon is a vehicle that takes room and, if it uses ammunition, takes the ammunition from the stores.
  ///   Not ported: the Inventory button (it needs the battlescape: it does nothing)
  /// </summary>
  TXcomCraftEquipmentState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FCraft: TXcomCraft;
    FAmmoColor: Byte;
    FTotalItems: Integer;
    FItems: TList<string>;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnClear: TXcomTextButton;
    FBtnInventory: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtStores: TXcomText;
    FTxtAvailable: TXcomText;
    FTxtUsed: TXcomText;
    FTxtCrew: TXcomText;
    FList: TXcomTextList;
    FArrows: TXcomListArrowTimers;
    function RowColor(const AItem: string; AQuantity: Integer): Byte;
    function InCraft(const AItem: string): Integer;
    procedure UpdateQuantity(ARow: Integer);
    procedure MoveToBase(AChange: Integer);
    procedure MoveToCraft(AChange: Integer);
    procedure ShowError(const AMessage: string);
    procedure OkClick(AAction: TXcomAction);
    procedure ClearClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ACraft">The index of the craft in the base</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraft: Integer);
    destructor Destroy; override;
    procedure Think; override;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomMod.RuleUnit,
  DelphiDoom.XcomMod.Armor, DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Rules.Intf, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomBasescape.Names;

{ TXcomCraftEquipmentState }

constructor TXcomCraftEquipmentState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraft: Integer);
var
  LCrew: Integer;
  LNewBattle, LShowOk: Boolean;
  LElement: TXcomInterfaceElement;
  LInterface: TXcomRuleInterface;
  LRuleset: TXcomRuleset;
  LName, LText, LStores: string;
  LRule: TXcomRuleItem;
  LQuantity, LRow: Integer;
  LSave: TXcomSavedGame;
begin
  inherited Create(AHost);
  FBase := ABase;
  FCraft := FBase.Crafts[ACraft];
  FItems := TList<string>.Create;
  LSave := TXcomStrategy.SavedGame(AHost);
  LRuleset := TXcomStrategy.Ruleset(AHost);
  LCrew := FCraft.NumSoldiers(FBase.Soldiers);
  LNewBattle := LSave.MonthsPassed = -1;
  LShowOk := (LCrew > 0) or LNewBattle;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  if LShowOk then
    FBtnOk := TXcomTextButton.Create(148, 16, 164, 176)
  else
    FBtnOk := TXcomTextButton.Create(288, 16, 16, 176);
  FBtnClear := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnInventory := TXcomTextButton.Create(148, 16, 8, 176);
  FTxtTitle := TXcomText.Create(300, 17, 16, 7);
  FTxtItem := TXcomText.Create(144, 9, 16, 32);
  FTxtStores := TXcomText.Create(150, 9, 160, 32);
  FTxtAvailable := TXcomText.Create(110, 9, 16, 24);
  FTxtUsed := TXcomText.Create(110, 9, 130, 24);
  FTxtCrew := TXcomText.Create(71, 9, 244, 24);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 40);
  SetInterface('craftEquipment');
  LElement := Default(TXcomInterfaceElement);
  LInterface := Host.Resources.GetInterface('craftEquipment');
  if LInterface <> nil then
    LInterface.TryGetElement('ammoColor', LElement);
  FAmmoColor := Byte(LElement.Color);
  Add(FWindow, 'window', 'craftEquipment');
  Add(FBtnOk, 'button', 'craftEquipment');
  Add(FBtnClear, 'button', 'craftEquipment');
  Add(FBtnInventory, 'button', 'craftEquipment');
  Add(FTxtTitle, 'text', 'craftEquipment');
  Add(FTxtItem, 'text', 'craftEquipment');
  Add(FTxtStores, 'text', 'craftEquipment');
  Add(FTxtAvailable, 'text', 'craftEquipment');
  Add(FTxtUsed, 'text', 'craftEquipment');
  Add(FTxtCrew, 'text', 'craftEquipment');
  Add(FList, 'list', 'craftEquipment');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK04.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnClear.SetText(Tr('STR_UNLOAD_CRAFT'));
  FBtnClear.OnMouseClick(ClearClick);
  FBtnClear.Visible := LNewBattle;
  FBtnInventory.SetText(Tr('STR_INVENTORY'));
  FBtnInventory.Visible := (LCrew > 0) and not LNewBattle;
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_EQUIPMENT_FOR_CRAFT').Arg(TXcomBaseNames.CraftName(FCraft, Host.Language)));
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtStores.SetText(Tr('STR_STORES'));
  FTxtAvailable.SetText(Tr('STR_SPACE_AVAILABLE').Arg(FCraft.SpaceAvailable(FBase.Soldiers)));
  FTxtUsed.SetText(Tr('STR_SPACE_USED').Arg(FCraft.SpaceUsed(FBase.Soldiers)));
  FTxtCrew.SetText(Tr('STR_SOLDIERS_UC').Text + '>' + Char(XCOM_TOKEN_COLOR_FLIP) + IntToStr(LCrew));
  FList.SetArrowColumn(203, aoHorizontal);
  FList.SetColumns([156, 83, 41]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  // the left arrow moves to the base (Increase of the arrows), the right one to the craft; the wheel is reversed
  FArrows := TXcomListArrowTimers.Create(Host.Clock, Host.Options, FList,
    procedure(AChange: Integer)
    begin
      MoveToBase(AChange);
    end,
    procedure(AChange: Integer)
    begin
      MoveToCraft(AChange);
    end, True);
  LRow := 0;
  for LName in LRuleset.Items.Index do
  begin
    LRule := LRuleset.Items.Find(LName);
    if LRule.FixedWeapon then
      LQuantity := FCraft.VehicleCount(LName)
    else
    begin
      LQuantity := FCraft.Items.GetItem(LName);
      Inc(FTotalItems, LQuantity);
    end;
    if (LRule.BigSprite > -1) and (LRule.BattleType <> TXcomRuleItem.BT_NONE) and
      (LRule.BattleType <> TXcomRuleItem.BT_CORPSE) and LSave.IsResearched(LRule.Requirements) and
      ((FBase.StorageItems.GetItem(LName) > 0) or (LQuantity > 0)) then
    begin
      FItems.Add(LName);
      if LSave.MonthsPassed > -1 then
        LStores := IntToStr(FBase.StorageItems.GetItem(LName))
      else
        LStores := '-';
      LText := Tr(LName).Text;
      if LRule.BattleType = TXcomRuleItem.BT_AMMO then
        LText := '  ' + LText;
      FList.AddRow([LText, LStores, IntToStr(LQuantity)]);
      FList.SetRowColor(LRow, RowColor(LName, LQuantity));
      Inc(LRow);
    end;
  end;
end;

destructor TXcomCraftEquipmentState.Destroy;
begin
  // the arrows hold the list: they go first
  FArrows.Free;
  inherited Destroy;
  FItems.Free;
end;

function TXcomCraftEquipmentState.RowColor(const AItem: string; AQuantity: Integer): Byte;
begin
  if AQuantity = 0 then
  begin
    if TXcomStrategy.Ruleset(Host).Items.Find(AItem).BattleType = TXcomRuleItem.BT_AMMO then
      Result := FAmmoColor
    else
      Result := FList.GetColor;
  end
  else
    Result := FList.GetSecondaryColor;
end;

function TXcomCraftEquipmentState.InCraft(const AItem: string): Integer;
begin
  if TXcomStrategy.Ruleset(Host).Items.Find(AItem).FixedWeapon then
    Result := FCraft.VehicleCount(AItem)
  else
    Result := FCraft.Items.GetItem(AItem);
end;

procedure TXcomCraftEquipmentState.Think;
begin
  inherited Think;
  FArrows.Think;
end;

procedure TXcomCraftEquipmentState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftEquipmentState.UpdateQuantity(ARow: Integer);
var
  LItem, LStores: string;
  LQuantity: Integer;
begin
  LItem := FItems[ARow];
  LQuantity := InCraft(LItem);
  if TXcomStrategy.SavedGame(Host).MonthsPassed > -1 then
    LStores := IntToStr(FBase.StorageItems.GetItem(LItem))
  else
    LStores := '-';
  FList.SetRowColor(ARow, RowColor(LItem, LQuantity));
  FList.SetCellText(ARow, 1, LStores);
  FList.SetCellText(ARow, 2, IntToStr(LQuantity));
  FTxtAvailable.SetText(Tr('STR_SPACE_AVAILABLE').Arg(FCraft.SpaceAvailable(FBase.Soldiers)));
  FTxtUsed.SetText(Tr('STR_SPACE_USED').Arg(FCraft.SpaceUsed(FBase.Soldiers)));
end;

procedure TXcomCraftEquipmentState.ShowError(const AMessage: string);
var
  LMessage, LPalette: TXcomInterfaceElement;
  LInterface: TXcomRuleInterface;
begin
  LMessage := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  LPalette.Color := -1;
  LInterface := Host.Resources.GetInterface('craftEquipment');
  if LInterface <> nil then
  begin
    LInterface.TryGetElement('errorMessage', LMessage);
    LInterface.TryGetElement('errorPalette', LPalette);
  end;
  Host.PushState(TXcomErrorMessageState.Create(Host, AMessage, Palette, Byte(LMessage.Color), 'BACK04.SCR',
    LPalette.Color));
end;

procedure TXcomCraftEquipmentState.MoveToBase(AChange: Integer);
var
  LSelected, LIndex, LQuantity, LAmmoPerVehicle: Integer;
  LItem: string;
  LRule, LAmmo: TXcomRuleItem;
  LRuleset: TXcomRuleset;
  LStored: Boolean;
begin
  LSelected := FArrows.Selected;
  LItem := FItems[LSelected];
  LRuleset := TXcomStrategy.Ruleset(Host);
  LRule := LRuleset.Items.Find(LItem);
  LQuantity := InCraft(LItem);
  if (AChange <= 0) or (LQuantity <= 0) then
    Exit;
  AChange := Min(LQuantity, AChange);
  LStored := TXcomStrategy.SavedGame(Host).MonthsPassed <> -1;
  if LRule.FixedWeapon then
  begin
    // convert the vehicles back to items
    if Length(LRule.CompatibleAmmo) > 0 then
    begin
      LAmmo := LRuleset.Items.Find(LRule.CompatibleAmmo[0]);
      if (LAmmo.ClipSize > 0) and (LRule.ClipSize > 0) then
        LAmmoPerVehicle := LRule.ClipSize div LAmmo.ClipSize
      else
        LAmmoPerVehicle := LAmmo.ClipSize;
      if LStored then
      begin
        FBase.StorageItems.AddItem(LItem, AChange);
        FBase.StorageItems.AddItem(LAmmo.ItemType, LAmmoPerVehicle * AChange);
      end;
    end
    else if LStored then
      FBase.StorageItems.AddItem(LItem, AChange);
    LIndex := 0;
    while (LIndex < FCraft.Vehicles.Count) and (AChange > 0) do
      if FCraft.Vehicles[LIndex].Rules.ItemType = LItem then
      begin
        FCraft.Vehicles.Delete(LIndex);
        Dec(AChange);
      end
      else
        Inc(LIndex);
  end
  else
  begin
    FCraft.Items.RemoveItem(LItem, AChange);
    Dec(FTotalItems, AChange);
    if TXcomStrategy.SavedGame(Host).MonthsPassed > -1 then
      FBase.StorageItems.AddItem(LItem, AChange);
  end;
  UpdateQuantity(LSelected);
end;

procedure TXcomCraftEquipmentState.MoveToCraft(AChange: Integer);
var
  LSelected, LBaseQuantity, LSize, LRoom, LAmmoPerVehicle, LClipSize, LAddable, LIndex: Integer;
  LItem: string;
  LRule, LAmmo: TXcomRuleItem;
  LRuleset: TXcomRuleset;
  LUnit: TXcomRuleUnit;
  LArmor: TXcomArmor;
  LNewBattle: Boolean;
  LRules: TXcomRulesetRules;
  LItemRule: IXcomItemRule;
begin
  LSelected := FArrows.Selected;
  LItem := FItems[LSelected];
  LRuleset := TXcomStrategy.Ruleset(Host);
  LRule := LRuleset.Items.Find(LItem);
  LNewBattle := TXcomStrategy.SavedGame(Host).MonthsPassed = -1;
  LBaseQuantity := FBase.StorageItems.GetItem(LItem);
  if LNewBattle then
  begin
    if AChange = MaxInt then
      AChange := 10;
    LBaseQuantity := AChange;
  end;
  if (AChange <= 0) or (LBaseQuantity <= 0) then
    Exit;
  AChange := Min(LBaseQuantity, AChange);
  if LRule.FixedWeapon then
  begin
    // an item that becomes a vehicle
    LSize := 4;
    LUnit := LRuleset.Units.Find(LRule.ItemType);
    if Assigned(LUnit) then
    begin
      LArmor := LRuleset.Armors.Find(LUnit.Armor);
      if Assigned(LArmor) then
        LSize := LArmor.Size * LArmor.Size;
    end;
    LRoom := Min(FCraft.Rules.Vehicles - FCraft.NumVehicles, FCraft.SpaceAvailable(FBase.Soldiers) div LSize);
    if LRoom <= 0 then
    begin
      UpdateQuantity(LSelected);
      Exit;
    end;
    AChange := Min(LRoom, AChange);
    LRules := TXcomRulesetRules.Create(LRuleset);
    try
      LItemRule := LRules.Item(LItem);
    finally
      LRules.Free;
    end;
    if Length(LRule.CompatibleAmmo) > 0 then
    begin
      LAmmo := LRuleset.Items.Find(LRule.CompatibleAmmo[0]);
      if (LAmmo.ClipSize > 0) and (LRule.ClipSize > 0) then
      begin
        LClipSize := LRule.ClipSize;
        LAmmoPerVehicle := LClipSize div LAmmo.ClipSize;
      end
      else
      begin
        LClipSize := LAmmo.ClipSize;
        LAmmoPerVehicle := LClipSize;
      end;
      LBaseQuantity := FBase.StorageItems.GetItem(LAmmo.ItemType) div LAmmoPerVehicle;
      if LNewBattle then
        LBaseQuantity := AChange;
      LAddable := Min(AChange, LBaseQuantity);
      if LAddable > 0 then
        for LIndex := 1 to LAddable do
        begin
          if not LNewBattle then
          begin
            FBase.StorageItems.RemoveItem(LAmmo.ItemType, LAmmoPerVehicle);
            FBase.StorageItems.RemoveItem(LItem);
          end;
          FCraft.Vehicles.Add(TXcomVehicle.Create(LItemRule, LClipSize, LSize));
        end
      else
      begin
        // the count of vehicles could not grow because of the ammunition
        FArrows.StopDecrease;
        ShowError(Tr('STR_NOT_ENOUGH_AMMO_TO_ARM_HWP').Arg(LAmmoPerVehicle).Arg(Tr(LAmmo.ItemType).Text).Text);
      end;
    end
    else
      for LIndex := 1 to AChange do
      begin
        FCraft.Vehicles.Add(TXcomVehicle.Create(LItemRule, LRule.ClipSize, LSize));
        if not LNewBattle then
          FBase.StorageItems.RemoveItem(LItem);
      end;
  end
  else
  begin
    if (FCraft.Rules.MaxItems > 0) and (FTotalItems + AChange > FCraft.Rules.MaxItems) then
    begin
      FArrows.StopDecrease;
      ShowError(Tr('STR_NO_MORE_EQUIPMENT_ALLOWED', FCraft.Rules.MaxItems).Text);
      AChange := FCraft.Rules.MaxItems - FTotalItems;
    end;
    FCraft.Items.AddItem(LItem, AChange);
    Inc(FTotalItems, AChange);
    if TXcomStrategy.SavedGame(Host).MonthsPassed > -1 then
      FBase.StorageItems.RemoveItem(LItem, AChange);
  end;
  UpdateQuantity(LSelected);
end;

procedure TXcomCraftEquipmentState.ClearClick(AAction: TXcomAction);
var
  LIndex: Integer;
begin
  // the selected row of the arrows is what MoveToBase uses: the C++ sets _sel
  for LIndex := 0 to FItems.Count - 1 do
  begin
    FArrows.SelectRow(LIndex);
    MoveToBase(MaxInt);
  end;
end;

end.
