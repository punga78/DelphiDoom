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
  DelphiDoom.MathCore.Types in '..\Libs\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.Intf in '..\Libs\MathCore\DelphiDoom.MathCore.Intf.pas',
  DelphiDoom.MathCore.TableFineSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineSine.pas',
  DelphiDoom.MathCore.TableFineTangent in '..\Libs\MathCore\DelphiDoom.MathCore.TableFineTangent.pas',
  DelphiDoom.MathCore.TableTanToAngle in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngle.pas',
  DelphiDoom.MathCore.TableTanToAngleEx in '..\Libs\MathCore\DelphiDoom.MathCore.TableTanToAngleEx.pas',
  DelphiDoom.MathCore.TableFixedSine in '..\Libs\MathCore\DelphiDoom.MathCore.TableFixedSine.pas',
  DelphiDoom.MathCore.TableRandom in '..\Libs\MathCore\DelphiDoom.MathCore.TableRandom.pas',
  DelphiDoom.MathCore.TableSysRandom in '..\Libs\MathCore\DelphiDoom.MathCore.TableSysRandom.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.FixedMath in '..\Libs\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.MemoryFill in '..\Libs\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
  DelphiDoom.MathCore.PixelBatch in '..\Libs\MathCore\DelphiDoom.MathCore.PixelBatch.pas',
  DelphiDoom.MathCore.Trigonometry in '..\Libs\MathCore\DelphiDoom.MathCore.Trigonometry.pas',
  DelphiDoom.MathCore.VectorMath in '..\Libs\MathCore\DelphiDoom.MathCore.VectorMath.pas',
  DelphiDoom.MathCore.BoundingBox in '..\Libs\MathCore\DelphiDoom.MathCore.BoundingBox.pas',
  DelphiDoom.MathCore.IntegerStack in '..\Libs\MathCore\DelphiDoom.MathCore.IntegerStack.pas',
  DelphiDoom.MathCore.IntegerQueue in '..\Libs\MathCore\DelphiDoom.MathCore.IntegerQueue.pas',
  DelphiDoom.MathCore.GameRandom in '..\Libs\MathCore\DelphiDoom.MathCore.GameRandom.pas',
  DelphiDoom.MathCore.SystemEntropySource in '..\Libs\MathCore\DelphiDoom.MathCore.SystemEntropySource.pas',
  DelphiDoom.MathCore.StringHashTable in '..\Libs\MathCore\DelphiDoom.MathCore.StringHashTable.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.MathCore.Sha1 in '..\Libs\MathCore\DelphiDoom.MathCore.Sha1.pas',
  DelphiDoom.MathCore.Factory in '..\Libs\MathCore\DelphiDoom.MathCore.Factory.pas',
  DelphiDoom.Tests.MathCore.Fingerprint in 'Source\DelphiDoom.Tests.MathCore.Fingerprint.pas',
  DelphiDoom.Tests.MathCore.Samples in 'Source\DelphiDoom.Tests.MathCore.Samples.pas',
  DelphiDoom.Tests.MathCore.Golden in 'Source\DelphiDoom.Tests.MathCore.Golden.pas',
  DelphiDoom.Tests.MathCore.PairRunner in 'Source\DelphiDoom.Tests.MathCore.PairRunner.pas',
  DelphiDoom.Tests.MathCore.FixedMath in 'Source\DelphiDoom.Tests.MathCore.FixedMath.pas',
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
  DelphiDoom.IdLib.Core.Exceptions in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Math.Math in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.MathCore.Float.Angles in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Angles.pas',
  DelphiDoom.MathCore.Float.Quat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Quat.pas',
  DelphiDoom.MathCore.Float.CQuat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.CQuat.pas',
  DelphiDoom.MathCore.Float.Mat3 in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Mat3.pas',
  DelphiDoom.MathCore.Float.Rotation in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Rotation.pas',
  DelphiDoom.MathCore.Float.Complex in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Complex.pas',
  DelphiDoom.MathCore.Float.Polynomial in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Polynomial.pas',
  DelphiDoom.MathCore.Float.Conversions in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Conversions.pas',
  DelphiDoom.Geometry.Types in '..\Libs\Geometry\DelphiDoom.Geometry.Types.pas',
  DelphiDoom.Geometry.FloatMath in '..\Libs\Geometry\DelphiDoom.Geometry.FloatMath.pas',
  DelphiDoom.Geometry.Vec3 in '..\Libs\Geometry\DelphiDoom.Geometry.Vec3.pas',
  DelphiDoom.Geometry.Mat3 in '..\Libs\Geometry\DelphiDoom.Geometry.Mat3.pas',
  DelphiDoom.Geometry.Plane in '..\Libs\Geometry\DelphiDoom.Geometry.Plane.pas',
  DelphiDoom.Geometry.Sphere in '..\Libs\Geometry\DelphiDoom.Geometry.Sphere.pas',
  DelphiDoom.Geometry.Bounds in '..\Libs\Geometry\DelphiDoom.Geometry.Bounds.pas',
  DelphiDoom.Geometry.Box in '..\Libs\Geometry\DelphiDoom.Geometry.Box.pas',
  DelphiDoom.MathCore.Float.GeometryAdapter in '..\Libs\MathCore\DelphiDoom.MathCore.Float.GeometryAdapter.pas',
  DelphiDoom.MathCore.Float.BoundsRotation in '..\Libs\MathCore\DelphiDoom.MathCore.Float.BoundsRotation.pas',
  DelphiDoom.Tests.IdLib.Golden in 'Source\DelphiDoom.Tests.IdLib.Golden.pas',
  DelphiDoom.Tests.MathCore.Geometry.Parity in 'Source\DelphiDoom.Tests.MathCore.Geometry.Parity.pas',
  DelphiDoom.Tests.MathCore.Geometry.Values in 'Source\DelphiDoom.Tests.MathCore.Geometry.Values.pas',
  DelphiDoom.Tests.MathCore.Float.Parity in 'Source\DelphiDoom.Tests.MathCore.Float.Parity.pas',
  DelphiDoom.Tests.MathCore.Float.Values in 'Source\DelphiDoom.Tests.MathCore.Float.Values.pas';

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
