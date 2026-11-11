{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - DeleteGameState of OpenXcom (asks to delete a saved game)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.DeleteGameState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   The question "Is it OK to delete the saved game?" with Yes and No. Yes deletes the file through the save
  ///   catalog of the host and, when it cannot, shows the error window
  /// </summary>
  TXcomDeleteGameState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FFileName: string;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtMessage: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string);
  end;

implementation

uses
  DelphiDoom.XcomMenu.ErrorMessageState;

constructor TXcomDeleteGameState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FFileName := AFileName;
  // _screen = false: the list stays visible around the window
  ToggleScreen;
  FWindow :=TXcomWindow.Create(Self, 256, 100, 32, 50, wpBoth);
  FBtnYes := TXcomTextButton.Create(60, 18, 60, 122);
  FBtnNo := TXcomTextButton.Create(60, 18, 200, 122);
  FTxtMessage := TXcomText.Create(246, 32, 37, 70);
  SetInterface('saveMenus');
  Add(FWindow, 'confirmDelete', 'saveMenus');
  Add(FBtnYes, 'confirmDelete', 'saveMenus');
  Add(FBtnNo, 'confirmDelete', 'saveMenus');
  Add(FTxtMessage, 'confirmDelete', 'saveMenus');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnYes.OnKeyboardPress(YesClick, Host.Options.KeyOk);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FBtnNo.OnKeyboardPress(NoClick, Host.Options.KeyCancel);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetBig;
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(Tr('STR_IS_IT_OK_TO_DELETE_THE_SAVED_GAME'));
end;

procedure TXcomDeleteGameState.NoClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomDeleteGameState.YesClick(AAction: TXcomAction);
var
  LDeleted: Boolean;
begin
  Host.PopState;
  LDeleted := (Host.SaveCatalog <> nil) and Host.SaveCatalog.DeleteSave(FFileName);
  if not LDeleted then
    Host.PushState(TXcomErrorMessageState.ForOrigin(Host, FOrigin, Tr('STR_DELETE_UNSUCCESSFUL').Text, Palette));
end;

end.