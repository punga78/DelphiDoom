{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the id Tech library (DUnitX)                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.IdTech;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.IdTech.Types in '..\IdTech1\IdTech\DelphiDoom.IdTech.Types.pas',
  DelphiDoom.IdTech.Intf in '..\IdTech1\IdTech\DelphiDoom.IdTech.Intf.pas',
  DelphiDoom.IdTech.Engine in '..\IdTech1\IdTech\DelphiDoom.IdTech.Engine.pas',
  DelphiDoom.IdTech.Factory in '..\IdTech1\IdTech\DelphiDoom.IdTech.Factory.pas',
  DelphiDoom.Tests.IdTech.Types in 'Source\DelphiDoom.Tests.IdTech.Types.pas',
  DelphiDoom.Tests.IdTech.Engine in 'Source\DelphiDoom.Tests.IdTech.Engine.pas';

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
