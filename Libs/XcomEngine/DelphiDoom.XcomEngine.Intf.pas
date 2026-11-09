{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the contracts of the device (window,       }
{  events, clock, audio) that replace SDL                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Intf;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types;

type
  /// <summary>The window: it shows a picture of 8 bit pixels with a palette (SDL_SetVideoMode and SDL_Flip)</summary>
  IXcomVideoDevice = interface
    ['{4A1E9C73-52B8-4D06-8F31-7C2D95A0E614}']
    /// <summary>(Re)creates the display of the given size; the real size of the window is returned</summary>
    procedure SetMode(var AWidth, AHeight: Integer; AFullscreen: Boolean);
    /// <summary>Shows the picture (AWidth x AHeight pixels, rows from the top) with the palette</summary>
    procedure Present(const APixels: TBytes; AWidth, AHeight: Integer; const APalette: TXcomColors);
    procedure SetTitle(const ATitle: string);
  end;

  /// <summary>Where the events come from (SDL_PollEvent)</summary>
  IXcomEventSource = interface
    ['{B7D30F58-1A6E-4C92-9E45-D81F2B70A3C6}']
    /// <summary>The next event, or false if there is none</summary>
    function Poll(out AEvent: TXcomInputEvent): Boolean;
    /// <summary>The position of the mouse and the buttons down as a mask (SDL_GetMouseState)</summary>
    function MouseState(out AX, AY: Integer): Integer;
    /// <summary>The modifier keys that are down (SDL_GetModState)</summary>
    function ModifierState: Integer;
  end;

  /// <summary>The clock in milliseconds (SDL_GetTicks) and the wait (SDL_Delay)</summary>
  IXcomClock = interface
    ['{E26B84A1-9F03-47D5-B618-3A5C0D7E92F4}']
    function Ticks: Cardinal;
    procedure Delay(AMilliseconds: Cardinal);
  end;

  /// <summary>The audio output; OpenXcom plays sounds and music through it (not used by the menus)</summary>
  IXcomAudioDevice = interface
    ['{0C58D7E3-6B29-4A14-A3F0-9E81B2C45D76}']
    function IsAvailable: Boolean;
    procedure SetVolume(ASound, AMusic, AUi: Integer);
  end;

  /// <summary>The files of the game and of the user, by path (CrossPlatform of OpenXcom: fileExists, readFile...)</summary>
  IXcomFileSystem = interface
    ['{7D2C6A15-E984-4B3F-A0D1-5F8B3E1C9A47}']
    function FileExists(const APath: string): Boolean;
    function FolderExists(const APath: string): Boolean;
    function ReadAll(const APath: string): TBytes;
    procedure WriteAll(const APath: string; const ABytes: TBytes);
    /// <summary>The names (without extension) of the files of a folder that have the extension, sorted</summary>
    function FolderContents(const AFolder, AExtension: string): TArray<string>;
  end;

  /// <summary>Where the log goes (Log(LOG_INFO))</summary>
  IXcomLog = interface
    ['{91F4A2B6-3D80-4E57-B1C9-6A07E5D83F12}']
    procedure Write(const ALevel, AMessage: string);
  end;

implementation

end.
