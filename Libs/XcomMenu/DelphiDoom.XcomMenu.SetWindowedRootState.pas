{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - SetWindowedRootState of OpenXcom (the        }
{  position of the window on the desktop)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.SetWindowedRootState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   A popup where the position of the window is typed. OK sets the pending options; Cancel calls the handler it
  ///   is given (the video screen releases its "fixed position" button) and closes
  /// </summary>
  TXcomSetWindowedRootState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FOnCancel: TXcomNotify;
    FWindow: TXcomWindow;
    FTxtTitle: TXcomText;
    FTxtPositionX: TXcomText;
    FTxtPositionY: TXcomText;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FEdtPositionX: TXcomTextEdit;
    FEdtPositionY: TXcomTextEdit;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AOnCancel: TXcomNotify);
  end;

implementation

constructor TXcomSetWindowedRootState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const AOnCancel: TXcomNotify);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FOnCancel := AOnCancel;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 216, 100, 52, 50, wpBoth);
  FTxtTitle := TXcomText.Create(206, 20, 57, 70);
  FTxtPositionX := TXcomText.Create(160, 10, 25, 90);
  FTxtPositionY := TXcomText.Create(160, 10, 25, 100);
  FBtnOk := TXcomTextButton.Create(50, 20, 70, 120);
  FBtnCancel := TXcomTextButton.Create(50, 20, 200, 120);
  FEdtPositionX := TXcomTextEdit.Create(Self, 40, 10, 190, 90);
  FEdtPositionY := TXcomTextEdit.Create(Self, 40, 10, 190, 100);
  SetInterface('optionsMenu');
  Add(FWindow, 'confirmVideo', 'optionsMenu');
  Add(FBtnOk, 'confirmVideo', 'optionsMenu');
  Add(FBtnCancel, 'confirmVideo', 'optionsMenu');
  Add(FTxtTitle, 'confirmVideo', 'optionsMenu');
  Add(FTxtPositionX, 'confirmVideo', 'optionsMenu');
  Add(FTxtPositionY, 'confirmVideo', 'optionsMenu');
  Add(FEdtPositionX, 'confirmVideo', 'optionsMenu');
  Add(FEdtPositionY, 'confirmVideo', 'optionsMenu');
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetWordWrap(True);
  FTxtTitle.SetText(Tr('STR_DISPLAY_SET_WINDOW_POSITION'));
  FTxtPositionX.SetAlign(haRight);
  FTxtPositionX.SetWordWrap(True);
  FTxtPositionX.SetText(Tr('STR_DISPLAY_WINDOW_POSITION_NEW_X'));
  FTxtPositionY.SetAlign(haRight);
  FTxtPositionY.SetWordWrap(True);
  FTxtPositionY.SetText(Tr('STR_DISPLAY_WINDOW_POSITION_NEW_Y'));
  FEdtPositionX.SetText(IntToStr(Host.Options.NewWindowedModePositionX));
  FEdtPositionX.SetConstraint(tecNumeric);
  FEdtPositionY.SetText(IntToStr(Host.Options.NewWindowedModePositionY));
  FEdtPositionY.SetConstraint(tecNumeric);
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
end;

procedure TXcomSetWindowedRootState.OkClick(AAction: TXcomAction);
begin
  // the stream of the C++ reads an integer and leaves 0 when the text is not one
  Host.Options.NewRootWindowedMode := True;
  Host.Options.NewWindowedModePositionX := StrToIntDef(FEdtPositionX.GetText, 0);
  Host.Options.NewWindowedModePositionY := StrToIntDef(FEdtPositionY.GetText, 0);
  Host.PopState;
end;

procedure TXcomSetWindowedRootState.CancelClick(AAction: TXcomAction);
begin
  if Assigned(FOnCancel) then
    FOnCancel();
  Host.PopState;
end;

end.
