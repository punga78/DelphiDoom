{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - a picture of colors to a device context     }
{  The GDI step of the displays of the library, for a game that owns its own    }
{  window (the engine of Doom): a picture in memory, no copy                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.GdiBlitter;

interface

uses
  Winapi.Windows, System.Types;

type
  /// <summary>
  ///   Draws a picture of 32 bit colors that is already in memory (blue in the low byte of each pixel, rows from the
  ///   top, no padding between the rows) into a device context. The pixels are read where they are: nothing is
  ///   copied. One call per picture
  /// </summary>
  TGameHostWinGdiBlitter = class
  public
    /// <summary>
    ///   Draws AWidth x AHeight pixels at ADestination of ADevice. A destination of the same size is copied pixel by
    ///   pixel, any other is stretched taking the nearest pixel (no filter). False when there is nothing to draw
    /// </summary>
    class function Draw(ADevice: HDC; ABits: Pointer; AWidth, AHeight: Integer; const ADestination: TRect): Boolean;
      static;
  end;

implementation

{ TGameHostWinGdiBlitter }

class function TGameHostWinGdiBlitter.Draw(ADevice: HDC; ABits: Pointer; AWidth, AHeight: Integer;
  const ADestination: TRect): Boolean;
var
  LInfo: TBitmapInfo;
begin
  Result := (ADevice <> 0) and Assigned(ABits) and (AWidth > 0) and (AHeight > 0) and
    (ADestination.Width > 0) and (ADestination.Height > 0);
  if not Result then
    Exit;
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
  LInfo.bmiHeader.biWidth := AWidth;
  // a negative height: the rows go from the top
  LInfo.bmiHeader.biHeight := -AHeight;
  LInfo.bmiHeader.biPlanes := 1;
  LInfo.bmiHeader.biBitCount := 32;
  LInfo.bmiHeader.biCompression := BI_RGB;
  if (ADestination.Width = AWidth) and (ADestination.Height = AHeight) then
    SetDIBitsToDevice(ADevice, ADestination.Left, ADestination.Top, AWidth, AHeight, 0, 0, 0, AHeight, ABits,
      LInfo, DIB_RGB_COLORS)
  else
  begin
    SetStretchBltMode(ADevice, COLORONCOLOR);
    StretchDIBits(ADevice, ADestination.Left, ADestination.Top, ADestination.Width, ADestination.Height, 0, 0,
      AWidth, AHeight, ABits, LInfo, DIB_RGB_COLORS, SRCCOPY);
  end;
end;

end.
