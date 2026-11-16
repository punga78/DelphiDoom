{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the port to 64 bit (issue #44, DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Win64;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
{$IFNDEF CPUX86}
  DelphiDoom.MathCore.Types in '..\Framework\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\Framework\GameMath\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.MemoryFill in '..\Framework\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
{$ENDIF}
  d_delphi in '..\IdTech1\Common\d_delphi.pas',
  DelphiDoom.Tests.Win64.CommonPointers in 'Source\DelphiDoom.Tests.Win64.CommonPointers.pas';

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
