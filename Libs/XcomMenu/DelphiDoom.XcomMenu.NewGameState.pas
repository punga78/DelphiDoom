{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - NewGameState of OpenXcom (the choice of the  }
{  difficulty of a new game)                                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.NewGameState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types,
  DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.ToggleTextButton, DelphiDoom.XcomEngine.Session.Intf;

type
  /// <summary>
  ///   The window where the difficulty is chosen (five buttons of a group), with the ironman switch, OK and Cancel.
  ///   Cancel closes it; OK needs the new saved game and the geoscape, which are not ported, so it does nothing
  /// </summary>
  TXcomNewGameState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBeginner: TXcomTextButton;
    FExperienced: TXcomTextButton;
    FVeteran: TXcomTextButton;
    FGenius: TXcomTextButton;
    FSuperhuman: TXcomTextButton;
    FIronman: TXcomToggleTextButton;
    FOk: TXcomTextButton;
    FCancel: TXcomTextButton;
    FTitle: TXcomText;
    FIronmanText: TXcomText;
    FDifficulty: TXcomButtonGroup;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost);
    destructor Destroy; override;
    /// <summary>The selected difficulty, 0 (beginner) to 4 (superhuman)</summary>
    function Difficulty: Integer;
  end;

implementation

constructor TXcomNewGameState.Create(AHost: TXcomStateHost);
begin
  inherited Create(AHost);
  FDifficulty := TXcomButtonGroup.Create;
  FWindow := TXcomWindow.Create(Self, 192, 180, 64, 10, wpVertical);
  FBeginner := TXcomTextButton.Create(160, 18, 80, 32);
  FExperienced := TXcomTextButton.Create(160, 18, 80, 52);
  FVeteran := TXcomTextButton.Create(160, 18, 80, 72);
  FGenius := TXcomTextButton.Create(160, 18, 80, 92);
  FSuperhuman := TXcomTextButton.Create(160, 18, 80, 112);
  FIronman := TXcomToggleTextButton.Create(78, 18, 80, 138);
  FOk := TXcomTextButton.Create(78, 16, 80, 164);
  FCancel := TXcomTextButton.Create(78, 16, 162, 164);
  FTitle := TXcomText.Create(192, 9, 64, 20);
  FIronmanText := TXcomText.Create(90, 24, 162, 135);
  FDifficulty.Selected := FBeginner;
  SetInterface('newGameMenu');
  Add(FWindow, 'window', 'newGameMenu');
  Add(FBeginner, 'button', 'newGameMenu');
  Add(FExperienced, 'button', 'newGameMenu');
  Add(FVeteran, 'button', 'newGameMenu');
  Add(FGenius, 'button', 'newGameMenu');
  Add(FSuperhuman, 'button', 'newGameMenu');
  Add(FIronman, 'ironman', 'newGameMenu');
  Add(FOk, 'button', 'newGameMenu');
  Add(FCancel, 'button', 'newGameMenu');
  Add(FTitle, 'text', 'newGameMenu');
  Add(FIronmanText, 'ironman', 'newGameMenu');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBeginner.SetText(Tr('STR_1_BEGINNER'));
  FBeginner.SetGroup(FDifficulty);
  FExperienced.SetText(Tr('STR_2_EXPERIENCED'));
  FExperienced.SetGroup(FDifficulty);
  FVeteran.SetText(Tr('STR_3_VETERAN'));
  FVeteran.SetGroup(FDifficulty);
  FGenius.SetText(Tr('STR_4_GENIUS'));
  FGenius.SetGroup(FDifficulty);
  FSuperhuman.SetText(Tr('STR_5_SUPERHUMAN'));
  FSuperhuman.SetGroup(FDifficulty);
  FIronman.SetText(Tr('STR_IRONMAN'));
  FOk.SetText(Tr('STR_OK'));
  FOk.OnMouseClick(OkClick);
  FOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FCancel.SetText(Tr('STR_CANCEL'));
  FCancel.OnMouseClick(CancelClick);
  FCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTitle.SetAlign(haCenter);
  FTitle.SetText(Tr('STR_SELECT_DIFFICULTY_LEVEL'));
  FIronmanText.SetWordWrap(True);
  FIronmanText.SetVerticalAlign(vaMiddle);
  FIronmanText.SetText(Tr('STR_IRONMAN_DESC'));
end;

destructor TXcomNewGameState.Destroy;
begin
  // the buttons of the group are freed with the state, before the group they point to
  inherited Destroy;
  FDifficulty.Free;
end;

function TXcomNewGameState.Difficulty: Integer;
begin
  if FDifficulty.Selected = FExperienced then
    Result := 1
  else if FDifficulty.Selected = FVeteran then
    Result := 2
  else if FDifficulty.Selected = FGenius then
    Result := 3
  else if FDifficulty.Selected = FSuperhuman then
    Result := 4
  else
    Result := 0;
end;

procedure TXcomNewGameState.OkClick(AAction: TXcomAction);
var
  LStarter: IXcomNewGameStarter;
begin
  // NewGameState::btnOkClick: the saved game and the geoscape are made by the starter that the program gave the game
  LStarter := Host.NewGameStarter;
  if Assigned(LStarter) then
    LStarter.StartNewGame(Difficulty, FIronman.GetPressed);
end;

procedure TXcomNewGameState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
