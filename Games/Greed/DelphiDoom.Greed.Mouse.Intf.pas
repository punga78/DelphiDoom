{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the contract of the mouse of the game            }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the mouse of d_ints.pas     }
{  (mouse_t, mousehx, mousehy, mousevisible, menuusemouse)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Mouse.Intf;

interface

uses
  DelphiDoom.Greed.PlayerControl.Intf;

const
  /// <summary>MOUSESIZE: the picture of the pointer is 16 x 16 pixels</summary>
  GREED_MOUSE_SIZE = 16;
  /// <summary>mousehx and mousehy when the program starts: the middle of the screen of 320 x 200</summary>
  GREED_MOUSE_START_X = 160;
  GREED_MOUSE_START_Y = 100;

type
  /// <summary>
  ///   The mouse as d_ints.pas of the original leaves it to the game and to the menus: the record mouse (flags,
  ///   oldflags, dx, dy), the pointer of the menus (mousehx, mousehy, 0..319 and 0..199, moved only while it is
  ///   shown) and the two switches mousevisible and menuusemouse. Read is called by who reads the controls (the
  ///   timer of the original, on the odd tics): the game through its commands, a menu through its input
  /// </summary>
  IGreedMouse = interface
    ['{6E0C4B1F-83D2-4A57-9B36-F1D7A52C0E94}']
    /// <summary>INT_ReadMouse: the buttons, how far the cursor is from where it was put, then ResetMouse</summary>
    procedure Read;
    /// <summary>ResetMouse: the cursor of the system goes back to the middle of the window</summary>
    procedure Reset;
    /// <summary>mouse.flags: 1 the left button (fire), 2 the right (use), 4 the middle (north)</summary>
    function IsDown(AButton: TGreedMouseButton): Boolean;
    /// <summary>mouse.dx and mouse.dy of the last reading: left and up are positive</summary>
    function GetDeltaX: Integer;
    function GetDeltaY: Integer;
    /// <summary>
    ///   MouseGetClick: True once when the left button went down between the last two readings, with the pointer
    ///   rounded to a pixel of the screen of 320 x 200; always False when the menus do not use the mouse
    /// </summary>
    function TakeClick(out AX, AY: Integer): Boolean;
    /// <summary>MouseShow: the pointer is shown, and moves, if the menus use the mouse</summary>
    procedure Show;
    /// <summary>MouseHide</summary>
    procedure Hide;
    /// <summary>mousevisible</summary>
    function IsVisible: Boolean;
    /// <summary>mousehx and mousehy (float of the original: single)</summary>
    function GetPointerX: Single;
    function GetPointerY: Single;
    /// <summary>menuusemouse (the setting menumouse)</summary>
    function GetMenuEnabled: Boolean;
    procedure SetMenuEnabled(AValue: Boolean);
    property DeltaX: Integer read GetDeltaX;
    property DeltaY: Integer read GetDeltaY;
    property PointerX: Single read GetPointerX;
    property PointerY: Single read GetPointerY;
    property MenuEnabled: Boolean read GetMenuEnabled write SetMenuEnabled;
  end;

  /// <summary>What a script of keys does to a mouse that has no hardware (TGreedScriptMouse)</summary>
  IGreedScriptMouse = interface
    ['{B81D3F70-5C2A-49E6-8A04-7D6E1F93C2B5}']
    /// <summary>The cursor moves ADeltaX pixels to the right and ADeltaY down (the next reading sees it)</summary>
    procedure Move(ADeltaX, ADeltaY: Integer);
    /// <summary>A button goes down or up: fire is the left one, use the right, north the middle</summary>
    procedure SetButton(AButton: TGreedMouseButton; ADown: Boolean);
    /// <summary>
    ///   A click of the left button at the pixel (AX, AY) of the screen of 320 x 200, made of four readings of the
    ///   mouse: the pointer goes to the top left corner (as far as it stops), then to the pixel, then the button
    ///   goes down, then up. It works where the pointer is shown (a menu); the clicks wait for each other
    /// </summary>
    procedure Click(AX, AY: Integer);
  end;

implementation

end.
