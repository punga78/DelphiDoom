{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - NewPossibleResearchState of OpenXcom     }
{  (new topics can be researched)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.NewPossibleResearchState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomMod.RuleResearch,
  DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   "We can now research": the topics without requirements that did not pop up before and are not researched;
  ///   each one is remembered as popped. The second button opens the research screen of the base
  /// </summary>
  TXcomNewPossibleResearchState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnResearch: TXcomTextButton;
    FTxtTitle: TXcomText;
    FLstPossibilities: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure ResearchClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="APossibilities">The topics that became possible (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; const APossibilities: TList<TXcomRuleResearch>;
      const AControl: IXcomGeoscapeControl);
    property Possibilities: TXcomTextList read FLstPossibilities;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.Navigator.Intf;

{ TXcomNewPossibleResearchState }

constructor TXcomNewPossibleResearchState.Create(AHost: TXcomStateHost; ABase: TXcomBase;
  const APossibilities: TList<TXcomRuleResearch>; const AControl: IXcomGeoscapeControl);
var
  LSave: TXcomSavedGame;
  LResearch: TXcomRuleResearch;
  LFoundNew: Boolean;
begin
  inherited Create(AHost);
  FBase := ABase;
  FControl := AControl;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 288, 180, 16, 10, wpNone);
  FBtnOk := TXcomTextButton.Create(160, 14, 80, 149);
  FBtnResearch := TXcomTextButton.Create(160, 14, 80, 165);
  FTxtTitle := TXcomText.Create(288, 40, 16, 20);
  FLstPossibilities := TXcomTextList.Create(Host.Options, Host.Clock, 250, 96, 35, 50);
  SetInterface('geoResearch');
  Add(FWindow, 'window', 'geoResearch');
  Add(FBtnOk, 'button', 'geoResearch');
  Add(FBtnResearch, 'button', 'geoResearch');
  Add(FTxtTitle, 'text1', 'geoResearch');
  Add(FLstPossibilities, 'text2', 'geoResearch');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnResearch.SetText(Tr('STR_ALLOCATE_RESEARCH'));
  FBtnResearch.OnMouseClick(ResearchClick);
  FBtnResearch.OnKeyboardPress(ResearchClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FLstPossibilities.SetColumns([250]);
  FLstPossibilities.SetBig;
  FLstPossibilities.SetAlign(haCenter);
  FLstPossibilities.SetScrolling(True, 0);
  LSave := TXcomStrategy.SavedGame(AHost);
  LFoundNew := False;
  for LResearch in APossibilities do
    // the topics with "requires" are left to the list of new projects; those that popped before or that are
    // researched already (topics that can be researched more than once) are ignored
    if (Length(LResearch.Requirements) = 0) and not LSave.WasResearchPopped(LResearch)
      and not LSave.IsResearched(LResearch.Name, False) then
    begin
      LSave.AddPoppedResearch(LResearch);
      FLstPossibilities.AddRow([Tr(LResearch.Name).Text]);
      LFoundNew := True;
    end;
  if LFoundNew then
    FTxtTitle.SetText(Tr('STR_WE_CAN_NOW_RESEARCH'));
end;

procedure TXcomNewPossibleResearchState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomNewPossibleResearchState.ResearchClick(AAction: TXcomAction);
begin
  Host.PopState;
  FControl.OpenBaseScreen(bsResearch, FBase);
end;

end.
