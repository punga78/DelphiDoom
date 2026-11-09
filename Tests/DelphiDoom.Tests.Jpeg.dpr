{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Jpeg library (DUnitX)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Jpeg;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Jpeg.Intf in '..\Libs\Jpeg\DelphiDoom.Jpeg.Intf.pas',
  DelphiDoom.Jpeg.Types in '..\Libs\Jpeg\DelphiDoom.Jpeg.Types.pas',
  DelphiDoom.Jpeg.ByteSource in '..\Libs\Jpeg\DelphiDoom.Jpeg.ByteSource.pas',
  DelphiDoom.Jpeg.Frame in '..\Libs\Jpeg\DelphiDoom.Jpeg.Frame.pas',
  DelphiDoom.Jpeg.MarkerReader in '..\Libs\Jpeg\DelphiDoom.Jpeg.MarkerReader.pas',
  DelphiDoom.Jpeg.HuffmanTable in '..\Libs\Jpeg\DelphiDoom.Jpeg.HuffmanTable.pas',
  DelphiDoom.Jpeg.BitReader in '..\Libs\Jpeg\DelphiDoom.Jpeg.BitReader.pas',
  DelphiDoom.Jpeg.EntropyDecoder in '..\Libs\Jpeg\DelphiDoom.Jpeg.EntropyDecoder.pas',
  DelphiDoom.Jpeg.EntropyDecoderBase in '..\Libs\Jpeg\DelphiDoom.Jpeg.EntropyDecoderBase.pas',
  DelphiDoom.Jpeg.SequentialDecoder in '..\Libs\Jpeg\DelphiDoom.Jpeg.SequentialDecoder.pas',
  DelphiDoom.Jpeg.ProgressiveDecoder in '..\Libs\Jpeg\DelphiDoom.Jpeg.ProgressiveDecoder.pas',
  DelphiDoom.Jpeg.InverseDct in '..\Libs\Jpeg\DelphiDoom.Jpeg.InverseDct.pas',
  DelphiDoom.Jpeg.SlowInverseDct in '..\Libs\Jpeg\DelphiDoom.Jpeg.SlowInverseDct.pas',
  DelphiDoom.Jpeg.ComponentBuffers in '..\Libs\Jpeg\DelphiDoom.Jpeg.ComponentBuffers.pas',
  DelphiDoom.Jpeg.RowUpsampler in '..\Libs\Jpeg\DelphiDoom.Jpeg.RowUpsampler.pas',
  DelphiDoom.Jpeg.ReplicatingUpsampler in '..\Libs\Jpeg\DelphiDoom.Jpeg.ReplicatingUpsampler.pas',
  DelphiDoom.Jpeg.FancyUpsamplerH2V1 in '..\Libs\Jpeg\DelphiDoom.Jpeg.FancyUpsamplerH2V1.pas',
  DelphiDoom.Jpeg.FancyUpsamplerH2V2 in '..\Libs\Jpeg\DelphiDoom.Jpeg.FancyUpsamplerH2V2.pas',
  DelphiDoom.Jpeg.ColorConverter in '..\Libs\Jpeg\DelphiDoom.Jpeg.ColorConverter.pas',
  DelphiDoom.Jpeg.GrayConverter in '..\Libs\Jpeg\DelphiDoom.Jpeg.GrayConverter.pas',
  DelphiDoom.Jpeg.RgbConverter in '..\Libs\Jpeg\DelphiDoom.Jpeg.RgbConverter.pas',
  DelphiDoom.Jpeg.YccConverter in '..\Libs\Jpeg\DelphiDoom.Jpeg.YccConverter.pas',
  DelphiDoom.Jpeg.ColorConverterFactory in '..\Libs\Jpeg\DelphiDoom.Jpeg.ColorConverterFactory.pas',
  DelphiDoom.Jpeg.RowRenderer in '..\Libs\Jpeg\DelphiDoom.Jpeg.RowRenderer.pas',
  DelphiDoom.Jpeg.BlockSmoother in '..\Libs\Jpeg\DelphiDoom.Jpeg.BlockSmoother.pas',
  DelphiDoom.Jpeg.McuTarget in '..\Libs\Jpeg\DelphiDoom.Jpeg.McuTarget.pas',
  DelphiDoom.Jpeg.CoefficientTarget in '..\Libs\Jpeg\DelphiDoom.Jpeg.CoefficientTarget.pas',
  DelphiDoom.Jpeg.SampleTarget in '..\Libs\Jpeg\DelphiDoom.Jpeg.SampleTarget.pas',
  DelphiDoom.Jpeg.Decompressor in '..\Libs\Jpeg\DelphiDoom.Jpeg.Decompressor.pas',
  DelphiDoom.Jpeg.Decoder in '..\Libs\Jpeg\DelphiDoom.Jpeg.Decoder.pas',
  DelphiDoom.Jpeg.Encoder in '..\Libs\Jpeg\DelphiDoom.Jpeg.Encoder.pas',
  DelphiDoom.Jpeg.Engine in '..\Libs\Jpeg\DelphiDoom.Jpeg.Engine.pas',
  DelphiDoom.Jpeg.Client in '..\Libs\Jpeg\DelphiDoom.Jpeg.Client.pas',
  DelphiDoom.Jpeg.Loader in '..\Libs\Jpeg\DelphiDoom.Jpeg.Loader.pas',
  DelphiDoom.Jpeg.Provider in '..\Libs\Jpeg\DelphiDoom.Jpeg.Provider.pas',
  DelphiDoom.Texture.JpegBitmap in '..\Libs\Texture\DelphiDoom.Texture.JpegBitmap.pas',
  DelphiDoom.Tests.Jpeg.Random in 'Source\DelphiDoom.Tests.Jpeg.Random.pas',
  DelphiDoom.Tests.Jpeg.Digest in 'Source\DelphiDoom.Tests.Jpeg.Digest.pas',
  DelphiDoom.Tests.Jpeg.Synthesizer in 'Source\DelphiDoom.Tests.Jpeg.Synthesizer.pas',
  DelphiDoom.Tests.Jpeg.TinyStream in 'Source\DelphiDoom.Tests.Jpeg.TinyStream.pas',
  DelphiDoom.Tests.Jpeg.Observer in 'Source\DelphiDoom.Tests.Jpeg.Observer.pas',
  DelphiDoom.Tests.Jpeg.Cases in 'Source\DelphiDoom.Tests.Jpeg.Cases.pas',
  DelphiDoom.Tests.Jpeg.Parity in 'Source\DelphiDoom.Tests.Jpeg.Parity.pas',
  DelphiDoom.Tests.Jpeg.Types in 'Source\DelphiDoom.Tests.Jpeg.Types.pas',
  DelphiDoom.Tests.Jpeg.ByteSource in 'Source\DelphiDoom.Tests.Jpeg.ByteSource.pas',
  DelphiDoom.Tests.Jpeg.HuffmanTable in 'Source\DelphiDoom.Tests.Jpeg.HuffmanTable.pas',
  DelphiDoom.Tests.Jpeg.BitReader in 'Source\DelphiDoom.Tests.Jpeg.BitReader.pas',
  DelphiDoom.Tests.Jpeg.MarkerReader in 'Source\DelphiDoom.Tests.Jpeg.MarkerReader.pas',
  DelphiDoom.Tests.Jpeg.Frame in 'Source\DelphiDoom.Tests.Jpeg.Frame.pas',
  DelphiDoom.Tests.Jpeg.SlowInverseDct in 'Source\DelphiDoom.Tests.Jpeg.SlowInverseDct.pas',
  DelphiDoom.Tests.Jpeg.Rows in 'Source\DelphiDoom.Tests.Jpeg.Rows.pas',
  DelphiDoom.Tests.Jpeg.ReplicatingUpsampler in 'Source\DelphiDoom.Tests.Jpeg.ReplicatingUpsampler.pas',
  DelphiDoom.Tests.Jpeg.FancyUpsamplerH2V1 in 'Source\DelphiDoom.Tests.Jpeg.FancyUpsamplerH2V1.pas',
  DelphiDoom.Tests.Jpeg.FancyUpsamplerH2V2 in 'Source\DelphiDoom.Tests.Jpeg.FancyUpsamplerH2V2.pas',
  DelphiDoom.Tests.Jpeg.GrayConverter in 'Source\DelphiDoom.Tests.Jpeg.GrayConverter.pas',
  DelphiDoom.Tests.Jpeg.RgbConverter in 'Source\DelphiDoom.Tests.Jpeg.RgbConverter.pas',
  DelphiDoom.Tests.Jpeg.YccConverter in 'Source\DelphiDoom.Tests.Jpeg.YccConverter.pas',
  DelphiDoom.Tests.Jpeg.ColorConverterFactory in 'Source\DelphiDoom.Tests.Jpeg.ColorConverterFactory.pas',
  DelphiDoom.Tests.Jpeg.ComponentBuffers in 'Source\DelphiDoom.Tests.Jpeg.ComponentBuffers.pas',
  DelphiDoom.Tests.Jpeg.McuTargets in 'Source\DelphiDoom.Tests.Jpeg.McuTargets.pas',
  DelphiDoom.Tests.Jpeg.BlockSmoother in 'Source\DelphiDoom.Tests.Jpeg.BlockSmoother.pas',
  DelphiDoom.Tests.Jpeg.RowRenderer in 'Source\DelphiDoom.Tests.Jpeg.RowRenderer.pas',
  DelphiDoom.Tests.Jpeg.SequentialDecoder in 'Source\DelphiDoom.Tests.Jpeg.SequentialDecoder.pas',
  DelphiDoom.Tests.Jpeg.ProgressiveDecoder in 'Source\DelphiDoom.Tests.Jpeg.ProgressiveDecoder.pas',
  DelphiDoom.Tests.Jpeg.Decoder in 'Source\DelphiDoom.Tests.Jpeg.Decoder.pas',
  DelphiDoom.Tests.Jpeg.Decompressor in 'Source\DelphiDoom.Tests.Jpeg.Decompressor.pas',
  DelphiDoom.Tests.Jpeg.Regression in 'Source\DelphiDoom.Tests.Jpeg.Regression.pas',
  DelphiDoom.Tests.Jpeg.Engine in 'Source\DelphiDoom.Tests.Jpeg.Engine.pas',
  DelphiDoom.Tests.Jpeg.Client in 'Source\DelphiDoom.Tests.Jpeg.Client.pas',
  DelphiDoom.Tests.Jpeg.Loader in 'Source\DelphiDoom.Tests.Jpeg.Loader.pas',
  DelphiDoom.Tests.Jpeg.Provider in 'Source\DelphiDoom.Tests.Jpeg.Provider.pas',
  DelphiDoom.Tests.Texture.JpegBitmap in 'Source\DelphiDoom.Tests.Texture.JpegBitmap.pas';

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
