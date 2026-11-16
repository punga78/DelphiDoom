{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Imaging library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Imaging;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Imaging.Types in '..\Framework\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.Intf in '..\Framework\Imaging\DelphiDoom.Imaging.Intf.pas',
  DelphiDoom.Imaging.ColorMath in '..\Framework\Imaging\DelphiDoom.Imaging.ColorMath.pas',
  DelphiDoom.Imaging.ColumnPainter in '..\Framework\Imaging\DelphiDoom.Imaging.ColumnPainter.pas',
  DelphiDoom.Imaging.ColumnRebuilder in '..\Framework\Imaging\DelphiDoom.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Imaging.FixedColumn in '..\Framework\Imaging\DelphiDoom.Imaging.FixedColumn.pas',
  DelphiDoom.Imaging.PatchReader in '..\Framework\Imaging\DelphiDoom.Imaging.PatchReader.pas',
  DelphiDoom.Imaging.FlatReader in '..\Framework\Imaging\DelphiDoom.Imaging.FlatReader.pas',
  DelphiDoom.Imaging.FlatShrinker in '..\Framework\Imaging\DelphiDoom.Imaging.FlatShrinker.pas',
  DelphiDoom.Imaging.SpanGrower in '..\Framework\Imaging\DelphiDoom.Imaging.SpanGrower.pas',
  DelphiDoom.Imaging.ColumnExpander in '..\Framework\Imaging\DelphiDoom.Imaging.ColumnExpander.pas',
  DelphiDoom.Imaging.HiResTables in '..\Framework\Imaging\DelphiDoom.Imaging.HiResTables.pas',
  DelphiDoom.Imaging.MeltWipe in '..\Framework\Imaging\DelphiDoom.Imaging.MeltWipe.pas',
  DelphiDoom.Imaging.SineTable in '..\Framework\Imaging\DelphiDoom.Imaging.SineTable.pas',
  DelphiDoom.Imaging.WallScale in '..\Framework\Imaging\DelphiDoom.Imaging.WallScale.pas',
  DelphiDoom.Imaging.ThumbnailBuilder in '..\Framework\Imaging\DelphiDoom.Imaging.ThumbnailBuilder.pas',
  DelphiDoom.Imaging.SaveThumbnail in '..\Framework\Imaging\DelphiDoom.Imaging.SaveThumbnail.pas',
  DelphiDoom.Imaging.Resampler in '..\Framework\Imaging\DelphiDoom.Imaging.Resampler.pas',
  DelphiDoom.Imaging.Factory in '..\Framework\Imaging\DelphiDoom.Imaging.Factory.pas',
  DelphiDoom.Imaging.ColorPatchBuilder in '..\Framework\Imaging\DelphiDoom.Imaging.ColorPatchBuilder.pas',
  DelphiDoom.Tests.Imaging.Samples in 'Source\DelphiDoom.Tests.Imaging.Samples.pas',
  DelphiDoom.Tests.Imaging.ResampleCases in 'Source\DelphiDoom.Tests.Imaging.ResampleCases.pas',
  DelphiDoom.Tests.Endoom.Digest in 'Source\DelphiDoom.Tests.Endoom.Digest.pas',
  DelphiDoom.Tests.Imaging.Golden in 'Source\DelphiDoom.Tests.Imaging.Golden.pas',
  DelphiDoom.Tests.Imaging.Types in 'Source\DelphiDoom.Tests.Imaging.Types.pas',
  DelphiDoom.Tests.Imaging.ColorMath in 'Source\DelphiDoom.Tests.Imaging.ColorMath.pas',
  DelphiDoom.Tests.Imaging.ColumnPainter in 'Source\DelphiDoom.Tests.Imaging.ColumnPainter.pas',
  DelphiDoom.Tests.Imaging.ColumnRebuilder in 'Source\DelphiDoom.Tests.Imaging.ColumnRebuilder.pas',
  DelphiDoom.Tests.Imaging.FixedColumn in 'Source\DelphiDoom.Tests.Imaging.FixedColumn.pas',
  DelphiDoom.Tests.Imaging.PatchReader in 'Source\DelphiDoom.Tests.Imaging.PatchReader.pas',
  DelphiDoom.Tests.Imaging.FlatReader in 'Source\DelphiDoom.Tests.Imaging.FlatReader.pas',
  DelphiDoom.Tests.Imaging.FlatShrinker in 'Source\DelphiDoom.Tests.Imaging.FlatShrinker.pas',
  DelphiDoom.Tests.Imaging.SpanGrower in 'Source\DelphiDoom.Tests.Imaging.SpanGrower.pas',
  DelphiDoom.Tests.Imaging.ColumnExpander in 'Source\DelphiDoom.Tests.Imaging.ColumnExpander.pas',
  DelphiDoom.Tests.Imaging.HiResTables in 'Source\DelphiDoom.Tests.Imaging.HiResTables.pas',
  DelphiDoom.Tests.Imaging.MeltWipe in 'Source\DelphiDoom.Tests.Imaging.MeltWipe.pas',
  DelphiDoom.Tests.Imaging.OldWipe in 'Source\DelphiDoom.Tests.Imaging.OldWipe.pas',
  DelphiDoom.Tests.Imaging.SineTable in 'Source\DelphiDoom.Tests.Imaging.SineTable.pas',
  DelphiDoom.Tests.Imaging.WallScale in 'Source\DelphiDoom.Tests.Imaging.WallScale.pas',
  DelphiDoom.Tests.Imaging.ThumbnailBuilder in 'Source\DelphiDoom.Tests.Imaging.ThumbnailBuilder.pas',
  DelphiDoom.Tests.Imaging.SaveThumbnail in 'Source\DelphiDoom.Tests.Imaging.SaveThumbnail.pas',
  DelphiDoom.Tests.Imaging.Factory in 'Source\DelphiDoom.Tests.Imaging.Factory.pas',
  DelphiDoom.Tests.Imaging.Resampler in 'Source\DelphiDoom.Tests.Imaging.Resampler.pas',
  DelphiDoom.Imaging.PatchWriter in '..\Framework\Imaging\DelphiDoom.Imaging.PatchWriter.pas',
  DelphiDoom.Tests.Sound.Digest in 'Source\DelphiDoom.Tests.Sound.Digest.pas',
  DelphiDoom.Tests.Font.Golden in 'Source\DelphiDoom.Tests.Font.Golden.pas',
  DelphiDoom.Tests.Font.Scenarios in 'Source\DelphiDoom.Tests.Font.Scenarios.pas',
  DelphiDoom.Tests.Imaging.PatchWriter in 'Source\DelphiDoom.Tests.Imaging.PatchWriter.pas',
  DelphiDoom.Tests.Imaging.ColorPatchBuilder in 'Source\DelphiDoom.Tests.Imaging.ColorPatchBuilder.pas',
  DelphiDoom.IdLib.Core.Exceptions in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Core.Intf in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Intf.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Text.Str in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Str.pas',
  DelphiDoom.IdLib.Text.Types in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Types.pas',
  DelphiDoom.IdLib.Text.Token in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Token.pas',
  DelphiDoom.IdLib.Text.Lexer in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Lexer.pas',
  DelphiDoom.IdLib.Math.Math in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Framework\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Framework\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.Imaging.Rgba.Image in '..\Framework\Imaging\DelphiDoom.Imaging.Rgba.Image.pas',
  DelphiDoom.Imaging.Rgba.Sampler in '..\Framework\Imaging\DelphiDoom.Imaging.Rgba.Sampler.pas',
  DelphiDoom.Imaging.ImageProgram.Intf in '..\Framework\Imaging\DelphiDoom.Imaging.ImageProgram.Intf.pas',
  DelphiDoom.Imaging.ImageProgram.Operations in '..\Framework\Imaging\DelphiDoom.Imaging.ImageProgram.Operations.pas',
  DelphiDoom.Imaging.ImageProgram.Interpreter in '..\Framework\Imaging\DelphiDoom.Imaging.ImageProgram.Interpreter.pas',
  DelphiDoom.Tests.IdImages.Golden in 'Source\DelphiDoom.Tests.IdImages.Golden.pas',
  DelphiDoom.Tests.Imaging.RgbaSampler in 'Source\DelphiDoom.Tests.Imaging.RgbaSampler.pas',
  DelphiDoom.Tests.Imaging.ProgramOperations in 'Source\DelphiDoom.Tests.Imaging.ProgramOperations.pas',
  DelphiDoom.Tests.Imaging.ImageProgram in 'Source\DelphiDoom.Tests.Imaging.ImageProgram.pas';

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
