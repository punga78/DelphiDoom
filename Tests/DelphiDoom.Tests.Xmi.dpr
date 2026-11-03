{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Xmi library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Xmi;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  d_delphi in '..\Libs\Xmi\Shim\d_delphi.pas',
  xmi_consts in '..\XMILIB\xmi_consts.pas',
  xmi_iff in '..\XMILIB\xmi_iff.pas',
  xmi_core in '..\XMILIB\xmi_core.pas',
  DelphiDoom.Xmi.Intf in '..\Libs\Xmi\DelphiDoom.Xmi.Intf.pas',
  DelphiDoom.Xmi.Native in '..\Libs\Xmi\DelphiDoom.Xmi.Native.pas',
  DelphiDoom.Xmi.Engine in '..\Libs\Xmi\DelphiDoom.Xmi.Engine.pas',
  DelphiDoom.Xmi.Client in '..\Libs\Xmi\DelphiDoom.Xmi.Client.pas',
  DelphiDoom.Xmi.Loader in '..\Libs\Xmi\DelphiDoom.Xmi.Loader.pas',
  DelphiDoom.Tests.Xmi.Samples in 'Source\DelphiDoom.Tests.Xmi.Samples.pas',
  DelphiDoom.Tests.Xmi.Engine in 'Source\DelphiDoom.Tests.Xmi.Engine.pas',
  DelphiDoom.Tests.Xmi.Client in 'Source\DelphiDoom.Tests.Xmi.Client.pas',
  DelphiDoom.Tests.Xmi.Loader in 'Source\DelphiDoom.Tests.Xmi.Loader.pas';

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
