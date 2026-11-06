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
{$ENDIF}
  DelphiDoom.Engine.Acs.SourceProvider,
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
{$ENDIF}
end;

end.
