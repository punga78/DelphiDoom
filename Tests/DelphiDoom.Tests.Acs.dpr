{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the ACS compiler library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Acs;

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
  DelphiDoom.Acs.Types in '..\Libs\Acs\DelphiDoom.Acs.Types.pas',
  DelphiDoom.Acs.Intf in '..\Libs\Acs\DelphiDoom.Acs.Intf.pas',
  DelphiDoom.Acs.Tokens in '..\Libs\Acs\DelphiDoom.Acs.Tokens.pas',
  DelphiDoom.Acs.PCodes in '..\Libs\Acs\DelphiDoom.Acs.PCodes.pas',
  DelphiDoom.Acs.ErrorCodes in '..\Libs\Acs\DelphiDoom.Acs.ErrorCodes.pas',
  DelphiDoom.Acs.ErrorTexts in '..\Libs\Acs\DelphiDoom.Acs.ErrorTexts.pas',
  DelphiDoom.Acs.Diagnostics in '..\Libs\Acs\DelphiDoom.Acs.Diagnostics.pas',
  DelphiDoom.Acs.SymbolTable in '..\Libs\Acs\DelphiDoom.Acs.SymbolTable.pas',
  DelphiDoom.Acs.StringTable in '..\Libs\Acs\DelphiDoom.Acs.StringTable.pas',
  DelphiDoom.Acs.ObjectWriter in '..\Libs\Acs\DelphiDoom.Acs.ObjectWriter.pas',
  DelphiDoom.Acs.Tokenizer in '..\Libs\Acs\DelphiDoom.Acs.Tokenizer.pas',
  DelphiDoom.Acs.Parser in '..\Libs\Acs\DelphiDoom.Acs.Parser.pas',
  DelphiDoom.Acs.Compiler in '..\Libs\Acs\DelphiDoom.Acs.Compiler.pas',
  DelphiDoom.Acs.MemorySourceProvider in '..\Libs\Acs\DelphiDoom.Acs.MemorySourceProvider.pas',
  DelphiDoom.Acs.Machine.Types in '..\Libs\Acs\DelphiDoom.Acs.Machine.Types.pas',
  DelphiDoom.Acs.Machine.Intf in '..\Libs\Acs\DelphiDoom.Acs.Machine.Intf.pas',
  DelphiDoom.Acs.Machine.Arithmetic in '..\Libs\Acs\DelphiDoom.Acs.Machine.Arithmetic.pas',
  DelphiDoom.Acs.Machine.Behavior in '..\Libs\Acs\DelphiDoom.Acs.Machine.Behavior.pas',
  DelphiDoom.Acs.Machine.Variables in '..\Libs\Acs\DelphiDoom.Acs.Machine.Variables.pas',
  DelphiDoom.Acs.Machine.Interpreter in '..\Libs\Acs\DelphiDoom.Acs.Machine.Interpreter.pas',
  DelphiDoom.Acs.Machine in '..\Libs\Acs\DelphiDoom.Acs.Machine.pas',
  DelphiDoom.Acs.Factory in '..\Libs\Acs\DelphiDoom.Acs.Factory.pas',
  DelphiDoom.Tests.Acs.FakeWorld in 'Source\DelphiDoom.Tests.Acs.FakeWorld.pas',
  DelphiDoom.Tests.Acs.FakeThinkers in 'Source\DelphiDoom.Tests.Acs.FakeThinkers.pas',
  DelphiDoom.Tests.Acs.FakeHost in 'Source\DelphiDoom.Tests.Acs.FakeHost.pas',
  DelphiDoom.Tests.Acs.Scenario in 'Source\DelphiDoom.Tests.Acs.Scenario.pas',
  DelphiDoom.Tests.Acs.MachineTarget in 'Source\DelphiDoom.Tests.Acs.MachineTarget.pas',
  DelphiDoom.Tests.Acs.ObjectBuilder in 'Source\DelphiDoom.Tests.Acs.ObjectBuilder.pas',
  DelphiDoom.Tests.Acs.Arithmetic in 'Source\DelphiDoom.Tests.Acs.Arithmetic.pas',
  DelphiDoom.Tests.Acs.Behavior in 'Source\DelphiDoom.Tests.Acs.Behavior.pas',
  DelphiDoom.Tests.Acs.Variables in 'Source\DelphiDoom.Tests.Acs.Variables.pas',
  DelphiDoom.Tests.Acs.Machine in 'Source\DelphiDoom.Tests.Acs.Machine.pas',
  DelphiDoom.Tests.Acs.Compiler in 'Source\DelphiDoom.Tests.Acs.Compiler.pas';

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
