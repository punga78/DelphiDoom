{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the definitions library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Definitions;

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
  DelphiDoom.Scanner.Text in '..\Libs\Scanner\DelphiDoom.Scanner.Text.pas',
  DelphiDoom.Definitions.Types in '..\Libs\Definitions\DelphiDoom.Definitions.Types.pas',
  DelphiDoom.Definitions.Intf in '..\Libs\Definitions\DelphiDoom.Definitions.Intf.pas',
  DelphiDoom.Definitions.AnimDefsParser in '..\Libs\Definitions\DelphiDoom.Definitions.AnimDefsParser.pas',
  DelphiDoom.Definitions.SwitchLumpReader in '..\Libs\Definitions\DelphiDoom.Definitions.SwitchLumpReader.pas',
  DelphiDoom.Definitions.SwitchSelector in '..\Libs\Definitions\DelphiDoom.Definitions.SwitchSelector.pas',
  DelphiDoom.Definitions.SwitchTables in '..\Libs\Definitions\DelphiDoom.Definitions.SwitchTables.pas',
  DelphiDoom.Definitions.TerrainTable in '..\Libs\Definitions\DelphiDoom.Definitions.TerrainTable.pas',
  DelphiDoom.Definitions.TerrainTables in '..\Libs\Definitions\DelphiDoom.Definitions.TerrainTables.pas',
  DelphiDoom.Definitions.Factory in '..\Libs\Definitions\DelphiDoom.Definitions.Factory.pas',
  DelphiDoom.Tests.Definitions.Fakes in 'Source\DelphiDoom.Tests.Definitions.Fakes.pas',
  DelphiDoom.Tests.Definitions.Corpus in 'Source\DelphiDoom.Tests.Definitions.Corpus.pas',
  DelphiDoom.Tests.Definitions.Parity in 'Source\DelphiDoom.Tests.Definitions.Parity.pas',
  DelphiDoom.Tests.Definitions.AnimDefsParser in 'Source\DelphiDoom.Tests.Definitions.AnimDefsParser.pas',
  DelphiDoom.Tests.Definitions.SwitchLumpReader in 'Source\DelphiDoom.Tests.Definitions.SwitchLumpReader.pas',
  DelphiDoom.Tests.Definitions.SwitchSelector in 'Source\DelphiDoom.Tests.Definitions.SwitchSelector.pas',
  DelphiDoom.Tests.Definitions.TerrainTable in 'Source\DelphiDoom.Tests.Definitions.TerrainTable.pas',
  DelphiDoom.Tests.Definitions.TerrainTables in 'Source\DelphiDoom.Tests.Definitions.TerrainTables.pas',
  DelphiDoom.Tests.Definitions.Tables in 'Source\DelphiDoom.Tests.Definitions.Tables.pas';

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
