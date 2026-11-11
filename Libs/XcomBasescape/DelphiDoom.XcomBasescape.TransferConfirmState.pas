{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - TransferConfirmState of OpenXcom (the   }
{  cost of the transfer, to confirm)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.TransferConfirmState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Base;

type
  /// <summary>What the transfer to a base costs, with OK and Cancel (a small window over the list)</summary>
  TXcomTransferConfirmState = class(TXcomState)
  strict private
    FCompleteTransfer: TProc;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FBtnOk: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtCost: TXcomText;
    FTxtTotal: TXcomText;
    procedure CancelClick(AAction: TXcomAction);
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The destination base (not owned)</param>
    /// <param name="ATotal">The cost of the transfer</param>
    /// <param name="ACompleteTransfer">Does the transfer (TransferItemsState::completeTransfer); the three screens close after it</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ATotal: Int64; const ACompleteTransfer: TProc);
  end;

implementation

uses
  DelphiDoom.XcomBasescape.Funding;

{ TXcomTransferConfirmState }

constructor TXcomTransferConfirmState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ATotal: Int64;
  const ACompleteTransfer: TProc);
begin
  inherited Create(AHost);
  FCompleteTransfer := ACompleteTransfer;
  // _screen = false: the list stays visible around the window
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 80, 0, 60);
  FBtnCancel := TXcomTextButton.Create(128, 16, 176, 115);
  FBtnOk := TXcomTextButton.Create(128, 16, 16, 115);
  FTxtTitle := TXcomText.Create(310, 17, 5, 75);
  FTxtCost := TXcomText.Create(60, 17, 110, 95);
  FTxtTotal := TXcomText.Create(100, 17, 170, 95);
  SetInterface('transferConfirm');
  Add(FWindow, 'window', 'transferConfirm');
  Add(FBtnCancel, 'button', 'transferConfirm');
  Add(FBtnOk, 'button', 'transferConfirm');
  Add(FTxtTitle, 'text', 'transferConfirm');
  Add(FTxtCost, 'text', 'transferConfirm');
  Add(FTxtTotal, 'text', 'transferConfirm');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_TRANSFER_ITEMS_TO').Arg(ABase.Name));
  FTxtCost.SetBig;
  FTxtCost.SetText(Tr('STR_COST'));
  FTxtTotal.SetBig;
  FTxtTotal.SetText(Chr(XCOM_TOKEN_COLOR_FLIP) + TXcomFunding.Format(ATotal));
end;

procedure TXcomTransferConfirmState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomTransferConfirmState.OkClick(AAction: TXcomAction);
begin
  FCompleteTransfer();
  Host.PopState;
  Host.PopState;
  Host.PopState;
end;

end.
