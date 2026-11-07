{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - the shared types and constants                }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.Types;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

const
  /// <summary>Bits of the fractional part of the map coordinates of the automap</summary>
  AUTOMAP_MAPBITS = 12;
  /// <summary>One unit of the automap (4096): map coordinates have 12 fractional bits</summary>
  AUTOMAP_MAPUNIT = 1 shl AUTOMAP_MAPBITS;
  /// <summary>Shift from the 16.16 coordinates of the level to the ones of the automap</summary>
  AUTOMAP_FRACTOMAPBITS = FIXED_FRACBITS - AUTOMAP_MAPBITS;
  /// <summary>Divisor from the 16.16 coordinates of the level to the ones of the automap (16)</summary>
  AUTOMAP_FRACTOMAPUNIT = 1 shl AUTOMAP_FRACTOMAPBITS;
  /// <summary>Radius of the player in map coordinates</summary>
  AUTOMAP_PLAYERRADIUS = 16 * (1 shl AUTOMAP_MAPBITS);
  /// <summary>How many marks the automap keeps</summary>
  AUTOMAP_MAX_MARKS = 10;
  /// <summary>Scale (map to frame buffer) when a level starts, before it is fitted</summary>
  AUTOMAP_INITIAL_SCALE = FIXED_ONE div 5;
  /// <summary>How much the window zooms in at each tic (1.02)</summary>
  AUTOMAP_ZOOM_IN = Trunc(1.02 * FIXED_ONE);
  /// <summary>How much the window zooms out at each tic (1 / 1.02)</summary>
  AUTOMAP_ZOOM_OUT = Trunc(FIXED_ONE / 1.02);
  /// <summary>
  ///   The value of the old D_PI: it is not the real pi, and the lines of the characters of the
  ///   automap (the player arrow, the things) were rotated with it
  /// </summary>
  AUTOMAP_PI = 3.141592657;
  /// <summary>Radians of one unit of an angle (a full turn is $100000000)</summary>
  AUTOMAP_ANGLE_TO_RADIANS = 2 * AUTOMAP_PI / $100000000;

type
  /// <summary>A point of the map in fixed point (the old mpoint_t)</summary>
  TAutomapPoint = record
    X: TFixed;
    Y: TFixed;
  end;
  PAutomapPoint = ^TAutomapPoint;

  /// <summary>A line of the map (the old mline_t)</summary>
  TAutomapLine = record
    A: TAutomapPoint;
    B: TAutomapPoint;
  end;
  PAutomapLine = ^TAutomapLine;

  /// <summary>A point of the frame buffer in pixels (the old fpoint_t)</summary>
  TAutomapFramePoint = record
    X: Integer;
    Y: Integer;
  end;
  PAutomapFramePoint = ^TAutomapFramePoint;

  /// <summary>A line of the frame buffer (the old fline_t)</summary>
  TAutomapFrameLine = record
    A: TAutomapFramePoint;
    B: TAutomapFramePoint;
  end;
  PAutomapFrameLine = ^TAutomapFrameLine;

  /// <summary>
  ///   The window of the automap: where it is on the screen (frame), which part of the map it
  ///   shows, and the scale between the two. These are the old f_x, f_y, f_w, f_h, m_x, m_y, m_x2,
  ///   m_y2, m_w, m_h, scale_mtof and scale_ftom
  /// </summary>
  TAutomapWindow = record
    FrameX: Integer;
    FrameY: Integer;
    FrameWidth: Integer;
    FrameHeight: Integer;
    /// <summary>Lower left corner of the window on the map</summary>
    MapX: TFixed;
    MapY: TFixed;
    /// <summary>Upper right corner of the window on the map</summary>
    MapX2: TFixed;
    MapY2: TFixed;
    MapWidth: TFixed;
    MapHeight: TFixed;
    /// <summary>Scale from map to frame buffer</summary>
    ScaleMapToFrame: TFixed;
    /// <summary>Scale from frame buffer to map (1 / ScaleMapToFrame)</summary>
    ScaleFrameToMap: TFixed;
  end;

  /// <summary>Raised when a call of the library is wrong (for instance a mark that does not exist)</summary>
  EAutomapException = class(Exception);

const
  SMarkIndexOutOfRange = 'The automap has no mark with index %d';

implementation

end.
