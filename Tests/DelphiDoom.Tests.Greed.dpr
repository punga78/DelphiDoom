{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the greed library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Greed;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.Greed.Types in '..\Libs\Greed\DelphiDoom.Greed.Types.pas',
  DelphiDoom.Greed.LittleEndian in '..\Libs\Greed\DelphiDoom.Greed.LittleEndian.pas',
  DelphiDoom.Greed.Intf in '..\Libs\Greed\DelphiDoom.Greed.Intf.pas',
  DelphiDoom.Greed.PstCorrection in '..\Libs\Greed\DelphiDoom.Greed.PstCorrection.pas',
  DelphiDoom.Greed.LumpFixes in '..\Libs\Greed\DelphiDoom.Greed.LumpFixes.pas',
  DelphiDoom.Greed.BloArchive in '..\Libs\Greed\DelphiDoom.Greed.BloArchive.pas',
  DelphiDoom.Greed.FolderFiles in '..\Libs\Greed\DelphiDoom.Greed.FolderFiles.pas',
  DelphiDoom.Greed.Map in '..\Libs\Greed\DelphiDoom.Greed.Map.pas',
  DelphiDoom.Greed.MapReader in '..\Libs\Greed\DelphiDoom.Greed.MapReader.pas',
  DelphiDoom.Greed.MapLoader in '..\Libs\Greed\DelphiDoom.Greed.MapLoader.pas',
  DelphiDoom.Greed.Palette in '..\Libs\Greed\DelphiDoom.Greed.Palette.pas',
  DelphiDoom.Greed.PictureDecoder in '..\Libs\Greed\DelphiDoom.Greed.PictureDecoder.pas',
  DelphiDoom.Greed.FlatDecoder in '..\Libs\Greed\DelphiDoom.Greed.FlatDecoder.pas',
  DelphiDoom.Greed.WallDecoder in '..\Libs\Greed\DelphiDoom.Greed.WallDecoder.pas',
  DelphiDoom.Greed.SpriteDecoder in '..\Libs\Greed\DelphiDoom.Greed.SpriteDecoder.pas',
  DelphiDoom.Greed.LumpClassifier in '..\Libs\Greed\DelphiDoom.Greed.LumpClassifier.pas',
  DelphiDoom.Greed.PngEncoder in '..\Libs\Greed\DelphiDoom.Greed.PngEncoder.pas',
  DelphiDoom.Greed.MapRenderer in '..\Libs\Greed\DelphiDoom.Greed.MapRenderer.pas',
  DelphiDoom.Greed.PngExporter in '..\Libs\Greed\DelphiDoom.Greed.PngExporter.pas',
  DelphiDoom.Greed.Factory in '..\Libs\Greed\DelphiDoom.Greed.Factory.pas',
  DelphiDoom.Greed.Composition in '..\Greed\DelphiDoom.Greed.Composition.pas',
  DelphiDoom.Tests.Greed.Builders in 'Source\DelphiDoom.Tests.Greed.Builders.pas',
  DelphiDoom.Tests.Greed.RealData in 'Source\DelphiDoom.Tests.Greed.RealData.pas',
  DelphiDoom.Tests.Greed.Types in 'Source\DelphiDoom.Tests.Greed.Types.pas',
  DelphiDoom.Tests.Greed.LittleEndian in 'Source\DelphiDoom.Tests.Greed.LittleEndian.pas',
  DelphiDoom.Tests.Greed.BloArchive in 'Source\DelphiDoom.Tests.Greed.BloArchive.pas',
  DelphiDoom.Tests.Greed.LumpFixes in 'Source\DelphiDoom.Tests.Greed.LumpFixes.pas',
  DelphiDoom.Tests.Greed.Map in 'Source\DelphiDoom.Tests.Greed.Map.pas',
  DelphiDoom.Tests.Greed.MapLoader in 'Source\DelphiDoom.Tests.Greed.MapLoader.pas',
  DelphiDoom.Tests.Greed.FolderFiles in 'Source\DelphiDoom.Tests.Greed.FolderFiles.pas',
  DelphiDoom.Tests.Greed.Palette in 'Source\DelphiDoom.Tests.Greed.Palette.pas',
  DelphiDoom.Tests.Greed.ImageDecoders in 'Source\DelphiDoom.Tests.Greed.ImageDecoders.pas',
  DelphiDoom.Tests.Greed.LumpClassifier in 'Source\DelphiDoom.Tests.Greed.LumpClassifier.pas',
  DelphiDoom.Tests.Greed.PngEncoder in 'Source\DelphiDoom.Tests.Greed.PngEncoder.pas',
  DelphiDoom.Tests.Greed.MapRenderer in 'Source\DelphiDoom.Tests.Greed.MapRenderer.pas',
  DelphiDoom.Tests.Greed.PngExporter in 'Source\DelphiDoom.Tests.Greed.PngExporter.pas',
  DelphiDoom.Tests.Greed.Factory in 'Source\DelphiDoom.Tests.Greed.Factory.pas',
  DelphiDoom.Tests.Greed.Golden in 'Source\DelphiDoom.Tests.Greed.Golden.pas';

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
