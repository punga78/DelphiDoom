{******************************************************************************}
{                                                                              }
{  DelphiDoom: input library - the contracts                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Input.Intf;

interface

uses
  DelphiDoom.Input.Types;

type
  /// <summary>The calls of the system that the keyboard of Windows makes</summary>
  IKeyboardSystem = interface
    ['{4C1E8D27-93A5-4F60-B2D8-7A05E3C916F4}']
    /// <summary>One byte for every virtual key (GetKeyboardState); false if the system refuses</summary>
    function ReadKeyboardState(var AStates: TKeyStates): Boolean;
    /// <summary>GetKeyState: negative when the key is down, bit 0 set when it is toggled on</summary>
    function GetKeyState(AVirtualKey: Integer): SmallInt;
  end;

  /// <summary>The calls of the system that the mouse of Windows makes</summary>
  ICursorSystem = interface
    ['{A79B3E05-1D6C-48F2-9E47-C3B80F25D61A}']
    /// <summary>Finds the functions of the cursor (in physical pixels where the system has them)</summary>
    procedure Open;
    procedure Close;
    function GetCursorPosition(out AX, AY: Integer): Boolean;
    function SetCursorPosition(AX, AY: Integer): Boolean;
    /// <summary>GetKeyState of a button of the mouse: negative when it is down</summary>
    function GetKeyState(AVirtualKey: Integer): SmallInt;
  end;

  /// <summary>The calls of the multimedia joystick API of the system, for the first joystick</summary>
  IJoystickSystem = interface
    ['{E2D05B91-6F38-4A7C-8D13-59F4A6C0B827}']
    /// <summary>joyGetNumDevs: how many joysticks the driver can hold, not how many there are</summary>
    function DeviceCount: Cardinal;
    function Capture(AWindow: THandle): Boolean;
    procedure Release;
    /// <summary>joyGetPosEx with every value; false if there is no joystick to read</summary>
    function ReadPosition(out AReading: TJoystickReading): Boolean;
  end;

  IKeyboardDevice = interface
    ['{2F6C8A14-D3E7-4B90-A5C1-7E49B02D6F83}']
    /// <summary>Raises EInputDeviceException if it cannot start</summary>
    procedure Initialize;
    procedure Shutdown;
    /// <summary>
    ///   Fills the table; false when there is nothing to read now (the input was lost) and
    ///   the table is not to be used
    /// </summary>
    function ReadState(var AStates: TKeyStates): Boolean;
    /// <summary>The window gains or loses the focus</summary>
    procedure SetActive(AActive: Boolean);
    function IsCapsLockOn: Boolean;
  end;

  IMouseDevice = interface
    ['{91B3E5D7-48A2-4C06-8F1D-A2C57E30B964}']
    procedure Initialize;
    procedure Shutdown;
    procedure GetPosition(out AX, AY: Integer);
    procedure SetPosition(AX, AY: Integer);
    function IsButtonDown(AButton: TMouseButton): Boolean;
  end;

  IJoystickDevice = interface
    ['{C70E24A9-5B1F-4D83-96E2-0F8A3D41B5C7}']
    /// <summary>True when there is a joystick</summary>
    function Initialize: Boolean;
    procedure Shutdown;
    function Read(out AReading: TJoystickReading): Boolean;
  end;

  /// <summary>Says whether the program is in a state where it listens to the devices</summary>
  IInputGate = interface
    ['{5A8D1B62-E9C4-47F3-B018-6D2E7A93C5F1}']
    function IsInputAllowed: Boolean;
  end;

  /// <summary>The size of the screen: the mouse is brought back to its centre</summary>
  IScreenSize = interface
    ['{E4137F58-0B9A-4C26-AD75-39C8D1E02B46}']
    function GetWidth: Integer;
    function GetHeight: Integer;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
  end;

  /// <summary>From the code of a key of the device to the code of the game; 0 means none</summary>
  IKeyMap = interface
    ['{0D92C6E1-7A35-4F48-B8A0-5E1F94D7C23B}']
    function Translate(AVirtualKey: Integer): Integer;
    /// <summary>Shift, control and alt are reported a second time, as the keys of the game</summary>
    function TranslateModifier(AVirtualKey: Integer): Integer;
  end;

  /// <summary>Where the events go</summary>
  IInputEventSink = interface
    ['{B6E80D3A-1C57-49F2-8D94-2A7F05C1E8B3}']
    procedure Post(const AEvent: TInputEvent);
  end;

  /// <summary>
  ///   Before Initialize and after Shutdown the poller is idle: Process, Synchronize and
  ///   Shutdown do nothing and the caps lock is off
  /// </summary>
  IInputPoller = interface
    ['{38F2A7C5-9D61-4E0B-A3B8-C4D5160E7F29}']
    /// <summary>Starts the devices; raises EInputDeviceException if one cannot start</summary>
    procedure Initialize;
    procedure Shutdown;
    /// <summary>Reads the devices and posts the events of what changed</summary>
    procedure Process;
    /// <summary>The window gains (True) or loses the focus</summary>
    procedure Synchronize(AActive: Boolean);
    function IsInitialized: Boolean;
    /// <summary>Positive: those buttons are down; negative: those buttons are released</summary>
    procedure SetMouseClicks(AValue: Integer);
    function IsCapsLockOn: Boolean;
  end;

implementation

end.
