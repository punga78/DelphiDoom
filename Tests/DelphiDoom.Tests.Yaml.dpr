{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the yaml library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library is a port of yaml-cpp 0.7.0, MIT: see Libs\Yaml\README.md)      }
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
  DelphiDoom.Yaml.Types in '..\Libs\Yaml\DelphiDoom.Yaml.Types.pas',
  DelphiDoom.Yaml.Intf in '..\Libs\Yaml\DelphiDoom.Yaml.Intf.pas',
  DelphiDoom.Yaml.Stream in '..\Libs\Yaml\DelphiDoom.Yaml.Stream.pas',
  DelphiDoom.Yaml.RegEx in '..\Libs\Yaml\DelphiDoom.Yaml.RegEx.pas',
  DelphiDoom.Yaml.Exp in '..\Libs\Yaml\DelphiDoom.Yaml.Exp.pas',
  DelphiDoom.Yaml.Token in '..\Libs\Yaml\DelphiDoom.Yaml.Token.pas',
  DelphiDoom.Yaml.ScanScalar in '..\Libs\Yaml\DelphiDoom.Yaml.ScanScalar.pas',
  DelphiDoom.Yaml.ScanTag in '..\Libs\Yaml\DelphiDoom.Yaml.ScanTag.pas',
  DelphiDoom.Yaml.Directives in '..\Libs\Yaml\DelphiDoom.Yaml.Directives.pas',
  DelphiDoom.Yaml.Scanner in '..\Libs\Yaml\DelphiDoom.Yaml.Scanner.pas',
  DelphiDoom.Yaml.SingleDocParser in '..\Libs\Yaml\DelphiDoom.Yaml.SingleDocParser.pas',
  DelphiDoom.Yaml.DocumentParser in '..\Libs\Yaml\DelphiDoom.Yaml.DocumentParser.pas',
  DelphiDoom.Yaml.Convert in '..\Libs\Yaml\DelphiDoom.Yaml.Convert.pas',
  DelphiDoom.Yaml.Detail in '..\Libs\Yaml\DelphiDoom.Yaml.Detail.pas',
  DelphiDoom.Yaml.Node in '..\Libs\Yaml\DelphiDoom.Yaml.Node.pas',
  DelphiDoom.Yaml.NodeBuilder in '..\Libs\Yaml\DelphiDoom.Yaml.NodeBuilder.pas',
  DelphiDoom.Yaml.NodeEvents in '..\Libs\Yaml\DelphiDoom.Yaml.NodeEvents.pas',
  DelphiDoom.Yaml.Loader in '..\Libs\Yaml\DelphiDoom.Yaml.Loader.pas',
  DelphiDoom.Yaml.DiskFileSource in '..\Libs\Yaml\DelphiDoom.Yaml.DiskFileSource.pas',
  DelphiDoom.Yaml.OutputWriter in '..\Libs\Yaml\DelphiDoom.Yaml.OutputWriter.pas',
  DelphiDoom.Yaml.EmitterState in '..\Libs\Yaml\DelphiDoom.Yaml.EmitterState.pas',
  DelphiDoom.Yaml.EmitterUtils in '..\Libs\Yaml\DelphiDoom.Yaml.EmitterUtils.pas',
  DelphiDoom.Yaml.EmitFromEvents in '..\Libs\Yaml\DelphiDoom.Yaml.EmitFromEvents.pas',
  DelphiDoom.Yaml.Emitter in '..\Libs\Yaml\DelphiDoom.Yaml.Emitter.pas',
  DelphiDoom.Yaml.Factory in '..\Libs\Yaml\DelphiDoom.Yaml.Factory.pas',
  DelphiDoom.Tests.Yaml.Dumper in 'Source\DelphiDoom.Tests.Yaml.Dumper.pas',
  DelphiDoom.Tests.Yaml.EmitScript in 'Source\DelphiDoom.Tests.Yaml.EmitScript.pas',
  DelphiDoom.Tests.Yaml.Parity in 'Source\DelphiDoom.Tests.Yaml.Parity.pas';

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
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
