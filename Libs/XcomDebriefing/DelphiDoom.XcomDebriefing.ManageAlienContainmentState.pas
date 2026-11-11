{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - ManageAlienContainmentState of         }
{  OpenXcom (the live aliens of a base: which ones are removed)                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.ManageAlienContainmentState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomBasescape.ListArrowTimers;

type
  /// <summary>
  ///   The live aliens in the stores of a base (and the ones under interrogation, which cannot be removed): the arrows
  ///   choose how many of each are removed; they become corpses, or money with Options::canSellLiveAliens. With the
  ///   storage limits enforced and too many aliens the buttons are there only when the aliens left fit, and after OK
  ///   overfull stores open the sale screen. The base, the saved game and the ruleset are not owned
  /// </summary>
  TXcomManageAlienContainmentState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FSavedGame: TXcomSavedGame;
    FRuleset: TXcomRuleset;
    FOrigin: TXcomOptionsOrigin;
    FCapacity: TXcomBaseCapacity;
    FArrows: TXcomListArrowTimers;
    FAliens: TList<string>;
    FQuantities: TList<Integer>;
    FAliensSold: Integer;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtAvailable: TXcomText;
    FTxtUsed: TXcomText;
    FTxtItem: TXcomText;
    FTxtLiveAliens: TXcomText;
    FTxtDeadAliens: TXcomText;
    FTxtInterrogatedAliens: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure Increase(AChange: Integer);
    procedure Decrease(AChange: Integer);
    procedure UpdateStrings;
    procedure FillList;
    function StoredQuantity: Integer;
    function ErrorElementColor(const AId: string): Integer;
  public
    /// <param name="AOrigin">ooBattlescape after a mission (the debriefing), otherwise the basescape</param>
    constructor Create(AHost: TXcomStateHost; const ABase: TXcomBase; const ASavedGame: TXcomSavedGame;
      const ARuleset: TXcomRuleset; AOrigin: TXcomOptionsOrigin);
    destructor Destroy; override;
    procedure Think; override;
    property List: TXcomTextList read FList;
    property OkButton: TXcomTextButton read FBtnOk;
    /// <summary>How many aliens are chosen to be removed (_aliensSold)</summary>
    property AliensSold: Integer read FAliensSold;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomSave.ResearchProject,
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomBasescape.SellState;

{ TXcomManageAlienContainmentState }

constructor TXcomManageAlienContainmentState.Create(AHost: TXcomStateHost; const ABase: TXcomBase;
  const ASavedGame: TXcomSavedGame; const ARuleset: TXcomRuleset; AOrigin: TXcomOptionsOrigin);
var
  LOverCrowded: Boolean;
  LFree: Integer;
begin
  inherited Create(AHost);
  FBase := ABase;
  FSavedGame := ASavedGame;
  FRuleset := ARuleset;
  FOrigin := AOrigin;
  FCapacity := TXcomBaseCapacity.Create(ARuleset);
  FAliens := TList<string>.Create;
  FQuantities := TList<Integer>.Create;
  LFree := FCapacity.AvailableContainment(FBase) - FCapacity.UsedContainment(FBase);
  LOverCrowded := Host.Options.GetBool('storageLimitsEnforced') and (LFree < 0);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  if LOverCrowded then
    FBtnOk := TXcomTextButton.Create(288, 16, 16, 176)
  else
    FBtnOk := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtAvailable := TXcomText.Create(190, 9, 10, 24);
  FTxtUsed := TXcomText.Create(110, 9, 136, 24);
  FTxtItem := TXcomText.Create(120, 9, 10, 41);
  FTxtLiveAliens := TXcomText.Create(54, 18, 153, 32);
  FTxtDeadAliens := TXcomText.Create(54, 18, 207, 32);
  FTxtInterrogatedAliens := TXcomText.Create(54, 18, 261, 32);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 286, 112, 8, 53);
  SetInterface('manageContainment');
  Add(FWindow, 'window', 'manageContainment');
  Add(FBtnOk, 'button', 'manageContainment');
  Add(FBtnCancel, 'button', 'manageContainment');
  Add(FTxtTitle, 'text', 'manageContainment');
  Add(FTxtAvailable, 'text', 'manageContainment');
  Add(FTxtUsed, 'text', 'manageContainment');
  Add(FTxtItem, 'text', 'manageContainment');
  Add(FTxtLiveAliens, 'text', 'manageContainment');
  Add(FTxtDeadAliens, 'text', 'manageContainment');
  Add(FTxtInterrogatedAliens, 'text', 'manageContainment');
  Add(FList, 'list', 'manageContainment');
  CenterAllSurfaces;
  if AOrigin = ooBattlescape then
    FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'))
  else
    FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Tr('STR_REMOVE_SELECTED'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  if LOverCrowded then
  begin
    FBtnCancel.Visible := False;
    FBtnOk.Visible := False;
  end;
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_MANAGE_CONTAINMENT'));
  FTxtItem.SetText(Tr('STR_ALIEN'));
  FTxtLiveAliens.SetText(Tr('STR_LIVE_ALIENS'));
  FTxtLiveAliens.SetWordWrap(True);
  FTxtLiveAliens.SetVerticalAlign(vaBottom);
  FTxtDeadAliens.SetText(Tr('STR_DEAD_ALIENS'));
  FTxtDeadAliens.SetWordWrap(True);
  FTxtDeadAliens.SetVerticalAlign(vaBottom);
  FTxtInterrogatedAliens.SetText(Tr('STR_UNDER_INTERROGATION'));
  FTxtInterrogatedAliens.SetWordWrap(True);
  FTxtInterrogatedAliens.SetVerticalAlign(vaBottom);
  FTxtAvailable.SetText(Tr('STR_SPACE_AVAILABLE').Arg(LFree));
  FTxtUsed.SetText(Tr('STR_SPACE_USED').Arg(FCapacity.UsedContainment(FBase)));
  FList.SetArrowColumn(184, aoHorizontal);
  FList.SetColumns([160, 64, 46, 46]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(2);
  // here the right arrow adds to the aliens to remove and the left one takes away (the lists of quantities do the
  // opposite): the two actions are swapped, and so is the wheel
  FArrows := TXcomListArrowTimers.Create(Host.Clock, Host.Options, FList, Decrease, Increase, True);
  FillList;
end;

destructor TXcomManageAlienContainmentState.Destroy;
begin
  inherited Destroy;
  FArrows.Free;
  FCapacity.Free;
  FQuantities.Free;
  FAliens.Free;
end;

procedure TXcomManageAlienContainmentState.FillList;
var
  LResearchList: TList<string>;
  LProject: TXcomResearchProject;
  LItem: TXcomRuleItem;
  LName, LInterrogated: string;
  LQuantity, LFound: Integer;
begin
  LResearchList := TList<string>.Create;
  try
    for LProject in FBase.Research do
    begin
      LItem := FRuleset.Items.Find(LProject.Rules.Name);
      if Assigned(LItem) and LItem.LiveAlien then
        LResearchList.Add(LProject.Rules.Name);
    end;
    for LName in FRuleset.Items.Index do
    begin
      LQuantity := FBase.StorageItems.GetItem(LName);
      if (LQuantity > 0) and FRuleset.Items.Find(LName).LiveAlien then
      begin
        FQuantities.Add(0);
        FAliens.Add(LName);
        LFound := LResearchList.IndexOf(LName);
        if LFound >= 0 then
        begin
          LInterrogated := '1';
          LResearchList.Delete(LFound);
        end
        else
          LInterrogated := '0';
        FList.AddRow([Tr(LName).Text, IntToStr(LQuantity), '0', LInterrogated]);
      end;
    end;
    // the aliens that are only under interrogation: none in the stores
    for LName in LResearchList do
    begin
      FAliens.Add(LName);
      FQuantities.Add(0);
      FList.AddRow([Tr(LName).Text, '0', '0', '1']);
      FList.SetRowColor(FQuantities.Count - 1, FList.GetSecondaryColor);
    end;
  finally
    LResearchList.Free;
  end;
end;

procedure TXcomManageAlienContainmentState.Think;
begin
  inherited Think;
  FArrows.Think;
end;

function TXcomManageAlienContainmentState.ErrorElementColor(const AId: string): Integer;
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
begin
  Result := 0;
  LInterface := Host.Resources.GetInterface('manageContainment');
  if (LInterface <> nil) and LInterface.TryGetElement(AId, LElement) then
    Result := LElement.Color;
end;

procedure TXcomManageAlienContainmentState.OkClick(AAction: TXcomAction);
var
  LIndex: Integer;
  LCorpse, LBackground: string;
begin
  for LIndex := 0 to FQuantities.Count - 1 do
    if FQuantities[LIndex] > 0 then
    begin
      FBase.StorageItems.RemoveItem(FAliens[LIndex], FQuantities[LIndex]);
      if Host.Options.GetBool('canSellLiveAliens') then
        FSavedGame.SetFunds(FSavedGame.Funds +
          Int64(FRuleset.Items.Find(FAliens[LIndex]).SellCost) * FQuantities[LIndex])
      else
      begin
        // the corpse of the armor of the unit of that name
        LCorpse := FRuleset.Armors.Find(FRuleset.Units.Find(FAliens[LIndex]).Armor).CorpseGeoscape;
        FBase.StorageItems.AddItem(LCorpse, FQuantities[LIndex]);
      end;
    end;
  Host.PopState;
  if Host.Options.GetBool('storageLimitsEnforced') and FCapacity.StoresOverfull(FBase, 0) then
  begin
    Host.PushState(TXcomSellState.Create(Host, FBase, FOrigin = ooBattlescape));
    if FOrigin = ooBattlescape then
      LBackground := 'BACK01.SCR'
    else
      LBackground := 'BACK13.SCR';
    Host.PushState(TXcomErrorMessageState.Create(Host, Tr('STR_STORAGE_EXCEEDED').Arg(FBase.Name).Text, Palette,
      Byte(ErrorElementColor('errorMessage')), LBackground, ErrorElementColor('errorPalette')));
  end;
end;

procedure TXcomManageAlienContainmentState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

function TXcomManageAlienContainmentState.StoredQuantity: Integer;
begin
  Result := FBase.StorageItems.GetItem(FAliens[FArrows.Selected]);
end;

procedure TXcomManageAlienContainmentState.Increase(AChange: Integer);
var
  LLeft: Integer;
begin
  if (FArrows.Selected < 0) or (FArrows.Selected >= FQuantities.Count) then
    Exit;
  LLeft := StoredQuantity - FQuantities[FArrows.Selected];
  if (AChange <= 0) or (LLeft <= 0) then
    Exit;
  AChange := Min(LLeft, AChange);
  FQuantities[FArrows.Selected] := FQuantities[FArrows.Selected] + AChange;
  Inc(FAliensSold, AChange);
  UpdateStrings;
end;

procedure TXcomManageAlienContainmentState.Decrease(AChange: Integer);
begin
  if (FArrows.Selected < 0) or (FArrows.Selected >= FQuantities.Count) then
    Exit;
  if (AChange <= 0) or (FQuantities[FArrows.Selected] <= 0) then
    Exit;
  AChange := Min(FQuantities[FArrows.Selected], AChange);
  FQuantities[FArrows.Selected] := FQuantities[FArrows.Selected] - AChange;
  Dec(FAliensSold, AChange);
  UpdateStrings;
end;

procedure TXcomManageAlienContainmentState.UpdateStrings;
var
  LLeft, LAliens, LSpaces: Integer;
begin
  LLeft := StoredQuantity - FQuantities[FArrows.Selected];
  if LLeft = 0 then
    FList.SetRowColor(FArrows.Selected, FList.GetSecondaryColor)
  else
    FList.SetRowColor(FArrows.Selected, FList.GetColor);
  FList.SetCellText(FArrows.Selected, 1, IntToStr(LLeft));
  FList.SetCellText(FArrows.Selected, 2, IntToStr(FQuantities[FArrows.Selected]));
  LAliens := FCapacity.UsedContainment(FBase) - FAliensSold;
  LSpaces := FCapacity.AvailableContainment(FBase) - LAliens;
  if Host.Options.GetBool('storageLimitsEnforced') then
    FBtnOk.Visible := LSpaces >= 0;
  FTxtAvailable.SetText(Tr('STR_SPACE_AVAILABLE').Arg(LSpaces));
  FTxtUsed.SetText(Tr('STR_SPACE_USED').Arg(LAliens));
end;

end.
