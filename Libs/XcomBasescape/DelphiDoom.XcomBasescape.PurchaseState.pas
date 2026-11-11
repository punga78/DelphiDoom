{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - PurchaseState of OpenXcom (purchase /   }
{  hire personnel)                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.PurchaseState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ComboBox,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomBasescape.TransferRow, DelphiDoom.XcomBasescape.ListArrowTimers;

type
  /// <summary>
  ///   Buys items, hires personnel and buys crafts for a base: a row per soldier type, scientist, engineer, craft and
  ///   item that can be bought, with a category filter; what is bought arrives as transfers when OK is pressed
  /// </summary>
  TXcomPurchaseState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FRuleset: TXcomRuleset;
    FCapacity: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtFunds: TXcomText;
    FTxtPurchases: TXcomText;
    FTxtSpaceUsed: TXcomText;
    FTxtCost: TXcomText;
    FTxtQuantity: TXcomText;
    FCbxCategory: TXcomComboBox;
    FLstItems: TXcomTextList;
    FItems: TList<TXcomTransferRow>;
    FRows: TList<Integer>;
    FCategories: TList<string>;
    FCraftWeapons: TDictionary<string, Boolean>;
    FArmors: TDictionary<string, Boolean>;
    FTotal: Int64;
    FPersonnelQty: Integer;
    FCraftQty: Integer;
    FItemQty: Double;
    FAmmoColor: Byte;
    FArrows: TXcomListArrowTimers;
    procedure AddRowOf(const ARow: TXcomTransferRow);
    function CategoryOf(const ARow: TXcomTransferRow): string;
    function IsAmmo(const ARow: TXcomTransferRow): Boolean;
    function CurrentRowIndex: Integer;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure CategoryChange(AAction: TXcomAction);
    procedure Increase(AChange: Integer);
    procedure Decrease(AChange: Integer);
    procedure UpdateItemStrings;
    procedure ShowError(const AKey: string);
    procedure PayAndDeliver;
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    destructor Destroy; override;
    procedure Think; override;
    /// <summary>updateList: the rows of the category that is selected</summary>
    procedure UpdateList;
    /// <summary>The cost of what is selected so far</summary>
    property Total: Int64 read FTotal;
    property List: TXcomTextList read FLstItems;
    property Category: TXcomComboBox read FCbxCategory;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Transfer,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.NewGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomStrategy.BaseCrafts, DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomBasescape.SpaceText,
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleSoldier,
  DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomMod.Armor;

{ TXcomPurchaseState }

constructor TXcomPurchaseState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LIndex: Integer;
  LRow: TXcomTransferRow;
  LSoldier: TXcomRuleSoldier;
  LCraft: TXcomRuleCraft;
  LItem: TXcomRuleItem;
  LWeapon: TXcomRuleCraftWeapon;
  LArmor: TXcomArmor;
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
  LSave: TXcomSavedGame;
begin
  inherited Create(AHost);
  FBase := ABase;
  FRuleset := TXcomStrategy.Ruleset(AHost);
  LSave := TXcomStrategy.SavedGame(AHost);
  FCapacity := TXcomBaseCapacity.Create(FRuleset);
  FItems := TList<TXcomTransferRow>.Create;
  FRows := TList<Integer>.Create;
  FCategories := TList<string>.Create;
  FCraftWeapons := TDictionary<string, Boolean>.Create;
  FArmors := TDictionary<string, Boolean>.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtFunds := TXcomText.Create(150, 9, 10, 24);
  FTxtPurchases := TXcomText.Create(150, 9, 160, 24);
  FTxtSpaceUsed := TXcomText.Create(150, 9, 160, 34);
  FTxtCost := TXcomText.Create(102, 9, 152, 44);
  FTxtQuantity := TXcomText.Create(60, 9, 256, 44);
  FCbxCategory := TXcomComboBox.Create(Self, 120, 16, 10, 36);
  FLstItems := TXcomTextList.Create(Host.Options, Host.Clock, 287, 120, 8, 54);
  SetInterface('buyMenu');
  LInterface := Host.Resources.GetInterface('buyMenu');
  if (LInterface <> nil) and LInterface.TryGetElement('ammoColor', LElement) then
    FAmmoColor := Byte(LElement.Color);
  Add(FWindow, 'window', 'buyMenu');
  Add(FBtnOk, 'button', 'buyMenu');
  Add(FBtnCancel, 'button', 'buyMenu');
  Add(FTxtTitle, 'text', 'buyMenu');
  Add(FTxtFunds, 'text', 'buyMenu');
  Add(FTxtPurchases, 'text', 'buyMenu');
  Add(FTxtSpaceUsed, 'text', 'buyMenu');
  Add(FTxtCost, 'text', 'buyMenu');
  Add(FTxtQuantity, 'text', 'buyMenu');
  Add(FLstItems, 'list', 'buyMenu');
  Add(FCbxCategory, 'text', 'buyMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_PURCHASE_HIRE_PERSONNEL'));
  FTxtFunds.SetText(Tr('STR_CURRENT_FUNDS').Arg(TXcomFunding.Format(LSave.Funds)));
  FTxtPurchases.SetText(Tr('STR_COST_OF_PURCHASES').Arg(TXcomFunding.Format(FTotal)));
  FTxtSpaceUsed.Visible := Host.Options.GetBool('storageLimitsEnforced');
  FTxtSpaceUsed.SetText(Tr('STR_SPACE_USED').Arg(TXcomSpaceText.Format(FCapacity.UsedStores(FBase), 0,
    FCapacity.AvailableStores(FBase))));
  FTxtCost.SetText(Tr('STR_COST_PER_UNIT_UC'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FLstItems.SetArrowColumn(227, aoVertical);
  FLstItems.SetColumns([150, 55, 50, 32]);
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
  for LIndex := 0 to Length(FRuleset.Soldiers.Index) - 1 do
  begin
    LSoldier := FRuleset.Soldiers.Find(FRuleset.Soldiers.Index[LIndex]);
    if (LSoldier.BuyCost <> 0) and LSave.IsResearched(LSoldier.Requirements) then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkSoldier;
      LRow.Rule := LSoldier;
      LRow.Name := Tr(LSoldier.SoldierType).Text;
      LRow.Cost := LSoldier.BuyCost;
      LRow.QtySrc := FCapacity.SoldierCount(FBase, LSoldier.SoldierType);
      AddRowOf(LRow);
    end;
  end;
  LRow := Default(TXcomTransferRow);
  LRow.Kind := tkScientist;
  LRow.Name := Tr('STR_SCIENTIST').Text;
  LRow.Cost := FRuleset.Settings.CostScientist * 2;
  LRow.QtySrc := FCapacity.TotalScientists(FBase);
  AddRowOf(LRow);
  LRow := Default(TXcomTransferRow);
  LRow.Kind := tkEngineer;
  LRow.Name := Tr('STR_ENGINEER').Text;
  LRow.Cost := FRuleset.Settings.CostEngineer * 2;
  LRow.QtySrc := FCapacity.TotalEngineers(FBase);
  AddRowOf(LRow);
  for LIndex := 0 to Length(FRuleset.Crafts.Index) - 1 do
  begin
    LCraft := FRuleset.Crafts.Find(FRuleset.Crafts.Index[LIndex]);
    if (LCraft.BuyCost <> 0) and LSave.IsResearched(LCraft.Requirements) then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkCraft;
      LRow.Rule := LCraft;
      LRow.Name := Tr(LCraft.CraftType).Text;
      LRow.Cost := LCraft.BuyCost;
      LRow.QtySrc := TXcomBaseCrafts.Count(FBase, LCraft.CraftType);
      AddRowOf(LRow);
    end;
  end;
  for LIndex := 0 to Length(FRuleset.Items.Index) - 1 do
  begin
    LItem := FRuleset.Items.Find(FRuleset.Items.Index[LIndex]);
    if (LItem.BuyCost <> 0) and LSave.IsResearched(LItem.Requirements) then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkItem;
      LRow.Rule := LItem;
      LRow.Name := Tr(LItem.ItemType).Text;
      LRow.Cost := LItem.BuyCost;
      LRow.QtySrc := FBase.StorageItems.GetItem(LItem.ItemType);
      AddRowOf(LRow);
    end;
  end;
  FCbxCategory.SetOptions(FCategories.ToArray, True);
  FCbxCategory.OnChange(CategoryChange);
  UpdateList;
end;

destructor TXcomPurchaseState.Destroy;
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

procedure TXcomPurchaseState.Think;
begin
  inherited Think;
  FArrows.Think;
end;

procedure TXcomPurchaseState.AddRowOf(const ARow: TXcomTransferRow);
var
  LCategory: string;
begin
  FItems.Add(ARow);
  LCategory := CategoryOf(ARow);
  if FCategories.IndexOf(LCategory) < 0 then
    FCategories.Add(LCategory);
end;

function TXcomPurchaseState.CategoryOf(const ARow: TXcomTransferRow): string;
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

function TXcomPurchaseState.IsAmmo(const ARow: TXcomTransferRow): Boolean;
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

function TXcomPurchaseState.CurrentRowIndex: Integer;
begin
  Result := FRows[FArrows.Selected];
end;

procedure TXcomPurchaseState.UpdateList;
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
    FLstItems.AddRow([LName, TXcomFunding.Format(LRow.Cost), IntToStr(LRow.QtySrc), IntToStr(LRow.Amount)]);
    FRows.Add(LIndex);
    if LRow.Amount > 0 then
      FLstItems.SetRowColor(FRows.Count - 1, FLstItems.GetSecondaryColor)
    else if LAmmo then
      FLstItems.SetRowColor(FRows.Count - 1, FAmmoColor);
  end;
end;

procedure TXcomPurchaseState.PayAndDeliver;
var
  LRow: TXcomTransferRow;
  LSave: TXcomSavedGame;
  LTransfer: TXcomTransfer;
  LNewGame: TXcomNewGame;
  LSoldierRule: TXcomRuleSoldier;
  LCraftRule: TXcomRuleCraft;
  LItemRule: TXcomRuleItem;
  LCraft: TXcomCraft;
  LTime, LCount: Integer;
begin
  LSave := TXcomStrategy.SavedGame(Host);
  LSave.SetFunds(LSave.Funds - FTotal);
  // genSoldier needs the ruleset, the generator and the saved game; the rules of the saved game objects are not used
  LNewGame := TXcomNewGame.Create(FRuleset, nil, nil, TXcomStrategy.Random(Host));
  try
    for LRow in FItems do
    begin
      if LRow.Amount <= 0 then
        Continue;
      case LRow.Kind of
        tkSoldier:
          begin
            LSoldierRule := TXcomRuleSoldier(LRow.Rule);
            for LCount := 1 to LRow.Amount do
            begin
              LTime := LSoldierRule.TransferTime;
              if LTime = 0 then
                LTime := FRuleset.Settings.TimePersonnel;
              LTransfer := TXcomTransfer.Create(LTime);
              LTransfer.Soldier := LNewGame.GenSoldier(LSave, LSoldierRule.SoldierType);
              FBase.Transfers.Add(LTransfer);
            end;
          end;
        tkScientist:
          begin
            LTransfer := TXcomTransfer.Create(FRuleset.Settings.TimePersonnel);
            LTransfer.Scientists := LRow.Amount;
            FBase.Transfers.Add(LTransfer);
          end;
        tkEngineer:
          begin
            LTransfer := TXcomTransfer.Create(FRuleset.Settings.TimePersonnel);
            LTransfer.Engineers := LRow.Amount;
            FBase.Transfers.Add(LTransfer);
          end;
        tkCraft:
          begin
            LCraftRule := TXcomRuleCraft(LRow.Rule);
            for LCount := 1 to LRow.Amount do
            begin
              LTransfer := TXcomTransfer.Create(LCraftRule.TransferTime);
              LCraft := TXcomCraft.Create(LCraftRule, FBase, LSave.GetId(LCraftRule.CraftType));
              LCraft.Status := 'STR_REFUELLING';
              LTransfer.Craft := LCraft;
              FBase.Transfers.Add(LTransfer);
            end;
          end;
        tkItem:
          begin
            LItemRule := TXcomRuleItem(LRow.Rule);
            LTransfer := TXcomTransfer.Create(LItemRule.TransferTime);
            LTransfer.SetItems(LItemRule.ItemType, LRow.Amount);
            FBase.Transfers.Add(LTransfer);
          end;
      end;
    end;
  finally
    LNewGame.Free;
  end;
end;

procedure TXcomPurchaseState.OkClick(AAction: TXcomAction);
begin
  PayAndDeliver;
  Host.PopState;
end;

procedure TXcomPurchaseState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomPurchaseState.CategoryChange(AAction: TXcomAction);
begin
  UpdateList;
end;

procedure TXcomPurchaseState.ShowError(const AKey: string);
var
  LInterface: TXcomRuleInterface;
  LMessage, LPalette: TXcomInterfaceElement;
begin
  LMessage := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  LPalette.Color := -1;
  LInterface := Host.Resources.GetInterface('buyMenu');
  if LInterface <> nil then
  begin
    LInterface.TryGetElement('errorMessage', LMessage);
    LInterface.TryGetElement('errorPalette', LPalette);
  end;
  Host.PushState(TXcomErrorMessageState.Create(Host, Tr(AKey), Palette, Byte(LMessage.Color), 'BACK13.SCR',
    LPalette.Color));
end;

procedure TXcomPurchaseState.Increase(AChange: Integer);
var
  LRow: TXcomTransferRow;
  LIndex: Integer;
  LError: string;
  LMaxByMoney, LMaxByQuarters, LMaxByHangars, LMaxByStores: Integer;
  LNeeded, LFree: Double;
  LFunds: Int64;
begin
  if AChange <= 0 then
    Exit;
  LIndex := CurrentRowIndex;
  LRow := FItems[LIndex];
  LFunds := TXcomStrategy.SavedGame(Host).Funds;
  LError := '';
  if FTotal + LRow.Cost > LFunds then
    LError := 'STR_NOT_ENOUGH_MONEY'
  else
    case LRow.Kind of
      tkSoldier, tkScientist, tkEngineer:
        if FPersonnelQty + 1 > FCapacity.AvailableQuarters(FBase) - FCapacity.UsedQuarters(FBase) then
          LError := 'STR_NOT_ENOUGH_LIVING_SPACE';
      tkCraft:
        if FCraftQty + 1 > FCapacity.AvailableHangars(FBase) - FCapacity.UsedHangars(FBase) then
          LError := 'STR_NO_FREE_HANGARS_FOR_PURCHASE';
      tkItem:
        if FCapacity.StoresOverfull(FBase, FItemQty + TXcomRuleItem(LRow.Rule).Size) then
          LError := 'STR_NOT_ENOUGH_STORE_SPACE';
    end;
  if LError = '' then
  begin
    LMaxByMoney := Integer((LFunds - FTotal) div LRow.Cost);
    if LMaxByMoney >= 0 then
      AChange := Min(LMaxByMoney, AChange);
    case LRow.Kind of
      tkSoldier, tkScientist, tkEngineer:
        begin
          LMaxByQuarters := FCapacity.AvailableQuarters(FBase) - FCapacity.UsedQuarters(FBase) - FPersonnelQty;
          AChange := Min(LMaxByQuarters, AChange);
          Inc(FPersonnelQty, AChange);
        end;
      tkCraft:
        begin
          LMaxByHangars := FCapacity.AvailableHangars(FBase) - FCapacity.UsedHangars(FBase) - FCraftQty;
          AChange := Min(LMaxByHangars, AChange);
          Inc(FCraftQty, AChange);
        end;
      tkItem:
        begin
          LNeeded := TXcomRuleItem(LRow.Rule).Size;
          LFree := FCapacity.AvailableStores(FBase) - FCapacity.UsedStores(FBase) - FItemQty;
          LMaxByStores := MaxInt;
          if not SameValue(LNeeded, 0.0) then
            LMaxByStores := Trunc(Min((LFree + 0.05) / LNeeded, MaxInt));
          AChange := Min(LMaxByStores, AChange);
          FItemQty := FItemQty + AChange * LNeeded;
        end;
    end;
    LRow.Amount := LRow.Amount + AChange;
    FItems[LIndex] := LRow;
    FTotal := FTotal + Int64(LRow.Cost) * AChange;
    UpdateItemStrings;
  end
  else
  begin
    FArrows.StopIncrease;
    ShowError(LError);
  end;
end;

procedure TXcomPurchaseState.Decrease(AChange: Integer);
var
  LRow: TXcomTransferRow;
  LIndex: Integer;
begin
  LIndex := CurrentRowIndex;
  LRow := FItems[LIndex];
  if (AChange <= 0) or (LRow.Amount <= 0) then
    Exit;
  AChange := Min(LRow.Amount, AChange);
  case LRow.Kind of
    tkSoldier, tkScientist, tkEngineer:
      Dec(FPersonnelQty, AChange);
    tkCraft:
      Dec(FCraftQty, AChange);
    tkItem:
      FItemQty := FItemQty - TXcomRuleItem(LRow.Rule).Size * AChange;
  end;
  LRow.Amount := LRow.Amount - AChange;
  FItems[LIndex] := LRow;
  FTotal := FTotal - Int64(LRow.Cost) * AChange;
  UpdateItemStrings;
end;

procedure TXcomPurchaseState.UpdateItemStrings;
var
  LRow: TXcomTransferRow;
  LSelected: Integer;
begin
  LSelected := FArrows.Selected;
  LRow := FItems[CurrentRowIndex];
  FTxtPurchases.SetText(Tr('STR_COST_OF_PURCHASES').Arg(TXcomFunding.Format(FTotal)));
  FLstItems.SetCellText(LSelected, 3, IntToStr(LRow.Amount));
  if LRow.Amount > 0 then
    FLstItems.SetRowColor(LSelected, FLstItems.GetSecondaryColor)
  else
  begin
    FLstItems.SetRowColor(LSelected, FLstItems.GetColor);
    if IsAmmo(LRow) then
      FLstItems.SetRowColor(LSelected, FAmmoColor);
  end;
  FTxtSpaceUsed.SetText(Tr('STR_SPACE_USED').Arg(TXcomSpaceText.Format(FCapacity.UsedStores(FBase), FItemQty,
    FCapacity.AvailableStores(FBase))));
end;

end.
