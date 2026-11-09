{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - MainMenuState of OpenXcom                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.MainMenuState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton;

type
  /// <summary>
  ///   The main menu: a popup window with the title and the buttons New Game, New Battle, Load, Options, Mods and
  ///   Quit. Quit and Options work; the other buttons open screens that are not ported yet, and do nothing
  /// </summary>
  TXcomMainMenuState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FNewGame: TXcomTextButton;
    FNewBattle: TXcomTextButton;
    FLoad: TXcomTextButton;
    FOptions: TXcomTextButton;
    FMods: TXcomTextButton;
    FQuit: TXcomTextButton;
    FTitle: TXcomText;
    FVersionText: string;
    procedure OptionsClick(AAction: TXcomAction);
    procedure QuitClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; const AVersionText: string);
  end;

implementation


constructor TXcomMainMenuState.Create(AHost: TXcomStateHost; const AVersionText: string);
begin
  inherited Create(AHost);
  FVersionText := AVersionText;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20, wpBoth);
  FNewGame := TXcomTextButton.Create(92, 20, 64, 90);
  FNewBattle := TXcomTextButton.Create(92, 20, 164, 90);
  FLoad := TXcomTextButton.Create(92, 20, 64, 118);
  FOptions := TXcomTextButton.Create(92, 20, 164, 118);
  FMods := TXcomTextButton.Create(92, 20, 64, 146);
  FQuit := TXcomTextButton.Create(92, 20, 164, 146);
  FTitle := TXcomText.Create(256, 30, 32, 45);
  SetInterface('mainMenu');
  Add(FWindow, 'window', 'mainMenu');
  Add(FNewGame, 'button', 'mainMenu');
  Add(FNewBattle, 'button', 'mainMenu');
  Add(FLoad, 'button', 'mainMenu');
  Add(FOptions, 'button', 'mainMenu');
  Add(FMods, 'button', 'mainMenu');
  Add(FQuit, 'button', 'mainMenu');
  Add(FTitle, 'text', 'mainMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FNewGame.SetText(Tr('STR_NEW_GAME'));
  FNewBattle.SetText(Tr('STR_NEW_BATTLE'));
  FLoad.SetText(Tr('STR_LOAD_SAVED_GAME'));
  FOptions.SetText(Tr('STR_OPTIONS'));
  FOptions.OnMouseClick(OptionsClick);
  FMods.SetText(Tr('STR_MODS'));
  FQuit.SetText(Tr('STR_QUIT'));
  FQuit.OnMouseClick(QuitClick);
  FTitle.SetAlign(haCenter);
  FTitle.SetBig;
  FTitle.SetText(Tr('STR_OPENXCOM').Text + #2 + FVersionText);
end;

procedure TXcomMainMenuState.OptionsClick(AAction: TXcomAction);
begin
  // the options screens are the next slice
end;

procedure TXcomMainMenuState.QuitClick(AAction: TXcomAction);
begin
  Host.Quit;
end;

end.
