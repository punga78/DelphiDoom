{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the geometry and collision libraries (DUnitX)     }
{                                                                              }
{  The libraries derive from Doom 3 GPL Source Code (GPL v3 with additional    }
{  terms): this test program is GPL v3 as well                                 }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Collision;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Logging.Log in '..\Libs\Logging\DelphiDoom.Logging.Log.pas',
  DelphiDoom.Logging.Recorder in '..\Libs\Logging\DelphiDoom.Logging.Recorder.pas',
  DelphiDoom.Logging.Factory in '..\Libs\Logging\DelphiDoom.Logging.Factory.pas',
  DelphiDoom.Geometry.Types in '..\Libs\Geometry\DelphiDoom.Geometry.Types.pas',
  DelphiDoom.Geometry.FloatMath in '..\Libs\Geometry\DelphiDoom.Geometry.FloatMath.pas',
  DelphiDoom.Geometry.Vec3 in '..\Libs\Geometry\DelphiDoom.Geometry.Vec3.pas',
  DelphiDoom.Geometry.Mat3 in '..\Libs\Geometry\DelphiDoom.Geometry.Mat3.pas',
  DelphiDoom.Geometry.Plane in '..\Libs\Geometry\DelphiDoom.Geometry.Plane.pas',
  DelphiDoom.Geometry.Bounds in '..\Libs\Geometry\DelphiDoom.Geometry.Bounds.pas',
  DelphiDoom.Geometry.Pluecker in '..\Libs\Geometry\DelphiDoom.Geometry.Pluecker.pas',
  DelphiDoom.Geometry.Winding in '..\Libs\Geometry\DelphiDoom.Geometry.Winding.pas',
  DelphiDoom.Geometry.TraceModel in '..\Libs\Geometry\DelphiDoom.Geometry.TraceModel.pas',
  DelphiDoom.Collision.Types in '..\Libs\Collision\DelphiDoom.Collision.Types.pas',
  DelphiDoom.Collision.Model.Types in '..\Libs\Collision\DelphiDoom.Collision.Model.Types.pas',
  DelphiDoom.Collision.Model.Polygon in '..\Libs\Collision\DelphiDoom.Collision.Model.Polygon.pas',
  DelphiDoom.Collision.Model.Brush in '..\Libs\Collision\DelphiDoom.Collision.Model.Brush.pas',
  DelphiDoom.Collision.Model.Node in '..\Libs\Collision\DelphiDoom.Collision.Model.Node.pas',
  DelphiDoom.Collision.Model in '..\Libs\Collision\DelphiDoom.Collision.Model.pas',
  DelphiDoom.Collision.Intf in '..\Libs\Collision\DelphiDoom.Collision.Intf.pas',
  DelphiDoom.Collision.HashIndex in '..\Libs\Collision\DelphiDoom.Collision.HashIndex.pas',
  DelphiDoom.Collision.CheckCounter in '..\Libs\Collision\DelphiDoom.Collision.CheckCounter.pas',
  DelphiDoom.Collision.Sidedness in '..\Libs\Collision\DelphiDoom.Collision.Sidedness.pas',
  DelphiDoom.Collision.Builder.Table in '..\Libs\Collision\DelphiDoom.Collision.Builder.Table.pas',
  DelphiDoom.Collision.Builder.Bsp in '..\Libs\Collision\DelphiDoom.Collision.Builder.Bsp.pas',
  DelphiDoom.Collision.Builder.EdgeNormals in '..\Libs\Collision\DelphiDoom.Collision.Builder.EdgeNormals.pas',
  DelphiDoom.Collision.Builder.Optimizer in '..\Libs\Collision\DelphiDoom.Collision.Builder.Optimizer.pas',
  DelphiDoom.Collision.Builder in '..\Libs\Collision\DelphiDoom.Collision.Builder.pas',
  DelphiDoom.Collision.TraceWork in '..\Libs\Collision\DelphiDoom.Collision.TraceWork.pas',
  DelphiDoom.Collision.Translator in '..\Libs\Collision\DelphiDoom.Collision.Translator.pas',
  DelphiDoom.Collision.ContentsTester in '..\Libs\Collision\DelphiDoom.Collision.ContentsTester.pas',
  DelphiDoom.Collision.Tracer in '..\Libs\Collision\DelphiDoom.Collision.Tracer.pas',
  DelphiDoom.Collision.ContentsRunner in '..\Libs\Collision\DelphiDoom.Collision.ContentsRunner.pas',
  DelphiDoom.Collision.TranslationRunner in '..\Libs\Collision\DelphiDoom.Collision.TranslationRunner.pas',
  DelphiDoom.Collision.TrmModel in '..\Libs\Collision\DelphiDoom.Collision.TrmModel.pas',
  DelphiDoom.Collision.TrmExtractor in '..\Libs\Collision\DelphiDoom.Collision.TrmExtractor.pas',
  DelphiDoom.Collision.ContentsNames in '..\Libs\Collision\DelphiDoom.Collision.ContentsNames.pas',
  DelphiDoom.Collision.CmFile.Tokenizer in '..\Libs\Collision\DelphiDoom.Collision.CmFile.Tokenizer.pas',
  DelphiDoom.Collision.CmFile.Writer in '..\Libs\Collision\DelphiDoom.Collision.CmFile.Writer.pas',
  DelphiDoom.Collision.CmFile.Reader in '..\Libs\Collision\DelphiDoom.Collision.CmFile.Reader.pas',
  DelphiDoom.Collision.Manager in '..\Libs\Collision\DelphiDoom.Collision.Manager.pas',
  DelphiDoom.Collision.Factory in '..\Libs\Collision\DelphiDoom.Collision.Factory.pas',
  DelphiDoom.Tests.Collision.Support in 'Source\DelphiDoom.Tests.Collision.Support.pas',
  DelphiDoom.Tests.Geometry.Math in 'Source\DelphiDoom.Tests.Geometry.Math.pas',
  DelphiDoom.Tests.Geometry.Winding in 'Source\DelphiDoom.Tests.Geometry.Winding.pas',
  DelphiDoom.Tests.Collision.Builder in 'Source\DelphiDoom.Tests.Collision.Builder.pas',
  DelphiDoom.Tests.Collision.Translation in 'Source\DelphiDoom.Tests.Collision.Translation.pas',
  DelphiDoom.Tests.Collision.CmFile in 'Source\DelphiDoom.Tests.Collision.CmFile.pas',
  DelphiDoom.Tests.Collision.Parity in 'Source\DelphiDoom.Tests.Collision.Parity.pas';

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
