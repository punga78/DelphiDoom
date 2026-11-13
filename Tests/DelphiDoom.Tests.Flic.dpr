{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the flic library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Flic;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Flic.Types in '..\Libs\Flic\DelphiDoom.Flic.Types.pas',
  DelphiDoom.Flic.FrameDecoder in '..\Libs\Flic\DelphiDoom.Flic.FrameDecoder.pas',
  DelphiDoom.Tests.XcomEngine.FlcBuilder in 'Source\DelphiDoom.Tests.XcomEngine.FlcBuilder.pas',
  DelphiDoom.Tests.Flic.XcomReference in 'Source\DelphiDoom.Tests.Flic.XcomReference.pas',
  DelphiDoom.Tests.Flic.FrameDecoder in 'Source\DelphiDoom.Tests.Flic.FrameDecoder.pas';

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
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
