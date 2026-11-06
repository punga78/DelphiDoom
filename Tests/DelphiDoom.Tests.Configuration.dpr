{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the configuration library (DUnitX)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Configuration;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Configuration.Types in '..\Libs\Configuration\DelphiDoom.Configuration.Types.pas',
  DelphiDoom.Configuration.Intf in '..\Libs\Configuration\DelphiDoom.Configuration.Intf.pas',
  DelphiDoom.Configuration.Values in '..\Libs\Configuration\DelphiDoom.Configuration.Values.pas',
  DelphiDoom.Configuration.Document in '..\Libs\Configuration\DelphiDoom.Configuration.Document.pas',
  DelphiDoom.Configuration.Writer in '..\Libs\Configuration\DelphiDoom.Configuration.Writer.pas',
  DelphiDoom.Configuration.Format in '..\Libs\Configuration\DelphiDoom.Configuration.Format.pas',
  DelphiDoom.Configuration.Factory in '..\Libs\Configuration\DelphiDoom.Configuration.Factory.pas',
  DelphiDoom.Tests.Configuration.Values in 'Source\DelphiDoom.Tests.Configuration.Values.pas',
  DelphiDoom.Tests.Configuration.Format in 'Source\DelphiDoom.Tests.Configuration.Format.pas';

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
