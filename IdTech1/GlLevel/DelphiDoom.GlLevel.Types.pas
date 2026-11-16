{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL level geometry - the shared types                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlLevel.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>The old limit of the points of a polygon being carved (the polygon needs less than this)</summary>
  GLLEVEL_MAX_CARVER_SIDES = 64;
  /// <summary>The flag of the child of a node that is a subsector (NF_SUBSECTOR)</summary>
  GLLEVEL_NODE_SUBSECTOR = $8000;

type
  /// <summary>A point of the map in 16.16 fixed point</summary>
  TGlFixedPoint = record
    X: Integer;
    Y: Integer;
  end;
  PGlFixedPoint = ^TGlFixedPoint;

  /// <summary>A line of a partition (divline_t): a point and a direction, in 16.16 fixed point</summary>
  TGlDivLine = record
    X: Integer;
    Y: Integer;
    DX: Integer;
    DY: Integer;
  end;

  /// <summary>A node of the BSP: its partition line and its two children (a subsector has the flag of GLLEVEL_NODE_SUBSECTOR)</summary>
  TGlCarverNode = record
    Line: TGlDivLine;
    Children: array[0..1] of Integer;
  end;

  /// <summary>A subsector: its sector and its run of segs</summary>
  TGlCarverSubsector = record
    SectorId: Integer;
    FirstLine: Integer;
    LineCount: Integer;
  end;

  /// <summary>A seg: only the vertexes are needed</summary>
  TGlCarverSeg = record
    Start: TGlFixedPoint;
    Finish: TGlFixedPoint;
  end;

  /// <summary>
  ///   A line of a sector as the preprocessor of the sectors reads it: the numbers of its two vertexes in the
  ///   vertex array of the level (a number outside the array is a line the old code stopped at) and, if it has
  ///   both sides, the top and bottom textures of each side (zero = no texture)
  /// </summary>
  TGlSectorLine = record
    Vertex1: Integer;
    Vertex2: Integer;
    HasBothSides: Boolean;
    FrontTopTexture: Integer;
    FrontBottomTexture: Integer;
    BackTopTexture: Integer;
    BackBottomTexture: Integer;
  end;

  /// <summary>Is a sector closed (a sector that gets no flat)</summary>
  TGlSectorClosed = reference to function(const ASectorId: Integer): Boolean;

  /// <summary>The carver found a polygon with too many sides</summary>
  EGlLevelException = class(Exception);

resourcestring
  SGlLevelTooManyPoints = 'gld_FlatEdgeClipper(): Too many points in carver';

implementation

end.
