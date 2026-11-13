{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the geometry library (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Geometry;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.IdLib.Core.Exceptions in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Math.Math in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.IdLib.Math.Vec4 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec4.pas',
  DelphiDoom.MathCore.Float.Angles in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Angles.pas',
  DelphiDoom.MathCore.Float.Quat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Quat.pas',
  DelphiDoom.MathCore.Float.CQuat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.CQuat.pas',
  DelphiDoom.MathCore.Float.Mat3 in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Mat3.pas',
  DelphiDoom.MathCore.Float.JointQuat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.JointQuat.pas',
  DelphiDoom.MathCore.Float.JointMat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.JointMat.pas',
  DelphiDoom.Geometry.Types in '..\Libs\Geometry\DelphiDoom.Geometry.Types.pas',
  DelphiDoom.Geometry.FloatMath in '..\Libs\Geometry\DelphiDoom.Geometry.FloatMath.pas',
  DelphiDoom.Geometry.Vec3 in '..\Libs\Geometry\DelphiDoom.Geometry.Vec3.pas',
  DelphiDoom.Geometry.Mat3 in '..\Libs\Geometry\DelphiDoom.Geometry.Mat3.pas',
  DelphiDoom.Geometry.Plane in '..\Libs\Geometry\DelphiDoom.Geometry.Plane.pas',
  DelphiDoom.Geometry.Pluecker in '..\Libs\Geometry\DelphiDoom.Geometry.Pluecker.pas',
  DelphiDoom.Geometry.Sphere in '..\Libs\Geometry\DelphiDoom.Geometry.Sphere.pas',
  DelphiDoom.Geometry.Bounds in '..\Libs\Geometry\DelphiDoom.Geometry.Bounds.pas',
  DelphiDoom.Geometry.Box in '..\Libs\Geometry\DelphiDoom.Geometry.Box.pas',
  DelphiDoom.Geometry.Winding in '..\Libs\Geometry\DelphiDoom.Geometry.Winding.pas',
  DelphiDoom.Geometry.Frustum in '..\Libs\Geometry\DelphiDoom.Geometry.Frustum.pas',
  DelphiDoom.Geometry.Winding2D in '..\Libs\Geometry\DelphiDoom.Geometry.Winding2D.pas',
  DelphiDoom.Geometry.DrawVert in '..\Libs\Geometry\DelphiDoom.Geometry.DrawVert.pas',
  DelphiDoom.Geometry.Surface in '..\Libs\Geometry\DelphiDoom.Geometry.Surface.pas',
  DelphiDoom.Geometry.Surface.Polytope in '..\Libs\Geometry\DelphiDoom.Geometry.Surface.Polytope.pas',
  DelphiDoom.Geometry.Surface.Patch in '..\Libs\Geometry\DelphiDoom.Geometry.Surface.Patch.pas',
  DelphiDoom.MathCore.Float.GeometryAdapter in '..\Libs\MathCore\DelphiDoom.MathCore.Float.GeometryAdapter.pas',
  DelphiDoom.Tests.Geometry.Golden in 'Source\DelphiDoom.Tests.Geometry.Golden.pas',
  DelphiDoom.Tests.Geometry.DrawVert in 'Source\DelphiDoom.Tests.Geometry.DrawVert.pas',
  DelphiDoom.Tests.Geometry.JointMat in 'Source\DelphiDoom.Tests.Geometry.JointMat.pas',
  DelphiDoom.Tests.Geometry.Winding2D in 'Source\DelphiDoom.Tests.Geometry.Winding2D.pas',
  DelphiDoom.Tests.Geometry.Surface in 'Source\DelphiDoom.Tests.Geometry.Surface.pas',
  DelphiDoom.Tests.Geometry.SurfacePolytope in 'Source\DelphiDoom.Tests.Geometry.SurfacePolytope.pas',
  DelphiDoom.Tests.Geometry.SurfacePatch in 'Source\DelphiDoom.Tests.Geometry.SurfacePatch.pas',
  DelphiDoom.Tests.Geometry.Frustum.Parity in 'Source\DelphiDoom.Tests.Geometry.Frustum.Parity.pas',
  DelphiDoom.Tests.Geometry.Frustum.Values in 'Source\DelphiDoom.Tests.Geometry.Frustum.Values.pas';

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
