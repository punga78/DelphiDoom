{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the cinematic library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Cinematic;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.IdLib.Math.Math in '..\Libs\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.Imaging.Types in '..\Libs\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Cinematic.Types in '..\Libs\Cinematic\DelphiDoom.Cinematic.Types.pas',
  DelphiDoom.Cinematic.Intf in '..\Libs\Cinematic\DelphiDoom.Cinematic.Intf.pas',
  DelphiDoom.Cinematic.Jpeg.Intf in '..\Libs\Cinematic\DelphiDoom.Cinematic.Jpeg.Intf.pas',
  DelphiDoom.Cinematic.MemorySource in '..\Libs\Cinematic\DelphiDoom.Cinematic.MemorySource.pas',
  DelphiDoom.Cinematic.StreamSource in '..\Libs\Cinematic\DelphiDoom.Cinematic.StreamSource.pas',
  DelphiDoom.Cinematic.YuvConverter in '..\Libs\Cinematic\DelphiDoom.Cinematic.YuvConverter.pas',
  DelphiDoom.Cinematic.SoundDecoder in '..\Libs\Cinematic\DelphiDoom.Cinematic.SoundDecoder.pas',
  DelphiDoom.Cinematic.Codebook in '..\Libs\Cinematic\DelphiDoom.Cinematic.Codebook.pas',
  DelphiDoom.Cinematic.ModeCodebook in '..\Libs\Cinematic\DelphiDoom.Cinematic.ModeCodebook.pas',
  DelphiDoom.Cinematic.QuadMap in '..\Libs\Cinematic\DelphiDoom.Cinematic.QuadMap.pas',
  DelphiDoom.Cinematic.FramePainter in '..\Libs\Cinematic\DelphiDoom.Cinematic.FramePainter.pas',
  DelphiDoom.Cinematic.Decoder in '..\Libs\Cinematic\DelphiDoom.Cinematic.Decoder.pas',
  DelphiDoom.Cinematic.Player in '..\Libs\Cinematic\DelphiDoom.Cinematic.Player.pas',
  DelphiDoom.Cinematic.AudioCollector in '..\Libs\Cinematic\DelphiDoom.Cinematic.AudioCollector.pas',
  DelphiDoom.Cinematic.Factory in '..\Libs\Cinematic\DelphiDoom.Cinematic.Factory.pas',
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
  DelphiDoom.Cinematic.Jpeg.Decoder in '..\Libs\Cinematic\DelphiDoom.Cinematic.Jpeg.Decoder.pas',
  DelphiDoom.Cinematic.Jpeg.Factory in '..\Libs\Cinematic\DelphiDoom.Cinematic.Jpeg.Factory.pas',
  DelphiDoom.Flic.Types in '..\Libs\Flic\DelphiDoom.Flic.Types.pas',
  DelphiDoom.Flic.FrameDecoder in '..\Libs\Flic\DelphiDoom.Flic.FrameDecoder.pas',
  DelphiDoom.Cinematic.Flic.Types in '..\Libs\Cinematic\DelphiDoom.Cinematic.Flic.Types.pas',
  DelphiDoom.Cinematic.Flic.Intf in '..\Libs\Cinematic\DelphiDoom.Cinematic.Flic.Intf.pas',
  DelphiDoom.Cinematic.Flic.PixelConverter in '..\Libs\Cinematic\DelphiDoom.Cinematic.Flic.PixelConverter.pas',
  DelphiDoom.Cinematic.Flic.Decoder in '..\Libs\Cinematic\DelphiDoom.Cinematic.Flic.Decoder.pas',
  DelphiDoom.Cinematic.Flic.Player in '..\Libs\Cinematic\DelphiDoom.Cinematic.Flic.Player.pas',
  DelphiDoom.Cinematic.Flic.Factory in '..\Libs\Cinematic\DelphiDoom.Cinematic.Flic.Factory.pas',
  DelphiDoom.Tests.Cinematic.Support in 'Source\DelphiDoom.Tests.Cinematic.Support.pas',
  DelphiDoom.Tests.Cinematic.Types in 'Source\DelphiDoom.Tests.Cinematic.Types.pas',
  DelphiDoom.Tests.Cinematic.Sources in 'Source\DelphiDoom.Tests.Cinematic.Sources.pas',
  DelphiDoom.Tests.Cinematic.YuvConverter in 'Source\DelphiDoom.Tests.Cinematic.YuvConverter.pas',
  DelphiDoom.Tests.Cinematic.SoundDecoder in 'Source\DelphiDoom.Tests.Cinematic.SoundDecoder.pas',
  DelphiDoom.Tests.Cinematic.Codebook in 'Source\DelphiDoom.Tests.Cinematic.Codebook.pas',
  DelphiDoom.Tests.Cinematic.QuadMap in 'Source\DelphiDoom.Tests.Cinematic.QuadMap.pas',
  DelphiDoom.Tests.Cinematic.FramePainter in 'Source\DelphiDoom.Tests.Cinematic.FramePainter.pas',
  DelphiDoom.Tests.Cinematic.Decoder in 'Source\DelphiDoom.Tests.Cinematic.Decoder.pas',
  DelphiDoom.Tests.Cinematic.Player in 'Source\DelphiDoom.Tests.Cinematic.Player.pas',
  DelphiDoom.Tests.Cinematic.AudioCollector in 'Source\DelphiDoom.Tests.Cinematic.AudioCollector.pas',
  DelphiDoom.Tests.Cinematic.Parity in 'Source\DelphiDoom.Tests.Cinematic.Parity.pas',
  DelphiDoom.Tests.Cinematic.FlicSupport in 'Source\DelphiDoom.Tests.Cinematic.FlicSupport.pas',
  DelphiDoom.Tests.Cinematic.FlicPixelConverter in 'Source\DelphiDoom.Tests.Cinematic.FlicPixelConverter.pas',
  DelphiDoom.Tests.Cinematic.FlicDecoder in 'Source\DelphiDoom.Tests.Cinematic.FlicDecoder.pas',
  DelphiDoom.Tests.Cinematic.FlicPlayer in 'Source\DelphiDoom.Tests.Cinematic.FlicPlayer.pas',
  DelphiDoom.Tests.Cinematic.FlicParity in 'Source\DelphiDoom.Tests.Cinematic.FlicParity.pas',
  DelphiDoom.Tests.Cinematic.ModeCodebook in 'Source\DelphiDoom.Tests.Cinematic.ModeCodebook.pas',
  DelphiDoom.Tests.Cinematic.ModeParity in 'Source\DelphiDoom.Tests.Cinematic.ModeParity.pas',
  DelphiDoom.Tests.Cinematic.JpegDecoder in 'Source\DelphiDoom.Tests.Cinematic.JpegDecoder.pas',
  DelphiDoom.Tests.Cinematic.DecoderJpeg in 'Source\DelphiDoom.Tests.Cinematic.DecoderJpeg.pas';

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
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
