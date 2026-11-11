{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - ResearchState of OpenXcom (the current  }
{  research projects of a base)                                                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ResearchState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseCapacity;

type
  /// <summary>
  ///   "Current research": the projects with the scientists assigned and the progress, the scientists and the
  ///   laboratory space that are free; a click on a project opens its screen, the button starts a new project
  /// </summary>
  TXcomResearchState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FCapacity: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FBtnNew: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtAvailable: TXcomText;
    FTxtAllocated: TXcomText;
    FTxtSpace: TXcomText;
    FTxtProject: TXcomText;
    FTxtScientists: TXcomText;
    FTxtProgress: TXcomText;
    FLstResearch: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure NewClick(AAction: TXcomAction);
    procedure SelectProject(AAction: TXcomAction);
    procedure FillProjectList;
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    destructor Destroy; override;
    procedure Init; override;
    property List: TXcomTextList read FLstResearch;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.ResearchInfoState,
  DelphiDoom.XcomBasescape.NewResearchListState;

{ TXcomResearchState }

constructor TXcomResearchState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
begin
  inherited Create(AHost);
  FBase := ABase;
  FCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(AHost));
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpNone);
  FBtnNew := TXcomTextButton.Create(148, 16, 8, 176);
  FBtnOk := TXcomTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TXcomText.Create(310, 17, 5, 8);
  FTxtAvailable := TXcomText.Create(150, 9, 10, 24);
  FTxtAllocated := TXcomText.Create(150, 9, 160, 24);
  FTxtSpace := TXcomText.Create(300, 9, 10, 34);
  FTxtProject := TXcomText.Create(110, 17, 10, 44);
  FTxtScientists := TXcomText.Create(106, 17, 120, 44);
  FTxtProgress := TXcomText.Create(84, 9, 226, 44);
  FLstResearch := TXcomTextList.Create(Host.Options, Host.Clock, 288, 112, 8, 62);
  SetInterface('researchMenu');
  Add(FWindow, 'window', 'researchMenu');
  Add(FBtnNew, 'button', 'researchMenu');
  Add(FBtnOk, 'button', 'researchMenu');
  Add(FTxtTitle, 'text', 'researchMenu');
  Add(FTxtAvailable, 'text', 'researchMenu');
  Add(FTxtAllocated, 'text', 'researchMenu');
  Add(FTxtSpace, 'text', 'researchMenu');
  Add(FTxtProject, 'text', 'researchMenu');
  Add(FTxtScientists, 'text', 'researchMenu');
  Add(FTxtProgress, 'text', 'researchMenu');
  Add(FLstResearch, 'list', 'researchMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnNew.SetText(Tr('STR_NEW_PROJECT'));
  FBtnNew.OnMouseClick(NewClick);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_CURRENT_RESEARCH'));
  FTxtProject.SetWordWrap(True);
  FTxtProject.SetText(Tr('STR_RESEARCH_PROJECT'));
  FTxtScientists.SetWordWrap(True);
  FTxtScientists.SetText(Tr('STR_SCIENTISTS_ALLOCATED_UC'));
  FTxtProgress.SetText(Tr('STR_PROGRESS'));
  FLstResearch.SetColumns([158, 58, 70]);
  FLstResearch.SetSelectable(True);
  FLstResearch.SetBackground(FWindow);
  FLstResearch.SetMargin(2);
  FLstResearch.SetWordWrap(True);
  FLstResearch.OnMouseClick(SelectProject);
end;

destructor TXcomResearchState.Destroy;
begin
  inherited Destroy;
  FCapacity.Free;
end;

procedure TXcomResearchState.Init;
begin
  inherited Init;
  FillProjectList;
end;

procedure TXcomResearchState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomResearchState.NewClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomNewResearchListState.Create(Host, FBase));
end;

procedure TXcomResearchState.SelectProject(AAction: TXcomAction);
begin
  if (FLstResearch.GetSelectedRow >= 0) and (FLstResearch.GetSelectedRow < FBase.Research.Count) then
    Host.PushState(TXcomResearchInfoState.Create(Host, FBase, FBase.Research[FLstResearch.GetSelectedRow]));
end;

procedure TXcomResearchState.FillProjectList;
var
  LIndex, LAllocated: Integer;
begin
  FLstResearch.ClearList;
  LAllocated := 0;
  for LIndex := 0 to FBase.Research.Count - 1 do
  begin
    FLstResearch.AddRow([Tr(FBase.Research[LIndex].Rules.Name).Text, IntToStr(FBase.Research[LIndex].Assigned),
      Tr(FBase.Research[LIndex].ResearchProgress).Text]);
    Inc(LAllocated, FBase.Research[LIndex].Assigned);
  end;
  FTxtAvailable.SetText(Tr('STR_SCIENTISTS_AVAILABLE').Arg(FCapacity.AvailableScientists(FBase)));
  FTxtAllocated.SetText(Tr('STR_SCIENTISTS_ALLOCATED').Arg(LAllocated));
  FTxtSpace.SetText(Tr('STR_LABORATORY_SPACE_AVAILABLE').Arg(FCapacity.FreeLaboratories(FBase)));
end;

end.
