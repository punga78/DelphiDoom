{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - where the picture goes in the window         }
{  Derived from the window of Xcom32 (OpenXcom, the OpenXcom Developers),       }
{  GPL v3 or later: see Libs\XcomFormats\README.md for the license of this unit }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.PictureLayout;

interface

uses
  System.Types, DelphiDoom.GameHost.Types;

type
  /// <summary>
  ///   The geometry of a picture in the client area of its window, without a window: at full screen the picture
  ///   keeps its proportions in the middle of the monitor with black bands around it, in a window it starts at the
  ///   corner with the size of the mode
  /// </summary>
  TGameHostPictureLayout = class
  public
    /// <summary>
    ///   Full screen only: the rectangle of the picture in the client area. False in a window, or when a size is
    ///   not positive
    /// </summary>
    class function PictureRect(const AState: TGameHostWindowState; out ARect: TRect): Boolean; static;
    /// <summary>Where the picture goes: PictureRect, or the size of the mode from the corner</summary>
    class function OutputRect(const AState: TGameHostWindowState): TRect; static;
    /// <summary>
    ///   A point of the client area as a point of the picture: itself in a window, brought back from the stretched
    ///   picture at full screen
    /// </summary>
    class function ToPicture(const AState: TGameHostWindowState; AX, AY: Integer): TPoint; static;
  end;

implementation

uses
  Winapi.Windows;

class function TGameHostPictureLayout.PictureRect(const AState: TGameHostWindowState; out ARect: TRect): Boolean;
var
  LWidth: Integer;
  LHeight: Integer;
begin
  ARect := Rect(0, 0, 0, 0);
  Result := AState.Fullscreen and (AState.Width > 0) and (AState.Height > 0) and (AState.ClientWidth > 0) and
    (AState.ClientHeight > 0);
  if not Result then
    Exit;
  LWidth := AState.ClientWidth;
  LHeight := MulDiv(LWidth, AState.Height, AState.Width);
  if LHeight > AState.ClientHeight then
  begin
    LHeight := AState.ClientHeight;
    LWidth := MulDiv(LHeight, AState.Width, AState.Height);
  end;
  ARect.Left := (AState.ClientWidth - LWidth) div 2;
  ARect.Top := (AState.ClientHeight - LHeight) div 2;
  ARect.Right := ARect.Left + LWidth;
  ARect.Bottom := ARect.Top + LHeight;
end;

class function TGameHostPictureLayout.OutputRect(const AState: TGameHostWindowState): TRect;
begin
  if not PictureRect(AState, Result) then
    Result := Rect(0, 0, AState.Width, AState.Height);
end;

class function TGameHostPictureLayout.ToPicture(const AState: TGameHostWindowState; AX, AY: Integer): TPoint;
var
  LPicture: TRect;
begin
  Result := Point(AX, AY);
  if not PictureRect(AState, LPicture) then
    Exit;
  Result.X := MulDiv(AX - LPicture.Left, AState.Width, LPicture.Right - LPicture.Left);
  Result.Y := MulDiv(AY - LPicture.Top, AState.Height, LPicture.Bottom - LPicture.Top);
end;

end.
