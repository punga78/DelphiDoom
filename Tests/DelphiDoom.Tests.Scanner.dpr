{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the specials library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Scanner;

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
  DelphiDoom.Scanner.Numbers in '..\Libs\Scanner\DelphiDoom.Scanner.Numbers.pas',
  DelphiDoom.Scanner.Expression.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.Expression.Intf.pas',
  DelphiDoom.Scanner.Expression.Node in '..\Libs\Scanner\DelphiDoom.Scanner.Expression.Node.pas',
  DelphiDoom.Scanner.Expression.Builtins in '..\Libs\Scanner\DelphiDoom.Scanner.Expression.Builtins.pas',
  DelphiDoom.Scanner.Expression.Evaluator in '..\Libs\Scanner\DelphiDoom.Scanner.Expression.Evaluator.pas',
  DelphiDoom.Scanner.Preprocessor.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.Preprocessor.Intf.pas',
  DelphiDoom.Scanner.Defines in '..\Libs\Scanner\DelphiDoom.Scanner.Defines.pas',
  DelphiDoom.Scanner.Preprocessor in '..\Libs\Scanner\DelphiDoom.Scanner.Preprocessor.pas',
  DelphiDoom.Scanner.Directive.Flag in '..\Libs\Scanner\DelphiDoom.Scanner.Directive.Flag.pas',
  DelphiDoom.Scanner.Directive.CvarForce in '..\Libs\Scanner\DelphiDoom.Scanner.Directive.CvarForce.pas',
  DelphiDoom.Scanner.Directive.CreatePalette in '..\Libs\Scanner\DelphiDoom.Scanner.Directive.CreatePalette.pas',
  DelphiDoom.Scanner.AutoLoad.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.AutoLoad.Intf.pas',
  DelphiDoom.Scanner.AutoLoad in '..\Libs\Scanner\DelphiDoom.Scanner.AutoLoad.pas',
  DelphiDoom.Scanner.ContextEvaluator.Intf in '..\Libs\Scanner\DelphiDoom.Scanner.ContextEvaluator.Intf.pas',
  DelphiDoom.Scanner.ContextEvaluator in '..\Libs\Scanner\DelphiDoom.Scanner.ContextEvaluator.pas',
  DelphiDoom.Scanner.TextPreprocessor in '..\Libs\Scanner\DelphiDoom.Scanner.TextPreprocessor.pas',
  DelphiDoom.Tests.Scanner.Parity in 'Source\DelphiDoom.Tests.Scanner.Parity.pas',
  DelphiDoom.Tests.Scanner.Text in 'Source\DelphiDoom.Tests.Scanner.Text.pas',
  DelphiDoom.Tests.Scanner.Preprocessor in 'Source\DelphiDoom.Tests.Scanner.Preprocessor.pas',
  DelphiDoom.Tests.Scanner.AutoLoad in 'Source\DelphiDoom.Tests.Scanner.AutoLoad.pas',
  DelphiDoom.Tests.Scanner.Expression in 'Source\DelphiDoom.Tests.Scanner.Expression.pas',
  DelphiDoom.Tests.Scanner.TextPreprocessor in 'Source\DelphiDoom.Tests.Scanner.TextPreprocessor.pas',
  DelphiDoom.Tests.Scanner.ContextEvaluator in 'Source\DelphiDoom.Tests.Scanner.ContextEvaluator.pas';

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
