{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - LowFuelState of OpenXcom (a craft is     }
{  low on fuel and returns to its base)                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.LowFuelState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>The popup "Triton-1 is low on fuel": OK, or OK and the time back to 5 seconds</summary>
  TXcomLowFuelState = class(TXcomState)
  strict private
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnOk5Secs: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtMessage: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure Ok5SecsClick(AAction: TXcomAction);
  public
    /// <param name="ACraftName">The name of the craft (already in the language)</param>
    constructor Create(AHost: TXcomStateHost; const ACraftName: string; const AControl: IXcomGeoscapeControl);
  end;

implementation

{ TXcomLowFuelState }

constructor TXcomLowFuelState.Create(AHost: TXcomStateHost; const ACraftName: string;
  const AControl: IXcomGeoscapeControl);
begin
  inherited Create(AHost);
  FControl := AControl;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 224, 120, 16, 40, wpBoth);
  FBtnOk := TXcomTextButton.Create(90, 18, 30, 120);
  FBtnOk5Secs := TXcomTextButton.Create(90, 18, 136, 120);
  FTxtTitle := TXcomText.Create(214, 17, 21, 60);
  FTxtMessage := TXcomText.Create(214, 17, 21, 90);
  SetInterface('lowFuel');
  Add(FWindow, 'window', 'lowFuel');
  Add(FBtnOk, 'button', 'lowFuel');
  Add(FBtnOk5Secs, 'button', 'lowFuel');
  Add(FTxtTitle, 'text', 'lowFuel');
  Add(FTxtMessage, 'text', 'lowFuel');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK12.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnOk5Secs.SetText(Tr('STR_OK_5_SECONDS'));
  FBtnOk5Secs.OnMouseClick(Ok5SecsClick);
  FBtnOk5Secs.OnKeyboardPress(Ok5SecsClick, Host.Options.KeyOk);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(ACraftName);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetText(Tr('STR_IS_LOW_ON_FUEL_RETURNING_TO_BASE'));
end;

procedure TXcomLowFuelState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomLowFuelState.Ok5SecsClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  Host.PopState;
end;

end.
