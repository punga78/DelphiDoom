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
    /// <summary>SDL_WarpMouse: the mouse goes to the position (window pixels) and a motion event is produced</summary>
    procedure WarpMouse(AX, AY: Integer);
  end;

  /// <summary>A size of the display that the video options list (an SDL_Rect of SDL_ListModes)</summary>
  TXcomDisplayMode = record
    Width: Integer;
    Height: Integer;
  end;

  /// <summary>The full screen modes of the display (SDL_ListModes), from the largest to the smallest</summary>
  IXcomDisplayModes = interface
    ['{3F6D1B84-27A5-4E90-B3C8-9A1D5E7F20C6}']
    function Modes: TArray<TXcomDisplayMode>;
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
    /// <summary>Plays a WAV file now (the volume is already in the samples); a sound that is playing is replaced</summary>
    procedure PlayWave(const AWave: TBytes);
    /// <summary>Mix_CloseAudio: the device stops using the game (the game calls it before it releases the device)</summary>
    procedure Close;
  end;

  /// <summary>
  ///   Where the mixer takes the sound to play (what the SDL audio callback asks for): 16 bit samples, left and
  ///   right, at the rate the output was opened with
  /// </summary>
  IXcomPcmSource = interface
    ['{6A2F90C4-1D75-4E38-B8A6-3C0E97D15F42}']
    /// <summary>Fills ABytes bytes (a multiple of 4) of ABuffer with samples; what has no sound is silence</summary>
    procedure Render(ABuffer: PByte; ABytes: Integer);
  end;

  /// <summary>The output of the sound of the machine (SDL_OpenAudio): it asks the source for samples while it is open</summary>
  IXcomPcmOutput = interface
    ['{D81B3E57-4C09-4A62-9F14-B7E5A20C6D38}']
    /// <summary>Opens the device at the rate (16 bit stereo); false when there is no device that can play</summary>
    function Open(ARate: Integer; const ASource: IXcomPcmSource): Boolean;
    /// <summary>Stops asking for samples and closes the device</summary>
    procedure Close;
    function IsOpen: Boolean;
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
