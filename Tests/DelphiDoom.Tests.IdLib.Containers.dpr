{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the idLib containers (DUnitX)                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.IdLib.Containers;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.IdLib.Core.Exceptions in '..\Libs\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Libs\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Containers.HashIndex in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.HashIndex.pas',
  DelphiDoom.IdLib.Containers.LinkList in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.LinkList.pas',
  DelphiDoom.IdLib.Containers.Hierarchy in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.Hierarchy.pas',
  DelphiDoom.IdLib.Containers.BinSearch in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.BinSearch.pas',
  DelphiDoom.IdLib.Containers.BTree in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.BTree.pas',
  DelphiDoom.IdLib.Containers.StrPool in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.StrPool.pas',
  DelphiDoom.IdLib.Containers.List in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.List.pas',
  DelphiDoom.IdLib.Containers.StaticList in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.StaticList.pas',
  DelphiDoom.IdLib.Containers.HashTable in '..\Libs\IdLib\Containers\DelphiDoom.IdLib.Containers.HashTable.pas',
  DelphiDoom.Tests.IdLib.Golden in'Source\DelphiDoom.Tests.IdLib.Golden.pas',
  DelphiDoom.Tests.IdLib.Containers.Cases in 'Source\DelphiDoom.Tests.IdLib.Containers.Cases.pas',
  DelphiDoom.Tests.IdLib.Containers.ListCases in 'Source\DelphiDoom.Tests.IdLib.Containers.ListCases.pas',
  DelphiDoom.Tests.IdLib.Containers.ListFixture in 'Source\DelphiDoom.Tests.IdLib.Containers.ListFixture.pas',
  DelphiDoom.Tests.IdLib.Containers.Fixture in 'Source\DelphiDoom.Tests.IdLib.Containers.Fixture.pas';

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