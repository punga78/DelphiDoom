{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldierDiaryOverviewState of OpenXcom   }
{  (the missions of a soldier, with the rating and the date)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierDiaryOverviewState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomBasescape.SoldierDiaryTypes;

type
  /// <summary>
  ///   The first screen of the diary of a soldier of a base (or of a dead one, when there is no base): the list of
  ///   his missions with the rating and the date; a click on a mission opens its details, the buttons open the
  ///   combat, performance and awards screens and go to the previous and next soldier
  /// </summary>
  TXcomSoldierDiaryOverviewState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FList: TObjectList<TXcomSoldier>;
    FSoldierId: Integer;
    FSoldier: TXcomSoldier;
    FOnSoldierChanged: TXcomSoldierIdChanged;
    FWindow: TXcomWindow;
    FBtnKills: TXcomTextButton;
    FBtnMissions: TXcomTextButton;
    FBtnCommendations: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FBtnPrev: TXcomTextButton;
    FBtnNext: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtMission: TXcomText;
    FTxtRating: TXcomText;
    FTxtDate: TXcomText;
    FDiaryList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure KillsClick(AAction: TXcomAction);
    procedure MissionsClick(AAction: TXcomAction);
    procedure CommendationsClick(AAction: TXcomAction);
    procedure PrevClick(AAction: TXcomAction);
    procedure NextClick(AAction: TXcomAction);
    procedure DiaryClick(AAction: TXcomAction);
    procedure OpenPerformance(ADisplay: TXcomDiaryDisplay);
  public
    /// <param name="ABase">The base; nil for the dead soldiers (not owned)</param>
    /// <param name="ASoldierId">The index in the list of soldiers</param>
    /// <param name="AOnSoldierChanged">Told the soldier when the screen closes (SoldierInfoState::setSoldierId)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer;
      const AOnSoldierChanged: TXcomSoldierIdChanged);
    procedure Init; override;
    /// <summary>setSoldierId</summary>
    property SoldierId: Integer read FSoldierId write FSoldierId;
    property List: TXcomTextList read FDiaryList;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.MissionStatistics,
  DelphiDoom.XcomBasescape.Names, DelphiDoom.XcomBasescape.SoldierDiaryMissionState,
  DelphiDoom.XcomBasescape.SoldierDiaryPerformanceState;

{ TXcomSoldierDiaryOverviewState }

constructor TXcomSoldierDiaryOverviewState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer;
  const AOnSoldierChanged: TXcomSoldierIdChanged);
begin
  inherited Create(AHost);
  FBase := ABase;
  FSoldierId := ASoldierId;
  FOnSoldierChanged := AOnSoldierChanged;
  if FBase = nil then
    FList := TXcomStrategy.SavedGame(AHost).DeadSoldiers
  else
    FList := FBase.Soldiers;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnKills := TXcomTextButton.Create(70, 16, 8, 176);
  FBtnMissions := TXcomTextButton.Create(70, 16, 86, 176);
  FBtnCommendations := TXcomTextButton.Create(70, 16, 164, 176);
  FBtnOk := TXcomTextButton.Create(70, 16, 242, 176);
  FBtnPrev := TXcomTextButton.Create(28, 14, 8, 8);
  FBtnNext := TXcomTextButton.Create(28, 14, 284, 8);
  FTxtTitle := TXcomText.Create(310, 16, 5, 8);
  FTxtMission := TXcomText.Create(114, 9, 16, 36);
  FTxtRating := TXcomText.Create(102, 9, 120, 36);
  FTxtDate := TXcomText.Create(90, 9, 218, 36);
  FDiaryList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 120, 8, 44);
  SetInterface('soldierDiary');
  Add(FWindow, 'window', 'soldierDiary');
  Add(FBtnOk, 'button', 'soldierDiary');
  Add(FBtnKills, 'button', 'soldierDiary');
  Add(FBtnMissions, 'button', 'soldierDiary');
  Add(FBtnCommendations, 'button', 'soldierDiary');
  Add(FBtnPrev, 'button', 'soldierDiary');
  Add(FBtnNext, 'button', 'soldierDiary');
  Add(FTxtTitle, 'text1', 'soldierDiary');
  Add(FTxtMission, 'text2', 'soldierDiary');
  Add(FTxtRating, 'text2', 'soldierDiary');
  Add(FTxtDate, 'text2', 'soldierDiary');
  Add(FDiaryList, 'list', 'soldierDiary');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnKills.SetText(Tr('STR_COMBAT'));
  FBtnKills.OnMouseClick(KillsClick);
  FBtnMissions.SetText(Tr('STR_PERFORMANCE'));
  FBtnMissions.OnMouseClick(MissionsClick);
  FBtnCommendations.SetText(Tr('STR_AWARDS'));
  FBtnCommendations.OnMouseClick(CommendationsClick);
  FBtnCommendations.Visible := TXcomStrategy.Ruleset(AHost).Commendations.Count > 0;
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
  FTxtMission.SetText(Tr('STR_MISSION'));
  FTxtRating.SetText(Tr('STR_RATING_UC'));
  FTxtDate.SetText(Tr('STR_DATE_UC'));
  FDiaryList.SetColumns([104, 98, 30, 25, 35]);
  FDiaryList.SetSelectable(True);
  FDiaryList.SetBackground(FWindow);
  FDiaryList.SetMargin(8);
  FDiaryList.OnMouseClick(DiaryClick);
  Init;
end;

procedure TXcomSoldierDiaryOverviewState.Init;
var
  LMission: TXcomMissionStatistics;
  LRows: Integer;
  LId: Integer;
  LWasOnMission: Boolean;
begin
  inherited Init;
  if FList.Count = 0 then
  begin
    Host.PopState;
    Exit;
  end;
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  FSoldier := FList[FSoldierId];
  FTxtTitle.SetText(FSoldier.Name);
  FDiaryList.ClearList;
  LRows := 0;
  for LMission in TXcomStrategy.SavedGame(Host).MissionStatistics do
  begin
    LWasOnMission := False;
    for LId in FSoldier.Diary.MissionIdList do
      if LId = LMission.Id then
      begin
        LWasOnMission := True;
        Break;
      end;
    if not LWasOnMission then
      Continue;
    FDiaryList.AddRow([TXcomBaseNames.MissionName(LMission, Host.Language),
      TXcomBaseNames.RatingString(LMission, Host.Language),
      Tr(LMission.Time.DayStringKey).Arg(LMission.Time.Day).Text, Tr(LMission.Time.MonthString).Text,
      IntToStr(LMission.Time.Year)]);
    Inc(LRows);
  end;
  if (LRows > 0) and (FDiaryList.GetScroll >= LRows) then
    FDiaryList.ScrollTo(0);
end;

procedure TXcomSoldierDiaryOverviewState.OkClick(AAction: TXcomAction);
begin
  if Assigned(FOnSoldierChanged) then
    FOnSoldierChanged(FSoldierId);
  Host.PopState;
end;

procedure TXcomSoldierDiaryOverviewState.OpenPerformance(ADisplay: TXcomDiaryDisplay);
begin
  Host.PushState(TXcomSoldierDiaryPerformanceState.Create(Host, FBase, FSoldierId, ADisplay,
    procedure(ASoldierId: Integer)
    begin
      FSoldierId := ASoldierId;
    end));
end;

procedure TXcomSoldierDiaryOverviewState.KillsClick(AAction: TXcomAction);
begin
  OpenPerformance(ddKills);
end;

procedure TXcomSoldierDiaryOverviewState.MissionsClick(AAction: TXcomAction);
begin
  OpenPerformance(ddMissions);
end;

procedure TXcomSoldierDiaryOverviewState.CommendationsClick(AAction: TXcomAction);
begin
  OpenPerformance(ddCommendations);
end;

procedure TXcomSoldierDiaryOverviewState.PrevClick(AAction: TXcomAction);
begin
  if FSoldierId = 0 then
    FSoldierId := FList.Count - 1
  else
    Dec(FSoldierId);
  Init;
end;

procedure TXcomSoldierDiaryOverviewState.NextClick(AAction: TXcomAction);
begin
  Inc(FSoldierId);
  if FSoldierId >= FList.Count then
    FSoldierId := 0;
  Init;
end;

procedure TXcomSoldierDiaryOverviewState.DiaryClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomSoldierDiaryMissionState.Create(Host, FSoldier, FDiaryList.GetSelectedRow));
end;

end.
