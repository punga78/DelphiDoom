{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the dynamic lights library (DUnitX)               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.DynLights;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.GameState.Intf in '..\Libs\GameState\DelphiDoom.GameState.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.DynLights.Types in '..\Libs\DynLights\DelphiDoom.DynLights.Types.pas',
  DelphiDoom.DynLights.Intf in '..\Libs\DynLights\DelphiDoom.DynLights.Intf.pas',
  DelphiDoom.DynLights.Tokens in '..\Libs\DynLights\DelphiDoom.DynLights.Tokens.pas',
  DelphiDoom.DynLights.Registry in '..\Libs\DynLights\DelphiDoom.DynLights.Registry.pas',
  DelphiDoom.DynLights.FixedMath in '..\Libs\DynLights\DelphiDoom.DynLights.FixedMath.pas',
  DelphiDoom.DynLights.Animator in '..\Libs\DynLights\DelphiDoom.DynLights.Animator.pas',
  DelphiDoom.DynLights.StateBinder in '..\Libs\DynLights\DelphiDoom.DynLights.StateBinder.pas',
  DelphiDoom.DynLights.Parser in '..\Libs\DynLights\DelphiDoom.DynLights.Parser.pas',
  DelphiDoom.DynLights.Loader in '..\Libs\DynLights\DelphiDoom.DynLights.Loader.pas',
  DelphiDoom.DynLights.Factory in '..\Libs\DynLights\DelphiDoom.DynLights.Factory.pas',
  DelphiDoom.Tests.DynLights.Fakes in 'Source\DelphiDoom.Tests.DynLights.Fakes.pas',
  DelphiDoom.Tests.DynLights.Corpus in 'Source\DelphiDoom.Tests.DynLights.Corpus.pas',
  DelphiDoom.Tests.DynLights.Parity in 'Source\DelphiDoom.Tests.DynLights.Parity.pas',
  DelphiDoom.Tests.DynLights.Behavior in 'Source\DelphiDoom.Tests.DynLights.Behavior.pas';

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
