{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SoldierMemorialState of OpenXcom (the   }
{  soldiers who died, with the date)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SoldierMemorialState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList;

type
  /// <summary>
  ///   The memorial: the soldiers who died (the latest first) with the rank and the date of the death. A click on a
  ///   soldier opens his info. The Statistics button of the C++ (StatisticsState) is not ported: it does nothing
  /// </summary>
  TXcomSoldierMemorialState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnStatistics: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtName: TXcomText;
    FTxtRank: TXcomText;
    FTxtDate: TXcomText;
    FTxtRecruited: TXcomText;
    FTxtLost: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure ListClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost);
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Soldier,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomBasescape.Names,
  DelphiDoom.XcomBasescape.SoldierInfoState;

{ TXcomSoldierMemorialState }

constructor TXcomSoldierMemorialState.Create(AHost: TXcomStateHost);
var
  LSave: TXcomSavedGame;
  LCapacity: TXcomBaseCapacity;
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
  LLost, LRecruited, LIndex: Integer;
begin
  inherited Create(AHost);
  LSave := TXcomStrategy.SavedGame(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(148, 16, 164, 176);
  FBtnStatistics := TXcomTextButton.Create(148, 16, 8, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtName := TXcomText.Create(114, 9, 16, 36);
  FTxtRank := TXcomText.Create(102, 9, 130, 36);
  FTxtDate := TXcomText.Create(90, 9, 218, 36);
  FTxtRecruited := TXcomText.Create(150, 9, 16, 24);
  FTxtLost := TXcomText.Create(150, 9, 160, 24);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 120, 8, 44);
  SetInterface('soldierMemorial');
  Add(FWindow, 'window', 'soldierMemorial');
  Add(FBtnOk, 'button', 'soldierMemorial');
  Add(FBtnStatistics, 'button', 'soldierMemorial');
  Add(FTxtTitle, 'text', 'soldierMemorial');
  Add(FTxtName, 'text', 'soldierMemorial');
  Add(FTxtRank, 'text', 'soldierMemorial');
  Add(FTxtDate, 'text', 'soldierMemorial');
  Add(FTxtRecruited, 'text', 'soldierMemorial');
  Add(FTxtLost, 'text', 'soldierMemorial');
  Add(FList, 'list', 'soldierMemorial');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnStatistics.SetText(Tr('STR_STATISTICS'));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_MEMORIAL'));
  FTxtName.SetText(Tr('STR_NAME_UC'));
  FTxtRank.SetText(Tr('STR_RANK'));
  FTxtDate.SetText(Tr('STR_DATE_UC'));
  LLost := LSave.DeadSoldiers.Count;
  LRecruited := LLost;
  LCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(AHost));
  try
    for LBase in LSave.Bases do
      Inc(LRecruited, LCapacity.TotalSoldiers(LBase));
  finally
    LCapacity.Free;
  end;
  FTxtRecruited.SetText(Tr('STR_SOLDIERS_RECRUITED_UC').Arg(LRecruited));
  FTxtLost.SetText(Tr('STR_SOLDIERS_LOST_UC').Arg(LLost));
  FList.SetColumns([114, 88, 30, 25, 35]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FList.OnMouseClick(ListClick);
  for LIndex := LSave.DeadSoldiers.Count - 1 downto 0 do
  begin
    LSoldier := LSave.DeadSoldiers[LIndex];
    FList.AddRow([LSoldier.Name, Tr(TXcomBaseNames.RankKey(LSoldier.Rank)).Text,
      Tr(LSoldier.Death.Time.DayStringKey).Arg(LSoldier.Death.Time.Day).Text,
      Tr(LSoldier.Death.Time.MonthString).Text, IntToStr(LSoldier.Death.Time.Year)]);
  end;
end;

procedure TXcomSoldierMemorialState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
  Host.PlayMusic('GMGEO');
end;

procedure TXcomSoldierMemorialState.ListClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomSoldierInfoState.Create(Host, nil, FList.GetSelectedRow));
end;

end.
