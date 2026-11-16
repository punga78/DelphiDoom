{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL automap - the shared types                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlAutomap.Types;

interface

uses
  System.SysUtils;

type
  /// <summary>What an item of the automap of a frame is</summary>
  TGlAutomapItemKind = (
    /// <summary>The rectangle that clears the frame of the map</summary>
    gakBackground,
    /// <summary>A line of one colour</summary>
    gakLine,
    /// <summary>A triangle of the floor of a sector (textured automap)</summary>
    gakTriangle,
    /// <summary>A patch (the number of a mark)</summary>
    gakPatch);

  /// <summary>What a triangle needs of the floor of its sector, as the sector has it (fixed point and angles)</summary>
  TGlAutomapFloor = record
    /// <summary>The number of the flat of the floor</summary>
    Flat: Integer;
    /// <summary>The floor ripples (the texture changes with the time of the level)</summary>
    Ripples: Boolean;
    /// <summary>The offsets of the texture, 16.16 fixed point (zero where the game has no offsets)</summary>
    OffsetX: Integer;
    OffsetY: Integer;
    /// <summary>The rotation of the texture (the whole circle is $FFFFFFFF) and its centre, 16.16 fixed point</summary>
    Angle: Cardinal;
    AngleX: Integer;
    AngleY: Integer;
  end;

  /// <summary>One item of the automap of a frame, ready to be drawn</summary>
  /// <remarks>Every kind fills only its own fields; the others keep what the last item in that place had</remarks>
  TGlAutomapItem = record
    Kind: TGlAutomapItemKind;
    /// <summary>The corners in pixels of the frame (a line has two, a patch one, the background the size)</summary>
    X1, Y1, X2, Y2, X3, Y3: Integer;
    /// <summary>The coordinates of the texture at the corners, in flats (64 units of the map)</summary>
    U1, V1, U2, V2, U3, V3: Single;
    Lump: Integer;
    Flat: Integer;
    Ripples: Boolean;
    OffsetX: Integer;
    OffsetY: Integer;
    HasAngle: Boolean;
    /// <summary>The rotation in degrees and its centre in flats</summary>
    Angle: Single;
    AngleX: Single;
    AngleY: Single;
    Red, Green, Blue: Single;
  end;
  PGlAutomapItem = ^TGlAutomapItem;

  /// <summary>Raised by the classes of the OpenGL automap</summary>
  EGlAutomapException = class(Exception);

implementation

end.
