{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the contracts                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types;

type
  /// <summary>A patch that is open: the columns that the lookup of a texture needs from it</summary>
  /// <remarks>
  ///   The patch is released when the last reference goes away. The engine keeps it in the zone
  ///   memory as static until then
  /// </remarks>
  IRendererPatchColumns = interface
    ['{4B7E2C91-D035-4A68-9E1F-B8C63A02F5D7}']
    /// <summary>The number of columns of the patch</summary>
    function Width: Integer;
    /// <summary>
    ///   Where the posts of a column start (the offset from the start of the patch lump, the
    ///   same number that the lump has in its table of columns) and how many posts it has
    /// </summary>
    procedure Column(AColumn: Integer; out AOffset, APostCount: Integer);
  end;

  /// <summary>The patches of the WAD, as the lookup of a texture sees them</summary>
  IRendererPatchSource = interface
    ['{9A31F6D4-7C08-4E25-B6A3-2D8F51C0E974}']
    /// <summary>
    ///   Opens the patch of a lump. Nil when the lump is not a patch of the game: the lookup
    ///   ignores it, as if the texture did not have it
    /// </summary>
    function Open(ALump: Integer): IRendererPatchColumns;
  end;

  /// <summary>The tables that tell the renderer where each column of a texture is</summary>
  IRendererTextureLookup = interface
    ['{E5084B2A-3F96-4D17-8A5C-61B9D7E03C48}']
    /// <summary>
    ///   Fills, for each column of the texture, the lump of the patch that has it (or
    ///   RENDERER_COLUMN_COMPOSITE, or RENDERER_COLUMN_WITHOUT_PATCH) and the offset of the
    ///   first post inside that lump (or inside the composite block). A column that no
    ///   case writes keeps the value that the caller gave. Returns the size of the composite
    ///   block (zero when no column needs it)
    /// </summary>
    /// <param name="AColumnLump">One entry per column of the texture, at least Width</param>
    /// <param name="AColumnOffset">One entry per column of the texture, at least Width</param>
    function Build(const ATexture: TRendererTextureInfo; var AColumnLump,
      AColumnOffset: TArray<Integer>): Integer;
  end;

  /// <summary>The calculations on the whole level that the software renderer does when the level is loaded</summary>
  IRendererLevelPrecalc = interface
    ['{17D9A8E3-B462-4C50-93F7-0E5A2C86D1B9}']
    /// <summary>
    ///   The lowest floor and the highest ceiling of the sectors, and whether the level is
    ///   tall enough to need the tall walls
    /// </summary>
    function MeasureHeights(const AFloorHeights,
      ACeilingHeights: TArray<Integer>): TRendererHeightRange;
    /// <summary>
    ///   The length of every seg: rounded to map units, and its inverse in map fixed units
    ///   (a seg of length zero divides by zero, as the old code did)
    /// </summary>
    /// <param name="AStartX">Fixed point coordinates of the first vertex of each seg</param>
    /// <param name="AMapLength">One entry per seg: the length in map units</param>
    /// <param name="AInverseLength">One entry per seg: one over the length in fixed units</param>
    procedure MeasureSegments(const AStartX, AStartY, AEndX, AEndY: TArray<Integer>;
      var AMapLength: TArray<Integer>; var AInverseLength: TArray<Double>);
  end;

implementation

end.
