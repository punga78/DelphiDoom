{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - CraftSoldiersState of OpenXcom (the    }
{  crew of a craft)                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.CraftSoldiersState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ComboBox, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Soldier;

type
  /// <summary>
  ///   The crew of a craft: a click puts a soldier in the craft or takes him out, the arrows reorder the list
  ///   and the combo box sorts it (stable). Declared difference: the C++ warps the mouse after moving a row with the
  ///   arrows, here the pointer stays where it is
  /// </summary>
  TXcomCraftSoldiersState = class(TXcomState)
  strict private
    type
      TStatFunction = function(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer;
    var
      FBase: TXcomBase;
      FCraft: TXcomCraft;
      FOtherCraftColor: Byte;
      FWindow: TXcomWindow;
      FBtnOk: TXcomTextButton;
      FTxtTitle: TXcomText;
      FTxtName: TXcomText;
      FTxtRank: TXcomText;
      FTxtCraft: TXcomText;
      FTxtAvailable: TXcomText;
      FTxtUsed: TXcomText;
      FCbxSortBy: TXcomComboBox;
      FList: TXcomTextList;
      FOriginalOrder: TList<TXcomSoldier>;
      FSortFunctions: TList<TStatFunction>;
    class function RankStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function MissionsStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function KillsStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function RecoveryStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function TimeUnitsStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function StaminaStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function HealthStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function BraveryStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function ReactionsStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function FiringStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function ThrowingStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function StrengthStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function PsiStrengthStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function PsiSkillStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    class function MeleeStat(const AState: TXcomCraftSoldiersState; ASoldier: TXcomSoldier): Integer; static;
    function PsiRequirementsResearched: Boolean;
    procedure AddSortOption(var AOptions: TArray<string>; const AKey: string; AFunction: TStatFunction);
    procedure UpdateSpace;
    procedure InitList;
    procedure SortByChange(AAction: TXcomAction);
    procedure OkClick(AAction: TXcomAction);
    procedure LeftArrowClick(AAction: TXcomAction);
    procedure RightArrowClick(AAction: TXcomAction);
    procedure MoveSoldierUp(AAction: TXcomAction; ARow: Integer; AToTop: Boolean = False);
    procedure MoveSoldierDown(AAction: TXcomAction; ARow: Integer; AToBottom: Boolean = False);
    procedure SoldiersClick(AAction: TXcomAction);
    procedure SoldiersPress(AAction: TXcomAction);
    procedure ResetSortBox;
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ACraft">The index of the craft in the base</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraft: Integer);
    destructor Destroy; override;
    procedure Init; override;
    property List: TXcomTextList read FList;
    property SortBox: TXcomComboBox read FCbxSortBy;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.Ruleset,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.SoldierInfoState;

{ TXcomCraftSoldiersState }

class function TXcomCraftSoldiersState.RankStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.Rank;
end;

class function TXcomCraftSoldiersState.MissionsStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.Missions;
end;

class function TXcomCraftSoldiersState.KillsStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.Kills;
end;

class function TXcomCraftSoldiersState.RecoveryStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.WoundRecovery;
end;

class function TXcomCraftSoldiersState.TimeUnitsStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.TimeUnits;
end;

class function TXcomCraftSoldiersState.StaminaStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Stamina;
end;

class function TXcomCraftSoldiersState.HealthStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Health;
end;

class function TXcomCraftSoldiersState.BraveryStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Bravery;
end;

class function TXcomCraftSoldiersState.ReactionsStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Reactions;
end;

class function TXcomCraftSoldiersState.FiringStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Firing;
end;

class function TXcomCraftSoldiersState.ThrowingStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Throwing;
end;

class function TXcomCraftSoldiersState.StrengthStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Strength;
end;

class function TXcomCraftSoldiersState.PsiStrengthStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  // don't reveal (relative) psi strength before it would otherwise be known
  if (ASoldier.CurrentStats.PsiSkill > 0) or (AState.Host.Options.GetBool('psiStrengthEval') and
    AState.PsiRequirementsResearched) then
    Result := ASoldier.CurrentStats.PsiStrength
  else
    Result := 0;
end;

class function TXcomCraftSoldiersState.PsiSkillStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  // protect against a negative psiSkill (possible with anytimePsiTraining)
  if ASoldier.CurrentStats.PsiSkill > 0 then
    Result := ASoldier.CurrentStats.PsiSkill
  else
    Result := 0;
end;

class function TXcomCraftSoldiersState.MeleeStat(const AState: TXcomCraftSoldiersState;
  ASoldier: TXcomSoldier): Integer;
begin
  Result := ASoldier.CurrentStats.Melee;
end;

function TXcomCraftSoldiersState.PsiRequirementsResearched: Boolean;
var
  LRuleset: TXcomRuleset;
  LName: string;
  LRequirements: TArray<string>;
begin
  // Mod::getPsiRequirements: the requirements of the first facility with psionic laboratories
  LRuleset := TXcomStrategy.Ruleset(Host);
  LRequirements := nil;
  for LName in LRuleset.Facilities.Index do
    if LRuleset.Facilities.Find(LName).PsiLaboratories > 0 then
    begin
      LRequirements := LRuleset.Facilities.Find(LName).Requirements;
      Break;
    end;
  Result := TXcomStrategy.SavedGame(Host).IsResearched(LRequirements);
end;

procedure TXcomCraftSoldiersState.AddSortOption(var AOptions: TArray<string>; const AKey: string;
  AFunction: TStatFunction);
begin
  SetLength(AOptions, Length(AOptions) + 1);
  AOptions[High(AOptions)] := Tr(AKey).Text;
  FSortFunctions.Add(AFunction);
end;

constructor TXcomCraftSoldiersState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ACraft: Integer);
var
  LOptions: TArray<string>;
  LElement: TXcomInterfaceElement;
  LInterface: TXcomRuleInterface;
  LSoldier: TXcomSoldier;
  LShowPsiStrength, LShowPsiSkill: Boolean;
begin
  inherited Create(AHost);
  FBase := ABase;
  FCraft := FBase.Crafts[ACraft];
  FOriginalOrder := TList<TXcomSoldier>.Create;
  FOriginalOrder.AddRange(FBase.Soldiers);
  FSortFunctions := TList<TStatFunction>.Create;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(300, 17, 16, 7);
  FTxtName := TXcomText.Create(114, 9, 16, 32);
  FTxtRank := TXcomText.Create(102, 9, 122, 32);
  FTxtCraft := TXcomText.Create(84, 9, 224, 32);
  FTxtAvailable := TXcomText.Create(110, 9, 16, 24);
  FTxtUsed := TXcomText.Create(110, 9, 122, 24);
  FCbxSortBy := TXcomComboBox.Create(Self, 148, 16, 8, 176, True);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 40);
  SetInterface('craftSoldiers');
  Add(FWindow, 'window', 'craftSoldiers');
  Add(FBtnOk, 'button', 'craftSoldiers');
  Add(FTxtTitle, 'text', 'craftSoldiers');
  Add(FTxtName, 'text', 'craftSoldiers');
  Add(FTxtRank, 'text', 'craftSoldiers');
  Add(FTxtCraft, 'text', 'craftSoldiers');
  Add(FTxtAvailable, 'text', 'craftSoldiers');
  Add(FTxtUsed, 'text', 'craftSoldiers');
  Add(FList, 'list', 'craftSoldiers');
  Add(FCbxSortBy, 'button', 'craftSoldiers');
  LElement := Default(TXcomInterfaceElement);
  LInterface := Host.Resources.GetInterface('craftSoldiers');
  if LInterface <> nil then
    LInterface.TryGetElement('otherCraft', LElement);
  FOtherCraftColor := Byte(LElement.Color);
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_SELECT_SQUAD_FOR_CRAFT').Arg(TXcomBaseNames.CraftName(FCraft, Host.Language)));
  FTxtName.SetText(Tr('STR_NAME_UC'));
  FTxtRank.SetText(Tr('STR_RANK'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));
  // the sort options; the first (original order) has no function
  LOptions := nil;
  SetLength(LOptions, 1);
  LOptions[0] := Tr('STR_ORIGINAL_ORDER').Text;
  FSortFunctions.Add(nil);
  AddSortOption(LOptions, 'STR_RANK', RankStat);
  AddSortOption(LOptions, 'STR_MISSIONS2', MissionsStat);
  AddSortOption(LOptions, 'STR_KILLS2', KillsStat);
  AddSortOption(LOptions, 'STR_WOUND_RECOVERY2', RecoveryStat);
  AddSortOption(LOptions, 'STR_TIME_UNITS', TimeUnitsStat);
  AddSortOption(LOptions, 'STR_STAMINA', StaminaStat);
  AddSortOption(LOptions, 'STR_HEALTH', HealthStat);
  AddSortOption(LOptions, 'STR_BRAVERY', BraveryStat);
  AddSortOption(LOptions, 'STR_REACTIONS', ReactionsStat);
  AddSortOption(LOptions, 'STR_FIRING_ACCURACY', FiringStat);
  AddSortOption(LOptions, 'STR_THROWING_ACCURACY', ThrowingStat);
  AddSortOption(LOptions, 'STR_STRENGTH', StrengthStat);
  // the psionic options only when they have data they can use
  LShowPsiStrength := Host.Options.GetBool('psiStrengthEval') and PsiRequirementsResearched;
  LShowPsiSkill := False;
  for LSoldier in FBase.Soldiers do
    if LSoldier.CurrentStats.PsiSkill > 0 then
    begin
      LShowPsiStrength := True;
      LShowPsiSkill := True;
      Break;
    end;
  if LShowPsiStrength then
    AddSortOption(LOptions, 'STR_PSIONIC_STRENGTH', PsiStrengthStat);
  if LShowPsiSkill then
    AddSortOption(LOptions, 'STR_PSIONIC_SKILL', PsiSkillStat);
  AddSortOption(LOptions, 'STR_MELEE_ACCURACY', MeleeStat);
  FCbxSortBy.SetOptions(LOptions);
  FCbxSortBy.SetSelected(0);
  FCbxSortBy.OnChange(SortByChange);
  FCbxSortBy.SetText(Tr('STR_SORT_BY'));
  FList.SetArrowColumn(192, aoVertical);
  FList.SetColumns([106, 102, 72]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FList.OnLeftArrowClick(LeftArrowClick);
  FList.OnRightArrowClick(RightArrowClick);
  FList.OnMouseClick(SoldiersClick, 0);
  FList.OnMousePress(SoldiersPress);
end;

destructor TXcomCraftSoldiersState.Destroy;
begin
  inherited Destroy;
  FSortFunctions.Free;
  FOriginalOrder.Free;
end;

procedure TXcomCraftSoldiersState.SortByChange(AAction: TXcomAction);
var
  LSelected, LIndex, LInner: Integer;
  LFunction: TStatFunction;
  LSorted: TArray<TXcomSoldier>;
  LSoldier: TXcomSoldier;
  LCurrent: Integer;
begin
  LSelected := FCbxSortBy.GetSelected;
  if LSelected < 0 then
    Exit;
  LFunction := FSortFunctions[LSelected];
  if Assigned(LFunction) then
  begin
    // std::stable_sort with "less than": an insertion sort keeps the equal ones in order
    LSorted := FBase.Soldiers.ToArray;
    for LIndex := 1 to High(LSorted) do
    begin
      LSoldier := LSorted[LIndex];
      LCurrent := LFunction(Self, LSoldier);
      LInner := LIndex - 1;
      while (LInner >= 0) and (LCurrent < LFunction(Self, LSorted[LInner])) do
      begin
        LSorted[LInner + 1] := LSorted[LInner];
        Dec(LInner);
      end;
      LSorted[LInner + 1] := LSoldier;
    end;
    for LIndex := 0 to High(LSorted) do
      FBase.Soldiers.Move(FBase.Soldiers.IndexOf(LSorted[LIndex]), LIndex);
  end
  else
    // the original ordering, ignoring the soldiers that have been sacked since this state started
    for LSoldier in FOriginalOrder do
    begin
      LIndex := FBase.Soldiers.IndexOf(LSoldier);
      if LIndex >= 0 then
        FBase.Soldiers.Move(LIndex, FBase.Soldiers.Count - 1);
    end;
  InitList;
end;

procedure TXcomCraftSoldiersState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftSoldiersState.UpdateSpace;
begin
  FTxtAvailable.SetText(Tr('STR_SPACE_AVAILABLE').Arg(FCraft.SpaceAvailable(FBase.Soldiers)));
  FTxtUsed.SetText(Tr('STR_SPACE_USED').Arg(FCraft.SpaceUsed(FBase.Soldiers)));
end;

procedure TXcomCraftSoldiersState.InitList;
var
  LScroll, LRow: Integer;
  LSoldier: TXcomSoldier;
  LColor: Byte;
begin
  LScroll := FList.GetScroll;
  LRow := 0;
  FList.ClearList;
  for LSoldier in FBase.Soldiers do
  begin
    FList.AddRow([LSoldier.Name, Tr(TXcomBaseNames.RankKey(LSoldier.Rank)).Text,
      TXcomBaseNames.CraftText(LSoldier, Host.Language)]);
    if LSoldier.Craft = FCraft then
      LColor := FList.GetSecondaryColor
    else if Assigned(LSoldier.Craft) then
      LColor := FOtherCraftColor
    else
      LColor := FList.GetColor;
    FList.SetRowColor(LRow, LColor);
    Inc(LRow);
  end;
  FList.Draw;
  FList.ScrollTo(LScroll);
  UpdateSpace;
end;

procedure TXcomCraftSoldiersState.Init;
begin
  inherited Init;
  InitList;
end;

procedure TXcomCraftSoldiersState.ResetSortBox;
begin
  FCbxSortBy.SetText(Tr('STR_SORT_BY'));
  FCbxSortBy.SetSelected(-1);
end;

procedure TXcomCraftSoldiersState.LeftArrowClick(AAction: TXcomAction);
var
  LRow: Integer;
begin
  LRow := FList.GetSelectedRow;
  if LRow > 0 then
  begin
    if AAction.Details^.Button = XCOM_BUTTON_LEFT then
      MoveSoldierUp(AAction, LRow)
    else if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
      MoveSoldierUp(AAction, LRow, True);
  end;
  ResetSortBox;
end;

procedure TXcomCraftSoldiersState.MoveSoldierUp(AAction: TXcomAction; ARow: Integer; AToTop: Boolean);
begin
  if AToTop then
    FBase.Soldiers.Move(ARow, 0)
  else
  begin
    FBase.Soldiers.Exchange(ARow, ARow - 1);
    // SDL_WarpMouse up one row unless the row is the first visible: then the list scrolls
    if ARow <> FList.GetScroll then
      Host.WarpMouse(AAction.LeftBlackBand + AAction.XMouse,
        AAction.TopBlackBand + AAction.YMouse - Trunc(8 * AAction.YScale) and $FFFF)
    else
      FList.ScrollUp(False);
  end;
  InitList;
end;

procedure TXcomCraftSoldiersState.RightArrowClick(AAction: TXcomAction);
var
  LRow: Integer;
begin
  LRow := FList.GetSelectedRow;
  if (FBase.Soldiers.Count > 0) and (LRow < FBase.Soldiers.Count - 1) then
  begin
    if AAction.Details^.Button = XCOM_BUTTON_LEFT then
      MoveSoldierDown(AAction, LRow)
    else if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
      MoveSoldierDown(AAction, LRow, True);
  end;
  ResetSortBox;
end;

procedure TXcomCraftSoldiersState.MoveSoldierDown(AAction: TXcomAction; ARow: Integer; AToBottom: Boolean);
begin
  if AToBottom then
    FBase.Soldiers.Move(ARow, FBase.Soldiers.Count - 1)
  else
  begin
    FBase.Soldiers.Exchange(ARow, ARow + 1);
    if ARow <> FList.GetVisibleRows - 1 + FList.GetScroll then
      Host.WarpMouse(AAction.LeftBlackBand + AAction.XMouse,
        AAction.TopBlackBand + AAction.YMouse + Trunc(8 * AAction.YScale) and $FFFF)
    else
      FList.ScrollDown(False);
  end;
  InitList;
end;

procedure TXcomCraftSoldiersState.SoldiersClick(AAction: TXcomAction);
var
  LRow: Integer;
  LSoldier: TXcomSoldier;
  LColor: Byte;
begin
  if (AAction.AbsoluteXMouse >= FList.GetArrowsLeftEdge) and (AAction.AbsoluteXMouse < FList.GetArrowsRightEdge) then
    Exit;
  LRow := FList.GetSelectedRow;
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    LSoldier := FBase.Soldiers[LRow];
    LColor := FList.GetColor;
    if LSoldier.Craft = FCraft then
    begin
      LSoldier.Craft := nil;
      FList.SetCellText(LRow, 2, Tr('STR_NONE_UC').Text);
    end
    else if Assigned(LSoldier.Craft) and (TXcomCraft(LSoldier.Craft).Status = 'STR_OUT') then
      LColor := FOtherCraftColor
    else if (FCraft.SpaceAvailable(FBase.Soldiers) > 0) and (LSoldier.WoundRecovery = 0) then
    begin
      LSoldier.Craft := FCraft;
      FList.SetCellText(LRow, 2, TXcomBaseNames.CraftName(FCraft, Host.Language));
      LColor := FList.GetSecondaryColor;
    end;
    FList.SetRowColor(LRow, LColor);
    UpdateSpace;
  end
  else if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    Host.PushState(TXcomSoldierInfoState.Create(Host, FBase, LRow));
end;

procedure TXcomCraftSoldiersState.SoldiersPress(AAction: TXcomAction);
var
  LRow: Integer;
begin
  if Host.Options.GetValue('changeValueByMouseWheel') = 0 then
    Exit;
  LRow := FList.GetSelectedRow;
  if (AAction.AbsoluteXMouse < FList.GetArrowsLeftEdge) or (AAction.AbsoluteXMouse > FList.GetArrowsRightEdge) then
    Exit;
  if (AAction.Details^.Button = XCOM_BUTTON_WHEELUP) and (LRow > 0) then
    MoveSoldierUp(AAction, LRow)
  else if (AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN) and (FBase.Soldiers.Count > 0) and
    (LRow < FBase.Soldiers.Count - 1) then
    MoveSoldierDown(AAction, LRow);
end;

end.
