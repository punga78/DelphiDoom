{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - composition root }
{                                                                              }
{  Written for the repository (licence GPL v2 or later).                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Render.Intf;

type
  /// <summary>The only place that knows the classes of the library</summary>
  TQ3RenderFactory = class sealed
  public
    /// <summary>The reader of files over the file system of Framework\Wad</summary>
    class function CreateFiles(const AFileSystem: IGameFileSystem): IQ3RenderFiles; static;
    /// <summary>R_LoadImage</summary>
    class function CreateImageLoader(const AFiles: IQ3RenderFiles; const ALog: ILog = nil;
      AExtensionSearch: Boolean = False): IQ3ImageLoader; static;
    /// <summary>
    ///   Shaders (scripts/*.shader through the declaration manager of IdTech4\Decl), images, models and the BSP
    ///   loader, over one file system. AKeepPixels keeps the RGBA bytes of every image loaded (hundreds of
    ///   megabytes for a whole game); the default keeps only the sizes. AColorShift is r_mapOverBrightBits -
    ///   overbrightBits. AExtensionSearch (default True) is the image search of ioquake3, which OpenArena uses: see
    ///   TQ3ImageLoader (False is the R_LoadImage of Quake III 1.32)
    /// </summary>
    class function CreateSystem(const AFileSystem: IGameFileSystem; const ALog: ILog = nil;
      AKeepPixels: Boolean = False; AColorShift: Integer = 1; AExtensionSearch: Boolean = True): IQ3RenderSystem; static;
    /// <summary>
    ///   The renderer that cgame and ui call: AInner (the recording renderer of Q3Host, or any IQ3HostRenderer) gets
    ///   every call as before, and the tables of ASystem are filled by the registrations
    /// </summary>
    class function CreateHostRenderer(const AInner: IQ3HostRenderer; const ASystem: IQ3RenderSystem;
      const ALog: ILog = nil): IQ3HostRenderer; static;
  end;

implementation

uses
  DelphiDoom.Decl.Factory, DelphiDoom.Models.Static.Factory, DelphiDoom.Models.Q3Player.Factory,
  DelphiDoom.MapFile.Bsp.Factory, DelphiDoom.Q3Render.Files.GameFs, DelphiDoom.Q3Render.Image.Loader,
  DelphiDoom.Q3Render.Image.Catalog, DelphiDoom.Q3Render.Shader.Registry, DelphiDoom.Q3Render.Model.Registry,
  DelphiDoom.Q3Render.World.Loader, DelphiDoom.Q3Render.System, DelphiDoom.Q3Render.Host.Adapter;

class function TQ3RenderFactory.CreateFiles(const AFileSystem: IGameFileSystem): IQ3RenderFiles;
begin
  Result := TQ3RenderGameFiles.Create(AFileSystem);
end;

class function TQ3RenderFactory.CreateImageLoader(const AFiles: IQ3RenderFiles; const ALog: ILog;
  AExtensionSearch: Boolean): IQ3ImageLoader;
begin
  Result := TQ3ImageLoader.Create(AFiles, ALog, AExtensionSearch);
end;

class function TQ3RenderFactory.CreateSystem(const AFileSystem: IGameFileSystem; const ALog: ILog;
  AKeepPixels: Boolean; AColorShift: Integer; AExtensionSearch: Boolean): IQ3RenderSystem;
var
  LFiles: IQ3RenderFiles;
  LImages: IQ3ImageCatalog;
  LShaders: IQ3ShaderRegistry;
  LModels: IQ3ModelRegistry;
  LWorld: IQ3WorldLoader;
begin
  LFiles := CreateFiles(AFileSystem);
  LImages := TQ3ImageCatalog.Create(CreateImageLoader(LFiles, ALog, AExtensionSearch), AKeepPixels);
  LShaders := TQ3ShaderRegistry.Create(TDeclFactory.CreateQuake3ShaderManagerOnFileSystem(AFileSystem, nil, nil),
    LImages);
  LModels := TQ3ModelRegistry.Create(LFiles, TStaticModelFactory.CreateMd3Reader, LShaders,
    TQ3PlayerFactory.CreateTagLerper, ALog);
  LWorld := TQ3WorldLoader.Create(LFiles, TBspFactory.CreateReader, TBspFactory.CreateTreeLoader,
    TBspFactory.CreateVisibilityLoader, TBspFactory.CreateLightmapLoader, TBspFactory.CreateLightGridLoader,
    TBspFactory.CreateFaceLoader(AColorShift), TBspFactory.CreateTriangleLoader(AColorShift),
    TBspFactory.CreateFlareLoader, TBspFactory.CreatePatchLoader(AColorShift), AColorShift, ALog);
  Result := TQ3RenderSystem.Create(LImages, LShaders, LModels, LWorld);
end;

class function TQ3RenderFactory.CreateHostRenderer(const AInner: IQ3HostRenderer; const ASystem: IQ3RenderSystem;
  const ALog: ILog): IQ3HostRenderer;
begin
  Result := TQ3HostRendererAdapter.Create(AInner, ASystem.Shaders, ASystem.Models, ASystem.WorldLoader, ALog);
end;

end.
