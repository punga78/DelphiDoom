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
