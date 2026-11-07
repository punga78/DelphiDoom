{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Ogg library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Ogg;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Ogg.Types in '..\Libs\Ogg\DelphiDoom.Ogg.Types.pas',
  DelphiDoom.Ogg.Memory in '..\Libs\Ogg\DelphiDoom.Ogg.Memory.pas',
  DelphiDoom.Ogg.Crc in '..\Libs\Ogg\DelphiDoom.Ogg.Crc.pas',
  DelphiDoom.Ogg.BitPacker in '..\Libs\Ogg\DelphiDoom.Ogg.BitPacker.pas',
  DelphiDoom.Ogg.PageReader in '..\Libs\Ogg\DelphiDoom.Ogg.PageReader.pas',
  DelphiDoom.Ogg.Stream in '..\Libs\Ogg\DelphiDoom.Ogg.Stream.pas',
  DelphiDoom.Ogg.Sync in '..\Libs\Ogg\DelphiDoom.Ogg.Sync.pas',
  DelphiDoom.Tests.Ogg.Backends in 'Source\DelphiDoom.Tests.Ogg.Backends.pas',
  DelphiDoom.Tests.Ogg.Structures in 'Source\DelphiDoom.Tests.Ogg.Structures.pas',
  DelphiDoom.Tests.Ogg.BitPacker in 'Source\DelphiDoom.Tests.Ogg.BitPacker.pas',
  DelphiDoom.Tests.Ogg.Framing in 'Source\DelphiDoom.Tests.Ogg.Framing.pas',
  DelphiDoom.Tests.Ogg.Memory in 'Source\DelphiDoom.Tests.Ogg.Memory.pas',
  DelphiDoom.Tests.Ogg.Stream in 'Source\DelphiDoom.Tests.Ogg.Stream.pas',
  DelphiDoom.Tests.Ogg.Sync in 'Source\DelphiDoom.Tests.Ogg.Sync.pas';

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
