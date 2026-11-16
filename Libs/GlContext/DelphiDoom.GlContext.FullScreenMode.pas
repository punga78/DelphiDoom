{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL context - the screen mode of the full screen window      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlContext.FullScreenMode;

interface

uses
  Winapi.Windows;

type
  /// <summary>The screen mode asked to Windows when an OpenGL game goes full screen</summary>
  TGlFullScreenMode = class sealed
  public
    /// <summary>
    ///   Fills the structure for ChangeDisplaySettings: the size of the game screen at 32 bits per pixel, and
    ///   only the width, the height and the colour depth as valid fields
    /// </summary>
    class procedure Describe(const AWidth, AHeight: Integer; out AMode: DEVMODE); static;
  end;

implementation

{ TGlFullScreenMode }

class procedure TGlFullScreenMode.Describe(const AWidth, AHeight: Integer; out AMode: DEVMODE);
begin
  ZeroMemory(@AMode, SizeOf(AMode));
  AMode.dmSize := SizeOf(AMode);
  AMode.dmPelsWidth := AWidth;
  AMode.dmPelsHeight := AHeight;
  AMode.dmBitsPerPel := 32;
  AMode.dmFields := DM_PELSWIDTH or DM_PELSHEIGHT or DM_BITSPERPEL;
end;

end.
