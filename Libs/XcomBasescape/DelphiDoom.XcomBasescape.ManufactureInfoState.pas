{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - ManufactureInfoState of OpenXcom (the   }
{  engineers and the units of a production)                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ManufactureInfoState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.ToggleTextButton,
  DelphiDoom.XcomUi.ArrowButton, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Production,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomBasescape.HoldRepeater;

type
  /// <summary>
  ///   The engineers and the number of units of a production (more and less with the left button, all or infinite
  ///   with the right, repeating while held), the sale of what it produces and the profit of a month. For a new
  ///   production (made from an item) OK pays the first unit and starts it and closes this screen and the one
  ///   below; for one that exists the button stops it
  /// </summary>
  TXcomManufactureInfoState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FItem: TXcomRuleManufacture;
    FProduction: TXcomProduction;
    FCapacity: TXcomBaseCapacity;
    FProducedItemsValue: Integer;
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FBtnOk: TXcomTextButton;
    FBtnStop: TXcomTextButton;
    FBtnSell: TXcomToggleTextButton;
    FTxtAvailableEngineer: TXcomText;
    FTxtAvailableSpace: TXcomText;
    FTxtMonthlyProfit: TXcomText;
    FTxtAllocatedEngineer: TXcomText;
    FTxtUnitToProduce: TXcomText;
    FTxtEngineerUp: TXcomText;
    FTxtEngineerDown: TXcomText;
    FTxtUnitUp: TXcomText;
    FTxtUnitDown: TXcomText;
    FBtnEngineerUp: TXcomArrowButton;
    FBtnEngineerDown: TXcomArrowButton;
    FBtnUnitUp: TXcomArrowButton;
    FBtnUnitDown: TXcomArrowButton;
    FTxtAllocated: TXcomText;
    FTxtTodo: TXcomText;
    FSurfaceEngineers: TXcomInteractiveSurface;
    FSurfaceUnits: TXcomInteractiveSurface;
    FRepeatMoreEngineer: TXcomHoldRepeater;
    FRepeatLessEngineer: TXcomHoldRepeater;
    FRepeatMoreUnit: TXcomHoldRepeater;
    FRepeatLessUnit: TXcomHoldRepeater;
    procedure BuildUi;
    procedure InitProfitInfo;
    procedure SellClick(AAction: TXcomAction);
    procedure StopClick(AAction: TXcomAction);
    procedure OkClick(AAction: TXcomAction);
    procedure ExitState;
    procedure SetAssignedEngineer;
    procedure WheelEngineer(AAction: TXcomAction);
    procedure WheelUnit(AAction: TXcomAction);
    procedure MoreEngineerClick(AAction: TXcomAction);
    procedure LessEngineerClick(AAction: TXcomAction);
    procedure MoreUnitClick(AAction: TXcomAction);
    procedure LessUnitClick(AAction: TXcomAction);
    procedure ShowNoHangars;
  public
    /// <summary>A production that exists (not owned)</summary>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AProduction: TXcomProduction);
    /// <summary>A new production for an item: it is made, with one unit, and added to the base</summary>
    constructor CreateForRule(AHost: TXcomStateHost; ABase: TXcomBase; AItem: TXcomRuleManufacture);
    destructor Destroy; override;
    procedure Think; override;
    /// <summary>getMonthlyNetFunds: the change in the funds in a month (not the net worth)</summary>
    function MonthlyNetFunds: Integer;
    procedure MoreEngineer(AChange: Integer);
    procedure LessEngineer(AChange: Integer);
    procedure MoreUnit(AChange: Integer);
    procedure LessUnit(AChange: Integer);
    property Production: TXcomProduction read FProduction;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomStrategy.ProductionStepper, DelphiDoom.XcomGeoscape.Funding, DelphiDoom.XcomMenu.ErrorMessageState;

const
  INFINITY_SIGN = #$221E;

{ TXcomManufactureInfoState }

constructor TXcomManufactureInfoState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AProduction: TXcomProduction);
begin
  inherited Create(AHost);
  FBase := ABase;
  FItem := nil;
  FProduction := AProduction;
  BuildUi;
end;

constructor TXcomManufactureInfoState.CreateForRule(AHost: TXcomStateHost; ABase: TXcomBase;
  AItem: TXcomRuleManufacture);
begin
  inherited Create(AHost);
  FBase := ABase;
  FItem := AItem;
  FProduction := nil;
  BuildUi;
end;

destructor TXcomManufactureInfoState.Destroy;
begin
  inherited Destroy;
  FRepeatLessUnit.Free;
  FRepeatMoreUnit.Free;
  FRepeatLessEngineer.Free;
  FRepeatMoreEngineer.Free;
  FCapacity.Free;
end;

procedure TXcomManufactureInfoState.BuildUi;
begin
  FCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(Host));
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 160, 0, 20, wpBoth);
  FTxtTitle := TXcomText.Create(320, 17, 0, 30);
  FBtnOk := TXcomTextButton.Create(136, 16, 168, 155);
  FBtnStop := TXcomTextButton.Create(136, 16, 16, 155);
  FBtnSell := TXcomToggleTextButton.Create(60, 16, 244, 61);
  FTxtAvailableEngineer := TXcomText.Create(160, 9, 16, 50);
  FTxtAvailableSpace := TXcomText.Create(160, 9, 16, 60);
  FTxtMonthlyProfit := TXcomText.Create(160, 9, 168, 50);
  FTxtAllocatedEngineer := TXcomText.Create(112, 32, 16, 80);
  FTxtUnitToProduce := TXcomText.Create(112, 48, 168, 64);
  FTxtEngineerUp := TXcomText.Create(90, 9, 40, 118);
  FTxtEngineerDown := TXcomText.Create(90, 9, 40, 138);
  FTxtUnitUp := TXcomText.Create(90, 9, 192, 118);
  FTxtUnitDown := TXcomText.Create(90, 9, 192, 138);
  FBtnEngineerUp := TXcomArrowButton.Create(Host.Clock, arBigUp, 13, 14, 132, 114);
  FBtnEngineerDown := TXcomArrowButton.Create(Host.Clock, arBigDown, 13, 14, 132, 136);
  FBtnUnitUp := TXcomArrowButton.Create(Host.Clock, arBigUp, 13, 14, 284, 114);
  FBtnUnitDown := TXcomArrowButton.Create(Host.Clock, arBigDown, 13, 14, 284, 136);
  FTxtAllocated := TXcomText.Create(40, 16, 128, 88);
  FTxtTodo := TXcomText.Create(40, 16, 280, 88);
  FSurfaceEngineers := TXcomInteractiveSurface.Create(160, 150, 0, 25);
  FSurfaceEngineers.OnMouseClick(WheelEngineer, 0);
  FSurfaceUnits := TXcomInteractiveSurface.Create(160, 150, 160, 25);
  FSurfaceUnits.OnMouseClick(WheelUnit, 0);
  SetInterface('manufactureInfo');
  Add(FSurfaceEngineers);
  Add(FSurfaceUnits);
  Add(FWindow, 'window', 'manufactureInfo');
  Add(FTxtTitle, 'text', 'manufactureInfo');
  Add(FTxtAvailableEngineer, 'text', 'manufactureInfo');
  Add(FTxtAvailableSpace, 'text', 'manufactureInfo');
  Add(FTxtMonthlyProfit, 'text', 'manufactureInfo');
  Add(FTxtAllocatedEngineer, 'text', 'manufactureInfo');
  Add(FTxtAllocated, 'text', 'manufactureInfo');
  Add(FTxtUnitToProduce, 'text', 'manufactureInfo');
  Add(FTxtTodo, 'text', 'manufactureInfo');
  Add(FTxtEngineerUp, 'text', 'manufactureInfo');
  Add(FTxtEngineerDown, 'text', 'manufactureInfo');
  Add(FBtnEngineerUp, 'button1', 'manufactureInfo');
  Add(FBtnEngineerDown, 'button1', 'manufactureInfo');
  Add(FTxtUnitUp, 'text', 'manufactureInfo');
  Add(FTxtUnitDown, 'text', 'manufactureInfo');
  Add(FBtnUnitUp, 'button1', 'manufactureInfo');
  Add(FBtnUnitDown, 'button1', 'manufactureInfo');
  Add(FBtnOk, 'button2', 'manufactureInfo');
  Add(FBtnStop, 'button2', 'manufactureInfo');
  Add(FBtnSell, 'button1', 'manufactureInfo');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK17.SCR'));
  if Assigned(FItem) then
    FTxtTitle.SetText(Tr(FItem.Name))
  else
    FTxtTitle.SetText(Tr(FProduction.Rules.Name));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtAllocatedEngineer.SetText(Tr('STR_ENGINEERS__ALLOCATED'));
  FTxtAllocatedEngineer.SetBig;
  FTxtAllocatedEngineer.SetWordWrap(True);
  FTxtAllocatedEngineer.SetVerticalAlign(vaBottom);
  FTxtAllocated.SetBig;
  FTxtTodo.SetBig;
  FTxtUnitToProduce.SetText(Tr('STR_UNITS_TO_PRODUCE'));
  FTxtUnitToProduce.SetBig;
  FTxtUnitToProduce.SetWordWrap(True);
  FTxtUnitToProduce.SetVerticalAlign(vaBottom);
  FTxtEngineerUp.SetText(Tr('STR_INCREASE_UC'));
  FTxtEngineerDown.SetText(Tr('STR_DECREASE_UC'));
  FTxtUnitUp.SetText(Tr('STR_INCREASE_UC'));
  FTxtUnitDown.SetText(Tr('STR_DECREASE_UC'));
  FBtnEngineerUp.OnMouseClick(MoreEngineerClick, 0);
  FBtnEngineerDown.OnMouseClick(LessEngineerClick, 0);
  FBtnUnitUp.OnMouseClick(MoreUnitClick, 0);
  FBtnUnitDown.OnMouseClick(LessUnitClick, 0);
  FBtnSell.SetText(Tr('STR_SELL_PRODUCTION'));
  FBtnSell.OnMouseClick(SellClick, 0);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnStop.SetText(Tr('STR_STOP_PRODUCTION'));
  FBtnStop.OnMouseClick(StopClick);
  if FProduction = nil then
  begin
    FProduction := TXcomProduction.Create(FItem, 1);
    FBase.AddProduction(FProduction);
  end;
  FBtnSell.SetPressed(FProduction.SellItems);
  InitProfitInfo;
  SetAssignedEngineer;
  FRepeatMoreEngineer := TXcomHoldRepeater.Create(Host.Clock, FBtnEngineerUp,
    procedure
    begin
      MoreEngineer(1);
    end);
  FRepeatLessEngineer := TXcomHoldRepeater.Create(Host.Clock, FBtnEngineerDown,
    procedure
    begin
      LessEngineer(1);
    end);
  FRepeatMoreUnit := TXcomHoldRepeater.Create(Host.Clock, FBtnUnitUp,
    procedure
    begin
      MoreUnit(1);
    end);
  FRepeatLessUnit := TXcomHoldRepeater.Create(Host.Clock, FBtnUnitDown,
    procedure
    begin
      LessUnit(1);
    end);
end;

procedure TXcomManufactureInfoState.InitProfitInfo;
var
  LRule: TXcomRuleManufacture;
  LIndex: Integer;
  LSell: Integer;
  LName: string;
  LRuleset: TXcomRuleset;
begin
  LRuleset := TXcomStrategy.Ruleset(Host);
  LRule := FProduction.Rules;
  FProducedItemsValue := 0;
  for LIndex := 0 to LRule.ProducedItems.Count - 1 do
  begin
    LName := LRule.ProducedItems.Key(LIndex);
    if LRule.Category = 'STR_CRAFT' then
      LSell := LRuleset.Crafts.Find(LName).SellCost
    else
      LSell := LRuleset.Items.Find(LName).SellCost;
    Inc(FProducedItemsValue, LSell * LRule.ProducedItems.Value(LIndex));
  end;
end;

function TXcomManufactureInfoState.MonthlyNetFunds: Integer;
const
  // it does not take leap years into account
  AVG_HOURS_PER_MONTH = (365 * 24) div 12;
var
  LRule: TXcomRuleManufacture;
  LSaleValue, LManHoursPerMonth, LManHoursRemaining: Integer;
  LItemsPerMonth: Single;
begin
  LRule := FProduction.Rules;
  if FBtnSell.GetPressed then
    LSaleValue := FProducedItemsValue
  else
    LSaleValue := 0;
  LManHoursPerMonth := AVG_HOURS_PER_MONTH * FProduction.AssignedEngineers;
  if not FProduction.InfiniteAmount then
  begin
    // scaled down to the man hours that are needed when the job takes less than a month
    LManHoursRemaining := LRule.ManufactureTime * (FProduction.AmountTotal - FProduction.AmountProduced);
    LManHoursPerMonth := Min(LManHoursPerMonth, LManHoursRemaining);
  end;
  LItemsPerMonth := LManHoursPerMonth / Single(LRule.ManufactureTime);
  Result := Trunc((LSaleValue - LRule.ManufactureCost) * LItemsPerMonth);
end;

procedure TXcomManufactureInfoState.SellClick(AAction: TXcomAction);
begin
  SetAssignedEngineer;
end;

procedure TXcomManufactureInfoState.StopClick(AAction: TXcomAction);
begin
  FBase.RemoveProduction(FProduction);
  ExitState;
end;

procedure TXcomManufactureInfoState.OkClick(AAction: TXcomAction);
var
  LStepper: TXcomProductionStepper;
begin
  if Assigned(FItem) then
  begin
    LStepper := TXcomProductionStepper.Create(TXcomStrategy.Ruleset(Host));
    try
      LStepper.StartItem(FProduction, FBase, TXcomStrategy.SavedGame(Host));
    finally
      LStepper.Free;
    end;
  end;
  FProduction.SellItems := FBtnSell.GetPressed;
  ExitState;
end;

procedure TXcomManufactureInfoState.ExitState;
begin
  Host.PopState;
  // a new production also closes the screen of the requirements
  if Assigned(FItem) then
    Host.PopState;
end;

procedure TXcomManufactureInfoState.SetAssignedEngineer;
var
  LTodo: string;
begin
  FTxtAvailableEngineer.SetText(Tr('STR_ENGINEERS_AVAILABLE_UC').Arg(FCapacity.AvailableEngineers(FBase)));
  FTxtAvailableSpace.SetText(Tr('STR_WORKSHOP_SPACE_AVAILABLE_UC').Arg(FCapacity.FreeWorkshops(FBase)));
  FTxtAllocated.SetText('>' + Chr(XCOM_TOKEN_COLOR_FLIP) + IntToStr(FProduction.AssignedEngineers));
  if FProduction.InfiniteAmount then
    LTodo := INFINITY_SIGN
  else
    LTodo := IntToStr(FProduction.AmountTotal);
  FTxtTodo.SetText('>' + Chr(XCOM_TOKEN_COLOR_FLIP) + LTodo);
  FTxtMonthlyProfit.SetText(Tr('STR_MONTHLY_PROFIT').Arg(TXcomFunding.Format(MonthlyNetFunds)));
end;

procedure TXcomManufactureInfoState.MoreEngineer(AChange: Integer);
var
  LAvailableEngineer, LAvailableSpace: Integer;
begin
  if AChange <= 0 then
    Exit;
  LAvailableEngineer := FCapacity.AvailableEngineers(FBase);
  LAvailableSpace := FCapacity.FreeWorkshops(FBase);
  if (LAvailableEngineer > 0) and (LAvailableSpace > 0) then
  begin
    AChange := Min(Min(LAvailableEngineer, LAvailableSpace), AChange);
    FProduction.AssignedEngineers := FProduction.AssignedEngineers + AChange;
    FBase.Engineers := FBase.Engineers - AChange;
    SetAssignedEngineer;
  end;
end;

procedure TXcomManufactureInfoState.LessEngineer(AChange: Integer);
var
  LAssigned: Integer;
begin
  if AChange <= 0 then
    Exit;
  LAssigned := FProduction.AssignedEngineers;
  if LAssigned > 0 then
  begin
    AChange := Min(LAssigned, AChange);
    FProduction.AssignedEngineers := LAssigned - AChange;
    FBase.Engineers := FBase.Engineers + AChange;
    SetAssignedEngineer;
  end;
end;

procedure TXcomManufactureInfoState.ShowNoHangars;
var
  LInterface: TXcomRuleInterface;
  LMessage, LPalette: TXcomInterfaceElement;
begin
  LMessage := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  LPalette.Color := -1;
  LInterface := Host.Resources.GetInterface('basescape');
  if LInterface <> nil then
  begin
    LInterface.TryGetElement('errorMessage', LMessage);
    LInterface.TryGetElement('errorPalette', LPalette);
  end;
  Host.PushState(TXcomErrorMessageState.Create(Host, Tr('STR_NO_FREE_HANGARS_FOR_CRAFT_PRODUCTION'), Palette,
    Byte(LMessage.Color), 'BACK17.SCR', LPalette.Color));
end;

procedure TXcomManufactureInfoState.MoreUnit(AChange: Integer);
var
  LUnits, LFreeHangars: Integer;
begin
  if AChange <= 0 then
    Exit;
  LFreeHangars := FCapacity.AvailableHangars(FBase) - FCapacity.UsedHangars(FBase);
  if (FProduction.Rules.Category = 'STR_CRAFT') and (LFreeHangars <= 0) then
  begin
    FRepeatMoreUnit.Stop;
    ShowNoHangars;
  end
  else
  begin
    LUnits := FProduction.AmountTotal;
    AChange := Min(MaxInt - LUnits, AChange);
    if FProduction.Rules.Category = 'STR_CRAFT' then
      AChange := Min(LFreeHangars, AChange);
    FProduction.AmountTotal := LUnits + AChange;
    SetAssignedEngineer;
  end;
end;

procedure TXcomManufactureInfoState.LessUnit(AChange: Integer);
var
  LUnits: Integer;
begin
  if AChange <= 0 then
    Exit;
  LUnits := FProduction.AmountTotal;
  AChange := Min(LUnits - (FProduction.AmountProduced + 1), AChange);
  FProduction.AmountTotal := LUnits - AChange;
  SetAssignedEngineer;
end;

procedure TXcomManufactureInfoState.MoreEngineerClick(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    MoreEngineer(MaxInt);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    MoreEngineer(1);
end;

procedure TXcomManufactureInfoState.LessEngineerClick(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    LessEngineer(MaxInt);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    LessEngineer(1);
end;

procedure TXcomManufactureInfoState.MoreUnitClick(AAction: TXcomAction);
begin
  // nothing is more than infinite
  if FProduction.InfiniteAmount then
    Exit;
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
  begin
    if FProduction.Rules.Category = 'STR_CRAFT' then
      MoreUnit(MaxInt)
    else
    begin
      FProduction.InfiniteAmount := True;
      SetAssignedEngineer;
    end;
  end
  else if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    MoreUnit(1);
end;

procedure TXcomManufactureInfoState.LessUnitClick(AAction: TXcomAction);
begin
  if (AAction.Details^.Button = XCOM_BUTTON_RIGHT) or (AAction.Details^.Button = XCOM_BUTTON_LEFT) then
  begin
    FProduction.InfiniteAmount := False;
    // the units that are produced are over the planned ones, or it was a right click
    if (AAction.Details^.Button = XCOM_BUTTON_RIGHT) or (FProduction.AmountTotal <= FProduction.AmountProduced) then
    begin
      FProduction.AmountTotal := FProduction.AmountProduced + 1;
      SetAssignedEngineer;
    end;
    if AAction.Details^.Button = XCOM_BUTTON_LEFT then
      LessUnit(1);
  end;
end;

procedure TXcomManufactureInfoState.WheelEngineer(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
    MoreEngineer(Host.Options.ChangeValueByMouseWheel)
  else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
    LessEngineer(Host.Options.ChangeValueByMouseWheel);
end;

procedure TXcomManufactureInfoState.WheelUnit(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
    MoreUnit(Host.Options.ChangeValueByMouseWheel)
  else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
    LessUnit(Host.Options.ChangeValueByMouseWheel);
end;

procedure TXcomManufactureInfoState.Think;
begin
  inherited Think;
  FRepeatLessEngineer.Think;
  FRepeatMoreEngineer.Think;
  FRepeatLessUnit.Think;
  FRepeatMoreUnit.Think;
end;

end.
