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
{$IFDEF RADIX}
  DelphiDoom.Engine.Radix.Composition,
  DelphiDoom.Engine.Level.RadixRules,
{$ENDIF}
{$IFDEF SPEED}
  DelphiDoom.Engine.Speed.Composition,
  DelphiDoom.Engine.Level.SpeedRules,
  speed_race,
{$ENDIF}
  System.SysUtils,
  DelphiDoom.GameData.Aliases,
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
  DelphiDoom.Engine.MapInfo.Records,
{$ENDIF}
  DelphiDoom.Engine.Acs.SourceProvider,
  DelphiDoom.Engine.Acs.Host,
  DelphiDoom.Dehacked.Games,
  DelphiDoom.Dehacked.Factory,
  DelphiDoom.Actions.Factory,
  DelphiDoom.Engine.Dehacked.Applier,
  DelphiDoom.Engine.Dehacked.ThingFields,
  deh_base,
  deh_main,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Iwad.Intf,
  DelphiDoom.Iwad.Games,
  DelphiDoom.Iwad.Factory,
  DelphiDoom.Engine.Iwad.Options,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Zone.Factory,
  DelphiDoom.Engine.Zone.Memory,
  DelphiDoom.Engine.Zone.Allocator,
  DelphiDoom.Engine.Shutdown.Intf,
  DelphiDoom.Engine.Shutdown,
  DelphiDoom.Engine.Video.Screens.Intf,
  DelphiDoom.Engine.Video.Screens,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Wad.Lumps,
  DelphiDoom.Threading.Intf,
  DelphiDoom.Threading.Factory,
  DelphiDoom.Engine.Threading.Services,
  i_threads,
  mt_utils,
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
  DelphiDoom.MathCore.SystemEntropySource,
  DelphiDoom.Parity.Factory,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.SwitchClock,
  DelphiDoom.Parity.SwitchEntropy,
  DelphiDoom.Engine.Parity.Adapter,
  DelphiDoom.Engine.Parity.InputGate,
  DelphiDoom.Engine.Parity.LogSink,
  DelphiDoom.Engine.Parity.Zone,
  m_rnd,
  DelphiDoom.Thinkers.Light.Types,
  DelphiDoom.Thinkers.Light.Games,
  DelphiDoom.Thinkers.Light.Factory,
  DelphiDoom.Engine.Light.Services,
  DelphiDoom.Engine.Light.PhaseSpawner,
  DelphiDoom.Thinkers.Platform.Types,
  DelphiDoom.Thinkers.Platform.Intf,
  DelphiDoom.Thinkers.Platform.Games,
  DelphiDoom.Thinkers.Platform.Factory,
  DelphiDoom.Engine.Plat.Services,
  DelphiDoom.Engine.Plat.Surroundings,
  DelphiDoom.Engine.Plat.UdmfHost,
{$IFNDEF HEXEN}
  DelphiDoom.Engine.Plat.Host,
{$ENDIF}
  DelphiDoom.Engine.Teleport.Services,
  DelphiDoom.Engine.Teleport.FogSpawner,
  DelphiDoom.Thinkers.Door.Types,
  DelphiDoom.Thinkers.Door.Intf,
  DelphiDoom.Thinkers.Door.Profiles,
  DelphiDoom.Thinkers.Door.Factory,
  DelphiDoom.Engine.Door.Services,
  DelphiDoom.Engine.Door.Host,
  DelphiDoom.Engine.Plane.Services,
  DelphiDoom.Engine.Plane.Host,
{$IFNDEF HEXEN}
  DelphiDoom.Thinkers.Ceiling.Games,
  DelphiDoom.Thinkers.Floor.Games,
{$ENDIF}
  DelphiDoom.Serializer.Intf,
  DelphiDoom.Serializer.Factory,
  DelphiDoom.Engine.Serializer.Resolver,
  p_serializer,
  DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.Factory,
  DelphiDoom.Engine.Imaging.ColorIndex,
  DelphiDoom.Engine.Imaging.Random,
{$IFNDEF STRIFE}
  f_wipe,
{$ENDIF}
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
  DelphiDoom.Engine.Texture.DrawTextures,
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
  r_segs2,
{$ENDIF}
  DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Profiles,
  DelphiDoom.Renderer.Intf,
  DelphiDoom.Renderer.Factory,
  DelphiDoom.Engine.Renderer.PatchSource,
  DelphiDoom.Engine.Renderer.SpriteSource,
  DelphiDoom.Engine.Renderer.SubsectorLocator,
  DelphiDoom.Engine.Renderer.LumpDirectory,
  DelphiDoom.Engine.Renderer.SpriteHeaders,
  DelphiDoom.Engine.Renderer.Pk3Catalog,
  DelphiDoom.Console.Intf,
  DelphiDoom.Console.Factory,
  DelphiDoom.Engine.Console.Output,
  DelphiDoom.Engine.Console.FileSystem,
  DelphiDoom.Engine.Console.FileLister,
  DelphiDoom.Engine.Console.LumpSource,
  DelphiDoom.Engine.Console.LumpFiles,
  DelphiDoom.Engine.Console.Browser,
  DelphiDoom.Engine.Console.Startup,
  DelphiDoom.Engine.Console.VariableSource,
  DelphiDoom.Engine.Console.Intf,
  DelphiDoom.Engine.Console.Screen,
  DelphiDoom.Engine.Configuration.Intf,
  DelphiDoom.Engine.Configuration.Defaults,
  DelphiDoom.Engine.Configuration.Table,
  DelphiDoom.Engine.CommandLine.Environment,
  DelphiDoom.Engine.Screenshot.Intf,
  DelphiDoom.Engine.Screenshot.Service,
  DelphiDoom.Engine.Platform.Intf,
  DelphiDoom.Engine.Platform.Files,
  DelphiDoom.Engine.Palette.Intf,
  DelphiDoom.Engine.Palette.DefaultPalette,
  c_cmds,
  c_utils,
  d_notifications,
  DelphiDoom.Engine.Video.DisplayModeApplier,
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
  psi_game,
  psi_overlay,
  psi_system,
  psi_globals,
  psi_map,
  ps_dll,
  ps_import,
  ps_main,
  DelphiDoom.ScriptHost.Factory,
  DelphiDoom.ScriptHost.Games,
  DelphiDoom.ScriptHost.Types,
  DelphiDoom.ScriptHost.Intf,
  DelphiDoom.ScriptHost.System.Intf,
  DelphiDoom.Engine.Script.Console,
  DelphiDoom.Engine.Script.Constants.Game,
  DelphiDoom.Engine.Script.Constants.Groups,
  DelphiDoom.Engine.Script.Constants.Mobj,
  DelphiDoom.Engine.Script.Constants.World,
  DelphiDoom.Engine.Script.DllSource,
  DelphiDoom.Engine.Script.ActorContext,
  DelphiDoom.Engine.Script.ActorContext.Intf,
  DelphiDoom.Engine.Script.Actors,
  DelphiDoom.Engine.Script.Environment,
  DelphiDoom.Engine.Script.GameInfo,
  DelphiDoom.Engine.Script.Keyboard,
  DelphiDoom.Engine.Script.MobjInfo,
  DelphiDoom.Engine.Script.Overlay.Canvas,
  DelphiDoom.Engine.Script.Players,
  DelphiDoom.Engine.Script.Textures,
  DelphiDoom.Engine.Script.Output,
  DelphiDoom.Engine.Script.Routines,
  DelphiDoom.Engine.Script.SectorSpecials,
  DelphiDoom.Engine.Script.SourceProvider,
  DelphiDoom.Engine.Script.VariablesFailure,
  DelphiDoom.Engine.Script.VariablesFiles,
  DelphiDoom.Engine.Script.World,
  DelphiDoom.ScriptHost.Players.Intf,
  DelphiDoom.ScriptHost.World.Intf,
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
  r_aspect,
{$IFNDEF OPENGL}
  r_fake3d,
  r_things_sortvissprites,
{$ENDIF}
  r_sky,
  r_things,
  r_subsectors,
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
  DelphiDoom.Engine.Nodes.Intf,
  DelphiDoom.Engine.Nodes.GlbspRunner,
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
  DelphiDoom.Models.Definition.Intf,
  DelphiDoom.Models.Factory,
  DelphiDoom.Engine.Models.DefinitionSink,
  DelphiDoom.Engine.Models.DefinitionLookup,
  DelphiDoom.GlLevel.Intf,
  DelphiDoom.GlLevel.Factory,
  DelphiDoom.Engine.GlLevel.FlatWorld,
  DelphiDoom.Engine.GlLevel.FlatLoopSink,
  DelphiDoom.Engine.GlLevel.SectorWorld,
  gl_automap,
  DelphiDoom.GlAutomap.Factory,
  DelphiDoom.GlScene.Factory,
  DelphiDoom.Engine.GlScene.FlatCollector,
  DelphiDoom.Engine.GlScene.WallCollector,
  DelphiDoom.Engine.GlScene.WallPainter,
  DelphiDoom.Engine.GlScene.FlatPainter,
  DelphiDoom.Engine.GlScene.ModelPainter,
  DelphiDoom.Engine.GlScene.VoxelPainter,
  DelphiDoom.Engine.GlScene.SpritePainter,
  DelphiDoom.Engine.GlScene.LightSorter,
  DelphiDoom.Engine.GlScene.LightPainter,
  DelphiDoom.Engine.GlScene.SceneDrawer,
  DelphiDoom.Engine.GlVSync,
  DelphiDoom.Engine.GlInitializer,
  DelphiDoom.Engine.GlScene.Frame,
  DelphiDoom.Engine.GlLevel.Preprocessor,
  DelphiDoom.Engine.GlScene.LightMarker,
  DelphiDoom.Engine.GlScene.SpriteCollector,
  DelphiDoom.Engine.GlAutomap.Painter,
{$ENDIF}
  DelphiDoom.Automap.Intf,
  DelphiDoom.Automap.Factory,
  am_map,
  DelphiDoom.Hud.Types,
  DelphiDoom.Hud.Intf,
  DelphiDoom.Hud.View,
  DelphiDoom.Hud.Factory,
  DelphiDoom.Engine.Hud.Rules,
  DelphiDoom.Engine.Hud.Environment,
  DelphiDoom.Engine.Hud.Drawer,
  hu_stuff,
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
  DelphiDoom.TableExport.Saver.Intf,
  DelphiDoom.TableExport.Saver,
  DelphiDoom.Engine.TableExport.Output,
  DelphiDoom.Info.Intf,
  DelphiDoom.Engine.ActorDef.ParamRandom,
  DelphiDoom.Engine.Info.Intf,
  DelphiDoom.Engine.Info.Tables,
  DelphiDoom.Engine.Info.Things,
  DelphiDoom.Engine.Info.States,
  DelphiDoom.Engine.Info.Groups,
  DelphiDoom.Engine.Info.Random,
  DelphiDoom.Engine.Info.RandomRules,
  DelphiDoom.Engine.Info.StateTokens,
  DelphiDoom.Engine.Info.StateText,
  DelphiDoom.Engine.Info.StateNames,
  info_common,
  info_rnd,
  sc_states,
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
  DelphiDoom.Audio.Mixer,
  DelphiDoom.Audio.MusicNumberResolver,
  DelphiDoom.Audio.SfxNumberResolver,
  DelphiDoom.Engine.Audio.SfxTable,
  DelphiDoom.Engine.Audio.MusicTable,
  DelphiDoom.GameHost.Win.PcmOutput,
  DelphiDoom.Engine.Audio.WaveOutDevice,
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
  DelphiDoom.Midi.Factory,
  i_midi,
  DelphiDoom.Engine.Midi.SongPlayer,
  DelphiDoom.Mp3.Provider,
  s_sound,
  s_pk3sounds,
  DelphiDoom.GameState.Intf,
  DelphiDoom.Engine.GameContext,
  DelphiDoom.Engine.World,
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
  DelphiDoom.Engine.Video.FramePresenter.Intf,
  DelphiDoom.Engine.Video.GdiPresenter,
  DelphiDoom.Engine.Video.DisplaySettings,
{$ENDIF}
  m_menu,
  d_event,
  i_mainwindow,
  p_acs,
  DelphiDoom.Configuration.Factory,
  DelphiDoom.Configuration.Intf,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.CommandLine.Factory,
  DelphiDoom.Platform.DataFolder.Factory,
  DelphiDoom.Video.Types,
  DelphiDoom.Engine.Startup.ResponseFileSource,
  DelphiDoom.Engine.Startup.Numbers,
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
  DelphiDoom.Engine.Platform.TempDirectory,
  i_mikplay,
  i_midi_legacy,
  i_net,
  DelphiDoom.EngineSystem.Intf,
  DelphiDoom.EngineSystem.Factory,
  DelphiDoom.Engine.System.ShutdownPlan,
  DelphiDoom.Engine.System.FatalErrorSteps;

// The script preprocessor (given back: ActorDef, MapInfo, DynLights, VOXELDEF and MODELDEF use
// it), the defines of the game that it reads, and the evaluator of the expressions in the
// parameters of the actors (given back: the DEHACKED applier gives it to the parameter lists)
function ComposeScanner(const ALog: ILog; const ADefaults: IEngineDefaults; const ALumps: IEngineLumps;
  const AZone: IZoneAllocator; const AShutdown: IEngineShutdown; const ATempFiles: ITempFiles;
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
    TPaletteFactory.CreateColorMatcher, TPaletteProfiles.Hexen), False, ALumps, AZone, AShutdown, ATempFiles);
{$ELSE}
  LPalettes := TEnginePaletteGenerator.Create(TPaletteFactory.CreatePaletteBuilder(
    TPaletteFactory.CreateColorMatcher, TPaletteProfiles.Doom), True, ALumps, AZone, AShutdown, ATempFiles);
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
  TMainRoutines.D_ConfigureGameDefines(LGameDefines);
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
  // the strategy of the video output: the frame in the window with GDI, the resolution with the display settings
  I_ConfigureVideoOutput(
    TEngineGdiFramePresenter.Create(
      function: THandle
      begin
        Result := hMainWnd;
      end),
    TEngineDisplaySettingsResolution.Create);
{$ENDIF}
  TMenuRoutines.M_ConfigureDisplayModes(LCatalog);
  D_ConfigureNotifications(TVideoFactory.CreateDeferredNotifications(TEngineDisplayModeApplier.Create));
end;

// The end screen; the result is its tic, that the loop of the network runs (nothing in Hexen,
// which has no end screen)
function ComposeEndoom(const ALumps: IEngineLumps; const AZone: IZoneAllocator;
  const ALog: ILog; const AShutdown: IEngineShutdown; const AScreens: IEngineScreens): TProc;
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
    end, ALumps, AZone, ALog, AShutdown, AScreens);
  TMainRoutines.D_ConfigureEndoom(LScreen);
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

// The system of the process: the options of the network game, the shutdown (from the network to the files)
// and the handler of the fatal errors. The handler is given first, as soon as the log exists, so that an error
// of the composition itself is handled; the shutdown needs the network, the defaults and the input
procedure ComposeFatalError(const ALog: ILog);
begin
  I_ConfigureFatalError(TEngineSystemFactory.CreateFatalErrorHandler(TEngineFatalErrorSteps.Create(ALog)));
end;

procedure ComposeSystem(const ALog: ILog; const ACommandLine: ICommandLine; const ANetGame: IEngineNetGame;
  const ADefaults: IEngineDefaults; const AInput: IInputPoller);
begin
  I_ConfigureNetOptions(TEngineSystemFactory.CreateNetCommandLineReader(ACommandLine, ALog));
  I_ConfigureShutdown(TEngineSystemFactory.CreateShutdownSequence(
    TEngineShutdownPlan.Create(ANetGame, ADefaults, AInput, ACommandLine), ALog,
    procedure(ACode: Integer)
    begin
      Halt(ACode);
    end));
end;

function ComposeNetGame(const AClock: IClock; const ALog: ILog; const AGame: IGameContext;
  const AConsole: IEngineConsole; const AEndScreenTick: TProc; const AShutdown: IEngineShutdown): IEngineNetGame;
var
  LNetGame: IEngineNetGame;
begin
  LNetGame := TEngineNetGame.Create(AClock, ALog, AGame, AConsole, AEndScreenTick, AShutdown);
  TMainRoutines.D_ConfigureNetGame(LNetGame);
  G_ConfigureNetGame(LNetGame);
  TRendererMain.R_ConfigureNetGame(LNetGame);
  I_ConfigureNetGame(LNetGame);
  Result := LNetGame;
end;

const
  // the seed of the unpredictable random numbers when the parity tools are on
  PARITY_ENTROPY_SEED = $5EED1234;

function ComposeInput(const ALog: ILog; const AParity: IParitySwitch): IInputPoller;
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
    TEngineParityInputGate.Create(TEngineInputGate.Create, AParity), TEngineScreenSize.Create,
    TEngineKeyMap.Create,
    TEngineInputSink.Create, ALog, NUMJOYBUTTONS);
  Result := LPoller;
  I_ConfigureInput(LPoller);
  G_ConfigureInput(LPoller);
{$IFDEF OPENGL}
  GL_ConfigureInput(LPoller);
{$ELSE}
  I_ConfigureWindowInput(LPoller);
{$ENDIF}
end;

procedure ComposeSound(const ALog: ILog);
const
  // frames per second of the sound output: the samples of the game (11025 Hz and the like) are resampled to it
  SOUND_OUTPUT_RATE = 44100;
begin
  S_ConfigureSound(
    function(AWithDevice: Boolean): ISfxPlayer
    var
      LDevice: ISoundDevice;
    begin
      LDevice := nil;
      if AWithDevice then
      begin
        // the strategy of the sound effects: a software mixer on the PCM output (waveOut) of the game host
        LDevice := TEngineWaveOutSoundDevice.Create(TGameHostWinPcmOutput.Create,
          TSfxMixer.Create(SOUND_OUTPUT_RATE), SOUND_OUTPUT_RATE, ALog);
        // no sound card: the game goes on without sound
        if not LDevice.Initialize then
          LDevice := nil;
      end;
      Result := TAudioFactory.CreateSfxPlayer(LDevice, TEngineSfxSampleSource.Create(ALog), ALog);
    end);
  // the rules of the numbers of the songs on the table of the engine
  S_ConfigureMusicNumbers(
    TMusicNumberResolver.Create(
      TEngineMusicTable.Create,
      function(const AName: string): Integer
      begin
        Result := W_CheckNumForName(AName);
      end,
      ALog));
end;

procedure ComposeMusic(const ATempFiles: ITempFiles; const ACommandLine: ICommandLine;
  const AZone: IZoneAllocator; const ALog: ILog; const AShutdown: IEngineShutdown);
var
  LMidiStream: IEngineMidiStream;
  LMus: IMusicBackend;
begin
  // the MIDI files that the player of the midi stream plays (snd_uselegacymidiplayer = 0, 2)
  // are turned into the events of the stream by a sequencer for each song
  I_ConfigureMidi(TEngineMidiSongPlayer.Create(TMidiFactory.CreateSequencerFactory(ALog), ALog,
    I_SelectDefaultMidiDevice));
  // the legacy player (snd_uselegacymidiplayer = 1) and the choice of the player and the device
  I_ConfigureLegacyMidi(TEngineSystemFactory.CreateLegacyMidiPlayer(ALog));
  I_ConfigureMidiOptions(ACommandLine);
  // the tracker music (MOD, S3M, XM, IT)
  I_ConfigureMik(TEngineSystemFactory.CreateModuleMusicPlayer(ALog,
    function: NativeUInt
    begin
      Result := hMainWnd;
    end));
  // the midi stream of the MUS songs is closed by the backends of the MIDI files
  LMidiStream := TMusMusicBackend.Create(TM2mEngine.Create, ACommandLine, ALog, AShutdown);
  LMus := LMidiStream as IMusicBackend;
  // the order is the one in which a song is looked at: the first backend that knows it plays it
  S_ConfigureMusic(TAudioFactory.CreateMusicPlayer(TArray<IMusicBackend>.Create(
    TModuleMusicBackend.Create,
    TMp3MusicBackend.Create(TMp3Provider.Mp3),
    TId3MusicBackend.Create,
    TXmiMusicBackend.Create(ATempFiles, LMidiStream, ALog),
    LMus,
    TMidiFileMusicBackend.Create(ATempFiles, LMidiStream, ALog))));
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
  TMainRoutines.D_ConfigureMapInfo(TEngineMapInfoRecords.Create(
    TMapInfoFactory.CreateLoader(LTextSource, LTextSource,
      TMapInfoFactory.CreateParser(LMapServices, ALog), LCatalog),
    LCatalog));
end;
{$ENDIF}

procedure ComposeDehacked(const ALog: ILog; const AEvaluator: IContextExpressionEvaluator;
  const AThingFields: IEngineDehackedThingFields);
var
  LGame: TDehackedGame;
begin
  if not TDehackedGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Dehacked), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of DEHACKED', [_GAME]);
  // TEngineDehackedApplier is the class of the game (one unit with this name in each folder).
  // AThingFields knows no field until a game with things of its own fills it (ComposeRadix)
  // the names of the fields and of the flags: the library is their one source (DEH_Init fills the lists of deh_main)
  TDehMainRoutines.DEH_ConfigureTokens(TDehackedGames.DataOf(LGame));
  DEH_ConfigureApplier(TEngineDehackedApplier.Create(TDehackedFactory.CreateParser(LGame, ALog, AThingFields),
    AEvaluator));
  DEH_ConfigureActions(TActionsFactory.CreateRegistry);
end;

procedure ComposeDynLights(const ALog: ILog; const AContext: IGameContext;
  const APreprocessor: IScriptTextPreprocessor; const APakFiles: IPakFileSystem;
  const ARandom: IGameRandom; const ALumps: IEngineLumps);
var
  LServices: TEngineDynLightServices;
  LServicesRef: IInterface;
  LRegistry: IDynLightRegistry;
  LParserServices: TDynLightParserServices;
  LCoefficient: Double;
  LCache: IDynLightRenderCache;
begin
  LServices := TEngineDynLightServices.Create(APreprocessor, APakFiles, ARandom, ALumps);
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
  // the sprites of the OpenGL scene mark their lights in the same cache (the draw list is there: ComposeOpenGl)
  gld_ConfigureSpriteCollector(TEngineGlSceneSpriteCollector.Create(gld_SceneDrawList, gld_LightTable,
    TEngineGlSceneLightMarker.Create(LCache)));
{$ELSE}
  TRendererMain.R_ConfigureDynamicLights(LCache);
  TRendererSoftLights.R_ConfigureSoftLights(LCache);
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
// in Doom, the switches of IdTech1\Definitions and the nodes of the old engine. The switches of
// Heretic, Hexen and Strife keep their own tables: they are used after the start
function ComposeLevelRules(const ALog: ILog; const AContext: IGameContext;
  const ANodesSource: INodesLumpSource; const ACommandLine: ICommandLine;
  const ARandom: IGameRandom; const ALumps: IEngineLumps;
  const AShutdown: IEngineShutdown): ILevelGameRules;
{$IFNDEF HEXEN}
var
  LAnimDefs: IEngineAnimDefsLoader;
{$ENDIF}
{$IFDEF SPEED}
var
  LSpeedRules: TSpeedLevelRules;
{$ENDIF}
begin
{$IFNDEF HEXEN}
  LAnimDefs := TEngineAnimDefsLoader.Create(
    TDefinitionsFactory.CreateAnimDefsParser(TEngineAnimNameCatalog.Create(ALumps), ALog), ALumps,
    AShutdown);
{$ENDIF}
{$IF DEFINED(DOOM)}
{$IFDEF RADIX}
  Result := TRadixLevelRules.Create(
{$ELSE}
  Result := TDoomLevelRules.Create(
{$ENDIF}
    TEngineSwitchListLoader.Create(TDefinitionsFactory.CreateSwitchLumpReader(False),
      TDefinitionsFactory.CreateSwitchSelector(TEngineTextureLookup.Create, ALog),
      TDefinitionsFactory.CreateSwitchTable(TDefGame.Doom)),
    LAnimDefs, TEngineVanillaNodes.Create(ANodesSource), AContext, ARandom);
{$IFDEF SPEED}
  // Speed Haste loads a level as Doom does and then reads the track of the race from its lumps
  LSpeedRules := TSpeedLevelRules.Create(Result, Result as ILevelGeometryRules,
    Result as ILevelThingRules, ALumps, ALog);
  // the race is built when the level is loaded and forgotten when the next one starts
  SH_ConfigureRace(ALog, ARandom);
  LSpeedRules.OnTrackReady := SH_StartLevel;
  LSpeedRules.OnLevelCleared := SH_EndLevel;
  Result := LSpeedRules;
{$ENDIF}
{$ELSEIF DEFINED(HERETIC)}
  Result := THereticLevelRules.Create(LAnimDefs, ARandom);
{$ELSEIF DEFINED(HEXEN)}
  Result := THexenLevelRules.Create(ACommandLine);
{$ELSE}
  Result := TStrifeLevelRules.Create(LAnimDefs, ARandom);
{$ENDIF}
end;

// The loading of the levels (TLevelLoader) for g_game and d_main, with the text maps of the
// game, the nodes, the blockmap and the rules of the game
procedure ComposeLevel(const ALog: ILog; const AContext: IGameContext; const ATempFiles: ITempFiles;
  const AWadServices: IEngineWadServices; const AMusInfo: IMusInfoLoader;
  const ACommandLine: ICommandLine; const ASaveFileNames: ISaveFileNames;
  const ARegistry: ICommandRegistry; const ARandom: IGameRandom; const ALumps: IEngineLumps;
  const AZone: IZoneAllocator; const AShutdown: IEngineShutdown);
var
  LGame: TUdmfGame;
  LNodesSource: INodesLumpSource;
  LHexen: Boolean;
  LGlbsp: IEngineGlbspRunner;
  LRules: ILevelGameRules;
  LUdmf: ILevelUdmf;
  LLoader: ILevelLoader;
begin
  if not TUdmfGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Udmf), LGame) then
    AShutdown.Fail(Format('ComposeEngine(): the game %s has no format of text maps', [_GAME]));
  LUdmf := TEngineUdmfMapLoader.Create(
    TUdmfFactory.CreateConverter(LGame, TEngineUdmfSoundResolver.Create, ALog), AWadServices,
    TEngineUdmfSectorApplier.Create(
      TUdmfApplyFactory.CreateSectorInterpreter, TUdmfApplyFactory.CreateTriangleSlopes),
    TEngineUdmfLineApplier.Create(
      TUdmfApplyFactory.CreateLineSpecialTranslator(UDMF_SPECIAL_START, UDMF_NORMAL_ADD)),
    TEngineUdmfSideApplier.Create,
    TEngineUdmfSegApplier.Create(TUdmfApplyFactory.CreateFakeContrast), ASaveFileNames, ALumps,
    AZone, AShutdown);

  // the maps of Hexen are already in the Hexen format: the other games convert them for the node builder
{$IFDEF HEXEN}
  LHexen := True;
{$ELSE}
  LHexen := False;
{$ENDIF}
  LNodesSource := TEngineNodesLumpSource.Create(ALumps);
  LGlbsp := TEngineGlbspRunner.Create(LHexen, ALog);
  LRules := ComposeLevelRules(ALog, AContext, LNodesSource, ACommandLine, ARandom, ALumps,
    AShutdown);

  LLoader := TLevelLoader.Create(AContext, LRules,
    TEngineLevelMapReader.Create(LRules as ILevelGeometryRules, AContext, ALumps, AZone, ALog,
      AShutdown),
    TEngineLevelThings.Create(LRules as ILevelThingRules, ALumps, AZone),
    TEngineLevelNodes.Create(LNodesSource, TNodesFactory.CreateGlDetector(LNodesSource),
      TNodesFactory.CreateGlMapFinder(LNodesSource),
      TNodesFactory.CreateGlbspInputBuilder(LNodesSource, LHexen), ATempFiles, ASaveFileNames,
      LHexen, ALumps, AZone, ALog, AShutdown, LGlbsp),
    TEngineLevelBlockmap.Create(TBlockmapFactory.CreateBuilder, TBlockmapFactory.CreateLumpReader,
      TBlockmapFactory.CreateSlimeTrailRemover, ACommandLine, ALumps, AZone, AShutdown),
    LUdmf, AMusInfo, ARegistry, ARandom, ALumps, AZone);
  G_ConfigureLevel(LLoader);
  TMainRoutines.D_ConfigureLevel(LLoader);
{$IFDEF OPENGL}
  // the GL nodes of the files added at startup (D_AddFile)
  TMainRoutines.D_ConfigureGlbsp(LGlbsp);
{$ENDIF}
end;

procedure ComposePalette(const APakFiles: IPakFileSystem; const AZone: IZoneAllocator);
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
  TRendererVoxels.R_ConfigureVoxelPalette(LDefaultPalette);
{$ENDIF}
  R_ConfigureTranslations(TPaletteFactory.CreateTranslationNames, APakFiles);
  V_ConfigureGamma(TPaletteFactory.CreateGammaTables);
  TRendererMain.R_ConfigureLightTables(TPaletteFactory.CreateLightTableCalculator);
  R_ConfigurePrecalc(TPaletteFactory.CreatePrecalcTables);
{$IF DEFINED(DOOM)}
  TRendererDraw.R_ConfigurePlayerTranslations(TPaletteFactory.CreateDoomPlayerTranslations);
{$ELSEIF DEFINED(HERETIC)}
  TRendererDraw.R_ConfigurePlayerTranslations(TPaletteFactory.CreateHereticPlayerTranslations);
{$ELSEIF DEFINED(STRIFE)}
  TRendererDraw.R_ConfigurePlayerTranslations(TPaletteFactory.CreateStrifePlayerTranslations);
{$ENDIF}
end;

procedure ComposeTextureDefs(const ALog: ILog; const APakFiles: IPakFileSystem;
  const ALumps: IEngineLumps);
var
  LFormat: TTextureDefsFormat;
begin
{$IFDEF STRIFE}
  LFormat := TTextureDefsFormat.Strife;
{$ELSE}
  LFormat := TTextureDefsFormat.Standard;
{$ENDIF}
  R_ConfigureTextureDefs(TTextureDefsFactory.CreateLoader(TEngineTextureLumpSource.Create(ALumps), LFormat));
  R_ConfigureFlatInfo(TTextureDefsFactory.CreateFlatInfoParser(ALog), TEngineFlatCatalog.Create, APakFiles);
end;

// The console on the screen; it owns the objects of Framework\Console. ARegistry and AInterpreter
// are given back: the defaults register their commands and run "get"
function ComposeConsole(const ALog: ILog; const AGame: IGameContext;
  const ACommandLine: IQueriedCommandLine; const ASaveFileNames: ISaveFileNames;
  const ALumps: IEngineLumps; const ASettings: IConfigurationTable;
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
  C_ConfigureUtilityCommands(TConsoleFactory.CreateUtilityCommands(ARegistry, LOutput,
    TEngineConsoleFileLister.Create, TEngineConsoleBrowser.Create, AInterpreter));
  LRunner := TConsoleFactory.CreateScriptRunner(AInterpreter, TEngineConsoleFileSystem.Create,
    LOutput, ALog);
  LVariables := TEngineConsoleVariableSource.Create(ASettings);
  Result := TEngineConsoleScreen.Create(ARegistry, AInterpreter,
    TConsoleFactory.CreateStandardCommands(ARegistry, LOutput, LRunner),
    TConsoleFactory.CreateAutoExec(TEngineConsoleStartup.Create(ACommandLine, ASaveFileNames, ALumps),
      LRunner, LOutput, AppTitle),
    TConsoleFactory.CreateVariableCommands(ARegistry, LVariables, LOutput, ALog,
      function: Boolean
      begin
        Result := AGame.IsNetGame;
      end),
    TConsoleFactory.CreateCommandQueue(AInterpreter),
    TConsoleFactory.CreateInputLine(']', AInterpreter, LOutput, TConsoleFactory.CreateHistory,
      TConsoleFactory.CreateCompleter(ARegistry, LVariables)),
    ACommandLine);
  TMainRoutines.D_ConfigureConsole(Result);
{$IFDEF OPENGL}
  GL_ConfigureConsole(Result);
{$ELSE}
  V_ConfigureConsole(Result);
{$ENDIF}
  P_ConfigureTickerConsole(Result);
  P_ConfigureConsole(Result);
end;

// The defaults of the configuration file, with their two console commands
function ComposeDefaults(const ARegistry: ICommandRegistry;
  const AInterpreter: IConsoleInterpreter; const ACommandLine: ICommandLine;
  const ASettings: IConfigurationTable): IEngineDefaults;
var
  LDefaults: TEngineDefaults;
  LFormat: IConfigurationFormat;
begin
  LFormat := TConfigurationFactory.CreateFormat;
  LDefaults := TEngineDefaults.Create(LFormat, ASettings,
    TConfigurationFactory.CreateTableStore(ASettings, LFormat), ARegistry, AInterpreter, ACommandLine);
  Result := LDefaults;
  LDefaults.RegisterCommands;
  TMainRoutines.D_ConfigureDefaults(Result);
  I_ConfigureDefaults(Result);
end;

// The functions that scripts can call: the registry, with the units of script that are classes
// (SYSTEM and PS_FIXED); ps_import adds the others when the scripts start (PS_InitProcLists).
// The specials of the sectors and the loader of the DLLs of the PAK files are given to their facades
procedure ComposeScriptHost(const ALog: ILog; const AContext: IGameContext;
  const AConsole: IEngineConsole; const ADefaults: IEngineDefaults; const ARandom: IGameRandom;
  const APakFiles: IPakFileSystem; const ATempFiles: ITempFiles);
var
  LRegistry: IScriptFunctionRegistry;
  LSystem: IScriptSystemFunctions;
  LGame: TScriptGame;
  LWorld: IScriptWorld;
  LVertices: IScriptVertices;
  LSides: IScriptSides;
  LLines: IScriptLines;
  LActorContext: IEngineScriptActorContext;
  LPlayers: IScriptPlayers;
begin
  if not TScriptGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Script), LGame) then
    I_Error('ComposeEngine(): the game %s has no functions of scripts', [_GAME]);
  // the vertexes, sides and lines: one gateway, three classes of functions; psi_game keeps them
  // for the properties of the classes of the scripts
  LWorld := TEngineScriptWorld.Create;
  LVertices := TScriptHostFactory.CreateVertices(LWorld);
  LSides := TScriptHostFactory.CreateSides(LWorld);
  LLines := TScriptHostFactory.CreateLines(LWorld, LGame);
  PS_ConfigureWorldFunctions(LVertices, LSides, LLines,
    TScriptHostFactory.CreateSectors(LWorld, LGame));
  // the actor that the script runs for (PS_Event* and A_RunScript enter it), the mobj types, the
  // players and the actors: psi_game keeps them for the properties of the classes of the scripts
  LActorContext := TEngineScriptActorContext.Create;
  LPlayers := TScriptHostFactory.CreatePlayers(TEngineScriptPlayers.Create(LActorContext), LGame);
  PS_ConfigureMobjFunctions(
    TScriptHostFactory.CreateMobjInfo(TEngineScriptMobjInfo.Create, LGame), LPlayers);
  PS_ConfigureActorFunctions(
    TScriptHostFactory.CreateActors(TEngineScriptActors.Create(LActorContext), LActorContext,
      LPlayers, LGame),
    LActorContext);
  // PS_OVERLAY: the overlay is made by PS_Init with this canvas (screen, lumps, font and level time of the engine)
  PS_ConfigureOverlay(TEngineOverlayCanvas.Create);
  // PS_GAME is a group of the unit ps_import: it asks these parts for the functions that are classes
  PS_ConfigureGameFunctions(
    TScriptHostFactory.CreateGameInfo(TEngineScriptGameInfo.Create, LGame),
    TScriptHostFactory.CreateTextures(TEngineScriptTextures.Create),
    TScriptHostFactory.CreateKeys(TEngineScriptKeyboard.Create(AContext), LGame));
  LRegistry := TScriptHostFactory.CreateRegistry;
  LSystem :=TScriptHostFactory.CreateSystemFunctions(TEngineScriptRoutines.SystemRoutines,
    TEngineScriptOutput.Create, TEngineScriptEnvironment.Create,
    TEngineScriptConsole.Create(AConsole, ADefaults), ARandom);
  LRegistry.AddGroup(LSystem as IScriptFunctionGroup);
  LRegistry.AddGroup(TScriptHostFactory.CreateFixedGroup(TEngineScriptRoutines.FixedRoutines));
  PS_ConfigureSystem(LSystem);
  // what the compiler and the interpreter of the scripts use: the functions, the classes and the constants
  // that scripts see (one table for the compiler and the interpreter), the files they include and the game.
  // The defines are read at each compilation: -devparm is known after the composition
  PS_ConfigureHostServices(TScriptHostFactory.CreateServices(LRegistry,
    TScriptHostFactory.CreateClassCatalog(LGame),
    TScriptHostFactory.CreateConstants(TEngineScriptMobjConstants.Create, TEngineScriptGameConstants.Create,
      TEngineScriptWorldConstants.Create, TEngineScriptGroupConstants.Create),
    TEngineScriptSourceProvider.Create(APakFiles), _GAME, LGame,
    function: TArray<string>
    begin
      Result := TScriptHostFactory.CreateDefines(_GAME, LGame,
{$IFDEF DEBUG}
        True,
{$ELSE}
        False,
{$ENDIF}
        devparm,
{$IFDEF OPENGL}
        True);
{$ELSE}
        False);
{$ENDIF}
    end, ALog));
  // the events and the serializer of the script state warn through the log
  PS_ConfigureStateServices(ALog);
  PS_ConfigureSectorSpecials(
    TScriptHostFactory.CreateSectorSpecialFunctions(TEngineScriptSectorSpecials.Create));
  PS_ConfigureDllLoader(TScriptHostFactory.CreateDllLoader(
    TEngineScriptDllSource.Create(APakFiles, ATempFiles),
    TScriptHostFactory.CreateWindowsDllLibrary, ALog));
end;

procedure ComposeImaging(const ARandom: IGameRandom);
begin
{$IFNDEF STRIFE}
  // Strife fades (f_fade) instead of melting
  wipe_Configure(TImagingFactory.CreateMeltWipe(TEngineImagingRandom.Create(ARandom)));
{$ENDIF}
{$IFNDEF OPENGL}
  R_ConfigureFlatCache(TImagingFactory.CreateSpanGrower);
{$ENDIF}
  V_ConfigureFlatShrink(TImagingFactory.CreateFlatShrinker);
  R_ConfigureComposite(TImagingFactory.CreateColumnPainter, TImagingFactory.CreateColumnRebuilder);
{$IFNDEF OPENGL}
  R_ConfigureFixedColumn(TImagingFactory.CreateFixedColumnBuilder);
{$ENDIF}
  TRendererMain.R_ConfigureMenuThumbnail(TImagingFactory.CreateThumbnailBuilder(
    TEngineImagingColorIndex.Create(TPaletteFactory.CreateColorMatcher)));
  W_ConfigureSpritePatches(TImagingFactory.CreateColorPatchBuilder(
    TEngineImagingColorIndex.Create(TPaletteFactory.CreateColorMatcher)));
end;

procedure ComposeRenderer(const ALog: ILog);
var
  LDirectory: IRendererLumpDirectory;
  LGame: TRendererGame;
  LProfile: TRendererProfile;
begin
  if not TRendererProfiles.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Renderer), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of the renderer', [_GAME]);
  LProfile := TRendererProfiles.ForGame(LGame);
  R_ConfigurePrecache(TRendererFactory.CreatePrecachePlanner, LProfile);
  TRendererSky.R_ConfigureSky(LProfile.SkyTextureMid);
  R_ConfigureAspect(TRendererFactory.CreateMonitorAspect(
    TVideoFactory.CreateWindowsDisplayModeSource));
{$IFNDEF OPENGL}
  R_ConfigureFake3D(TRendererFactory.CreateFake3DAngles);
  R_ConfigureSpriteSort(TRendererFactory.CreateSpriteSortPolicy);
{$ENDIF}
  R_ConfigureTextureLookup(TRendererFactory.CreateTextureLookup(
    TEngineRendererPatchSource.Create, ALog));
  TRendererThings.R_ConfigureSpriteDefs(TRendererFactory.CreateSpriteDefs(
    TEngineRendererSpriteSource.Create, ALog));
  TRendererSubsectors.R_ConfigureSubsectorGrid(TRendererFactory.CreateSubsectorGridBuilder,
    TEngineRendererSubsectorLocator.Create);
  TRendererMain.R_ConfigureTextureMapping(TRendererFactory.CreateTextureMappingBuilder);
  TRendererMain.R_ConfigureViewTables(TRendererFactory.CreateViewTables);
  LDirectory := TEngineRendererLumpDirectory.Create;
  R_ConfigureLumpRanges(TRendererFactory.CreateLumpRanges(LDirectory, ALog),
    TRendererFactory.CreateSpriteTableBuilder(LDirectory,
      TEngineRendererSpriteHeaders.Create));
{$IFNDEF OPENGL}
  TRendererSegs2.R_ConfigureLevelPrecalc(TRendererFactory.CreateLevelPrecalc);
{$ENDIF}
end;

procedure ComposeScreenshot(const ASaveFileNames: ISaveFileNames);
var
  LScreenshot: IEngineScreenshot;
begin
  LScreenshot := TEngineScreenshotService.Create(
    TScreenshotFactory.CreateWriter(TPngProvider.Client, TJpegProvider.Client),
    TScreenshotFactory.CreateTargets(TEngineScreenshotFolders.Create(ASaveFileNames)),
    ASaveFileNames);
  TMainRoutines.D_ConfigureScreenshot(LScreenshot);
  G_ConfigureScreenshot(LScreenshot);
  TMenuRoutines.M_ConfigureScreenshot(LScreenshot);
end;

procedure ComposeTexture(const ALog: ILog; const APakFiles: IPakFileSystem;
  const AShutdown: IEngineShutdown);
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
  LServices.JpegConverter := TEngineTextureJpegConverter.Create(AShutdown);
  LServices.Log := ALog;
  LFiles := TEngineTextureFiles.Create(TTextureFactory.CreateFormats(LServices), APakFiles);
  // a material asks the files for the images it names: the resolver keeps them weakly
  LResolver.Attach(LFiles);
  V_ConfigureDrawTextures(TEngineDrawTextures.Create(LFiles));
  W_ConfigureSpriteTextures(LFiles);
  R_ConfigurePK3Textures(LFiles, APakFiles, TRendererFactory.CreatePk3NameSelector,
    TEngineRendererPk3Catalog.Create(LFiles), TRendererFactory.CreatePk3TextHash);
{$IFDEF OPENGL}
  gld_ConfigureTextureFiles(LFiles);
{$ELSE}
  R_ConfigureFlatTextures(LFiles);
  TRendererCacheWalls.R_ConfigureWallTextures(LFiles);
{$ENDIF}
end;

// The temporary files are one object for the whole engine: who makes one receives it, and
// i_tmp deletes them all at the shut down
function ComposePlatform(const ALog: ILog; const ARegistry: ICommandRegistry;
  const AStore: IFileStore; const ASaveFileNames: ISaveFileNames; const ALumps: IEngineLumps;
  const AZone: IZoneAllocator; const AShutdown: IEngineShutdown): ITempFiles;
var
  LFiles: IEngineFiles;
begin
  LFiles := TEngineFiles.Create(AStore, AZone, AShutdown);
  // the demos and the saves (Hexen: g_demo and sv_save; Strife: also p_saveg and the menus)
  G_ConfigureFiles(LFiles);
{$IFDEF HEXEN}
  SV_ConfigureFiles(LFiles);
{$ENDIF}
{$IFDEF STRIFE}
  P_ConfigureFiles(LFiles);
  TMenuRoutines.M_ConfigureFiles(LFiles);
{$ENDIF}
  PS_ConfigureVariables(TEngineScriptVariablesFiles.Create(LFiles),
    TEngineScriptVariablesFailure.Create);
  // lumpsize, lumpnum, numlumps and savelumptodisk
  W_ConfigureLumpCommands(TConsoleFactory.CreateLumpCommands(ARegistry, TEngineConsoleOutput.Create,
    TEngineConsoleLumpSource.Create(ALumps), TEngineConsoleLumpFiles.Create(LFiles, ASaveFileNames),
    ALog));
  Result := TPlatformFactory.CreateTempFiles(TEngineTempDirectory.Create(ASaveFileNames), AStore);
  I_ConfigureTempFiles(Result);
  I_ConfigurePlatform(TPlatformFactory.CreateServices);
end;

// The lights (udmf_lights, p_lights): the random of the game, the flicker rules and the numbers
// of the sequences of the game, and the maker of the thinkers of the phased lights
procedure ComposeLights(const ARandom: IGameRandom);
var
  LGame: TLightGame;
begin
  if not TLightGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Lights), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of lights', [_GAME]);
  P_ConfigureLights(ARandom, TLightFactory.CreateFlickerRules(LGame),
    TLightGames.SequenceProfile(LGame), TEngineLightPhaseSpawner.Create);
end;

// The platforms (udmf_plats, p_plats): the machine of the classic ones (not in Hexen, which has
// none) with the rules of the game, and the one of the scripted specials, both with the random of
// the game and what is around a sector
procedure ComposePlats(const ARandom: IGameRandom);
var
{$IFNDEF HEXEN}
  LGame: TPlatGame;
{$ENDIF}
  LMachine: IPlatMachine;
begin
  LMachine := nil;
{$IFNDEF HEXEN}
  if not TPlatGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Platforms), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of platforms', [_GAME]);
  LMachine := TPlatFactory.CreateMachine(LGame, TEnginePlatHost.Create,
    TEnginePlatSurroundings.Create, ARandom);
{$ENDIF}
  P_ConfigurePlats(LMachine, TPlatFactory.CreateUdmfMachine(TEngineUdmfPlatHost.Create,
    TEnginePlatSurroundings.Create, ARandom));
end;

// The teleports (udmf_telept, p_telept): the fog spawner and the random of the game
procedure ComposeTeleport(const ARandom: IGameRandom);
begin
  P_ConfigureTeleport(TEngineTeleportFogSpawner.Create, ARandom);
end;

// The vertical doors (udmf_doors, p_doors): the profile of the game for each flavor of door, the
// services of the real game (movement of the ceiling, sounds, sectors around, compatibility
// option) and the classes that run and make the doors. Hexen has only the scripted doors
procedure ComposeDoors;
var
  LGame: TDoorGame;
  LHost: IDoorPlaneMover;
  LProfile: TDoorProfile;
  LClassicRunner: IDoorRunner;
  LClassicSpawner: IDoorSpawner;
  LUdmfRunner: IDoorRunner;
  LUdmfSpawner: IDoorSpawner;
begin
  if not TDoorProfiles.TryGameFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Doors), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of doors', [_GAME]);

  LClassicRunner := nil;
  LClassicSpawner := nil;
  if LGame <> TDoorGame.Hexen then
  begin
    LHost := TEngineDoorHost.Create(TDoorFlavor.Classic);
    LProfile := TDoorProfiles.ForGame(LGame, TDoorFlavor.Classic);
    LClassicRunner := TDoorFactory.CreateRunner(LProfile, LHost, LHost as IDoorSounds,
      LHost as IDoorOptions);
    LClassicSpawner := TDoorFactory.CreateSpawner(LProfile, LHost as IDoorSounds,
      LHost as IDoorSectorQueries);
  end;

  LHost := TEngineDoorHost.Create(TDoorFlavor.Udmf);
  LProfile := TDoorProfiles.ForGame(LGame, TDoorFlavor.Udmf);
  LUdmfRunner := TDoorFactory.CreateRunner(LProfile, LHost, LHost as IDoorSounds,
    LHost as IDoorOptions);
  LUdmfSpawner := TDoorFactory.CreateSpawner(LProfile, LHost as IDoorSounds,
    LHost as IDoorSectorQueries);

  P_ConfigureDoors(LClassicRunner, LClassicSpawner, LUdmfRunner, LUdmfSpawner);
end;

// The moving planes (floors, ceilings, and soon doors and platforms): what the game does when a
// plane of a sector moves
procedure ComposePlanes;
{$IFNDEF HEXEN}
var
  LGame: TPlatGame;
{$ENDIF}
begin
  P_ConfigurePlanes(TEnginePlaneHost.Create);
{$IFNDEF HEXEN}
  // the classic ceilings (p_ceilng, one unit for Doom, Heretic and Strife) and floors (p_floor, one
  // unit for Doom and Strife): the rules of the game, which is the one of the classic platforms
  if not TPlatGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Platforms), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of ceilings', [_GAME]);
  P_ConfigureCeilings(TCeilingGames.ProfileOf(LGame));
  P_ConfigureFloors(TFloorGames.ProfileOf(LGame));
{$ENDIF}
end;

procedure ComposeThreading;
var
  LThreads: IWorkerThreadFactory;
  LMessages: IWorkerMessages;
begin
  // one factory of real threads for the TDThread of the renderer and for the pools of mt_utils
  LThreads := TThreadingFactory.CreateThreadFactory;
  I_ConfigureThreads(LThreads);
  LMessages := TEngineThreadServices.Create;
  MT_ConfigureThreads(TThreadingFactory.CreatePoolFactory(LThreads), LMessages,
    LMessages as IWorkerMemoryOps);
end;

procedure ComposeMathCore(const ARandom: IGameRandom);
begin
  M_ConfigureRandom(ARandom);
  R_ConfigureNameHash(TMathCoreFactory.CreateStringHashTable);
  ComposeLights(ARandom);
  ComposePlats(ARandom);
  ComposeTeleport(ARandom);
  ComposeDoors;
  ComposePlanes;
end;

// The world of a level (p_tick): the list of the thinkers on the head that the saved games know,
// the time of the level where the engine keeps it and the random of the game
procedure ComposeWorld(const ARandom: IGameRandom);
begin
  P_ConfigureWorld(TEngineWorld.Create(@TTickState.ThinkerCap, P_WorldTime, ARandom));
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
  // the records that the saved games keep whole: on disk they are the ones of the 32 bit program (issue #40)
  P_ConfigureSaveRecords(TSerializerFactory.CreateDiskLayouts, TSerializerFactory.CreateDiskRecordWriter);
end;

{$IFDEF OPENGL}
procedure ComposeModels(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor);
begin
  gld_ConfigureModelDefinitions(APreprocessor,
    TModelsFactory.CreateDefinitionParser(TEngineModelDefinitionLookup.Create, ALog),
    TEngineModelDefinitionSink.Create);
end;

procedure ComposeLevelGeometry;
begin
  gld_ConfigureFlatCarver(TGlLevelFactory.CreateFlatCarver(TEngineGlFlatWorld.Create,
    TEngineGlFlatLoopSink.Create));
  gld_ConfigureSectorPreprocessor(TGlLevelFactory.CreateSectorPreprocessor(TEngineGlSectorWorld.Create));
end;

procedure ComposeGlAutomap;
begin
  // Hexen maps a flat by its real size; the other games by 64 units
  gld_ConfigureAutomap(TGlAutomapFactory.CreateDisplayList,
    TEngineGlAutomapPainter.Create({$IFDEF HEXEN}True{$ELSE}False{$ENDIF}));
end;

procedure ComposeGlScene;
var
  LWalls: TEngineGlSceneWallCollector;
  LWallPainter: TEngineGlSceneWallPainter;
  LFlatPainter: TEngineGlSceneFlatPainter;
  LSpritePainter: TEngineGlSceneSpritePainter;
  LLightSorter: TEngineGlSceneLightSorter;
  LLightPainter: TEngineGlSceneLightPainter;
  LInitializer: TEngineGlInitializer;
begin
  // classes and not interfaces: gl_render calls them for every wall, flat and sprite of a frame, and owns them
  gld_ConfigureDrawList(TGlSceneFactory.CreateDrawList(gld_SceneItemSizes));
  gld_ConfigureFlatCollector(TEngineGlSceneFlatCollector.Create(gld_SceneDrawList, gld_LightTable));
  LWalls := TEngineGlSceneWallCollector.Create(gld_SceneDrawList, gld_LightTable, gld_FlatCollector);
  gld_ConfigureWallCollector(LWalls);
  gld_ConfigureLevelPreprocessor(TEngineGlLevelPreprocessor.Create(gld_SceneDrawList, gld_FlatCollector, LWalls));
  LWallPainter := TEngineGlSceneWallPainter.Create;
  gld_ConfigureWallPainter(LWallPainter);
  LFlatPainter := TEngineGlSceneFlatPainter.Create;
  gld_ConfigureFlatPainter(LFlatPainter);
  LSpritePainter := TEngineGlSceneSpritePainter.Create(TEngineGlSceneModelPainter.Create,
    TEngineGlSceneVoxelPainter.Create);
  gld_ConfigureSpritePainter(LSpritePainter);
  // the drawer only walks the list: the owner of the painters is still gl_render
  LLightSorter := TEngineGlSceneLightSorter.Create;
  gld_ConfigureLightSorter(LLightSorter);
  LLightPainter := TEngineGlSceneLightPainter.Create;
  gld_ConfigureLightPainter(LLightPainter);
  gld_ConfigureSceneDrawer(TEngineGlSceneDrawer.Create(gld_SceneDrawList, LWalls, LWallPainter,
    LFlatPainter, LSpritePainter, LLightSorter, LLightPainter));
  // the start of the renderer (gld_Init) owns the vertical sync object and fills the light table of gl_render
  LInitializer := TEngineGlInitializer.Create(TEngineGlVSync.Create, gld_LightTable);
  gld_ConfigureInitializer(LInitializer);
  // the frame follows the vertical sync the initializer started
  gld_ConfigureSceneFrame(TEngineGlSceneFrame.Create(gld_SceneDrawList, gld_FlatCollector, LWalls, LWallPainter,
    LSpritePainter, LLightPainter, LInitializer.VSync));
end;

procedure ComposeOpenGl(const APreprocessor: IScriptTextPreprocessor);
begin
  GL_ConfigureClipper(TGlMathFactory.CreateAngleClipper);
  ComposeGlAutomap;
  ComposeGlScene;
end;
{$ENDIF}

procedure ComposeStartup(const ALog: ILog; const ACommandLine: ICommandLine);
var
  LLimits: TScreenSizeLimits;
begin
  LLimits.MinWidth := MINWIDTH;
  LLimits.MinHeight := MINHEIGHT;
  LLimits.MaxWidth := MAXWIDTH;
  LLimits.MaxHeight := MAXHEIGHT;
  TMainRoutines.D_ConfigureStartup(
    TCommandLineFactory.CreateResponseFileExpander(TEngineResponseFileSource.Create, ALog),
    TVideoFactory.CreateScreenSizeResolver(ACommandLine, TVideoFactory.CreateWindowsDisplayMetrics,
      LLimits,
      function(AText: string): Integer
      begin
        Result := EngineParseNumber(AText);
      end));
end;

procedure ComposeAutomap;
var
  LView: IAutomapView;
  LNavigator: IAutomapNavigator;
begin
  TAutomapFactory.CreateView(LView, LNavigator);
  AM_Configure(LView, LNavigator, TAutomapFactory.CreateMarks);
end;

procedure ComposeHud;
var
  LEnvironment: TEngineHudEnvironment;
  LFlags: IHudFlags;
  LPlayers: IHudPlayers;
  LMessages: IHudPlayerMessage;
  LSettings: IHudSettings;
  LSound: IHudChatSound;
  LEcho: IHudEcho;
  LHeadsUp: IHeadsUp;
  LView: IHudView;
begin
  // one object answers the six contracts: the interfaces keep it alive
  LEnvironment := TEngineHudEnvironment.Create;
  LFlags := LEnvironment;
  LPlayers := LEnvironment;
  LMessages := LEnvironment;
  LSettings := LEnvironment;
  LSound := LEnvironment;
  LEcho := LEnvironment;
  THudFactory.CreateHeadsUp(TEngineHudRules.Build, LFlags, LPlayers, LMessages, LSettings, LSound,
    LEcho, LHeadsUp, LView);
  HU_Configure(LHeadsUp, TEngineHudDrawer.Create(LView, LEnvironment));
end;

procedure ComposeActorDef(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor;
  const ARegistry: ICommandRegistry; const ALumps: IEngineLumps);
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
  if not TActorDefProfiles.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.ActorDef), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of ACTORDEF', [_GAME]);
  LProfile := TActorDefProfiles.ForGame(LGame);
{$IFDEF RADIX}
  // the properties of the actors that only Radix has (the INVENTORY block of the pickups ...)
  LProfile.ExtraProperties := ComposeRadixActorProperties(ALog);
{$ENDIF}
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
    APreprocessor, ARegistry, ALumps);
  LLumps := LLumpsObject;
  TMainRoutines.D_ConfigureActorDef(LLumps);
  // the rules of the numbers of the sounds: the table of the game (its own unit in the folder
  // of each game) and the aliases that the ACTORDEF lumps fill
  S_ConfigureSoundNumbers(
    TSfxNumberResolver.Create(
      TEngineSfxTable.Create,
      function(const AName: string): string
      begin
        Result := LAliases.Resolve(AName);
      end,
      ALog));
end;

procedure ComposeTableExport(const ACommandLine: ICommandLine);
var
  LGame: TExportGame;
  LThings: IExportThingSource;
  LStates: IExportStateSource;
  LWeapons: IExportWeaponSource;
  LNames: TEngineExportNames;
  LNamesRef: IInterface;
  LSaver: ITableExportSaver;
begin
  if not TExportProfiles.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.TableExport), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of the table exports', [_GAME]);
  LThings := TEngineExportThings.Create(False);
  LStates := TEngineExportStates.Create;
  LWeapons := TEngineExportWeapons.Create;
  LNames := TEngineExportNames.Create;
  LNamesRef := LNames;
  LSaver := TTableExportSaver.Create(TEngineExportOutput.Create);
  DEH_ConfigureExport(
    TTableExportFactory.CreateDehWriter(LGame, LThings, LStates, LWeapons,
      TEngineExportSettings.Create(ACommandLine),
      LNames, LNames),
    TTableExportFactory.CreateCsvWriter(LStates, LNames),
    TTableExportFactory.CreateActorDefWriter(LThings, LStates, LNames, LNames, LNames),
    TTableExportFactory.CreateWeaponDefWriter(LGame, LWeapons, LStates, LNames, LNames),
    TTableExportFactory.CreateStateOwnersWriter(LStates, LNames), LSaver);
  Info_ConfigureExport(
    TTableExportFactory.CreatePascalWriter(LGame, LThings, TEngineExportThings.Create(True), LStates,
      LNames, LNames, LNames), LSaver);
end;

procedure ComposeIwad;
var
  LGame: TIwadGame;
  LServices: TIwadServices;
begin
  if not TIwadGames.TryFromName(TGameAliases.ProfileOf(_GAME, TGameProfileArea.Iwad), LGame) then
    I_Error('ComposeEngine(): the game %s has no profile of IWADs', [_GAME]);
  LServices := TIwadFactory.CreateWindowsServices(LGame, TEngineIwadOptions.Create);
  TMainRoutines.D_ConfigureIwad(LServices.Locator, LServices.Identifier);
end;

procedure ComposeVoxels(const ALog: ILog; const APreprocessor: IScriptTextPreprocessor;
  const APakFiles: IPakFileSystem; const ASaveFileNames: ISaveFileNames;
  const ALumps: IEngineLumps; const AScreens: IEngineScreens; const ATempFiles: ITempFiles);
var
  LLoader: IVoxelLoader;
  LCubes: IVoxelCubeBuilder;
  LLumps: IVoxelLumpNames;
begin
  LLoader := TVoxelFactory.CreateLoader(TEngineVoxelFileSource.Create(APakFiles, ALumps), ALog);
  LCubes := TVoxelFactory.CreateCubeBuilder;
  LLumps := TEngineVoxelLumpNames.Create(ALumps);
  R_ConfigureVoxelSprites(TEngineVoxelSpriteGenerator.Create(LLoader, LCubes,
    TVoxelFactory.CreatePatchBuilder(TEngineVoxelColorMapper.Create(AScreens)),
    function: IVoxelSpriteNames
    begin
      Result := TVoxelFactory.CreateSpriteNames(LLumps);
    end,
    function: Boolean
    begin
      // the option is read at each call: the .ini is read after the composition
      Result := r_generatespritesfromvoxels;
    end, APakFiles, ASaveFileNames, ALumps, ATempFiles));
  // the sink makes the model of the renderer of each new voxel with the loader
  VX_ConfigureVoxels(
    TVoxelFactory.CreateDefinitionParser(TEngineVoxelDefinitionLookup.Create, ALog),
    TEngineVoxelDefinitionSink.Create(LLoader, LCubes), APreprocessor);
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

// The tables of things and states stay data (info.pas of the game); the searches, the names of
// the groups, the monsters placed at random and the names of the states are the classes of
// IdTech1\Info, and info_common, info_rnd, info_fnd and sc_states are facades over them (issue #185, slice 1b)
procedure ComposeInfoTables;
var
  LTables: TEngineInfoTables;
  LMobjs: IInfoMobjSource;
  LStates: IInfoStateSource;
  LSprites: IInfoSpriteSource;
  LThings: IEngineInfoThings;
  LThingNames: IInfoThingNames;
  LInfoRandom: IInfoRandom;
begin
  // one object reads the three tables: the interfaces keep it alive
  LTables := TEngineInfoTables.Create;
  LMobjs := LTables;
  LStates := LTables;
  LSprites := LTables;
  LThings := TEngineInfoThings.Create(LMobjs);
  LThingNames := LThings as IInfoThingNames;
  Info_ConfigureThings(LThings);
  Info_ConfigureStates(TEngineInfoStates.Create(LMobjs, LStates, LSprites));
  Info_ConfigureGroups(TEngineInfoGroups.Create);
  LInfoRandom := TEngineParamRandom.Create;
  Info_ConfigureRandom(TEngineInfoRandom.Create(LMobjs, TEngineInfoRandomRules.Create, LInfoRandom));
  SC_ConfigureStateNames(TEngineStateNames.Create(LMobjs, TEngineInfoStateTokens.Create, LThingNames,
    TEngineInfoStateText.Create));
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
  LPakFiles: IPakFileSystem;
  LPakContainers: IPakContainers;
  LRegistry: ICommandRegistry;
  LInterpreter: IConsoleInterpreter;
  LConsole: IEngineConsole;
  LDefaults: IEngineDefaults;
  LEndScreenTick: TProc;
  LCommandLine: IQueriedCommandLine;
  LSaveFileNames: ISaveFileNames;
  LRandom: IGameRandom;
  LStore: IFileStore;
  LShutdown: IEngineShutdown;
  LScreens: IEngineScreens;
  LParity: TEngineParity;
  LParitySwitch: IParitySwitch;
  LParityClock: TParitySwitchClock;
  LNetGame: IEngineNetGame;
  LInput: IInputPoller;
  LSettings: IConfigurationTable;
  LThingFields: IEngineDehackedThingFields;
begin
  // how a class of the engine stops the game: I_Error and I_Quit of i_system
  LShutdown := TEngineShutdown.Create;
  LScreens := TEngineScreens.Create;
  // The parity tools (-statehash, -framehash, -autodemo...) are built when the command line says so: until
  // then their switch is off and the zone, the clock, the input gate and the random numbers are the real ones
  LParity := TEngineParity.Create(LShutdown);
  LParitySwitch := LParity;
  // The zone first: whatever is built next can already allocate from it
  LZoneCore := TEngineParityZone.Create(TZoneFactory.CreateAllocator(TEngineZoneMemory.Create), LParitySwitch);
  Z_ConfigureZone(LZoneCore);
  // the classes of the engine use the same allocator, with the I_Error of the Z_* functions
  LZone := TEngineZoneAllocator.Create(LZoneCore, LShutdown);
  LLumps := TEngineLumps.Create;
  // DelphiDoom is a port of the Doom engine: id Tech 1, at the version of doomdef
  LEngine := TIdTechFactory.CreateDelphiDoom(VERSION);
  TMainRoutines.D_Configure(LEngine);
  ComposeIwad;
  // the command line exists from here on, the arguments are attached by M_InitArgv
  LCommandLine := TCommandLineFactory.CreateQueriedCommandLine;
  LStore := TPlatformFactory.CreateFileStore;
  LSaveFileNames := TCommandLineFactory.CreateSaveFileNames(LCommandLine,
    function: Boolean
    begin
      Result := I_IsCDRomDrive;
    end,
    procedure(APath: string)
    begin
      LStore.EnsureDirectory(APath);
    end, CD_WORKDIR);
  // the program works in the folder of the data of its game (bin\Game), wherever its executable was built
  M_ConfigureDataFolder(TDataFolderFactory.CreateLocator);
  M_ConfigureArgv(TCommandLineFactory.CreateStartup(TCommandLineFactory.CreateBuilder, LSaveFileNames,
    TEngineProgramEnvironment.Create, APPNAME, DEFARGVFILENAME), LCommandLine, LSaveFileNames);
  LParity.AttachCommandLine(LCommandLine);
  LRandom := TMathCoreFactory.CreateGameRandom(TParitySwitchEntropy.Create(
    TSystemEntropySource.Create(True), LParitySwitch, PARITY_ENTROPY_SEED));
  LParity.AttachRandom(LRandom);
  LContext := TEngineGameContext.Create;
  LLog := TLogFactory.CreateLog(TArray<ILogSink>.Create(TEngineParityLogSink.Create(TEngineLogSink.Create, LParitySwitch)),
    function: Boolean
    begin
      Result := LContext.IsDeveloperMode;
    end);
  I_ConfigureLog(LLog);
  // the fatal errors are handled from here on
  ComposeFatalError(LLog);
  // The WAD services and the PAK file system: the classes that read files receive them
  LWadServices := TEngineWadServices.Create;
  ComposePak(LWadServices, LPakFiles, LPakContainers);
  // the console before anyone registers a command; the defaults after it (#CVARFORCE uses them)
  // the rows of the options (m_defs), shared by the console and the defaults
  LSettings := TEngineConfigurationTable.Build;
  LConsole := ComposeConsole(LLog, LContext, LCommandLine, LSaveFileNames, LLumps, LSettings,
    LRegistry, LInterpreter);
  LDefaults := ComposeDefaults(LRegistry, LInterpreter, LCommandLine, LSettings);
  LTempFiles := ComposePlatform(LLog, LRegistry, LStore, LSaveFileNames, LLumps, LZone, LShutdown);
  LPreprocessor := ComposeScanner(LLog, LDefaults, LLumps, LZone, LShutdown, LTempFiles, LEvaluator);
  ComposeScriptHost(LLog, LContext, LConsole, LDefaults, LRandom, LPakFiles, LTempFiles);
  ComposeThreading;
  ComposeMathCore(LRandom);
  ComposeWorld(LRandom);
  ComposeSerializer;
{$IFDEF OPENGL}
  ComposeOpenGl(LPreprocessor);
{$ENDIF}
  LClock := TClockFactory.CreateClock(LLog);
  LParityClock := TParityFactory.CreateSwitchClock(LClock, LParitySwitch, TICRATE);
  LClock := LParityClock;
  LParity.AttachClock(LParityClock);
  I_ConfigureClock(LClock);
  I_ConfigureVideo(TVideoFactory.CreateServices);
  ComposeDisplayModes;
  LInput := ComposeInput(LLog, LParitySwitch);
  ComposeSound(LLog);
  ComposeMusic(LTempFiles, LCommandLine, LZone, LLog, LShutdown);
  S_ConfigurePK3Sounds(LTempFiles);
  LThingFields := TEngineDehackedThingFields.Create;
  ComposeDehacked(LLog, LEvaluator, LThingFields);
  ComposeImaging(LRandom);
  ComposeRenderer(LLog);
  ComposeScreenshot(LSaveFileNames);
  ComposeTexture(LLog, LPakFiles, LShutdown);
  ComposeTextureDefs(LLog, LPakFiles, LLumps);
  ComposePalette(LPakFiles, LZone);
  LMusInfo := ComposeMusInfo(LLog, LLumps);
  ComposeDynLights(LLog, LContext, LPreprocessor, LPakFiles, LRandom, LLumps);
  ComposeAutomap;
  ComposeHud;
  ComposeActorDef(LLog, LPreprocessor, LRegistry, LLumps);
  ComposeInfoTables;
  ComposeTableExport(LCommandLine);
  P_ConfigureAcs(TAcsFactory.CreateCompiler(TEngineAcsSourceProvider.Create, LLog),
    TAcsFactory.CreateMachine(TEngineAcsHost.Create(LRandom, LZone), LLog));
  LEndScreenTick := ComposeEndoom(LLumps, LZone, LLog, LShutdown, LScreens);
  LNetGame := ComposeNetGame(LClock, LLog, LContext, LConsole, LEndScreenTick, LShutdown);
  ComposeSystem(LLog, LCommandLine, LNetGame, LDefaults, LInput);
  ComposeVoxels(LLog, LPreprocessor, LPakFiles, LSaveFileNames, LLumps, LScreens, LTempFiles);
{$IFDEF OPENGL}
  ComposeModels(LLog, LPreprocessor);
  ComposeLevelGeometry;
{$ENDIF}

  W_Configure(LWadServices);
{$IFDEF RADIX}
  ComposeRadix(LLog, LLumps, LThingFields, LRandom);
{$ENDIF}
{$IFDEF SPEED}
  ComposeSpeed(LLog);
{$ENDIF}
  TWadReader.Configure(LWadServices);
  TWadWriter.Configure(LWadServices);
  ComposeStartup(LLog, LCommandLine);
  TMainRoutines.D_ConfigureAutoLoad(TAutoLoadReader.Create(TEngineAutoLoadLumps.Create(LLumps),
    TEngineAutoLoadSink.Create(LPakContainers), TEngineScannerLog.Create));
  ComposeLevel(LLog, LContext, LTempFiles, LWadServices, LMusInfo, LCommandLine, LSaveFileNames,
    LRegistry, LRandom, LLumps, LZone, LShutdown);
{$IFNDEF HEXEN}
  // Hexen has its own specials (p_spec): the UDMF ones are only for the other games
  P_ConfigureLineSpecials(TSpecialsFactory.CreateRegistry);
  ComposeMapInfo(LLog, LPreprocessor, LLumps);
{$ENDIF}
end;

end.
