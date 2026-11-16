{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the yaml library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library is a port of yaml-cpp 0.7.0, MIT: see Framework\Yaml\README.md)      }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Yaml;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Yaml.Types in '..\Framework\Yaml\DelphiDoom.Yaml.Types.pas',
  DelphiDoom.Yaml.Intf in '..\Framework\Yaml\DelphiDoom.Yaml.Intf.pas',
  DelphiDoom.Yaml.Stream in '..\Framework\Yaml\DelphiDoom.Yaml.Stream.pas',
  DelphiDoom.Yaml.RegEx in '..\Framework\Yaml\DelphiDoom.Yaml.RegEx.pas',
  DelphiDoom.Yaml.Exp in '..\Framework\Yaml\DelphiDoom.Yaml.Exp.pas',
  DelphiDoom.Yaml.Token in '..\Framework\Yaml\DelphiDoom.Yaml.Token.pas',
  DelphiDoom.Yaml.ScanScalar in '..\Framework\Yaml\DelphiDoom.Yaml.ScanScalar.pas',
  DelphiDoom.Yaml.ScanTag in '..\Framework\Yaml\DelphiDoom.Yaml.ScanTag.pas',
  DelphiDoom.Yaml.Directives in '..\Framework\Yaml\DelphiDoom.Yaml.Directives.pas',
  DelphiDoom.Yaml.Scanner in '..\Framework\Yaml\DelphiDoom.Yaml.Scanner.pas',
  DelphiDoom.Yaml.SingleDocParser in '..\Framework\Yaml\DelphiDoom.Yaml.SingleDocParser.pas',
  DelphiDoom.Yaml.DocumentParser in '..\Framework\Yaml\DelphiDoom.Yaml.DocumentParser.pas',
  DelphiDoom.Yaml.Convert in '..\Framework\Yaml\DelphiDoom.Yaml.Convert.pas',
  DelphiDoom.Yaml.Detail in '..\Framework\Yaml\DelphiDoom.Yaml.Detail.pas',
  DelphiDoom.Yaml.Node in '..\Framework\Yaml\DelphiDoom.Yaml.Node.pas',
  DelphiDoom.Yaml.NodeBuilder in '..\Framework\Yaml\DelphiDoom.Yaml.NodeBuilder.pas',
  DelphiDoom.Yaml.NodeEvents in '..\Framework\Yaml\DelphiDoom.Yaml.NodeEvents.pas',
  DelphiDoom.Yaml.Loader in '..\Framework\Yaml\DelphiDoom.Yaml.Loader.pas',
  DelphiDoom.Yaml.DiskFileSource in '..\Framework\Yaml\DelphiDoom.Yaml.DiskFileSource.pas',
  DelphiDoom.Yaml.OutputWriter in '..\Framework\Yaml\DelphiDoom.Yaml.OutputWriter.pas',
  DelphiDoom.Yaml.EmitterState in '..\Framework\Yaml\DelphiDoom.Yaml.EmitterState.pas',
  DelphiDoom.Yaml.EmitterUtils in '..\Framework\Yaml\DelphiDoom.Yaml.EmitterUtils.pas',
  DelphiDoom.Yaml.EmitFromEvents in '..\Framework\Yaml\DelphiDoom.Yaml.EmitFromEvents.pas',
  DelphiDoom.Yaml.Emitter in '..\Framework\Yaml\DelphiDoom.Yaml.Emitter.pas',
  DelphiDoom.Yaml.Factory in '..\Framework\Yaml\DelphiDoom.Yaml.Factory.pas',
  DelphiDoom.Tests.Yaml.Dumper in 'Source\DelphiDoom.Tests.Yaml.Dumper.pas',
  DelphiDoom.Tests.Yaml.EmitScript in 'Source\DelphiDoom.Tests.Yaml.EmitScript.pas',
  DelphiDoom.Tests.Yaml.Node in 'Source\DelphiDoom.Tests.Yaml.Node.pas',
  DelphiDoom.Tests.Yaml.Convert in 'Source\DelphiDoom.Tests.Yaml.Convert.pas',
  DelphiDoom.Tests.Yaml.Parser in 'Source\DelphiDoom.Tests.Yaml.Parser.pas',
  DelphiDoom.Tests.Yaml.Emitter in 'Source\DelphiDoom.Tests.Yaml.Emitter.pas',
  DelphiDoom.Tests.Yaml.Parity in 'Source\DelphiDoom.Tests.Yaml.Parity.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
  {$ENDIF}
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
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
