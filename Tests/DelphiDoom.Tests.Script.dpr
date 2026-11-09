{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Script library (DUnitX)                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Script;

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
  DelphiDoom.Script.Intf in '..\Libs\Script\DelphiDoom.Script.Intf.pas',
  DelphiDoom.Script.Native in '..\Libs\Script\DelphiDoom.Script.Native.pas',
  DelphiDoom.Script.Native.Compiler in '..\Libs\Script\DelphiDoom.Script.Native.Compiler.pas',
  DelphiDoom.Script.Native.Executor in '..\Libs\Script\DelphiDoom.Script.Native.Executor.pas',
  DelphiDoom.Script.Engine.Compiler in '..\Libs\Script\DelphiDoom.Script.Engine.Compiler.pas',
  DelphiDoom.Script.Engine.Executor in '..\Libs\Script\DelphiDoom.Script.Engine.Executor.pas',
  DelphiDoom.Script.Engine in '..\Libs\Script\DelphiDoom.Script.Engine.pas',
  DelphiDoom.Script.Client.Compiler in '..\Libs\Script\DelphiDoom.Script.Client.Compiler.pas',
  DelphiDoom.Script.Client.Executor in '..\Libs\Script\DelphiDoom.Script.Client.Executor.pas',
  DelphiDoom.Script.Client.HostList in '..\Libs\Script\DelphiDoom.Script.Client.HostList.pas',
  DelphiDoom.Script.Client in '..\Libs\Script\DelphiDoom.Script.Client.pas',
  DelphiDoom.Script.Loader in '..\Libs\Script\DelphiDoom.Script.Loader.pas',
  DelphiDoom.Tests.Script.Samples in 'Source\DelphiDoom.Tests.Script.Samples.pas',
  DelphiDoom.Tests.Script.Engine in 'Source\DelphiDoom.Tests.Script.Engine.pas',
  DelphiDoom.Tests.Script.Client in 'Source\DelphiDoom.Tests.Script.Client.pas',
  DelphiDoom.Tests.Script.Loader in 'Source\DelphiDoom.Tests.Script.Loader.pas',
  DelphiDoom.Tests.Script.Declarations in 'Source\DelphiDoom.Tests.Script.Declarations.pas',
  DelphiDoom.Tests.Script.HostList in 'Source\DelphiDoom.Tests.Script.HostList.pas',
  DelphiDoom.Tests.Script.Memory in 'Source\DelphiDoom.Tests.Script.Memory.pas',
  DelphiDoom.Tests.Script.Globals in 'Source\DelphiDoom.Tests.Script.Globals.pas',
  DelphiDoom.Tests.Script.Preprocessor in 'Source\DelphiDoom.Tests.Script.Preprocessor.pas',
  DelphiDoom.Tests.Script.ErrorCodes in 'Source\DelphiDoom.Tests.Script.ErrorCodes.pas';

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
