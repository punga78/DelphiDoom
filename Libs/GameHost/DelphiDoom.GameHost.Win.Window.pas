{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the window of Windows                        }
{  What SDL_SetVideoMode and the SDL event loop did: the window, its style and  }
{  size, and its messages turned into events of the game. What draws in it      }
{  (GDI or OpenGL) is a device that receives this window                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Win.Window;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.MultiMon, System.Types, System.SysUtils, DelphiDoom.GameHost.Types,
  DelphiDoom.GameHost.Win.MessageTranslator;

type
  /// <summary>
  ///   The window of a game. The window procedure gives the keyboard and mouse messages to the translator, which
  ///   posts them as events; the system cursor can be hidden over the window for a game that draws its own. The
  ///   handle is made by the first SetMode and can be thrown away (DestroyHandle) to be made again by the next one:
  ///   a window that had an OpenGL pixel format cannot go back to GDI. Everything is done by the thread that
  ///   created it
  /// </summary>
  TGameHostWinWindow = class
  strict private
    FHandle: HWND;
    FTranslator: TGameHostWinMessageTranslator;
    FTitle: string;
    FWidth: Integer;
    FHeight: Integer;
    FClosed: Boolean;
    FFullscreen: Boolean;
    FBorderless: Boolean;
    FResizable: Boolean;
    FSettingMode: Boolean;
    FHideCursor: Boolean;
    FHasPosition: Boolean;
    FPosition: TPoint;
    FPlacementFixed: Boolean;
    FPlacementCentered: Boolean;
    FPlacement: TPoint;
    function PlacementPosition(AWindowWidth, AWindowHeight: Integer; out APosition: TPoint): Boolean;
    class var FClassRegistered: Boolean;
    class function WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall; static;
    class procedure RegisterWindowClass; static;
    function HandleMessage(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM; out AResult: LRESULT): Boolean;
    procedure CreateWindowHandle;
    procedure ApplyWindowStyle;
    function WindowStyle: DWORD;
  public
    /// <param name="ATranslator">Turns the messages into events; owned (freed with the window)</param>
    /// <param name="AHideCursor">The system cursor is not shown over the client area (the game draws its own)</param>
    constructor Create(const ATitle: string; ATranslator: TGameHostWinMessageTranslator; AHideCursor: Boolean);
    destructor Destroy; override;
    /// <summary>Without a frame, or with a border the player can drag: taken at the next SetMode</summary>
    procedure SetStyle(ABorderless, AResizable: Boolean);
    /// <summary>
    ///   Taken at the next SetMode: AFixed puts the corner of the window at (AX, AY) (ignored when no monitor shows
    ///   that point: the window would be out of reach), ACentered puts it in the middle of the work area; neither
    ///   leaves it where it is
    /// </summary>
    procedure SetPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
    /// <summary>
    ///   Makes the window if there is none and gives it the size of the picture; full screen is a window without
    ///   borders over the whole monitor (the display mode of the system is not changed)
    /// </summary>
    procedure SetMode(AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure SetTitle(const ATitle: string);
    /// <summary>The mode, the client area and what the window is doing, now</summary>
    function State: TGameHostWindowState;
    /// <summary>
    ///   Full screen only: where the picture goes in the client area, with its proportions kept in the middle of the
    ///   monitor and black bands around it. False in a window (the picture is the client area)
    /// </summary>
    function PictureRect(out ARect: TRect): Boolean;
    /// <summary>Where the picture goes in the client area: PictureRect, or the size of the mode from the corner</summary>
    function OutputRect: TRect;
    /// <summary>Destroys the handle and keeps the place of the window: the next SetMode makes a new one there</summary>
    procedure DestroyHandle;
    /// <summary>Reads the messages of the window, which become events; false once the window has been closed</summary>
    function Pump: Boolean;
    /// <summary>0 before the first SetMode and after DestroyHandle</summary>
    property Handle: HWND read FHandle;
  end;

implementation

uses
  DelphiDoom.GameHost.PictureLayout;

const
  WINDOW_CLASS = 'DelphiDoomGameHostWindow';

function TGameHostWinWindow.State: TGameHostWindowState;
var
  LClient: TRect;
begin
  Result := Default(TGameHostWindowState);
  Result.Width := FWidth;
  Result.Height := FHeight;
  Result.Fullscreen := FFullscreen;
  Result.Resizable := FResizable;
  Result.SettingMode := FSettingMode;
  if (FHandle <> 0) and GetClientRect(FHandle, LClient) then
  begin
    Result.ClientWidth := LClient.Right;
    Result.ClientHeight := LClient.Bottom;
  end;
end;

function TGameHostWinWindow.PictureRect(out ARect: TRect): Boolean;
begin
  Result := TGameHostPictureLayout.PictureRect(State, ARect);
end;

function TGameHostWinWindow.OutputRect: TRect;
begin
  Result := TGameHostPictureLayout.OutputRect(State);
end;

function TGameHostWinWindow.WindowStyle: DWORD;
begin
  if FBorderless then
    Result := WS_POPUP
  else
  begin
    Result := WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX;
    if FResizable then
      Result := Result or WS_THICKFRAME or WS_MAXIMIZEBOX;
  end;
end;

procedure TGameHostWinWindow.SetStyle(ABorderless, AResizable: Boolean);
begin
  FBorderless := ABorderless;
  FResizable := AResizable;
end;

procedure TGameHostWinWindow.SetPlacement(AFixed: Boolean; AX, AY: Integer; ACentered: Boolean);
begin
  FPlacementFixed := AFixed;
  FPlacement := Point(AX, AY);
  FPlacementCentered := ACentered;
end;

function TGameHostWinWindow.PlacementPosition(AWindowWidth, AWindowHeight: Integer; out APosition: TPoint): Boolean;
const
  // a point of the title bar that must be on a monitor for the window to be reachable
  GRIP_X = 32;
  GRIP_Y = 8;
var
  LWork: TRect;
begin
  Result := False;
  APosition := Point(0, 0);
  if FPlacementFixed then
  begin
    APosition := FPlacement;
    Result := MonitorFromPoint(Point(FPlacement.X + GRIP_X, FPlacement.Y + GRIP_Y), MONITOR_DEFAULTTONULL) <> 0;
  end
  else if FPlacementCentered and SystemParametersInfo(SPI_GETWORKAREA, 0, @LWork, 0) then
  begin
    APosition.X := LWork.Left + ((LWork.Right - LWork.Left) - AWindowWidth) div 2;
    APosition.Y := LWork.Top + ((LWork.Bottom - LWork.Top) - AWindowHeight) div 2;
    Result := True;
  end;
end;

procedure TGameHostWinWindow.ApplyWindowStyle;
var
  LRect: TRect;
  LMonitor: TMonitorInfo;
  LPlace: TPoint;
begin
  if FFullscreen then
  begin
    // a window without borders over the whole monitor: the display mode of the system is not changed
    LMonitor.cbSize := SizeOf(LMonitor);
    GetMonitorInfo(MonitorFromWindow(FHandle, MONITOR_DEFAULTTONEAREST), @LMonitor);
    SetWindowLongPtr(FHandle, GWL_STYLE, LONG_PTR(WS_POPUP or WS_VISIBLE));
    SetWindowPos(FHandle, HWND_TOP, LMonitor.rcMonitor.Left, LMonitor.rcMonitor.Top,
      LMonitor.rcMonitor.Right - LMonitor.rcMonitor.Left, LMonitor.rcMonitor.Bottom - LMonitor.rcMonitor.Top,
      SWP_FRAMECHANGED);
  end
  else
  begin
    SetWindowLongPtr(FHandle, GWL_STYLE, LONG_PTR(WindowStyle or WS_VISIBLE));
    LRect := Rect(0, 0, FWidth, FHeight);
    AdjustWindowRect(LRect, WindowStyle, False);
    if PlacementPosition(LRect.Right - LRect.Left, LRect.Bottom - LRect.Top, LPlace) then
      SetWindowPos(FHandle, 0, LPlace.X, LPlace.Y, LRect.Right - LRect.Left, LRect.Bottom - LRect.Top,
        SWP_NOZORDER or SWP_FRAMECHANGED)
    else
      SetWindowPos(FHandle, 0, 0, 0, LRect.Right - LRect.Left, LRect.Bottom - LRect.Top,
        SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED);
  end;
end;

function TGameHostWinWindow.HandleMessage(AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM;
  out AResult: LRESULT): Boolean;
begin
  AResult := 0;
  case AMessage of
    WM_LBUTTONDOWN:
      // the release is seen also when the mouse leaves the window with the button down
      SetCapture(FHandle);
    WM_LBUTTONUP:
      ReleaseCapture;
    WM_SETCURSOR:
      if FHideCursor and (LoWord(ALParam) = HTCLIENT) then
      begin
        SetCursor(0);
        AResult := 1;
        Exit(True);
      end;
    WM_CLOSE:
      FClosed := True;
    WM_ERASEBKGND:
      begin
        // the picture covers the client area: nothing to erase
        AResult := 1;
        Exit(True);
      end;
  end;
  Result := FTranslator.Translate(AMessage, AWParam, ALParam, State, AResult);
end;

class function TGameHostWinWindow.WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT;
var
  LSelf: TGameHostWinWindow;
begin
  LSelf := TGameHostWinWindow(GetWindowLongPtr(AWindow, GWLP_USERDATA));
  if Assigned(LSelf) and LSelf.HandleMessage(AMessage, AWParam, ALParam, Result) then
    Exit;
  Result := DefWindowProc(AWindow, AMessage, AWParam, ALParam);
end;

class procedure TGameHostWinWindow.RegisterWindowClass;
var
  LClass: TWndClass;
begin
  if FClassRegistered then
    Exit;
  FillChar(LClass, SizeOf(LClass), 0);
  // a device context of its own: an OpenGL context stays bound to it for the life of the window
  LClass.style := CS_OWNDC;
  LClass.lpfnWndProc := @TGameHostWinWindow.WindowProc;
  LClass.hInstance := HInstance;
  LClass.hCursor := LoadCursor(0, IDC_ARROW);
  LClass.lpszClassName := WINDOW_CLASS;
  if Winapi.Windows.RegisterClass(LClass) = 0 then
    RaiseLastOSError;
  FClassRegistered := True;
end;

constructor TGameHostWinWindow.Create(const ATitle: string; ATranslator: TGameHostWinMessageTranslator;
  AHideCursor: Boolean);
begin
  // the translator is owned from here on, also when the construction fails
  FTranslator := ATranslator;
  inherited Create;
  if not Assigned(ATranslator) then
    raise EArgumentNilException.Create('ATranslator');
  FTitle := ATitle;
  FHideCursor := AHideCursor;
end;

destructor TGameHostWinWindow.Destroy;
begin
  DestroyHandle;
  FTranslator.Free;
  inherited Destroy;
end;

procedure TGameHostWinWindow.DestroyHandle;
var
  LRect: TRect;
begin
  if FHandle = 0 then
    Exit;
  // the place of a full screen window is the monitor: the one it had before, if any, is kept
  if (not FFullscreen) and GetWindowRect(FHandle, LRect) then
  begin
    FPosition := LRect.TopLeft;
    FHasPosition := True;
  end;
  // no events from a window that is going away (it loses the focus while it is destroyed)
  SetWindowLongPtr(FHandle, GWLP_USERDATA, 0);
  DestroyWindow(FHandle);
  FHandle := 0;
  FFullscreen := False;
end;

procedure TGameHostWinWindow.CreateWindowHandle;
var
  LRect: TRect;
  LStyle: DWORD;
  LLeft: Integer;
  LTop: Integer;
  LPlace: TPoint;
begin
  RegisterWindowClass;
  LStyle := WindowStyle;
  LRect := Rect(0, 0, FWidth, FHeight);
  AdjustWindowRect(LRect, LStyle, False);
  LLeft := Integer(CW_USEDEFAULT);
  LTop := Integer(CW_USEDEFAULT);
  if PlacementPosition(LRect.Right - LRect.Left, LRect.Bottom - LRect.Top, LPlace) then
  begin
    LLeft := LPlace.X;
    LTop := LPlace.Y;
  end
  else if FHasPosition then
  begin
    LLeft := FPosition.X;
    LTop := FPosition.Y;
  end;
  FHandle := CreateWindow(WINDOW_CLASS, PChar(FTitle), LStyle, LLeft, LTop, LRect.Right - LRect.Left,
    LRect.Bottom - LRect.Top, 0, 0, HInstance, nil);
  if FHandle = 0 then
    RaiseLastOSError;
  SetWindowLongPtr(FHandle, GWLP_USERDATA, LONG_PTR(Self));
  ShowWindow(FHandle, SW_SHOWNORMAL);
  UpdateWindow(FHandle);
end;

procedure TGameHostWinWindow.SetMode(AWidth, AHeight: Integer; AFullscreen: Boolean);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  // the sizes the window takes here are not a resize of the player
  FSettingMode := True;
  try
    if FHandle = 0 then
    begin
      FFullscreen := False;
      CreateWindowHandle;
      if not AFullscreen then
        Exit;
    end;
    FFullscreen := AFullscreen;
    ApplyWindowStyle;
  finally
    FSettingMode := False;
  end;
end;

procedure TGameHostWinWindow.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
  if FHandle <> 0 then
    SetWindowText(FHandle, PChar(ATitle));
end;

function TGameHostWinWindow.Pump: Boolean;
var
  LMessage: TMsg;
begin
  while PeekMessage(LMessage, 0, 0, 0, PM_REMOVE) do
  begin
    if LMessage.message = WM_QUIT then
      FClosed := True;
    TranslateMessage(LMessage);
    DispatchMessage(LMessage);
  end;
  Result := not FClosed;
end;

end.
