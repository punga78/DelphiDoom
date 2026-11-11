{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - PauseState of OpenXcom (the Options window   }
{  of the game in progress: load, save, abandon, options)                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.PauseState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf;

type
  /// <summary>
  ///   The pause window of the geoscape: Load Game, Save Game, Abandon Game, Game Options and Cancel. In an ironman
  ///   game load and save are hidden and abandon becomes "Save and abandon". The options screens come from the
  ///   navigator of the options (nil: Game Options does nothing)
  /// </summary>
  TXcomPauseState = class(TXcomState)
  strict private
    FOrigin: TXcomOptionsOrigin;
    FNavigator: IXcomOptionsNavigator;
    FWindow: TXcomWindow;
    FBtnLoad: TXcomTextButton;
    FBtnSave: TXcomTextButton;
    FBtnAbandon: TXcomTextButton;
    FBtnOptions: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure LoadClick(AAction: TXcomAction);
    procedure SaveClick(AAction: TXcomAction);
    procedure AbandonClick(AAction: TXcomAction);
    procedure OptionsClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
    property LoadButton: TXcomTextButton read FBtnLoad;
    property SaveButton: TXcomTextButton read FBtnSave;
    property AbandonButton: TXcomTextButton read FBtnAbandon;
    property OptionsButton: TXcomTextButton read FBtnOptions;
    property CancelButton: TXcomTextButton read FBtnCancel;
  end;

implementation

uses
  DelphiDoom.XcomMenu.BattlescapeTheme,
  DelphiDoom.XcomMenu.ListLoadState, DelphiDoom.XcomMenu.ListSaveState, DelphiDoom.XcomMenu.AbandonGameState;

constructor TXcomPauseState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LX: Integer;
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FNavigator := ANavigator;
  ToggleScreen;
  if FOrigin = ooGeoscape then
    LX := 20
  else
    LX := 52;
  FWindow := TXcomWindow.Create(Self, 216, 160, LX, 20, wpBoth);
  FBtnLoad := TXcomTextButton.Create(180, 18, LX + 18, 52);
  FBtnSave := TXcomTextButton.Create(180, 18, LX + 18, 74);
  FBtnAbandon := TXcomTextButton.Create(180, 18, LX + 18, 96);
  FBtnOptions := TXcomTextButton.Create(180, 18, LX + 18, 122);
  FBtnCancel := TXcomTextButton.Create(180, 18, LX + 18, 150);
  FTxtTitle := TXcomText.Create(206, 17, LX + 5, 32);
  SetInterface('pauseMenu', False, True);
  Add(FWindow, 'window', 'pauseMenu');
  Add(FBtnLoad, 'button', 'pauseMenu');
  Add(FBtnSave, 'button', 'pauseMenu');
  Add(FBtnAbandon, 'button', 'pauseMenu');
  Add(FBtnOptions, 'button', 'pauseMenu');
  Add(FBtnCancel, 'button', 'pauseMenu');
  Add(FTxtTitle, 'text', 'pauseMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnLoad.SetText(Tr('STR_LOAD_GAME'));
  FBtnLoad.OnMouseClick(LoadClick);
  FBtnSave.SetText(Tr('STR_SAVE_GAME'));
  FBtnSave.OnMouseClick(SaveClick);
  FBtnAbandon.SetText(Tr('STR_ABANDON_GAME'));
  FBtnAbandon.OnMouseClick(AbandonClick);
  FBtnOptions.SetText(Tr('STR_GAME_OPTIONS'));
  FBtnOptions.OnMouseClick(OptionsClick);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  // keyGeoOptions (Escape) is the same key as keyCancel; the key that opens the options of a battle closes them too
  if FOrigin = ooBattlescape then
    FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.GetValue('keyBattleOptions'));
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Tr('STR_OPTIONS_UC'));
  if FOrigin = ooBattlescape then
    TXcomBattlescapeTheme.Apply(Self);
  if (Host.SavedGameSaver <> nil) and Host.SavedGameSaver.IsIronman then
  begin
    FBtnLoad.Visible := False;
    FBtnSave.Visible := False;
    FBtnAbandon.SetText(Tr('STR_SAVE_AND_ABANDON_GAME'));
  end;
end;

procedure TXcomPauseState.LoadClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomListLoadState.Create(Host, FOrigin));
end;

procedure TXcomPauseState.SaveClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomListSaveState.Create(Host, FOrigin));
end;

procedure TXcomPauseState.AbandonClick(AAction: TXcomAction);
begin
  Host.PushState(TXcomAbandonGameState.Create(Host, FOrigin));
end;

procedure TXcomPauseState.OptionsClick(AAction: TXcomAction);
var
  LState: TXcomState;
  LCategory: TXcomOptionsCategory;
begin
  if FNavigator = nil then
    Exit;
  // OptionsGeoscapeState from the geoscape, OptionsBattlescapeState from a battle, OptionsVideoState otherwise
  case FOrigin of
    ooGeoscape:
      LCategory := ocGeoscape;
    ooBattlescape:
      LCategory := ocBattlescape;
  else
    LCategory := ocVideo;
  end;
  LState := FNavigator.CreateCategory(LCategory, FOrigin, Host);
  if LState <> nil then
    Host.PushState(LState);
end;

procedure TXcomPauseState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
