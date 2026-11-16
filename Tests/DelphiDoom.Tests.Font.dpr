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
  DelphiDoom.Font.Types in '..\Strumenti\Font\DelphiDoom.Font.Types.pas',
  DelphiDoom.Font.Settings in '..\Strumenti\Font\DelphiDoom.Font.Settings.pas',
  DelphiDoom.Font.SettingsFormat in '..\Strumenti\Font\DelphiDoom.Font.SettingsFormat.pas',
  DelphiDoom.Font.Intf in '..\Strumenti\Font\DelphiDoom.Font.Intf.pas',
  DelphiDoom.Font.GlyphCropper in '..\Strumenti\Font\DelphiDoom.Font.GlyphCropper.pas',
  DelphiDoom.Font.TextComposer in '..\Strumenti\Font\DelphiDoom.Font.TextComposer.pas',
  DelphiDoom.Font.GridComposer in '..\Strumenti\Font\DelphiDoom.Font.GridComposer.pas',
  DelphiDoom.Font.PerlinNoise in '..\Strumenti\Font\DelphiDoom.Font.PerlinNoise.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Framework\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.Font.Colorizer in '..\Strumenti\Font\DelphiDoom.Font.Colorizer.pas',
  DelphiDoom.Font.Exporter in '..\Strumenti\Font\DelphiDoom.Font.Exporter.pas',
  DelphiDoom.Font.LumpNames in '..\Strumenti\Font\DelphiDoom.Font.LumpNames.pas',
  DelphiDoom.Font.WadGenerator in '..\Strumenti\Font\DelphiDoom.Font.WadGenerator.pas',
  DelphiDoom.Font.Factory in '..\Strumenti\Font\DelphiDoom.Font.Factory.pas',
  DelphiDoom.Wad.Factory in '..\Framework\Wad\DelphiDoom.Wad.Factory.pas',
  DelphiDoom.Palette.GamePalettes in '..\Framework\Palette\DelphiDoom.Palette.GamePalettes.pas',
  DelphiDoom.Palette.ColorMatcher in '..\Framework\Palette\DelphiDoom.Palette.ColorMatcher.pas',
  DelphiDoom.Palette.NearestColor in '..\Framework\Palette\DelphiDoom.Palette.NearestColor.pas',
  DelphiDoom.Imaging.PatchWriter in '..\Framework\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Imaging.Factory in '..\Framework\Imaging\DelphiDoom.Imaging.Factory.pas',
  DelphiDoom.Imaging.ColorPatchBuilder in '..\Framework\Imaging\DelphiDoom.Imaging.ColorPatchBuilder.pas',
  DelphiDoom.Palette.Types in '..\Framework\Palette\DelphiDoom.Palette.Types.pas',
  DelphiDoom.Palette.Intf in '..\Framework\Palette\DelphiDoom.Palette.Intf.pas',
  DelphiDoom.Imaging.Intf in '..\Framework\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Wad.Intf in '..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
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
  DelphiDoom.Palette.GamePaletteData in '..\Framework\Palette\DelphiDoom.Palette.GamePaletteData.pas',
  DelphiDoom.Imaging.Types in '..\Framework\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.ColumnPainter in '..\Framework\Imaging\DelphiDoom.Imaging.ColumnPainter.pas',
  DelphiDoom.Imaging.ColumnRebuilder in '..\Framework\Imaging\DelphiDoom.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Imaging.FixedColumn in '..\Framework\Imaging\DelphiDoom.Imaging.FixedColumn.pas',
  DelphiDoom.Imaging.PatchReader in '..\Framework\Imaging\DelphiDoom.Imaging.PatchReader.pas',
  DelphiDoom.Imaging.FlatReader in '..\Framework\Imaging\DelphiDoom.Imaging.FlatReader.pas',
  DelphiDoom.Imaging.FlatShrinker in '..\Framework\Imaging\DelphiDoom.Imaging.FlatShrinker.pas',
  DelphiDoom.Imaging.SpanGrower in '..\Framework\Imaging\DelphiDoom.Imaging.SpanGrower.pas',
  DelphiDoom.Imaging.ColumnExpander in '..\Framework\Imaging\DelphiDoom.Imaging.ColumnExpander.pas',
  DelphiDoom.Imaging.HiResTables in '..\Framework\Imaging\DelphiDoom.Imaging.HiResTables.pas',
  DelphiDoom.Imaging.MeltWipe in '..\Framework\Imaging\DelphiDoom.Imaging.MeltWipe.pas',
  DelphiDoom.Imaging.SineTable in '..\Framework\Imaging\DelphiDoom.Imaging.SineTable.pas',
  DelphiDoom.Imaging.WallScale in '..\Framework\Imaging\DelphiDoom.Imaging.WallScale.pas',
  DelphiDoom.Imaging.ThumbnailBuilder in '..\Framework\Imaging\DelphiDoom.Imaging.ThumbnailBuilder.pas',
  DelphiDoom.Wad.Pak.Types in '..\Framework\Wad\DelphiDoom.Wad.Pak.Types.pas',
  DelphiDoom.Wad.Name in '..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Indicators in '..\Framework\Wad\DelphiDoom.Wad.Indicators.pas',
  DelphiDoom.Wad.Source.Base in '..\Framework\Wad\DelphiDoom.Wad.Source.Base.pas',
  DelphiDoom.Wad.Pak.Names in '..\Framework\Wad\DelphiDoom.Wad.Pak.Names.pas',
  DelphiDoom.Imaging.ColorMath in '..\Framework\Imaging\DelphiDoom.Imaging.ColorMath.pas',
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
