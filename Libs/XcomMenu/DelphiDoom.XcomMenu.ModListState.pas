{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ModListState of OpenXcom (the master mod,    }
{  the mods that can be switched on and their order)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.ModListState;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Options,
  DelphiDoom.XcomEngine.ModInfo, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.ComboBox;

type
  /// <summary>
  ///   The Mods screen of the main menu: the combo box of the master mods (the base game), the list of the other mods
  ///   that work with that master (name, arrows that move the mod up and down, whether it is on) and OK and Cancel.
  ///   The changes are in Options.Mods: OK saves them, Cancel loads the saved ones back
  /// </summary>
  TXcomModListState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FTxtMaster: TXcomText;
    FCbxMasters: TXcomComboBox;
    FLstMods: TXcomTextList;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTooltip: TXcomText;
    FMasters: TList<TXcomModInfo>;
    FMods: TList<TXcomModSetting>;
    FCurrentMasterId: string;
    FCurrentMasterIndex: Integer;
    FReload: Boolean;
    function MakeTooltip(AInfo: TXcomModInfo): string;
    procedure MasterHover(AAction: TXcomAction);
    procedure MasterChange(AAction: TXcomAction);
    procedure ChangeMasterMod;
    procedure ModsRefresh(AScrollLocation: Integer);
    procedure ModsHover(AAction: TXcomAction);
    procedure ModsClick(AAction: TXcomAction);
    procedure ToggleMod;
    procedure LeftArrowClick(AAction: TXcomAction);
    procedure RightArrowClick(AAction: TXcomAction);
    procedure MoveModUp(ARow: Integer; AMax: Boolean = False);
    procedure MoveModDown(ARow: Integer; AMax: Boolean = False);
    procedure MoveAbove(const ASource, ADestination: TXcomModSetting);
    procedure MoveBelow(const ASource, ADestination: TXcomModSetting);
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure TooltipIn(AAction: TXcomAction);
    procedure TooltipOut(AAction: TXcomAction);
    function IndexOfMod(const AId: string): Integer;
  public
    constructor Create(AHost: TXcomStateHost);
    destructor Destroy; override;
    /// <summary>The list of the mods that are shown (those that work with the master in use)</summary>
    property List: TXcomTextList read FLstMods;
    property Masters: TXcomComboBox read FCbxMasters;
    /// <summary>The mods were changed in a way that needs the game to load its data again (Options::reload)</summary>
    property ReloadNeeded: Boolean read FReload;
  end;

implementation

uses
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomMenu.ModConfirmExtendedState;

constructor TXcomModListState.Create(AHost: TXcomStateHost);
var
  LMeasure: TXcomText;
  LYes: Integer;
  LNo: Integer;
  LRightColumn: Integer;
  LArrowColumn: Integer;
  LLeftColumn: Integer;
  LNames: TArray<string>;
  LSetting: TXcomModSetting;
  LInfo: TXcomModInfo;
  LMods: TArray<TXcomModSetting>;
begin
  inherited Create(AHost);
  FMasters := TList<TXcomModInfo>.Create;
  FMods := TList<TXcomModSetting>.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FTxtMaster := TXcomText.Create(305, 9, 8, 8);
  FCbxMasters := TXcomComboBox.Create(Self, 305, 16, 8, 18);
  FLstMods := TXcomTextList.Create(Host.Options, Host.Clock, 288, 104, 8, 40);
  FBtnOk := TXcomTextButton.Create(100, 16, 8, 176);
  FBtnCancel := TXcomTextButton.Create(100, 16, 212, 176);
  FTxtTooltip := TXcomText.Create(305, 25, 8, 148);
  SetInterface('modsMenu');
  Add(FWindow, 'window', 'modsMenu');
  Add(FTxtMaster, 'text', 'modsMenu');
  Add(FLstMods, 'optionLists', 'modsMenu');
  Add(FBtnOk, 'button2', 'modsMenu');
  Add(FBtnCancel, 'button2', 'modsMenu');
  Add(FTxtTooltip, 'tooltip', 'modsMenu');
  Add(FCbxMasters, 'button1', 'modsMenu');
  CenterAllSurfaces;
  // how much room do we need for YES/NO
  LMeasure := TXcomText.Create(100, 9, 0, 0);
  try
    LMeasure.InitText(Host.Resources.GetFont('FONT_BIG'), Host.Resources.GetFont('FONT_SMALL'), Host.Language);
    LMeasure.SetText(Tr('STR_YES'));
    LYes := LMeasure.GetTextWidth;
    LMeasure.SetText(Tr('STR_NO'));
    LNo := LMeasure.GetTextWidth;
  finally
    LMeasure.Free;
  end;
  LRightColumn := Max(LYes, LNo) + 2;
  LArrowColumn := 25;
  LLeftColumn := FLstMods.Width - (LRightColumn + LArrowColumn);
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FTxtMaster.SetText(Tr('STR_BASE_GAME'));
  // scan for masters
  if Host.ModCatalog <> nil then
  begin
    LMods := Host.Options.Mods;
    Host.ModCatalog.Refresh(LMods);
    Host.Options.Mods := LMods;
  end;
  FCurrentMasterIndex := 0;
  for LSetting in Host.Options.Mods do
  begin
    if (Host.ModCatalog = nil) or not Host.ModCatalog.TryGetInfo(LSetting.Id, LInfo) or not LInfo.IsMaster then
      Continue;
    if LSetting.Active then
      FCurrentMasterId := LSetting.Id
    else if FCurrentMasterId = '' then
      Inc(FCurrentMasterIndex);
    FMasters.Add(LInfo);
    SetLength(LNames, Length(LNames) + 1);
    LNames[High(LNames)] := LInfo.Name;
  end;
  FCbxMasters.SetOptions(LNames);
  FCbxMasters.SetSelected(FCurrentMasterIndex);
  FCbxMasters.OnChange(MasterChange);
  FCbxMasters.OnMouseIn(TooltipIn);
  FCbxMasters.OnMouseOut(TooltipOut);
  FCbxMasters.OnMouseOver(MasterHover);
  FCbxMasters.OnListMouseIn(TooltipIn);
  FCbxMasters.OnListMouseOut(TooltipOut);
  FCbxMasters.OnListMouseOver(MasterHover);
  FLstMods.SetArrowColumn(LLeftColumn + 1, aoVertical);
  FLstMods.SetColumns([LLeftColumn, LArrowColumn, LRightColumn]);
  FLstMods.SetAlign(haRight, 1);
  FLstMods.SetSelectable(True);
  FLstMods.SetBackground(FWindow);
  FLstMods.SetWordWrap(True);
  FLstMods.OnMouseClick(ModsClick);
  FLstMods.OnLeftArrowClick(LeftArrowClick);
  FLstMods.OnRightArrowClick(RightArrowClick);
  FLstMods.OnMouseIn(TooltipIn);
  FLstMods.OnMouseOut(TooltipOut);
  FLstMods.OnMouseOver(ModsHover);
  ModsRefresh(0);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTooltip.SetWordWrap(True);
end;

destructor TXcomModListState.Destroy;
begin
  FMods.Free;
  FMasters.Free;
  inherited Destroy;
end;

function TXcomModListState.IndexOfMod(const AId: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(Host.Options.Mods) do
    if Host.Options.Mods[LIndex].Id = AId then
      Exit(LIndex);
  Result := -1;
end;

function TXcomModListState.MakeTooltip(AInfo: TXcomModInfo): string;
begin
  Result := Tr('STR_MODS_TOOLTIP').Arg(AInfo.Version).Arg(AInfo.Author).Arg(AInfo.Description).Text;
end;

procedure TXcomModListState.MasterHover(AAction: TXcomAction);
var
  LIndex: Integer;
begin
  LIndex := FCbxMasters.GetHoveredListIdx;
  if (LIndex >= 0) and (LIndex < FMasters.Count) then
    FTxtTooltip.SetText(MakeTooltip(FMasters[LIndex]));
end;

procedure TXcomModListState.MasterChange(AAction: TXcomAction);
var
  LInfo: TXcomModInfo;
begin
  LInfo := FMasters[FCbxMasters.GetSelected];
  // when changing a master mod, check if it requires an extended engine: the player confirms or goes back
  if not LInfo.EngineOk then
  begin
    Host.PushState(TXcomModConfirmExtendedState.Create(Host, LInfo.RequiredExtendedEngine,
      procedure
      begin
        ChangeMasterMod;
      end,
      procedure
      begin
        // revertMasterMod
        FCbxMasters.SetSelected(FCurrentMasterIndex);
      end));
    Exit;
  end;
  ChangeMasterMod;
end;

procedure TXcomModListState.ChangeMasterMod;
var
  LMods: TArray<TXcomModSetting>;
  LIndex: Integer;
  LMasterId: string;
begin
  LMasterId := FMasters[FCbxMasters.GetSelected].Id;
  LMods := Host.Options.Mods;
  for LIndex := 0 to High(LMods) do
    if LMods[LIndex].Id = LMasterId then
      LMods[LIndex].Active := True
    else if LMods[LIndex].Id = FCurrentMasterId then
      LMods[LIndex].Active := False;
  Host.Options.Mods := LMods;
  FReload := True;
  FCurrentMasterIndex := FCbxMasters.GetSelected;
  FCurrentMasterId := LMasterId;
  ModsRefresh(0);
end;

procedure TXcomModListState.ModsRefresh(AScrollLocation: Integer);
var
  LSetting: TXcomModSetting;
  LInfo: TXcomModInfo;
  LState: string;
begin
  FLstMods.ClearList;
  FMods.Clear;
  // only show mods that work with the current master
  for LSetting in Host.Options.Mods do
  begin
    if (Host.ModCatalog = nil) or not Host.ModCatalog.TryGetInfo(LSetting.Id, LInfo) then
      Continue;
    if LInfo.IsMaster or not LInfo.CanActivate(FCurrentMasterId) then
      Continue;
    if LSetting.Active then
      LState := Tr('STR_YES').Text
    else
      LState := Tr('STR_NO').Text;
    FLstMods.AddRow([LInfo.Name, '', LState]);
    FMods.Add(LSetting);
  end;
  FLstMods.ScrollTo(AScrollLocation);
end;

procedure TXcomModListState.ModsHover(AAction: TXcomAction);
var
  LRow: Integer;
  LInfo: TXcomModInfo;
begin
  LRow := FLstMods.GetSelectedRow;
  if (LRow >= 0) and (LRow < FMods.Count) and Host.ModCatalog.TryGetInfo(FMods[LRow].Id, LInfo) then
    FTxtTooltip.SetText(MakeTooltip(LInfo));
end;

procedure TXcomModListState.ModsClick(AAction: TXcomAction);
var
  LRow: Integer;
  LInfo: TXcomModInfo;
begin
  if (AAction.AbsoluteXMouse >= FLstMods.GetArrowsLeftEdge) and (AAction.AbsoluteXMouse <= FLstMods.GetArrowsRightEdge) then
    // an arrow click is not a toggle
    Exit;
  LRow := FLstMods.GetSelectedRow;
  if (LRow < 0) or (LRow >= FMods.Count) then
    Exit;
  // when activating a mod, check if it requires an extended engine: the player confirms first
  if (not FMods[LRow].Active) and Host.ModCatalog.TryGetInfo(FMods[LRow].Id, LInfo) and not LInfo.EngineOk then
  begin
    Host.PushState(TXcomModConfirmExtendedState.Create(Host, LInfo.RequiredExtendedEngine,
      procedure
      begin
        ToggleMod;
      end));
    Exit;
  end;
  ToggleMod;
end;

procedure TXcomModListState.ToggleMod;
var
  LRow: Integer;
  LIndex: Integer;
  LMod: TXcomModSetting;
  LMods: TArray<TXcomModSetting>;
begin
  LRow := FLstMods.GetSelectedRow;
  LMod := FMods[LRow];
  LIndex := IndexOfMod(LMod.Id);
  if LIndex >= 0 then
  begin
    LMod.Active := not LMod.Active;
    FMods[LRow] := LMod;
    LMods := Host.Options.Mods;
    LMods[LIndex].Active := LMod.Active;
    Host.Options.Mods := LMods;
    if LMod.Active then
      FLstMods.SetCellText(LRow, 2, Tr('STR_YES').Text)
    else
      FLstMods.SetCellText(LRow, 2, Tr('STR_NO').Text);
  end;
  FReload := True;
end;

procedure TXcomModListState.LeftArrowClick(AAction: TXcomAction);
var
  LRow: Integer;
begin
  LRow := FLstMods.GetSelectedRow;
  if LRow <= 0 then
    Exit;
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    MoveModUp(LRow)
  else if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    MoveModUp(LRow, True);
end;

procedure TXcomModListState.RightArrowClick(AAction: TXcomAction);
var
  LRow: Integer;
begin
  LRow := FLstMods.GetSelectedRow;
  if (FMods.Count = 0) or (LRow < 0) or (LRow >= FMods.Count - 1) then
    Exit;
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    MoveModDown(LRow)
  else if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    MoveModDown(LRow, True);
end;

procedure TXcomModListState.MoveAbove(const ASource, ADestination: TXcomModSetting);
var
  LMods: TList<TXcomModSetting>;
  LIndex: Integer;
begin
  LMods := TList<TXcomModSetting>.Create;
  try
    LMods.AddRange(Host.Options.Mods);
    // insert a copy of the source above the destination
    for LIndex := 0 to LMods.Count - 1 do
      if LMods[LIndex].Id = ADestination.Id then
      begin
        LMods.Insert(LIndex, ASource);
        Break;
      end;
    // remove the old copy of the source (the last one with its id)
    for LIndex := LMods.Count - 1 downto 0 do
      if LMods[LIndex].Id = ASource.Id then
      begin
        LMods.Delete(LIndex);
        Break;
      end;
    Host.Options.Mods := LMods.ToArray;
  finally
    LMods.Free;
  end;
end;

procedure TXcomModListState.MoveBelow(const ASource, ADestination: TXcomModSetting);
var
  LMods: TList<TXcomModSetting>;
  LIndex: Integer;
begin
  LMods := TList<TXcomModSetting>.Create;
  try
    LMods.AddRange(Host.Options.Mods);
    // insert a copy of the source below the destination (the last one with its id)
    for LIndex := LMods.Count - 1 downto 0 do
      if LMods[LIndex].Id = ADestination.Id then
      begin
        LMods.Insert(LIndex + 1, ASource);
        Break;
      end;
    // remove the first copy of the source
    for LIndex := 0 to LMods.Count - 1 do
      if LMods[LIndex].Id = ASource.Id then
      begin
        LMods.Delete(LIndex);
        Break;
      end;
    Host.Options.Mods := LMods.ToArray;
  finally
    LMods.Free;
  end;
end;

procedure TXcomModListState.MoveModUp(ARow: Integer; AMax: Boolean);
var
  LScroll: Integer;
  LTarget: Integer;
  LIndex: Integer;
begin
  if AMax then
  begin
    MoveAbove(FMods[ARow], FMods[0]);
    // the scroll position stays
    ModsRefresh(FLstMods.GetScroll);
  end
  else
  begin
    // the target scroll position (the mouse is not moved along with the row: SDL_WarpMouse is not ported)
    LScroll := FLstMods.GetScroll;
    LTarget := 0;
    for LIndex := 0 to ARow - 2 do
      Inc(LTarget, FLstMods.GetNumTextLines(LIndex));
    if LScroll >= LTarget then
      FLstMods.ScrollTo(LTarget);
    MoveAbove(FMods[ARow], FMods[ARow - 1]);
    ModsRefresh(FLstMods.GetScroll);
  end;
  FReload := True;
end;

procedure TXcomModListState.MoveModDown(ARow: Integer; AMax: Boolean);
var
  LScroll: Integer;
  LTarget: Integer;
  LIndex: Integer;
begin
  if AMax then
  begin
    MoveBelow(FMods[ARow], FMods[FMods.Count - 1]);
    ModsRefresh(FLstMods.GetScroll);
  end
  else
  begin
    LScroll := FLstMods.GetScroll;
    LTarget := 0;
    for LIndex := 0 to ARow + 1 do
      if LIndex <> ARow then
        Inc(LTarget, FLstMods.GetNumTextLines(LIndex));
    if LScroll + FLstMods.GetVisibleRows <= LTarget then
      FLstMods.ScrollTo(LTarget - FLstMods.GetVisibleRows + 1);
    MoveBelow(FMods[ARow], FMods[ARow + 1]);
    ModsRefresh(FLstMods.GetScroll);
  end;
  FReload := True;
end;

procedure TXcomModListState.OkClick(AAction: TXcomAction);
begin
  // Options::save(); the game does not load its data again for the new mods (StartState): it goes back
  if Host.OptionsStore <> nil then
    Host.OptionsStore.Save(Host.Options);
  Host.PopState;
end;

procedure TXcomModListState.CancelClick(AAction: TXcomAction);
begin
  FReload := False;
  // Options::load(): the saved mods come back
  if Host.OptionsStore <> nil then
    Host.OptionsStore.Load(Host.Options);
  Host.PopState;
end;

procedure TXcomModListState.TooltipIn(AAction: TXcomAction);
begin
  // the controls of this screen have no tooltip key: the text goes empty, and the hover fills it
  FTxtTooltip.SetText('');
end;

procedure TXcomModListState.TooltipOut(AAction: TXcomAction);
begin
  FTxtTooltip.SetText('');
end;

end.
