{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - UfoLostState of OpenXcom (a UFO that     }
{  was followed is not seen any more)                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.UfoLostState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>The popup "UFO-12 tracking lost" with an OK button</summary>
  TXcomUfoLostState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="AUfoName">The name of the UFO (already in the language)</param>
    constructor Create(AHost: TXcomStateHost; const AUfoName: string);
    property Title: TXcomText read FTxtTitle;
  end;

implementation

{ TXcomUfoLostState }

constructor TXcomUfoLostState.Create(AHost: TXcomStateHost; const AUfoName: string);
begin
  inherited Create(AHost);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 192, 104, 32, 48, wpBoth);
  FBtnOk := TXcomTextButton.Create(60, 12, 98, 112);
  FTxtTitle := TXcomText.Create(160, 32, 48, 72);
  SetInterface('UFOLost');
  Add(FWindow, 'window', 'UFOLost');
  Add(FBtnOk, 'button', 'UFOLost');
  Add(FTxtTitle, 'text', 'UFOLost');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK15.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(AUfoName + #10 + Tr('STR_TRACKING_LOST').Text);
end;

procedure TXcomUfoLostState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
