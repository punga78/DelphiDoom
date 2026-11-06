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
  I_ConfigureClock(TClockFactory.CreateClock(LLog));
  I_ConfigureVideo(TVideoFactory.CreateServices);
  ComposeInput(LLog);
  ComposeSound(LLog);
  ComposeMusic;
  ComposeDehacked(LLog);
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
