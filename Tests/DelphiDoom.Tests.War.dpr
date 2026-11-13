{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the war library (DUnitX)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.War;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.War.Types in '..\Libs\War\DelphiDoom.War.Types.pas',
  DelphiDoom.War.Intf in '..\Libs\War\DelphiDoom.War.Intf.pas',
  DelphiDoom.War.LittleEndian in '..\Libs\War\DelphiDoom.War.LittleEndian.pas',
  DelphiDoom.War.Decompressor in '..\Libs\War\DelphiDoom.War.Decompressor.pas',
  DelphiDoom.War.Archive in '..\Libs\War\DelphiDoom.War.Archive.pas',
  DelphiDoom.War.StreamSource in '..\Libs\War\DelphiDoom.War.StreamSource.pas',
  DelphiDoom.War.Catalog.Data in '..\Libs\War\DelphiDoom.War.Catalog.Data.pas',
  DelphiDoom.War.Catalog in '..\Libs\War\DelphiDoom.War.Catalog.pas',
  DelphiDoom.War.Factory in '..\Libs\War\DelphiDoom.War.Factory.pas',
  DelphiDoom.War.Graphics.Types in '..\Libs\War\DelphiDoom.War.Graphics.Types.pas',
  DelphiDoom.War.Graphics.Intf in '..\Libs\War\DelphiDoom.War.Graphics.Intf.pas',
  DelphiDoom.War.Graphics.PaletteDecoder in '..\Libs\War\DelphiDoom.War.Graphics.PaletteDecoder.pas',
  DelphiDoom.War.Graphics.PaletteComposer in '..\Libs\War\DelphiDoom.War.Graphics.PaletteComposer.pas',
  DelphiDoom.War.Graphics.ColorLookup in '..\Libs\War\DelphiDoom.War.Graphics.ColorLookup.pas',
  DelphiDoom.War.Graphics.ImageDecoder in '..\Libs\War\DelphiDoom.War.Graphics.ImageDecoder.pas',
  DelphiDoom.War.Graphics.SpriteDecoder in '..\Libs\War\DelphiDoom.War.Graphics.SpriteDecoder.pas',
  DelphiDoom.War.Graphics.CursorDecoder in '..\Libs\War\DelphiDoom.War.Graphics.CursorDecoder.pas',
  DelphiDoom.War.Graphics.TilesetDecoder in '..\Libs\War\DelphiDoom.War.Graphics.TilesetDecoder.pas',
  DelphiDoom.War.Graphics in '..\Libs\War\DelphiDoom.War.Graphics.pas',
  DelphiDoom.War.Font.Types in '..\Libs\War\DelphiDoom.War.Font.Types.pas',
  DelphiDoom.War.Font.Intf in '..\Libs\War\DelphiDoom.War.Font.Intf.pas',
  DelphiDoom.War.Font.Data in '..\Libs\War\DelphiDoom.War.Font.Data.pas',
  DelphiDoom.War.Font.Metrics in '..\Libs\War\DelphiDoom.War.Font.Metrics.pas',
  DelphiDoom.Tests.War.Builders in 'Source\DelphiDoom.Tests.War.Builders.pas',
  DelphiDoom.Tests.War.RealData in 'Source\DelphiDoom.Tests.War.RealData.pas',
  DelphiDoom.Tests.War.Types in 'Source\DelphiDoom.Tests.War.Types.pas',
  DelphiDoom.Tests.War.Decompressor in 'Source\DelphiDoom.Tests.War.Decompressor.pas',
  DelphiDoom.Tests.War.Archive in 'Source\DelphiDoom.Tests.War.Archive.pas',
  DelphiDoom.Tests.War.Catalog in 'Source\DelphiDoom.Tests.War.Catalog.pas',
  DelphiDoom.Tests.War.StreamSource in 'Source\DelphiDoom.Tests.War.StreamSource.pas',
  DelphiDoom.Tests.War.Parity in 'Source\DelphiDoom.Tests.War.Parity.pas',
  DelphiDoom.Tests.War.PngWriter in 'Source\DelphiDoom.Tests.War.PngWriter.pas',
  DelphiDoom.Tests.War.Palette in 'Source\DelphiDoom.Tests.War.Palette.pas',
  DelphiDoom.Tests.War.Pixels in 'Source\DelphiDoom.Tests.War.Pixels.pas',
  DelphiDoom.Tests.War.Graphics in 'Source\DelphiDoom.Tests.War.Graphics.pas',
  DelphiDoom.Tests.War.Font in 'Source\DelphiDoom.Tests.War.Font.pas',
  DelphiDoom.Tests.War.GraphicsParity in 'Source\DelphiDoom.Tests.War.GraphicsParity.pas',
  DelphiDoom.War.Level.Types in '..\Libs\War\DelphiDoom.War.Level.Types.pas',
  DelphiDoom.War.Level.Intf in '..\Libs\War\DelphiDoom.War.Level.Intf.pas',
  DelphiDoom.War.Level.InfoReader in '..\Libs\War\DelphiDoom.War.Level.InfoReader.pas',
  DelphiDoom.War.Level.MapReader in '..\Libs\War\DelphiDoom.War.Level.MapReader.pas',
  DelphiDoom.War.Level in '..\Libs\War\DelphiDoom.War.Level.pas',
  DelphiDoom.War.Level.Loader in '..\Libs\War\DelphiDoom.War.Level.Loader.pas',
  DelphiDoom.War.Campaign.Types in '..\Libs\War\DelphiDoom.War.Campaign.Types.pas',
  DelphiDoom.War.Campaign.Intf in '..\Libs\War\DelphiDoom.War.Campaign.Intf.pas',
  DelphiDoom.War.Campaign.Data in '..\Libs\War\DelphiDoom.War.Campaign.Data.pas',
  DelphiDoom.War.Campaign.Catalog in '..\Libs\War\DelphiDoom.War.Campaign.Catalog.pas',
  DelphiDoom.War.Campaign.Objectives in '..\Libs\War\DelphiDoom.War.Campaign.Objectives.pas',
  DelphiDoom.War.Level.Factory in '..\Libs\War\DelphiDoom.War.Level.Factory.pas',
  DelphiDoom.War.Autotile.Types in '..\Libs\War\DelphiDoom.War.Autotile.Types.pas',
  DelphiDoom.War.Autotile.Data in '..\Libs\War\DelphiDoom.War.Autotile.Data.pas',
  DelphiDoom.War.Autotile.Line in '..\Libs\War\DelphiDoom.War.Autotile.Line.pas',
  DelphiDoom.War.Autotile.Ruins in '..\Libs\War\DelphiDoom.War.Autotile.Ruins.pas',
  DelphiDoom.War.Autotile.Forest in '..\Libs\War\DelphiDoom.War.Autotile.Forest.pas',
  DelphiDoom.War.Map.Grid in '..\Libs\War\DelphiDoom.War.Map.Grid.pas',
  DelphiDoom.Tests.War.Level in 'Source\DelphiDoom.Tests.War.Level.pas',
  DelphiDoom.Tests.War.LevelParity in 'Source\DelphiDoom.Tests.War.LevelParity.pas',
  DelphiDoom.Tests.War.Campaign in 'Source\DelphiDoom.Tests.War.Campaign.pas',
  DelphiDoom.Tests.War.Autotile in 'Source\DelphiDoom.Tests.War.Autotile.pas',
  DelphiDoom.Tests.War.MapGrid in 'Source\DelphiDoom.Tests.War.MapGrid.pas';

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
