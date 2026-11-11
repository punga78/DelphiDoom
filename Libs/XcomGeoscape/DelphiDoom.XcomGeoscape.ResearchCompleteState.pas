{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ResearchCompleteState of OpenXcom (a     }
{  research project is finished)                                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ResearchCompleteState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>"Research completed" with the name of the topic; the second button opens the Ufopaedia</summary>
  TXcomResearchCompleteState = class(TXcomState)
  strict private
    FOnReport: TProc;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnReport: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtResearch: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure ReportClick(AAction: TXcomAction);
  public
    /// <param name="AResearchName">The name of the finished topic (the key of the language; '' when there is none)</param>
    /// <param name="AOnReport">Opens the entries of the Ufopaedia after the popup is closed (nil: nothing)</param>
    constructor Create(AHost: TXcomStateHost; const AResearchName: string; const AOnReport: TProc);
  end;

implementation

{ TXcomResearchCompleteState }

constructor TXcomResearchCompleteState.Create(AHost: TXcomStateHost; const AResearchName: string;
  const AOnReport: TProc);
begin
  inherited Create(AHost);
  FOnReport := AOnReport;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 230, 140, 45, 30, wpBoth);
  FBtnOk := TXcomTextButton.Create(80, 16, 64, 146);
  FBtnReport := TXcomTextButton.Create(80, 16, 176, 146);
  FTxtTitle := TXcomText.Create(230, 17, 45, 70);
  FTxtResearch := TXcomText.Create(230, 32, 45, 96);
  SetInterface('geoResearchComplete');
  Add(FWindow, 'window', 'geoResearchComplete');
  Add(FBtnOk, 'button', 'geoResearchComplete');
  Add(FBtnReport, 'button', 'geoResearchComplete');
  Add(FTxtTitle, 'text1', 'geoResearchComplete');
  Add(FTxtResearch, 'text2', 'geoResearchComplete');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnReport.SetText(Tr('STR_VIEW_REPORTS'));
  FBtnReport.OnMouseClick(ReportClick);
  FBtnReport.OnKeyboardPress(ReportClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_RESEARCH_COMPLETED'));
  FTxtResearch.SetAlign(haCenter);
  FTxtResearch.SetBig;
  FTxtResearch.SetWordWrap(True);
  if AResearchName <> '' then
    FTxtResearch.SetText(Tr(AResearchName));
end;

procedure TXcomResearchCompleteState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomResearchCompleteState.ReportClick(AAction: TXcomAction);
begin
  Host.PopState;
  if Assigned(FOnReport) then
    FOnReport();
end;

end.
