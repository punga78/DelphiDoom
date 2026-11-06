{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the ActorDef library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.ActorDef;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.Scanner.Text in '..\Libs\Scanner\DelphiDoom.Scanner.Text.pas',
  DelphiDoom.ActorDef.ActorReader in '..\Libs\ActorDef\DelphiDoom.ActorDef.ActorReader.pas',
  DelphiDoom.ActorDef.ActorStateOwner in '..\Libs\ActorDef\DelphiDoom.ActorDef.ActorStateOwner.pas',
  DelphiDoom.ActorDef.DehSink in '..\Libs\ActorDef\DelphiDoom.ActorDef.DehSink.pas',
  DelphiDoom.ActorDef.DehWriter in '..\Libs\ActorDef\DelphiDoom.ActorDef.DehWriter.pas',
  DelphiDoom.ActorDef.DocumentReader in '..\Libs\ActorDef\DelphiDoom.ActorDef.DocumentReader.pas',
  DelphiDoom.ActorDef.Factory in '..\Libs\ActorDef\DelphiDoom.ActorDef.Factory.pas',
  DelphiDoom.ActorDef.FlagEditor in '..\Libs\ActorDef\DelphiDoom.ActorDef.FlagEditor.pas',
  DelphiDoom.ActorDef.FlagReader in '..\Libs\ActorDef\DelphiDoom.ActorDef.FlagReader.pas',
  DelphiDoom.ActorDef.GotoResolver in '..\Libs\ActorDef\DelphiDoom.ActorDef.GotoResolver.pas',
  DelphiDoom.ActorDef.Intf in '..\Libs\ActorDef\DelphiDoom.ActorDef.Intf.pas',
  DelphiDoom.ActorDef.LabelMatcher in '..\Libs\ActorDef\DelphiDoom.ActorDef.LabelMatcher.pas',
  DelphiDoom.ActorDef.Parser in '..\Libs\ActorDef\DelphiDoom.ActorDef.Parser.pas',
  DelphiDoom.ActorDef.Profiles in '..\Libs\ActorDef\DelphiDoom.ActorDef.Profiles.pas',
  DelphiDoom.ActorDef.SoundAliases in '..\Libs\ActorDef\DelphiDoom.ActorDef.SoundAliases.pas',
  DelphiDoom.ActorDef.SoundInfoParser in '..\Libs\ActorDef\DelphiDoom.ActorDef.SoundInfoParser.pas',
  DelphiDoom.ActorDef.StateOwner in '..\Libs\ActorDef\DelphiDoom.ActorDef.StateOwner.pas',
  DelphiDoom.ActorDef.StateReader in '..\Libs\ActorDef\DelphiDoom.ActorDef.StateReader.pas',
  DelphiDoom.ActorDef.Text in '..\Libs\ActorDef\DelphiDoom.ActorDef.Text.pas',
  DelphiDoom.ActorDef.Types in '..\Libs\ActorDef\DelphiDoom.ActorDef.Types.pas',
  DelphiDoom.ActorDef.WeaponReader in '..\Libs\ActorDef\DelphiDoom.ActorDef.WeaponReader.pas',
  DelphiDoom.ActorDef.WeaponStateOwner in '..\Libs\ActorDef\DelphiDoom.ActorDef.WeaponStateOwner.pas',
  DelphiDoom.Tests.ActorDef.Replay in 'Source\DelphiDoom.Tests.ActorDef.Replay.pas',
  DelphiDoom.Tests.ActorDef.Parity in 'Source\DelphiDoom.Tests.ActorDef.Parity.pas',
  DelphiDoom.Tests.ActorDef.Model in 'Source\DelphiDoom.Tests.ActorDef.Model.pas',
  DelphiDoom.Tests.ActorDef.Units in 'Source\DelphiDoom.Tests.ActorDef.Units.pas';

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
