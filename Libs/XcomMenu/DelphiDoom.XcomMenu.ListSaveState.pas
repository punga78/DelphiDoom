{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ListSaveState of OpenXcom (the Save Game      }
{  screen)                                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.ListSaveState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomMenu.OptionsTypes,
  DelphiDoom.XcomMenu.ListGamesState;

type
  /// <summary>
  ///   The saved games to write over, with a first row for a new slot. A click on a row opens a text field on it to name
  ///   the save; Enter or the Save Game button writes it (the file of an existing slot is renamed when the name
  ///   changes, and a name already taken gets underscores): SaveGameState does the writing. In an ironman game
  ///   there is no Cancel
  /// </summary>
  TXcomListSaveState = class(TXcomListGamesState)
  strict private
    FEdtSave: TXcomTextEdit;
    FBtnSaveGame: TXcomTextButton;
    FPreviousSelectedRow: Integer;
    FSelectedRow: Integer;
    FSelected: string;
    procedure SaveGameClick(AAction: TXcomAction);
    procedure EditKeyPress(AAction: TXcomAction);
    procedure SaveGame;
  protected
    procedure UpdateList; override;
    procedure SavePress(AAction: TXcomAction); override;
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin);
    property Edit: TXcomTextEdit read FEdtSave;
    property SaveButton: TXcomTextButton read FBtnSaveGame;
  end;

implementation

uses
  DelphiDoom.XcomMenu.SaveNames, DelphiDoom.XcomMenu.SaveGameState;

constructor TXcomListSaveState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin);
var
  LIronman: Boolean;
begin
  inherited Create(AHost, AOrigin, 1, False);
  FPreviousSelectedRow := -1;
  FSelectedRow := -1;
  LIronman := (Host.SavedGameSaver <> nil) and Host.SavedGameSaver.IsIronman;
  FEdtSave := TXcomTextEdit.Create(Self, 168, 9, 0, 0);
  if LIronman then
    FBtnSaveGame := TXcomTextButton.Create(200, 16, 60, 172)
  else
    FBtnSaveGame := TXcomTextButton.Create(80, 16, 60, 172);
  Add(FEdtSave);
  Add(FBtnSaveGame, 'button', 'saveMenus');
  FTxtTitle.SetText(Tr('STR_SELECT_SAVE_POSITION'));
  if LIronman then
    FBtnCancel.Visible := False
  else
    FBtnCancel.X := 180;
  FBtnSaveGame.SetText(Tr('STR_SAVE_GAME'));
  FBtnSaveGame.OnMouseClick(SaveGameClick);
  FEdtSave.SetColor(FList.GetSecondaryColor);
  FEdtSave.Visible := False;
  FEdtSave.OnKeyboardPress(EditKeyPress);
  CenterAllSurfaces;
end;

procedure TXcomListSaveState.UpdateList;
begin
  FList.AddRow([Tr('STR_NEW_SAVED_GAME_SLOT').Text]);
  if FOrigin <> ooBattlescape then
    FList.SetRowColor(0, FList.GetSecondaryColor);
  inherited UpdateList;
end;

procedure TXcomListSaveState.SavePress(AAction: TXcomAction);
begin
  if (AAction.Details^.Button = XCOM_BUTTON_RIGHT) and FEdtSave.IsFocused then
  begin
    FEdtSave.SetText('');
    FEdtSave.Visible := False;
    FEdtSave.SetFocus(False, False);
    FList.SetScrolling(True);
  end;
  inherited SavePress(AAction);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FPreviousSelectedRow := FSelectedRow;
    FSelectedRow := FList.GetSelectedRow;
    case FPreviousSelectedRow of
      -1:
        ;
      0:
        FList.SetCellText(FPreviousSelectedRow, 0, Tr('STR_NEW_SAVED_GAME_SLOT').Text);
    else
      FList.SetCellText(FPreviousSelectedRow, 0, FSelected);
    end;
    FSelected := FList.GetCellText(FList.GetSelectedRow, 0);
    FList.SetCellText(FList.GetSelectedRow, 0, '');
    if FList.GetSelectedRow = 0 then
    begin
      FEdtSave.SetText('');
      FSelected := '';
    end
    else
      FEdtSave.SetText(FSelected);
    FEdtSave.X := FList.GetColumnX(0);
    FEdtSave.Y := FList.GetRowY(FSelectedRow);
    FEdtSave.Visible := True;
    FEdtSave.SetFocus(True, False);
    FList.SetScrolling(False);
    DisableSort;
  end;
end;

procedure TXcomListSaveState.EditKeyPress(AAction: TXcomAction);
begin
  if (AAction.Details^.Key = XCOM_KEY_RETURN) or (AAction.Details^.Key = XCOM_KEY_KP_ENTER) then
    SaveGame;
end;

procedure TXcomListSaveState.SaveGameClick(AAction: TXcomAction);
begin
  if FSelectedRow <> -1 then
    SaveGame;
end;

procedure TXcomListSaveState.SaveGame;
var
  LNewName, LOldName: string;

  procedure MakeUnique;
  begin
    while (Host.SaveCatalog <> nil) and Host.SaveCatalog.SaveExists(LNewName + '.sav') do
      LNewName := LNewName + '_';
  end;

begin
  if Host.SavedGameSaver <> nil then
    Host.SavedGameSaver.SetName(FEdtSave.GetText);
  LNewName := TXcomSaveNames.Sanitize(FEdtSave.GetText);
  if FSelectedRow > 0 then
  begin
    LOldName := FSaves[FSelectedRow - 1].FileName;
    if LOldName <> LNewName + '.sav' then
    begin
      MakeUnique;
      if Host.SaveCatalog <> nil then
        Host.SaveCatalog.RenameSave(LOldName, LNewName + '.sav');
    end;
  end
  else
    MakeUnique;
  Host.PushState(TXcomSaveGameState.Create(Host, FOrigin, LNewName + '.sav', Palette));
end;

end.
