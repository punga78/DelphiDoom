{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - composition root                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Composition;

interface

/// <summary>
///   The one place that chooses the classes behind the interfaces of the engine and
///   gives them to the units that use them. Call it first thing in the program, before
///   anything opens a WAD or a PAK
/// </summary>
procedure ComposeEngine;

implementation

uses
  System.SysUtils,
  DelphiDoom.Logging.Factory,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Engine.Log.Sink,
  DelphiDoom.Clock.Factory,
  DelphiDoom.Video.Intf,
  DelphiDoom.Video.Factory,
  DelphiDoom.Acs.Factory,
  DelphiDoom.Udmf.Games,
  DelphiDoom.Udmf.Factory,
  DelphiDoom.Engine.Udmf.SoundResolver,
  DelphiDoom.Udmf.Apply.Factory,
  DelphiDoom.Engine.Udmf.SectorApplier,
  DelphiDoom.Engine.Udmf.LineApplier,
  DelphiDoom.Engine.Udmf.SideApplier,
  DelphiDoom.Engine.Udmf.SegApplier,
  m_base,
  p_udmf,
{$IFNDEF HEXEN}
  udmf_spec,
  DelphiDoom.Specials.Factory,
  DelphiDoom.MapInfo.Intf,
  DelphiDoom.MapInfo.Factory,
  DelphiDoom.Engine.MapInfo.Services,
  DelphiDoom.Engine.MapInfo.TextSource,
  p_umapinfo,
{$ENDIF}
  DelphiDoom.Engine.Acs.SourceProvider,
  DelphiDoom.Engine.Acs.Host,
  DelphiDoom.Dehacked.Games,
  DelphiDoom.Dehacked.Factory,
  DelphiDoom.Actions.Factory,
  deh_base,
  deh_main,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.Games,
  DelphiDoom.Iwad.Factory,
  DelphiDoom.Engine.Iwad.Options,
  DelphiDoom.Zone.Factory,
  DelphiDoom.Engine.Zone.Memory,
  z_zone,
  d_net,
{$IFNDEF HEXEN}
  DelphiDoom.Endoom.Factory,
  DelphiDoom.Engine.Endoom.Intf,
  DelphiDoom.Engine.Endoom.Screen,
{$ENDIF}
  DelphiDoom.MathCore.Intf,
  DelphiDoom.MathCore.Factory,
  m_rnd,
  DelphiDoom.Serializer.Intf,
  DelphiDoom.Serializer.Factory,
  DelphiDoom.Engine.Serializer.Resolver,
  p_serializer,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.Factory,
  DelphiDoom.Engine.Imaging.ColorIndex,
  DelphiDoom.Screenshot.Factory,
  DelphiDoom.Engine.Screenshot.Folders,
  DelphiDoom.Png.Provider,
  DelphiDoom.Jpeg.Provider,
  DelphiDoom.Texture.Intf,
  DelphiDoom.Texture.Factory,
  DelphiDoom.Engine.Texture.PaletteSource,
  DelphiDoom.Engine.Texture.PngReader,
  DelphiDoom.Engine.Texture.PngSettings,
  DelphiDoom.Engine.Texture.JpegConverter,
  DelphiDoom.Engine.Texture.Resolver,
  DelphiDoom.Engine.Texture.Intf,
  DelphiDoom.Engine.Texture.Files,
  t_draw,
  w_sprite,
  r_pk3textures,
{$IFDEF OPENGL}
  gl_tex,
{$ELSE}
  r_cache_walls,
{$ENDIF}
{$IFNDEF OPENGL}
  r_cache_flats,
  r_patch,
{$ENDIF}
  DelphiDoom.Console.Intf,
  DelphiDoom.Console.Factory,
  DelphiDoom.Engine.Console.Output,
  DelphiDoom.Engine.Console.FileSystem,
  DelphiDoom.Engine.Console.Startup,
  DelphiDoom.Engine.Console.VariableSource,
  c_cmds,
  r_translations,
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  r_colormaps,
{$ENDIF}
  r_draw,
  r_precalc,
  r_main,
  v_video,
  c_con,
  DelphiDoom.TextureDefs.Types,
  DelphiDoom.TextureDefs.Intf,
  DelphiDoom.TextureDefs.Factory,
  DelphiDoom.Engine.TextureDefs.LumpSource,
  DelphiDoom.Engine.TextureDefs.FlatCatalog,
  r_data,
  DelphiDoom.Palette.Types,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Palette.Factory,
  r_palette,
  DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf,
  DelphiDoom.Definitions.Factory,
  DelphiDoom.Engine.Definitions.AnimCatalog,
  DelphiDoom.Engine.Definitions.TextureLookup,
{$IFDEF DOOM}
  p_switch,
{$ENDIF}
  p_animdefs,
  DelphiDoom.MusInfo.Intf,
  DelphiDoom.MusInfo.Factory,
  DelphiDoom.Engine.MusInfo.Services,
  p_musinfo,
  DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.Factory,
  DelphiDoom.Engine.Nodes.LumpSource,
  nd_main,
  DelphiDoom.DynLights.Types,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.DynLights.Factory,
  DelphiDoom.Engine.DynLights.Services,
{$IFDEF OPENGL}
  gl_render,
{$ELSE}
  r_softlights,
{$ENDIF}
{$IFDEF OPENGL}
  gl_defs,
  DelphiDoom.GlMath.Factory,
  gl_clipper,
  gl_models,
{$ENDIF}
  DelphiDoom.Automap.Intf,
  DelphiDoom.Automap.Factory,
  am_map,
  DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf,
  DelphiDoom.ActorDef.Profiles,
  DelphiDoom.ActorDef.Factory,
  DelphiDoom.Engine.ActorDef.Catalog,
  DelphiDoom.Engine.ActorDef.Hooks,
  DelphiDoom.Engine.ActorDef.SoundInfoListener,
  sc_actordef,
  DelphiDoom.TableExport.Types,
  DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.Profile,
  DelphiDoom.TableExport.Profiles,
  DelphiDoom.TableExport.Factory,
  DelphiDoom.Engine.TableExport.Things,
  DelphiDoom.Engine.TableExport.States,
  DelphiDoom.Engine.TableExport.Weapons,
  DelphiDoom.Engine.TableExport.Settings,
  DelphiDoom.Engine.TableExport.Names,
  info_export,
  DelphiDoom.Voxel.Intf,
  DelphiDoom.Voxel.Factory,
  DelphiDoom.Engine.Voxel.FileSource,
  DelphiDoom.Engine.Voxel.ColorMapper,
  DelphiDoom.Engine.Voxel.DefinitionLookup,
  DelphiDoom.Engine.Voxel.DefinitionSink,
  DelphiDoom.Engine.Voxel.LumpNames,
  DelphiDoom.Engine.Voxel.SpriteGenerator,
  vx_base,
{$IFDEF OPENGL}
  gl_voxels,
{$ELSE}
  r_voxels,
{$ENDIF}
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.Factory,
  DelphiDoom.Engine.Audio.DirectSoundDevice,
  DelphiDoom.Engine.Audio.SfxSampleSource,
  DelphiDoom.Engine.Music.ModuleBackend,
  DelphiDoom.Engine.Music.Mp3Backend,
  DelphiDoom.Engine.Music.Id3Backend,
  DelphiDoom.Engine.Music.XmiBackend,
  DelphiDoom.Engine.Music.MusBackend,
  DelphiDoom.Engine.Music.MidiFileBackend,
  DelphiDoom.Engine.Music.ExternalSource,
  DelphiDoom.Mp3.Provider,
  s_sound,
  DelphiDoom.GameState.Intf,
  DelphiDoom.Engine.GameContext,
  DelphiDoom.Input.Intf,
  DelphiDoom.Input.Factory,
  DelphiDoom.Engine.Input.KeyMap,
  DelphiDoom.Engine.Input.Sink,
  DelphiDoom.Engine.Input.Gate,
  DelphiDoom.Engine.Input.ScreenSize,
  g_game,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_main,
  i_video,
{$ENDIF}
  m_menu,
  d_event,
  i_mainwindow,
  i_sound,
  p_acs,
  i_music,
  DelphiDoom.Configuration.Factory,
  DelphiDoom.CommandLine.Factory,
  DelphiDoom.IdTech.Intf,
  DelphiDoom.IdTech.Factory,
  DelphiDoom.Engine.Wad.Intf,
  DelphiDoom.Engine.Wad.Services,
  w_wad,
  w_wadreader,
  w_wadwriter,
  w_pak,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Pak.FileSystem,
  DelphiDoom.Scanner.AutoLoad,
  DelphiDoom.Engine.Wad.AutoLoadLumps,
  DelphiDoom.Engine.Wad.AutoLoadSink,
  DelphiDoom.Engine.Scanner.Log,
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Scanner.TextPreprocessor,
  DelphiDoom.Scanner.Directive.Flag,
  DelphiDoom.Scanner.Directive.CvarForce,
  DelphiDoom.Scanner.Directive.CreatePalette,
  DelphiDoom.Scanner.ContextEvaluator.Intf,
  DelphiDoom.Scanner.ContextEvaluator,
  DelphiDoom.Engine.Scanner.IncludeSource,
  DelphiDoom.Engine.Scanner.CvarSetter,
  DelphiDoom.Engine.Scanner.PaletteGenerator,
  DelphiDoom.Engine.Scanner.DefinesSource,
  DelphiDoom.Engine.Scanner.ActorVariables,
  DelphiDoom.Engine.Scanner.ActorFunctions,
  sc_utils,
  sc_params,
  doomdef,
  d_main,
  m_argv,
  m_misc,
  i_system,
  i_tmp,
  DelphiDoom.Platform.Intf,
  DelphiDoom.Platform.Factory,
  DelphiDoom.Engine.Platform.TempDirectory;

// The script preprocessor (given back: ActorDef, MapInfo, DynLights and MODELDEF use it)
// and the evaluator of the expressions in the parameters of the actors
function ComposeScanner(const ALog: ILog): IScriptTextPreprocessor;
var
  LDirectives: TArray<IScriptDirective>;
  LEvaluator: TContextExpressionEvaluator;
  LEvaluatorRef: IContextExpressionEvaluator;
begin
{$IFDEF DOOM}
  LDirectives := TArray<IScriptDirective>.Create(
    TFlagDirective.Create(TArray<string>.Create('VANILLA_DEMO_OFF', '#VANILLA_DEMO_OFF', '{$VANILLA_DEMO_OFF}'),
      procedure
      begin
        vanilla_demo_off := true;
      end),
    TCvarForceDirective.Create(TEngineCvarSetter.Create, ALog),
    TCreatePaletteDirective.Create(TEnginePaletteGenerator.Create, ALog));
{$ELSE}
  LDirectives := TArray<IScriptDirective>.Create(
    TCvarForceDirective.Create(TEngineCvarSetter.Create, ALog),
    TCreatePaletteDirective.Create(TEnginePaletteGenerator.Create, ALog));
{$ENDIF}
  Result := TScriptTextPreprocessor.Create(TEngineIncludeSource.Create, LDirectives,
    TEngineScriptDefinesSource.Create, ALog);
  // VOXELDEF (vx_base) still goes through the facade
  SC_ConfigurePreprocessor(Result);

  LEvaluator := TContextExpressionEvaluator.Create(ALog, TEngineActorExpressionVariables.Create);
  LEvaluatorRef := LEvaluator;
  TEngineActorExpressionFunctions.Register(LEvaluator);
  SC_ConfigureParams(LEvaluatorRef);
end;

procedure ComposeDisplayModes;
var
  LCatalog: IDisplayModeCatalog;
begin
  // the video fills the catalog when the graphics start; the menus list it
  LCatalog := TVideoFactory.CreateDisplayModeCatalog(TVideoFactory.CreateWindowsDisplayModeSource);
{$IFDEF OPENGL}
  GL_ConfigureDisplayModes(LCatalog);
{$ELSE}
  I_ConfigureDisplayModes(LCatalog);
{$ENDIF}
  M_ConfigureDisplayModes(LCatalog);
end;

{$IFNDEF HEXEN}
procedure ComposeEndoom;
var
  LScreen: IEngineEndoomScreen;
begin
  LScreen := TEngineEndoomScreen.Create(TEndoomFactory.CreateRenderer,
    TEndoomFactory.CreateSession(TICRATE),
    function: string
    begin
      // DEHACKED can change it after the start (END_TEXT_LUMP)
      Result := EndLumpName;
    end);
  D_ConfigureEndoom(LScreen);
  G_ConfigureEndoom(LScreen);
  D_ConfigureNetEndoom(LScreen);
{$IFDEF OPENGL}
  GL_ConfigureEndoom(LScreen);
{$ENDIF}
end;
{$ENDIF}

procedure ComposeInput(const ALog: ILog);
var
  LWindow: TFunc<THandle>;
  LPoller: IInputPoller;
begin
  LWindow :=
    function: THandle
    begin
      Result := hMainWnd;
    end;
  // One poller for the whole program, idle until I_Init starts it. The keyboard is the one of
  // Windows: the choice of DirectInput (usedirectinput) was never set by anything
  LPoller := TInputFactory.CreatePoller(TInputFactory.CreateWindowsKeyboard,
    TInputFactory.CreateWindowsMouse, TInputFactory.CreateWindowsJoystick(LWindow),
    TEngineInputGate.Create, TEngineScreenSize.Create, TEngineKeyMap.Create,
    TEngineInputSink.Create, ALog, NUMJOYBUTTONS);
  I_ConfigureInput(LPoller);
  G_ConfigureInput(LPoller);
{$IFDEF OPENGL}
  GL_ConfigureInput(LPoller);
{$ELSE}
  I_ConfigureWindowInput(LPoller);
{$ENDIF}
end;

procedure ComposeSound(const ALog: ILog);
var
  LWindow: TFunc<THandle>;
begin
  LWindow :=
    function: THandle
    begin
      Result := hMainWnd;
    end;
  I_ConfigureSound(
    function(AWithDevice: Boolean): ISfxPlayer
    var
      LDevice: ISoundDevice;
    begin
      LDevice := nil;
      if AWithDevice then
      begin
        LDevice := TDirectSoundDevice.Create(LWindow, ALog);
        // no sound card: the game goes on without sound
        if not LDevice.Initialize then
          LDevice := nil;
      end;
      Result := TAudioFactory.CreateSfxPlayer(LDevice, TEngineSfxSampleSource.Create, ALog);
    end);
end;

procedure ComposeMusic(const ATempFiles: ITempFiles);
begin
  // the order is the one in which a song is looked at: the first backend that knows it plays it
  I_ConfigureMusic(TAudioFactory.CreateMusicPlayer(TArray<IMusicBackend>.Create(
    TModuleMusicBackend.Create,
    TMp3MusicBackend.Create(TMp3Provider.Mp3),
    TId3MusicBackend.Create,
    TXmiMusicBackend.Create(ATempFiles),
    TMusMusicBackend.Create,
    TMidiFileMusicBackend.Create(ATempFiles))));
  S_ConfigureExternalMusic(TAudioFactory.CreateExternalMusicCache(
    TEngineExternalMusicSource.Create));
end;

{$IFNDEF HEXEN}
procedure ComposeMapInfo(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor);
var
  LServices: TEngineMapInfoServices;
  LTextSource: TEngineMapInfoTextSource;
  LMapServices: TMapInfoServices;
  LCatalog: IMapInfoCatalog;
begin
  LServices := TEngineMapInfoServices.Create;
  LTextSource := TEngineMapInfoTextSource.Create(APreprocessor);
  LMapServices.Validator := LServices;
  LMapServices.Lumps := LServices;
  LMapServices.Music := LServices;
  LMapServices.Actors := LServices;
  // the exit specials that a boss action may use depend on the game
{$IFDEF DOOM}
  LMapServices.BossRule := TMapInfoFactory.CreateTaggedBossActionRule(TArray<Integer>.Create(11, 51, 52, 124));
  LMapServices.Episodes := LServices;
{$ENDIF}
{$IFDEF HERETIC}
  LMapServices.BossRule := TMapInfoFactory.CreateTaggedBossActionRule(TArray<Integer>.Create(11, 51, 52, 105));
  LMapServices.Episodes := LServices;
{$ENDIF}
{$IFDEF STRIFE}
  // Strife has no episodes and a boss action may use any special
  LMapServices.BossRule := TMapInfoFactory.CreateOpenBossActionRule;
  LMapServices.Episodes := nil;
{$ENDIF}
  LCatalog := TMapInfoFactory.CreateCatalog(LServices);
  U_ConfigureMapInfo(
    TMapInfoFactory.CreateLoader(LTextSource, LTextSource,
      TMapInfoFactory.CreateParser(LMapServices, ALog), LCatalog),
    LCatalog);
end;
{$ENDIF}

procedure ComposeDehacked(const ALog: ILog);
var
  LGame: TDehackedGame;
begin
  if not TDehackedGames.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of DEHACKED', [_GAME]);
  DEH_Configure(TDehackedFactory.CreateParser(LGame, ALog));
  DEH_ConfigureActions(TActionsFactory.CreateRegistry);
end;

procedure ComposeDynLights(const ALog: ILog; const AContext: IGameContext;
  const APreprocessor: IScriptTextPreprocessor; const APakFiles: IPakFileSystem);
var
  LServices: TEngineDynLightServices;
  LServicesRef: IInterface;
  LRegistry: IDynLightRegistry;
  LParserServices: TDynLightParserServices;
  LCoefficient: Double;
  LCache: IDynLightRenderCache;
begin
  LServices := TEngineDynLightServices.Create(APreprocessor, APakFiles);
  LServicesRef := LServices;
  LRegistry := TDynLightFactory.CreateRegistry;
  LParserServices.Registry := LRegistry;
  LParserServices.Random := LServices;
  LParserServices.Objects := LServices;
  LParserServices.Sprites := LServices;
  LParserServices.Binder := TDynLightFactory.CreateBinder(LServices);
  LParserServices.Context := AContext;
{$IFDEF OPENGL}
  LCoefficient := MAP_COEFF;
{$ELSE}
  LCoefficient := 1;
{$ENDIF}
  LCache := TDynLightFactory.CreateRenderCache(
    TDynLightFactory.CreateLoader(LServices, LServices,
      TDynLightFactory.CreateParser(LParserServices, ALog, LCoefficient)),
    LRegistry,
    TDynLightFactory.CreateAnimator(LRegistry, LServices));
{$IFDEF OPENGL}
  gld_ConfigureDynamicLights(LCache);
{$ELSE}
  R_ConfigureDynamicLights(LCache);
  R_ConfigureSoftLights(LCache);
{$ENDIF}
end;

procedure ComposeMusInfo(const ALog: ILog);
var
  LServices: TEngineMusInfoServices;
  LServicesRef: IInterface;
  LCatalog: IMusInfoCatalog;
begin
  LServices := TEngineMusInfoServices.Create;
  LServicesRef := LServices;
  LCatalog := TMusInfoFactory.CreateCatalog(LServices, ALog);
  P_ConfigureMusInfo(LCatalog,
    TMusInfoFactory.CreateLoader(LServices, TMusInfoFactory.CreateParser(ALog), LCatalog));
end;

procedure ComposeNodes(const ATempFiles: ITempFiles);
var
  LSource: INodesLumpSource;
  LHexen: Boolean;
begin
  // the maps of Hexen are already in the Hexen format: the other games convert them for the node builder
{$IFDEF HEXEN}
  LHexen := True;
{$ELSE}
  LHexen := False;
{$ENDIF}
  LSource := TEngineNodesLumpSource.Create;
  ND_Configure(LSource, TNodesFactory.CreateGlDetector(LSource),
    TNodesFactory.CreateGlMapFinder(LSource),
    TNodesFactory.CreateGlbspInputBuilder(LSource, LHexen), ATempFiles, LHexen);
end;

procedure ComposeDefinitions(const ALog: ILog);
begin
  P_ConfigureAnimDefs(TDefinitionsFactory.CreateAnimDefsParser(TEngineAnimNameCatalog.Create, ALog));
  // the terrain of the flats has no state: r_data calls TTerrainTables directly
{$IFDEF DOOM}
  // The switches of Heretic, Hexen and Strife keep their own tables: they are used after the start
  P_ConfigureSwitches(TDefinitionsFactory.CreateSwitchLumpReader(False),
    TDefinitionsFactory.CreateSwitchSelector(TEngineTextureLookup.Create, ALog),
    TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom));
{$ENDIF}
end;

procedure ComposePalette(const APakFiles: IPakFileSystem);
var
  LMatcher: IColorMatcher;
begin
  LMatcher := TPaletteFactory.CreateColorMatcher;
  R_ConfigurePalette(TPaletteFactory.CreatePaletteUnpacker(TVideoFactory.CreatePaletteConverter));
  R_ConfigureColormaps(LMatcher, TPaletteFactory.CreateColormapPreparer);
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  R_ConfigureCustomColormaps(TPaletteFactory.CreateColormapPreparer);
{$ENDIF}
  R_ConfigureTranslations(TPaletteFactory.CreateTranslationNames, APakFiles);
  V_ConfigureGamma(TPaletteFactory.CreateGammaTables);
  R_ConfigureLightTables(TPaletteFactory.CreateLightTableCalculator);
  R_ConfigurePrecalc(TPaletteFactory.CreatePrecalcTables);
{$IF DEFINED(DOOM)}
  R_ConfigurePlayerTranslations(TPaletteFactory.CreateDoomPlayerTranslations);
{$ELSEIF DEFINED(HERETIC)}
  R_ConfigurePlayerTranslations(TPaletteFactory.CreateHereticPlayerTranslations);
{$ELSEIF DEFINED(STRIFE)}
  R_ConfigurePlayerTranslations(TPaletteFactory.CreateStrifePlayerTranslations);
{$ENDIF}
end;

procedure ComposeTextureDefs(const ALog: ILog; const APakFiles: IPakFileSystem);
var
  LFormat: TTextureDefsFormat;
begin
{$IFDEF STRIFE}
  LFormat := TTextureDefsFormat.Strife;
{$ELSE}
  LFormat := TTextureDefsFormat.Standard;
{$ENDIF}
  R_ConfigureTextureDefs(TTextureDefsFactory.CreateLoader(TEngineTextureLumpSource.Create, LFormat));
  R_ConfigureFlatInfo(TTextureDefsFactory.CreateFlatInfoParser(ALog), TEngineFlatCatalog.Create, APakFiles);
end;

procedure ComposeConsole(const ALog: ILog; const AGame: IGameContext);
var
  LRegistry: ICommandRegistry;
  LInterpreter: IConsoleInterpreter;
  LOutput: IConsoleOutput;
  LRunner: IConsoleScriptRunner;
  LVariables: IConsoleVariableSource;
begin
  LRegistry := TConsoleFactory.CreateRegistry;
  LInterpreter := TConsoleFactory.CreateInterpreter(LRegistry);
  C_ConfigureCommands(LRegistry, LInterpreter);
  LOutput := TEngineConsoleOutput.Create;
  LRunner := TConsoleFactory.CreateScriptRunner(LInterpreter, TEngineConsoleFileSystem.Create,
    LOutput, ALog);
  LVariables := TEngineConsoleVariableSource.Create;
  C_ConfigureScripts(
    TConsoleFactory.CreateStandardCommands(LRegistry, LOutput, LRunner),
    TConsoleFactory.CreateAutoExec(TEngineConsoleStartup.Create, LRunner, LOutput, AppTitle),
    TConsoleFactory.CreateVariableCommands(LRegistry, LVariables, LOutput, ALog, AGame));
  C_ConfigureInput(
    TConsoleFactory.CreateCommandQueue(LInterpreter),
    TConsoleFactory.CreateInputLine(']', LInterpreter, LOutput, TConsoleFactory.CreateHistory,
      TConsoleFactory.CreateCompleter(LRegistry, LVariables)));
end;

procedure ComposeImaging;
begin
{$IFNDEF OPENGL}
  R_ConfigureFlatCache(TImagingFactory.CreateSpanGrower);
{$ENDIF}
  V_ConfigureFlatShrink(TImagingFactory.CreateFlatShrinker);
  R_ConfigureComposite(TImagingFactory.CreateColumnPainter, TImagingFactory.CreateColumnRebuilder);
{$IFNDEF OPENGL}
  R_ConfigureFixedColumn(TImagingFactory.CreateFixedColumnBuilder);
{$ENDIF}
  R_ConfigureMenuThumbnail(TImagingFactory.CreateThumbnailBuilder(
    TEngineImagingColorIndex.Create(TPaletteFactory.CreateColorMatcher)));
end;

procedure ComposeScreenshot;
begin
  M_ConfigureScreenshot(TScreenshotFactory.CreateWriter(TPngProvider.Client, TJpegProvider.Client),
    TScreenshotFactory.CreateTargets(TEngineScreenshotFolders.Create));
end;

procedure ComposeTexture(const ALog: ILog; const APakFiles: IPakFileSystem);
var
  LServices: TTextureServices;
  LResolver: TEngineTextureResolver;
  LFiles: IEngineTextureFiles;
begin
  LServices.Palette := TEngineTexturePaletteSource.Create;
  LResolver := TEngineTextureResolver.Create;
  LServices.Resolver := LResolver;
  LServices.PngReader := TEngineTexturePngReader.Create;
  LServices.PngSettings := TEngineTexturePngSettings.Create;
  LServices.JpegConverter := TEngineTextureJpegConverter.Create;
  LServices.Log := ALog;
  LFiles := TEngineTextureFiles.Create(TTextureFactory.CreateFormats(LServices), APakFiles);
  // a material asks the files for the images it names: the resolver keeps them weakly
  LResolver.Attach(LFiles);
  T_ConfigureDrawTextures(LFiles);
  W_ConfigureSpriteTextures(LFiles);
  R_ConfigurePK3Textures(LFiles, APakFiles);
{$IFDEF OPENGL}
  gld_ConfigureTextureFiles(LFiles);
{$ELSE}
  R_ConfigureFlatTextures(LFiles);
  R_ConfigureWallTextures(LFiles);
{$ENDIF}
end;

// The temporary files are one object for the whole engine: who makes one receives it, and
// i_tmp deletes them all at the shut down
function ComposePlatform: ITempFiles;
var
  LStore: IFileStore;
begin
  LStore := TPlatformFactory.CreateFileStore;
  M_ConfigureFiles(LStore);
  Result := TPlatformFactory.CreateTempFiles(TEngineTempDirectory.Create, LStore);
  I_ConfigureTempFiles(Result);
  I_ConfigurePlatform(TPlatformFactory.CreateServices);
end;

procedure ComposeMathCore;
begin
  M_ConfigureRandom(TMathCoreFactory.CreateGameRandom);
  R_ConfigureNameHash(TMathCoreFactory.CreateStringHashTable);
end;

procedure ComposeSerializer;
var
  LResolver: TEngineSerializerResolver;
  LHolder: ISerializerStateResolver;
begin
  // one object answers for states, mobjs and players: an interface keeps it alive
  LResolver := TEngineSerializerResolver.Create;
  LHolder := LResolver;
  P_ConfigureSerializer(TSerializerFactory.Create(LResolver, LResolver, LResolver));
end;

{$IFDEF OPENGL}
procedure ComposeOpenGl(const APreprocessor: IScriptTextPreprocessor);
begin
  gld_ConfigureModelDefinitions(APreprocessor);
  GL_ConfigureClipper(TGlMathFactory.CreateAngleClipper);
end;
{$ENDIF}

procedure ComposeAutomap;
var
  LView: IAutomapView;
  LNavigator: IAutomapNavigator;
begin
  TAutomapFactory.CreateView(LView, LNavigator);
  AM_Configure(LView, LNavigator, TAutomapFactory.CreateMarks);
end;

procedure ComposeActorDef(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor);
var
  LGame: TActorDefGame;
  LProfile: TActorDefProfile;
  LCatalog: TEngineActorDefCatalog;
  LCatalogRef: IInterface;
  LHooks: TEngineActorDefHooks;
  LHooksRef: IInterface;
  LAliases: IActorDefSoundAliasTable;
  LListener: IActorDefSoundInfoListener;
begin
  if not TActorDefProfiles.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of ACTORDEF', [_GAME]);
  LProfile := TActorDefProfiles.ForGame(LGame);
  LCatalog := TEngineActorDefCatalog.Create;
  LCatalogRef := LCatalog;
  // a thinker is an actor written as text: it goes back to the parser through the facade
  LHooks := TEngineActorDefHooks.Create(ALog,
    procedure(AText: string)
    begin
      SC_ParseActordefLump(AText);
    end, APreprocessor);
  LHooksRef := LHooks;
  LAliases := TActorDefFactory.CreateSoundAliases(ALog);
{$IFDEF HEXEN}
  LListener := TEngineSoundInfoListener.Create;
{$ELSE}
  LListener := nil;
{$ENDIF}
  SC_ConfigureActorDef(
    TActorDefFactory.CreateParser(LProfile, ALog, LCatalog, LCatalog, LCatalog,
      TActorDefFactory.CreateDehSink(LProfile, LCatalog, LCatalog, LAliases, LHooks, ALog),
      LHooks, LHooks, LHooks),
    procedure(AText: string)
    begin
      TActorDefFactory.ParseSoundInfo(LProfile, AText, LAliases, LListener);
    end,
    LAliases, APreprocessor);
end;

procedure ComposeTableExport;
var
  LGame: TExportGame;
  LThings: IExportThingSource;
  LStates: IExportStateSource;
  LWeapons: IExportWeaponSource;
  LNames: TEngineExportNames;
  LNamesRef: IInterface;
begin
  if not TExportProfiles.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of the table exports', [_GAME]);
  LThings := TEngineExportThings.Create(False);
  LStates := TEngineExportStates.Create;
  LWeapons := TEngineExportWeapons.Create;
  LNames := TEngineExportNames.Create;
  LNamesRef := LNames;
  DEH_ConfigureExport(
    TTableExportFactory.CreateDehWriter(LGame, LThings, LStates, LWeapons, TEngineExportSettings.Create,
      LNames, LNames),
    TTableExportFactory.CreateCsvWriter(LStates, LNames),
    TTableExportFactory.CreateActorDefWriter(LThings, LStates, LNames, LNames, LNames),
    TTableExportFactory.CreateWeaponDefWriter(LGame, LWeapons, LStates, LNames, LNames),
    TTableExportFactory.CreateStateOwnersWriter(LStates, LNames));
  Info_ConfigureExport(
    TTableExportFactory.CreatePascalWriter(LGame, LThings, TEngineExportThings.Create(True), LStates,
      LNames, LNames, LNames));
end;

procedure ComposeIwad;
var
  LGame: TIwadGame;
  LServices: TIwadServices;
begin
  if not TIwadGames.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of IWADs', [_GAME]);
  LServices := TIwadFactory.CreateWindowsServices(LGame, TEngineIwadOptions.Create);
  D_ConfigureIwad(LServices.Locator, LServices.Identifier);
end;

procedure ComposeVoxels(const ALog: ILog; const APakFiles: IPakFileSystem);
var
  LLoader: IVoxelLoader;
  LCubes: IVoxelCubeBuilder;
  LLumps: IVoxelLumpNames;
begin
  LLoader := TVoxelFactory.CreateLoader(TEngineVoxelFileSource.Create(APakFiles), ALog);
  LCubes := TVoxelFactory.CreateCubeBuilder;
  LLumps := TEngineVoxelLumpNames.Create;
  R_ConfigureVoxelSprites(TEngineVoxelSpriteGenerator.Create(LLoader, LCubes,
    TVoxelFactory.CreatePatchBuilder(TEngineVoxelColorMapper.Create),
    function: IVoxelSpriteNames
    begin
      Result := TVoxelFactory.CreateSpriteNames(LLumps);
    end,
    function: Boolean
    begin
      // the option is read at each call: the .ini is read after the composition
      Result := r_generatespritesfromvoxels;
    end, APakFiles));
  // the sink makes the model of the renderer of each new voxel with the loader
  VX_ConfigureVoxels(
    TVoxelFactory.CreateDefinitionParser(TEngineVoxelDefinitionLookup.Create, ALog),
    TEngineVoxelDefinitionSink.Create(LLoader, LCubes));
end;

procedure ComposeUdmfApply;
begin
  P_ConfigureUdmfApply(
    TEngineUdmfSectorApplier.Create(
      TUdmfApplyFactory.CreateSectorInterpreter, TUdmfApplyFactory.CreateTriangleSlopes),
    TEngineUdmfLineApplier.Create(
      TUdmfApplyFactory.CreateLineSpecialTranslator(UDMF_SPECIAL_START, UDMF_NORMAL_ADD)),
    TEngineUdmfSideApplier.Create,
    TEngineUdmfSegApplier.Create(TUdmfApplyFactory.CreateFakeContrast));
end;

// The PAK file system is one object: the facade w_pak and the classes that read files share it
procedure ComposePak(const AServices: IEngineWadServices; out AFiles: IPakFileSystem;
  out AContainers: IPakContainers);
var
  LFileSystem: TPakFileSystem;
begin
  LFileSystem := TPakFileSystem.Create(AServices);
  AFiles := LFileSystem;
  AContainers := LFileSystem;
  PAK_Configure(AFiles, AContainers);
end;

procedure ComposeEngine;
var
  LWadServices: IEngineWadServices;
  LEngine: IIdTechEngine;
  LLog: ILog;
  LContext: IGameContext;
  LClock: IClock;
  LGame: TUdmfGame;
  LPreprocessor: IScriptTextPreprocessor;
  LTempFiles: ITempFiles;
  LPakFiles: IPakFileSystem;
  LPakContainers: IPakContainers;
begin
  // The zone first: whatever is built next can already allocate from it
  Z_ConfigureZone(TZoneFactory.CreateAllocator(TEngineZoneMemory.Create));
  // DelphiDoom is a port of the Doom engine: id Tech 1, at the version of doomdef
  LEngine := TIdTechFactory.CreateDelphiDoom(VERSION);
  D_Configure(LEngine);
  ComposeIwad;
  M_ConfigureArgv(TCommandLineFactory.CreateBuilder);
  M_ConfigureDefaults(TConfigurationFactory.CreateFormat);
  LContext := TEngineGameContext.Create;
  LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(TEngineLogSink.Create),
    function: Boolean
    begin
      Result := LContext.IsDeveloperMode;
    end);
  I_ConfigureLog(LLog);
  // The WAD services and the PAK file system: the classes that read files receive them
  LWadServices := TEngineWadServices.Create;
  ComposePak(LWadServices, LPakFiles, LPakContainers);
  LPreprocessor := ComposeScanner(LLog);
  LTempFiles := ComposePlatform;
  ComposeMathCore;
  ComposeSerializer;
{$IFDEF OPENGL}
  ComposeOpenGl(LPreprocessor);
{$ENDIF}
  ComposeConsole(LLog, LContext);
  LClock := TClockFactory.CreateClock(LLog);
  I_ConfigureClock(LClock);
  D_ConfigureNet(LClock, LLog, LContext);
  I_ConfigureVideo(TVideoFactory.CreateServices);
  ComposeDisplayModes;
  ComposeInput(LLog);
  ComposeSound(LLog);
  ComposeMusic(LTempFiles);
  ComposeDehacked(LLog);
  ComposeImaging;
  ComposeScreenshot;
  ComposeTexture(LLog, LPakFiles);
  ComposeTextureDefs(LLog, LPakFiles);
  ComposePalette(LPakFiles);
  ComposeDefinitions(LLog);
  ComposeMusInfo(LLog);
  ComposeNodes(LTempFiles);
  ComposeDynLights(LLog, LContext, LPreprocessor, LPakFiles);
  ComposeAutomap;
  ComposeActorDef(LLog, LPreprocessor);
  ComposeTableExport;
  P_ConfigureAcs(TAcsFactory.CreateCompiler(TEngineAcsSourceProvider.Create, LLog),
    TAcsFactory.CreateMachine(TEngineAcsHost.Create, LLog));
{$IFNDEF HEXEN}
  ComposeEndoom;
{$ENDIF}
  ComposeVoxels(LLog, LPakFiles);

  W_Configure(LWadServices);
  TWadReader.Configure(LWadServices);
  TWadWriter.Configure(LWadServices);
  D_ConfigureAutoLoad(TAutoLoadReader.Create(TEngineAutoLoadLumps.Create,
    TEngineAutoLoadSink.Create(LPakContainers), TEngineScannerLog.Create));
  if not TUdmfGames.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no format of text maps', [_GAME]);
  P_ConfigureUdmf(TUdmfFactory.CreateConverter(LGame, TEngineUdmfSoundResolver.Create, LLog), LWadServices);
  ComposeUdmfApply;
{$IFNDEF HEXEN}
  // Hexen has its own specials (p_spec): the UDMF ones are only for the other games
  P_ConfigureLineSpecials(TSpecialsFactory.CreateRegistry);
  ComposeMapInfo(LLog, LPreprocessor);
{$ENDIF}
end;

end.
