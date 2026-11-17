{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the OpenGL scene of Heretic (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.OpenGl.Heretic;

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
  doomdef in 'Shim\OpenGlGame\doomdef.pas',
  d_main in 'Shim\OpenGlGame\d_main.pas',
  v_video in 'Shim\OpenGlGame\v_video.pas',
  i_system in 'Shim\OpenGlGame\i_system.pas',
  w_wad in 'Shim\OpenGlGame\w_wad.pas',
  gl_tex in 'Shim\OpenGlGame\gl_tex.pas',
  gl_sky in 'Shim\OpenGlGame\gl_sky.pas',
  gl_lights in 'Shim\OpenGlGame\gl_lights.pas',
  gl_models in 'Shim\OpenGlGame\gl_models.pas',
  gl_voxels in 'Shim\OpenGlGame\gl_voxels.pas',
  gl_lightmaps in 'Shim\OpenGlGame\gl_lightmaps.pas',
  gl_automap in 'Shim\OpenGlGame\gl_automap.pas',
  gl_ambient in 'Shim\OpenGlGame\gl_ambient.pas',
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Framework\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Framework\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.Engine.Scanner.Log in '..\IdTech1\Base\DelphiDoom.Engine.Scanner.Log.pas',
  DelphiDoom.GlScene.Types in '..\IdTech1\GlScene\DelphiDoom.GlScene.Types.pas',
  DelphiDoom.GlContext.ExtensionList in '..\IdTech1\GlContext\DelphiDoom.GlContext.ExtensionList.pas',
  DelphiDoom.Engine.GlLightmap.Types in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlLightmap.Types.pas',
  DelphiDoom.Engine.GlVSync in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlVSync.pas',
  DelphiDoom.Engine.GlInitializer in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlInitializer.pas',
  DelphiDoom.Tests.OpenGl.Initializer in 'Source\DelphiDoom.Tests.OpenGl.Initializer.pas',
  r_renderstyle in 'Shim\OpenGlGame\r_renderstyle.pas',
  r_draw in 'Shim\OpenGlGame\r_draw.pas',
  r_defs in 'Shim\OpenGlGame\r_defs.pas',
  r_main in 'Shim\OpenGlGame\r_main.pas',
  r_things in 'Shim\OpenGlGame\r_things.pas',
  info_h in 'Shim\OpenGlGame\info_h.pas',
  gl_types in 'Shim\OpenGlGame\gl_types.pas',
  st_stuff in 'Shim\OpenGlGame\st_stuff.pas',
  gl_render in 'Shim\OpenGlGame\gl_render.pas',
  DelphiDoom.Engine.GlHudPainter in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlHudPainter.pas',
  DelphiDoom.Tests.OpenGl.HudPainter in 'Source\DelphiDoom.Tests.OpenGl.HudPainter.pas',
  tables in 'Shim\OpenGlGame\tables.pas',
  gl_main in 'Shim\OpenGlGame\gl_main.pas',
  DelphiDoom.GlScene.DrawList in 'Shim\OpenGlGame\DelphiDoom.GlScene.DrawList.pas',
  DelphiDoom.Engine.GlScene.FlatCollector in 'Shim\OpenGlGame\DelphiDoom.Engine.GlScene.FlatCollector.pas',
  DelphiDoom.Engine.GlScene.WallCollector in 'Shim\OpenGlGame\DelphiDoom.Engine.GlScene.WallCollector.pas',
  DelphiDoom.Engine.GlScene.WallPainter in 'Shim\OpenGlGame\DelphiDoom.Engine.GlScene.WallPainter.pas',
  DelphiDoom.Engine.GlScene.SpritePainter in 'Shim\OpenGlGame\DelphiDoom.Engine.GlScene.SpritePainter.pas',
  DelphiDoom.Engine.GlScene.LightPainter in 'Shim\OpenGlGame\DelphiDoom.Engine.GlScene.LightPainter.pas',
  DelphiDoom.Engine.Gl2dMode in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.Gl2dMode.pas',
  DelphiDoom.Engine.GlScene.Frame in '..\IdTech1\OpenGl\Legacy\DelphiDoom.Engine.GlScene.Frame.pas',
  DelphiDoom.Tests.OpenGl.SceneFrame in 'Source\DelphiDoom.Tests.OpenGl.SceneFrame.pas',
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
