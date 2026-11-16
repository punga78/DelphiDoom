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
  DelphiDoom.MathCore.Crc32 in '..\Framework\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.Keen.Types in '..\Games\Keen\DelphiDoom.Keen.Types.pas',
  DelphiDoom.Keen.LittleEndian in '..\Games\Keen\DelphiDoom.Keen.LittleEndian.pas',
  DelphiDoom.Keen.Intf in '..\Games\Keen\DelphiDoom.Keen.Intf.pas',
  DelphiDoom.Keen.UserTypes in '..\Games\Keen\DelphiDoom.Keen.UserTypes.pas',
  DelphiDoom.Keen.UserIntf in '..\Games\Keen\DelphiDoom.Keen.UserIntf.pas',
  DelphiDoom.Keen.Huffman in '..\Games\Keen\DelphiDoom.Keen.Huffman.pas',
  DelphiDoom.Keen.Rlew in '..\Games\Keen\DelphiDoom.Keen.Rlew.pas',
  DelphiDoom.Keen.MemoryFiles in '..\Games\Keen\DelphiDoom.Keen.MemoryFiles.pas',
  DelphiDoom.Keen.FolderFiles in '..\Games\Keen\DelphiDoom.Keen.FolderFiles.pas',
  DelphiDoom.Keen.FileNames in '..\Games\Keen\DelphiDoom.Keen.FileNames.pas',
  DelphiDoom.Keen.OffsetTable in '..\Games\Keen\DelphiDoom.Keen.OffsetTable.pas',
  DelphiDoom.Keen.GraphicsLayout in '..\Games\Keen\DelphiDoom.Keen.GraphicsLayout.pas',
  DelphiDoom.Keen.ExplicitLayout in '..\Games\Keen\DelphiDoom.Keen.ExplicitLayout.pas',
  DelphiDoom.Keen.ChunkSource in '..\Games\Keen\DelphiDoom.Keen.ChunkSource.pas',
  DelphiDoom.Keen.Map in '..\Games\Keen\DelphiDoom.Keen.Map.pas',
  DelphiDoom.Keen.TileInfo in '..\Games\Keen\DelphiDoom.Keen.TileInfo.pas',
  DelphiDoom.Keen.MapSource in '..\Games\Keen\DelphiDoom.Keen.MapSource.pas',
  DelphiDoom.Keen.Graphics in '..\Games\Keen\DelphiDoom.Keen.Graphics.pas',
  DelphiDoom.Keen.EgaPalette in '..\Games\Keen\DelphiDoom.Keen.EgaPalette.pas',
  DelphiDoom.Keen.PlanarConverter in '..\Games\Keen\DelphiDoom.Keen.PlanarConverter.pas',
  DelphiDoom.Keen.MapRenderer in '..\Games\Keen\DelphiDoom.Keen.MapRenderer.pas',
  DelphiDoom.Keen.PngEncoder in '..\Games\Keen\DelphiDoom.Keen.PngEncoder.pas',
  DelphiDoom.Keen.MapExporter in '..\Games\Keen\DelphiDoom.Keen.MapExporter.pas',
  DelphiDoom.Keen.GameData in '..\Games\Keen\DelphiDoom.Keen.GameData.pas',
  DelphiDoom.Keen.GameLoader in '..\Games\Keen\DelphiDoom.Keen.GameLoader.pas',
  DelphiDoom.Keen.Arithmetic in '..\Games\Keen\DelphiDoom.Keen.Arithmetic.pas',
  DelphiDoom.Keen.EgaMemory in '..\Games\Keen\DelphiDoom.Keen.EgaMemory.pas',
  DelphiDoom.Keen.SpriteShifter in '..\Games\Keen\DelphiDoom.Keen.SpriteShifter.pas',
  DelphiDoom.Keen.SpriteCache in '..\Games\Keen\DelphiDoom.Keen.SpriteCache.pas',
  DelphiDoom.Keen.Video in '..\Games\Keen\DelphiDoom.Keen.Video.pas',
  DelphiDoom.Keen.DisplayCapture in '..\Games\Keen\DelphiDoom.Keen.DisplayCapture.pas',
  DelphiDoom.Keen.WorkingMap in '..\Games\Keen\DelphiDoom.Keen.WorkingMap.pas',
  DelphiDoom.Keen.Refresh in '..\Games\Keen\DelphiDoom.Keen.Refresh.pas',
  DelphiDoom.Keen.ManualClock in '..\Games\Keen\DelphiDoom.Keen.ManualClock.pas',
  DelphiDoom.Clock.Intf in '..\Framework\Clock\DelphiDoom.Clock.Intf.pas',
  DelphiDoom.Clock.ManualClock in '..\Framework\Clock\DelphiDoom.Clock.ManualClock.pas',
  DelphiDoom.Keen.HostClock in '..\Games\Keen\DelphiDoom.Keen.HostClock.pas',
  DelphiDoom.Keen.SaveFormat in '..\Games\Keen\DelphiDoom.Keen.SaveFormat.pas',
  DelphiDoom.Keen.LzExe in '..\Games\Keen\DelphiDoom.Keen.LzExe.pas',
  DelphiDoom.Keen.DosStateLocator in '..\Games\Keen\DelphiDoom.Keen.DosStateLocator.pas',
  DelphiDoom.Keen.DosSaveConverter in '..\Games\Keen\DelphiDoom.Keen.DosSaveConverter.pas',
  DelphiDoom.Keen.LoopProfile in '..\Games\Keen\DelphiDoom.Keen.LoopProfile.pas',
  DelphiDoom.Keen.InputTypes in '..\Games\Keen\DelphiDoom.Keen.InputTypes.pas',
  DelphiDoom.Keen.ScanTables in '..\Games\Keen\DelphiDoom.Keen.ScanTables.pas',
  DelphiDoom.Keen.DemoTape in '..\Games\Keen\DelphiDoom.Keen.DemoTape.pas',
  DelphiDoom.Keen.Input in '..\Games\Keen\DelphiDoom.Keen.Input.pas',
  DelphiDoom.Keen.KeyboardPump in '..\Games\Keen\DelphiDoom.Keen.KeyboardPump.pas',
  DelphiDoom.Keen.MouseAdapter in '..\Games\Keen\DelphiDoom.Keen.MouseAdapter.pas',
  DelphiDoom.Keen.JoystickAdapter in '..\Games\Keen\DelphiDoom.Keen.JoystickAdapter.pas',
  DelphiDoom.Keen.ViewExporter in '..\Games\Keen\DelphiDoom.Keen.ViewExporter.pas',
  DelphiDoom.Keen.StateTypes in '..\Games\Keen\DelphiDoom.Keen.StateTypes.pas',
  DelphiDoom.Keen.GameTypes in '..\Games\Keen\DelphiDoom.Keen.GameTypes.pas',
  DelphiDoom.Keen.GraphicsIds in '..\Games\Keen\DelphiDoom.Keen.GraphicsIds.pas',
  DelphiDoom.Keen.AudioIds in '..\Games\Keen\DelphiDoom.Keen.AudioIds.pas',
  DelphiDoom.Keen.ActionIds in '..\Games\Keen\DelphiDoom.Keen.ActionIds.pas',
  DelphiDoom.Keen.StateTable in '..\Games\Keen\DelphiDoom.Keen.StateTable.pas',
  DelphiDoom.Keen.StateTableCopy in '..\Games\Keen\DelphiDoom.Keen.StateTableCopy.pas',
  DelphiDoom.Keen.Random in '..\Games\Keen\DelphiDoom.Keen.Random.pas',
  DelphiDoom.Keen.ObjectList in '..\Games\Keen\DelphiDoom.Keen.ObjectList.pas',
  DelphiDoom.Keen.ActorMover in '..\Games\Keen\DelphiDoom.Keen.ActorMover.pas',
  DelphiDoom.Keen.StateMachine in '..\Games\Keen\DelphiDoom.Keen.StateMachine.pas',
  DelphiDoom.Keen.LevelScanner in '..\Games\Keen\DelphiDoom.Keen.LevelScanner.pas',
  DelphiDoom.Keen.PlayState in '..\Games\Keen\DelphiDoom.Keen.PlayState.pas',
  DelphiDoom.Keen.UnmanagedObject in '..\Games\Keen\DelphiDoom.Keen.UnmanagedObject.pas',
  DelphiDoom.Keen.ActionContext in '..\Games\Keen\DelphiDoom.Keen.ActionContext.pas',
  DelphiDoom.Keen.ActionAdapters in '..\Games\Keen\DelphiDoom.Keen.ActionAdapters.pas',
  DelphiDoom.Keen.CommonActions in '..\Games\Keen\DelphiDoom.Keen.CommonActions.pas',
  DelphiDoom.Keen.Act1Actions in '..\Games\Keen\DelphiDoom.Keen.Act1Actions.pas',
  DelphiDoom.Keen.Act2Actions in '..\Games\Keen\DelphiDoom.Keen.Act2Actions.pas',
  DelphiDoom.Keen.ScoreBox in '..\Games\Keen\DelphiDoom.Keen.ScoreBox.pas',
  DelphiDoom.Keen.PlayerActions in '..\Games\Keen\DelphiDoom.Keen.PlayerActions.pas',
  DelphiDoom.Keen.GameActions in '..\Games\Keen\DelphiDoom.Keen.GameActions.pas',
  DelphiDoom.Keen.PcSpeaker in '..\Games\Keen\DelphiDoom.Keen.PcSpeaker.pas',
  DelphiDoom.Keen.AdLibSound in '..\Games\Keen\DelphiDoom.Keen.AdLibSound.pas',
  DelphiDoom.Keen.AdLibPlayer in '..\Games\Keen\DelphiDoom.Keen.AdLibPlayer.pas',
  DelphiDoom.Keen.SoundManager in '..\Games\Keen\DelphiDoom.Keen.SoundManager.pas',
  DelphiDoom.Keen.SpeakerSynth in '..\Games\Keen\DelphiDoom.Keen.SpeakerSynth.pas',
  DelphiDoom.Keen.OplAdLib in '..\Games\Keen\DelphiDoom.Keen.OplAdLib.pas',
  DelphiDoom.Keen.AudioLock in '..\Games\Keen\DelphiDoom.Keen.AudioLock.pas',
  DelphiDoom.Keen.AudioMixer in '..\Games\Keen\DelphiDoom.Keen.AudioMixer.pas',
  DelphiDoom.Keen.LockedSoundManager in '..\Games\Keen\DelphiDoom.Keen.LockedSoundManager.pas',
  DelphiDoom.Keen.PlayLoop in '..\Games\Keen\DelphiDoom.Keen.PlayLoop.pas',
  DelphiDoom.Keen.Font in '..\Games\Keen\DelphiDoom.Keen.Font.pas',
  DelphiDoom.Keen.BufferedVideo in '..\Games\Keen\DelphiDoom.Keen.BufferedVideo.pas',
  DelphiDoom.Keen.Fader in '..\Games\Keen\DelphiDoom.Keen.Fader.pas',
  DelphiDoom.Keen.UserWindows in '..\Games\Keen\DelphiDoom.Keen.UserWindows.pas',
  DelphiDoom.Keen.UserFiles in '..\Games\Keen\DelphiDoom.Keen.UserFiles.pas',
  DelphiDoom.Keen.UserState in '..\Games\Keen\DelphiDoom.Keen.UserState.pas',
  DelphiDoom.Keen.ConfigStore in '..\Games\Keen\DelphiDoom.Keen.ConfigStore.pas',
  DelphiDoom.Keen.HighScores in '..\Games\Keen\DelphiDoom.Keen.HighScores.pas',
  DelphiDoom.Keen.SaveSlots in '..\Games\Keen\DelphiDoom.Keen.SaveSlots.pas',
  DelphiDoom.Keen.ControlPanel in '..\Games\Keen\DelphiDoom.Keen.ControlPanel.pas',
  DelphiDoom.Keen.Script in '..\Games\Keen\DelphiDoom.Keen.Script.pas',
  DelphiDoom.Keen.ScriptedHost in '..\Games\Keen\DelphiDoom.Keen.ScriptedHost.pas',
  DelphiDoom.Keen.LateActions in '..\Games\Keen\DelphiDoom.Keen.LateActions.pas',
  DelphiDoom.Keen.LateEvents in '..\Games\Keen\DelphiDoom.Keen.LateEvents.pas',
  DelphiDoom.Keen.LevelSetup in '..\Games\Keen\DelphiDoom.Keen.LevelSetup.pas',
  DelphiDoom.Keen.GameSaver in '..\Games\Keen\DelphiDoom.Keen.GameSaver.pas',
  DelphiDoom.Keen.Game in '..\Games\Keen\DelphiDoom.Keen.Game.pas',
  DelphiDoom.Keen.Lzh in '..\Games\Keen\DelphiDoom.Keen.Lzh.pas',
  DelphiDoom.Keen.ShapeLibrary in '..\Games\Keen\DelphiDoom.Keen.ShapeLibrary.pas',
  DelphiDoom.Keen.Shape in '..\Games\Keen\DelphiDoom.Keen.Shape.pas',
  DelphiDoom.Keen.DemoLoop in '..\Games\Keen\DelphiDoom.Keen.DemoLoop.pas',
  DelphiDoom.Keen.HelpFiles in '..\Games\Keen\DelphiDoom.Keen.HelpFiles.pas',
  DelphiDoom.Keen.GameFactory in '..\Games\Keen\DelphiDoom.Keen.GameFactory.pas',
  DelphiDoom.Keen.ScreenPicture in '..\Games\Keen\DelphiDoom.Keen.ScreenPicture.pas',
  DelphiDoom.Keen.SoundJournal in '..\Games\Keen\DelphiDoom.Keen.SoundJournal.pas',
  DelphiDoom.Keen.Factory in '..\Games\Keen\DelphiDoom.Keen.Factory.pas',
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
  DelphiDoom.Tests.Keen.ActionScenarios in 'Source\DelphiDoom.Tests.Keen.ActionScenarios.pas',
  DelphiDoom.Tests.Keen.ActionsParity in 'Source\DelphiDoom.Tests.Keen.ActionsParity.pas',
  DelphiDoom.Tests.Keen.GameActions in 'Source\DelphiDoom.Tests.Keen.GameActions.pas',
  DelphiDoom.Tests.Keen.Sound in 'Source\DelphiDoom.Tests.Keen.Sound.pas',
  DelphiDoom.Tests.Keen.AdLib in 'Source\DelphiDoom.Tests.Keen.AdLib.pas',
  DelphiDoom.Tests.Keen.AdLibScenarios in 'Source\DelphiDoom.Tests.Keen.AdLibScenarios.pas',
  DelphiDoom.Tests.Keen.AdLibParity in 'Source\DelphiDoom.Tests.Keen.AdLibParity.pas',
  DelphiDoom.Tests.Keen.Audio in 'Source\DelphiDoom.Tests.Keen.Audio.pas',
  DelphiDoom.Tests.Keen.UiWorld in 'Source\DelphiDoom.Tests.Keen.UiWorld.pas',
  DelphiDoom.Tests.Keen.Font in 'Source\DelphiDoom.Tests.Keen.Font.pas',
  DelphiDoom.Tests.Keen.BufferedVideo in 'Source\DelphiDoom.Tests.Keen.BufferedVideo.pas',
  DelphiDoom.Tests.Keen.UserWindows in 'Source\DelphiDoom.Tests.Keen.UserWindows.pas',
  DelphiDoom.Tests.Keen.UserFiles in 'Source\DelphiDoom.Tests.Keen.UserFiles.pas',
  DelphiDoom.Tests.Keen.Script in 'Source\DelphiDoom.Tests.Keen.Script.pas',
  DelphiDoom.Tests.Keen.ControlPanel in 'Source\DelphiDoom.Tests.Keen.ControlPanel.pas',
  DelphiDoom.Tests.Keen.GameSaver in 'Source\DelphiDoom.Tests.Keen.GameSaver.pas',
  DelphiDoom.Tests.Keen.Lzh in 'Source\DelphiDoom.Tests.Keen.Lzh.pas',
  DelphiDoom.Tests.Keen.DemoLoop in 'Source\DelphiDoom.Tests.Keen.DemoLoop.pas',
  DelphiDoom.Tests.Keen.GameSession in 'Source\DelphiDoom.Tests.Keen.GameSession.pas',
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
  DelphiDoom.Tests.Keen.Golden in 'Source\DelphiDoom.Tests.Keen.Golden.pas',
  DelphiDoom.Tests.Keen.HostClock in 'Source\DelphiDoom.Tests.Keen.HostClock.pas',
  DelphiDoom.Tests.Keen.LoopProfile in 'Source\DelphiDoom.Tests.Keen.LoopProfile.pas',
  DelphiDoom.Keen.ScriptedDevices in '..\Games\Keen\DelphiDoom.Keen.ScriptedDevices.pas',
  DelphiDoom.Keen.Parameters in '..\Games\Keen\DelphiDoom.Keen.Parameters.pas',
  DelphiDoom.Tests.Keen.InputDevices in 'Source\DelphiDoom.Tests.Keen.InputDevices.pas',
  DelphiDoom.Tests.Keen.Parameters in 'Source\DelphiDoom.Tests.Keen.Parameters.pas',
  DelphiDoom.Tests.Keen.DosSave in 'Source\DelphiDoom.Tests.Keen.DosSave.pas',
  DelphiDoom.Tests.Keen.SaveFormat in 'Source\DelphiDoom.Tests.Keen.SaveFormat.pas';

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
