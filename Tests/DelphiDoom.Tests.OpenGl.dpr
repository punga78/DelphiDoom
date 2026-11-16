{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the OpenGL call recorder (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.OpenGl;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.OpenGl.Recorder.Types in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Types.pas',
  DelphiDoom.OpenGl.Recorder.Intf in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Intf.pas',
  DelphiDoom.OpenGl.Recorder.Fnv in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Fnv.pas',
  DelphiDoom.OpenGl.Recorder.PixelFormats in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.PixelFormats.pas',
  DelphiDoom.OpenGl.Recorder.ClientArrays in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.ClientArrays.pas',
  DelphiDoom.OpenGl.Recorder.Encoder in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Encoder.pas',
  DelphiDoom.OpenGl.Recorder.CallRecorder in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.CallRecorder.pas',
  DelphiDoom.OpenGl.Recorder.HookTable in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.HookTable.pas',
  DelphiDoom.OpenGl.Recorder.Installer in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Installer.pas',
  DelphiDoom.OpenGl.Recorder.Session in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Session.pas',
  DelphiDoom.OpenGl.Recorder.Thunks in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Thunks.pas',
  DelphiDoom.OpenGl.Recorder.Hook in '..\Framework\OpenGlBinding\Recorder\DelphiDoom.OpenGl.Recorder.Hook.pas',
  dglOpenGL in '..\Framework\OpenGlBinding\dglOpenGL.pas',
  DelphiDoom.GlTexture.Types in '..\IdTech1\GlTexture\DelphiDoom.GlTexture.Types.pas',
  DelphiDoom.GlTexture.Palette in '..\IdTech1\GlTexture\DelphiDoom.GlTexture.Palette.pas',
  DelphiDoom.GlTexture.PatchPainter in '..\IdTech1\GlTexture\DelphiDoom.GlTexture.PatchPainter.pas',
  DelphiDoom.GlTexture.FlatPainter in '..\IdTech1\GlTexture\DelphiDoom.GlTexture.FlatPainter.pas',
  DelphiDoom.GlTexture.Ripple in '..\IdTech1\GlTexture\DelphiDoom.GlTexture.Ripple.pas',
  DelphiDoom.GlTexture.Transparency in '..\IdTech1\GlTexture\DelphiDoom.GlTexture.Transparency.pas',
  DelphiDoom.Tests.OpenGl.OldTextureBuffers in 'Source\DelphiDoom.Tests.OpenGl.OldTextureBuffers.pas',
  DelphiDoom.Tests.OpenGl.TextureBuffers in 'Source\DelphiDoom.Tests.OpenGl.TextureBuffers.pas',
  DelphiDoom.GlLevel.Types in '..\IdTech1\GlLevel\DelphiDoom.GlLevel.Types.pas',
  DelphiDoom.GlLevel.Intf in '..\IdTech1\GlLevel\DelphiDoom.GlLevel.Intf.pas',
  DelphiDoom.GlLevel.FlatEdgeClipper in '..\IdTech1\GlLevel\DelphiDoom.GlLevel.FlatEdgeClipper.pas',
  DelphiDoom.GlLevel.FlatCarver in '..\IdTech1\GlLevel\DelphiDoom.GlLevel.FlatCarver.pas',
  DelphiDoom.GlLevel.SectorPreprocessor in '..\IdTech1\GlLevel\DelphiDoom.GlLevel.SectorPreprocessor.pas',
  DelphiDoom.GlLevel.Factory in '..\IdTech1\GlLevel\DelphiDoom.GlLevel.Factory.pas',
  DelphiDoom.GlAutomap.Types in '..\IdTech1\GlAutomap\DelphiDoom.GlAutomap.Types.pas',
  DelphiDoom.GlAutomap.Intf in '..\IdTech1\GlAutomap\DelphiDoom.GlAutomap.Intf.pas',
  DelphiDoom.GlAutomap.DisplayList in '..\IdTech1\GlAutomap\DelphiDoom.GlAutomap.DisplayList.pas',
  DelphiDoom.GlAutomap.Factory in '..\IdTech1\GlAutomap\DelphiDoom.GlAutomap.Factory.pas',
  DelphiDoom.GlContext.PixelFormat in '..\IdTech1\GlContext\DelphiDoom.GlContext.PixelFormat.pas',
  DelphiDoom.GlContext.FullScreenMode in '..\IdTech1\GlContext\DelphiDoom.GlContext.FullScreenMode.pas',
  DelphiDoom.GlContext.DisplayModeClamp in '..\IdTech1\GlContext\DelphiDoom.GlContext.DisplayModeClamp.pas',
  DelphiDoom.GlContext.ExtensionList in '..\IdTech1\GlContext\DelphiDoom.GlContext.ExtensionList.pas',
  DelphiDoom.GlScene.PaletteTint in '..\IdTech1\GlScene\DelphiDoom.GlScene.PaletteTint.pas',
  DelphiDoom.Tests.OpenGl.OldAutomapBuffer in 'Source\DelphiDoom.Tests.OpenGl.OldAutomapBuffer.pas',
  DelphiDoom.Tests.OpenGl.AutomapDisplayList in 'Source\DelphiDoom.Tests.OpenGl.AutomapDisplayList.pas',
  DelphiDoom.GlScene.Types in '..\IdTech1\GlScene\DelphiDoom.GlScene.Types.pas',
  DelphiDoom.GlScene.DrawList in '..\IdTech1\GlScene\DelphiDoom.GlScene.DrawList.pas',
  DelphiDoom.GlScene.Factory in '..\IdTech1\GlScene\DelphiDoom.GlScene.Factory.pas',
  DelphiDoom.GlScene.Light in '..\IdTech1\GlScene\DelphiDoom.GlScene.Light.pas',
  DelphiDoom.Tests.OpenGl.SceneLight in 'Source\DelphiDoom.Tests.OpenGl.SceneLight.pas',
  DelphiDoom.Tests.OpenGl.DisplayModeClamp in 'Source\DelphiDoom.Tests.OpenGl.DisplayModeClamp.pas',
  DelphiDoom.Tests.OpenGl.ContextFormats in 'Source\DelphiDoom.Tests.OpenGl.ContextFormats.pas',
  DelphiDoom.Tests.OpenGl.ExtensionList in 'Source\DelphiDoom.Tests.OpenGl.ExtensionList.pas',
  DelphiDoom.Tests.OpenGl.PaletteTint in 'Source\DelphiDoom.Tests.OpenGl.PaletteTint.pas',
  DelphiDoom.Tests.OpenGl.OldSceneDrawList in 'Source\DelphiDoom.Tests.OpenGl.OldSceneDrawList.pas',
  DelphiDoom.Tests.OpenGl.SceneDrawList in 'Source\DelphiDoom.Tests.OpenGl.SceneDrawList.pas',
  DelphiDoom.Tests.OpenGl.OldFlatCarver in 'Source\DelphiDoom.Tests.OpenGl.OldFlatCarver.pas',
  DelphiDoom.Tests.OpenGl.FlatCarver in 'Source\DelphiDoom.Tests.OpenGl.FlatCarver.pas',
  DelphiDoom.Tests.OpenGl.OldSectorPreprocessor in 'Source\DelphiDoom.Tests.OpenGl.OldSectorPreprocessor.pas',
  DelphiDoom.Tests.OpenGl.SectorPreprocessor in 'Source\DelphiDoom.Tests.OpenGl.SectorPreprocessor.pas',
  DelphiDoom.Tests.OpenGl.Fnv in 'Source\DelphiDoom.Tests.OpenGl.Fnv.pas',
  DelphiDoom.Tests.OpenGl.PixelFormats in 'Source\DelphiDoom.Tests.OpenGl.PixelFormats.pas',
  DelphiDoom.Tests.OpenGl.ClientArrays in 'Source\DelphiDoom.Tests.OpenGl.ClientArrays.pas',
  DelphiDoom.Tests.OpenGl.Encoder in 'Source\DelphiDoom.Tests.OpenGl.Encoder.pas',
  DelphiDoom.Tests.OpenGl.CallRecorder in 'Source\DelphiDoom.Tests.OpenGl.CallRecorder.pas',
  DelphiDoom.Tests.OpenGl.HookInstaller in 'Source\DelphiDoom.Tests.OpenGl.HookInstaller.pas',
  DelphiDoom.Tests.OpenGl.Session in 'Source\DelphiDoom.Tests.OpenGl.Session.pas',
  DelphiDoom.Tests.OpenGl.Thunks in 'Source\DelphiDoom.Tests.OpenGl.Thunks.pas';

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
