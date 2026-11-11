{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - TransferItemsState of OpenXcom (what to }
{  send to another base)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.TransferItemsState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ComboBox,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomBasescape.TransferRow, DelphiDoom.XcomBasescape.ListArrowTimers;

type
  /// <summary>
  ///   What to send from a base to another: soldiers and crafts (with their crew) that are at home, scientists,
  ///   engineers and items, with the room that the destination has for them. The cost grows with the distance
  ///   between the bases; the transfers are made when the confirmation is given
  /// </summary>
  TXcomTransferItemsState = class(TXcomState)
  strict private
    FBaseFrom: TXcomBase;
    FBaseTo: TXcomBase;
    FRuleset: TXcomRuleset;
    FCapacityTo: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtAmountTransfer: TXcomText;
    FTxtAmountDestination: TXcomText;
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
    FAlienQty: Integer;
    FItemQty: Double;
    FDistance: Double;
    FAmmoColor: Byte;
    FArrows: TXcomListArrowTimers;
    function ComputeDistance: Double;
    procedure AddRowOf(const ARow: TXcomTransferRow);
    function CategoryOf(const ARow: TXcomTransferRow): string;
    function IsAmmo(const ARow: TXcomTransferRow): Boolean;
    function CraftContentsSize(ACraft: TObject): Double;
    function IsAirborneTransferFree(ACraft: TObject): Boolean;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure CategoryChange(AAction: TXcomAction);
    procedure Increase(AChange: Integer);
    procedure Decrease(AChange: Integer);
    procedure UpdateItemStrings;
    procedure ShowError(const AKey: string);
  public
    /// <param name="ABaseFrom">The base that sends (not owned)</param>
    /// <param name="ABaseTo">The base that receives (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABaseFrom, ABaseTo: TXcomBase);
    destructor Destroy; override;
    procedure Think; override;
    procedure UpdateList;
    /// <summary>completeTransfer: pays and makes the transfers of everything that was chosen</summary>
    procedure CompleteTransfer;
    property Total: Int64 read FTotal;
    property Distance: Double read FDistance;
    property List: TXcomTextList read FLstItems;
  end;

implementation

uses
  System.Generics.Defaults, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomStrategy.BaseCrafts, DelphiDoom.XcomBasescape.SpaceText,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.ItemSizes, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomBasescape.TransferConfirmState, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.RuleCraftWeapon,
  DelphiDoom.XcomMod.Armor;

{ TXcomTransferItemsState }

constructor TXcomTransferItemsState.Create(AHost: TXcomStateHost; ABaseFrom, ABaseTo: TXcomBase);
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

begin
  inherited Create(AHost);
  FBaseFrom := ABaseFrom;
  FBaseTo := ABaseTo;
  FRuleset := TXcomStrategy.Ruleset(AHost);
  FCapacityTo := TXcomBaseCapacity.Create(FRuleset);
  FItems := TList<TXcomTransferRow>.Create;
  FRows := TList<Integer>.Create;
  FCategories := TList<string>.Create;
  FCraftWeapons := TDictionary<string, Boolean>.Create;
  FArmors := TDictionary<string, Boolean>.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtQuantity := TXcomText.Create(50, 9, 150, 24);
  FTxtAmountTransfer := TXcomText.Create(60, 17, 200, 24);
  FTxtAmountDestination := TXcomText.Create(60, 17, 260, 24);
  FCbxCategory := TXcomComboBox.Create(Self, 120, 16, 10, 24);
  FLstItems := TXcomTextList.Create(Host.Options, Host.Clock, 287, 128, 8, 44);
  SetInterface('transferMenu');
  LInterface := Host.Resources.GetInterface('transferMenu');
  if (LInterface <> nil) and LInterface.TryGetElement('ammoColor', LElement) then
    FAmmoColor := Byte(LElement.Color);
  Add(FWindow, 'window', 'transferMenu');
  Add(FBtnOk, 'button', 'transferMenu');
  Add(FBtnCancel, 'button', 'transferMenu');
  Add(FTxtTitle, 'text', 'transferMenu');
  Add(FTxtQuantity, 'text', 'transferMenu');
  Add(FTxtAmountTransfer, 'text', 'transferMenu');
  Add(FTxtAmountDestination, 'text', 'transferMenu');
  Add(FLstItems, 'list', 'transferMenu');
  Add(FCbxCategory, 'text', 'transferMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_TRANSFER'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_TRANSFER'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtAmountTransfer.SetText(Tr('STR_AMOUNT_TO_TRANSFER'));
  FTxtAmountTransfer.SetWordWrap(True);
  FTxtAmountDestination.SetText(Tr('STR_AMOUNT_AT_DESTINATION'));
  FTxtAmountDestination.SetWordWrap(True);
  FLstItems.SetArrowColumn(193, aoVertical);
  FLstItems.SetColumns([162, 58, 40, 27]);
  FLstItems.SetSelectable(True);
  FLstItems.SetBackground(FWindow);
  FLstItems.SetMargin(2);
  FArrows := TXcomListArrowTimers.Create(Host.Clock, Host.Options, FLstItems, Increase, Decrease);
  FDistance := ComputeDistance;
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
  for LSoldier in FBaseFrom.Soldiers do
    if LSoldier.Craft = nil then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkSoldier;
      LRow.Rule := LSoldier;
      LRow.Name := LSoldier.Name;
      LRow.Cost := Trunc(5 * FDistance);
      LRow.QtySrc := 1;
      AddRowOf(LRow);
    end;
  for LCraft in FBaseFrom.Crafts do
    if (LCraft.Status <> 'STR_OUT') or (Host.Options.GetBool('canTransferCraftsWhileAirborne') and
      (LCraft.Fuel >= LCraft.FuelLimit(FBaseTo))) then
    begin
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkCraft;
      LRow.Rule := LCraft;
      LRow.Name := TXcomBaseNames.CraftName(LCraft, Host.Language);
      LRow.Cost := Trunc(25 * FDistance);
      LRow.QtySrc := 1;
      AddRowOf(LRow);
    end;
  if FCapacityTo.AvailableScientists(FBaseFrom) > 0 then
  begin
    LRow := Default(TXcomTransferRow);
    LRow.Kind := tkScientist;
    LRow.Name := Tr('STR_SCIENTIST').Text;
    LRow.Cost := Trunc(5 * FDistance);
    LRow.QtySrc := FCapacityTo.AvailableScientists(FBaseFrom);
    LRow.QtyDst := FCapacityTo.AvailableScientists(FBaseTo);
    AddRowOf(LRow);
  end;
  if FCapacityTo.AvailableEngineers(FBaseFrom) > 0 then
  begin
    LRow := Default(TXcomTransferRow);
    LRow.Kind := tkEngineer;
    LRow.Name := Tr('STR_ENGINEER').Text;
    LRow.Cost := Trunc(5 * FDistance);
    LRow.QtySrc := FCapacityTo.AvailableEngineers(FBaseFrom);
    LRow.QtyDst := FCapacityTo.AvailableEngineers(FBaseTo);
    AddRowOf(LRow);
  end;
  for LIndex := 0 to Length(FRuleset.Items.Index) - 1 do
  begin
    LName := FRuleset.Items.Index[LIndex];
    LQty := FBaseFrom.StorageItems.GetItem(LName);
    if LQty > 0 then
    begin
      LItem := FRuleset.Items.Find(LName);
      LRow := Default(TXcomTransferRow);
      LRow.Kind := tkItem;
      LRow.Rule := LItem;
      LRow.Name := Tr(LName).Text;
      LRow.Cost := Trunc(1 * FDistance);
      LRow.QtySrc := LQty;
      LRow.QtyDst := FBaseTo.StorageItems.GetItem(LName);
      AddRowOf(LRow);
    end;
  end;
  FCbxCategory.SetOptions(FCategories.ToArray, True);
  FCbxCategory.OnChange(CategoryChange);
  UpdateList;
end;

destructor TXcomTransferItemsState.Destroy;
begin
  inherited Destroy;
  FArrows.Free;
  FCapacityTo.Free;
  FItems.Free;
  FRows.Free;
  FCategories.Free;
  FCraftWeapons.Free;
  FArmors.Free;
end;

procedure TXcomTransferItemsState.Think;
begin
  inherited Think;
  FArrows.Think;
end;

function TXcomTransferItemsState.ComputeDistance: Double;
var
  LX, LY, LZ: array[0..2] of Double;
  LIndex: Integer;
  LBase: TXcomBase;
const
  Radius: Double = 51.2;
begin
  LBase := FBaseFrom;
  for LIndex := 0 to 1 do
  begin
    LX[LIndex] := Radius * Cos(LBase.Latitude) * Cos(LBase.Longitude);
    LY[LIndex] := Radius * Cos(LBase.Latitude) * Sin(LBase.Longitude);
    LZ[LIndex] := Radius * -Sin(LBase.Latitude);
    LBase := FBaseTo;
  end;
  LX[2] := LX[1] - LX[0];
  LY[2] := LY[1] - LY[0];
  LZ[2] := LZ[1] - LZ[0];
  Result := Sqrt(LX[2] * LX[2] + LY[2] * LY[2] + LZ[2] * LZ[2]);
end;

procedure TXcomTransferItemsState.AddRowOf(const ARow: TXcomTransferRow);
var
  LCategory: string;
begin
  FItems.Add(ARow);
  LCategory := CategoryOf(ARow);
  if FCategories.IndexOf(LCategory) < 0 then
    FCategories.Add(LCategory);
end;

function TXcomTransferItemsState.CategoryOf(const ARow: TXcomTransferRow): string;
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

function TXcomTransferItemsState.IsAmmo(const ARow: TXcomTransferRow): Boolean;
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

function TXcomTransferItemsState.CraftContentsSize(ACraft: TObject): Double;
begin
  Result := TXcomItemSizes.TotalSize(TXcomCraft(ACraft).Items, FRuleset);
end;

function TXcomTransferItemsState.IsAirborneTransferFree(ACraft: TObject): Boolean;
begin
  Result := Host.Options.GetBool('canTransferCraftsWhileAirborne') and Assigned(ACraft) and
    (TXcomCraft(ACraft).Status = 'STR_OUT');
end;

procedure TXcomTransferItemsState.UpdateList;
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
    FLstItems.AddRow([LName, IntToStr(LRow.QtySrc - LRow.Amount), IntToStr(LRow.Amount), IntToStr(LRow.QtyDst)]);
    FRows.Add(LIndex);
    if LRow.Amount > 0 then
      FLstItems.SetRowColor(FRows.Count - 1, FLstItems.GetSecondaryColor)
    else if LAmmo then
      FLstItems.SetRowColor(FRows.Count - 1, FAmmoColor);
  end;
end;

procedure TXcomTransferItemsState.OkClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomTransferConfirmState.Create(Host, FBaseTo, FTotal, CompleteTransfer));
end;

procedure TXcomTransferItemsState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
  Host.PopState;
end;

procedure TXcomTransferItemsState.CategoryChange(AAction: TXcomAction);
begin
  UpdateList;
end;

procedure TXcomTransferItemsState.CompleteTransfer;
var
  LTime: Integer;
  LSave: TXcomSavedGame;
  LRow: TXcomTransferRow;
  LTransfer: TXcomTransfer;
  LSoldier: TXcomSoldier;
  LCraft: TXcomCraft;
  LIndex: Integer;
  LReturning: Boolean;
begin
  LTime := Floor(6 + FDistance / 10.0);
  LSave := TXcomStrategy.SavedGame(Host);
  LSave.SetFunds(LSave.Funds - FTotal);
  for LRow in FItems do
  begin
    if LRow.Amount <= 0 then
      Continue;
    case LRow.Kind of
      tkSoldier:
        begin
          LSoldier := TXcomSoldier(LRow.Rule);
          LSoldier.PsiTraining := False;
          LTransfer := TXcomTransfer.Create(LTime);
          // the transfer owns the soldier now: it leaves the list without being freed
          FBaseFrom.Soldiers.Extract(LSoldier);
          LTransfer.Soldier := LSoldier;
          FBaseTo.Transfers.Add(LTransfer);
        end;
      tkCraft:
        begin
          LCraft := TXcomCraft(LRow.Rule);
          // the crew of the craft goes with it
          LIndex := 0;
          while LIndex < FBaseFrom.Soldiers.Count do
          begin
            LSoldier := FBaseFrom.Soldiers[LIndex];
            if LSoldier.Craft = LCraft then
            begin
              LSoldier.PsiTraining := False;
              FBaseFrom.Soldiers.Extract(LSoldier);
              if LCraft.Status = 'STR_OUT' then
                FBaseTo.Soldiers.Add(LSoldier)
              else
              begin
                LTransfer := TXcomTransfer.Create(LTime);
                LTransfer.Soldier := LSoldier;
                FBaseTo.Transfers.Add(LTransfer);
              end;
            end
            else
              Inc(LIndex);
          end;
          TXcomBaseCrafts.Remove(FBaseFrom, LCraft, False, FRuleset);
          if LCraft.Status = 'STR_OUT' then
          begin
            LReturning := LCraft.Destination = TXcomTarget(LCraft.Base);
            FBaseTo.Crafts.Add(LCraft);
            LCraft.SetBase(FBaseTo, False);
            if LCraft.Fuel <= LCraft.FuelLimit(FBaseTo) then
            begin
              LCraft.LowFuel := True;
              LCraft.ReturnToBase;
            end
            else if LReturning then
            begin
              LCraft.LowFuel := False;
              LCraft.ReturnToBase;
            end;
          end
          else
          begin
            LTransfer := TXcomTransfer.Create(LTime);
            LTransfer.Craft := LCraft;
            FBaseTo.Transfers.Add(LTransfer);
          end;
        end;
      tkScientist:
        begin
          FBaseFrom.Scientists := FBaseFrom.Scientists - LRow.Amount;
          LTransfer := TXcomTransfer.Create(LTime);
          LTransfer.Scientists := LRow.Amount;
          FBaseTo.Transfers.Add(LTransfer);
        end;
      tkEngineer:
        begin
          FBaseFrom.Engineers := FBaseFrom.Engineers - LRow.Amount;
          LTransfer := TXcomTransfer.Create(LTime);
          LTransfer.Engineers := LRow.Amount;
          FBaseTo.Transfers.Add(LTransfer);
        end;
      tkItem:
        begin
          FBaseFrom.StorageItems.RemoveItem(TXcomRuleItem(LRow.Rule).ItemType, LRow.Amount);
          LTransfer := TXcomTransfer.Create(LTime);
          LTransfer.SetItems(TXcomRuleItem(LRow.Rule).ItemType, LRow.Amount);
          FBaseTo.Transfers.Add(LTransfer);
        end;
    end;
  end;
end;

procedure TXcomTransferItemsState.ShowError(const AKey: string);
var
  LInterface: TXcomRuleInterface;
  LMessage, LPalette: TXcomInterfaceElement;
begin
  LMessage := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  LPalette.Color := -1;
  LInterface := Host.Resources.GetInterface('transferMenu');
  if LInterface <> nil then
  begin
    LInterface.TryGetElement('errorMessage', LMessage);
    LInterface.TryGetElement('errorPalette', LPalette);
  end;
  Host.PushState(TXcomErrorMessageState.Create(Host, Tr(AKey), Palette, Byte(LMessage.Color), 'BACK13.SCR',
    LPalette.Color));
end;

procedure TXcomTransferItemsState.Increase(AChange: Integer);
var
  LIndex: Integer;
  LRow: TXcomTransferRow;
  LError: string;
  LEnforced: Boolean;
  LFreeQuarters, LFreeContainment, LFreeForItem: Integer;
  LNeeded, LFree, LFreeForItemValue: Double;
  LCraft: TXcomCraft;
  LItem: TXcomRuleItem;
begin
  LIndex := FRows[FArrows.Selected];
  LRow := FItems[LIndex];
  if (AChange <= 0) or (LRow.QtySrc <= LRow.Amount) then
    Exit;
  LEnforced := Host.Options.GetBool('storageLimitsEnforced');
  LError := '';
  LCraft := nil;
  LItem := nil;
  case LRow.Kind of
    tkSoldier, tkScientist, tkEngineer:
      if FPersonnelQty + 1 > FCapacityTo.AvailableQuarters(FBaseTo) - FCapacityTo.UsedQuarters(FBaseTo) then
        LError := 'STR_NO_FREE_ACCOMODATION';
    tkCraft:
      begin
        LCraft := TXcomCraft(LRow.Rule);
        if FCraftQty + 1 > FCapacityTo.AvailableHangars(FBaseTo) - FCapacityTo.UsedHangars(FBaseTo) then
          LError := 'STR_NO_FREE_HANGARS_FOR_TRANSFER'
        else if FPersonnelQty + LCraft.NumSoldiers(FBaseFrom.Soldiers) >
          FCapacityTo.AvailableQuarters(FBaseTo) - FCapacityTo.UsedQuarters(FBaseTo) then
          LError := 'STR_NO_FREE_ACCOMODATION_CREW'
        else if LEnforced and FCapacityTo.StoresOverfull(FBaseTo, FItemQty + CraftContentsSize(LCraft)) then
          LError := 'STR_NOT_ENOUGH_STORE_SPACE_FOR_CRAFT';
      end;
    tkItem:
      begin
        LItem := TXcomRuleItem(LRow.Rule);
        if not LItem.LiveAlien and FCapacityTo.StoresOverfull(FBaseTo, LItem.Size + FItemQty) then
          LError := 'STR_NOT_ENOUGH_STORE_SPACE'
        else if LItem.LiveAlien and (Ord(LEnforced) * FAlienQty + 1 >
          FCapacityTo.AvailableContainment(FBaseTo) - Ord(LEnforced) * FCapacityTo.UsedContainment(FBaseTo)) then
          LError := 'STR_NO_ALIEN_CONTAINMENT_FOR_TRANSFER';
      end;
  end;
  if LError <> '' then
  begin
    FArrows.StopIncrease;
    ShowError(LError);
    Exit;
  end;
  LFreeQuarters := FCapacityTo.AvailableQuarters(FBaseTo) - FCapacityTo.UsedQuarters(FBaseTo) - FPersonnelQty;
  case LRow.Kind of
    tkSoldier, tkScientist, tkEngineer:
      begin
        AChange := Min(Min(LFreeQuarters, LRow.QtySrc - LRow.Amount), AChange);
        Inc(FPersonnelQty, AChange);
        LRow.Amount := LRow.Amount + AChange;
        FTotal := FTotal + Int64(LRow.Cost) * AChange;
      end;
    tkCraft:
      begin
        Inc(FCraftQty);
        Inc(FPersonnelQty, LCraft.NumSoldiers(FBaseFrom.Soldiers));
        FItemQty := FItemQty + CraftContentsSize(LCraft);
        Inc(LRow.Amount);
        if not IsAirborneTransferFree(LCraft) then
          FTotal := FTotal + LRow.Cost;
      end;
    tkItem:
      if not LItem.LiveAlien then
      begin
        LNeeded := LItem.Size;
        LFree := FCapacityTo.AvailableStores(FBaseTo) - FCapacityTo.UsedStores(FBaseTo) - FItemQty;
        LFreeForItemValue := MaxInt;
        if not SameValue(LNeeded, 0.0) then
          LFreeForItemValue := (LFree + 0.05) / LNeeded;
        LFreeForItem := Trunc(Min(LFreeForItemValue, MaxInt));
        AChange := Min(Min(LFreeForItem, LRow.QtySrc - LRow.Amount), AChange);
        FItemQty := FItemQty + AChange * LNeeded;
        LRow.Amount := LRow.Amount + AChange;
        FTotal := FTotal + Int64(LRow.Cost) * AChange;
      end
      else
      begin
        if LEnforced then
          LFreeContainment := FCapacityTo.AvailableContainment(FBaseTo) - FCapacityTo.UsedContainment(FBaseTo) -
            FAlienQty
        else
          LFreeContainment := MaxInt;
        AChange := Min(Min(LFreeContainment, LRow.QtySrc - LRow.Amount), AChange);
        Inc(FAlienQty, AChange);
        LRow.Amount := LRow.Amount + AChange;
        FTotal := FTotal + Int64(LRow.Cost) * AChange;
      end;
  end;
  FItems[LIndex] := LRow;
  UpdateItemStrings;
end;

procedure TXcomTransferItemsState.Decrease(AChange: Integer);
var
  LIndex: Integer;
  LRow: TXcomTransferRow;
  LCraft: TXcomCraft;
  LItem: TXcomRuleItem;
begin
  LIndex := FRows[FArrows.Selected];
  LRow := FItems[LIndex];
  if (AChange <= 0) or (LRow.Amount <= 0) then
    Exit;
  LCraft := nil;
  AChange := Min(LRow.Amount, AChange);
  case LRow.Kind of
    tkSoldier, tkScientist, tkEngineer:
      Dec(FPersonnelQty, AChange);
    tkCraft:
      begin
        LCraft := TXcomCraft(LRow.Rule);
        Dec(FCraftQty);
        Dec(FPersonnelQty, LCraft.NumSoldiers(FBaseFrom.Soldiers));
        FItemQty := FItemQty - CraftContentsSize(LCraft);
      end;
    tkItem:
      begin
        LItem := TXcomRuleItem(LRow.Rule);
        if not LItem.LiveAlien then
          FItemQty := FItemQty - LItem.Size * AChange
        else
          Dec(FAlienQty, AChange);
      end;
  end;
  LRow.Amount := LRow.Amount - AChange;
  FItems[LIndex] := LRow;
  if not IsAirborneTransferFree(LCraft) then
    FTotal := FTotal - Int64(LRow.Cost) * AChange;
  UpdateItemStrings;
end;

procedure TXcomTransferItemsState.UpdateItemStrings;
var
  LRow: TXcomTransferRow;
  LSelected: Integer;
begin
  LSelected := FArrows.Selected;
  LRow := FItems[FRows[LSelected]];
  FLstItems.SetCellText(LSelected, 1, IntToStr(LRow.QtySrc - LRow.Amount));
  FLstItems.SetCellText(LSelected, 2, IntToStr(LRow.Amount));
  if LRow.Amount > 0 then
    FLstItems.SetRowColor(LSelected, FLstItems.GetSecondaryColor)
  else
  begin
    FLstItems.SetRowColor(LSelected, FLstItems.GetColor);
    if IsAmmo(LRow) then
      FLstItems.SetRowColor(LSelected, FAmmoColor);
  end;
end;

end.
