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

  IInputPoller = interface
    ['{38F2A7C5-9D61-4E0B-A3B8-C4D5160E7F29}']
    /// <summary>Starts the devices; raises EInputDeviceException if one cannot start</summary>
    procedure Initialize;
    procedure Shutdown;
    /// <summary>Reads the devices and posts the events of what changed</summary>
    procedure Process;
    /// <summary>The window gains (True) or loses the focus</summary>
    procedure Synchronize(AActive: Boolean);
    /// <summary>Positive: those buttons are down; negative: those buttons are released</summary>
    procedure SetMouseClicks(AValue: Integer);
    function IsCapsLockOn: Boolean;
  end;

implementation

end.
