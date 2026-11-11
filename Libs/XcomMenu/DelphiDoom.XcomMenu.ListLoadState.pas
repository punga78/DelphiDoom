{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ListLoadState of OpenXcom (the Load Game screen)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.ListLoadState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.ListGamesState;

type
  /// <summary>
  ///   The saved games to load (also the quick save and the autosaves). A click on a row starts LoadGameState. The
  ///   button of the original X-COM saves is there but opens nothing (ListLoadOriginalState is not ported), and so is
  ///   the confirmation that a save needs mods that are not active (ConfirmLoadState): the save is loaded anyway
  /// </summary>
  TXcomListLoadState = class(TXcomListGamesState)
  strict private
    FBtnOld: TXcomTextButton;
  protected
    procedure SavePress(AAction: TXcomAction); override;
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin);
  end;

implementation

uses
  DelphiDoom.XcomEngine.ModNames, DelphiDoom.XcomMenu.LoadGameState, DelphiDoom.XcomMenu.ConfirmLoadState;

constructor TXcomListLoadState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin);
begin
  inherited Create(AHost, AOrigin, 0, True);
  FBtnOld := TXcomTextButton.Create(80, 16, 60, 172);
  FBtnCancel.X := 180;
  Add(FBtnOld, 'button', 'saveMenus');
  FTxtTitle.SetText(Tr('STR_SELECT_GAME_TO_LOAD'));
  FBtnOld.SetText(Tr('STR_ORIGINAL_XCOM'));
  CenterAllSurfaces;
end;

procedure TXcomListLoadState.SavePress(AAction: TXcomAction);
var
  LRow: Integer;
  LMod: string;
  LConfirm: Boolean;
begin
  inherited SavePress(AAction);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    LRow := FList.GetSelectedRow;
    if (LRow >= 0) and (LRow < Length(FSaves)) then
    begin
      // a save that lists a mod that is not in the active ones asks first (the missing content prompt)
      LConfirm := False;
      for LMod in FSaves[LRow].Mods do
        if not Host.Options.IsModActive(TXcomModNames.Sanitize(LMod)) then
        begin
          LConfirm := True;
          Break;
        end;
      if LConfirm then
        Host.PushState(TXcomConfirmLoadState.Create(Host, FOrigin, FSaves[LRow].FileName))
      else
        Host.PushState(TXcomLoadGameState.Create(Host, FOrigin, FSaves[LRow].FileName, Palette));
    end;
  end;
end;

end.