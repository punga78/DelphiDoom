{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the IWAD library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Iwad;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Iwad.Types in '..\Libs\Iwad\DelphiDoom.Iwad.Types.pas',
  DelphiDoom.Iwad.Intf in '..\Libs\Iwad\DelphiDoom.Iwad.Intf.pas',
  DelphiDoom.Iwad.PathList in '..\Libs\Iwad\DelphiDoom.Iwad.PathList.pas',
  DelphiDoom.Iwad.EnvironmentDirectories in '..\Libs\Iwad\DelphiDoom.Iwad.EnvironmentDirectories.pas',
  DelphiDoom.Iwad.EnvironmentPathLists in '..\Libs\Iwad\DelphiDoom.Iwad.EnvironmentPathLists.pas',
  DelphiDoom.Iwad.AdditionalPaths in '..\Libs\Iwad\DelphiDoom.Iwad.AdditionalPaths.pas',
  DelphiDoom.Iwad.SteamPaths in '..\Libs\Iwad\DelphiDoom.Iwad.SteamPaths.pas',
  DelphiDoom.Iwad.Locator in '..\Libs\Iwad\DelphiDoom.Iwad.Locator.pas',
  DelphiDoom.Iwad.Profile in '..\Libs\Iwad\DelphiDoom.Iwad.Profile.pas',
  DelphiDoom.Iwad.Games in '..\Libs\Iwad\DelphiDoom.Iwad.Games.pas',
  DelphiDoom.Iwad.Identifier in '..\Libs\Iwad\DelphiDoom.Iwad.Identifier.pas',
  DelphiDoom.Iwad.WindowsEnvironment in '..\Libs\Iwad\DelphiDoom.Iwad.WindowsEnvironment.pas',
  DelphiDoom.Iwad.DiskFileSystem in '..\Libs\Iwad\DelphiDoom.Iwad.DiskFileSystem.pas',
  DelphiDoom.Iwad.SteamRegistry in '..\Libs\Iwad\DelphiDoom.Iwad.SteamRegistry.pas',
  DelphiDoom.Iwad.Factory in '..\Libs\Iwad\DelphiDoom.Iwad.Factory.pas',
  DelphiDoom.Tests.Iwad.Fakes in 'Source\DelphiDoom.Tests.Iwad.Fakes.pas',
  DelphiDoom.Tests.Iwad.PathList in 'Source\DelphiDoom.Tests.Iwad.PathList.pas',
  DelphiDoom.Tests.Iwad.EnvironmentDirectories in 'Source\DelphiDoom.Tests.Iwad.EnvironmentDirectories.pas',
  DelphiDoom.Tests.Iwad.EnvironmentPathLists in 'Source\DelphiDoom.Tests.Iwad.EnvironmentPathLists.pas',
  DelphiDoom.Tests.Iwad.AdditionalPaths in 'Source\DelphiDoom.Tests.Iwad.AdditionalPaths.pas',
  DelphiDoom.Tests.Iwad.SteamPaths in 'Source\DelphiDoom.Tests.Iwad.SteamPaths.pas',
  DelphiDoom.Tests.Iwad.Locator in 'Source\DelphiDoom.Tests.Iwad.Locator.pas',
  DelphiDoom.Tests.Iwad.Games in 'Source\DelphiDoom.Tests.Iwad.Games.pas',
  DelphiDoom.Tests.Iwad.Identifier in 'Source\DelphiDoom.Tests.Iwad.Identifier.pas',
  DelphiDoom.Tests.Iwad.Parity in 'Source\DelphiDoom.Tests.Iwad.Parity.pas',
  DelphiDoom.Tests.Iwad.Windows in 'Source\DelphiDoom.Tests.Iwad.Windows.pas';

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
