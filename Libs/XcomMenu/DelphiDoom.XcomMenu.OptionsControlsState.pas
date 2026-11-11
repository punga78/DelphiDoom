{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsControlsState of OpenXcom (the keys)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.OptionsControlsState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.OptionInfo, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf, DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The list of the keys of the game (general, geoscape and battlescape). A click selects a key (the row changes
  ///   color), the next key pressed becomes its value; the right button clears it
  /// </summary>
  TXcomOptionsControlsState = class(TXcomOptionsBaseState)
  strict private
    FList: TXcomTextList;
    FControlsGeneral: TList<TXcomOptionInfo>;
    FControlsGeo: TList<TXcomOptionInfo>;
    FControlsBattle: TList<TXcomOptionInfo>;
    FSelected: Integer;
    FSelectedKey: string;
    FColorGroup: Byte;
    FColorSelected: Byte;
    FColorNormal: Byte;
    procedure AddControls(AKeys: TList<TXcomOptionInfo>);
    /// <summary>The key option of a row, or an empty id when the row is a heading or a blank</summary>
    function ControlOf(ARow: Integer): string;
    procedure ListClick(AAction: TXcomAction);
    procedure ListKeyPress(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
    destructor Destroy; override;
    procedure Init; override;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomEngine.OptionTable, DelphiDoom.XcomEngine.KeyNames;

constructor TXcomOptionsControlsState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LInfo: TXcomOptionInfo;
  LInterface: string;
begin
  inherited Create(AHost, AOrigin, ANavigator);
  FControlsGeneral := TList<TXcomOptionInfo>.Create;
  FControlsGeo := TList<TXcomOptionInfo>.Create;
  FControlsBattle := TList<TXcomOptionInfo>.Create;
  FSelected := -1;
  SetCategory(FBtnControls);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 200, 136, 94, 8);
  if AOrigin <> ooBattlescape then
    LInterface := 'controlsMenu'
  else
    LInterface := 'battlescape';
  Add(FList, 'optionLists', LInterface);
  CenterAllSurfaces;
  FList.SetColumns([152, 48]);
  FList.SetWordWrap(True);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.OnMouseClick(ListClick, 0);
  FList.OnKeyboardPress(ListKeyPress);
  FList.SetFocus(True);
  FList.Tooltip := 'STR_CONTROLS_DESC';
  FList.OnMouseIn(TooltipIn);
  FList.OnMouseOut(TooltipOut);
  FColorGroup := FList.GetSecondaryColor;
  FColorSelected := FList.GetScrollbarColor;
  FColorNormal := FList.GetColor;
  for LInfo in TXcomOptionTable.All do
    if (LInfo.Kind = okKey) and (LInfo.Description <> '') then
    begin
      if LInfo.Category = 'STR_GENERAL' then
        FControlsGeneral.Add(LInfo)
      else if LInfo.Category = 'STR_GEOSCAPE' then
        FControlsGeo.Add(LInfo)
      else if LInfo.Category = 'STR_BATTLESCAPE' then
        FControlsBattle.Add(LInfo);
    end;
end;

destructor TXcomOptionsControlsState.Destroy;
begin
  inherited Destroy;
  FControlsBattle.Free;
  FControlsGeo.Free;
  FControlsGeneral.Free;
end;

procedure TXcomOptionsControlsState.Init;
begin
  inherited Init;
  FList.ClearList;
  FList.AddRow([Tr('STR_GENERAL').Text, '']);
  FList.SetCellColor(0, 0, FColorGroup);
  AddControls(FControlsGeneral);
  FList.AddRow(['', '']);
  FList.AddRow([Tr('STR_GEOSCAPE').Text, '']);
  FList.SetCellColor(FControlsGeneral.Count + 2, 0, FColorGroup);
  AddControls(FControlsGeo);
  FList.AddRow(['', '']);
  FList.AddRow([Tr('STR_BATTLESCAPE').Text, '']);
  FList.SetCellColor(FControlsGeneral.Count + 2 + FControlsGeo.Count + 2, 0, FColorGroup);
  AddControls(FControlsBattle);
end;

procedure TXcomOptionsControlsState.AddControls(AKeys: TList<TXcomOptionInfo>);
var
  LInfo: TXcomOptionInfo;
begin
  for LInfo in AKeys do
    FList.AddRow([Tr(LInfo.Description).Text, TXcomKeyNames.Display(Host.Options.GetValue(LInfo.Id))]);
end;

function TXcomOptionsControlsState.ControlOf(ARow: Integer): string;
begin
  Result := '';
  if (ARow > 0) and (ARow <= FControlsGeneral.Count) then
    Result := FControlsGeneral[ARow - 1].Id
  else if (ARow > FControlsGeneral.Count + 2) and (ARow <= FControlsGeneral.Count + 2 + FControlsGeo.Count) then
    Result := FControlsGeo[ARow - 1 - FControlsGeneral.Count - 2].Id
  else if (ARow > FControlsGeneral.Count + 2 + FControlsGeo.Count + 2) and
    (ARow <= FControlsGeneral.Count + 2 + FControlsGeo.Count + 2 + FControlsBattle.Count) then
    Result := FControlsBattle[ARow - 1 - FControlsGeneral.Count - 2 - FControlsGeo.Count - 2].Id;
end;

procedure TXcomOptionsControlsState.ListClick(AAction: TXcomAction);
var
  LButton: Integer;
  LSelected: Integer;
begin
  LButton := AAction.Details^.Button;
  if (LButton <> XCOM_BUTTON_LEFT) and (LButton <> XCOM_BUTTON_RIGHT) then
    Exit;
  if FSelected <> -1 then
  begin
    LSelected := FSelected;
    FList.SetCellColor(FSelected, 0, FColorNormal);
    FList.SetCellColor(FSelected, 1, FColorNormal);
    FSelected := -1;
    FSelectedKey := '';
    if LSelected = FList.GetSelectedRow then
      Exit;
  end;
  FSelected := FList.GetSelectedRow;
  FSelectedKey := ControlOf(FSelected);
  if FSelectedKey = '' then
  begin
    FSelected := -1;
    Exit;
  end;
  if LButton = XCOM_BUTTON_LEFT then
  begin
    FList.SetCellColor(FSelected, 0, FColorSelected);
    FList.SetCellColor(FSelected, 1, FColorSelected);
  end
  else
  begin
    FList.SetCellText(FSelected, 1, '');
    Host.Options.SetValue(FSelectedKey, XCOM_KEY_UNKNOWN);
    FSelected := -1;
    FSelectedKey := '';
  end;
end;

procedure TXcomOptionsControlsState.ListKeyPress(AAction: TXcomAction);
var
  LKey: Integer;
begin
  if FSelected = -1 then
    Exit;
  LKey := AAction.Details^.Key;
  if LKey <> 0 then
  begin
    Host.Options.SetValue(FSelectedKey, LKey);
    FList.SetCellText(FSelected, 1, TXcomKeyNames.UpperWords(TXcomKeyNames.Name(LKey)));
  end;
  FList.SetCellColor(FSelected, 0, FColorNormal);
  FList.SetCellColor(FSelected, 1, FColorNormal);
  FSelected := -1;
  FSelectedKey := '';
end;

end.