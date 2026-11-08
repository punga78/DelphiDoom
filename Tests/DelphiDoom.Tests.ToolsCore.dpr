{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the ToolsCore library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.ToolsCore;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tools.Types in '..\Libs\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.Intf in '..\Libs\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Tools.PathText in '..\Libs\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Tools.UndoHistory in '..\Libs\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\Libs\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\Libs\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\Libs\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\Libs\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Tools.Factory in '..\Libs\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Tests.ToolsCore.Fakes in 'Source\DelphiDoom.Tests.ToolsCore.Fakes.pas',
  DelphiDoom.Tests.ToolsCore.UndoHistory in 'Source\DelphiDoom.Tests.ToolsCore.UndoHistory.pas',
  DelphiDoom.Tests.ToolsCore.RecentFiles in 'Source\DelphiDoom.Tests.ToolsCore.RecentFiles.pas',
  DelphiDoom.Tests.ToolsCore.SettingsStore in 'Source\DelphiDoom.Tests.ToolsCore.SettingsStore.pas',
  DelphiDoom.Tests.ToolsCore.ProgressReporter in 'Source\DelphiDoom.Tests.ToolsCore.ProgressReporter.pas',
  DelphiDoom.Tests.ToolsCore.FileBackup in 'Source\DelphiDoom.Tests.ToolsCore.FileBackup.pas';

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
