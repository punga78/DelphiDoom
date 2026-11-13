{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - reading a menuDef                                 }
{                                                                              }
{  Port of Menu_Parse, the table menuParseKeywords and every MenuParse_*       }
{  function of ui_shared.c (Quake III Arena, id Software, GPL v2 or later).    }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.MenuParser;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Menu,
  DelphiDoom.Gui.ValueReader, DelphiDoom.Gui.ItemParser, DelphiDoom.Gui.Assets, DelphiDoom.Gui.FontRegistry;

type
  /// <summary>A MenuParse_* function: reads the arguments of its keyword into the menu</summary>
  TGuiMenuKeywordHandler = function(const AMenu: TGuiMenu): Boolean of object;

  /// <summary>
  ///   Reads "{ keyword arguments ... itemDef { ... } ... }" into a TGuiMenu. Keywords are found without regard
  ///   to case. Past 96 items the original returns success without reading the item block: its text is then read
  ///   as menu keywords (see the README of the library); that is kept.
  /// </summary>
  TGuiMenuParser = class
  strict private
    FReader: TGuiValueReader;
    FItemParser: TGuiItemParser;
    FAssetRegistry: IGuiAssetRegistry;
    FAssets: TGuiAssets;
    FFonts: TGuiFontRegistry;
    FKeywords: TDictionary<AnsiString, TGuiMenuKeywordHandler>;
    procedure AddKeyword(const AName: AnsiString; const AHandler: TGuiMenuKeywordHandler);
    procedure RegisterKeywords;
    function ReadFourColors(var AColor: TGuiColor; const AMenu: TGuiMenu; const ASetsForeColorFlag: Boolean): Boolean;
    function ParseFont(const AMenu: TGuiMenu): Boolean;
    function ParseName(const AMenu: TGuiMenu): Boolean;
    function ParseFullScreen(const AMenu: TGuiMenu): Boolean;
    function ParseRect(const AMenu: TGuiMenu): Boolean;
    function ParseStyle(const AMenu: TGuiMenu): Boolean;
    function ParseVisible(const AMenu: TGuiMenu): Boolean;
    function ParseOnOpen(const AMenu: TGuiMenu): Boolean;
    function ParseOnClose(const AMenu: TGuiMenu): Boolean;
    function ParseOnESC(const AMenu: TGuiMenu): Boolean;
    function ParseBorder(const AMenu: TGuiMenu): Boolean;
    function ParseBorderSize(const AMenu: TGuiMenu): Boolean;
    function ParseBackColor(const AMenu: TGuiMenu): Boolean;
    function ParseForeColor(const AMenu: TGuiMenu): Boolean;
    function ParseBorderColor(const AMenu: TGuiMenu): Boolean;
    function ParseFocusColor(const AMenu: TGuiMenu): Boolean;
    function ParseDisableColor(const AMenu: TGuiMenu): Boolean;
    function ParseOutlineColor(const AMenu: TGuiMenu): Boolean;
    function ParseBackground(const AMenu: TGuiMenu): Boolean;
    function ParseCinematic(const AMenu: TGuiMenu): Boolean;
    function ParseOwnerDrawFlag(const AMenu: TGuiMenu): Boolean;
    function ParseOwnerDraw(const AMenu: TGuiMenu): Boolean;
    function ParsePopup(const AMenu: TGuiMenu): Boolean;
    function ParseOutOfBounds(const AMenu: TGuiMenu): Boolean;
    function ParseSoundLoop(const AMenu: TGuiMenu): Boolean;
    function ParseFadeClamp(const AMenu: TGuiMenu): Boolean;
    function ParseFadeAmount(const AMenu: TGuiMenu): Boolean;
    function ParseFadeCycle(const AMenu: TGuiMenu): Boolean;
    function ParseItemDef(const AMenu: TGuiMenu): Boolean;
    /// <summary>Item_InitControls</summary>
    procedure InitControls(const AItem: TGuiItem);
  public
    /// <summary>Everything is the caller's; the item parser reads from the same reader</summary>
    constructor Create(const AReader: TGuiValueReader; const AItemParser: TGuiItemParser;
      const AAssetRegistry: IGuiAssetRegistry; const AAssets: TGuiAssets; const AFonts: TGuiFontRegistry);
    destructor Destroy; override;
    /// <summary>Menu_Parse</summary>
    function Parse(const AMenu: TGuiMenu): Boolean;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings;

const
  // the "font" keyword of a menu registers the text font at 48 points
  MENU_FONT_POINT_SIZE = 48;

constructor TGuiMenuParser.Create(const AReader: TGuiValueReader; const AItemParser: TGuiItemParser;
  const AAssetRegistry: IGuiAssetRegistry; const AAssets: TGuiAssets; const AFonts: TGuiFontRegistry);
begin
  inherited Create;
  FReader := AReader;
  FItemParser := AItemParser;
  FAssetRegistry := AAssetRegistry;
  FAssets := AAssets;
  FFonts := AFonts;
  FKeywords := TDictionary<AnsiString, TGuiMenuKeywordHandler>.Create;
  RegisterKeywords;
end;

destructor TGuiMenuParser.Destroy;
begin
  FKeywords.Free;
  inherited Destroy;
end;

procedure TGuiMenuParser.AddKeyword(const AName: AnsiString; const AHandler: TGuiMenuKeywordHandler);
begin
  FKeywords.AddOrSetValue(TIdStrings.ToLower(AName), AHandler);
end;

procedure TGuiMenuParser.RegisterKeywords;
begin
  AddKeyword('font', ParseFont);
  AddKeyword('name', ParseName);
  AddKeyword('fullscreen', ParseFullScreen);
  AddKeyword('rect', ParseRect);
  AddKeyword('style', ParseStyle);
  AddKeyword('visible', ParseVisible);
  AddKeyword('onOpen', ParseOnOpen);
  AddKeyword('onClose', ParseOnClose);
  AddKeyword('onESC', ParseOnESC);
  AddKeyword('border', ParseBorder);
  AddKeyword('borderSize', ParseBorderSize);
  AddKeyword('backcolor', ParseBackColor);
  AddKeyword('forecolor', ParseForeColor);
  AddKeyword('bordercolor', ParseBorderColor);
  AddKeyword('focuscolor', ParseFocusColor);
  AddKeyword('disablecolor', ParseDisableColor);
  AddKeyword('outlinecolor', ParseOutlineColor);
  AddKeyword('background', ParseBackground);
  AddKeyword('ownerdraw', ParseOwnerDraw);
  AddKeyword('ownerdrawFlag', ParseOwnerDrawFlag);
  AddKeyword('outOfBoundsClick', ParseOutOfBounds);
  AddKeyword('soundLoop', ParseSoundLoop);
  AddKeyword('itemDef', ParseItemDef);
  AddKeyword('cinematic', ParseCinematic);
  AddKeyword('popup', ParsePopup);
  AddKeyword('fadeClamp', ParseFadeClamp);
  AddKeyword('fadeCycle', ParseFadeCycle);
  AddKeyword('fadeAmount', ParseFadeAmount);
end;

function TGuiMenuParser.Parse(const AMenu: TGuiMenu): Boolean;
var
  LToken: TGuiToken;
  LHandler: TGuiMenuKeywordHandler;
begin
  if not FReader.ReadToken(LToken) then
    Exit(False);
  if (LToken.Text = '') or (LToken.Text[1] <> '{') then
    Exit(False);
  while True do
  begin
    if not FReader.ReadToken(LToken) then
    begin
      FReader.SourceError('end of file inside menu' + #10);
      Exit(False);
    end;
    if (LToken.Text <> '') and (LToken.Text[1] = '}') then
      Exit(True);
    if not FKeywords.TryGetValue(TIdStrings.ToLower(LToken.Text), LHandler) then
    begin
      FReader.SourceError('unknown menu keyword ' + string(LToken.Text));
      Continue;
    end;
    if not LHandler(AMenu) then
    begin
      FReader.SourceError('couldn''t parse menu keyword ' + string(LToken.Text));
      Exit(False);
    end;
  end;
end;

function TGuiMenuParser.ReadFourColors(var AColor: TGuiColor; const AMenu: TGuiMenu;
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
      AMenu.Window.Flags := AMenu.Window.Flags or WINDOW_FORECOLORSET;
  end;
  Result := True;
end;

function TGuiMenuParser.ParseFont(const AMenu: TGuiMenu): Boolean;
begin
  if not FReader.ReadString(AMenu.Font) then
    Exit(False);
  if not FAssets.FontRegistered then
  begin
    FFonts.Register(AMenu.Font, MENU_FONT_POINT_SIZE, FAssets.TextFont);
    FAssets.FontRegistered := True;
  end;
  Result := True;
end;

function TGuiMenuParser.ParseName(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadString(AMenu.Window.Name);
end;

function TGuiMenuParser.ParseFullScreen(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadInt(AMenu.FullScreen);
end;

function TGuiMenuParser.ParseRect(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadRect(AMenu.Window.Rect);
end;

function TGuiMenuParser.ParseStyle(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadInt(AMenu.Window.Style);
end;

function TGuiMenuParser.ParseVisible(const AMenu: TGuiMenu): Boolean;
var
  LValue: Integer;
begin
  LValue := 0;
  if not FReader.ReadInt(LValue) then
    Exit(False);
  if LValue <> 0 then
    AMenu.Window.Flags := AMenu.Window.Flags or WINDOW_VISIBLE;
  Result := True;
end;

function TGuiMenuParser.ParseOnOpen(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadScript(AMenu.OnOpen);
end;

function TGuiMenuParser.ParseOnClose(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadScript(AMenu.OnClose);
end;

function TGuiMenuParser.ParseOnESC(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadScript(AMenu.OnESC);
end;

function TGuiMenuParser.ParseBorder(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadInt(AMenu.Window.Border);
end;

function TGuiMenuParser.ParseBorderSize(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadFloat(AMenu.Window.BorderSize);
end;

function TGuiMenuParser.ParseBackColor(const AMenu: TGuiMenu): Boolean;
begin
  Result := ReadFourColors(AMenu.Window.BackColor, AMenu, False);
end;

function TGuiMenuParser.ParseForeColor(const AMenu: TGuiMenu): Boolean;
begin
  Result := ReadFourColors(AMenu.Window.ForeColor, AMenu, True);
end;

function TGuiMenuParser.ParseBorderColor(const AMenu: TGuiMenu): Boolean;
begin
  Result := ReadFourColors(AMenu.Window.BorderColor, AMenu, False);
end;

function TGuiMenuParser.ParseFocusColor(const AMenu: TGuiMenu): Boolean;
begin
  Result := ReadFourColors(AMenu.FocusColor, AMenu, False);
end;

function TGuiMenuParser.ParseDisableColor(const AMenu: TGuiMenu): Boolean;
begin
  Result := ReadFourColors(AMenu.DisableColor, AMenu, False);
end;

function TGuiMenuParser.ParseOutlineColor(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadColor(AMenu.Window.OutlineColor);
end;

function TGuiMenuParser.ParseBackground(const AMenu: TGuiMenu): Boolean;
var
  LName: AnsiString;
begin
  LName := '';
  if not FReader.ReadString(LName) then
    Exit(False);
  AMenu.Window.Background := FAssetRegistry.RegisterShader(LName);
  Result := True;
end;

function TGuiMenuParser.ParseCinematic(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadString(AMenu.Window.CinematicName);
end;

function TGuiMenuParser.ParseOwnerDrawFlag(const AMenu: TGuiMenu): Boolean;
var
  LValue: Integer;
begin
  LValue := 0;
  if not FReader.ReadInt(LValue) then
    Exit(False);
  AMenu.Window.OwnerDrawFlags := AMenu.Window.OwnerDrawFlags or LValue;
  Result := True;
end;

function TGuiMenuParser.ParseOwnerDraw(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadInt(AMenu.Window.OwnerDraw);
end;

function TGuiMenuParser.ParsePopup(const AMenu: TGuiMenu): Boolean;
begin
  AMenu.Window.Flags := AMenu.Window.Flags or WINDOW_POPUP;
  Result := True;
end;

function TGuiMenuParser.ParseOutOfBounds(const AMenu: TGuiMenu): Boolean;
begin
  AMenu.Window.Flags := AMenu.Window.Flags or WINDOW_OOB_CLICK;
  Result := True;
end;

function TGuiMenuParser.ParseSoundLoop(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadString(AMenu.SoundName);
end;

function TGuiMenuParser.ParseFadeClamp(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadFloat(AMenu.FadeClamp);
end;

function TGuiMenuParser.ParseFadeAmount(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadFloat(AMenu.FadeAmount);
end;

function TGuiMenuParser.ParseFadeCycle(const AMenu: TGuiMenu): Boolean;
begin
  Result := FReader.ReadInt(AMenu.FadeCycle);
end;

procedure TGuiMenuParser.InitControls(const AItem: TGuiItem);
begin
  if AItem.ItemType = ITEM_TYPE_LISTBOX then
  begin
    AItem.CursorPos := 0;
    if AItem.DataKind = gdkListBox then
    begin
      AItem.ListBox.CursorPos := 0;
      AItem.ListBox.StartPos := 0;
      AItem.ListBox.EndPos := 0;
    end;
  end;
end;

function TGuiMenuParser.ParseItemDef(const AMenu: TGuiMenu): Boolean;
var
  LItem: TGuiItem;
begin
  if AMenu.Items.Count < GUI_MAX_MENUITEMS then
  begin
    LItem := TGuiItem.Create;
    if not FItemParser.Parse(LItem) then
    begin
      LItem.Free;
      Exit(False);
    end;
    InitControls(LItem);
    LItem.Parent := AMenu;
    AMenu.Items.Add(LItem);
  end;
  Result := True;
end;

end.
