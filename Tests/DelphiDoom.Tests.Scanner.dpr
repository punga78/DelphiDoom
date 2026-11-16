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
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Recorder in '..\Framework\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Log in '..\Framework\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Factory in '..\Framework\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Scanner.Strings in '..\Framework\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Framework\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.Scanner.Text in '..\Framework\Scanner\DelphiDoom.Scanner.Text.pas',
  DelphiDoom.Scanner.Numbers in '..\Framework\Scanner\DelphiDoom.Scanner.Numbers.pas',
  DelphiDoom.Scanner.Expression.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.Expression.Intf.pas',
  DelphiDoom.Scanner.Expression.Node in '..\Framework\Scanner\DelphiDoom.Scanner.Expression.Node.pas',
  DelphiDoom.Scanner.Expression.Builtins in '..\Framework\Scanner\DelphiDoom.Scanner.Expression.Builtins.pas',
  DelphiDoom.Scanner.Expression.Evaluator in '..\Framework\Scanner\DelphiDoom.Scanner.Expression.Evaluator.pas',
  DelphiDoom.Scanner.Preprocessor.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.Preprocessor.Intf.pas',
  DelphiDoom.Scanner.Defines in '..\Framework\Scanner\DelphiDoom.Scanner.Defines.pas',
  DelphiDoom.Scanner.Preprocessor in '..\Framework\Scanner\DelphiDoom.Scanner.Preprocessor.pas',
  DelphiDoom.Scanner.Directive.Flag in '..\Framework\Scanner\DelphiDoom.Scanner.Directive.Flag.pas',
  DelphiDoom.Scanner.Directive.CvarForce in '..\Framework\Scanner\DelphiDoom.Scanner.Directive.CvarForce.pas',
  DelphiDoom.Scanner.Directive.CreatePalette in '..\Framework\Scanner\DelphiDoom.Scanner.Directive.CreatePalette.pas',
  DelphiDoom.Scanner.AutoLoad.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.AutoLoad.Intf.pas',
  DelphiDoom.Scanner.AutoLoad in '..\Framework\Scanner\DelphiDoom.Scanner.AutoLoad.pas',
  DelphiDoom.Scanner.ContextEvaluator.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.ContextEvaluator.Intf.pas',
  DelphiDoom.Scanner.ContextEvaluator in '..\Framework\Scanner\DelphiDoom.Scanner.ContextEvaluator.pas',
  DelphiDoom.Scanner.TextPreprocessor in '..\Framework\Scanner\DelphiDoom.Scanner.TextPreprocessor.pas',
  DelphiDoom.Scanner.GameDefines in '..\Framework\Scanner\DelphiDoom.Scanner.GameDefines.pas',
  DelphiDoom.Scanner.IdCNumbers in '..\Framework\Scanner\DelphiDoom.Scanner.IdCNumbers.pas',
  DelphiDoom.Scanner.IdParser.Types in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.Types.pas',
  DelphiDoom.Scanner.IdParser.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.Intf.pas',
  DelphiDoom.Scanner.IdParser.Define in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.Define.pas',
  DelphiDoom.Scanner.IdParser.GlobalDefines in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.GlobalDefines.pas',
  DelphiDoom.Scanner.IdParser.Evaluator in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.Evaluator.pas',
  DelphiDoom.Scanner.IdParser in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.pas',
  DelphiDoom.Scanner.IdDict in '..\Framework\Scanner\DelphiDoom.Scanner.IdDict.pas',
  DelphiDoom.Scanner.IdLangDict in '..\Framework\Scanner\DelphiDoom.Scanner.IdLangDict.pas',
  DelphiDoom.Scanner.IdDictLister in '..\Framework\Scanner\DelphiDoom.Scanner.IdDictLister.pas',
  DelphiDoom.Scanner.IdDictCommands.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.IdDictCommands.Intf.pas',
  DelphiDoom.Scanner.IdDictCommands in '..\Framework\Scanner\DelphiDoom.Scanner.IdDictCommands.pas',
  DelphiDoom.Tests.Scanner.Parity in 'Source\DelphiDoom.Tests.Scanner.Parity.pas',
  DelphiDoom.Tests.Scanner.Text in 'Source\DelphiDoom.Tests.Scanner.Text.pas',
  DelphiDoom.Tests.Scanner.Preprocessor in 'Source\DelphiDoom.Tests.Scanner.Preprocessor.pas',
  DelphiDoom.Tests.Scanner.AutoLoad in 'Source\DelphiDoom.Tests.Scanner.AutoLoad.pas',
  DelphiDoom.Tests.Scanner.Expression in 'Source\DelphiDoom.Tests.Scanner.Expression.pas',
  DelphiDoom.Tests.Scanner.TextPreprocessor in 'Source\DelphiDoom.Tests.Scanner.TextPreprocessor.pas',
  DelphiDoom.Tests.Scanner.ContextEvaluator in 'Source\DelphiDoom.Tests.Scanner.ContextEvaluator.pas',
  DelphiDoom.Tests.Scanner.GameDefines in 'Source\DelphiDoom.Tests.Scanner.GameDefines.pas',
  DelphiDoom.Tests.Scanner.IdFakes in 'Source\DelphiDoom.Tests.Scanner.IdFakes.pas',
  DelphiDoom.Tests.Scanner.IdParser in 'Source\DelphiDoom.Tests.Scanner.IdParser.pas',
  DelphiDoom.Tests.Scanner.IdParser.Golden in 'Source\DelphiDoom.Tests.Scanner.IdParser.Golden.pas',
  DelphiDoom.Tests.Scanner.IdDict in 'Source\DelphiDoom.Tests.Scanner.IdDict.pas',
  DelphiDoom.Tests.Scanner.IdDictLister in 'Source\DelphiDoom.Tests.Scanner.IdDictLister.pas',
  DelphiDoom.Scanner.Q3.Types in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Types.pas',
  DelphiDoom.Scanner.Q3.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Intf.pas',
  DelphiDoom.Scanner.Q3.Compressor in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Compressor.pas',
  DelphiDoom.Scanner.Q3.Punctuations in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Punctuations.pas',
  DelphiDoom.Scanner.Q3.Script in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Script.pas',
  DelphiDoom.Scanner.Q3.ScriptLoader.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.ScriptLoader.Intf.pas',
  DelphiDoom.Scanner.Q3.ScriptLoader in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.ScriptLoader.pas',
  DelphiDoom.Scanner.Q3.TokenNode in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.TokenNode.pas',
  DelphiDoom.Scanner.Q3.Define in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Define.pas',
  DelphiDoom.Scanner.Q3.DefineHash in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.DefineHash.pas',
  DelphiDoom.Scanner.Q3.GlobalDefines in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.GlobalDefines.pas',
  DelphiDoom.Scanner.Q3.Expression in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Expression.pas',
  DelphiDoom.Scanner.Q3.Source in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.Source.pas',
  DelphiDoom.Scanner.Q3.SourceHandles in '..\Framework\Scanner\DelphiDoom.Scanner.Q3.SourceHandles.pas',
  DelphiDoom.Tests.Scanner.Q3.Values in 'Source\DelphiDoom.Tests.Scanner.Q3.Values.pas',
  DelphiDoom.Tests.Scanner.Q3.Golden in 'Source\DelphiDoom.Tests.Scanner.Q3.Golden.pas',
  DelphiDoom.Tests.Scanner.IdDictCommands in 'Source\DelphiDoom.Tests.Scanner.IdDictCommands.pas';

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
