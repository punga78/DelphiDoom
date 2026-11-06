{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the contracts                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types;

type
  /// <summary>Clips a column of posts and copies it into a column of pixels</summary>
  IImagingColumnPainter = interface
    ['{8E3F5A12-6B47-4D90-A1C8-2F7D03E96B54}']
    /// <summary>
    ///   Copies the posts of the column that starts at ASourceOffset (the header of its first
    ///   post) into ACache, a column of ACacheHeight pixels that starts at ACacheOffset, with its
    ///   top at AOriginY. When AMarks is not empty the pixels that were written are marked
    ///   with $FF, from AMarksOffset
    /// </summary>
    procedure Paint(const ASource: TBytes; ASourceOffset: Integer; var ACache: TBytes;
      ACacheOffset, AOriginY, ACacheHeight: Integer; const AMarks: TBytes;
      AMarksOffset: Integer);
  end;

  /// <summary>Writes again the posts of a column from the transparency marks of its pixels</summary>
  IImagingColumnRebuilder = interface
    ['{B41D7C69-0E25-4A38-9F6B-5C18A2D7E403}']
    /// <summary>
    ///   ABlock has, from AColumnOffset, the header of the first post followed by AHeight
    ///   pixels; the posts are written there, in place, from the pixels and the AHeight marks
    ///   that start at AMarksOffset. The column ends with a topdelta of $FF
    /// </summary>
    procedure Rebuild(var ABlock: TBytes; AColumnOffset: Integer; const AMarks: TBytes;
      AMarksOffset, AHeight: Integer);
  end;

  /// <summary>Makes the columns of a texture that the renderer needs at a fixed height</summary>
  IImagingFixedColumnBuilder = interface
    ['{2A96E0B8-D713-4C54-8B2F-91E4C07A5D36}']
    /// <summary>A column of AHeight pixels (1..128) repeated until it is 128 pixels tall</summary>
    function Repeat128(const ASource: TBytes; ASourceOffset, AHeight: Integer): TBytes;
    /// <summary>The pixels of a column of posts laid out in a column of AHeight pixels (0 where there is no post)</summary>
    function FromPosts(const AColumn: TBytes; AColumnOffset, AHeight: Integer): TBytes;
  end;

  /// <summary>Decodes the lump of a patch</summary>
  IImagingPatchReader = interface
    ['{C7058F3D-4AE1-4B96-A2D4-E83B6F10927C}']
    function Read(const ALump: TBytes): TImagingPatchImage;
  end;

  /// <summary>Converts the lump of a flat to 32 bit pixels</summary>
  IImagingFlatReader = interface
    ['{5F82D1A4-93C6-4E07-B5A9-7D40C2E8136B}']
    /// <param name="ALump">The bytes of the lump</param>
    /// <param name="APalette">The 256 colors of the palette</param>
    /// <param name="AInfoSizeIndex">The size that FLATINFO gave to the flat (0: it comes from the length of the lump)</param>
    function Read(const ALump: TBytes; const APalette: TImagingPixels;
      AInfoSizeIndex: Integer): TImagingFlatImage;
  end;

  /// <summary>Reduces a flat of any size to the 64x64 one</summary>
  IImagingFlatShrinker = interface
    ['{19B4E7C3-5D08-4F72-A691-3E5A8D02B7F4}']
    /// <summary>
    ///   Takes the pixels of the flat (64x64 or 64x128 as they are, from 128x128 to 4096x4096 one
    ///   every so many); false when the size of the lump is not one of the flats
    /// </summary>
    function Shrink(const AFlat: TBytes; out AResult: TBytes): Boolean;
  end;

  /// <summary>Makes bigger the 64x64 flats, with a filter</summary>
  IImagingSpanGrower = interface
    ['{E0A37B58-2C91-4D6F-8B14-A5D7F396C082}']
    /// <summary>The 4096 pixels of a 64x64 flat as 16384 pixels (128x128)</summary>
    function Grow64to128(const ASource: TImagingPixels): TImagingPixels;
    /// <summary>The 4096 pixels of a 64x64 flat as 65536 pixels (256x256)</summary>
    function Grow64to256(const ASource: TImagingPixels): TImagingPixels;
    /// <summary>The 4096 pixels of a 64x64 flat as 262144 pixels (512x512): the slow one</summary>
    function Grow64to512(const ASource: TImagingPixels): TImagingPixels;
  end;

  /// <summary>Interpolates the 128 pixels of a column to a multiple of them</summary>
  IImagingColumnExpander = interface
    ['{4D6C92F1-A387-4B05-9E48-B1F0D3A7C625}']
    /// <summary>
    ///   Expands in place the 128 pixels of ABuffer to 129 * AFactor ones: the buffer must be
    ///   that long
    /// </summary>
    procedure Expand(var ABuffer: TImagingPixels; AFactor: Integer);
  end;

  /// <summary>Makes the tables that blend two colors of a palette</summary>
  IImagingHiResTableBuilder = interface
    ['{A8F5130E-7B94-4C26-95D8-60E2B4C71A39}']
    /// <summary>
    ///   The table of the blends of the colors of APalette (256 colors): IMAGING_HIRES_FACTOR
    ///   levels of 256 x 256 colors, the index of (level, first, second) is
    ///   (level * 256 + first) * 256 + second
    /// </summary>
    function Build(const APalette: TImagingPixels): TImagingPixels;
  end;

  /// <summary>A source of random bytes (the engine gives the one that its demos need)</summary>
  IImagingRandom = interface
    ['{63B90E2A-F514-48D7-A3C6-1D82E57F0B94}']
    function NextByte: Byte;
  end;

  /// <summary>The melt of the screen of the end of a level</summary>
  IImagingMeltWipe = interface
    ['{D2417A9C-0E63-4B58-8F17-C95A3E60D482}']
    /// <summary>
    ///   Starts a melt from AStartScreen to AEndScreen (Width * Height pixels each, row after
    ///   row). ADestination is the buffer that the melt fills: it gets the start screen at once
    /// </summary>
    procedure Start(const ASettings: TImagingWipeSettings; const AStartScreen,
      AEndScreen: TImagingPixels; const ADestination: TImagingPixels);
    /// <summary>Moves the columns for ATicks tics; true when the melt is over</summary>
    function Advance(ATicks: Integer): Boolean;
  end;

  /// <summary>The sines of the engine as 16.16 numbers (fixedsine)</summary>
  IImagingSineTable = interface
    ['{7C1E58B3-92A0-4F6D-B84A-35D9F0E27C16}']
    /// <summary>Entry AIndex (0..IMAGING_SINE_TABLE_SIZE - 1)</summary>
    function Sine(AIndex: Integer): Integer;
  end;

  /// <summary>The scale of the texture of a wall at an angle</summary>
  IImagingWallScale = interface
    ['{F3A6D940-1B58-4E72-A0C3-8E7B5D214F69}']
    /// <summary>The scale in 16.16, with the limits of the engine; AOverflow tells that a limit was hit</summary>
    function FromGlobalAngle(const AContext: TImagingScaleContext; AVisAngle: Cardinal;
      out AOverflow: Boolean): Integer;
    /// <summary>The same without the overflow flag</summary>
    function FromGlobalAngleFixed(const AContext: TImagingScaleContext;
      AVisAngle: Cardinal): Integer;
    /// <summary>The same in floating point</summary>
    function FromGlobalAngleDouble(const AContext: TImagingScaleContext;
      AVisAngle: Cardinal): Double;
  end;

implementation

end.
