{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom ruleset library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Games\XcomFormats\README.md)                                                  }
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
  DelphiDoom.XcomMod.Types in '..\Games\XcomMod\DelphiDoom.XcomMod.Types.pas',
  DelphiDoom.XcomMod.Random in '..\Games\XcomMod\DelphiDoom.XcomMod.Random.pas',
  DelphiDoom.XcomMod.NodeReader in '..\Games\XcomMod\DelphiDoom.XcomMod.NodeReader.pas',
  DelphiDoom.XcomMod.Areas in '..\Games\XcomMod\DelphiDoom.XcomMod.Areas.pas',
  DelphiDoom.XcomMod.WeightedOptions in '..\Games\XcomMod\DelphiDoom.XcomMod.WeightedOptions.pas',
  DelphiDoom.XcomMod.RuleInventory in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleInventory.pas',
  DelphiDoom.XcomMod.RuleCountry in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleCountry.pas',
  DelphiDoom.XcomMod.RuleRegion in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleRegion.pas',
  DelphiDoom.XcomMod.RuleResearch in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleResearch.pas',
  DelphiDoom.XcomMod.RuleManufacture in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleManufacture.pas',
  DelphiDoom.XcomMod.AlienRace in '..\Games\XcomMod\DelphiDoom.XcomMod.AlienRace.pas',
  DelphiDoom.XcomMod.UfoTrajectory in '..\Games\XcomMod\DelphiDoom.XcomMod.UfoTrajectory.pas',
  DelphiDoom.XcomMod.RuleMusic in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleMusic.pas',
  DelphiDoom.XcomMod.MapBlock in '..\Games\XcomMod\DelphiDoom.XcomMod.MapBlock.pas',
  DelphiDoom.XcomMod.RuleCommendations in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleCommendations.pas',
  DelphiDoom.XcomMod.ModOffsets in '..\Games\XcomMod\DelphiDoom.XcomMod.ModOffsets.pas',
  DelphiDoom.XcomMod.RuleCraftWeapon in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleCraftWeapon.pas',
  DelphiDoom.XcomMod.RuleItem in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleItem.pas',
  DelphiDoom.XcomMod.UnitStats in '..\Games\XcomMod\DelphiDoom.XcomMod.UnitStats.pas',
  DelphiDoom.XcomMod.Armor in '..\Games\XcomMod\DelphiDoom.XcomMod.Armor.pas',
  DelphiDoom.XcomMod.ModFiles.Intf in '..\Games\XcomMod\DelphiDoom.XcomMod.ModFiles.Intf.pas',
  DelphiDoom.XcomMod.SoldierNamePool in '..\Games\XcomMod\DelphiDoom.XcomMod.SoldierNamePool.pas',
  DelphiDoom.XcomMod.RuleSoldier in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleSoldier.pas',
  DelphiDoom.XcomMod.RuleUnit in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleUnit.pas',
  DelphiDoom.Tests.XcomMod.DiskModFiles in 'Source\DelphiDoom.Tests.XcomMod.DiskModFiles.pas',
  DelphiDoom.XcomMod.AlienDeployment in '..\Games\XcomMod\DelphiDoom.XcomMod.AlienDeployment.pas',
  DelphiDoom.XcomMod.RuleAlienMission in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleAlienMission.pas',
  DelphiDoom.XcomMod.RuleMissionScript in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleMissionScript.pas',
  DelphiDoom.XcomMod.IntStringMap in '..\Games\XcomMod\DelphiDoom.XcomMod.IntStringMap.pas',
  DelphiDoom.XcomMod.SoundDefinition in '..\Games\XcomMod\DelphiDoom.XcomMod.SoundDefinition.pas',
  DelphiDoom.XcomMod.RuleInterface in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleInterface.pas',
  DelphiDoom.XcomMod.RuleVideo in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleVideo.pas',
  DelphiDoom.XcomMod.ExtraStrings in '..\Games\XcomMod\DelphiDoom.XcomMod.ExtraStrings.pas',
  DelphiDoom.XcomMod.ExtraSounds in '..\Games\XcomMod\DelphiDoom.XcomMod.ExtraSounds.pas',
  DelphiDoom.XcomMod.ExtraSprites in '..\Games\XcomMod\DelphiDoom.XcomMod.ExtraSprites.pas',
  DelphiDoom.XcomMod.StatString in '..\Games\XcomMod\DelphiDoom.XcomMod.StatString.pas',
  DelphiDoom.XcomMod.McdPatch in '..\Games\XcomMod\DelphiDoom.XcomMod.McdPatch.pas',
  DelphiDoom.XcomMod.RuleConverter in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleConverter.pas',
  DelphiDoom.XcomMod.ArticleDefinition in '..\Games\XcomMod\DelphiDoom.XcomMod.ArticleDefinition.pas',
  DelphiDoom.XcomMod.MapScript in '..\Games\XcomMod\DelphiDoom.XcomMod.MapScript.pas',
  DelphiDoom.XcomMod.ModConstants in '..\Games\XcomMod\DelphiDoom.XcomMod.ModConstants.pas',
  DelphiDoom.XcomMod.RulesetSettings in '..\Games\XcomMod\DelphiDoom.XcomMod.RulesetSettings.pas',
  DelphiDoom.Tests.XcomMod.ModDumpMisc in 'Source\DelphiDoom.Tests.XcomMod.ModDumpMisc.pas',
  DelphiDoom.XcomMod.RuleBaseFacility in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleBaseFacility.pas',
  DelphiDoom.XcomMod.MapDataSet in '..\Games\XcomMod\DelphiDoom.XcomMod.MapDataSet.pas',
  DelphiDoom.XcomMod.RuleTerrain in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleTerrain.pas',
  DelphiDoom.XcomMod.RuleCraft in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleCraft.pas',
  DelphiDoom.XcomMod.RuleUfo in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleUfo.pas',
  DelphiDoom.XcomMod.RuleRegistry in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleRegistry.pas',
  DelphiDoom.XcomMod.MapData in '..\Games\XcomMod\DelphiDoom.XcomMod.MapData.pas',
  DelphiDoom.XcomMod.MapDataLoader in '..\Games\XcomMod\DelphiDoom.XcomMod.MapDataLoader.pas',
  DelphiDoom.XcomMod.Polygon in '..\Games\XcomMod\DelphiDoom.XcomMod.Polygon.pas',
  DelphiDoom.XcomMod.Polyline in '..\Games\XcomMod\DelphiDoom.XcomMod.Polyline.pas',
  DelphiDoom.XcomMod.Texture in '..\Games\XcomMod\DelphiDoom.XcomMod.Texture.pas',
  DelphiDoom.XcomMod.RuleGlobe in '..\Games\XcomMod\DelphiDoom.XcomMod.RuleGlobe.pas',
  DelphiDoom.XcomMod.Ruleset in '..\Games\XcomMod\DelphiDoom.XcomMod.Ruleset.pas',
  DelphiDoom.XcomMod.ModLoader in '..\Games\XcomMod\DelphiDoom.XcomMod.ModLoader.pas',
  DelphiDoom.Tests.XcomMod.DumpWriter in 'Source\DelphiDoom.Tests.XcomMod.DumpWriter.pas',
  DelphiDoom.Tests.XcomMod.ModDump in 'Source\DelphiDoom.Tests.XcomMod.ModDump.pas',
  DelphiDoom.Tests.XcomMod.RealData in 'Source\DelphiDoom.Tests.XcomMod.RealData.pas',
  DelphiDoom.Tests.XcomMod.RealMod in 'Source\DelphiDoom.Tests.XcomMod.RealMod.pas',
  DelphiDoom.Tests.XcomMod.Ruleset in 'Source\DelphiDoom.Tests.XcomMod.Ruleset.pas',
  DelphiDoom.Tests.XcomMod.MapData in 'Source\DelphiDoom.Tests.XcomMod.MapData.pas',
  DelphiDoom.Tests.XcomMod.Picks in 'Source\DelphiDoom.Tests.XcomMod.Picks.pas',
  DelphiDoom.Tests.XcomMod.Globe in 'Source\DelphiDoom.Tests.XcomMod.Globe.pas',
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
