{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Mikmod library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Mikmod;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DirectX in '..\Common\DirectX.pas',
  BTMemoryModule in '..\Base\BTMemoryModule.pas',
  mikmod in '..\Base\mikmod.pas',
  DelphiDoom.Mikmod.Intf in '..\Libs\Mikmod\DelphiDoom.Mikmod.Intf.pas',
  DelphiDoom.Mikmod.Player in '..\Libs\Mikmod\DelphiDoom.Mikmod.Player.pas',
  DelphiDoom.Mikmod.Engine in '..\Libs\Mikmod\DelphiDoom.Mikmod.Engine.pas',
  DelphiDoom.Mikmod.Client in '..\Libs\Mikmod\DelphiDoom.Mikmod.Client.pas',
  DelphiDoom.Mikmod.Loader in '..\Libs\Mikmod\DelphiDoom.Mikmod.Loader.pas',
  DelphiDoom.Mikmod.Provider in '..\Libs\Mikmod\DelphiDoom.Mikmod.Provider.pas',
  DelphiDoom.Tracker.Types in '..\Libs\Mikmod\DelphiDoom.Tracker.Types.pas',
  DelphiDoom.Tracker.ByteReader in '..\Libs\Mikmod\DelphiDoom.Tracker.ByteReader.pas',
  DelphiDoom.Tracker.Loader.ProTracker in '..\Libs\Mikmod\DelphiDoom.Tracker.Loader.ProTracker.pas',
  DelphiDoom.Tracker.Loader.S3m in '..\Libs\Mikmod\DelphiDoom.Tracker.Loader.S3m.pas',
  DelphiDoom.Tests.Tracker.Loader.ProTracker in 'Source\DelphiDoom.Tests.Tracker.Loader.ProTracker.pas',
  DelphiDoom.Tests.Tracker.Loader.S3m in 'Source\DelphiDoom.Tests.Tracker.Loader.S3m.pas',
  DelphiDoom.Tests.Mikmod.Engine in 'Source\DelphiDoom.Tests.Mikmod.Engine.pas',
  DelphiDoom.Tests.Mikmod.Client in 'Source\DelphiDoom.Tests.Mikmod.Client.pas',
  DelphiDoom.Tests.Mikmod.Loader in 'Source\DelphiDoom.Tests.Mikmod.Loader.pas',
  DelphiDoom.Tests.Mikmod.Provider in 'Source\DelphiDoom.Tests.Mikmod.Provider.pas';

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

