{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ConfirmLoadState of OpenXcom (asks whether   }
{  to load a saved game that needs mods that are not active)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.ConfirmLoadState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   The question "The saved game needs mods that are not installed or not active: load it anyway?" with Yes and
  ///   No. Yes replaces the question with the loading of the game; No closes it
  /// </summary>
  TXcomConfirmLoadState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FFileName: string;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtText: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AFileName: string);
  end;

implementation

uses
  DelphiDoom.XcomMenu.LoadGameState;

constructor TXcomConfirmLoadState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const AFileName: string);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FFileName := AFileName;
  // _screen = false: the list stays visible around the window
  ToggleScreen;
  FWindow :=TXcomWindow.Create(Self, 216, 100, 52, 50, wpBoth);
  FBtnYes := TXcomTextButton.Create(50, 20, 70, 120);
  FBtnNo := TXcomTextButton.Create(50, 20, 200, 120);
  FTxtText := TXcomText.Create(204, 58, 58, 60);
  SetInterface('saveMenus');
  Add(FWindow, 'confirmLoad', 'saveMenus');
  Add(FBtnYes, 'confirmLoad', 'saveMenus');
  Add(FBtnNo, 'confirmLoad', 'saveMenus');
  Add(FTxtText, 'confirmLoad', 'saveMenus');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnYes.SetText(Tr('STR_YES'));
  FBtnYes.OnMouseClick(YesClick);
  FBtnYes.OnKeyboardPress(YesClick, Host.Options.KeyOk);
  FBtnNo.SetText(Tr('STR_NO'));
  FBtnNo.OnMouseClick(NoClick);
  FBtnNo.OnKeyboardPress(NoClick, Host.Options.KeyCancel);
  FTxtText.SetAlign(haCenter);
  FTxtText.SetBig;
  FTxtText.SetWordWrap(True);
  FTxtText.SetText(Tr('STR_MISSING_CONTENT_PROMPT'));
end;

procedure TXcomConfirmLoadState.YesClick(AAction: TXcomAction);
begin
  Host.PopState;
  Host.PushState(TXcomLoadGameState.Create(Host, FOrigin, FFileName, Palette));
end;

procedure TXcomConfirmLoadState.NoClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
