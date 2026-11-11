{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ufopaedia library (DUnitX)                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomUfopaedia;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.XcomEngine.World in 'Source\DelphiDoom.Tests.XcomEngine.World.pas',
  DelphiDoom.Tests.XcomGeoscape.World in 'Source\DelphiDoom.Tests.XcomGeoscape.World.pas',
  DelphiDoom.Tests.XcomUfopaedia.Fakes in 'Source\DelphiDoom.Tests.XcomUfopaedia.Fakes.pas',
  DelphiDoom.Tests.XcomUfopaedia.Catalog in 'Source\DelphiDoom.Tests.XcomUfopaedia.Catalog.pas',
  DelphiDoom.Tests.XcomUfopaedia.ArticleFormat in 'Source\DelphiDoom.Tests.XcomUfopaedia.ArticleFormat.pas',
  DelphiDoom.Tests.XcomUfopaedia.Screens in 'Source\DelphiDoom.Tests.XcomUfopaedia.Screens.pas',
  DelphiDoom.Tests.XcomUfopaedia.RealData in 'Source\DelphiDoom.Tests.XcomUfopaedia.RealData.pas';

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

