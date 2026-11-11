{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - OptionsAdvancedState of OpenXcom (the settings of the game)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.OptionsAdvancedState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.OptionInfo, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextList, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf,
  DelphiDoom.XcomMenu.OptionsBaseState;

type
  /// <summary>
  ///   The list of the settings that are not keys and have a description (general, geoscape, battlescape): a click
  ///   toggles a yes/no or raises a number by one (the right button lowers it, the wheel of the speeds by ten); a
  ///   number that goes over its range wraps around. The tooltip is the description of the row under the mouse
  /// </summary>
  TXcomOptionsAdvancedState = class(TXcomOptionsBaseState)
  strict private
    FList: TXcomTextList;
    FSettingsGeneral: TList<TXcomOptionInfo>;
    FSettingsGeo: TList<TXcomOptionInfo>;
    FSettingsBattle: TList<TXcomOptionInfo>;
    FColorGroup: Byte;
    procedure AddSettings(ASettings: TList<TXcomOptionInfo>);
    function SettingOf(ARow: Integer; out AInfo: TXcomOptionInfo): Boolean;
    procedure ListClick(AAction: TXcomAction);
    procedure ListMouseOver(AAction: TXcomAction);
    procedure ListMouseOut(AAction: TXcomAction);
  public
    constructor Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const ANavigator: IXcomOptionsNavigator);
    destructor Destroy; override;
    procedure Init; override;
    property List: TXcomTextList read FList;
  end;

implementation

uses
  DelphiDoom.XcomEngine.OptionTable;

constructor TXcomOptionsAdvancedState.Create(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const ANavigator: IXcomOptionsNavigator);
var
  LInfo: TXcomOptionInfo;
  LInterface: string;
  LMeasure: TXcomText;
  LYes: Integer;
  LNo: Integer;
  LRightColumn: Integer;
begin
  inherited Create(AHost, AOrigin, ANavigator);
  FSettingsGeneral := TList<TXcomOptionInfo>.Create;
  FSettingsGeo := TList<TXcomOptionInfo>.Create;
  FSettingsBattle := TList<TXcomOptionInfo>.Create;
  SetCategory(FBtnAdvanced);
  FList := TXcomTextList.Create(Host.Options, Host.Clock, 200, 136, 94, 8);
  if AOrigin <> ooBattlescape then
    LInterface := 'advancedMenu'
  else
    LInterface := 'battlescape';
  Add(FList, 'optionLists', LInterface);
  CenterAllSurfaces;
  // how much room is needed for YES and NO
  LMeasure := TXcomText.Create(100, 9, 0, 0);
  try
    LMeasure.InitText(Host.Resources.GetFont('FONT_BIG'), Host.Resources.GetFont('FONT_SMALL'), Host.Language);
    LMeasure.SetText(Tr('STR_YES'));
    LYes := LMeasure.GetTextWidth;
    LMeasure.SetText(Tr('STR_NO'));
    LNo := LMeasure.GetTextWidth;
  finally
    LMeasure.Free;
  end;
  if LYes > LNo then
    LRightColumn := LYes + 2
  else
    LRightColumn := LNo + 2;
  FList.SetAlign(haRight, 1);
  FList.SetColumns([FList.Width - LRightColumn, LRightColumn]);
  FList.SetWordWrap(True);
  FList.SetSelectable(True);
  FList.SetBackground(FWindow);
  FList.OnMouseClick(ListClick, 0);
  FList.OnMouseOver(ListMouseOver);
  FList.OnMouseOut(ListMouseOut);
  FColorGroup := FList.GetSecondaryColor;
  for LInfo in TXcomOptionTable.All do
    if (LInfo.Kind <> okKey) and (LInfo.Description <> '') then
    begin
      if LInfo.Category = 'STR_GENERAL' then
        FSettingsGeneral.Add(LInfo)
      else if LInfo.Category = 'STR_GEOSCAPE' then
        FSettingsGeo.Add(LInfo)
      else if LInfo.Category = 'STR_BATTLESCAPE' then
        FSettingsBattle.Add(LInfo);
    end;
end;

destructor TXcomOptionsAdvancedState.Destroy;
begin
  inherited Destroy;
  FSettingsBattle.Free;
  FSettingsGeo.Free;
  FSettingsGeneral.Free;
end;

procedure TXcomOptionsAdvancedState.Init;
begin
  inherited Init;
  FList.ClearList;
  FList.AddRow([Tr('STR_GENERAL').Text, '']);
  FList.SetCellColor(0, 0, FColorGroup);
  AddSettings(FSettingsGeneral);
  FList.AddRow(['', '']);
  FList.AddRow([Tr('STR_GEOSCAPE').Text, '']);
  FList.SetCellColor(FSettingsGeneral.Count + 2, 0, FColorGroup);
  AddSettings(FSettingsGeo);
  FList.AddRow(['', '']);
  FList.AddRow([Tr('STR_BATTLESCAPE').Text, '']);
  FList.SetCellColor(FSettingsGeneral.Count + 2 + FSettingsGeo.Count + 2, 0, FColorGroup);
  AddSettings(FSettingsBattle);
end;

procedure TXcomOptionsAdvancedState.AddSettings(ASettings: TList<TXcomOptionInfo>);
var
  LInfo: TXcomOptionInfo;
  LValue: string;
begin
  for LInfo in ASettings do
  begin
    LValue := '';
    if LInfo.Kind = okBool then
    begin
      if Host.Options.GetBool(LInfo.Id) then
        LValue := Tr('STR_YES').Text
      else
        LValue := Tr('STR_NO').Text;
    end
    else if LInfo.Kind = okInt then
      LValue := IntToStr(Host.Options.GetValue(LInfo.Id));
    FList.AddRow([Tr(LInfo.Description).Text, LValue]);
  end;
end;

function TXcomOptionsAdvancedState.SettingOf(ARow: Integer; out AInfo: TXcomOptionInfo): Boolean;
begin
  Result := True;
  if (ARow > 0) and (ARow <= FSettingsGeneral.Count) then
    AInfo := FSettingsGeneral[ARow - 1]
  else if (ARow > FSettingsGeneral.Count + 2) and (ARow <= FSettingsGeneral.Count + 2 + FSettingsGeo.Count) then
    AInfo := FSettingsGeo[ARow - 1 - FSettingsGeneral.Count - 2]
  else if (ARow > FSettingsGeneral.Count + 2 + FSettingsGeo.Count + 2) and
    (ARow <= FSettingsGeneral.Count + 2 + FSettingsGeo.Count + 2 + FSettingsBattle.Count) then
    AInfo := FSettingsBattle[ARow - 1 - FSettingsGeneral.Count - 2 - FSettingsGeo.Count - 2]
  else
    Result := False;
end;

procedure TXcomOptionsAdvancedState.ListClick(AAction: TXcomAction);
var
  LButton: Integer;
  LRow: Integer;
  LInfo: TXcomOptionInfo;
  LText: string;
  LValue: Integer;
  LIncrement: Integer;
  LMin: Integer;
  LMax: Integer;
begin
  LButton := AAction.Details^.Button;
  if (LButton <> XCOM_BUTTON_LEFT) and (LButton <> XCOM_BUTTON_RIGHT) then
    Exit;
  LRow := FList.GetSelectedRow;
  if not SettingOf(LRow, LInfo) then
    Exit;
  LText := '';
  if LInfo.Kind = okBool then
  begin
    Host.Options.SetBool(LInfo.Id, not Host.Options.GetBool(LInfo.Id));
    if Host.Options.GetBool(LInfo.Id) then
      LText := Tr('STR_YES').Text
    else
      LText := Tr('STR_NO').Text;
  end
  else if LInfo.Kind = okInt then
  begin
    // left click raises, right click lowers
    if LButton = XCOM_BUTTON_LEFT then
      LIncrement := 1
    else
      LIncrement := -1;
    if (LInfo.Id = 'changeValueByMouseWheel') or (LInfo.Id = 'FPS') or (LInfo.Id = 'FPSInactive') then
      LIncrement := LIncrement * 10;
    LValue := Host.Options.GetValue(LInfo.Id) + LIncrement;
    LMin := 0;
    LMax := 0;
    if LInfo.Id = 'battleExplosionHeight' then
      LMax := 3
    else if LInfo.Id = 'changeValueByMouseWheel' then
      LMax := 50
    else if LInfo.Id = 'FPS' then
      LMax := 120
    else if LInfo.Id = 'FPSInactive' then
    begin
      LMin := 10;
      LMax := 120;
    end
    else if LInfo.Id = 'mousewheelSpeed' then
    begin
      LMin := 1;
      LMax := 7;
    end
    else if LInfo.Id = 'autosaveFrequency' then
    begin
      LMin := 1;
      LMax := 5;
    end;
    if LValue < LMin then
      LValue := LMax
    else if LValue > LMax then
      LValue := LMin;
    Host.Options.SetValue(LInfo.Id, LValue);
    LText := IntToStr(LValue);
  end;
  FList.SetCellText(LRow, 1, LText);
end;

procedure TXcomOptionsAdvancedState.ListMouseOver(AAction: TXcomAction);
var
  LInfo: TXcomOptionInfo;
  LDescription: string;
begin
  LDescription := '';
  if SettingOf(FList.GetSelectedRow, LInfo) then
    LDescription := Tr(LInfo.Description + '_DESC').Text;
  FTxtTooltip.SetText(LDescription);
end;

procedure TXcomOptionsAdvancedState.ListMouseOut(AAction: TXcomAction);
begin
  FTxtTooltip.SetText('');
end;

end.