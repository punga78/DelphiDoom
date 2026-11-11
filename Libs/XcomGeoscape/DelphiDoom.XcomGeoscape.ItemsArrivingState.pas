{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - ItemsArrivingState of OpenXcom (the      }
{  transfers that arrived)                                                      }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.ItemsArrivingState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomSave.Base, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   The list of the transfers that arrived (item, quantity, destination base). It only reads the transfers that
  ///   have no hours left: the simulation takes them off the bases (and uses the items that a craft can use) when the
  ///   popup has been made, as ItemsArrivingState does in its constructor
  /// </summary>
  TXcomItemsArrivingState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnGotoBase: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtItem: TXcomText;
    FTxtQuantity: TXcomText;
    FTxtDestination: TXcomText;
    FLstTransfers: TXcomTextList;
    procedure OkClick(AAction: TXcomAction);
    procedure GotoBaseClick(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl);
    property Transfers: TXcomTextList read FLstTransfers;
  end;

implementation

uses
  DelphiDoom.XcomSave.SavedGame, DelphiDoom.XcomSave.Transfer, DelphiDoom.XcomGeoscape.Strategy,
  DelphiDoom.XcomGeoscape.TargetNames;

{ TXcomItemsArrivingState }

constructor TXcomItemsArrivingState.Create(AHost: TXcomStateHost; const AControl: IXcomGeoscapeControl);
var
  LBase: TXcomBase;
  LTransfer: TXcomTransfer;
  LName: string;
  LQuantity: Integer;
begin
  inherited Create(AHost);
  FControl := AControl;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 184, 0, 8, wpBoth);
  FBtnOk := TXcomTextButton.Create(142, 16, 16, 166);
  FBtnGotoBase := TXcomTextButton.Create(142, 16, 162, 166);
  FTxtTitle := TXcomText.Create(310, 17, 5, 18);
  FTxtItem := TXcomText.Create(114, 9, 16, 34);
  FTxtQuantity := TXcomText.Create(54, 9, 152, 34);
  FTxtDestination := TXcomText.Create(112, 9, 212, 34);
  FLstTransfers := TXcomTextList.Create(Host.Options, Host.Clock, 271, 112, 14, 50);
  SetInterface('itemsArriving');
  Add(FWindow, 'window', 'itemsArriving');
  Add(FBtnOk, 'button', 'itemsArriving');
  Add(FBtnGotoBase, 'button', 'itemsArriving');
  Add(FTxtTitle, 'text1', 'itemsArriving');
  Add(FTxtItem, 'text1', 'itemsArriving');
  Add(FTxtQuantity, 'text1', 'itemsArriving');
  Add(FTxtDestination, 'text1', 'itemsArriving');
  Add(FLstTransfers, 'text2', 'itemsArriving');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FBtnGotoBase.SetText(Tr('STR_GO_TO_BASE'));
  FBtnGotoBase.OnMouseClick(GotoBaseClick);
  FBtnGotoBase.OnKeyboardPress(GotoBaseClick, Host.Options.KeyOk);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_ITEMS_ARRIVING'));
  FTxtItem.SetText(Tr('STR_ITEM'));
  FTxtQuantity.SetText(Tr('STR_QUANTITY_UC'));
  FTxtDestination.SetText(Tr('STR_DESTINATION_UC'));
  FLstTransfers.SetColumns([155, 41, 98]);
  FLstTransfers.SetSelectable(True);
  FLstTransfers.SetBackground(FWindow);
  FLstTransfers.SetMargin(2);
  for LBase in TXcomStrategy.SavedGame(AHost).Bases do
    for LTransfer in LBase.Transfers do
      if LTransfer.Hours = 0 then
      begin
        FBase := LBase;
        // Transfer::getName and getQuantity
        if Assigned(LTransfer.Soldier) then
        begin
          LName := LTransfer.Soldier.Name;
          LQuantity := 1;
        end
        else if Assigned(LTransfer.Craft) then
        begin
          LName := TXcomTargetNames.Name(LTransfer.Craft, Host.Language);
          LQuantity := 1;
        end
        else if LTransfer.Scientists <> 0 then
        begin
          LName := Tr('STR_SCIENTISTS').Text;
          LQuantity := LTransfer.Scientists;
        end
        else if LTransfer.Engineers <> 0 then
        begin
          LName := Tr('STR_ENGINEERS').Text;
          LQuantity := LTransfer.Engineers;
        end
        else
        begin
          LName := Tr(LTransfer.ItemId).Text;
          LQuantity := LTransfer.ItemQty;
        end;
        FLstTransfers.AddRow([LName, IntToStr(LQuantity), LBase.Name]);
      end;
end;

procedure TXcomItemsArrivingState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomItemsArrivingState.GotoBaseClick(AAction: TXcomAction);
begin
  FControl.TimerReset;
  Host.PopState;
  if Assigned(FBase) then
    FControl.OpenBase(FBase);
end;

end.
