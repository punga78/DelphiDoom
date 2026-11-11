{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - a craft takes its equipment again from  }
{  the stores after a mission (DebriefingState::reequipCraft)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.CraftReequipper;

interface

uses
  System.SysUtils, System.Generics.Collections, System.Math, DelphiDoom.XcomMod.Types, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Vehicle,
  DelphiDoom.XcomSave.ItemContainer, DelphiDoom.XcomSave.RulesetRules, DelphiDoom.XcomDebriefing.Types;

type
  /// <summary>
  ///   After a mission the items and the vehicles that the craft carried are taken from the stores of the base; what
  ///   the stores do not have is lost for the craft and goes in the list of the missing items. The vehicles are made
  ///   again so that their ammunition is redistributed (the vehicles that the craft had are freed: in a base
  ///   defense the C++ keeps them for the list of the base, which the saved game does not have)
  /// </summary>
  TXcomCraftReequipper = class
  strict private
    FRuleset: TXcomRuleset;
    FRules: TXcomRulesetRules;
    FOptions: TXcomDebriefingOptions;
    FMissing: TList<TXcomReequipStat>;
    procedure AddMissing(const AItem: string; AQuantity: Integer; const ACraft: TXcomCraft);
    procedure ReequipItems(const ABase: TXcomBase; const ACraft: TXcomCraft);
    procedure ReequipVehicles(const ABase: TXcomBase; const ACraft: TXcomCraft);
  public
    /// <param name="ARuleset">The ruleset (not owned)</param>
    /// <param name="ARules">The rules as the saved game sees them (not owned)</param>
    /// <param name="AMissing">The list of the missing items of the report (not owned)</param>
    constructor Create(const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
      const AOptions: TXcomDebriefingOptions; const AMissing: TList<TXcomReequipStat>);
    /// <summary>reequipCraft</summary>
    procedure Reequip(const ABase: TXcomBase; const ACraft: TXcomCraft);
  end;

implementation

{ TXcomCraftReequipper }

constructor TXcomCraftReequipper.Create(const ARuleset: TXcomRuleset; const ARules: TXcomRulesetRules;
  const AOptions: TXcomDebriefingOptions; const AMissing: TList<TXcomReequipStat>);
begin
  inherited Create;
  FRuleset := ARuleset;
  FRules := ARules;
  FOptions := AOptions;
  FMissing := AMissing;
end;

procedure TXcomCraftReequipper.AddMissing(const AItem: string; AQuantity: Integer; const ACraft: TXcomCraft);
var
  LStat: TXcomReequipStat;
begin
  LStat.Item := AItem;
  LStat.Quantity := AQuantity;
  LStat.CraftName := FOptions.CraftName(ACraft);
  FMissing.Add(LStat);
end;

procedure TXcomCraftReequipper.ReequipItems(const ABase: TXcomBase; const ACraft: TXcomCraft);
var
  LContents: TXcomStringMap<Integer>;
  LIndex: Integer;
  LName: string;
  LWanted: Integer;
  LQuantity: Integer;
begin
  // the loop works on a copy (a map by name, as std::map): the contents of the craft change
  LContents := ACraft.Items.Contents.Copy;
  try
    for LIndex := 0 to LContents.Count - 1 do
    begin
      LName := LContents.Key(LIndex);
      LWanted := LContents.Value(LIndex);
      LQuantity := ABase.StorageItems.GetItem(LName);
      if LQuantity >= LWanted then
        ABase.StorageItems.RemoveItem(LName, LWanted)
      else
      begin
        ABase.StorageItems.RemoveItem(LName, LQuantity);
        ACraft.Items.RemoveItem(LName, LWanted - LQuantity);
        AddMissing(LName, LWanted - LQuantity, ACraft);
      end;
    end;
  finally
    LContents.Free;
  end;
end;

procedure TXcomCraftReequipper.ReequipVehicles(const ABase: TXcomBase; const ACraft: TXcomCraft);
var
  LVehicles: TXcomItemContainer;
  LVehicle: TXcomVehicle;
  LName: string;
  LTankRule, LAmmo: TXcomRuleItem;
  LWanted, LQuantity, LSize, LCanBeAdded, LAmmoPerVehicle, LClipSize, LStored, LIndex, LVehicleIndex: Integer;
begin
  LVehicles := TXcomItemContainer.Create;
  try
    for LVehicle in ACraft.Vehicles do
      LVehicles.AddItem(LVehicle.Rules.ItemType);
    // the vehicles are made again, because their ammo is redistributed
    ACraft.Vehicles.Clear;
    for LVehicleIndex := 0 to LVehicles.Contents.Count - 1 do
    begin
      LName := LVehicles.Contents.Key(LVehicleIndex);
      LWanted := LVehicles.Contents.Value(LVehicleIndex);
      LQuantity := ABase.StorageItems.GetItem(LName);
      LTankRule := FRuleset.Items.Find(LName);
      LSize := 4;
      if Assigned(FRuleset.Units.Find(LTankRule.ItemType)) then
      begin
        LSize := FRuleset.Armors.Find(FRuleset.Units.Find(LTankRule.ItemType).Armor).Size;
        LSize := LSize * LSize;
      end;
      LCanBeAdded := Min(LQuantity, LWanted);
      if LQuantity < LWanted then
        AddMissing(LName, LWanted - LQuantity, ACraft);
      if Length(LTankRule.CompatibleAmmo) = 0 then
      begin
        // this tank does not need ammo
        for LIndex := 1 to LCanBeAdded do
          ACraft.Vehicles.Add(TXcomVehicle.Create(FRules.Item(LName), LTankRule.ClipSize, LSize));
        ABase.StorageItems.RemoveItem(LName, LCanBeAdded);
      end
      else
      begin
        LAmmo := FRuleset.Items.Find(LTankRule.CompatibleAmmo[0]);
        if (LAmmo.ClipSize > 0) and (LTankRule.ClipSize > 0) then
        begin
          LClipSize := LTankRule.ClipSize;
          LAmmoPerVehicle := LClipSize div LAmmo.ClipSize;
        end
        else
        begin
          LClipSize := LAmmo.ClipSize;
          LAmmoPerVehicle := LClipSize;
        end;
        LStored := ABase.StorageItems.GetItem(LAmmo.ItemType);
        if LStored < LWanted * LAmmoPerVehicle then
          AddMissing(LAmmo.ItemType, LWanted * LAmmoPerVehicle - LStored, ACraft);
        LCanBeAdded := Min(LCanBeAdded, LStored div LAmmoPerVehicle);
        if LCanBeAdded > 0 then
        begin
          for LIndex := 1 to LCanBeAdded do
          begin
            ACraft.Vehicles.Add(TXcomVehicle.Create(FRules.Item(LName), LClipSize, LSize));
            ABase.StorageItems.RemoveItem(LAmmo.ItemType, LAmmoPerVehicle);
          end;
          ABase.StorageItems.RemoveItem(LName, LCanBeAdded);
        end;
      end;
    end;
  finally
    LVehicles.Free;
  end;
end;

procedure TXcomCraftReequipper.Reequip(const ABase: TXcomBase; const ACraft: TXcomCraft);
begin
  ReequipItems(ABase, ACraft);
  ReequipVehicles(ABase, ACraft);
end;

end.
