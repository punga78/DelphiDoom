{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - PromotionsState of OpenXcom (the       }
{  soldiers that were promoted after the mission)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.PromotionsState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.SavedGame;

type
  /// <summary>
  ///   The soldiers of every base that were just promoted: name, new rank and base. Asking a soldier whether it was
  ///   promoted clears its mark (Soldier::isPromoted): the screen can be made once. The saved game is not owned and is
  ///   not kept after the constructor
  /// </summary>
  TXcomPromotionsState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtName: TXcomText;
    FTxtRank: TXcomText;
    FTxtBase: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; const ASavedGame: TXcomSavedGame);
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomBasescape.Names;

{ TXcomPromotionsState }

constructor TXcomPromotionsState.Create(AHost: TXcomStateHost; const ASavedGame: TXcomSavedGame);
var
  LBase: TXcomBase;
  LSoldier: TXcomSoldier;
begin
  inherited Create(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TXcomTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TXcomText.Create(300, 17, 10, 8);
  FTxtName := TXcomText.Create(114, 9, 16, 32);
  FTxtRank := TXcomText.Create(90, 9, 130, 32);
  FTxtBase := TXcomText.Create(80, 9, 220, 32);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 128, 8, 40);
  SetInterface('promotions');
  Add(FWindow, 'window', 'promotions');
  Add(FBtnOk, 'button', 'promotions');
  Add(FTxtTitle, 'heading', 'promotions');
  Add(FTxtName, 'text', 'promotions');
  Add(FTxtRank, 'text', 'promotions');
  Add(FTxtBase, 'text', 'promotions');
  Add(FList, 'list', 'promotions');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetText(Tr('STR_PROMOTIONS'));
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtName.SetText(Tr('STR_NAME'));
  FTxtRank.SetText(Tr('STR_NEW_RANK'));
  FTxtBase.SetText(Tr('STR_BASE'));
  FList.SetColumns([114, 90, 84]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  for LBase in ASavedGame.Bases do
    for LSoldier in LBase.Soldiers do
      if LSoldier.IsPromoted then
        FList.AddRow([LSoldier.Name, Tr(TXcomBaseNames.RankKey(LSoldier.Rank)).Text, LBase.Name]);
end;

procedure TXcomPromotionsState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
