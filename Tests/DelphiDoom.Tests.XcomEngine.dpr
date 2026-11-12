{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom engine library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later: see           }
{  Libs\XcomFormats\README.md)                                                  }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.XcomEngine;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Tests.XcomEngine.Compose in 'Source\DelphiDoom.Tests.XcomEngine.Compose.pas',
  DelphiDoom.Tests.XcomEngine.World in 'Source\DelphiDoom.Tests.XcomEngine.World.pas',
  DelphiDoom.Tests.XcomEngine.Core in 'Source\DelphiDoom.Tests.XcomEngine.Core.pas',
  DelphiDoom.Tests.XcomEngine.Game in 'Source\DelphiDoom.Tests.XcomEngine.Game.pas',
  DelphiDoom.Tests.XcomEngine.GamePause in 'Source\DelphiDoom.Tests.XcomEngine.GamePause.pas',
  DelphiDoom.Tests.XcomEngine.Ui in 'Source\DelphiDoom.Tests.XcomEngine.Ui.pas',
  DelphiDoom.Tests.XcomEngine.Menu in 'Source\DelphiDoom.Tests.XcomEngine.Menu.pas',
  DelphiDoom.Tests.XcomEngine.Timer in 'Source\DelphiDoom.Tests.XcomEngine.Timer.pas',
  DelphiDoom.Tests.XcomEngine.Controls in 'Source\DelphiDoom.Tests.XcomEngine.Controls.pas',
  DelphiDoom.Tests.XcomEngine.OptionsScreens in 'Source\DelphiDoom.Tests.XcomEngine.OptionsScreens.pas',
  DelphiDoom.Tests.XcomEngine.RealFrames in 'Source\DelphiDoom.Tests.XcomEngine.RealFrames.pas',
  DelphiDoom.Tests.XcomEngine.OptionsMore in 'Source\DelphiDoom.Tests.XcomEngine.OptionsMore.pas',
  DelphiDoom.Tests.XcomEngine.SaveScreens in 'Source\DelphiDoom.Tests.XcomEngine.SaveScreens.pas',
  DelphiDoom.Tests.XcomEngine.PauseSave in 'Source\DelphiDoom.Tests.XcomEngine.PauseSave.pas',
  DelphiDoom.Tests.XcomEngine.BattlescapeTheme in 'Source\DelphiDoom.Tests.XcomEngine.BattlescapeTheme.pas',
  DelphiDoom.Tests.XcomEngine.RealAudio in 'Source\DelphiDoom.Tests.XcomEngine.RealAudio.pas',
  DelphiDoom.Tests.XcomEngine.RealSounds in 'Source\DelphiDoom.Tests.XcomEngine.RealSounds.pas',
  DelphiDoom.Tests.XcomEngine.RealUfoMusic in 'Source\DelphiDoom.Tests.XcomEngine.RealUfoMusic.pas',
  DelphiDoom.Tests.XcomEngine.AudioFakes in 'Source\DelphiDoom.Tests.XcomEngine.AudioFakes.pas',
  DelphiDoom.Tests.XcomEngine.Audio in 'Source\DelphiDoom.Tests.XcomEngine.Audio.pas',
  DelphiDoom.Tests.XcomEngine.AudioMusic in 'Source\DelphiDoom.Tests.XcomEngine.AudioMusic.pas',
  DelphiDoom.Tests.XcomEngine.AudioFiles in 'Source\DelphiDoom.Tests.XcomEngine.AudioFiles.pas',
  DelphiDoom.Tests.XcomEngine.AudioFormats in 'Source\DelphiDoom.Tests.XcomEngine.AudioFormats.pas',
  DelphiDoom.Tests.XcomEngine.Mods in 'Source\DelphiDoom.Tests.XcomEngine.Mods.pas',
  DelphiDoom.Xcom.HostVideoDevice in '..\OpenXcom\DelphiDoom.Xcom.HostVideoDevice.pas',
  DelphiDoom.Xcom.HostEventSink in '..\OpenXcom\DelphiDoom.Xcom.HostEventSink.pas',
  DelphiDoom.Xcom.HostLog in '..\OpenXcom\DelphiDoom.Xcom.HostLog.pas',
  DelphiDoom.Xcom.HostPcmOutput in '..\OpenXcom\DelphiDoom.Xcom.HostPcmOutput.pas',
  DelphiDoom.Xcom.HostShaderLoader in '..\OpenXcom\DelphiDoom.Xcom.HostShaderLoader.pas',
  DelphiDoom.Tests.XcomEngine.HostAdapters in 'Source\DelphiDoom.Tests.XcomEngine.HostAdapters.pas',
  DelphiDoom.Tests.XcomEngine.VideoDeviceSelector in 'Source\DelphiDoom.Tests.XcomEngine.VideoDeviceSelector.pas',
  DelphiDoom.Tests.XcomEngine.ShaderFileReader in 'Source\DelphiDoom.Tests.XcomEngine.ShaderFileReader.pas',
  DelphiDoom.Tests.XcomEngine.FolderShaderCatalog in 'Source\DelphiDoom.Tests.XcomEngine.FolderShaderCatalog.pas',
  DelphiDoom.Tests.XcomEngine.FlcBuilder in 'Source\DelphiDoom.Tests.XcomEngine.FlcBuilder.pas',
  DelphiDoom.Tests.XcomEngine.FlcDecoder in 'Source\DelphiDoom.Tests.XcomEngine.FlcDecoder.pas',
  DelphiDoom.Tests.XcomEngine.Cutscenes in 'Source\DelphiDoom.Tests.XcomEngine.Cutscenes.pas',
  DelphiDoom.Tests.XcomEngine.RealFlc in 'Source\DelphiDoom.Tests.XcomEngine.RealFlc.pas',
  DelphiDoom.Tests.XcomEngine.UiSounds in 'Source\DelphiDoom.Tests.XcomEngine.UiSounds.pas',
  DelphiDoom.Tests.XcomEngine.WindowPlacement in 'Source\DelphiDoom.Tests.XcomEngine.WindowPlacement.pas',
  DelphiDoom.Tests.XcomEngine.TrueColorComposer in 'Source\DelphiDoom.Tests.XcomEngine.TrueColorComposer.pas',
  DelphiDoom.Tests.XcomEngine.TrueColorDisplay in 'Source\DelphiDoom.Tests.XcomEngine.TrueColorDisplay.pas',
  DelphiDoom.Xcom.TrueColorOption in '..\OpenXcom\DelphiDoom.Xcom.TrueColorOption.pas',
  DelphiDoom.Tests.XcomEngine.TrueColorOption in 'Source\DelphiDoom.Tests.XcomEngine.TrueColorOption.pas',
  DelphiDoom.Tests.XcomEngine.LineWidget in 'Source\DelphiDoom.Tests.XcomEngine.LineWidget.pas',
  DelphiDoom.Tests.XcomSurface.FakeRasterizer in 'Source\DelphiDoom.Tests.XcomSurface.FakeRasterizer.pas',
  DelphiDoom.Tests.XcomEngine.FontFakes in 'Source\DelphiDoom.Tests.XcomEngine.FontFakes.pas',
  DelphiDoom.Tests.XcomEngine.FontSettingsReader in 'Source\DelphiDoom.Tests.XcomEngine.FontSettingsReader.pas',
  DelphiDoom.Tests.XcomEngine.RasterFontOverlay in 'Source\DelphiDoom.Tests.XcomEngine.RasterFontOverlay.pas',
  DelphiDoom.Tests.XcomEngine.FontChoices in 'Source\DelphiDoom.Tests.XcomEngine.FontChoices.pas',
  DelphiDoom.Tests.XcomEngine.FontGridGenerator in 'Source\DelphiDoom.Tests.XcomEngine.FontGridGenerator.pas',
  DelphiDoom.Tests.XcomEngine.DetailFakes in 'Source\DelphiDoom.Tests.XcomEngine.DetailFakes.pas',
  DelphiDoom.Tests.XcomEngine.DetailFont in 'Source\DelphiDoom.Tests.XcomEngine.DetailFont.pas',
  DelphiDoom.Tests.XcomEngine.InkComposer in 'Source\DelphiDoom.Tests.XcomEngine.InkComposer.pas',
  DelphiDoom.Tests.XcomEngine.TrueColorStale in 'Source\DelphiDoom.Tests.XcomEngine.TrueColorStale.pas',
  DelphiDoom.Tests.XcomEngine.TextDetail in 'Source\DelphiDoom.Tests.XcomEngine.TextDetail.pas',
  DelphiDoom.Tests.XcomEngine.TextOriginal in 'Source\DelphiDoom.Tests.XcomEngine.TextOriginal.pas';

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
