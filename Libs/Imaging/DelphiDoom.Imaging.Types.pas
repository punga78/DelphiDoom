{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - shared types and constants                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Bits of the fractional part of a 16.16 fixed point number</summary>
  IMAGING_FRACBITS = 16;
  IMAGING_FRACUNIT = 1 shl IMAGING_FRACBITS;
  /// <summary>The topdelta that closes a column of posts</summary>
  IMAGING_POST_END = $FF;
  /// <summary>Side of the base flat, and its number of pixels</summary>
  IMAGING_FLAT_SIDE = 64;
  IMAGING_FLAT_PIXELS = IMAGING_FLAT_SIDE * IMAGING_FLAT_SIDE;
  /// <summary>The flats go from 64x64 (index 0) to 4096x4096 (index 6)</summary>
  IMAGING_FLAT_MAX_INDEX = 6;
  /// <summary>Levels of interpolation of the hi-resolution tables</summary>
  IMAGING_HIRES_BITS = 3;
  IMAGING_HIRES_FACTOR = 1 shl IMAGING_HIRES_BITS;
  /// <summary>Entries of the palettes</summary>
  IMAGING_PALETTE_SIZE = 256;
  /// <summary>An angle of 90 degrees in the 32 bit binary angles of the engine</summary>
  IMAGING_ANGLE_90 = $40000000;
  /// <summary>
  ///   The value of pi that the engine uses (it is not the exact one: 3.141592657); kept
  ///   because the results of the engine depend on it
  /// </summary>
  IMAGING_PI = 3.141592657;
  IMAGING_ANGLE_TO_RADIANS = 2 * IMAGING_PI / $100000000;
  /// <summary>Entries of the table of the sines: five quarters of the circle at 16 bits</summary>
  IMAGING_SINE_TABLE_SIZE = (5 * IMAGING_FRACUNIT) div 4;

type
  /// <summary>Raised when the data are not what the library needs (truncated, out of bounds ...)</summary>
  EImagingException = class(Exception);

  /// <summary>Pixels of 32 bits, $00BBGGRR: the red one is the low byte, as in the engine</summary>
  TImagingPixels = TArray<Cardinal>;

  /// <summary>The header of a patch of Doom (packed, 8 bytes, same on 32 and 64 bits)</summary>
  TImagingPatchHeader = packed record
    Width: SmallInt;
    Height: SmallInt;
    LeftOffset: SmallInt;
    TopOffset: SmallInt;
  end;

  /// <summary>The header of a post of a column (3 bytes: the data come after it)</summary>
  TImagingPostHeader = packed record
    TopDelta: Byte;
    Length: Byte;
    Padding: Byte;
  end;

  /// <summary>A decoded patch: pixels of the palette in rows, and which of them are opaque</summary>
  TImagingPatchImage = record
    Width: Integer;
    Height: Integer;
    LeftOffset: Integer;
    TopOffset: Integer;
    /// <summary>Width * Height bytes, row by row; 0 where the patch is transparent</summary>
    Pixels: TBytes;
    /// <summary>Width * Height bytes, $FF where a post covers the pixel and 0 elsewhere</summary>
    Opaque: TBytes;
  end;

  /// <summary>A flat as 32 bit pixels</summary>
  TImagingFlatImage = record
    /// <summary>The side of the flat (64, 128, 256 ...)</summary>
    Side: Integer;
    /// <summary>Side * Side pixels</summary>
    Pixels: TImagingPixels;
  end;

  /// <summary>How a melt wipe writes: the sizes of the screen and of the buffer that it fills</summary>
  TImagingWipeSettings = record
    Width: Integer;
    Height: Integer;
    /// <summary>Pixels between two rows of the destination (Width for the software renderer, the power of two for OpenGL)</summary>
    DestinationPitch: Integer;
    /// <summary>Or-ed to the pixels that the melt copies ($FF000000 for OpenGL, 0 for the software renderer)</summary>
    AlphaMask: Cardinal;
  end;

  /// <summary>What the scale of a wall depends on: the values that the engine keeps in globals</summary>
  TImagingScaleContext = record
    ViewAngle: Cardinal;
    NormalAngle: Cardinal;
    Distance: Integer;
    ProjectionY: Integer;
    MaxScale: Integer;
    /// <summary>True when an overflow of the scale must be reported (precisescalefromglobalangle)</summary>
    PreciseOverflow: Boolean;
  end;

resourcestring
  SImagingColumnWithoutEnd = 'The column does not end inside the data';
  SImagingPostTruncated = 'A post of the column goes past the end of the data';
  SImagingCacheTooSmall = 'The cache of the column is smaller than the height that was asked for';
  SImagingMarksTooSmall = 'The transparency marks are smaller than the height that was asked for';
  SImagingBadHeight = 'The height of the column is not valid';
  SImagingRebuildDiverges = 'The column cannot be rebuilt: the offsets of its posts do not converge';
  SImagingRebuildOverflow = 'The rebuilt column does not fit its block';
  SImagingPatchTruncated = 'The patch is shorter than its header and its table of columns';
  SImagingPatchBadSize = 'The patch has a negative width or height';
  SImagingPatchBadColumn = 'A column of the patch starts outside the lump';
  SImagingBadPalette = 'A palette needs 256 colors';
  SImagingBadFlatIndex = 'The index of the size of a flat is not valid';
  SImagingSpanTooSmall = 'A 64x64 span needs 4096 pixels';
  SImagingBufferTooSmall = 'The buffer is smaller than the algorithm needs';
  SImagingBadFactor = 'The factor of the expansion is not valid';
  SImagingBadWipeSettings = 'The settings of the wipe are not valid';
  SImagingWipeNotStarted = 'The wipe has not been started';
  SImagingWipeBufferSize = 'A buffer of the wipe is smaller than the screen';
  SImagingBadSineTable = 'The table of the sines needs five quarters of the circle';

implementation

end.
