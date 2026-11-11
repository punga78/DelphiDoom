{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the work of the bases as the time goes  }
{  on: transfers, productions, constructions, research, wounds and psionic     }
{  training (the base parts of GeoscapeState::time1Hour and time1Day)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.BaseWork;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.Random,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.Transfer,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Production,
  DelphiDoom.XcomSave.ResearchProject, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.MissionSite,
  DelphiDoom.XcomSave.Settings.Intf, DelphiDoom.XcomStrategy.Types, DelphiDoom.XcomStrategy.Events.Intf,
  DelphiDoom.XcomStrategy.Settings.Intf, DelphiDoom.XcomStrategy.ProductionStepper;

type
  /// <summary>
  ///   What the bases do by themselves: every hour the transfers move, the productions go on and a new mission
  ///   site is announced; every day the facilities are built, the research advances and the wounded heal.
  ///   Research that is finished is taken off the base and announced; the discoveries that follow (new topics,
  ///   things to manufacture) are not ported
  /// </summary>
  TXcomBaseWork = class
  strict private
    FGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FRandom: IXcomRandom;
    FEvents: IXcomGeoscapeEvents;
    FSettings: IXcomStrategySettings;
    FSaveSettings: IXcomSaveSettings;
    FStepper: TXcomProductionStepper;
    FCapacity: TXcomBaseCapacity;
    procedure AdvanceTransfer(const ATransfer: TXcomTransfer; const ABase: TXcomBase);
    procedure ReceiveArrivedTransfers;
    procedure StepProductions(const ABase: TXcomBase);
    procedure FinishResearch(const ABase: TXcomBase);
  public
    constructor Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset; const ARandom: IXcomRandom;
      const AEvents: IXcomGeoscapeEvents; const ASettings: IXcomStrategySettings;
      const ASaveSettings: IXcomSaveSettings);
    destructor Destroy; override;
    /// <summary>
    ///   The base parts of time1Hour: the transfers advance (and what arrived is received), the productions
    ///   step, a storage that is too full is announced, the first mission site that is not shown is announced
    /// </summary>
    procedure Hourly;
    /// <summary>The base part of time1Day: constructions, research, wounds and the daily psionic training</summary>
    procedure Daily;
  end;

implementation

{ TXcomBaseWork }

constructor TXcomBaseWork.Create(const AGame: TXcomSavedGame; const ARuleset: TXcomRuleset;
  const ARandom: IXcomRandom; const AEvents: IXcomGeoscapeEvents; const ASettings: IXcomStrategySettings;
  const ASaveSettings: IXcomSaveSettings);
begin
  inherited Create;
  FGame := AGame;
  FRuleset := ARuleset;
  FRandom := ARandom;
  FEvents := AEvents;
  FSettings := ASettings;
  FSaveSettings := ASaveSettings;
  FStepper := TXcomProductionStepper.Create(ARuleset);
  FCapacity := TXcomBaseCapacity.Create(ARuleset);
end;

destructor TXcomBaseWork.Destroy;
begin
  FCapacity.Free;
  FStepper.Free;
  inherited Destroy;
end;

procedure TXcomBaseWork.AdvanceTransfer(const ATransfer: TXcomTransfer; const ABase: TXcomBase);
var
  LSoldier: TXcomSoldier;
  LCraft: TXcomCraft;
begin
  ATransfer.Hours := ATransfer.Hours - 1;
  if ATransfer.Hours > 0 then
    Exit;
  if Assigned(ATransfer.Soldier) then
  begin
    ATransfer.Deliver(LSoldier, LCraft);
    ABase.Soldiers.Add(LSoldier);
  end
  else if Assigned(ATransfer.Craft) then
  begin
    ATransfer.Deliver(LSoldier, LCraft);
    ABase.Crafts.Add(LCraft);
    LCraft.SetBase(ABase);
    LCraft.Checkup;
  end
  else if ATransfer.ItemQty <> 0 then
  begin
    ABase.StorageItems.AddItem(ATransfer.ItemId, ATransfer.ItemQty);
    ATransfer.Delivered := True;
  end
  else if ATransfer.Scientists <> 0 then
  begin
    ABase.Scientists := ABase.Scientists + ATransfer.Scientists;
    ATransfer.Delivered := True;
  end
  else if ATransfer.Engineers <> 0 then
  begin
    ABase.Engineers := ABase.Engineers + ATransfer.Engineers;
    ATransfer.Delivered := True;
  end
  else
    ATransfer.Delivered := True;
end;

procedure TXcomBaseWork.ReceiveArrivedTransfers;
var
  LBase: TXcomBase;
  LIndex, LCraft: Integer;
  LItem: TXcomRuleItem;
  LTransfer: TXcomTransfer;
begin
  // what ItemsArrivingState does when it opens: the items that something can use are used, the transfers go
  for LBase in FGame.Bases do
  begin
    LIndex := 0;
    while LIndex < LBase.Transfers.Count do
    begin
      LTransfer := LBase.Transfers[LIndex];
      if LTransfer.Hours = 0 then
      begin
        if (LTransfer.ItemQty <> 0) and not Assigned(LTransfer.Soldier) and not Assigned(LTransfer.Craft) then
        begin
          LItem := FRuleset.Items.Find(LTransfer.ItemId);
          if not Assigned(LItem) then
            raise EXcomStrategyException.CreateFmt('%s not found', [LTransfer.ItemId]);
          if LItem.BattleType = TXcomRuleItem.BT_NONE then
            for LCraft := 0 to LBase.Crafts.Count - 1 do
              LBase.Crafts[LCraft].ReuseItem(LTransfer.ItemId, FRuleset);
        end;
        LBase.Transfers.Delete(LIndex);
      end
      else
        Inc(LIndex);
    end;
  end;
end;

procedure TXcomBaseWork.StepProductions(const ABase: TXcomBase);
var
  LResults: TArray<TXcomProductionProgress>;
  LIndex: Integer;
  LNames: TArray<string>;
  LProductions: TArray<TXcomProduction>;
begin
  SetLength(LResults, ABase.Productions.Count);
  SetLength(LNames, ABase.Productions.Count);
  SetLength(LProductions, ABase.Productions.Count);
  for LIndex := 0 to ABase.Productions.Count - 1 do
  begin
    LProductions[LIndex] := ABase.Productions[LIndex];
    LNames[LIndex] := LProductions[LIndex].Rules.Name;
    LResults[LIndex] := FStepper.Step(LProductions[LIndex], ABase, FGame);
  end;
  for LIndex := 0 to High(LResults) do
    if LResults[LIndex] > ppNotComplete then
    begin
      FEvents.ProductionFinished(ABase, LNames[LIndex], LResults[LIndex]);
      ABase.RemoveProduction(LProductions[LIndex]);
    end;
end;

procedure TXcomBaseWork.Hourly;
var
  LBase: TXcomBase;
  LTransfer: TXcomTransfer;
  LWindow: Boolean;
  LSite: TXcomMissionSite;
begin
  LWindow := False;
  for LBase in FGame.Bases do
    for LTransfer in LBase.Transfers do
    begin
      AdvanceTransfer(LTransfer, LBase);
      if not LWindow and (LTransfer.Hours <= 0) then
        LWindow := True;
    end;
  if LWindow then
  begin
    FEvents.ItemsArriving;
    ReceiveArrivedTransfers;
  end;
  for LBase in FGame.Bases do
  begin
    StepProductions(LBase);
    if FSettings.StorageLimitsEnforced and FCapacity.StoresOverfull(LBase, 0) then
      FEvents.StorageExceeded(LBase);
  end;
  for LSite in FGame.MissionSites do
    if not LSite.Detected then
    begin
      LSite.Detected := True;
      FEvents.MissionDetected(LSite);
      Break;
    end;
end;

procedure TXcomBaseWork.FinishResearch(const ABase: TXcomBase);
var
  LFinished: TList<TXcomResearchProject>;
  LProject: TXcomResearchProject;
  LName: string;
begin
  LFinished := TList<TXcomResearchProject>.Create;
  try
    for LProject in ABase.Research do
      if LProject.Step then
        LFinished.Add(LProject);
    for LProject in LFinished do
    begin
      LName := LProject.Rules.Name;
      ABase.RemoveResearch(LProject);
      FEvents.ResearchFinished(ABase, LName);
    end;
  finally
    LFinished.Free;
  end;
end;

procedure TXcomBaseWork.Daily;
var
  LBase: TXcomBase;
  LFacility: TXcomBaseFacility;
  LSoldier: TXcomSoldier;
begin
  for LBase in FGame.Bases do
  begin
    for LFacility in LBase.Facilities do
      if LFacility.BuildTime > 0 then
      begin
        LFacility.Build;
        if LFacility.BuildTime = 0 then
          FEvents.FacilityBuilt(LBase, LFacility);
      end;
    FinishResearch(LBase);
    for LSoldier in LBase.Soldiers do
      if LSoldier.WoundRecovery > 0 then
        LSoldier.Heal;
    if (FCapacity.AvailablePsiLabs(LBase) > 0) and FSettings.AnytimePsiTraining then
      for LSoldier in LBase.Soldiers do
        // the stat string of the soldier is not ported
        LSoldier.TrainPsiOneDay(FSaveSettings, FRandom);
  end;
end;

end.
