{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - shared types (events, handlers, errors)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Types;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types;

type
  /// <summary>Base of the errors of the xcom engine library (Exception of OpenXcom)</summary>
  EXcomEngineException = class(Exception);

  /// <summary>The kinds of event that the engine understands (the SDL events that OpenXcom uses)</summary>
  TXcomEventKind = (ekQuit, ekKeyDown, ekKeyUp, ekMouseMotion, ekMouseDown, ekMouseUp, ekActive, ekResize);

  /// <summary>An input event, the SDL_Event of OpenXcom reduced to what the engine reads</summary>
  TXcomInputEvent = record
    Kind: TXcomEventKind;
    /// <summary>The key as an SDLKey of SDL 1.2 (Return 13, Escape 27, F12 293...)</summary>
    Key: Integer;
    /// <summary>The modifier keys as KMOD_ of SDL 1.2</summary>
    Modifiers: Integer;
    /// <summary>The character typed (SDL unicode field), 0 if none</summary>
    Character: Cardinal;
    /// <summary>1 left, 2 middle, 3 right, 4 wheel up, 5 wheel down (SDL_BUTTON_)</summary>
    Button: Integer;
    /// <summary>Position of the mouse in pixels of the window</summary>
    X: Integer;
    Y: Integer;
    /// <summary>The size of the window for a resize</summary>
    Width: Integer;
    Height: Integer;
    class function Make(AKind: TXcomEventKind): TXcomInputEvent; static;
  end;

  PXcomInputEvent = ^TXcomInputEvent;

  /// <summary>The 256 colors of a state, a screen or a surface (SDL_Color[256])</summary>
  TXcomColors = array[0..255] of TXcomColor;
  PXcomColors = ^TXcomColors;

  /// <summary>A pointer to the first color of a run of colors (SDL_Color *)</summary>
  PXcomColor = ^TXcomColor;

  /// <summary>The handler of the timer of a state or of a surface (StateHandler and SurfaceHandler)</summary>
  TXcomNotify = reference to procedure;

  /// <summary>KeyboardType: how text is typed (KEYBOARD_OFF: arrows pick a letter; KEYBOARD_ON: the keyboard)</summary>
  TXcomKeyboardMode = (kmOff, kmOn, kmVirtual);

const
  XCOM_BUTTON_LEFT = 1;
  XCOM_BUTTON_MIDDLE = 2;
  XCOM_BUTTON_RIGHT = 3;
  XCOM_BUTTON_WHEELUP = 4;
  XCOM_BUTTON_WHEELDOWN = 5;
  XCOM_BUTTON_COUNT = 5;

  XCOM_KEY_ANY = -1;
  XCOM_KEY_UNKNOWN = 0;
  XCOM_KEY_BACKSPACE = 8;
  XCOM_KEY_TAB = 9;
  XCOM_KEY_RETURN = 13;
  XCOM_KEY_ESCAPE = 27;
  XCOM_KEY_DELETE = 127;
  XCOM_KEY_KP_ENTER = 271;
  XCOM_KEY_UP = 273;
  XCOM_KEY_DOWN = 274;
  XCOM_KEY_RIGHT = 275;
  XCOM_KEY_LEFT = 276;
  XCOM_KEY_HOME = 278;
  XCOM_KEY_END = 279;
  XCOM_KEY_F12 = 293;
  XCOM_KMOD_SHIFT = $0003;
  XCOM_KMOD_CTRL = $00C0;
  XCOM_KMOD_ALT = $0300;

implementation

class function TXcomInputEvent.Make(AKind: TXcomEventKind): TXcomInputEvent;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Kind := AKind;
end;

end.
