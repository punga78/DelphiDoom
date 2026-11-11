{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - AbandonGameState of OpenXcom (the question   }
{  "Abandon game?")                                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.AbandonGameState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Session.Intf,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   Yes goes back to the main menu and the saved game is gone (in an ironman game it is saved first, then the same);
  ///   No closes the window
  /// </summary>
  TXcomAbandonGameState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FWindow: TXcomWindow;
    FBtnYes: TXcomTextButton;
    FBtnNo: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure YesClick(AAction: TXcomAction);
    procedure NoClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin);
    property YesButton: TXcomTextButton read FBtnYes;
    property NoButton: TXcomTextButton read FBtnNo;
  end;

implementation

uses
  DelphiDoom.XcomMenu.SaveGameState;

constructor TXcomAbandonGameState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin);
var
  LX: Integer;
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  ToggleScreen;
  if FOrigin = ooGeoscape then
    LX := 20
  else
    LX := 52;
  FWindow := TXcomWindow.Create(Self, 216, 160, LX, 20, wpBoth);
  FBtnYes := TXcomTextButton.Create(50, 20, LX + 18, 140);
  FBtnNo := TXcomTextButton.Create(50, 20, LX + 148, 140);
  FTxtTitle := TXcomText.Create(206, 17, LX + 5, 70);
  SetInterface('geoscape');
  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FBtnYes, 'genericButton2', 'geoscape');
  Add(FBtnNo, 'genericButton2', 'geoscape');
  Add(FTxtTitle, 'genericText', 'geoscape');
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
  FTxtTitle.SetText(Tr('STR_ABANDON_GAME_QUESTION'));
end;

procedure TXcomAbandonGameState.YesClick(AAction: TXcomAction);
var
  LSaver: IXcomSavedGameSaver;
begin
  LSaver := Host.SavedGameSaver;
  if LSaver = nil then
    Exit;
  if not LSaver.IsIronman then
    LSaver.AbandonGame
  else
    Host.PushState(TXcomSaveGameState.Create(Host, ooGeoscape, stIronmanEnd, Palette));
end;

procedure TXcomAbandonGameState.NoClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
