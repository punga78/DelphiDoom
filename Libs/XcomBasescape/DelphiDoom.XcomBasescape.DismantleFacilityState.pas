{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - DismantleFacilityState of OpenXcom (the }
{  confirmation to dismantle a facility)                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.DismantleFacilityState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomBasescape.BaseView;

type
  /// <summary>
  ///   "Dismantle" with the name of the facility, OK and Cancel. OK removes the facility from the base (the access
  ///   lift removes the whole base from the game) and gives back the cost of a building that had not started
  /// </summary>
  TXcomDismantleFacilityState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FView: TXcomBaseView;
    FFacility: TXcomBaseFacility;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtFacility: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned; the saved game frees it when the lift goes)</param>
    /// <param name="AView">The grid to refresh (not owned)</param>
    /// <param name="AFacility">The facility (not owned until it is removed)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AView: TXcomBaseView; AFacility: TXcomBaseFacility);
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomMod.RuleBaseFacility, DelphiDoom.XcomGeoscape.Strategy;

{ TXcomDismantleFacilityState }

constructor TXcomDismantleFacilityState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AView: TXcomBaseView;
  AFacility: TXcomBaseFacility);
begin
  inherited Create(AHost);
  FBase := ABase;
  FView := AView;
  FFacility := AFacility;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 152, 80, 20, 60, wpNone);
  FBtnOk := TXcomTextButton.Create(44, 16, 36, 115);
  FBtnCancel := TXcomTextButton.Create(44, 16, 112, 115);
  FTxtTitle := TXcomText.Create(142, 9, 25, 75);
  FTxtFacility := TXcomText.Create(142, 9, 25, 85);
  SetInterface('dismantleFacility');
  Add(FWindow, 'window', 'dismantleFacility');
  Add(FBtnOk, 'button', 'dismantleFacility');
  Add(FBtnCancel, 'button', 'dismantleFacility');
  Add(FTxtTitle, 'text', 'dismantleFacility');
  Add(FTxtFacility, 'text', 'dismantleFacility');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_DISMANTLE'));
  FTxtFacility.SetAlign(haCenter);
  FTxtFacility.SetText(Tr(FFacility.Rules.FacilityType));
end;

procedure TXcomDismantleFacilityState.OkClick(AAction: TXcomAction);
var
  LSave: TXcomSavedGame;
  LRule: TXcomRuleBaseFacility;
begin
  LSave := TXcomStrategy.SavedGame(Host);
  LRule := TXcomStrategy.Ruleset(Host).Facilities.Find(FFacility.Rules.FacilityType);
  if not LRule.IsLift then
  begin
    // refund for a building that is queued and not started
    if FFacility.BuildTime > LRule.BuildTime then
      LSave.SetFunds(LSave.Funds + LRule.BuildCost);
    if FBase.Facilities.Contains(FFacility) then
    begin
      FView.ResetSelectedFacility;
      FBase.Facilities.Remove(FFacility);
    end;
  end
  else if LSave.Bases.Contains(FBase) then
    // the whole base goes with its access lift
    LSave.Bases.Remove(FBase);
  Host.PopState;
end;

procedure TXcomDismantleFacilityState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
