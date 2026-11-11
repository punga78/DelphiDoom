{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - ResearchInfoState of OpenXcom (the      }
{  scientists of a research project)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ResearchInfoState;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.InteractiveSurface,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.ArrowButton, DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.ResearchProject,
  DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomMod.RuleResearch;

type
  /// <summary>
  ///   The scientists of a project: more and less (one with the left button, all with the right, held down they
  ///   repeat). For a new project (made from a topic) the project is added to the base when the screen opens, with a
  ///   cost between half and one and a half of the cost of the topic, and Cancel takes it away; for a project that
  ///   exists the button cancels the project
  /// </summary>
  TXcomResearchInfoState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FProject: TXcomResearchProject;
    FRule: TXcomRuleResearch;
    FCapacity: TXcomBaseCapacity;
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FTxtAvailableScientist: TXcomText;
    FTxtAvailableSpace: TXcomText;
    FTxtAllocatedScientist: TXcomText;
    FTxtMore: TXcomText;
    FTxtLess: TXcomText;
    FBtnCancel: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FBtnMore: TXcomArrowButton;
    FBtnLess: TXcomArrowButton;
    FSurfaceScientists: TXcomInteractiveSurface;
    FTimerMore: TXcomTimer;
    FTimerLess: TXcomTimer;
    procedure BuildUi;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
    procedure HandleWheel(AAction: TXcomAction);
    procedure MorePress(AAction: TXcomAction);
    procedure MoreRelease(AAction: TXcomAction);
    procedure MoreClick(AAction: TXcomAction);
    procedure LessPress(AAction: TXcomAction);
    procedure LessRelease(AAction: TXcomAction);
    procedure LessClick(AAction: TXcomAction);
    procedure MoreTick;
    procedure LessTick;
    procedure SetAssignedScientist;
  public
    /// <summary>A project that exists (not owned)</summary>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AProject: TXcomResearchProject);
    /// <summary>A new project for a topic: it is made and added to the base</summary>
    constructor CreateForRule(AHost: TXcomStateHost; ABase: TXcomBase; ARule: TXcomRuleResearch);
    destructor Destroy; override;
    procedure Think; override;
    /// <summary>moreByValue: assigns scientists (at most the free ones and the free laboratory space)</summary>
    procedure MoreByValue(AChange: Integer);
    /// <summary>lessByValue: takes scientists away</summary>
    procedure LessByValue(AChange: Integer);
    property Project: TXcomResearchProject read FProject;
  end;

implementation

uses
  DelphiDoom.XcomGeoscape.Strategy;

{ TXcomResearchInfoState }

constructor TXcomResearchInfoState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AProject: TXcomResearchProject);
begin
  inherited Create(AHost);
  FBase := ABase;
  FProject := AProject;
  FRule := nil;
  BuildUi;
end;

constructor TXcomResearchInfoState.CreateForRule(AHost: TXcomStateHost; ABase: TXcomBase; ARule: TXcomRuleResearch);
begin
  inherited Create(AHost);
  FBase := ABase;
  FRule := ARule;
  // the cost of the project is between half and one and a half of the cost of the topic
  FProject := TXcomResearchProject.Create(ARule, Trunc(ARule.Cost * TXcomStrategy.Random(AHost).Generate(50, 150) / 100));
  BuildUi;
end;

destructor TXcomResearchInfoState.Destroy;
begin
  inherited Destroy;
  FTimerLess.Free;
  FTimerMore.Free;
  FCapacity.Free;
end;

procedure TXcomResearchInfoState.BuildUi;
begin
  FCapacity := TXcomBaseCapacity.Create(TXcomStrategy.Ruleset(Host));
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 230, 140, 45, 30, wpNone);
  FTxtTitle := TXcomText.Create(210, 17, 61, 40);
  FTxtAvailableScientist := TXcomText.Create(210, 9, 61, 60);
  FTxtAvailableSpace := TXcomText.Create(210, 9, 61, 70);
  FTxtAllocatedScientist := TXcomText.Create(210, 17, 61, 80);
  FTxtMore := TXcomText.Create(110, 17, 85, 100);
  FTxtLess := TXcomText.Create(110, 17, 85, 120);
  FBtnCancel := TXcomTextButton.Create(90, 16, 61, 145);
  FBtnOk := TXcomTextButton.Create(90, 16, 169, 145);
  FBtnMore := TXcomArrowButton.Create(Host.Clock, arBigUp, 13, 14, 195, 100);
  FBtnLess := TXcomArrowButton.Create(Host.Clock, arBigDown, 13, 14, 195, 120);
  FSurfaceScientists := TXcomInteractiveSurface.Create(230, 140, 45, 30);
  FSurfaceScientists.OnMouseClick(HandleWheel, 0);
  SetInterface('allocateResearch');
  Add(FSurfaceScientists);
  Add(FWindow, 'window', 'allocateResearch');
  Add(FBtnOk, 'button2', 'allocateResearch');
  Add(FBtnCancel, 'button2', 'allocateResearch');
  Add(FTxtTitle, 'text', 'allocateResearch');
  Add(FTxtAvailableScientist, 'text', 'allocateResearch');
  Add(FTxtAvailableSpace, 'text', 'allocateResearch');
  Add(FTxtAllocatedScientist, 'text', 'allocateResearch');
  Add(FTxtMore, 'text', 'allocateResearch');
  Add(FTxtLess, 'text', 'allocateResearch');
  Add(FBtnMore, 'button1', 'allocateResearch');
  Add(FBtnLess, 'button1', 'allocateResearch');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr(FProject.Rules.Name));
  FTxtAllocatedScientist.SetBig;
  FTxtMore.SetText(Tr('STR_INCREASE'));
  FTxtLess.SetText(Tr('STR_DECREASE'));
  FTxtMore.SetBig;
  FTxtLess.SetBig;
  if Assigned(FRule) then
  begin
    FBase.AddResearch(FProject);
    if FRule.NeedItem and FRule.DestroyItem then
      FBase.StorageItems.RemoveItem(FRule.Name, 1);
  end;
  SetAssignedScientist;
  FBtnMore.OnMousePress(MorePress);
  FBtnMore.OnMouseRelease(MoreRelease);
  FBtnMore.OnMouseClick(MoreClick, 0);
  FBtnLess.OnMousePress(LessPress);
  FBtnLess.OnMouseRelease(LessRelease);
  FBtnLess.OnMouseClick(LessClick, 0);
  FTimerMore := TXcomTimer.Create(Host.Clock, 250);
  FTimerMore.OnTimerState(MoreTick);
  FTimerLess := TXcomTimer.Create(Host.Clock, 250);
  FTimerLess.OnTimerState(LessTick);
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  if Assigned(FRule) then
  begin
    FBtnOk.SetText(Tr('STR_START_PROJECT'));
    FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
    FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  end
  else
  begin
    FBtnOk.SetText(Tr('STR_OK'));
    FBtnCancel.SetText(Tr('STR_CANCEL_PROJECT'));
    FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  end;
  FBtnCancel.OnMouseClick(CancelClick);
end;

procedure TXcomResearchInfoState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomResearchInfoState.CancelClick(AAction: TXcomAction);
begin
  // the project leaves the base (its scientists come back; the project is freed)
  FBase.RemoveResearch(FProject);
  Host.PopState;
end;

procedure TXcomResearchInfoState.SetAssignedScientist;
begin
  FTxtAvailableScientist.SetText(Tr('STR_SCIENTISTS_AVAILABLE_UC').Arg(FCapacity.AvailableScientists(FBase)));
  FTxtAvailableSpace.SetText(Tr('STR_LABORATORY_SPACE_AVAILABLE_UC').Arg(FCapacity.FreeLaboratories(FBase)));
  FTxtAllocatedScientist.SetText(Tr('STR_SCIENTISTS_ALLOCATED').Arg(FProject.Assigned));
end;

procedure TXcomResearchInfoState.HandleWheel(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
    MoreByValue(Host.Options.ChangeValueByMouseWheel)
  else if AAction.Details^.Button = XCOM_BUTTON_WHEELDOWN then
    LessByValue(Host.Options.ChangeValueByMouseWheel);
end;

procedure TXcomResearchInfoState.MorePress(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    FTimerMore.Start;
end;

procedure TXcomResearchInfoState.MoreRelease(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FTimerMore.SetInterval(250);
    FTimerMore.Stop;
  end;
end;

procedure TXcomResearchInfoState.MoreClick(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    MoreByValue(MaxInt);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    MoreByValue(1);
end;

procedure TXcomResearchInfoState.LessPress(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    FTimerLess.Start;
end;

procedure TXcomResearchInfoState.LessRelease(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FTimerLess.SetInterval(250);
    FTimerLess.Stop;
  end;
end;

procedure TXcomResearchInfoState.LessClick(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    LessByValue(MaxInt);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    LessByValue(1);
end;

procedure TXcomResearchInfoState.MoreTick;
begin
  FTimerMore.SetInterval(50);
  MoreByValue(1);
end;

procedure TXcomResearchInfoState.LessTick;
begin
  FTimerLess.SetInterval(50);
  LessByValue(1);
end;

procedure TXcomResearchInfoState.MoreByValue(AChange: Integer);
var
  LFreeScientists, LFreeSpace: Integer;
begin
  if AChange <= 0 then
    Exit;
  LFreeScientists := FCapacity.AvailableScientists(FBase);
  LFreeSpace := FCapacity.FreeLaboratories(FBase);
  if (LFreeScientists > 0) and (LFreeSpace > 0) then
  begin
    AChange := Min(Min(LFreeScientists, LFreeSpace), AChange);
    FProject.Assigned := FProject.Assigned + AChange;
    FBase.Scientists := FBase.Scientists - AChange;
    SetAssignedScientist;
  end;
end;

procedure TXcomResearchInfoState.LessByValue(AChange: Integer);
var
  LAssigned: Integer;
begin
  if AChange <= 0 then
    Exit;
  LAssigned := FProject.Assigned;
  if LAssigned > 0 then
  begin
    AChange := Min(LAssigned, AChange);
    FProject.Assigned := LAssigned - AChange;
    FBase.Scientists := FBase.Scientists + AChange;
    SetAssignedScientist;
  end;
end;

procedure TXcomResearchInfoState.Think;
begin
  inherited Think;
  FTimerLess.Think(True, False);
  FTimerMore.Think(True, False);
end;

end.
