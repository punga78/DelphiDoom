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
  DelphiDoom.FontEditor.Types in '..\Strumenti\FontEditor\DelphiDoom.FontEditor.Types.pas',
  DelphiDoom.FontEditor.Intf in '..\Strumenti\FontEditor\DelphiDoom.FontEditor.Intf.pas',
  DelphiDoom.FontEditor.Presenter in '..\Strumenti\FontEditor\DelphiDoom.FontEditor.Presenter.pas',
  DelphiDoom.Tools.Factory in '..\Strumenti\ToolsCore\DelphiDoom.Tools.Factory.pas',
  DelphiDoom.Tools.PathText in '..\Strumenti\ToolsCore\DelphiDoom.Tools.PathText.pas',
  DelphiDoom.Font.Factory in '..\Strumenti\Font\DelphiDoom.Font.Factory.pas',
  DelphiDoom.Font.SettingsFormat in '..\Strumenti\Font\DelphiDoom.Font.SettingsFormat.pas',
  DelphiDoom.Font.LumpNames in '..\Strumenti\Font\DelphiDoom.Font.LumpNames.pas',
  DelphiDoom.Wad.Factory in '..\Framework\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Palette.GamePalettes in '..\Framework\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Imaging.PatchWriter in '..\Framework\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Font.Types in '..\Strumenti\Font\DelphiDoom.Font.Types.pas',
  DelphiDoom.Tools.Intf in '..\Strumenti\ToolsCore\DelphiDoom.Tools.Intf.pas',
  DelphiDoom.Font.Settings in '..\Strumenti\Font\DelphiDoom.Font.Settings.pas',
  DelphiDoom.Font.Intf in '..\Strumenti\Font\DelphiDoom.Font.Intf.pas',
  DelphiDoom.Tools.Types in '..\Strumenti\ToolsCore\DelphiDoom.Tools.Types.pas',
  DelphiDoom.Tools.UndoHistory in '..\Strumenti\ToolsCore\DelphiDoom.Tools.UndoHistory.pas',
  DelphiDoom.Tools.RecentFiles in '..\Strumenti\ToolsCore\DelphiDoom.Tools.RecentFiles.pas',
  DelphiDoom.Tools.SettingsStore in '..\Strumenti\ToolsCore\DelphiDoom.Tools.SettingsStore.pas',
  DelphiDoom.Tools.ProgressReporter in '..\Strumenti\ToolsCore\DelphiDoom.Tools.ProgressReporter.pas',
  DelphiDoom.Tools.FileBackup in '..\Strumenti\ToolsCore\DelphiDoom.Tools.FileBackup.pas',
  DelphiDoom.Wad.Intf in '..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Framework\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Palette.NearestColor in '..\Framework\Palette\DelphiDoom.Palette.NearestColor.pas',
  DelphiDoom.Font.TextComposer in '..\Strumenti\Font\DelphiDoom.Font.TextComposer.pas',
  DelphiDoom.Font.GridComposer in '..\Strumenti\Font\DelphiDoom.Font.GridComposer.pas',
  DelphiDoom.Font.Exporter in '..\Strumenti\Font\DelphiDoom.Font.Exporter.pas',
  DelphiDoom.Font.WadGenerator in '..\Strumenti\Font\DelphiDoom.Font.WadGenerator.pas',
  DelphiDoom.Wad.Types in '..\Framework\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Pak.Intf in '..\Framework\Wad\DelphiDoom.Wad.Pak.Intf.pas',
  DelphiDoom.Wad.Directory in '..\Framework\Wad\DelphiDoom.Wad.Directory.pas',
  DelphiDoom.Wad.LumpCache in '..\Framework\Wad\DelphiDoom.Wad.LumpCache.pas',
  DelphiDoom.Wad.Builder in '..\Framework\Wad\DelphiDoom.Wad.Builder.pas',
  DelphiDoom.Wad.Source.Wad in '..\Framework\Wad\DelphiDoom.Wad.Source.Wad.pas',
  DelphiDoom.Wad.Source.Wad2 in '..\Framework\Wad\DelphiDoom.Wad.Source.Wad2.pas',
  DelphiDoom.Wad.Source.Pak in '..\Framework\Wad\DelphiDoom.Wad.Source.Pak.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Framework\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Source.Zip in '..\Framework\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Wad.Source.Folder in '..\Framework\Wad\DelphiDoom.Wad.Source.Folder.pas',
  DelphiDoom.Wad.Source.SingleFile in '..\Framework\Wad\DelphiDoom.Wad.Source.SingleFile.pas',
  DelphiDoom.Wad.Pak.Index in '..\Framework\Wad\DelphiDoom.Wad.Pak.Index.pas',
  DelphiDoom.Wad.Pak.PathResolver in '..\Framework\Wad\DelphiDoom.Wad.Pak.PathResolver.pas',
  DelphiDoom.Palette.Types in '..\Framework\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.GamePaletteData in '..\Framework\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Imaging.Types in '..\Framework\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Framework\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Palette.Intf in '..\Framework\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Font.GlyphCropper in '..\Strumenti\Font\DelphiDoom.Font.GlyphCropper.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Framework\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.Font.Colorizer in '..\Strumenti\Font\DelphiDoom.Font.Colorizer.pas',
  DelphiDoom.Wad.Pak.Types in '..\Framework\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Name in '..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Indicators in '..\Framework\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Framework\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Pak.Names in '..\Framework\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Font.PerlinNoise in '..\Strumenti\Font\DelphiDoom.Font.PerlinNoise.pas',
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
