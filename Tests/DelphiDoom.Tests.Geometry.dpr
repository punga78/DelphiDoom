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
  DelphiDoom.IdLib.Core.Exceptions in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Math.Math in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.IdLib.Math.Vec4 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec4.pas',
  DelphiDoom.MathCore.Float.Angles in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Angles.pas',
  DelphiDoom.MathCore.Float.Quat in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Quat.pas',
  DelphiDoom.MathCore.Float.CQuat in '..\Framework\MathCore\DelphiDoom.MathCore.Float.CQuat.pas',
  DelphiDoom.MathCore.Float.Mat3 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat3.pas',
  DelphiDoom.MathCore.Float.JointQuat in '..\Framework\MathCore\DelphiDoom.MathCore.Float.JointQuat.pas',
  DelphiDoom.MathCore.Float.JointMat in '..\Framework\MathCore\DelphiDoom.MathCore.Float.JointMat.pas',
  DelphiDoom.Geometry.Types in '..\Framework\Geometry\DelphiDoom.Geometry.Types.pas',
  DelphiDoom.Geometry.FloatMath in '..\Framework\Geometry\DelphiDoom.Geometry.FloatMath.pas',
  DelphiDoom.Geometry.Vec3 in '..\Framework\Geometry\DelphiDoom.Geometry.Vec3.pas',
  DelphiDoom.Geometry.Mat3 in '..\Framework\Geometry\DelphiDoom.Geometry.Mat3.pas',
  DelphiDoom.Geometry.Plane in '..\Framework\Geometry\DelphiDoom.Geometry.Plane.pas',
  DelphiDoom.Geometry.Pluecker in '..\Framework\Geometry\DelphiDoom.Geometry.Pluecker.pas',
  DelphiDoom.Geometry.Sphere in '..\Framework\Geometry\DelphiDoom.Geometry.Sphere.pas',
  DelphiDoom.Geometry.Bounds in '..\Framework\Geometry\DelphiDoom.Geometry.Bounds.pas',
  DelphiDoom.Geometry.Box in '..\Framework\Geometry\DelphiDoom.Geometry.Box.pas',
  DelphiDoom.Geometry.Winding in '..\Framework\Geometry\DelphiDoom.Geometry.Winding.pas',
  DelphiDoom.Geometry.Frustum in '..\Framework\Geometry\DelphiDoom.Geometry.Frustum.pas',
  DelphiDoom.Geometry.Winding2D in '..\Framework\Geometry\DelphiDoom.Geometry.Winding2D.pas',
  DelphiDoom.Geometry.DrawVert in '..\Framework\Geometry\DelphiDoom.Geometry.DrawVert.pas',
  DelphiDoom.Geometry.Surface in '..\Framework\Geometry\DelphiDoom.Geometry.Surface.pas',
  DelphiDoom.Geometry.Surface.Polytope in '..\Framework\Geometry\DelphiDoom.Geometry.Surface.Polytope.pas',
  DelphiDoom.Geometry.Surface.Patch in '..\Framework\Geometry\DelphiDoom.Geometry.Surface.Patch.pas',
  DelphiDoom.Geometry.TraceModel in '..\Framework\Geometry\DelphiDoom.Geometry.TraceModel.pas',
  DelphiDoom.MathCore.Float.GeometryAdapter in '..\Framework\MathCore\DelphiDoom.MathCore.Float.GeometryAdapter.pas',
  DelphiDoom.Tests.Geometry.TraceModel in 'Source\DelphiDoom.Tests.Geometry.TraceModel.pas',
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
