{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the compression library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Compression;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Containers.HashIndex in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.HashIndex.pas',
  DelphiDoom.Compression.Types in '..\Libs\Compression\DelphiDoom.Compression.Types.pas',
  DelphiDoom.Compression.Intf in '..\Libs\Compression\DelphiDoom.Compression.Intf.pas',
  DelphiDoom.Compression.None in '..\Libs\Compression\DelphiDoom.Compression.None.pas',
  DelphiDoom.Compression.BitStream in '..\Libs\Compression\DelphiDoom.Compression.BitStream.pas',
  DelphiDoom.Compression.RunLength in '..\Libs\Compression\DelphiDoom.Compression.RunLength.pas',
  DelphiDoom.Compression.RunLengthZeroBased in '..\Libs\Compression\DelphiDoom.Compression.RunLengthZeroBased.pas',
  DelphiDoom.Compression.Huffman in '..\Libs\Compression\DelphiDoom.Compression.Huffman.pas',
  DelphiDoom.Compression.Arithmetic in '..\Libs\Compression\DelphiDoom.Compression.Arithmetic.pas',
  DelphiDoom.Compression.Lzss in '..\Libs\Compression\DelphiDoom.Compression.Lzss.pas',
  DelphiDoom.Compression.LzssWordAligned in '..\Libs\Compression\DelphiDoom.Compression.LzssWordAligned.pas',
  DelphiDoom.Compression.Lzw in '..\Libs\Compression\DelphiDoom.Compression.Lzw.pas',
  DelphiDoom.Compression.Factory in '..\Libs\Compression\DelphiDoom.Compression.Factory.pas',
  DelphiDoom.Tests.Compression.Compressors in 'Source\DelphiDoom.Tests.Compression.Compressors.pas',
  DelphiDoom.Tests.Compression.Parity in 'Source\DelphiDoom.Tests.Compression.Parity.pas';

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
