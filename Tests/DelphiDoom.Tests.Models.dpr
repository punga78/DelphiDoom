{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the 3D models library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Models;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.Models.Types in '..\Libs\Models\DelphiDoom.Models.Types.pas',
  DelphiDoom.Models.Definition.Types in '..\Libs\Models\DelphiDoom.Models.Definition.Types.pas',
  DelphiDoom.Models.Definition.Intf in '..\Libs\Models\DelphiDoom.Models.Definition.Intf.pas',
  DelphiDoom.Models.Definition.Parser in '..\Libs\Models\DelphiDoom.Models.Definition.Parser.pas',
  DelphiDoom.Models.I3d.Types in '..\Libs\Models\DelphiDoom.Models.I3d.Types.pas',
  DelphiDoom.Models.I3d.Intf in '..\Libs\Models\DelphiDoom.Models.I3d.Intf.pas',
  DelphiDoom.Models.I3d.Factory in '..\Libs\Models\DelphiDoom.Models.I3d.Factory.pas',
  DelphiDoom.Models.I3d.Palette in '..\Libs\Models\DelphiDoom.Models.I3d.Palette.pas',
  DelphiDoom.Models.I3d.Coordinates in '..\Libs\Models\DelphiDoom.Models.I3d.Coordinates.pas',
  DelphiDoom.Models.I3d.TireAnimator in '..\Libs\Models\DelphiDoom.Models.I3d.TireAnimator.pas',
  DelphiDoom.Models.I3d.Model in '..\Libs\Models\DelphiDoom.Models.I3d.Model.pas',
  DelphiDoom.Models.I3d.Parser in '..\Libs\Models\DelphiDoom.Models.I3d.Parser.pas',
  DelphiDoom.Models.I3d.CorrectionReader in '..\Libs\Models\DelphiDoom.Models.I3d.CorrectionReader.pas',
  DelphiDoom.Models.I3d.Renderer in '..\Libs\Models\DelphiDoom.Models.I3d.Renderer.pas',
  DelphiDoom.Models.I3d.MeshBuilder in '..\Libs\Models\DelphiDoom.Models.I3d.MeshBuilder.pas',
  DelphiDoom.Models.Intf in '..\Libs\Models\DelphiDoom.Models.Intf.pas',
  DelphiDoom.Models.Md2Model in '..\Libs\Models\DelphiDoom.Models.Md2Model.pas',
  DelphiDoom.Models.Md2Parser in '..\Libs\Models\DelphiDoom.Models.Md2Parser.pas',
  DelphiDoom.Models.CommandStream in '..\Libs\Models\DelphiDoom.Models.CommandStream.pas',
  DelphiDoom.Models.Factory in '..\Libs\Models\DelphiDoom.Models.Factory.pas',
  DelphiDoom.IdLib.Core.Exceptions in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Core.Intf in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Intf.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Text.Str in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Str.pas',
  DelphiDoom.IdLib.Text.Types in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Types.pas',
  DelphiDoom.IdLib.Text.Token in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Token.pas',
  DelphiDoom.IdLib.Text.Lexer in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Lexer.pas',
  DelphiDoom.IdLib.Math.Math in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.IdLib.Math.Vec4 in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Vec4.pas',
  DelphiDoom.MathCore.Float.Angles in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Angles.pas',
  DelphiDoom.MathCore.Float.Quat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Quat.pas',
  DelphiDoom.MathCore.Float.CQuat in '..\Libs\MathCore\DelphiDoom.MathCore.Float.CQuat.pas',
  DelphiDoom.MathCore.Float.Mat3 in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Mat3.pas',
  DelphiDoom.MathCore.Float.Rotation in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Rotation.pas',
  DelphiDoom.MathCore.Float.Conversions in '..\Libs\MathCore\DelphiDoom.MathCore.Float.Conversions.pas',
  DelphiDoom.Geometry.FloatMath in '..\Libs\Geometry\DelphiDoom.Geometry.FloatMath.pas',
  DelphiDoom.Geometry.Vec3 in '..\Libs\Geometry\DelphiDoom.Geometry.Vec3.pas',
  DelphiDoom.Geometry.Mat3 in '..\Libs\Geometry\DelphiDoom.Geometry.Mat3.pas',
  DelphiDoom.Geometry.Types in '..\Libs\Geometry\DelphiDoom.Geometry.Types.pas',
  DelphiDoom.Geometry.Plane in '..\Libs\Geometry\DelphiDoom.Geometry.Plane.pas',
  DelphiDoom.Geometry.Bounds in '..\Libs\Geometry\DelphiDoom.Geometry.Bounds.pas',
  DelphiDoom.Models.Md5.Types in '..\Libs\Models\DelphiDoom.Models.Md5.Types.pas',
  DelphiDoom.Models.Md5.JointQuat in '..\Libs\Models\DelphiDoom.Models.Md5.JointQuat.pas',
  DelphiDoom.Models.Md5.JointMat in '..\Libs\Models\DelphiDoom.Models.Md5.JointMat.pas',
  DelphiDoom.Models.Md5.Intf in '..\Libs\Models\DelphiDoom.Models.Md5.Intf.pas',
  DelphiDoom.Models.Md5.Skeleton in '..\Libs\Models\DelphiDoom.Models.Md5.Skeleton.pas',
  DelphiDoom.Models.Md5.Mesh in '..\Libs\Models\DelphiDoom.Models.Md5.Mesh.pas',
  DelphiDoom.Models.Md5.MeshParser in '..\Libs\Models\DelphiDoom.Models.Md5.MeshParser.pas',
  DelphiDoom.Models.Md5.Model in '..\Libs\Models\DelphiDoom.Models.Md5.Model.pas',
  DelphiDoom.Models.Md5.ModelParser in '..\Libs\Models\DelphiDoom.Models.Md5.ModelParser.pas',
  DelphiDoom.Models.Md5.Anim in '..\Libs\Models\DelphiDoom.Models.Md5.Anim.pas',
  DelphiDoom.Models.Md5.AnimParser in '..\Libs\Models\DelphiDoom.Models.Md5.AnimParser.pas',
  DelphiDoom.Models.Md5.Factory in '..\Libs\Models\DelphiDoom.Models.Md5.Factory.pas',
  DelphiDoom.Tests.Models.Md5Golden in 'Source\DelphiDoom.Tests.Models.Md5Golden.pas',
  DelphiDoom.Tests.Models.Md5Parity in 'Source\DelphiDoom.Tests.Models.Md5Parity.pas',
  DelphiDoom.Tests.Models.DefinitionFakes in 'Source\DelphiDoom.Tests.Models.DefinitionFakes.pas',
  DelphiDoom.Tests.Models.OldModelDefinition in 'Source\DelphiDoom.Tests.Models.OldModelDefinition.pas',
  DelphiDoom.Tests.Models.DefinitionParser in 'Source\DelphiDoom.Tests.Models.DefinitionParser.pas',
  DelphiDoom.Tests.Models.Fingerprint in 'Source\DelphiDoom.Tests.Models.Fingerprint.pas',
  DelphiDoom.Tests.Models.Golden in 'Source\DelphiDoom.Tests.Models.Golden.pas',
  DelphiDoom.Tests.Models.Samples in 'Source\DelphiDoom.Tests.Models.Samples.pas',
  DelphiDoom.Tests.Models.Scenarios in 'Source\DelphiDoom.Tests.Models.Scenarios.pas',
  DelphiDoom.Tests.Models.Subject in 'Source\DelphiDoom.Tests.Models.Subject.pas',
  DelphiDoom.Tests.Models.Md2Parser in 'Source\DelphiDoom.Tests.Models.Md2Parser.pas',
  DelphiDoom.Tests.Models.CommandStream in 'Source\DelphiDoom.Tests.Models.CommandStream.pas',
  DelphiDoom.Tests.Models.I3dFileBuilder in 'Source\DelphiDoom.Tests.Models.I3dFileBuilder.pas',
  DelphiDoom.Tests.Models.I3dRecorder in 'Source\DelphiDoom.Tests.Models.I3dRecorder.pas',
  DelphiDoom.Tests.Models.I3dDump in 'Source\DelphiDoom.Tests.Models.I3dDump.pas',
  DelphiDoom.Tests.Models.I3dParser in 'Source\DelphiDoom.Tests.Models.I3dParser.pas',
  DelphiDoom.Tests.Models.I3dRenderer in 'Source\DelphiDoom.Tests.Models.I3dRenderer.pas',
  DelphiDoom.Tests.Models.I3dCoordinates in 'Source\DelphiDoom.Tests.Models.I3dCoordinates.pas',
  DelphiDoom.Tests.Models.I3dPalette in 'Source\DelphiDoom.Tests.Models.I3dPalette.pas',
  DelphiDoom.Tests.Models.I3dTireAnimator in 'Source\DelphiDoom.Tests.Models.I3dTireAnimator.pas',
  DelphiDoom.Tests.Models.I3dCorrections in 'Source\DelphiDoom.Tests.Models.I3dCorrections.pas',
  DelphiDoom.Tests.Models.I3dMeshBuilder in 'Source\DelphiDoom.Tests.Models.I3dMeshBuilder.pas';

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

