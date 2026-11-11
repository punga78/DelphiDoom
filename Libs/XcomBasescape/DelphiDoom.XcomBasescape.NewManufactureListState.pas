{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - NewManufactureListState of OpenXcom     }
{  (the items that can be produced in a base)                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.NewManufactureListState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomMod.RuleManufacture;

type
  /// <summary>
  ///   "Production items": the items whose research is done and that the base does not produce, with a filter by
  ///   category; a click opens the screen that starts the production
  /// </summary>
  TXcomNewManufactureListState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FPossible: TList<TXcomRuleManufacture>;
    FCategories: TList<string>;
    FDisplayed: TList<TXcomRuleManufacture>;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtCategory: TXcomText;
    FLstManufacture: TXcomTextList;
    FCbxCategory: TXcomComboBox;
    procedure OkClick(AAction: TXcomAction);
    procedure ProductionClick(AAction: TXcomAction);
    procedure CategoryChange(AAction: TXcomAction);
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
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomStrategy.ResearchRules,
  DelphiDoom.XcomBasescape.ManufactureStartState;

{ TXcomNewManufactureListState }

constructor TXcomNewManufactureListState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LRules: TXcomResearchRules;
  LRule: TXcomRuleManufacture;
  LOptions: TArray<string>;
begin
  inherited Create(AHost);
  FBase := ABase;
  FPossible := nil;
  FCategories := TList<string>.Create;
  FDisplayed := TList<TXcomRuleManufacture>.Create;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 156, 0, 22, wpBoth);
  FBtnOk := TXcomTextButton.Create(304, 16, 8, 154);
  FTxtTitle := TXcomText.Create(320, 17, 0, 30);
  FTxtItem := TXcomText.Create(156, 9, 10, 62);
  FTxtCategory := TXcomText.Create(130, 9, 166, 62);
  FLstManufacture := TXcomTextList.Create(Host.Options, Host.Clock, 288, 80, 8, 70);
  FCbxCategory := TXcomComboBox.Create(Self, 146, 16, 166, 46);
  SetInterface('selectNewManufacture');
  Add(FWindow, 'window', 'selectNewManufacture');
  Add(FBtnOk, 'button', 'selectNewManufacture');
  Add(FTxtTitle, 'text', 'selectNewManufacture');
  Add(FTxtItem, 'text', 'selectNewManufacture');
  Add(FTxtCategory, 'text', 'selectNewManufacture');
  Add(FLstManufacture, 'list', 'selectNewManufacture');
  Add(FCbxCategory, 'catBox', 'selectNewManufacture');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK17.SCR'));
  FTxtTitle.SetText(Tr('STR_PRODUCTION_ITEMS'));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtCategory.SetText(Tr('STR_CATEGORY'));
  FLstManufacture.SetColumns([156, 130]);
  FLstManufacture.SetSelectable(True);
  FLstManufacture.SetBackground(FWindow);
  FLstManufacture.SetMargin(2);
  FLstManufacture.OnMouseClick(ProductionClick);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  LRules := TXcomResearchRules.Create(TXcomStrategy.SavedGame(AHost), TXcomStrategy.Ruleset(AHost));
  try
    FPossible := LRules.AvailableProductions(ABase);
  finally
    LRules.Free;
  end;
  FCategories.Add('STR_ALL_ITEMS');
  for LRule in FPossible do
    if not FCategories.Contains(LRule.Category) then
      FCategories.Add(LRule.Category);
  LOptions := FCategories.ToArray;
  FCbxCategory.SetOptions(LOptions, True);
  FCbxCategory.OnChange(CategoryChange);
end;

destructor TXcomNewManufactureListState.Destroy;
begin
  inherited Destroy;
  FDisplayed.Free;
  FCategories.Free;
  FPossible.Free;
end;

procedure TXcomNewManufactureListState.Init;
begin
  inherited Init;
  FillProductionList;
end;

procedure TXcomNewManufactureListState.FillProductionList;
var
  LRules: TXcomResearchRules;
  LRule: TXcomRuleManufacture;
  LSelected: string;
begin
  FLstManufacture.ClearList;
  FPossible.Free;
  LRules := TXcomResearchRules.Create(TXcomStrategy.SavedGame(Host), TXcomStrategy.Ruleset(Host));
  try
    FPossible := LRules.AvailableProductions(FBase);
  finally
    LRules.Free;
  end;
  FDisplayed.Clear;
  LSelected := FCategories[FCbxCategory.GetSelected];
  for LRule in FPossible do
    if (LRule.Category = LSelected) or (LSelected = 'STR_ALL_ITEMS') then
    begin
      FLstManufacture.AddRow([Tr(LRule.Name).Text, Tr(LRule.Category).Text]);
      FDisplayed.Add(LRule);
    end;
end;

procedure TXcomNewManufactureListState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomNewManufactureListState.CategoryChange(AAction: TXcomAction);
begin
  FillProductionList;
end;

procedure TXcomNewManufactureListState.ProductionClick(AAction: TXcomAction);
begin
  if (FLstManufacture.GetSelectedRow >= 0) and (FLstManufacture.GetSelectedRow < FDisplayed.Count) then
    Host.PushState(TXcomManufactureStartState.Create(Host, FBase, FDisplayed[FLstManufacture.GetSelectedRow]));
end;

end.
