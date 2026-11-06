{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the factory: the composition root                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Input.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the classes behind the input contracts</summary>
  TInputFactory = class
  public
    class function CreateWindowsKeyboard: IKeyboardDevice; static;
    class function CreateWindowsMouse: IMouseDevice; static;
    /// <param name="AWindow">The window that captures the joystick, asked when the joystick starts</param>
    class function CreateWindowsJoystick(const AWindow: TFunc<THandle>): IJoystickDevice; static;
    /// <summary>ALog may be nil</summary>
    class function CreatePoller(const AKeyboard: IKeyboardDevice; const AMouse: IMouseDevice;
      const AJoystick: IJoystickDevice; const AGate: IInputGate; const AScreen: IScreenSize;
      const AKeyMap: IKeyMap; const ASink: IInputEventSink; const ALog: ILog;
      AJoystickButtons: Integer): IInputPoller; static;
  end;

implementation

uses
  DelphiDoom.Input.Poller, DelphiDoom.Input.WindowsKeyboard, DelphiDoom.Input.WindowsMouse,
  DelphiDoom.Input.WindowsJoystick;

{ TInputFactory }

class function TInputFactory.CreateWindowsKeyboard: IKeyboardDevice;
begin
  Result := TWindowsKeyboard.Create;
end;

class function TInputFactory.CreateWindowsMouse: IMouseDevice;
begin
  Result := TWindowsMouse.Create;
end;

class function TInputFactory.CreateWindowsJoystick(const AWindow: TFunc<THandle>): IJoystickDevice;
begin
  Result := TWindowsJoystick.Create(AWindow);
end;

class function TInputFactory.CreatePoller(const AKeyboard: IKeyboardDevice;
  const AMouse: IMouseDevice; const AJoystick: IJoystickDevice; const AGate: IInputGate;
  const AScreen: IScreenSize; const AKeyMap: IKeyMap; const ASink: IInputEventSink;
  const ALog: ILog; AJoystickButtons: Integer): IInputPoller;
begin
  Result := TInputPoller.Create(AKeyboard, AMouse, AJoystick, AGate, AScreen, AKeyMap, ASink,
    ALog, AJoystickButtons);
end;

end.
