{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the EndoomEditor library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.EndoomEditor;

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
  DelphiDoom.Endoom.Types in '..\Libs\Endoom\DelphiDoom.Endoom.Types.pas',
  DelphiDoom.Endoom.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.Intf.pas',
  DelphiDoom.Endoom.Renderer in '..\Libs\Endoom\DelphiDoom.Endoom.Renderer.pas',
  DelphiDoom.Endoom.Session in '..\Libs\Endoom\DelphiDoom.Endoom.Session.pas',
  DelphiDoom.Endoom.DosFont in '..\Libs\Endoom\DelphiDoom.Endoom.DosFont.pas',
  DelphiDoom.Endoom.FontSource in '..\Libs\Endoom\DelphiDoom.Endoom.FontSource.pas',
  DelphiDoom.Endoom.ColorQuantizer in '..\Libs\Endoom\DelphiDoom.Endoom.ColorQuantizer.pas',
  DelphiDoom.Endoom.Screen in '..\Libs\Endoom\DelphiDoom.Endoom.Screen.pas',
  DelphiDoom.Endoom.Drawing in '..\Libs\Endoom\DelphiDoom.Endoom.Drawing.pas',
  DelphiDoom.Endoom.TextPaste in '..\Libs\Endoom\DelphiDoom.Endoom.TextPaste.pas',
  DelphiDoom.Endoom.ScreenImage in '..\Libs\Endoom\DelphiDoom.Endoom.ScreenImage.pas',
  DelphiDoom.Endoom.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.Factory.pas',
  DelphiDoom.Endoom.TextArt.Types in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Types.pas',
  DelphiDoom.Endoom.TextArt.Intf in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Intf.pas',
  DelphiDoom.Endoom.TextArt.BackgroundOnly in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundOnly.pas',
  DelphiDoom.Endoom.TextArt.BackgroundForeground in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.BackgroundForeground.pas',
  DelphiDoom.Endoom.TextArt.Dither in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Dither.pas',
  DelphiDoom.Endoom.TextArt.SpecialChars in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.SpecialChars.pas',
  DelphiDoom.Endoom.TextArt.Converter in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Converter.pas',
  DelphiDoom.Endoom.TextArt.Factory in '..\Libs\Endoom\DelphiDoom.Endoom.TextArt.Factory.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.EndoomEditor.Types in '..\Libs\EndoomEditor\DelphiDoom.EndoomEditor.Types.pas',
  DelphiDoom.EndoomEditor.Intf in '..\Libs\EndoomEditor\DelphiDoom.EndoomEditor.Intf.pas',
  DelphiDoom.EndoomEditor.Presenter in '..\Libs\EndoomEditor\DelphiDoom.EndoomEditor.Presenter.pas',
  DelphiDoom.Tests.ToolsCore.Fakes in 'Source\DelphiDoom.Tests.ToolsCore.Fakes.pas',
  DelphiDoom.Tests.EndoomEditor.Fakes in 'Source\DelphiDoom.Tests.EndoomEditor.Fakes.pas',
  DelphiDoom.Tests.EndoomEditor.Presenter in 'Source\DelphiDoom.Tests.EndoomEditor.Presenter.pas';

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
