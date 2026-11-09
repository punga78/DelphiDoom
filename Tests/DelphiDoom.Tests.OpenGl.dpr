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
  DelphiDoom.OpenGl.Recorder.Types in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Types.pas',
  DelphiDoom.OpenGl.Recorder.Intf in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Intf.pas',
  DelphiDoom.OpenGl.Recorder.Fnv in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Fnv.pas',
  DelphiDoom.OpenGl.Recorder.PixelFormats in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.PixelFormats.pas',
  DelphiDoom.OpenGl.Recorder.ClientArrays in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.ClientArrays.pas',
  DelphiDoom.OpenGl.Recorder.Encoder in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Encoder.pas',
  DelphiDoom.OpenGl.Recorder.CallRecorder in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.CallRecorder.pas',
  DelphiDoom.OpenGl.Recorder.HookTable in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.HookTable.pas',
  DelphiDoom.OpenGl.Recorder.Installer in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Installer.pas',
  DelphiDoom.OpenGl.Recorder.Session in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Session.pas',
  DelphiDoom.OpenGl.Recorder.Thunks in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Thunks.pas',
  DelphiDoom.OpenGl.Recorder.Hook in '..\Libs\OpenGl\Recorder\DelphiDoom.OpenGl.Recorder.Hook.pas',
  dglOpenGL in '..\Libs\OpenGl\Binding\dglOpenGL.pas',
  DelphiDoom.GlTexture.Types in '..\Libs\GlTexture\DelphiDoom.GlTexture.Types.pas',
  DelphiDoom.GlTexture.Palette in '..\Libs\GlTexture\DelphiDoom.GlTexture.Palette.pas',
  DelphiDoom.GlTexture.PatchPainter in '..\Libs\GlTexture\DelphiDoom.GlTexture.PatchPainter.pas',
  DelphiDoom.GlTexture.FlatPainter in '..\Libs\GlTexture\DelphiDoom.GlTexture.FlatPainter.pas',
  DelphiDoom.GlTexture.Ripple in '..\Libs\GlTexture\DelphiDoom.GlTexture.Ripple.pas',
  DelphiDoom.GlTexture.Transparency in '..\Libs\GlTexture\DelphiDoom.GlTexture.Transparency.pas',
  DelphiDoom.Tests.OpenGl.OldTextureBuffers in 'Source\DelphiDoom.Tests.OpenGl.OldTextureBuffers.pas',
  DelphiDoom.Tests.OpenGl.TextureBuffers in 'Source\DelphiDoom.Tests.OpenGl.TextureBuffers.pas',
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
