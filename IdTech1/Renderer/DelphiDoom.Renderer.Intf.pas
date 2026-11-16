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

  /// <summary>The sprite lumps of the WAD, as the builder of the sprite definitions sees them</summary>
  IRendererSpriteSource = interface
    ['{3C8D5E17-A2B4-4F90-8E36-D1075B9A64F2}']
    /// <summary>The number of the first sprite lump</summary>
    function FirstLump: Integer;
    /// <summary>The number of the last sprite lump</summary>
    function LastLump: Integer;
    /// <summary>The lump is a sprite that the game can use (read at its position from FirstLump)</summary>
    function IsPresent(ALump: Integer): Boolean;
    function LumpName(ALump: Integer): TRendererLumpName;
    /// <summary>
    ///   The lump that a game with patched WADs uses for the sprite of this lump (the last one
    ///   with the name); the lump itself when the game is not modified
    /// </summary>
    function PatchedLump(ALump: Integer): Integer;
    /// <summary>Developer mode: errors about the sprite lumps are only warnings</summary>
    function DeveloperMode: Boolean;
  end;

  /// <summary>The sprite definitions: frames and rotations of every sprite of the game</summary>
  IRendererSpriteDefs = interface
    ['{F61A92C8-5D07-4B3E-A4C9-2E8D703B15A6}']
    /// <summary>
    ///   Builds, for each sprite name (four characters packed in an integer, little endian),
    ///   its frames from the lumps of the sprite source. Warns about the lumps that do not
    ///   agree; raises ERendererException with the text of the engine error when the lumps
    ///   are not consistent (a sprite with some rotations missing) and the developer mode is off
    /// </summary>
    function Build(const ANames: TArray<Integer>): TArray<TRendererSpriteDefinition>;
  end;

  /// <summary>Finds the subsector of a point of the level, as the nodes of the level say</summary>
  IRendererSubsectorLocator = interface
    ['{8E2B47D9-1C6A-4F53-A0D8-95B3E7164C20}']
    /// <summary>
    ///   The number of the subsector that has the point (fixed point coordinates), or -1 when
    ///   the point is on the side of a seg of that subsector that the point test of the
    ///   renderer reports (a point that is not clearly inside)
    /// </summary>
    function Locate(AX, AY: Integer): Integer;
  end;

  /// <summary>Builds the grid of the precalculated point in subsector of a level</summary>
  IRendererSubsectorGridBuilder = interface
    ['{5A93C1E6-70B8-4D24-B1F7-0C6E8D2A39F5}']
    /// <summary>
    ///   Measures the level from its vertexes, cuts it in cells of 32 map units and, for each
    ///   cell, asks the locator for the four corners: the cell has a subsector when they are all
    ///   inside the same one
    /// </summary>
    function Build(const AVertexX, AVertexY: TArray<Integer>;
      const ALocator: IRendererSubsectorLocator): TRendererSubsectorGrid;
  end;

  /// <summary>The directory of the lumps of the WAD, as the ranges of flats and sprites see it</summary>
  IRendererLumpDirectory = interface
    ['{B7E20A4C-96D1-4F83-8C5A-3D0E71F4A862}']
    function LumpCount: Integer;
    function LumpName(ALump: Integer): TRendererLumpName;
    /// <summary>The first lump with the name, or -1</summary>
    function FirstLumpNamed(const AName: string): Integer;
    /// <summary>The last lump with the name (the one that wins in a patched game), or -1</summary>
    function LastLumpNamed(const AName: string): Integer;
  end;

  /// <summary>Where the flats and the sprites are in the lumps of the WAD</summary>
  IRendererLumpRanges = interface
    ['{4D9A63F1-E208-4B7C-95A3-C1F6082E7B54}']
    /// <summary>
    ///   The lumps between F_START and F_END (and the FF_ ones when they reach farther).
    ///   Raises ERendererException when a marker that the game needs is missing, with the text
    ///   of the engine error
    /// </summary>
    function FlatRange: TRendererLumpRange;
    /// <summary>
    ///   The lumps between S_START (or SS_START) and S_END (or SS_END). Warns when the
    ///   markers are misplaced; raises ERendererException when S_END is missing
    /// </summary>
    function SpriteRange: TRendererLumpRange;
  end;

  /// <summary>The header of a sprite lump: size and offsets of the patch</summary>
  IRendererSpriteHeaders = interface
    ['{91C5E8B2-3A47-4D06-B1F9-6E24D80C7A35}']
    /// <summary>Reads the header and releases the lump (the engine caches it as static meanwhile)</summary>
    procedure Header(ALump: Integer; out AWidth, ALeftOffset, ATopOffset: Integer);
  end;

  /// <summary>Reads the headers of the sprite lumps once, so that the renderer does not cache a sprite just to know its size</summary>
  IRendererSpriteTableBuilder = interface
    ['{2F8B1D7E-C493-4A60-8E15-B7D90A3C56F1}']
    /// <summary>
    ///   For every lump of the range: the width and the offsets of the patch in fixed point,
    ///   and whether it is a sprite. The markers are not sprites, and the lumps outside a
    ///   section between a start and an end marker are not either
    /// </summary>
    function Build(const ARange: TRendererLumpRange): TRendererSpriteTable;
  end;
  /// <summary>Builds the tables that map the angles of the view to the columns of the screen</summary>
  IRendererTextureMappingBuilder = interface
    ['{6B1F4A93-D8C2-4E57-A09B-3F7E15C2D840}']
    /// <summary>
    ///   viewangletox (the next greatest column after a view angle) and xtoviewangle (the
    ///   smallest view angle that maps to a column), from the focal length in fixed point,
    ///   the horizontal centre of the view in fixed point and the width of the view. Raises
    ///   ERendererException when the table of the tangents is too short or the width negative
    /// </summary>
    /// <param name="AFineTangent">The tangents of the fine angles of the half circle in front, in fixed point</param>
    function Build(AFocalLength, ACenterXFrac, AViewWidth: Integer;
      const AFineTangent: TArray<Integer>): TRendererTextureMapping;
  end;
  /// <summary>One way of ordering the sprites of a frame from the farthest to the nearest</summary>
  IRendererSpriteSorter = interface
    ['{3F8A2D61-C7E5-4B09-8A14-D6B90E27F5C3}']
    /// <summary>
    ///   The sort uses the scale of the sprite as the engine counts it for sorting (a dropped
    ///   object counts one more); false: the plain scale (the old merge sort did this)
    /// </summary>
    function UsesDroppedAdjustment: Boolean;
    /// <summary>Makes room for ACount sprites, so that sorting does not allocate (and can run in a thread)</summary>
    procedure Reserve(ACount: Integer);
    /// <summary>
    ///   Orders by Key, smallest first. Sprites with the same key end in the order of the
    ///   algorithm: the frames depend on it, so every sorter keeps the order of the old code
    /// </summary>
    procedure Sort(AItems: PRendererSortItemArray; ACount: Integer);
    /// <summary>Gives back the memory</summary>
    procedure Release;
  end;

  /// <summary>Chooses the sorter that is fastest for the number of sprites of the frame</summary>
  IRendererSpriteSortPolicy = interface
    ['{91B4E7C2-5A3D-4F68-B0E9-2C7A18D3F456}']
    function Select(ACount: Integer): IRendererSpriteSorter;
    procedure Reserve(ACount: Integer);
    procedure Release;
  end;

  /// <summary>The tables that depend on the size of the view: done when the size changes, never for a frame</summary>
  IRendererViewTables = interface
    ['{B07E5C19-84DA-4F32-A6C1-D93F2E80B7A5}']
    /// <summary>
    ///   The size of the view for a number of blocks (the size slider of the screen): from eleven
    ///   blocks up the whole screen, at ten the whole width and AFullViewHeight (the height above
    ///   the status bar); less than ten, a part of the width and ABlockBase times the blocks over
    ///   ABlockDivisor, a multiple of eight
    /// </summary>
    function Dimensions(ASetBlocks, AScreenWidth, AScreenHeight, AFullViewHeight, ABlockBase,
      ABlockDivisor: Integer): TRendererViewDimensions;
    /// <summary>
    ///   The tables of the rows: FixedDiv of the projection over the distance of the centre of
    ///   each row from the horizon (a row on it counts one half)
    /// </summary>
    function Slopes(AProjectionY, ACenterYFrac, AViewHeight: Integer): TRendererSlopeTables;
    /// <summary>For each column, one over the cosine in fixed point (the cosines are positive)</summary>
    function DistanceScales(const AColumnCosines: TArray<Integer>): TArray<Integer>;
    /// <summary>
    ///   For each of ALevels light levels and AColumns columns, how much of the colour is kept
    ///   (the old scalelightlevels, in the order level * AColumns + column); the games count the
    ///   screen width in a different order of operations, the flag says which
    /// </summary>
    function LightLevels(ALevels, AColumns, AViewWidth, AScreenWidth: Integer;
      ADoomStyle: Boolean): TArray<Integer>;
  end;

  /// <summary>Which screen mode of the monitor the aspect of the widescreen view comes from</summary>
  IRendererMonitorAspect = interface
    ['{5A93D2C8-F1B4-4E60-9D27-8C0B6E3A7154}']
    /// <summary>
    ///   The size of the biggest mode of 32 bits that is bigger than 640x480 in both sides, as the
    ///   system lists the modes (a later mode that is not smaller in both sides wins);
    ///   640x480 when there is none
    /// </summary>
    function Measure: TRendererMonitorSize;
  end;

  /// <summary>The table of the angles of the "fake 3D" view (looking up and down)</summary>
  IRendererFake3DAngles = interface
    ['{E8B7140D-3C59-4A82-B6F1-27D90A5C3E68}']
    /// <summary>
    ///   The cosine of the angle for each look direction from AMinIndex to AMaxIndex (entry zero
    ///   is AMinIndex): the angle follows the circle through the two extremes and the middle of the
    ///   range, so that the view bends smoothly. Without a circle (collinear points) all are one
    /// </summary>
    function Cosines(AMinIndex, AMaxIndex: Integer): TArray<Double>;
  end;

  /// <summary>What the selector of the images of a PK3 asks of the engine</summary>
  IRendererPk3Catalog = interface
    ['{7E31B5A8-2D94-4C07-B1F6-90A8C4D5E321}']
    /// <summary>The extension (upper case, with its dot) is one of an image that the engine decodes</summary>
    function IsTextureExtension(const AExtension: string): Boolean;
    /// <summary>The WAD already has a lump with the name</summary>
    function HasLump(const AName: string): Boolean;
    /// <summary>The number of the texture with the name (zero for the "no texture" marker, -1 when it is not there)</summary>
    function TextureNumber(const AName: string): Integer;
  end;

  /// <summary>Chooses which images of a PK3 are converted to textures and flats</summary>
  IRendererPk3NameSelector = interface
    ['{C4F82A67-1B3E-4D95-A07C-5D29E8B16F40}']
    /// <summary>
    ///   Of the names of the files of the PK3: the images in textures\ and flats\ that have a
    ///   name of at most eight characters, one dot, and no lump in the WAD; the ones of textures\
    ///   that are not already textures are textures and flats, the others flats. Without
    ///   duplicates (letters of any case count the same), sorted
    /// </summary>
    function Select(const AEntryNames: TArray<string>;
      const ACatalog: IRendererPk3Catalog): TRendererPk3Names;
  end;

  /// <summary>The number that names the cache of the textures of a PK3</summary>
  IRendererPk3TextHash = interface
    ['{18D6A3F4-E7B2-4590-8C1D-F3A7062B94E8}']
    /// <summary>The hash of the text of a list of names (each one followed by a line break)</summary>
    function Compute(const AText: string): Integer;
  end;

  /// <summary>Which flats, textures and sprites a level uses</summary>
  IRendererPrecachePlanner = interface
    ['{A2C47E15-93B8-4D60-8F1A-5E0D7B34C9F2}']
    /// <summary>
    ///   One flag for each flat, texture and sprite of the game: set when a sector, a side, an
    ///   extra entry or an object uses it. Numbers outside the game are ignored
    /// </summary>
    function Plan(const AInput: TRendererPrecacheInput): TRendererPrecachePlan;
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
