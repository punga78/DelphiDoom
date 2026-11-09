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
