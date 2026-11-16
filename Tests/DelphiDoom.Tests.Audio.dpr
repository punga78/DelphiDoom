{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Audio;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Framework\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Framework\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Framework\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Audio.Types in '..\Framework\Audio\DelphiDoom.Audio.Types.pas',
  DelphiDoom.Audio.Intf in '..\Framework\Audio\DelphiDoom.Audio.Intf.pas',
  DelphiDoom.Audio.Levels in '..\Framework\Audio\DelphiDoom.Audio.Levels.pas',
  DelphiDoom.Audio.SfxAttenuation in '..\Framework\Audio\DelphiDoom.Audio.SfxAttenuation.pas',
  DelphiDoom.Audio.ChannelPicker in '..\Framework\Audio\DelphiDoom.Audio.ChannelPicker.pas',
  DelphiDoom.Audio.ExternalMusicNames in '..\Framework\Audio\DelphiDoom.Audio.ExternalMusicNames.pas',
  DelphiDoom.Scanner.Strings in '..\Framework\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Audio.Sound.Intf in '..\Framework\Audio\DelphiDoom.Audio.Sound.Intf.pas',
  DelphiDoom.Audio.SoundNames in '..\Framework\Audio\DelphiDoom.Audio.SoundNames.pas',
  DelphiDoom.Audio.MusicNumberResolver in '..\Framework\Audio\DelphiDoom.Audio.MusicNumberResolver.pas',
  DelphiDoom.Audio.Pk3SoundNames in '..\Framework\Audio\DelphiDoom.Audio.Pk3SoundNames.pas',
  DelphiDoom.Audio.SfxNumberResolver in '..\Framework\Audio\DelphiDoom.Audio.SfxNumberResolver.pas',
  DelphiDoom.Audio.SfxRandomGroup in '..\Framework\Audio\DelphiDoom.Audio.SfxRandomGroup.pas',
  DelphiDoom.Audio.SfxPlayer in '..\Framework\Audio\DelphiDoom.Audio.SfxPlayer.pas',
  DelphiDoom.Audio.MusicPlayer in '..\Framework\Audio\DelphiDoom.Audio.MusicPlayer.pas',
  DelphiDoom.Audio.ExternalMusicCache in '..\Framework\Audio\DelphiDoom.Audio.ExternalMusicCache.pas',
  DelphiDoom.Audio.Factory in '..\Framework\Audio\DelphiDoom.Audio.Factory.pas',
  DelphiDoom.Audio.SoundParameters in '..\Framework\Audio\DelphiDoom.Audio.SoundParameters.pas',
  DelphiDoom.Audio.WaveParser in '..\Framework\Audio\DelphiDoom.Audio.WaveParser.pas',
  DelphiDoom.Audio.MusConverter in '..\Framework\Audio\DelphiDoom.Audio.MusConverter.pas',
  DelphiDoom.Audio.Efx.Types in '..\Framework\Audio\DelphiDoom.Audio.Efx.Types.pas',
  DelphiDoom.Audio.Efx.EffectsFile in '..\Framework\Audio\DelphiDoom.Audio.Efx.EffectsFile.pas',
  DelphiDoom.Audio.WaveHeader in '..\Framework\Audio\DelphiDoom.Audio.WaveHeader.pas',
  DelphiDoom.Wad.Fs.Types in '..\Framework\Wad\DelphiDoom.Wad.Fs.Types.pas',
  DelphiDoom.Wad.Fs.Intf in '..\Framework\Wad\DelphiDoom.Wad.Fs.Intf.pas',
  DelphiDoom.Audio.WaveFile.Types in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.Types.pas',
  DelphiDoom.Audio.WaveFile.Intf in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.Intf.pas',
  DelphiDoom.Audio.WaveFile in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.pas',
  DelphiDoom.Audio.WaveFile.GameFileSystem in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.GameFileSystem.pas',
  DelphiDoom.Audio.D3.Types in '..\Framework\Audio\DelphiDoom.Audio.D3.Types.pas',
  DelphiDoom.Audio.D3.Intf in '..\Framework\Audio\DelphiDoom.Audio.D3.Intf.pas',
  DelphiDoom.Audio.D3.PortalSpatializer in '..\Framework\Audio\DelphiDoom.Audio.D3.PortalSpatializer.pas',
  DelphiDoom.Audio.D3.ChannelGain in '..\Framework\Audio\DelphiDoom.Audio.D3.ChannelGain.pas',
  DelphiDoom.Audio.D3.SpeakerMixer in '..\Framework\Audio\DelphiDoom.Audio.D3.SpeakerMixer.pas',
  DelphiDoom.Audio.SoundSample.Types in '..\Framework\Audio\DelphiDoom.Audio.SoundSample.Types.pas',
  DelphiDoom.Audio.SoundSample.Cache in '..\Framework\Audio\DelphiDoom.Audio.SoundSample.Cache.pas',
  DelphiDoom.Decl.Sound.Types in '..\IdTech4\Decl\DelphiDoom.Decl.Sound.Types.pas',
  DelphiDoom.Decl.Sound.Intf in '..\IdTech4\Decl\DelphiDoom.Decl.Sound.Intf.pas',
  DelphiDoom.Decl.Sound.CacheCatalog in '..\IdTech4\Decl\DelphiDoom.Decl.Sound.CacheCatalog.pas',
  DelphiDoom.Ogg.Types in '..\Framework\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Framework\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Framework\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Framework\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Framework\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Framework\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Framework\Ogg\DelphiDoom.Ogg.Sync.pas',
  DelphiDoom.Audio.Q3.Sfx in '..\Framework\Audio\DelphiDoom.Audio.Q3.Sfx.pas',
  DelphiDoom.Audio.Q3.Types in '..\Framework\Audio\DelphiDoom.Audio.Q3.Types.pas',
  DelphiDoom.Audio.Q3.Intf in '..\Framework\Audio\DelphiDoom.Audio.Q3.Intf.pas',
  DelphiDoom.Audio.Q3.State in '..\Framework\Audio\DelphiDoom.Audio.Q3.State.pas',
  DelphiDoom.Audio.Q3.Resampler in '..\Framework\Audio\DelphiDoom.Audio.Q3.Resampler.pas',
  DelphiDoom.Audio.Q3.Loader in '..\Framework\Audio\DelphiDoom.Audio.Q3.Loader.pas',
  DelphiDoom.Audio.Q3.SfxRegistry in '..\Framework\Audio\DelphiDoom.Audio.Q3.SfxRegistry.pas',
  DelphiDoom.Audio.Q3.Listener in '..\Framework\Audio\DelphiDoom.Audio.Q3.Listener.pas',
  DelphiDoom.Audio.Q3.ChannelPool in '..\Framework\Audio\DelphiDoom.Audio.Q3.ChannelPool.pas',
  DelphiDoom.Audio.Q3.LoopSounds in '..\Framework\Audio\DelphiDoom.Audio.Q3.LoopSounds.pas',
  DelphiDoom.Audio.Q3.RawStream in '..\Framework\Audio\DelphiDoom.Audio.Q3.RawStream.pas',
  DelphiDoom.Audio.Q3.RoqSink in '..\Framework\Audio\DelphiDoom.Audio.Q3.RoqSink.pas',
  DelphiDoom.Audio.Q3.Mixer in '..\Framework\Audio\DelphiDoom.Audio.Q3.Mixer.pas',
  DelphiDoom.Audio.Q3.Scheduler in '..\Framework\Audio\DelphiDoom.Audio.Q3.Scheduler.pas',
  DelphiDoom.Audio.Q3.SoundSystem in '..\Framework\Audio\DelphiDoom.Audio.Q3.SoundSystem.pas',
  DelphiDoom.Audio.Q3.Factory in '..\Framework\Audio\DelphiDoom.Audio.Q3.Factory.pas',
  DelphiDoom.Imaging.Types in '..\Framework\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Cinematic.Types in '..\Framework\Cinematic\DelphiDoom.Cinematic.Types.pas',
  DelphiDoom.Cinematic.Intf in '..\Framework\Cinematic\DelphiDoom.Cinematic.Intf.pas',
  DelphiDoom.Sndfile.Intf in '..\Framework\Sndfile\DelphiDoom.Sndfile.Intf.pas',
  DelphiDoom.Sound.Samples in '..\Framework\Sound\DelphiDoom.Sound.Samples.pas',
  DelphiDoom.Sound.Convert in '..\Framework\Sound\DelphiDoom.Sound.Convert.pas',
  DelphiDoom.Sound.Companding in '..\Framework\Sound\DelphiDoom.Sound.Companding.pas',
  DelphiDoom.Sound.ByteReader in '..\Framework\Sound\DelphiDoom.Sound.ByteReader.pas',
  DelphiDoom.Sound.PcmReader in '..\Framework\Sound\DelphiDoom.Sound.PcmReader.pas',
  DelphiDoom.Sound.SoundFile in '..\Framework\Sound\DelphiDoom.Sound.SoundFile.pas',
  DelphiDoom.Sound.Format in '..\Framework\Sound\DelphiDoom.Sound.Format.pas',
  DelphiDoom.Sound.Format.Wav in '..\Framework\Sound\DelphiDoom.Sound.Format.Wav.pas',
  DelphiDoom.Sound.Format.Aiff in '..\Framework\Sound\DelphiDoom.Sound.Format.Aiff.pas',
  DelphiDoom.Sound.Format.Au in '..\Framework\Sound\DelphiDoom.Sound.Format.Au.pas',
  DelphiDoom.Sound.Format.Voc in '..\Framework\Sound\DelphiDoom.Sound.Format.Voc.pas',
  DelphiDoom.Sound.Format.Avr in '..\Framework\Sound\DelphiDoom.Sound.Format.Avr.pas',
  DelphiDoom.Sound.WavLike.Fmt in '..\Framework\Sound\DelphiDoom.Sound.WavLike.Fmt.pas',
  DelphiDoom.Sound.Format.W64 in '..\Framework\Sound\DelphiDoom.Sound.Format.W64.pas',
  DelphiDoom.Sound.Format.Rf64 in '..\Framework\Sound\DelphiDoom.Sound.Format.Rf64.pas',
  DelphiDoom.Sound.Format.Caf in '..\Framework\Sound\DelphiDoom.Sound.Format.Caf.pas',
  DelphiDoom.Sound.Format.Svx in '..\Framework\Sound\DelphiDoom.Sound.Format.Svx.pas',
  DelphiDoom.Sound.Format.Ircam in '..\Framework\Sound\DelphiDoom.Sound.Format.Ircam.pas',
  DelphiDoom.Sound.Format.Mat4 in '..\Framework\Sound\DelphiDoom.Sound.Format.Mat4.pas',
  DelphiDoom.Sound.Format.Mat5 in '..\Framework\Sound\DelphiDoom.Sound.Format.Mat5.pas',
  DelphiDoom.Sound.Format.Wve in '..\Framework\Sound\DelphiDoom.Sound.Format.Wve.pas',
  DelphiDoom.Sound.Format.Mpc2k in '..\Framework\Sound\DelphiDoom.Sound.Format.Mpc2k.pas',
  DelphiDoom.Sound.CodecSamples in '..\Framework\Sound\DelphiDoom.Sound.CodecSamples.pas',
  DelphiDoom.Sound.Codec.MsAdpcm in '..\Framework\Sound\DelphiDoom.Sound.Codec.MsAdpcm.pas',
  DelphiDoom.Sound.Codec.ImaAdpcm in '..\Framework\Sound\DelphiDoom.Sound.Codec.ImaAdpcm.pas',
  DelphiDoom.Sound.Codec.Gsm610 in '..\Framework\Sound\DelphiDoom.Sound.Codec.Gsm610.pas',
  DelphiDoom.Sound.Codec.G72x in '..\Framework\Sound\DelphiDoom.Sound.Codec.G72x.pas',
  DelphiDoom.Sound.Codec.Dwvw in '..\Framework\Sound\DelphiDoom.Sound.Codec.Dwvw.pas',
  DelphiDoom.Sound.Codec.Flac in '..\Framework\Sound\DelphiDoom.Sound.Codec.Flac.pas',
  DelphiDoom.Sound.Format.Flac in '..\Framework\Sound\DelphiDoom.Sound.Format.Flac.pas',
  DelphiDoom.Sound.Vorbis.Types in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Types.pas',
  DelphiDoom.Sound.Vorbis.WindowTables in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.WindowTables.pas',
  DelphiDoom.Sound.Vorbis.Mdct in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Mdct.pas',
  DelphiDoom.Sound.Vorbis.Codebook in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Codebook.pas',
  DelphiDoom.Sound.Vorbis.Floor1 in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Floor1.pas',
  DelphiDoom.Sound.Vorbis.Residue in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Residue.pas',
  DelphiDoom.Sound.Vorbis.Mapping in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Mapping.pas',
  DelphiDoom.Sound.Vorbis.Info in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Info.pas',
  DelphiDoom.Sound.Vorbis.Dsp in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Dsp.pas',
  DelphiDoom.Sound.Vorbis.Length in '..\Framework\Sound\DelphiDoom.Sound.Vorbis.Length.pas',
  DelphiDoom.Sound.Codec.Vorbis in '..\Framework\Sound\DelphiDoom.Sound.Codec.Vorbis.pas',
  DelphiDoom.Sound.Format.Ogg in '..\Framework\Sound\DelphiDoom.Sound.Format.Ogg.pas',
  DelphiDoom.Sound.Format.Paf in '..\Framework\Sound\DelphiDoom.Sound.Format.Paf.pas',
  DelphiDoom.Sound.Format.Sds in '..\Framework\Sound\DelphiDoom.Sound.Format.Sds.pas',
  DelphiDoom.Sound.Format.Xi in '..\Framework\Sound\DelphiDoom.Sound.Format.Xi.pas',
  DelphiDoom.Sound.Format.Htk in '..\Framework\Sound\DelphiDoom.Sound.Format.Htk.pas',
  DelphiDoom.Sound.Engine in '..\Framework\Sound\DelphiDoom.Sound.Engine.pas',
  DelphiDoom.Sound.Factory in '..\Framework\Sound\DelphiDoom.Sound.Factory.pas',
  DelphiDoom.Tests.Audio.Scenarios in 'Source\DelphiDoom.Tests.Audio.Scenarios.pas',
  DelphiDoom.Tests.Audio.WaveParser in 'Source\DelphiDoom.Tests.Audio.WaveParser.pas',
  DelphiDoom.Tests.Audio.MusConverter in 'Source\DelphiDoom.Tests.Audio.MusConverter.pas',
  DelphiDoom.Tests.Audio.Fakes in 'Source\DelphiDoom.Tests.Audio.Fakes.pas',
  DelphiDoom.Tests.Audio.SfxPlayer in 'Source\DelphiDoom.Tests.Audio.SfxPlayer.pas',
  DelphiDoom.Tests.Audio.ExternalMusicCache in 'Source\DelphiDoom.Tests.Audio.ExternalMusicCache.pas',
  DelphiDoom.Tests.Audio.Q3.Fakes in 'Source\DelphiDoom.Tests.Audio.Q3.Fakes.pas',
  DelphiDoom.Tests.Audio.Q3.Parity in 'Source\DelphiDoom.Tests.Audio.Q3.Parity.pas',
  DelphiDoom.Tests.Audio.Q3.Rig in 'Source\DelphiDoom.Tests.Audio.Q3.Rig.pas',
  DelphiDoom.Tests.Audio.Q3.Resampler in 'Source\DelphiDoom.Tests.Audio.Q3.Resampler.pas',
  DelphiDoom.Tests.Audio.Q3.Loader in 'Source\DelphiDoom.Tests.Audio.Q3.Loader.pas',
  DelphiDoom.Tests.Audio.Q3.Listener in 'Source\DelphiDoom.Tests.Audio.Q3.Listener.pas',
  DelphiDoom.Tests.Audio.Q3.ChannelPool in 'Source\DelphiDoom.Tests.Audio.Q3.ChannelPool.pas',
  DelphiDoom.Tests.Audio.Q3.LoopSounds in 'Source\DelphiDoom.Tests.Audio.Q3.LoopSounds.pas',
  DelphiDoom.Tests.Audio.Q3.RawStream in 'Source\DelphiDoom.Tests.Audio.Q3.RawStream.pas',
  DelphiDoom.Tests.Audio.Q3.Mixer in 'Source\DelphiDoom.Tests.Audio.Q3.Mixer.pas',
  DelphiDoom.Tests.Audio.Q3.SoundSystem in 'Source\DelphiDoom.Tests.Audio.Q3.SoundSystem.pas',
  DelphiDoom.Tests.Audio.MusicPlayer in 'Source\DelphiDoom.Tests.Audio.MusicPlayer.pas',
  DelphiDoom.Tests.Scanner.IdFakes in 'Source\DelphiDoom.Tests.Scanner.IdFakes.pas',
  DelphiDoom.Tests.Audio.Efx in 'Source\DelphiDoom.Tests.Audio.Efx.pas',
  DelphiDoom.Tests.Audio.WaveHeader in 'Source\DelphiDoom.Tests.Audio.WaveHeader.pas',
  DelphiDoom.Tests.Audio.WaveFile in 'Source\DelphiDoom.Tests.Audio.WaveFile.pas',
  DelphiDoom.Tests.Audio.WaveFileSystem in 'Source\DelphiDoom.Tests.Audio.WaveFileSystem.pas',
  DelphiDoom.Tests.Audio.WaveFileGolden in 'Source\DelphiDoom.Tests.Audio.WaveFileGolden.pas',
  DelphiDoom.Tests.Audio.SoundSampleCache in 'Source\DelphiDoom.Tests.Audio.SoundSampleCache.pas',
  DelphiDoom.Tests.Audio.D3 in 'Source\DelphiDoom.Tests.Audio.D3.pas',
  DelphiDoom.Tests.Audio.SoundCacheCatalog in 'Source\DelphiDoom.Tests.Audio.SoundCacheCatalog.pas',
  DelphiDoom.AudioMix.Types in '..\Framework\AudioMix\DelphiDoom.AudioMix.Types.pas',
  DelphiDoom.AudioMix.Intf in '..\Framework\AudioMix\DelphiDoom.AudioMix.Intf.pas',
  DelphiDoom.AudioMix.VoiceList in '..\Framework\AudioMix\DelphiDoom.AudioMix.VoiceList.pas',
  DelphiDoom.AudioMix.Saturation in '..\Framework\AudioMix\DelphiDoom.AudioMix.Saturation.pas',
  DelphiDoom.Audio.Mixer.Intf in '..\Framework\Audio\DelphiDoom.Audio.Mixer.Intf.pas',
  DelphiDoom.Audio.Mixer.Gains in '..\Framework\Audio\DelphiDoom.Audio.Mixer.Gains.pas',
  DelphiDoom.Audio.Mixer.Voice in '..\Framework\Audio\DelphiDoom.Audio.Mixer.Voice.pas',
  DelphiDoom.Audio.Mixer in '..\Framework\Audio\DelphiDoom.Audio.Mixer.pas',
  DelphiDoom.GameHost.Audio.Intf in '..\Framework\GameHost\DelphiDoom.GameHost.Audio.Intf.pas',
  DelphiDoom.Engine.Audio.WaveOutDevice in '..\IdTech1\Base\DelphiDoom.Engine.Audio.WaveOutDevice.pas',
  DelphiDoom.Tests.Audio.Mixer.Gains in 'Source\DelphiDoom.Tests.Audio.Mixer.Gains.pas',
  DelphiDoom.Tests.Audio.Mixer in 'Source\DelphiDoom.Tests.Audio.Mixer.pas',
  DelphiDoom.Tests.Audio.WaveOutDevice in 'Source\DelphiDoom.Tests.Audio.WaveOutDevice.pas',
  DelphiDoom.Tests.Audio.OldSound in 'Source\DelphiDoom.Tests.Audio.OldSound.pas',
  DelphiDoom.Tests.Audio.OldMusicNames in 'Source\DelphiDoom.Tests.Audio.OldMusicNames.pas',
  DelphiDoom.Tests.Audio.OldSoundTables in 'Source\DelphiDoom.Tests.Audio.OldSoundTables.pas',
  DelphiDoom.Tests.Audio.MusicNumberResolver in 'Source\DelphiDoom.Tests.Audio.MusicNumberResolver.pas',
  DelphiDoom.Tests.Audio.SfxNumberResolver in 'Source\DelphiDoom.Tests.Audio.SfxNumberResolver.pas',
  DelphiDoom.Tests.Audio.ExternalMusicNames in 'Source\DelphiDoom.Tests.Audio.ExternalMusicNames.pas',
  DelphiDoom.Tests.Audio.SfxAttenuation in 'Source\DelphiDoom.Tests.Audio.SfxAttenuation.pas',
  DelphiDoom.Tests.Audio.ChannelPicker in 'Source\DelphiDoom.Tests.Audio.ChannelPicker.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
