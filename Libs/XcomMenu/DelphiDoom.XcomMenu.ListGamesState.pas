{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ListGamesState of OpenXcom (the list of the saved games)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.ListGamesState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.SaveInfo, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextList, DelphiDoom.XcomUi.ArrowButton,
  DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   The window of the saved games, the base of the Load screen: the title, the list (name, date, time) sorted by
  ///   name or by date (the arrows beside the headings), the details of the row under the mouse, Cancel, and the
  ///   right button on a row to delete it. The saves come from the save catalog of the host; with no catalog the list
  ///   is empty. The quick save and the autosaves come first, in the color of the headings
  /// </summary>
  TXcomListGamesState = class(TXcomState)
  strict private
    FFirstValidRow: Integer;
    FAutoQuick: Boolean;
    FSortable: Boolean;
    FTxtDelete: TXcomText;
    FTxtName: TXcomText;
    FTxtDate: TXcomText;
    FTxtDetails: TXcomText;
    FSortName: TXcomArrowButton;
    FSortDate: TXcomArrowButton;
    procedure UpdateArrows;
    procedure SortNameClick(AAction: TXcomAction);
    procedure SortDateClick(AAction: TXcomAction);
    procedure ListMouseOver(AAction: TXcomAction);
    procedure ListMouseOut(AAction: TXcomAction);
    procedure ListPress(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  protected
    FOrigin: TXcomOptionsOrigin;
    FSaves: TArray<TXcomSaveInfo>;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FList: TXcomTextList;
    /// <summary>The rows of the list: ListSaveState adds the "new saved game" slot first</summary>
    procedure UpdateList; virtual;
    /// <summary>lstSavesPress of the derived screens: called for every press on the list, after the delete check</summary>
    procedure SavePress(AAction: TXcomAction); virtual;
    procedure DisableSort;
    procedure SortList(AOrder: Integer);
    property FirstValidRow: Integer read FFirstValidRow;
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; AFirstValidRow: Integer;
      AAutoQuick: Boolean);
    procedure Init; override;
    property List: TXcomTextList read FList;
    /// <summary>The arrows of the headings Name and Date that change the order</summary>
    property SortNameButton: TXcomArrowButton read FSortName;
    property SortDateButton: TXcomArrowButton read FSortDate;
    property Saves: TArray<TXcomSaveInfo> read FSaves;
  end;

implementation

uses
  DelphiDoom.XcomMenu.DeleteGameState;

const
  SORT_NAME_ASC = 0;
  SORT_NAME_DESC = 1;
  SORT_DATE_ASC = 2;
  SORT_DATE_DESC = 3;

constructor TXcomListGamesState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; AFirstValidRow: Integer;
  AAutoQuick: Boolean);
begin
  inherited Create(AHost);
  FOrigin := AOrigin;
  FFirstValidRow := AFirstValidRow;
  FAutoQuick := AAutoQuick;
  FSortable := True;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 320, 200, 0, 0, wpBoth);
  FBtnCancel := TXcomTextButton.Create(80, 16, 120, 172);
  FTxtTitle := TXcomText.Create(310, 17, 5, 7);
  FTxtDelete := TXcomText.Create(310, 9, 5, 23);
  FTxtName := TXcomText.Create(150, 9, 16, 32);
  FTxtDate := TXcomText.Create(110, 9, 204, 32);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 288, 112, 8, 42);
  FTxtDetails := TXcomText.Create(288, 16, 16, 156);
  FSortName := TXcomArrowButton.Create(Host.Clock, arNone, 11, 8, 16, 32);
  FSortDate := TXcomArrowButton.Create(Host.Clock, arNone, 11, 8, 204, 32);
  SetInterface('geoscape', True);
  Add(FWindow, 'window', 'saveMenus');
  Add(FBtnCancel, 'button', 'saveMenus');
  Add(FTxtTitle, 'text', 'saveMenus');
  Add(FTxtDelete, 'text', 'saveMenus');
  Add(FTxtName, 'text', 'saveMenus');
  Add(FTxtDate, 'text', 'saveMenus');
  Add(FList, 'list', 'saveMenus');
  Add(FTxtDetails, 'text', 'saveMenus');
  Add(FSortName, 'text', 'saveMenus');
  Add(FSortDate, 'text', 'saveMenus');
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(haCenter);
  FTxtDelete.SetAlign(haCenter);
  FTxtDelete.SetText(Tr('STR_RIGHT_CLICK_TO_DELETE'));
  FTxtName.SetText(Tr('STR_NAME'));
  FTxtDate.SetText(Tr('STR_DATE'));
  FList.SetColumns([188, 60, 40]);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.SetMargin(8);
  FList.OnMouseOver(ListMouseOver);
  FList.OnMouseOut(ListMouseOut);
  FList.OnMousePress(ListPress);
  FTxtDetails.SetWordWrap(True);
  FTxtDetails.SetText(Tr('STR_DETAILS').Arg(''));
  FSortName.X := FSortName.X + FTxtName.GetTextWidth + 5;
  FSortName.OnMouseClick(SortNameClick);
  FSortDate.X := FSortDate.X + FTxtDate.GetTextWidth + 5;
  FSortDate.OnMouseClick(SortDateClick);
  UpdateArrows;
end;

procedure TXcomListGamesState.Init;
begin
  inherited Init;
  if Host.SaveCatalog <> nil then
    FSaves := Host.SaveCatalog.List(Host.Language, FAutoQuick)
  else
    FSaves := nil;
  FList.ClearList;
  SortList(Host.Options.GetValue('saveOrder'));
end;

procedure TXcomListGamesState.UpdateArrows;
begin
  FSortName.SetShape(arNone);
  FSortDate.SetShape(arNone);
  case Host.Options.GetValue('saveOrder') of
    SORT_NAME_ASC:
      FSortName.SetShape(arSmallUp);
    SORT_NAME_DESC:
      FSortName.SetShape(arSmallDown);
    SORT_DATE_ASC:
      FSortDate.SetShape(arSmallUp);
    SORT_DATE_DESC:
      FSortDate.SetShape(arSmallDown);
  end;
end;

procedure TXcomListGamesState.SortList(AOrder: Integer);
var
  LIndex: Integer;
  LInner: Integer;
  LItem: TXcomSaveInfo;

  // A goes before B: the reserved slots first, then by the key of the order (a stable insertion sort)
  function Before(const A, B: TXcomSaveInfo): Boolean;
  begin
    if A.Reserved <> B.Reserved then
      Exit(A.Reserved);
    case AOrder of
      SORT_NAME_ASC:
        Result := Host.SaveCatalog.NameBefore(A.DisplayName, B.DisplayName);
      SORT_NAME_DESC:
        Result := Host.SaveCatalog.NameBefore(B.DisplayName, A.DisplayName);
      SORT_DATE_ASC:
        Result := A.Timestamp < B.Timestamp;
      SORT_DATE_DESC:
        Result := A.Timestamp > B.Timestamp;
    else
      Result := False;
    end;
  end;

begin
  if (Host.SaveCatalog <> nil) and (Length(FSaves) > 1) then
    for LIndex := 1 to High(FSaves) do
    begin
      LItem := FSaves[LIndex];
      LInner := LIndex - 1;
      while (LInner >= 0) and Before(LItem, FSaves[LInner]) do
      begin
        FSaves[LInner + 1] := FSaves[LInner];
        Dec(LInner);
      end;
      FSaves[LInner + 1] := LItem;
    end;
  UpdateList;
end;

procedure TXcomListGamesState.UpdateList;
var
  LRow: Integer;
begin
  for LRow := 0 to High(FSaves) do
  begin
    FList.AddRow([FSaves[LRow].DisplayName, FSaves[LRow].IsoDate, FSaves[LRow].IsoTime]);
    if FSaves[LRow].Reserved and (FOrigin <> ooBattlescape) then
      FList.SetRowColor(LRow, FList.GetSecondaryColor);
  end;
end;

procedure TXcomListGamesState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomListGamesState.ListMouseOver(AAction: TXcomAction);
var
  LSelected: Integer;
  LDetails: string;
begin
  LSelected := FList.GetSelectedRow - FFirstValidRow;
  LDetails := '';
  if (LSelected >= 0) and (LSelected < Length(FSaves)) then
    LDetails := FSaves[LSelected].Details;
  FTxtDetails.SetText(Tr('STR_DETAILS').Arg(LDetails));
end;

procedure TXcomListGamesState.ListMouseOut(AAction: TXcomAction);
begin
  FTxtDetails.SetText(Tr('STR_DETAILS').Arg(''));
end;

procedure TXcomListGamesState.ListPress(AAction: TXcomAction);
begin
  SavePress(AAction);
end;

procedure TXcomListGamesState.SavePress(AAction: TXcomAction);
begin
  if (AAction.Details^.Button = XCOM_BUTTON_RIGHT) and (FList.GetSelectedRow >= FFirstValidRow) and
    (FList.GetSelectedRow - FFirstValidRow < Length(FSaves)) then
    Host.PushState(TXcomDeleteGameState.Create(Host, FOrigin, FSaves[FList.GetSelectedRow - FFirstValidRow].FileName));
end;

procedure TXcomListGamesState.SortNameClick(AAction: TXcomAction);
begin
  if not FSortable then
    Exit;
  if Host.Options.GetValue('saveOrder') = SORT_NAME_ASC then
    Host.Options.SetValue('saveOrder', SORT_NAME_DESC)
  else
    Host.Options.SetValue('saveOrder', SORT_NAME_ASC);
  UpdateArrows;
  FList.ClearList;
  SortList(Host.Options.GetValue('saveOrder'));
end;

procedure TXcomListGamesState.SortDateClick(AAction: TXcomAction);
begin
  if not FSortable then
    Exit;
  if Host.Options.GetValue('saveOrder') = SORT_DATE_DESC then
    Host.Options.SetValue('saveOrder', SORT_DATE_ASC)
  else
    Host.Options.SetValue('saveOrder', SORT_DATE_DESC);
  UpdateArrows;
  FList.ClearList;
  SortList(Host.Options.GetValue('saveOrder'));
end;

procedure TXcomListGamesState.DisableSort;
begin
  FSortable := False;
end;

end.