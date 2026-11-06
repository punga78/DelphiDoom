{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the MUSINFO library (DUnitX)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.MusInfo;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Libs\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Libs\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Scanner.Strings in '..\Libs\Scanner\DelphiDoom.Scanner.Strings.pas',
  DelphiDoom.Scanner.Scanner in '..\Libs\Scanner\DelphiDoom.Scanner.Scanner.pas',
  DelphiDoom.MusInfo.Types in '..\Libs\MusInfo\DelphiDoom.MusInfo.Types.pas',
  DelphiDoom.MusInfo.Intf in '..\Libs\MusInfo\DelphiDoom.MusInfo.Intf.pas',
  DelphiDoom.MusInfo.Parser in '..\Libs\MusInfo\DelphiDoom.MusInfo.Parser.pas',
  DelphiDoom.MusInfo.Catalog in '..\Libs\MusInfo\DelphiDoom.MusInfo.Catalog.pas',
  DelphiDoom.MusInfo.Loader in '..\Libs\MusInfo\DelphiDoom.MusInfo.Loader.pas',
  DelphiDoom.MusInfo.Factory in '..\Libs\MusInfo\DelphiDoom.MusInfo.Factory.pas',
  DelphiDoom.Tests.MusInfo.Fakes in 'Source\DelphiDoom.Tests.MusInfo.Fakes.pas',
  DelphiDoom.Tests.MusInfo.Corpus in 'Source\DelphiDoom.Tests.MusInfo.Corpus.pas',
  DelphiDoom.Tests.MusInfo.Parity in 'Source\DelphiDoom.Tests.MusInfo.Parity.pas',
  DelphiDoom.Tests.MusInfo.Parser in 'Source\DelphiDoom.Tests.MusInfo.Parser.pas',
  DelphiDoom.Tests.MusInfo.Catalog in 'Source\DelphiDoom.Tests.MusInfo.Catalog.pas',
  DelphiDoom.Tests.MusInfo.Loader in 'Source\DelphiDoom.Tests.MusInfo.Loader.pas';

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
