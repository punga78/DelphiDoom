{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Keen;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.Keen.Types in '..\Libs\Keen\DelphiDoom.Keen.Types.pas',
  DelphiDoom.Keen.LittleEndian in '..\Libs\Keen\DelphiDoom.Keen.LittleEndian.pas',
  DelphiDoom.Keen.Intf in '..\Libs\Keen\DelphiDoom.Keen.Intf.pas',
  DelphiDoom.Keen.Huffman in '..\Libs\Keen\DelphiDoom.Keen.Huffman.pas',
  DelphiDoom.Keen.Rlew in '..\Libs\Keen\DelphiDoom.Keen.Rlew.pas',
  DelphiDoom.Keen.MemoryFiles in '..\Libs\Keen\DelphiDoom.Keen.MemoryFiles.pas',
  DelphiDoom.Keen.FolderFiles in '..\Libs\Keen\DelphiDoom.Keen.FolderFiles.pas',
  DelphiDoom.Keen.FileNames in '..\Libs\Keen\DelphiDoom.Keen.FileNames.pas',
  DelphiDoom.Keen.OffsetTable in '..\Libs\Keen\DelphiDoom.Keen.OffsetTable.pas',
  DelphiDoom.Keen.GraphicsLayout in '..\Libs\Keen\DelphiDoom.Keen.GraphicsLayout.pas',
  DelphiDoom.Keen.ExplicitLayout in '..\Libs\Keen\DelphiDoom.Keen.ExplicitLayout.pas',
  DelphiDoom.Keen.ChunkSource in '..\Libs\Keen\DelphiDoom.Keen.ChunkSource.pas',
  DelphiDoom.Keen.Map in '..\Libs\Keen\DelphiDoom.Keen.Map.pas',
  DelphiDoom.Keen.TileInfo in '..\Libs\Keen\DelphiDoom.Keen.TileInfo.pas',
  DelphiDoom.Keen.MapSource in '..\Libs\Keen\DelphiDoom.Keen.MapSource.pas',
  DelphiDoom.Keen.Graphics in '..\Libs\Keen\DelphiDoom.Keen.Graphics.pas',
  DelphiDoom.Keen.EgaPalette in '..\Libs\Keen\DelphiDoom.Keen.EgaPalette.pas',
  DelphiDoom.Keen.PlanarConverter in '..\Libs\Keen\DelphiDoom.Keen.PlanarConverter.pas',
  DelphiDoom.Keen.MapRenderer in '..\Libs\Keen\DelphiDoom.Keen.MapRenderer.pas',
  DelphiDoom.Keen.PngEncoder in '..\Libs\Keen\DelphiDoom.Keen.PngEncoder.pas',
  DelphiDoom.Keen.MapExporter in '..\Libs\Keen\DelphiDoom.Keen.MapExporter.pas',
  DelphiDoom.Keen.GameData in '..\Libs\Keen\DelphiDoom.Keen.GameData.pas',
  DelphiDoom.Keen.GameLoader in '..\Libs\Keen\DelphiDoom.Keen.GameLoader.pas',
  DelphiDoom.Keen.Arithmetic in '..\Libs\Keen\DelphiDoom.Keen.Arithmetic.pas',
  DelphiDoom.Keen.EgaMemory in '..\Libs\Keen\DelphiDoom.Keen.EgaMemory.pas',
  DelphiDoom.Keen.SpriteShifter in '..\Libs\Keen\DelphiDoom.Keen.SpriteShifter.pas',
  DelphiDoom.Keen.SpriteCache in '..\Libs\Keen\DelphiDoom.Keen.SpriteCache.pas',
  DelphiDoom.Keen.Video in '..\Libs\Keen\DelphiDoom.Keen.Video.pas',
  DelphiDoom.Keen.DisplayCapture in '..\Libs\Keen\DelphiDoom.Keen.DisplayCapture.pas',
  DelphiDoom.Keen.WorkingMap in '..\Libs\Keen\DelphiDoom.Keen.WorkingMap.pas',
  DelphiDoom.Keen.Refresh in '..\Libs\Keen\DelphiDoom.Keen.Refresh.pas',
  DelphiDoom.Keen.ManualClock in '..\Libs\Keen\DelphiDoom.Keen.ManualClock.pas',
  DelphiDoom.Keen.InputTypes in '..\Libs\Keen\DelphiDoom.Keen.InputTypes.pas',
  DelphiDoom.Keen.ScanTables in '..\Libs\Keen\DelphiDoom.Keen.ScanTables.pas',
  DelphiDoom.Keen.DemoTape in '..\Libs\Keen\DelphiDoom.Keen.DemoTape.pas',
  DelphiDoom.Keen.Input in '..\Libs\Keen\DelphiDoom.Keen.Input.pas',
  DelphiDoom.Keen.KeyboardPump in '..\Libs\Keen\DelphiDoom.Keen.KeyboardPump.pas',
  DelphiDoom.Keen.MouseAdapter in '..\Libs\Keen\DelphiDoom.Keen.MouseAdapter.pas',
  DelphiDoom.Keen.JoystickAdapter in '..\Libs\Keen\DelphiDoom.Keen.JoystickAdapter.pas',
  DelphiDoom.Keen.ViewExporter in '..\Libs\Keen\DelphiDoom.Keen.ViewExporter.pas',
  DelphiDoom.Keen.StateTypes in '..\Libs\Keen\DelphiDoom.Keen.StateTypes.pas',
  DelphiDoom.Keen.GameTypes in '..\Libs\Keen\DelphiDoom.Keen.GameTypes.pas',
  DelphiDoom.Keen.GraphicsIds in '..\Libs\Keen\DelphiDoom.Keen.GraphicsIds.pas',
  DelphiDoom.Keen.AudioIds in '..\Libs\Keen\DelphiDoom.Keen.AudioIds.pas',
  DelphiDoom.Keen.ActionIds in '..\Libs\Keen\DelphiDoom.Keen.ActionIds.pas',
  DelphiDoom.Keen.StateTable in '..\Libs\Keen\DelphiDoom.Keen.StateTable.pas',
  DelphiDoom.Keen.StateTableCopy in '..\Libs\Keen\DelphiDoom.Keen.StateTableCopy.pas',
  DelphiDoom.Keen.Random in '..\Libs\Keen\DelphiDoom.Keen.Random.pas',
  DelphiDoom.Keen.ObjectList in '..\Libs\Keen\DelphiDoom.Keen.ObjectList.pas',
  DelphiDoom.Keen.ActorMover in '..\Libs\Keen\DelphiDoom.Keen.ActorMover.pas',
  DelphiDoom.Keen.StateMachine in '..\Libs\Keen\DelphiDoom.Keen.StateMachine.pas',
  DelphiDoom.Keen.LevelScanner in '..\Libs\Keen\DelphiDoom.Keen.LevelScanner.pas',
  DelphiDoom.Keen.PlayLoop in '..\Libs\Keen\DelphiDoom.Keen.PlayLoop.pas',
  DelphiDoom.Keen.Factory in '..\Libs\Keen\DelphiDoom.Keen.Factory.pas',
  DelphiDoom.Tests.Keen.VideoFakes in 'Source\DelphiDoom.Tests.Keen.VideoFakes.pas',
  DelphiDoom.Tests.Keen.EgaMemory in 'Source\DelphiDoom.Tests.Keen.EgaMemory.pas',
  DelphiDoom.Tests.Keen.SpriteShifter in 'Source\DelphiDoom.Tests.Keen.SpriteShifter.pas',
  DelphiDoom.Tests.Keen.SpriteCache in 'Source\DelphiDoom.Tests.Keen.SpriteCache.pas',
  DelphiDoom.Tests.Keen.Video in 'Source\DelphiDoom.Tests.Keen.Video.pas',
  DelphiDoom.Tests.Keen.Refresh in 'Source\DelphiDoom.Tests.Keen.Refresh.pas',
  DelphiDoom.Tests.Keen.RefreshRealData in 'Source\DelphiDoom.Tests.Keen.RefreshRealData.pas',
  DelphiDoom.Tests.Keen.DemoTape in 'Source\DelphiDoom.Tests.Keen.DemoTape.pas',
  DelphiDoom.Tests.Keen.InputFakes in 'Source\DelphiDoom.Tests.Keen.InputFakes.pas',
  DelphiDoom.Tests.Keen.Input in 'Source\DelphiDoom.Tests.Keen.Input.pas',
  DelphiDoom.Tests.Keen.InputAdapters in 'Source\DelphiDoom.Tests.Keen.InputAdapters.pas',
  DelphiDoom.Tests.Keen.GameFakes in 'Source\DelphiDoom.Tests.Keen.GameFakes.pas',
  DelphiDoom.Tests.Keen.GameWorld in 'Source\DelphiDoom.Tests.Keen.GameWorld.pas',
  DelphiDoom.Tests.Keen.GameObjects in 'Source\DelphiDoom.Tests.Keen.GameObjects.pas',
  DelphiDoom.Tests.Keen.ActorMover in 'Source\DelphiDoom.Tests.Keen.ActorMover.pas',
  DelphiDoom.Tests.Keen.StateMachine in 'Source\DelphiDoom.Tests.Keen.StateMachine.pas',
  DelphiDoom.Tests.Keen.LevelScanner in 'Source\DelphiDoom.Tests.Keen.LevelScanner.pas',
  DelphiDoom.Tests.Keen.LevelScannerRealData in 'Source\DelphiDoom.Tests.Keen.LevelScannerRealData.pas',
  DelphiDoom.Tests.Keen.PlayLoop in 'Source\DelphiDoom.Tests.Keen.PlayLoop.pas',
  DelphiDoom.Tests.Keen.Builders in 'Source\DelphiDoom.Tests.Keen.Builders.pas',
  DelphiDoom.Tests.Keen.RealData in 'Source\DelphiDoom.Tests.Keen.RealData.pas',
  DelphiDoom.Tests.Keen.Types in 'Source\DelphiDoom.Tests.Keen.Types.pas',
  DelphiDoom.Tests.Keen.LittleEndian in 'Source\DelphiDoom.Tests.Keen.LittleEndian.pas',
  DelphiDoom.Tests.Keen.Huffman in 'Source\DelphiDoom.Tests.Keen.Huffman.pas',
  DelphiDoom.Tests.Keen.Rlew in 'Source\DelphiDoom.Tests.Keen.Rlew.pas',
  DelphiDoom.Tests.Keen.MemoryFiles in 'Source\DelphiDoom.Tests.Keen.MemoryFiles.pas',
  DelphiDoom.Tests.Keen.FolderFiles in 'Source\DelphiDoom.Tests.Keen.FolderFiles.pas',
  DelphiDoom.Tests.Keen.FileNames in 'Source\DelphiDoom.Tests.Keen.FileNames.pas',
  DelphiDoom.Tests.Keen.OffsetTable in 'Source\DelphiDoom.Tests.Keen.OffsetTable.pas',
  DelphiDoom.Tests.Keen.ChunkSource in 'Source\DelphiDoom.Tests.Keen.ChunkSource.pas',
  DelphiDoom.Tests.Keen.Graphics in 'Source\DelphiDoom.Tests.Keen.Graphics.pas',
  DelphiDoom.Tests.Keen.MapSource in 'Source\DelphiDoom.Tests.Keen.MapSource.pas',
  DelphiDoom.Tests.Keen.Map in 'Source\DelphiDoom.Tests.Keen.Map.pas',
  DelphiDoom.Tests.Keen.TileInfo in 'Source\DelphiDoom.Tests.Keen.TileInfo.pas',
  DelphiDoom.Tests.Keen.PlanarConverter in 'Source\DelphiDoom.Tests.Keen.PlanarConverter.pas',
  DelphiDoom.Tests.Keen.EgaPalette in 'Source\DelphiDoom.Tests.Keen.EgaPalette.pas',
  DelphiDoom.Tests.Keen.MapRenderer in 'Source\DelphiDoom.Tests.Keen.MapRenderer.pas',
  DelphiDoom.Tests.Keen.PngEncoder in 'Source\DelphiDoom.Tests.Keen.PngEncoder.pas',
  DelphiDoom.Tests.Keen.MapExporter in 'Source\DelphiDoom.Tests.Keen.MapExporter.pas',
  DelphiDoom.Tests.Keen.GameLoader in 'Source\DelphiDoom.Tests.Keen.GameLoader.pas',
  DelphiDoom.Tests.Keen.Golden in 'Source\DelphiDoom.Tests.Keen.Golden.pas';

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
