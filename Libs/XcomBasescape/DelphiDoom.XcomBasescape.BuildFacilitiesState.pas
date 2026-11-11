{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - BuildFacilitiesState of OpenXcom (the   }
{  list of the facilities that can be built)                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.BuildFacilitiesState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomMod.RuleBaseFacility;

type
  /// <summary>
  ///   "Installation": the facilities (not the lift) whose research requirements are met; a click chooses where to
  ///   build one. When it comes back to the top it asks the basescape that opened it to refresh
  /// </summary>
  TXcomBuildFacilitiesState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FParent: TXcomState;
    FFacilities: TList<TXcomRuleBaseFacility>;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FLstFacilities: TXcomTextList;
    FTxtTitle: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure FacilitiesClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="AParent">The basescape to refresh when this state is on top again (not owned; nil: none)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AParent: TXcomState);
    destructor Destroy; override;
    procedure Init; override;
    property List: TXcomTextList read FLstFacilities;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.PlaceFacilityState;

{ TXcomBuildFacilitiesState }

constructor TXcomBuildFacilitiesState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AParent: TXcomState);
var
  LName: string;
  LRule: TXcomRuleBaseFacility;
begin
  inherited Create(AHost);
  FBase := ABase;
  FParent := AParent;
  FFacilities := TList<TXcomRuleBaseFacility>.Create;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 128, 160, 192, 40, wpVertical);
  FBtnOk := TXcomTextButton.Create(112, 16, 200, 176);
  FLstFacilities := TXcomTextList.Create(Host.Options, Host.Clock, 104, 104, 200, 64);
  FTxtTitle := TXcomText.Create(118, 17, 197, 48);
  SetInterface('selectFacility');
  Add(FWindow, 'window', 'selectFacility');
  Add(FBtnOk, 'button', 'selectFacility');
  Add(FTxtTitle, 'text', 'selectFacility');
  Add(FLstFacilities, 'list', 'selectFacility');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_INSTALLATION'));
  FLstFacilities.SetColumns([104]);
  FLstFacilities.SetSelectable(True);
  FLstFacilities.SetBackground(FWindow);
  FLstFacilities.SetMargin(2);
  FLstFacilities.SetWordWrap(True);
  FLstFacilities.SetScrolling(True, 0);
  FLstFacilities.OnMouseClick(FacilitiesClick);
  // PopulateBuildList: the facilities whose requirements are researched
  for LName in TXcomStrategy.Ruleset(AHost).Facilities.Index do
  begin
    LRule := TXcomStrategy.Ruleset(AHost).Facilities.Find(LName);
    if TXcomStrategy.SavedGame(AHost).IsResearched(LRule.Requirements) and not LRule.IsLift then
      FFacilities.Add(LRule);
  end;
  for LRule in FFacilities do
    FLstFacilities.AddRow([Tr(LRule.FacilityType).Text]);
end;

destructor TXcomBuildFacilitiesState.Destroy;
begin
  inherited Destroy;
  FFacilities.Free;
end;

procedure TXcomBuildFacilitiesState.Init;
begin
  if Assigned(FParent) then
    FParent.Init;
  inherited Init;
end;

procedure TXcomBuildFacilitiesState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomBuildFacilitiesState.FacilitiesClick(AAction: TXcomAction);
begin
  if (FLstFacilities.GetSelectedRow >= 0) and (FLstFacilities.GetSelectedRow < FFacilities.Count) then
    Host.PushState(TXcomPlaceFacilityState.Create(Host, FBase, FFacilities[FLstFacilities.GetSelectedRow]));
end;

end.
