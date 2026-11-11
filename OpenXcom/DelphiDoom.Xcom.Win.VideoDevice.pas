{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the window of Windows                                  }
{  What SDL_SetVideoMode, SDL_Flip and the SDL event loop did, on GDI: the      }
{  picture of 8 bit pixels goes to the window with its palette (no conversion   }
{  to colors), and the messages of the window become events of the game         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.VideoDevice;

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.MultiMon, System.Types, System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.QueueEventSource;

type
  /// <summary>
  ///   IXcomVideoDevice on a Windows window. The window procedure puts the keyboard and mouse messages in the queue of
  ///   events that it is given (SDL 1.2 key codes and button numbers); the system cursor is hidden over the window
  ///   because the game draws its own. Everything is done by the thread that created it
  /// </summary>
  TXcomWinVideoDevice = class(TInterfacedObject, IXcomVideoDevice, IXcomWindowStyle)
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
    class var FClassRegistered: Boolean;
    class function WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall; static;
    class procedure RegisterWindowClass; static;
    class function KeyOf(AVirtualKey: WPARAM): Integer; static;
    procedure Post(AKind: TXcomEventKind; AKey, AButton: Integer; ALParam: LPARAM; ACharacter: Cardinal = 0);
    procedure CreateWindowHandle;
    function Modifiers: Integer;
    function CharacterOf(AVirtualKey: WPARAM; ALParam: LPARAM): Cardinal;
    function PictureRect(out ARect: TRect): Boolean;
    function ScalePoint(ALParam: LPARAM): LPARAM;
    procedure ApplyWindowStyle;
    function WindowStyle: DWORD;
    procedure PostResize(AWidth, AHeight: Integer);
  public
    /// <param name="AEvents">Where the events go; not owned</param>
    constructor Create(const ATitle: string; AEvents: TXcomQueueEventSource);
    destructor Destroy; override;
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
    /// <summary>IXcomWindowStyle: taken at the next SetMode</summary>
    procedure SetWindowStyle(ABorderless, AResizable: Boolean);
    /// <summary>Reads the messages of the window into the queue of events; false once the window has been closed</summary>
    function Pump: Boolean;
  end;

implementation

const
  WINDOW_CLASS = 'DelphiDoomXcomWindow';

class function TXcomWinVideoDevice.KeyOf(AVirtualKey: WPARAM): Integer;
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

function TXcomWinVideoDevice.Modifiers: Integer;
begin
  Result := 0;
  if GetKeyState(VK_SHIFT) < 0 then
    Result := Result or XCOM_KMOD_SHIFT;
  if GetKeyState(VK_CONTROL) < 0 then
    Result := Result or XCOM_KMOD_CTRL;
  if GetKeyState(VK_MENU) < 0 then
    Result := Result or XCOM_KMOD_ALT;
end;

function TXcomWinVideoDevice.CharacterOf(AVirtualKey: WPARAM; ALParam: LPARAM): Cardinal;
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

function TXcomWinVideoDevice.PictureRect(out ARect: TRect): Boolean;
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

function TXcomWinVideoDevice.ScalePoint(ALParam: LPARAM): LPARAM;
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

function TXcomWinVideoDevice.WindowStyle: DWORD;
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

procedure TXcomWinVideoDevice.SetWindowStyle(ABorderless, AResizable: Boolean);
begin
  FBorderless := ABorderless;
  FResizable := AResizable;
end;

procedure TXcomWinVideoDevice.PostResize(AWidth, AHeight: Integer);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekResize);
  LEvent.X := AWidth;
  LEvent.Y := AHeight;
  FEvents.Enqueue(LEvent);
end;

procedure TXcomWinVideoDevice.ApplyWindowStyle;
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

procedure TXcomWinVideoDevice.Post(AKind: TXcomEventKind; AKey, AButton: Integer; ALParam: LPARAM;
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

class function TXcomWinVideoDevice.WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM;
  ALParam: LPARAM): LRESULT;
var
  LSelf: TXcomWinVideoDevice;
  LKey: Integer;
  LWheelX: Integer;
  LWheelY: Integer;
  LCharacter: Cardinal;
begin
  LSelf := TXcomWinVideoDevice(GetWindowLongPtr(AWindow, GWLP_USERDATA));
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

class procedure TXcomWinVideoDevice.RegisterWindowClass;
var
  LClass: TWndClass;
begin
  if FClassRegistered then
    Exit;
  FillChar(LClass, SizeOf(LClass), 0);
  LClass.lpfnWndProc := @TXcomWinVideoDevice.WindowProc;
  LClass.hInstance := HInstance;
  LClass.hCursor := LoadCursor(0, IDC_ARROW);
  LClass.lpszClassName := WINDOW_CLASS;
  if Winapi.Windows.RegisterClass(LClass) = 0 then
    RaiseLastOSError;
  FClassRegistered := True;
end;

constructor TXcomWinVideoDevice.Create(const ATitle: string; AEvents: TXcomQueueEventSource);
begin
  inherited Create;
  FTitle := ATitle;
  FEvents := AEvents;
end;

destructor TXcomWinVideoDevice.Destroy;
begin
  if FHandle <> 0 then
  begin
    SetWindowLongPtr(FHandle, GWLP_USERDATA, 0);
    DestroyWindow(FHandle);
  end;
  inherited Destroy;
end;

procedure TXcomWinVideoDevice.CreateWindowHandle;
var
  LRect: TRect;
  LStyle: DWORD;
begin
  RegisterWindowClass;
  LStyle := WindowStyle;
  LRect := Rect(0, 0, FWidth, FHeight);
  AdjustWindowRect(LRect, LStyle, False);
  FHandle := CreateWindow(WINDOW_CLASS, PChar(FTitle), LStyle, CW_USEDEFAULT, CW_USEDEFAULT,
    LRect.Right - LRect.Left, LRect.Bottom - LRect.Top, 0, 0, HInstance, nil);
  if FHandle = 0 then
    RaiseLastOSError;
  SetWindowLongPtr(FHandle, GWLP_USERDATA, LONG_PTR(Self));
  ShowWindow(FHandle, SW_SHOWNORMAL);
  UpdateWindow(FHandle);
end;

procedure TXcomWinVideoDevice.SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
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
begin
  if (FHandle = 0) or (Length(APixels) < AWidth * AHeight) then
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
  LDevice := GetDC(FHandle);
  try
    if PictureRect(LClient) then
    begin
      // the bands beside the picture (nothing erases the background of this window)
      if GetClientRect(FHandle, LWhole) then
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
    ReleaseDC(FHandle, LDevice);
  end;
end;

procedure TXcomWinVideoDevice.SetTitle(const ATitle: string);
begin
  FTitle := ATitle;
  if FHandle <> 0 then
    SetWindowText(FHandle, PChar(ATitle));
end;

function TXcomWinVideoDevice.Pump: Boolean;
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
