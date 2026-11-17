{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the OpenGL scene of Strife (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.OpenGl.Strife;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  dglOpenGL in '..\Framework\OpenGlBinding\dglOpenGL.pas',
  d_delphi in 'Shim\OpenGlGame\d_delphi.pas',
  m_fixed in 'Shim\OpenGlGame\m_fixed.pas',
  d_player in 'Shim\OpenGlGame\d_player.pas',
  g_game in 'Shim\OpenGlGame\g_game.pas',
  doomstat in 'Shim\OpenGlGame\doomstat.pas',
  gl_defs in 'Shim\OpenGlGame\gl_defs.pas',
  r_colormaps in 'Shim\OpenGlGame\r_colormaps.pas',
  r_data in 'Shim\OpenGlGame\r_data.pas',
  p_mobj_h in 'Shim\OpenGlGame\p_mobj_h.pas',
  p_tick in 'Shim\OpenGlGame\p_tick.pas',
  DelphiDoom.GameState.Intf in '..\IdTech1\GameState\DelphiDoom.GameState.Intf.pas',
  DelphiDoom.DynLights.Types in '..\IdTech1\DynLights\DelphiDoom.DynLights.Types.pas',
  DelphiDoom.DynLights.Intf in '..\IdTech1\DynLights\DelphiDoom.DynLights.Intf.pas',
  r_dynlights in 'Shim\OpenGlGame\r_dynlights.pas',
  gl_shadows in 'Shim\OpenGlGame\gl_shadows.pas',
  DelphiDoom.Engine.GlScene.Types in 'Shim\OpenGlGame\DelphiDoom.Engine.GlScene.Types.pas',
  DelphiDoom.Tests.OpenGl.FakeGlLog in 'Source\DelphiDoom.Tests.OpenGl.FakeGlLog.pas',
  DelphiDoom.Engine.GlScene.Fog in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.Fog.pas',
  DelphiDoom.Engine.GlScene.LightMarker in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.LightMarker.pas',
  DelphiDoom.Tests.OpenGl.SceneLightMarker in 'Source\DelphiDoom.Tests.OpenGl.SceneLightMarker.pas',
  DelphiDoom.Tests.OpenGl.SceneFog in 'Source\DelphiDoom.Tests.OpenGl.SceneFog.pas';

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
