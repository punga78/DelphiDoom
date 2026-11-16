{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the bot AI library (DUnitX)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.BotAi;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.BotAi.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Types.pas',
  DelphiDoom.BotAi.Import.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.BotAi.Random.MsvcRand in '..\IdTech4\BotAi\DelphiDoom.BotAi.Random.MsvcRand.pas',
  DelphiDoom.BotAi.LibVars.Table in '..\IdTech4\BotAi\DelphiDoom.BotAi.LibVars.Table.pas',
  DelphiDoom.BotAi.Chat.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Types.pas',
  DelphiDoom.BotAi.Chat.Message in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Message.pas',
  DelphiDoom.BotAi.Chat.ChatType in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ChatType.pas',
  DelphiDoom.BotAi.Chat.Chat in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Chat.pas',
  DelphiDoom.BotAi.Chat.ReplyChat in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ReplyChat.pas',
  DelphiDoom.BotAi.Chat.SynonymList in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.SynonymList.pas',
  DelphiDoom.BotAi.Chat.RandomList in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.RandomList.pas',
  DelphiDoom.BotAi.Chat.Tables in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Tables.pas',
  DelphiDoom.BotAi.Chat.Text in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Text.pas',
  DelphiDoom.Scanner.Q3.Compressor in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Compressor.pas',
  DelphiDoom.BotAi.Chat.ScriptCompressor in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ScriptCompressor.pas',
  DelphiDoom.BotAi.Chat.ScriptFileSystem in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ScriptFileSystem.pas',
  DelphiDoom.BotAi.Chat.ScriptLog in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ScriptLog.pas',
  DelphiDoom.BotAi.Chat.Source in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Source.pas',
  DelphiDoom.BotAi.Chat.MessageReader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.MessageReader.pas',
  DelphiDoom.BotAi.Chat.MatchPieceReader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.MatchPieceReader.pas',
  DelphiDoom.BotAi.Chat.SynonymLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.SynonymLoader.pas',
  DelphiDoom.BotAi.Chat.RandomListLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.RandomListLoader.pas',
  DelphiDoom.BotAi.Chat.MatchTemplateLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.MatchTemplateLoader.pas',
  DelphiDoom.BotAi.Chat.ReplyKeyChecker in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ReplyKeyChecker.pas',
  DelphiDoom.BotAi.Chat.RandomStrings in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.RandomStrings.pas',
  DelphiDoom.BotAi.Chat.IntegrityChecker in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.IntegrityChecker.pas',
  DelphiDoom.BotAi.Chat.ReplyChatLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ReplyChatLoader.pas',
  DelphiDoom.BotAi.Chat.InitialChatLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.InitialChatLoader.pas',
  DelphiDoom.BotAi.Chat.Matcher in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Matcher.pas',
  DelphiDoom.BotAi.Chat.SynonymReplacer in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.SynonymReplacer.pas',
  DelphiDoom.BotAi.Chat.MessageBuilder in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.MessageBuilder.pas',
  DelphiDoom.BotAi.Chat.ConsoleHeap in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.ConsoleHeap.pas',
  DelphiDoom.BotAi.Chat.State in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.State.pas',
  DelphiDoom.BotAi.Chat.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Intf.pas',
  DelphiDoom.BotAi.Chat.System in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.System.pas',
  DelphiDoom.BotAi.Chat.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Chat.Factory.pas',
  DelphiDoom.BotAi.Exceptions in '..\IdTech4\BotAi\DelphiDoom.BotAi.Exceptions.pas',
  DelphiDoom.BotAi.Text.CFormat in '..\IdTech4\BotAi\DelphiDoom.BotAi.Text.CFormat.pas',
  DelphiDoom.BotAi.LibVars.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.LibVars.Intf.pas',
  DelphiDoom.BotAi.Struct.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Struct.Types.pas',
  DelphiDoom.BotAi.Struct.Reader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Struct.Reader.pas',
  DelphiDoom.BotAi.Struct.Writer in '..\IdTech4\BotAi\DelphiDoom.BotAi.Struct.Writer.pas',
  DelphiDoom.BotAi.Weight.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Types.pas',
  DelphiDoom.BotAi.Weight.Separator in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Separator.pas',
  DelphiDoom.BotAi.Weight.Config in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Config.pas',
  DelphiDoom.BotAi.Weight.Reader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Reader.pas',
  DelphiDoom.BotAi.Weight.Evaluator in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Evaluator.pas',
  DelphiDoom.BotAi.Weight.Scaler in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Scaler.pas',
  DelphiDoom.BotAi.Weight.Breeder in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Breeder.pas',
  DelphiDoom.BotAi.Weight.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Intf.pas',
  DelphiDoom.BotAi.Weight.Cache in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Cache.pas',
  DelphiDoom.BotAi.Weight.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weight.Factory.pas',
  DelphiDoom.BotAi.Character.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.Types.pas',
  DelphiDoom.BotAi.Character.Data in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.Data.pas',
  DelphiDoom.BotAi.Character.Loader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.Loader.pas',
  DelphiDoom.BotAi.Character.Interpolator in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.Interpolator.pas',
  DelphiDoom.BotAi.Character.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.Intf.pas',
  DelphiDoom.BotAi.Character.System in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.System.pas',
  DelphiDoom.BotAi.Character.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Character.Factory.pas',
  DelphiDoom.BotAi.Weapon.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.Types.pas',
  DelphiDoom.BotAi.Weapon.Definitions in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.Definitions.pas',
  DelphiDoom.BotAi.Weapon.Config in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.Config.pas',
  DelphiDoom.BotAi.Weapon.ConfigLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.ConfigLoader.pas',
  DelphiDoom.BotAi.Weapon.State in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.State.pas',
  DelphiDoom.BotAi.Weapon.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.Intf.pas',
  DelphiDoom.BotAi.Weapon.System in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.System.pas',
  DelphiDoom.BotAi.Weapon.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Weapon.Factory.pas',
  DelphiDoom.BotAi.Ea.Actions in '..\IdTech4\BotAi\DelphiDoom.BotAi.Ea.Actions.pas',
  DelphiDoom.BotAi.Ea.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Ea.Intf.pas',
  DelphiDoom.BotAi.Ea.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Ea.Types.pas',
  DelphiDoom.BotAi.Gen.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Gen.Intf.pas',
  DelphiDoom.BotAi.Gen.Selector in '..\IdTech4\BotAi\DelphiDoom.BotAi.Gen.Selector.pas',
  DelphiDoom.BotAi.Goal.Chooser in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.Chooser.pas',
  DelphiDoom.BotAi.Goal.Context in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.Context.pas',
  DelphiDoom.BotAi.Goal.EntityItems in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.EntityItems.pas',
  DelphiDoom.BotAi.Goal.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.Factory.pas',
  DelphiDoom.BotAi.Goal.InfoEntities in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.InfoEntities.pas',
  DelphiDoom.BotAi.Goal.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.Intf.pas',
  DelphiDoom.BotAi.Goal.ItemConfig in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.ItemConfig.pas',
  DelphiDoom.BotAi.Goal.ItemConfigLoader in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.ItemConfigLoader.pas',
  DelphiDoom.BotAi.Goal.ItemDefinitions in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.ItemDefinitions.pas',
  DelphiDoom.BotAi.Goal.ItemInitializer in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.ItemInitializer.pas',
  DelphiDoom.BotAi.Goal.LevelItems in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.LevelItems.pas',
  DelphiDoom.BotAi.Goal.State in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.State.pas',
  DelphiDoom.BotAi.Goal.System in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.System.pas',
  DelphiDoom.BotAi.Goal.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Goal.Types.pas',
  DelphiDoom.BotAi.Move.AvoidSpots in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.AvoidSpots.pas',
  DelphiDoom.BotAi.Move.Basics in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Basics.pas',
  DelphiDoom.BotAi.Move.Context in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Context.pas',
  DelphiDoom.BotAi.Move.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Factory.pas',
  DelphiDoom.BotAi.Move.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Intf.pas',
  DelphiDoom.BotAi.Move.Locator in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Locator.pas',
  DelphiDoom.BotAi.Move.ModelTypes in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.ModelTypes.pas',
  DelphiDoom.BotAi.Move.Movers in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Movers.pas',
  DelphiDoom.BotAi.Move.Predictor in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Predictor.pas',
  DelphiDoom.BotAi.Move.ReachChooser in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.ReachChooser.pas',
  DelphiDoom.BotAi.Move.State in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.State.pas',
  DelphiDoom.BotAi.Move.System in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.System.pas',
  DelphiDoom.BotAi.Move.Travel.BarrierJump in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.BarrierJump.pas',
  DelphiDoom.BotAi.Move.Travel.Base in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Base.pas',
  DelphiDoom.BotAi.Move.Travel.BfgJump in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.BfgJump.pas',
  DelphiDoom.BotAi.Move.Travel.Crouch in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Crouch.pas',
  DelphiDoom.BotAi.Move.Travel.Elevator in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Elevator.pas',
  DelphiDoom.BotAi.Move.Travel.FuncBob in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.FuncBob.pas',
  DelphiDoom.BotAi.Move.Travel.Grapple in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Grapple.pas',
  DelphiDoom.BotAi.Move.Travel.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Intf.pas',
  DelphiDoom.BotAi.Move.Travel.Jump in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Jump.pas',
  DelphiDoom.BotAi.Move.Travel.JumpPad in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.JumpPad.pas',
  DelphiDoom.BotAi.Move.Travel.Ladder in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Ladder.pas',
  DelphiDoom.BotAi.Move.Travel.RocketJump in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.RocketJump.pas',
  DelphiDoom.BotAi.Move.Travel.Swim in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Swim.pas',
  DelphiDoom.BotAi.Move.Travel.Teleport in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Teleport.pas',
  DelphiDoom.BotAi.Move.Travel.Walk in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.Walk.pas',
  DelphiDoom.BotAi.Move.Travel.WalkOffLedge in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.WalkOffLedge.pas',
  DelphiDoom.BotAi.Move.Travel.WaterJump in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.WaterJump.pas',
  DelphiDoom.BotAi.Move.Travel.WeaponJump in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Travel.WeaponJump.pas',
  DelphiDoom.BotAi.Move.Types in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Types.pas',
  DelphiDoom.BotAi.Move.Vars in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.Vars.pas',
  DelphiDoom.BotAi.Move.VectorMath in '..\IdTech4\BotAi\DelphiDoom.BotAi.Move.VectorMath.pas',
  DelphiDoom.BotAi.Facade.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Facade.Intf.pas',
  DelphiDoom.BotAi.Facade.Bundle in '..\IdTech4\BotAi\DelphiDoom.BotAi.Facade.Bundle.pas',
  DelphiDoom.BotAi.Facade.Factory in '..\IdTech4\BotAi\DelphiDoom.BotAi.Facade.Factory.pas',
  DelphiDoom.BotAi.World.AasWorld in '..\IdTech4\BotAi\DelphiDoom.BotAi.World.AasWorld.pas',
  DelphiDoom.BotAi.World.EntitySource in '..\IdTech4\BotAi\DelphiDoom.BotAi.World.EntitySource.pas',
  DelphiDoom.BotAi.World.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.World.Intf.pas',
  DelphiDoom.Tests.BotAi.Support in 'Source\DelphiDoom.Tests.BotAi.Support.pas',
  DelphiDoom.Tests.BotAi.AiScenarioRunner in 'Source\DelphiDoom.Tests.BotAi.AiScenarioRunner.pas',
  DelphiDoom.Tests.BotAi.AiParity in 'Source\DelphiDoom.Tests.BotAi.AiParity.pas',
  DelphiDoom.Tests.BotAi.CFormat in 'Source\DelphiDoom.Tests.BotAi.CFormat.pas',
  DelphiDoom.Tests.BotAi.LibVars in 'Source\DelphiDoom.Tests.BotAi.LibVars.pas',
  DelphiDoom.Tests.BotAi.Struct in 'Source\DelphiDoom.Tests.BotAi.Struct.pas',
  DelphiDoom.Tests.BotAi.Weight in 'Source\DelphiDoom.Tests.BotAi.Weight.pas',
  DelphiDoom.Tests.BotAi.Character in 'Source\DelphiDoom.Tests.BotAi.Character.pas',
  DelphiDoom.Tests.BotAi.Weapon in 'Source\DelphiDoom.Tests.BotAi.Weapon.pas',
  DelphiDoom.Tests.BotAi.OpenArenaAi in 'Source\DelphiDoom.Tests.BotAi.OpenArenaAi.pas',
  DelphiDoom.Tests.BotAi.ScenarioRunner in 'Source\DelphiDoom.Tests.BotAi.ScenarioRunner.pas',
  DelphiDoom.Tests.BotAi.Text in 'Source\DelphiDoom.Tests.BotAi.Text.pas',
  DelphiDoom.Tests.BotAi.Chat in 'Source\DelphiDoom.Tests.BotAi.Chat.pas',
  DelphiDoom.Tests.BotAi.Source in 'Source\DelphiDoom.Tests.BotAi.Source.pas',
  DelphiDoom.Tests.BotAi.OpenArena in 'Source\DelphiDoom.Tests.BotAi.OpenArena.pas',
  DelphiDoom.Tests.BotAi.Parity in 'Source\DelphiDoom.Tests.BotAi.Parity.pas',
  DelphiDoom.Tests.Aas.Sample in 'Source\DelphiDoom.Tests.Aas.Sample.pas',
  DelphiDoom.Tests.BotAi.World in 'Source\DelphiDoom.Tests.BotAi.World.pas',
  DelphiDoom.Tests.BotAi.GoalMoveScenario in 'Source\DelphiDoom.Tests.BotAi.GoalMoveScenario.pas',
  DelphiDoom.Tests.BotAi.GoalMoveParity in 'Source\DelphiDoom.Tests.BotAi.GoalMoveParity.pas',
  DelphiDoom.Tests.BotAi.Ea in 'Source\DelphiDoom.Tests.BotAi.Ea.pas',
  DelphiDoom.Tests.BotAi.WorldUnits in 'Source\DelphiDoom.Tests.BotAi.WorldUnits.pas',
  DelphiDoom.Tests.BotAi.GoalConfig in 'Source\DelphiDoom.Tests.BotAi.GoalConfig.pas',
  DelphiDoom.Tests.BotAi.Facade in 'Source\DelphiDoom.Tests.BotAi.Facade.pas';

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
