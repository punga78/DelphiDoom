{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed - the window of Windows                                    }
{  What DirectDraw (i_video.pas) and the window procedure of i_main.pas did, on }
{  GDI: the picture of 8 bit pixels is turned into colors and stretched         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Win.Window;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Types, System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Frame.Intf;

type
  /// <summary>
  ///   A window that shows the pictures (IGreedFramePresenter) and tells which keys are down (IGreedInput): arrows
  ///   or W, S to walk, left and right arrows or Q, E to turn, A, D to step aside, Shift to run, Escape to quit.
  ///   Everything is done by the thread that created it
  /// </summary>
  TGreedWindow = class(TInterfacedObject, IGreedFramePresenter, IGreedInput)
  strict private
    FHandle: HWND;
    FClosed: Boolean;
    FKeys: array[0..255] of Boolean;
    FBitmap: TArray<Cardinal>;
    FScale: Integer;
    class var FClassRegistered: Boolean;
    class function WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT; stdcall; static;
    class procedure RegisterWindowClass; static;
    function KeyDown(AFirst: Integer; ASecond: Integer): Boolean; inline;
  public
    /// <param name="AWidth">Width of the picture; the client area is AScale times as wide</param>
    constructor Create(const ATitle: string; AWidth, AHeight, AScale: Integer);
    destructor Destroy; override;
    procedure Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
    function Pump: Boolean;
    function IsDown(AKey: TGreedKey): Boolean;
  end;

implementation

const
  WINDOW_CLASS = 'DelphiDoomGreedWindow';

{ TGreedWindow }

class function TGreedWindow.WindowProc(AWindow: HWND; AMessage: UINT; AWParam: WPARAM; ALParam: LPARAM): LRESULT;
var
  LSelf: TGreedWindow;
begin
  LSelf := TGreedWindow(GetWindowLongPtr(AWindow, GWLP_USERDATA));
  case AMessage of
    WM_KEYDOWN, WM_SYSKEYDOWN:
      begin
        if Assigned(LSelf) and (AWParam < 256) then
          LSelf.FKeys[AWParam] := True;
        if AMessage = WM_SYSKEYDOWN then
          Exit(DefWindowProc(AWindow, AMessage, AWParam, ALParam));
        Exit(0);
      end;
    WM_KEYUP, WM_SYSKEYUP:
      begin
        if Assigned(LSelf) and (AWParam < 256) then
          LSelf.FKeys[AWParam] := False;
        if AMessage = WM_SYSKEYUP then
          Exit(DefWindowProc(AWindow, AMessage, AWParam, ALParam));
        Exit(0);
      end;
    WM_KILLFOCUS:
      begin
        if Assigned(LSelf) then
          FillChar(LSelf.FKeys, SizeOf(LSelf.FKeys), 0);
        Exit(0);
      end;
    WM_CLOSE:
      begin
        if Assigned(LSelf) then
          LSelf.FClosed := True;
        Exit(0);
      end;
    WM_ERASEBKGND:
      Exit(1);
  end;
  Result := DefWindowProc(AWindow, AMessage, AWParam, ALParam);
end;

class procedure TGreedWindow.RegisterWindowClass;
var
  LClass: TWndClass;
begin
  if FClassRegistered then
    Exit;
  FillChar(LClass, SizeOf(LClass), 0);
  LClass.lpfnWndProc := @TGreedWindow.WindowProc;
  LClass.hInstance := HInstance;
  LClass.hCursor := LoadCursor(0, IDC_ARROW);
  LClass.lpszClassName := WINDOW_CLASS;
  if Winapi.Windows.RegisterClass(LClass) = 0 then
    RaiseLastOSError;
  FClassRegistered := True;
end;

constructor TGreedWindow.Create(const ATitle: string; AWidth, AHeight, AScale: Integer);
var
  LRect: TRect;
begin
  inherited Create;
  if (AWidth < 1) or (AHeight < 1) or (AScale < 1) then
    raise EGreedException.CreateFmt(SGreedImageSize, [AWidth, AHeight, 'window']);
  FScale := AScale;
  RegisterWindowClass;
  LRect := Rect(0, 0, AWidth * AScale, AHeight * AScale);
  AdjustWindowRect(LRect, WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX, False);
  FHandle := CreateWindow(WINDOW_CLASS, PChar(ATitle), WS_OVERLAPPED or WS_CAPTION or WS_SYSMENU or WS_MINIMIZEBOX,
    Integer(CW_USEDEFAULT), Integer(CW_USEDEFAULT), LRect.Right - LRect.Left, LRect.Bottom - LRect.Top, 0, 0, HInstance, nil);
  if FHandle = 0 then
    RaiseLastOSError;
  SetWindowLongPtr(FHandle, GWLP_USERDATA, LONG_PTR(Self));
  ShowWindow(FHandle, SW_SHOWNORMAL);
  UpdateWindow(FHandle);
end;

destructor TGreedWindow.Destroy;
begin
  if FHandle <> 0 then
  begin
    SetWindowLongPtr(FHandle, GWLP_USERDATA, 0);
    DestroyWindow(FHandle);
  end;
  inherited Destroy;
end;

procedure TGreedWindow.Present(const AFrame: TGreedFrame; const AColors: TGreedColors);
var
  LInfo: TBitmapInfo;
  LDevice: HDC;
  LRect: TRect;
  LIndex: Integer;
begin
  if (FHandle = 0) or (AFrame.Width < 1) or (Length(AFrame.Pixels) < AFrame.Width * AFrame.Height) then
    Exit;
  if Length(FBitmap) <> AFrame.Width * AFrame.Height then
    SetLength(FBitmap, AFrame.Width * AFrame.Height);
  for LIndex := 0 to High(FBitmap) do
    FBitmap[LIndex] := AColors[AFrame.Pixels[LIndex]];
  FillChar(LInfo, SizeOf(LInfo), 0);
  LInfo.bmiHeader.biSize := SizeOf(LInfo.bmiHeader);
  LInfo.bmiHeader.biWidth := AFrame.Width;
  // a negative height: the rows go from the top, as in the frame
  LInfo.bmiHeader.biHeight := -AFrame.Height;
  LInfo.bmiHeader.biPlanes := 1;
  LInfo.bmiHeader.biBitCount := 32;
  LInfo.bmiHeader.biCompression := BI_RGB;
  GetClientRect(FHandle, LRect);
  LDevice := GetDC(FHandle);
  try
    StretchDIBits(LDevice, 0, 0, LRect.Right, LRect.Bottom, 0, 0, AFrame.Width, AFrame.Height, @FBitmap[0], LInfo,
      DIB_RGB_COLORS, SRCCOPY);
  finally
    ReleaseDC(FHandle, LDevice);
  end;
end;

function TGreedWindow.Pump: Boolean;
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

function TGreedWindow.KeyDown(AFirst: Integer; ASecond: Integer): Boolean;
begin
  Result := FKeys[AFirst] or ((ASecond >= 0) and FKeys[ASecond]);
end;

function TGreedWindow.IsDown(AKey: TGreedKey): Boolean;
begin
  case AKey of
    gkForward: Result := KeyDown(VK_UP, Ord('W'));
    gkBackward: Result := KeyDown(VK_DOWN, Ord('S'));
    gkTurnLeft: Result := KeyDown(VK_LEFT, Ord('Q'));
    gkTurnRight: Result := KeyDown(VK_RIGHT, Ord('E'));
    gkStrafeLeft: Result := KeyDown(Ord('A'), -1);
    gkStrafeRight: Result := KeyDown(Ord('D'), -1);
    gkRun: Result := KeyDown(VK_SHIFT, -1);
    gkQuit: Result := KeyDown(VK_ESCAPE, -1);
  else
    Result := False;
  end;
end;

end.
