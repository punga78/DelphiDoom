{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the first joystick read from Windows             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.WindowsJoystick;

interface

uses
  System.SysUtils, Winapi.Windows, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>The multimedia joystick API (joyGetPosEx); the window that captures it is asked when needed</summary>
  TWindowsJoystick = class(TInterfacedObject, IJoystickDevice)
  private
    FWindow: TFunc<THandle>;
  public
    constructor Create(const AWindow: TFunc<THandle>);
    function Initialize: Boolean;
    procedure Shutdown;
    function Read(out AReading: TJoystickReading): Boolean;
  end;

implementation

uses
  Winapi.MMSystem;

{ TWindowsJoystick }

constructor TWindowsJoystick.Create(const AWindow: TFunc<THandle>);
begin
  inherited Create;
  FWindow := AWindow;
end;

function TWindowsJoystick.Initialize: Boolean;
begin
  Result := joyGetNumDevs > 0;
  if Result then
    Result := joySetCapture(FWindow(), JOYSTICKID1, 0, False) = JOYERR_NOERROR;
end;

procedure TWindowsJoystick.Shutdown;
begin
  joyReleaseCapture(JOYSTICKID1);
end;

function TWindowsJoystick.Read(out AReading: TJoystickReading): Boolean;
var
  LInfo: TJoyInfoEx;
begin
  ZeroMemory(@LInfo, SizeOf(LInfo));
  LInfo.dwSize := SizeOf(LInfo);
  LInfo.dwFlags := JOY_RETURNALL;
  Result := joyGetPosEx(JOYSTICKID1, @LInfo) = JOYERR_NOERROR;
  if Result then
  begin
    AReading.ButtonCount := LInfo.dwButtonNumber;
    AReading.Buttons := LInfo.wButtons;
    AReading.X := Integer(LInfo.wXpos);
    AReading.Y := Integer(LInfo.wYpos);
  end;
end;

end.
