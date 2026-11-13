{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the FontEditor library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.FontEditor;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.FontEditor.Types in '..\Libs\FontEditor\DelphiDoom.FontEditor.Types.pas',
  DelphiDoom.FontEditor.Intf in '..\Libs\FontEditor\DelphiDoom.FontEditor.Intf.pas',
  DelphiDoom.FontEditor.Presenter in '..\Libs\FontEditor\DelphiDoom.FontEditor.Presenter.pas',
  DelphiDoom.Tools.Factory in '..\Libs\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Tools.PathText in '..\Libs\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Font.Factory in '..\Libs\Font\DelphiDoom.Font.Factory.pas',
  DelphiDoom.Font.SettingsFormat in '..\Libs\Font\DelphiDoom.Font.SettingsFormat.pas',
  DelphiDoom.Font.LumpNames in '..\Libs\Font\DelphiDoom.Font.LumpNames.pas',
  DelphiDoom.Wad.Factory in '..\Libs\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Palette.GamePalettes in '..\Libs\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Imaging.PatchWriter in '..\Libs\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Font.Types in '..\Libs\Font\DelphiDoom.Font.Types.pas',
  DelphiDoom.Tools.Intf in '..\Libs\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Font.Settings in '..\Libs\Font\DelphiDoom.Font.Settings.pas',
  DelphiDoom.Font.Intf in '..\Libs\Font\DelphiDoom.Font.Intf.pas',
  DelphiDoom.Tools.Types in '..\Libs\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.UndoHistory in '..\Libs\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\Libs\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\Libs\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\Libs\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\Libs\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Wad.Intf in '..\Libs\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Libs\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Font.TextComposer in '..\Libs\Font\DelphiDoom.Font.TextComposer.pas',
  DelphiDoom.Font.GridComposer in '..\Libs\Font\DelphiDoom.Font.GridComposer.pas',
  DelphiDoom.Font.Exporter in '..\Libs\Font\DelphiDoom.Font.Exporter.pas',
  DelphiDoom.Font.WadGenerator in '..\Libs\Font\DelphiDoom.Font.WadGenerator.pas',
  DelphiDoom.Wad.Types in '..\Libs\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Pak.Intf in '..\Libs\Wad\DelphiDoom.Wad.Pak.Intf.pas',
  DelphiDoom.Wad.Directory in '..\Libs\Wad\DelphiDoom.Wad.Directory.pas',
  DelphiDoom.Wad.LumpCache in '..\Libs\Wad\DelphiDoom.Wad.LumpCache.pas',
  DelphiDoom.Wad.Builder in '..\Libs\Wad\DelphiDoom.Wad.Builder.pas',
  DelphiDoom.Wad.Source.Wad in '..\Libs\Wad\DelphiDoom.Wad.Source.Wad.pas',
  DelphiDoom.Wad.Source.Wad2 in '..\Libs\Wad\DelphiDoom.Wad.Source.Wad2.pas',
  DelphiDoom.Wad.Source.Pak in '..\Libs\Wad\DelphiDoom.Wad.Source.Pak.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Libs\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Source.Zip in '..\Libs\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Source.Folder in '..\Libs\Wad\DelphiDoom.Wad.Source.Folder.pas',
  DelphiDoom.Wad.Source.SingleFile in '..\Libs\Wad\DelphiDoom.Wad.Source.SingleFile.pas',
  DelphiDoom.Wad.Pak.Index in '..\Libs\Wad\DelphiDoom.Wad.Pak.Index.pas',
  DelphiDoom.Wad.Pak.PathResolver in '..\Libs\Wad\DelphiDoom.Wad.Pak.PathResolver.pas',
  DelphiDoom.Palette.Types in '..\Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.GamePaletteData in '..\Libs\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Palette.Intf in '..\Libs\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Font.GlyphCropper in '..\Libs\Font\DelphiDoom.Font.GlyphCropper.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Libs\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.Font.Colorizer in '..\Libs\Font\DelphiDoom.Font.Colorizer.pas',
  DelphiDoom.Wad.Pak.Types in '..\Libs\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Name in '..\Libs\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Indicators in '..\Libs\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Libs\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Pak.Names in '..\Libs\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Font.PerlinNoise in '..\Libs\Font\DelphiDoom.Font.PerlinNoise.pas',
  DelphiDoom.Tests.Sound.Digest in 'Source\DelphiDoom.Tests.Sound.Digest.pas',
  DelphiDoom.Tests.Font.SyntheticGlyphs in 'Source\DelphiDoom.Tests.Font.SyntheticGlyphs.pas',
  DelphiDoom.Tests.Font.Scenarios in 'Source\DelphiDoom.Tests.Font.Scenarios.pas',
  DelphiDoom.Tests.Font.Fakes in 'Source\DelphiDoom.Tests.Font.Fakes.pas',
  DelphiDoom.Tests.ToolsCore.Fakes in 'Source\DelphiDoom.Tests.ToolsCore.Fakes.pas',
  DelphiDoom.Tests.FontEditor.Fakes in 'Source\DelphiDoom.Tests.FontEditor.Fakes.pas',
  DelphiDoom.Tests.FontEditor.Presenter in 'Source\DelphiDoom.Tests.FontEditor.Presenter.pas';

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
