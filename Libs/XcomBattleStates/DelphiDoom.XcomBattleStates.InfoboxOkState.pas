{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - a message over the battle      }
{  with an OK button (InfoboxOKState: "... has died from a fatal wound")        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.InfoboxOkState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.Frame, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>A framed message that waits for OK (the mouse pointer is shown again for it)</summary>
  TXcomInfoboxOkState = class(TXcomState)
  strict private
    FFrame: TXcomFrame;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure BtnOkClick(AAction: TXcomAction);
  public
    /// <param name="APalette">The 256 colors of the battle (the palette of its depth)</param>
    constructor Create(AHost: TXcomStateHost; APalette: PXcomColor; const AMessage: string);
  end;

implementation

uses
  DelphiDoom.XcomUi.Types;

constructor TXcomInfoboxOkState.Create(AHost: TXcomStateHost; APalette: PXcomColor; const AMessage: string);
begin
  inherited Create(AHost);
  ToggleScreen;
  FFrame := TXcomFrame.Create(261, 89, 30, 48);
  FBtnOk := TXcomTextButton.Create(120, 18, 100, 112);
  FTxtTitle := TXcomText.Create(255, 61, 33, 51);
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(APalette, 0, 256);
  Add(FFrame, 'infoBoxOK', 'battlescape');
  Add(FBtnOk, 'infoBoxOKButton', 'battlescape');
  Add(FTxtTitle, 'infoBoxOK', 'battlescape');
  CenterAllSurfaces;
  FFrame.SetThickness(3);
  FFrame.SetHighContrast(True);
  FBtnOk.SetText(Tr('STR_OK').Text);
  FBtnOk.OnMouseClick(BtnOkClick);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyCancel);
  FBtnOk.SetHighContrast(True);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetVerticalAlign(vaMiddle);
  FTxtTitle.SetHighContrast(True);
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(AMessage);
  Host.Cursor.Visible := True;
end;

procedure TXcomInfoboxOkState.BtnOkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
