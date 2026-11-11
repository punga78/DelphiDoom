{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - PlaceFacilityState of OpenXcom (where   }
{  a facility is built)                                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.PlaceFacilityState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomBasescape.BaseView;

type
  /// <summary>
  ///   The grid of the base with the cost, the construction time and the maintenance of the facility: a click on a
  ///   place where it fits builds it (the cost is taken from the funds); elsewhere a message says it cannot be built
  ///   there, or that the money is not enough. The queue of buildings (option allowBuildingQueue) is not ported
  /// </summary>
  TXcomPlaceFacilityState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FRule: TXcomRuleBaseFacility;
    FWindow: TXcomWindow;
    FView: TXcomBaseView;
    FBtnCancel: TXcomTextButton;
    FTxtFacility: TXcomText;
    FTxtCost: TXcomText;
    FNumCost: TXcomText;
    FTxtTime: TXcomText;
    FNumTime: TXcomText;
    FTxtMaintenance: TXcomText;
    FNumMaintenance: TXcomText;
    procedure CancelClick(AAction: TXcomAction);
    procedure ViewClick(AAction: TXcomAction);
    procedure ShowError(const AKey: string);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ARule">The facility to build (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ARule: TXcomRuleBaseFacility);
    property View: TXcomBaseView read FView;
    /// <summary>The click of the view on the square (AX, AY) of the grid</summary>
    procedure Place;
  end;

implementation

uses
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.BaseFacility,
  DelphiDoom.XcomSave.RuleAdapters, DelphiDoom.XcomGeoscape.Strategy, DelphiDoom.XcomBasescape.Funding,
  DelphiDoom.XcomMenu.ErrorMessageState;

{ TXcomPlaceFacilityState }

constructor TXcomPlaceFacilityState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ARule: TXcomRuleBaseFacility);
begin
  inherited Create(AHost);
  FBase := ABase;
  FRule := ARule;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 128, 160, 192, 40, wpNone);
  FView := TXcomBaseView.Create(Host.Clock, TXcomStrategy.Ruleset(AHost), 192, 192, 0, 8);
  FBtnCancel := TXcomTextButton.Create(112, 16, 200, 176);
  FTxtFacility := TXcomText.Create(110, 9, 202, 50);
  FTxtCost := TXcomText.Create(110, 9, 202, 62);
  FNumCost := TXcomText.Create(110, 17, 202, 70);
  FTxtTime := TXcomText.Create(110, 9, 202, 90);
  FNumTime := TXcomText.Create(110, 17, 202, 98);
  FTxtMaintenance := TXcomText.Create(110, 9, 202, 118);
  FNumMaintenance := TXcomText.Create(110, 17, 202, 126);
  SetInterface('placeFacility');
  Add(FWindow, 'window', 'placeFacility');
  Add(FView, 'baseView', 'basescape');
  Add(FBtnCancel, 'button', 'placeFacility');
  Add(FTxtFacility, 'text', 'placeFacility');
  Add(FTxtCost, 'text', 'placeFacility');
  Add(FNumCost, 'numbers', 'placeFacility');
  Add(FTxtTime, 'text', 'placeFacility');
  Add(FNumTime, 'numbers', 'placeFacility');
  Add(FTxtMaintenance, 'text', 'placeFacility');
  Add(FNumMaintenance, 'numbers', 'placeFacility');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FView.SetTexture(TXcomStrategy.Rules(AHost).GetSurfaceSet('BASEBITS.PCK'));
  FView.SetBase(FBase);
  FView.SetSelectable(FRule.Size);
  FView.OnMouseClick(ViewClick);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtFacility.SetText(Tr(FRule.FacilityType));
  FTxtCost.SetText(Tr('STR_COST_UC'));
  FNumCost.SetBig;
  FNumCost.SetText(TXcomFunding.Format(FRule.BuildCost));
  FTxtTime.SetText(Tr('STR_CONSTRUCTION_TIME_UC'));
  FNumTime.SetBig;
  FNumTime.SetText(Tr('STR_DAY', FRule.BuildTime));
  FTxtMaintenance.SetText(Tr('STR_MAINTENANCE_UC'));
  FNumMaintenance.SetBig;
  FNumMaintenance.SetText(TXcomFunding.Format(FRule.MonthlyCost));
end;

procedure TXcomPlaceFacilityState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomPlaceFacilityState.ShowError(const AKey: string);
var
  LInterface: TXcomRuleInterface;
  LMessage, LPalette: TXcomInterfaceElement;
begin
  LMessage := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  LPalette.Color := -1;
  LInterface := Host.Resources.GetInterface('placeFacility');
  if LInterface <> nil then
  begin
    LInterface.TryGetElement('errorMessage', LMessage);
    LInterface.TryGetElement('errorPalette', LPalette);
  end;
  Host.PushState(TXcomErrorMessageState.Create(Host, Tr(AKey), Palette, Byte(LMessage.Color), 'BACK01.SCR',
    LPalette.Color));
end;

procedure TXcomPlaceFacilityState.ViewClick(AAction: TXcomAction);
begin
  Place;
end;

procedure TXcomPlaceFacilityState.Place;
var
  LSave: TXcomSavedGame;
  LFacility: TXcomBaseFacility;
begin
  LSave := TXcomStrategy.SavedGame(Host);
  if not FView.IsPlaceable(FRule, False) then
    ShowError('STR_CANNOT_BUILD_HERE')
  else if LSave.Funds < FRule.BuildCost then
  begin
    Host.PopState;
    ShowError('STR_NOT_ENOUGH_MONEY');
  end
  else
  begin
    LFacility := TXcomBaseFacility.Create(TXcomFacilityRuleAdapter.Create(FRule));
    LFacility.X := FView.GridX;
    LFacility.Y := FView.GridY;
    LFacility.BuildTime := FRule.BuildTime;
    FBase.Facilities.Add(LFacility);
    LSave.SetFunds(LSave.Funds - FRule.BuildCost);
    Host.PopState;
  end;
end;

end.
