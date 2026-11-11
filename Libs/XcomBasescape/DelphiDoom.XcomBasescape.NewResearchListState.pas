{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - NewResearchListState of OpenXcom (the   }
{  topics that can be researched in a base)                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.NewResearchListState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomMod.RuleResearch;

type
  /// <summary>
  ///   "New research projects": the topics that can be researched in the base and have no "requires" (those are
  ///   discovered only indirectly); a click starts a project for the topic
  /// </summary>
  TXcomNewResearchListState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FProjects: TList<TXcomRuleResearch>;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FLstResearch: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
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
  DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomStrategy.ResearchRules, DelphiDoom.XcomBasescape.ResearchInfoState;

{ TXcomNewResearchListState }

constructor TXcomNewResearchListState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
begin
  inherited Create(AHost);
  FBase := ABase;
  FProjects := TList<TXcomRuleResearch>.Create;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 230, 140, 45, 30, wpBoth);
  FBtnOk := TXcomTextButton.Create(214, 16, 53, 146);
  FTxtTitle := TXcomText.Create(214, 16, 53, 38);
  FLstResearch := TXcomTextList.Create(Host.Options, Host.Clock, 198, 88, 53, 54);
  SetInterface('selectNewResearch');
  Add(FWindow, 'window', 'selectNewResearch');
  Add(FBtnOk, 'button', 'selectNewResearch');
  Add(FTxtTitle, 'text', 'selectNewResearch');
  Add(FLstResearch, 'list', 'selectNewResearch');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_NEW_RESEARCH_PROJECTS'));
  FLstResearch.SetColumns([190]);
  FLstResearch.SetSelectable(True);
  FLstResearch.SetBackground(FWindow);
  FLstResearch.SetMargin(8);
  FLstResearch.SetAlign(haCenter);
  FLstResearch.OnMouseClick(SelectProject);
end;

destructor TXcomNewResearchListState.Destroy;
begin
  inherited Destroy;
  FProjects.Free;
end;

procedure TXcomNewResearchListState.Init;
begin
  inherited Init;
  FillProjectList;
end;

procedure TXcomNewResearchListState.FillProjectList;
var
  LRules: TXcomResearchRules;
  LAvailable: TList<TXcomRuleResearch>;
  LResearch: TXcomRuleResearch;
begin
  FProjects.Clear;
  FLstResearch.ClearList;
  LRules := TXcomResearchRules.Create(TXcomStrategy.SavedGame(Host), TXcomStrategy.Ruleset(Host));
  try
    // the only place where the debug mode is considered; topics with "requires" are discovered indirectly
    LAvailable := LRules.AvailableProjects(FBase, True);
    try
      for LResearch in LAvailable do
        if Length(LResearch.Requirements) = 0 then
        begin
          FProjects.Add(LResearch);
          FLstResearch.AddRow([Tr(LResearch.Name).Text]);
        end;
    finally
      LAvailable.Free;
    end;
  finally
    LRules.Free;
  end;
end;

procedure TXcomNewResearchListState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomNewResearchListState.SelectProject(AAction: TXcomAction);
begin
  if (FLstResearch.GetSelectedRow >= 0) and (FLstResearch.GetSelectedRow < FProjects.Count) then
    Host.PushState(TXcomResearchInfoState.CreateForRule(Host, FBase, FProjects[FLstResearch.GetSelectedRow]));
end;

end.
