{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the picture in the window with GDI          }
{  What SDL_Flip did without OpenGL: the picture of 8 bit pixels goes to the    }
{  window with its palette (no conversion to colors)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.GdiVideoDevice;

interface

uses
  Winapi.Windows, System.Types, System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Win.WindowDevice;

type
  /// <summary>
  ///   The display of a game on GDI, the default one and the one used when OpenGL cannot be. A picture of the size
  ///   of the mode is copied to the window pixel by pixel; it is stretched to the picture rectangle of a full
  ///   screen window, and to the mode when it has another size (a game that draws small and shows large)
  /// </summary>
  TGameHostWinGdiVideoDevice = class(TGameHostWinWindowDevice)
  public
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette); override;
  end;

implementation

procedure TGameHostWinGdiVideoDevice.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
type
  TInfo = record
    Header: TBitmapInfoHeader;
    Colors: array[0..255] of TRGBQuad;
  end;
var
  LInfo: TInfo;
  LDevice: HDC;
  LIndex: Integer;
  LOutput: TRect;
  LWhole: TRect;
  LHandle: HWND;
  LFullscreen: Boolean;
begin
  LHandle := Window.Handle;
  if (LHandle = 0) or (AWidth < 1) or (AHeight < 1) or (Length(APixels) < AWidth * AHeight) then
    Exit;
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.Header.biSize := SizeOf(LInfo.Header);
  LInfo.Header.biWidth := AWidth;
  // a negative height: the rows go from the top, as in the pictures of the game
  LInfo.Header.biHeight := -AHeight;
  LInfo.Header.biPlanes := 1;
  LInfo.Header.biBitCount := 8;
  LInfo.Header.biCompression := BI_RGB;
  LInfo.Header.biClrUsed := 256;
  for LIndex := 0 to 255 do
  begin
    LInfo.Colors[LIndex].rgbRed := APalette[LIndex].Red;
    LInfo.Colors[LIndex].rgbGreen := APalette[LIndex].Green;
    LInfo.Colors[LIndex].rgbBlue := APalette[LIndex].Blue;
  end;
  LFullscreen := Window.PictureRect(LOutput);
  if not LFullscreen then
    LOutput := Window.OutputRect;
  LDevice := GetDC(LHandle);
  try
    // the bands beside the picture (nothing erases the background of this window)
    if LFullscreen and GetClientRect(LHandle, LWhole) then
    begin
      PatBlt(LDevice, 0, 0, LOutput.Left, LWhole.Bottom, BLACKNESS);
      PatBlt(LDevice, LOutput.Right, 0, LWhole.Right - LOutput.Right, LWhole.Bottom, BLACKNESS);
      PatBlt(LDevice, 0, 0, LWhole.Right, LOutput.Top, BLACKNESS);
      PatBlt(LDevice, 0, LOutput.Bottom, LWhole.Right, LWhole.Bottom - LOutput.Bottom, BLACKNESS);
    end;
    if LFullscreen or (LOutput.Width <> AWidth) or (LOutput.Height <> AHeight) then
    begin
      SetStretchBltMode(LDevice, COLORONCOLOR);
      StretchDIBits(LDevice, LOutput.Left, LOutput.Top, LOutput.Width, LOutput.Height, 0, 0, AWidth, AHeight,
        @APixels[0], PBitmapInfo(@LInfo)^, DIB_RGB_COLORS, SRCCOPY);
    end
    else
      SetDIBitsToDevice(LDevice, 0, 0, AWidth, AHeight, 0, 0, 0, AHeight, @APixels[0], PBitmapInfo(@LInfo)^,
        DIB_RGB_COLORS);
  finally
    ReleaseDC(LHandle, LDevice);
  end;
end;

end.
