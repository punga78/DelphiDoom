{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiDoomFontEx, a font of Doom 3 in three sizes   }
{                                                                              }
{  fontInfoEx_t of renderer\RenderSystem.h (id Software, GPL v3): the small    }
{  (12 points), medium (24) and large (48) fonts, the biggest glyph of each    }
{  and the one of the size in use.                                             }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Font.DoomEx;

interface

uses
  DelphiDoom.Gui.Font.Doom;

type
  /// <summary>
  ///   fontInfoEx_t. <c>MaxHeight</c> and <c>MaxWidth</c> are the values of the size that the device context
  ///   chose last (<c>SetFontByScale</c> writes them, as the original does).
  /// </summary>
  TGuiDoomFontEx = class
  strict private
    FSmall: TGuiDoomFont;
    FMedium: TGuiDoomFont;
    FLarge: TGuiDoomFont;
  public
    MaxHeight: Integer;
    MaxWidth: Integer;
    MaxHeightSmall: Integer;
    MaxWidthSmall: Integer;
    MaxHeightMedium: Integer;
    MaxWidthMedium: Integer;
    MaxHeightLarge: Integer;
    MaxWidthLarge: Integer;
    Name: AnsiString;
    /// <summary>A font of zeros (what a font that fails to load leaves in the list)</summary>
    constructor Create;
    destructor Destroy; override;
    property FontSmall: TGuiDoomFont read FSmall;
    property FontMedium: TGuiDoomFont read FMedium;
    property FontLarge: TGuiDoomFont read FLarge;
  end;

implementation

constructor TGuiDoomFontEx.Create;
begin
  inherited Create;
  FSmall := TGuiDoomFont.Create;
  FMedium := TGuiDoomFont.Create;
  FLarge := TGuiDoomFont.Create;
end;

destructor TGuiDoomFontEx.Destroy;
begin
  FLarge.Free;
  FMedium.Free;
  FSmall.Free;
  inherited Destroy;
end;

end.
