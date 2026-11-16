{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the calls of Windows                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.WindowsSystem;

interface

uses
  Winapi.Windows, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>
  ///   The calls of Windows behind the keyboard, the mouse and the joystick: GetKeyboardState,
  ///   GetKeyState, the cursor in physical pixels (GetPhysicalCursorPos, or GetCursorPos on the
  ///   systems that do not have it) and joyGetPosEx of the first joystick. Nothing else is here,
  ///   so the devices can be tried with a fake system
  /// </summary>
  TWindowsInputSystem = class(TInterfacedObject, IKeyboardSystem, ICursorSystem, IJoystickSystem)
  private
    type
      TGetCursorPosFunc = function(var APoint: TPoint): BOOL; stdcall;
      TSetCursorPosFunc = function(AX, AY: Integer): BOOL; stdcall;
    var
      FUser32: HMODULE;
      FGetCursorPos: TGetCursorPosFunc;
      FSetCursorPos: TSetCursorPosFunc;
  public
    destructor Destroy; override;
    { IKeyboardSystem }
    function ReadKeyboardState(var AStates: TKeyStates): Boolean;
    function GetKeyState(AVirtualKey: Integer): SmallInt;
    { ICursorSystem }
    procedure Open;
    procedure Close;
    function GetCursorPosition(out AX, AY: Integer): Boolean;
    function SetCursorPosition(AX, AY: Integer): Boolean;
    { IJoystickSystem }
    function DeviceCount: Cardinal;
    function Capture(AWindow: THandle): Boolean;
    procedure Release;
    function ReadPosition(out AReading: TJoystickReading): Boolean;
  end;

implementation

uses
  Winapi.MMSystem;

{ TWindowsInputSystem }

destructor TWindowsInputSystem.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TWindowsInputSystem.ReadKeyboardState(var AStates: TKeyStates): Boolean;
var
  LState: TKeyboardState;
begin
  Result := Winapi.Windows.GetKeyboardState(LState);
  Move(LState, AStates, SizeOf(AStates));
end;

function TWindowsInputSystem.GetKeyState(AVirtualKey: Integer): SmallInt;
begin
  Result := Winapi.Windows.GetKeyState(AVirtualKey);
end;

procedure TWindowsInputSystem.Open;
begin
  Close;
  FUser32 := LoadLibrary(user32);
  FGetCursorPos := GetProcAddress(FUser32, 'GetPhysicalCursorPos');
  if not Assigned(FGetCursorPos) then
    FGetCursorPos := GetProcAddress(FUser32, 'GetCursorPos');
  FSetCursorPos := GetProcAddress(FUser32, 'SetPhysicalCursorPos');
  if not Assigned(FSetCursorPos) then
    FSetCursorPos := GetProcAddress(FUser32, 'SetCursorPos');
end;

procedure TWindowsInputSystem.Close;
begin
  FGetCursorPos := nil;
  FSetCursorPos := nil;
  if FUser32 <> 0 then
    FreeLibrary(FUser32);
  FUser32 := 0;
end;

function TWindowsInputSystem.GetCursorPosition(out AX, AY: Integer): Boolean;
var
  LPoint: TPoint;
begin
  LPoint.X := 0;
  LPoint.Y := 0;
  Result := Assigned(FGetCursorPos) and FGetCursorPos(LPoint);
  AX := LPoint.X;
  AY := LPoint.Y;
end;

function TWindowsInputSystem.SetCursorPosition(AX, AY: Integer): Boolean;
begin
  Result := Assigned(FSetCursorPos) and FSetCursorPos(AX, AY);
end;

function TWindowsInputSystem.DeviceCount: Cardinal;
begin
  Result := joyGetNumDevs;
end;

function TWindowsInputSystem.Capture(AWindow: THandle): Boolean;
begin
  Result := joySetCapture(AWindow, JOYSTICKID1, 0, False) = JOYERR_NOERROR;
end;

procedure TWindowsInputSystem.Release;
begin
  joyReleaseCapture(JOYSTICKID1);
end;

function TWindowsInputSystem.ReadPosition(out AReading: TJoystickReading): Boolean;
var
  LInfo: TJoyInfoEx;
begin
  ZeroMemory(@LInfo, SizeOf(LInfo));
  LInfo.dwSize := SizeOf(LInfo);
  LInfo.dwFlags := JOY_RETURNALL;
  Result := joyGetPosEx(JOYSTICKID1, @LInfo) = JOYERR_NOERROR;
  AReading.ButtonCount := LInfo.dwButtonNumber;
  AReading.Buttons := LInfo.wButtons;
  AReading.X := Integer(LInfo.wXpos);
  AReading.Y := Integer(LInfo.wYpos);
end;

end.
