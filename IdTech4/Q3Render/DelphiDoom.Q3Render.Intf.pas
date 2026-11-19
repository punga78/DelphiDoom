{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - contracts        }
{                                                                              }
{  Written for the repository (licence GPL v2 or later); the behaviour that    }
{  the contracts describe is that of renderer\tr_image.c, tr_shader.c,         }
{  tr_model.c and tr_bsp.c of the Quake III Arena GPL Source Code.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Intf;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Models.Static.Md3.Intf, DelphiDoom.MapFile.Bsp.Intf,
  DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.RenderTypes, DelphiDoom.MathCore.Patch.Intf,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Scene.Types;

type
  /// <summary>Where the renderer reads its files from: ri.FS_ReadFile (a path with '/' relative to the paks)</summary>
  IQ3RenderFiles = interface
    ['{A2E5C7D1-4B93-4F60-8E1A-3D7B09C6F254}']
    /// <summary>False when the file is not there</summary>
    function ReadFile(const AName: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>R_LoadImage: any supported file into 32 bit RGBA, without a texture</summary>
  IQ3ImageLoader = interface
    ['{7B31F0A9-26D4-4C85-B1E7-90A4D2C5E348}']
    /// <summary>False when no image could be read (the C returns a NULL picture)</summary>
    function Load(const AName: AnsiString; out AImage: TQ3RenderImage): Boolean;
  end;

  /// <summary>R_FindImageFile without OpenGL: an image is found once and kept in memory</summary>
  IQ3ImageCatalog = interface
    ['{C4D82E56-1F07-4A39-96B2-5E8A31D7F0C9}']
    /// <summary>The handle (1, 2, ...) of the image, loading it the first time; 0 when it cannot be loaded</summary>
    function Find(const AName: AnsiString): Integer;
    function GetImage(AHandle: Integer; out AImage: TQ3RenderImage): Boolean;
    /// <summary>The images loaded</summary>
    function LoadedCount: Integer;
    /// <summary>The names asked for that could not be loaded, each once</summary>
    function MissingNames: TArray<string>;
  end;

  /// <summary>R_FindShader and the shader table of the renderer, as data</summary>
  IQ3ShaderRegistry = interface
    ['{19A6E3B8-D5C2-4E74-A0F1-7C4B82D63E95}']
    /// <summary>
    ///   RE_RegisterShader / RE_RegisterShaderNoMip: the handle (1, 2, ...) of the shader, 0 when the shader is
    ///   defective (an image it names is not there) as the renderer answers
    /// </summary>
    function Register(const AName: AnsiString): Integer;
    function GetShader(AHandle: Integer; out AShader: TQ3ShaderData): Boolean;
    /// <summary>The shaders registered (each name once, whatever the case)</summary>
    function RegisteredCount: Integer;
    /// <summary>Of those, the ones that a script defines</summary>
    function DefinedCount: Integer;
    /// <summary>The ones the renderer makes from an image alone (no script)</summary>
    function ImplicitCount: Integer;
    /// <summary>The ones that came out defective</summary>
    function DefectiveNames: TArray<string>;
  end;

  /// <summary>One shader_t of tr.shaders: the data of the shader as it is for a lightmap index</summary>
  TQ3ShaderEntry = record
    Name: AnsiString;
    Data: TQ3ShaderData;
    /// <summary>shader.lightmapIndex after FinishShader</summary>
    LightmapIndex: Integer;
    /// <summary>shader.defaultShader: the one of tr.defaultShader</summary>
    IsDefault: Boolean;
    /// <summary>shader.sortedIndex: the place in the list sorted by sort (it moves when a shader is added)</summary>
    SortedIndex: Integer;
  end;

  /// <summary>
  ///   The shaders as the renderer keeps them (R_FindShader, tr.shaders and tr.sortedShaders): one entry for every
  ///   name and lightmap index, in the order they were asked for. Entry 0 is tr.defaultShader, 1 the stencil shadow
  ///   marker. A shader that cannot be loaded is not an entry of its own: it is entry 0 (the C makes a shader of the
  ///   defective one and answers 0 to RE_RegisterShader: the same drawing, only the sorted index of the others moves)
  /// </summary>
  IQ3ShaderTable = interface
    ['{D3A7B5E9-0C42-4F18-96B7-2E81C4F05A63}']
    /// <summary>R_FindShader: the index of the entry; 0 for an empty name and for a shader that is defective</summary>
    function FindShader(const AName: AnsiString; ALightmapIndex: Integer): Integer;
    /// <summary>R_GetShaderByHandle: an index that is not in the table is the default shader</summary>
    function GetEntry(AIndex: Integer): TQ3ShaderEntry;
    function SortedIndexOf(AIndex: Integer): Integer;
    /// <summary>tr.sortedShaders[ASortedIndex]: the entry that has this place in the list sorted by sort</summary>
    function GetSortedEntry(ASortedIndex: Integer): TQ3ShaderEntry;
    /// <summary>The table index of the shader that has this place in the sorted list</summary>
    function GetSortedShader(ASortedIndex: Integer): Integer;
    function Count: Integer;
    /// <summary>tr.numLightmaps: R_FindShader turns a lightmap that is not there into LIGHTMAP_BY_VERTEX</summary>
    procedure SetLightmapCount(ACount: Integer);
    function GetLightmapCount: Integer;
  end;

  /// <summary>The surfaces of a world as the renderer keeps them: the lists, not the OpenGL objects</summary>
  IQ3RenderWorld = interface
    ['{5F08B2C4-73E1-4D96-A8C3-E1946B07D5F2}']
    function GetBsp: IBspFile;
    function GetTree: TBspRenderTree;
    function GetVisibility: TBspVisibility;
    function GetLightGrid: TBspLightGrid;
    function GetLightmaps: TArray<TBytes>;
    function GetFaces: TArray<TBspFaceSurface>;
    function GetTriangleSurfaces: TArray<TBspTriangleSurface>;
    function GetFlares: TArray<TBspFlareSurface>;
    /// <summary>The number of patch grids that are drawn</summary>
    function PatchCount: Integer;
    /// <summary>Surfaces of every type (planar, patch, triangle soup, flare) as the BSP has them</summary>
    function SurfaceCount: Integer;
    /// <summary>Surfaces the loaders refused (a bad index, a face past the lumps): the C reads past or drops</summary>
    function RefusedCount: Integer;
    function FogCount: Integer;
    function SubmodelCount: Integer;
    /// <summary>The shader names of the BSP (index = shader number of the surfaces)</summary>
    function ShaderNames: TArray<AnsiString>;
    /// <summary>R_inPVS: do the two points see each other (a cluster of -1 sees everything)</summary>
    function InPvs(const APoint1, APoint2: TQ3RenderVec3): Boolean;
    /// <summary>The bounds of model "*AIndex", False if there is no such submodel</summary>
    function SubmodelBounds(AIndex: Integer; out AMins, AMaxs: TQ3RenderVec3): Boolean;
    /// <summary>The msurface_t table (R1): one entry per surface of the BSP, in the order of the lump</summary>
    function GetSurfaces: TArray<TQ3WorldSurface>;
    /// <summary>The grid of every surface that is a drawn patch (nil for any other surface)</summary>
    function GetGrids: TArray<IPatchGrid>;
    /// <summary>
    ///   world_t.fogs: the entry 0 is "no fog" and the fogs of the BSP follow (numfogs is the length). A fog whose
    ///   brush is not in the lumps gets an empty box that nothing is inside (the C stops with an error)
    /// </summary>
    function GetFogs: TArray<TQ3WorldFog>;
    /// <summary>tr.numLightmaps</summary>
    function GetLightmapCount: Integer;
  end;

  /// <summary>RE_LoadWorldMap</summary>
  IQ3WorldLoader = interface
    ['{E27D59A0-8C14-4B36-90F7-2A5D8E1C4B73}']
    /// <summary>Loads the BSP; nil when the file is not there; a damaged file is an EQ3RenderException</summary>
    function Load(const AName: AnsiString): IQ3RenderWorld;
  end;

  /// <summary>R_LoadMD3 and the model table: models as data</summary>
  IQ3ModelRegistry = interface
    ['{B6C03E71-5A28-4F94-83D1-0E7A9C42F5B6}']
    /// <summary>
    ///   RE_RegisterModel: the handle (1, 2, ...); 0 for a name that does not load. A name "*N" is the submodel N of
    ///   the world given to SetWorld
    /// </summary>
    function Register(const AName: AnsiString): Integer;
    procedure SetWorld(const AWorld: IQ3RenderWorld);
    /// <summary>The md3 of a handle (lod 0), nil for a brush model or a missing one</summary>
    function GetModel(AHandle: Integer): IMd3Model;
    /// <summary>The levels of detail of a model that were loaded (mod->numLods): 1 to 3, 0 for a handle without an md3</summary>
    function LodCount(AHandle: Integer): Integer;
    /// <summary>
    ///   mod->md3[lod]: the md3 of a level of detail (0 the most detailed). A level the files do not have is the next
    ///   lower one that is there (the C leaves it NULL and crashes); a level past the last is the last
    /// </summary>
    function GetModelLod(AHandle, ALod: Integer): IMd3Model;
    function LoadedCount: Integer;
    function MissingNames: TArray<string>;
    /// <summary>The number N of a brush model "*N" of the world, -1 for a mesh and for a handle that is no model</summary>
    function BrushIndex(AHandle: Integer): Integer;
    /// <summary>R_ModelBounds: False when the handle is not a model with bounds</summary>
    function ModelBounds(AHandle: Integer; out AMins, AMaxs: TQ3RenderVec3): Boolean;
    /// <summary>R_LerpTag: False when the model or the tag is not there (the origin and axis are cleared)</summary>
    function LerpTag(AHandle, AStartFrame, AEndFrame: Integer; AFraction: Single; const ATagName: AnsiString;
      out AOrigin: TQ3RenderVec3; out AAxis: TQ3RenderAxis): Boolean;
  end;

  /// <summary>The tables of a renderer without OpenGL, built from one file system by TQ3RenderFactory</summary>
  IQ3RenderSystem = interface
    ['{3A9D41F6-0C57-4E82-B6A3-F18D2E70C4B9}']
    function GetImages: IQ3ImageCatalog;
    function GetShaders: IQ3ShaderRegistry;
    function GetModels: IQ3ModelRegistry;
    function GetWorldLoader: IQ3WorldLoader;
    property Images: IQ3ImageCatalog read GetImages;
    property Shaders: IQ3ShaderRegistry read GetShaders;
    property Models: IQ3ModelRegistry read GetModels;
    property WorldLoader: IQ3WorldLoader read GetWorldLoader;
  end;

implementation

end.
