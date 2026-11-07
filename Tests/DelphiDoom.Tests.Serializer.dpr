{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the serializer library (DUnitX)                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Serializer;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Serializer.Types in '..\Libs\Serializer\DelphiDoom.Serializer.Types.pas',
  DelphiDoom.Serializer.Intf in '..\Libs\Serializer\DelphiDoom.Serializer.Intf.pas',
  DelphiDoom.Serializer.MemoryStream in '..\Libs\Serializer\DelphiDoom.Serializer.MemoryStream.pas',
  DelphiDoom.Serializer.FieldCodec in '..\Libs\Serializer\DelphiDoom.Serializer.FieldCodec.pas',
  DelphiDoom.Serializer.RecordSerializer in '..\Libs\Serializer\DelphiDoom.Serializer.RecordSerializer.pas',
  DelphiDoom.Serializer.Factory in '..\Libs\Serializer\DelphiDoom.Serializer.Factory.pas',
  DelphiDoom.Tests.Serializer.Fakes in 'Source\DelphiDoom.Tests.Serializer.Fakes.pas',
  DelphiDoom.Tests.Serializer.RecordSerializer in 'Source\DelphiDoom.Tests.Serializer.RecordSerializer.pas',
  DelphiDoom.Tests.Serializer.Golden in 'Source\DelphiDoom.Tests.Serializer.Golden.pas',
  DelphiDoom.Tests.Serializer.MemoryStream in 'Source\DelphiDoom.Tests.Serializer.MemoryStream.pas';

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
