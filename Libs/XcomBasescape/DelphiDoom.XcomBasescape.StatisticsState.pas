{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - StatisticsState of OpenXcom (the numbers  }
{  of the game so far, from the memorial; at the end of the game too)           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.StatisticsState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList;

type
  /// <summary>
  ///   The list of the statistics of the game (TXcomGameStatistics) with the title and the date. The screen of the end
  ///   of the game (a victory or a defeat, which leaves for the main menu) is not ported: OK closes the screen
  /// </summary>
  TXcomStatisticsState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost);
    property List: TXcomTextList read FList;
    property TitleText: TXcomText read FTxtTitle;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomBasescape.GameStatistics;

{ TXcomStatisticsState }

constructor TXcomStatisticsState.Create(AHost: TXcomStateHost);
var
  LSave: TXcomSavedGame;
  LRow: TXcomGameStatistic;
  LValue: string;
begin
  inherited Create(AHost);
  LSave := TXcomStrategy.SavedGame(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(50, 12, 135, 180);
  FTxtTitle := TXcomText.Create(310, 25, 5, 8);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 280, 136, 12, 36);
  SetInterface('endGameStatistics');
  Add(FWindow, 'window', 'endGameStatistics');
  Add(FBtnOk, 'button', 'endGameStatistics');
  Add(FTxtTitle, 'text', 'endGameStatistics');
  Add(FList, 'list', 'endGameStatistics');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FList.SetColumns([200, 80]);
  FList.SetDot(True);
  FTxtTitle.SetText(Tr(TXcomGameStatistics.TitleKey(LSave)).Text + Chr(XCOM_TOKEN_NEWLINE_SMALL) +
    Tr(LSave.Time.DayStringKey).Arg(LSave.Time.Day).Text + ' ' + Tr(LSave.Time.MonthString).Text + ' ' +
    IntToStr(LSave.Time.Year));
  for LRow in TXcomGameStatistics.Calculate(LSave, TXcomStrategy.Ruleset(AHost)) do
  begin
    if LRow.ValueIsKey then
      LValue := Tr(LRow.Value).Text
    else
      LValue := LRow.Value;
    FList.AddRow([Tr(LRow.LabelKey).Text, LValue]);
  end;
end;

procedure TXcomStatisticsState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
