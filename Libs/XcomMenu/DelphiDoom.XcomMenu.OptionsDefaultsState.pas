{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsDefaultsState of OpenXcom (the        }
{  question "restore the default options?")                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.OptionsDefaultsState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   A popup that asks if the options go back to their defaults. Yes restores them, saves them, closes the popup and
  ///   does what OK of the options screen does (the handler it is given: the C++ calls the screen)
  /// </summary>
  TXcomOptionsDefaultsState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FOnOk: TXcomActionHandler;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AOnOk: TXcomActionHandler);
  end;

implementation

constructor TXcomOptionsDefaultsState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const AOnOk: TXcomActionHandler);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FOnOk := AOnOk;
  // _screen = false
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 100, 32, 50, wpBoth);
  FBtnYes := TXcomTextButton.Create(60, 18, 60, 122);
  FBtnNo := TXcomTextButton.Create(60, 18, 200, 122);
  FTxtTitle := TXcomText.Create(246, 32, 37, 70);
  SetInterface('optionsMenu');
  Add(FWindow, 'confirmDefaults', 'optionsMenu');
  Add(FBtnYes, 'confirmDefaults', 'optionsMenu');
  Add(FBtnNo, 'confirmDefaults', 'optionsMenu');
  Add(FTxtTitle, 'confirmDefaults', 'optionsMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnYes.OnKeyboardPress(YesClick, Host.Options.KeyOk);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FBtnNo.OnKeyboardPress(NoClick, Host.Options.KeyCancel);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr('STR_RESTORE_DEFAULTS_QUESTION'));
end;

procedure TXcomOptionsDefaultsState.YesClick(AAction: TXcomAction);
begin
  Host.Options.ResetDefaults;
  if (Host.OptionsStore <> nil) then
    Host.OptionsStore.Save(Host.Options);
  Host.PopState;
  FOnOk(AAction);
end;

procedure TXcomOptionsDefaultsState.NoClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
