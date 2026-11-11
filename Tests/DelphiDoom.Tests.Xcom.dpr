{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom formats library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Xcom;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Xcom.Types in '..\Libs\XcomFormats\DelphiDoom.Xcom.Types.pas',
  DelphiDoom.Xcom.BinaryReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.BinaryReader.pas',
  DelphiDoom.Xcom.Palette in '..\Libs\XcomFormats\DelphiDoom.Xcom.Palette.pas',
  DelphiDoom.Xcom.Image in '..\Libs\XcomFormats\DelphiDoom.Xcom.Image.pas',
  DelphiDoom.Xcom.Map in '..\Libs\XcomFormats\DelphiDoom.Xcom.Map.pas',
  DelphiDoom.Xcom.Intf in '..\Libs\XcomFormats\DelphiDoom.Xcom.Intf.pas',
  DelphiDoom.Xcom.PckDecoder in '..\Libs\XcomFormats\DelphiDoom.Xcom.PckDecoder.pas',
  DelphiDoom.Xcom.DatDecoder in '..\Libs\XcomFormats\DelphiDoom.Xcom.DatDecoder.pas',
  DelphiDoom.Xcom.ScrDecoder in '..\Libs\XcomFormats\DelphiDoom.Xcom.ScrDecoder.pas',
  DelphiDoom.Xcom.SpkDecoder in '..\Libs\XcomFormats\DelphiDoom.Xcom.SpkDecoder.pas',
  DelphiDoom.Xcom.BdyDecoder in '..\Libs\XcomFormats\DelphiDoom.Xcom.BdyDecoder.pas',
  DelphiDoom.Xcom.PaletteReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.PaletteReader.pas',
  DelphiDoom.Xcom.CatArchive in '..\Libs\XcomFormats\DelphiDoom.Xcom.CatArchive.pas',
  DelphiDoom.Xcom.MapReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.MapReader.pas',
  DelphiDoom.Xcom.RouteReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.RouteReader.pas',
  DelphiDoom.Xcom.McdReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.McdReader.pas',
  DelphiDoom.Xcom.WorldReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.WorldReader.pas',
  DelphiDoom.Xcom.WordTableReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.WordTableReader.pas',
  DelphiDoom.Xcom.LbmReader in '..\Libs\XcomFormats\DelphiDoom.Xcom.LbmReader.pas',
  DelphiDoom.Xcom.BattlescapePalette in '..\Libs\XcomFormats\DelphiDoom.Xcom.BattlescapePalette.pas',
  DelphiDoom.Xcom.MemoryFiles in '..\Libs\XcomFormats\DelphiDoom.Xcom.MemoryFiles.pas',
  DelphiDoom.Xcom.FolderFiles in '..\Libs\XcomFormats\DelphiDoom.Xcom.FolderFiles.pas',
  DelphiDoom.Xcom.GameData in '..\Libs\XcomFormats\DelphiDoom.Xcom.GameData.pas',
  DelphiDoom.Xcom.SpriteSheet in '..\Libs\XcomFormats\DelphiDoom.Xcom.SpriteSheet.pas',
  DelphiDoom.Xcom.MapPicture in '..\Libs\XcomFormats\DelphiDoom.Xcom.MapPicture.pas',
  DelphiDoom.Xcom.PngEncoder in '..\Libs\XcomFormats\DelphiDoom.Xcom.PngEncoder.pas',
  DelphiDoom.Xcom.ImageExporter in '..\Libs\XcomFormats\DelphiDoom.Xcom.ImageExporter.pas',
  DelphiDoom.Xcom.Factory in '..\Libs\XcomFormats\DelphiDoom.Xcom.Factory.pas',
  DelphiDoom.Xcom.ExportArguments in '..\OpenXcom\DelphiDoom.Xcom.ExportArguments.pas',
  DelphiDoom.Tests.Xcom.Builders in'Source\DelphiDoom.Tests.Xcom.Builders.pas',
  DelphiDoom.Tests.Xcom.Cases in 'Source\DelphiDoom.Tests.Xcom.Cases.pas',
  DelphiDoom.Tests.Xcom.Types in 'Source\DelphiDoom.Tests.Xcom.Types.pas',
  DelphiDoom.Tests.Xcom.BinaryReader in 'Source\DelphiDoom.Tests.Xcom.BinaryReader.pas',
  DelphiDoom.Tests.Xcom.Palette in 'Source\DelphiDoom.Tests.Xcom.Palette.pas',
  DelphiDoom.Tests.Xcom.Image in 'Source\DelphiDoom.Tests.Xcom.Image.pas',
  DelphiDoom.Tests.Xcom.PckDecoder in 'Source\DelphiDoom.Tests.Xcom.PckDecoder.pas',
  DelphiDoom.Tests.Xcom.DatDecoder in 'Source\DelphiDoom.Tests.Xcom.DatDecoder.pas',
  DelphiDoom.Tests.Xcom.ScrDecoder in 'Source\DelphiDoom.Tests.Xcom.ScrDecoder.pas',
  DelphiDoom.Tests.Xcom.SpkDecoder in 'Source\DelphiDoom.Tests.Xcom.SpkDecoder.pas',
  DelphiDoom.Tests.Xcom.BdyDecoder in 'Source\DelphiDoom.Tests.Xcom.BdyDecoder.pas',
  DelphiDoom.Tests.Xcom.PaletteReader in 'Source\DelphiDoom.Tests.Xcom.PaletteReader.pas',
  DelphiDoom.Tests.Xcom.CatArchive in 'Source\DelphiDoom.Tests.Xcom.CatArchive.pas',
  DelphiDoom.Tests.Xcom.MapReader in 'Source\DelphiDoom.Tests.Xcom.MapReader.pas',
  DelphiDoom.Tests.Xcom.RouteReader in 'Source\DelphiDoom.Tests.Xcom.RouteReader.pas',
  DelphiDoom.Tests.Xcom.McdReader in 'Source\DelphiDoom.Tests.Xcom.McdReader.pas',
  DelphiDoom.Tests.Xcom.WorldReader in 'Source\DelphiDoom.Tests.Xcom.WorldReader.pas',
  DelphiDoom.Tests.Xcom.WordTableReader in 'Source\DelphiDoom.Tests.Xcom.WordTableReader.pas',
  DelphiDoom.Tests.Xcom.MemoryFiles in 'Source\DelphiDoom.Tests.Xcom.MemoryFiles.pas',
  DelphiDoom.Tests.Xcom.FolderFiles in 'Source\DelphiDoom.Tests.Xcom.FolderFiles.pas',
  DelphiDoom.Tests.Xcom.GameData in 'Source\DelphiDoom.Tests.Xcom.GameData.pas',
  DelphiDoom.Tests.Xcom.SpriteSheet in 'Source\DelphiDoom.Tests.Xcom.SpriteSheet.pas',
  DelphiDoom.Tests.Xcom.MapPicture in 'Source\DelphiDoom.Tests.Xcom.MapPicture.pas',
  DelphiDoom.Tests.Xcom.PngEncoder in 'Source\DelphiDoom.Tests.Xcom.PngEncoder.pas',
  DelphiDoom.Tests.Xcom.ImageExporter in 'Source\DelphiDoom.Tests.Xcom.ImageExporter.pas',
  DelphiDoom.Tests.Xcom.LbmReader in 'Source\DelphiDoom.Tests.Xcom.LbmReader.pas',
  DelphiDoom.Tests.Xcom.BattlescapePalette in 'Source\DelphiDoom.Tests.Xcom.BattlescapePalette.pas',
  DelphiDoom.Tests.Xcom.ExportArguments in 'Source\DelphiDoom.Tests.Xcom.ExportArguments.pas',
  DelphiDoom.Tests.Xcom.RealData in'Source\DelphiDoom.Tests.Xcom.RealData.pas',
  DelphiDoom.Tests.Xcom.Golden in 'Source\DelphiDoom.Tests.Xcom.Golden.pas';

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
