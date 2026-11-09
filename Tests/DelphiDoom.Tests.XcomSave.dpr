{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom saved game library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
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
  DelphiDoom.XcomMod.Types in '..\Libs\XcomMod\DelphiDoom.XcomMod.Types.pas',
  DelphiDoom.XcomMod.Random in '..\Libs\XcomMod\DelphiDoom.XcomMod.Random.pas',
  DelphiDoom.XcomMod.NodeReader in '..\Libs\XcomMod\DelphiDoom.XcomMod.NodeReader.pas',
  DelphiDoom.XcomMod.Areas in '..\Libs\XcomMod\DelphiDoom.XcomMod.Areas.pas',
  DelphiDoom.XcomMod.WeightedOptions in '..\Libs\XcomMod\DelphiDoom.XcomMod.WeightedOptions.pas',
  DelphiDoom.XcomMod.RuleCountry in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleCountry.pas',
  DelphiDoom.XcomMod.RuleRegion in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleRegion.pas',
  DelphiDoom.XcomMod.RuleResearch in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleResearch.pas',
  DelphiDoom.XcomSave.NodeWriter in '..\Libs\XcomSave\DelphiDoom.XcomSave.NodeWriter.pas',
  DelphiDoom.XcomSave.GameTime in '..\Libs\XcomSave\DelphiDoom.XcomSave.GameTime.pas',
  DelphiDoom.XcomSave.Country in '..\Libs\XcomSave\DelphiDoom.XcomSave.Country.pas',
  DelphiDoom.XcomSave.Region in '..\Libs\XcomSave\DelphiDoom.XcomSave.Region.pas',
  DelphiDoom.XcomSave.ResearchProject in '..\Libs\XcomSave\DelphiDoom.XcomSave.ResearchProject.pas',
  DelphiDoom.XcomSave.Serialization in '..\Libs\XcomSave\DelphiDoom.XcomSave.Serialization.pas',
  DelphiDoom.XcomMod.MapBlock in '..\Libs\XcomMod\DelphiDoom.XcomMod.MapBlock.pas',
  DelphiDoom.XcomSave.Types in '..\Libs\XcomSave\DelphiDoom.XcomSave.Types.pas',
  DelphiDoom.XcomSave.Rules.Intf in '..\Libs\XcomSave\DelphiDoom.XcomSave.Rules.Intf.pas',
  DelphiDoom.XcomSave.PositionCodec in '..\Libs\XcomSave\DelphiDoom.XcomSave.PositionCodec.pas',
  DelphiDoom.XcomSave.Target in '..\Libs\XcomSave\DelphiDoom.XcomSave.Target.pas',
  DelphiDoom.XcomSave.Waypoint in '..\Libs\XcomSave\DelphiDoom.XcomSave.Waypoint.pas',
  DelphiDoom.XcomSave.AlienBase in '..\Libs\XcomSave\DelphiDoom.XcomSave.AlienBase.pas',
  DelphiDoom.XcomSave.MissionSite in '..\Libs\XcomSave\DelphiDoom.XcomSave.MissionSite.pas',
  DelphiDoom.XcomSave.Node in '..\Libs\XcomSave\DelphiDoom.XcomSave.Node.pas',
  DelphiDoom.XcomSave.EquipmentLayoutItem in '..\Libs\XcomSave\DelphiDoom.XcomSave.EquipmentLayoutItem.pas',
  DelphiDoom.XcomMod.RuleManufacture in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleManufacture.pas',
  DelphiDoom.XcomSave.ItemContainer in '..\Libs\XcomSave\DelphiDoom.XcomSave.ItemContainer.pas',
  DelphiDoom.XcomSave.Vehicle in '..\Libs\XcomSave\DelphiDoom.XcomSave.Vehicle.pas',
  DelphiDoom.XcomSave.CraftWeapon in '..\Libs\XcomSave\DelphiDoom.XcomSave.CraftWeapon.pas',
  DelphiDoom.XcomSave.BaseFacility in '..\Libs\XcomSave\DelphiDoom.XcomSave.BaseFacility.pas',
  DelphiDoom.XcomSave.Production in '..\Libs\XcomSave\DelphiDoom.XcomSave.Production.pas',
  DelphiDoom.Tests.XcomSave.ObjectScenario in 'Source\DelphiDoom.Tests.XcomSave.ObjectScenario.pas',
  DelphiDoom.Tests.XcomSave.ObjectGolden in 'Source\DelphiDoom.Tests.XcomSave.ObjectGolden.pas',
  DelphiDoom.Tests.XcomSave.Holdings in 'Source\DelphiDoom.Tests.XcomSave.Holdings.pas',
  DelphiDoom.Tests.XcomSave.Targets in 'Source\DelphiDoom.Tests.XcomSave.Targets.pas',
  DelphiDoom.Tests.XcomSave.Scenario in 'Source\DelphiDoom.Tests.XcomSave.Scenario.pas',
  DelphiDoom.Tests.XcomSave.Golden in 'Source\DelphiDoom.Tests.XcomSave.Golden.pas',
  DelphiDoom.Tests.XcomSave.Objects in 'Source\DelphiDoom.Tests.XcomSave.Objects.pas';

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
