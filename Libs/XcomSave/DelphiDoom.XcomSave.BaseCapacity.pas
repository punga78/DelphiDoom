{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - what a base can hold and costs         }
{  (Base::getAvailableXxx, getUsedXxx and the maintenance of OpenXcom)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.BaseCapacity;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomSave.SavedGame;

type
  /// <summary>What a transfer carries (Transfer::getType)</summary>
  TXcomTransferKind = (tkItem, tkCraft, tkSoldier, tkScientist, tkEngineer);

  /// <summary>
  ///   The capacities, the use and the maintenance of a base, computed from its facilities, people, stores and
  ///   transfers with the rules of the ruleset (the ruleset is not owned). The functions are the ones of Base of
  ///   OpenXcom with the same names and results; they do not change the base. The floating point steps are rounded to
  ///   a double as the C++ does with SSE
  /// </summary>
  TXcomBaseCapacity = class
  strict private
    FRuleset: TXcomRuleset;
    function FacilityRule(const AType: string): TXcomRuleBaseFacility;
    function ItemSize(const AType: string): Double;
    function BuiltRules(ABase: TXcomBase): TArray<TXcomRuleBaseFacility>;
  public
    constructor Create(ARuleset: TXcomRuleset);
    /// <summary>Transfer::getType</summary>
    class function KindOf(ATransfer: TXcomTransfer): TXcomTransferKind; static;
    /// <summary>Transfer::getQuantity</summary>
    class function QuantityOf(ATransfer: TXcomTransfer): Integer; static;
    function TotalSoldiers(ABase: TXcomBase): Integer;
    /// <summary>getSoldierCount: the soldiers of the type, those that are being transferred included</summary>
    function SoldierCount(ABase: TXcomBase; const ASoldierType: string): Integer;
    function AvailableScientists(ABase: TXcomBase): Integer;
    function TotalScientists(ABase: TXcomBase): Integer;
    function AvailableEngineers(ABase: TXcomBase): Integer;
    function TotalEngineers(ABase: TXcomBase): Integer;
    function UsedQuarters(ABase: TXcomBase): Integer;
    function AvailableQuarters(ABase: TXcomBase): Integer;
    function UsedStores(ABase: TXcomBase): Double;
    function IgnoredStores(ABase: TXcomBase): Double;
    function AvailableStores(ABase: TXcomBase): Integer;
    /// <summary>storesOverfull: the stores plus the offset, cut to hundredths, are more than the capacity</summary>
    function StoresOverfull(ABase: TXcomBase; AOffset: Double): Boolean;
    function UsedLaboratories(ABase: TXcomBase): Integer;
    function AvailableLaboratories(ABase: TXcomBase): Integer;
    function FreeLaboratories(ABase: TXcomBase): Integer;
    function UsedWorkshops(ABase: TXcomBase): Integer;
    function AvailableWorkshops(ABase: TXcomBase): Integer;
    function FreeWorkshops(ABase: TXcomBase): Integer;
    function UsedHangars(ABase: TXcomBase): Integer;
    function AvailableHangars(ABase: TXcomBase): Integer;
    function UsedPsiLabs(ABase: TXcomBase): Integer;
    function AvailablePsiLabs(ABase: TXcomBase): Integer;
    function UsedContainment(ABase: TXcomBase): Integer;
    function AvailableContainment(ABase: TXcomBase): Integer;
    function DefenseValue(ABase: TXcomBase): Integer;
    function GravShields(ABase: TXcomBase): Integer;
    /// <summary>getDetectionChance: the percentage that an alien detects the base</summary>
    function DetectionChance(ABase: TXcomBase): Integer;
    function CraftMaintenance(ABase: TXcomBase): Integer;
    function PersonnelMaintenance(ABase: TXcomBase): Integer;
    function FacilityMaintenance(ABase: TXcomBase): Integer;
    function MonthlyMaintenance(ABase: TXcomBase): Integer;
    /// <summary>SavedGame::getBaseMaintenance: the maintenance of all the bases</summary>
    function BaseMaintenance(ASave: TXcomSavedGame): Int64;
  end;

implementation

uses
  DelphiDoom.XcomMod.Types, DelphiDoom.XcomSave.Types, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.CraftWeapon, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.Production,
  DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomSave.Vehicle, DelphiDoom.XcomSave.FloatMode,
  DelphiDoom.XcomMod.RuleCraft, DelphiDoom.XcomMod.RuleCraftWeapon, DelphiDoom.XcomMod.RuleSoldier,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomMod.RuleResearch;

resourcestring
  SXcomNoFacilityRule = 'Xcom: the ruleset has no facility %s';
  SXcomNoItemRule = 'Xcom: the ruleset has no item %s';

constructor TXcomBaseCapacity.Create(ARuleset: TXcomRuleset);
begin
  inherited Create;
  FRuleset := ARuleset;
end;

function TXcomBaseCapacity.FacilityRule(const AType: string): TXcomRuleBaseFacility;
begin
  Result := FRuleset.Facilities.Find(AType);
  if not Assigned(Result) then
    raise EXcomSaveException.CreateFmt(SXcomNoFacilityRule, [AType]);
end;

function TXcomBaseCapacity.ItemSize(const AType: string): Double;
var
  LRule: TXcomRuleItem;
begin
  LRule := FRuleset.Items.Find(AType);
  if not Assigned(LRule) then
    raise EXcomSaveException.CreateFmt(SXcomNoItemRule, [AType]);
  Result := LRule.Size;
end;

function TXcomBaseCapacity.BuiltRules(ABase: TXcomBase): TArray<TXcomRuleBaseFacility>;
var
  LFacility: TXcomBaseFacility;
begin
  Result := nil;
  for LFacility in ABase.Facilities do
    if LFacility.BuildTime = 0 then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FacilityRule(LFacility.Rules.FacilityType);
    end;
end;

class function TXcomBaseCapacity.KindOf(ATransfer: TXcomTransfer): TXcomTransferKind;
begin
  if Assigned(ATransfer.Soldier) then
    Result := tkSoldier
  else if Assigned(ATransfer.Craft) then
    Result := tkCraft
  else if ATransfer.Scientists <> 0 then
    Result := tkScientist
  else if ATransfer.Engineers <> 0 then
    Result := tkEngineer
  else
    Result := tkItem;
end;

class function TXcomBaseCapacity.QuantityOf(ATransfer: TXcomTransfer): Integer;
begin
  if ATransfer.ItemQty <> 0 then
    Result := ATransfer.ItemQty
  else if ATransfer.Scientists <> 0 then
    Result := ATransfer.Scientists
  else if ATransfer.Engineers <> 0 then
    Result := ATransfer.Engineers
  else
    Result := 1;
end;

function TXcomBaseCapacity.TotalSoldiers(ABase: TXcomBase): Integer;
var
  LTransfer: TXcomTransfer;
begin
  Result := ABase.Soldiers.Count;
  for LTransfer in ABase.Transfers do
    if KindOf(LTransfer) = tkSoldier then
      Inc(Result, QuantityOf(LTransfer));
end;

function TXcomBaseCapacity.SoldierCount(ABase: TXcomBase; const ASoldierType: string): Integer;
var
  LTransfer: TXcomTransfer;
  LSoldier: TXcomSoldier;
begin
  Result := 0;
  for LTransfer in ABase.Transfers do
    if (KindOf(LTransfer) = tkSoldier) and (LTransfer.Soldier.Rules.SoldierType = ASoldierType) then
      Inc(Result);
  for LSoldier in ABase.Soldiers do
    if LSoldier.Rules.SoldierType = ASoldierType then
      Inc(Result);
end;

function TXcomBaseCapacity.AvailableScientists(ABase: TXcomBase): Integer;
begin
  Result := ABase.Scientists;
end;

function TXcomBaseCapacity.TotalScientists(ABase: TXcomBase): Integer;
var
  LTransfer: TXcomTransfer;
  LProject: TXcomResearchProject;
begin
  Result := ABase.Scientists;
  for LTransfer in ABase.Transfers do
    if KindOf(LTransfer) = tkScientist then
      Inc(Result, QuantityOf(LTransfer));
  for LProject in ABase.Research do
    Inc(Result, LProject.Assigned);
end;

function TXcomBaseCapacity.AvailableEngineers(ABase: TXcomBase): Integer;
begin
  Result := ABase.Engineers;
end;

function TXcomBaseCapacity.TotalEngineers(ABase: TXcomBase): Integer;
var
  LTransfer: TXcomTransfer;
  LProduction: TXcomProduction;
begin
  Result := ABase.Engineers;
  for LTransfer in ABase.Transfers do
    if KindOf(LTransfer) = tkEngineer then
      Inc(Result, QuantityOf(LTransfer));
  for LProduction in ABase.Productions do
    Inc(Result, LProduction.AssignedEngineers);
end;

function TXcomBaseCapacity.UsedQuarters(ABase: TXcomBase): Integer;
begin
  Result := TotalSoldiers(ABase) + TotalScientists(ABase) + TotalEngineers(ABase);
end;

function TXcomBaseCapacity.AvailableQuarters(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.Personnel);
end;

function TXcomBaseCapacity.UsedStores(ABase: TXcomBase): Double;
var
  LCraft: TXcomCraft;
  LVehicle: TXcomVehicle;
  LTransfer: TXcomTransfer;
  LTotal, LPart: Double;
  LMode: TXcomFloatMode;

  function ContainerSize(const AContents: TXcomStringMap<Integer>): Double;
  var
    LEntry: Integer;
    LSize: Double;
  begin
    Result := 0;
    for LEntry := 0 to AContents.Count - 1 do
    begin
      LSize := ItemSize(AContents.Key(LEntry));
      LSize := LSize * AContents.Value(LEntry);
      Result := Result + LSize;
    end;
  end;

begin
  LMode := TXcomFloatMode.Enter;
  try
    LTotal := ContainerSize(ABase.StorageItems.Contents);
    for LCraft in ABase.Crafts do
    begin
      LTotal := LTotal + ContainerSize(LCraft.Items.Contents);
      for LVehicle in LCraft.Vehicles do
        LTotal := LTotal + ItemSize(LVehicle.Rules.ItemType);
    end;
    for LTransfer in ABase.Transfers do
      case KindOf(LTransfer) of
        tkItem:
          begin
            LPart := ItemSize(LTransfer.ItemId);
            LPart := LPart * QuantityOf(LTransfer);
            LTotal := LTotal + LPart;
          end;
        tkCraft:
          LTotal := LTotal + ContainerSize(LTransfer.Craft.Items.Contents);
      end;
    Result := LTotal - IgnoredStores(ABase);
  finally
    LMode.Leave;
  end;
end;

function TXcomBaseCapacity.IgnoredStores(ABase: TXcomBase): Double;
var
  LCraft: TXcomCraft;
  LWeapon: TXcomCraftWeapon;
  LClip: string;
  LAvailable, LClipSize, LNeeded: Integer;
  LRule: TXcomRuleCraftWeapon;
  LItem: TXcomRuleItem;
  LPart: Double;
  LMode: TXcomFloatMode;
begin
  LMode := TXcomFloatMode.Enter;
  try
    Result := 0;
    for LCraft in ABase.Crafts do
      if LCraft.Status = 'STR_REARMING' then
        for LWeapon in LCraft.Weapons do
          if Assigned(LWeapon) and LWeapon.Rearming then
          begin
            LRule := FRuleset.CraftWeapons.Find(LWeapon.Rules.WeaponType);
            LClip := LRule.ClipItem;
            LAvailable := ABase.StorageItems.GetItem(LClip);
            if (LClip <> '') and (LAvailable > 0) then
            begin
              LItem := FRuleset.Items.Find(LClip);
              LClipSize := LItem.ClipSize;
              LNeeded := 0;
              if LClipSize > 0 then
                LNeeded := (LRule.AmmoMax - LWeapon.Ammo) div LClipSize;
              LPart := LItem.Size;
              LPart := LPart * Min(LAvailable, LNeeded);
              Result := Result + LPart;
            end;
          end;
  finally
    LMode.Leave;
  end;
end;

function TXcomBaseCapacity.AvailableStores(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.Storage);
end;

function TXcomBaseCapacity.StoresOverfull(ABase: TXcomBase; AOffset: Double): Boolean;
var
  LCapacity: Integer;
  LUsed: Double;
begin
  LCapacity := AvailableStores(ABase) * 100;
  LUsed := (UsedStores(ABase) + AOffset) * 100;
  Result := Trunc(LUsed) > LCapacity;
end;

function TXcomBaseCapacity.UsedLaboratories(ABase: TXcomBase): Integer;
var
  LProject: TXcomResearchProject;
begin
  Result := 0;
  for LProject in ABase.Research do
    Inc(Result, LProject.Assigned);
end;

function TXcomBaseCapacity.AvailableLaboratories(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.Laboratories);
end;

function TXcomBaseCapacity.FreeLaboratories(ABase: TXcomBase): Integer;
begin
  Result := AvailableLaboratories(ABase) - UsedLaboratories(ABase);
end;

function TXcomBaseCapacity.UsedWorkshops(ABase: TXcomBase): Integer;
var
  LProduction: TXcomProduction;
begin
  Result := 0;
  for LProduction in ABase.Productions do
    Inc(Result, LProduction.AssignedEngineers + LProduction.Rules.RequiredSpace);
end;

function TXcomBaseCapacity.AvailableWorkshops(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.Workshops);
end;

function TXcomBaseCapacity.FreeWorkshops(ABase: TXcomBase): Integer;
begin
  Result := AvailableWorkshops(ABase) - UsedWorkshops(ABase);
end;

function TXcomBaseCapacity.UsedHangars(ABase: TXcomBase): Integer;
var
  LTransfer: TXcomTransfer;
  LProduction: TXcomProduction;
begin
  Result := ABase.Crafts.Count;
  for LTransfer in ABase.Transfers do
    if KindOf(LTransfer) = tkCraft then
      Inc(Result, QuantityOf(LTransfer));
  for LProduction in ABase.Productions do
    if LProduction.Rules.Category = 'STR_CRAFT' then
      Inc(Result, LProduction.AmountTotal - LProduction.AmountProduced);
end;

function TXcomBaseCapacity.AvailableHangars(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.Crafts);
end;

function TXcomBaseCapacity.UsedPsiLabs(ABase: TXcomBase): Integer;
var
  LSoldier: TXcomSoldier;
begin
  Result := 0;
  for LSoldier in ABase.Soldiers do
    if LSoldier.PsiTraining then
      Inc(Result);
end;

function TXcomBaseCapacity.AvailablePsiLabs(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.PsiLaboratories);
end;

function TXcomBaseCapacity.UsedContainment(ABase: TXcomBase): Integer;
var
  LIndex: Integer;
  LTransfer: TXcomTransfer;
  LProject: TXcomResearchProject;
begin
  Result := 0;
  for LIndex := 0 to ABase.StorageItems.Contents.Count - 1 do
    if FRuleset.Items.Find(ABase.StorageItems.Contents.Key(LIndex)).LiveAlien then
      Inc(Result, ABase.StorageItems.Contents.Value(LIndex));
  for LTransfer in ABase.Transfers do
    if (KindOf(LTransfer) = tkItem) and FRuleset.Items.Find(LTransfer.ItemId).LiveAlien then
      Inc(Result, QuantityOf(LTransfer));
  for LProject in ABase.Research do
    if LProject.Rules.NeedItem and (FRuleset.Units.Find(LProject.Rules.Name) <> nil) then
      Inc(Result);
end;

function TXcomBaseCapacity.AvailableContainment(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.Aliens);
end;

function TXcomBaseCapacity.DefenseValue(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.DefenseValue);
end;

function TXcomBaseCapacity.GravShields(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    if LRule.IsGravShield then
      Inc(Result);
end;

function TXcomBaseCapacity.DetectionChance(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
  LMindShields, LCompleted: Cardinal;
begin
  LMindShields := 0;
  LCompleted := 0;
  for LRule in BuiltRules(ABase) do
  begin
    if LRule.IsMindShield then
      Inc(LMindShields);
    Inc(LCompleted, Cardinal(LRule.Size * LRule.Size));
  end;
  Result := Integer((LCompleted div 6 + 15) div (LMindShields + 1));
end;

function TXcomBaseCapacity.CraftMaintenance(ABase: TXcomBase): Integer;
var
  LTransfer: TXcomTransfer;
  LCraft: TXcomCraft;
begin
  Result := 0;
  for LTransfer in ABase.Transfers do
    if KindOf(LTransfer) = tkCraft then
      Inc(Result, LTransfer.Craft.Rules.RentCost);
  for LCraft in ABase.Crafts do
    Inc(Result, LCraft.Rules.RentCost);
end;

function TXcomBaseCapacity.PersonnelMaintenance(ABase: TXcomBase): Integer;
var
  LTransfer: TXcomTransfer;
  LSoldier: TXcomSoldier;
begin
  Result := 0;
  for LTransfer in ABase.Transfers do
    if KindOf(LTransfer) = tkSoldier then
      Inc(Result, LTransfer.Soldier.Rules.SalaryCost);
  for LSoldier in ABase.Soldiers do
    Inc(Result, LSoldier.Rules.SalaryCost);
  Inc(Result, TotalEngineers(ABase) * FRuleset.Settings.CostEngineer);
  Inc(Result, TotalScientists(ABase) * FRuleset.Settings.CostScientist);
end;

function TXcomBaseCapacity.FacilityMaintenance(ABase: TXcomBase): Integer;
var
  LRule: TXcomRuleBaseFacility;
begin
  Result := 0;
  for LRule in BuiltRules(ABase) do
    Inc(Result, LRule.MonthlyCost);
end;

function TXcomBaseCapacity.MonthlyMaintenance(ABase: TXcomBase): Integer;
begin
  Result := CraftMaintenance(ABase) + PersonnelMaintenance(ABase) + FacilityMaintenance(ABase);
end;

function TXcomBaseCapacity.BaseMaintenance(ASave: TXcomSavedGame): Int64;
var
  LBase: TXcomBase;
begin
  Result := 0;
  for LBase in ASave.Bases do
    Inc(Result, MonthlyMaintenance(LBase));
end;

end.
