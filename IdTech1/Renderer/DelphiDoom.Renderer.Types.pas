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
  /// <summary>The folder of the PK3 whose images are textures (and flats)</summary>
  RENDERER_PK3_TEXTURE_PATH = 'TEXTURES\';
  /// <summary>The folder of the PK3 whose images are flats only</summary>
  RENDERER_PK3_FLAT_PATH = 'FLATS\';
  /// <summary>The longest name of a texture or a flat of a WAD</summary>
  RENDERER_PK3_MAX_NAME_LENGTH = 8;
  /// <summary>The number of fine angles of a full circle (the index of the tables of the tangents)</summary>
  RENDERER_FINEANGLES = 8192;
  /// <summary>How many binary angles a fine angle has (the angles are 32 bit: a full circle is 2^32)</summary>
  RENDERER_ANGLE_TO_FINE_UNIT = 1 shl 19;
  /// <summary>90 degrees as a binary angle</summary>
  RENDERER_ANGLE_90 = $40000000;
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
  /// <summary>The tables that map the angles of the view to the columns of the screen and back</summary>
  TRendererTextureMapping = record
    /// <summary>For each fine angle of the half circle in front, the next greatest column after it (0 to the view width)</summary>
    ViewAngleToX: TArray<Integer>;
    /// <summary>For each column from 0 to the view width, the smallest view angle that maps to it (a binary angle)</summary>
    XToViewAngle: TArray<Cardinal>;
    /// <summary>The angle of the left edge of the view (the first of XToViewAngle)</summary>
    ClipAngle: Cardinal;
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
  /// <summary>The games that the software renderer has rules for</summary>
  TRendererGame = (Doom, Heretic, Hexen, Strife);
  /// <summary>
  ///   What each game has in the cold part of the renderer (the data of the textures, the sky,
  ///   the size of the view): the values that the old code had in its {$IFDEF}
  /// </summary>
  TRendererProfile = record
    Game: TRendererGame;
    /// <summary>The height of the middle of the sky texture, in fixed point (skytexturemid)</summary>
    SkyTextureMid: Integer;
    /// <summary>The texture of a wall that has none or whose name is not found (-1 or 0)</summary>
    MissingTexture: Integer;
    /// <summary>
    ///   A negative number in a side is no texture (Heretic and Hexen); otherwise only zero is,
    ///   and a negative number is a custom colormap
    /// </summary>
    NegativeSideTextureIsNone: Boolean;
    /// <summary>The sides can have a custom colormap instead of a texture, and a missing name can be one</summary>
    CustomColormapsOnSides: Boolean;
    /// <summary>The columns of the light levels of the high detail count in the way of Doom (the others use a different division)</summary>
    DoomLightLevelColumns: Boolean;
  end;
  /// <summary>A sprite to sort: the number that orders it (its scale) and the sprite itself</summary>
  TRendererSortItem = record
    Key: Integer;
    Item: Pointer;
  end;
  PRendererSortItem = ^TRendererSortItem;
  TRendererSortItemArray = array[0..MaxInt div SizeOf(TRendererSortItem) - 1] of TRendererSortItem;
  PRendererSortItemArray = ^TRendererSortItemArray;
  /// <summary>The size of the part of the screen that the 3D view uses</summary>
  TRendererViewDimensions = record
    /// <summary>The width of the view (the whole screen from ten blocks up)</summary>
    ScaledViewWidth: Integer;
    ViewHeight: Integer;
  end;
  /// <summary>The distances of the rows of the screen, for the flats and the lights of the slopes</summary>
  TRendererSlopeTables = record
    /// <summary>For each row: the distance scale of the flats (yslope)</summary>
    YSlope: TArray<Integer>;
    /// <summary>For each row: the same, but the rows near the horizon do not go below a minimum (slyslope)</summary>
    LightYSlope: TArray<Integer>;
  end;
  /// <summary>The size of the biggest screen mode of the monitor that the renderer takes for its aspect</summary>
  TRendererMonitorSize = record
    Width: Integer;
    Height: Integer;
  end;
  /// <summary>The images of a PK3 that become textures and flats, sorted by name</summary>
  TRendererPk3Names = record
    /// <summary>The names that are textures (they are flats too)</summary>
    Textures: TArray<string>;
    /// <summary>The names that are flats (the textures are in the list too)</summary>
    Flats: TArray<string>;
  end;
  /// <summary>What a level uses, as numbers: the renderer loads only that</summary>
  TRendererPrecacheInput = record
    /// <summary>How many flats, textures and sprites the game has (the size of the tables of what is present)</summary>
    FlatCount: Integer;
    TextureCount: Integer;
    SpriteCount: Integer;
    /// <summary>The floor and the ceiling flat of each sector (they have the same length or are two lists to read together)</summary>
    SectorFlats: TArray<Integer>;
    /// <summary>The upper, middle and lower texture of every side</summary>
    SideTextures: TArray<Integer>;
    /// <summary>Flats and textures that are used without being in a sector or a side (animated ones, the sky)</summary>
    ExtraFlats: TArray<Integer>;
    ExtraTextures: TArray<Integer>;
    /// <summary>The sprite of every object of the level</summary>
    ObjectSprites: TArray<Integer>;
  end;
  /// <summary>What is used by the level, one flag for each flat, texture and sprite of the game</summary>
  TRendererPrecachePlan = record
    FlatPresent: TArray<Boolean>;
    TexturePresent: TArray<Boolean>;
    SpritePresent: TArray<Boolean>;
  end;

implementation

end.
