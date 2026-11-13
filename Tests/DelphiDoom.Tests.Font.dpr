{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Font library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Font;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Font.Types in '..\Libs\Font\DelphiDoom.Font.Types.pas',
  DelphiDoom.Font.Settings in '..\Libs\Font\DelphiDoom.Font.Settings.pas',
  DelphiDoom.Font.SettingsFormat in '..\Libs\Font\DelphiDoom.Font.SettingsFormat.pas',
  DelphiDoom.Font.Intf in '..\Libs\Font\DelphiDoom.Font.Intf.pas',
  DelphiDoom.Font.GlyphCropper in '..\Libs\Font\DelphiDoom.Font.GlyphCropper.pas',
  DelphiDoom.Font.TextComposer in '..\Libs\Font\DelphiDoom.Font.TextComposer.pas',
  DelphiDoom.Font.GridComposer in '..\Libs\Font\DelphiDoom.Font.GridComposer.pas',
  DelphiDoom.Font.PerlinNoise in '..\Libs\Font\DelphiDoom.Font.PerlinNoise.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Libs\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.Font.Colorizer in '..\Libs\Font\DelphiDoom.Font.Colorizer.pas',
  DelphiDoom.Font.Exporter in '..\Libs\Font\DelphiDoom.Font.Exporter.pas',
  DelphiDoom.Font.LumpNames in '..\Libs\Font\DelphiDoom.Font.LumpNames.pas',
  DelphiDoom.Font.WadGenerator in '..\Libs\Font\DelphiDoom.Font.WadGenerator.pas',
  DelphiDoom.Font.Factory in '..\Libs\Font\DelphiDoom.Font.Factory.pas',
  DelphiDoom.Wad.Factory in '..\Libs\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Palette.GamePalettes in '..\Libs\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Libs\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Imaging.PatchWriter in '..\Libs\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Imaging.Factory in '..\Libs\Imaging\DelphiDoom.Imaging.Factory.pas',
  DelphiDoom.Palette.Types in '..\Libs\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.Intf in '..\Libs\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Imaging.Intf in '..\Libs\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Wad.Intf in '..\Libs\Wad\DelphiDoom.Wad.Intf.pas',
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
  DelphiDoom.Palette.GamePaletteData in '..\Libs\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.ColumnPainter in '..\Libs\Imaging\DelphiDoom.Imaging.ColumnPainter.pas',
  DelphiDoom.Imaging.ColumnRebuilder in '..\Libs\Imaging\DelphiDoom.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Imaging.FixedColumn in '..\Libs\Imaging\DelphiDoom.Imaging.FixedColumn.pas',
  DelphiDoom.Imaging.PatchReader in '..\Libs\Imaging\DelphiDoom.Imaging.PatchReader.pas',
  DelphiDoom.Imaging.FlatReader in '..\Libs\Imaging\DelphiDoom.Imaging.FlatReader.pas',
  DelphiDoom.Imaging.FlatShrinker in '..\Libs\Imaging\DelphiDoom.Imaging.FlatShrinker.pas',
  DelphiDoom.Imaging.SpanGrower in '..\Libs\Imaging\DelphiDoom.Imaging.SpanGrower.pas',
  DelphiDoom.Imaging.ColumnExpander in '..\Libs\Imaging\DelphiDoom.Imaging.ColumnExpander.pas',
  DelphiDoom.Imaging.HiResTables in '..\Libs\Imaging\DelphiDoom.Imaging.HiResTables.pas',
  DelphiDoom.Imaging.MeltWipe in '..\Libs\Imaging\DelphiDoom.Imaging.MeltWipe.pas',
  DelphiDoom.Imaging.SineTable in '..\Libs\Imaging\DelphiDoom.Imaging.SineTable.pas',
  DelphiDoom.Imaging.WallScale in '..\Libs\Imaging\DelphiDoom.Imaging.WallScale.pas',
  DelphiDoom.Imaging.ThumbnailBuilder in '..\Libs\Imaging\DelphiDoom.Imaging.ThumbnailBuilder.pas',
  DelphiDoom.Wad.Pak.Types in '..\Libs\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Name in '..\Libs\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Indicators in '..\Libs\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Libs\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Pak.Names in '..\Libs\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Imaging.ColorMath in '..\Libs\Imaging\DelphiDoom.Imaging.ColorMath.pas',
  DelphiDoom.Tests.Sound.Digest in 'Source\DelphiDoom.Tests.Sound.Digest.pas',
  DelphiDoom.Tests.Font.SyntheticGlyphs in 'Source\DelphiDoom.Tests.Font.SyntheticGlyphs.pas',
  DelphiDoom.Tests.Font.Scenarios in 'Source\DelphiDoom.Tests.Font.Scenarios.pas',
  DelphiDoom.Tests.Font.Golden in 'Source\DelphiDoom.Tests.Font.Golden.pas',
  DelphiDoom.Tests.Font.Fakes in 'Source\DelphiDoom.Tests.Font.Fakes.pas',
  DelphiDoom.Tests.Font.Settings in 'Source\DelphiDoom.Tests.Font.Settings.pas',
  DelphiDoom.Tests.Font.PerlinNoise in 'Source\DelphiDoom.Tests.Font.PerlinNoise.pas',
  DelphiDoom.Tests.Font.Colorizer in 'Source\DelphiDoom.Tests.Font.Colorizer.pas',
  DelphiDoom.Tests.Font.GlyphCropper in 'Source\DelphiDoom.Tests.Font.GlyphCropper.pas',
  DelphiDoom.Tests.Font.TextComposer in 'Source\DelphiDoom.Tests.Font.TextComposer.pas',
  DelphiDoom.Tests.Font.Exporter in 'Source\DelphiDoom.Tests.Font.Exporter.pas',
  DelphiDoom.Tests.Font.LumpNames in 'Source\DelphiDoom.Tests.Font.LumpNames.pas',
  DelphiDoom.Tests.Font.WadGenerator in 'Source\DelphiDoom.Tests.Font.WadGenerator.pas';

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
