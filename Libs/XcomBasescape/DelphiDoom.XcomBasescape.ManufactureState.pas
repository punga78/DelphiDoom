{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - ManufactureState of OpenXcom (the       }
{  current productions of a base)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ManufactureState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity;

type
  /// <summary>
  ///   "Current production": item, engineers, units produced, cost per unit and the time left of each production of
  ///   the base, with the engineers and the workshop space that are free and the funds
  /// </summary>
  TXcomManufactureState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FCapacity: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FBtnNew: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtAvailable: TXcomText;
    FTxtAllocated: TXcomText;
    FTxtSpace: TXcomText;
    FTxtFunds: TXcomText;
    FTxtItem: TXcomText;
    FTxtEngineers: TXcomText;
    FTxtProduced: TXcomText;
    FTxtCost: TXcomText;
    FTxtTimeLeft: TXcomText;
    FLstManufacture: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure NewProductionClick(AAction: TXcomAction);
    procedure ManufactureClick(AAction: TXcomAction);
    procedure FillProductionList;
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    destructor Destroy; override;
    procedure Init; override;
    property List: TXcomTextList read FLstManufacture;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Production, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomBasescape.NewManufactureListState,
  DelphiDoom.XcomBasescape.ManufactureInfoState;

const
  INFINITY_SIGN = #$221E;

{ TXcomManufactureState }

constructor TXcomManufactureState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
begin
  inherited Create(AHost);
  FBase := ABase;
  FCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(AHost));
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnNew := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnOk := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtAvailable := TXcomText.Create(150, 9, 8, 24);
  FTxtAllocated := TXcomText.Create(150, 9, 160, 24);
  FTxtSpace := TXcomText.Create(150, 9, 8, 34);
  FTxtFunds := TXcomText.Create(150, 9, 160, 34);
  FTxtItem := TXcomText.Create(80, 9, 10, 52);
  FTxtEngineers := TXcomText.Create(56, 18, 112, 44);
  FTxtProduced := TXcomText.Create(56, 18, 168, 44);
  FTxtCost := TXcomText.Create(44, 27, 222, 44);
  FTxtTimeLeft := TXcomText.Create(60, 27, 260, 44);
  FLstManufacture := TXcomTextList.Create(Host.Options, Host.Clock, 288, 88, 8, 80);
  SetInterface('manufactureMenu');
  Add(FWindow, 'window', 'manufactureMenu');
  Add(FBtnNew, 'button', 'manufactureMenu');
  Add(FBtnOk, 'button', 'manufactureMenu');
  Add(FTxtTitle, 'text1', 'manufactureMenu');
  Add(FTxtAvailable, 'text1', 'manufactureMenu');
  Add(FTxtAllocated, 'text1', 'manufactureMenu');
  Add(FTxtSpace, 'text1', 'manufactureMenu');
  Add(FTxtFunds, 'text1', 'manufactureMenu');
  Add(FTxtItem, 'text2', 'manufactureMenu');
  Add(FTxtEngineers, 'text2', 'manufactureMenu');
  Add(FTxtProduced, 'text2', 'manufactureMenu');
  Add(FTxtCost, 'text2', 'manufactureMenu');
  Add(FTxtTimeLeft, 'text2', 'manufactureMenu');
  Add(FLstManufacture, 'list', 'manufactureMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK17.SCR'));
  FBtnNew.SetText(Tr('STR_NEW_PRODUCTION'));
  FBtnNew.OnMouseClick(NewProductionClick);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_CURRENT_PRODUCTION'));
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtEngineers.SetText(Tr('STR_ENGINEERS__ALLOCATED'));
  FTxtEngineers.SetWordWrap(True);
  FTxtProduced.SetText(Tr('STR_UNITS_PRODUCED'));
  FTxtProduced.SetWordWrap(True);
  FTxtCost.SetText(Tr('STR_COST__PER__UNIT'));
  FTxtCost.SetWordWrap(True);
  FTxtTimeLeft.SetText(Tr('STR_DAYS_HOURS_LEFT'));
  FTxtTimeLeft.SetWordWrap(True);
  FLstManufacture.SetColumns([115, 15, 52, 56, 48]);
  FLstManufacture.SetAlign(haRight);
  FLstManufacture.SetAlign(haLeft, 0);
  FLstManufacture.SetSelectable(True);
  FLstManufacture.SetBackground(FWindow);
  FLstManufacture.SetMargin(2);
  FLstManufacture.SetWordWrap(True);
  FLstManufacture.OnMouseClick(ManufactureClick);
  FillProductionList;
end;

destructor TXcomManufactureState.Destroy;
begin
  inherited Destroy;
  FCapacity.Free;
end;

procedure TXcomManufactureState.Init;
begin
  inherited Init;
  FillProductionList;
end;

procedure TXcomManufactureState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomManufactureState.NewProductionClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomNewManufactureListState.Create(Host, FBase));
end;

procedure TXcomManufactureState.ManufactureClick(AAction: TXcomAction);
begin
  if (FLstManufacture.GetSelectedRow >= 0) and (FLstManufacture.GetSelectedRow < FBase.Productions.Count) then
    Host.PushState(TXcomManufactureInfoState.Create(Host, FBase, FBase.Productions[FLstManufacture.GetSelectedRow]));
end;

procedure TXcomManufactureState.FillProductionList;
var
  LProduction: TXcomProduction;
  LProduced, LTimeLeft, LHoursLeft: string;
  LTime, LEngineers, LHours: Integer;
  LAllocated: Integer;
begin
  FLstManufacture.ClearList;
  LAllocated := 0;
  for LProduction in FBase.Productions do
  begin
    LProduced := IntToStr(LProduction.AmountProduced) + '/';
    if LProduction.InfiniteAmount then
      LProduced := LProduced + INFINITY_SIGN
    else
      LProduced := LProduced + IntToStr(LProduction.AmountTotal);
    if LProduction.SellItems then
      LProduced := LProduced + ' $';
    LHoursLeft := '';
    if LProduction.InfiniteAmount then
      LTimeLeft := INFINITY_SIGN
    else if LProduction.AssignedEngineers > 0 then
    begin
      LTime := LProduction.AmountTotal * LProduction.Rules.ManufactureTime - LProduction.TimeSpent;
      LEngineers := LProduction.AssignedEngineers;
      // it takes an entire hour to manufacture any part of that hour's capacity: round up
      LHours := (LTime + LEngineers - 1) div LEngineers;
      LTimeLeft := IntToStr(LHours div 24) + '/' + IntToStr(LHours mod 24);
    end
    else
      LTimeLeft := '-';
    FLstManufacture.AddRow([Tr(LProduction.Rules.Name).Text, IntToStr(LProduction.AssignedEngineers), LProduced,
      TXcomFunding.Format(LProduction.Rules.ManufactureCost), LTimeLeft]);
    Inc(LAllocated, LProduction.AssignedEngineers);
  end;
  FTxtAvailable.SetText(Tr('STR_ENGINEERS_AVAILABLE').Arg(FCapacity.AvailableEngineers(FBase)));
  FTxtAllocated.SetText(Tr('STR_ENGINEERS_ALLOCATED').Arg(LAllocated));
  FTxtSpace.SetText(Tr('STR_WORKSHOP_SPACE_AVAILABLE').Arg(FCapacity.FreeWorkshops(FBase)));
  FTxtFunds.SetText(Tr('STR_CURRENT_FUNDS').Arg(TXcomFunding.Format(TXcomStrategy.SavedGame(Host).Funds)));
end;

end.
