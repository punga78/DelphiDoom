{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - menu files and the list of menu files             }
{                                                                              }
{  Port of UI_ParseMenu, Load_Menu and UI_LoadMenus of ui_main.c (Quake III    }
{  Arena / Team Arena, id Software, GPL v2 or later). Based on the Quake III   }
{  Arena GPL Source Code (id Software).                                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.MenuFileReader;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.MenuSet, DelphiDoom.Gui.ValueReader;

type
  /// <summary>Reads menu files into a menu set: one file, or a list of files ("loadmenu")</summary>
  TGuiMenuFileReader = class
  strict private
    FLoader: IGuiSourceLoader;
    FMenus: TGuiMenuSet;
    FLog: IGuiLog;
    function LoadMenu(const AReader: TGuiValueReader): Boolean;
  public
    /// <summary>The menu set is the caller's; the log may be nil</summary>
    constructor Create(const ALoader: IGuiSourceLoader; const AMenus: TGuiMenuSet; const ALog: IGuiLog = nil);
    /// <summary>
    ///   UI_ParseMenu: reads the "assetGlobalDef" and "menuDef" blocks of a file until its end or a "}". A file
    ///   that cannot be opened is a message and false; the first menu that fails ends the file.
    /// </summary>
    function ParseMenu(const AFileName: AnsiString): Boolean;
    /// <summary>
    ///   UI_LoadMenus: reads the list of files ("loadmenu { "file" }"). If AListName cannot be opened the default
    ///   list "ui/menus.txt" is read; if that fails as well, EGuiFileNotFoundException (the original calls
    ///   trap_Error, which ends the game).
    /// </summary>
    procedure LoadMenus(const AListName: AnsiString; const AReset: Boolean);
  end;

implementation

uses
  DelphiDoom.Gui.AssetParser, DelphiDoom.IdLib.Text.Strings;

const
  DEFAULT_MENU_LIST = 'ui/menus.txt';

constructor TGuiMenuFileReader.Create(const ALoader: IGuiSourceLoader; const AMenus: TGuiMenuSet;
  const ALog: IGuiLog);
begin
  inherited Create;
  FLoader := ALoader;
  FMenus := AMenus;
  FLog := ALog;
end;

function TGuiMenuFileReader.ParseMenu(const AFileName: AnsiString): Boolean;
var
  LSource: IGuiTokenSource;
  LReader: TGuiValueReader;
  LToken: TGuiToken;
  LAssetParser: TGuiAssetParser;
begin
  if Assigned(FLog) then
    FLog.Info('Parsing menu file:' + string(AFileName));
  LSource := FLoader.Load(AFileName);
  if not Assigned(LSource) then
    Exit(False);
  LReader := TGuiValueReader.Create(LSource, FMenus.Strings, FLog);
  try
    while True do
    begin
      if not LReader.ReadToken(LToken) then
        Break;
      if (LToken.Text <> '') and (LToken.Text[1] = '}') then
        Break;
      if TIdStrings.Icmp(LToken.Text, 'assetGlobalDef') = 0 then
      begin
        LAssetParser := TGuiAssetParser.Create(LReader, FMenus.Assets, FMenus.Registry, FMenus.Fonts);
        try
          if LAssetParser.Parse then
            Continue;
        finally
          LAssetParser.Free;
        end;
        Break;
      end;
      if TIdStrings.Icmp(LToken.Text, 'menudef') = 0 then
        FMenus.AddMenu(LReader);
    end;
  finally
    LReader.Free;
  end;
  Result := True;
end;

function TGuiMenuFileReader.LoadMenu(const AReader: TGuiValueReader): Boolean;
var
  LToken: TGuiToken;
begin
  if not AReader.ReadToken(LToken) then
    Exit(False);
  if (LToken.Text = '') or (LToken.Text[1] <> '{') then
    Exit(False);
  while True do
  begin
    if not AReader.ReadToken(LToken) then
      Exit(False);
    if LToken.Text = '' then
      Exit(False);
    if LToken.Text[1] = '}' then
      Exit(True);
    ParseMenu(LToken.Text);
  end;
end;

procedure TGuiMenuFileReader.LoadMenus(const AListName: AnsiString; const AReset: Boolean);
var
  LSource: IGuiTokenSource;
  LReader: TGuiValueReader;
  LToken: TGuiToken;
begin
  LSource := FLoader.Load(AListName);
  if not Assigned(LSource) then
  begin
    if Assigned(FLog) then
      FLog.Info('menu file not found: ' + string(AListName) + ', using default');
    LSource := FLoader.Load(DEFAULT_MENU_LIST);
    if not Assigned(LSource) then
      raise EGuiFileNotFoundException.Create(DEFAULT_MENU_LIST);
  end;
  if AReset then
    FMenus.Reset;
  LReader := TGuiValueReader.Create(LSource, FMenus.Strings, FLog);
  try
    while True do
    begin
      if not LReader.ReadToken(LToken) then
        Break;
      if (LToken.Text = '') or (LToken.Text[1] = '}') then
        Break;
      if TIdStrings.Icmp(LToken.Text, 'loadmenu') = 0 then
      begin
        if LoadMenu(LReader) then
          Continue;
        Break;
      end;
    end;
  finally
    LReader.Free;
  end;
end;

end.
