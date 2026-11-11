{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldierDiaryPerformanceState of         }
{  OpenXcom (the kills, missions and awards of a soldier by category)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierDiaryPerformanceState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomMod.Types,
  DelphiDoom.XcomBasescape.SoldierDiaryTypes, DelphiDoom.XcomSurface.SurfaceSet;

type
  /// <summary>
  ///   What a soldier did, by category: the units he neutralized by race, rank and weapon (with the totals of
  ///   kills, stuns, accuracy and mind controls), the missions by place, type and UFO (with the totals), or his
  ///   commendations with their sprites and the description of the one under the mouse
  /// </summary>
  TXcomSoldierDiaryPerformanceState = class(TXcomState)
  strict private
    const
      MedalRows = 10;
    var
    FBase: TXcomBase;
    FList: TObjectList<TXcomSoldier>;
    FSoldierId: Integer;
    FSoldier: TXcomSoldier;
    FDisplay: TXcomDiaryDisplay;
    FOnSoldierChanged: TXcomSoldierIdChanged;
    FGroup: TXcomButtonGroup;
    FLastScrollPos: Integer;
    FMedalDescriptions: TList<string>;
    FWindow: TXcomWindow;
    FBtnPrev: TXcomTextButton;
    FBtnNext: TXcomTextButton;
    FBtnKills: TXcomTextButton;
    FBtnMissions: TXcomTextButton;
    FBtnCommendations: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FPerformance: TXcomTextList;
    FKillTotals: TXcomTextList;
    FMissionTotals: TXcomTextList;
    FTxtMedalName: TXcomText;
    FTxtMedalLevel: TXcomText;
    FTxtMedalInfo: TXcomText;
    FCommendationList: TXcomTextList;
    FMedals: array[0..MedalRows - 1] of TXcomWidget;
    FDecorations: array[0..MedalRows - 1] of TXcomWidget;
    procedure AddTally(const ATitle: string; const ATally: TXcomStringMap<Integer>; ASkipNoUfo: Boolean;
      ALast: Boolean);
    procedure DrawSprites;
    procedure OkClick(AAction: TXcomAction);
    procedure PrevClick(AAction: TXcomAction);
    procedure NextClick(AAction: TXcomAction);
    procedure KillsToggle(AAction: TXcomAction);
    procedure MissionsToggle(AAction: TXcomAction);
    procedure CommendationsToggle(AAction: TXcomAction);
    procedure InfoMouseOver(AAction: TXcomAction);
    procedure InfoMouseOut(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer; ADisplay: TXcomDiaryDisplay;
      const AOnSoldierChanged: TXcomSoldierIdChanged);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    property Display: TXcomDiaryDisplay read FDisplay;
    property Performance: TXcomTextList read FPerformance;
    property CommendationList: TXcomTextList read FCommendationList;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleCommendations,
  DelphiDoom.XcomSave.SoldierCommendation, DelphiDoom.XcomSave.MissionStatistics, DelphiDoom.XcomSave.BattleUnitKills,
  DelphiDoom.XcomSave.SoldierDiary, DelphiDoom.XcomBasescape.PsiRequirements, DelphiDoom.XcomMod.UnitStats;

{ TXcomSoldierDiaryPerformanceState }

constructor TXcomSoldierDiaryPerformanceState.Create(AHost: TXcomStateHost; ABase: TXcomBase;
  ASoldierId: Integer; ADisplay: TXcomDiaryDisplay; const AOnSoldierChanged: TXcomSoldierIdChanged);
var
  LIndex: Integer;
begin
  inherited Create(AHost);
  FBase := ABase;
  FSoldierId := ASoldierId;
  FDisplay := ADisplay;
  FOnSoldierChanged := AOnSoldierChanged;
  FMedalDescriptions := TList<string>.Create;
  FGroup := TXcomButtonGroup.Create;
  if FBase = nil then
    FList := TXcomStrategy.SavedGame(AHost).DeadSoldiers
  else
    FList := FBase.Soldiers;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnPrev := TXcomTextButton.Create(28, 14, 8, 8);
  FBtnNext := TXcomTextButton.Create(28, 14, 284, 8);
  FBtnKills := TXcomTextButton.Create(70, 16, 8, 176);
  FBtnMissions := TXcomTextButton.Create(70, 16, 86, 176);
  FBtnCommendations := TXcomTextButton.Create(70, 16, 164, 176);
  FBtnOk := TXcomTextButton.Create(70, 16, 242, 176);
  FTxtTitle := TXcomText.Create(310, 16, 5, 8);
  FPerformance := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 28);
  FKillTotals := TXcomTextList.Create(Host.Options, Host.Clock, 302, 9, 8, 164);
  FMissionTotals := TXcomTextList.Create(Host.Options, Host.Clock, 302, 9, 8, 164);
  FTxtMedalName := TXcomText.Create(120, 18, 16, 36);
  FTxtMedalLevel := TXcomText.Create(120, 18, 186, 36);
  FTxtMedalInfo := TXcomText.Create(280, 32, 20, 135);
  FCommendationList := TXcomTextList.Create(Host.Options, Host.Clock, 240, 80, 48, 52);
  for LIndex := 0 to MedalRows - 1 do
  begin
    FMedals[LIndex] := TXcomWidget.Create(31, 8, 16, 52 + 8 * LIndex);
    FDecorations[LIndex] := TXcomWidget.Create(31, 8, 16, 52 + 8 * LIndex);
  end;
  SetInterface('soldierDiaryPerformance');
  Add(FWindow, 'window', 'soldierDiaryPerformance');
  Add(FBtnOk, 'button', 'soldierDiaryPerformance');
  Add(FBtnKills, 'button', 'soldierDiaryPerformance');
  Add(FBtnMissions, 'button', 'soldierDiaryPerformance');
  Add(FBtnCommendations, 'button', 'soldierDiaryPerformance');
  Add(FBtnPrev, 'button', 'soldierDiaryPerformance');
  Add(FBtnNext, 'button', 'soldierDiaryPerformance');
  Add(FTxtTitle, 'text1', 'soldierDiaryPerformance');
  Add(FPerformance, 'list', 'soldierDiaryPerformance');
  Add(FKillTotals, 'text2', 'soldierDiaryPerformance');
  Add(FMissionTotals, 'text2', 'soldierDiaryPerformance');
  Add(FTxtMedalName, 'text2', 'soldierDiaryPerformance');
  Add(FTxtMedalLevel, 'text2', 'soldierDiaryPerformance');
  Add(FTxtMedalInfo, 'text2', 'soldierDiaryPerformance');
  Add(FCommendationList, 'list', 'soldierDiaryPerformance');
  for LIndex := 0 to MedalRows - 1 do
  begin
    Add(FMedals[LIndex]);
    Add(FDecorations[LIndex]);
  end;
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnKills.SetText(Tr('STR_COMBAT'));
  FBtnKills.OnMouseClick(KillsToggle);
  FBtnMissions.SetText(Tr('STR_PERFORMANCE'));
  FBtnMissions.OnMouseClick(MissionsToggle);
  FBtnCommendations.SetText(Tr('STR_AWARDS'));
  FBtnCommendations.OnMouseClick(CommendationsToggle);
  FBtnPrev.SetText('<<');
  FBtnNext.SetText('>>');
  // the dead are listed backwards: previous and next swap
  if FBase = nil then
  begin
    FBtnPrev.OnMouseClick(NextClick);
    FBtnPrev.OnKeyboardPress(NextClick, Host.Options.GetValue('keyBattlePrevUnit'));
    FBtnNext.OnMouseClick(PrevClick);
    FBtnNext.OnKeyboardPress(PrevClick, Host.Options.GetValue('keyBattleNextUnit'));
  end
  else
  begin
    FBtnPrev.OnMouseClick(PrevClick);
    FBtnPrev.OnKeyboardPress(PrevClick, Host.Options.GetValue('keyBattlePrevUnit'));
    FBtnNext.OnMouseClick(NextClick);
    FBtnNext.OnKeyboardPress(NextClick, Host.Options.GetValue('keyBattleNextUnit'));
  end;
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FPerformance.SetColumns([273, 15]);
  FPerformance.SetDot(True);
  FKillTotals.SetColumns([72, 72, 72, 86]);
  FMissionTotals.SetColumns([72, 72, 72, 86]);
  FTxtMedalName.SetText(Tr('STR_MEDAL_NAME'));
  FTxtMedalLevel.SetText(Tr('STR_MEDAL_DECOR_LEVEL'));
  FTxtMedalInfo.SetWordWrap(True);
  FCommendationList.SetColumns([138, 100]);
  FCommendationList.SetSelectable(True);
  FCommendationList.SetBackground(FWindow);
  FCommendationList.OnMouseOver(InfoMouseOver);
  FCommendationList.OnMouseOut(InfoMouseOut);
  case FDisplay of
    ddKills: FGroup.Selected := FBtnKills;
    ddMissions: FGroup.Selected := FBtnMissions;
    ddCommendations: FGroup.Selected := FBtnCommendations;
  end;
  FBtnKills.SetGroup(FGroup);
  FBtnMissions.SetGroup(FGroup);
  FBtnCommendations.SetGroup(FGroup);
  Init;
end;

destructor TXcomSoldierDiaryPerformanceState.Destroy;
begin
  inherited Destroy;
  FGroup.Free;
  FMedalDescriptions.Free;
end;

procedure TXcomSoldierDiaryPerformanceState.AddTally(const ATitle: string; const ATally: TXcomStringMap<Integer>;
  ASkipNoUfo: Boolean; ALast: Boolean);
var
  LIndex: Integer;
begin
  FPerformance.AddRow([ATitle]);
  FPerformance.SetRowColor(FPerformance.GetRows - 1, FPerformance.GetSecondaryColor);
  for LIndex := 0 to ATally.Count - 1 do
  begin
    if ASkipNoUfo and (ATally.Key(LIndex) = 'NO_UFO') then
      Continue;
    FPerformance.AddRow([Tr(ATally.Key(LIndex)).Text, IntToStr(ATally.Value(LIndex))]);
  end;
  if not ALast then
    FPerformance.AddRow(['']);
end;

procedure TXcomSoldierDiaryPerformanceState.Init;
var
  LSave: TXcomSavedGame;
  LRuleset: TXcomRuleset;
  LDiary: TXcomSoldierDiary;
  LIndex: Integer;
  LTally: TXcomStringMap<Integer>;
  LItem: TXcomSoldierCommendation;
  LRule: TXcomRuleCommendations;
  LPsiVisible: Boolean;
  LNoun: string;
  LStats: TXcomUnitStats;
begin
  inherited Init;
  for LIndex := 0 to MedalRows - 1 do
  begin
    FMedals[LIndex].Clear;
    FDecorations[LIndex].Clear;
  end;
  FPerformance.ScrollTo(0);
  FKillTotals.ScrollTo(0);
  FMissionTotals.ScrollTo(0);
  FCommendationList.ScrollTo(0);
  FLastScrollPos := 0;
  LSave := TXcomStrategy.SavedGame(Host);
  LRuleset := TXcomStrategy.Ruleset(Host);
  FPerformance.Visible := FDisplay <> ddCommendations;
  FKillTotals.Visible := FDisplay = ddKills;
  FMissionTotals.Visible := FDisplay = ddMissions;
  FTxtMedalName.Visible := FDisplay = ddCommendations;
  FTxtMedalLevel.Visible := FDisplay = ddCommendations;
  FTxtMedalInfo.Visible := FDisplay = ddCommendations;
  FCommendationList.Visible := FDisplay = ddCommendations;
  FBtnCommendations.Visible := LRuleset.Commendations.Count > 0;
  if FList.Count = 0 then
  begin
    Host.PopState;
    Exit;
  end;
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  FSoldier := FList[FSoldierId];
  LDiary := FSoldier.Diary;
  FKillTotals.ClearList;
  FMissionTotals.ClearList;
  FMedalDescriptions.Clear;
  FTxtTitle.SetText(FSoldier.Name);
  FPerformance.ClearList;
  FCommendationList.ClearList;
  case FDisplay of
    ddKills:
      begin
        LTally := LDiary.KillTally(
          function(AKill: TXcomBattleUnitKills): string
          begin
            Result := AKill.Race;
          end, False);
        try
          AddTally(Tr('STR_NEUTRALIZATIONS_BY_RACE').Text, LTally, False, False);
        finally
          LTally.Free;
        end;
        LTally := LDiary.KillTally(
          function(AKill: TXcomBattleUnitKills): string
          begin
            Result := AKill.Rank;
          end, False);
        try
          AddTally(Tr('STR_NEUTRALIZATIONS_BY_RANK').Text, LTally, False, False);
        finally
          LTally.Free;
        end;
        LTally := LDiary.KillTally(
          function(AKill: TXcomBattleUnitKills): string
          begin
            Result := AKill.Weapon;
          end, True);
        try
          AddTally(Tr('STR_NEUTRALIZATIONS_BY_WEAPON').Text, LTally, False, True);
        finally
          LTally.Free;
        end;
        LStats := FSoldier.CurrentStats;
        LPsiVisible := (LStats.PsiSkill > 0) or (Host.Options.GetBool('psiStrengthEval') and
          LSave.IsResearched(TXcomPsiRequirements.Resolve(LRuleset)));
        if LPsiVisible then
          FKillTotals.AddRow([Tr('STR_KILLS').Arg(LDiary.KillTotal).Text, Tr('STR_STUNS').Arg(LDiary.StunTotal).Text,
            Tr('STR_DIARY_ACCURACY').Arg(LDiary.Accuracy).Text,
            Tr('STR_MINDCONTROLS').Arg(LDiary.ControlTotal).Text])
        else
          FKillTotals.AddRow([Tr('STR_KILLS').Arg(LDiary.KillTotal).Text, Tr('STR_STUNS').Arg(LDiary.StunTotal).Text,
            Tr('STR_DIARY_ACCURACY').Arg(LDiary.Accuracy).Text]);
      end;
    ddMissions:
      begin
        LTally := LDiary.MissionTally(LSave.MissionStatistics,
          function(AMission: TXcomMissionStatistics): string
          begin
            Result := AMission.Region;
          end);
        try
          AddTally(Tr('STR_MISSIONS_BY_LOCATION').Text, LTally, True, False);
        finally
          LTally.Free;
        end;
        LTally := LDiary.MissionTally(LSave.MissionStatistics,
          function(AMission: TXcomMissionStatistics): string
          begin
            Result := AMission.MissionType;
          end);
        try
          AddTally(Tr('STR_MISSIONS_BY_TYPE').Text, LTally, True, False);
        finally
          LTally.Free;
        end;
        LTally := LDiary.MissionTally(LSave.MissionStatistics,
          function(AMission: TXcomMissionStatistics): string
          begin
            Result := AMission.Ufo;
          end);
        try
          AddTally(Tr('STR_MISSIONS_BY_UFO').Text, LTally, True, True);
        finally
          LTally.Free;
        end;
        FMissionTotals.AddRow([Tr('STR_MISSIONS').Arg(LDiary.MissionTotal).Text,
          Tr('STR_WINS').Arg(LDiary.WinTotal(LSave.MissionStatistics)).Text,
          Tr('STR_SCORE_VALUE').Arg(LDiary.ScoreTotal(LSave.MissionStatistics)).Text,
          Tr('STR_DAYS_WOUNDED').Arg(LDiary.DaysWoundedTotal).Text]);
      end;
    ddCommendations:
      if LRuleset.Commendations.Count > 0 then
      begin
        for LItem in LDiary.Commendations do
        begin
          if not LRuleset.Commendations.TryGetValue(LItem.CommendationType, LRule) then
            Continue;
          LNoun := LItem.Noun;
          if LNoun <> 'noNoun' then
          begin
            FCommendationList.AddRow([Tr(LItem.CommendationType).Arg(Tr(LNoun).Text).Text,
              Tr('STR_AWARD_DECOR_' + IntToStr(LItem.DecorationLevel)).Text]);
            FMedalDescriptions.Add(Tr(LRule.Description).Arg(Tr(LNoun).Text).Text);
          end
          else
          begin
            FCommendationList.AddRow([Tr(LItem.CommendationType).Text,
              Tr('STR_AWARD_DECOR_' + IntToStr(LItem.DecorationLevel)).Text]);
            FMedalDescriptions.Add(Tr(LRule.Description).Text);
          end;
        end;
        DrawSprites;
      end;
  end;
end;

procedure TXcomSoldierDiaryPerformanceState.DrawSprites;
var
  LCommendations, LDecorations: TXcomSurfaceSet;
  LVisible, LScroll, LPosition: Integer;
  LItem: TXcomSoldierCommendation;
  LRule: TXcomRuleCommendations;
begin
  if FDisplay <> ddCommendations then
    Exit;
  LCommendations := TXcomStrategy.Rules(Host).GetSurfaceSet('Commendations');
  LDecorations := TXcomStrategy.Rules(Host).GetSurfaceSet('CommendationDecorations');
  for LVisible := 0 to MedalRows - 1 do
  begin
    FMedals[LVisible].Clear;
    FDecorations[LVisible].Clear;
  end;
  LPosition := 0;
  LScroll := FCommendationList.GetScroll;
  for LItem in FSoldier.Diary.Commendations do
  begin
    if not TXcomStrategy.Ruleset(Host).Commendations.TryGetValue(LItem.CommendationType, LRule) then
      Continue;
    // skip the commendations that are not in the visible part of the list
    if (LPosition < LScroll) or (LPosition - LScroll >= MedalRows) then
    begin
      Inc(LPosition);
      Continue;
    end;
    LCommendations.GetFrame(LRule.Sprite).X := 0;
    LCommendations.GetFrame(LRule.Sprite).Y := 0;
    LCommendations.GetFrame(LRule.Sprite).Blit(FMedals[LPosition - LScroll]);
    if LItem.DecorationLevel <> 0 then
    begin
      LDecorations.GetFrame(LItem.DecorationLevel).X := 0;
      LDecorations.GetFrame(LItem.DecorationLevel).Y := 0;
      LDecorations.GetFrame(LItem.DecorationLevel).Blit(FDecorations[LPosition - LScroll]);
    end;
    Inc(LPosition);
  end;
end;

procedure TXcomSoldierDiaryPerformanceState.Think;
begin
  inherited Think;
  if FLastScrollPos <> FCommendationList.GetScroll then
  begin
    DrawSprites;
    FLastScrollPos := FCommendationList.GetScroll;
  end;
end;

procedure TXcomSoldierDiaryPerformanceState.OkClick(AAction: TXcomAction);
begin
  if Assigned(FOnSoldierChanged) then
    FOnSoldierChanged(FSoldierId);
  Host.PopState;
end;

procedure TXcomSoldierDiaryPerformanceState.PrevClick(AAction: TXcomAction);
begin
  if FSoldierId = 0 then
    FSoldierId := FList.Count - 1
  else
    Dec(FSoldierId);
  Init;
end;

procedure TXcomSoldierDiaryPerformanceState.NextClick(AAction: TXcomAction);
begin
  Inc(FSoldierId);
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  Init;
end;

procedure TXcomSoldierDiaryPerformanceState.KillsToggle(AAction: TXcomAction);
begin
  FDisplay := ddKills;
  Init;
end;

procedure TXcomSoldierDiaryPerformanceState.MissionsToggle(AAction: TXcomAction);
begin
  FDisplay := ddMissions;
  Init;
end;

procedure TXcomSoldierDiaryPerformanceState.CommendationsToggle(AAction: TXcomAction);
begin
  FDisplay := ddCommendations;
  Init;
end;

procedure TXcomSoldierDiaryPerformanceState.InfoMouseOver(AAction: TXcomAction);
var
  LSelected: Integer;
begin
  LSelected := FCommendationList.GetSelectedRow;
  if (FMedalDescriptions.Count = 0) or (LSelected > FMedalDescriptions.Count - 1) then
    FTxtMedalInfo.SetText('')
  else
    FTxtMedalInfo.SetText(FMedalDescriptions[LSelected]);
end;

procedure TXcomSoldierDiaryPerformanceState.InfoMouseOut(AAction: TXcomAction);
begin
  FTxtMedalInfo.SetText('');
end;

end.
