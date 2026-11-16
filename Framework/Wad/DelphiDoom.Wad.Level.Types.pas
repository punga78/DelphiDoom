{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - records of the lumps of a level                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Level.Types;

interface

{$ALIGN 1}

const
  // Names of the lumps of a level, in the order of the WAD
  LEVEL_LUMP_THINGS = 'THINGS';
  LEVEL_LUMP_LINEDEFS = 'LINEDEFS';
  LEVEL_LUMP_SIDEDEFS = 'SIDEDEFS';
  LEVEL_LUMP_VERTEXES = 'VERTEXES';
  LEVEL_LUMP_SEGS = 'SEGS';
  LEVEL_LUMP_SSECTORS = 'SSECTORS';
  LEVEL_LUMP_NODES = 'NODES';
  LEVEL_LUMP_SECTORS = 'SECTORS';
  LEVEL_LUMP_REJECT = 'REJECT';
  LEVEL_LUMP_BLOCKMAP = 'BLOCKMAP';
  LEVEL_LUMP_BEHAVIOR = 'BEHAVIOR';

type
  /// <summary>Texture and flat names: 8 characters padded with #0</summary>
  TWadName8 = array[0..7] of AnsiChar;

  /// <summary>THINGS (Doom, Heretic): 10 bytes. Coordinates and angle in map units/degrees</summary>
  TWadThing = packed record
    X: SmallInt;
    Y: SmallInt;
    Angle: SmallInt;
    ThingType: SmallInt;
    Options: SmallInt;
  end;

  /// <summary>THINGS (Hexen): 20 bytes</summary>
  TWadHexenThing = packed record
    Tid: SmallInt;
    X: SmallInt;
    Y: SmallInt;
    Z: SmallInt;
    Angle: SmallInt;
    ThingType: SmallInt;
    Options: SmallInt;
    Special: Byte;
    Arguments: array[0..4] of Byte;
  end;

  /// <summary>LINEDEFS (Doom, Heretic): 14 bytes. A side number of -1 means no side</summary>
  TWadLinedef = packed record
    Vertex1: SmallInt;
    Vertex2: SmallInt;
    Flags: SmallInt;
    Special: SmallInt;
    Tag: SmallInt;
    SideNumber: array[0..1] of SmallInt;
  end;

  /// <summary>LINEDEFS (Hexen): 16 bytes</summary>
  TWadHexenLinedef = packed record
    Vertex1: SmallInt;
    Vertex2: SmallInt;
    Flags: SmallInt;
    Special: Byte;
    Arguments: array[0..4] of Byte;
    SideNumber: array[0..1] of SmallInt;
  end;

  /// <summary>SIDEDEFS: 30 bytes</summary>
  TWadSidedef = packed record
    TextureOffset: SmallInt;
    RowOffset: SmallInt;
    TopTexture: TWadName8;
    BottomTexture: TWadName8;
    MiddleTexture: TWadName8;
    Sector: SmallInt;
  end;

  /// <summary>VERTEXES: 4 bytes</summary>
  TWadVertex = packed record
    X: SmallInt;
    Y: SmallInt;
  end;

  /// <summary>SEGS: 12 bytes</summary>
  TWadSeg = packed record
    Vertex1: SmallInt;
    Vertex2: SmallInt;
    Angle: SmallInt;
    Linedef: SmallInt;
    Side: SmallInt;
    Offset: SmallInt;
  end;

  /// <summary>SSECTORS: 4 bytes</summary>
  TWadSubsector = packed record
    SegCount: SmallInt;
    FirstSeg: SmallInt;
  end;

  /// <summary>NODES: 28 bytes. A child with the high bit set is a subsector</summary>
  TWadNode = packed record
    X: SmallInt;
    Y: SmallInt;
    DeltaX: SmallInt;
    DeltaY: SmallInt;
    BoundingBox: array[0..1, 0..3] of SmallInt;
    Children: array[0..1] of Word;
  end;

  /// <summary>SECTORS: 26 bytes</summary>
  TWadSector = packed record
    FloorHeight: SmallInt;
    CeilingHeight: SmallInt;
    FloorTexture: TWadName8;
    CeilingTexture: TWadName8;
    LightLevel: SmallInt;
    Special: SmallInt;
    Tag: SmallInt;
  end;

implementation

end.
