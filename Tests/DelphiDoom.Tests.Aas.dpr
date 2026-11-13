{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the AAS library of Quake III (DUnitX)             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Aas;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.BotAi.Types in '..\Libs\BotAi\DelphiDoom.BotAi.Types.pas',
  DelphiDoom.BotAi.Import.Intf in '..\Libs\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.Aas.Types in '..\Libs\Aas\DelphiDoom.Aas.Types.pas',
  DelphiDoom.Aas.Intf in '..\Libs\Aas\DelphiDoom.Aas.Intf.pas',
  DelphiDoom.Aas.Printer in '..\Libs\Aas\DelphiDoom.Aas.Printer.pas',
  DelphiDoom.Aas.VectorMath in '..\Libs\Aas\DelphiDoom.Aas.VectorMath.pas',
  DelphiDoom.Aas.HeaderCipher in '..\Libs\Aas\DelphiDoom.Aas.HeaderCipher.pas',
  DelphiDoom.Aas.ByteSwapper in '..\Libs\Aas\DelphiDoom.Aas.ByteSwapper.pas',
  DelphiDoom.Aas.AasFile in '..\Libs\Aas\DelphiDoom.Aas.AasFile.pas',
  DelphiDoom.Aas.Reader in '..\Libs\Aas\DelphiDoom.Aas.Reader.pas',
  DelphiDoom.Aas.BoxMath in '..\Libs\Aas\DelphiDoom.Aas.BoxMath.pas',
  DelphiDoom.Aas.Sampler in '..\Libs\Aas\DelphiDoom.Aas.Sampler.pas',
  DelphiDoom.Aas.AreaQuery in '..\Libs\Aas\DelphiDoom.Aas.AreaQuery.pas',
  DelphiDoom.Aas.Tracer in '..\Libs\Aas\DelphiDoom.Aas.Tracer.pas',
  DelphiDoom.Aas.FaceTester in '..\Libs\Aas\DelphiDoom.Aas.FaceTester.pas',
  DelphiDoom.Aas.BoxAreas in '..\Libs\Aas\DelphiDoom.Aas.BoxAreas.pas',
  DelphiDoom.Aas.Factory in '..\Libs\Aas\DelphiDoom.Aas.Factory.pas',
  DelphiDoom.Tests.Aas.Sample in 'Source\DelphiDoom.Tests.Aas.Sample.pas',
  DelphiDoom.Tests.Aas.Support in 'Source\DelphiDoom.Tests.Aas.Support.pas',
  DelphiDoom.Tests.Aas.ScenarioRunner in 'Source\DelphiDoom.Tests.Aas.ScenarioRunner.pas',
  DelphiDoom.Tests.Aas.Golden in 'Source\DelphiDoom.Tests.Aas.Golden.pas',
  DelphiDoom.Tests.Aas.Reader in 'Source\DelphiDoom.Tests.Aas.Reader.pas',
  DelphiDoom.Tests.Aas.Sampling in 'Source\DelphiDoom.Tests.Aas.Sampling.pas';

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
