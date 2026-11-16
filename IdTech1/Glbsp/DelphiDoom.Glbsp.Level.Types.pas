{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - in-memory model of a level                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of level.h of glBSP 2.24 (C) 2000-2007 Andrew Apted                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Smallest distance between two points before they are the same</summary>
  DIST_EPSILON = 1.0 / 128.0;

  /// <summary>Smallest degrees between two angles before they are the same</summary>
  ANG_EPSILON = 1.0 / 1024.0;

  /// <summary>
  ///   A line closer than this to the end of a seg is "iffy": splitting there
  ///   would create a very short seg
  /// </summary>
  IFFY_LEN = 4.0;

  /// <summary>Bit 30 of the index of a GL vertex</summary>
  IS_GL_VERTEX = 1 shl 30;

  /// <summary>Segs and blocks: a block is a leaf up to this size</summary>
  SUPERBLOCK_LEAF_SIZE = 256;

type
  /// <summary>Raised when the data of a level is missing or inconsistent</summary>
  EGlbspLevelException = class(Exception);

  TGlbspSector = class;
  TGlbspSidedef = class;
  TGlbspLinedef = class;
  TGlbspVertex = class;
  TGlbspSeg = class;
  TGlbspSubsec = class;
  TGlbspNode = class;
  TGlbspSuperBlock = class;

  /// <summary>
  ///   Where a wall meets a vertex. The tips of a vertex form a list kept
  ///   in anti-clockwise order
  /// </summary>
  TGlbspWallTip = class
  public
    Next: TGlbspWallTip;
    Prev: TGlbspWallTip;
    /// <summary>Angle of the line at the vertex, in degrees</summary>
    Angle: Double;
    /// <summary>Sector on the side of increasing angles; nil for a one sided wall</summary>
    Left: TGlbspSector;
    /// <summary>Sector on the side of decreasing angles; nil for a one sided wall</summary>
    Right: TGlbspSector;
  end;

  TGlbspVertex = class
  public
    X, Y: Double;
    /// <summary>Valid after loading and pruning; bit 30 set for GL vertices</summary>
    Index: Integer;
    RefCount: Integer;
    /// <summary>Vertex at the same place as a previous one (pruning only)</summary>
    Equiv: TGlbspVertex;
    TipSet: TGlbspWallTip;
    /// <summary>Duplicate used when normal and V2 GL nodes are built together</summary>
    NormalDup: TGlbspVertex;
  end;

  TGlbspSector = class
  public
    Index: Integer;
    /// <summary>Allows segs of other sectors in the same subsector</summary>
    Coalesce: Boolean;
    HasPolyobj: Integer;
    RefCount: Integer;
    FloorHeight, CeilingHeight: Integer;
    FloorTex: array[0..7] of AnsiChar;
    CeilingTex: array[0..7] of AnsiChar;
    Light: Integer;
    Special: Integer;
    Tag: Integer;
    // Used to build the REJECT table: sectors isolated from the others share
    // a group number and are linked in a ring
    RejGroup: Integer;
    RejNext: TGlbspSector;
    RejPrev: TGlbspSector;
    WarnedFacing: Integer;
    WarnedUnclosed: Boolean;
  end;

  TGlbspSidedef = class
  public
    /// <summary>Adjacent sector; nil for an invalid sidedef</summary>
    Sector: TGlbspSector;
    XOffset, YOffset: Integer;
    UpperTex: array[0..7] of AnsiChar;
    LowerTex: array[0..7] of AnsiChar;
    MidTex: array[0..7] of AnsiChar;
    Index: Integer;
    RefCount: Integer;
    /// <summary>Identical sidedef found earlier (pruning only)</summary>
    Equiv: TGlbspSidedef;
    /// <summary>The sidedef is on a special line and is never merged</summary>
    OnSpecial: Integer;
  end;

  TGlbspLinedef = class
  public
    Next: TGlbspLinedef;
    Start: TGlbspVertex;
    EndVertex: TGlbspVertex;
    Right: TGlbspSidedef;
    Left: TGlbspSidedef;
    TwoSided: Boolean;
    /// <summary>Prefer not to split the line</summary>
    IsPrecious: Boolean;
    ZeroLength: Boolean;
    SelfRef: Boolean;
    /// <summary>One sided line used as a window: the opposite sector</summary>
    WindowEffect: TGlbspSector;
    Flags: Integer;
    LineType: Integer;
    Tag: Integer;
    Specials: array[0..4] of Integer;
    /// <summary>Earlier line that this one overlaps directly (no segs for it)</summary>
    Overlap: TGlbspLinedef;
    Index: Integer;
  end;

  TGlbspThing = class
  public
    X, Y: Integer;
    ThingType: Integer;
    Options: Integer;
    Index: Integer;
  end;

  TGlbspSeg = class
  public
    Next: TGlbspSeg;
    Start: TGlbspVertex;
    EndVertex: TGlbspVertex;
    /// <summary>Linedef the seg goes along; nil for a miniseg</summary>
    Linedef: TGlbspLinedef;
    Sector: TGlbspSector;
    /// <summary>0 for right, 1 for left</summary>
    Side: Integer;
    Partner: TGlbspSeg;
    /// <summary>Negative while the seg is not yet in a subsector</summary>
    Index: Integer;
    Degenerate: Integer;
    Block: TGlbspSuperBlock;
    // Precomputed data for faster calculations
    PsX, PsY: Double;
    PeX, PeY: Double;
    PdX, PdY: Double;
    PLength: Double;
    PAngle: Double;
    PPara: Double;
    PPerp: Double;
    /// <summary>Linedef the seg comes from; for minisegs the partition line</summary>
    SourceLine: TGlbspLinedef;

    /// <summary>Copies every field of ASource, as the C assignment of a seg</summary>
    procedure Assign(const ASource: TGlbspSeg);
    /// <summary>Distance of a point from the seg, along the seg's line</summary>
    function ParallelDist(const AX, AY: Double): Double;
    /// <summary>Distance of a point from the seg's line; positive on the right</summary>
    function PerpDist(const AX, AY: Double): Double;
  end;

  /// <summary>
  ///   Where a vertex touches a partition line (especially a vertex made by
  ///   a seg split). The list is sorted by AlongDist
  /// </summary>
  TGlbspIntersection = class
  public
    Next: TGlbspIntersection;
    Prev: TGlbspIntersection;
    Vertex: TGlbspVertex;
    /// <summary>
    ///   Distance along the partition: zero at its start, positive in its
    ///   direction
    /// </summary>
    AlongDist: Double;
    /// <summary>The intersection was on a self-referencing linedef</summary>
    SelfRef: Boolean;
    /// <summary>Sector before/after the vertex along the partition; nil if not open</summary>
    Before: TGlbspSector;
    After: TGlbspSector;
  end;

  TGlbspSubsec = class
  public
    SegList: TGlbspSeg;
    SegCount: Integer;
    Index: Integer;
    MidX, MidY: Double;
  end;

  TGlbspBBox = record
    MinX, MinY: Integer;
    MaxX, MaxY: Integer;
  end;

  /// <summary>Child of a node: a node or a subsector (one of them is nil)</summary>
  TGlbspChild = record
    Node: TGlbspNode;
    Subsec: TGlbspSubsec;
    Bounds: TGlbspBBox;
  end;

  TGlbspNode = class
  public
    X, Y: Integer;
    Dx, Dy: Integer;
    R: TGlbspChild;
    L: TGlbspChild;
    Index: Integer;
    /// <summary>The (Dx, Dy) values are halved in the NODES lump</summary>
    TooLong: Integer;
  end;

  TGlbspSuperBlock = class
  public
    Parent: TGlbspSuperBlock;
    X1, Y1: Integer;
    X2, Y2: Integer;
    /// <summary>[0] has the lower coordinates, [1] the higher</summary>
    Subs: array[0..1] of TGlbspSuperBlock;
    RealNum: Integer;
    MiniNum: Integer;
    Segs: TGlbspSeg;

    /// <summary>Frees the sub-blocks; the segs are not owned by the block</summary>
    destructor Destroy; override;
    function IsLeaf: Boolean;
  end;

implementation

{ TGlbspSeg }

procedure TGlbspSeg.Assign(const ASource: TGlbspSeg);
begin
  Next := ASource.Next;
  Start := ASource.Start;
  EndVertex := ASource.EndVertex;
  Linedef := ASource.Linedef;
  Sector := ASource.Sector;
  Side := ASource.Side;
  Partner := ASource.Partner;
  Index := ASource.Index;
  Degenerate := ASource.Degenerate;
  Block := ASource.Block;
  PsX := ASource.PsX;
  PsY := ASource.PsY;
  PeX := ASource.PeX;
  PeY := ASource.PeY;
  PdX := ASource.PdX;
  PdY := ASource.PdY;
  PLength := ASource.PLength;
  PAngle := ASource.PAngle;
  PPara := ASource.PPara;
  PPerp := ASource.PPerp;
  SourceLine := ASource.SourceLine;
end;

function TGlbspSeg.ParallelDist(const AX, AY: Double): Double;
begin
  Result := (AX * PdX + AY * PdY + PPara) / PLength;
end;

function TGlbspSeg.PerpDist(const AX, AY: Double): Double;
begin
  Result := (AX * PdY - AY * PdX + PPerp) / PLength;
end;

{ TGlbspSuperBlock }

destructor TGlbspSuperBlock.Destroy;
begin
  Subs[0].Free;
  Subs[1].Free;
  inherited Destroy;
end;

function TGlbspSuperBlock.IsLeaf: Boolean;
begin
  Result := (X2 - X1 <= SUPERBLOCK_LEAF_SIZE) and (Y2 - Y1 <= SUPERBLOCK_LEAF_SIZE);
end;

end.
