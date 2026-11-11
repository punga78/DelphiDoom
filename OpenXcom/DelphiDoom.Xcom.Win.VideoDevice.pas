{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the picture in the window with GDI                      }
{  What SDL_Flip did without OpenGL: the picture of 8 bit pixels goes to the    }
{  window with its palette (no conversion to colors)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.VideoDevice;

interface

uses
  Winapi.Windows, System.Types, System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.Xcom.Win.WindowDevice;

type
  /// <summary>
  ///   The display of the game on GDI, the default one and the one used when OpenGL cannot be: the picture is copied
  ///   to the window pixel by pixel, or stretched to the picture rectangle of a full screen window
  /// </summary>
  TXcomWinVideoDevice = class(TXcomWinWindowDevice)
  public
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors); override;
  end;

implementation

procedure TXcomWinVideoDevice.Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
type
  TInfo = record
    Header: TBitmapInfoHeader;
    Colors: array[0..255] of TRGBQuad;
  end;
var
  LInfo: TInfo;
  LDevice: HDC;
  LIndex: Integer;
  LClient: TRect;
  LWhole: TRect;
  LHandle: HWND;
begin
  LHandle := Window.Handle;
  if (LHandle = 0) or (Length(APixels) < AWidth * AHeight) then
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
  LDevice := GetDC(LHandle);
  try
    if Window.PictureRect(LClient) then
    begin
      // the bands beside the picture (nothing erases the background of this window)
      if GetClientRect(LHandle, LWhole) then
      begin
        PatBlt(LDevice, 0, 0, LClient.Left, LWhole.Bottom, BLACKNESS);
        PatBlt(LDevice, LClient.Right, 0, LWhole.Right - LClient.Right, LWhole.Bottom, BLACKNESS);
        PatBlt(LDevice, 0, 0, LWhole.Right, LClient.Top, BLACKNESS);
        PatBlt(LDevice, 0, LClient.Bottom, LWhole.Right, LWhole.Bottom - LClient.Bottom, BLACKNESS);
      end;
      SetStretchBltMode(LDevice, COLORONCOLOR);
      StretchDIBits(LDevice, LClient.Left, LClient.Top, LClient.Right - LClient.Left, LClient.Bottom - LClient.Top,
        0, 0, AWidth, AHeight, @APixels[0], PBitmapInfo(@LInfo)^, DIB_RGB_COLORS, SRCCOPY);
    end
    else
      SetDIBitsToDevice(LDevice, 0, 0, AWidth, AHeight, 0, 0, 0, AHeight, @APixels[0], PBitmapInfo(@LInfo)^,
        DIB_RGB_COLORS);
  finally
    ReleaseDC(LHandle, LDevice);
  end;
end;

end.
