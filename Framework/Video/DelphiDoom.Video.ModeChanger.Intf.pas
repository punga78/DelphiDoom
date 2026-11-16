{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the contracts of the change of the video mode    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.ModeChanger.Intf;

interface

type
  /// <summary>
  ///   What the change of the video mode needs from the engine: the size of the window and of the screen, the
  ///   window of the game, the resolution of the desktop and the messages. The engine gives it (the window, the
  ///   globals of the sizes); a fake gives it in the tests
  /// </summary>
  IVideoModeHost = interface
    ['{4C2E7A19-D0B3-4F65-9A81-3E7B5C60D2F4}']
    function GetWindowWidth: Integer;
    function GetWindowHeight: Integer;
    procedure SetWindowSize(const AWidth, AHeight: Integer);
    /// <summary>The width of the rendering screen</summary>
    function GetScreenWidth: Integer;
    /// <summary>The height of the rendering screen</summary>
    function GetScreenHeight: Integer;
    /// <summary>Works out the window of a mode (WindowWidth and WindowHeight)</summary>
    procedure FindWindowSize(const AMode: Integer);
    /// <summary>Keeps the window inside the desktop</summary>
    procedure AdjustWindowMode;
    /// <summary>Gives the window its style and its place for AMode</summary>
    procedure RestoreWindowPosition(const AMode: Integer);
    procedure DisableAltTab;
    procedure EnableAltTab;
    /// <summary>Changes the resolution of the desktop; false when the system refuses</summary>
    function ChangeResolution(const AWidth, AHeight: Integer): Boolean;
    /// <summary>Gives back the resolution of the desktop that the user chose</summary>
    procedure RestoreResolution;
    /// <summary>Narrows the screen when its width is one of the slow ones; true when it did</summary>
    function ApplyMemoryStallHack: Boolean;
    /// <summary>Builds the screens of the renderer again (the width changed)</summary>
    procedure ReinitializeScreens;
    procedure RefreshDpi;
    procedure Warn(const AMessage: string);
    procedure Print(const AMessage: string);

    property WindowWidth: Integer read GetWindowWidth;
    property WindowHeight: Integer read GetWindowHeight;
    property ScreenWidth: Integer read GetScreenWidth;
    property ScreenHeight: Integer read GetScreenHeight;
  end;

  /// <summary>The sequences of the full screen modes of the software video: start and change</summary>
  IVideoModeChanger = interface
    ['{B8D13F57-6E24-4A90-85C7-1F0A9D3E4B62}']
    /// <summary>
    ///   The window and the resolution at the start of the video: AFullScreen is brought inside the known modes and
    ///   it is the shared window mode when the exclusive one fails
    /// </summary>
    procedure Initialize(var AFullScreen: Integer);
    /// <summary>Moves to ANewMode (shared, exclusive or window); AFullScreen is the new mode when it worked</summary>
    procedure ChangeFullScreen(const ANewMode: Integer; var AFullScreen: Integer);
    /// <summary>The end of the video: the resolution of the desktop comes back and the Alt+Tab key is free</summary>
    procedure Release;
    function GetResolutionChanged: Boolean;
    /// <summary>True while the resolution of the desktop is not the one the user chose</summary>
    property ResolutionChanged: Boolean read GetResolutionChanged;
  end;

implementation

end.
