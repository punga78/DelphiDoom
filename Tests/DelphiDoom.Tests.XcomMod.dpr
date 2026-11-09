{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomMod;

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
  DelphiDoom.XcomMod.RuleInventory in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleInventory.pas',
  DelphiDoom.XcomMod.RuleCountry in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleCountry.pas',
  DelphiDoom.XcomMod.RuleRegion in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleRegion.pas',
  DelphiDoom.XcomMod.RuleResearch in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleResearch.pas',
  DelphiDoom.XcomMod.RuleManufacture in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleManufacture.pas',
  DelphiDoom.XcomMod.AlienRace in '..\Libs\XcomMod\DelphiDoom.XcomMod.AlienRace.pas',
  DelphiDoom.XcomMod.UfoTrajectory in '..\Libs\XcomMod\DelphiDoom.XcomMod.UfoTrajectory.pas',
  DelphiDoom.XcomMod.RuleMusic in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleMusic.pas',
  DelphiDoom.XcomMod.MapBlock in '..\Libs\XcomMod\DelphiDoom.XcomMod.MapBlock.pas',
  DelphiDoom.XcomMod.RuleCommendations in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleCommendations.pas',
  DelphiDoom.XcomMod.ModOffsets in '..\Libs\XcomMod\DelphiDoom.XcomMod.ModOffsets.pas',
  DelphiDoom.XcomMod.RuleCraftWeapon in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleCraftWeapon.pas',
  DelphiDoom.XcomMod.RuleItem in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleItem.pas',
  DelphiDoom.XcomMod.UnitStats in '..\Libs\XcomMod\DelphiDoom.XcomMod.UnitStats.pas',
  DelphiDoom.XcomMod.Armor in '..\Libs\XcomMod\DelphiDoom.XcomMod.Armor.pas',
  DelphiDoom.XcomMod.ModFiles.Intf in '..\Libs\XcomMod\DelphiDoom.XcomMod.ModFiles.Intf.pas',
  DelphiDoom.XcomMod.SoldierNamePool in '..\Libs\XcomMod\DelphiDoom.XcomMod.SoldierNamePool.pas',
  DelphiDoom.XcomMod.RuleSoldier in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleSoldier.pas',
  DelphiDoom.XcomMod.RuleUnit in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleUnit.pas',
  DelphiDoom.Tests.XcomMod.DiskModFiles in 'Source\DelphiDoom.Tests.XcomMod.DiskModFiles.pas',
  DelphiDoom.XcomMod.AlienDeployment in '..\Libs\XcomMod\DelphiDoom.XcomMod.AlienDeployment.pas',
  DelphiDoom.XcomMod.RuleAlienMission in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleAlienMission.pas',
  DelphiDoom.XcomMod.RuleMissionScript in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleMissionScript.pas',
  DelphiDoom.XcomMod.IntStringMap in '..\Libs\XcomMod\DelphiDoom.XcomMod.IntStringMap.pas',
  DelphiDoom.XcomMod.SoundDefinition in '..\Libs\XcomMod\DelphiDoom.XcomMod.SoundDefinition.pas',
  DelphiDoom.XcomMod.RuleInterface in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleInterface.pas',
  DelphiDoom.XcomMod.RuleVideo in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleVideo.pas',
  DelphiDoom.XcomMod.ExtraStrings in '..\Libs\XcomMod\DelphiDoom.XcomMod.ExtraStrings.pas',
  DelphiDoom.XcomMod.ExtraSounds in '..\Libs\XcomMod\DelphiDoom.XcomMod.ExtraSounds.pas',
  DelphiDoom.XcomMod.ExtraSprites in '..\Libs\XcomMod\DelphiDoom.XcomMod.ExtraSprites.pas',
  DelphiDoom.XcomMod.StatString in '..\Libs\XcomMod\DelphiDoom.XcomMod.StatString.pas',
  DelphiDoom.XcomMod.McdPatch in '..\Libs\XcomMod\DelphiDoom.XcomMod.McdPatch.pas',
  DelphiDoom.XcomMod.RuleConverter in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleConverter.pas',
  DelphiDoom.XcomMod.ArticleDefinition in '..\Libs\XcomMod\DelphiDoom.XcomMod.ArticleDefinition.pas',
  DelphiDoom.XcomMod.MapScript in '..\Libs\XcomMod\DelphiDoom.XcomMod.MapScript.pas',
  DelphiDoom.XcomMod.ModConstants in '..\Libs\XcomMod\DelphiDoom.XcomMod.ModConstants.pas',
  DelphiDoom.XcomMod.RulesetSettings in '..\Libs\XcomMod\DelphiDoom.XcomMod.RulesetSettings.pas',
  DelphiDoom.Tests.XcomMod.ModDumpMisc in 'Source\DelphiDoom.Tests.XcomMod.ModDumpMisc.pas',
  DelphiDoom.XcomMod.RuleBaseFacility in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleBaseFacility.pas',
  DelphiDoom.XcomMod.MapDataSet in '..\Libs\XcomMod\DelphiDoom.XcomMod.MapDataSet.pas',
  DelphiDoom.XcomMod.RuleTerrain in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleTerrain.pas',
  DelphiDoom.XcomMod.RuleCraft in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleCraft.pas',
  DelphiDoom.XcomMod.RuleUfo in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleUfo.pas',
  DelphiDoom.XcomMod.RuleRegistry in '..\Libs\XcomMod\DelphiDoom.XcomMod.RuleRegistry.pas',
  DelphiDoom.XcomMod.Ruleset in '..\Libs\XcomMod\DelphiDoom.XcomMod.Ruleset.pas',
  DelphiDoom.XcomMod.ModLoader in '..\Libs\XcomMod\DelphiDoom.XcomMod.ModLoader.pas',
  DelphiDoom.Tests.XcomMod.DumpWriter in 'Source\DelphiDoom.Tests.XcomMod.DumpWriter.pas',
  DelphiDoom.Tests.XcomMod.ModDump in 'Source\DelphiDoom.Tests.XcomMod.ModDump.pas',
  DelphiDoom.Tests.XcomMod.RealData in 'Source\DelphiDoom.Tests.XcomMod.RealData.pas',
  DelphiDoom.Tests.XcomMod.RealMod in 'Source\DelphiDoom.Tests.XcomMod.RealMod.pas',
  DelphiDoom.Tests.XcomMod.ModOffsets in 'Source\DelphiDoom.Tests.XcomMod.ModOffsets.pas',
  DelphiDoom.Tests.XcomMod.Scenario in 'Source\DelphiDoom.Tests.XcomMod.Scenario.pas',
  DelphiDoom.Tests.XcomMod.Golden in 'Source\DelphiDoom.Tests.XcomMod.Golden.pas',
  DelphiDoom.Tests.XcomMod.Rules in 'Source\DelphiDoom.Tests.XcomMod.Rules.pas';

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
