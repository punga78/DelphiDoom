{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the types the games and the host share      }
{  A picture of 8 bit pixels with its palette, an input event as Windows gives  }
{  it, and how a display shows the picture                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>The library cannot do what it was asked; the message says why</summary>
  EGameHostException = class(Exception);

  /// <summary>A display cannot be made on this machine (no OpenGL context, for instance); the message says why</summary>
  EGameHostVideoDeviceException = class(EGameHostException);

  /// <summary>A color of the palette of a picture</summary>
  TGameHostColor = packed record
    Red: Byte;
    Green: Byte;
    Blue: Byte;
  end;

  /// <summary>The 256 colors of a picture of 8 bit pixels</summary>
  TGameHostPalette = array[0..255] of TGameHostColor;

  /// <summary>
  ///   What happened in the window. A turn of the wheel is one event (the game decides what it becomes); hekActive
  ///   says that the window got or lost the focus or was minimized; hekResize that the player dragged the border
  /// </summary>
  TGameHostEventKind = (hekQuit, hekKeyDown, hekKeyUp, hekMouseMotion, hekMouseDown, hekMouseUp, hekMouseWheel,
    hekActive, hekResize);

  TGameHostMouseButton = (hmbNone, hmbLeft, hmbMiddle, hmbRight);

  TGameHostModifier = (hmShift, hmControl, hmAlt);

  /// <summary>The modifier keys that are down when the event happens</summary>
  TGameHostModifiers = set of TGameHostModifier;

  /// <summary>
  ///   An input event of the window, with nothing of a game in it: the key is the virtual key of Windows (VK_),
  ///   each game turns it into its own codes
  /// </summary>
  TGameHostEvent = record
    Kind: TGameHostEventKind;
    /// <summary>hekKeyDown and hekKeyUp: the virtual key code of Windows</summary>
    VirtualKey: Integer;
    /// <summary>hekKeyDown: what the key types with the current layout and shift state (32 or more), 0 if nothing</summary>
    Character: Cardinal;
    Modifiers: TGameHostModifiers;
    /// <summary>hekMouseDown and hekMouseUp</summary>
    Button: TGameHostMouseButton;
    /// <summary>
    ///   The mouse events but the wheel: the position in pixels of the picture (a full screen picture is stretched,
    ///   the position is brought back). hekResize: the new size of the client area
    /// </summary>
    X: Integer;
    Y: Integer;
    /// <summary>hekMouseWheel: positive away from the player</summary>
    WheelDelta: Integer;
    /// <summary>hekActive: the window has the focus and is not minimized</summary>
    Focused: Boolean;
    /// <summary>hekActive: the window is minimized</summary>
    Minimized: Boolean;
    class function Make(AKind: TGameHostEventKind): TGameHostEvent; static;
  end;

  /// <summary>
  ///   What the translation of a message needs to know of the window when the message arrives: the mode that was
  ///   set, the client area and what the window is doing
  /// </summary>
  TGameHostWindowState = record
    /// <summary>The size of the picture (the mode)</summary>
    Width: Integer;
    Height: Integer;
    ClientWidth: Integer;
    ClientHeight: Integer;
    Fullscreen: Boolean;
    Resizable: Boolean;
    /// <summary>The window is taking a size the game asked for: it is not a resize of the player</summary>
    SettingMode: Boolean;
  end;

  /// <summary>
  ///   How the picture goes to the display. Shader is a path that the shader loader of the game understands, empty
  ///   for none
  /// </summary>
  TGameHostDisplayFilter = record
    UseOpenGL: Boolean;
    Shader: string;
    Smoothing: Boolean;
    VSync: Boolean;
  end;

  /// <summary>The black bands around a picture that does not fill the display, in pixels of the display</summary>
  TGameHostBlackBands = record
    Left: Integer;
    Right: Integer;
    Top: Integer;
    Bottom: Integer;
  end;

  /// <summary>
  ///   A shader of the display. The two programs are bytes as the compiler of the driver wants them; an empty one
  ///   is not compiled
  /// </summary>
  TGameHostShaderSource = record
    /// <summary>The language is GLSL, the only one that is compiled</summary>
    IsGlsl: Boolean;
    /// <summary>The texture of the picture is sampled with the linear filter</summary>
    Linear: Boolean;
    Fragment: RawByteString;
    Vertex: RawByteString;
  end;

implementation

class function TGameHostEvent.Make(AKind: TGameHostEventKind): TGameHostEvent;
begin
  Result := Default(TGameHostEvent);
  Result.Kind := AKind;
end;

end.
