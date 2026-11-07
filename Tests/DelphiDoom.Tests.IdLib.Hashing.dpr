{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the idLib hashing (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.IdLib.Hashing;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.IdLib.Hashing.Types in '..\Libs\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Types.pas',
  DelphiDoom.IdLib.Hashing.Md4 in '..\Libs\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Md4.pas',
  DelphiDoom.IdLib.Hashing.Md5 in '..\Libs\IdLib\Hashing\DelphiDoom.IdLib.Hashing.Md5.pas',
  DelphiDoom.Tests.IdLib.Golden in 'Source\DelphiDoom.Tests.IdLib.Golden.pas',
  DelphiDoom.Tests.IdLib.Hashing.Cases in 'Source\DelphiDoom.Tests.IdLib.Hashing.Cases.pas',
  DelphiDoom.Tests.IdLib.Hashing.Md4 in 'Source\DelphiDoom.Tests.IdLib.Hashing.Md4.pas',
  DelphiDoom.Tests.IdLib.Hashing.Md5 in 'Source\DelphiDoom.Tests.IdLib.Hashing.Md5.pas',
  DelphiDoom.Tests.IdLib.Hashing.Crc32 in 'Source\DelphiDoom.Tests.IdLib.Hashing.Crc32.pas';

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