{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Gui library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Gui;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Scanner.IdCNumbers in '..\Libs\Scanner\DelphiDoom.Scanner.IdCNumbers.pas',
  DelphiDoom.Scanner.IdParser.Types in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Types.pas',
  DelphiDoom.Scanner.IdParser.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Intf.pas',
  DelphiDoom.Scanner.IdParser.Define in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Define.pas',
  DelphiDoom.Scanner.IdParser.GlobalDefines in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.GlobalDefines.pas',
  DelphiDoom.Scanner.IdParser.Evaluator in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.Evaluator.pas',
  DelphiDoom.Scanner.IdParser in '..\Libs\Scanner\DelphiDoom.Scanner.IdParser.pas',
  DelphiDoom.Gui.Types in '..\Libs\Gui\DelphiDoom.Gui.Types.pas',
  DelphiDoom.Gui.Intf in '..\Libs\Gui\DelphiDoom.Gui.Intf.pas',
  DelphiDoom.Gui.DeviceContext.Intf in '..\Libs\Gui\DelphiDoom.Gui.DeviceContext.Intf.pas',
  DelphiDoom.Gui.StringPool in '..\Libs\Gui\DelphiDoom.Gui.StringPool.pas',
  DelphiDoom.Gui.PrecompilerSource in '..\Libs\Gui\DelphiDoom.Gui.PrecompilerSource.pas',
  DelphiDoom.Gui.PrecompilerLoader in '..\Libs\Gui\DelphiDoom.Gui.PrecompilerLoader.pas',
  DelphiDoom.Gui.IdLibLog in '..\Libs\Gui\DelphiDoom.Gui.IdLibLog.pas',
  DelphiDoom.Gui.ValueReader in '..\Libs\Gui\DelphiDoom.Gui.ValueReader.pas',
  DelphiDoom.Gui.Font.Types in '..\Libs\Gui\DelphiDoom.Gui.Font.Types.pas',
  DelphiDoom.Gui.Font in '..\Libs\Gui\DelphiDoom.Gui.Font.pas',
  DelphiDoom.Gui.FontReader in '..\Libs\Gui\DelphiDoom.Gui.FontReader.pas',
  DelphiDoom.Gui.FontRegistry in '..\Libs\Gui\DelphiDoom.Gui.FontRegistry.pas',
  DelphiDoom.Gui.Assets in '..\Libs\Gui\DelphiDoom.Gui.Assets.pas',
  DelphiDoom.Gui.Menu in '..\Libs\Gui\DelphiDoom.Gui.Menu.pas',
  DelphiDoom.Gui.ItemParser in '..\Libs\Gui\DelphiDoom.Gui.ItemParser.pas',
  DelphiDoom.Gui.MenuParser in '..\Libs\Gui\DelphiDoom.Gui.MenuParser.pas',
  DelphiDoom.Gui.MenuSet in '..\Libs\Gui\DelphiDoom.Gui.MenuSet.pas',
  DelphiDoom.Gui.AssetParser in '..\Libs\Gui\DelphiDoom.Gui.AssetParser.pas',
  DelphiDoom.Gui.MenuFileReader in '..\Libs\Gui\DelphiDoom.Gui.MenuFileReader.pas',
  DelphiDoom.Gui.ScriptCursor in '..\Libs\Gui\DelphiDoom.Gui.ScriptCursor.pas',
  DelphiDoom.Gui.ScriptRunner in '..\Libs\Gui\DelphiDoom.Gui.ScriptRunner.pas',
  DelphiDoom.Gui.Factory in '..\Libs\Gui\DelphiDoom.Gui.Factory.pas',
  DelphiDoom.Tests.Gui.Fakes in 'Source\DelphiDoom.Tests.Gui.Fakes.pas',
  DelphiDoom.Tests.Gui.Scenario in 'Source\DelphiDoom.Tests.Gui.Scenario.pas',
  DelphiDoom.Tests.Gui.Parity in 'Source\DelphiDoom.Tests.Gui.Parity.pas';

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
