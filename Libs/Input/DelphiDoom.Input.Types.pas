{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the shared types                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Keys of the keyboard state table (the virtual key codes of Windows)</summary>
  KEYSTATE_COUNT = 256;
  /// <summary>The bit of a keyboard state byte that says the key is down</summary>
  KEYSTATE_DOWN = $80;

  /// <summary>Bits of the mouse buttons in the event</summary>
  MOUSEBUTTON_LEFT = 1;
  MOUSEBUTTON_RIGHT = 2;
  MOUSEBUTTON_MIDDLE = 4;

type
  /// <summary>One byte for every virtual key: bit $80 set when the key is down</summary>
  TKeyStates = array[0..KEYSTATE_COUNT - 1] of Byte;

  TInputEventKind = (KeyDown, KeyUp, Mouse, Joystick);

  /// <summary>
  ///   Keys: Data1 is the key. Mouse: Data1 the buttons, Data2 and Data3 how far it moved.
  ///   Joystick: Data1 the buttons, Data2 and Data3 how far it is from where it was at the start
  /// </summary>
  TInputEvent = record
    Kind: TInputEventKind;
    Data1: Integer;
    Data2: Integer;
    Data3: Integer;
  end;

  TMouseButton = (Left, Right, Middle);

  TJoystickReading = record
    /// <summary>How many buttons the device has</summary>
    ButtonCount: Cardinal;
    Buttons: Cardinal;
    X: Integer;
    Y: Integer;
  end;

  /// <summary>An input device that could not start</summary>
  EInputDeviceException = class(Exception);

implementation

end.
