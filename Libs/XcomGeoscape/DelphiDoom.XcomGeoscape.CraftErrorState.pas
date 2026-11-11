{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - CraftErrorState of OpenXcom (a craft     }
{  cannot be rearmed or refueled)                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.CraftErrorState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>A message with OK and "OK, 5 seconds" (the time goes back to the slowest speed)</summary>
  TXcomCraftErrorState = class(TXcomState)
  strict private
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnOk5Secs: TXcomTextButton;
    FTxtMessage: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure Ok5SecsClick(AAction: TXcomAction);
  public
    /// <param name="AMessage">The text (already in the language)</param>
    constructor Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl; const AMessage: string);
  end;

implementation

{ TXcomCraftErrorState }

constructor TXcomCraftErrorState.Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl;
  const AMessage: string);
begin
  inherited Create(AHost);
  FControl := AControl;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20, wpBoth);
  FBtnOk := TXcomTextButton.Create(100, 18, 48, 150);
  FBtnOk5Secs := TXcomTextButton.Create(100, 18, 172, 150);
  FTxtMessage := TXcomText.Create(246, 96, 37, 42);
  SetInterface('craftError');
  Add(FWindow, 'window', 'craftError');
  Add(FBtnOk, 'button', 'craftError');
  Add(FBtnOk5Secs, 'button', 'craftError');
  Add(FTxtMessage, 'text1', 'craftError');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnOk5Secs.SetText(Tr('STR_OK_5_SECONDS'));
  FBtnOk5Secs.OnMouseClick(Ok5SecsClick);
  FBtnOk5Secs.OnKeyboardPress(Ok5SecsClick, Host.Options.KeyOk);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetVerticalAlign(vaMiddle);
  FTxtMessage.SetBig;
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(AMessage);
end;

procedure TXcomCraftErrorState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomCraftErrorState.Ok5SecsClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  Host.PopState;
end;

end.
