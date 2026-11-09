{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the script host library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.ScriptHost;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  d_delphi in '..\Libs\Script\Shim\d_delphi.pas',
  ps_defs in '..\Libs\PascalScript\ps_defs.pas',
  ps_keywords in '..\Libs\PascalScript\ps_keywords.pas',
  ps_utils in '..\Libs\PascalScript\ps_utils.pas',
  ps_compiler in '..\Libs\PascalScript\ps_compiler.pas',
  uPSPreProcessor in '..\Libs\PascalScript\uPSPreProcessor.pas',
  ps_runtime in '..\Libs\PascalScript\ps_runtime.pas',
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.ScriptHost.Types in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Types.pas',
  DelphiDoom.ScriptHost.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Intf.pas',
  DelphiDoom.ScriptHost.FunctionList in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.FunctionList.pas',
  DelphiDoom.ScriptHost.Registry in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Registry.pas',
  DelphiDoom.ScriptHost.CallbackGroup in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.CallbackGroup.pas',
  DelphiDoom.ScriptHost.System.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.System.Intf.pas',
  DelphiDoom.ScriptHost.System.Functions in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.System.Functions.pas',
  DelphiDoom.ScriptHost.Fixed.Functions in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Fixed.Functions.pas',
  DelphiDoom.ScriptHost.Variables.Types in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.Types.pas',
  DelphiDoom.ScriptHost.Variables.Intf in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.Intf.pas',
  DelphiDoom.ScriptHost.Variables.HashTable in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.HashTable.pas',
  DelphiDoom.ScriptHost.Variables.HashList in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.HashList.pas',
  DelphiDoom.ScriptHost.Variables in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Variables.pas',
  DelphiDoom.ScriptHost.Factory in '..\Libs\ScriptHost\DelphiDoom.ScriptHost.Factory.pas',
  DelphiDoom.Tests.ScriptHost.Fakes in 'Source\DelphiDoom.Tests.ScriptHost.Fakes.pas',
  DelphiDoom.Tests.ScriptHost.VariablesFakes in 'Source\DelphiDoom.Tests.ScriptHost.VariablesFakes.pas',
  DelphiDoom.Tests.ScriptHost.Variables in 'Source\DelphiDoom.Tests.ScriptHost.Variables.pas',
  DelphiDoom.Tests.ScriptHost.VariablesHash in 'Source\DelphiDoom.Tests.ScriptHost.VariablesHash.pas',
  DelphiDoom.Tests.ScriptHost.Registry in 'Source\DelphiDoom.Tests.ScriptHost.Registry.pas',
  DelphiDoom.Tests.ScriptHost.FunctionList in 'Source\DelphiDoom.Tests.ScriptHost.FunctionList.pas',
  DelphiDoom.Tests.ScriptHost.CallbackGroup in 'Source\DelphiDoom.Tests.ScriptHost.CallbackGroup.pas',
  DelphiDoom.Tests.ScriptHost.SystemFunctions in 'Source\DelphiDoom.Tests.ScriptHost.SystemFunctions.pas',
  DelphiDoom.Tests.ScriptHost.FixedFunctions in 'Source\DelphiDoom.Tests.ScriptHost.FixedFunctions.pas';

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
