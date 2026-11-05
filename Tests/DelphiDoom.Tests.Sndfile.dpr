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
  DelphiDoom.Sound.SoundFile in '..\Libs\Sound\DelphiDoom.Sound.SoundFile.pas',
  DelphiDoom.Sound.Format in '..\Libs\Sound\DelphiDoom.Sound.Format.pas',
  DelphiDoom.Sound.Format.Wav in '..\Libs\Sound\DelphiDoom.Sound.Format.Wav.pas',
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
