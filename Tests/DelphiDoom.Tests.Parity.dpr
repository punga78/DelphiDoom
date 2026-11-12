{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the parity library (DUnitX)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Parity;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Clock.Intf in '..\Libs\Clock\DelphiDoom.Clock.Intf.pas',
  DelphiDoom.Clock.ManualClock in '..\Libs\Clock\DelphiDoom.Clock.ManualClock.pas',
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.Parity.Types in '..\Libs\Parity\DelphiDoom.Parity.Types.pas',
  DelphiDoom.Parity.Hasher in '..\Libs\Parity\DelphiDoom.Parity.Hasher.pas',
  DelphiDoom.Parity.Intf in '..\Libs\Parity\DelphiDoom.Parity.Intf.pas',
  DelphiDoom.Parity.StateHashWriter in '..\Libs\Parity\DelphiDoom.Parity.StateHashWriter.pas',
  DelphiDoom.Parity.FileLog in '..\Libs\Parity\DelphiDoom.Parity.FileLog.pas',
  DelphiDoom.Parity.FrameHashWriter in '..\Libs\Parity\DelphiDoom.Parity.FrameHashWriter.pas',
  DelphiDoom.Parity.BitmapWriter in '..\Libs\Parity\DelphiDoom.Parity.BitmapWriter.pas',
  DelphiDoom.Parity.OptionsParser in '..\Libs\Parity\DelphiDoom.Parity.OptionsParser.pas',
  DelphiDoom.Parity.Random in '..\Libs\Parity\DelphiDoom.Parity.Random.pas',
  DelphiDoom.Parity.Pilot in '..\Libs\Parity\DelphiDoom.Parity.Pilot.pas',
  DelphiDoom.Parity.VirtualClock in '..\Libs\Parity\DelphiDoom.Parity.VirtualClock.pas',
  DelphiDoom.Parity.SwitchClock in '..\Libs\Parity\DelphiDoom.Parity.SwitchClock.pas',
  DelphiDoom.Parity.SwitchEntropy in '..\Libs\Parity\DelphiDoom.Parity.SwitchEntropy.pas',
  DelphiDoom.Parity.LogComparer in '..\Libs\Parity\DelphiDoom.Parity.LogComparer.pas',
  DelphiDoom.Parity.Factory in '..\Libs\Parity\DelphiDoom.Parity.Factory.pas',
  DelphiDoom.Tests.Parity.Fakes in 'Source\DelphiDoom.Tests.Parity.Fakes.pas',
  DelphiDoom.Tests.Parity.Hasher in 'Source\DelphiDoom.Tests.Parity.Hasher.pas',
  DelphiDoom.Tests.Parity.StateHashWriter in 'Source\DelphiDoom.Tests.Parity.StateHashWriter.pas',
  DelphiDoom.Tests.Parity.FileLog in 'Source\DelphiDoom.Tests.Parity.FileLog.pas',
  DelphiDoom.Tests.Parity.FrameHashWriter in 'Source\DelphiDoom.Tests.Parity.FrameHashWriter.pas',
  DelphiDoom.Tests.Parity.BitmapWriter in 'Source\DelphiDoom.Tests.Parity.BitmapWriter.pas',
  DelphiDoom.Tests.Parity.OptionsParser in 'Source\DelphiDoom.Tests.Parity.OptionsParser.pas',
  DelphiDoom.Tests.Parity.Random in 'Source\DelphiDoom.Tests.Parity.Random.pas',
  DelphiDoom.Tests.Parity.Pilot in 'Source\DelphiDoom.Tests.Parity.Pilot.pas',
  DelphiDoom.Tests.Parity.VirtualClock in 'Source\DelphiDoom.Tests.Parity.VirtualClock.pas',
  DelphiDoom.Tests.Parity.SwitchClock in 'Source\DelphiDoom.Tests.Parity.SwitchClock.pas',
  DelphiDoom.Tests.Parity.SwitchEntropy in 'Source\DelphiDoom.Tests.Parity.SwitchEntropy.pas',
  DelphiDoom.Tests.Parity.LogComparer in 'Source\DelphiDoom.Tests.Parity.LogComparer.pas',
  DelphiDoom.Tests.Parity.Factory in 'Source\DelphiDoom.Tests.Parity.Factory.pas';

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
