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
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.Greed.FixedMath in '..\Libs\Greed\DelphiDoom.Greed.FixedMath.pas',
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
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Audio.Types in '..\Libs\Audio\DelphiDoom.Audio.Types.pas',
  DelphiDoom.Audio.Intf in '..\Libs\Audio\DelphiDoom.Audio.Intf.pas',
  DelphiDoom.Audio.WaveParser in '..\Libs\Audio\DelphiDoom.Audio.WaveParser.pas',
  DelphiDoom.Greed.Sound.Intf in '..\Libs\Greed\DelphiDoom.Greed.Sound.Intf.pas',
  DelphiDoom.Greed.AudioDevice in '..\Libs\Greed\DelphiDoom.Greed.AudioDevice.pas',
  DelphiDoom.Greed.TrigTables in '..\Libs\Greed\DelphiDoom.Greed.TrigTables.pas',
  DelphiDoom.Greed.SoundVolumes in '..\Libs\Greed\DelphiDoom.Greed.SoundVolumes.pas',
  DelphiDoom.Greed.SoundGeometry in '..\Libs\Greed\DelphiDoom.Greed.SoundGeometry.pas',
  DelphiDoom.Greed.SoundEffects in '..\Libs\Greed\DelphiDoom.Greed.SoundEffects.pas',
  DelphiDoom.Greed.Music in '..\Libs\Greed\DelphiDoom.Greed.Music.pas',
  DelphiDoom.Greed.SongSelector in '..\Libs\Greed\DelphiDoom.Greed.SongSelector.pas',
  DelphiDoom.Greed.SaveTypes in '..\Libs\Greed\DelphiDoom.Greed.SaveTypes.pas',
  DelphiDoom.Greed.Save.Intf in '..\Libs\Greed\DelphiDoom.Greed.Save.Intf.pas',
  DelphiDoom.Greed.SaveGames in '..\Libs\Greed\DelphiDoom.Greed.SaveGames.pas',
  DelphiDoom.Greed.SaveFolder in '..\Libs\Greed\DelphiDoom.Greed.SaveFolder.pas',
  DelphiDoom.Greed.Settings.Intf in '..\Libs\Greed\DelphiDoom.Greed.Settings.Intf.pas',
  DelphiDoom.Greed.Settings in '..\Libs\Greed\DelphiDoom.Greed.Settings.pas',
  DelphiDoom.Greed.SettingsStore in '..\Libs\Greed\DelphiDoom.Greed.SettingsStore.pas',
  DelphiDoom.Greed.World.Intf in '..\Libs\Greed\DelphiDoom.Greed.World.Intf.pas',
  DelphiDoom.Greed.Slopes in '..\Libs\Greed\DelphiDoom.Greed.Slopes.pas',
  DelphiDoom.Greed.World in '..\Libs\Greed\DelphiDoom.Greed.World.pas',
  DelphiDoom.Greed.Terrain in '..\Libs\Greed\DelphiDoom.Greed.Terrain.pas',
  DelphiDoom.Greed.Player.Intf in '..\Libs\Greed\DelphiDoom.Greed.Player.Intf.pas',
  DelphiDoom.Greed.PlayerRules in '..\Libs\Greed\DelphiDoom.Greed.PlayerRules.pas',
  DelphiDoom.Greed.Actor.Types in '..\Libs\Greed\DelphiDoom.Greed.Actor.Types.pas',
  DelphiDoom.Greed.LinkedPool in '..\Libs\Greed\DelphiDoom.Greed.LinkedPool.pas',
  DelphiDoom.Greed.Elevator.Intf in '..\Libs\Greed\DelphiDoom.Greed.Elevator.Intf.pas',
  DelphiDoom.Greed.ElevatorRules in '..\Libs\Greed\DelphiDoom.Greed.ElevatorRules.pas',
  DelphiDoom.Greed.PlayerMovement in '..\Libs\Greed\DelphiDoom.Greed.PlayerMovement.pas',
  DelphiDoom.Greed.SpriteDeath in '..\Libs\Greed\DelphiDoom.Greed.SpriteDeath.pas',
  DelphiDoom.Clock.Intf in '..\Libs\Clock\DelphiDoom.Clock.Intf.pas',
  DelphiDoom.Greed.Frame.Intf in '..\Libs\Greed\DelphiDoom.Greed.Frame.Intf.pas',
  DelphiDoom.Greed.TopDownRenderer in '..\Libs\Greed\DelphiDoom.Greed.TopDownRenderer.pas',
  DelphiDoom.Greed.GameLoop in '..\Libs\Greed\DelphiDoom.Greed.GameLoop.pas',
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
  DelphiDoom.Tests.Greed.FixedMath in 'Source\DelphiDoom.Tests.Greed.FixedMath.pas',
  DelphiDoom.Tests.Audio.Fakes in 'Source\DelphiDoom.Tests.Audio.Fakes.pas',
  DelphiDoom.Tests.Greed.AudioDevice in 'Source\DelphiDoom.Tests.Greed.AudioDevice.pas',
  DelphiDoom.Tests.Greed.SoundFakes in 'Source\DelphiDoom.Tests.Greed.SoundFakes.pas',
  DelphiDoom.Tests.Greed.TrigTables in 'Source\DelphiDoom.Tests.Greed.TrigTables.pas',
  DelphiDoom.Tests.Greed.SoundGeometry in 'Source\DelphiDoom.Tests.Greed.SoundGeometry.pas',
  DelphiDoom.Tests.Greed.SoundEffects in 'Source\DelphiDoom.Tests.Greed.SoundEffects.pas',
  DelphiDoom.Tests.Greed.Music in 'Source\DelphiDoom.Tests.Greed.Music.pas',
  DelphiDoom.Tests.Greed.SongSelector in 'Source\DelphiDoom.Tests.Greed.SongSelector.pas',
  DelphiDoom.Tests.Greed.SaveGames in 'Source\DelphiDoom.Tests.Greed.SaveGames.pas',
  DelphiDoom.Tests.Greed.SaveFolder in 'Source\DelphiDoom.Tests.Greed.SaveFolder.pas',
  DelphiDoom.Tests.Greed.Settings in 'Source\DelphiDoom.Tests.Greed.Settings.pas',
  DelphiDoom.Tests.Greed.Terrain in 'Source\DelphiDoom.Tests.Greed.Terrain.pas',
  DelphiDoom.Tests.Greed.PlayerRules in 'Source\DelphiDoom.Tests.Greed.PlayerRules.pas',
  DelphiDoom.Tests.Greed.Actors in 'Source\DelphiDoom.Tests.Greed.Actors.pas',
  DelphiDoom.Tests.Greed.PlayerMovement in 'Source\DelphiDoom.Tests.Greed.PlayerMovement.pas',
  DelphiDoom.Tests.Greed.SpriteDeath in 'Source\DelphiDoom.Tests.Greed.SpriteDeath.pas',
  DelphiDoom.Tests.Greed.GameLoop in 'Source\DelphiDoom.Tests.Greed.GameLoop.pas',
  DelphiDoom.Greed.Random in '..\Libs\Greed\DelphiDoom.Greed.Random.pas',
  DelphiDoom.Greed.Render.Types in '..\Libs\Greed\DelphiDoom.Greed.Render.Types.pas',
  DelphiDoom.Greed.Render.Assets.Intf in '..\Libs\Greed\DelphiDoom.Greed.Render.Assets.Intf.pas',
  DelphiDoom.Greed.Render.ArchiveAssets in '..\Libs\Greed\DelphiDoom.Greed.Render.ArchiveAssets.pas',
  DelphiDoom.Greed.Render.Tables in '..\Libs\Greed\DelphiDoom.Greed.Render.Tables.pas',
  DelphiDoom.Greed.Render.State in '..\Libs\Greed\DelphiDoom.Greed.Render.State.pas',
  DelphiDoom.Greed.Render.SpanSorter in '..\Libs\Greed\DelphiDoom.Greed.Render.SpanSorter.pas',
  DelphiDoom.Greed.Render.WallRenderer in '..\Libs\Greed\DelphiDoom.Greed.Render.WallRenderer.pas',
  DelphiDoom.Greed.Render.PlaneRenderer in '..\Libs\Greed\DelphiDoom.Greed.Render.PlaneRenderer.pas',
  DelphiDoom.Greed.Render.ContentRenderer in '..\Libs\Greed\DelphiDoom.Greed.Render.ContentRenderer.pas',
  DelphiDoom.Greed.Render.SpanDrawer in '..\Libs\Greed\DelphiDoom.Greed.Render.SpanDrawer.pas',
  DelphiDoom.Greed.Render.SpriteInterpolator in '..\Libs\Greed\DelphiDoom.Greed.Render.SpriteInterpolator.pas',
  DelphiDoom.Greed.Render.FrameRenderer in '..\Libs\Greed\DelphiDoom.Greed.Render.FrameRenderer.pas',
  DelphiDoom.Tests.Greed.RenderScenarios in 'Source\DelphiDoom.Tests.Greed.RenderScenarios.pas',
  DelphiDoom.Tests.Greed.RenderRunner in 'Source\DelphiDoom.Tests.Greed.RenderRunner.pas',
  DelphiDoom.Tests.Greed.Render in 'Source\DelphiDoom.Tests.Greed.Render.pas',
  DelphiDoom.Greed.Door.Intf in '..\Libs\Greed\DelphiDoom.Greed.Door.Intf.pas',
  DelphiDoom.Greed.DoorRules in '..\Libs\Greed\DelphiDoom.Greed.DoorRules.pas',
  DelphiDoom.Greed.DoorSpawner in '..\Libs\Greed\DelphiDoom.Greed.DoorSpawner.pas',
  DelphiDoom.Greed.HostAudio in '..\Greed\DelphiDoom.Greed.HostAudio.pas',
  DelphiDoom.Greed.TrackerSongDecoder in '..\Greed\DelphiDoom.Greed.TrackerSongDecoder.pas',
  DelphiDoom.Tests.Greed.PcmMixer in 'Source\DelphiDoom.Tests.Greed.PcmMixer.pas',
  DelphiDoom.Tests.Greed.PlayerScenarios in 'Source\DelphiDoom.Tests.Greed.PlayerScenarios.pas',
  DelphiDoom.Tests.Greed.PlayerControl in 'Source\DelphiDoom.Tests.Greed.PlayerControl.pas',
  DelphiDoom.Tests.Greed.Doors in 'Source\DelphiDoom.Tests.Greed.Doors.pas',
  DelphiDoom.Tests.Greed.GameTables in 'Source\DelphiDoom.Tests.Greed.GameTables.pas',
  DelphiDoom.Tests.Greed.GameState in 'Source\DelphiDoom.Tests.Greed.GameState.pas',
  DelphiDoom.Tests.Greed.SpawnScenarios in 'Source\DelphiDoom.Tests.Greed.SpawnScenarios.pas',
  DelphiDoom.Tests.Greed.Spawner in 'Source\DelphiDoom.Tests.Greed.Spawner.pas',
  DelphiDoom.Tests.Greed.MonsterPictureFix in 'Source\DelphiDoom.Tests.Greed.MonsterPictureFix.pas',
  DelphiDoom.Tests.Greed.Golden in 'Source\DelphiDoom.Tests.Greed.Golden.pas',
  DelphiDoom.Tests.Greed.SpriteScenarios in 'Source\DelphiDoom.Tests.Greed.SpriteScenarios.pas',
  DelphiDoom.Tests.Greed.SpriteRunner in 'Source\DelphiDoom.Tests.Greed.SpriteRunner.pas',
  DelphiDoom.Tests.Greed.SpriteLogic in 'Source\DelphiDoom.Tests.Greed.SpriteLogic.pas',
  DelphiDoom.Tests.Greed.EventScenarios in 'Source\DelphiDoom.Tests.Greed.EventScenarios.pas',
  DelphiDoom.Tests.Greed.Events in 'Source\DelphiDoom.Tests.Greed.Events.pas',
  DelphiDoom.Greed.HostWindow in '..\Greed\DelphiDoom.Greed.HostWindow.pas',
  DelphiDoom.Tests.Greed.HostWindow in 'Source\DelphiDoom.Tests.Greed.HostWindow.pas';

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
