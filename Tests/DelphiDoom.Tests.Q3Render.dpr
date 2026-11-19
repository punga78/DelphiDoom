{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Quake III renderer library without OpenGL     }
{  (phase R0: images, shaders, models, world, host adapter; DUnitX)            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Q3Render;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Q3Render.Types in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Types.pas',
  DelphiDoom.Q3Render.Scene.Types in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Scene.Types.pas',
  DelphiDoom.Q3Render.Intf in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Intf.pas',
  DelphiDoom.Q3Render.View.Setup in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.View.Setup.pas',
  DelphiDoom.Q3Render.View.Culler in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.View.Culler.pas',
  DelphiDoom.Q3Render.Draw.Sorter in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Draw.Sorter.pas',
  DelphiDoom.Q3Render.Draw.List in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Draw.List.pas',
  DelphiDoom.Q3Render.Shader.Table in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Shader.Table.pas',
  DelphiDoom.Q3Render.World.Surfaces in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.World.Surfaces.pas',
  DelphiDoom.Q3Render.Scene.Buffers in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Scene.Buffers.pas',
  DelphiDoom.Q3Render.Scene.FrontEnd in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Scene.FrontEnd.pas',
  DelphiDoom.Q3Render.Frame.Commands in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Frame.Commands.pas',
  DelphiDoom.Q3Render.Backend.Gl in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Backend.Gl.pas',
  DelphiDoom.Q3Render.Backend.State in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Backend.State.pas',
  DelphiDoom.Q3Render.Backend.Executor in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Backend.Executor.pas',
  DelphiDoom.Q3Render.Frame.Renderer in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Frame.Renderer.pas',
  DelphiDoom.Q3Render.Files.GameFs in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Files.GameFs.pas',
  DelphiDoom.Q3Render.Image.TgaReader in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Image.TgaReader.pas',
  DelphiDoom.Q3Render.Image.JpegReader in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Image.JpegReader.pas',
  DelphiDoom.Q3Render.Image.Loader in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Image.Loader.pas',
  DelphiDoom.Q3Render.Image.Catalog in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Image.Catalog.pas',
  DelphiDoom.Q3Render.Shader.Registry in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Shader.Registry.pas',
  DelphiDoom.Q3Render.Model.Registry in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Model.Registry.pas',
  DelphiDoom.Q3Render.World.Data in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.World.Data.pas',
  DelphiDoom.Q3Render.World.Loader in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.World.Loader.pas',
  DelphiDoom.Q3Render.System in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.System.pas',
  DelphiDoom.Q3Render.Host.Adapter in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Host.Adapter.pas',
  DelphiDoom.Q3Render.Factory in '..\IdTech4\Q3Render\DelphiDoom.Q3Render.Factory.pas',
  DelphiDoom.Tests.Q3Render.Support in 'Source\DelphiDoom.Tests.Q3Render.Support.pas',
  DelphiDoom.Tests.Q3Render.Image in 'Source\DelphiDoom.Tests.Q3Render.Image.pas',
  DelphiDoom.Tests.Q3Render.Shader in 'Source\DelphiDoom.Tests.Q3Render.Shader.pas',
  DelphiDoom.Tests.Q3Render.Model in 'Source\DelphiDoom.Tests.Q3Render.Model.pas',
  DelphiDoom.Tests.Q3Render.World in 'Source\DelphiDoom.Tests.Q3Render.World.pas',
  DelphiDoom.Tests.Q3Render.Adapter in 'Source\DelphiDoom.Tests.Q3Render.Adapter.pas',
  DelphiDoom.Tests.Q3Render.Front in 'Source\DelphiDoom.Tests.Q3Render.Front.pas',
  DelphiDoom.Tests.Q3Render.Backend in 'Source\DelphiDoom.Tests.Q3Render.Backend.pas',
  DelphiDoom.Tests.Q3Render.Reach in 'Source\DelphiDoom.Tests.Q3Render.Reach.pas';

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
