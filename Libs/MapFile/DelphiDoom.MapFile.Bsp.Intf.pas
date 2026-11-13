{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: contracts        }
{                                                                              }
{  Written for this library (the original reads the lumps in tr_bsp.c and      }
{  cm_load.c). Based on the Quake III Arena GPL Source Code (id Software).     }
{  Copyright (C) 1999-2005 Id Software, Inc. This unit is derived from the     }
{  Quake III Arena source code and is therefore available under the GNU        }
{  General Public License, version 2 or (at your option) any later version.    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.Intf;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Patch.Intf, DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   A BSP file that was read: the 17 lumps as arrays of records (a lump is empty when its
  ///   length is 0). The arrays are shared with the file: do not change them.
  /// </summary>
  IBspFile = interface
    ['{7A41C0D2-3E58-4B9A-A6F1-0D52E8B7C913}']
    function GetVersion: Integer;
    function GetLump(const AIndex: Integer): TBspLump;
    function GetLumpData(const AIndex: Integer): TBytes;
    function GetEntityText: AnsiString;
    function GetShaders: TArray<TBspShader>;
    function GetPlanes: TArray<TBspPlane>;
    function GetNodes: TArray<TBspNode>;
    function GetLeafs: TArray<TBspLeaf>;
    function GetLeafSurfaces: TArray<Integer>;
    function GetLeafBrushes: TArray<Integer>;
    function GetModels: TArray<TBspModel>;
    function GetBrushes: TArray<TBspBrush>;
    function GetBrushSides: TArray<TBspBrushSide>;
    function GetDrawVerts: TArray<TBspDrawVert>;
    function GetDrawIndexes: TArray<Integer>;
    function GetFogs: TArray<TBspFog>;
    function GetSurfaces: TArray<TBspSurface>;
    function GetLightmaps: TBytes;
    function GetLightGrid: TBytes;
    function GetNumClusters: Integer;
    function GetClusterBytes: Integer;
    function GetVisibility: TBytes;
    /// <summary>The name in a shader or fog record (up to the first NUL)</summary>
    function ShaderName(const AIndex: Integer): AnsiString;
    function FogShaderName(const AIndex: Integer): AnsiString;
    /// <summary>The number of lightmaps (the lump length divided by 128 x 128 x 3)</summary>
    function LightmapCount: Integer;
    property Version: Integer read GetVersion;
    /// <summary>The header entry of lump AIndex (LUMP_ENTITIES ... LUMP_VISIBILITY)</summary>
    property Lumps[const AIndex: Integer]: TBspLump read GetLump;
    /// <summary>The bytes of lump AIndex as they are in the file</summary>
    property LumpData[const AIndex: Integer]: TBytes read GetLumpData;
    /// <summary>The entities lump up to the first NUL: key/value text, see TBspEntityReader</summary>
    property EntityText: AnsiString read GetEntityText;
    property Shaders: TArray<TBspShader> read GetShaders;
    property Planes: TArray<TBspPlane> read GetPlanes;
    property Nodes: TArray<TBspNode> read GetNodes;
    property Leafs: TArray<TBspLeaf> read GetLeafs;
    property LeafSurfaces: TArray<Integer> read GetLeafSurfaces;
    property LeafBrushes: TArray<Integer> read GetLeafBrushes;
    property Models: TArray<TBspModel> read GetModels;
    property Brushes: TArray<TBspBrush> read GetBrushes;
    property BrushSides: TArray<TBspBrushSide> read GetBrushSides;
    property DrawVerts: TArray<TBspDrawVert> read GetDrawVerts;
    property DrawIndexes: TArray<Integer> read GetDrawIndexes;
    property Fogs: TArray<TBspFog> read GetFogs;
    property Surfaces: TArray<TBspSurface> read GetSurfaces;
    /// <summary>The lightmaps, 49152 bytes each, one after the other</summary>
    property Lightmaps: TBytes read GetLightmaps;
    /// <summary>The light grid, 8 bytes per cell (the size is not checked here: the renderer does it)</summary>
    property LightGrid: TBytes read GetLightGrid;
    /// <summary>The first integer of the visibility lump (0 if the lump is empty)</summary>
    property NumClusters: Integer read GetNumClusters;
    /// <summary>The second integer of the visibility lump: the bytes of the row of a cluster</summary>
    property ClusterBytes: Integer read GetClusterBytes;
    /// <summary>The bit rows that follow the two integers (empty if the lump is empty)</summary>
    property Visibility: TBytes read GetVisibility;
  end;

  /// <summary>Turns the bytes of a .bsp file into the model</summary>
  IBspReader = interface
    ['{2C93E6B8-5D07-4F1A-8B34-9E0A71D5C246}']
    /// <summary>
    ///   Reads a file through the file system of the reader; nil if there is no such file.
    ///   A file that is not valid raises EBspFileException
    /// </summary>
    function Parse(const AFileName: AnsiString): IBspFile;
    /// <summary>Reads a file that is already in memory; the name is only used in the messages</summary>
    function ParseBytes(const AData: TBytes; const AName: AnsiString): IBspFile;
  end;

  /// <summary>
  ///   Checks that the references between the lumps stay inside them (the checks the engine
  ///   does here and there while it loads, and those whose absence makes it read out of its
  ///   arrays). The messages name the lump and the index.
  /// </summary>
  IBspValidator = interface
    ['{91D5B3F0-6A2C-4E78-A1D4-3B8F07C5E912}']
    /// <summary>Empty when the file is consistent</summary>
    function Validate(const AFile: IBspFile): TArray<string>;
  end;

  /// <summary>R_StitchAllPatches and R_StitchPatches of tr_bsp.c</summary>
  IBspPatchStitcher = interface
    ['{5E08A7C1-B49D-4D36-8F52-C1A6D3E07B84}']
    /// <summary>
    ///   Stitches the grids of the same LOD group until no more cracks are found (a grid in a
    ///   slot is replaced by the grid with the column or row added; nil slots are not grids).
    ///   Returns the number of stitches
    /// </summary>
    function StitchAll(var AGrids: TArray<IPatchGrid>): Integer;
    /// <summary>
    ///   R_StitchPatches: looks for a missing vertex on the edge of the second grid that the
    ///   first one has, and adds it to the second (replacing it in its slot); True if it did
    /// </summary>
    function StitchPair(var AGrids: TArray<IPatchGrid>; const AFirst, ASecond: Integer): Boolean;
  end;

  /// <summary>R_FixSharedVertexLodError of tr_bsp.c</summary>
  IBspLodFixer = interface
    ['{B3F714D9-0C85-4A2E-96D1-7E4A2058C3B6}']
    /// <summary>
    ///   Gives the vertices that two grids of a group share the same LOD error (the errors of
    ///   the grids are changed in place)
    /// </summary>
    procedure Fix(const AGrids: TArray<IPatchGrid>);
  end;

  /// <summary>
  ///   The patch part of R_LoadSurfaces: ParseMesh for every patch surface, then the
  ///   stitching and the LOD fix
  /// </summary>
  IBspPatchLoader = interface
    ['{D8A25E63-4F17-4B90-A3C8-26E1B7F5094D}']
    /// <summary>
    ///   One entry per surface: the grid for a patch that is drawn, nil for any other surface
    ///   and for a patch with SURF_NODRAW
    /// </summary>
    function LoadGrids(const AFile: IBspFile): TArray<IPatchGrid>;
    /// <summary>The stitches done by the last LoadGrids</summary>
    function GetStitchCount: Integer;
    property StitchCount: Integer read GetStitchCount;
  end;

implementation

end.
