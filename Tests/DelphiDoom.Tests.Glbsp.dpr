{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Glbsp library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Glbsp;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Intf in '..\Libs\Glbsp\DelphiDoom.Glbsp.Intf.pas',
  DelphiDoom.Glbsp.Executable in '..\Libs\Glbsp\DelphiDoom.Glbsp.Executable.pas',
  DelphiDoom.Glbsp.Runner in '..\Libs\Glbsp\DelphiDoom.Glbsp.Runner.pas',
  DelphiDoom.Glbsp.Engine in '..\Libs\Glbsp\DelphiDoom.Glbsp.Engine.pas',
  DelphiDoom.Glbsp.Client in '..\Libs\Glbsp\DelphiDoom.Glbsp.Client.pas',
  DelphiDoom.Glbsp.Loader in '..\Libs\Glbsp\DelphiDoom.Glbsp.Loader.pas',
  DelphiDoom.Tests.Glbsp.Executable in 'Source\DelphiDoom.Tests.Glbsp.Executable.pas',
  DelphiDoom.Tests.Glbsp.Runner in 'Source\DelphiDoom.Tests.Glbsp.Runner.pas',
  DelphiDoom.Tests.Glbsp.Engine in 'Source\DelphiDoom.Tests.Glbsp.Engine.pas',
  DelphiDoom.Tests.Glbsp.Client in 'Source\DelphiDoom.Tests.Glbsp.Client.pas',
  DelphiDoom.Tests.Glbsp.Loader in 'Source\DelphiDoom.Tests.Glbsp.Loader.pas';

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
