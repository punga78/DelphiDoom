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
  DelphiDoom.Engine.Dehacked.Applier,
  deh_base,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.Games,
  DelphiDoom.Iwad.Factory,
  DelphiDoom.Engine.Iwad.Options,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Zone.Factory,
  DelphiDoom.Engine.Zone.Memory,
  DelphiDoom.Engine.Zone.Allocator,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Wad.Lumps,
  z_zone,
  DelphiDoom.Engine.Net.Intf,
  DelphiDoom.Engine.Net.Game,
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
  t_main,
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
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.Engine.Console.Screen,
  DelphiDoom.Engine.Configuration.Intf,
  DelphiDoom.Engine.Configuration.Defaults,
  DelphiDoom.Engine.Screenshot.Intf,
  DelphiDoom.Engine.Screenshot.Service,
  DelphiDoom.Engine.Platform.Intf,
  DelphiDoom.Engine.Platform.Files,
  DelphiDoom.Engine.Palette.Intf,
  DelphiDoom.Engine.Palette.DefaultPalette,
  c_cmds,
  r_translations,
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  r_colormaps,
{$ENDIF}
  r_draw,
  r_precalc,
  r_main,
  v_video,
{$IFNDEF OPENGL}
  v_displaymode,
{$ENDIF}
  p_tick,
  p_common,
  psi_system,
  psi_globals,
  w_utils,
{$IFDEF HEXEN}
  g_demo,
  sv_save,
{$ENDIF}
{$IFDEF STRIFE}
  p_saveg,
{$ENDIF}
  DelphiDoom.TextureDefs.Types,
  DelphiDoom.TextureDefs.Intf,
  DelphiDoom.TextureDefs.Factory,
  DelphiDoom.Engine.TextureDefs.LumpSource,
  DelphiDoom.Engine.TextureDefs.FlatCatalog,
  r_data,
  DelphiDoom.Palette.Types,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Palette.Factory,
  DelphiDoom.Palette.Profiles,
  DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf,
  DelphiDoom.Definitions.Factory,
  DelphiDoom.Engine.Definitions.AnimCatalog,
  DelphiDoom.Engine.Definitions.TextureLookup,
  DelphiDoom.Engine.Definitions.Intf,
  DelphiDoom.Engine.Definitions.AnimDefsLoader,
{$IFDEF DOOM}
  DelphiDoom.Engine.Definitions.SwitchListLoader,
{$ENDIF}
  DelphiDoom.MusInfo.Intf,
  DelphiDoom.MusInfo.Factory,
  DelphiDoom.Engine.MusInfo.Services,
  p_musinfo,
  DelphiDoom.Nodes.Intf,
  DelphiDoom.Nodes.Factory,
  DelphiDoom.Engine.Nodes.LumpSource,
  DelphiDoom.Blockmap.Factory,
  DelphiDoom.Engine.Udmf.MapLoader,
  DelphiDoom.Engine.Level.Intf,
  DelphiDoom.Engine.Level.Loader,
  DelphiDoom.Engine.Level.MapReader,
  DelphiDoom.Engine.Level.Things,
  DelphiDoom.Engine.Level.Nodes,
  DelphiDoom.Engine.Level.Blockmap,
{$IF DEFINED(DOOM)}
  DelphiDoom.Engine.Level.VanillaNodes,
  DelphiDoom.Engine.Level.DoomRules,
{$ELSEIF DEFINED(HERETIC)}
  DelphiDoom.Engine.Level.HereticRules,
{$ELSEIF DEFINED(HEXEN)}
  DelphiDoom.Engine.Level.HexenRules,
{$ELSE}
  DelphiDoom.Engine.Level.StrifeRules,
{$ENDIF}
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
  DelphiDoom.Engine.ActorDef.Intf,
  DelphiDoom.Engine.ActorDef.Lumps,
  sounds,
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
  DelphiDoom.M2m.Engine,
  DelphiDoom.Engine.Music.Intf,
  DelphiDoom.Engine.Music.ModuleBackend,
  DelphiDoom.Engine.Music.Mp3Backend,
  DelphiDoom.Engine.Music.Id3Backend,
  DelphiDoom.Engine.Music.XmiBackend,
  DelphiDoom.Engine.Music.MusBackend,
  DelphiDoom.Engine.Music.MidiFileBackend,
  DelphiDoom.Engine.Music.ExternalSource,
  DelphiDoom.Mp3.Provider,
  s_sound,
  s_pk3sounds,
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
  p_acs,
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
  DelphiDoom.Scanner.GameDefines,
  DelphiDoom.Engine.Scanner.ActorVariables,
  DelphiDoom.Engine.Scanner.ActorFunctions,
  doomdef,
  d_main,
  m_argv,
  i_system,
  i_tmp,
  DelphiDoom.Platform.Intf,
  DelphiDoom.Platform.Factory,
  DelphiDoom.Engine.Platform.TempDirectory;

// The script preprocessor (given back: ActorDef, MapInfo, DynLights, VOXELDEF and MODELDEF use
// it), the defines of the game that it reads, and the evaluator of the expressions in the
// parameters of the actors (given back: the DEHACKED applier gives it to the parameter lists)
function ComposeScanner(const ALog: ILog; const ADefaults: IEngineDefaults; const ALumps: IEngineLumps;
  const AZone: IZoneAllocator;
  out AEvaluator: IContextExpressionEvaluator): IScriptTextPreprocessor;
var
  LDirectives: TArray<IScriptDirective>;
  LEvaluator: TContextExpressionEvaluator;
  LGameDefines: IScriptGameDefines;
  LPalettes: IPaletteGenerator;
begin
  // #CREATEPALETTE makes the palettes of the profile of the game; Hexen has no FOGMAP
{$IFDEF HEXEN}
  LPalettes := TEnginePaletteGenerator.Create(TPaletteFactory.CreatePaletteBuilder(
    TPaletteFactory.CreateColorMatcher, TPaletteProfiles.Hexen), False, ALumps, AZone);
{$ELSE}
  LPalettes := TEnginePaletteGenerator.Create(TPaletteFactory.CreatePaletteBuilder(
    TPaletteFactory.CreateColorMatcher, TPaletteProfiles.Doom), True, ALumps, AZone);
{$ENDIF}
{$IFDEF DOOM}
  LDirectives := TArray<IScriptDirective>.Create(
    TFlagDirective.Create(TArray<string>.Create('VANILLA_DEMO_OFF', '#VANILLA_DEMO_OFF', '{$VANILLA_DEMO_OFF}'),
      procedure
      begin
        vanilla_demo_off := true;
      end),
    TCvarForceDirective.Create(TEngineCvarSetter.Create(ADefaults), ALog),
    TCreatePaletteDirective.Create(LPalettes, ALog));
{$ELSE}
  LDirectives := TArray<IScriptDirective>.Create(
    TCvarForceDirective.Create(TEngineCvarSetter.Create(ADefaults), ALog),
    TCreatePaletteDirective.Create(LPalettes, ALog));
{$ENDIF}
  // the game fills its defines while it starts (D_FillGameDefines), the preprocessor reads them
  LGameDefines := TScriptGameDefines.Create;
  D_ConfigureGameDefines(LGameDefines);
  Result := TScriptTextPreprocessor.Create(TEngineIncludeSource.Create(ALumps), LDirectives,
    LGameDefines, ALog);

  LEvaluator := TContextExpressionEvaluator.Create(ALog, TEngineActorExpressionVariables.Create);
  AEvaluator := LEvaluator;
  TEngineActorExpressionFunctions.Register(LEvaluator);
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

// The end screen; the result is its tic, that the loop of the network runs (nothing in Hexen,
// which has no end screen)
function ComposeEndoom(const ALumps: IEngineLumps; const AZone: IZoneAllocator): TProc;
{$IFNDEF HEXEN}
var
  LScreen: IEngineEndoomScreen;
{$ENDIF}
begin
{$IFDEF HEXEN}
  Result :=
    procedure
    begin
    end;
{$ELSE}
  LScreen := TEngineEndoomScreen.Create(TEndoomFactory.CreateRenderer,
    TEndoomFactory.CreateSession(TICRATE),
    function: string
    begin
      // DEHACKED can change it after the start (END_TEXT_LUMP)
      Result := EndLumpName;
    end, ALumps, AZone);
  D_ConfigureEndoom(LScreen);
  G_ConfigureEndoom(LScreen);
{$IFDEF OPENGL}
  GL_ConfigureEndoom(LScreen);
{$ENDIF}
  Result :=
    procedure
    begin
      LScreen.Tick;
    end;
{$ENDIF}
end;

procedure ComposeNetGame(const AClock: IClock; const ALog: ILog; const AGame: IGameContext;
  const AConsole: IEngineConsole; const AEndScreenTick: TProc);
var
  LNetGame: IEngineNetGame;
begin
  LNetGame := TEngineNetGame.Create(AClock, ALog, AGame, AConsole, AEndScreenTick);
  D_ConfigureNetGame(LNetGame);
  G_ConfigureNetGame(LNetGame);
  R_ConfigureNetGame(LNetGame);
  I_ConfigureNetGame(LNetGame);
end;

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
  S_ConfigureSound(
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
      Result := TAudioFactory.CreateSfxPlayer(LDevice, TEngineSfxSampleSource.Create(ALog), ALog);
    end);
end;

procedure ComposeMusic(const ATempFiles: ITempFiles; const AZone: IZoneAllocator);
var
  LMidiStream: IEngineMidiStream;
  LMus: IMusicBackend;
begin
  // the midi stream of the MUS songs is closed by the backends of the MIDI files
  LMidiStream := TMusMusicBackend.Create(TM2mEngine.Create);
  LMus := LMidiStream as IMusicBackend;
  // the order is the one in which a song is looked at: the first backend that knows it plays it
  S_ConfigureMusic(TAudioFactory.CreateMusicPlayer(TArray<IMusicBackend>.Create(
    TModuleMusicBackend.Create,
    TMp3MusicBackend.Create(TMp3Provider.Mp3),
    TId3MusicBackend.Create,
    TXmiMusicBackend.Create(ATempFiles, LMidiStream),
    LMus,
    TMidiFileMusicBackend.Create(ATempFiles, LMidiStream))));
  S_ConfigureExternalMusic(TAudioFactory.CreateExternalMusicCache(
    TEngineExternalMusicSource.Create(AZone)));
end;

{$IFNDEF HEXEN}
procedure ComposeMapInfo(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor;
  const ALumps: IEngineLumps);
var
  LServices: TEngineMapInfoServices;
  LTextSource: TEngineMapInfoTextSource;
  LMapServices: TMapInfoServices;
  LCatalog: IMapInfoCatalog;
begin
  LServices := TEngineMapInfoServices.Create(ALumps);
  LTextSource := TEngineMapInfoTextSource.Create(APreprocessor, ALumps);
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

procedure ComposeDehacked(const ALog: ILog; const AEvaluator: IContextExpressionEvaluator);
var
  LGame: TDehackedGame;
begin
  if not TDehackedGames.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of DEHACKED', [_GAME]);
  // TEngineDehackedApplier is the class of the game (one unit with this name in each folder)
  DEH_ConfigureApplier(TEngineDehackedApplier.Create(TDehackedFactory.CreateParser(LGame, ALog),
    AEvaluator));
  DEH_ConfigureActions(TActionsFactory.CreateRegistry);
end;

procedure ComposeDynLights(const ALog: ILog; const AContext: IGameContext;
  const APreprocessor: IScriptTextPreprocessor);
var
  LServices: TEngineDynLightServices;
  LServicesRef: IInterface;
  LRegistry: IDynLightRegistry;
  LParserServices: TDynLightParserServices;
  LCoefficient: Double;
  LCache: IDynLightRenderCache;
begin
  LServices := TEngineDynLightServices.Create(APreprocessor, ALumps);
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

// The catalog goes to A_MusicChanger (p_musinfo); the loader is given back for the loading of
// the levels, that reads MUSINFO at the start
function ComposeMusInfo(const ALog: ILog; const ALumps: IEngineLumps): IMusInfoLoader;
var
  LServices: TEngineMusInfoServices;
  LServicesRef: IInterface;
  LCatalog: IMusInfoCatalog;
begin
  LServices := TEngineMusInfoServices.Create(ALumps);
  LServicesRef := LServices;
  LCatalog := TMusInfoFactory.CreateCatalog(LServices, ALog);
  P_ConfigureMusInfo(LCatalog);
  Result := TMusInfoFactory.CreateLoader(LServices, TMusInfoFactory.CreateParser(ALog), LCatalog);
end;

// The rules of the game for the loading of the levels: ANIMDEFS (not Hexen, that has p_anim) and,
// in Doom, the switches of Libs\Definitions and the nodes of the old engine. The switches of
// Heretic, Hexen and Strife keep their own tables: they are used after the start
function ComposeLevelRules(const ALog: ILog; const AContext: IGameContext;
  const ANodesSource: INodesLumpSource; const ALumps: IEngineLumps): ILevelGameRules;
{$IFNDEF HEXEN}
var
  LAnimDefs: IEngineAnimDefsLoader;
{$ENDIF}
begin
{$IFNDEF HEXEN}
  LAnimDefs := TEngineAnimDefsLoader.Create(
    TDefinitionsFactory.CreateAnimDefsParser(TEngineAnimNameCatalog.Create(ALumps), ALog), ALumps);
{$ENDIF}
{$IF DEFINED(DOOM)}
  Result := TDoomLevelRules.Create(
    TEngineSwitchListLoader.Create(TDefinitionsFactory.CreateSwitchLumpReader(False),
      TDefinitionsFactory.CreateSwitchSelector(TEngineTextureLookup.Create, ALog),
      TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom)),
    LAnimDefs, TEngineVanillaNodes.Create(ANodesSource), AContext);
{$ELSEIF DEFINED(HERETIC)}
  Result := THereticLevelRules.Create(LAnimDefs);
{$ELSEIF DEFINED(HEXEN)}
  Result := THexenLevelRules.Create;
{$ELSE}
  Result := TStrifeLevelRules.Create(LAnimDefs);
{$ENDIF}
end;

// The loading of the levels (TLevelLoader) for g_game and d_main, with the text maps of the
// game, the nodes, the blockmap and the rules of the game
procedure ComposeLevel(const ALog: ILog; const AContext: IGameContext; const ATempFiles: ITempFiles;
  const AWadServices: IEngineWadServices; const AMusInfo: IMusInfoLoader;
  const ALumps: IEngineLumps; const AZone: IZoneAllocator);
var
  LGame: TUdmfGame;
  LNodesSource: INodesLumpSource;
  LHexen: Boolean;
  LRules: ILevelGameRules;
  LUdmf: ILevelUdmf;
  LLoader: ILevelLoader;
begin
  if not TUdmfGames.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no format of text maps', [_GAME]);
  LUdmf := TEngineUdmfMapLoader.Create(
    TUdmfFactory.CreateConverter(LGame, TEngineUdmfSoundResolver.Create, ALog), AWadServices,
    TEngineUdmfSectorApplier.Create(
      TUdmfApplyFactory.CreateSectorInterpreter, TUdmfApplyFactory.CreateTriangleSlopes),
    TEngineUdmfLineApplier.Create(
      TUdmfApplyFactory.CreateLineSpecialTranslator(UDMF_SPECIAL_START, UDMF_NORMAL_ADD)),
    TEngineUdmfSideApplier.Create,
    TEngineUdmfSegApplier.Create(TUdmfApplyFactory.CreateFakeContrast), ALumps, AZone);

  // the maps of Hexen are already in the Hexen format: the other games convert them for the node builder
{$IFDEF HEXEN}
  LHexen := True;
{$ELSE}
  LHexen := False;
{$ENDIF}
  LNodesSource := TEngineNodesLumpSource.Create(ALumps);
  LRules := ComposeLevelRules(ALog, AContext, LNodesSource, ALumps);

  LLoader := TLevelLoader.Create(AContext, LRules,
    TEngineLevelMapReader.Create(LRules as ILevelGeometryRules, AContext, ALumps, AZone),
    TEngineLevelThings.Create(LRules as ILevelThingRules, ALumps, AZone),
    TEngineLevelNodes.Create(LNodesSource, TNodesFactory.CreateGlDetector(LNodesSource),
      TNodesFactory.CreateGlMapFinder(LNodesSource),
      TNodesFactory.CreateGlbspInputBuilder(LNodesSource, LHexen), ATempFiles, LHexen,
      ALumps, AZone),
    TEngineLevelBlockmap.Create(TBlockmapFactory.CreateBuilder, TBlockmapFactory.CreateLumpReader,
      TBlockmapFactory.CreateSlimeTrailRemover, ALumps, AZone),
    LUdmf, AMusInfo, ALumps, AZone);
  G_ConfigureLevel(LLoader);
  D_ConfigureLevel(LLoader);
end;

procedure ComposePalette(const AZone: IZoneAllocator);
var
  LMatcher: IColorMatcher;
  LDefaultPalette: IEngineDefaultPalette;
begin
  LMatcher := TPaletteFactory.CreateColorMatcher;
  // one palette read once, for the colormaps and the voxels
  LDefaultPalette := TEngineDefaultPalette.Create(
    TPaletteFactory.CreatePaletteUnpacker(TVideoFactory.CreatePaletteConverter), AZone);
  R_ConfigureColormaps(LMatcher, TPaletteFactory.CreateColormapPreparer, LDefaultPalette);
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  R_ConfigureCustomColormaps(TPaletteFactory.CreateColormapPreparer, LDefaultPalette);
{$ENDIF}
{$IFNDEF OPENGL}
  R_ConfigureVoxelPalette(LDefaultPalette);
{$ENDIF}
  R_ConfigureTranslations(TPaletteFactory.CreateTranslationNames);
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

procedure ComposeTextureDefs(const ALog: ILog; const ALumps: IEngineLumps);
var
  LFormat: TTextureDefsFormat;
begin
{$IFDEF STRIFE}
  LFormat := TTextureDefsFormat.Strife;
{$ELSE}
  LFormat := TTextureDefsFormat.Standard;
{$ENDIF}
  R_ConfigureTextureDefs(TTextureDefsFactory.CreateLoader(TEngineTextureLumpSource.Create(ALumps), LFormat));
  R_ConfigureFlatInfo(TTextureDefsFactory.CreateFlatInfoParser(ALog), TEngineFlatCatalog.Create);
end;

// The console on the screen; it owns the objects of Libs\Console. ARegistry and AInterpreter
// are given back: the defaults register their commands and run "get"
function ComposeConsole(const ALog: ILog; const AGame: IGameContext; const ALumps: IEngineLumps;
  out ARegistry: ICommandRegistry; out AInterpreter: IConsoleInterpreter): IEngineConsole;
var
  LOutput: IConsoleOutput;
  LRunner: IConsoleScriptRunner;
  LVariables: IConsoleVariableSource;
begin
  ARegistry := TConsoleFactory.CreateRegistry;
  AInterpreter := TConsoleFactory.CreateInterpreter(ARegistry);
  C_ConfigureCommands(ARegistry, AInterpreter);
  LOutput := TEngineConsoleOutput.Create;
  LRunner := TConsoleFactory.CreateScriptRunner(AInterpreter, TEngineConsoleFileSystem.Create,
    LOutput, ALog);
  LVariables := TEngineConsoleVariableSource.Create;
  Result := TEngineConsoleScreen.Create(ARegistry, AInterpreter,
    TConsoleFactory.CreateStandardCommands(ARegistry, LOutput, LRunner),
    TConsoleFactory.CreateAutoExec(TEngineConsoleStartup.Create(ALumps), LRunner, LOutput, AppTitle),
    TConsoleFactory.CreateVariableCommands(ARegistry, LVariables, LOutput, ALog, AGame),
    TConsoleFactory.CreateCommandQueue(AInterpreter),
    TConsoleFactory.CreateInputLine(']', AInterpreter, LOutput, TConsoleFactory.CreateHistory,
      TConsoleFactory.CreateCompleter(ARegistry, LVariables)));
  D_ConfigureConsole(Result);
{$IFDEF OPENGL}
  GL_ConfigureConsole(Result);
{$ELSE}
  V_ConfigureConsole(Result);
{$ENDIF}
  P_ConfigureTickerConsole(Result);
  P_ConfigureConsole(Result);
  PS_ConfigureConsole(Result);
end;

// The defaults of the configuration file, with their two console commands
function ComposeDefaults(const ARegistry: ICommandRegistry;
  const AInterpreter: IConsoleInterpreter): IEngineDefaults;
var
  LDefaults: TEngineDefaults;
begin
  LDefaults := TEngineDefaults.Create(TConfigurationFactory.CreateFormat, ARegistry, AInterpreter);
  Result := LDefaults;
  LDefaults.RegisterCommands;
  D_ConfigureDefaults(Result);
  I_ConfigureDefaults(Result);
  PS_ConfigureDefaults(Result);
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
var
  LScreenshot: IEngineScreenshot;
begin
  LScreenshot := TEngineScreenshotService.Create(
    TScreenshotFactory.CreateWriter(TPngProvider.Client, TJpegProvider.Client),
    TScreenshotFactory.CreateTargets(TEngineScreenshotFolders.Create));
  D_ConfigureScreenshot(LScreenshot);
  G_ConfigureScreenshot(LScreenshot);
  M_ConfigureScreenshot(LScreenshot);
end;

procedure ComposeTexture(const ALog: ILog);
var
  LServices: TTextureServices;
begin
  LServices.Palette := TEngineTexturePaletteSource.Create;
  LServices.Resolver := TEngineTextureResolver.Create;
  LServices.PngReader := TEngineTexturePngReader.Create;
  LServices.PngSettings := TEngineTexturePngSettings.Create;
  LServices.JpegConverter := TEngineTextureJpegConverter.Create;
  LServices.Log := ALog;
  T_ConfigureTextures(TTextureFactory.CreateFormats(LServices));
end;

// The temporary files are one object for the whole engine: who makes one receives it, and
// i_tmp deletes them all at the shut down
function ComposePlatform(const AZone: IZoneAllocator): ITempFiles;
var
  LStore: IFileStore;
  LFiles: IEngineFiles;
begin
  LStore := TPlatformFactory.CreateFileStore;
  LFiles := TEngineFiles.Create(LStore, AZone);
  // the demos and the saves (Hexen: g_demo and sv_save; Strife: also p_saveg and the menus)
  G_ConfigureFiles(LFiles);
{$IFDEF HEXEN}
  SV_ConfigureFiles(LFiles);
{$ENDIF}
{$IFDEF STRIFE}
  P_ConfigureFiles(LFiles);
  M_ConfigureFiles(LFiles);
{$ENDIF}
  PS_ConfigureFiles(LFiles);
  W_ConfigureFiles(LFiles);
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

procedure ComposeActorDef(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor;
  const ALumps: IEngineLumps);
var
  LGame: TActorDefGame;
  LProfile: TActorDefProfile;
  LCatalog: TEngineActorDefCatalog;
  LCatalogRef: IInterface;
  LHooks: TEngineActorDefHooks;
  LHooksRef: IInterface;
  LAliases: IActorDefSoundAliasTable;
  LListener: IActorDefSoundInfoListener;
  LLumps: IEngineActorDefLumps;
  LLumpsObject: TEngineActorDefLumps;
begin
  if not TActorDefProfiles.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of ACTORDEF', [_GAME]);
  LProfile := TActorDefProfiles.ForGame(LGame);
  LCatalog := TEngineActorDefCatalog.Create;
  LCatalogRef := LCatalog;
  // a thinker is an actor written as text: it goes back to the parser through the reader of
  // the lumps. The closure holds the object without a reference (d_main keeps it alive): with
  // the interface the reader, the parser and the hooks would hold each other
  LLumpsObject := nil;
  LHooks := TEngineActorDefHooks.Create(ALog,
    procedure(AText: string)
    begin
      LLumpsObject.ParseText(AText);
    end, APreprocessor);
  LHooksRef := LHooks;
  LAliases := TActorDefFactory.CreateSoundAliases(ALog);
{$IFDEF HEXEN}
  LListener := TEngineSoundInfoListener.Create;
{$ELSE}
  LListener := nil;
{$ENDIF}
  LLumpsObject := TEngineActorDefLumps.Create(
    TActorDefFactory.CreateParser(LProfile, ALog, LCatalog, LCatalog, LCatalog,
      TActorDefFactory.CreateDehSink(LProfile, LCatalog, LCatalog, LAliases, LHooks, ALog),
      LHooks, LHooks, LHooks),
    procedure(AText: string)
    begin
      TActorDefFactory.ParseSoundInfo(LProfile, AText, LAliases, LListener);
    end,
    APreprocessor, ALumps);
  LLumps := LLumpsObject;
  D_ConfigureActorDef(LLumps);
  S_ConfigureSoundAliases(LAliases);
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

procedure ComposeVoxels(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor;
  const ALumps: IEngineLumps);
var
  LLoader: IVoxelLoader;
  LCubes: IVoxelCubeBuilder;
  LLumps: IVoxelLumpNames;
begin
  LLoader := TVoxelFactory.CreateLoader(TEngineVoxelFileSource.Create(ALumps), ALog);
  LCubes := TVoxelFactory.CreateCubeBuilder;
  LLumps := TEngineVoxelLumpNames.Create(ALumps);
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
    end,
    ALumps));
  // the sink makes the model of the renderer of each new voxel with the loader
  VX_ConfigureVoxels(
    TVoxelFactory.CreateDefinitionParser(TEngineVoxelDefinitionLookup.Create, ALog),
    TEngineVoxelDefinitionSink.Create(LLoader, LCubes), APreprocessor);
end;

procedure ComposeEngine;
var
  LWadServices: IEngineWadServices;
  LZoneCore: IZoneAllocator;
  LZone: IZoneAllocator;
  LLumps: IEngineLumps;
  LEngine: IIdTechEngine;
  LLog: ILog;
  LContext: IGameContext;
  LClock: IClock;
  LMusInfo: IMusInfoLoader;
  LPreprocessor: IScriptTextPreprocessor;
  LEvaluator: IContextExpressionEvaluator;
  LTempFiles: ITempFiles;
  LRegistry: ICommandRegistry;
  LInterpreter: IConsoleInterpreter;
  LConsole: IEngineConsole;
  LDefaults: IEngineDefaults;
  LEndScreenTick: TProc;
begin
  // The zone first: whatever is built next can already allocate from it
  LZoneCore := TZoneFactory.CreateAllocator(TEngineZoneMemory.Create);
  Z_ConfigureZone(LZoneCore);
  // the classes of the engine use the same allocator, with the I_Error of the Z_* functions
  LZone := TEngineZoneAllocator.Create(LZoneCore);
  LLumps := TEngineLumps.Create;
  // DelphiDoom is a port of the Doom engine: id Tech 1, at the version of doomdef
  LEngine := TIdTechFactory.CreateDelphiDoom(VERSION);
  D_Configure(LEngine);
  ComposeIwad;
  M_ConfigureArgv(TCommandLineFactory.CreateBuilder);
  LContext := TEngineGameContext.Create;
  LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(TEngineLogSink.Create),
    function: Boolean
    begin
      Result := LContext.IsDeveloperMode;
    end);
  I_ConfigureLog(LLog);
  // the console before anyone registers a command; the defaults after it (#CVARFORCE uses them)
  LConsole := ComposeConsole(LLog, LContext, LLumps, LRegistry, LInterpreter);
  LDefaults := ComposeDefaults(LRegistry, LInterpreter);
  LPreprocessor := ComposeScanner(LLog, LDefaults, LLumps, LZone, LEvaluator);
  LTempFiles := ComposePlatform(LZone);
  ComposeMathCore;
  ComposeSerializer;
{$IFDEF OPENGL}
  ComposeOpenGl(LPreprocessor);
{$ENDIF}
  LClock := TClockFactory.CreateClock(LLog);
  I_ConfigureClock(LClock);
  I_ConfigureVideo(TVideoFactory.CreateServices);
  ComposeDisplayModes;
  ComposeInput(LLog);
  ComposeSound(LLog);
  ComposeMusic(LTempFiles, LZone);
  S_ConfigurePK3Sounds(LTempFiles);
  ComposeDehacked(LLog, LEvaluator);
  ComposeImaging;
  ComposeScreenshot;
  ComposeTexture(LLog);
  ComposeTextureDefs(LLog, LLumps);
  ComposePalette(LZone);
  LMusInfo := ComposeMusInfo(LLog, LLumps);
  ComposeDynLights(LLog, LContext, LPreprocessor);
  ComposeAutomap;
  ComposeActorDef(LLog, LPreprocessor, LLumps);
  ComposeTableExport;
  P_ConfigureAcs(TAcsFactory.CreateCompiler(TEngineAcsSourceProvider.Create, LLog),
    TAcsFactory.CreateMachine(TEngineAcsHost.Create(LZone), LLog));
  LEndScreenTick := ComposeEndoom(LLumps, LZone);
  ComposeNetGame(LClock, LLog, LContext, LConsole, LEndScreenTick);
  ComposeVoxels(LLog, LPreprocessor, LLumps);

  LWadServices := TEngineWadServices.Create;
  W_Configure(LWadServices);
  TWadReader.Configure(LWadServices);
  TWadWriter.Configure(LWadServices);
  PAK_Configure(LWadServices);
  D_ConfigureAutoLoad(TAutoLoadReader.Create(TEngineAutoLoadLumps.Create(LLumps),
    TEngineAutoLoadSink.Create, TEngineScannerLog.Create));
  ComposeLevel(LLog, LContext, LTempFiles, LWadServices, LMusInfo, LLumps, LZone);
{$IFNDEF HEXEN}
  // Hexen has its own specials (p_spec): the UDMF ones are only for the other games
  P_ConfigureLineSpecials(TSpecialsFactory.CreateRegistry);
  ComposeMapInfo(LLog, LPreprocessor, LLumps);
{$ENDIF}
end;

end.
