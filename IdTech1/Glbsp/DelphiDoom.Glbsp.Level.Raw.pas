{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - on-disk structures of the level lumps                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of structs.h of glBSP 2.24 (C) 2000-2007 Andrew Apted                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Level.Raw;

interface

const
  LINEFLAG_TWO_SIDED = 4;

  HEXTYPE_POLY_START = 1;
  HEXTYPE_POLY_EXPLICIT = 5;

  // Hexen polyobj thing types
  PO_ANCHOR_TYPE = 3000;
  PO_SPAWN_TYPE = 3001;
  PO_SPAWNCRUSH_TYPE = 3002;

  // ZDoom polyobj thing types
  ZDOOM_PO_ANCHOR_TYPE = 9300;
  ZDOOM_PO_SPAWN_TYPE = 9301;
  ZDOOM_PO_SPAWNCRUSH_TYPE = 9302;

type
  // All the records are packed and little endian, like the lumps

  TRawBlockmapHeader = packed record
    XOrigin, YOrigin: SmallInt;
    XBlocks, YBlocks: SmallInt;
  end;

  TRawVertex = packed record
    X, Y: SmallInt;
  end;

  TRawV2Vertex = packed record
    X, Y: Integer;
  end;

  TRawLinedef = packed record
    Start: Word;
    EndVertex: Word;
    Flags: Word;
    LineType: Word;
    Tag: SmallInt;
    Sidedef1: Word;
    Sidedef2: Word;
  end;

  TRawHexenLinedef = packed record
    Start: Word;
    EndVertex: Word;
    Flags: Word;
    LineType: Byte;
    Specials: array[0..4] of Byte;
    Sidedef1: Word;
    Sidedef2: Word;
  end;

  TRawSidedef = packed record
    XOffset: SmallInt;
    YOffset: SmallInt;
    UpperTex: array[0..7] of AnsiChar;
    LowerTex: array[0..7] of AnsiChar;
    MidTex: array[0..7] of AnsiChar;
    Sector: Word;
  end;

  TRawSector = packed record
    FloorHeight: SmallInt;
    CeilingHeight: SmallInt;
    FloorTex: array[0..7] of AnsiChar;
    CeilingTex: array[0..7] of AnsiChar;
    Light: Word;
    Special: Word;
    Tag: SmallInt;
  end;

  TRawThing = packed record
    X, Y: SmallInt;
    Angle: SmallInt;
    ThingType: Word;
    Options: Word;
  end;

  TRawHexenThing = packed record
    Tid: SmallInt;
    X, Y: SmallInt;
    Height: SmallInt;
    Angle: SmallInt;
    ThingType: Word;
    Options: Word;
    Special: Byte;
    Args: array[0..4] of Byte;
  end;

  TRawSeg = packed record
    Start: Word;
    EndVertex: Word;
    Angle: Word;
    Linedef: Word;
    Flip: Word;
    Dist: Word;
  end;

  TRawGLSeg = packed record
    Start: Word;
    EndVertex: Word;
    Linedef: Word;
    Side: Word;
    Partner: Word;
  end;

  TRawV3Seg = packed record
    Start: Cardinal;
    EndVertex: Cardinal;
    Linedef: Word;
    Side: Word;
    Partner: Cardinal;
  end;

  TRawBBox = packed record
    MaxY, MinY: SmallInt;
    MinX, MaxX: SmallInt;
  end;

  TRawNode = packed record
    X, Y: SmallInt;
    Dx, Dy: SmallInt;
    B1, B2: TRawBBox;
    Right, Left: Word;
  end;

  TRawSubsector = packed record
    Count: Word;
    First: Word;
  end;

  TRawV3Subsector = packed record
    Count: Cardinal;
    First: Cardinal;
  end;

  TRawV5Node = packed record
    X, Y: SmallInt;
    Dx, Dy: SmallInt;
    B1, B2: TRawBBox;
    Right, Left: Cardinal;
  end;

implementation

end.
