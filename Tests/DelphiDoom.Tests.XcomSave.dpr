{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom saved game library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Games\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomSave;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.XcomMod.Types in '..\Games\XcomMod\DelphiDoom.XcomMod.Types.pas',
  DelphiDoom.XcomMod.Random in '..\Games\XcomMod\DelphiDoom.XcomMod.Random.pas',
  DelphiDoom.XcomMod.NodeReader in '..\Games\XcomMod\DelphiDoom.XcomMod.NodeReader.pas',
  DelphiDoom.XcomMod.Areas in '..\Games\XcomMod\DelphiDoom.XcomMod.Areas.pas',
  DelphiDoom.XcomMod.WeightedOptions in '..\Games\XcomMod\DelphiDoom.XcomMod.WeightedOptions.pas',
  DelphiDoom.XcomMod.RuleCountry in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleCountry.pas',
  DelphiDoom.XcomMod.RuleRegion in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleRegion.pas',
  DelphiDoom.XcomMod.RuleResearch in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleResearch.pas',
  DelphiDoom.XcomSave.NodeWriter in '..\Games\XcomSave\DelphiDoom.XcomSave.NodeWriter.pas',
  DelphiDoom.XcomSave.GameTime in '..\Games\XcomSave\DelphiDoom.XcomSave.GameTime.pas',
  DelphiDoom.XcomSave.Country in '..\Games\XcomSave\DelphiDoom.XcomSave.Country.pas',
  DelphiDoom.XcomSave.Region in '..\Games\XcomSave\DelphiDoom.XcomSave.Region.pas',
  DelphiDoom.XcomSave.ResearchProject in '..\Games\XcomSave\DelphiDoom.XcomSave.ResearchProject.pas',
  DelphiDoom.XcomSave.Serialization in '..\Games\XcomSave\DelphiDoom.XcomSave.Serialization.pas',
  DelphiDoom.XcomMod.MapBlock in '..\Games\XcomMod\DelphiDoom.XcomMod.MapBlock.pas',
  DelphiDoom.XcomSave.Types in '..\Games\XcomSave\DelphiDoom.XcomSave.Types.pas',
  DelphiDoom.XcomSave.Rules.Intf in '..\Games\XcomSave\DelphiDoom.XcomSave.Rules.Intf.pas',
  DelphiDoom.XcomSave.PositionCodec in '..\Games\XcomSave\DelphiDoom.XcomSave.PositionCodec.pas',
  DelphiDoom.XcomSave.Target in '..\Games\XcomSave\DelphiDoom.XcomSave.Target.pas',
  DelphiDoom.XcomSave.Waypoint in '..\Games\XcomSave\DelphiDoom.XcomSave.Waypoint.pas',
  DelphiDoom.XcomSave.AlienBase in '..\Games\XcomSave\DelphiDoom.XcomSave.AlienBase.pas',
  DelphiDoom.XcomSave.MissionSite in '..\Games\XcomSave\DelphiDoom.XcomSave.MissionSite.pas',
  DelphiDoom.XcomSave.Node in '..\Games\XcomSave\DelphiDoom.XcomSave.Node.pas',
  DelphiDoom.XcomSave.EquipmentLayoutItem in '..\Games\XcomSave\DelphiDoom.XcomSave.EquipmentLayoutItem.pas',
  DelphiDoom.XcomMod.RuleManufacture in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleManufacture.pas',
  DelphiDoom.XcomSave.ItemContainer in '..\Games\XcomSave\DelphiDoom.XcomSave.ItemContainer.pas',
  DelphiDoom.XcomSave.Vehicle in '..\Games\XcomSave\DelphiDoom.XcomSave.Vehicle.pas',
  DelphiDoom.XcomSave.CraftWeapon in '..\Games\XcomSave\DelphiDoom.XcomSave.CraftWeapon.pas',
  DelphiDoom.XcomSave.BaseFacility in '..\Games\XcomSave\DelphiDoom.XcomSave.BaseFacility.pas',
  DelphiDoom.XcomSave.Production in '..\Games\XcomSave\DelphiDoom.XcomSave.Production.pas',
  DelphiDoom.XcomSave.NodeIteration in '..\Games\XcomSave\DelphiDoom.XcomSave.NodeIteration.pas',
  DelphiDoom.XcomSave.UnitEnums in '..\Games\XcomSave\DelphiDoom.XcomSave.UnitEnums.pas',
  DelphiDoom.XcomSave.RuleAdapters in '..\Games\XcomSave\DelphiDoom.XcomSave.RuleAdapters.pas',
  DelphiDoom.XcomSave.RulesetRules in '..\Games\XcomSave\DelphiDoom.XcomSave.RulesetRules.pas',
  DelphiDoom.XcomSave.BaseCapacity in '..\Games\XcomSave\DelphiDoom.XcomSave.BaseCapacity.pas',
  DelphiDoom.Tests.XcomSave.RulesetRules in 'Source\DelphiDoom.Tests.XcomSave.RulesetRules.pas',
  DelphiDoom.XcomMod.UnitStats in '..\Games\XcomMod\DelphiDoom.XcomMod.UnitStats.pas',
  DelphiDoom.XcomSave.UnitStats in '..\Games\XcomSave\DelphiDoom.XcomSave.UnitStats.pas',
  DelphiDoom.XcomSave.BattleUnitKills in '..\Games\XcomSave\DelphiDoom.XcomSave.BattleUnitKills.pas',
  DelphiDoom.XcomSave.BattleUnitStatistics in '..\Games\XcomSave\DelphiDoom.XcomSave.BattleUnitStatistics.pas',
  DelphiDoom.XcomSave.SoldierDeath in '..\Games\XcomSave\DelphiDoom.XcomSave.SoldierDeath.pas',
  DelphiDoom.Tests.XcomSave.ObjectScenario in 'Source\DelphiDoom.Tests.XcomSave.ObjectScenario.pas',
  DelphiDoom.Tests.XcomSave.ObjectGolden in 'Source\DelphiDoom.Tests.XcomSave.ObjectGolden.pas',
  DelphiDoom.Tests.XcomSave.Soldiers in 'Source\DelphiDoom.Tests.XcomSave.Soldiers.pas',
  DelphiDoom.Tests.XcomSave.Holdings in 'Source\DelphiDoom.Tests.XcomSave.Holdings.pas',
  DelphiDoom.Tests.XcomSave.Targets in 'Source\DelphiDoom.Tests.XcomSave.Targets.pas',
  DelphiDoom.Tests.XcomSave.Scenario in 'Source\DelphiDoom.Tests.XcomSave.Scenario.pas',
  DelphiDoom.Tests.XcomSave.Golden in 'Source\DelphiDoom.Tests.XcomSave.Golden.pas',
  DelphiDoom.Tests.XcomMod.DiskModFiles in 'Source\DelphiDoom.Tests.XcomMod.DiskModFiles.pas',
  DelphiDoom.Tests.XcomMod.RealData in 'Source\DelphiDoom.Tests.XcomMod.RealData.pas',
  DelphiDoom.Tests.XcomSave.RealSave in 'Source\DelphiDoom.Tests.XcomSave.RealSave.pas',
  DelphiDoom.Tests.XcomSave.Strategy in 'Source\DelphiDoom.Tests.XcomSave.Strategy.pas',
  DelphiDoom.Tests.XcomSave.Sim in 'Source\DelphiDoom.Tests.XcomSave.Sim.pas',
  DelphiDoom.Tests.XcomSave.CraftScenario in 'Source\DelphiDoom.Tests.XcomSave.CraftScenario.pas',
  DelphiDoom.Tests.XcomSave.Objects in 'Source\DelphiDoom.Tests.XcomSave.Objects.pas',
  DelphiDoom.XcomSave.DiaryRules.Intf in '..\Games\XcomSave\DelphiDoom.XcomSave.DiaryRules.Intf.pas',
  DelphiDoom.XcomSave.CommendationManager in '..\Games\XcomSave\DelphiDoom.XcomSave.CommendationManager.pas',
  DelphiDoom.XcomSave.RulesetDiaryRules in '..\Games\XcomSave\DelphiDoom.XcomSave.RulesetDiaryRules.pas',
  DelphiDoom.Tests.XcomSave.FakeDiaryRules in 'Source\DelphiDoom.Tests.XcomSave.FakeDiaryRules.pas',
  DelphiDoom.Tests.XcomSave.DiaryScenario in 'Source\DelphiDoom.Tests.XcomSave.DiaryScenario.pas',
  DelphiDoom.Tests.XcomSave.Diary in 'Source\DelphiDoom.Tests.XcomSave.Diary.pas';

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
