{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the audio mix library (DUnitX)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.AudioMix;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.AudioMix.Types in '..\Libs\AudioMix\DelphiDoom.AudioMix.Types.pas',
  DelphiDoom.AudioMix.Intf in '..\Libs\AudioMix\DelphiDoom.AudioMix.Intf.pas',
  DelphiDoom.AudioMix.Saturation in '..\Libs\AudioMix\DelphiDoom.AudioMix.Saturation.pas',
  DelphiDoom.AudioMix.VoiceList in '..\Libs\AudioMix\DelphiDoom.AudioMix.VoiceList.pas',
  DelphiDoom.AudioMix.FixedPointResampler in '..\Libs\AudioMix\DelphiDoom.AudioMix.FixedPointResampler.pas',
  DelphiDoom.AudioMix.FramePositionResampler in '..\Libs\AudioMix\DelphiDoom.AudioMix.FramePositionResampler.pas',
  DelphiDoom.AudioMix.UnsignedMonoVoice in '..\Libs\AudioMix\DelphiDoom.AudioMix.UnsignedMonoVoice.pas',
  DelphiDoom.AudioMix.StereoChannelVoice in '..\Libs\AudioMix\DelphiDoom.AudioMix.StereoChannelVoice.pas',
  DelphiDoom.AudioMix.NearestRateVoice in '..\Libs\AudioMix\DelphiDoom.AudioMix.NearestRateVoice.pas',
  DelphiDoom.Tests.AudioMix.Support in 'Source\DelphiDoom.Tests.AudioMix.Support.pas',
  DelphiDoom.Tests.AudioMix.LegacyWaveVoice in 'Source\DelphiDoom.Tests.AudioMix.LegacyWaveVoice.pas',
  DelphiDoom.Tests.AudioMix.LegacyFixedPointResampler in 'Source\DelphiDoom.Tests.AudioMix.LegacyFixedPointResampler.pas',
  DelphiDoom.Tests.AudioMix.LegacyFramePositionResampler in 'Source\DelphiDoom.Tests.AudioMix.LegacyFramePositionResampler.pas',
  DelphiDoom.Tests.AudioMix.Saturation in 'Source\DelphiDoom.Tests.AudioMix.Saturation.pas',
  DelphiDoom.Tests.AudioMix.VoiceList in 'Source\DelphiDoom.Tests.AudioMix.VoiceList.pas',
  DelphiDoom.Tests.AudioMix.FixedPointResampler in 'Source\DelphiDoom.Tests.AudioMix.FixedPointResampler.pas',
  DelphiDoom.Tests.AudioMix.FramePositionResampler in 'Source\DelphiDoom.Tests.AudioMix.FramePositionResampler.pas',
  DelphiDoom.Tests.AudioMix.UnsignedMonoVoice in 'Source\DelphiDoom.Tests.AudioMix.UnsignedMonoVoice.pas',
  DelphiDoom.Tests.AudioMix.StereoChannelVoice in 'Source\DelphiDoom.Tests.AudioMix.StereoChannelVoice.pas',
  DelphiDoom.Tests.AudioMix.NearestRateVoice in 'Source\DelphiDoom.Tests.AudioMix.NearestRateVoice.pas';

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
