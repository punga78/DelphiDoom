{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the window of Windows                                  }
{  What SDL_SetVideoMode and the SDL event loop did: the window, its style and  }
{  size, and its messages turned into events of the game. What draws in it      }
{  (GDI or OpenGL) is a device that receives this window                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.Window;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.MultiMon, System.Types, System.SysUtils, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.QueueEventSource;

type
  /// <summary>
  ///   The window of the game. The window procedure puts the keyboard and mouse messages in the queue of events that
  ///   it is given (SDL 1.2 key codes and button numbers); the system cursor is hidden over the window because the
  ///   game draws its own. The handle is made by the first SetMode and can be thrown away (DestroyHandle) to be made
  ///   again by the next one: a window that had an OpenGL pixel format cannot go back to GDI. Everything is done by
  ///   the thread that created it
  /// </summary>
  TXcomWinWindow = class
  strict private
    FHandle: HWND;
    FEvents: TXcomQueueEventSource;
    FTitle: string;
    FWidth: Integer;
    FHeight: Integer;
    FClosed: Boolean;
    FFullscreen: Boolean;
    FBorderless: Boolean;
    FResizable: Boolean;
    FSettingMode: Boolean;
    FHasPosition: Boolean;
    FPosition: TPoint;
    class var FClassRegistered: Boolean;
    class function WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall; static;
    class procedure RegisterWindowClass; static;
    class function KeyOf(AVirtualKey: WPARAM): Integer; static;
    procedure Post(AKind: TXcomEventKind; AKey, AButton: Integer; ALParam: LPARAM; ACharacter: Cardinal = 0);
    procedure CreateWindowHandle;
    function Modifiers: Integer;
    function CharacterOf(AVirtualKey: WPARAM; ALParam: LPARAM): Cardinal;
    function ScalePoint(ALParam: LPARAM): LPARAM;
    procedure ApplyWindowStyle;
    function WindowStyle: DWORD;
    procedure PostResize(AWidth, AHeight: Integer);
  public
    /// <param name="AEvents">Where the events go; not owned</param>
    constructor Create(const ATitle: string; AEvents: TXcomQueueEventSource);
    destructor Destroy; override;
    /// <summary>SDL_NOFRAME and SDL_RESIZABLE: taken at the next SetMode</summary>
    procedure SetStyle(ABorderless, AResizable: Boolean);
    /// <summary>
    ///   Makes the window if there is none and gives it the size of the picture; full screen is a window without
    ///   borders over the whole monitor (the display mode of the system is not changed)
    /// </summary>
    procedure SetMode(AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure SetTitle(const ATitle: string);
    /// <summary>
    ///   Full screen only: where the picture goes in the client area, with its proportions kept in the middle of the
    ///   monitor and black bands around it. False in a window (the picture is the client area)
    /// </summary>
    function PictureRect(out ARect: TRect): Boolean;
    /// <summary>Where the picture goes in the client area: PictureRect, or the size of the mode from the corner</summary>
    function OutputRect: TRect;
    /// <summary>Destroys the handle and keeps the place of the window: the next SetMode makes a new one there</summary>
    procedure DestroyHandle;
    /// <summary>Reads the messages of the window into the queue of events; false once the window has been closed</summary>
    function Pump: Boolean;
    /// <summary>0 before the first SetMode and after DestroyHandle</summary>
    property Handle: HWND read FHandle;
  end;

implementation

const
  WINDOW_CLASS = 'DelphiDoomXcomWindow';

class function TXcomWinWindow.KeyOf(AVirtualKey: WPARAM): Integer;
begin
  // SDLK of SDL 1.2: letters are the lower case ASCII, the function keys 282 on
  case AVirtualKey of
    VK_BACK: Result := 8;
    VK_TAB: Result := 9;
    VK_RETURN: Result := 13;
    VK_ESCAPE: Result := 27;
    VK_SPACE: Result := 32;
    VK_DELETE: Result := 127;
    VK_UP: Result := 273;
    VK_DOWN: Result := 274;
    VK_RIGHT: Result := 275;
    VK_LEFT: Result := 276;
    VK_INSERT: Result := 277;
    VK_HOME: Result := 278;
    VK_END: Result := 279;
    VK_PRIOR: Result := 280;
    VK_NEXT: Result := 281;
    VK_F1..VK_F12: Result := 282 + Integer(AVirtualKey) - VK_F1;
    Ord('0')..Ord('9'): Result := Integer(AVirtualKey);
    Ord('A')..Ord('Z'): Result := Integer(AVirtualKey) + 32;
  else
    Result := 0;
  end;
end;

function TXcomWinWindow.Modifiers: Integer;
begin
  Result := 0;
  if GetKeyState(VK_SHIFT) < 0 then
    Result := Result or XCOM_KMOD_SHIFT;
  if GetKeyState(VK_CONTROL) < 0 then
    Result := Result or XCOM_KMOD_CTRL;
  if GetKeyState(VK_MENU) < 0 then
    Result := Result or XCOM_KMOD_ALT;
end;

function TXcomWinWindow.CharacterOf(AVirtualKey: WPARAM; ALParam: LPARAM): Cardinal;
var
  LState: TKeyboardState;
  LBuffer: array[0..3] of WideChar;
begin
  // the unicode field of the key event of SDL 1.2: what the key types with the current layout and shift state
  Result := 0;
  if not GetKeyboardState(LState) then
    Exit;
  if ToUnicode(UINT(AVirtualKey), (UINT(ALParam) shr 16) and $FF, LState, LBuffer, Length(LBuffer), 0) = 1 then
    if Ord(LBuffer[0]) >= 32 then
      Result := Ord(LBuffer[0]);
end;

function TXcomWinWindow.PictureRect(out ARect: TRect): Boolean;
var
  LClient: TRect;
  LWidth: Integer;
  LHeight: Integer;
begin
  // full screen: the picture keeps its proportions in the middle of the monitor, black bands around it
  Result := FFullscreen and (FHandle <> 0) and (FWidth > 0) and (FHeight > 0) and GetClientRect(FHandle, LClient) and
    (LClient.Right > 0) and (LClient.Bottom > 0);
  if not Result then
    Exit;
  LWidth := LClient.Right;
  LHeight := MulDiv(LWidth, FHeight, FWidth);
  if LHeight > LClient.Bottom then
  begin
    LHeight := LClient.Bottom;
    LWidth := MulDiv(LHeight, FWidth, FHeight);
  end;
  ARect.Left := (LClient.Right - LWidth) div 2;
  ARect.Top := (LClient.Bottom - LHeight) div 2;
  ARect.Right := ARect.Left + LWidth;
  ARect.Bottom := ARect.Top + LHeight;
end;

function TXcomWinWindow.OutputRect: TRect;
begin
  if not PictureRect(Result) then
    Result := Rect(0, 0, FWidth, FHeight);
end;

function TXcomWinWindow.ScalePoint(ALParam: LPARAM): LPARAM;
var
  LPicture: TRect;
  LX: Integer;
  LY: Integer;
begin
  // full screen: the picture is stretched, the game wants the position in the picture
  Result := ALParam;
  if not PictureRect(LPicture) then
    Exit;
  LX := MulDiv(SmallInt(LoWord(ALParam)) - LPicture.Left, FWidth, LPicture.Right - LPicture.Left);
  LY := MulDiv(SmallInt(HiWord(ALParam)) - LPicture.Top, FHeight, LPicture.Bottom - LPicture.Top);
  Result := MakeLParam(Word(LX), Word(LY));
end;

function TXcomWinWindow.WindowStyle: DWORD;
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

procedure TXcomWinWindow.SetStyle(ABorderless, AResizable: Boolean);
begin
  FBorderless := ABorderless;
  FResizable := AResizable;
end;

procedure TXcomWinWindow.PostResize(AWidth, AHeight: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekResize);
  LEvent.X := AWidth;
  LEvent.Y := AHeight;
  FEvents.Enqueue(LEvent);
end;

procedure TXcomWinWindow.ApplyWindowStyle;
var
  LRect: TRect;
  LMonitor: TMonitorInfo;
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
    SetWindowPos(FHandle, 0, 0, 0, LRect.Right - LRect.Left, LRect.Bottom - LRect.Top,
      SWP_NOMOVE or SWP_NOZORDER or SWP_FRAMECHANGED);
  end;
end;

procedure TXcomWinWindow.Post(AKind: TXcomEventKind; AKey, AButton: Integer; ALParam: LPARAM;
  ACharacter: Cardinal);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(AKind);
  LEvent.Key := AKey;
  LEvent.Button := AButton;
  LEvent.Character := ACharacter;
  LEvent.Modifiers := Modifiers;
  if AKind in [ekMouseMotion, ekMouseDown, ekMouseUp] then
  begin
    ALParam := ScalePoint(ALParam);
    LEvent.X := SmallInt(LoWord(ALParam));
    LEvent.Y := SmallInt(HiWord(ALParam));
  end;
  FEvents.SetModifiers(LEvent.Modifiers);
  FEvents.Enqueue(LEvent);
end;

class function TXcomWinWindow.WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT;
var
  LSelf: TXcomWinWindow;
  LKey: Integer;
  LWheelX: Integer;
  LWheelY: Integer;
  LCharacter: Cardinal;
begin
  LSelf := TXcomWinWindow(GetWindowLongPtr(AWindow, GWLP_USERDATA));
  if Assigned(LSelf) then
    case AMessage of
      WM_KEYDOWN, WM_SYSKEYDOWN:
        begin
          LKey := KeyOf(AWParam);
          LCharacter := LSelf.CharacterOf(AWParam, ALParam);
          // SDL 1.2: the key of a printable character without a name of its own is its lower case ASCII code
          if (LKey = 0) and (LCharacter >= 32) and (LCharacter < 127) then
            LKey := Ord(LowerCase(string(Char(LCharacter)))[1]);
          if (LKey <> 0) or (LCharacter <> 0) then
            LSelf.Post(ekKeyDown, LKey, 0, 0, LCharacter);
          if AMessage = WM_KEYDOWN then
            Exit(0);
        end;
      WM_KEYUP, WM_SYSKEYUP:
        begin
          LKey := KeyOf(AWParam);
          if LKey <> 0 then
            LSelf.Post(ekKeyUp, LKey, 0, 0);
          if AMessage = WM_KEYUP then
            Exit(0);
        end;
      WM_MOUSEMOVE:
        begin
          LSelf.Post(ekMouseMotion, 0, 0, ALParam);
          Exit(0);
        end;
      WM_LBUTTONDOWN:
        begin
          SetCapture(AWindow);
          LSelf.Post(ekMouseDown, 0, XCOM_BUTTON_LEFT, ALParam);
          Exit(0);
        end;
      WM_LBUTTONUP:
        begin
          ReleaseCapture;
          LSelf.Post(ekMouseUp, 0, XCOM_BUTTON_LEFT, ALParam);
          Exit(0);
        end;
      WM_MBUTTONDOWN:
        begin
          LSelf.Post(ekMouseDown, 0, XCOM_BUTTON_MIDDLE, ALParam);
          Exit(0);
        end;
      WM_MBUTTONUP:
        begin
          LSelf.Post(ekMouseUp, 0, XCOM_BUTTON_MIDDLE, ALParam);
          Exit(0);
        end;
      WM_RBUTTONDOWN:
        begin
          LSelf.Post(ekMouseDown, 0, XCOM_BUTTON_RIGHT, ALParam);
          Exit(0);
        end;
      WM_RBUTTONUP:
        begin
          LSelf.Post(ekMouseUp, 0, XCOM_BUTTON_RIGHT, ALParam);
          Exit(0);
        end;
      WM_MOUSEWHEEL:
        begin
          // the wheel position is in screen coordinates: the position of the last motion is kept
          if SmallInt(HiWord(AWParam)) > 0 then
            LKey := XCOM_BUTTON_WHEELUP
          else
            LKey := XCOM_BUTTON_WHEELDOWN;
          LSelf.FEvents.MouseState(LWheelX, LWheelY);
          LSelf.Post(ekMouseDown, 0, LKey, MakeLParam(LWheelX, LWheelY));
          LSelf.Post(ekMouseUp, 0, LKey, MakeLParam(LWheelX, LWheelY));
          Exit(0);
        end;
      WM_SETCURSOR:
        if LoWord(ALParam) = HTCLIENT then
        begin
          SetCursor(0);
          Exit(1);
        end;
      WM_ACTIVATE:
        // the window gets or loses the focus, or is minimized (SDL_ACTIVEEVENT): Key is 1 with the focus
        LSelf.Post(ekActive, Ord((LoWord(AWParam) <> WA_INACTIVE) and (HiWord(AWParam) = 0)), 0, 0);
      WM_CLOSE:
        begin
          LSelf.FClosed := True;
          LSelf.Post(ekQuit, 0, 0, 0);
          Exit(0);
        end;
      WM_SIZE:
        // the player has dragged the border (SDL_VIDEORESIZE): not the sizes the game itself asks for
        if LSelf.FResizable and (not LSelf.FFullscreen) and (not LSelf.FSettingMode) and (AWParam <> SIZE_MINIMIZED) and
          ((LoWord(ALParam) <> LSelf.FWidth) or (HiWord(ALParam) <> LSelf.FHeight)) then
          LSelf.PostResize(LoWord(ALParam), HiWord(ALParam));
      WM_ERASEBKGND:
        Exit(1);
    end;
  Result := DefWindowProc(AWindow, AMessage, AWParam, ALParam);
end;

class procedure TXcomWinWindow.RegisterWindowClass;
var
  LClass: TWndClass;
begin
  if FClassRegistered then
    Exit;
  FillChar(LClass, SizeOf(LClass), 0);
  // a device context of its own: an OpenGL context stays bound to it for the life of the window
  LClass.style := CS_OWNDC;
  LClass.lpfnWndProc := @TXcomWinWindow.WindowProc;
  LClass.hInstance := HInstance;
  LClass.hCursor := LoadCursor(0, IDC_ARROW);
  LClass.lpszClassName := WINDOW_CLASS;
  if Winapi.Windows.RegisterClass(LClass) = 0 then
    RaiseLastOSError;
  FClassRegistered := True;
end;

constructor TXcomWinWindow.Create(const ATitle: string; AEvents: TXcomQueueEventSource);
begin
  inherited Create;
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  FTitle := ATitle;
  FEvents := AEvents;
end;

destructor TXcomWinWindow.Destroy;
begin
  DestroyHandle;
  inherited Destroy;
end;

procedure TXcomWinWindow.DestroyHandle;
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

procedure TXcomWinWindow.CreateWindowHandle;
var
  LRect: TRect;
  LStyle: DWORD;
  LLeft: Integer;
  LTop: Integer;
begin
  RegisterWindowClass;
  LStyle := WindowStyle;
  LRect := Rect(0, 0, FWidth, FHeight);
  AdjustWindowRect(LRect, LStyle, False);
  LLeft := Integer(CW_USEDEFAULT);
  LTop := Integer(CW_USEDEFAULT);
  if FHasPosition then
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

procedure TXcomWinWindow.SetMode(AWidth, AHeight: Integer; AFullscreen: Boolean);
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

procedure TXcomWinWindow.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
  if FHandle <> 0 then
    SetWindowText(FHandle, PChar(ATitle));
end;

function TXcomWinWindow.Pump: Boolean;
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
