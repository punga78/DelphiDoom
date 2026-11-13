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
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Audio.Types in '..\Libs\Audio\DelphiDoom.Audio.Types.pas',
  DelphiDoom.Audio.Intf in '..\Libs\Audio\DelphiDoom.Audio.Intf.pas',
  DelphiDoom.Audio.Levels in '..\Libs\Audio\DelphiDoom.Audio.Levels.pas',
  DelphiDoom.Audio.SfxPlayer in '..\Libs\Audio\DelphiDoom.Audio.SfxPlayer.pas',
  DelphiDoom.Audio.MusicPlayer in '..\Libs\Audio\DelphiDoom.Audio.MusicPlayer.pas',
  DelphiDoom.Audio.ExternalMusicCache in '..\Libs\Audio\DelphiDoom.Audio.ExternalMusicCache.pas',
  DelphiDoom.Audio.Factory in '..\Libs\Audio\DelphiDoom.Audio.Factory.pas',
  DelphiDoom.Audio.SoundParameters in '..\Libs\Audio\DelphiDoom.Audio.SoundParameters.pas',
  DelphiDoom.Audio.WaveParser in '..\Libs\Audio\DelphiDoom.Audio.WaveParser.pas',
  DelphiDoom.Audio.MusConverter in '..\Libs\Audio\DelphiDoom.Audio.MusConverter.pas',
  DelphiDoom.Ogg.Types in '..\Libs\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Libs\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Libs\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Libs\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Libs\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Libs\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Libs\Ogg\DelphiDoom.Ogg.Sync.pas',
  DelphiDoom.Audio.Q3.Sfx in '..\Libs\Audio\DelphiDoom.Audio.Q3.Sfx.pas',
  DelphiDoom.Audio.Q3.Types in '..\Libs\Audio\DelphiDoom.Audio.Q3.Types.pas',
  DelphiDoom.Audio.Q3.Intf in '..\Libs\Audio\DelphiDoom.Audio.Q3.Intf.pas',
  DelphiDoom.Audio.Q3.State in '..\Libs\Audio\DelphiDoom.Audio.Q3.State.pas',
  DelphiDoom.Audio.Q3.Resampler in '..\Libs\Audio\DelphiDoom.Audio.Q3.Resampler.pas',
  DelphiDoom.Audio.Q3.Loader in '..\Libs\Audio\DelphiDoom.Audio.Q3.Loader.pas',
  DelphiDoom.Audio.Q3.SfxRegistry in '..\Libs\Audio\DelphiDoom.Audio.Q3.SfxRegistry.pas',
  DelphiDoom.Audio.Q3.Listener in '..\Libs\Audio\DelphiDoom.Audio.Q3.Listener.pas',
  DelphiDoom.Audio.Q3.ChannelPool in '..\Libs\Audio\DelphiDoom.Audio.Q3.ChannelPool.pas',
  DelphiDoom.Audio.Q3.LoopSounds in '..\Libs\Audio\DelphiDoom.Audio.Q3.LoopSounds.pas',
  DelphiDoom.Audio.Q3.RawStream in '..\Libs\Audio\DelphiDoom.Audio.Q3.RawStream.pas',
  DelphiDoom.Audio.Q3.RoqSink in '..\Libs\Audio\DelphiDoom.Audio.Q3.RoqSink.pas',
  DelphiDoom.Audio.Q3.Mixer in '..\Libs\Audio\DelphiDoom.Audio.Q3.Mixer.pas',
  DelphiDoom.Audio.Q3.Scheduler in '..\Libs\Audio\DelphiDoom.Audio.Q3.Scheduler.pas',
  DelphiDoom.Audio.Q3.SoundSystem in '..\Libs\Audio\DelphiDoom.Audio.Q3.SoundSystem.pas',
  DelphiDoom.Audio.Q3.Factory in '..\Libs\Audio\DelphiDoom.Audio.Q3.Factory.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Cinematic.Types in '..\Libs\Cinematic\DelphiDoom.Cinematic.Types.pas',
  DelphiDoom.Cinematic.Intf in '..\Libs\Cinematic\DelphiDoom.Cinematic.Intf.pas',
  DelphiDoom.Sndfile.Intf in '..\Libs\Sndfile\DelphiDoom.Sndfile.Intf.pas',
  DelphiDoom.Sound.Samples in '..\Libs\Sound\DelphiDoom.Sound.Samples.pas',
  DelphiDoom.Sound.Convert in '..\Libs\Sound\DelphiDoom.Sound.Convert.pas',
  DelphiDoom.Sound.Companding in '..\Libs\Sound\DelphiDoom.Sound.Companding.pas',
  DelphiDoom.Sound.ByteReader in '..\Libs\Sound\DelphiDoom.Sound.ByteReader.pas',
  DelphiDoom.Sound.PcmReader in '..\Libs\Sound\DelphiDoom.Sound.PcmReader.pas',
  DelphiDoom.Sound.SoundFile in '..\Libs\Sound\DelphiDoom.Sound.SoundFile.pas',
  DelphiDoom.Sound.Format in '..\Libs\Sound\DelphiDoom.Sound.Format.pas',
  DelphiDoom.Sound.Format.Wav in '..\Libs\Sound\DelphiDoom.Sound.Format.Wav.pas',
  DelphiDoom.Sound.Format.Aiff in '..\Libs\Sound\DelphiDoom.Sound.Format.Aiff.pas',
  DelphiDoom.Sound.Format.Au in '..\Libs\Sound\DelphiDoom.Sound.Format.Au.pas',
  DelphiDoom.Sound.Format.Voc in '..\Libs\Sound\DelphiDoom.Sound.Format.Voc.pas',
  DelphiDoom.Sound.Format.Avr in '..\Libs\Sound\DelphiDoom.Sound.Format.Avr.pas',
  DelphiDoom.Sound.WavLike.Fmt in '..\Libs\Sound\DelphiDoom.Sound.WavLike.Fmt.pas',
  DelphiDoom.Sound.Format.W64 in '..\Libs\Sound\DelphiDoom.Sound.Format.W64.pas',
  DelphiDoom.Sound.Format.Rf64 in '..\Libs\Sound\DelphiDoom.Sound.Format.Rf64.pas',
  DelphiDoom.Sound.Format.Caf in '..\Libs\Sound\DelphiDoom.Sound.Format.Caf.pas',
  DelphiDoom.Sound.Format.Svx in '..\Libs\Sound\DelphiDoom.Sound.Format.Svx.pas',
  DelphiDoom.Sound.Format.Ircam in '..\Libs\Sound\DelphiDoom.Sound.Format.Ircam.pas',
  DelphiDoom.Sound.Format.Mat4 in '..\Libs\Sound\DelphiDoom.Sound.Format.Mat4.pas',
  DelphiDoom.Sound.Format.Mat5 in '..\Libs\Sound\DelphiDoom.Sound.Format.Mat5.pas',
  DelphiDoom.Sound.Format.Wve in '..\Libs\Sound\DelphiDoom.Sound.Format.Wve.pas',
  DelphiDoom.Sound.Format.Mpc2k in '..\Libs\Sound\DelphiDoom.Sound.Format.Mpc2k.pas',
  DelphiDoom.Sound.CodecSamples in '..\Libs\Sound\DelphiDoom.Sound.CodecSamples.pas',
  DelphiDoom.Sound.Codec.MsAdpcm in '..\Libs\Sound\DelphiDoom.Sound.Codec.MsAdpcm.pas',
  DelphiDoom.Sound.Codec.ImaAdpcm in '..\Libs\Sound\DelphiDoom.Sound.Codec.ImaAdpcm.pas',
  DelphiDoom.Sound.Codec.Gsm610 in '..\Libs\Sound\DelphiDoom.Sound.Codec.Gsm610.pas',
  DelphiDoom.Sound.Codec.G72x in '..\Libs\Sound\DelphiDoom.Sound.Codec.G72x.pas',
  DelphiDoom.Sound.Codec.Dwvw in '..\Libs\Sound\DelphiDoom.Sound.Codec.Dwvw.pas',
  DelphiDoom.Sound.Codec.Flac in '..\Libs\Sound\DelphiDoom.Sound.Codec.Flac.pas',
  DelphiDoom.Sound.Format.Flac in '..\Libs\Sound\DelphiDoom.Sound.Format.Flac.pas',
  DelphiDoom.Sound.Vorbis.Types in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Types.pas',
  DelphiDoom.Sound.Vorbis.WindowTables in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.WindowTables.pas',
  DelphiDoom.Sound.Vorbis.Mdct in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Mdct.pas',
  DelphiDoom.Sound.Vorbis.Codebook in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Codebook.pas',
  DelphiDoom.Sound.Vorbis.Floor1 in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Floor1.pas',
  DelphiDoom.Sound.Vorbis.Residue in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Residue.pas',
  DelphiDoom.Sound.Vorbis.Mapping in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Mapping.pas',
  DelphiDoom.Sound.Vorbis.Info in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Info.pas',
  DelphiDoom.Sound.Vorbis.Dsp in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Dsp.pas',
  DelphiDoom.Sound.Vorbis.Length in '..\Libs\Sound\DelphiDoom.Sound.Vorbis.Length.pas',
  DelphiDoom.Sound.Codec.Vorbis in '..\Libs\Sound\DelphiDoom.Sound.Codec.Vorbis.pas',
  DelphiDoom.Sound.Format.Ogg in '..\Libs\Sound\DelphiDoom.Sound.Format.Ogg.pas',
  DelphiDoom.Sound.Format.Paf in '..\Libs\Sound\DelphiDoom.Sound.Format.Paf.pas',
  DelphiDoom.Sound.Format.Sds in '..\Libs\Sound\DelphiDoom.Sound.Format.Sds.pas',
  DelphiDoom.Sound.Format.Xi in '..\Libs\Sound\DelphiDoom.Sound.Format.Xi.pas',
  DelphiDoom.Sound.Format.Htk in '..\Libs\Sound\DelphiDoom.Sound.Format.Htk.pas',
  DelphiDoom.Sound.Engine in '..\Libs\Sound\DelphiDoom.Sound.Engine.pas',
  DelphiDoom.Sound.Factory in '..\Libs\Sound\DelphiDoom.Sound.Factory.pas',
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
  DelphiDoom.Tests.Audio.MusicPlayer in 'Source\DelphiDoom.Tests.Audio.MusicPlayer.pas';

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
