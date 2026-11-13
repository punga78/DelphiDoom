{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - reading an itemDef                                }
{                                                                              }
{  Port of Item_Parse, the table itemParseKeywords and every ItemParse_*       }
{  function of ui_shared.c (Quake III Arena, id Software, GPL v2 or later).    }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.ItemParser;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Menu,
  DelphiDoom.Gui.ValueReader;

type
  /// <summary>An ItemParse_* function: reads the arguments of its keyword into the item</summary>
  TGuiItemKeywordHandler = function(const AItem: TGuiItem): Boolean of object;

  /// <summary>
  ///   Reads "{ keyword arguments ... }" into a TGuiItem. Keywords are found without regard to case, like the
  ///   keyword hash of the original. Keywords of the type data (listbox, edit field, multi, model) fail when the
  ///   item has no data of that kind: the original dereferences a null or foreign pointer there.
  /// </summary>
  TGuiItemParser = class
  strict private
    FReader: TGuiValueReader;
    FAssets: IGuiAssetRegistry;
    FRandom: IGuiRandom;
    FKeywords: TDictionary<AnsiString, TGuiItemKeywordHandler>;
    procedure AddKeyword(const AName: AnsiString; const AHandler: TGuiItemKeywordHandler);
    procedure RegisterKeywords;
    function ReadFourColors(var AColor: TGuiColor; const AItem: TGuiItem; const ASetsForeColorFlag: Boolean): Boolean;
    function ParseScriptInto(var AText: AnsiString): Boolean;
    function ParseName(const AItem: TGuiItem): Boolean;
    function ParseFocusSound(const AItem: TGuiItem): Boolean;
    function ParseText(const AItem: TGuiItem): Boolean;
    function ParseGroup(const AItem: TGuiItem): Boolean;
    function ParseAssetModel(const AItem: TGuiItem): Boolean;
    function ParseAssetShader(const AItem: TGuiItem): Boolean;
    function ParseModelOrigin(const AItem: TGuiItem): Boolean;
    function ParseModelFovX(const AItem: TGuiItem): Boolean;
    function ParseModelFovY(const AItem: TGuiItem): Boolean;
    function ParseModelRotation(const AItem: TGuiItem): Boolean;
    function ParseModelAngle(const AItem: TGuiItem): Boolean;
    function ParseRect(const AItem: TGuiItem): Boolean;
    function ParseStyle(const AItem: TGuiItem): Boolean;
    function ParseDecoration(const AItem: TGuiItem): Boolean;
    function ParseNotSelectable(const AItem: TGuiItem): Boolean;
    function ParseWrapped(const AItem: TGuiItem): Boolean;
    function ParseAutoWrapped(const AItem: TGuiItem): Boolean;
    function ParseHorizontalScroll(const AItem: TGuiItem): Boolean;
    function ParseType(const AItem: TGuiItem): Boolean;
    function ParseElementWidth(const AItem: TGuiItem): Boolean;
    function ParseElementHeight(const AItem: TGuiItem): Boolean;
    function ParseFeeder(const AItem: TGuiItem): Boolean;
    function ParseElementType(const AItem: TGuiItem): Boolean;
    function ParseColumns(const AItem: TGuiItem): Boolean;
    function ParseBorder(const AItem: TGuiItem): Boolean;
    function ParseBorderSize(const AItem: TGuiItem): Boolean;
    function ParseVisible(const AItem: TGuiItem): Boolean;
    function ParseOwnerDraw(const AItem: TGuiItem): Boolean;
    function ParseAlign(const AItem: TGuiItem): Boolean;
    function ParseTextAlign(const AItem: TGuiItem): Boolean;
    function ParseTextAlignX(const AItem: TGuiItem): Boolean;
    function ParseTextAlignY(const AItem: TGuiItem): Boolean;
    function ParseTextScale(const AItem: TGuiItem): Boolean;
    function ParseTextStyle(const AItem: TGuiItem): Boolean;
    function ParseBackColor(const AItem: TGuiItem): Boolean;
    function ParseForeColor(const AItem: TGuiItem): Boolean;
    function ParseBorderColor(const AItem: TGuiItem): Boolean;
    function ParseOutlineColor(const AItem: TGuiItem): Boolean;
    function ParseBackground(const AItem: TGuiItem): Boolean;
    function ParseCinematic(const AItem: TGuiItem): Boolean;
    function ParseDoubleClick(const AItem: TGuiItem): Boolean;
    function ParseOnFocus(const AItem: TGuiItem): Boolean;
    function ParseLeaveFocus(const AItem: TGuiItem): Boolean;
    function ParseMouseEnter(const AItem: TGuiItem): Boolean;
    function ParseMouseExit(const AItem: TGuiItem): Boolean;
    function ParseMouseEnterText(const AItem: TGuiItem): Boolean;
    function ParseMouseExitText(const AItem: TGuiItem): Boolean;
    function ParseAction(const AItem: TGuiItem): Boolean;
    function ParseSpecial(const AItem: TGuiItem): Boolean;
    function ParseCvarTest(const AItem: TGuiItem): Boolean;
    function ParseCvar(const AItem: TGuiItem): Boolean;
    function ParseMaxChars(const AItem: TGuiItem): Boolean;
    function ParseMaxPaintChars(const AItem: TGuiItem): Boolean;
    function ParseCvarFloat(const AItem: TGuiItem): Boolean;
    function ParseCvarStrList(const AItem: TGuiItem): Boolean;
    function ParseCvarFloatList(const AItem: TGuiItem): Boolean;
    function ParseAddColorRange(const AItem: TGuiItem): Boolean;
    function ParseOwnerDrawFlag(const AItem: TGuiItem): Boolean;
    function ParseEnableCvar(const AItem: TGuiItem): Boolean;
    function ParseDisableCvar(const AItem: TGuiItem): Boolean;
    function ParseShowCvar(const AItem: TGuiItem): Boolean;
    function ParseHideCvar(const AItem: TGuiItem): Boolean;
    function ParseEnableAction(const AItem: TGuiItem; const AFlags: Integer): Boolean;
    /// <summary>The item has the type data of AKind after Item_ValidateTypeData</summary>
    function HasData(const AItem: TGuiItem; const AKind: TGuiItemDataKind): Boolean;
  public
    /// <summary>The reader is the caller's; the registry gives the handles of shaders, models and sounds; the random is optional</summary>
    constructor Create(const AReader: TGuiValueReader; const AAssets: IGuiAssetRegistry;
      const ARandom: IGuiRandom = nil);
    destructor Destroy; override;
    /// <summary>Item_Parse: false at the end of the file, at a keyword that cannot be read, or if the block does not start with "{"</summary>
    function Parse(const AItem: TGuiItem): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

constructor TGuiItemParser.Create(const AReader: TGuiValueReader; const AAssets: IGuiAssetRegistry;
  const ARandom: IGuiRandom);
begin
  inherited Create;
  FReader := AReader;
  FAssets := AAssets;
  FRandom := ARandom;
  FKeywords := TDictionary<AnsiString, TGuiItemKeywordHandler>.Create;
  RegisterKeywords;
end;

destructor TGuiItemParser.Destroy;
begin
  FKeywords.Free;
  inherited Destroy;
end;

procedure TGuiItemParser.AddKeyword(const AName: AnsiString; const AHandler: TGuiItemKeywordHandler);
begin
  FKeywords.AddOrSetValue(TIdStrings.ToLower(AName), AHandler);
end;

procedure TGuiItemParser.RegisterKeywords;
begin
  AddKeyword('name', ParseName);
  AddKeyword('text', ParseText);
  AddKeyword('group', ParseGroup);
  AddKeyword('asset_model', ParseAssetModel);
  AddKeyword('asset_shader', ParseAssetShader);
  AddKeyword('model_origin', ParseModelOrigin);
  AddKeyword('model_fovx', ParseModelFovX);
  AddKeyword('model_fovy', ParseModelFovY);
  AddKeyword('model_rotation', ParseModelRotation);
  AddKeyword('model_angle', ParseModelAngle);
  AddKeyword('rect', ParseRect);
  AddKeyword('style', ParseStyle);
  AddKeyword('decoration', ParseDecoration);
  AddKeyword('notselectable', ParseNotSelectable);
  AddKeyword('wrapped', ParseWrapped);
  AddKeyword('autowrapped', ParseAutoWrapped);
  AddKeyword('horizontalscroll', ParseHorizontalScroll);
  AddKeyword('type', ParseType);
  AddKeyword('elementwidth', ParseElementWidth);
  AddKeyword('elementheight', ParseElementHeight);
  AddKeyword('feeder', ParseFeeder);
  AddKeyword('elementtype', ParseElementType);
  AddKeyword('columns', ParseColumns);
  AddKeyword('border', ParseBorder);
  AddKeyword('bordersize', ParseBorderSize);
  AddKeyword('visible', ParseVisible);
  AddKeyword('ownerdraw', ParseOwnerDraw);
  AddKeyword('align', ParseAlign);
  AddKeyword('textalign', ParseTextAlign);
  AddKeyword('textalignx', ParseTextAlignX);
  AddKeyword('textaligny', ParseTextAlignY);
  AddKeyword('textscale', ParseTextScale);
  AddKeyword('textstyle', ParseTextStyle);
  AddKeyword('backcolor', ParseBackColor);
  AddKeyword('forecolor', ParseForeColor);
  AddKeyword('bordercolor', ParseBorderColor);
  AddKeyword('outlinecolor', ParseOutlineColor);
  AddKeyword('background', ParseBackground);
  AddKeyword('onFocus', ParseOnFocus);
  AddKeyword('leaveFocus', ParseLeaveFocus);
  AddKeyword('mouseEnter', ParseMouseEnter);
  AddKeyword('mouseExit', ParseMouseExit);
  AddKeyword('mouseEnterText', ParseMouseEnterText);
  AddKeyword('mouseExitText', ParseMouseExitText);
  AddKeyword('action', ParseAction);
  AddKeyword('special', ParseSpecial);
  AddKeyword('cvar', ParseCvar);
  AddKeyword('maxChars', ParseMaxChars);
  AddKeyword('maxPaintChars', ParseMaxPaintChars);
  AddKeyword('focusSound', ParseFocusSound);
  AddKeyword('cvarFloat', ParseCvarFloat);
  AddKeyword('cvarStrList', ParseCvarStrList);
  AddKeyword('cvarFloatList', ParseCvarFloatList);
  AddKeyword('addColorRange', ParseAddColorRange);
  AddKeyword('ownerdrawFlag', ParseOwnerDrawFlag);
  AddKeyword('enableCvar', ParseEnableCvar);
  AddKeyword('cvarTest', ParseCvarTest);
  AddKeyword('disableCvar', ParseDisableCvar);
  AddKeyword('showCvar', ParseShowCvar);
  AddKeyword('hideCvar', ParseHideCvar);
  AddKeyword('cinematic', ParseCinematic);
  AddKeyword('doubleclick', ParseDoubleClick);
end;

function TGuiItemParser.HasData(const AItem: TGuiItem; const AKind: TGuiItemDataKind): Boolean;
begin
  Result := AItem.DataKind = AKind;
end;

function TGuiItemParser.ParseScriptInto(var AText: AnsiString): Boolean;
begin
  Result := FReader.ReadScript(AText);
end;

function TGuiItemParser.Parse(const AItem: TGuiItem): Boolean;
var
  LToken: TGuiToken;
  LHandler: TGuiItemKeywordHandler;
begin
  if not FReader.ReadToken(LToken) then
    Exit(False);
  if (LToken.Text = '') or (LToken.Text[1] <> '{') then
    Exit(False);
  while True do
  begin
    if not FReader.ReadToken(LToken) then
    begin
      FReader.SourceError('end of file inside menu item' + #10);
      Exit(False);
    end;
    if (LToken.Text <> '') and (LToken.Text[1] = '}') then
      Exit(True);
    if not FKeywords.TryGetValue(TIdStrings.ToLower(LToken.Text), LHandler) then
    begin
      FReader.SourceError('unknown menu item keyword ' + string(LToken.Text));
      Continue;
    end;
    if not LHandler(AItem) then
    begin
      FReader.SourceError('couldn''t parse menu item keyword ' + string(LToken.Text));
      Exit(False);
    end;
  end;
end;

function TGuiItemParser.ReadFourColors(var AColor: TGuiColor; const AItem: TGuiItem;
  const ASetsForeColorFlag: Boolean): Boolean;
var
  LIndex: Integer;
  LValue: Single;
begin
  LValue := 0;
  for LIndex := 0 to 3 do
  begin
    if not FReader.ReadFloat(LValue) then
      Exit(False);
    AColor[LIndex] := LValue;
    if ASetsForeColorFlag then
      AItem.Window.Flags := AItem.Window.Flags or WINDOW_FORECOLORSET;
  end;
  Result := True;
end;

function TGuiItemParser.ParseName(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadString(AItem.Window.Name);
end;

function TGuiItemParser.ParseFocusSound(const AItem: TGuiItem): Boolean;
var
  LName: AnsiString;
begin
  LName := '';
  if not FReader.ReadString(LName) then
    Exit(False);
  AItem.FocusSound := FAssets.RegisterSound(LName, False);
  Result := True;
end;

function TGuiItemParser.ParseText(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadString(AItem.Text);
end;

function TGuiItemParser.ParseGroup(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadString(AItem.Window.Group);
end;

function TGuiItemParser.ParseAssetModel(const AItem: TGuiItem): Boolean;
var
  LName: AnsiString;
begin
  AItem.ValidateTypeData;
  // the original writes into typeData whatever it is (null for a button: a crash)
  if not HasData(AItem, gdkModel) then
    Exit(False);
  LName := '';
  if not FReader.ReadString(LName) then
    Exit(False);
  AItem.Asset := FAssets.RegisterModel(LName);
  if Assigned(FRandom) then
    AItem.Model.Angle := FRandom.Next(360)
  else
    AItem.Model.Angle := 0;
  Result := True;
end;

function TGuiItemParser.ParseAssetShader(const AItem: TGuiItem): Boolean;
var
  LName: AnsiString;
begin
  LName := '';
  if not FReader.ReadString(LName) then
    Exit(False);
  AItem.Asset := FAssets.RegisterShader(LName);
  Result := True;
end;

function TGuiItemParser.ParseModelOrigin(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkModel) then
    Exit(False);
  Result := FReader.ReadFloat(AItem.Model.Origin[0]) and FReader.ReadFloat(AItem.Model.Origin[1]) and
    FReader.ReadFloat(AItem.Model.Origin[2]);
end;

function TGuiItemParser.ParseModelFovX(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkModel) then
    Exit(False);
  Result := FReader.ReadFloat(AItem.Model.FovX);
end;

function TGuiItemParser.ParseModelFovY(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkModel) then
    Exit(False);
  Result := FReader.ReadFloat(AItem.Model.FovY);
end;

function TGuiItemParser.ParseModelRotation(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkModel) then
    Exit(False);
  Result := FReader.ReadInt(AItem.Model.RotationSpeed);
end;

function TGuiItemParser.ParseModelAngle(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkModel) then
    Exit(False);
  Result := FReader.ReadInt(AItem.Model.Angle);
end;

function TGuiItemParser.ParseRect(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadRect(AItem.Window.RectClient);
end;

function TGuiItemParser.ParseStyle(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadInt(AItem.Window.Style);
end;

function TGuiItemParser.ParseDecoration(const AItem: TGuiItem): Boolean;
begin
  AItem.Window.Flags := AItem.Window.Flags or WINDOW_DECORATION;
  Result := True;
end;

function TGuiItemParser.ParseNotSelectable(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if (AItem.ItemType = ITEM_TYPE_LISTBOX) and HasData(AItem, gdkListBox) then
    AItem.ListBox.NotSelectable := True;
  Result := True;
end;

function TGuiItemParser.ParseWrapped(const AItem: TGuiItem): Boolean;
begin
  AItem.Window.Flags := AItem.Window.Flags or WINDOW_WRAPPED;
  Result := True;
end;

function TGuiItemParser.ParseAutoWrapped(const AItem: TGuiItem): Boolean;
begin
  AItem.Window.Flags := AItem.Window.Flags or WINDOW_AUTOWRAPPED;
  Result := True;
end;

function TGuiItemParser.ParseHorizontalScroll(const AItem: TGuiItem): Boolean;
begin
  AItem.Window.Flags := AItem.Window.Flags or WINDOW_HORIZONTAL;
  Result := True;
end;

function TGuiItemParser.ParseType(const AItem: TGuiItem): Boolean;
begin
  if not FReader.ReadInt(AItem.ItemType) then
    Exit(False);
  AItem.ValidateTypeData;
  Result := True;
end;

function TGuiItemParser.ParseElementWidth(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkListBox) then
    Exit(False);
  Result := FReader.ReadFloat(AItem.ListBox.ElementWidth);
end;

function TGuiItemParser.ParseElementHeight(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkListBox) then
    Exit(False);
  Result := FReader.ReadFloat(AItem.ListBox.ElementHeight);
end;

function TGuiItemParser.ParseFeeder(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadFloat(AItem.Special);
end;

function TGuiItemParser.ParseElementType(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkListBox) then
    Exit(False);
  Result := FReader.ReadInt(AItem.ListBox.ElementStyle);
end;

function TGuiItemParser.ParseColumns(const AItem: TGuiItem): Boolean;
var
  LNumber: Integer;
  LIndex: Integer;
  LPos: Integer;
  LWidth: Integer;
  LMaxChars: Integer;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkListBox) then
    Exit(False);
  LNumber := 0;
  if not FReader.ReadInt(LNumber) then
    Exit(False);
  if LNumber > GUI_MAX_LB_COLUMNS then
    LNumber := GUI_MAX_LB_COLUMNS;
  AItem.ListBox.NumColumns := LNumber;
  for LIndex := 0 to LNumber - 1 do
  begin
    LPos := 0;
    LWidth := 0;
    LMaxChars := 0;
    if FReader.ReadInt(LPos) and FReader.ReadInt(LWidth) and FReader.ReadInt(LMaxChars) then
    begin
      AItem.ListBox.ColumnInfo[LIndex].Pos := LPos;
      AItem.ListBox.ColumnInfo[LIndex].Width := LWidth;
      AItem.ListBox.ColumnInfo[LIndex].MaxChars := LMaxChars;
    end
    else
      Exit(False);
  end;
  Result := True;
end;

function TGuiItemParser.ParseBorder(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadInt(AItem.Window.Border);
end;

function TGuiItemParser.ParseBorderSize(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadFloat(AItem.Window.BorderSize);
end;

function TGuiItemParser.ParseVisible(const AItem: TGuiItem): Boolean;
var
  LValue: Integer;
begin
  LValue := 0;
  if not FReader.ReadInt(LValue) then
    Exit(False);
  if LValue <> 0 then
    AItem.Window.Flags := AItem.Window.Flags or WINDOW_VISIBLE;
  Result := True;
end;

function TGuiItemParser.ParseOwnerDraw(const AItem: TGuiItem): Boolean;
begin
  if not FReader.ReadInt(AItem.Window.OwnerDraw) then
    Exit(False);
  AItem.ItemType := ITEM_TYPE_OWNERDRAW;
  Result := True;
end;

function TGuiItemParser.ParseAlign(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadInt(AItem.Alignment);
end;

function TGuiItemParser.ParseTextAlign(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadInt(AItem.TextAlignment);
end;

function TGuiItemParser.ParseTextAlignX(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadFloat(AItem.TextAlignX);
end;

function TGuiItemParser.ParseTextAlignY(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadFloat(AItem.TextAlignY);
end;

function TGuiItemParser.ParseTextScale(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadFloat(AItem.TextScale);
end;

function TGuiItemParser.ParseTextStyle(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadInt(AItem.TextStyle);
end;

function TGuiItemParser.ParseBackColor(const AItem: TGuiItem): Boolean;
begin
  Result := ReadFourColors(AItem.Window.BackColor, AItem, False);
end;

function TGuiItemParser.ParseForeColor(const AItem: TGuiItem): Boolean;
begin
  Result := ReadFourColors(AItem.Window.ForeColor, AItem, True);
end;

function TGuiItemParser.ParseBorderColor(const AItem: TGuiItem): Boolean;
begin
  Result := ReadFourColors(AItem.Window.BorderColor, AItem, False);
end;

function TGuiItemParser.ParseOutlineColor(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadColor(AItem.Window.OutlineColor);
end;

function TGuiItemParser.ParseBackground(const AItem: TGuiItem): Boolean;
var
  LName: AnsiString;
begin
  LName := '';
  if not FReader.ReadString(LName) then
    Exit(False);
  AItem.Window.Background := FAssets.RegisterShader(LName);
  Result := True;
end;

function TGuiItemParser.ParseCinematic(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadString(AItem.Window.CinematicName);
end;

function TGuiItemParser.ParseDoubleClick(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkListBox) then
    Exit(False);
  Result := FReader.ReadScript(AItem.ListBox.DoubleClick);
end;

function TGuiItemParser.ParseOnFocus(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.OnFocus);
end;

function TGuiItemParser.ParseLeaveFocus(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.LeaveFocus);
end;

function TGuiItemParser.ParseMouseEnter(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.MouseEnter);
end;

function TGuiItemParser.ParseMouseExit(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.MouseExit);
end;

function TGuiItemParser.ParseMouseEnterText(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.MouseEnterText);
end;

function TGuiItemParser.ParseMouseExitText(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.MouseExitText);
end;

function TGuiItemParser.ParseAction(const AItem: TGuiItem): Boolean;
begin
  Result := ParseScriptInto(AItem.Action);
end;

function TGuiItemParser.ParseSpecial(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadFloat(AItem.Special);
end;

function TGuiItemParser.ParseCvarTest(const AItem: TGuiItem): Boolean;
begin
  Result := FReader.ReadString(AItem.CvarTest);
end;

function TGuiItemParser.ParseCvar(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not FReader.ReadString(AItem.Cvar) then
    Exit(False);
  if HasData(AItem, gdkEditField) then
  begin
    AItem.EditField.MinVal := -1;
    AItem.EditField.MaxVal := -1;
    AItem.EditField.DefVal := -1;
  end;
  Result := True;
end;

function TGuiItemParser.ParseMaxChars(const AItem: TGuiItem): Boolean;
var
  LValue: Integer;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkEditField) then
    Exit(False);
  LValue := 0;
  if not FReader.ReadInt(LValue) then
    Exit(False);
  AItem.EditField.MaxChars := LValue;
  Result := True;
end;

function TGuiItemParser.ParseMaxPaintChars(const AItem: TGuiItem): Boolean;
var
  LValue: Integer;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkEditField) then
    Exit(False);
  LValue := 0;
  if not FReader.ReadInt(LValue) then
    Exit(False);
  AItem.EditField.MaxPaintChars := LValue;
  Result := True;
end;

function TGuiItemParser.ParseCvarFloat(const AItem: TGuiItem): Boolean;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkEditField) then
    Exit(False);
  Result := FReader.ReadString(AItem.Cvar) and FReader.ReadFloat(AItem.EditField.DefVal) and
    FReader.ReadFloat(AItem.EditField.MinVal) and FReader.ReadFloat(AItem.EditField.MaxVal);
end;

function TGuiItemParser.ParseCvarStrList(const AItem: TGuiItem): Boolean;
var
  LToken: TGuiToken;
  LPass: Integer;
  LText: AnsiString;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkMulti) then
    Exit(False);
  AItem.Multi.Count := 0;
  AItem.Multi.StrDef := True;
  if not FReader.ReadToken(LToken) then
    Exit(False);
  if (LToken.Text = '') or (LToken.Text[1] <> '{') then
    Exit(False);
  LPass := 0;
  while True do
  begin
    if not FReader.ReadToken(LToken) then
    begin
      FReader.SourceError('end of file inside menu item' + #10);
      Exit(False);
    end;
    if (LToken.Text <> '') and (LToken.Text[1] = '}') then
      Exit(True);
    if (LToken.Text <> '') and (LToken.Text[1] in [',', ';']) then
      Continue;
    LText := FReader.Strings.Alloc(LToken.Text);
    if LPass = 0 then
    begin
      AItem.Multi.CvarList[AItem.Multi.Count] := LText;
      LPass := 1;
    end
    else
    begin
      AItem.Multi.CvarStr[AItem.Multi.Count] := LText;
      LPass := 0;
      Inc(AItem.Multi.Count);
      if AItem.Multi.Count >= GUI_MAX_MULTI_CVARS then
        Exit(False);
    end;
  end;
end;

function TGuiItemParser.ParseCvarFloatList(const AItem: TGuiItem): Boolean;
var
  LToken: TGuiToken;
begin
  AItem.ValidateTypeData;
  if not HasData(AItem, gdkMulti) then
    Exit(False);
  AItem.Multi.Count := 0;
  AItem.Multi.StrDef := False;
  if not FReader.ReadToken(LToken) then
    Exit(False);
  if (LToken.Text = '') or (LToken.Text[1] <> '{') then
    Exit(False);
  while True do
  begin
    if not FReader.ReadToken(LToken) then
    begin
      FReader.SourceError('end of file inside menu item' + #10);
      Exit(False);
    end;
    if (LToken.Text <> '') and (LToken.Text[1] = '}') then
      Exit(True);
    if (LToken.Text <> '') and (LToken.Text[1] in [',', ';']) then
      Continue;
    AItem.Multi.CvarList[AItem.Multi.Count] := FReader.Strings.Alloc(LToken.Text);
    if not FReader.ReadFloat(AItem.Multi.CvarValue[AItem.Multi.Count]) then
      Exit(False);
    Inc(AItem.Multi.Count);
    if AItem.Multi.Count >= GUI_MAX_MULTI_CVARS then
      Exit(False);
  end;
end;

function TGuiItemParser.ParseAddColorRange(const AItem: TGuiItem): Boolean;
var
  LRange: TGuiColorRange;
begin
  LRange := Default(TGuiColorRange);
  if FReader.ReadFloat(LRange.Low) and FReader.ReadFloat(LRange.High) and FReader.ReadColor(LRange.Color) then
  begin
    if AItem.NumColors < GUI_MAX_COLOR_RANGES then
    begin
      AItem.ColorRanges[AItem.NumColors] := LRange;
      Inc(AItem.NumColors);
    end;
    Exit(True);
  end;
  Result := False;
end;

function TGuiItemParser.ParseOwnerDrawFlag(const AItem: TGuiItem): Boolean;
var
  LValue: Integer;
begin
  LValue := 0;
  if not FReader.ReadInt(LValue) then
    Exit(False);
  AItem.Window.OwnerDrawFlags := AItem.Window.OwnerDrawFlags or LValue;
  Result := True;
end;

function TGuiItemParser.ParseEnableAction(const AItem: TGuiItem; const AFlags: Integer): Boolean;
begin
  if FReader.ReadScript(AItem.EnableCvar) then
  begin
    AItem.CvarFlags := AFlags;
    Exit(True);
  end;
  Result := False;
end;

function TGuiItemParser.ParseEnableCvar(const AItem: TGuiItem): Boolean;
begin
  Result := ParseEnableAction(AItem, CVAR_ENABLE);
end;

function TGuiItemParser.ParseDisableCvar(const AItem: TGuiItem): Boolean;
begin
  Result := ParseEnableAction(AItem, CVAR_DISABLE);
end;

function TGuiItemParser.ParseShowCvar(const AItem: TGuiItem): Boolean;
begin
  Result := ParseEnableAction(AItem, CVAR_SHOW);
end;

function TGuiItemParser.ParseHideCvar(const AItem: TGuiItem): Boolean;
begin
  Result := ParseEnableAction(AItem, CVAR_HIDE);
end;

end.
