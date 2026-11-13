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
  DelphiDoom.BotAi.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Types.pas',
  DelphiDoom.BotAi.Import.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.BotAi.Random.MsvcRand in '..\Libs\BotAi\DelphiDoom.BotAi.Random.MsvcRand.pas',
  DelphiDoom.BotAi.LibVars.Table in '..\Libs\BotAi\DelphiDoom.BotAi.LibVars.Table.pas',
  DelphiDoom.BotAi.Chat.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Types.pas',
  DelphiDoom.BotAi.Chat.Message in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Message.pas',
  DelphiDoom.BotAi.Chat.ChatType in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ChatType.pas',
  DelphiDoom.BotAi.Chat.Chat in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Chat.pas',
  DelphiDoom.BotAi.Chat.ReplyChat in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ReplyChat.pas',
  DelphiDoom.BotAi.Chat.SynonymList in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.SynonymList.pas',
  DelphiDoom.BotAi.Chat.RandomList in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.RandomList.pas',
  DelphiDoom.BotAi.Chat.Tables in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Tables.pas',
  DelphiDoom.BotAi.Chat.Text in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Text.pas',
  DelphiDoom.BotAi.Chat.ScriptCompressor in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ScriptCompressor.pas',
  DelphiDoom.BotAi.Chat.ScriptFileSystem in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ScriptFileSystem.pas',
  DelphiDoom.BotAi.Chat.ScriptLog in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ScriptLog.pas',
  DelphiDoom.BotAi.Chat.Source in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Source.pas',
  DelphiDoom.BotAi.Chat.MessageReader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.MessageReader.pas',
  DelphiDoom.BotAi.Chat.MatchPieceReader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.MatchPieceReader.pas',
  DelphiDoom.BotAi.Chat.SynonymLoader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.SynonymLoader.pas',
  DelphiDoom.BotAi.Chat.RandomListLoader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.RandomListLoader.pas',
  DelphiDoom.BotAi.Chat.MatchTemplateLoader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.MatchTemplateLoader.pas',
  DelphiDoom.BotAi.Chat.ReplyKeyChecker in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ReplyKeyChecker.pas',
  DelphiDoom.BotAi.Chat.RandomStrings in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.RandomStrings.pas',
  DelphiDoom.BotAi.Chat.IntegrityChecker in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.IntegrityChecker.pas',
  DelphiDoom.BotAi.Chat.ReplyChatLoader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ReplyChatLoader.pas',
  DelphiDoom.BotAi.Chat.InitialChatLoader in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.InitialChatLoader.pas',
  DelphiDoom.BotAi.Chat.Matcher in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Matcher.pas',
  DelphiDoom.BotAi.Chat.SynonymReplacer in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.SynonymReplacer.pas',
  DelphiDoom.BotAi.Chat.MessageBuilder in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.MessageBuilder.pas',
  DelphiDoom.BotAi.Chat.ConsoleHeap in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.ConsoleHeap.pas',
  DelphiDoom.BotAi.Chat.State in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.State.pas',
  DelphiDoom.BotAi.Chat.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Intf.pas',
  DelphiDoom.BotAi.Chat.System in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.System.pas',
  DelphiDoom.BotAi.Chat.Factory in '..\Libs\BotAi\DelphiDoom.BotAi.Chat.Factory.pas',
  DelphiDoom.BotAi.Exceptions in '..\Libs\BotAi\DelphiDoom.BotAi.Exceptions.pas',
  DelphiDoom.BotAi.Text.CFormat in '..\Libs\BotAi\DelphiDoom.BotAi.Text.CFormat.pas',
  DelphiDoom.BotAi.LibVars.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.LibVars.Intf.pas',
  DelphiDoom.BotAi.Struct.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Struct.Types.pas',
  DelphiDoom.BotAi.Struct.Reader in '..\Libs\BotAi\DelphiDoom.BotAi.Struct.Reader.pas',
  DelphiDoom.BotAi.Struct.Writer in '..\Libs\BotAi\DelphiDoom.BotAi.Struct.Writer.pas',
  DelphiDoom.BotAi.Weight.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Types.pas',
  DelphiDoom.BotAi.Weight.Separator in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Separator.pas',
  DelphiDoom.BotAi.Weight.Config in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Config.pas',
  DelphiDoom.BotAi.Weight.Reader in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Reader.pas',
  DelphiDoom.BotAi.Weight.Evaluator in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Evaluator.pas',
  DelphiDoom.BotAi.Weight.Scaler in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Scaler.pas',
  DelphiDoom.BotAi.Weight.Breeder in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Breeder.pas',
  DelphiDoom.BotAi.Weight.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Intf.pas',
  DelphiDoom.BotAi.Weight.Cache in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Cache.pas',
  DelphiDoom.BotAi.Weight.Factory in '..\Libs\BotAi\DelphiDoom.BotAi.Weight.Factory.pas',
  DelphiDoom.BotAi.Character.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Character.Types.pas',
  DelphiDoom.BotAi.Character.Data in '..\Libs\BotAi\DelphiDoom.BotAi.Character.Data.pas',
  DelphiDoom.BotAi.Character.Loader in '..\Libs\BotAi\DelphiDoom.BotAi.Character.Loader.pas',
  DelphiDoom.BotAi.Character.Interpolator in '..\Libs\BotAi\DelphiDoom.BotAi.Character.Interpolator.pas',
  DelphiDoom.BotAi.Character.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Character.Intf.pas',
  DelphiDoom.BotAi.Character.System in '..\Libs\BotAi\DelphiDoom.BotAi.Character.System.pas',
  DelphiDoom.BotAi.Character.Factory in '..\Libs\BotAi\DelphiDoom.BotAi.Character.Factory.pas',
  DelphiDoom.BotAi.Weapon.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.Types.pas',
  DelphiDoom.BotAi.Weapon.Definitions in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.Definitions.pas',
  DelphiDoom.BotAi.Weapon.Config in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.Config.pas',
  DelphiDoom.BotAi.Weapon.ConfigLoader in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.ConfigLoader.pas',
  DelphiDoom.BotAi.Weapon.State in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.State.pas',
  DelphiDoom.BotAi.Weapon.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.Intf.pas',
  DelphiDoom.BotAi.Weapon.System in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.System.pas',
  DelphiDoom.BotAi.Weapon.Factory in '..\Libs\BotAi\DelphiDoom.BotAi.Weapon.Factory.pas',
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
  DelphiDoom.Tests.BotAi.Parity in 'Source\DelphiDoom.Tests.BotAi.Parity.pas';

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
