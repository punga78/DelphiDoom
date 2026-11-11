{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom battlescape states library (DUnitX)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomBattleStates;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.XcomMod.DiskModFiles in 'Source\DelphiDoom.Tests.XcomMod.DiskModFiles.pas',
  DelphiDoom.Tests.XcomMod.RealData in 'Source\DelphiDoom.Tests.XcomMod.RealData.pas',
  DelphiDoom.Tests.XcomEngine.World in 'Source\DelphiDoom.Tests.XcomEngine.World.pas',
  DelphiDoom.Tests.XcomBattleStates.Bench in 'Source\DelphiDoom.Tests.XcomBattleStates.Bench.pas',
  DelphiDoom.Tests.XcomBattleStates.BattlescapeState in 'Source\DelphiDoom.Tests.XcomBattleStates.BattlescapeState.pas',
  DelphiDoom.Tests.XcomBattleStates.TurnScreens in 'Source\DelphiDoom.Tests.XcomBattleStates.TurnScreens.pas',
  DelphiDoom.Tests.XcomBattleStates.MixerAudio in 'Source\DelphiDoom.Tests.XcomBattleStates.MixerAudio.pas',
  DelphiDoom.Tests.XcomBattleStates.WarningMessage in 'Source\DelphiDoom.Tests.XcomBattleStates.WarningMessage.pas',
  DelphiDoom.Tests.XcomBattleStates.BattleWorld in 'Source\DelphiDoom.Tests.XcomBattleStates.BattleWorld.pas',
  DelphiDoom.Tests.XcomBattleStates.UnitInfoState in 'Source\DelphiDoom.Tests.XcomBattleStates.UnitInfoState.pas',
  DelphiDoom.Tests.XcomBattleStates.MiniMapView in 'Source\DelphiDoom.Tests.XcomBattleStates.MiniMapView.pas',
  DelphiDoom.Tests.XcomBattleStates.MiniMapState in 'Source\DelphiDoom.Tests.XcomBattleStates.MiniMapState.pas',
  DelphiDoom.Tests.XcomBattleStates.AbortMissionState in 'Source\DelphiDoom.Tests.XcomBattleStates.AbortMissionState.pas';

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
