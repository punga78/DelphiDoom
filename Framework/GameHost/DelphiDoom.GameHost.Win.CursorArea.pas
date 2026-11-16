{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the client area of the window on the screen  }
{  For a game that reads the cursor of the system and puts it back in the       }
{  middle of its window                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.CursorArea;

interface

uses
  Winapi.Windows, System.Types, System.SysUtils, DelphiDoom.GameHost.Events.Intf, DelphiDoom.GameHost.Win.Window;

type
  /// <summary>
  ///   IGameHostCursorArea on the window of the game. The window is not owned and must outlive this object; its
  ///   handle is asked at each call, because a display makes it and can throw it away
  /// </summary>
  TGameHostWinCursorArea = class(TInterfacedObject, IGameHostCursorArea)
  strict private
    FWindow: TGameHostWinWindow;
  public
    /// <summary>EArgumentNilException if AWindow is nil</summary>
    constructor Create(AWindow: TGameHostWinWindow);
    function ClientOrigin(out AX, AY: Integer): Boolean;
    function ClientWidth: Integer;
    function ClientHeight: Integer;
    function IsForeground: Boolean;
  end;

implementation

constructor TGameHostWinCursorArea.Create(AWindow: TGameHostWinWindow);
begin
  inherited Create;
  if not Assigned(AWindow) then
    raise EArgumentNilException.Create('AWindow');
  FWindow := AWindow;
end;

function TGameHostWinCursorArea.ClientOrigin(out AX, AY: Integer): Boolean;
var
  LHandle: HWND;
  LPoint: TPoint;
begin
  AX := 0;
  AY := 0;
  LHandle := FWindow.Handle;
  LPoint := Point(0, 0);
  Result := (LHandle <> 0) and ClientToScreen(LHandle, LPoint);
  if Result then
  begin
    AX := LPoint.X;
    AY := LPoint.Y;
  end;
end;

function TGameHostWinCursorArea.ClientWidth: Integer;
begin
  Result := FWindow.State.ClientWidth;
end;

function TGameHostWinCursorArea.ClientHeight: Integer;
begin
  Result := FWindow.State.ClientHeight;
end;

function TGameHostWinCursorArea.IsForeground: Boolean;
var
  LHandle: HWND;
begin
  LHandle := FWindow.Handle;
  Result := (LHandle <> 0) and (GetForegroundWindow = LHandle) and not IsIconic(LHandle);
end;

end.
