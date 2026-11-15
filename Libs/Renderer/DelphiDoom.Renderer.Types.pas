{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - shared types                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Types;

interface

uses
  System.SysUtils;

const
  /// <summary>One in the fixed point of the engine (16.16)</summary>
  RENDERER_FRACUNIT = 65536;
  /// <summary>
  ///   A level whose sectors span more than this from the lowest floor to the highest ceiling
  ///   needs the renderer of tall walls
  /// </summary>
  RENDERER_TALL_WALL_OFFSET = 2048 * RENDERER_FRACUNIT;
  /// <summary>The column of a texture is not in a patch: it is a column of the composite block</summary>
  RENDERER_COLUMN_COMPOSITE = -1;
  /// <summary>No patch covers the column of the texture</summary>
  RENDERER_COLUMN_WITHOUT_PATCH = -2;
  /// <summary>A composite block bigger than this overflows the 64k offsets of the old texture format</summary>
  RENDERER_COMPOSITE_LIMIT = $10000;

type
  /// <summary>A malformed input of the renderer library (tables that do not match)</summary>
  ERendererException = class(Exception);

  /// <summary>Where a patch is placed on a texture</summary>
  TRendererTexturePatch = record
    /// <summary>The lump of the patch, as the engine numbers it (the library never reads it)</summary>
    Lump: Integer;
    /// <summary>The column of the texture where the first column of the patch is drawn (may be negative)</summary>
    OriginX: Integer;
  end;

  /// <summary>What the lookup tables of a texture are made from</summary>
  TRendererTextureInfo = record
    /// <summary>The number of the texture, for the messages</summary>
    Number: Integer;
    /// <summary>The name of the texture, for the messages</summary>
    Name: string;
    Width: Integer;
    Height: Integer;
    Patches: TArray<TRendererTexturePatch>;
  end;

  /// <summary>The name of a lump: eight bytes, padded with zeros (an 8 characters name has no zero)</summary>
  TRendererLumpName = array[0..7] of AnsiChar;

  /// <summary>One frame of a sprite: for each of the 32 view rotations, the lump to draw and whether it is flipped</summary>
  TRendererSpriteFrame = record
    /// <summary>-1 no lump yet, 0 one lump for all the rotations, 1 eight rotations, 2 sixteen, 3 thirty-two</summary>
    Rotate: Integer;
    /// <summary>The lump of the rotation, relative to the first sprite lump (-1 when there is none)</summary>
    Lump: array[0..31] of Integer;
    Flip: array[0..31] of Boolean;
  end;

  /// <summary>The frames that the lumps of the WAD give to a sprite name</summary>
  TRendererSpriteDefinition = record
    /// <summary>The frames from A to the last one found (empty when no lump has the name)</summary>
    Frames: TArray<TRendererSpriteFrame>;
  end;

  /// <summary>
  ///   The grid that tells, for the cells of the map that lie in one subsector only, which
  ///   subsector it is (the precalculated point in subsector of the renderer)
  /// </summary>
  TRendererSubsectorGrid = record
    /// <summary>The lowest x and y of the vertexes, in fixed point: the corner of the first cell</summary>
    MinX: Int64;
    MinY: Int64;
    /// <summary>The number of cells of a row and of a column</summary>
    Width: Int64;
    Height: Int64;
    /// <summary>Row by row, the number of the subsector of the cell, or -1 when the cell is not in one subsector only</summary>
    Cells: TArray<Integer>;
    /// <summary>How many cells have a subsector</summary>
    HitCount: Integer;
    /// <summary>The biggest absolute coordinate of the vertexes, in map units</summary>
    MaxBound: Integer;
  end;

  /// <summary>A run of consecutive lumps: from the first to the last, both included</summary>
  TRendererLumpRange = record
    First: Integer;
    Last: Integer;
  end;

  /// <summary>What the renderer keeps of the header of every sprite lump of the WAD</summary>
  TRendererSpriteTable = record
    /// <summary>One entry per lump of the range: the width of the patch in fixed point</summary>
    Width: TArray<Integer>;
    /// <summary>The left offset of the patch in fixed point</summary>
    LeftOffset: TArray<Integer>;
    /// <summary>The top offset of the patch in fixed point</summary>
    TopOffset: TArray<Integer>;
    /// <summary>The lump is a sprite (not a marker, and inside a sprite section)</summary>
    Present: TArray<Boolean>;
  end;
  /// <summary>How high and how low the sectors of a level go</summary>
  TRendererHeightRange = record
    /// <summary>The lowest floor height, in fixed point (MaxInt without sectors)</summary>
    LowestFloor: Integer;
    /// <summary>The highest ceiling height, in fixed point (Low(Integer) without sectors)</summary>
    HighestCeiling: Integer;
    /// <summary>The distance between them is more than RENDERER_TALL_WALL_OFFSET</summary>
    NeedsTallWalls: Boolean;
  end;

implementation

end.
