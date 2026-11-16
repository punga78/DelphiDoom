{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the TableExport library (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.TableExport;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.TableExport.Types in '..\IdTech1\TableExport\DelphiDoom.TableExport.Types.pas',
  DelphiDoom.TableExport.Intf in '..\IdTech1\TableExport\DelphiDoom.TableExport.Intf.pas',
  DelphiDoom.TableExport.Text in '..\IdTech1\TableExport\DelphiDoom.TableExport.Text.pas',
  DelphiDoom.TableExport.Profile in '..\IdTech1\TableExport\DelphiDoom.TableExport.Profile.pas',
  DelphiDoom.TableExport.Profiles in '..\IdTech1\TableExport\DelphiDoom.TableExport.Profiles.pas',
  DelphiDoom.TableExport.IndentedText in '..\IdTech1\TableExport\DelphiDoom.TableExport.IndentedText.pas',
  DelphiDoom.TableExport.StateChain in '..\IdTech1\TableExport\DelphiDoom.TableExport.StateChain.pas',
  DelphiDoom.TableExport.DehWriter in '..\IdTech1\TableExport\DelphiDoom.TableExport.DehWriter.pas',
  DelphiDoom.TableExport.CsvWriter in '..\IdTech1\TableExport\DelphiDoom.TableExport.CsvWriter.pas',
  DelphiDoom.TableExport.ActorDefWriter in '..\IdTech1\TableExport\DelphiDoom.TableExport.ActorDefWriter.pas',
  DelphiDoom.TableExport.WeaponDefWriter in '..\IdTech1\TableExport\DelphiDoom.TableExport.WeaponDefWriter.pas',
  DelphiDoom.TableExport.StateOwnersWriter in '..\IdTech1\TableExport\DelphiDoom.TableExport.StateOwnersWriter.pas',
  DelphiDoom.TableExport.PascalWriter in '..\IdTech1\TableExport\DelphiDoom.TableExport.PascalWriter.pas',
  DelphiDoom.TableExport.Factory in '..\IdTech1\TableExport\DelphiDoom.TableExport.Factory.pas',
  DelphiDoom.Tests.TableExport.Fakes in 'Source\DelphiDoom.Tests.TableExport.Fakes.pas',
  DelphiDoom.Tests.TableExport.Text in 'Source\DelphiDoom.Tests.TableExport.Text.pas',
  DelphiDoom.Tests.TableExport.Profiles in 'Source\DelphiDoom.Tests.TableExport.Profiles.pas',
  DelphiDoom.Tests.TableExport.StateChain in 'Source\DelphiDoom.Tests.TableExport.StateChain.pas',
  DelphiDoom.Tests.TableExport.DehWriter in 'Source\DelphiDoom.Tests.TableExport.DehWriter.pas',
  DelphiDoom.Tests.TableExport.CsvWriter in 'Source\DelphiDoom.Tests.TableExport.CsvWriter.pas',
  DelphiDoom.Tests.TableExport.ActorDefWriter in 'Source\DelphiDoom.Tests.TableExport.ActorDefWriter.pas',
  DelphiDoom.Tests.TableExport.WeaponDefWriter in 'Source\DelphiDoom.Tests.TableExport.WeaponDefWriter.pas',
  DelphiDoom.Tests.TableExport.StateOwnersWriter in 'Source\DelphiDoom.Tests.TableExport.StateOwnersWriter.pas',
  DelphiDoom.Tests.TableExport.PascalWriter in 'Source\DelphiDoom.Tests.TableExport.PascalWriter.pas';

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
