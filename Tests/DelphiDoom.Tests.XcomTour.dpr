{******************************************************************************}
{                                                                              }
{  DelphiDoom: tour of the strategic game of OpenXcom (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomTour;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Xcom.GameComposition in '..\OpenXcom\DelphiDoom.Xcom.GameComposition.pas',
  DelphiDoom.Xcom.GeoscapeNavigator in '..\OpenXcom\DelphiDoom.Xcom.GeoscapeNavigator.pas',
  DelphiDoom.Tests.XcomEngine.World in 'Source\DelphiDoom.Tests.XcomEngine.World.pas',
  DelphiDoom.Tests.XcomGeoscape.Popups in 'Source\DelphiDoom.Tests.XcomGeoscape.Popups.pas',
  DelphiDoom.Tests.XcomGeoscape.MonthlyReportState in 'Source\DelphiDoom.Tests.XcomGeoscape.MonthlyReportState.pas',
  DelphiDoom.Tests.XcomGeoscape.MissionLauncher in 'Source\DelphiDoom.Tests.XcomGeoscape.MissionLauncher.pas',
  DelphiDoom.Tests.XcomTour.World in 'Source\DelphiDoom.Tests.XcomTour.World.pas',
  DelphiDoom.Tests.XcomTour.Strategy in 'Source\DelphiDoom.Tests.XcomTour.Strategy.pas',
  DelphiDoom.Tests.XcomTour.Flows in 'Source\DelphiDoom.Tests.XcomTour.Flows.pas',
  DelphiDoom.Tests.XcomTour.Missions in 'Source\DelphiDoom.Tests.XcomTour.Missions.pas',
  DelphiDoom.Xcom.NewBattleNavigator in '..\OpenXcom\DelphiDoom.Xcom.NewBattleNavigator.pas',
  DelphiDoom.Tests.XcomTour.NewBattle in 'Source\DelphiDoom.Tests.XcomTour.NewBattle.pas',
  DelphiDoom.Tests.XcomTour.CustomBase in 'Source\DelphiDoom.Tests.XcomTour.CustomBase.pas',
  DelphiDoom.Tests.XcomTour.Demolition in 'Source\DelphiDoom.Tests.XcomTour.Demolition.pas',
  DelphiDoom.Tests.XcomTour.Dogfight in 'Source\DelphiDoom.Tests.XcomTour.Dogfight.pas',
  DelphiDoom.Tests.XcomTour.Globe in 'Source\DelphiDoom.Tests.XcomTour.Globe.pas',
  DelphiDoom.Tests.XcomTour.Hangar in 'Source\DelphiDoom.Tests.XcomTour.Hangar.pas',
  DelphiDoom.Tests.XcomTour.Barracks in 'Source\DelphiDoom.Tests.XcomTour.Barracks.pas',
  DelphiDoom.Tests.XcomTour.Ironman in 'Source\DelphiDoom.Tests.XcomTour.Ironman.pas',
  DelphiDoom.Tests.XcomTour.Trade in 'Source\DelphiDoom.Tests.XcomTour.Trade.pas',
  DelphiDoom.Tests.XcomTour.Workshop in 'Source\DelphiDoom.Tests.XcomTour.Workshop.pas',
  DelphiDoom.Xcom.MemoryCount in '..\OpenXcom\DelphiDoom.Xcom.MemoryCount.pas',
  DelphiDoom.Tests.XcomTour.Memory in 'Source\DelphiDoom.Tests.XcomTour.Memory.pas';

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

