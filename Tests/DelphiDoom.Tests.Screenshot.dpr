{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Screenshot library (DUnitX)                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Screenshot;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Zlib.Intf in '..\Libs\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Inflater in '..\Libs\Zlib\DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in '..\Libs\Zlib\DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in '..\Libs\Zlib\DelphiDoom.Zlib.Engine.pas',
  DelphiDoom.Zlib.Client in '..\Libs\Zlib\DelphiDoom.Zlib.Client.pas',
  DelphiDoom.Png.Intf in '..\Libs\Png\DelphiDoom.Png.Intf.pas',
  DelphiDoom.Png.Crc in '..\Libs\Png\DelphiDoom.Png.Crc.pas',
  DelphiDoom.Png.ByteOrder in '..\Libs\Png\DelphiDoom.Png.ByteOrder.pas',
  DelphiDoom.Png.Predictor in '..\Libs\Png\DelphiDoom.Png.Predictor.pas',
  DelphiDoom.Png.Header in '..\Libs\Png\DelphiDoom.Png.Header.pas',
  DelphiDoom.Png.Adam7 in '..\Libs\Png\DelphiDoom.Png.Adam7.pas',
  DelphiDoom.Png.ChunkReader in '..\Libs\Png\DelphiDoom.Png.ChunkReader.pas',
  DelphiDoom.Png.ChunkWriter in '..\Libs\Png\DelphiDoom.Png.ChunkWriter.pas',
  DelphiDoom.Png.Metadata in '..\Libs\Png\DelphiDoom.Png.Metadata.pas',
  DelphiDoom.Png.IdatStream in '..\Libs\Png\DelphiDoom.Png.IdatStream.pas',
  DelphiDoom.Png.Unfilter in '..\Libs\Png\DelphiDoom.Png.Unfilter.pas',
  DelphiDoom.Png.PixelConverter in '..\Libs\Png\DelphiDoom.Png.PixelConverter.pas',
  DelphiDoom.Png.Decoder in '..\Libs\Png\DelphiDoom.Png.Decoder.pas',
  DelphiDoom.Png.Filter in '..\Libs\Png\DelphiDoom.Png.Filter.pas',
  DelphiDoom.Png.PixelPacker in '..\Libs\Png\DelphiDoom.Png.PixelPacker.pas',
  DelphiDoom.Png.Encoder in '..\Libs\Png\DelphiDoom.Png.Encoder.pas',
  DelphiDoom.Png.Engine in '..\Libs\Png\DelphiDoom.Png.Engine.pas',
  DelphiDoom.Png.Client in '..\Libs\Png\DelphiDoom.Png.Client.pas',
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
  DelphiDoom.Screenshot.Types in '..\Libs\Screenshot\DelphiDoom.Screenshot.Types.pas',
  DelphiDoom.Screenshot.Formats in '..\Libs\Screenshot\DelphiDoom.Screenshot.Formats.pas',
  DelphiDoom.Screenshot.Intf in '..\Libs\Screenshot\DelphiDoom.Screenshot.Intf.pas',
  DelphiDoom.Screenshot.EncoderBase in '..\Libs\Screenshot\DelphiDoom.Screenshot.EncoderBase.pas',
  DelphiDoom.Screenshot.TgaEncoder in '..\Libs\Screenshot\DelphiDoom.Screenshot.TgaEncoder.pas',
  DelphiDoom.Screenshot.PngEncoder in '..\Libs\Screenshot\DelphiDoom.Screenshot.PngEncoder.pas',
  DelphiDoom.Screenshot.JpegEncoder in '..\Libs\Screenshot\DelphiDoom.Screenshot.JpegEncoder.pas',
  DelphiDoom.Screenshot.FileSink in '..\Libs\Screenshot\DelphiDoom.Screenshot.FileSink.pas',
  DelphiDoom.Screenshot.Writer in '..\Libs\Screenshot\DelphiDoom.Screenshot.Writer.pas',
  DelphiDoom.Screenshot.Targets in '..\Libs\Screenshot\DelphiDoom.Screenshot.Targets.pas',
  DelphiDoom.Screenshot.Factory in '..\Libs\Screenshot\DelphiDoom.Screenshot.Factory.pas',
  DelphiDoom.Tests.Imaging.Samples in 'Source\DelphiDoom.Tests.Imaging.Samples.pas',
  DelphiDoom.Tests.Screenshot.Golden in 'Source\DelphiDoom.Tests.Screenshot.Golden.pas',
  DelphiDoom.Tests.Screenshot.Fakes in 'Source\DelphiDoom.Tests.Screenshot.Fakes.pas',
  DelphiDoom.Tests.Screenshot.Formats in 'Source\DelphiDoom.Tests.Screenshot.Formats.pas',
  DelphiDoom.Tests.Screenshot.Targets in 'Source\DelphiDoom.Tests.Screenshot.Targets.pas',
  DelphiDoom.Tests.Screenshot.TgaEncoder in 'Source\DelphiDoom.Tests.Screenshot.TgaEncoder.pas',
  DelphiDoom.Tests.Screenshot.PngEncoder in 'Source\DelphiDoom.Tests.Screenshot.PngEncoder.pas',
  DelphiDoom.Tests.Screenshot.JpegEncoder in 'Source\DelphiDoom.Tests.Screenshot.JpegEncoder.pas',
  DelphiDoom.Tests.Screenshot.Writer in 'Source\DelphiDoom.Tests.Screenshot.Writer.pas',
  DelphiDoom.Tests.Screenshot.FileSink in 'Source\DelphiDoom.Tests.Screenshot.FileSink.pas',
  DelphiDoom.Tests.Screenshot.Factory in 'Source\DelphiDoom.Tests.Screenshot.Factory.pas';

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
