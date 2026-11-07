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
  System.SysUtils, DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>The multimedia joystick API; the window that captures it is asked when needed</summary>
  TWindowsJoystick = class(TInterfacedObject, IJoystickDevice)
  private
    FWindow: TFunc<THandle>;
    FSystem: IJoystickSystem;
  public
    /// <summary>Raises EArgumentNilException if AWindow or ASystem is nil</summary>
    constructor Create(const AWindow: TFunc<THandle>; const ASystem: IJoystickSystem);
    function Initialize: Boolean;
    procedure Shutdown;
    function Read(out AReading: TJoystickReading): Boolean;
  end;

implementation

const
  SWindowIsNil = 'TWindowsJoystick: the window is nil';
  SSystemIsNil = 'TWindowsJoystick: the system is nil';

{ TWindowsJoystick }

constructor TWindowsJoystick.Create(const AWindow: TFunc<THandle>; const ASystem: IJoystickSystem);
begin
  inherited Create;
  if not Assigned(AWindow) then
    raise EArgumentNilException.Create(SWindowIsNil);
  if not Assigned(ASystem) then
    raise EArgumentNilException.Create(SSystemIsNil);
  FWindow := AWindow;
  FSystem := ASystem;
end;

function TWindowsJoystick.Initialize: Boolean;
begin
  Result := FSystem.DeviceCount > 0;
  if Result then
    Result := FSystem.Capture(FWindow());
end;

procedure TWindowsJoystick.Shutdown;
begin
  FSystem.Release;
end;

function TWindowsJoystick.Read(out AReading: TJoystickReading): Boolean;
var
  LReading: TJoystickReading;
begin
  Result := FSystem.ReadPosition(LReading);
  // the reading is given only when there is one, as before
  if Result then
    AReading := LReading;
end;

end.
