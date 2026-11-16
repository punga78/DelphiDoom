{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the math core library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.MathCore;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Types in '..\Framework\GameMath\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Framework\GameMath\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.MathCore.TableFineSine in '..\Framework\GameMath\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in '..\Framework\GameMath\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in '..\Framework\GameMath\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in '..\Framework\GameMath\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.TableFixedSine in '..\Framework\GameMath\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.TableRandom in '..\Framework\GameMath\DelphiDoom.MathCore.TableRandom.pas',
  DelphiDoom.MathCore.TableSysRandom in '..\Framework\GameMath\DelphiDoom.MathCore.TableSysRandom.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Framework\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.FixedMath in '..\Framework\GameMath\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.SoftExtended in '..\Framework\MathCore\DelphiDoom.MathCore.SoftExtended.pas',
  DelphiDoom.MathCore.SoftArcTan in '..\Framework\MathCore\DelphiDoom.MathCore.SoftArcTan.pas',
  DelphiDoom.MathCore.X87Double in '..\Framework\GameMath\DelphiDoom.MathCore.X87Double.pas',
  DelphiDoom.MathCore.MemoryFill in '..\Framework\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
  DelphiDoom.MathCore.PixelBatch in '..\Framework\GameMath\DelphiDoom.MathCore.PixelBatch.pas',
  DelphiDoom.MathCore.Trigonometry in '..\Framework\GameMath\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.MathCore.VectorMath in '..\Framework\GameMath\DelphiDoom.MathCore.VectorMath.pas',
  DelphiDoom.MathCore.BoundingBox in '..\Framework\GameMath\DelphiDoom.MathCore.BoundingBox.pas',
  DelphiDoom.MathCore.IntegerStack in '..\Framework\MathCore\DelphiDoom.MathCore.IntegerStack.pas',
  DelphiDoom.MathCore.IntegerQueue in '..\Framework\MathCore\DelphiDoom.MathCore.IntegerQueue.pas',
  DelphiDoom.MathCore.GameRandom in '..\Framework\GameMath\DelphiDoom.MathCore.GameRandom.pas',
  DelphiDoom.MathCore.SystemEntropySource in '..\Framework\GameMath\DelphiDoom.MathCore.SystemEntropySource.pas',
  DelphiDoom.MathCore.StringHashTable in '..\Framework\GameMath\DelphiDoom.MathCore.StringHashTable.pas',
  DelphiDoom.MathCore.Crc32 in '..\Framework\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.MathCore.Sha1 in '..\Framework\MathCore\DelphiDoom.MathCore.Sha1.pas',
  DelphiDoom.MathCore.Factory in '..\Framework\GameMath\DelphiDoom.MathCore.Factory.pas',
  DelphiDoom.Tests.MathCore.Fingerprint in 'Source\DelphiDoom.Tests.MathCore.Fingerprint.pas',
  DelphiDoom.Tests.MathCore.Samples in 'Source\DelphiDoom.Tests.MathCore.Samples.pas',
  DelphiDoom.Tests.MathCore.Golden in 'Source\DelphiDoom.Tests.MathCore.Golden.pas',
  DelphiDoom.Tests.MathCore.PairRunner in 'Source\DelphiDoom.Tests.MathCore.PairRunner.pas',
  DelphiDoom.Tests.MathCore.FixedMath in 'Source\DelphiDoom.Tests.MathCore.FixedMath.pas',
  DelphiDoom.Tests.MathCore.SoftExtended in 'Source\DelphiDoom.Tests.MathCore.SoftExtended.pas',
  DelphiDoom.Tests.MathCore.SoftArcTan in 'Source\DelphiDoom.Tests.MathCore.SoftArcTan.pas',
  DelphiDoom.Tests.MathCore.FixedMul64Wide in 'Source\DelphiDoom.Tests.MathCore.FixedMul64Wide.pas',
  DelphiDoom.Tests.MathCore.X87Double in 'Source\DelphiDoom.Tests.MathCore.X87Double.pas',
  DelphiDoom.Tests.MathCore.X87DoubleSteps in 'Source\DelphiDoom.Tests.MathCore.X87DoubleSteps.pas',
  DelphiDoom.Tests.MathCore.MemoryFill in 'Source\DelphiDoom.Tests.MathCore.MemoryFill.pas',
  DelphiDoom.Tests.MathCore.PixelBatch in 'Source\DelphiDoom.Tests.MathCore.PixelBatch.pas',
  DelphiDoom.Tests.MathCore.Trigonometry in 'Source\DelphiDoom.Tests.MathCore.Trigonometry.pas',
  DelphiDoom.Tests.MathCore.VectorMath in 'Source\DelphiDoom.Tests.MathCore.VectorMath.pas',
  DelphiDoom.Tests.MathCore.BoundingBox in 'Source\DelphiDoom.Tests.MathCore.BoundingBox.pas',
  DelphiDoom.Tests.MathCore.GameRandom in 'Source\DelphiDoom.Tests.MathCore.GameRandom.pas',
  DelphiDoom.Tests.MathCore.RandomParity in 'Source\DelphiDoom.Tests.MathCore.RandomParity.pas',
  DelphiDoom.Tests.MathCore.StringHashTable in 'Source\DelphiDoom.Tests.MathCore.StringHashTable.pas',
  DelphiDoom.Tests.MathCore.IntegerStack in 'Source\DelphiDoom.Tests.MathCore.IntegerStack.pas',
  DelphiDoom.Tests.MathCore.IntegerQueue in 'Source\DelphiDoom.Tests.MathCore.IntegerQueue.pas',
  DelphiDoom.Tests.MathCore.Crc32 in 'Source\DelphiDoom.Tests.MathCore.Crc32.pas',
  DelphiDoom.Tests.MathCore.Sha1 in 'Source\DelphiDoom.Tests.MathCore.Sha1.pas',
  DelphiDoom.Tests.MathCore.SystemEntropySource in 'Source\DelphiDoom.Tests.MathCore.SystemEntropySource.pas',
  DelphiDoom.Tests.MathCore.Factory in 'Source\DelphiDoom.Tests.MathCore.Factory.pas',
  DelphiDoom.IdLib.Core.Exceptions in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Math.Math in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.MathCore.Float.Angles in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Angles.pas',
  DelphiDoom.MathCore.Float.Quat in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Quat.pas',
  DelphiDoom.MathCore.Float.CQuat in '..\Framework\MathCore\DelphiDoom.MathCore.Float.CQuat.pas',
  DelphiDoom.MathCore.Float.Mat3 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat3.pas',
  DelphiDoom.MathCore.Float.Rotation in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Rotation.pas',
  DelphiDoom.MathCore.Float.Complex in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Complex.pas',
  DelphiDoom.MathCore.Float.Polynomial in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Polynomial.pas',
  DelphiDoom.MathCore.Float.Conversions in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Conversions.pas',
  DelphiDoom.IdLib.Math.Vec4 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec4.pas',
  DelphiDoom.IdLib.Math.Random in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Random.pas',
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.MathCore.Float.Types in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Types.pas',
  DelphiDoom.MathCore.Float.Vec5 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Vec5.pas',
  DelphiDoom.MathCore.Float.Vec6 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Vec6.pas',
  DelphiDoom.MathCore.Float.VecX in '..\Framework\MathCore\DelphiDoom.MathCore.Float.VecX.pas',
  DelphiDoom.MathCore.Float.Polar3 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Polar3.pas',
  DelphiDoom.MathCore.Float.Mat2 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat2.pas',
  DelphiDoom.MathCore.Float.Mat4 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat4.pas',
  DelphiDoom.MathCore.Float.Mat5 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat5.pas',
  DelphiDoom.MathCore.Float.Mat6 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat6.pas',
  DelphiDoom.MathCore.Float.MatX in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.pas',
  DelphiDoom.MathCore.Float.MatX.Ldlt in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Ldlt.pas',
  DelphiDoom.MathCore.Float.MatX.LuUpdate in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.LuUpdate.pas',
  DelphiDoom.MathCore.Float.MatX.Qr in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Qr.pas',
  DelphiDoom.MathCore.Float.MatX.Svd in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Svd.pas',
  DelphiDoom.MathCore.Float.MatX.EigenGeneral in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.EigenGeneral.pas',
  DelphiDoom.MathCore.Float.Extrapolate in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Extrapolate.pas',
  DelphiDoom.MathCore.Float.Interpolate in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Interpolate.pas',
  DelphiDoom.MathCore.Float.Interpolate.AccelDecel in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Interpolate.AccelDecel.pas',
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelLinear in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Interpolate.AccelDecelLinear.pas',
  DelphiDoom.MathCore.Float.Interpolate.AccelDecelSine in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Interpolate.AccelDecelSine.pas',
  DelphiDoom.MathCore.Float.Curve.Arithmetic.VecX in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Arithmetic.VecX.pas',
  DelphiDoom.MathCore.Float.Surface.SweptSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Surface.SweptSpline.pas',
  DelphiDoom.MathCore.Float.MatX.Inverse in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Inverse.pas',
  DelphiDoom.MathCore.Float.MatX.Cholesky in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Cholesky.pas',
  DelphiDoom.MathCore.Float.MatX.Eigen in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Eigen.pas',
  DelphiDoom.MathCore.Float.MatX.TriDiagonal in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.TriDiagonal.pas',
  DelphiDoom.MathCore.Float.Curve in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.pas',
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Arithmetic.Scalar.pas',
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec2 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec2.pas',
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec3.pas',
  DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Arithmetic.Vec4.pas',
  DelphiDoom.MathCore.Float.Curve.Bezier in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Bezier.pas',
  DelphiDoom.MathCore.Float.Curve.BSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.BSpline.pas',
  DelphiDoom.MathCore.Float.Curve.CatmullRomSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.CatmullRomSpline.pas',
  DelphiDoom.MathCore.Float.Curve.CubicBezier in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.CubicBezier.pas',
  DelphiDoom.MathCore.Float.Curve.Intf in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Intf.pas',
  DelphiDoom.MathCore.Float.Curve.KochanekBartelsSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.KochanekBartelsSpline.pas',
  DelphiDoom.MathCore.Float.Curve.LuSolver in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.LuSolver.pas',
  DelphiDoom.MathCore.Float.Curve.NaturalCubicSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.NaturalCubicSpline.pas',
  DelphiDoom.MathCore.Float.Curve.NonUniformBSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.NonUniformBSpline.pas',
  DelphiDoom.MathCore.Float.Curve.NURBS in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.NURBS.pas',
  DelphiDoom.MathCore.Float.Curve.QuadraticBezier in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.QuadraticBezier.pas',
  DelphiDoom.MathCore.Float.Curve.Spline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Spline.pas',
  DelphiDoom.MathCore.Float.Curve.Types in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.Types.pas',
  DelphiDoom.MathCore.Float.Curve.UniformCubicBSpline in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Curve.UniformCubicBSpline.pas',
  DelphiDoom.MathCore.Float.Ode.Base in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Ode.Base.pas',
  DelphiDoom.MathCore.Float.Ode.Euler in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Ode.Euler.pas',
  DelphiDoom.MathCore.Float.Ode.Intf in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Ode.Intf.pas',
  DelphiDoom.MathCore.Float.Ode.Midpoint in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Ode.Midpoint.pas',
  DelphiDoom.MathCore.Float.Ode.RK4 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Ode.RK4.pas',
  DelphiDoom.MathCore.Float.Ode.RK4Adaptive in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Ode.RK4Adaptive.pas',
  DelphiDoom.MathCore.Float.PlaneFit in '..\Framework\MathCore\DelphiDoom.MathCore.Float.PlaneFit.pas',
  DelphiDoom.MathCore.Float.BoxFit in '..\Framework\MathCore\DelphiDoom.MathCore.Float.BoxFit.pas',
  DelphiDoom.MathCore.Float.MatX.Kernels in '..\Framework\MathCore\DelphiDoom.MathCore.Float.MatX.Kernels.pas',
  DelphiDoom.MathCore.Float.Lcp.Intf in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Lcp.Intf.pas',
  DelphiDoom.MathCore.Float.Lcp.Base in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Lcp.Base.pas',
  DelphiDoom.MathCore.Float.Lcp.Square in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Lcp.Square.pas',
  DelphiDoom.MathCore.Float.Lcp.Symmetric in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Lcp.Symmetric.pas',
  DelphiDoom.MathCore.Float.Lcp.Factory in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Lcp.Factory.pas',
  DelphiDoom.Geometry.Types in '..\Framework\Geometry\DelphiDoom.Geometry.Types.pas',
  DelphiDoom.Geometry.FloatMath in '..\Framework\Geometry\DelphiDoom.Geometry.FloatMath.pas',
  DelphiDoom.Geometry.Vec3 in '..\Framework\Geometry\DelphiDoom.Geometry.Vec3.pas',
  DelphiDoom.Geometry.Mat3 in '..\Framework\Geometry\DelphiDoom.Geometry.Mat3.pas',
  DelphiDoom.Geometry.Plane in '..\Framework\Geometry\DelphiDoom.Geometry.Plane.pas',
  DelphiDoom.Geometry.Sphere in '..\Framework\Geometry\DelphiDoom.Geometry.Sphere.pas',
  DelphiDoom.Geometry.Bounds in '..\Framework\Geometry\DelphiDoom.Geometry.Bounds.pas',
  DelphiDoom.Geometry.Box in '..\Framework\Geometry\DelphiDoom.Geometry.Box.pas',
  DelphiDoom.Geometry.Pluecker in '..\Framework\Geometry\DelphiDoom.Geometry.Pluecker.pas',
  DelphiDoom.Geometry.DrawVert in '..\Framework\Geometry\DelphiDoom.Geometry.DrawVert.pas',
  DelphiDoom.Geometry.Surface in '..\Framework\Geometry\DelphiDoom.Geometry.Surface.pas',
  DelphiDoom.MathCore.Float.GeometryAdapter in '..\Framework\MathCore\DelphiDoom.MathCore.Float.GeometryAdapter.pas',
  DelphiDoom.MathCore.Float.BoundsRotation in '..\Framework\MathCore\DelphiDoom.MathCore.Float.BoundsRotation.pas',
  DelphiDoom.Tests.IdLib.Golden in 'Source\DelphiDoom.Tests.IdLib.Golden.pas',
  DelphiDoom.Tests.MathCore.Geometry.Parity in 'Source\DelphiDoom.Tests.MathCore.Geometry.Parity.pas',
  DelphiDoom.Tests.MathCore.Geometry.Values in 'Source\DelphiDoom.Tests.MathCore.Geometry.Values.pas',
  DelphiDoom.Tests.MathCore.Float.Parity in 'Source\DelphiDoom.Tests.MathCore.Float.Parity.pas',
  DelphiDoom.Tests.MathCore.Float.Values in 'Source\DelphiDoom.Tests.MathCore.Float.Values.pas',
  DelphiDoom.Tests.MathCore.Matrix.Lines in 'Source\DelphiDoom.Tests.MathCore.Matrix.Lines.pas',
  DelphiDoom.Tests.MathCore.GoldenLines in 'Source\DelphiDoom.Tests.MathCore.GoldenLines.pas',
  DelphiDoom.Tests.MathCore.Ode.Parity in 'Source\DelphiDoom.Tests.MathCore.Ode.Parity.pas',
  DelphiDoom.Tests.MathCore.Ode.Values in 'Source\DelphiDoom.Tests.MathCore.Ode.Values.pas',
  DelphiDoom.Tests.MathCore.Curve.Parity in 'Source\DelphiDoom.Tests.MathCore.Curve.Parity.pas',
  DelphiDoom.Tests.MathCore.Curve.Values in 'Source\DelphiDoom.Tests.MathCore.Curve.Values.pas',
  DelphiDoom.Tests.MathCore.Matrix.Api in 'Source\DelphiDoom.Tests.MathCore.Matrix.Api.pas',
  DelphiDoom.Tests.MathCore.Matrix.Values in 'Source\DelphiDoom.Tests.MathCore.Matrix.Values.pas',
  DelphiDoom.Tests.MathCore.Matrix.Parity in 'Source\DelphiDoom.Tests.MathCore.Matrix.Parity.pas',
  DelphiDoom.Tests.MathCore.Matrix.Decompositions.Parity in 'Source\DelphiDoom.Tests.MathCore.Matrix.Decompositions.Parity.pas',
  DelphiDoom.Tests.MathCore.Matrix.Decompositions.Values in 'Source\DelphiDoom.Tests.MathCore.Matrix.Decompositions.Values.pas',
  DelphiDoom.Tests.MathCore.Interpolate.Parity in 'Source\DelphiDoom.Tests.MathCore.Interpolate.Parity.pas',
  DelphiDoom.Tests.MathCore.Interpolate.Values in 'Source\DelphiDoom.Tests.MathCore.Interpolate.Values.pas',
  DelphiDoom.Tests.MathCore.Surface.SweptSpline in 'Source\DelphiDoom.Tests.MathCore.Surface.SweptSpline.pas',
  DelphiDoom.MathCore.Patch.Types in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.Types.pas',
  DelphiDoom.MathCore.Patch.Intf in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.Intf.pas',
  DelphiDoom.MathCore.Patch.VertexMath in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.VertexMath.pas',
  DelphiDoom.MathCore.Patch.ControlMesh in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.ControlMesh.pas',
  DelphiDoom.MathCore.Patch.Normals in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.Normals.pas',
  DelphiDoom.MathCore.Patch.Grid in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.Grid.pas',
  DelphiDoom.MathCore.Patch.Subdivider in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.Subdivider.pas',
  DelphiDoom.MathCore.Patch.GridEditor in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.GridEditor.pas',
  DelphiDoom.MathCore.Patch.Factory in '..\Framework\MathCore\DelphiDoom.MathCore.Patch.Factory.pas',
  DelphiDoom.Tests.MathCore.Patch.Parity in 'Source\DelphiDoom.Tests.MathCore.Patch.Parity.pas',
  DelphiDoom.Tests.MathCore.Patch.Values in 'Source\DelphiDoom.Tests.MathCore.Patch.Values.pas';

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
