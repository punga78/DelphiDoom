{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the assets of the menus (cachedAssets_t)          }
{                                                                              }
{  The part of cachedAssets_t of ui_shared.h that the reading of menus uses    }
{  or sets (Quake III Arena, id Software, GPL v2 or later). Based on the       }
{  Quake III Arena GPL Source Code (id Software).                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Assets;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Font;

type
  /// <summary>The fonts, sounds, handles and fade values that "assetGlobalDef" sets and that menus start from</summary>
  TGuiAssets = class
  strict private
    FTextFont: TGuiFont;
    FSmallFont: TGuiFont;
    FBigFont: TGuiFont;
  public
    CursorStr: AnsiString;
    Cursor: Integer;
    GradientBar: Integer;
    MenuEnterSound: Integer;
    MenuExitSound: Integer;
    MenuBuzzSound: Integer;
    ItemFocusSound: Integer;
    FadeClamp: Single;
    FadeCycle: Integer;
    FadeAmount: Single;
    ShadowX: Single;
    ShadowY: Single;
    ShadowColor: TGuiColor;
    ShadowFadeClamp: Single;
    /// <summary>A menu "font" keyword registers the text font once, if no asset block did it</summary>
    FontRegistered: Boolean;
    constructor Create;
    destructor Destroy; override;
    property TextFont: TGuiFont read FTextFont;
    property SmallFont: TGuiFont read FSmallFont;
    property BigFont: TGuiFont read FBigFont;
  end;

implementation

constructor TGuiAssets.Create;
begin
  inherited Create;
  FTextFont := TGuiFont.Create;
  FSmallFont := TGuiFont.Create;
  FBigFont := TGuiFont.Create;
end;

destructor TGuiAssets.Destroy;
begin
  FBigFont.Free;
  FSmallFont.Free;
  FTextFont.Free;
  inherited Destroy;
end;

end.
