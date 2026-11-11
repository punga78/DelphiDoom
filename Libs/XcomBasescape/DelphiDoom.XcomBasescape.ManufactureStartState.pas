{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - ManufactureStartState of OpenXcom (the  }
{  requirements to start a production)                                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ManufactureStartState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.XcomMod.RuleManufacture, DelphiDoom.XcomMod.Ruleset;

type
  /// <summary>
  ///   The engineer hours, the cost, the workshop space and the special materials of an item: the button that starts
  ///   the production is shown only when the money, the space and the materials are enough
  /// </summary>
  TXcomManufactureStartState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FItem: TXcomRuleManufacture;
    FCapacity: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FBtnStart: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtManHour: TXcomText;
    FTxtCost: TXcomText;
    FTxtWorkSpace: TXcomText;
    FTxtRequiredItemsTitle: TXcomText;
    FTxtItemNameColumn: TXcomText;
    FTxtUnitRequiredColumn: TXcomText;
    FTxtUnitAvailableColumn: TXcomText;
    FLstRequiredItems: TXcomTextList;
    procedure CancelClick(AAction: TXcomAction);
    procedure StartClick(AAction: TXcomAction);
    procedure ShowError(const AKey: string);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="AItem">The item to produce (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AItem: TXcomRuleManufacture);
    destructor Destroy; override;
    /// <summary>Whether the start button is shown</summary>
    function ProductionPossible: Boolean;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomStrategy.BaseCrafts, DelphiDoom.XcomBasescape.Funding, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomBasescape.ManufactureInfoState;

{ TXcomManufactureStartState }

constructor TXcomManufactureStartState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AItem: TXcomRuleManufacture);
var
  LRuleset: TXcomRuleset;
  LIndex: Integer;
  LName: string;
  LRequired, LAvailable: Integer;
  LPossible: Boolean;
begin
  inherited Create(AHost);
  FBase := ABase;
  FItem := AItem;
  LRuleset := TXcomStrategy.Ruleset(AHost);
  FCapacity := TXcomBaseCapacity.Create(LRuleset);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 160, 0, 20, wpNone);
  FBtnCancel := TXcomTextButton.Create(136, 16, 16, 155);
  FTxtTitle := TXcomText.Create(320, 17, 0, 30);
  FTxtManHour := TXcomText.Create(290, 9, 16, 50);
  FTxtCost := TXcomText.Create(290, 9, 16, 60);
  FTxtWorkSpace := TXcomText.Create(290, 9, 16, 70);
  FTxtRequiredItemsTitle := TXcomText.Create(290, 9, 16, 84);
  FTxtItemNameColumn := TXcomText.Create(60, 16, 30, 92);
  FTxtUnitRequiredColumn := TXcomText.Create(60, 16, 155, 92);
  FTxtUnitAvailableColumn := TXcomText.Create(60, 16, 230, 92);
  FLstRequiredItems := TXcomTextList.Create(Host.Options, Host.Clock, 270, 40, 30, 108);
  FBtnStart := TXcomTextButton.Create(136, 16, 168, 155);
  SetInterface('allocateManufacture');
  Add(FWindow, 'window', 'allocateManufacture');
  Add(FTxtTitle, 'text', 'allocateManufacture');
  Add(FTxtManHour, 'text', 'allocateManufacture');
  Add(FTxtCost, 'text', 'allocateManufacture');
  Add(FTxtWorkSpace, 'text', 'allocateManufacture');
  Add(FBtnCancel, 'button', 'allocateManufacture');
  Add(FTxtRequiredItemsTitle, 'text', 'allocateManufacture');
  Add(FTxtItemNameColumn, 'text', 'allocateManufacture');
  Add(FTxtUnitRequiredColumn, 'text', 'allocateManufacture');
  Add(FTxtUnitAvailableColumn, 'text', 'allocateManufacture');
  Add(FLstRequiredItems, 'list', 'allocateManufacture');
  Add(FBtnStart, 'button', 'allocateManufacture');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK17.SCR'));
  FTxtTitle.SetText(Tr(FItem.Name));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtManHour.SetText(Tr('STR_ENGINEER_HOURS_TO_PRODUCE_ONE_UNIT').Arg(FItem.ManufactureTime));
  FTxtCost.SetText(Tr('STR_COST_PER_UNIT_').Arg(TXcomFunding.Format(FItem.ManufactureCost)));
  FTxtWorkSpace.SetText(Tr('STR_WORK_SPACE_REQUIRED').Arg(FItem.RequiredSpace));
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  LPossible := (TXcomStrategy.SavedGame(AHost).Funds >= FItem.ManufactureCost) and (FCapacity.FreeWorkshops(ABase) > 0);
  FTxtRequiredItemsTitle.SetText(Tr('STR_SPECIAL_MATERIALS_REQUIRED'));
  FTxtRequiredItemsTitle.SetAlign(haCenter);
  FTxtItemNameColumn.SetText(Tr('STR_ITEM_REQUIRED'));
  FTxtItemNameColumn.SetWordWrap(True);
  FTxtUnitRequiredColumn.SetText(Tr('STR_UNITS_REQUIRED'));
  FTxtUnitRequiredColumn.SetWordWrap(True);
  FTxtUnitAvailableColumn.SetText(Tr('STR_UNITS_AVAILABLE'));
  FTxtUnitAvailableColumn.SetWordWrap(True);
  FLstRequiredItems.SetColumns([140, 75, 55]);
  FLstRequiredItems.SetBackground(FWindow);
  for LIndex := 0 to FItem.RequiredItems.Count - 1 do
  begin
    LName := FItem.RequiredItems.Key(LIndex);
    LRequired := FItem.RequiredItems.Value(LIndex);
    LAvailable := 0;
    if Assigned(LRuleset.Items.Find(LName)) then
    begin
      LAvailable := ABase.StorageItems.GetItem(LName);
      LPossible := LPossible and (LAvailable >= LRequired);
    end
    else if Assigned(LRuleset.Crafts.Find(LName)) then
    begin
      LAvailable := TXcomBaseCrafts.Count(ABase, LName);
      LPossible := LPossible and (LAvailable >= LRequired);
    end;
    FLstRequiredItems.AddRow([Tr(LName).Text, IntToStr(LRequired), IntToStr(LAvailable)]);
    FLstRequiredItems.SetCellColor(LIndex, 1, FLstRequiredItems.GetSecondaryColor);
    FLstRequiredItems.SetCellColor(LIndex, 2, FLstRequiredItems.GetSecondaryColor);
  end;
  FTxtRequiredItemsTitle.Visible := FItem.RequiredItems.Count > 0;
  FTxtItemNameColumn.Visible := FItem.RequiredItems.Count > 0;
  FTxtUnitRequiredColumn.Visible := FItem.RequiredItems.Count > 0;
  FTxtUnitAvailableColumn.Visible := FItem.RequiredItems.Count > 0;
  FLstRequiredItems.Visible := FItem.RequiredItems.Count > 0;
  FBtnStart.SetText(Tr('STR_START_PRODUCTION'));
  FBtnStart.OnMouseClick(StartClick);
  FBtnStart.OnKeyboardPress(StartClick, Host.Options.KeyOk);
  FBtnStart.Visible := LPossible;
end;

destructor TXcomManufactureStartState.Destroy;
begin
  inherited Destroy;
  FCapacity.Free;
end;

function TXcomManufactureStartState.ProductionPossible: Boolean;
begin
  Result := FBtnStart.Visible;
end;

procedure TXcomManufactureStartState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomManufactureStartState.ShowError(const AKey: string);
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
  Host.PushState(TXcomErrorMessageState.Create(Host, Tr(AKey), Palette, Byte(LMessage.Color), 'BACK17.SCR',
    LPalette.Color));
end;

procedure TXcomManufactureStartState.StartClick(AAction: TXcomAction);
begin
  if (FItem.Category = 'STR_CRAFT') and (FCapacity.AvailableHangars(FBase) - FCapacity.UsedHangars(FBase) <= 0) then
    ShowError('STR_NO_FREE_HANGARS_FOR_CRAFT_PRODUCTION')
  else if FItem.RequiredSpace > FCapacity.FreeWorkshops(FBase) then
    ShowError('STR_NOT_ENOUGH_WORK_SPACE')
  else
    Host.PushState(TXcomManufactureInfoState.CreateForRule(Host, FBase, FItem));
end;

end.
