{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the blockmap library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Blockmap;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Blockmap.Types in '..\Libs\Blockmap\DelphiDoom.Blockmap.Types.pas',
  DelphiDoom.Blockmap.Intf in '..\Libs\Blockmap\DelphiDoom.Blockmap.Intf.pas',
  DelphiDoom.Blockmap.Builder in '..\Libs\Blockmap\DelphiDoom.Blockmap.Builder.pas',
  DelphiDoom.Blockmap.LumpReader in '..\Libs\Blockmap\DelphiDoom.Blockmap.LumpReader.pas',
  DelphiDoom.Blockmap.SlimeTrails in '..\Libs\Blockmap\DelphiDoom.Blockmap.SlimeTrails.pas',
  DelphiDoom.Blockmap.Factory in '..\Libs\Blockmap\DelphiDoom.Blockmap.Factory.pas',
  DelphiDoom.Tests.Blockmap.Fingerprint in 'Source\DelphiDoom.Tests.Blockmap.Fingerprint.pas',
  DelphiDoom.Tests.Blockmap.Cases in 'Source\DelphiDoom.Tests.Blockmap.Cases.pas',
  DelphiDoom.Tests.Blockmap.Builder in 'Source\DelphiDoom.Tests.Blockmap.Builder.pas',
  DelphiDoom.Tests.Blockmap.LumpReader in 'Source\DelphiDoom.Tests.Blockmap.LumpReader.pas',
  DelphiDoom.Tests.Blockmap.SlimeTrails in 'Source\DelphiDoom.Tests.Blockmap.SlimeTrails.pas';

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
