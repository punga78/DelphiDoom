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
  Winapi.Windows, System.Types, System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Win.WindowDevice,
  DelphiDoom.GameHost.TrueColor.Intf;

type
  /// <summary>
  ///   The display of a game on GDI, the default one and the one used when OpenGL cannot be. A picture of the size
  ///   of the mode is copied to the window pixel by pixel; it is stretched to the picture rectangle of a full
  ///   screen window, and to the mode when it has another size (a game that draws small and shows large). A
  ///   picture of colors (IGameHostTrueColorDisplay) goes the same way as a 32 bit bitmap
  /// </summary>
  TGameHostWinGdiVideoDevice = class(TGameHostWinWindowDevice, IGameHostTrueColorDisplay)
  strict private
    procedure Show(AInfo: PBitmapInfo; ABits: Pointer; AWidth, AHeight: Integer);
  public
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TGameHostPalette); override;
    function PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth, AHeight: Integer): Boolean;
  end;

implementation

procedure TGameHostWinGdiVideoDevice.Show(AInfo: PBitmapInfo; ABits: Pointer; AWidth, AHeight: Integer);
var
  LDevice: HDC;
  LOutput: TRect;
  LWhole: TRect;
  LHandle: HWND;
  LFullscreen: Boolean;
begin
  LHandle := Window.Handle;
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
        ABits, AInfo^, DIB_RGB_COLORS, SRCCOPY);
    end
    else
      SetDIBitsToDevice(LDevice, 0, 0, AWidth, AHeight, 0, 0, 0, AHeight, ABits, AInfo^, DIB_RGB_COLORS);
  finally
    ReleaseDC(LHandle, LDevice);
  end;
end;

procedure TGameHostWinGdiVideoDevice.Present(const APixels: TBytes; AWidth, AHeight: Integer;
  const APalette: TGameHostPalette);
type
  TInfo = record
    Header: TBitmapInfoHeader;
    Colors: array[0..255] of TRGBQuad;
  end;
var
  LInfo: TInfo;
  LIndex: Integer;
begin
  if (Window.Handle = 0) or (AWidth < 1) or (AHeight < 1) or (Length(APixels) < AWidth * AHeight) then
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
  Show(PBitmapInfo(@LInfo), @APixels[0], AWidth, AHeight);
end;

function TGameHostWinGdiVideoDevice.PresentTrueColor(const APixels: TGameHostTrueColorPixels; AWidth,
  AHeight: Integer): Boolean;
var
  LInfo: TBitmapInfo;
begin
  Result := (Window.Handle <> 0) and (AWidth > 0) and (AHeight > 0) and (Length(APixels) >= AWidth * AHeight);
  if not Result then
    Exit;
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
  LInfo.bmiHeader.biWidth := AWidth;
  LInfo.bmiHeader.biHeight := -AHeight;
  LInfo.bmiHeader.biPlanes := 1;
  // blue, green, red and an unused byte: the values of the picture as they are
  LInfo.bmiHeader.biBitCount := 32;
  LInfo.bmiHeader.biCompression := BI_RGB;
  Show(@LInfo, @APixels[0], AWidth, AHeight);
end;

end.
