{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the menus that are loaded                         }
{                                                                              }
{  What the global arrays of ui_shared.c (Menus[], menuCount, the string pool, }
{  the display context assets) are in an object: Menu_New, Menu_Count,         }
{  Menu_Reset, Menus_FindByName (Quake III Arena, id Software, GPL v2 or       }
{  later). Based on the Quake III Arena GPL Source Code (id Software).         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.MenuSet;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.Gui.Menu,
  DelphiDoom.Gui.Assets, DelphiDoom.Gui.StringPool, DelphiDoom.Gui.FontRegistry, DelphiDoom.Gui.ValueReader;

type
  /// <summary>
  ///   The menus read so far (at most 64), the string pool they share and the assets they start from. Two sets
  ///   share nothing.
  /// </summary>
  TGuiMenuSet = class
  strict private
    FMenus: TObjectList<TGuiMenu>;
    FStrings: TGuiStringPool;
    FAssets: TGuiAssets;
    FRegistry: IGuiAssetRegistry;
    FFonts: TGuiFontRegistry;
    FRandom: IGuiRandom;
  public
    /// <summary>The font registry is the caller's; the random (the angle of model items) is optional</summary>
    constructor Create(const ARegistry: IGuiAssetRegistry; const AFonts: TGuiFontRegistry;
      const ARandom: IGuiRandom = nil);
    destructor Destroy; override;
    /// <summary>
    ///   Menu_New: reads "{ ... }" from the source into a new menu; the menu is kept (after Menu_PostParse)
    ///   only if it was read to its end. False when it was not or when 64 menus exist (nothing is read then).
    /// </summary>
    function AddMenu(const AReader: TGuiValueReader): Boolean;
    /// <summary>Menu_Reset: forgets the menus (not the strings)</summary>
    procedure Reset;
    /// <summary>Menu_Count</summary>
    function Count: Integer;
    function GetMenu(const AIndex: Integer): TGuiMenu;
    /// <summary>Menus_FindByName: the first menu with this name (without case), nil if none</summary>
    function FindByName(const AName: AnsiString): TGuiMenu;
    property Menus[const AIndex: Integer]: TGuiMenu read GetMenu; default;
    property Strings: TGuiStringPool read FStrings;
    property Assets: TGuiAssets read FAssets;
    property Fonts: TGuiFontRegistry read FFonts;
    property Registry: IGuiAssetRegistry read FRegistry;
  end;

implementation

uses
  DelphiDoom.Gui.ItemParser, DelphiDoom.Gui.MenuParser, DelphiDoom.IdLib.Text.Strings;

constructor TGuiMenuSet.Create(const ARegistry: IGuiAssetRegistry; const AFonts: TGuiFontRegistry;
  const ARandom: IGuiRandom);
begin
  inherited Create;
  FRegistry := ARegistry;
  FFonts := AFonts;
  FRandom := ARandom;
  FMenus := TObjectList<TGuiMenu>.Create(True);
  FStrings := TGuiStringPool.Create;
  FAssets := TGuiAssets.Create;
end;

destructor TGuiMenuSet.Destroy;
begin
  FAssets.Free;
  FStrings.Free;
  FMenus.Free;
  inherited Destroy;
end;

function TGuiMenuSet.AddMenu(const AReader: TGuiValueReader): Boolean;
var
  LMenu: TGuiMenu;
  LItemParser: TGuiItemParser;
  LMenuParser: TGuiMenuParser;
begin
  if FMenus.Count >= GUI_MAX_MENUS then
    Exit(False);
  LMenu := TGuiMenu.Create(FAssets.FadeAmount, FAssets.FadeClamp, FAssets.FadeCycle);
  LItemParser := TGuiItemParser.Create(AReader, FRegistry, FRandom);
  try
    LMenuParser := TGuiMenuParser.Create(AReader, LItemParser, FRegistry, FAssets, FFonts);
    try
      Result := LMenuParser.Parse(LMenu);
    finally
      LMenuParser.Free;
    end;
  finally
    LItemParser.Free;
  end;
  if Result then
  begin
    LMenu.PostParse;
    FMenus.Add(LMenu);
  end
  else
    LMenu.Free;
end;

procedure TGuiMenuSet.Reset;
begin
  FMenus.Clear;
end;

function TGuiMenuSet.Count: Integer;
begin
  Result := FMenus.Count;
end;

function TGuiMenuSet.GetMenu(const AIndex: Integer): TGuiMenu;
begin
  Result := FMenus[AIndex];
end;

function TGuiMenuSet.FindByName(const AName: AnsiString): TGuiMenu;
var
  LMenu: TGuiMenu;
begin
  for LMenu in FMenus do
    if TIdStrings.Icmp(LMenu.Window.Name, AName) = 0 then
      Exit(LMenu);
  Result := nil;
end;

end.
