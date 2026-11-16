{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - reading "assetGlobalDef"                          }
{                                                                              }
{  Port of Asset_Parse of ui_main.c (Quake III Arena / Team Arena, id          }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.AssetParser;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Assets, DelphiDoom.Gui.FontRegistry,
  DelphiDoom.Gui.ValueReader;

type
  /// <summary>Reads the block of fonts, sounds, cursor, fade and shadow values into the assets</summary>
  TGuiAssetParser = class
  strict private
    FReader: TGuiValueReader;
    FAssets: TGuiAssets;
    FRegistry: IGuiAssetRegistry;
    FFonts: TGuiFontRegistry;
    function ReadFont(const AFont: TObject; const AIsText: Boolean): Boolean;
  public
    constructor Create(const AReader: TGuiValueReader; const AAssets: TGuiAssets;
      const ARegistry: IGuiAssetRegistry; const AFonts: TGuiFontRegistry);
    /// <summary>Asset_Parse: true at the closing brace, false at the end of the file or a value that cannot be read</summary>
    function Parse: Boolean;
  end;

implementation

uses
  DelphiDoom.Gui.Font, DelphiDoom.IdLib.Text.Strings;

constructor TGuiAssetParser.Create(const AReader: TGuiValueReader; const AAssets: TGuiAssets;
  const ARegistry: IGuiAssetRegistry; const AFonts: TGuiFontRegistry);
begin
  inherited Create;
  FReader := AReader;
  FAssets := AAssets;
  FRegistry := ARegistry;
  FFonts := AFonts;
end;

function TGuiAssetParser.ReadFont(const AFont: TObject; const AIsText: Boolean): Boolean;
var
  LName: AnsiString;
  LPointSize: Integer;
begin
  LName := '';
  LPointSize := 0;
  if (not FReader.ReadString(LName)) or (not FReader.ReadInt(LPointSize)) then
    Exit(False);
  FFonts.Register(LName, LPointSize, AFont as TGuiFont);
  if AIsText then
    FAssets.FontRegistered := True;
  Result := True;
end;

function TGuiAssetParser.Parse: Boolean;
var
  LToken: TGuiToken;
  LText: AnsiString;
  LKey: AnsiString;
begin
  if not FReader.ReadToken(LToken) then
    Exit(False);
  if TIdStrings.Icmp(LToken.Text, '{') <> 0 then
    Exit(False);
  while True do
  begin
    if not FReader.ReadToken(LToken) then
      Exit(False);
    if TIdStrings.Icmp(LToken.Text, '}') = 0 then
      Exit(True);
    LKey := TIdStrings.ToLower(LToken.Text);
    LText := '';
    if LKey = 'font' then
    begin
      if not ReadFont(FAssets.TextFont, True) then
        Exit(False);
    end
    else if LKey = 'smallfont' then
    begin
      if not ReadFont(FAssets.SmallFont, False) then
        Exit(False);
    end
    else if LKey = 'bigfont' then
    begin
      if not ReadFont(FAssets.BigFont, False) then
        Exit(False);
    end
    else if LKey = 'gradientbar' then
    begin
      if not FReader.ReadString(LText) then
        Exit(False);
      FAssets.GradientBar := FRegistry.RegisterShader(LText);
    end
    else if LKey = 'menuentersound' then
    begin
      if not FReader.ReadString(LText) then
        Exit(False);
      FAssets.MenuEnterSound := FRegistry.RegisterSound(LText, False);
    end
    else if LKey = 'menuexitsound' then
    begin
      if not FReader.ReadString(LText) then
        Exit(False);
      FAssets.MenuExitSound := FRegistry.RegisterSound(LText, False);
    end
    else if LKey = 'itemfocussound' then
    begin
      if not FReader.ReadString(LText) then
        Exit(False);
      FAssets.ItemFocusSound := FRegistry.RegisterSound(LText, False);
    end
    else if LKey = 'menubuzzsound' then
    begin
      if not FReader.ReadString(LText) then
        Exit(False);
      FAssets.MenuBuzzSound := FRegistry.RegisterSound(LText, False);
    end
    else if LKey = 'cursor' then
    begin
      if not FReader.ReadString(FAssets.CursorStr) then
        Exit(False);
      FAssets.Cursor := FRegistry.RegisterShader(FAssets.CursorStr);
    end
    else if LKey = 'fadeclamp' then
    begin
      if not FReader.ReadFloat(FAssets.FadeClamp) then
        Exit(False);
    end
    else if LKey = 'fadecycle' then
    begin
      if not FReader.ReadInt(FAssets.FadeCycle) then
        Exit(False);
    end
    else if LKey = 'fadeamount' then
    begin
      if not FReader.ReadFloat(FAssets.FadeAmount) then
        Exit(False);
    end
    else if LKey = 'shadowx' then
    begin
      if not FReader.ReadFloat(FAssets.ShadowX) then
        Exit(False);
    end
    else if LKey = 'shadowy' then
    begin
      if not FReader.ReadFloat(FAssets.ShadowY) then
        Exit(False);
    end
    else if LKey = 'shadowcolor' then
    begin
      if not FReader.ReadColor(FAssets.ShadowColor) then
        Exit(False);
      FAssets.ShadowFadeClamp := FAssets.ShadowColor[3];
    end;
    // any other keyword is skipped without a message, as in the original
  end;
end;

end.
