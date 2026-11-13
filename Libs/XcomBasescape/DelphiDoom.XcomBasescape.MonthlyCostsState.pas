{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - MonthlyCostsState of OpenXcom (craft    }
{  rental, salaries and maintenance of a base)                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.MonthlyCostsState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>
  ///   The monthly costs of a base: the rental of the crafts, the salaries of soldiers, engineers and scientists, the
  ///   maintenance of the facilities and the total, with the income and the maintenance of all the bases
  /// </summary>
  TXcomMonthlyCostsState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtCost: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtTotal: TXcomText;
    FTxtRental: TXcomText;
    FTxtSalaries: TXcomText;
    FTxtIncome: TXcomText;
    FTxtMaintenance: TXcomText;
    FLstCrafts: TXcomTextList;
    FLstSalaries: TXcomTextList;
    FLstMaintenance: TXcomTextList;
    FLstTotal: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    property CraftsList: TXcomTextList read FLstCrafts;
    property SalariesList: TXcomTextList read FLstSalaries;
    property MaintenanceList: TXcomTextList read FLstMaintenance;
    property TotalList: TXcomTextList read FLstTotal;
    property IncomeText: TXcomText read FTxtIncome;
    property MaintenanceText: TXcomText read FTxtMaintenance;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleCraft,
  DelphiDoom.XcomMod.RuleSoldier, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.XcomStrategy.BaseCrafts, DelphiDoom.XcomGeoscape.Funding;

{ TXcomMonthlyCostsState }

constructor TXcomMonthlyCostsState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LRuleset: TXcomRuleset;
  LSave: TXcomSavedGame;
  LCapacity: TXcomBaseCapacity;
  LName, LRowName: string;
  LCraft: TXcomRuleCraft;
  LSoldier: TXcomRuleSoldier;
  LCount: Integer;
begin
  inherited Create(AHost);
  LRuleset := TXcomStrategy.Ruleset(AHost);
  LSave := TXcomStrategy.SavedGame(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(300, 20, 10, 170);
  FTxtTitle := TXcomText.Create(310, 17, 5, 12);
  FTxtCost := TXcomText.Create(80, 9, 115, 32);
  FTxtQuantity := TXcomText.Create(55, 9, 195, 32);
  FTxtTotal := TXcomText.Create(60, 9, 249, 32);
  FTxtRental := TXcomText.Create(150, 9, 10, 40);
  FTxtSalaries := TXcomText.Create(150, 9, 10, 80);
  FTxtIncome := TXcomText.Create(150, 9, 10, 146);
  FTxtMaintenance := TXcomText.Create(150, 9, 10, 154);
  FLstCrafts := TXcomTextList.Create(Host.Options, Host.Clock, 288, 32, 10, 48);
  FLstSalaries := TXcomTextList.Create(Host.Options, Host.Clock, 288, 40, 10, 88);
  FLstMaintenance := TXcomTextList.Create(Host.Options, Host.Clock, 300, 9, 10, 128);
  FLstTotal := TXcomTextList.Create(Host.Options, Host.Clock, 100, 9, 205, 150);
  SetInterface('costsInfo');
  Add(FWindow, 'window', 'costsInfo');
  Add(FBtnOk, 'button', 'costsInfo');
  Add(FTxtTitle, 'text1', 'costsInfo');
  Add(FTxtCost, 'text1', 'costsInfo');
  Add(FTxtQuantity, 'text1', 'costsInfo');
  Add(FTxtTotal, 'text1', 'costsInfo');
  Add(FTxtRental, 'text1', 'costsInfo');
  Add(FLstCrafts, 'list', 'costsInfo');
  Add(FTxtSalaries, 'text1', 'costsInfo');
  Add(FLstSalaries, 'list', 'costsInfo');
  Add(FLstMaintenance, 'text1', 'costsInfo');
  Add(FTxtIncome, 'list', 'costsInfo');
  Add(FTxtMaintenance, 'list', 'costsInfo');
  Add(FLstTotal, 'text2', 'costsInfo');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_MONTHLY_COSTS'));
  FTxtCost.SetText(Tr('STR_COST_PER_UNIT'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY'));
  FTxtTotal.SetText(Tr('STR_TOTAL'));
  FTxtRental.SetText(Tr('STR_CRAFT_RENTAL'));
  FTxtSalaries.SetText(Tr('STR_SALARIES'));
  FTxtIncome.SetText(Tr('STR_INCOME').Text + '=' + TXcomFunding.Format(LSave.CountryFunding));
  LCapacity := TXcomBaseCapacity.Create(LRuleset);
  try
    FTxtMaintenance.SetText(Tr('STR_MAINTENANCE').Text + '=' + TXcomFunding.Format(LCapacity.BaseMaintenance(LSave)));
    FLstCrafts.SetColumns([125, 70, 44, 50]);
    FLstCrafts.SetDot(True);
    for LName in LRuleset.Crafts.Index do
    begin
      LCraft := LRuleset.Crafts.Find(LName);
      if (LCraft.RentCost <> 0) and LSave.IsResearched(LCraft.Requirements) then
      begin
        LCount := TXcomBaseCrafts.Count(ABase, LName);
        FLstCrafts.AddRow([Tr(LName).Text, TXcomFunding.Format(LCraft.RentCost), IntToStr(LCount),
          TXcomFunding.Format(Int64(LCount) * LCraft.RentCost)]);
      end;
    end;
    FLstSalaries.SetColumns([125, 70, 44, 50]);
    FLstSalaries.SetDot(True);
    for LName in LRuleset.Soldiers.Index do
    begin
      LSoldier := LRuleset.Soldiers.Find(LName);
      if (LSoldier.SalaryCost <> 0) and LSave.IsResearched(LSoldier.Requirements) then
      begin
        LCount := LCapacity.SoldierCount(ABase, LName);
        LRowName := LName;
        if Length(LRuleset.Soldiers.Index) = 1 then
          LRowName := 'STR_SOLDIERS';
        FLstSalaries.AddRow([Tr(LRowName).Text, TXcomFunding.Format(LSoldier.SalaryCost), IntToStr(LCount),
          TXcomFunding.Format(Int64(LCount) * LSoldier.SalaryCost)]);
      end;
    end;
    LCount := LCapacity.TotalEngineers(ABase);
    FLstSalaries.AddRow([Tr('STR_ENGINEERS').Text, TXcomFunding.Format(LRuleset.Settings.CostEngineer),
      IntToStr(LCount), TXcomFunding.Format(Int64(LCount) * LRuleset.Settings.CostEngineer)]);
    LCount := LCapacity.TotalScientists(ABase);
    FLstSalaries.AddRow([Tr('STR_SCIENTISTS').Text, TXcomFunding.Format(LRuleset.Settings.CostScientist),
      IntToStr(LCount), TXcomFunding.Format(Int64(LCount) * LRuleset.Settings.CostScientist)]);
    FLstMaintenance.SetColumns([239, 60]);
    FLstMaintenance.SetDot(True);
    FLstMaintenance.AddRow([Tr('STR_BASE_MAINTENANCE').Text,
      Char(XCOM_TOKEN_COLOR_FLIP) + TXcomFunding.Format(LCapacity.FacilityMaintenance(ABase))]);
    FLstTotal.SetColumns([44, 55]);
    FLstTotal.SetDot(True);
    FLstTotal.AddRow([Tr('STR_TOTAL').Text, TXcomFunding.Format(LCapacity.MonthlyMaintenance(ABase))]);
  finally
    LCapacity.Free;
  end;
end;

procedure TXcomMonthlyCostsState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
