{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - put the items on the units           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.ItemEquipper;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.RuleInventory, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.InventoryRules;

type
  /// <summary>
  ///   The placing of an item on a unit (the static _addItem of BattlescapeGenerator) and the auto-equip of the
  ///   soldiers from the craft inventory
  /// </summary>
  TXcomItemEquipper = class
  strict private
    FRuleset: TXcomRuleset;
    FSave: TXcomSavedBattleGame;
    FAllowAutoLoadout: Boolean;
  public
    /// <param name="ASave">The saved battle that gets the placed items (addToSave of the C++); nil adds nothing</param>
    constructor Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame;
      AAllowAutoLoadout: Boolean);
    /// <summary>The inventory section AName; raises EXcomBattleException if the mod does not have it</summary>
    function Inventory(const AName: string): TXcomRuleInventory;
    /// <summary>_addItem: true if the item is now on the unit (the caller frees it otherwise)</summary>
    function AddItem(const AItem: TXcomBattleItem; const AUnit: TXcomBattleUnit; AAllowSecondClip: Boolean = False)
      : Boolean;
    /// <summary>
    ///   autoEquip: the items of ACraftInventory that are on the ground go to the soldiers that have no equipment
    ///   layout (rifles, pistols, ammunition, the rest); what is left on the ground goes to the saved battle
    /// </summary>
    procedure AutoEquip(const AUnits: TArray<TXcomBattleUnit>; const ACraftInventory: TList<TXcomBattleItem>;
      const AGround: TXcomRuleInventory; AWorldShade: Integer; AOverrideEquipmentLayout: Boolean);
  end;

implementation

const
  SInventoryNotFound = 'Inventory %s not found.';
  /// <summary>TileEngine::MAX_DARKNESS_TO_SEE_UNITS</summary>
  MAX_DARKNESS_TO_SEE_UNITS = 9;

constructor TXcomItemEquipper.Create(const ARuleset: TXcomRuleset; const ASave: TXcomSavedBattleGame;
  AAllowAutoLoadout: Boolean);
begin
  inherited Create;
  FRuleset := ARuleset;
  FSave := ASave;
  FAllowAutoLoadout := AAllowAutoLoadout;
end;

function TXcomItemEquipper.Inventory(const AName: string): TXcomRuleInventory;
begin
  Result := FRuleset.Inventories.Find(AName);
  if not Assigned(Result) then
    raise EXcomBattleException.CreateFmt(SInventoryNotFound, [AName]);
end;

function TXcomItemEquipper.AddItem(const AItem: TXcomBattleItem; const AUnit: TXcomBattleUnit;
  AAllowSecondClip: Boolean): Boolean;
var
  LRightHand: TXcomRuleInventory;
  LLeftHand: TXcomRuleInventory;
  LPlaced: Boolean;
  LLoaded: Boolean;
  LRightWeapon: TXcomBattleItem;
  LLeftWeapon: TXcomBattleItem;
  LWeight: Integer;
  LTally: Integer;
  LOther: TXcomBattleItem;
  LKeep: Boolean;
  LFallThrough: Boolean;
  LName: string;
  LAmmoName: string;
  LSlot: TXcomRuleInventory;
  LCell: TXcomRuleSlot;
begin
  LRightHand := Inventory('STR_RIGHT_HAND');
  LLeftHand := Inventory('STR_LEFT_HAND');
  LPlaced := False;
  LLoaded := False;
  LRightWeapon := AUnit.GetItem('STR_RIGHT_HAND');
  LLeftWeapon := AUnit.GetItem('STR_LEFT_HAND');
  LWeight := 0;
  if (AUnit.Faction = FACTION_PLAYER) and AUnit.HasInventory then
  begin
    LWeight := AUnit.GetCarriedWeight + AItem.Rules.Weight;
    if Assigned(AItem.AmmoItem) and (AItem.AmmoItem <> AItem) then
      Inc(LWeight, AItem.AmmoItem.Rules.Weight);
    if Length(AItem.Rules.CompatibleAmmo) = 0 then
    begin
      LTally := 0;
      for LOther in AUnit.Inventory do
      begin
        if AItem.Rules.ItemType = LOther.Rules.ItemType then
        begin
          if AAllowSecondClip and (AItem.Rules.BattleType = TXcomRuleItem.BT_AMMO) then
          begin
            Inc(LTally);
            if LTally = 2 then
              Exit(False);
          end
          else
            Exit(False);
        end;
      end;
    end;
  end;
  if AItem.Rules.FixedWeapon then
  begin
    if (not Assigned(LRightWeapon)) or (not Assigned(LLeftWeapon)) then
    begin
      AItem.MoveToOwner(AUnit);
      if not Assigned(LRightWeapon) then
        AItem.Slot := LRightHand
      else
        AItem.Slot := LLeftHand;
      LPlaced := True;
      if Assigned(FSave) then
        FSave.Items.Add(AItem);
      AItem.XcomProperty := AUnit.Faction = FACTION_PLAYER;
    end;
    Exit(LPlaced);
  end;
  LFallThrough := False;
  case AItem.Rules.BattleType of
    TXcomRuleItem.BT_FIREARM, TXcomRuleItem.BT_MELEE:
      begin
        if Assigned(AItem.AmmoItem) or (AUnit.Faction <> FACTION_PLAYER) or (not AUnit.HasInventory) then
          LLoaded := True;
        if LLoaded and ((not Assigned(AUnit.GeoscapeSoldier)) or FAllowAutoLoadout) then
        begin
          if (not Assigned(LRightWeapon)) and (AUnit.Stats.Strength * 0.66 >= LWeight) then
          begin
            AItem.MoveToOwner(AUnit);
            AItem.Slot := LRightHand;
            LPlaced := True;
          end
          else if (not Assigned(LLeftWeapon)) and (AUnit.Faction <> FACTION_PLAYER) then
          begin
            AItem.MoveToOwner(AUnit);
            AItem.Slot := LLeftHand;
            LPlaced := True;
          end;
        end;
      end;
    TXcomRuleItem.BT_AMMO:
      begin
        if Assigned(LRightWeapon) and (LRightWeapon.Rules.FixedWeapon or (AUnit.Faction <> FACTION_PLAYER)) and
          (Length(LRightWeapon.Rules.CompatibleAmmo) > 0) and (not Assigned(LRightWeapon.AmmoItem)) and
          (LRightWeapon.SetAmmoItem(AItem) = 0) then
        begin
          AItem.Slot := LRightHand;
          LPlaced := True;
        end
        else if Assigned(LLeftWeapon) and (LLeftWeapon.Rules.FixedWeapon or (AUnit.Faction <> FACTION_PLAYER)) and
          (Length(LLeftWeapon.Rules.CompatibleAmmo) > 0) and (not Assigned(LLeftWeapon.AmmoItem)) and
          (LLeftWeapon.SetAmmoItem(AItem) = 0) then
        begin
          AItem.Slot := LLeftHand;
          LPlaced := True;
        end
        else
        begin
          LKeep := AUnit.Faction <> FACTION_PLAYER;
          LName := AItem.Rules.ItemType;
          if Assigned(LRightWeapon) then
            for LAmmoName in LRightWeapon.Rules.CompatibleAmmo do
              if LAmmoName = LName then
              begin
                LKeep := True;
                Break;
              end;
          if Assigned(LLeftWeapon) then
            for LAmmoName in LLeftWeapon.Rules.CompatibleAmmo do
              if LAmmoName = LName then
              begin
                LKeep := True;
                Break;
              end;
          // the C++ falls into the default branch unless the clip is not kept
          LFallThrough := LKeep;
        end;
      end;
  else
    LFallThrough := True;
  end;
  if LFallThrough and ((not Assigned(AUnit.GeoscapeSoldier)) or FAllowAutoLoadout) and
    (AUnit.Stats.Strength >= LWeight) then
  begin
    for LName in FRuleset.Inventories.Index do
    begin
      if LPlaced then
        Break;
      LSlot := FRuleset.Inventories.Find(LName);
      if LSlot.InventoryType = INV_SLOT then
      begin
        for LCell in LSlot.Slots do
        begin
          if LPlaced then
            Break;
          if (not TXcomInventoryRules.OverlapItems(AUnit, AItem, LSlot, LCell.X, LCell.Y)) and
            LSlot.FitItemInSlot(AItem.Rules.InventoryWidth, AItem.Rules.InventoryHeight, LCell.X, LCell.Y) then
          begin
            AItem.MoveToOwner(AUnit);
            AItem.Slot := LSlot;
            AItem.SlotX := LCell.X;
            AItem.SlotY := LCell.Y;
            LPlaced := True;
          end;
        end;
      end;
    end;
  end;
  if LPlaced and Assigned(FSave) then
    FSave.Items.Add(AItem);
  AItem.XcomProperty := AUnit.Faction = FACTION_PLAYER;
  Result := LPlaced;
end;

procedure TXcomItemEquipper.AutoEquip(const AUnits: TArray<TXcomBattleUnit>;
  const ACraftInventory: TList<TXcomBattleItem>; const AGround: TXcomRuleInventory; AWorldShade: Integer;
  AOverrideEquipmentLayout: Boolean);
var
  LPass: Integer;
  LIndex: Integer;
  LItem: TXcomBattleItem;
  LAdd: Boolean;
  LUnit: TXcomBattleUnit;
begin
  for LPass := 0 to 3 do
  begin
    LIndex := 0;
    while LIndex < ACraftInventory.Count do
    begin
      LItem := ACraftInventory[LIndex];
      if LItem.Slot = AGround then
      begin
        LAdd := False;
        case LPass of
          0: LAdd := LItem.Rules.IsRifle;
          1: LAdd := LItem.Rules.IsPistol;
          2: LAdd := LItem.Rules.BattleType = TXcomRuleItem.BT_AMMO;
          3: LAdd := (not LItem.Rules.IsPistol) and (not LItem.Rules.IsRifle) and
            ((LItem.Rules.BattleType <> TXcomRuleItem.BT_FLARE) or (AWorldShade > MAX_DARKNESS_TO_SEE_UNITS));
        end;
        if LAdd then
        begin
          for LUnit in AUnits do
          begin
            if (not LUnit.HasInventory) or (not Assigned(LUnit.GeoscapeSoldier)) or
              ((not AOverrideEquipmentLayout) and (LUnit.GeoscapeSoldier.EquipmentLayout.Count > 0)) then
              Continue;
            if AddItem(LItem, LUnit, LPass = 3) then
            begin
              ACraftInventory.Delete(LIndex);
              LAdd := False;
              Break;
            end;
          end;
          if not LAdd then
            Continue;
        end;
      end;
      Inc(LIndex);
    end;
  end;
  LIndex := 0;
  while LIndex < ACraftInventory.Count do
  begin
    LItem := ACraftInventory[LIndex];
    if LItem.Slot <> AGround then
      ACraftInventory.Delete(LIndex)
    else
    begin
      if Assigned(FSave) then
        FSave.Items.Add(LItem);
      Inc(LIndex);
    end;
  end;
end;

end.
