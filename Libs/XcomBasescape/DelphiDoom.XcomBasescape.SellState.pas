{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SellState of OpenXcom (sell items and   }
{  sack personnel)                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SellState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ComboBox,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomBasescape.TransferRow, DelphiDoom.XcomBasescape.ListArrowTimers;

type
  /// <summary>
  ///   Sells the items and the crafts of a base and sacks its personnel: a row per soldier without a craft, craft not
  ///   out, scientist and engineer available, and item in the stores, with a category filter. The space that the
  ///   sale frees (armors, weapons of the crafts, items) is shown, and with the storage limits enforced the OK
  ///   button is there only when the stores would not be overfull
  /// </summary>
  TXcomSellState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FRuleset: TXcomRuleset;
    FCapacity: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtSales: TXcomText;
    FTxtFunds: TXcomText;
    FTxtSpaceUsed: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtSell: TXcomText;
    FTxtValue: TXcomText;
    FCbxCategory: TXcomComboBox;
    FLstItems: TXcomTextList;
    FItems: TList<TXcomTransferRow>;
    FRows: TList<Integer>;
    FCategories: TList<string>;
    FCraftWeapons: TDictionary<string, Boolean>;
    FArmors: TDictionary<string, Boolean>;
    FTotal: Int64;
    FSpaceChange: Double;
    FAmmoColor: Byte;
    FArrows: TXcomListArrowTimers;
    procedure AddRowOf(const ARow: TXcomTransferRow);
    function CategoryOf(const ARow: TXcomTransferRow): string;
    function IsAmmo(const ARow: TXcomTransferRow): Boolean;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure CategoryChange(AAction: TXcomAction);
    procedure Increase(AChange: Integer);
    procedure Decrease(AChange: Integer);
    procedure ChangeByValue(AChange, ADirection: Integer);
    procedure UpdateItemStrings;
    procedure SellItem(const ARow: TXcomTransferRow);
    function CraftWeaponsSpace(ACraft: TObject): Double;
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ABattlescapeOrigin">Opened from the debriefing (OPT_BATTLESCAPE): the items of the crafts and of the transfers count too</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ABattlescapeOrigin: Boolean = False);
    destructor Destroy; override;
    procedure Think; override;
    procedure UpdateList;
    property Total: Int64 read FTotal;
    property List: TXcomTextList read FLstItems;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Transfer,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomStrategy.BaseCrafts, DelphiDoom.XcomGeoscape.Funding,
  DelphiDoom.XcomBasescape.SpaceText, DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomMod.Armor;

{ TXcomSellState }

constructor TXcomSellState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ABattlescapeOrigin: Boolean);
var
  LIndex, LQty: Integer;
  LRow: TXcomTransferRow;
  LSoldier: TXcomSoldier;
  LCraft: TXcomCraft;
  LItem: TXcomRuleItem;
  LName: string;
  LWeapon: TXcomRuleCraftWeapon;
  LArmor: TXcomArmor;
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
  LEnforced, LOverfull: Boolean;
  LTransfer: TXcomTransfer;
begin
  inherited Create(AHost);
  FBase := ABase;
  FRuleset := TXcomStrategy.Ruleset(AHost);
  FCapacity := TXcomBaseCapacity.Create(FRuleset);
  FItems := TList<TXcomTransferRow>.Create;
  FRows := TList<Integer>.Create;
  FCategories := TList<string>.Create;
  FCraftWeapons := TDictionary<string, Boolean>.Create;
  FArmors := TDictionary<string, Boolean>.Create;
  LEnforced := Host.Options.GetBool('storageLimitsEnforced');
  LOverfull := LEnforced and FCapacity.StoresOverfull(FBase, 0);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  if LOverfull then
    FBtnOk := TXcomTextButton.Create(288, 16, 16, 176)
  else
    FBtnOk := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtSales := TXcomText.Create(150, 9, 10, 24);
  FTxtFunds := TXcomText.Create(150, 9, 160, 24);
  FTxtSpaceUsed := TXcomText.Create(150, 9, 160, 34);
  FTxtQuantity := TXcomText.Create(54, 9, 136, 44);
  FTxtSell := TXcomText.Create(96, 9, 190, 44);
  FTxtValue := TXcomText.Create(40, 9, 270, 44);
  FCbxCategory := TXcomComboBox.Create(Self, 120, 16, 10, 36);
  FLstItems := TXcomTextList.Create(Host.Options, Host.Clock, 287, 120, 8, 54);
  SetInterface('sellMenu');
  LInterface := Host.Resources.GetInterface('sellMenu');
  if (LInterface <> nil) and LInterface.TryGetElement('ammoColor', LElement) then
    FAmmoColor := Byte(LElement.Color);
  Add(FWindow, 'window', 'sellMenu');
  Add(FBtnOk, 'button', 'sellMenu');
  Add(FBtnCancel, 'button', 'sellMenu');
  Add(FTxtTitle, 'text', 'sellMenu');
  Add(FTxtSales, 'text', 'sellMenu');
  Add(FTxtFunds, 'text', 'sellMenu');
  Add(FTxtSpaceUsed, 'text', 'sellMenu');
  Add(FTxtQuantity, 'text', 'sellMenu');
  Add(FTxtSell, 'text', 'sellMenu');
  Add(FTxtValue, 'text', 'sellMenu');
  Add(FLstItems, 'list', 'sellMenu');
  Add(FCbxCategory, 'text', 'sellMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_SELL_SACK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  if LOverfull then
  begin
    FBtnCancel.Visible := False;
    FBtnOk.Visible := False;
  end;
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SELL_ITEMS_SACK_PERSONNEL'));
  FTxtSales.SetText(Tr('STR_VALUE_OF_SALES').Arg(TXcomFunding.Format(FTotal)));
  FTxtFunds.SetText(Tr('STR_FUNDS').Arg(TXcomFunding.Format(TXcomStrategy.SavedGame(AHost).Funds)));
  FTxtSpaceUsed.Visible := LEnforced;
  FTxtSpaceUsed.SetText(Tr('STR_SPACE_USED').Arg(TXcomSpaceText.Format(FCapacity.UsedStores(FBase), 0,
    FCapacity.AvailableStores(FBase))));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtSell.SetText(Tr('STR_SELL_SACK'));
  FTxtValue.SetText(Tr('STR_VALUE'));
  FLstItems.SetArrowColumn(182, aoVertical);
  FLstItems.SetColumns([156, 54, 24, 53]);
  FLstItems.SetSelectable(True);
  FLstItems.SetBackground(FWindow);
  FLstItems.SetMargin(2);
  FArrows := TXcomListArrowTimers.Create(Host.Clock, Host.Options, FLstItems, Increase, Decrease);
  FCategories.Add('STR_ALL_ITEMS');
  for LIndex := 0 to Length(FRuleset.CraftWeapons.Index) - 1 do
  begin
    LWeapon := FRuleset.CraftWeapons.Find(FRuleset.CraftWeapons.Index[LIndex]);
    FCraftWeapons.AddOrSetValue(LWeapon.LauncherItem, True);
    FCraftWeapons.AddOrSetValue(LWeapon.ClipItem, True);
  end;
  for LIndex := 0 to Length(FRuleset.Armors.Index) - 1 do
  begin
    LArmor := FRuleset.Armors.Find(FRuleset.Armors.Index[LIndex]);
    FArmors.AddOrSetValue(LArmor.StoreItem, True);
  end;
  for LSoldier in FBase.Soldiers do
    if LSoldier.Craft = nil then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkSoldier;
      LRow.Rule := LSoldier;
      LRow.Name := LSoldier.Name;
      LRow.QtySrc := 1;
      AddRowOf(LRow);
    end;
  for LCraft in FBase.Crafts do
    if LCraft.Status <> 'STR_OUT' then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkCraft;
      LRow.Rule := LCraft;
      LRow.Name := TXcomBaseNames.CraftName(LCraft, Host.Language);
      LRow.Cost := LCraft.Rules.SellCost;
      LRow.QtySrc := 1;
      AddRowOf(LRow);
    end;
  if FCapacity.AvailableScientists(FBase) > 0 then
  begin
    LRow := Default(TXcomTransferRow);
    LRow.Kind := tkScientist;
    LRow.Name := Tr('STR_SCIENTIST').Text;
    LRow.QtySrc := FCapacity.AvailableScientists(FBase);
    AddRowOf(LRow);
  end;
  if FCapacity.AvailableEngineers(FBase) > 0 then
  begin
    LRow := Default(TXcomTransferRow);
    LRow.Kind := tkEngineer;
    LRow.Name := Tr('STR_ENGINEER').Text;
    LRow.QtySrc := FCapacity.AvailableEngineers(FBase);
    AddRowOf(LRow);
  end;
  for LIndex := 0 to Length(FRuleset.Items.Index) - 1 do
  begin
    LName := FRuleset.Items.Index[LIndex];
    LQty := FBase.StorageItems.GetItem(LName);
    if LEnforced and ABattlescapeOrigin then
    begin
      for LTransfer in FBase.Transfers do
        if LTransfer.ItemId = LName then
          Inc(LQty, LTransfer.ItemQty);
      for LCraft in FBase.Crafts do
        Inc(LQty, LCraft.Items.GetItem(LName));
    end;
    LItem := FRuleset.Items.Find(LName);
    if (LQty > 0) and (Host.Options.GetBool('canSellLiveAliens') or not LItem.LiveAlien) then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkItem;
      LRow.Rule := LItem;
      LRow.Name := Tr(LName).Text;
      LRow.Cost := LItem.SellCost;
      LRow.QtySrc := LQty;
      AddRowOf(LRow);
    end;
  end;
  FCbxCategory.SetOptions(FCategories.ToArray, True);
  FCbxCategory.OnChange(CategoryChange);
  UpdateList;
end;

destructor TXcomSellState.Destroy;
begin
  inherited Destroy;
  FArrows.Free;
  FCapacity.Free;
  FItems.Free;
  FRows.Free;
  FCategories.Free;
  FCraftWeapons.Free;
  FArmors.Free;
end;

procedure TXcomSellState.Think;
begin
  inherited Think;
  FArrows.Think;
end;

procedure TXcomSellState.AddRowOf(const ARow: TXcomTransferRow);
var
  LCategory: string;
begin
  FItems.Add(ARow);
  LCategory := CategoryOf(ARow);
  if FCategories.IndexOf(LCategory) < 0 then
    FCategories.Add(LCategory);
end;

function TXcomSellState.CategoryOf(const ARow: TXcomTransferRow): string;
var
  LRule: TXcomRuleItem;
begin
  case ARow.Kind of
    tkSoldier, tkScientist, tkEngineer:
      Result := 'STR_PERSONNEL';
    tkCraft:
      Result := 'STR_CRAFT_ARMAMENT';
  else
    begin
      LRule := TXcomRuleItem(ARow.Rule);
      if (LRule.BattleType = TXcomRuleItem.BT_CORPSE) or LRule.LiveAlien then
        Result := 'STR_ALIENS'
      else if LRule.BattleType = TXcomRuleItem.BT_NONE then
      begin
        if FCraftWeapons.ContainsKey(LRule.ItemType) then
          Result := 'STR_CRAFT_ARMAMENT'
        else if FArmors.ContainsKey(LRule.ItemType) then
          Result := 'STR_EQUIPMENT'
        else
          Result := 'STR_COMPONENTS';
      end
      else
        Result := 'STR_EQUIPMENT';
    end;
  end;
end;

function TXcomSellState.IsAmmo(const ARow: TXcomTransferRow): Boolean;
var
  LRule: TXcomRuleItem;
begin
  Result := False;
  if ARow.Kind = tkItem then
  begin
    LRule := TXcomRuleItem(ARow.Rule);
    Result := (LRule.BattleType = TXcomRuleItem.BT_AMMO) or
      ((LRule.BattleType = TXcomRuleItem.BT_NONE) and (LRule.ClipSize > 0));
  end;
end;

procedure TXcomSellState.UpdateList;
var
  LIndex: Integer;
  LCategory, LName: string;
  LRow: TXcomTransferRow;
  LAmmo: Boolean;
begin
  FLstItems.ClearList;
  FRows.Clear;
  for LIndex := 0 to FItems.Count - 1 do
  begin
    LRow := FItems[LIndex];
    LCategory := FCategories[FCbxCategory.GetSelected];
    if (LCategory <> 'STR_ALL_ITEMS') and (LCategory <> CategoryOf(LRow)) then
      Continue;
    LName := LRow.Name;
    LAmmo := IsAmmo(LRow);
    if LAmmo then
      LName := '  ' + LName;
    FLstItems.AddRow([LName, IntToStr(LRow.QtySrc - LRow.Amount), IntToStr(LRow.Amount),
      TXcomFunding.Format(LRow.Cost)]);
    FRows.Add(LIndex);
    if LRow.Amount > 0 then
      FLstItems.SetRowColor(FRows.Count - 1, FLstItems.GetSecondaryColor)
    else if LAmmo then
      FLstItems.SetRowColor(FRows.Count - 1, FAmmoColor);
  end;
end;

procedure TXcomSellState.SellItem(const ARow: TXcomTransferRow);
var
  LSoldier: TXcomSoldier;
  LCraft: TXcomCraft;
  LItem: TXcomRuleItem;
  LToRemove, LHeld, LIndex: Integer;
  LTransfer: TXcomTransfer;
begin
  case ARow.Kind of
    tkSoldier:
      begin
        LSoldier := TXcomSoldier(ARow.Rule);
        if LSoldier.Armor.StoreItem <> TXcomArmor.NONE then
          FBase.StorageItems.AddItem(LSoldier.Armor.StoreItem);
        // the list owns the soldier: removing it deletes it, as the C++ does
        FBase.Soldiers.Remove(LSoldier);
      end;
    tkCraft:
      begin
        LCraft := TXcomCraft(ARow.Rule);
        TXcomBaseCrafts.Remove(FBase, LCraft, True, FRuleset);
        LCraft.Free;
      end;
    tkScientist:
      FBase.Scientists := FBase.Scientists - ARow.Amount;
    tkEngineer:
      FBase.Engineers := FBase.Engineers - ARow.Amount;
    tkItem:
      begin
        LItem := TXcomRuleItem(ARow.Rule);
        if FBase.StorageItems.GetItem(LItem.ItemType) < ARow.Amount then
        begin
          LToRemove := ARow.Amount - FBase.StorageItems.GetItem(LItem.ItemType);
          // all of the items of the base, then those of the crafts, then those on their way
          FBase.StorageItems.RemoveItem(LItem.ItemType, MaxInt);
          for LCraft in FBase.Crafts do
          begin
            if LToRemove = 0 then
              Break;
            LHeld := LCraft.Items.GetItem(LItem.ItemType);
            if LHeld < LToRemove then
            begin
              Dec(LToRemove, LHeld);
              LCraft.Items.RemoveItem(LItem.ItemType, MaxInt);
            end
            else
            begin
              LCraft.Items.RemoveItem(LItem.ItemType, LToRemove);
              LToRemove := 0;
            end;
          end;
          LIndex := 0;
          while (LIndex < FBase.Transfers.Count) and (LToRemove > 0) do
          begin
            LTransfer := FBase.Transfers[LIndex];
            if LTransfer.ItemId = LItem.ItemType then
            begin
              if LTransfer.ItemQty <= LToRemove then
              begin
                Dec(LToRemove, LTransfer.ItemQty);
                FBase.Transfers.Delete(LIndex);
              end
              else
              begin
                LTransfer.SetItems(LTransfer.ItemId, LTransfer.ItemQty - LToRemove);
                LToRemove := 0;
                Inc(LIndex);
              end;
            end
            else
              Inc(LIndex);
          end;
        end
        else
          FBase.StorageItems.RemoveItem(LItem.ItemType, ARow.Amount);
      end;
  end;
end;

procedure TXcomSellState.OkClick(AAction: TXcomAction);
var
  LSave: TXcomSavedGame;
  LRow: TXcomTransferRow;
begin
  LSave := TXcomStrategy.SavedGame(Host);
  LSave.SetFunds(LSave.Funds + FTotal);
  for LRow in FItems do
    if LRow.Amount > 0 then
      SellItem(LRow);
  Host.PopState;
end;

procedure TXcomSellState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomSellState.CategoryChange(AAction: TXcomAction);
begin
  UpdateList;
end;

procedure TXcomSellState.Increase(AChange: Integer);
begin
  ChangeByValue(AChange, 1);
end;

procedure TXcomSellState.Decrease(AChange: Integer);
begin
  ChangeByValue(AChange, -1);
end;

function TXcomSellState.CraftWeaponsSpace(ACraft: TObject): Double;
var
  LWeapon: TXcomCraftWeapon;
  LLauncher, LAmmo: TXcomRuleItem;
  LRule: TXcomRuleCraftWeapon;
  LClips: Integer;
begin
  Result := 0.0;
  for LWeapon in TXcomCraft(ACraft).Weapons do
  begin
    if LWeapon = nil then
      Continue;
    LRule := FRuleset.CraftWeapons.Find(LWeapon.Rules.WeaponType);
    LLauncher := FRuleset.Items.Find(LRule.LauncherItem);
    Result := Result + LLauncher.Size;
    LAmmo := FRuleset.Items.Find(LRule.ClipItem);
    if LAmmo <> nil then
    begin
      // getClipsLoaded
      if LAmmo.ClipSize > 0 then
        LClips := Floor(LWeapon.Ammo / LAmmo.ClipSize)
      else
        LClips := Floor(LWeapon.Ammo / LWeapon.Rules.RearmRate);
      Result := Result + LAmmo.Size * LClips;
    end;
  end;
end;

procedure TXcomSellState.ChangeByValue(AChange, ADirection: Integer);
var
  LIndex: Integer;
  LRow: TXcomTransferRow;
  LArmor: TXcomRuleItem;
  LSoldier: TXcomSoldier;
begin
  LIndex := FRows[FArrows.Selected];
  LRow := FItems[LIndex];
  if ADirection > 0 then
  begin
    if (AChange <= 0) or (LRow.QtySrc <= LRow.Amount) then
      Exit;
    AChange := Min(LRow.QtySrc - LRow.Amount, AChange);
  end
  else
  begin
    if (AChange <= 0) or (LRow.Amount <= 0) then
      Exit;
    AChange := Min(LRow.Amount, AChange);
  end;
  LRow.Amount := LRow.Amount + ADirection * AChange;
  FItems[LIndex] := LRow;
  FTotal := FTotal + Int64(ADirection) * LRow.Cost * AChange;
  case LRow.Kind of
    tkSoldier:
      begin
        LSoldier := TXcomSoldier(LRow.Rule);
        if LSoldier.Armor.StoreItem <> TXcomArmor.NONE then
        begin
          LArmor := FRuleset.Items.Find(LSoldier.Armor.StoreItem);
          FSpaceChange := FSpaceChange + ADirection * LArmor.Size;
        end;
      end;
    tkCraft:
      FSpaceChange := FSpaceChange + ADirection * CraftWeaponsSpace(LRow.Rule);
    tkItem:
      FSpaceChange := FSpaceChange - ADirection * AChange * TXcomRuleItem(LRow.Rule).Size;
  end;
  UpdateItemStrings;
end;

procedure TXcomSellState.UpdateItemStrings;
var
  LRow: TXcomTransferRow;
  LSelected: Integer;
begin
  LSelected := FArrows.Selected;
  LRow := FItems[FRows[LSelected]];
  FLstItems.SetCellText(LSelected, 2, IntToStr(LRow.Amount));
  FLstItems.SetCellText(LSelected, 1, IntToStr(LRow.QtySrc - LRow.Amount));
  FTxtSales.SetText(Tr('STR_VALUE_OF_SALES').Arg(TXcomFunding.Format(FTotal)));
  if LRow.Amount > 0 then
    FLstItems.SetRowColor(LSelected, FLstItems.GetSecondaryColor)
  else
  begin
    FLstItems.SetRowColor(LSelected, FLstItems.GetColor);
    if IsAmmo(LRow) then
      FLstItems.SetRowColor(LSelected, FAmmoColor);
  end;
  FTxtSpaceUsed.SetText(Tr('STR_SPACE_USED').Arg(TXcomSpaceText.Format(FCapacity.UsedStores(FBase), FSpaceChange,
    FCapacity.AvailableStores(FBase))));
  if Host.Options.GetBool('storageLimitsEnforced') then
    FBtnOk.Visible := not FCapacity.StoresOverfull(FBase, FSpaceChange);
end;

end.
