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
  DelphiDoom.XcomMenu.OptionsBaseState, DelphiDoom.XcomEngine.ExtraChoiceOptions.Intf;

type
  /// <summary>
  ///   The list of the settings that are not keys and have a description (general, geoscape, battlescape): a click
  ///   toggles a yes/no or raises a number by one (the right button lowers it, the wheel of the speeds by ten); a
  ///   number that goes over its range wraps around. The tooltip is the description of the row under the mouse
  ///   When the host has settings of its own (IXcomExtraOptions) they follow in a last section; without, the
  ///   list is the one of OpenXcom
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
    function ExtraRows: Integer;
    function ExtraOf(ARow: Integer; out AIndex: Integer): Boolean;
    function ExtraKind(AIndex: Integer): TXcomExtraKind;
    function ExtraValue(AIndex: Integer): string;
    procedure RefreshExtra(ARow: Integer; AIndex: Integer);
    function YesNo(AValue: Boolean): string;
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
var
  LFirst: Integer;
  LIndex: Integer;
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
  // the settings OpenXcom does not have, after its own
  if ExtraRows > 0 then
  begin
    FList.AddRow(['', '']);
    FList.AddRow([Host.ExtraOptions.Heading, '']);
    LFirst := FSettingsGeneral.Count + 2 + FSettingsGeo.Count + 2 + FSettingsBattle.Count + 2;
    FList.SetCellColor(LFirst, 0, FColorGroup);
    for LIndex := 0 to ExtraRows - 1 do
      FList.AddRow([Host.ExtraOptions.Title(LIndex), ExtraValue(LIndex)]);
  end;
end;

function TXcomOptionsAdvancedState.ExtraKind(AIndex: Integer): TXcomExtraKind;
var
  LChoices: IXcomExtraChoiceOptions;
begin
  // a host that only knows yes/no rows has toggles
  if Supports(Host.ExtraOptions, IXcomExtraChoiceOptions, LChoices) then
    Result := LChoices.Kind(AIndex)
  else
    Result := ekToggle;
end;

function TXcomOptionsAdvancedState.ExtraValue(AIndex: Integer): string;
begin
  // a choice has its value in the title: the YES/NO column is only for the toggles
  if ExtraKind(AIndex) = ekToggle then
    Result := YesNo(Host.ExtraOptions.IsOn(AIndex))
  else
    Result := '';
end;

procedure TXcomOptionsAdvancedState.RefreshExtra(ARow: Integer; AIndex: Integer);
var
  LIndex: Integer;
  LFirst: Integer;
begin
  // a change of one row can change the others (the font Original has no size)
  LFirst := ARow - AIndex;
  for LIndex := 0 to ExtraRows - 1 do
  begin
    FList.SetCellText(LFirst + LIndex, 0, Host.ExtraOptions.Title(LIndex));
    FList.SetCellText(LFirst + LIndex, 1, ExtraValue(LIndex));
  end;
end;

function TXcomOptionsAdvancedState.ExtraRows: Integer;
begin
  if Host.ExtraOptions <> nil then
    Result := Host.ExtraOptions.Count
  else
    Result := 0;
end;

function TXcomOptionsAdvancedState.ExtraOf(ARow: Integer; out AIndex: Integer): Boolean;
begin
  // after the last section: an empty row, the heading, then the rows
  AIndex := ARow - (FSettingsGeneral.Count + 2 + FSettingsGeo.Count + 2 + FSettingsBattle.Count + 3);
  Result := (AIndex >= 0) and (AIndex < ExtraRows);
end;

function TXcomOptionsAdvancedState.YesNo(AValue: Boolean): string;
begin
  if AValue then
    Result := Tr('STR_YES').Text
  else
    Result := Tr('STR_NO').Text;
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
  LExtra: Integer;
begin
  LButton := AAction.Details^.Button;
  if (LButton <> XCOM_BUTTON_LEFT) and (LButton <> XCOM_BUTTON_RIGHT) then
    Exit;
  LRow := FList.GetSelectedRow;
  if ExtraOf(LRow, LExtra) then
  begin
    case ExtraKind(LExtra) of
      ekToggle:
        Host.ExtraOptions.SetOn(LExtra, not Host.ExtraOptions.IsOn(LExtra));
      ekChoice:
        // left button: the next one, right button: the previous one
        if LButton = XCOM_BUTTON_LEFT then
          (Host.ExtraOptions as IXcomExtraChoiceOptions).Step(LExtra, 1)
        else
          (Host.ExtraOptions as IXcomExtraChoiceOptions).Step(LExtra, -1);
    end;
    RefreshExtra(LRow, LExtra);
    Exit;
  end;
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
  LExtra: Integer;
begin
  LDescription := '';
  if SettingOf(FList.GetSelectedRow, LInfo) then
    LDescription := Tr(LInfo.Description + '_DESC').Text
  else if ExtraOf(FList.GetSelectedRow, LExtra) then
    LDescription := Host.ExtraOptions.Description(LExtra);
  FTxtTooltip.SetText(LDescription);
end;

procedure TXcomOptionsAdvancedState.ListMouseOut(AAction: TXcomAction);
begin
  FTxtTooltip.SetText('');
end;

end.