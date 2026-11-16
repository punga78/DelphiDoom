{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Png library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Png;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  // zlib: the PNG code compresses with an IZlib, the tests give it an engine
  // linked in the executable (and, in the loader tests, the one of DDZlib.dll)
  DelphiDoom.Zlib.Intf in '..\Framework\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Inflater in '..\Framework\Zlib\DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in '..\Framework\Zlib\DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in '..\Framework\Zlib\DelphiDoom.Zlib.Engine.pas',
  DelphiDoom.Zlib.Loader in '..\Framework\Zlib\DelphiDoom.Zlib.Loader.pas',
  DelphiDoom.Zlib.Client in '..\Framework\Zlib\DelphiDoom.Zlib.Client.pas',
  DelphiDoom.Zlib.Provider in '..\Framework\Zlib\DelphiDoom.Zlib.Provider.pas',
  DelphiDoom.Png.Intf in '..\Framework\Png\DelphiDoom.Png.Intf.pas',
  DelphiDoom.Png.Crc in '..\Framework\Png\DelphiDoom.Png.Crc.pas',
  DelphiDoom.Png.ByteOrder in '..\Framework\Png\DelphiDoom.Png.ByteOrder.pas',
  DelphiDoom.Png.Predictor in '..\Framework\Png\DelphiDoom.Png.Predictor.pas',
  DelphiDoom.Png.Header in '..\Framework\Png\DelphiDoom.Png.Header.pas',
  DelphiDoom.Png.Adam7 in '..\Framework\Png\DelphiDoom.Png.Adam7.pas',
  DelphiDoom.Png.ChunkReader in '..\Framework\Png\DelphiDoom.Png.ChunkReader.pas',
  DelphiDoom.Png.ChunkWriter in '..\Framework\Png\DelphiDoom.Png.ChunkWriter.pas',
  DelphiDoom.Png.Metadata in '..\Framework\Png\DelphiDoom.Png.Metadata.pas',
  DelphiDoom.Png.IdatStream in '..\Framework\Png\DelphiDoom.Png.IdatStream.pas',
  DelphiDoom.Png.Unfilter in '..\Framework\Png\DelphiDoom.Png.Unfilter.pas',
  DelphiDoom.Png.PixelConverter in '..\Framework\Png\DelphiDoom.Png.PixelConverter.pas',
  DelphiDoom.Png.Decoder in '..\Framework\Png\DelphiDoom.Png.Decoder.pas',
  DelphiDoom.Png.Filter in '..\Framework\Png\DelphiDoom.Png.Filter.pas',
  DelphiDoom.Png.PixelPacker in '..\Framework\Png\DelphiDoom.Png.PixelPacker.pas',
  DelphiDoom.Png.Encoder in '..\Framework\Png\DelphiDoom.Png.Encoder.pas',
  DelphiDoom.Png.Engine in '..\Framework\Png\DelphiDoom.Png.Engine.pas',
  DelphiDoom.Png.Client in '..\Framework\Png\DelphiDoom.Png.Client.pas',
  DelphiDoom.Png.Loader in '..\Framework\Png\DelphiDoom.Png.Loader.pas',
  DelphiDoom.Png.Provider in '..\Framework\Png\DelphiDoom.Png.Provider.pas',
  DelphiDoom.Png.IndexedImage in '..\Framework\Png\DelphiDoom.Png.IndexedImage.pas',
  DelphiDoom.Png.IndexedEncoder.Intf in '..\Framework\Png\DelphiDoom.Png.IndexedEncoder.Intf.pas',
  DelphiDoom.Png.IndexedEncoder in '..\Framework\Png\DelphiDoom.Png.IndexedEncoder.pas',
  DelphiDoom.Png.PaletteEncoder.Intf in '..\Framework\Png\DelphiDoom.Png.PaletteEncoder.Intf.pas',
  DelphiDoom.Png.PaletteEncoder in '..\Framework\Png\DelphiDoom.Png.PaletteEncoder.pas',
  DelphiDoom.Texture.PngFileWriter in '..\Framework\Texture\DelphiDoom.Texture.PngFileWriter.pas',
  DelphiDoom.Tests.Png.Samples in 'Source\DelphiDoom.Tests.Png.Samples.pas',
  DelphiDoom.Tests.Png.Engine in 'Source\DelphiDoom.Tests.Png.Engine.pas',
  DelphiDoom.Tests.Png.Client in 'Source\DelphiDoom.Tests.Png.Client.pas',
  DelphiDoom.Tests.Png.Loader in 'Source\DelphiDoom.Tests.Png.Loader.pas',
  DelphiDoom.Tests.Png.Provider in 'Source\DelphiDoom.Tests.Png.Provider.pas',
  DelphiDoom.Tests.Png.IndexedEncoder in 'Source\DelphiDoom.Tests.Png.IndexedEncoder.pas',
  DelphiDoom.Tests.Png.PaletteEncoder in 'Source\DelphiDoom.Tests.Png.PaletteEncoder.pas',
  DelphiDoom.Tests.Texture.PngFileWriter in 'Source\DelphiDoom.Tests.Texture.PngFileWriter.pas';

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
