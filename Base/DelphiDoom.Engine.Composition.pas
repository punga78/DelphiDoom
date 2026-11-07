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
  DelphiDoom.Video.Factory,
  DelphiDoom.Acs.Factory,
  DelphiDoom.Udmf.Games,
  DelphiDoom.Udmf.Factory,
  DelphiDoom.Engine.Udmf.SoundResolver,
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
  DelphiDoom.Dehacked.Games,
  DelphiDoom.Dehacked.Factory,
  deh_main,
  DelphiDoom.Clock.Intf,
  d_net,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.MathCore.Factory,
  m_rnd,
  m_hash,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.Factory,
  DelphiDoom.Engine.Imaging.ColorIndex,
  DelphiDoom.Screenshot.Factory,
  DelphiDoom.Engine.Screenshot.Folders,
  DelphiDoom.Png.Provider,
  DelphiDoom.Jpeg.Provider,
  mn_screenshot,
  DelphiDoom.Texture.Intf,
  DelphiDoom.Texture.Factory,
  DelphiDoom.Engine.Texture.PaletteSource,
  DelphiDoom.Engine.Texture.PngReader,
  DelphiDoom.Engine.Texture.PngSettings,
  DelphiDoom.Engine.Texture.JpegConverter,
  DelphiDoom.Engine.Texture.Resolver,
  t_main,
{$IFNDEF OPENGL}
  r_grow,
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
  r_flatinfo,
  DelphiDoom.Palette.Types,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Palette.Profiles,
  DelphiDoom.Palette.Factory,
  v_palettes,
  r_palette,
  DelphiDoom.Definitions.Types,
  DelphiDoom.Definitions.Intf,
  DelphiDoom.Definitions.Factory,
  DelphiDoom.Engine.Definitions.AnimCatalog,
  DelphiDoom.Engine.Definitions.TextureLookup,
  p_terrain,
{$IFDEF DOOM}
  p_switch,
{$ENDIF}
  p_animdefs,
  DelphiDoom.MusInfo.Intf,
  DelphiDoom.MusInfo.Factory,
  DelphiDoom.Engine.MusInfo.Services,
  p_musinfo,
  DelphiDoom.DynLights.Types,
  DelphiDoom.DynLights.Intf,
  DelphiDoom.DynLights.Factory,
  DelphiDoom.Engine.DynLights.Services,
  r_dynlights,
{$IFDEF OPENGL}
  gl_defs,
  DelphiDoom.GlMath.Factory,
  gl_frustum,
  gl_clipper,
  DelphiDoom.Models.Intf,
  DelphiDoom.Models.Factory,
  mdl_base,
{$ENDIF}
  DelphiDoom.ActorDef.Types,
  DelphiDoom.ActorDef.Intf,
  DelphiDoom.ActorDef.Profiles,
  DelphiDoom.ActorDef.Factory,
  DelphiDoom.Engine.ActorDef.Catalog,
  DelphiDoom.Engine.ActorDef.Hooks,
  DelphiDoom.Engine.ActorDef.SoundInfoListener,
  sc_actordef,
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
  DelphiDoom.GameState.Intf,
  DelphiDoom.Engine.GameContext,
  DelphiDoom.Input.Intf,
  DelphiDoom.Input.Factory,
  DelphiDoom.Engine.Input.KeyMap,
  DelphiDoom.Engine.Input.Sink,
  DelphiDoom.Engine.Input.Gate,
  DelphiDoom.Engine.Input.ScreenSize,
  DelphiDoom.Engine.Input.DirectKeyboard,
  d_event,
  i_mainwindow,
  i_input,
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
  doomdef,
  d_main,
  m_argv,
  m_misc,
  i_system;

procedure ComposeInput(const ALog: ILog);
var
  LWindow: TFunc<THandle>;
begin
  LWindow :=
    function: THandle
    begin
      Result := hMainWnd;
    end;
  I_ConfigureInput(
    function(AUseDirectInput: Boolean): IInputPoller
    var
      LKeyboard: IKeyboardDevice;
    begin
      if AUseDirectInput then
        LKeyboard := TDirectKeyboard.Create(LWindow, ALog)
      else
        LKeyboard := TInputFactory.CreateWindowsKeyboard;
      Result := TInputFactory.CreatePoller(LKeyboard, TInputFactory.CreateWindowsMouse,
        TInputFactory.CreateWindowsJoystick(LWindow), TEngineInputGate.Create,
        TEngineScreenSize.Create, TEngineKeyMap.Create, TEngineInputSink.Create, ALog,
        NUMJOYBUTTONS);
    end);
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

procedure ComposeMusic;
begin
  // the order is the one in which a song is looked at: the first backend that knows it plays it
  I_ConfigureMusic(TAudioFactory.CreateMusicPlayer(TArray<IMusicBackend>.Create(
    TModuleMusicBackend.Create,
    TMp3MusicBackend.Create,
    TId3MusicBackend.Create,
    TXmiMusicBackend.Create,
    TMusMusicBackend.Create,
    TMidiFileMusicBackend.Create)));
end;

{$IFNDEF HEXEN}
procedure ComposeMapInfo(const ALog: ILog);
var
  LServices: TEngineMapInfoServices;
  LTextSource: TEngineMapInfoTextSource;
  LMapServices: TMapInfoServices;
  LCatalog: IMapInfoCatalog;
begin
  LServices := TEngineMapInfoServices.Create;
  LTextSource := TEngineMapInfoTextSource.Create;
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
end;

procedure ComposeDynLights(const ALog: ILog; const AContext: IGameContext);
var
  LServices: TEngineDynLightServices;
  LServicesRef: IInterface;
  LRegistry: IDynLightRegistry;
  LParserServices: TDynLightParserServices;
  LCoefficient: Double;
begin
  LServices := TEngineDynLightServices.Create;
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
  R_ConfigureDynamicLights(
    TDynLightFactory.CreateLoader(LServices, LServices,
      TDynLightFactory.CreateParser(LParserServices, ALog, LCoefficient)),
    LRegistry,
    TDynLightFactory.CreateAnimator(LRegistry, LServices));
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

procedure ComposeDefinitions(const ALog: ILog);
var
  LGame: TDefGame;
begin
  P_ConfigureAnimDefs(TDefinitionsFactory.CreateAnimDefsParser(TEngineAnimNameCatalog.Create, ALog));
{$IFDEF DOOM}
  LGame := TDefGame.Doom;
{$ENDIF}
{$IFDEF HERETIC}
  LGame := TDefGame.Heretic;
{$ENDIF}
{$IFDEF HEXEN}
  LGame := TDefGame.Hexen;
{$ENDIF}
{$IFDEF STRIFE}
  LGame := TDefGame.Strife;
{$ENDIF}
  P_ConfigureTerrain(TDefinitionsFactory.CreateTerrainTable(LGame));
{$IFDEF DOOM}
  // The switches of Heretic, Hexen and Strife keep their own tables: they are used after the start
  P_ConfigureSwitches(TDefinitionsFactory.CreateSwitchLumpReader(False),
    TDefinitionsFactory.CreateSwitchSelector(TEngineTextureLookup.Create, ALog),
    TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom));
{$ENDIF}
end;

procedure ComposePalette;
var
  LMatcher: IColorMatcher;
begin
  LMatcher := TPaletteFactory.CreateColorMatcher;
{$IFDEF HEXEN}
  V_ConfigurePalettes(TPaletteFactory.CreatePaletteBuilder(LMatcher, TPaletteProfiles.Hexen),
    TPaletteFactory.CreateTranslationBuilder(LMatcher));
{$ELSE}
  V_ConfigurePalettes(TPaletteFactory.CreatePaletteBuilder(LMatcher, TPaletteProfiles.Doom),
    TPaletteFactory.CreateTranslationBuilder(LMatcher));
{$ENDIF}
  R_ConfigurePalette(TPaletteFactory.CreatePaletteUnpacker(TVideoFactory.CreatePaletteConverter));
  R_ConfigureColormaps(LMatcher, TPaletteFactory.CreateColormapPreparer);
{$IF NOT (DEFINED(HERETIC) OR DEFINED(HEXEN))}
  R_ConfigureCustomColormaps(TPaletteFactory.CreateColormapPreparer);
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

procedure ComposeTextureDefs(const ALog: ILog);
var
  LFormat: TTextureDefsFormat;
begin
{$IFDEF STRIFE}
  LFormat := TTextureDefsFormat.Strife;
{$ELSE}
  LFormat := TTextureDefsFormat.Standard;
{$ENDIF}
  R_ConfigureTextureDefs(TTextureDefsFactory.CreateLoader(TEngineTextureLumpSource.Create, LFormat));
  R_ConfigureFlatInfo(TTextureDefsFactory.CreateFlatInfoParser(ALog), TEngineFlatCatalog.Create);
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
  R_ConfigureGrow(TImagingFactory.CreateSpanGrower);
{$ENDIF}
  R_ConfigureFlatShrink(TImagingFactory.CreateFlatShrinker);
  R_ConfigureComposite(TImagingFactory.CreateColumnPainter, TImagingFactory.CreateColumnRebuilder);
{$IFNDEF OPENGL}
  R_ConfigureFixedColumn(TImagingFactory.CreateFixedColumnBuilder);
{$ENDIF}
  MN_ConfigureScreenShot(TImagingFactory.CreateThumbnailBuilder(
    TEngineImagingColorIndex.Create(TPaletteFactory.CreateColorMatcher)));
end;

procedure ComposeScreenshot;
begin
  M_ConfigureScreenshot(TScreenshotFactory.CreateWriter(TPngProvider.Client, TJpegProvider.Client),
    TScreenshotFactory.CreateTargets(TEngineScreenshotFolders.Create));
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

procedure ComposeMathCore;
begin
  M_ConfigureRandom(TMathCoreFactory.CreateGameRandom);
  M_ConfigureHash(TMathCoreFactory.CreateStringHashTable);
end;

{$IFDEF OPENGL}
procedure ComposeOpenGl;
begin
  GL_ConfigureFrustum(TGlMathFactory.CreateFrustum);
  GL_ConfigureClipper(TGlMathFactory.CreateAngleClipper);
  MDL_ConfigureModels(TModelsFactory.CreateMd2Parser,
    function: IModelCommandStream
    begin
      Result := TModelsFactory.CreateCommandStream;
    end);
end;
{$ENDIF}

procedure ComposeActorDef(const ALog: ILog);
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
    end);
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
    LAliases);
end;

procedure ComposeEngine;
var
  LWadServices: IEngineWadServices;
  LEngine: IIdTechEngine;
  LLog: ILog;
  LContext: IGameContext;
  LClock: IClock;
  LGame: TUdmfGame;
begin
  // DelphiDoom is a port of the Doom engine: id Tech 1, at the version of doomdef
  LEngine := TIdTechFactory.CreateDelphiDoom(VERSION);
  D_Configure(LEngine);
  M_ConfigureArgv(TCommandLineFactory.CreateBuilder);
  M_ConfigureDefaults(TConfigurationFactory.CreateFormat);
  LContext := TEngineGameContext.Create;
  LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(TEngineLogSink.Create),
    function: Boolean
    begin
      Result := LContext.IsDeveloperMode;
    end);
  I_ConfigureLog(LLog);
  ComposeMathCore;
{$IFDEF OPENGL}
  ComposeOpenGl;
{$ENDIF}
  ComposeConsole(LLog, LContext);
  LClock := TClockFactory.CreateClock(LLog);
  I_ConfigureClock(LClock);
  D_ConfigureNet(LClock, LLog, LContext);
  I_ConfigureVideo(TVideoFactory.CreateServices);
  ComposeInput(LLog);
  ComposeSound(LLog);
  ComposeMusic;
  ComposeDehacked(LLog);
  ComposeImaging;
  ComposeScreenshot;
  ComposeTexture(LLog);
  ComposeTextureDefs(LLog);
  ComposePalette;
  ComposeDefinitions(LLog);
  ComposeMusInfo(LLog);
  ComposeDynLights(LLog, LContext);
  ComposeActorDef(LLog);
  P_ConfigureAcs(TAcsFactory.CreateCompiler(TEngineAcsSourceProvider.Create, LLog));

  LWadServices := TEngineWadServices.Create;
  W_Configure(LWadServices);
  TWadReader.Configure(LWadServices);
  TWadWriter.Configure(LWadServices);
  PAK_Configure(LWadServices);
  if not TUdmfGames.TryFromName(_GAME, LGame) then
    I_Error('ComposeEngine(): the game %s has no format of text maps', [_GAME]);
  P_ConfigureUdmf(TUdmfFactory.CreateConverter(LGame, TEngineUdmfSoundResolver.Create, LLog), LWadServices);
{$IFNDEF HEXEN}
  // Hexen has its own specials (p_spec): the UDMF ones are only for the other games
  P_ConfigureLineSpecials(TSpecialsFactory.CreateRegistry);
  ComposeMapInfo(LLog);
{$ENDIF}
end;

end.
