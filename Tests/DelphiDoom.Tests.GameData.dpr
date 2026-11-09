{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the game data library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.GameData;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.GameData.Types in '..\Libs\GameData\DelphiDoom.GameData.Types.pas',
  DelphiDoom.GameData.Intf in '..\Libs\GameData\DelphiDoom.GameData.Intf.pas',
  DelphiDoom.GameData.PatchBuilder in '..\Libs\GameData\DelphiDoom.GameData.PatchBuilder.pas',
  DelphiDoom.GameData.WadComposer in '..\Libs\GameData\DelphiDoom.GameData.WadComposer.pas',
  DelphiDoom.GameData.Factory in '..\Libs\GameData\DelphiDoom.GameData.Factory.pas',
  DelphiDoom.Tests.GameData.Scenarios in 'Source\DelphiDoom.Tests.GameData.Scenarios.pas',
  DelphiDoom.Tests.GameData.PatchBuilder in 'Source\DelphiDoom.Tests.GameData.PatchBuilder.pas',
  DelphiDoom.Tests.GameData.WadComposer in 'Source\DelphiDoom.Tests.GameData.WadComposer.pas';

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
