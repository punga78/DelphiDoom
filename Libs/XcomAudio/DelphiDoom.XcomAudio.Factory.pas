{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the factory: the composition root of the    }
{  audio of the game                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.Factory;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.Music.Intf,
  DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   The only place that knows the classes of the audio: the decoders of Libs\Sound and Libs\Mp3, the tracker of
  ///   Libs\Mikmod, the sequencer of Libs\Midi, the Adlib, the mixer and the music player
  /// </summary>
  TXcomAudioFactory = class
  public
    /// <summary>
    ///   The mixer on the output (Game::run: Mix_OpenAudio, then setVolume of the options) and the player of the
    ///   music that plays on it. ADevice is also IXcomMixerMeter and IXcomChannelMixer. When there is no output the
    ///   device says it is not available and nothing plays
    /// </summary>
    /// <param name="AOptions">The options of the game; they are read, not owned</param>
    /// <param name="ARate">The rate of the mixer; 0 or less takes Options::audioSampleRate (22050 by default)</param>
    class procedure CreateAudio(AOptions: TXcomOptions; const AOutput: IXcomPcmOutput; ARate: Integer;
      out ADevice: IXcomAudioDevice; out AMusic: IXcomMusicPlayer); static;
    /// <summary>The decoder of WAV, OGG Vorbis, FLAC and the other sound files (Libs\Sound)</summary>
    class function CreateSoundDecoder: IXcomSampleDecoder; static;
    /// <summary>The decoder of MP3 files (Libs\Mp3)</summary>
    class function CreateMp3Decoder: IXcomSampleDecoder; static;
    /// <summary>The loaders of every format of music, in the order of MusicFormat</summary>
    class function CreateLoaders(const ASettings: IXcomMusicSettings; ARate: Integer): TArray<IXcomMusicFormatLoader>; static;
  end;

implementation

uses
  DelphiDoom.Sound.Factory, DelphiDoom.Mp3.Provider, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAdlib.Factory,
  DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomAudio.Types, DelphiDoom.XcomAudio.Mixer,
  DelphiDoom.XcomAudio.MusicPlayer, DelphiDoom.XcomAudio.CatSongs, DelphiDoom.XcomAudio.OptionsSettings,
  DelphiDoom.XcomAudio.SndfileDecoder, DelphiDoom.XcomAudio.Mp3Decoder, DelphiDoom.XcomAudio.AdlibMusicLoader,
  DelphiDoom.XcomAudio.DigitalMusicLoader, DelphiDoom.XcomAudio.TrackerMusicLoader,
  DelphiDoom.XcomAudio.MidiMusicLoader, DelphiDoom.XcomAudio.MidiSynth;

class function TXcomAudioFactory.CreateSoundDecoder: IXcomSampleDecoder;
begin
  Result := TXcomSndfileDecoder.Create(TSoundFactory.CreateEngine);
end;

class function TXcomAudioFactory.CreateMp3Decoder: IXcomSampleDecoder;
begin
  Result := TXcomMp3Decoder.Create(TMp3Provider.Mp3);
end;

class function TXcomAudioFactory.CreateLoaders(const ASettings: IXcomMusicSettings;
  ARate: Integer): TArray<IXcomMusicFormatLoader>;
var
  LSound: IXcomSampleDecoder;
  LSynth: IXcomMidiSynth;
begin
  LSound := CreateSoundDecoder;
  LSynth := TXcomMidiSynth.Create(ARate);
  Result := [
    TXcomDigitalMusicLoader.Create(mfFlac, '.flac', 'FLAC', LSound, ARate),
    TXcomDigitalMusicLoader.Create(mfOgg, '.ogg', 'OGG', LSound, ARate),
    TXcomDigitalMusicLoader.Create(mfMp3, '.mp3', 'MP3', CreateMp3Decoder, ARate),
    TXcomTrackerMusicLoader.Create(ARate),
    TXcomDigitalMusicLoader.Create(mfWav, '.wav', 'WAV', LSound, ARate),
    TXcomAdlibMusicLoader.Create(ASettings,
      function: IXcomAdlibPlayer
      begin
        Result := TXcomAdlibFactory.CreatePlayer(ARate);
      end,
      function(const AResources: IXcomResources): IXcomAdlibSongs
      begin
        Result := TXcomCatSongs.FromResources(AResources);
      end),
    TXcomMidiMusicLoader.Create(mfGm, ARate, LSynth),
    TXcomMidiMusicLoader.Create(mfMidi, ARate, LSynth)];
end;

class procedure TXcomAudioFactory.CreateAudio(AOptions: TXcomOptions; const AOutput: IXcomPcmOutput; ARate: Integer;
  out ADevice: IXcomAudioDevice; out AMusic: IXcomMusicPlayer);
var
  LSink: IXcomMusicSink;
  LMeter: IXcomMixerMeter;
  LSettings: IXcomMusicSettings;
begin
  // Options::audioSampleRate when no rate is asked
  if ARate <= 0 then
    ARate := AOptions.GetValue('audioSampleRate');
  if ARate <= 0 then
    ARate := XCOM_AUDIO_RATE;
  ADevice := TXcomMixer.Create(AOutput, ARate, CreateSoundDecoder);
  LSink := ADevice as IXcomMusicSink;
  LMeter := ADevice as IXcomMixerMeter;
  Randomize;
  LSettings := TXcomOptionsMusicSettings.Create(AOptions);
  AMusic := TXcomMusicPlayer.Create(LSink, LSettings, CreateLoaders(LSettings, ARate));
  if LMeter.Open then
    ADevice.SetVolume(AOptions.SoundVolume, AOptions.MusicVolume, AOptions.UiVolume);
end;

end.
