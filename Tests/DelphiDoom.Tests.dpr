{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests;

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
  DelphiDoom.Zlib.Loader in '..\Libs\Zlib\DelphiDoom.Zlib.Loader.pas',
  DelphiDoom.Zlib.Provider in '..\Libs\Zlib\DelphiDoom.Zlib.Provider.pas',
  DelphiDoom.Tests.Zlib.Engine in 'Source\DelphiDoom.Tests.Zlib.Engine.pas',
  DelphiDoom.Tests.Zlib.Client in 'Source\DelphiDoom.Tests.Zlib.Client.pas',
  DelphiDoom.Tests.Zlib.Loader in 'Source\DelphiDoom.Tests.Zlib.Loader.pas',
  DelphiDoom.Tests.Zlib.Provider in 'Source\DelphiDoom.Tests.Zlib.Provider.pas',
  ide_binary in '..\DD_IDE\ide_binary.pas',
  DelphiDoom.Tests.Ide.Binary in 'Source\DelphiDoom.Tests.Ide.Binary.pas';

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
