{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - TransfersState of OpenXcom (what is on  }
{  its way to a base)                                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.TransfersState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base;

type
  /// <summary>The transfers of a base: name, quantity and hours to the arrival</summary>
  TXcomTransfersState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtArrivalTime: TXcomText;
    FList: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase);
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomSave.BaseCapacity, DelphiDoom.XcomBasescape.Names;

{ TXcomTransfersState }

constructor TXcomTransfersState.Create(AHost: TXcomStateHost; ABase: TXcomBase);
var
  LTransfer: TXcomTransfer;
begin
  inherited Create(AHost);
  // _screen = false: the base information stays visible around the window
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 184, 0, 8, wpBoth);
  FBtnOk := TXcomTextButton.Create(288, 16, 16, 166);
  FTxtTitle := TXcomText.Create(278, 17, 21, 18);
  FTxtItem := TXcomText.Create(114, 9, 16, 34);
  FTxtQuantity := TXcomText.Create(54, 9, 152, 34);
  FTxtArrivalTime := TXcomText.Create(112, 9, 212, 34);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 273, 112, 14, 50);
  SetInterface('transferInfo');
  Add(FWindow, 'window', 'transferInfo');
  Add(FBtnOk, 'button', 'transferInfo');
  Add(FTxtTitle, 'text', 'transferInfo');
  Add(FTxtItem, 'text', 'transferInfo');
  Add(FTxtQuantity, 'text', 'transferInfo');
  Add(FTxtArrivalTime, 'text', 'transferInfo');
  Add(FList, 'list', 'transferInfo');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_TRANSFERS'));
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtArrivalTime.SetText(Tr('STR_ARRIVAL_TIME_HOURS'));
  FList.SetColumns([155, 75, 46]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(2);
  for LTransfer in ABase.Transfers do
    FList.AddRow([TXcomBaseNames.TransferName(LTransfer, Host.Language),
      IntToStr(TXcomBaseCapacity.QuantityOf(LTransfer)), IntToStr(LTransfer.Hours)]);
end;

procedure TXcomTransfersState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
