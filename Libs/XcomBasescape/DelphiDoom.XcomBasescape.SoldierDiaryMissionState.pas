{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldierDiaryMissionState of OpenXcom    }
{  (the details of a mission of a soldier: score, place, kills)                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierDiaryMissionState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Soldier;

type
  /// <summary>
  ///   A popup with what the soldier did in the mission of the row he was on: score, place, race, daylight, days
  ///   wounded and the units he killed, stunned, panicked or mind controlled. The buttons go to the previous and
  ///   next mission. As in the C++ the mission is looked up by its id used as an index of the list
  /// </summary>
  TXcomSoldierDiaryMissionState = class(TXcomState)
  strict private
    FSoldier: TXcomSoldier;
    FRowEntry: Integer;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnPrev: TXcomTextButton;
    FBtnNext: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtUfo: TXcomText;
    FTxtScore: TXcomText;
    FTxtKills: TXcomText;
    FTxtLocation: TXcomText;
    FTxtRace: TXcomText;
    FTxtDaylight: TXcomText;
    FTxtDaysWounded: TXcomText;
    FTxtNoRecord: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure PrevClick(AAction: TXcomAction);
    procedure NextClick(AAction: TXcomAction);
  public
    /// <param name="ASoldier">The soldier (not owned)</param>
    /// <param name="ARowEntry">The place in the list of missions of his diary</param>
    constructor Create(AHost: TXcomStateHost; ASoldier: TXcomSoldier; ARowEntry: Integer);
    procedure Init; override;
    property RowEntry: Integer read FRowEntry;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.MissionStatistics,
  DelphiDoom.XcomSave.BattleUnitKills, DelphiDoom.XcomSave.UnitEnums, DelphiDoom.XcomBasescape.Names;

{ TXcomSoldierDiaryMissionState }

constructor TXcomSoldierDiaryMissionState.Create(AHost: TXcomStateHost; ASoldier: TXcomSoldier;
  ARowEntry: Integer);
begin
  inherited Create(AHost);
  FSoldier := ASoldier;
  FRowEntry := ARowEntry;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 300, 128, 10, 36, wpHorizontal);
  FBtnOk := TXcomTextButton.Create(240, 16, 40, 140);
  FBtnPrev := TXcomTextButton.Create(28, 14, 18, 44);
  FBtnNext := TXcomTextButton.Create(28, 14, 274, 44);
  FTxtTitle := TXcomText.Create(262, 9, 29, 44);
  FTxtUfo := TXcomText.Create(262, 9, 29, 52);
  FTxtScore := TXcomText.Create(180, 9, 29, 68);
  FTxtKills := TXcomText.Create(120, 9, 169, 68);
  FTxtLocation := TXcomText.Create(180, 9, 29, 76);
  FTxtRace := TXcomText.Create(120, 9, 169, 76);
  FTxtDaylight := TXcomText.Create(120, 9, 169, 84);
  FTxtDaysWounded := TXcomText.Create(180, 9, 29, 84);
  FTxtNoRecord := TXcomText.Create(240, 9, 29, 100);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 270, 32, 20, 100);
  SetInterface('soldierDiaryMission');
  Add(FWindow, 'window', 'soldierDiaryMission');
  Add(FBtnOk, 'button', 'soldierDiaryMission');
  Add(FBtnPrev, 'button', 'soldierDiaryMission');
  Add(FBtnNext, 'button', 'soldierDiaryMission');
  Add(FTxtTitle, 'text', 'soldierDiaryMission');
  Add(FTxtUfo, 'text', 'soldierDiaryMission');
  Add(FTxtScore, 'text', 'soldierDiaryMission');
  Add(FTxtKills, 'text', 'soldierDiaryMission');
  Add(FTxtLocation, 'text', 'soldierDiaryMission');
  Add(FTxtRace, 'text', 'soldierDiaryMission');
  Add(FTxtDaylight, 'text', 'soldierDiaryMission');
  Add(FTxtDaysWounded, 'text', 'soldierDiaryMission');
  Add(FTxtNoRecord, 'text', 'soldierDiaryMission');
  Add(FList, 'list', 'soldierDiaryMission');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK16.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnPrev.SetText('<<');
  FBtnPrev.OnMouseClick(PrevClick);
  FBtnPrev.OnKeyboardPress(PrevClick, Host.Options.GetValue('keyBattleNextUnit'));
  FBtnNext.SetText('>>');
  FBtnNext.OnMouseClick(NextClick);
  FBtnNext.OnKeyboardPress(NextClick, Host.Options.GetValue('keyBattlePrevUnit'));
  FTxtTitle.SetAlign(haCenter);
  FTxtUfo.SetAlign(haCenter);
  FList.SetColumns([60, 110, 100]);
  Init;
end;

procedure TXcomSoldierDiaryMissionState.Init;
var
  LStatistics: TObjectList<TXcomMissionStatistics>;
  LMission: TXcomMissionStatistics;
  LMissionId, LDaysWounded, LKills, LIndex: Integer;
  LStunOrKill: Boolean;
  LKill: TXcomBattleUnitKills;
  LName: string;
begin
  inherited Init;
  if FSoldier.Diary.MissionTotal = 0 then
  begin
    Host.PopState;
    Exit;
  end;
  LStatistics := TXcomStrategy.SavedGame(Host).MissionStatistics;
  LMissionId := FSoldier.Diary.MissionIdList[FRowEntry];
  if LMissionId > LStatistics.Count then
    LMissionId := 0;
  if LMissionId >= LStatistics.Count then
    Exit;
  LMission := LStatistics[LMissionId];
  LDaysWounded := 0;
  for LIndex := 0 to High(LMission.InjuryList) do
    if LMission.InjuryList[LIndex].Wounds = FSoldier.Id then
      LDaysWounded := LMission.InjuryList[LIndex].Soldiers;
  FList.ClearList;
  FTxtTitle.SetText(Tr(LMission.MissionType));
  if LMission.IsUfoMission then
    FTxtUfo.SetText(Tr(LMission.Ufo));
  FTxtUfo.Visible := LMission.IsUfoMission;
  FTxtScore.SetText(Tr('STR_SCORE_VALUE').Arg(LMission.Score));
  FTxtLocation.SetText(Tr('STR_LOCATION').Arg(Tr(LMission.LocationString).Text));
  FTxtRace.SetText(Tr('STR_RACE_TYPE').Arg(Tr(LMission.AlienRace).Text));
  FTxtRace.Visible := LMission.AlienRace <> 'STR_UNKNOWN';
  FTxtDaylight.SetText(Tr('STR_DAYLIGHT_TYPE').Arg(Tr(LMission.DaylightString).Text));
  FTxtDaysWounded.SetText(Tr('STR_DAYS_WOUNDED').Arg(LDaysWounded));
  FTxtDaysWounded.Visible := LDaysWounded <> 0;
  LKills := 0;
  LStunOrKill := False;
  for LKill in FSoldier.Diary.KillList do
  begin
    if LKill.Mission <> LMissionId then
      Continue;
    case LKill.Status of
      XcomStatusDead:
        begin
          Inc(LKills);
          LStunOrKill := True;
        end;
      XcomStatusUnconscious, XcomStatusPanicking, XcomStatusTurning:
        LStunOrKill := True;
    end;
    LName := TXcomBaseNames.KillUnitName(LKill, Host.Language);
    FList.AddRow([Tr(LKill.KillStatusString).Text, LName, Tr(LKill.Weapon).Text]);
  end;
  FTxtNoRecord.SetAlign(haCenter);
  FTxtNoRecord.SetText(Tr('STR_NO_RECORD'));
  FTxtNoRecord.Visible := not LStunOrKill;
  FTxtKills.SetText(Tr('STR_KILLS').Arg(LKills));
end;

procedure TXcomSoldierDiaryMissionState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomSoldierDiaryMissionState.PrevClick(AAction: TXcomAction);
begin
  if FRowEntry = 0 then
    FRowEntry := FSoldier.Diary.MissionTotal - 1
  else
    Dec(FRowEntry);
  Init;
end;

procedure TXcomSoldierDiaryMissionState.NextClick(AAction: TXcomAction);
begin
  Inc(FRowEntry);
  if FRowEntry >= FSoldier.Diary.MissionTotal then
    FRowEntry := 0;
  Init;
end;

end.
