{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the contracts                                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.Intf;

interface

uses
  DelphiDoom.Video.Types;

type
  /// <summary>From the palette of the game (256 colors of R, G, B) to colors of the screen</summary>
  IPaletteConverter = interface
    ['{4B7E2D91-A5C8-4F03-9E16-D70B3A8C5E42}']
    /// <summary>
    ///   Every color goes through the gamma table (256 bytes) and is packed as $00RRGGBB.
    ///   ASource has 256 * 3 bytes, ADest 256 values
    /// </summary>
    procedure Convert(ASource: PByte; AGamma: PByte; ADest: PCardinal);
  end;

  /// <summary>The size of the main screen of the computer</summary>
  IDisplayMetrics = interface
    ['{F1A83C60-27D5-4B9E-8C34-0E65B9D17A28}']
    function GetWidth: Integer;
    function GetHeight: Integer;
    property Width: Integer read GetWidth;
    property Height: Integer read GetHeight;
  end;

  /// <summary>
  ///   The size of the rendering screen that the command line asks for (-screenwidth,
  ///   -screenheight, -geom, -fullhd, -vga, -svga, -cga, -cgaX2, -cgaX3): the old size part of
  ///   D_CheckCommonParams
  /// </summary>
  IScreenSizeResolver = interface
    ['{2E5A91D3-7C48-4B06-A3F7-9D10C86B54E2}']
    /// <summary>
    ///   AWidth and AHeight are the size so far (-1 is "the size of the desktop"); the result is
    ///   the size after the options of the command line, always inside the limits
    /// </summary>
    procedure Resolve(var AWidth, AHeight: Integer);
  end;

  /// <summary>A window cannot be bigger than the screen</summary>
  ISizeLimiter = interface
    ['{83D5E0B7-9C14-4A62-B1F8-6A2C4E7D0953}']
    /// <summary>Reduces what is too big; true when something was reduced</summary>
    function Limit(var AWidth, AHeight: Integer): Boolean;
  end;

  /// <summary>
  ///   Some widths (1024, 1152, 1280) make the memory stall: the screen is two pixels narrower
  /// </summary>
  IMemoryStallHack = interface
    ['{2C60F9A4-5E7B-4D18-A3C2-B84D1E9F6037}']
    /// <summary>
    ///   Reduces the width if it is one of those and AEnabled. The result is true if the width
    ///   is in the hack: it stays true until another, different width is given
    /// </summary>
    function Apply(var AScreenWidth: Integer; AEnabled: Boolean): Boolean;
  end;

  /// <summary>Where the screen modes come from: the graphics system of the computer</summary>
  IDisplayModeSource = interface
    ['{5D1E7A32-B8C4-4F96-A0D3-27E94C6B1F58}']
    /// <summary>Every mode the system knows, in its order, with repetitions</summary>
    function ListModes: TArray<TDisplayMode>;
  end;

  /// <summary>The screen modes the game can choose from, sorted by width then height</summary>
  IDisplayModeCatalog = interface
    ['{C3A09E64-1F7D-4B85-9E2A-D6B4057F3C91}']
    function GetCount: Integer;
    function GetMode(AIndex: Integer): TDisplayMode;
    /// <summary>
    ///   Asks the source again. Keeps the 32 bit modes of at least 320x200 and not bigger than
    ///   AMaxWidth x AMaxHeight; if there are none, the modes of at least 16 bits and 640x400;
    ///   if there are still none, 320x200 and 640x400
    /// </summary>
    procedure Refresh(AMaxWidth, AMaxHeight: Integer);
    procedure Clear;
    /// <summary>The index of the mode with exactly this size, or -1</summary>
    function IndexOf(AWidth, AHeight: Integer): Integer;
    /// <summary>
    ///   The index of the mode that is nearest to this size (a mode bigger than the size counts 50
    ///   more for each side), the exact one if there is; -1 without modes
    /// </summary>
    function NearestIndex(AWidth, AHeight: Integer): Integer;
    /// <summary>
    ///   The size of the window for a screen: the exact mode or the nearest one. False without
    ///   modes: the window is as big as the screen of the computer
    /// </summary>
    function FindWindowSize(AScreenWidth, AScreenHeight: Integer;
      out AWindowWidth, AWindowHeight: Integer): Boolean;
    property Count: Integer read GetCount;
    property Modes[AIndex: Integer]: TDisplayMode read GetMode; default;
  end;

  /// <summary>What the engine does when a deferred notification is run</summary>
  IDisplayModeApplier = interface
    ['{3D9B6E48-C0A1-4752-8F3E-A7D52B81F094}']
    /// <summary>Changes the display mode of the screen to this size</summary>
    procedure ApplyDisplayMode(AWidth, AHeight: Integer);
    /// <summary>Tells the OpenGL window about its display mode (nothing without OpenGL)</summary>
    procedure ApplyGLDisplayMode;
  end;

  /// <summary>
  ///   Changes that the menus and the renderer ask for in the middle of a frame and that the game
  ///   loop does between two frames (D_NotifyVideoModeChange, D_RunNotifications)
  /// </summary>
  IDeferredNotifications = interface
    ['{91E5A0C3-48D7-4B2F-A6B9-2C70F3E8D15A}']
    /// <summary>A new display mode is asked for: the last request before Run wins</summary>
    procedure NotifyVideoModeChange(AWidth, AHeight: Integer);
    procedure NotifyGLDisplayMode;
    /// <summary>Does what is asked, the mode first, and forgets it</summary>
    procedure Run;
  end;

  /// <summary>What the video of the engine needs that does not depend on the graphics API</summary>
  IVideoServices = interface
    ['{A9F4C713-0D82-4E5B-96A7-1B3E58C2D406}']
    function GetPalette: IPaletteConverter;
    function GetSizeLimiter: ISizeLimiter;
    function GetStallHack: IMemoryStallHack;
    property Palette: IPaletteConverter read GetPalette;
    property SizeLimiter: ISizeLimiter read GetSizeLimiter;
    property StallHack: IMemoryStallHack read GetStallHack;
  end;

implementation

end.
