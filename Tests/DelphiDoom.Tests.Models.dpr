{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the 3D models library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Models;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Models.Types in '..\Libs\Models\DelphiDoom.Models.Types.pas',
  DelphiDoom.Models.Intf in '..\Libs\Models\DelphiDoom.Models.Intf.pas',
  DelphiDoom.Models.Md2Model in '..\Libs\Models\DelphiDoom.Models.Md2Model.pas',
  DelphiDoom.Models.Md2Parser in '..\Libs\Models\DelphiDoom.Models.Md2Parser.pas',
  DelphiDoom.Models.CommandStream in '..\Libs\Models\DelphiDoom.Models.CommandStream.pas',
  DelphiDoom.Models.Factory in '..\Libs\Models\DelphiDoom.Models.Factory.pas',
  DelphiDoom.Tests.Models.Fingerprint in 'Source\DelphiDoom.Tests.Models.Fingerprint.pas',
  DelphiDoom.Tests.Models.Golden in 'Source\DelphiDoom.Tests.Models.Golden.pas',
  DelphiDoom.Tests.Models.Samples in 'Source\DelphiDoom.Tests.Models.Samples.pas',
  DelphiDoom.Tests.Models.Scenarios in 'Source\DelphiDoom.Tests.Models.Scenarios.pas',
  DelphiDoom.Tests.Models.Subject in 'Source\DelphiDoom.Tests.Models.Subject.pas',
  DelphiDoom.Tests.Models.Md2Parser in 'Source\DelphiDoom.Tests.Models.Md2Parser.pas',
  DelphiDoom.Tests.Models.CommandStream in 'Source\DelphiDoom.Tests.Models.CommandStream.pas';

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
