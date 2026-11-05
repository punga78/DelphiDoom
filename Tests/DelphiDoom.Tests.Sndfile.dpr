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
  scanf_c in '..\C_LIB\scanf_c.pas',
  scanf in '..\C_LIB\scanf.pas',
  c_lib in '..\C_LIB\c_lib.pas',
  DelphiDoom.Ogg.Types in '..\Libs\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Libs\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Libs\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Libs\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Libs\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Libs\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Libs\Ogg\DelphiDoom.Ogg.Sync.pas',
  libogg in '..\Libs\Sndfile\Native\libogg.pas',
  libvorbis in '..\Libs\Sndfile\Native\libvorbis.pas',
  libflac in '..\Libs\Sndfile\Native\libflac.pas',
  DelphiDoom.Sndfile.Intf in '..\Libs\Sndfile\DelphiDoom.Sndfile.Intf.pas',
  DelphiDoom.Sndfile.Native in '..\Libs\Sndfile\DelphiDoom.Sndfile.Native.pas',
  DelphiDoom.Sndfile.SoundFile in '..\Libs\Sndfile\DelphiDoom.Sndfile.SoundFile.pas',
  DelphiDoom.Sndfile.Engine in '..\Libs\Sndfile\DelphiDoom.Sndfile.Engine.pas',
  DelphiDoom.Sndfile.Client in '..\Libs\Sndfile\DelphiDoom.Sndfile.Client.pas',
  DelphiDoom.Sndfile.Loader in '..\Libs\Sndfile\DelphiDoom.Sndfile.Loader.pas',
  DelphiDoom.Sndfile.Provider in '..\Libs\Sndfile\DelphiDoom.Sndfile.Provider.pas',
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
  DelphiDoom.Sound.Format.Htk in '..\Libs\Sound\DelphiDoom.Sound.Format.Htk.pas',
  DelphiDoom.Sound.Engine in '..\Libs\Sound\DelphiDoom.Sound.Engine.pas',
  DelphiDoom.Sound.Factory in '..\Libs\Sound\DelphiDoom.Sound.Factory.pas',
  DelphiDoom.Audio.WavBuilder in '..\Base\DelphiDoom.Audio.WavBuilder.pas',
  DelphiDoom.Audio.SoundConverter in '..\Base\DelphiDoom.Audio.SoundConverter.pas',
  DelphiDoom.Tests.Sndfile.Wav in 'Source\DelphiDoom.Tests.Sndfile.Wav.pas',
  DelphiDoom.Tests.Sndfile.Engine in 'Source\DelphiDoom.Tests.Sndfile.Engine.pas',
  DelphiDoom.Tests.Sndfile.Client in 'Source\DelphiDoom.Tests.Sndfile.Client.pas',
  DelphiDoom.Tests.Sndfile.Loader in 'Source\DelphiDoom.Tests.Sndfile.Loader.pas',
  DelphiDoom.Tests.Audio.WavBuilder in 'Source\DelphiDoom.Tests.Audio.WavBuilder.pas',
  DelphiDoom.Tests.Audio.SoundConverter in 'Source\DelphiDoom.Tests.Audio.SoundConverter.pas',
  DelphiDoom.Tests.Sound.WavFile in 'Source\DelphiDoom.Tests.Sound.WavFile.pas',
  DelphiDoom.Tests.Sound.FlacFile in 'Source\DelphiDoom.Tests.Sound.FlacFile.pas',
  DelphiDoom.Tests.Sound.VorbisFile in 'Source\DelphiDoom.Tests.Sound.VorbisFile.pas',
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
