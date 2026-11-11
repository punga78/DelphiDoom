{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - one hour of a production (Production::  }
{  step, startItem and the check of the materials)                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.ProductionStepper;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleItem,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomSave.Production, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomStrategy.BaseCrafts,
  DelphiDoom.XcomStrategy.Types;

type
  /// <summary>
  ///   The work that the engineers of a base do on a production in an hour: the time spent grows, the items that
  ///   are done reach the base (or are sold, or a craft is built) and the next unit starts if the funds and the
  ///   materials allow it (Production::step). The ruleset gives the rules of items and crafts
  /// </summary>
  TXcomProductionStepper = class
  strict private
    FRuleset: TXcomRuleset;
    function HaveEnoughMaterialsForOneMoreUnit(const AProduction: TXcomProduction; const ABase: TXcomBase): Boolean;
    procedure Deliver(const AProduction: TXcomProduction; const ABase: TXcomBase; const AGame: TXcomSavedGame);
  public
    /// <param name="ARuleset">The ruleset of the game (not owned)</param>
    constructor Create(const ARuleset: TXcomRuleset);
    /// <summary>startItem: a unit starts: its cost leaves the funds and its materials leave the base (crafts included)</summary>
    procedure StartItem(const AProduction: TXcomProduction; const ABase: TXcomBase; const AGame: TXcomSavedGame);
    /// <summary>
    ///   step: ppComplete when the amount is reached, ppNotEnoughMoney or ppNotEnoughMaterials when a unit
    ///   that is due cannot start. The item of a production that the ruleset does not know is
    ///   EXcomStrategyException (Mod::getItem with error)
    /// </summary>
    function Step(const AProduction: TXcomProduction; const ABase: TXcomBase; const AGame: TXcomSavedGame)
      : TXcomProductionProgress;
  end;

implementation

const
  SUnknownItem = 'Item %s not found';
  SUnknownCraft = 'Craft %s not found';

{ TXcomProductionStepper }

constructor TXcomProductionStepper.Create(const ARuleset: TXcomRuleset);
begin
  inherited Create;
  if not Assigned(ARuleset) then
    raise EArgumentNilException.Create('ARuleset');
  FRuleset := ARuleset;
end;

function TXcomProductionStepper.HaveEnoughMaterialsForOneMoreUnit(const AProduction: TXcomProduction;
  const ABase: TXcomBase): Boolean;
var
  LIndex: Integer;
  LName: string;
  LRequired: Integer;
begin
  Result := True;
  for LIndex := 0 to AProduction.Rules.RequiredItems.Count - 1 do
  begin
    LName := AProduction.Rules.RequiredItems.Key(LIndex);
    LRequired := AProduction.Rules.RequiredItems.Value(LIndex);
    if Assigned(FRuleset.Items.Find(LName)) and (ABase.StorageItems.GetItem(LName) < LRequired) then
      Exit(False)
    else if not Assigned(FRuleset.Items.Find(LName)) and Assigned(FRuleset.Crafts.Find(LName)) and
      (TXcomBaseCrafts.Count(ABase, LName) < LRequired) then
      Exit(False);
  end;
end;

procedure TXcomProductionStepper.StartItem(const AProduction: TXcomProduction; const ABase: TXcomBase;
  const AGame: TXcomSavedGame);
var
  LIndex, LCraftIndex: Integer;
  LName: string;
  LCraft: TXcomCraft;
begin
  AGame.SetFunds(AGame.Funds - AProduction.Rules.ManufactureCost);
  for LIndex := 0 to AProduction.Rules.RequiredItems.Count - 1 do
  begin
    LName := AProduction.Rules.RequiredItems.Key(LIndex);
    if Assigned(FRuleset.Items.Find(LName)) then
      ABase.StorageItems.RemoveItem(LName, AProduction.Rules.RequiredItems.Value(LIndex))
    else if Assigned(FRuleset.Crafts.Find(LName)) then
    begin
      // the first suitable craft of the base is dismantled
      for LCraftIndex := 0 to ABase.Crafts.Count - 1 do
        if ABase.Crafts[LCraftIndex].Rules.CraftType = LName then
        begin
          LCraft := TXcomBaseCrafts.Remove(ABase, ABase.Crafts[LCraftIndex], True, FRuleset);
          LCraft.Free;
          Break;
        end;
    end;
  end;
end;

procedure TXcomProductionStepper.Deliver(const AProduction: TXcomProduction; const ABase: TXcomBase;
  const AGame: TXcomSavedGame);
var
  LIndex, LCraftIndex: Integer;
  LName: string;
  LCraft: TXcomCraft;
  LItem: TXcomRuleItem;
begin
  for LIndex := 0 to AProduction.Rules.ProducedItems.Count - 1 do
  begin
    LName := AProduction.Rules.ProducedItems.Key(LIndex);
    if AProduction.Rules.Category = 'STR_CRAFT' then
    begin
      if not Assigned(FRuleset.Crafts.Find(LName)) then
        raise EXcomStrategyException.CreateFmt(SUnknownCraft, [LName]);
      LCraft := TXcomCraft.Create(FRuleset.Crafts.Find(LName), ABase, AGame.GetId(LName));
      LCraft.Status := 'STR_REFUELLING';
      ABase.Crafts.Add(LCraft);
      // only the first produced item of a craft
      Break;
    end;
    LItem := FRuleset.Items.Find(LName);
    if not Assigned(LItem) then
      raise EXcomStrategyException.CreateFmt(SUnknownItem, [LName]);
    if LItem.BattleType = TXcomRuleItem.BT_NONE then
      for LCraftIndex := 0 to ABase.Crafts.Count - 1 do
        ABase.Crafts[LCraftIndex].ReuseItem(LName, FRuleset);
    if AProduction.SellItems then
      AGame.SetFunds(AGame.Funds + LItem.SellCost * AProduction.Rules.ProducedItems.Value(LIndex))
    else
      ABase.StorageItems.AddItem(LName, AProduction.Rules.ProducedItems.Value(LIndex));
  end;
end;

function TXcomProductionStepper.Step(const AProduction: TXcomProduction; const ABase: TXcomBase;
  const AGame: TXcomSavedGame): TXcomProductionProgress;
var
  LDone, LProduced, LCount: Integer;
begin
  LDone := AProduction.AmountProduced;
  AProduction.TimeSpent := AProduction.TimeSpent + AProduction.AssignedEngineers;
  if LDone < AProduction.AmountProduced then
  begin
    if not AProduction.InfiniteAmount then
      // not more than the amount: nothing is overproduced
      LProduced := Min(AProduction.AmountProduced, AProduction.AmountTotal) - LDone
    else
      LProduced := AProduction.AmountProduced - LDone;
    LCount := 0;
    repeat
      Deliver(AProduction, ABase, AGame);
      Inc(LCount);
      if LCount < LProduced then
      begin
        // there must be money and materials for one more unit
        if not AProduction.HaveEnoughMoneyForOneMoreUnit(AGame.Funds) then
          Exit(ppNotEnoughMoney);
        if not HaveEnoughMaterialsForOneMoreUnit(AProduction, ABase) then
          Exit(ppNotEnoughMaterials);
        StartItem(AProduction, ABase, AGame);
      end;
    until LCount >= LProduced;
  end;
  if (AProduction.AmountProduced >= AProduction.AmountTotal) and not AProduction.InfiniteAmount then
    Exit(ppComplete);
  if LDone < AProduction.AmountProduced then
  begin
    if not AProduction.HaveEnoughMoneyForOneMoreUnit(AGame.Funds) then
      Exit(ppNotEnoughMoney);
    if not HaveEnoughMaterialsForOneMoreUnit(AProduction, ABase) then
      Exit(ppNotEnoughMaterials);
    StartItem(AProduction, ABase, AGame);
  end;
  Result := ppNotComplete;
end;

end.
