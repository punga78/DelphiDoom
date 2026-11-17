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
  DelphiDoom.Serializer.Types in '..\Framework\Serializer\DelphiDoom.Serializer.Types.pas',
  DelphiDoom.Serializer.Intf in '..\Framework\Serializer\DelphiDoom.Serializer.Intf.pas',
  DelphiDoom.Serializer.MemoryStream in '..\Framework\Serializer\DelphiDoom.Serializer.MemoryStream.pas',
  DelphiDoom.Serializer.FieldCodec in '..\Framework\Serializer\DelphiDoom.Serializer.FieldCodec.pas',
  DelphiDoom.Serializer.RecordSerializer in '..\Framework\Serializer\DelphiDoom.Serializer.RecordSerializer.pas',
  DelphiDoom.Serializer.DiskLayout in '..\Framework\Serializer\DelphiDoom.Serializer.DiskLayout.pas',
  DelphiDoom.Serializer.DiskLayoutBuilder in '..\Framework\Serializer\DelphiDoom.Serializer.DiskLayoutBuilder.pas',
  DelphiDoom.Serializer.DiskLayouts in '..\Framework\Serializer\DelphiDoom.Serializer.DiskLayouts.pas',
  DelphiDoom.Serializer.DiskRecordWriter in '..\Framework\Serializer\DelphiDoom.Serializer.DiskRecordWriter.pas',
  DelphiDoom.Serializer.Factory in '..\Framework\Serializer\DelphiDoom.Serializer.Factory.pas',
  DelphiDoom.Serializer.SaveGameName in '..\Framework\Serializer\DelphiDoom.Serializer.SaveGameName.pas',
  DelphiDoom.Serializer.SaveGameHeader in '..\Framework\Serializer\DelphiDoom.Serializer.SaveGameHeader.pas',
  DelphiDoom.Serializer.SaveGameVersions in '..\Framework\Serializer\DelphiDoom.Serializer.SaveGameVersions.pas',
  DelphiDoom.Serializer.SaveGameSessionBlock in '..\Framework\Serializer\DelphiDoom.Serializer.SaveGameSessionBlock.pas',
  DelphiDoom.Tests.Serializer.Fakes in 'Source\DelphiDoom.Tests.Serializer.Fakes.pas',
  DelphiDoom.Tests.Serializer.RecordSerializer in 'Source\DelphiDoom.Tests.Serializer.RecordSerializer.pas',
  DelphiDoom.Tests.Serializer.Golden in 'Source\DelphiDoom.Tests.Serializer.Golden.pas',
  DelphiDoom.Tests.Serializer.DiskLayout in 'Source\DelphiDoom.Tests.Serializer.DiskLayout.pas',
  DelphiDoom.Tests.Serializer.DiskRecordWriter in 'Source\DelphiDoom.Tests.Serializer.DiskRecordWriter.pas',
  DelphiDoom.Tests.Serializer.MemoryStream in 'Source\DelphiDoom.Tests.Serializer.MemoryStream.pas',
  DelphiDoom.Tests.Serializer.SaveGameName in 'Source\DelphiDoom.Tests.Serializer.SaveGameName.pas',
  DelphiDoom.Tests.Serializer.SaveGameHeader in 'Source\DelphiDoom.Tests.Serializer.SaveGameHeader.pas',
  DelphiDoom.Tests.Serializer.SaveGameVersions in 'Source\DelphiDoom.Tests.Serializer.SaveGameVersions.pas',
  DelphiDoom.Tests.Serializer.SaveGameSessionBlock in 'Source\DelphiDoom.Tests.Serializer.SaveGameSessionBlock.pas';

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
