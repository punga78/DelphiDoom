{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - what the lump RMAP of a level says              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.MapInfo.Types;

interface

type
  /// <summary>Which statements of RMAP were given for a sector</summary>
  TRadixSectorStatement = (rssFloorSlope, rssCeilingSlope, rssXMul, rssXAdd, rssYMul, rssYAdd,
    rssFloorAngle, rssFloorAngleX, rssFloorAngleY, rssCeilingAngle, rssCeilingAngleX, rssCeilingAngleY,
    rssHeightNodesX, rssHeightNodesY, rssFloorHeights, rssCeilingHeights, rssFlags);
  TRadixSectorStatements = set of TRadixSectorStatement;

  /// <summary>Which statements of RMAP were given for a wall (a line of the Doom map)</summary>
  TRadixWallStatement = (rwsFlags, rwsHitPoints, rwsTrigger, rwsBriefingIgnore);
  TRadixWallStatements = set of TRadixWallStatement;

  /// <summary>The plane a * x + b * y + c * z + d = 0 as RADIX.DAT has it (integers, fixed point)</summary>
  TRadixPlaneEquation = record
    A: Integer;
    B: Integer;
    C: Integer;
    D: Integer;
  end;

  TRadixTriple = array[0..2] of Integer;

  /// <summary>
  ///   What RMAP says of a sector. Statements tells which fields were given; the others have the
  ///   values of a sector that RMAP does not name (XMul and YMul 1, the rest 0)
  /// </summary>
  TRadixSectorInfo = record
    SectorId: Integer;
    Statements: TRadixSectorStatements;
    FloorSlope: TRadixPlaneEquation;
    CeilingSlope: TRadixPlaneEquation;
    /// <summary>Doom x = XMul * radix x + XAdd; XMul and YMul are 1 or -1</summary>
    XMul: Integer;
    XAdd: Integer;
    YMul: Integer;
    YAdd: Integer;
    /// <summary>The angle of the floor texture as RADIX.DAT has it (0..4095; 2048 is half a turn)</summary>
    FloorAngle: Cardinal;
    FloorAngleX: Cardinal;
    FloorAngleY: Cardinal;
    CeilingAngle: Cardinal;
    CeilingAngleX: Cardinal;
    CeilingAngleY: Cardinal;
    /// <summary>The three points (in the coordinates of RADIX.DAT) that give the planes of the slopes</summary>
    HeightNodesX: TRadixTriple;
    HeightNodesY: TRadixTriple;
    FloorHeights: TRadixTriple;
    CeilingHeights: TRadixTriple;
    Flags: Integer;
  end;

  /// <summary>What RMAP says of a wall</summary>
  TRadixWallInfo = record
    WallId: Integer;
    Statements: TRadixWallStatements;
    Flags: Integer;
    HitPoints: Integer;
    Trigger: Integer;
  end;

  /// <summary>The whole RMAP: the sectors and the walls it names, each once, in the order of their first statement</summary>
  TRadixMapInfo = record
    Sectors: TArray<TRadixSectorInfo>;
    Walls: TArray<TRadixWallInfo>;
  end;

  /// <summary>
  ///   A plane as the slopes of the engine want it: z = (-A * x - B * y - D) * InverseC, with x, y
  ///   and z in map units
  /// </summary>
  TRadixSlopePlane = record
    A: Single;
    B: Single;
    InverseC: Single;
    D: Single;
    /// <summary>False when the three points are on a line or the plane is vertical (no slope can be made)</summary>
    Valid: Boolean;
  end;

implementation

end.
