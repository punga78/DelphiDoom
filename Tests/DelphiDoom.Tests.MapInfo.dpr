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
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.MapInfo.Types in '..\Libs\MapInfo\DelphiDoom.MapInfo.Types.pas',
  DelphiDoom.MapInfo.Intf in '..\Libs\MapInfo\DelphiDoom.MapInfo.Intf.pas',
  DelphiDoom.MapInfo.TextPreparer in '..\Libs\MapInfo\DelphiDoom.MapInfo.TextPreparer.pas',
  DelphiDoom.MapInfo.Parser in '..\Libs\MapInfo\DelphiDoom.MapInfo.Parser.pas',
  DelphiDoom.MapInfo.Merger in '..\Libs\MapInfo\DelphiDoom.MapInfo.Merger.pas',
  DelphiDoom.MapInfo.Catalog in '..\Libs\MapInfo\DelphiDoom.MapInfo.Catalog.pas',
  DelphiDoom.MapInfo.BossActionRule in '..\Libs\MapInfo\DelphiDoom.MapInfo.BossActionRule.pas',
  DelphiDoom.MapInfo.Loader in '..\Libs\MapInfo\DelphiDoom.MapInfo.Loader.pas',
  DelphiDoom.MapInfo.Factory in '..\Libs\MapInfo\DelphiDoom.MapInfo.Factory.pas',
  DelphiDoom.Tests.MapInfo.Fakes in 'Source\DelphiDoom.Tests.MapInfo.Fakes.pas',
  DelphiDoom.Tests.MapInfo.Corpus in 'Source\DelphiDoom.Tests.MapInfo.Corpus.pas',
  DelphiDoom.Tests.MapInfo.Parity in 'Source\DelphiDoom.Tests.MapInfo.Parity.pas',
  DelphiDoom.Tests.MapInfo.Behavior in 'Source\DelphiDoom.Tests.MapInfo.Behavior.pas';

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
