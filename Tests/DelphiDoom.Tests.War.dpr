{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the war library (DUnitX)                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.War;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.TableCrc32 in '..\Libs\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Libs\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.War.Types in '..\Libs\War\DelphiDoom.War.Types.pas',
  DelphiDoom.War.Intf in '..\Libs\War\DelphiDoom.War.Intf.pas',
  DelphiDoom.War.LittleEndian in '..\Libs\War\DelphiDoom.War.LittleEndian.pas',
  DelphiDoom.War.Decompressor in '..\Libs\War\DelphiDoom.War.Decompressor.pas',
  DelphiDoom.War.Archive in '..\Libs\War\DelphiDoom.War.Archive.pas',
  DelphiDoom.War.StreamSource in '..\Libs\War\DelphiDoom.War.StreamSource.pas',
  DelphiDoom.War.Catalog.Data in '..\Libs\War\DelphiDoom.War.Catalog.Data.pas',
  DelphiDoom.War.Catalog in '..\Libs\War\DelphiDoom.War.Catalog.pas',
  DelphiDoom.War.Factory in '..\Libs\War\DelphiDoom.War.Factory.pas',
  DelphiDoom.Tests.War.Builders in 'Source\DelphiDoom.Tests.War.Builders.pas',
  DelphiDoom.Tests.War.RealData in 'Source\DelphiDoom.Tests.War.RealData.pas',
  DelphiDoom.Tests.War.Types in 'Source\DelphiDoom.Tests.War.Types.pas',
  DelphiDoom.Tests.War.Decompressor in 'Source\DelphiDoom.Tests.War.Decompressor.pas',
  DelphiDoom.Tests.War.Archive in 'Source\DelphiDoom.Tests.War.Archive.pas',
  DelphiDoom.Tests.War.Catalog in 'Source\DelphiDoom.Tests.War.Catalog.pas',
  DelphiDoom.Tests.War.StreamSource in 'Source\DelphiDoom.Tests.War.StreamSource.pas',
  DelphiDoom.Tests.War.Parity in 'Source\DelphiDoom.Tests.War.Parity.pas';

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
