{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - CannotReequipState of OpenXcom (the     }
{  items that the stores did not have to equip the craft again)                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.CannotReequipState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomDebriefing.Types;

type
  /// <summary>The list of the items and vehicles that the craft misses, with the quantity and the name of the craft</summary>
  TXcomCannotReequipState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtCraft: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="AMissingItems">The list of the report (the rows are made now: the list is not kept)</param>
    constructor Create(AHost: TXcomStateHost; const AMissingItems: TList<TXcomReequipStat>);
    property List: TXcomTextList read FList;
  end;

implementation

{ TXcomCannotReequipState }

constructor TXcomCannotReequipState.Create(AHost: TXcomStateHost; const AMissingItems: TList<TXcomReequipStat>);
var
  LStat: TXcomReequipStat;
begin
  inherited Create(AHost);
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnOk := TXcomTextButton.Create(120, 18, 100, 174);
  FTxtTitle := TXcomText.Create(220, 32, 50, 8);
  FTxtItem := TXcomText.Create(142, 9, 10, 50);
  FTxtQuantity := TXcomText.Create(88, 9, 152, 50);
  FTxtCraft := TXcomText.Create(74, 9, 218, 50);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 112, 8, 58);
  SetInterface('cannotReequip');
  Add(FWindow, 'window', 'cannotReequip');
  Add(FBtnOk, 'button', 'cannotReequip');
  Add(FTxtTitle, 'heading', 'cannotReequip');
  Add(FTxtItem, 'text', 'cannotReequip');
  Add(FTxtQuantity, 'text', 'cannotReequip');
  Add(FTxtCraft, 'text', 'cannotReequip');
  Add(FList, 'list', 'cannotReequip');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetText(Tr('STR_NOT_ENOUGH_EQUIPMENT_TO_FULLY_RE_EQUIP_SQUAD'));
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetBig;
  FTxtTitle.SetWordWrap(True);
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtCraft.SetText(Tr('STR_CRAFT'));
  FList.SetColumns([162, 46, 80]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(2);
  for LStat in AMissingItems do
    FList.AddRow([Tr(LStat.Item).Text, IntToStr(LStat.Quantity), LStat.CraftName]);
end;

procedure TXcomCannotReequipState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
