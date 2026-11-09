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
  DelphiDoom.Zlib.Intf in '..\Libs\Zlib\DelphiDoom.Zlib.Intf.pas',
  DelphiDoom.Zlib.Inflater in '..\Libs\Zlib\DelphiDoom.Zlib.Inflater.pas',
  DelphiDoom.Zlib.Deflater in '..\Libs\Zlib\DelphiDoom.Zlib.Deflater.pas',
  DelphiDoom.Zlib.Engine in '..\Libs\Zlib\DelphiDoom.Zlib.Engine.pas',
  DelphiDoom.Zlib.Loader in '..\Libs\Zlib\DelphiDoom.Zlib.Loader.pas',
  DelphiDoom.Zlib.Client in '..\Libs\Zlib\DelphiDoom.Zlib.Client.pas',
  DelphiDoom.Zlib.Provider in '..\Libs\Zlib\DelphiDoom.Zlib.Provider.pas',
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
  DelphiDoom.Png.Loader in '..\Libs\Png\DelphiDoom.Png.Loader.pas',
  DelphiDoom.Png.Provider in '..\Libs\Png\DelphiDoom.Png.Provider.pas',
  DelphiDoom.Texture.PngFileWriter in '..\Libs\Texture\DelphiDoom.Texture.PngFileWriter.pas',
  DelphiDoom.Tests.Png.Samples in 'Source\DelphiDoom.Tests.Png.Samples.pas',
  DelphiDoom.Tests.Png.Engine in 'Source\DelphiDoom.Tests.Png.Engine.pas',
  DelphiDoom.Tests.Png.Client in 'Source\DelphiDoom.Tests.Png.Client.pas',
  DelphiDoom.Tests.Png.Loader in 'Source\DelphiDoom.Tests.Png.Loader.pas',
  DelphiDoom.Tests.Png.Provider in 'Source\DelphiDoom.Tests.Png.Provider.pas',
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
