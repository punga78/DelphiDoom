{******************************************************************************}
{                                                                              }
{  DelphiDoom: blockmap - shared types                                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Blockmap.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>Places to shift a map coordinate to get the number of the block</summary>
  BLOCKMAP_SHIFT = 7;
  /// <summary>Mask of the position of a coordinate inside a block</summary>
  BLOCKMAP_MASK = (1 shl BLOCKMAP_SHIFT) - 1;
  /// <summary>Fixed point unit (16.16) of the vertex coordinates</summary>
  BLOCKMAP_FRACUNIT = 65536;
  /// <summary>Value of the neg limits when the blockmap is not wide enough to wrap</summary>
  BLOCKMAP_NEG_DISABLED = -257;
  /// <summary>Number of values of the header of a blockmap: origin x and y, columns and rows</summary>
  BLOCKMAP_HEADER_SIZE = 4;
  /// <summary>Most values (16 bit words) a BLOCKMAP lump may hold to be accepted</summary>
  BLOCKMAP_MAX_LUMP_WORDS = $10000;

resourcestring
  SBlockmapNoVertexes = 'Blockmap: the level has no vertexes';
  SBlockmapTooBig = 'Blockmap: the level is too big (%d columns by %d rows)';
  SBlockmapVertexOutOfRange = 'Slime trails: vertex %d is outside the %d vertexes of the level';

type
  /// <summary>A vertex of the level: 16.16 fixed point coordinates</summary>
  TBlockmapPoint = record
    X: Integer;
    Y: Integer;
  end;

  /// <summary>A line of the level: the 16.16 fixed point coordinates of its two ends</summary>
  TBlockmapLine = record
    X1: Integer;
    Y1: Integer;
    X2: Integer;
    Y2: Integer;
  end;

  /// <summary>
  ///   A seg for the slime trails: the indexes of its two vertexes and what the
  ///   calculation needs of its parent line
  /// </summary>
  TBlockmapSeg = record
    /// <summary>Index of the first vertex of the seg</summary>
    Vertex1: Integer;
    /// <summary>Index of the second vertex of the seg</summary>
    Vertex2: Integer;
    /// <summary>A miniseg has no parent line and is skipped</summary>
    Miniseg: Boolean;
    /// <summary>Index of the first vertex of the parent line</summary>
    LineVertex1: Integer;
    /// <summary>Index of the second vertex of the parent line</summary>
    LineVertex2: Integer;
    /// <summary>Delta x of the parent line, 16.16 fixed point, as it was loaded</summary>
    LineDeltaX: Integer;
    /// <summary>Delta y of the parent line, 16.16 fixed point, as it was loaded</summary>
    LineDeltaY: Integer;
  end;

  /// <summary>
  ///   A blockmap in the format of the engine: a header, the offset of the list of
  ///   each block and the lists, all as 32 bit values
  /// </summary>
  TBlockmapData = record
    /// <summary>Header, offsets and lists; the lists end with -1</summary>
    Lump: TArray<Integer>;
    /// <summary>Origin x in map units</summary>
    OriginX: Integer;
    /// <summary>Origin y in map units</summary>
    OriginY: Integer;
    /// <summary>Number of columns of blocks</summary>
    Columns: Integer;
    /// <summary>Number of rows of blocks</summary>
    Rows: Integer;
    /// <summary>Blocks left of this one are the wrapped ones (vanilla wrap emulation)</summary>
    NegX: Integer;
    /// <summary>Blocks below this one are the wrapped ones (vanilla wrap emulation)</summary>
    NegY: Integer;
    /// <summary>True when the lists were made by the builder (32 bit offsets)</summary>
    Built: Boolean;
  end;

  /// <summary>Raised when the data of a level cannot make a blockmap or the slime trails</summary>
  EBlockmapException = class(Exception);

implementation

end.
