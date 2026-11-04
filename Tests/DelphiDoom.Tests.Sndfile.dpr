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
  DelphiDoom.Audio.WavBuilder in '..\Base\DelphiDoom.Audio.WavBuilder.pas',
  DelphiDoom.Audio.SoundConverter in '..\Base\DelphiDoom.Audio.SoundConverter.pas',
  DelphiDoom.Tests.Sndfile.Wav in 'Source\DelphiDoom.Tests.Sndfile.Wav.pas',
  DelphiDoom.Tests.Sndfile.Engine in 'Source\DelphiDoom.Tests.Sndfile.Engine.pas',
  DelphiDoom.Tests.Sndfile.Client in 'Source\DelphiDoom.Tests.Sndfile.Client.pas',
  DelphiDoom.Tests.Sndfile.Loader in 'Source\DelphiDoom.Tests.Sndfile.Loader.pas',
  DelphiDoom.Tests.Audio.WavBuilder in 'Source\DelphiDoom.Tests.Audio.WavBuilder.pas',
  DelphiDoom.Tests.Audio.SoundConverter in 'Source\DelphiDoom.Tests.Audio.SoundConverter.pas';

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
