{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the UMAPINFO library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.MapInfo;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Framework\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Framework\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.MapInfo.Types in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Types.pas',
  DelphiDoom.MapInfo.Intf in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Intf.pas',
  DelphiDoom.MapInfo.TextPreparer in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.TextPreparer.pas',
  DelphiDoom.MapInfo.Parser in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Parser.pas',
  DelphiDoom.MapInfo.Merger in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Merger.pas',
  DelphiDoom.MapInfo.Catalog in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Catalog.pas',
  DelphiDoom.MapInfo.BossActionRule in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.BossActionRule.pas',
  DelphiDoom.MapInfo.Loader in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Loader.pas',
  DelphiDoom.MapInfo.Factory in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.Factory.pas',
  DelphiDoom.MapInfo.MapName in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.MapName.pas',
  DelphiDoom.MapInfo.LevelProgression in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.LevelProgression.pas',
  DelphiDoom.MapInfo.LevelExit in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.LevelExit.pas',
  DelphiDoom.MapInfo.IntermissionPlanner in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.IntermissionPlanner.pas',
  DelphiDoom.MapInfo.NewGameLimits in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.NewGameLimits.pas',
  DelphiDoom.MapInfo.SkillSpeed in '..\IdTech1\MapInfo\DelphiDoom.MapInfo.SkillSpeed.pas',
  DelphiDoom.Tests.MapInfo.Fakes in 'Source\DelphiDoom.Tests.MapInfo.Fakes.pas',
  DelphiDoom.Tests.MapInfo.Corpus in 'Source\DelphiDoom.Tests.MapInfo.Corpus.pas',
  DelphiDoom.Tests.MapInfo.Parity in 'Source\DelphiDoom.Tests.MapInfo.Parity.pas',
  DelphiDoom.Tests.MapInfo.Behavior in 'Source\DelphiDoom.Tests.MapInfo.Behavior.pas',
  DelphiDoom.Tests.MapInfo.MapName in 'Source\DelphiDoom.Tests.MapInfo.MapName.pas',
  DelphiDoom.Tests.MapInfo.LevelProgression in 'Source\DelphiDoom.Tests.MapInfo.LevelProgression.pas',
  DelphiDoom.Tests.MapInfo.LevelExit in 'Source\DelphiDoom.Tests.MapInfo.LevelExit.pas',
  DelphiDoom.Tests.MapInfo.IntermissionPlanner in 'Source\DelphiDoom.Tests.MapInfo.IntermissionPlanner.pas',
  DelphiDoom.Tests.MapInfo.NewGameLimits in 'Source\DelphiDoom.Tests.MapInfo.NewGameLimits.pas',
  DelphiDoom.Tests.MapInfo.SkillSpeed in 'Source\DelphiDoom.Tests.MapInfo.SkillSpeed.pas';

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
