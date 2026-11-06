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
