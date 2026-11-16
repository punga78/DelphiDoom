{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Sndfile library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Sndfile;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Ogg.Types in '..\Framework\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Framework\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Framework\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Framework\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Framework\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Framework\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Framework\Ogg\DelphiDoom.Ogg.Sync.pas',
  DelphiDoom.Sndfile.Intf in '..\Framework\Sndfile\DelphiDoom.Sndfile.Intf.pas',
  DelphiDoom.Audio.WaveFile.Types in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.Types.pas',
  DelphiDoom.Audio.WaveFile.Intf in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.Intf.pas',
  DelphiDoom.Audio.WaveFile.SoundOggDecoder in '..\Framework\Audio\DelphiDoom.Audio.WaveFile.SoundOggDecoder.pas',
  DelphiDoom.Sndfile.Client in '..\Framework\Sndfile\DelphiDoom.Sndfile.Client.pas',
  DelphiDoom.Sndfile.Loader in '..\Framework\Sndfile\DelphiDoom.Sndfile.Loader.pas',
  DelphiDoom.Sndfile.Factory.Intf in '..\Framework\Sndfile\DelphiDoom.Sndfile.Factory.Intf.pas',
  DelphiDoom.Sndfile.Provider in '..\Framework\Sndfile\DelphiDoom.Sndfile.Provider.pas',
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
  DelphiDoom.Sound.EngineFactory in '..\Framework\Sound\DelphiDoom.Sound.EngineFactory.pas',
  DelphiDoom.Audio.WavBuilder in '..\Base\DelphiDoom.Audio.WavBuilder.pas',
  DelphiDoom.Audio.SoundConverter in '..\Base\DelphiDoom.Audio.SoundConverter.pas',
  DelphiDoom.Tests.Sndfile.Wav in 'Source\DelphiDoom.Tests.Sndfile.Wav.pas',
  DelphiDoom.Tests.Sndfile.Engine in 'Source\DelphiDoom.Tests.Sndfile.Engine.pas',
  DelphiDoom.Tests.Sndfile.FakeSound in 'Source\DelphiDoom.Tests.Sndfile.FakeSound.pas',
  DelphiDoom.Tests.Sndfile.Exception in 'Source\DelphiDoom.Tests.Sndfile.Exception.pas',
  DelphiDoom.Tests.Sndfile.Client in 'Source\DelphiDoom.Tests.Sndfile.Client.pas',
  DelphiDoom.Tests.Sndfile.Loader in 'Source\DelphiDoom.Tests.Sndfile.Loader.pas',
  DelphiDoom.Tests.Audio.WavBuilder in 'Source\DelphiDoom.Tests.Audio.WavBuilder.pas',
  DelphiDoom.Tests.Audio.SoundConverter in 'Source\DelphiDoom.Tests.Audio.SoundConverter.pas',
  DelphiDoom.Tests.Sound.WavFile in 'Source\DelphiDoom.Tests.Sound.WavFile.pas',
  DelphiDoom.Tests.Sound.FlacFile in 'Source\DelphiDoom.Tests.Sound.FlacFile.pas',
  DelphiDoom.Tests.Sound.VorbisFile in 'Source\DelphiDoom.Tests.Sound.VorbisFile.pas',
  DelphiDoom.Tests.Audio.WaveOggDecoder in 'Source\DelphiDoom.Tests.Audio.WaveOggDecoder.pas',
  DelphiDoom.Tests.Sound.PafFile in 'Source\DelphiDoom.Tests.Sound.PafFile.pas',
  DelphiDoom.Tests.Sound.SdsFile in 'Source\DelphiDoom.Tests.Sound.SdsFile.pas',
  DelphiDoom.Tests.Sound.XiFile in 'Source\DelphiDoom.Tests.Sound.XiFile.pas',
  DelphiDoom.Tests.Sound.Digest in 'Source\DelphiDoom.Tests.Sound.Digest.pas',
  DelphiDoom.Tests.Sound.Golden in 'Source\DelphiDoom.Tests.Sound.Golden.pas',
  DelphiDoom.Tests.Sound.ContainerFiles in 'Source\DelphiDoom.Tests.Sound.ContainerFiles.pas',
  DelphiDoom.Tests.Sound.Parity in 'Source\DelphiDoom.Tests.Sound.Parity.pas';

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
