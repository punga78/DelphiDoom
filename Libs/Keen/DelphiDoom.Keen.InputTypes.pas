{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the types of the input manager                    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later: id_in.h }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.InputTypes;

interface

const
  KEEN_MAX_PLAYERS = 4;
  KEEN_MAX_KEYBOARDS = 2;
  KEEN_MAX_JOYSTICKS = 2;
  /// <summary>Scan codes that the keyboard table keeps (NumCodes)</summary>
  KEEN_NUM_CODES = 128;

  // ---- the scan codes of the PC keyboard (set 1) ----

  KEEN_SC_NONE = $00;
  KEEN_SC_BAD = $FF;
  KEEN_SC_ESCAPE = $01;
  KEEN_SC_BACKSPACE = $0E;
  KEEN_SC_TAB = $0F;
  KEEN_SC_RETURN = $1C;
  KEEN_SC_CONTROL = $1D;
  KEEN_SC_LSHIFT = $2A;
  KEEN_SC_RSHIFT = $36;
  KEEN_SC_ALT = $38;
  KEEN_SC_SPACE = $39;
  KEEN_SC_CAPSLOCK = $3A;
  KEEN_SC_F1 = $3B;
  KEEN_SC_F2 = $3C;
  KEEN_SC_F3 = $3D;
  KEEN_SC_F4 = $3E;
  KEEN_SC_F5 = $3F;
  KEEN_SC_F6 = $40;
  KEEN_SC_F7 = $41;
  KEEN_SC_F8 = $42;
  KEEN_SC_F9 = $43;
  KEEN_SC_F10 = $44;
  KEEN_SC_F11 = $57;
  KEEN_SC_F12 = $59;
  KEEN_SC_HOME = $47;
  KEEN_SC_UPARROW = $48;
  KEEN_SC_PGUP = $49;
  KEEN_SC_LEFTARROW = $4B;
  KEEN_SC_RIGHTARROW = $4D;
  KEEN_SC_END = $4F;
  KEEN_SC_DOWNARROW = $50;
  KEEN_SC_PGDN = $51;
  KEEN_SC_INSERT = $52;
  KEEN_SC_DELETE = $53;

  // ---- the ASCII codes the input manager gives (key_*) ----

  KEEN_KEY_NONE = 0;
  KEEN_KEY_BACKSPACE = $08;
  KEEN_KEY_TAB = $09;
  KEEN_KEY_RETURN = $0D;
  KEEN_KEY_ESCAPE = $1B;
  KEEN_KEY_SPACE = $20;
  KEEN_KEY_DELETE = $7F;

  /// <summary>The cap of the value of a joystick axis in a control (+/-127)</summary>
  KEEN_JOY_MAX_DELTA = 127;
  /// <summary>JoyScaleMax, JoyScaleShift and MaxJoyValue of id_in.c</summary>
  KEEN_JOY_SCALE_MAX = 32768;
  KEEN_JOY_SCALE_SHIFT = 8;
  KEEN_MAX_JOY_VALUE = 5000;

type
  /// <summary>Demo: what the input manager does with the demo buffer (demo_Off, demo_Record, demo_Playback, demo_PlayDone)</summary>
  TKeenDemoMode = (kdmOff, kdmRecord, kdmPlayback, kdmPlayDone);

  /// <summary>
  ///   ControlType: which device a player has. The keyboard 1 and 2 and the joystick 1 and 2 are the first
  ///   and the second of their device
  /// </summary>
  TKeenControlType = (kctKeyboard1, kctKeyboard2, kctJoystick1, kctJoystick2, kctMouse);

  /// <summary>Motion: -1 left or up, 0 none, 1 right or down</summary>
  TKeenMotion = -1..1;

  /// <summary>Direction: the eight ways of a control, and none</summary>
  TKeenDirection = (kdNorth, kdNorthEast, kdEast, kdSouthEast, kdSouth, kdSouthWest, kdWest, kdNorthWest, kdNone);

  /// <summary>ControlInfo and CursorInfo: the buttons, how far the control moved and in which direction</summary>
  TKeenControlInfo = record
    Button0: Boolean;
    Button1: Boolean;
    X: Integer;
    Y: Integer;
    XAxis: TKeenMotion;
    YAxis: TKeenMotion;
    Direction: TKeenDirection;
  end;

  /// <summary>KeyboardDef: the scan codes of the keys that a keyboard control uses</summary>
  TKeenKeyboardDef = record
    Button0: Byte;
    Button1: Byte;
    UpLeft: Byte;
    Up: Byte;
    UpRight: Byte;
    Left: Byte;
    Right: Byte;
    DownLeft: Byte;
    Down: Byte;
    DownRight: Byte;
  end;

  /// <summary>JoystickDef: the range of the axes, the dead zone and the scale (all 16 bit unsigned)</summary>
  TKeenJoystickDef = record
    JoyMinX: Word;
    JoyMinY: Word;
    ThreshMinX: Word;
    ThreshMinY: Word;
    ThreshMaxX: Word;
    ThreshMaxY: Word;
    JoyMaxX: Word;
    JoyMaxY: Word;
    JoyMultXL: Word;
    JoyMultYL: Word;
    JoyMultXH: Word;
    JoyMultYH: Word;
  end;

implementation

end.
