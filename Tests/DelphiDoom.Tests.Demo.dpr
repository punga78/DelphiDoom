{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the demo library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Demo;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Demo.Types in '..\IdTech1\Demo\DelphiDoom.Demo.Types.pas',
  DelphiDoom.Demo.Profiles in '..\IdTech1\Demo\DelphiDoom.Demo.Profiles.pas',
  DelphiDoom.Demo.HeaderCodec in '..\IdTech1\Demo\DelphiDoom.Demo.HeaderCodec.pas',
  DelphiDoom.Demo.CommandCodec in '..\IdTech1\Demo\DelphiDoom.Demo.CommandCodec.pas',
  DelphiDoom.Demo.DeathTrimmer in '..\IdTech1\Demo\DelphiDoom.Demo.DeathTrimmer.pas',
  DelphiDoom.Tests.Demo.HeaderCodec in 'Source\DelphiDoom.Tests.Demo.HeaderCodec.pas',
  DelphiDoom.Tests.Demo.CommandCodec in 'Source\DelphiDoom.Tests.Demo.CommandCodec.pas',
  DelphiDoom.Tests.Demo.DeathTrimmer in 'Source\DelphiDoom.Tests.Demo.DeathTrimmer.pas';

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
