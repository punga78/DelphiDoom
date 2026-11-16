{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Texture library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Texture;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Imaging.Types in '..\Framework\Imaging\DelphiDoom.Imaging.Types.pas',
  DelphiDoom.Imaging.ColorMath in '..\Framework\Imaging\DelphiDoom.Imaging.ColorMath.pas',
  DelphiDoom.Texture.Types in '..\Framework\Texture\DelphiDoom.Texture.Types.pas',
  DelphiDoom.Texture.Colors in '..\Framework\Texture\DelphiDoom.Texture.Colors.pas',
  DelphiDoom.Texture.ByteReader in '..\Framework\Texture\DelphiDoom.Texture.ByteReader.pas',
  DelphiDoom.Texture.Image in '..\Framework\Texture\DelphiDoom.Texture.Image.pas',
  DelphiDoom.Texture.Alpha in '..\Framework\Texture\DelphiDoom.Texture.Alpha.pas',
  DelphiDoom.Texture.Intf in '..\Framework\Texture\DelphiDoom.Texture.Intf.pas',
  DelphiDoom.Texture.Decoder.Bmp in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Bmp.pas',
  DelphiDoom.Texture.Decoder.Tga in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Tga.pas',
  DelphiDoom.Texture.Decoder.PcxLegacy in '..\Framework\Texture\DelphiDoom.Texture.Decoder.PcxLegacy.pas',
  DelphiDoom.Texture.Decoder.Pcx in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Pcx.pas',
  DelphiDoom.Texture.Decoder.Flat in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Flat.pas',
  DelphiDoom.Texture.Decoder.Patch in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Patch.pas',
  DelphiDoom.Texture.Decoder.Material in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Material.pas',
  DelphiDoom.Texture.Decoder.PngBase in '..\Framework\Texture\DelphiDoom.Texture.Decoder.PngBase.pas',
  DelphiDoom.Texture.Decoder.PngTexture in '..\Framework\Texture\DelphiDoom.Texture.Decoder.PngTexture.pas',
  DelphiDoom.Texture.Decoder.PngSprite in '..\Framework\Texture\DelphiDoom.Texture.Decoder.PngSprite.pas',
  DelphiDoom.Texture.Decoder.Jpeg in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Jpeg.pas',
  DelphiDoom.Texture.PatchInspector in '..\Framework\Texture\DelphiDoom.Texture.PatchInspector.pas',
  DelphiDoom.Texture.Formats in '..\Framework\Texture\DelphiDoom.Texture.Formats.pas',
  DelphiDoom.Texture.Factory in '..\Framework\Texture\DelphiDoom.Texture.Factory.pas',
  DelphiDoom.Tests.Texture.Samples in 'Source\DelphiDoom.Tests.Texture.Samples.pas',
  DelphiDoom.Tests.Texture.Golden in 'Source\DelphiDoom.Tests.Texture.Golden.pas',
  DelphiDoom.Tests.Texture.Fakes in 'Source\DelphiDoom.Tests.Texture.Fakes.pas',
  DelphiDoom.Tests.Texture.Operations in 'Source\DelphiDoom.Tests.Texture.Operations.pas',
  DelphiDoom.Tests.Texture.Colors in 'Source\DelphiDoom.Tests.Texture.Colors.pas',
  DelphiDoom.Tests.Texture.ByteReader in 'Source\DelphiDoom.Tests.Texture.ByteReader.pas',
  DelphiDoom.Tests.Texture.Image in 'Source\DelphiDoom.Tests.Texture.Image.pas',
  DelphiDoom.Tests.Texture.Alpha in 'Source\DelphiDoom.Tests.Texture.Alpha.pas',
  DelphiDoom.Tests.Texture.BmpDecoder in 'Source\DelphiDoom.Tests.Texture.BmpDecoder.pas',
  DelphiDoom.Tests.Texture.TgaDecoder in 'Source\DelphiDoom.Tests.Texture.TgaDecoder.pas',
  DelphiDoom.Tests.Texture.PcxDecoder in 'Source\DelphiDoom.Tests.Texture.PcxDecoder.pas',
  DelphiDoom.Tests.Texture.FlatDecoder in 'Source\DelphiDoom.Tests.Texture.FlatDecoder.pas',
  DelphiDoom.Tests.Texture.PatchDecoder in 'Source\DelphiDoom.Tests.Texture.PatchDecoder.pas',
  DelphiDoom.Tests.Texture.PatchInspector in 'Source\DelphiDoom.Tests.Texture.PatchInspector.pas',
  DelphiDoom.Tests.Texture.MaterialDecoder in 'Source\DelphiDoom.Tests.Texture.MaterialDecoder.pas',
  DelphiDoom.Tests.Texture.PngTextureDecoder in 'Source\DelphiDoom.Tests.Texture.PngTextureDecoder.pas',
  DelphiDoom.Tests.Texture.PngSpriteDecoder in 'Source\DelphiDoom.Tests.Texture.PngSpriteDecoder.pas',
  DelphiDoom.Tests.Texture.JpegDecoder in 'Source\DelphiDoom.Tests.Texture.JpegDecoder.pas',
  DelphiDoom.Tests.Texture.Formats in 'Source\DelphiDoom.Tests.Texture.Formats.pas',
  DelphiDoom.Tests.Texture.Factory in 'Source\DelphiDoom.Tests.Texture.Factory.pas',
  DelphiDoom.Tests.Texture.Parity in 'Source\DelphiDoom.Tests.Texture.Parity.pas',
  DelphiDoom.Tests.Texture.Pk3 in 'Source\DelphiDoom.Tests.Texture.Pk3.pas',
  DelphiDoom.Imaging.Rgba.Image in '..\Framework\Imaging\DelphiDoom.Imaging.Rgba.Image.pas',
  DelphiDoom.Imaging.Rgba.Sampler in '..\Framework\Imaging\DelphiDoom.Imaging.Rgba.Sampler.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Framework\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Framework\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.Texture.Dds.Types in '..\Framework\Texture\DelphiDoom.Texture.Dds.Types.pas',
  DelphiDoom.Texture.Dds.BlockDecoder in '..\Framework\Texture\DelphiDoom.Texture.Dds.BlockDecoder.pas',
  DelphiDoom.Texture.Dds.Reader in '..\Framework\Texture\DelphiDoom.Texture.Dds.Reader.pas',
  DelphiDoom.Texture.Dds.Writer in '..\Framework\Texture\DelphiDoom.Texture.Dds.Writer.pas',
  DelphiDoom.Texture.Decoder.Dds in '..\Framework\Texture\DelphiDoom.Texture.Decoder.Dds.pas',
  DelphiDoom.Texture.Tga.IdReader in '..\Framework\Texture\DelphiDoom.Texture.Tga.IdReader.pas',
  DelphiDoom.Texture.IdImage.Intf in '..\Framework\Texture\DelphiDoom.Texture.IdImage.Intf.pas',
  DelphiDoom.Texture.IdImage.Bmp in '..\Framework\Texture\DelphiDoom.Texture.IdImage.Bmp.pas',
  DelphiDoom.Texture.IdImage.Pcx in '..\Framework\Texture\DelphiDoom.Texture.IdImage.Pcx.pas',
  DelphiDoom.Texture.IdImage.Loader in '..\Framework\Texture\DelphiDoom.Texture.IdImage.Loader.pas',
  DelphiDoom.Texture.IdImage.JpegViaBitmap in '..\Framework\Texture\DelphiDoom.Texture.IdImage.JpegViaBitmap.pas',
  DelphiDoom.Tests.IdImages.Golden in 'Source\DelphiDoom.Tests.IdImages.Golden.pas',
  DelphiDoom.Tests.Texture.DdsBlockDecoder in 'Source\DelphiDoom.Tests.Texture.DdsBlockDecoder.pas',
  DelphiDoom.Tests.Texture.DdsReader in 'Source\DelphiDoom.Tests.Texture.DdsReader.pas',
  DelphiDoom.Tests.Texture.DdsWriter in 'Source\DelphiDoom.Tests.Texture.DdsWriter.pas',
  DelphiDoom.Tests.Texture.IdImageLoader in 'Source\DelphiDoom.Tests.Texture.IdImageLoader.pas',
  DelphiDoom.Tests.Texture.TgaIdReader in 'Source\DelphiDoom.Tests.Texture.TgaIdReader.pas';


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
