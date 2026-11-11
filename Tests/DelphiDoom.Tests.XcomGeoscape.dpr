{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom geoscape library (DUnitX)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomGeoscape;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.XcomGeoscape.World in 'Source\DelphiDoom.Tests.XcomGeoscape.World.pas',
  DelphiDoom.Tests.XcomGeoscape.GameRules in 'Source\DelphiDoom.Tests.XcomGeoscape.GameRules.pas',
  DelphiDoom.Tests.XcomGeoscape.Host in 'Source\DelphiDoom.Tests.XcomGeoscape.Host.pas',
  DelphiDoom.Tests.XcomGeoscape.Funding in 'Source\DelphiDoom.Tests.XcomGeoscape.Funding.pas',
  DelphiDoom.Tests.XcomGeoscape.BaseViewParity in 'Source\DelphiDoom.Tests.XcomGeoscape.BaseViewParity.pas',
  DelphiDoom.Tests.XcomGeoscape.GlobeParity in 'Source\DelphiDoom.Tests.XcomGeoscape.GlobeParity.pas',
  DelphiDoom.Tests.XcomGeoscape.Globe in 'Source\DelphiDoom.Tests.XcomGeoscape.Globe.pas',
  DelphiDoom.Tests.XcomBasescape.Names in 'Source\DelphiDoom.Tests.XcomBasescape.Names.pas',
  DelphiDoom.Tests.XcomEngine.World in 'Source\DelphiDoom.Tests.XcomEngine.World.pas',
  DelphiDoom.Tests.XcomGeoscape.Popups in 'Source\DelphiDoom.Tests.XcomGeoscape.Popups.pas';

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

