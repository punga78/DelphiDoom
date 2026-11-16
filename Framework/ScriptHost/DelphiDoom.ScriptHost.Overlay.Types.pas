{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - overlay drawer, shared types and constants        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The overlay is a 320x200 buffer of palette indexes that scripts draw into   }
{  (text, patches, pixels, rectangles, lines) and the engine flashes over      }
{  every frame. The record of a drawer is what savegames store: its layout     }
{  (292 bytes) cannot change.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Overlay.Types;

interface

const
  /// <summary>Width of the overlay buffer, in pixels</summary>
  OVERLAYWIDTH = 320;
  /// <summary>Height of the overlay buffer, in pixels</summary>
  OVERLAYHEIGHT = 200;
  /// <summary>Number of pixels of the overlay buffer</summary>
  OVERLAYSIZE = OVERLAYWIDTH * OVERLAYHEIGHT;

  /// <summary>The text is drawn from x to the right</summary>
  OVR_ALIGN_LEFT = 0;
  /// <summary>The text ends at x</summary>
  OVR_ALIGN_RIGHT = 1;
  /// <summary>The text is centered at x</summary>
  OVR_ALIGN_CENTER = 2;

  /// <summary>Drawer kinds, as the savegames store them (0 is a dead drawer)</summary>
  OVR_DRAWTEXT = 1;
  OVR_DRAWPATCH = 2;
  OVR_DRAWPIXEL = 3;
  OVR_DRAWRECT = 4;
  OVR_DRAWLINE = 5;
  OVR_DRAWPATCHSTRETCHED = 6;

  /// <summary>Size of the record of a drawer on a savegame</summary>
  OVERLAY_DRAWER_SIZE = 292;

type
  /// <summary>
  ///   One thing that scripts asked to draw for some tics, as the savegames store it: the fields
  ///   and their order are those of the old overlaydrawer_t (the Pascal short string has 255
  ///   characters: the length byte and the characters)
  /// </summary>
  TOverlayDrawerRecord = packed record
    Kind: Integer;
    Tick: Integer;
    TextParameter: string[255];
    X: Integer;
    Y: Integer;
    Parameter1: Integer;
    Parameter2: Integer;
    Parameter3: Integer;
    X2: Integer;
    Y2: Integer;
  end;
  POverlayDrawerRecord = ^TOverlayDrawerRecord;
  TOverlayDrawerRecordArray = array[0..$FFF] of TOverlayDrawerRecord;
  POverlayDrawerRecordArray = ^TOverlayDrawerRecordArray;

  TOverlayBuffer = packed array[0..OVERLAYSIZE - 1] of Byte;
  POverlayBuffer = ^TOverlayBuffer;
  TOverlayRows = packed array[0..OVERLAYHEIGHT - 1, 0..OVERLAYWIDTH - 1] of Byte;
  POverlayRows = ^TOverlayRows;

  TOverlayIndexes = array[0..OVERLAYSIZE - 1] of Integer;
  POverlayIndexes = ^TOverlayIndexes;

  /// <summary>For every pixel of the screen, the pixel of the overlay that shows through it</summary>
  TOverlayLookup = array[0..$FFFFFF] of PByte;
  POverlayLookup = ^TOverlayLookup;

  /// <summary>The header of a patch (the lump format of Doom: all the numbers little endian)</summary>
  TOverlayPatchHeader = packed record
    Width: SmallInt;
    Height: SmallInt;
    LeftOffset: SmallInt;
    TopOffset: SmallInt;
  end;
  POverlayPatchHeader = ^TOverlayPatchHeader;

  /// <summary>The header of a post of a column of a patch (followed by a padding byte, the pixels and one more)</summary>
  TOverlayPatchPost = packed record
    TopDelta: Byte;
    Length: Byte;
  end;
  POverlayPatchPost = ^TOverlayPatchPost;

  /// <summary>
  ///   What the engine needs to put the overlay over a frame: for every screen pixel in
  ///   [FirstLookup[Start], LastLookup[Finish]] the pixel of the overlay in Lookup
  /// </summary>
  TOverlayFlashData = record
    Lookup: POverlayLookup;
    FirstLookup: POverlayIndexes;
    LastLookup: POverlayIndexes;
    /// <summary>First modified pixel of the overlay</summary>
    Start: Integer;
    /// <summary>Last modified pixel of the overlay</summary>
    Finish: Integer;
  end;
  POverlayFlashData = ^TOverlayFlashData;

implementation

end.
